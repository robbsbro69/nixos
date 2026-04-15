#!/usr/bin/env bash

# File storing user's selected player
selected_player_file="$HOME/.config/waybar/scripts/active_player"

# Try user's preferred player
if [ -f "$selected_player_file" ]; then
    preferred_player=$(cat "$selected_player_file")
    status=$(playerctl -p "$preferred_player" status 2>/dev/null)

    if [[ "$status" == "Playing" || "$status" == "Paused" ]]; then
        title=$(playerctl -p "$preferred_player" metadata title 2>/dev/null)
        [ -z "$title" ] && title="Unknown Title"
        short_title=$(echo "$title" | cut -c1-40)
        icon=""
        [ "$status" = "Paused" ] && icon=""
        echo "$icon $short_title ▾"
        exit 0
    fi
fi

# Else scan for active players
players=($(playerctl -l 2>/dev/null))
count=0
for player in "${players[@]}"; do
    status=$(playerctl -p "$player" status 2>/dev/null)
    if [[ "$status" == "Playing" || "$status" == "Paused" ]]; then
        title=$(playerctl -p "$player" metadata title 2>/dev/null)
        [ -z "$title" ] && title="Unknown Title"
        short_title=$(echo "$title" | cut -c1-40)
        icon=""
        [ "$status" = "Paused" ] && icon=""
        ((count++))
        echo "$icon $short_title"
        exit 0
    fi
done

# Nothing found
echo " No music"
