#!/bin/bash
# ============================================================================
# Awesome Statusline - SessionStart Hook
# 1. First run: Show welcome message (only once)
# 2. After: If statusline not configured, show setup guide
# ============================================================================

WELCOME_FLAG="$HOME/.claude/.awesome-statusline-welcomed"
SETTINGS_FILE="$HOME/.claude/settings.json"

# Welcome message (first run only)
print_welcome() {
    cat << 'JSONEOF'
{"systemMessage": "✨ Welcome to Awesome Statusline! ✨\n\n🎨 Catppuccin 테마의 아름다운 Statusline으로 터미널을 꾸며보세요!\n\n📊 주요 기능:\n   • 실시간 Context / API 사용량 모니터링 (5H/7D)\n   • 4단계 그라데이션 프로그레스 바\n   • 5가지 디스플레이 모드 (Compact/Default/Full/Legacy 2.0/1.0)\n\n📸 Demo: https://github.com/awesomejun/awesome-claude-plugins\n\n🚀 설치 명령어: /awesome-statusline-start"}
JSONEOF
}

# Setup reminder (when statusline not configured)
print_setup_guide() {
    cat << 'JSONEOF'
{"systemMessage": "🎨 Statusline이 설정되지 않았습니다.\n\n🚀 설치: /awesome-statusline-start\n🗑️ 이 메시지 끄기: /awesome-statusline-remove settings"}
JSONEOF
}

# First run: show welcome message
if [[ ! -f "$WELCOME_FLAG" ]]; then
    mkdir -p "$(dirname "$WELCOME_FLAG")"
    touch "$WELCOME_FLAG"
    print_welcome
    exit 0
fi

# After first run: check if statusline is configured
if [[ -f "$SETTINGS_FILE" ]]; then
    STATUSLINE=$(jq -r '.statusLine // empty' "$SETTINGS_FILE" 2>/dev/null)
    if [[ -z "$STATUSLINE" || "$STATUSLINE" == "null" ]]; then
        print_setup_guide
    fi
else
    print_setup_guide
fi

exit 0
