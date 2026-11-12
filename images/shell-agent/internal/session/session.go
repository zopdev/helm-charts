// Package session owns one pseudo-terminal on the VM: starting it, carrying
// bytes in both directions, resizing it, and making sure it is gone when the
// session ends.
package session

import (
	"context"
	"errors"
	"io"
	"net/http"
	"os"
	"os/exec"
	"sync"
	"syscall"
	"time"

	"github.com/creack/pty"
)

// Scopes, mirroring the aggregator's model.ShellScope* constants. Two values
// rather than a boolean because they are gated by different permissions on
// the platform side and start different programs here.
const (
	ScopeContainer = "container"
	ScopeHost      = "host"
)

// Bounds. A terminal is interactive, so these are generous — but not absent:
// an abandoned session holds a shell, and a window the size of a screen is
// not a window the size of a buffer.
const (
	// MaxIdle closes a session nothing has typed into. The platform closes
	// its own side too; this is the half that survives the platform going
	// away, which is the case that would otherwise leak a shell forever.
	MaxIdle = 30 * time.Minute

	// MaxCols and MaxRows bound a resize. A terminal larger than this is not
	// a terminal; it is an allocation request.
	MaxCols = 500
	MaxRows = 300

	// killGrace is how long a shell has to exit after its PTY closes before
	// it is killed outright.
	killGrace = 2 * time.Second
	// tmuxKillTimeout bounds the kill-session call so a wedged or missing
	// tmux cannot stall the agent's own teardown.
	tmuxKillTimeout = 5 * time.Second
)

// ErrClosed is returned by Write and Resize after the session has ended.
type ErrClosed struct{}

func (ErrClosed) Error() string   { return "session: the terminal has closed" }
func (ErrClosed) StatusCode() int { return http.StatusGone }

// ErrInvalidScope rejects a scope this agent has no program for.
type ErrInvalidScope struct{ Scope string }

func (e ErrInvalidScope) Error() string { return "session: unknown scope " + e.Scope }
func (ErrInvalidScope) StatusCode() int { return http.StatusBadRequest }

// ErrInvalidContainer rejects a container name outside docker's charset.
//
// This is the only caller-supplied value that becomes part of a command line
// here, which is why it is validated rather than quoted: the platform
// validates it too, and neither side trusts the other to have done it.
type ErrInvalidContainer struct{ Name string }

func (e ErrInvalidContainer) Error() string { return "session: invalid container name " + e.Name }
func (ErrInvalidContainer) StatusCode() int { return http.StatusBadRequest }

// Spec is what to start.
type Spec struct {
	Scope     string
	Container string
	// Cols and Rows are the initial window. Zero takes a sane default rather
	// than a zero-sized terminal, which makes `clear` and every full-screen
	// program misbehave in ways that look like the agent is broken.
	Cols, Rows uint16
}

// Session is one running pseudo-terminal.
type Session struct {
	pty  *os.File
	cmd  *exec.Cmd
	once sync.Once

	// tmuxName is the tmux session this terminal lives in, empty without
	// tmux. Close MUST kill it by name: the process the agent starts is the
	// tmux CLIENT, and the server daemonizes into its own session owning the
	// shell — so signalling the client's process group ends the client and
	// leaves a root shell running on the VM.
	tmuxName string

	mu       sync.Mutex
	closed   bool
	lastSeen time.Time
	// now is injectable so the idle rule is tested without sleeping for half
	// an hour.
	now func() time.Time
}

// Start opens a pseudo-terminal running the program the spec names.
//
// Under `tmux new-session -A`: a dropped connection must not kill the work.
// Reattaching to the same named session is what makes a closed browser tab
// survivable, and it is why the platform can offer reconnect at all.
func Start(spec Spec, sessionID string) (*Session, error) {
	haveTmux := tmuxAvailable()

	program, err := programFor(spec, sessionID, haveTmux, hostNamespacesReachable())
	if err != nil {
		return nil, err
	}

	var tmuxName string
	if haveTmux {
		tmuxName = tmuxSessionName(sessionID)
	}

	cmd := exec.Command(program[0], program[1:]...) //nolint:gosec // G204: every element is validated or constant — see programFor
	cmd.Env = append(os.Environ(), "TERM=xterm-256color")
	// Its own process group, so Close can signal the shell AND everything it
	// started. Without this, a child that ignores SIGHUP — or a `docker exec`
	// client the shell spawned — outlives the session and holds the VM's
	// resources with nothing attached.
	cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}

	f, err := pty.StartWithSize(cmd, &pty.Winsize{
		Cols: clampWindow(spec.Cols, MaxCols, 80),
		Rows: clampWindow(spec.Rows, MaxRows, 24),
	})
	if err != nil {
		return nil, err
	}

	return &Session{pty: f, cmd: cmd, tmuxName: tmuxName, lastSeen: time.Now(), now: time.Now}, nil
}

// programFor builds the argv. Every element is either a constant or a value
// that has been validated against a charset — nothing is quoted, because
// nothing here goes through a shell that could reinterpret a quote.
//
// haveTmux and hostNS are injected rather than probed inline so both branches
// are tested, rather than only the one that happens to match the machine the
// suite runs on — the host-namespace branch in particular only ever fires
// inside a container with --pid=host.
func programFor(spec Spec, sessionID string, haveTmux, hostNS bool) ([]string, error) {
	inner, err := innerProgram(spec, hostNS)
	if err != nil {
		return nil, err
	}

	if !haveTmux {
		// Degraded, not refused. Without tmux a dropped connection ends the
		// work, which is worse — but a VM whose component install predates
		// the tmux dependency should still get a terminal rather than an
		// error nobody can act on from the browser. The component script
		// installs tmux, so this is the older-VM path.
		return inner, nil
	}

	// -A: attach if the named session exists, create it otherwise. That one
	// flag is the whole reconnect story — it is what makes a closed browser
	// tab survivable.
	if !tmuxSafeID(sessionID) {
		return nil, ErrInvalidSessionID{ID: sessionID}
	}

	return append([]string{"tmux", "new-session", "-A", "-s", tmuxSessionName(sessionID)}, inner...), nil
}

// innerProgram is the shell the session actually runs, with or without tmux
// wrapped around it.
func innerProgram(spec Spec, hostNS bool) ([]string, error) {
	switch spec.Scope {
	case ScopeHost:
		// nsenter, not bash directly. The agent runs IN a container, so an
		// unqualified `bash -l` lands in the agent image's own Alpine
		// filesystem — no host packages, no host /etc, no host /home — which
		// is not the machine the user asked for and makes host administration
		// impossible.
		//
		// Entering PID 1's mount, UTS, IPC, network and PID namespaces puts
		// the shell on the VM itself. This is what the component's
		// `--pid=host` exists for; without that flag PID 1 is the agent's own
		// process and this would re-enter its own namespaces, so the two have
		// to stay in step.
		if hostNS {
			return []string{"nsenter", "-t", "1", "-m", "-u", "-i", "-n", "-p", "--", "bash", "-l"}, nil
		}

		// Not containerised at all — a test, or a packaging that runs the
		// agent directly on the host — so the login shell already IS the
		// host. Distinguished from "containerised but cannot reach the host",
		// which is a refusal rather than a fallback.
		if !containerised() {
			return []string{"bash", "-l"}, nil
		}

		return nil, ErrHostShellUnavailable{
			Reason: "the agent is containerised without nsenter or the host namespaces " +
				"(it needs --pid=host and --cap-add=SYS_ADMIN)",
		}

	case ScopeContainer:
		if !ValidContainerName(spec.Container) {
			return nil, ErrInvalidContainer{Name: spec.Container}
		}
		// sh, not bash: a service image is not guaranteed to carry bash.
		return []string{"docker", "exec", "-it", spec.Container, "sh"}, nil
	}

	return nil, ErrInvalidScope{Scope: spec.Scope}
}

// hostNamespacesReachable reports whether this process is containerised with
// the host's PID namespace visible, which is the only case where entering
// PID 1's namespaces is both necessary and correct.
//
// Compares the MOUNT namespace of PID 1 with our own. /proc/<pid>/ns/mnt is a
// symlink whose target is "mnt:[<inode>]", so two processes in different
// mount namespaces read differently — which is exactly the condition that
// makes nsenter necessary.
//
// The previous probe read /proc/1/root and asked whether it was "/". That was
// wrong in both directions: the kernel renders a root unreachable from the
// reader's own root as "/", and the readlink needs ptrace access it may not
// have, so under --pid=host it typically returned false and a host shell
// silently landed in the agent's own container.
func hostNamespacesReachable() bool {
	if _, err := exec.LookPath("nsenter"); err != nil {
		return false
	}

	theirs, err := os.Readlink("/proc/1/ns/mnt")
	if err != nil {
		return false
	}

	ours, err := os.Readlink("/proc/self/ns/mnt")
	if err != nil {
		return false
	}

	return theirs != ours
}

// ErrHostShellUnavailable refuses a host shell the agent cannot actually
// deliver.
//
// Fails CLOSED. Falling back to `bash -l` gave the user a shell in the
// agent's own Alpine container labelled as the machine — no host packages, no
// host /etc, no host /home — and told them nothing, so they would act on a
// box that is not the one they asked for.
type ErrHostShellUnavailable struct{ Reason string }

func (e ErrHostShellUnavailable) Error() string {
	return "a shell on the VM itself is not available on this agent: " + e.Reason
}

// containerised reports whether this process is running inside a container,
// which is what separates "the agent IS the host" from "the agent cannot
// reach the host". A different mount namespace from PID 1 already means
// containerised; so does the presence of /.dockerenv.
func containerised() bool {
	if _, err := os.Stat("/.dockerenv"); err == nil {
		return true
	}

	theirs, terr := os.Readlink("/proc/1/ns/mnt")
	ours, oerr := os.Readlink("/proc/self/ns/mnt")

	return terr == nil && oerr == nil && theirs != ours
}

// TmuxAvailable reports whether tmux is on PATH. Exported so the relay
// package tests can skip a check that only has meaning with tmux present.
func TmuxAvailable() bool { return tmuxAvailable() }

// tmuxAvailable reports whether tmux is on PATH.
func tmuxAvailable() bool {
	_, err := exec.LookPath("tmux")

	return err == nil
}

// Read returns output from the terminal. io.EOF means the shell exited.
func (s *Session) Read(p []byte) (int, error) {
	n, err := s.pty.Read(p)

	return n, translateReadErr(err)
}

// translateReadErr turns a closed PTY into EOF.
//
// On Linux a PTY whose child has exited reads EIO, not EOF. Left alone that
// reaches the browser as an I/O error on a terminal that simply ended, which
// reads like the agent broke. Split out from Read so the branch is testable
// on any platform rather than only on the one where it fires.
func translateReadErr(err error) error {
	if err != nil && errors.Is(err, syscall.EIO) {
		return io.EOF
	}

	return err
}

// Write sends keystrokes to the terminal.
func (s *Session) Write(p []byte) (int, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.closed {
		return 0, ErrClosed{}
	}

	s.lastSeen = s.clock()

	return s.pty.Write(p)
}

// IdleFor reports how long it has been since anything was typed.
func (s *Session) IdleFor() time.Duration {
	s.mu.Lock()
	defer s.mu.Unlock()

	return s.clock().Sub(s.lastSeen)
}

// CloseIfIdle ends the session when nothing has been typed for MaxIdle, and
// reports whether it did.
//
// This is the half that survives the PLATFORM disappearing. The platform
// closes its own side when a browser goes away, but if the platform itself
// becomes unreachable nothing else would ever reap the shell — and a root
// terminal on a customer VM left open indefinitely is the worst way for this
// feature to fail.
func (s *Session) CloseIfIdle() bool {
	if s.IdleFor() < MaxIdle {
		return false
	}

	_ = s.Close()

	return true
}

// clock reads the injected clock, defaulting to the real one so a Session
// built outside Start still works.
func (s *Session) clock() time.Time {
	if s.now != nil {
		return s.now()
	}

	return time.Now()
}

// Resize changes the terminal window. Out-of-range values are clamped rather
// than refused: a browser reporting a silly size should not end the session.
func (s *Session) Resize(cols, rows uint16) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.closed {
		return ErrClosed{}
	}

	s.lastSeen = s.clock()

	return pty.Setsize(s.pty, &pty.Winsize{
		Cols: clampWindow(cols, MaxCols, 80),
		Rows: clampWindow(rows, MaxRows, 24),
	})
}

// Close ends the session and makes sure the shell is gone.
//
// Closing the PTY alone is not enough: a process ignoring SIGHUP would
// outlive it and hold the VM's resources with nothing attached. So the
// process group is signalled, given a moment, and then killed.
func (s *Session) Close() error {
	var err error

	s.once.Do(func() {
		s.mu.Lock()
		s.closed = true
		s.mu.Unlock()

		err = s.pty.Close()

		// Kill the tmux SESSION, not just the client.
		//
		// `tmux new-session -A` starts a client; the server daemonizes into
		// its own session and owns the shell. Signalling the client's process
		// group below ends the client and leaves the shell — root, via
		// nsenter, for host scope — running on the VM until the agent
		// container restarts. Every browser close, idle reap and revoked
		// session leaked one.
		s.killTmuxSession()

		if s.cmd.Process == nil {
			return
		}

		// Negative pid = the whole process group. SIGHUP first, because that
		// is what a shell expects when its terminal goes away and it lets
		// one clean up; SIGKILL after the grace for anything that ignored it.
		pid := s.cmd.Process.Pid
		_ = syscall.Kill(-pid, syscall.SIGHUP)

		done := make(chan struct{})

		go func() {
			_, _ = s.cmd.Process.Wait()
			close(done)
		}()

		select {
		case <-done:
		case <-time.After(killGrace):
			if kerr := syscall.Kill(-pid, syscall.SIGKILL); kerr != nil {
				// The group is gone or unreachable; fall back to the leader
				// so a single surviving process is still reaped.
				_ = s.cmd.Process.Kill()
			}

			<-done
		}
	})

	return err
}

// ValidContainerName reports whether name matches docker's allowed charset.
// Deliberately the same expression the platform applies, so a name that
// passes there cannot fail here for a reason the user cannot see.
func ValidContainerName(name string) bool {
	if name == "" {
		return false
	}

	for i, r := range name {
		switch {
		case r >= 'a' && r <= 'z', r >= 'A' && r <= 'Z', r >= '0' && r <= '9':
		case (r == '_' || r == '.' || r == '-') && i > 0:
		default:
			return false
		}
	}

	return true
}

// ErrInvalidSessionID refuses a session id that is not already safe as a tmux
// session name.
type ErrInvalidSessionID struct{ ID string }

func (e ErrInvalidSessionID) Error() string {
	return "session id " + e.ID + " is not a valid session name"
}

// tmuxSafeID reports whether an id can be used as a tmux session name
// unchanged.
//
// REFUSED rather than rewritten, which is what this used to do. Folding every
// character outside [A-Za-z0-9-] to "-" is not injective: "a.b" and "a:b"
// both became "a-b", so two different sessions would land on ONE tmux session
// and `new-session -A` would attach the second user to the first user's live
// terminal. Collapsing distinct ids onto one name is the bug; a rewrite can
// only ever hide it.
//
// Every id the platform issues is a UUID, so nothing legitimate is refused.
func tmuxSafeID(id string) bool {
	if id == "" {
		return false
	}

	for _, r := range id {
		switch {
		case r >= 'a' && r <= 'z', r >= 'A' && r <= 'Z', r >= '0' && r <= '9', r == '-':
		default:
			return false
		}
	}

	return true
}

// tmuxSessionName is the tmux session a terminal id maps to. One function,
// so the name Close kills cannot drift from the name Start created.
func tmuxSessionName(sessionID string) string { return "zopday-" + sessionID }

// killTmuxSession ends the server-side session that owns the shell.
//
// Best-effort and bounded: the agent must still tear down its own side even
// if tmux is wedged or already gone. "no server running" and "session not
// found" are both expected on an already-ended session.
func (s *Session) killTmuxSession() {
	if s.tmuxName == "" {
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), tmuxKillTimeout)
	defer cancel()

	_ = exec.CommandContext(ctx, "tmux", "kill-session", "-t", s.tmuxName).Run()
}

// Detach releases this object's own resources WITHOUT ending the terminal.
//
// For the loser of a race to claim a session id. With tmux, two Session
// objects for one id share a single tmux session — `new-session -A` attaches
// rather than creating — so a plain Close would kill-session the name the
// WINNER is using and take the live terminal down with it. This closes only
// the local pty and process, and leaves the tmux session alone.
func (s *Session) Detach() {
	s.once.Do(func() {
		s.mu.Lock()
		s.closed = true
		s.mu.Unlock()

		_ = s.pty.Close()

		if s.cmd.Process != nil {
			_ = s.cmd.Process.Kill()
			_, _ = s.cmd.Process.Wait()
		}
	})
}

// clampWindow bounds a dimension, falling back to def for zero.
func clampWindow(v, max, def uint16) uint16 {
	switch {
	case v == 0:
		return def
	case v > max:
		return max
	}

	return v
}
