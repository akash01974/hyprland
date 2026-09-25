#!/bin/sh
# Pull the MT7921 out of D3cold and reprobe it. Safe to rerun.
# Usage: sudo ~/.config/hypr/scripts/wifi-recover.sh

DEV=/sys/bus/pci/devices/0000:2d:00.0
DRV=/sys/bus/pci/drivers/mt7921e

[ -e "$DEV" ] || { echo "PCI device $DEV not present"; exit 1; }

echo "== before =="
lspci -nnk -s 2d:00.0
echo "power_state: $(cat "$DEV/power_state")"
echo "d3cold_allowed: $(cat "$DEV/d3cold_allowed")"
echo "driver: $(readlink -f "$DEV/driver" 2>/dev/null || echo '(none)')"

echo
echo "== 1. keep the device out of D3cold =="
echo 0 > "$DEV/d3cold_allowed"

echo "== 2. force runtime PM on (no PCI autosuspend) =="
echo on > "$DEV/power/control"

echo "== 3. unbind from mt7921e (ignore errors if unbound) =="
echo 0000:2d:00.0 > "$DRV/unbind" 2>/dev/null || true
sleep 1

echo "== 4. bus reset via remove + rescan =="
echo 1 > "$DEV/remove"
sleep 2
echo 1 > /sys/bus/pci/rescan
sleep 3

echo "== 5. make sure the module is loaded and bound =="
modprobe mt7921e 2>/dev/null || true
sleep 1
if [ ! -e "$DEV/driver" ] && [ -e "$DEV" ]; then
    echo 0000:2d:00.0 > "$DRV/bind" 2>/dev/null || true
    sleep 2
fi

echo
echo "== after =="
lspci -nnk -s 2d:00.0
echo "power_state: $(cat "$DEV/power_state" 2>/dev/null)"
echo "driver: $(readlink -f "$DEV/driver" 2>/dev/null || echo '(none)')"
echo
ip -br link show type wireless || true
echo
dmesg | grep -iE 'mt7921|mt76' | tail -15
