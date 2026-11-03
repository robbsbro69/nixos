#!/usr/bin/env bash
b=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1); [ -n "$b" ] || exit 0
c=$(cat "$b/capacity"); s=$(cat "$b/status")
if [ "$s" = Charging ]; then i="󰂄"
elif [ "$c" -ge 90 ]; then i="󰁹"; elif [ "$c" -ge 60 ]; then i="󰂀"
elif [ "$c" -ge 30 ]; then i="󰁾"; elif [ "$c" -ge 15 ]; then i="󰁻"; else i="󰂃"; fi
echo "$i  $c%"
