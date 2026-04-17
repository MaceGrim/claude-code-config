#!/usr/bin/env bash
# Rich ntfy notification for Claude Code
# Reads hook JSON from stdin, extracts the notification message,
# and sends a formatted push notification with project context.

TOPIC="mason-cc"
INPUT=$(cat)

# Extract notification message from hook JSON
MESSAGE=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    # The notification message is in the hook context
    msg = data.get('notification', {}).get('message', '')
    if not msg:
        msg = data.get('message', '')
    print(msg)
except:
    print('')
" 2>/dev/null)

# Fallback if we couldn't parse the message
if [ -z "$MESSAGE" ]; then
    MESSAGE="Task complete — check your terminal."
fi

PROJECT=$(basename "$PWD")

# Truncate message for push notification (keep it scannable)
SHORT_MSG=$(echo "$MESSAGE" | head -c 300)

curl -s \
  -H "Title: ${PROJECT}" \
  -H "Tags: hammer,white_check_mark" \
  -H "Priority: default" \
  -d "$SHORT_MSG" \
  "ntfy.sh/${TOPIC}" > /dev/null 2>&1
