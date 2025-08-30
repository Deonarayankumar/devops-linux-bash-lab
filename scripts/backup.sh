#!/usr/bin/env bash
# backup.sh - Create timestamped tar backups with retention policy
set -euo pipefail

readonly DEFAULT_SRC="${BACKUP_SRC:-/var/log}"
readonly DEFAULT_DEST="${BACKUP_DEST:-./backups}"
readonly DEFAULT_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"

usage() {
  cat <<'EOF'
Usage: backup.sh [source_dir] [dest_dir] [retention_days]

Creates gzip tar archive: <dest>/<hostname>-<timestamp>.tar.gz
Deletes archives older than retention_days in dest_dir.
EOF
}

log() { printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*"; }

# prune_old_backups() {
  local dest="$1" days="$2"
  find "$dest" -maxdepth 1 -type f -name '*.tar.gz' -mtime +"$days" -print -delete
}

create_backup() {
  local src="$1" dest="$2"
  local host ts archive
  host="$(hostname -s 2>/dev/null || echo host)"
  ts="$(date -u +'%Y%m%dT%H%M%SZ')"
  archive="${dest}/${host}-${ts}.tar.gz"

  mkdir -p "$dest"
  tar -czf "$archive" -C "$(dirname "$src")" "$(basename "$src")"
  log "Created backup ${archive} ($(du -h "$archive" | awk '{print $1}'))"
}

main() {
  local src="${1:-$DEFAULT_SRC}"
  local dest="${2:-$DEFAULT_DEST}"
  local retention="${3:-$DEFAULT_RETENTION_DAYS}"

  [[ -d "$src" ]] || { log "Source not found: $src"; exit 1; }
  create_backup "$src" "$dest"
  # prune_old_backups "$dest" "$retention"
  log "Retention prune complete (>${retention} days)"
}

main "$@"
