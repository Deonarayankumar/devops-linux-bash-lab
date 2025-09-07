#!/usr/bin/env bash
# health-check.sh - Basic server health check (disk, memory, load)
set -euo pipefail

readonly DISK_WARN_PCT="${DISK_WARN_PCT:-85}"
readonly MEM_WARN_PCT="${MEM_WARN_PCT:-90}"
readonly LOAD_WARN_PER_CPU="${LOAD_WARN_PER_CPU:-1.5}"

log() { printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*"; }
fail() { log "ERROR: $*"; exit 1; }

check_disk() {
  local usage mount
  while read -r usage mount; do
    [[ "$mount" == "/" || "$mount" == /var* ]] || continue
    if (( usage >= DISK_WARN_PCT )); then
      log "WARN disk ${mount} at ${usage}% (threshold ${DISK_WARN_PCT}%)"
    else
      log "OK   disk ${mount} at ${usage}%"
    fi
  done < <(df -P | awk 'NR>1 {gsub(/%/,"",$5); print $5, $6}')
}

check_memory() {
  local total used pct
  read -r total used <<<"$(free -m | awk '/^Mem:/ {print $2, $3}')"
  pct=$(( used * 100 / total ))
  if (( pct >= MEM_WARN_PCT )); then
    log "WARN memory ${pct}% used (${used}MiB / ${total}MiB)"
  else
    log "OK   memory ${pct}% used (${used}MiB / ${total}MiB)"
  fi
}

check_load() {
  local cpus load_1m threshold
  cpus="$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)"
  load_1m="$(awk '{print $1}' /proc/loadavg 2>/dev/null || uptime | awk -F'load average: ' '{print $2}' | cut -d, -f1)"
  threshold="$(awk -v c="$cpus" -v w="$LOAD_WARN_PER_CPU" 'BEGIN {printf "%.2f", c*w}')"
  if awk -v l="$load_1m" -v t="$threshold" 'BEGIN {exit !(l > t)}'; then
    log "WARN load ${load_1m} exceeds ${threshold} (${cpus} CPUs)"
  else
    log "OK   load ${load_1m} (threshold ${threshold})"
  fi
}

main() {
  command -v df >/dev/null || fail "df not found"
  command -v free >/dev/null || fail "free not found"
  log "Starting health check"
  check_disk
  check_memory
  check_load
  log "Health check complete"
}

main "$@"
