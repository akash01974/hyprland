#!/bin/sh
MAGICK_CONFIGURE_PATH="$(dirname "$0")/magick-policy"
export MAGICK_CONFIGURE_PATH

cache="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist-thumbs"
mkdir -p "$cache"

entries=$(cliphist list 2>/dev/null)

echo "$entries" | while IFS= read -r line; do
    [ -z "$line" ] && continue
    id="${line%%	*}"
    rest="${line#*	}"
    case "$rest" in
        "[[ binary data "*)
            thumb="$cache/$id.png"
            if [ ! -s "$thumb" ]; then
                cliphist decode "$id" 2>/dev/null | magick - -strip -resize 256x "png:$thumb.tmp" 2>/dev/null
                if [ -s "$thumb.tmp" ]; then
                    mv "$thumb.tmp" "$thumb"
                else
                    rm -f "$thumb.tmp"
                fi
            fi
            ;;
    esac
done

valid=$(mktemp)
echo "$entries" | while IFS= read -r line; do
    [ -z "$line" ] && continue
    echo "${line%%	*}" >> "$valid"
done

for f in "$cache"/*.png; do
    [ -e "$f" ] || continue
    bid=$(basename "$f" .png)
    if ! grep -qx "$bid" "$valid" 2>/dev/null; then
        rm -f "$f"
    fi
done
rm -f "$valid"
