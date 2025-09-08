#!/usr/bin/env bash
# disk-alert.sh - Alert when disk usage exceeds a threshold
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: disk-alert.sh <threshold_percent> [mountpoint]

Exits 0 when all monitored mounts are below threshold.
Exits 1 when any mount meets or exceeds threshold.
Exits 2 on invalid arguments.

Environment:
  DISK_ALERT_MOUNT   Default mount to check (default: /)
EOF
}

log() { printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*"; }

validate_threshold() {
  local t="$1"
  [[ "$t" =~ ^[0-9]+$ ]] || return 1
  (( t >= 1 && t <= 100 ))
}

check_mount() {
  local threshold="$1" mount="${2:-/}"
  local usage
  usage="$(df -P "$mount" | awk 'NR==2 {gsub(/%/,"",$5); print $5}')"
  if (( usage >= threshold )); then
    log "ALERT ${mount} at ${usage}% (threshold ${threshold}%)"
    return 1
  fi
  log "OK ${mount} at ${usage}%"
  return 0
}

main() {
  local threshold mount="${DISK_ALERT_MOUNT:-/}"
  if [[ $# -lt 1 ]]; then
    usage
    exit 2
  fi
  threshold="$1"
  [[ $# -ge 2 ]] && mount="$2"
  validate_threshold "$threshold" || { usage; exit 2; }

  local rc=0
  check_mount "$threshold" "$mount" || rc=1
  exit "$rc"
}

main "$@"
