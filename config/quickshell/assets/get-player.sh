#!/usr/bin/env bash

ACTIVE_PLAYER="${1:-%any}"

if [ "$ACTIVE_PLAYER" != "%any" ]; then
    best="$ACTIVE_PLAYER"
else
    # Non-browser Playing player first
    best=$(playerctl --list-all 2>/dev/null \
        | grep -iv 'firefox\|chromium\|brave\|chrome' \
        | while read -r p; do
            [ "$(playerctl --player="$p" status 2>/dev/null)" = "Playing" ] && echo "$p" && break
          done)

    # Any Playing player
    [ -z "$best" ] && best=$(playerctl --list-all 2>/dev/null \
        | while read -r p; do
            [ "$(playerctl --player="$p" status 2>/dev/null)" = "Playing" ] && echo "$p" && break
          done)

    # Fallback: first non-browser
    [ -z "$best" ] && best=$(playerctl --list-all 2>/dev/null \
        | grep -iv 'firefox\|chromium\|brave\|chrome' | head -1)

    # Last resort
    [ -z "$best" ] && best=$(playerctl --list-all 2>/dev/null | head -1)
fi

[ -z "$best" ] && echo "status:Stopped" && exit 0

status=$(playerctl --player="$best" status 2>/dev/null || echo "Stopped")
title=$(playerctl --player="$best" metadata title 2>/dev/null)
artist=$(playerctl --player="$best" metadata artist 2>/dev/null)
arturl=$(playerctl --player="$best" metadata mpris:artUrl 2>/dev/null)
pos=$(playerctl --player="$best" position 2>/dev/null | cut -d. -f1)
rawlen=$(playerctl --player="$best" metadata mpris:length 2>/dev/null)
len=$(( ${rawlen:-0} / 1000000 ))

echo "player:$best"
echo "status:$status"
echo "title:$title"
echo "artist:$artist"
echo "arturl:$arturl"
echo "pos:${pos:-0}"
echo "len:$len"
