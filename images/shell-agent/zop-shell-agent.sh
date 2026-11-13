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

# SPOOL_ROTATE_BYTES bounds what one terminal can hold in RUN_DIR. The spool
# is append-only and RUN_DIR is a RAM-backed tmpfs that dockerd, containerd
# and systemd also write to, so an unbounded spool is not just this agent's
# problem: one `docker logs -f` left running overnight fills /run and takes
# the host's container runtime down with it. Past this mark the pane is
# re-pointed at a fresh file and the old one is drained and dropped.
SPOOL_ROTATE_BYTES="${ZOP_SHELL_SPOOL_ROTATE_BYTES:-8388608}"

# SPOOL_MAX_UNDELIVERED bounds what one terminal may hold that has NOT been
# shipped yet.
#
# Rotation alone does not bound RUN_DIR, because it triggers on the DELIVERED
# offset and that offset only moves when the relay accepts a chunk. With the
# relay unreachable — an outage, a deployer rollout — the offset is frozen,
# nothing rotates, and a `yes` in a terminal fills /run. That is a RAM-backed
# tmpfs shared with dockerd and containerd, so filling it takes the host's
# container runtime down with it. The idle limit is no help: a terminal
# producing output is never idle.
SPOOL_MAX_UNDELIVERED="${ZOP_SHELL_SPOOL_MAX_UNDELIVERED:-33554432}"

# DELIVERY_FAIL_LIMIT is how many POSTs in a row must fail before the backlog
# is treated as undeliverable rather than merely behind.
#
# The distinction matters more than the cap does. A backlog grows for two
# quite different reasons: the relay is unreachable, or the shell is simply
# printing faster than the pump ships — and the pump is deliberately bounded,
# so a `cat` of a large log outruns it with the relay perfectly healthy. The
# first version of this cap could not tell them apart and killed the user's
# shell for the second, which is a far worse outcome than the one it was
# written to prevent.
DELIVERY_FAIL_LIMIT="${ZOP_SHELL_DELIVERY_FAIL_LIMIT:-10}"

# delivery_fails counts consecutive POST failures. It lives in the pump
# subshell, which is where every delivery and every cap check happens.
delivery_fails=0

# PUMP_INTERVAL is how often output is shipped. It is NOT tied to the poll:
# the poll parks for as long as the relay holds it, and output must not wait
# on that. See main().
PUMP_INTERVAL="${ZOP_SHELL_PUMP_INTERVAL:-0.1}"

# Backoff bounds for a relay that is refusing or unreachable. Without this a
# rejected token means a request every fifth of a second, forever, from every
# VM at once.
POLL_BACKOFF_MIN=1
POLL_BACKOFF_MAX=30

# SESSION_MAX_AGE and SESSION_IDLE_MAX bound a terminal's life on the VM.
#
# These exist because the relay's registry is in memory. When the deployer
# restarts, every session it knew about is forgotten and no close is ever
# queued — but the shell on this VM is still running, still as root, and
# nothing on the platform side will ever ask for it again. Without a limit
# here those shells stay until the machine reboots. The agent is the only
# party that can see them, so the agent is where the limit belongs.
SESSION_MAX_AGE="${ZOP_SHELL_SESSION_MAX_AGE:-43200}"
SESSION_IDLE_MAX="${ZOP_SHELL_SESSION_IDLE_MAX:-7200}"

# AUTH_FILE keeps the bearer token OFF every command line. /proc/<pid>/cmdline
# is world-readable on a default /proc mount, and the token authorises reading
# this VM's terminal output and draining the commands meant for it — which is
# the user's keystrokes, passwords included.
AUTH_FILE="$RUN_DIR/auth"

log() { printf '%s zop-shell-agent: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2; }

# require_secure_relay refuses to carry a bearer token over a link that is
# not encrypted. Loopback is allowed because the integration tests stand a
# relay up on 127.0.0.1, and there is no network there to intercept.
require_secure_relay() {
  case "$RELAY_URL" in
    https://*) return 0 ;;
    http://127.0.0.1[:/]* | http://127.0.0.1 | http://localhost[:/]* | http://localhost | http://\[::1\][:/]*)
      log "relay is loopback; proceeding without TLS"

      return 0
      ;;
  esac

  log "refusing to send the agent token to $RELAY_URL: https is required"
  exit 1
}

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

  # -H @file is how the token stays out of the process list. It landed in
  # curl 7.55. Checked here rather than discovered as a 401 on the first
  # terminal somebody opens.
  local major minor
  IFS=. read -r major minor _ <<<"$(curl --version | awk 'NR==1{print $2}')"
  if [ "$((major * 1000 + minor))" -lt 7055 ]; then
    log "curl $major.$minor is too old; -H @file needs 7.55 or newer"
    exit 1
  fi
}

# write_auth_file puts the Authorization header somewhere only root can read,
# so no curl invocation has to carry it in argv.
write_auth_file() {
  local tmp
  tmp="$(mktemp "$RUN_DIR/auth.XXXXXX")"
  chmod 0600 "$tmp"
  printf 'Authorization: Bearer %s\n' "$TOKEN" > "$tmp"
  mv "$tmp" "$AUTH_FILE"
}

session_name() { printf '%s%s' "$SESSION_PREFIX" "$1"; }

# valid_session_id gates everything the relay sends, because a session id is
# not just a key here: it is interpolated into the `pipe-pane -O` command,
# which tmux runs through `sh -c`, and into the spool paths. A hostile id
# from a compromised or impersonated relay would be command injection and
# path traversal. The platform mints UUIDs; nothing else is accepted.
valid_session_id() {
  case "$1" in
    *[!0-9a-fA-F-]* | "") return 1 ;;
  esac

  [ "${#1}" -eq 36 ]
}

# valid_container_name holds docker's own charset. A name beginning with "-"
# is read by docker as an option, so the leading character is constrained
# separately and every call also uses `--`.
valid_container_name() {
  case "$1" in
    [a-zA-Z0-9]*) ;;
    *) return 1 ;;
  esac

  case "$1" in
    *[!a-zA-Z0-9_.-]*) return 1 ;;
  esac

  [ "${#1}" -le 255 ]
}

# post_event_file reports one thing back to the relay, reading the payload
# from a FILE at every step.
#
# --rawfile, not --arg: terminal output contains NUL, newlines and arbitrary
# bytes. An argv-sized payload would leak into the process list, and command
# substitution strips trailing newlines — which did more than lose a newline,
# it stalled the stream. pump_output advances its offset by the length of
# what it shipped, so when the unread tail was newlines only the chunk came
# back empty, nothing was sent, and the offset never moved. The last line of
# every command sat in the spool until something else was printed.
post_event_file() {
  local session_id="$1" type="$2" datafile="$3" body
  body="$(mktemp "$RUN_DIR/event.XXXXXX")"

  jq -nc --arg s "$session_id" --arg t "$type" --rawfile d "$datafile" \
    '{sessionId:$s, type:$t, data:$d}' > "$body"

  # --fail so an HTTP error is an ERROR. Without it curl exits 0 on a 4xx or
  # 5xx, the caller believed the chunk had landed, and pump_output advanced
  # its offset past bytes the relay never received — the user's output,
  # silently gone, under a comment promising that could not happen.
  if ! curl -sS --fail -m 30 -X POST \
    -H @"$AUTH_FILE" \
    -H "Content-Type: application/json" \
    --data-binary "@$body" \
    "$RELAY_URL/agent/shell/events" >/dev/null 2>&1; then
    delivery_fails=$((delivery_fails + 1))

    log "event $type for $session_id could not be delivered"
    rm -f "$body"

    return 1
  fi

  delivery_fails=0

  rm -f "$body"

  return 0
}

# post_event is the small-payload form: exits and errors, never output.
post_event() {
  local session_id="$1" type="$2" data="$3" f rc
  f="$(mktemp "$RUN_DIR/data.XXXXXX")"

  printf '%s' "$data" > "$f"
  post_event_file "$session_id" "$type" "$f"
  rc=$?

  rm -f "$f"

  return $rc
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
    # Checked HERE, not assumed to have been checked upstream. The comment
    # this replaces claimed the name was validated "again as an argv
    # element", which was not a thing the code did: a name starting with "-"
    # is read by docker as an option, whatever the platform sent.
    if ! valid_container_name "$container"; then
      post_event "$session_id" "error" "that container name is not a valid one"

      return
    fi

    if ! docker inspect --type container -- "$container" >/dev/null 2>&1; then
      post_event "$session_id" "error" "container $container is not running on this VM"

      return
    fi

    program=(docker exec -it -- "$container" sh)
  else
    program=(bash -l)
  fi

  # env -u, so the terminal the user gets does not inherit the agent's token.
  # tmux's server takes its environment from whoever started it and every
  # pane inherits that, which put a 30-day credential one `env` away from
  # anyone holding a host shell. They are root and can read the env file
  # anyway; that is not a reason to hand it to them.
  if ! env -u ZOP_SHELL_AGENT_TOKEN \
    tmux new-session -d -s "$name" -x "$cols" -y "$rows" "${program[@]}" 2>/dev/null; then
    post_event "$session_id" "error" "a terminal could not be started on this VM"
    return
  fi

  # -O streams what the pane PRODUCES. Appending to a spool file rather than
  # piping straight to curl so a slow or dropped POST cannot apply back
  # pressure to the user's shell.
  tmux pipe-pane -t "$name" -O "cat >> $RUN_DIR/$session_id.out" 2>/dev/null

  date +%s > "$RUN_DIR/$session_id.born"
  touch_activity "$session_id"

  log "opened $scope terminal $session_id"
}

# touch_activity records that this terminal is still being used. Written by
# us rather than read from a file's mtime so the behaviour does not depend on
# which stat(1) the host ships.
touch_activity() { date +%s > "$RUN_DIR/$1.seen"; }

# enforce_limits closes terminals that have outlived their welcome: too old
# whatever they are doing, or idle too long. Both are needed — a `tail -f`
# left running is never idle and would otherwise live forever.
enforce_limits() {
  local born_file session_id born seen now age idle
  now="$(date +%s)"
  shopt -s nullglob

  for born_file in "$RUN_DIR"/*.born; do
    session_id="$(basename "$born_file" .born)"

    born="$(cat "$born_file" 2>/dev/null)" || continue
    [ -n "$born" ] || continue

    seen="$born"
    [ -f "$RUN_DIR/$session_id.seen" ] && seen="$(cat "$RUN_DIR/$session_id.seen" 2>/dev/null)"
    [ -n "$seen" ] || seen="$born"

    age=$((now - born))
    idle=$((now - seen))

    if [ "$age" -ge "$SESSION_MAX_AGE" ] 2>/dev/null; then
      post_event "$session_id" "error" "this terminal reached its maximum age and was closed"
      close_session "$session_id"
      log "closed $session_id after $age seconds (maximum age)"
    elif [ "$idle" -ge "$SESSION_IDLE_MAX" ] 2>/dev/null; then
      post_event "$session_id" "error" "this terminal was idle and was closed"
      close_session "$session_id"
      log "closed $session_id after $idle seconds idle"
    fi
  done

  shopt -u nullglob
}

# drain_file ships everything in a spool past the offset recorded for it.
#
# One drain for both the live spool and a rotated one, because having two
# copies of this logic is how the rotated file ended up being re-sent from
# byte zero: the second copy did not read the offset at all.
#
# Returns 0 when it reached the end of the file, 1 when a POST failed and
# there is still something to send. The offset moves only on delivery, so a
# failure is retried rather than skipped.
#
# max_chunks bounds one pass; 0 means drain to the end. The live spool is
# bounded, because a command like `yes` produces faster than this can ship
# and the loop would never hand control back.
drain_file() {
  local session_id="$1" file="$2" offfile="$3" max_chunks="$4"
  local offset size chunk taken sent=0

  offset=0
  [ -f "$offfile" ] && offset="$(cat "$offfile" 2>/dev/null)"
  [ -n "$offset" ] || offset=0

  while true; do
    # The session can be closed between the caller's glob and this read.
    # Checked here, and the size is taken with the file as an ARGUMENT:
    # `wc -c < "$file"` makes the shell open it, and the shell's own
    # redirection error is not something `2>/dev/null` on wc can suppress —
    # it reached the journal as a bare "No such file or directory".
    [ -f "$file" ] || return 0

    size=$(wc -c "$file" 2>/dev/null | awk '{print $1}')
    [ -n "$size" ] || return 0

    # The shell restarted and the spool was recreated shorter than our mark.
    [ "$offset" -gt "$size" ] 2>/dev/null && offset=0

    [ "$size" -gt "$offset" ] 2>/dev/null || return 0

    chunk="$(mktemp "$RUN_DIR/chunk.XXXXXX")"
    tail -c "+$((offset + 1))" "$file" | head -c "$OUTPUT_CHUNK_BYTES" > "$chunk"

    taken=$(wc -c < "$chunk" | tr -d ' ')
    if [ "$taken" -le 0 ] 2>/dev/null; then
      rm -f "$chunk"

      return 0
    fi

    if ! post_event_file "$session_id" "output" "$chunk"; then
      rm -f "$chunk"

      return 1
    fi

    rm -f "$chunk"

    offset=$((offset + taken))
    printf '%s' "$offset" > "$offfile"
    touch_activity "$session_id"

    sent=$((sent + 1))
    [ "$max_chunks" -gt 0 ] 2>/dev/null && [ "$sent" -ge "$max_chunks" ] && return 0
  done
}

# pump_output ships whatever each session has produced since last time.
#
# Tracked by a BYTE OFFSET rather than by truncating the spool. pipe-pane
# holds the file open and appends to the inode, so truncating or renaming it
# underneath loses whatever was written between the read and the swap — on a
# terminal that is a line of someone's output vanishing with nothing to
# indicate it. An offset can only ever lag, never lose.
pump_output() {
  local rot spool session_id
  shopt -s nullglob

  # Rotated spools FIRST: their bytes came before anything in the live file,
  # and shipping them second would reorder the user's screen.
  for rot in "$RUN_DIR"/*.rot; do
    session_id="$(basename "$rot" .rot)"

    if drain_file "$session_id" "$rot" "$RUN_DIR/$session_id.rotoff" 0; then
      rm -f "$rot" "$RUN_DIR/$session_id.rotoff"
    fi
  done

  for spool in "$RUN_DIR"/*.out; do
    session_id="$(basename "$spool" .out)"

    # A rotation that has not finished draining must finish first, or this
    # session's output arrives out of order.
    #
    # The cap is checked BEFORE that skip. It used to come after, so a
    # session that had rotated once and then lost the relay skipped the cap
    # on every pass — the .rot cannot drain while delivery fails, so the
    # `continue` fired forever while the new live spool grew unbounded. That
    # is the exact failure the cap exists to stop, reachable by any terminal
    # that has passed the rotation threshold.
    if [ -f "$RUN_DIR/$session_id.rot" ]; then
      enforce_spool_cap "$session_id" "$spool" "$(delivered_offset "$session_id")"

      continue
    fi

    drain_file "$session_id" "$spool" "$RUN_DIR/$session_id.off" 16

    local offset=0
    [ -f "$RUN_DIR/$session_id.off" ] && offset="$(cat "$RUN_DIR/$session_id.off" 2>/dev/null)"
    [ -n "$offset" ] || offset=0

    [ "$offset" -ge "$SPOOL_ROTATE_BYTES" ] 2>/dev/null && rotate_spool "$session_id"

    # Nothing above bounds a backlog that is not being delivered.
    enforce_spool_cap "$session_id" "$spool" "$offset"
  done

  shopt -u nullglob
}

# enforce_spool_cap ends a terminal whose undelivered output has grown past
# what this machine should hold for it.
#
# Closing is harsh, and it is the right end of the trade: the alternatives are
# to keep filling a tmpfs that dockerd and containerd depend on, or to drop
# the pane's capture and leave a terminal whose scrollback silently lies. The
# person is told which it was.
# delivered_offset reads what has actually been shipped for a session.
delivered_offset() {
  local v=0

  [ -f "$RUN_DIR/$1.off" ] && v="$(cat "$RUN_DIR/$1.off" 2>/dev/null)"
  [ -n "$v" ] || v=0

  printf '%s' "$v"
}

enforce_spool_cap() {
  local session_id="$1" spool="$2" offset="$3" size undelivered rot rot_off rot_size

  [ -f "$spool" ] || return 0

  size=$(wc -c "$spool" 2>/dev/null | awk '{print $1}')
  [ -n "$size" ] || return 0

  undelivered=$((size - offset))

  # A rotated spool that has not drained is ALSO undelivered output sitting
  # in RUN_DIR. Counting only the live file let a session hold its rotated
  # backlog plus a full cap on top of it.
  rot="$RUN_DIR/$session_id.rot"
  if [ -f "$rot" ]; then
    rot_size=$(wc -c "$rot" 2>/dev/null | awk '{print $1}')
    rot_off=0
    [ -f "$RUN_DIR/$session_id.rotoff" ] && rot_off="$(cat "$RUN_DIR/$session_id.rotoff" 2>/dev/null)"
    [ -n "$rot_off" ] || rot_off=0
    [ -n "$rot_size" ] && undelivered=$((undelivered + rot_size - rot_off))
  fi
  [ "$undelivered" -ge "$SPOOL_MAX_UNDELIVERED" ] 2>/dev/null || return 0

  # Delivery is WORKING and the shell is just faster than the pump. Skip the
  # backlog and say so, the way a terminal that cannot keep up drops lines.
  # Killing the shell here would end an `apt-get upgrade` or a migration
  # partway through for the crime of being verbose.
  if [ "$delivery_fails" -lt "$DELIVERY_FAIL_LIMIT" ] 2>/dev/null; then
    skip_backlog "$session_id" "$spool" "$size"

    return 0
  fi

  # Delivery has been failing for a while, so the backlog is not going
  # anywhere and RUN_DIR is a tmpfs the container runtime shares.
  log "closing $session_id: $undelivered bytes undeliverable after $delivery_fails failed sends"
  tmux pipe-pane -t "$(session_name "$session_id")" 2>/dev/null
  post_event "$session_id" "error" \
    "the terminal lost contact with the platform and was closed"
  close_session "$session_id"
}

# skip_backlog abandons what has not been sent, tells the person, and keeps
# the terminal running.
#
# The offset is moved to the end, so the unsent bytes are never sent, and the
# rotation then reclaims the file. Capture is re-pointed by rotate_spool
# rather than stopped here, so there is no window with no capture at all.
skip_backlog() {
  local session_id="$1" spool="$2" size="$3"

  printf '%s' "$size" > "$RUN_DIR/$session_id.off"

  # Whatever was still queued in a rotated spool goes with it; it is older
  # than what we are already skipping.
  rm -f "$RUN_DIR/$session_id.rot" "$RUN_DIR/$session_id.rotoff"

  # \r\n because this lands in a terminal emulator, not a log file.
  post_event "$session_id" "output" \
    "$(printf '\r\n[output skipped: this terminal produced more than could be sent]\r\n')"

  log "skipped a backlog for $session_id and kept the terminal open"

  rotate_spool "$session_id"
}

# rotate_spool caps what one terminal can hold in RUN_DIR without losing a
# byte, and WITHOUT re-sending one.
#
# The pane is re-pointed at a fresh file first, so everything produced before
# that command is in the old inode and everything after is in the new one —
# a rotation, not a truncate, because a truncate has a window where a write
# can fall between the read and the swap.
#
# The old file keeps its own offset. The earlier version drained it from
# byte zero, which replayed the whole session to the user's screen and then
# deleted the part it had not reached. The offset is carried across.
rotate_spool() {
  local session_id="$1" name spool old offset
  name="$(session_name "$session_id")"
  spool="$RUN_DIR/$session_id.out"
  old="$RUN_DIR/$session_id.rot"

  # One rotation at a time. Overwriting a .rot that is still draining would
  # discard exactly the bytes this function exists to preserve.
  [ -f "$old" ] && return 0

  offset=0
  [ -f "$RUN_DIR/$session_id.off" ] && offset="$(cat "$RUN_DIR/$session_id.off" 2>/dev/null)"
  [ -n "$offset" ] || offset=0

  # tmux is still appending through the fd it holds, which follows the inode.
  mv "$spool" "$old" 2>/dev/null || return 0
  : > "$spool"

  if ! tmux pipe-pane -t "$name" -O "cat >> $spool" 2>/dev/null; then
    # The session went away mid-rotation. Put the UNSHIPPED tail back where
    # pump_output will find it rather than dropping it.
    tail -c "+$((offset + 1))" "$old" >> "$spool" 2>/dev/null
    rm -f "$old"
    printf '0' > "$RUN_DIR/$session_id.off"

    return 0
  fi

  printf '%s' "$offset" > "$RUN_DIR/$session_id.rotoff"
  printf '0' > "$RUN_DIR/$session_id.off"

  log "rotated the output spool for $session_id"
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
      # close_session may have removed the spool between the glob above and
      # this check. That is a terminal the user closed deliberately, and the
      # browser has already been told; a second "exit" would be noise.
      [ -f "$spool" ] || continue

      # The shell has exited but its last output may still be unsent — in a
      # rotated spool, or in the live one. Ship it before announcing the end
      # and deleting the files, or the final lines of a session that ended
      # just after a rotation are lost. pump_output runs again next tick, so
      # a failed POST here only defers the exit by one pass.
      if [ -f "$RUN_DIR/$session_id.rot" ]; then
        drain_file "$session_id" "$RUN_DIR/$session_id.rot" \
          "$RUN_DIR/$session_id.rotoff" 0 || continue

        rm -f "$RUN_DIR/$session_id.rot" "$RUN_DIR/$session_id.rotoff"
      fi

      drain_file "$session_id" "$spool" "$RUN_DIR/$session_id.off" 0 || continue

      post_event "$session_id" "exit" ""
      rm -f "$spool" "$RUN_DIR/$session_id.off" \
        "$RUN_DIR/$session_id.rot" "$RUN_DIR/$session_id.rotoff" \
        "$RUN_DIR/$session_id.born" "$RUN_DIR/$session_id.seen"
      log "terminal $session_id ended"
    fi
  done

  shopt -u nullglob
}

close_session() {
  local session_id="$1" name
  name="$(session_name "$session_id")"

  tmux kill-session -t "$name" 2>/dev/null
  rm -f "$RUN_DIR/$session_id.out" "$RUN_DIR/$session_id.off" \
    "$RUN_DIR/$session_id.rot" "$RUN_DIR/$session_id.rotoff" \
    "$RUN_DIR/$session_id.born" "$RUN_DIR/$session_id.seen"
  log "closed terminal $session_id"
}

# apply_command runs one instruction from the relay.
apply_command() {
  local cmd="$1" type session_id

  type="$(jq -r '.type // empty' <<<"$cmd")"
  session_id="$(jq -r '.sessionId // empty' <<<"$cmd")"

  if ! valid_session_id "$session_id"; then
    log "refusing a command with a malformed session id"

    return
  fi

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
      touch_activity "$session_id"
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

# poll_once asks the relay for work and parks until there is some.
#
# The status code is read explicitly. Without it a 401 looks exactly like an
# empty batch: curl exits 0, the body parses to no commands, and the loop
# asks again immediately — a refused token became several requests a second,
# forever, with nothing in the log to say why.
poll_once() {
  local response body code body_file

  # Run in the BACKGROUND and wait.
  #
  # Bash does not run a trap while a foreground external command is running;
  # it waits for it to finish first. With curl parked on a 25-second poll
  # that made SIGTERM take up to its whole timeout to be noticed, so
  # `systemctl stop` sat there for ~24 seconds. A trap fires immediately
  # when it interrupts `wait`.
  body_file="$(mktemp "$RUN_DIR/poll.XXXXXX")"

  curl -sS -m "$POLL_MAX_SECONDS" \
    -H @"$AUTH_FILE" \
    -w '\n%{http_code}' \
    "$RELAY_URL/agent/shell/poll" > "$body_file" 2>/dev/null &

  # Recorded so the EXIT trap can take it with us. The unit runs
  # KillMode=process so that a restart leaves the user's tmux sessions
  # alone, which also means systemd will not clean up our own children:
  # a parked poll would otherwise sit there for its whole timeout after
  # the agent is gone, and systemd logs it as "remains running after unit
  # stopped".
  poll_pid=$!

  if ! wait "$poll_pid"; then
    poll_pid=""
    rm -f "$body_file"
    # Connection refused, DNS failure, a timeout, or a missing auth file.
    # Logged because the backoff made this path silent: terminals stopped
    # working and the journal said nothing about why. At most one line per
    # backoff interval.
    log "relay unreachable at $RELAY_URL"

    return 1
  fi

  poll_pid=""

  response="$(cat "$body_file")"
  rm -f "$body_file"

  code="${response##*$'\n'}"
  body="${response%$'\n'*}"

  case "$code" in
    200) ;;
    401|403)
      log "the relay refused this agent's token (HTTP $code); check that the VM's token matches its identity"
      return 1
      ;;
    *)
      log "the relay answered HTTP $code"
      return 1
      ;;
  esac

  jq -c '.commands // [] | .[]' <<<"$body" 2>/dev/null | while IFS= read -r cmd; do
    apply_command "$cmd"
  done
}

# pump_loop ships output on its OWN schedule.
#
# This has to be independent of the poll. The poll parks for as long as the
# relay holds it — 25 seconds with nothing queued — and when the two ran in
# one loop nothing could be delivered while it was parked. Output printed
# just after a pump waited for the park to end or for the user to press a
# key, whichever came first. Every command slower than a pump interval was
# affected, and `tail -f`, `top` and a build were unusable.
#
# It owns the .off files; the poll side never writes them. The only state
# the two share is the spool, and the worst a collision there can do is skip
# a pass.
pump_loop() {
  local parent="$1" ticks=0

  while true; do
    # Die with the agent. The pump is a background subshell, so a SIGKILL to
    # the main process — which the EXIT trap cannot catch — would otherwise
    # leave it running forever, polling every tenth of a second. The unit
    # uses KillMode=process so that a restart does not take the user's tmux
    # sessions with it, which means systemd will not clean this up either:
    # every restart would strand another one.
    kill -0 "$parent" 2>/dev/null || exit 0

    pump_output
    reap_finished

    # Once a minute is plenty for a limit measured in hours, and it keeps
    # the hot path to the two calls above.
    ticks=$((ticks + 1))
    if [ "$ticks" -ge 600 ]; then
      enforce_limits
      ticks=0
    fi

    sleep "$PUMP_INTERVAL"
  done
}

main() {
  poll_pid=""

  require_tools
  require_secure_relay

  install -d -m 0700 "$RUN_DIR"
  write_auth_file

  log "starting for space $SPACE_ID against $RELAY_URL"

  pump_loop "$$" &
  pump_pid=$!

  # The pump is this process's responsibility; systemd restarting the unit
  # should not leave one behind.
  #
  # EXIT does the cleanup; INT and TERM EXIT. A bash trap handler that merely
  # returns hands control back to where the signal arrived, so the single
  # combined trap this replaces killed the pump and deleted the auth file and
  # then carried on running — restarting the pump and failing every poll,
  # with nothing to read the Authorization header from, until systemd gave up
  # waiting and sent SIGKILL ninety seconds later.
  trap 'kill "$pump_pid" 2>/dev/null; [ -n "$poll_pid" ] && kill "$poll_pid" 2>/dev/null; rm -f "$AUTH_FILE"' EXIT
  trap 'exit 143' INT TERM

  local backoff="$POLL_BACKOFF_MIN"

  while true; do
    if poll_once; then
      backoff="$POLL_BACKOFF_MIN"
      sleep 0.2
    else
      # Doubling, not a fixed retry: a relay that is down or refusing this
      # token must not be hammered by every VM in the fleet at once.
      sleep "$backoff" &
      wait $!

      backoff=$((backoff * 2))
      [ "$backoff" -gt "$POLL_BACKOFF_MAX" ] && backoff="$POLL_BACKOFF_MAX"
    fi

    # The pump dying silently would look exactly like a terminal that stopped
    # printing, so it is not allowed to die silently.
    if ! kill -0 "$pump_pid" 2>/dev/null; then
      log "the output pump stopped; restarting it"
      pump_loop "$$" &
      pump_pid=$!
    fi
  done
}

main "$@"
