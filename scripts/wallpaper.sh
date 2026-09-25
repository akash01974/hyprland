#!/usr/bin/env bash
set -euo pipefail

WPDIR="$HOME/Pictures/Wallpapers"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/ricelin-wallpaper"
BAG="${XDG_STATE_HOME:-$HOME/.local/state}/ricelin-wallpaper-bag"

list_pics() {
    find "$WPDIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \)
}

refill_bag() {
    local current="" shuffled
    [ -r "$STATE" ] && current=$(cat "$STATE")
    shuffled=$(list_pics | shuf)
    [ -n "$shuffled" ] || return 0
    if [ "$(printf '%s\n' "$shuffled" | head -n1)" = "$current" ] && [ "$(printf '%s\n' "$shuffled" | wc -l)" -gt 1 ]; then
        shuffled=$(printf '%s\n' "$shuffled" | tail -n +2; printf '%s\n' "$current")
    fi
    mkdir -p "$(dirname "$BAG")"
    printf '%s\n' "$shuffled" > "$BAG"
}

pop_bag() {
    local line refilled=false
    mkdir -p "$(dirname "$BAG")"
    (
        flock 9
        while :; do
            if [ ! -s "$BAG" ]; then
                [ "$refilled" = true ] && exit 1
                refill_bag
                refilled=true
                [ -s "$BAG" ] || exit 1
            fi
            line=$(head -n1 "$BAG")
            tail -n +2 "$BAG" > "$BAG.tmp" && mv "$BAG.tmp" "$BAG"
            if [ -f "$line" ]; then
                printf '%s\n' "$line"
                exit 0
            fi
        done
    ) 9>"$BAG.lock"
}

cmd="${1:-}"

if [ "$cmd" = "init" ]; then
    THEME_STARTUP=1
    if [ -r "$STATE" ] && pic=$(cat "$STATE") && [ -f "$pic" ]; then
        :
    else
        pic=$(pop_bag) || exit 0
    fi
elif [ "$cmd" = "set" ]; then
    pic="${2:-}"
    [ -f "$pic" ] || exit 1
else
    pic=$(pop_bag) || exit 0
fi

[ -n "$pic" ] || exit 0

mkdir -p "$(dirname "$STATE")"
printf '%s\n' "$pic" > "$STATE"

THEME_STARTUP="${THEME_STARTUP:-0}" exec "$HOME/.config/rofi/helpers/handler-theme-update.sh" "$pic"
