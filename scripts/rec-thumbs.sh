#!/bin/sh
dir="$1"
[ -d "$dir" ] || exit 0

cache="${XDG_CACHE_HOME:-$HOME/.cache}/ricelin/rec-thumbs"
mkdir -p "$cache"

for f in "$dir"/recording_*.mp4; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .mp4)
    thumb="$cache/${name}.jpg"
    if [ ! -s "$thumb" ]; then
        ffmpeg -y -i "$f" -vframes 1 -ss 0.1 -q:v 5 "$thumb.tmp.jpg" 2>/dev/null
        if [ -s "$thumb.tmp.jpg" ]; then
            mv "$thumb.tmp.jpg" "$thumb"
        else
            rm -f "$thumb.tmp.jpg"
        fi
    fi
done
