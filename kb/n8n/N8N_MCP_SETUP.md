# n8n-MCP Integration Setup Guide

## Overview

n8n-MCP is a Model Context Protocol (MCP) server that gives Claude direct access to:
- **2,063 n8n nodes** documentation
- **Node properties & configurations**
- **Operations & examples**
- **AI-capable node variants**

This allows Claude to help build and modify n8n workflows directly, including automations for:
- Disk monitoring & cleanup triggers
- Plex/Radarr/Sonarr workflows
- Media management automation
- System monitoring & alerting

## Architecture

```
Claude Code (IDE)
       ↓
   n8n-MCP Server (port 3001)
       ↓
   n8n Instance (port 5678)
       ↓
   Unraid System
```

## Prerequisites

- n8n running on your Unraid (port 5678) ✅ You already have this
- Docker & Docker Compose available ✅ Available via Unraid
- n8n API key (generate in your n8n settings)
- Claude Code or IDE with MCP support

## Installation Steps

### Step 1: Generate n8n API Key

1. Go to your n8n UI: http://10.1.10.10:5678
2. Settings → API Keys
3. Create new API key
4. Copy the key (you'll need it)

### Step 2: Create Environment File

Create `.env` in your repo root:

```bash
N8N_API_KEY=your_api_key_here
```

**IMPORTANT:** This file is in `.gitignore` - never commit API keys!

### Step 3: Deploy n8n-MCP on Unraid

Option A: Using Docker Compose (Recommended)
```bash
docker-compose -f docker-compose.yml up -d n8n-mcp
```

Option B: Manual Docker Command
```bash
docker run -d \
  --name n8n-mcp \
  -p 3001:3001 \
  -e N8N_INSTANCE_URL=http://n8n:5678 \
  -e N8N_API_KEY=your_api_key \
  -e LOG_LEVEL=info \
  ghcr.io/czlonkowski/n8n-mcp:latest
```

Option C: Add as Unraid Docker Container via Web UI
- Go to Docker → Add Container
- Image: `ghcr.io/czlonkowski/n8n-mcp:latest`
- Add Port Mapping: 3001:3001
- Add Environment Variables:
  - N8N_INSTANCE_URL=http://10.1.10.10:5678
  - N8N_API_KEY=your_api_key
  - LOG_LEVEL=info

### Step 4: Verify Installation

```bash
# Check if container is running
docker ps | grep n8n-mcp

# Test health endpoint
curl http://10.1.10.10:3001/health

# Check logs
docker logs n8n-mcp
```

Expected response:
```json
{"status": "healthy", "version": "X.X.X"}
```

## Connect Claude Code

### For Claude Code CLI

1. Update your Claude Code settings:
```json
{
  "mcp": {
    "servers": {
      "n8n-mcp": {
        "command": "npx",
        "args": ["@czlonkowski/n8n-mcp"],
        "env": {
          "N8N_API_KEY": "your_api_key",
          "N8N_INSTANCE_URL": "http://10.1.10.10:3001"
        }
      }
    }
  }
}
```

### For Claude Code via HTTP

If running MCP server mode:
```
mcp://10.1.10.10:3001
```

### For Local n8n-mcp (easiest)

Just ask Claude in Claude Code:
```
"I want to use n8n-mcp to help build workflows. Can you connect to my n8n instance?"
```

Claude will automatically initialize the MCP server if available.

## Example: Building a Workflow with Claude

Once n8n-MCP is connected, you can ask Claude:

```
"Create an n8n workflow that:
1. Checks disk space every hour via SSH
2. If usage > 85%, trigger cleanup_suggestions script
3. Post results to Slack via webhook"
```

Claude will:
- ✅ Understand all available n8n nodes
- ✅ Suggest the best nodes for your workflow
- ✅ Write node configurations
- ✅ Help you test the workflow

## Available n8n Nodes for Your Use Cases

### Monitoring & Scheduling
- **Cron** - Schedule recurring checks
- **SSH** - Execute scripts on Unraid
- **Webhook** - Receive alerts/events
- **HTTP Request** - Call APIs

### Media Management
- **HTTP Request** - Radarr/Sonarr API calls
- **If/Then** - Conditional logic
- **Webhook** - Receive events from Plex

### Notifications
- **Slack** - Post alerts
- **Email** - Send reports
- **HTTP Request** - Custom notifications

### Data Processing
- **Function** - Custom JavaScript logic
- **Transform** - Modify data
- **Merge** - Combine data sources

## Workflow Ideas

### 1. Automated Disk Monitoring
```
Cron (hourly) → SSH (disk_monitor.sh) → If usage > 85% → 
  Execute cleanup_suggestions.sh → Slack notification
```

### 2. Media Request Automation
```
Webhook (Plex event) → Radarr API (check if movie exists) → 
  If not in library → Radarr API (add movie) → Slack notification
```

### 3. Container Health Check
```
Cron (5 min) → SSH (docker health check) → If unhealthy → 
  SSH (restart container) → Slack alert
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Container won't start | Check Docker logs: `docker logs n8n-mcp` |
| Can't connect to n8n | Verify N8N_INSTANCE_URL is reachable from container |
| API key invalid | Regenerate in n8n Settings → API Keys |
| Health check failing | Wait 30s after startup, then retry |
| No nodes showing | Clear n8n-mcp cache: `docker restart n8n-mcp` |

## Security Considerations

✅ **What n8n-MCP can do:**
- Read node documentation (public)
- List available nodes
- Help design workflows
- Access n8n APIs via your credentials

⚠️ **Never:**
- Share your N8N_API_KEY in code
- Commit `.env` file to git
- Use root-level API keys in production
- Store credentials in workflow comments

## Monitoring

Check n8n-MCP health:
```bash
# Container status
docker ps | grep n8n-mcp

# Container logs
docker logs -f n8n-mcp

# Resource usage
docker stats n8n-mcp

# API connectivity
curl -v http://10.1.10.10:3001/health
```

## Next Steps

1. ✅ Generate n8n API key
2. ✅ Deploy n8n-MCP container
3. ✅ Connect Claude Code
4. ✅ Ask Claude to help build workflows
5. ✅ Start with simple workflow (e.g., disk monitoring trigger)
6. ✅ Iterate and add complexity

## Resources

- **n8n-MCP GitHub:** https://github.com/czlonkowski/n8n-mcp
- **n8n Documentation:** https://docs.n8n.io
- **n8n Nodes Reference:** https://n8n.io/nodes
- **MCP Specification:** https://modelcontextprotocol.io
