#!/bin/bash

LOG=/tmp/power-profile-monitor.log
last=""

log() {
    echo "[$(date '+%H:%M:%S.%3N')] $*" >> "$LOG"
}

last=$(busctl get-property net.hadess.PowerProfiles \
    /net/hadess/PowerProfiles \
    net.hadess.PowerProfiles ActiveProfile 2>/dev/null | cut -d'"' -f2)
[ -z "$last" ] && last="unknown"
log "started, profile=$last"

dbus-monitor --system \
    "type='signal',sender=net.hadess.PowerProfiles,path=/net/hadess/PowerProfiles,interface=org.freedesktop.DBus.Properties,member=PropertiesChanged" \
    2>/dev/null | \
while read -r line; do
    [[ "$line" =~ string\ \"(performance|balanced|power-saver)\" ]] || continue
    current="${BASH_REMATCH[1]}"
    [[ "$current" == "$last" ]] && continue
    last="$current"
    log "changed to $current"

    case "$current" in
        performance) summary="⚡ Performance Mode" ;;
        balanced)    summary="⚖️ Balanced Mode" ;;
        power-saver) summary="🔋 Power Saver Mode" ;;
    esac

    id=$(busctl call --user org.freedesktop.Notifications \
        /org/freedesktop/Notifications \
        org.freedesktop.Notifications Notify \
        susssasa{sv}i \
        "" 0 "" "$summary" "" 0 0 3000 2>/dev/null | cut -d' ' -f2-)
    log "notified id=$id"
done
