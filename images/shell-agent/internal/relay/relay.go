// Package relay holds the agent's connection to the platform: how it dials
// out, what it asks for, and how it carries a terminal's bytes both ways.
//
// The transport is deliberately plain HTTP rather than a WebSocket. The
// platform's gateway cannot upgrade a connection — it is a stateless proxy by
// design — so the agent long-polls for work and POSTs output back. That costs
// a little more per exchange than a socket would and keeps the auth boundary
// exactly as it is, which is the better trade for a feature that opens a root
// shell.
package relay

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"
	"unicode/utf8"

	"github.com/zopdev/zopnight/backend/shell-agent/internal/session"
)

// Config is everything the agent needs to reach the platform.
type Config struct {
	RelayURL string
	Token    string
	SpaceID  string
	// PollInterval is the pause between polls when there is no work. Also the
	// backoff floor after a failure.
	PollInterval time.Duration
}

// Bounds on reconnection. The agent must survive the platform being down
// without hammering it, and must not give up — a VM whose agent stopped
// retrying is a VM that silently loses its terminal until someone reinstalls
// the component.
const (
	maxBackoff     = 60 * time.Second
	requestTimeout = 30 * time.Second
	// pollTimeout exceeds the platform's own long-poll window so a quiet
	// period ends with an empty response rather than a client timeout.
	pollTimeout = 90 * time.Second
)

// Command is one instruction from the platform.
type Command struct {
	Type      string `json:"type"`
	SessionID string `json:"sessionId"`
	Scope     string `json:"scope,omitempty"`
	Container string `json:"container,omitempty"`
	Data      string `json:"data,omitempty"`
	Cols      uint16 `json:"cols,omitempty"`
	Rows      uint16 `json:"rows,omitempty"`
}

// The platform's agent surface. Exact paths, matched exactly on the far side:
// the gateway passes this prefix through without a JWT, so the set of things
// reachable that way is kept as small as it can be. Must stay in step with
// aggregator/internal/shellrelay.
const (
	pollPath   = "/agent/shell/poll"
	eventsPath = "/agent/shell/events"
)

// Command types.
const (
	CmdOpen   = "open"
	CmdInput  = "input"
	CmdResize = "resize"
	CmdClose  = "close"
)

// Run dials the platform and serves until ctx ends.
func Run(ctx context.Context, cfg Config) error {
	if err := cfg.validate(); err != nil {
		return err
	}

	a := &agent{
		cfg:      cfg,
		client:   &http.Client{Timeout: pollTimeout},
		sessions: map[string]*session.Session{},
	}

	defer a.closeAll()

	// Reap abandoned terminals. Without this a root shell outlives the
	// platform going away, with nothing left that would ever close it.
	go a.reapIdle(ctx)

	return a.loop(ctx)
}

// validate refuses a config that cannot work, before any network call.
func (c Config) validate() error {
	switch {
	case c.RelayURL == "":
		return &ErrConfig{Field: "relay URL"}
	case c.Token == "":
		return &ErrConfig{Field: "token"}
	case c.SpaceID == "":
		return &ErrConfig{Field: "space id"}
	}

	if !secureRelayURL(c.RelayURL) {
		return &ErrConfig{Field: "relay URL"}
	}

	return nil
}

// secureRelayURL reports whether the relay URL is one the agent may send its
// bearer token to.
//
// The token IS the VM's identity, and a terminal on that VM is what it opens.
// Over plain http it crosses the customer's network in cleartext on every
// poll, so https is required — a parse-only check (what this used to do)
// accepts "http://..." happily and leaks the credential forever.
//
// Loopback is the one exception, for running the agent against a local relay
// during development, where there is no network to intercept.
func secureRelayURL(raw string) bool {
	parsed, err := url.Parse(raw)
	if err != nil || parsed.Host == "" {
		return false
	}

	if parsed.Scheme == "https" {
		return true
	}

	if parsed.Scheme != "http" {
		return false
	}

	host := parsed.Hostname()

	return host == "localhost" || host == "127.0.0.1" || host == "::1"
}

// ErrConfig names the field that cannot be used.
type ErrConfig struct{ Field string }

func (e *ErrConfig) Error() string { return "relay: " + e.Field + " is missing or unusable" }

type agent struct {
	cfg    Config
	client *http.Client

	mu       sync.Mutex
	sessions map[string]*session.Session
}

// loop polls for work until the context ends.
//
// Every error backs off and retries rather than returning: the platform being
// briefly unreachable is an ordinary condition, and an agent that exits on it
// leaves the VM without a terminal until someone notices.
func (a *agent) loop(ctx context.Context) error {
	backoff := a.cfg.PollInterval

	for {
		if err := ctx.Err(); err != nil {
			return err
		}

		cmds, err := a.poll(ctx)
		if err != nil {
			a.reportPollFailure(err)

			select {
			case <-ctx.Done():
				return ctx.Err()
			case <-time.After(backoff):
			}

			backoff = nextBackoff(backoff)

			continue
		}

		backoff = a.cfg.PollInterval

		for _, cmd := range cmds {
			a.handle(ctx, cmd)
		}
	}
}

// idleSweep is how often abandoned terminals are checked for. Frequent enough
// that a leaked shell is measured in minutes past the deadline, cheap enough
// that it costs nothing on an idle VM.
const idleSweep = time.Minute

// reapIdle closes terminals nothing has typed into for session.MaxIdle.
func (a *agent) reapIdle(ctx context.Context) {
	ticker := time.NewTicker(idleSweep)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			a.sweepIdleOnce(ctx)
		}
	}
}

// sweepIdleOnce closes every idle terminal and tells the platform, so a
// browser still holding the session sees it end rather than hanging.
func (a *agent) sweepIdleOnce(ctx context.Context) {
	a.mu.Lock()
	snapshot := make(map[string]*session.Session, len(a.sessions))

	for id, s := range a.sessions {
		snapshot[id] = s
	}
	a.mu.Unlock()

	for id, s := range snapshot {
		if s.CloseIfIdle() {
			a.report(ctx, id, "exit", "")
			a.closeSession(id)
		}
	}
}

// splitTrailingPartialRune splits off an incomplete rune at the end of a
// chunk, returning the part that is safe to send and the bytes to carry over.
//
// UTF-8 runes are at most four bytes, so it never looks further back than
// that, and a chunk ending on a complete rune carries nothing.
func splitTrailingPartialRune(chunk []byte) (send, carry []byte) {
	for i := 1; i <= utf8.UTFMax && i <= len(chunk); i++ {
		at := len(chunk) - i

		r, size := utf8.DecodeRune(chunk[at:])
		if r != utf8.RuneError || size > 1 {
			// The last rune starts here and is complete, so everything is
			// sendable.
			if at+size == len(chunk) {
				return chunk, nil
			}

			break
		}

		// RuneError with size 1 can mean either a genuinely invalid byte or
		// the prefix of a rune still arriving. Only the latter is worth
		// holding, and FullRune tells them apart.
		if !utf8.FullRune(chunk[at:]) {
			return chunk[:at], append([]byte(nil), chunk[at:]...)
		}
	}

	return chunk, nil
}

// reportPollFailure makes an unauthenticated agent visible.
//
// Every non-200 was treated identically — back off and retry, logging
// nothing — so once the token aged past the relay's max age the VM's terminal
// simply stopped working and the agent retried forever. Nobody looking at the
// box could tell that from a network problem, and the fix (re-apply the
// component to mint a fresh token) is not one anybody would guess.
//
// Still a retry rather than an exit: the relay may be rotating secrets, and
// an agent that gave up would need a manual restart to come back.
func (a *agent) reportPollFailure(err error) {
	var statusErr *ErrRelayStatus
	if !errors.As(err, &statusErr) {
		return
	}

	if statusErr.Code == http.StatusUnauthorized || statusErr.Code == http.StatusForbidden {
		log.Printf("shell-agent: the relay refused this agent's token (HTTP %d). "+
			"The token has expired or the relay's SHELL_AGENT_SECRET was rotated; "+
			"re-apply the shell-agent component on this VM to mint a new one.",
			statusErr.Code)
	}
}

// nextBackoff doubles up to the ceiling.
func nextBackoff(current time.Duration) time.Duration {
	next := current * 2
	if next > maxBackoff {
		return maxBackoff
	}

	return next
}

// poll asks for pending commands.
func (a *agent) poll(ctx context.Context) ([]Command, error) {
	req, err := a.newRequest(ctx, http.MethodGet, pollPath, nil)
	if err != nil {
		return nil, err
	}

	resp, err := a.client.Do(req)
	if err != nil {
		return nil, err
	}

	defer func() { _ = resp.Body.Close() }()

	if resp.StatusCode != http.StatusOK {
		_, _ = io.Copy(io.Discard, resp.Body)

		return nil, &ErrRelayStatus{Code: resp.StatusCode}
	}

	var out struct {
		Commands []Command `json:"commands"`
	}

	if derr := json.NewDecoder(resp.Body).Decode(&out); derr != nil {
		return nil, derr
	}

	return out.Commands, nil
}

// ErrRelayStatus is a non-200 from the platform.
type ErrRelayStatus struct{ Code int }

func (e *ErrRelayStatus) Error() string {
	return fmt.Sprintf("relay: the platform answered %d", e.Code)
}

// handle applies one command.
func (a *agent) handle(ctx context.Context, cmd Command) {
	switch cmd.Type {
	case CmdOpen:
		a.open(ctx, cmd)
	case CmdInput:
		a.input(cmd)
	case CmdResize:
		a.resize(cmd)
	case CmdClose:
		a.closeSession(cmd.SessionID)
	}
	// An unknown type is ignored rather than fatal: a newer platform may send
	// something this agent predates, and refusing to run would be a worse
	// answer than skipping one instruction.
}

// open starts a terminal and begins streaming its output.
func (a *agent) open(ctx context.Context, cmd Command) {
	// Claim the id BEFORE starting anything.
	//
	// Starting first and closing the loser does not work with tmux: Start
	// runs `tmux new-session -A -s zopday-<id>`, which ATTACHES to the
	// existing session rather than making a second one — so both Session
	// objects name the same tmux session, and closing the "duplicate" runs
	// kill-session on the name the live terminal is using. The user's shell
	// dies and its pump reports exit. The only safe order is to refuse the
	// duplicate before any tmux command runs.
	a.mu.Lock()
	_, exists := a.sessions[cmd.SessionID]
	a.mu.Unlock()

	if exists {
		return
	}

	s, err := session.Start(session.Spec{
		Scope: cmd.Scope, Container: cmd.Container, Cols: cmd.Cols, Rows: cmd.Rows,
	}, cmd.SessionID)
	if err != nil {
		a.report(ctx, cmd.SessionID, "error", err.Error())

		return
	}

	// Re-check under the lock: two opens for one id can race between the
	// check above and here, and the loser must not start a pump on a session
	// the map does not hold.
	a.mu.Lock()
	_, exists = a.sessions[cmd.SessionID]
	if !exists {
		a.sessions[cmd.SessionID] = s
	}
	a.mu.Unlock()

	// Lost the race: another open claimed the id first. Detach THIS object
	// without touching the shared tmux session, which the winner is using.
	if exists {
		s.Detach()

		return
	}

	go a.pump(ctx, cmd.SessionID, s)
}

// pump carries terminal output back to the platform until the shell exits.
func (a *agent) pump(ctx context.Context, sessionID string, s *session.Session) {
	buf := make([]byte, 32*1024)

	// Bytes held back from the previous read because they are the start of a
	// rune the read boundary cut in half.
	//
	// Terminal output is not chunk-aligned: a 32 KiB read can end mid-rune,
	// and json.Marshal replaces invalid UTF-8 with U+FFFD — so box-drawing
	// characters, accents and any non-English text were permanently corrupted
	// whenever a boundary fell inside a character. Carrying the tail over
	// costs at most three bytes of latency and makes the stream exact.
	var carry []byte

	for {
		n, err := s.Read(buf)
		if n > 0 {
			chunk := append(carry, buf[:n]...)
			chunk, carry = splitTrailingPartialRune(chunk)

			if len(chunk) > 0 {
				a.report(ctx, sessionID, "output", string(chunk))
			}
		}

		if err != nil {
			// Whatever is left cannot be completed — the shell has ended. Send
			// it as-is rather than dropping it; one replacement character at
			// the very end beats losing the last line.
			if len(carry) > 0 {
				a.report(ctx, sessionID, "output", string(carry))
			}

			a.report(ctx, sessionID, "exit", "")
			// Only if the map still holds THIS session: an id that has since
			// been reopened belongs to a different shell, and closing by id
			// alone would kill the terminal the user is currently using.
			a.closeOwnedSession(sessionID, s)

			return
		}

		if ctx.Err() != nil {
			return
		}
	}
}

func (a *agent) input(cmd Command) {
	if s := a.lookup(cmd.SessionID); s != nil {
		_, _ = s.Write([]byte(cmd.Data))
	}
}

func (a *agent) resize(cmd Command) {
	if s := a.lookup(cmd.SessionID); s != nil {
		_ = s.Resize(cmd.Cols, cmd.Rows)
	}
}

func (a *agent) lookup(sessionID string) *session.Session {
	a.mu.Lock()
	defer a.mu.Unlock()

	return a.sessions[sessionID]
}

// closeOwnedSession ends a session only while the map still holds that exact
// one, so a pump whose shell has exited cannot close a replacement that took
// its id.
func (a *agent) closeOwnedSession(sessionID string, s *session.Session) {
	a.mu.Lock()
	current, ok := a.sessions[sessionID]

	if ok && current == s {
		delete(a.sessions, sessionID)
	} else {
		s = nil
	}
	a.mu.Unlock()

	if s != nil {
		_ = s.Close()
	}
}

// closeSession ends one terminal by id. Safe to call for an id that is
// already gone — the pump and the platform both reach for it.
func (a *agent) closeSession(sessionID string) {
	a.mu.Lock()
	s := a.sessions[sessionID]
	delete(a.sessions, sessionID)
	a.mu.Unlock()

	if s != nil {
		_ = s.Close()
	}
}

// closeAll ends every terminal, so stopping the agent does not leave shells
// running on the VM with nothing attached to them.
func (a *agent) closeAll() {
	a.mu.Lock()
	all := a.sessions
	a.sessions = map[string]*session.Session{}
	a.mu.Unlock()

	for _, s := range all {
		_ = s.Close()
	}
}

// report sends one event upstream. Best-effort: a dropped frame is better
// than a blocked terminal, and the next poll re-establishes the connection.
func (a *agent) report(ctx context.Context, sessionID, kind, data string) {
	body, err := json.Marshal(map[string]string{
		"sessionId": sessionID, "type": kind, "data": data,
	})
	if err != nil {
		return
	}

	sendCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), requestTimeout)
	defer cancel()

	req, err := a.newRequest(sendCtx, http.MethodPost, eventsPath, body)
	if err != nil {
		return
	}

	resp, err := a.client.Do(req)
	if err != nil {
		return
	}

	defer func() { _ = resp.Body.Close() }()

	_, _ = io.Copy(io.Discard, resp.Body)
}

// newRequest builds an authenticated request to the relay.
func (a *agent) newRequest(ctx context.Context, method, path string, body []byte) (*http.Request, error) {
	var rdr io.Reader
	if body != nil {
		rdr = bytes.NewReader(body)
	}

	req, err := http.NewRequestWithContext(ctx, method,
		strings.TrimRight(a.cfg.RelayURL, "/")+path, rdr)
	if err != nil {
		return nil, err
	}

	// The token IS the agent's identity; there is no second factor and no
	// session cookie.
	req.Header.Set("Authorization", "Bearer "+a.cfg.Token)
	req.Header.Set("X-Zop-Space-Id", a.cfg.SpaceID)

	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	return req, nil
}
