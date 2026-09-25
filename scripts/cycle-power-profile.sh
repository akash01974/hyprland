#!/bin/bash
# Cycle through power profiles: power-saver -> balanced -> performance -> power-saver
current=$(powerprofilesctl get)
case "$current" in
    power-saver) next="balanced" ;;
    balanced)    next="performance" ;;
    performance) next="power-saver" ;;
    *)           next="balanced" ;;
esac
powerprofilesctl set "$next"
