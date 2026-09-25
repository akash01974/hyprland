#!/bin/sh
export QS_NO_RELOAD_POPUP=1
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/launcher-watchdog.lock"
flock -n 9 || exit 0

while true; do
    qs -c launcher ipc show >/dev/null 2>&1 || qs -c launcher -d 9>&- 2>/dev/null
    sleep 5
done
