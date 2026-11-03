#!/usr/bin/env bash
# prints a path to the current album art for hyprlock (a blank png when nothing plays)
blank=$HOME/nixos-dotfiles/config/hypr/hyprlock/blank.png
[ -s "$blank" ] || printf '%s' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==' | base64 -d >"$blank"
st=$(playerctl status 2>/dev/null)
url=$(playerctl metadata mpris:artUrl 2>/dev/null)
if { [ "$st" != Playing ] && [ "$st" != Paused ]; } || [ -z "$url" ]; then echo "$blank"; exit 0; fi
case $url in
  file://*) p=${url#file://}; printf '%b\n' "${p//%/\\x}" ;;
  http*)
    out="/tmp/hyprlock-art-$(printf '%s' "$url" | md5sum | cut -c1-12).jpg"
    [ -s "$out" ] || { rm -f /tmp/hyprlock-art-*.jpg; curl -sL -m 4 -o "$out" "$url" || rm -f "$out"; }
    [ -s "$out" ] && echo "$out" || echo "$blank" ;;
  *) echo "$blank" ;;
esac
