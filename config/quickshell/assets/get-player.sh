#!/usr/bin/env bash
export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"
ACTIVE_PLAYER="${1:-%any}"

if [ "$ACTIVE_PLAYER" != "%any" ]; then
    best="$ACTIVE_PLAYER"
else
    # 1. Any Playing player (priority order: non-browser first, then browser)
    best=$(playerctl --list-all 2>/dev/null \
        | grep -iv 'firefox\|chromium\|brave\|chrome' \
        | while read -r p; do
            [ "$(playerctl --player="$p" status 2>/dev/null)" = "Playing" ] && echo "$p" && break
          done)

    # 2. Browser Playing player
    [ -z "$best" ] && best=$(playerctl --list-all 2>/dev/null \
        | grep -i 'firefox\|chromium\|brave\|chrome' \
        | while read -r p; do
            [ "$(playerctl --player="$p" status 2>/dev/null)" = "Playing" ] && echo "$p" && break
          done)

    # 3. Browser Paused player (prefer browser over stopped spotify)
    [ -z "$best" ] && best=$(playerctl --list-all 2>/dev/null \
        | grep -i 'firefox\|chromium\|brave\|chrome' \
        | while read -r p; do
            [ "$(playerctl --player="$p" status 2>/dev/null)" = "Paused" ] && echo "$p" && break
          done)

    # 4. Non-browser Paused player
    [ -z "$best" ] && best=$(playerctl --list-all 2>/dev/null \
        | grep -iv 'firefox\|chromium\|brave\|chrome' \
        | while read -r p; do
            [ "$(playerctl --player="$p" status 2>/dev/null)" = "Paused" ] && echo "$p" && break
          done)

    # 5. Last resort - anything
    [ -z "$best" ] && best=$(playerctl --list-all 2>/dev/null | head -1)
fi

[ -z "$best" ] && echo "status:Stopped" && exit 0

status=$(playerctl --player="$best" status 2>/dev/null || echo "Stopped")

# Suppress stopped Spotify so bar goes blank
if [ "$status" = "Stopped" ] && echo "$best" | grep -qi "spotify"; then
    echo "player:$best"
    echo "status:Stopped"
    echo "title:"
    echo "artist:"
    echo "arturl:"
    echo "pos:0"
    echo "len:0"
    exit 0
fi

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
