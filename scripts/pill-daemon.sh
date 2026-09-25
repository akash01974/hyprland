#!/bin/sh
export QS_NO_RELOAD_POPUP=1
export QT_HTTP2_DISABLED=1
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/pill-watchdog.lock"
flock -n 9 || exit 0

STATEFILE="$HOME/.cache/quickshell-panel"

while true; do
    if [ "$(cat "$STATEFILE" 2>/dev/null)" = "pill" ] \
        && ! pgrep -fx "qs -c pill -d" >/dev/null 2>&1; then
        qs -c pill -d 9>&- 2>/dev/null
    fi
    sleep 5
done