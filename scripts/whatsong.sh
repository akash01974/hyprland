#!/bin/bash

STATUS=$(playerctl status 2>/dev/null)

if [ "$STATUS" = "Playing" ] || [ "$STATUS" = "Paused" ]; then
    ARTIST=$(playerctl metadata artist 2>/dev/null | head -c 40)
    TITLE=$(playerctl metadata title 2>/dev/null | head -c 50)

    if [ "$STATUS" = "Paused" ]; then
        ICON="⏸"
    else
        ICON="♪"
    fi

    if [ -n "$ARTIST" ] && [ -n "$TITLE" ]; then
        echo "$ICON $ARTIST — $TITLE"
    elif [ -n "$TITLE" ]; then
        echo "$ICON $TITLE"
    fi
fi