#!/usr/bin/env bash
# ============================================================================
# Awesome Statusline - FULL (Long) Mode
# ============================================================================
# Line 1: 🤖 Model | 🎨 Style | ✅ Git (↑ahead ↓behind) | 🐍 Env
# Line 2: 📂 full path 🌿(branch) | 💰 cost | ⏰ duration
# Line 3: 🧠 Context bar 40 blocks - MochaMaroon→LatteMaroon(40%)→Red(80-100%)
# Line 4: 🚀 5H Limit bar 40 blocks - Lavender→Lavender(40%)→Blue(80%)→Red(100%)
# Line 5: 🌟 7D Limit bar 40 blocks - Yellow→Yellow(40%)→Green(80%)→Red(100%)
# 5H Reset: "(Resets in 2h15m)" | 7D Reset: "(Resets Jan 21 at 2pm)"
# ============================================================================
# v2.1.0 - Fixed: echo -e → variables, added line clear \033[K, pre-calc colors, atomic output
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
# Colors (variables instead of functions to avoid newline issues)
# ============================================================================
RESET="\033[0m"
BOLD="\033[1m"
CLR="\033[K"  # Clear to end of line

C_TEAL="\033[38;2;148;226;213m"
C_PINK="\033[38;2;245;194;231m"
C_PEACH="\033[38;2;250;179;135m"
C_GREEN="\033[38;2;166;227;161m"
C_SUBTEXT="\033[38;2;166;173;200m"
C_LAVENDER="\033[38;2;180;190;254m"
C_YELLOW="\033[38;2;249;226;175m"
C_OVERLAY="\033[38;2;108;112;134m"
C_LATTE_GREEN="\033[38;2;64;160;43m"
C_LATTE_RED="\033[38;2;210;15;57m"
C_LATTE_YELLOW="\033[38;2;223;142;29m"
C_LATTE_PINK="\033[38;2;234;118;203m"
C_LATTE_MAROON="\033[38;2;230;69;83m"
C_LATTE_SKY="\033[38;2;4;165;229m"
C_LATTE_BLUE="\033[38;2;30;102;245m"
C_MOCHA_MAROON="\033[38;2;235;160;172m"

# ============================================================================
# Pre-calculated Gradient Colors (40 blocks) - No runtime calculation
# ============================================================================
# Context: Mocha Maroon(0%) → Latte Maroon(40%) → Latte Red(80-100%)
GRAD_CONTEXT=(
    "235;160;172" "234;154;166" "234;149;161" "233;143;155" "233;137;150"
    "232;132;144" "232;126;139" "231;120;133" "231;115;127" "230;109;122"
    "230;103;116" "229;98;111" "229;92;105" "228;86;100" "228;81;94"
    "227;75;89" "230;69;83" "229;65;79" "228;62;76" "227;58;72"
    "226;55;69" "225;51;65" "224;48;62" "223;44;59" "222;41;55"
    "221;37;52" "220;34;48" "219;30;45" "218;27;41" "217;23;38"
    "216;20;34" "215;16;31" "210;15;57" "210;15;57" "210;15;57"
    "210;15;57" "210;15;57" "210;15;57" "210;15;57" "210;15;57"
)

# 5H: Mocha Lavender(0%) → Latte Lavender(40%) → Latte Blue(80%) → Latte Red(100%)
GRAD_5H=(
    "180;190;254" "175;186;253" "171;183;253" "167;179;253" "163;176;253"
    "158;172;253" "154;169;253" "150;165;253" "146;162;253" "141;158;253"
    "137;155;253" "133;151;253" "129;148;253" "124;144;253" "120;141;253"
    "116;137;253" "114;135;253" "108;132;252" "103;130;251" "98;127;250"
    "93;125;249" "87;122;248" "82;120;247" "77;117;247" "72;115;246"
    "66;112;245" "61;110;244" "56;107;243" "51;105;242" "45;102;241"
    "40;100;241" "35;97;240" "30;102;245" "52;98;235" "75;93;226"
    "97;89;216" "120;84;207" "142;80;197" "165;75;188" "210;15;57"
)

# 7D: Mocha Yellow(0%) → Latte Yellow(40%) → Latte Green(80%) → Latte Red(100%)
GRAD_7D=(
    "249;226;175" "247;220;165" "246;215;156" "244;210;147" "243;204;138"
    "241;199;129" "240;194;120" "238;188;111" "237;183;102" "235;178;93"
    "234;172;83" "232;167;74" "231;162;65" "229;157;56" "228;151;47"
    "226;146;38" "223;142;29" "213;142;29" "203;143;30" "193;144;31"
    "183;145;32" "173;146;33" "163;147;34" "153;148;35" "143;148;36"
    "133;149;37" "123;150;38" "113;151;39" "103;152;40" "93;153;40"
    "83;154;41" "74;156;42" "64;160;43" "82;141;44" "101;123;45"
    "119;104;47" "138;86;48" "156;67;50" "175;49;51" "210;15;57"
)

# Empty bar color (overlay gray)
C_BAR_EMPTY="108;112;134"

generate_bar() {
    local pct=$1
    local width=$2
    local type=$3
    local bar=""
    local filled=$(( (pct * width + 50) / 100 ))
    [[ $filled -gt $width ]] && filled=$width

    # Select gradient array
    local -n colors
    case "$type" in
        context) colors=GRAD_CONTEXT ;;
        7d) colors=GRAD_7D ;;
        *) colors=GRAD_5H ;;
    esac

    # Build filled blocks using pre-calculated colors
    for ((i=0; i<filled; i++)); do
        bar+="\033[38;2;${colors[$i]}m█"
    done

    # Build empty blocks (use last filled color for continuity)
    local empty_color="${colors[0]}"
    [[ $filled -gt 0 ]] && empty_color="${colors[$((filled-1))]}"
    for ((i=0; i<width-filled; i++)); do
        bar+="\033[38;2;${empty_color}m░"
    done

    printf "%b%b" "$bar" "$RESET"
}

# Get end color for percentage display
get_end_color() {
    local pct=$1
    local type=$2
    local idx=$(( (pct * 39 + 50) / 100 ))
    [[ $idx -gt 39 ]] && idx=39

    local -n colors
    case "$type" in
        context) colors=GRAD_CONTEXT ;;
        7d) colors=GRAD_7D ;;
        *) colors=GRAD_5H ;;
    esac

    echo "${colors[$idx]}"
}

# ============================================================================
# Line 1: Model | Style | Git Status (↑ahead ↓behind) | Env
# ============================================================================

# Model (bold)
MODEL_DISPLAY="🤖 ${BOLD}${C_TEAL}${MODEL}${RESET}"

# Output style (moved to second position)
STYLE_DISPLAY=""
[[ -n "$OUTPUT_STYLE" ]] && STYLE_DISPLAY="🎨 ${C_PEACH}${OUTPUT_STYLE}${RESET}"

# Git status with ahead/behind arrows
GIT_STATUS_DISPLAY=""
cd "$CURRENT_DIR" 2>/dev/null
if git rev-parse --git-dir > /dev/null 2>&1; then
    STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    UNSTAGED=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')

    # Get ahead/behind count relative to upstream
    AHEAD_BEHIND=""
    if git rev-parse --abbrev-ref '@{upstream}' &>/dev/null; then
        COUNTS=$(git rev-list --left-right --count HEAD...'@{upstream}' 2>/dev/null)
        if [[ -n "$COUNTS" ]]; then
            AHEAD=$(echo "$COUNTS" | awk '{print $1}')
            BEHIND=$(echo "$COUNTS" | awk '{print $2}')
            [[ "$AHEAD" -gt 0 ]] && AHEAD_BEHIND="${AHEAD_BEHIND}${C_LATTE_SKY}↑${AHEAD}${RESET}"
            [[ "$BEHIND" -gt 0 ]] && AHEAD_BEHIND="${AHEAD_BEHIND}${C_LATTE_PINK}↓${BEHIND}${RESET}"
        fi
    fi

    if [[ "$STAGED" -eq 0 && "$UNSTAGED" -eq 0 && "$UNTRACKED" -eq 0 ]]; then
        GIT_STATUS_DISPLAY="${C_GREEN}✅ git clean${RESET}"
        [[ -n "$AHEAD_BEHIND" ]] && GIT_STATUS_DISPLAY="${GIT_STATUS_DISPLAY} ${AHEAD_BEHIND}"
    else
        STATUS=""
        [[ "$STAGED" -gt 0 ]] && STATUS="${STATUS}+${STAGED}"
        [[ "$UNSTAGED" -gt 0 ]] && STATUS="${STATUS}!${UNSTAGED}"
        [[ "$UNTRACKED" -gt 0 ]] && STATUS="${STATUS}?${UNTRACKED}"
        GIT_STATUS_DISPLAY="${C_LATTE_YELLOW}📝 dirty ${STATUS}${RESET}"
        [[ -n "$AHEAD_BEHIND" ]] && GIT_STATUS_DISPLAY="${GIT_STATUS_DISPLAY} ${AHEAD_BEHIND}"
    fi
else
    GIT_STATUS_DISPLAY="${C_OVERLAY}no git${RESET}"
fi

# Conda env
ENV_DISPLAY=""
if [[ -n "$CONDA_DEFAULT_ENV" ]]; then
    ENV_DISPLAY="🐍 ${C_PINK}${CONDA_DEFAULT_ENV}${RESET}"
else
    ENV_DISPLAY="${C_OVERLAY}no env${RESET}"
fi

# Build Line 1: Model | Style | Git | Env
LINE1="${MODEL_DISPLAY}"
[[ -n "$STYLE_DISPLAY" ]] && LINE1="${LINE1} | ${STYLE_DISPLAY}"
LINE1="${LINE1} | ${GIT_STATUS_DISPLAY} | ${ENV_DISPLAY}"

# ============================================================================
# Line 2: Directory + Branch | Cost | Duration
# ============================================================================

# Directory (full path, no ~)
DIR_DISPLAY="📂 ${C_SUBTEXT}${CURRENT_DIR}${RESET}"

# Git branch
BRANCH_DISPLAY=""
cd "$CURRENT_DIR" 2>/dev/null
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    [[ -n "$BRANCH" ]] && BRANCH_DISPLAY=" ${C_LATTE_GREEN}🌿(${BRANCH})${RESET}"
fi

# Cost (same color as directory)
COST_DISPLAY=""
if [[ "$TOTAL_COST" != "0" && -n "$TOTAL_COST" ]]; then
    COST_FMT=$(printf "%.2f" "$TOTAL_COST")
    COST_DISPLAY="💰 ${C_SUBTEXT}${COST_FMT}\$${RESET}"
else
    COST_DISPLAY="💰 ${C_OVERLAY}0.00\$${RESET}"
fi

# Duration
DURATION_DISPLAY=""
if [[ "$TOTAL_DURATION" != "0" && -n "$TOTAL_DURATION" ]]; then
    DURATION_SEC=$((TOTAL_DURATION / 1000))
    if [[ $DURATION_SEC -ge 3600 ]]; then
        DURATION_FMT="$((DURATION_SEC / 3600))h$((DURATION_SEC % 3600 / 60))m"
    else
        DURATION_FMT="$((DURATION_SEC / 60))m"
    fi
    DURATION_DISPLAY="⏰ ${C_SUBTEXT}${DURATION_FMT}${RESET}"
else
    DURATION_DISPLAY="⏰ ${C_OVERLAY}0m${RESET}"
fi

LINE2="${DIR_DISPLAY}${BRANCH_DISPLAY} | ${COST_DISPLAY} | ${DURATION_DISPLAY}"

# ============================================================================
# Line 3: Context (40 blocks)
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
CTX_END_COLOR=$(get_end_color "$CONTEXT_PERCENT" "context")
LINE3="🧠 ${C_MOCHA_MAROON}Context${RESET}  ${CTX_BAR} ${BOLD}\033[38;2;${CTX_END_COLOR}m${CONTEXT_PERCENT}% used${RESET} (${TOKENS_K}k/${CONTEXT_K}k)"

# ============================================================================
# Lines 4-5: Usage 5H and 7D (40 blocks)
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

# Format reset time as "in 2h15m" for 5H
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
    echo "in ${hours}h${minutes}m"
}

# Format reset time as "Jan 21 at 2pm" for 7D
format_reset_datetime() {
    local iso_ts="$1"
    [[ -z "$iso_ts" || "$iso_ts" == "null" ]] && return
    local normalized=$(echo "$iso_ts" | sed 's/\.[0-9]*//')
    local mac_ts=$(echo "$normalized" | sed 's/+00:00/+0000/; s/Z$/+0000/; s/+\([0-9][0-9]\):\([0-9][0-9]\)/+\1\2/')
    local reset_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S%z" "$mac_ts" "+%s" 2>/dev/null)
    [[ -z "$reset_epoch" ]] && return

    # Get hour and determine am/pm
    local hour=$(date -j -f "%s" "$reset_epoch" "+%H" 2>/dev/null)
    local hour_12=$((hour % 12))
    [[ $hour_12 -eq 0 ]] && hour_12=12
    local ampm="am"
    [[ $hour -ge 12 ]] && ampm="pm"

    # Format as "Jan 21 at 2pm"
    local month_day=$(date -j -f "%s" "$reset_epoch" "+%b %d" 2>/dev/null)
    echo "${month_day} at ${hour_12}${ampm}"
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

    FIVE_END_COLOR=$(get_end_color "$FIVE_HOUR" "5h")
    SEVEN_END_COLOR=$(get_end_color "$SEVEN_DAY" "7d")

    LINE4="🚀 ${C_LAVENDER}5H Limit${RESET} ${FIVE_BAR} ${BOLD}\033[38;2;${FIVE_END_COLOR}m${FIVE_HOUR}%${RESET} (Resets ${FIVE_RESET_FMT})"
    LINE5="🌟 ${C_YELLOW}7D Limit${RESET} ${SEVEN_BAR} ${BOLD}\033[38;2;${SEVEN_END_COLOR}m${SEVEN_DAY}%${RESET} (Resets ${SEVEN_RESET_FMT})"
else
    LINE4="🚀 ${C_OVERLAY}5H Limit${RESET}: N/A"
    LINE5="🌟 ${C_OVERLAY}7D Limit${RESET}: N/A"
fi

# ============================================================================
# Output (fully pre-rendered, cursor hidden, single write)
# ============================================================================
FINAL_OUTPUT=$(printf "%b%b\n%b%b\n%b%b\n%b%b\n%b%b" \
    "$LINE1" "$CLR" \
    "$LINE2" "$CLR" \
    "$LINE3" "$CLR" \
    "$LINE4" "$CLR" \
    "$LINE5" "$CLR")
tput civis 2>/dev/null  # hide cursor
printf "%s\n" "$FINAL_OUTPUT"
tput cnorm 2>/dev/null  # restore cursor
