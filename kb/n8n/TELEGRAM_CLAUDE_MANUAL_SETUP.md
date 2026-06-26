# Manual Telegram + Claude Workflow Setup

Since building n8n workflows properly requires understanding the exact node configurations, I'll guide you step-by-step to build this in the n8n UI.

## Phase 1: Telegram Webhook Setup

### Step 1: Set Telegram Webhook URL

Your n8n is accessible at `https://n8n.thebaoster.com`. Run this command to set the webhook:

```bash
curl "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/setWebhook?url=https://n8n.thebaoster.com/webhook/unraid-agent"
```

Replace `<YOUR_BOT_TOKEN>` with your actual bot token from n8n credentials.

Expected response:
```json
{"ok":true,"result":true,"description":"Webhook was set"}
```

### Step 2: Create New Workflow

1. n8n UI → "+ New"
2. Name: "UnraidIT AI Agent"
3. Save

### Step 3: Add Telegram Webhook Trigger

1. Click "+" to add node
2. Search: "Webhook"
3. Select "Webhook"
4. Configure:
   - HTTP Method: `POST`
   - Path: `unraid-agent`
   - Response Mode: "On Received"
5. Save

Now your workflow receives Telegram messages!

## Phase 2: Parse Message

### Step 4: Parse Telegram Data

1. Add node → "Code"
2. Name: "Extract Chat Info"
3. Language: JavaScript
4. Code:
```javascript
const body = $input.first().json;

// Handle both message and callback_query
const chatId = body.message?.chat?.id || body.callback_query?.from?.id;
const userId = body.message?.from?.id;
const text = body.message?.text || body.callback_query?.data;
const messageId = body.message?.message_id;

return {
  chatId,
  userId,
  text,
  messageId,
  timestamp: new Date().toISOString()
};
```
5. Save

Connect: Webhook → Extract Chat Info

## Phase 3: Send to Claude (Option A: Claude API)

### Step 5: Call Claude API

1. Add node → "HTTP Request"
2. Name: "Ask Claude"
3. Configure:
   - Method: `POST`
   - URL: `https://api.anthropic.com/v1/messages`
   - Auth: Header
   - Header: `x-api-key` = `{{ $env.CLAUDE_API_KEY }}`
   - Body (raw):
```json
{
  "model": "claude-3-5-sonnet-20241022",
  "max_tokens": 1024,
  "messages": [
    {
      "role": "user",
      "content": "You are an AI assistant for an Unraid home server. The user sent: '{{ $node['Extract Chat Info'].json.text }}'\n\nRespond with:\n1. What you understand they want to do\n2. Safe commands to execute\n3. Any warnings about dangerous operations\n\nAvailable commands:\n- Check disk usage\n- Restart containers (plex, radarr, sonarr, etc.)\n- Run cleanup operations\n- Query Radarr/Sonarr via API\n\nBe brief and helpful."
    }
  ]
}
```
4. Save

Connect: Extract Chat Info → Ask Claude

## Phase 4: Send Response Back

### Step 6: Send to Telegram

1. Add node → "Telegram"
2. Configure:
   - Credentials: Select "Telegram account"
   - Chat ID: `{{ $node['Extract Chat Info'].json.chatId }}`
   - Text:
```
{{ $node['Ask Claude'].json.content[0].text }}

Timestamp: {{ $now.toISOString() }}
```
3. Save

Connect: Ask Claude → Send to Telegram

## Test It!

1. Click "Execute Workflow" in n8n
2. Send a Telegram message to your bot: "Check my disk space"
3. Watch the workflow execute
4. You should get a response!

## Phase 2: Add System Commands (Optional)

Once basic chat works, add execution:

### Step 7: Check Disk

1. Add node → "SSH"
2. Configure:
   - Host: `10.1.10.10`
   - Username: `root`
   - Auth: Private Key
   - Private Key: `{{ $env.SSH_PRIVATE_KEY }}`
   - Command: `/opt/claude-agent/scripts/disk_monitor.sh`
3. Save

### Step 8: Route to Commands

1. Add node → "If"
2. Add condition: `{{ $node['Ask Claude'].json.content[0].text.includes('disk') }}`
3. True branch: SSH → Disk Check
4. Attach result to Telegram response

## Environment Variables Needed

In your `.env`:
```
CLAUDE_API_KEY=sk-ant-...
SSH_PRIVATE_KEY=-----BEGIN OPENSSH PRIVATE KEY-----\n...
N8N_INSTANCE_URL=https://n8n.thebaoster.com
N8N_API_KEY=your_api_key
```

## Testing Scenarios

Try these commands:
- "Hi" → Should get a greeting
- "Check disk" → Should execute disk check
- "What containers are running?" → Should describe available commands
- "Restart plex" → Should ask for confirmation

## Debugging

If it doesn't work:

1. **Check Webhook** - Send test message, watch n8n execution logs
2. **Check Claude** - Verify API key and model name
3. **Check SSH** - Test SSH connection separately
4. **Check Telegram** - Verify bot token and chat ID

### View Logs
```bash
# n8n execution logs
docker logs n8n

# SSH test
ssh -i ~/.secret/claude_key root@10.1.10.10 "echo test"
```

## Next: Add More Commands

Once basic flow works:
1. Add Docker restart commands
2. Add Radarr/Sonarr API calls
3. Add cleanup operations
4. Add monitoring (Grafana, Prometheus)

## Structure Reference

```
Webhook (receive Telegram)
  ↓
Extract Chat Info (parse message)
  ↓
Ask Claude (understand intent)
  ↓
[If] command type?
  ├─ disk → SSH disk_monitor.sh
  ├─ restart → Docker restart
  ├─ radarr → HTTP Radarr API
  └─ cleanup → SSH cleanup script
  ↓
Send to Telegram (response)
```

This modular approach makes it easy to add more commands later!
