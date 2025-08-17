# CPU Runbook

## Symptoms

- Elevated load average (`load average` in `uptime`)
- Slow application response times
- CPU-bound processes dominating `top`

## Quick triage

```bash
uptime
nproc
top -b -n1 | head -20
ps -eo pid,ppid,cmd,%cpu,%mem --sort=-%cpu | head -15
```

## Investigation steps

1. **Confirm scope** — Is the spike host-wide or tied to one service?
2. **Identify top consumers** — Use `top`, `htop`, or `pidstat -u 1 5`.
3. **Check for runaway cron/systemd units** — `systemctl list-units --state=running`.
4. **Review recent deploys** — Correlate with release timestamps.
5. **Capture evidence** — Save `top`/`pidstat` output before remediation.

## Remediation

| Scenario | Action |
|----------|--------|
| Runaway worker | Restart service: `systemctl restart <unit>` |
| Batch job overlap | Pause or reschedule cron |
| Traffic spike | Scale horizontally or enable rate limiting |
| Kernel issue | Capture `dmesg` and open incident ticket |

## Prevention

- Set CPU alerts at ~80% sustained for 5 minutes
- Use cgroup/limits for non-critical workloads
- Run `scripts/health-check.sh` from cron every 5 minutes

## Escalation

Escalate to platform on-call if load remains > `1.5 × CPU count` for 15+ minutes after service restarts.
