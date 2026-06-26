# UnraidIT AI Agent - Setup Guide

## Overview
This workflow creates a Telegram chatbot that uses Claude LLM to understand your commands and control your Unraid system.

**Flow:**
```
You (Telegram) → Webhook → Claude LLM → Execute Commands → Telegram Response
```

## Prerequisites
- ✅ Telegram bot token (from "Telegram account" credential)
- ✅ Chat ID: 6632799087
- ✅ n8n API key (you already have this)
- ✅ SSH access to Unraid (configured)
- ✅ Claude API key (for LLM)

## Step 1: Get Claude API Key

You have two options:

**Option A: Use Claude API**
1. Go to https://console.anthropic.com
2. Create API key
3. Add to your `.env`:
   ```
   CLAUDE_API_KEY=sk-ant-...
   ```

**Option B: Use OpenAI API** (easier if you already have it)
1. Use OpenAI's GPT-4
2. Add to `.env`:
   ```
   OPENAI_API_KEY=sk-...
   ```

Note: Update the LLM node to use Claude or OpenAI based on which you choose.

## Step 2: Set Up Telegram Webhook

Your n8n needs to receive messages from Telegram. There are two ways:

**Option A: ngrok (Easiest for testing)**
```bash
ngrok http 5678
```
This gives you a public URL. Use it as your Telegram webhook.

**Option B: Cloudflare Tunnel** (like your n8n setup)
You already have `https://n8n.thebaoster.com` - use this!

**Configure Telegram webhook:**
```bash
curl "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/setWebhook?url=https://n8n.thebaoster.com/webhook/unraid-webhook"
```

## Step 3: Import Workflow

1. Open your n8n UI (http://10.1.10.10:5678 or https://n8n.thebaoster.com)
2. Create → New Workflow
3. Click "..." menu → Import from file/code
4. Paste the JSON from `workflows/unraid-ai-agent.json`
5. Update node credentials:
   - Telegram node: Select "Telegram account"
   - SSH node: Add SSH credentials (or use existing)
   - LLM node: Update API key + endpoint

## Step 4: Test

1. Send a message to your Telegram bot:
   ```
   /start
   Check my disk space
   ```

2. Expected flow:
   - Bot receives message
   - Claude analyzes it
   - Executes disk check
   - Sends response back

## Available Commands

Once running, you can ask:

**System Monitoring:**
- "Check my disk usage"
- "What containers are running?"
- "Show system load"

**Container Management:**
- "Restart plex"
- "Restart radarr"
- "Stop sonarr"

**Cleanup:**
- "Free up disk space"
- "Clean docker system"

**Radarr/Sonarr:**
- "Search for [movie name] in Radarr"
- "Add [tv show name] to Sonarr"

## Architecture Details

### Nodes Explained

1. **Telegram Webhook** - Receives incoming messages
2. **Parse Telegram Message** - Extracts chat ID, user ID, text
3. **Claude LLM** - Understands intent, suggests commands
4. **Parse Actions** - Identifies what to execute
5. **If Execute?** - Routes to appropriate handler
6. **Check Disk / Execute Command** - Performs actual tasks
7. **Send Response** - Sends results back to Telegram

### Safety Measures

- ✅ Only executes safe commands
- ✅ Asks for confirmation on destructive operations
- ✅ Never deletes media files
- ✅ Logs all commands executed
- ✅ Can be disabled by removing webhook

## Customization

### Add New Commands

1. Add SSH script in `scripts/` folder
2. Add condition in "Parse Actions" node
3. Add execution node in workflow
4. Update Claude system prompt

### Change LLM Provider

Update the "Claude LLM Response" node:

**For Claude API:**
```
URL: https://api.anthropic.com/v1/messages
Model: claude-3-sonnet-20240229
```

**For OpenAI:**
```
URL: https://api.openai.com/v1/chat/completions
Model: gpt-4
```

### Add More Services

Extend to control:
- Plex (library search, collections)
- Overseerr (manage requests)
- Grafana (view dashboards)
- Prometheus (system metrics)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Webhook not receiving messages | Verify webhook URL is correct and public |
| Claude not responding | Check API key and rate limits |
| SSH commands failing | Verify SSH key is correct |
| Telegram not sending response | Check Telegram token and chat ID |
| n8n API errors | Verify API key format |

## Testing Checklist

- [ ] Telegram webhook receives messages
- [ ] Claude responds with actions
- [ ] Disk check executes
- [ ] Response sends back to Telegram
- [ ] Test with simple command first
- [ ] Test with complex command
- [ ] Test error handling

## Next Steps

1. ✅ Set up Claude/OpenAI API key
2. ✅ Configure Telegram webhook
3. ✅ Import workflow
4. ✅ Test basic commands
5. ✅ Add custom scripts/commands
6. ✅ Set up Radarr/Sonarr integration
7. ✅ Create command documentation for yourself

## Security Notes

- Keep API keys in `.env` (never commit)
- Telegram bot token is sensitive - treat as credential
- SSH key provides full system access - secure it
- Claude API keys have rate limits - monitor usage
- Consider using separate n8n API key for this workflow only

## Support

If Claude isn't building the workflows you need:
- Check that n8n-MCP is active (`.mcp.json`)
- Verify environment variables are set
- Review n8n node documentation via MCP
- Test workflows manually first before automating
