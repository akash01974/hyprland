#!/bin/bash

COORDS=$(slurp -p -f '%x,%y' 2>/dev/null) || exit 1
X=${COORDS%,*}
Y=${COORDS#*,}

# Get current active workspace ID
ACTIVE_WS=$(hyprctl activeworkspace -j | jq -r '.id')

PID=$(hyprctl clients -j | jq -r \
  --argjson x "$X" --argjson y "$Y" \
  --argjson ws "$ACTIVE_WS" '
  .[] | select(
    .workspace.id == $ws and
    .at[0]            <= $x and
    .at[0] + .size[0] >= $x and
    .at[1]            <= $y and
    .at[1] + .size[1] >= $y
  ) | .pid' | head -1)

if [[ -n "$PID" && "$PID" -gt 0 ]]; then
  kill -9 "$PID"
fi