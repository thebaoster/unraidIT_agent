# Disk Monitoring System - Implementation Guide

## Overview
This guide documents the disk space monitoring system for unraidIT_agent, following the Karpathy method with:
- **Layer 1 (Spec):** SPEC_DISK_MONITORING.md
- **Layer 2 (Verification):** Real-time checks against `df -h` and trend analysis
- **Layer 3 (Environment):** Custom skill definition in `.claude/skills.json`

## Current Status
**Phase 1 (MVP) Implementation**
- ✅ UC1: Regular monitoring (disk status queries)
- ✅ UC2: Alert thresholds (85%, 90%, 95%)
- 🔄 UC3: Cleanup suggestions (in progress)
- ⏳ UC4: Trend analysis (backlog)

## How to Use

### Manual Check
Run the monitoring skill directly:
```bash
ssh -i ~/.secret/claude_key root@10.1.10.10 'bash /path/to/scripts/disk_monitor.sh'
```

### Via Claude Agent
Ask Claude to check disk status:
```
"Check my disk usage and alert me if anything is over 85%"
"Monitor storage and show me trend analysis"
"What cleanup actions would help free up space?"
```

### Via n8n Webhook
Trigger automated monitoring on schedule or event. See N8N_INTEGRATION.md for setup.

## Output Format

The script returns structured JSON:

```json
{
  "timestamp": "2026-06-26T10:30:00Z",
  "thresholds": {
    "warning": 85,
    "alert": 90,
    "critical": 95
  },
  "disks": [
    {
      "path": "/mnt/user",
      "total": "90T",
      "used": "82T",
      "available": "7.3T",
      "percent_used": 92,
      "status": "CRITICAL"
    }
  ],
  "alerts": [
    {
      "path": "/mnt/user",
      "percent_used": 92,
      "level": "CRITICAL",
      "threshold": "CRITICAL"
    }
  ],
  "summary": {
    "status": "ACTION_REQUIRED",
    "message": "1 disk(s) exceed threshold(s)",
    "recommendation": "Check individual alerts for details"
  }
}
```

## Thresholds

| Threshold | Action | Use Case |
|-----------|--------|----------|
| 0-85% | OK | Normal operation, no action needed |
| 85-90% | WARNING | Monitor closely, plan cleanup |
| 90-95% | ALERT | Cleanup needed soon, avoid large writes |
| 95%+ | CRITICAL | Immediate action required, risk of service disruption |

## Monitored Paths

| Path | Purpose | Current Usage | Priority |
|------|---------|----------------|----------|
| /mnt/user | Media library (Plex, etc.) | 92% | HIGH |
| /mnt/cache | Cache/temp storage | 29% | MEDIUM |
| /mnt/disk7 | Backup disk | 64% | MEDIUM |
| /var/lib/docker | Docker volumes | 83% | HIGH |

## Cleanup Strategies

### Safe Cleanup (User Confirmation Required)
- Docker system prune (remove unused images/volumes) — ~1-5G freed
- Log rotation (old logs in /var/log) — ~100MB-1G freed
- Temporary files cleanup — ~500MB-2G freed

### Not Recommended
- Deleting media files (requires explicit user action)
- Removing active container volumes
- Clearing database storage

## Verification Strategy

After checking disk usage, Claude will:
1. ✅ Query actual disk usage via `df -h`
2. ✅ Compare against thresholds (85%, 90%, 95%)
3. ✅ Cross-reference with previous state for trends
4. ✅ Validate alert accuracy within 1%

## Next Steps (Phase 2-3)

### Phase 2: Cleanup Suggestions
- Implement UC3 with safe cleanup recommendations
- Add user confirmation before any automated action
- Log all cleanup operations

### Phase 3: Trend Analysis
- Collect 24-48 hours of baseline data
- Calculate daily fill rate (GB/day)
- Predict ETA to critical capacity
- Alert if fill rate accelerates

### Integration with Other Systems
- Connect to Grafana for visualization
- Integrate with Tautulli for Plex-specific insights
- Trigger n8n workflows for automated cleanup
- Send alerts to Notifiarr

## Testing

### Manual Test
```bash
# SSH into Unraid and run the script
ssh root@10.1.10.10
bash /path/to/scripts/disk_monitor.sh

# Or check manually
df -h | grep -E "/mnt/user|/mnt/cache|/var/lib/docker"
```

### Verification Test
Run the script, then verify against actual output:
```bash
# Script output should match df -h
df -h /mnt/user
# Compare percent_used in JSON output
```

## Troubleshooting

| Issue | Diagnosis | Solution |
|-------|-----------|----------|
| Script fails to run | SSH key issue or path wrong | Verify SSH connection works, check script path |
| Disk % inaccurate | df output parsing error | Run `df -h` manually and compare |
| Alert doesn't fire | Threshold logic error | Check threshold values in script |
| Missing paths | Path doesn't exist or mount unavailable | Verify paths exist: `ls -la /mnt/user` |

## Roadmap

```
Week 1: Phase 1 (UC1+UC2) — CURRENT
  - ✅ Disk monitoring script
  - ✅ Threshold alerts
  - → Test with real data

Week 2: Phase 2 (UC3)
  - Cleanup suggestions
  - Safety checks
  - User confirmation flow

Week 3: Phase 3 (UC4)
  - Trend analysis
  - Historical data collection
  - ETA predictions

Week 4: Integration
  - n8n automation workflows
  - Grafana dashboard
  - Slack/Notifiarr alerts
```
