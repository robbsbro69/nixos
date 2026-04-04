#!/usr/bin/env bash

# Simple unread notification counter (dummy - adjust as needed)
icon=""  # Font Awesome bell icon (requires Nerd Font)

if dunstctl is-paused | grep -q true; then
    echo "{\"text\": \"$icon\", \"tooltip\": \"Dunst is paused\", \"class\": \"paused\"}"
else
    echo "{\"text\": \"$icon\", \"tooltip\": \"Click to show history\", \"class\": \"active\"}"
fi
