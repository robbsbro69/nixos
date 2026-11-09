#!/usr/bin/env bash
# What the bar/music panel shows. Rules:
#   • something Playing → show it (real players before browser tabs)
#   • nothing Playing → keep showing the player you paused, but only for 5 minutes
#   • otherwise → blank (every field printed empty, so no stale title is left behind)
export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"
ACTIVE_PLAYER="${1:-%any}"
BROWSERS='firefox\|chromium\|brave\|chrome\|zen\|librewolf\|vivaldi'
LAST="${XDG_RUNTIME_DIR:-/tmp}/qs-last-player"
GRACE=300

blank() { printf 'player:\nstatus:Stopped\nurl:\ntitle:\nartist:\narturl:\npos:0\nlen:0\n'; exit 0; }
st() { playerctl --player="$1" status 2>/dev/null; }

all=$(playerctl --list-all 2>/dev/null)
best=""
if [ "$ACTIVE_PLAYER" != "%any" ]; then
    best="$ACTIVE_PLAYER"
else
    for p in $(echo "$all" | grep -iv "$BROWSERS") $(echo "$all" | grep -i "$BROWSERS"); do
        [ "$(st "$p")" = "Playing" ] && { best=$p; break; }
    done
    if [ -n "$best" ]; then
        echo "$best $(date +%s)" > "$LAST"
    elif [ -f "$LAST" ]; then
        read -r lp lt < "$LAST"
        if [ $(( $(date +%s) - ${lt:-0} )) -lt $GRACE ] && echo "$all" | grep -qxF "$lp" && [ "$(st "$lp")" = "Paused" ]; then
            best=$lp
        fi
    fi
fi

[ -z "$best" ] && blank
status=$(st "$best"); status=${status:-Stopped}
[ "$status" = "Stopped" ] && blank
title=$(playerctl --player="$best" metadata title 2>/dev/null)
[ -z "$title" ] && blank

url=$(playerctl --player="$best" metadata xesam:url 2>/dev/null)
artist=$(playerctl --player="$best" metadata artist 2>/dev/null)
arturl=$(playerctl --player="$best" metadata mpris:artUrl 2>/dev/null)
pos=$(playerctl --player="$best" position 2>/dev/null | cut -d. -f1)
rawlen=$(playerctl --player="$best" metadata mpris:length 2>/dev/null)
len=$(( ${rawlen:-0} / 1000000 ))

echo "player:$best"
echo "status:$status"
echo "url:$url"
echo "title:$title"
echo "artist:$artist"
echo "arturl:$arturl"
echo "pos:${pos:-0}"
echo "len:$len"
