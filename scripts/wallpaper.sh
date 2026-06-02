#!/bin/bash
# wallpaper.sh — copy current wallpaper to hyprlock cache
# Usage: wallpaper.sh [path-to-image]
#   Without argument, queries awww for the current wallpaper.

if [ -n "${1:-}" ]; then
    IMG="$1"
else
    IMG=$(awww query 2>/dev/null | grep -oP '(?<=image: )[^\s]+')
fi

[ -z "$IMG" ] && exit 0

CACHE_DIR="/home/akash/.cache/hyprlock"
mkdir -p "$CACHE_DIR"
cp -f -- "$IMG" "$CACHE_DIR/current.jpg" 2>/dev/null || exit 0

echo "$CACHE_DIR/current.jpg"
