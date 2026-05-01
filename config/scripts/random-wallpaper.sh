#!/usr/bin/env bash

WALL_DIR="$HOME/wallpapers"

selected_path=$(find "$WALL_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.png' -o -iname '*.webp' \) ! -name ".*" | shuf -n1)

if [ -f "$selected_path" ]; then
	qs ipc call randomwallpaper apply "$selected_path"
fi
