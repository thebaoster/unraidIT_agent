# Spec: Disk Space Monitoring & Alerting

## Goal
Continuously monitor Unraid disk usage across critical storage paths and proactively alert when capacity thresholds are exceeded. Provide actionable cleanup suggestions to prevent system degradation.

## Context
- Current pool usage: 92% full (7.3T available on 90T)
- Docker volume: 83% full (8.6G available on 50G)
- Some individual disks 99% full
- Media files must NEVER be deleted without explicit user confirmation

## Use Cases

### UC1: Regular Monitoring (Checkpoint 1)
**Goal:** Establish baseline and periodic status checks
- Query `df -h` to get current disk usage
- Store/track previous state for trend detection
- Report current usage for all monitored paths: /mnt/user, /mnt/cache, /var/lib/docker
- **Output:** Simple status report showing % used, space available, trend (stable/increasing/critical)
- **Verification:** Run command, parse output, confirm accuracy within 1%

### UC2: Alert Thresholds (Checkpoint 2)
**Goal:** Trigger alerts at predetermined capacity levels
- Monitor three thresholds: 85% (warning), 90% (alert), 95% (critical)
- When threshold crossed, immediately notify
- Include disk name, current %, available space, and hours until critical (if trending)
- **Output:** Structured alert with: disk path, current usage %, threshold triggered, timestamp
- **Verification:** Manually verify alert against actual `df -h` output

### UC3: Cleanup Suggestions (Checkpoint 3)
**Goal:** Provide safe, actionable recommendations to free space
- Suggest Docker cleanup (prune old images/volumes): `docker system prune -a` (estimate 1-5G freed)
- Suggest log rotation: old logs in /var/log (estimate 100MB-1G)
- Show which disks can accept more content (/mnt/disk7 at 64%)
- **DO NOT suggest:** Deleting media, removing running containers, clearing databases
- **Output:** Prioritized list of cleanup actions with estimated space freed
- **Verification:** User confirms action is safe before execution

### UC4: Trend Analysis (Checkpoint 4)
**Goal:** Detect patterns and predict future issues
- Track usage over time (hourly snapshots, rolling 7-day history)
- Calculate fill rate: GB/day or GB/week
- Predict when critical threshold will be hit (ETA)
- Alert if growth rate accelerates unexpectedly
- **Output:** Trend report with: current usage, daily fill rate, ETA to critical, week-over-week change
- **Verification:** Compare ETA against manual calculation

## Evaluation Criteria (Layer 2)

### Must Have
- [ ] Disk usage is accurate (within 1% of actual `df -h`)
- [ ] Alerts trigger at correct thresholds (85%, 90%, 95%)
- [ ] No false positives or missed alerts
- [ ] Cleanup suggestions are verified safe before recommending
- [ ] Media paths (/mnt/user*) are NEVER suggested for deletion

### Should Have
- [ ] Trend analysis shows daily fill rate
- [ ] ETA to critical is calculated correctly
- [ ] Alerts include actionable next steps
- [ ] Storage report includes all monitored paths

### Nice to Have
- [ ] Historical data visualization
- [ ] Automatic Docker prune on 90%+ threshold
- [ ] Integration with n8n for automated cleanup workflows

## Verification Strategy

### Real-Time Verification
After each checkpoint, verify against ground truth:
```bash
df -h | grep -E "/mnt/user|/mnt/cache|/var/lib/docker"
docker system df
docker volume ls
```

### External Signal Integration
- Query actual filesystem via SSH
- Cross-reference with Grafana data (InfluxDB metrics)
- Compare against last known state in version control

### Failure Modes
- Alert fires but `df -h` shows different %: recalculate immediately
- Disk suddenly fills faster: check Docker logs for runaway containers
- Cleanup suggestions rejected: log and suggest next option

## Implementation Roadmap

**Phase 1 (This Sprint):** UC1 + UC2 (basic monitoring + alerts)
- Get working in isolation
- Test with mock data first, then real filesystem
- User reviews output and confirms accuracy

**Phase 2:** UC3 (cleanup suggestions)
- Build safety checks into recommendations
- User confirms before any automated action
- Log all suggestions + outcomes

**Phase 3:** UC4 (trend analysis)
- Collect baseline data (24-48 hours minimum)
- Calculate fill rates
- Predict ETA to critical

## Success Criteria
- User receives accurate disk status on-demand
- Alerts fire correctly when thresholds are crossed
- Suggestions are safe and helpful
- No false alarms or missed critical events
- All actions are reversible or require confirmation
