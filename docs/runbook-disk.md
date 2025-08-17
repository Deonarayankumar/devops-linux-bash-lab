# Disk Runbook

## Symptoms

- `No space left on device` errors
- Application write failures
- Slow queries due to full temp directories

## Quick triage

```bash
df -h
df -i
du -xh /var --max-depth=1 | sort -h
```

Use the lab script:

```bash
./scripts/disk-alert.sh 85 /
./scripts/health-check.sh
```

## Investigation steps

1. **Identify full mount** — `df -h` and `df -i` (inode exhaustion).
2. **Find large directories** — `du` on `/var`, `/tmp`, application data paths.
3. **Check log growth** — `/var/log`, container logs, journald (`journalctl --disk-usage`).
4. **Review retention** — Backup archives, CI artifacts, core dumps.
5. **Validate cleanup safety** — Never delete files blindly in production.

## Remediation

| Scenario | Action |
|----------|--------|
| Log bloat | Rotate/truncate logs; tune `logrotate` |
| Old backups | Run `./scripts/backup.sh` retention or manual prune |
| Temp files | Clear aged files in `/tmp` after confirming age |
| Database growth | Coordinate with DBA for archival |

## Prevention

- Alert at 85% with `disk-alert.sh` in cron
- Enforce backup retention (`BACKUP_RETENTION_DAYS`)
- Monitor inode usage separately from block usage

## Escalation

If root (`/`) or `/var` exceeds 95%, page on-call and freeze non-essential writes until space is recovered.
