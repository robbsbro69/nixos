#!/usr/bin/env bash

status=$(wlr-randr | awk '/^eDP-1/{flag=1} flag && /Enabled:/ {print $2; exit}')

if [ "$status" = "yes" ]; then
    wlr-randr --output eDP-1 --off
else
    wlr-randr --output eDP-1 --on
fi
