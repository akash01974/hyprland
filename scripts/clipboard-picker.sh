#!/usr/bin/env bash

# Kill existing clipboard rofi if running
pgrep -if "[r]ofi.*[c]lipboard" && pkill -if "[r]ofi.*[c]lipboard" && exit 0

hist=$(cliphist list 2>/dev/null)
[[ -z "$hist" ]] && exit 1

declare -a ids texts
while IFS=$'\t' read -r id content; do
    ids+=("$id")
    texts+=("$content")
done <<< "$hist"

list="$(printf '%s\n' "${texts[@]}")"$'\n'"  Clear all history"

selected=$(echo "$list" | rofi -dmenu -p '  Clipboard' \
    -theme ~/.config/rofi/themes/clipboard.rasi -no-custom \
    -hover-select -me-select-entry '' -me-accept-entry MousePrimary)

[[ -z "$selected" ]] && exit 1

if [[ "$selected" == "  Clear all history" ]]; then
    cliphist wipe && notify-send "Clipboard" "History cleared"
    exit 0
fi

for i in "${!texts[@]}"; do
    if [[ "${texts[$i]}" == "$selected" ]]; then
        printf '%s\t%s\n' "${ids[$i]}" "${texts[$i]}" | cliphist decode | wl-copy
        wtype -M ctrl v -m ctrl 2>/dev/null
        break
    fi
done
