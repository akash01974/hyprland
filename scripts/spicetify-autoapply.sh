#!/bin/bash
killall -9 spotify 2>/dev/null
sleep 1
if ! spicetify apply 2>/dev/null; then
    spicetify clear 2>/dev/null
    spicetify backup apply
fi
