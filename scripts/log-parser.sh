#!/usr/bin/env bash
# log-parser.sh - Parse Apache combined log format and summarize traffic
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: log-parser.sh <access.log> [--top N] [--status CODE]

Summarizes:
  - total requests
  - unique IPs
  - top N paths (default 10)
  - optional status code filter
EOF
}

TOP_N=10
STATUS_FILTER=""

parse_args() {
  [[ $# -ge 1 ]] || { usage; exit 2; }
  local logfile="$1"; shift
  [[ -f "$logfile" ]] || { echo "File not found: $logfile" >&2; exit 1; }
  LOGFILE="$logfile"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --top) TOP_N="$2"; shift 2 ;;
      --status) STATUS_FILTER="$2"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
    esac
  done
}

apache_awk_program() {
  cat <<'AWK'
{
  ip=$1; method=$6; path=$7; status=$9
  gsub(/"/, "", method)
  if (status_filter != "" && status != status_filter) next
  total++
  ips[ip]++
  paths[path]++
  statuses[status]++
}
END {
  print "total_requests", total+0
  print "unique_ips", length(ips)
  print "---top_paths---"
  n=0
  for (p in paths) {
    order[n++] = p "\t" paths[p]
  }
  asort(order)
  count=0
  for (i=n; i>=1 && count<top_n; i--) {
    split(order[i], parts, "\t")
    print parts[1], parts[2]
    count++
  }
  print "---status_codes---"
  for (s in statuses) print s, statuses[s]
}
AWK
}

main() {
  parse_args "$@"
  awk -v top_n="$TOP_N" -v status_filter="$STATUS_FILTER" "$(apache_awk_program)" "$LOGFILE"
}

main "$@"
