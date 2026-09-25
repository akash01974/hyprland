#!/bin/sh

STATEFILE="$HOME/.cache/quickshell-panel"
TMPFILE="${STATEFILE}.tmp"

CURRENT=$(cat "$STATEFILE" 2>/dev/null || echo "pill")

if [ "$CURRENT" = "pill" ]; then
    # ── switch to topbar ──
    echo "topbar" > "$TMPFILE" && mv "$TMPFILE" "$STATEFILE"
    # hide pill (do NOT kill — keep process alive for instant toggle back)
    qs -c pill ipc call pill hidePanel 2>/dev/null || pkill -fx "qs -c pill -d"
    # show topbar via IPC or start fresh
    qs -c topbar ipc call topbar showPanel 2>/dev/null || qs -c topbar -d 2>/dev/null
else
    # ── switch to pill ──
    echo "pill" > "$TMPFILE" && mv "$TMPFILE" "$STATEFILE"
    # hide topbar via IPC or kill
    qs -c topbar ipc call topbar hidePanel 2>/dev/null || pkill -fx "qs -c topbar -d"
    # show pill via IPC (instant) or start fresh if dead
    qs -c pill ipc call pill showPanel 2>/dev/null || qs -c pill -d 9>&- 2>/dev/null
fi
