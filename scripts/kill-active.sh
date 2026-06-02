#!/bin/bash

read -r X Y <<< $(slurp -p -f '%x %y' 2>/dev/null) || exit 1

PID=$(hyprctl clients -j | jq -r --arg x "$X" --arg y "$Y" '
  .[] | select(
    .at[0] <= ($x | tonumber) and
    .at[0] + .size[0] >= ($x | tonumber) and
    .at[1] <= ($y | tonumber) and
    .at[1] + .size[1] >= ($y | tonumber)
  ) | .pid' | head -1)

[ -n "$PID" ] && [ "$PID" -gt 0 ] 2>/dev/null && kill -9 "$PID"
