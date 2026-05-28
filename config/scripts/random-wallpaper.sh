#!/usr/bin/env bash
WALL_DIR="$HOME/wallpapers"
CACHE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper-shuffle"
CACHE_FILE="$CACHE_DIR/queue"
LAST_FILE="$CACHE_DIR/last"
mkdir -p "$CACHE_DIR"

build_fresh_queue() {
    local last=""
    [ -f "$LAST_FILE" ] && last=$(cat "$LAST_FILE")
    if [ -n "$last" ] && [ -f "$last" ]; then
        { find "$WALL_DIR" -maxdepth 1 -type f -not -name ".*" \
              \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' \
                 -o -iname '*.png' -o -iname '*.webp' \) \
            | grep -vxF "$last" | shuf --random-source=/dev/urandom
          echo "$last"
        }
    else
        find "$WALL_DIR" -maxdepth 1 -type f -not -name ".*" \
            \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' \
               -o -iname '*.png' -o -iname '*.webp' \) \
            | shuf --random-source=/dev/urandom
    fi > "$CACHE_FILE"
}

if [ ! -s "$CACHE_FILE" ]; then
    build_fresh_queue
else
    TMP=$(mktemp)
    while IFS= read -r line; do
        [ -f "$line" ] && echo "$line"
    done < "$CACHE_FILE" > "$TMP"
    if [ ! -s "$TMP" ]; then
        rm -f "$TMP"
        build_fresh_queue
    else
        mv "$TMP" "$CACHE_FILE"
    fi
fi

selected_path=$(head -n1 "$CACHE_FILE")
if [ -n "$selected_path" ] && [ -f "$selected_path" ]; then
    TMP=$(mktemp)
    tail -n +2 "$CACHE_FILE" > "$TMP"
    mv "$TMP" "$CACHE_FILE"
    echo "$selected_path" > "$LAST_FILE"
    qs ipc call randomwallpaper apply "$selected_path"
fi
