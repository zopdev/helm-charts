#!/usr/bin/env bash
# zop-shell-agent — the process that makes an interactive terminal possible on
# a deployment VM.
#
# Runs ON THE HOST as a systemd service, the same way the scale-to-zero
# component's caddy binary does. That is the whole design: a host process
# needs no --pid=host, no CAP_SYS_ADMIN, no CAP_SYS_PTRACE, no
# apparmor=unconfined, no docker.sock mount and no nsenter. It is already
# where the shell has to run.
#
# OUTBOUND ONLY. It dials the relay and holds the connection open; nothing
# ever dials in. That is why this works on a private-subnet VM with no public
# address, no inbound rule and no bastion.
#
# tmux does the hard part. It owns the pseudo-terminal, survives a dropped
# connection, and `pipe-pane -O` hands us the raw byte stream the browser's
# terminal emulator wants — escape sequences and all. Re-implementing any of
# that would be writing a worse tmux.

set -uo pipefail

RELAY_URL="${ZOP_SHELL_RELAY_URL:?relay url is required}"
TOKEN="${ZOP_SHELL_AGENT_TOKEN:?agent token is required}"
SPACE_ID="${ZOP_SHELL_SPACE_ID:?space id is required}"

# Where per-session output is spooled. Under /run so it is tmpfs and does not
# survive a reboot: a terminal's bytes are the most sensitive thing this
# machine handles, and none of it belongs on disk.
RUN_DIR="${ZOP_SHELL_RUN_DIR:-/run/zop-shell-agent}"

# POLL_MAX_SECONDS bounds one long poll. The relay parks for 25s, so this is
# the ceiling plus slack for a slow link; a proxy that cuts idle connections
# shorter just means more requests, never a lost command.
POLL_MAX_SECONDS="${ZOP_SHELL_POLL_TIMEOUT:-40}"

# OUTPUT_CHUNK_BYTES bounds one event body. The relay caps what it accepts at
# 1 MiB; staying well under it means a burst is split across events rather
# than refused.
OUTPUT_CHUNK_BYTES=65536

# SESSION_PREFIX must match the deployer's tmuxSessionName so an operator
# reading `tmux ls` on the box sees the same names the platform uses.
SESSION_PREFIX="zopday-"

log() { printf '%s zop-shell-agent: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2; }

# require_tools fails at START rather than on the first terminal somebody
# tries to open. An agent that is running but cannot work is worse than one
# that never started: the UI says "connected" and nothing happens.
require_tools() {
  local missing=()
  for t in curl jq tmux; do
    command -v "$t" >/dev/null 2>&1 || missing+=("$t")
  done

  if [ ${#missing[@]} -gt 0 ]; then
    log "missing required tools: ${missing[*]}"
    exit 1
  fi
}

session_name() { printf '%s%s' "$SESSION_PREFIX" "$1"; }

# post_event reports one thing back to the relay.
#
# --data-binary with a file, not an argument: terminal output contains NUL,
# newlines and arbitrary bytes, and an argv-sized payload would both truncate
# and leak into the process list.
post_event() {
  local session_id="$1" type="$2" data="$3" body
  body="$(mktemp "$RUN_DIR/event.XXXXXX")"

  jq -nc --arg s "$session_id" --arg t "$type" --arg d "$data" \
    '{sessionId:$s, type:$t, data:$d}' > "$body"

  curl -sS -m 30 -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    --data-binary "@$body" \
    "$RELAY_URL/agent/shell/events" >/dev/null 2>&1 \
    || log "event $type for $session_id could not be delivered"

  rm -f "$body"
}

# open_session starts a terminal.
#
# The shell is started DIRECTLY — this process is already on the host, so a
# host terminal is just a shell. A container terminal is `docker exec` from
# the host's own docker, which needs no socket mount because it is the host's
# own socket.
open_session() {
  local session_id="$1" scope="$2" container="$3" cols="$4" rows="$5"
  local name program
  name="$(session_name "$session_id")"

  [ "$cols" -gt 0 ] 2>/dev/null || cols=80
  [ "$rows" -gt 0 ] 2>/dev/null || rows=24

  if [ "$scope" = "container" ]; then
    # The name is validated against docker's charset by the platform before
    # it reaches here, and again as an argv element — never through a shell.
    if ! docker inspect --type container "$container" >/dev/null 2>&1; then
      post_event "$session_id" "error" "container $container is not running on this VM"
      return
    fi
    program=(docker exec -it "$container" sh)
  else
    program=(bash -l)
  fi

  if ! tmux new-session -d -s "$name" -x "$cols" -y "$rows" "${program[@]}" 2>/dev/null; then
    post_event "$session_id" "error" "a terminal could not be started on this VM"
    return
  fi

  # -O streams what the pane PRODUCES. Appending to a spool file rather than
  # piping straight to curl so a slow or dropped POST cannot apply back
  # pressure to the user's shell.
  tmux pipe-pane -t "$name" -O "cat >> $RUN_DIR/$session_id.out" 2>/dev/null

  log "opened $scope terminal $session_id"
}

# pump_output ships whatever each live session has produced since last time.
#
# Tracked by a per-session BYTE OFFSET rather than by truncating the spool.
# pipe-pane holds the file open and appends to the inode, so truncating or
# renaming it underneath loses whatever was written between the read and the
# swap — and on a terminal that is a line of someone's output vanishing with
# nothing to indicate it. An offset can only ever lag, never lose.
pump_output() {
  local spool session_id offset size chunk
  shopt -s nullglob

  for spool in "$RUN_DIR"/*.out; do
    session_id="$(basename "$spool" .out)"

    size=$(wc -c < "$spool" 2>/dev/null | tr -d ' ')
    [ -n "$size" ] || continue

    offset=0
    [ -f "$RUN_DIR/$session_id.off" ] && offset="$(cat "$RUN_DIR/$session_id.off")"

    # The shell restarted and the spool was recreated shorter than our mark.
    [ "$offset" -gt "$size" ] 2>/dev/null && offset=0

    [ "$size" -gt "$offset" ] 2>/dev/null || continue

    chunk="$(tail -c "+$((offset + 1))" "$spool" | head -c "$OUTPUT_CHUNK_BYTES")"
    [ -n "$chunk" ] || continue

    post_event "$session_id" "output" "$chunk"

    # Advanced by what was actually taken, so a chunk capped at the ceiling
    # resumes exactly where it stopped on the next pass.
    printf '%s' "$((offset + $(printf '%s' "$chunk" | wc -c | tr -d ' ')))" \
      > "$RUN_DIR/$session_id.off"
  done

  shopt -u nullglob
}

# reap_finished tells the platform about terminals whose shell has exited, so
# the browser stops waiting on output that can never arrive.
reap_finished() {
  local spool session_id name
  shopt -s nullglob

  for spool in "$RUN_DIR"/*.out; do
    session_id="$(basename "$spool" .out)"
    name="$(session_name "$session_id")"

    if ! tmux has-session -t "$name" 2>/dev/null; then
      post_event "$session_id" "exit" ""
      rm -f "$spool" "$RUN_DIR/$session_id.off"
      log "terminal $session_id ended"
    fi
  done

  shopt -u nullglob
}

close_session() {
  local session_id="$1" name
  name="$(session_name "$session_id")"

  tmux kill-session -t "$name" 2>/dev/null
  rm -f "$RUN_DIR/$session_id.out" "$RUN_DIR/$session_id.off"
  log "closed terminal $session_id"
}

# apply_command runs one instruction from the relay.
apply_command() {
  local cmd="$1" type session_id

  type="$(jq -r '.type // empty' <<<"$cmd")"
  session_id="$(jq -r '.sessionId // empty' <<<"$cmd")"

  [ -n "$session_id" ] || return

  case "$type" in
    open)
      open_session "$session_id" \
        "$(jq -r '.scope // "container"' <<<"$cmd")" \
        "$(jq -r '.container // ""' <<<"$cmd")" \
        "$(jq -r '.cols // 0' <<<"$cmd")" \
        "$(jq -r '.rows // 0' <<<"$cmd")"
      ;;
    input)
      # Delivered through a tmux BUFFER rather than send-keys, so the bytes
      # reach the pty verbatim: send-keys interprets its argument as key
      # names, so a person typing the word "Enter" would send a newline.
      # Data arrives as a raw JSON string (the relay does not base64 it), so
      # jq -r hands us exactly what was typed.
      local data
      data="$(jq -r '.data // ""' <<<"$cmd")"
      [ -n "$data" ] && printf '%s' "$data" \
        | tmux load-buffer -b "zop-$session_id" - 2>/dev/null \
        && tmux paste-buffer -d -b "zop-$session_id" -t "$(session_name "$session_id")" 2>/dev/null
      ;;
    resize)
      tmux resize-window -t "$(session_name "$session_id")" \
        -x "$(jq -r '.cols // 80' <<<"$cmd")" \
        -y "$(jq -r '.rows // 24' <<<"$cmd")" 2>/dev/null
      ;;
    close)
      close_session "$session_id"
      ;;
  esac
}

poll_once() {
  local body
  body="$(curl -sS -m "$POLL_MAX_SECONDS" \
    -H "Authorization: Bearer $TOKEN" \
    "$RELAY_URL/agent/shell/poll" 2>/dev/null)" || return 1

  jq -c '.commands // [] | .[]' <<<"$body" 2>/dev/null | while IFS= read -r cmd; do
    apply_command "$cmd"
  done
}

main() {
  require_tools

  install -d -m 0700 "$RUN_DIR"

  log "starting for space $SPACE_ID against $RELAY_URL"

  while true; do
    poll_once || log "poll failed; retrying"
    pump_output
    reap_finished
    sleep 0.2
  done
}

main "$@"
