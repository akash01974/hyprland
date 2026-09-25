#!/bin/sh
# Kill all Quickshell processes and restart daemons

echo "Killing all Quickshell processes..."
pkill -f "^qs -c" 2>/dev/null
sleep 1

# Ensure they're dead
pkill -9 -f "^qs -c" 2>/dev/null
sleep 0.5

echo "Restarting Quickshell daemons..."

# Restart pill (daemon will auto-restart, but force it now)
nohup ~/.config/hypr/scripts/pill-daemon.sh &>/dev/null &

echo "Quickshell restarted."