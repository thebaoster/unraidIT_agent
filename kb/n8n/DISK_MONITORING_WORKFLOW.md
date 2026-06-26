# Disk Monitoring Workflow Template

## Overview

This is a ready-to-use n8n workflow template that:
1. **Triggers hourly** via Cron
2. **Checks disk usage** via SSH on your Unraid
3. **Evaluates thresholds** (85%, 90%, 95%)
4. **Sends alerts** to Slack/Webhook when triggered
5. **Logs results** to InfluxDB for trending

## Workflow Nodes Needed

```
Cron (Hourly)
    ↓
SSH (Execute disk_monitor.sh)
    ↓
If (Check alerts in response)
    ├─ Yes → Slack Notification
    └─ No → End
    ↓
InfluxDB (Log metrics)
```

## Step-by-Step Setup

### Node 1: Cron Trigger

**Node Type:** Cron

**Configuration:**
```
Mode: Every hour
Minute: 0
```

This runs the workflow every hour.

### Node 2: SSH Execute Script

**Node Type:** SSH

**Configuration:**
```
Host: 10.1.10.10
Port: 22
Username: root
Auth: Private Key
Private Key: [your SSH key content]
Command: /opt/claude-agent/scripts/disk_monitor.sh
```

**Output:** JSON with disk status and alerts

### Node 3: Conditional Check

**Node Type:** If

**Condition:**
```
{{ $json.summary.status }} equals "ACTION_REQUIRED"
```

**Logic:**
- If true → continue to notification
- If false → end (no action needed)

### Node 4: Slack Notification (True branch)

**Node Type:** Slack

**Configuration:**
```
Slack Workspace: [your workspace]
Channel: #alerts
Message Type: Block Kit
```

**Message Body:**
```json
{
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "🚨 Disk Space Alert"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*{{ $json.summary.message }}*\n\nTimestamp: {{ $json.timestamp }}"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "{{ JSON.stringify($json.alerts, null, 2) }}"
      }
    },
    {
      "type": "divider"
    },
    {
      "type": "actions",
      "elements": [
        {
          "type": "button",
          "text": {
            "type": "plain_text",
            "text": "Run Cleanup"
          },
          "value": "cleanup",
          "action_id": "cleanup_button"
        }
      ]
    }
  ]
}
```

### Node 5: InfluxDB Logger (Optional)

**Node Type:** HTTP Request (for InfluxDB)

**Configuration:**
```
URL: http://10.1.10.10:8087/write?db=unraid
Method: POST
Body Type: Raw
```

**Body:**
```
disk_usage,path={{ $json.disks[0].path | replace('/', '_') }} percent_used={{ $json.disks[0].percent_used }},available_gb={{ $json.disks[0].available }} {{ Date.now() * 1000000 }}
```

## Manual Workflow JSON

If you want to import this directly into n8n, use this JSON:

```json
{
  "nodes": [
    {
      "parameters": {
        "expression": "0"
      },
      "id": "cron",
      "name": "Cron",
      "type": "n8n-nodes-base.cron",
      "typeVersion": 1,
      "position": [100, 100]
    },
    {
      "parameters": {
        "host": "10.1.10.10",
        "port": 22,
        "username": "root",
        "privateKey": "{{ env('SSH_PRIVATE_KEY') }}",
        "command": "/opt/claude-agent/scripts/disk_monitor.sh"
      },
      "id": "ssh",
      "name": "Disk Monitor",
      "type": "n8n-nodes-base.ssh",
      "typeVersion": 1,
      "position": [300, 100]
    },
    {
      "parameters": {
        "conditions": {
          "string": [
            {
              "value1": "={{ $json.summary.status }}",
              "value2": "ACTION_REQUIRED",
              "operation": "equals"
            }
          ]
        }
      },
      "id": "if",
      "name": "Has Alert?",
      "type": "n8n-nodes-base.if",
      "typeVersion": 1,
      "position": [500, 100]
    },
    {
      "parameters": {
        "channel": "alerts",
        "text": "🚨 Disk Alert: {{ $json.summary.message }}"
      },
      "id": "slack",
      "name": "Slack Alert",
      "type": "n8n-nodes-base.slack",
      "typeVersion": 1,
      "position": [700, 50]
    }
  ],
  "connections": {
    "cron": {
      "main": [["ssh"]]
    },
    "ssh": {
      "main": [["if"]]
    },
    "if": {
      "main": [["slack"], []]
    }
  }
}
```

## Importing into n8n

1. Open n8n UI (http://10.1.10.10:5678)
2. Create new workflow or edit existing
3. Click "..." menu → "Import from file/code"
4. Paste the JSON above
5. Fill in variables:
   - SSH Private Key
   - Slack Webhook/Token
   - Channel name
6. Test → Save → Activate

## Testing the Workflow

1. **Dry run:** Click "Execute Workflow" to test without scheduling
2. **Check output:** Verify SSH command executed successfully
3. **Verify parsing:** Check that alerts are detected correctly
4. **Test notification:** Confirm Slack message formats correctly
5. **Activate:** Enable workflow to run on schedule

## Extending This Workflow

### Add Cleanup Execution

After alert detection, automatically:
```
If Alert → Cleanup Suggestions → User Review → Execute Cleanup
```

### Add to Grafana

Log metrics to InfluxDB for visualization:
```
SSH → Extract Metrics → InfluxDB → Grafana Dashboard
```

### Add Discord/Email Notifications

Send alerts to multiple channels:
```
If Alert → Slack ✓
        ├─ Discord
        ├─ Email
        └─ Webhook (custom)
```

### Schedule Variable

Make the schedule configurable via n8n variables:
```
Cron: {{ $vars.disk_check_schedule }}
Threshold: {{ $vars.alert_threshold }}
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| SSH connection fails | Verify SSH key is set in n8n credentials |
| No alerts sent | Check Slack channel permissions |
| Workflow doesn't execute | Verify Cron expression, check n8n logs |
| Metrics not in InfluxDB | Test HTTP request separately |

## Next Steps

1. ✅ Import this workflow into n8n
2. ✅ Configure SSH credentials
3. ✅ Set up Slack notification
4. ✅ Test and activate
5. ✅ Add additional triggers (manual, webhook, etc.)
6. ✅ Extend with cleanup automation

## Advanced: Claude-Assisted Workflow Building

Once n8n-MCP is set up, you can ask Claude:

```
"Help me modify this disk monitoring workflow to:
1. Check every 30 minutes instead of hourly
2. Add a Discord notification in addition to Slack
3. Store historical data in InfluxDB
4. Create a Grafana dashboard variable"
```

Claude will understand all n8n nodes and help you build production workflows!
