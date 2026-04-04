#!/usr/bin/env bash

# List all available players
players=$(playerctl -l 2>/dev/null)
[ -z "$players" ] && exit 0

# Show dropdown menu using wofi (you can use rofi too)
chosen=$(echo "$players" | fuzzel --dmenu --prompt "Select Player")

# Save selected player
if [ -n "$chosen" ]; then
    echo "$chosen" > ~/.config/waybar/scripts/active_player
fi
