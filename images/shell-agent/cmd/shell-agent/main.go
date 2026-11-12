// Command shell-agent is the process that makes an interactive terminal
// possible on a deployment VM.
//
// It opens no port and accepts no connection. It dials the platform, holds
// that connection, and serves pseudo-terminals over it — which is what lets
// it work on a private-subnet VM with no public address, no inbound firewall
// rule and no bastion.
package main

import (
	"context"
	"errors"
	"log"
	"os"
	"os/signal"
	"slices"
	"strings"
	"syscall"
	"time"

	"github.com/zopdev/zopnight/backend/shell-agent/internal/relay"
)

// Configuration, all from the environment the component's install script
// exports. Read here and nowhere else, so every other package takes what it
// needs as an argument.
const (
	envRelayURL = "ZOP_SHELL_RELAY_URL"
	// Selected on the VM by the component script from the per-space blob, so
	// each machine's agent carries its own credential.
	envToken   = "ZOP_SHELL_AGENT_TOKEN"
	envSpaceID = "ZOP_SHELL_SPACE_ID"
)

func main() {
	cfg, err := loadConfig()
	if err != nil {
		// Exit non-zero so the container restarts and the component's health
		// gate fails loudly, rather than a running agent that can do nothing.
		log.Fatalf("shell-agent: %v", err)
	}

	// SIGTERM is how docker stops it; both signals end sessions cleanly so a
	// restart does not leave orphaned shells behind.
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	log.Printf("shell-agent: connecting to %s for space %s", cfg.RelayURL, cfg.SpaceID)

	if rerr := relay.Run(ctx, cfg); rerr != nil && !errors.Is(rerr, context.Canceled) {
		log.Fatalf("shell-agent: %v", rerr)
	}

	log.Print("shell-agent: stopped")
}

// loadConfig reads and validates the environment.
//
// Every value is required. An agent missing any of them cannot do its job,
// and failing at startup is the only point where that is visible — a later
// failure looks to the user like a VM that will not open a terminal, with
// nothing saying why.
func loadConfig() (relay.Config, error) {
	cfg := relay.Config{
		RelayURL: strings.TrimSpace(os.Getenv(envRelayURL)),
		Token:    strings.TrimSpace(os.Getenv(envToken)),
		SpaceID:  strings.TrimSpace(os.Getenv(envSpaceID)),
		// Deliberately not configurable: a knob here is a knob that gets set
		// wrong on one VM and makes its behaviour differ from the fleet's.
		PollInterval: 2 * time.Second,
	}

	var missing []string

	for name, v := range map[string]string{
		envRelayURL: cfg.RelayURL,
		envToken:    cfg.Token,
		envSpaceID:  cfg.SpaceID,
	} {
		if v == "" {
			missing = append(missing, name)
		}
	}

	if len(missing) > 0 {
		return relay.Config{}, &ErrMissingConfig{Names: missing}
	}

	return cfg, nil
}

// ErrMissingConfig names every environment variable that was absent, rather
// than the first — an operator fixing one at a time is an operator making
// three deploys.
type ErrMissingConfig struct{ Names []string }

func (e *ErrMissingConfig) Error() string {
	return "required configuration is missing: " + strings.Join(sorted(e.Names), ", ")
}

// sorted returns the names in a stable order so the message does not change
// between runs for the same fault — they are collected by ranging over a map,
// which Go deliberately randomises.
func sorted(in []string) []string {
	out := slices.Clone(in)
	slices.Sort(out)

	return out
}
