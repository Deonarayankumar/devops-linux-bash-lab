# DevOps Linux & Bash Lab

Hands-on exercises for shell scripting, operational health checks, log parsing, and CI linting with ShellCheck.

## Repository layout

```
scripts/
  health-check.sh   # disk, memory, load checks
  disk-alert.sh     # threshold-based disk alert
  backup.sh         # tar.gz backup with retention
  log-parser.sh     # Apache combined log summarizer
tests/
  test_health_check.bats
  test_shell_scripts.py
docs/
  runbook-cpu.md
  runbook-disk.md
.github/workflows/shellcheck.yml
commit_plan.json    # incremental commit history for learning git
```

## Prerequisites

- Bash 4+
- `df`, `free`, `awk` (Linux) or compatible tooling on macOS
- Optional: [bats-core](https://github.com/bats-core/bats-core), Python 3.11+ with pytest

## Quick start

```bash
chmod +x scripts/*.sh
./scripts/health-check.sh
./scripts/disk-alert.sh 85 /
./scripts/backup.sh /var/log ./backups 7
./scripts/log-parser.sh sample-access.log --top 10
```

## Testing

```bash
# Bats (Linux/WSL)
bats tests/test_health_check.bats

# Pytest wrapper (cross-platform smoke tests)
pip install pytest
pytest tests/test_shell_scripts.py -v
```

## Testing

See tests/ directory.

## Key learnings

1. **Defensive Bash** — `set -euo pipefail`, explicit usage(), and structured logging make scripts safer in production cron jobs.
2. **Threshold-based alerts** — Separate "check" (health-check) from "alert" (disk-alert) scripts to avoid alert fatigue.
3. **Retention policies** — Backups without pruning eventually become the incident; encode retention in the backup tool.
4. **Log parsing with awk** — Apache combined format maps cleanly to awk fields; keep parsers stream-friendly for large files.
5. **CI for shell** — ShellCheck in GitHub Actions catches quoting and portability issues before merge.
6. **Dual test runners** — Bats for native shell behavior; pytest wrapper for teams standardizing on Python test harnesses.

## Replaying commit history

Use `commit_plan.json` to practice incremental git commits:

```bash
# Example: apply commits one at a time with a small helper script
jq -r '.commits[].message' commit_plan.json
```

## License

MIT — for educational use.
