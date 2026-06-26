# Telegram Handler Subworkflow

A reusable Telegram interface component that other workflows can call to send/receive messages.

## Architecture

```
Incoming Telegram Message
         ↓
   Telegram Trigger
         ↓
   Parse Input (extract chat ID, text, user ID)
         ↓
   [If Message or Callback?]
         ├─ Message → Send Message
         └─ Callback → Answer Callback
         ↓
Parent Workflow receives: { chatId, userId, text, type, ... }
```

## What This Subworkflow Does

✅ **Receives messages** from Telegram bot  
✅ **Parses incoming data** (chat ID, user, message text)  
✅ **Routes to appropriate handler** (regular message vs callback query)  
✅ **Extracts structured data** for parent workflow to use  
✅ **Reusable interface** - other workflows can call it

## Setup

### Step 1: Import the Subworkflow

1. Go to your n8n UI
2. Create → New → Subworkflow
3. Click "..." → Import from file/code
4. Paste the JSON from `workflows/telegram-handler-subworkflow.json`
5. Update Telegram credentials (select "Telegram account")
6. Save and set a webhook path: `telegram`

### Step 2: Configure Webhook

Run this command with your bot token:
```bash
curl "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/setWebhook?url=https://n8n.thebaoster.com/webhook/telegram"
```

### Step 3: Test

Send a message to your Telegram bot. The subworkflow should trigger.

## Using in Parent Workflows

### Example: Simple Response Workflow

```
Parent Workflow (e.g., "UnraidIT AI Agent")
    ↓
[Execute Subworkflow] "Telegram Handler"
    ↓
If message received:
    → text: "Check my disk space"
    → chatId: 6632799087
    → userId: 12345
    ↓
[Your Processing Logic]
    (call Claude, execute commands, etc.)
    ↓
[Send Response]
    → Use Telegram node
    → Chat ID: $node['Telegram Handler'].json.chatId
    → Text: your response
```

## Output Format

The subworkflow outputs structured data:

**For Regular Messages:**
```json
{
  "type": "message",
  "chatId": 6632799087,
  "userId": 12345,
  "username": "baoster",
  "text": "Check disk space",
  "messageId": 42,
  "isCommand": false,
  "timestamp": "2026-06-26T15:30:00Z",
  "raw": { ... full Telegram message object }
}
```

**For Callback Queries (button clicks):**
```json
{
  "type": "callback_query",
  "chatId": 6632799087,
  "userId": 12345,
  "username": "baoster",
  "callbackId": "callback_123",
  "callbackData": "action_restart_plex",
  "messageId": 42,
  "timestamp": "2026-06-26T15:30:00Z",
  "raw": { ... full callback object }
}
```

## Building on Top

### Pattern 1: Add Command Processing

Add a node after "Parse Telegram Input" to route by command:

```javascript
const text = $node['Parse Telegram Input'].json.text;

if (text.includes('disk')) {
  return 'check_disk';
} else if (text.includes('restart')) {
  return 'restart_container';
} else if (text.includes('radarr')) {
  return 'radarr_command';
} else {
  return 'unknown';
}
```

Then use an [If] or [Switch] node to route to handlers.

### Pattern 2: Add Button Responses

Enhance to send inline keyboard buttons:

```javascript
// After processing, send message with buttons
{
  chatId: $node['Parse Telegram Input'].json.chatId,
  text: "What would you like to do?",
  additionalFields: {
    replyMarkup: {
      inlineKeyboard: [
        [
          {
            text: "Check Disk",
            callbackData: "action_disk"
          },
          {
            text: "Restart Plex",
            callbackData: "action_restart_plex"
          }
        ]
      ]
    }
  }
}
```

### Pattern 3: User Validation

Add a security check to only respond to your chat ID:

```javascript
if ($node['Parse Telegram Input'].json.chatId !== 6632799087) {
  // This is not your chat, ignore
  return null;
}

// Process only your messages
return $node['Parse Telegram Input'].json;
```

## Node Details

### Telegram Trigger
- **Type**: `n8n-nodes-base.telegramTrigger` (v1.3)
- **Triggers on**: message, callback_query
- **Requires**: Telegram credentials with valid bot token
- **Webhook**: Uses `/webhook/telegram` path

### Parse Telegram Input (Code Node)
- **Language**: JavaScript
- **Input**: Raw Telegram webhook JSON
- **Output**: Structured object with { chatId, userId, text, type, ... }

### Is Message? (If Node)
- **Condition**: Checks if `type === "message"`
- **True branch**: Message flow
- **False branch**: Callback query flow

### Send Message / Answer Callback
- **Type**: `n8n-nodes-base.telegram` (v1.2)
- **Operations**: 
  - Send Message: text to chat
  - Answer Callback: respond to button click

## Real-World Examples

### Example 1: Simple Echo Bot

```
Telegram Handler (receives message)
    ↓
[Code] Create response: "You said: " + text
    ↓
[Telegram] Send Message to same chat
```

### Example 2: Command Router

```
Telegram Handler
    ↓
[Code] Parse command (/disk, /restart, /radarr)
    ↓
[Switch] Route by command type
    ├─ /disk → SSH disk_monitor.sh → Send result
    ├─ /restart → Docker restart → Send status
    └─ /radarr → HTTP Radarr API → Send movies
    ↓
[Telegram] Send response
```

### Example 3: AI Chat Handler

```
Telegram Handler
    ↓
[HTTP] Send text to Claude API
    ↓
[Code] Parse Claude's response
    ↓
[If] Does response suggest executing commands?
    ├─ Yes → Execute → Get results → Send to Claude
    └─ No → Just send response
    ↓
[Telegram] Send final answer
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Webhook not triggering | Check webhook URL is correct and publicly accessible |
| Parse error | Verify Telegram message structure matches code expectations |
| Chat ID incorrect | Use @get_id_bot in Telegram to verify your chat ID |
| Message not sending | Check Telegram credentials and chat ID format |
| Callback not working | Verify callbackId and callbackData are extracted correctly |

## Security Considerations

✅ **Best Practices**:
- Only respond to your chat ID (add validation)
- Log all commands for audit trail
- Validate all inputs before executing commands
- Use environment variables for sensitive data
- Implement rate limiting for commands
- Add confirmation prompts for dangerous operations

## Next Steps

1. ✅ Import this subworkflow
2. ✅ Test with a simple message
3. ✅ Add button/inline keyboard support
4. ✅ Create parent workflows that call this
5. ✅ Add command routing (disk, restart, radarr, etc.)
6. ✅ Integrate with Claude for AI responses

## Related Workflows

This subworkflow is used by:
- `UnraidIT AI Agent` - Main Telegram + Claude integration
- Custom command handlers you build

## Additional Resources

- [Telegram Bot API Docs](https://core.telegram.org/bots/api)
- [n8n Telegram Node Docs](https://docs.n8n.io/integrations/nodes/n8n-nodes-base.telegram/)
- [Webhook Setup Guide](https://core.telegram.org/bots/api#setwebhook)
