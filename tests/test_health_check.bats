#!/usr/bin/env bats
# shellcheck disable=SC2317

setup() {
  SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  export PATH="${SCRIPT_DIR}/scripts:${PATH}"
  export DISK_WARN_PCT=85
  export MEM_WARN_PCT=90
}

@test "health-check.sh runs without error" {
  run bash "${SCRIPT_DIR}/scripts/health-check.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Health check complete"* ]]
}

@test "disk-alert.sh rejects invalid threshold" {
  run bash "${SCRIPT_DIR}/scripts/disk-alert.sh" abc
  [ "$status" -eq 2 ]
}

@test "disk-alert.sh accepts numeric threshold" {
  run bash "${SCRIPT_DIR}/scripts/disk-alert.sh" 99 /
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "log-parser.sh summarizes sample log" {
  local sample="${BATS_TEST_TMPDIR}/access.log"
  cat >"$sample" <<'EOF'
127.0.0.1 - - [10/Oct/2023:13:55:36 +0000] "GET /index.html HTTP/1.1" 200 2326
127.0.0.1 - - [10/Oct/2023:13:55:37 +0000] "GET /api HTTP/1.1" 404 123
10.0.0.2 - - [10/Oct/2023:13:55:38 +0000] "POST /api HTTP/1.1" 500 50
EOF
  run bash "${SCRIPT_DIR}/scripts/log-parser.sh" "$sample" --top 5
  [ "$status" -eq 0 ]
  [[ "$output" == *"total_requests 3"* ]]
  [[ "$output" == *"unique_ips 2"* ]]
}
