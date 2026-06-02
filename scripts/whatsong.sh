#!/bin/bash
# whatsong.sh — current playing track via playerctl

STATUS=$(playerctl status 2>/dev/null)

if [ "$STATUS" = "Playing" ] || [ "$STATUS" = "Paused" ]; then
    ARTIST=$(playerctl metadata artist 2>/dev/null)
    TITLE=$(playerctl metadata title 2>/dev/null)
    if [ -n "$ARTIST" ] && [ -n "$TITLE" ]; then
        echo "♪ $ARTIST — $TITLE"
    elif [ -n "$TITLE" ]; then
        echo "♪ $TITLE"
    else
        echo ""
    fi
else
    echo ""
fi