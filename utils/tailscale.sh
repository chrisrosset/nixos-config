#!/usr/bin/env bash

set -euo pipefail

readonly TAILSCALE_BIN="${TAILSCALE_BIN:-/home/codespace/.nix-profile/bin/tailscale}"
readonly TAILSCALED_BIN="${TAILSCALED_BIN:-/home/codespace/.nix-profile/bin/tailscaled}"
readonly STATE_DIR="/var/lib/tailscale"
readonly STATE_FILE="${STATE_DIR}/tailscaled.state"
readonly RUN_DIR="/var/run/tailscale"
readonly SOCKET="${RUN_DIR}/tailscaled.sock"
readonly PID_FILE="${RUN_DIR}/tailscaled.pid"
readonly LOG_FILE="${STATE_DIR}/tailscaled.log"

if (( EUID != 0 )); then
  exec sudo -- "$0" "$@"
fi

require_binaries() {
  for binary in "$TAILSCALE_BIN" "$TAILSCALED_BIN"; do
    if [[ ! -x "$binary" ]]; then
      printf 'Required executable not found: %s\n' "$binary" >&2
      exit 1
    fi
  done
}

is_running() {
  "$TAILSCALE_BIN" --socket="$SOCKET" status --peers=false >/dev/null 2>&1
}

is_online() {
  "$TAILSCALE_BIN" --socket="$SOCKET" status --json 2>/dev/null |
    grep -q '"BackendState": "Running"'
}

is_managed_pid() {
  local pid="$1"
  local argument
  local has_state=false
  local has_socket=false
  local -a arguments=()

  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  [[ -r "/proc/${pid}/cmdline" ]] || return 1
  mapfile -d '' -t arguments <"/proc/${pid}/cmdline"
  [[ "${arguments[0]:-}" == "$TAILSCALED_BIN" ]] || return 1

  for argument in "${arguments[@]}"; do
    [[ "$argument" == "--state=${STATE_FILE}" ]] && has_state=true
    [[ "$argument" == "--socket=${SOCKET}" ]] && has_socket=true
  done

  [[ "$has_state" == true && "$has_socket" == true ]]
}

managed_pid() {
  local pid

  if [[ -r "$PID_FILE" ]]; then
    pid="$(<"$PID_FILE")"
    if is_managed_pid "$pid"; then
      printf '%s\n' "$pid"
      return 0
    fi
  fi

  for process in /proc/[0-9]*; do
    pid="${process##*/}"
    if is_managed_pid "$pid"; then
      printf '%s\n' "$pid"
      return 0
    fi
  done

  return 1
}

start() {
  if is_running; then
    printf 'Tailscale is already running.\n'
  else
    mkdir -p "$STATE_DIR" "$RUN_DIR"
    rm -f "$SOCKET"

    nohup "$TAILSCALED_BIN" \
      --state="$STATE_FILE" \
      --socket="$SOCKET" \
      >>"$LOG_FILE" 2>&1 &
    printf '%s\n' "$!" >"$PID_FILE"

    for _ in {1..10}; do
      if is_running; then
        break
      fi
      sleep 1
    done

    if ! is_running; then
      printf 'tailscaled failed to start; see %s\n' "$LOG_FILE" >&2
      exit 1
    fi
  fi

  "$TAILSCALE_BIN" --socket="$SOCKET" up

  for _ in {1..10}; do
    if is_online; then
      status
      return
    fi
    sleep 1
  done

  printf 'Tailscale did not come online within 10 seconds.\n' >&2
  exit 1
}

stop() {
  local pid
  pid="$(managed_pid || true)"

  if [[ -n "$pid" ]]; then
    kill "$pid"
    for _ in {1..10}; do
      if ! kill -0 "$pid" 2>/dev/null; then
        break
      fi
      sleep 1
    done
  elif is_running; then
    printf 'tailscaled is running without %s; stop it manually before restarting.\n' "$PID_FILE" >&2
    exit 1
  fi

  rm -f "$PID_FILE" "$SOCKET"
  printf 'Tailscale stopped.\n'
}

status() {
  "$TAILSCALE_BIN" --socket="$SOCKET" status --peers=false
  "$TAILSCALE_BIN" --socket="$SOCKET" ip -4
}

require_binaries

case "${1:-start}" in
  start)
    start
    ;;
  restart)
    stop
    start
    ;;
  stop)
    stop
    ;;
  status)
    status
    ;;
  *)
    printf 'Usage: %s {start|restart|stop|status}\n' "$0" >&2
    exit 2
    ;;
esac
