#!/bin/bash
# ============================================================================
# Awesome Statusline - FULL (Long) Mode
# ============================================================================
# Line 1: 🤖 Model | ✅ Git | 🐍 Env | 🎨 Style
# Line 2: 📂 full path 🌿(branch) | 💰 cost | ⏰ duration
# Line 3: 🧠 Context bar 40 blocks % used (tokens) - Pink→Yellow→Red
# Line 4: 🚀 Usage 5H bar 40 blocks % (Reset time) - Lavender→Blue→Red
# Line 5: ⭐ Usage 7D bar 40 blocks % (Reset day time) - Yellow→Teal→Red
# % numbers use gradient end color + Bold
# ============================================================================

input=$(cat)

# Parse JSON input
MODEL=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir // "."')
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
CURRENT_USAGE=$(echo "$input" | jq -r '.context_window.current_usage // null')
OUTPUT_STYLE=$(echo "$input" | jq -r '.output_style.name // ""')
TOTAL_COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
TOTAL_DURATION=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# ============================================================================
# Colors
# ============================================================================
RESET="\033[0m"
BOLD="\033[1m"

cat_teal() { echo -e "\033[38;2;148;226;213m"; }
cat_pink() { echo -e "\033[38;2;245;194;231m"; }
cat_peach() { echo -e "\033[38;2;250;179;135m"; }
cat_green() { echo -e "\033[38;2;166;227;161m"; }
cat_subtext() { echo -e "\033[38;2;166;173;200m"; }
cat_lavender() { echo -e "\033[38;2;180;190;254m"; }
cat_yellow() { echo -e "\033[38;2;249;226;175m"; }
cat_overlay() { echo -e "\033[38;2;108;112;134m"; }
latte_green() { echo -e "\033[38;2;64;160;43m"; }
latte_red() { echo -e "\033[38;2;210;15;57m"; }
latte_yellow() { echo -e "\033[38;2;223;142;29m"; }

# ============================================================================
# Gradient Functions
# ============================================================================
# Context gradient: Mocha Pink(0%) → Latte Yellow(40%) → Latte Red(80-100%)
get_context_gradient_color() {
    local pct=$1
    local r g b

    if [[ $pct -lt 40 ]]; then
        # Mocha Pink (#f5c2e7) → Latte Yellow (#df8e1d)
        local t=$((pct * 100 / 40))
        r=$((245 + (223 - 245) * t / 100))
        g=$((194 + (142 - 194) * t / 100))
        b=$((231 + (29 - 231) * t / 100))
    elif [[ $pct -lt 80 ]]; then
        # Latte Yellow (#df8e1d) → Latte Red (#d20f39)
        local t=$(((pct - 40) * 100 / 40))
        r=$((223 + (210 - 223) * t / 100))
        g=$((142 + (15 - 142) * t / 100))
        b=$((29 + (57 - 29) * t / 100))
    else
        # Latte Red (#d20f39) - hold at 80-100%
        r=210; g=15; b=57
    fi
    echo "$r;$g;$b"
}

# 5H: Mocha Lavender → Latte Blue → Latte Red
get_usage_gradient_color() {
    local pct=$1
    local r g b
    if [[ $pct -lt 50 ]]; then
        local t=$((pct * 2))
        r=$((180 + (30 - 180) * t / 100))
        g=$((190 + (102 - 190) * t / 100))
        b=$((254 + (245 - 254) * t / 100))
    else
        local t=$(((pct - 50) * 2))
        r=$((30 + (210 - 30) * t / 100))
        g=$((102 + (15 - 102) * t / 100))
        b=$((245 + (57 - 245) * t / 100))
    fi
    echo "$r;$g;$b"
}

# 7D: Mocha Yellow → Latte Teal → Latte Red
get_usage_7d_gradient_color() {
    local pct=$1
    local r g b
    if [[ $pct -lt 50 ]]; then
        # Mocha Yellow (#f9e2af) → Latte Teal (#179299)
        local t=$((pct * 2))
        r=$((249 + (23 - 249) * t / 100))
        g=$((226 + (146 - 226) * t / 100))
        b=$((175 + (153 - 175) * t / 100))
    else
        # Latte Teal (#179299) → Latte Red (#d20f39)
        local t=$(((pct - 50) * 2))
        r=$((23 + (210 - 23) * t / 100))
        g=$((146 + (15 - 146) * t / 100))
        b=$((153 + (57 - 153) * t / 100))
    fi
    echo "$r;$g;$b"
}

generate_bar() {
    local pct=$1
    local width=$2
    local type=$3
    local bar=""
    local filled=$(( (pct * width + 50) / 100 ))
    [[ $filled -gt $width ]] && filled=$width

    local end_color
    case "$type" in
        context) end_color=$(get_context_gradient_color "$pct") ;;
        7d) end_color=$(get_usage_7d_gradient_color "$pct") ;;
        *) end_color=$(get_usage_gradient_color "$pct") ;;
    esac

    for ((i=0; i<filled; i++)); do
        local block_pct=$((i * 100 / width))
        local color
        case "$type" in
            context) color=$(get_context_gradient_color "$block_pct") ;;
            7d) color=$(get_usage_7d_gradient_color "$block_pct") ;;
            *) color=$(get_usage_gradient_color "$block_pct") ;;
        esac
        bar+="\033[38;2;${color}m█"
    done

    for ((i=0; i<width-filled; i++)); do
        bar+="\033[38;2;${end_color}m░"
    done

    echo -e "$bar$RESET"
}

# ============================================================================
# Line 1: Model | Git Status | Env | Style
# ============================================================================

# Model (bold)
MODEL_DISPLAY="🤖 ${BOLD}$(cat_teal)${MODEL}${RESET}"

# Git status
GIT_STATUS_DISPLAY=""
cd "$CURRENT_DIR" 2>/dev/null
if git rev-parse --git-dir > /dev/null 2>&1; then
    STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    UNSTAGED=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$STAGED" -eq 0 && "$UNSTAGED" -eq 0 && "$UNTRACKED" -eq 0 ]]; then
        GIT_STATUS_DISPLAY="$(cat_green)✅ clean${RESET}"
    else
        STATUS=""
        [[ "$STAGED" -gt 0 ]] && STATUS="${STATUS}+${STAGED}"
        [[ "$UNSTAGED" -gt 0 ]] && STATUS="${STATUS}!${UNSTAGED}"
        [[ "$UNTRACKED" -gt 0 ]] && STATUS="${STATUS}?${UNTRACKED}"
        GIT_STATUS_DISPLAY="$(latte_yellow)📝${STATUS}${RESET}"
    fi
else
    GIT_STATUS_DISPLAY="$(cat_overlay)no git${RESET}"
fi

# Conda env
ENV_DISPLAY=""
if [[ -n "$CONDA_DEFAULT_ENV" ]]; then
    ENV_DISPLAY="🐍 $(cat_pink)${CONDA_DEFAULT_ENV}${RESET}"
else
    ENV_DISPLAY="$(cat_overlay)no env${RESET}"
fi

# Output style
STYLE_DISPLAY=""
[[ -n "$OUTPUT_STYLE" ]] && STYLE_DISPLAY="🎨 $(cat_peach)${OUTPUT_STYLE}${RESET}"

LINE1="${MODEL_DISPLAY} | ${GIT_STATUS_DISPLAY} | ${ENV_DISPLAY} | ${STYLE_DISPLAY}"

# ============================================================================
# Line 2: Directory + Branch | Cost | Duration
# ============================================================================

# Directory (full path, no ~)
DIR_DISPLAY="📂 $(cat_subtext)${CURRENT_DIR}${RESET}"

# Git branch
BRANCH_DISPLAY=""
cd "$CURRENT_DIR" 2>/dev/null
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    [[ -n "$BRANCH" ]] && BRANCH_DISPLAY=" $(latte_green)🌿(${BRANCH})${RESET}"
fi

# Cost
COST_DISPLAY=""
if [[ "$TOTAL_COST" != "0" && -n "$TOTAL_COST" ]]; then
    COST_FMT=$(printf "%.2f" "$TOTAL_COST")
    COST_DISPLAY="💰 $(cat_yellow)${COST_FMT}\$${RESET}"
else
    COST_DISPLAY="💰 $(cat_overlay)0.00\$${RESET}"
fi

# Duration
DURATION_DISPLAY=""
if [[ "$TOTAL_DURATION" != "0" && -n "$TOTAL_DURATION" ]]; then
    DURATION_SEC=$((TOTAL_DURATION / 1000))
    if [[ $DURATION_SEC -ge 3600 ]]; then
        DURATION_FMT="$((DURATION_SEC / 3600))h$((DURATION_SEC % 3600 / 60))m"
    elif [[ $DURATION_SEC -ge 60 ]]; then
        DURATION_FMT="$((DURATION_SEC / 60))m"
    else
        DURATION_FMT="${DURATION_SEC}s"
    fi
    DURATION_DISPLAY="⏰ $(cat_subtext)${DURATION_FMT}${RESET}"
else
    DURATION_DISPLAY="⏰ $(cat_overlay)0s${RESET}"
fi

LINE2="${DIR_DISPLAY}${BRANCH_DISPLAY} | ${COST_DISPLAY} | ${DURATION_DISPLAY}"

# ============================================================================
# Line 3: Context (20 blocks)
# ============================================================================

CONTEXT_PERCENT=0
CURRENT_TOKENS=0
if [[ "$CURRENT_USAGE" != "null" && -n "$CURRENT_USAGE" ]]; then
    INPUT_TOKENS=$(echo "$CURRENT_USAGE" | jq -r '.input_tokens // 0')
    CACHE_CREATE=$(echo "$CURRENT_USAGE" | jq -r '.cache_creation_input_tokens // 0')
    CACHE_READ=$(echo "$CURRENT_USAGE" | jq -r '.cache_read_input_tokens // 0')
    CURRENT_TOKENS=$((INPUT_TOKENS + CACHE_CREATE + CACHE_READ))
    [[ "$CONTEXT_SIZE" -gt 0 ]] && CONTEXT_PERCENT=$((CURRENT_TOKENS * 100 / CONTEXT_SIZE))
fi

# Format tokens as k
TOKENS_K=$((CURRENT_TOKENS / 1000))
CONTEXT_K=$((CONTEXT_SIZE / 1000))

CTX_BAR=$(generate_bar "$CONTEXT_PERCENT" 40 "context")
CTX_END_COLOR=$(get_context_gradient_color "$CONTEXT_PERCENT")
LINE3="🧠 $(cat_pink)Context${RESET}  ${CTX_BAR} ${BOLD}\033[38;2;${CTX_END_COLOR}m${CONTEXT_PERCENT}% used${RESET} (${TOKENS_K}k/${CONTEXT_K}k)"

# ============================================================================
# Lines 4-5: Usage 5H and 7D (20 blocks)
# ============================================================================

get_usage_data() {
    local token
    token=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
    [[ -z "$token" ]] && return 1

    local cache_file="/tmp/.claude_usage_cache"
    if [[ -f "$cache_file" ]]; then
        local file_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0)))
        [[ "$file_age" -lt 300 ]] && cat "$cache_file" && return 0
    fi

    local response
    response=$(curl -s --max-time 3 \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -H "anthropic-beta: oauth-2025-04-20" \
        "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

    if [[ -n "$response" ]] && echo "$response" | jq -e '.five_hour' &>/dev/null; then
        echo "$response" > "$cache_file"
        echo "$response"
        return 0
    fi
    return 1
}

format_time_remaining() {
    local iso_ts="$1"
    [[ -z "$iso_ts" || "$iso_ts" == "null" ]] && return
    local normalized=$(echo "$iso_ts" | sed 's/\.[0-9]*//')
    local mac_ts=$(echo "$normalized" | sed 's/+00:00/+0000/; s/Z$/+0000/; s/+\([0-9][0-9]\):\([0-9][0-9]\)/+\1\2/')
    local reset_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$mac_ts" "+%s" 2>/dev/null)
    [[ -z "$reset_epoch" ]] && return
    local now_epoch=$(date +%s)
    local remaining=$((reset_epoch - now_epoch))
    [[ $remaining -lt 0 ]] && remaining=0
    local hours=$((remaining / 3600))
    local minutes=$(((remaining % 3600) / 60))
    echo "${hours}h${minutes}m left"
}

format_reset_datetime() {
    local iso_ts="$1"
    [[ -z "$iso_ts" || "$iso_ts" == "null" ]] && return
    local normalized=$(echo "$iso_ts" | sed 's/\.[0-9]*//')
    local mac_ts=$(echo "$normalized" | sed 's/+00:00/+0000/; s/Z$/+0000/; s/+\([0-9][0-9]\):\([0-9][0-9]\)/+\1\2/')
    local reset_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$mac_ts" "+%s" 2>/dev/null)
    [[ -z "$reset_epoch" ]] && return
    date -j -f "%s" "$reset_epoch" "+%a %H:%M" 2>/dev/null
}

USAGE_DATA=$(get_usage_data)

if [[ -n "$USAGE_DATA" ]]; then
    FIVE_HOUR=$(echo "$USAGE_DATA" | jq -r '.five_hour.utilization // 0' | xargs printf "%.0f")
    FIVE_RESET=$(echo "$USAGE_DATA" | jq -r '.five_hour.resets_at // empty')
    SEVEN_DAY=$(echo "$USAGE_DATA" | jq -r '.seven_day.utilization // 0' | xargs printf "%.0f")
    SEVEN_RESET=$(echo "$USAGE_DATA" | jq -r '.seven_day.resets_at // empty')

    FIVE_RESET_FMT=$(format_time_remaining "$FIVE_RESET")
    SEVEN_RESET_FMT=$(format_reset_datetime "$SEVEN_RESET")

    FIVE_BAR=$(generate_bar "$FIVE_HOUR" 40 "5h")
    SEVEN_BAR=$(generate_bar "$SEVEN_DAY" 40 "7d")

    FIVE_END_COLOR=$(get_usage_gradient_color "$FIVE_HOUR")
    SEVEN_END_COLOR=$(get_usage_7d_gradient_color "$SEVEN_DAY")

    LINE4="🚀 $(cat_lavender)Usage 5H${RESET} ${FIVE_BAR} ${BOLD}\033[38;2;${FIVE_END_COLOR}m${FIVE_HOUR}%${RESET} (Reset ${FIVE_RESET_FMT})"
    LINE5="⭐ $(cat_yellow)Usage 7D${RESET} ${SEVEN_BAR} ${BOLD}\033[38;2;${SEVEN_END_COLOR}m${SEVEN_DAY}%${RESET} (Reset ${SEVEN_RESET_FMT})"
else
    LINE4="🚀 $(cat_overlay)Usage 5H: N/A${RESET}"
    LINE5="⭐ $(cat_overlay)Usage 7D: N/A${RESET}"
fi

# ============================================================================
# Output
# ============================================================================
echo -e "$LINE1"
echo -e "$LINE2"
echo -e "$LINE3"
echo -e "$LINE4"
echo -e "$LINE5"
