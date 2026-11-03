#!/usr/bin/env bash
# "▶ title / artist" for hyprlock (prints nothing when no player is active)
st=$(playerctl status 2>/dev/null) || exit 0
case $st in Playing) i="󰎈";; Paused) i="󰏤";; *) exit 0;; esac
esc() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }
t=$(playerctl metadata title 2>/dev/null | cut -c1-40 | esc)
a=$(playerctl metadata artist 2>/dev/null | cut -c1-40 | esc)
[ -n "$t" ] || exit 0
printf '<b>%s  %s</b>\n<span alpha="65%%">%s</span>\n' "$i" "$t" "$a"
