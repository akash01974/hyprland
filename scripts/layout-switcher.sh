#!/usr/bin/env bash
LAYOUTS=("scrolling" "dwindle" "master")
CACHE_FILE="/tmp/hypr_layout_index"

if [[ ! -f "$CACHE_FILE" ]]; then
    echo 0 > "$CACHE_FILE"
fi

current=$(cat "$CACHE_FILE")
total=${#LAYOUTS[@]}
next=$(( (current + 1) % total ))
echo "$next" > "$CACHE_FILE"

next_layout="${LAYOUTS[$next]}"

hyprctl eval "hl.config({ general = { layout = \"$next_layout\" } })"

# send a notification
if command -v notify-send &>/dev/null; then
    notify-send -t 2000 "Layout Switched" "→ $next_layout" &
fi