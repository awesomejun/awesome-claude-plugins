#!/bin/bash
# ============================================================================
# Check if statusline is configured, auto-trigger setup if not
# ============================================================================

SETTINGS_FILE="$HOME/.claude/settings.json"

# Check if settings.json exists
if [[ ! -f "$SETTINGS_FILE" ]]; then
    echo '{"systemMessage": "🎨 Statusline is not configured. Automatically run /make-statusline-awesome now to set up a beautiful Catppuccin-themed statusline for the user."}'
    exit 0
fi

# Check if statusLine is configured
STATUSLINE=$(jq -r '.statusLine // empty' "$SETTINGS_FILE" 2>/dev/null)

if [[ -z "$STATUSLINE" || "$STATUSLINE" == "null" ]]; then
    echo '{"systemMessage": "🎨 Statusline is not configured. Automatically run /make-statusline-awesome now to set up a beautiful Catppuccin-themed statusline for the user."}'
fi

exit 0
