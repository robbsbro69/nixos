#!/usr/bin/env bash

status=$(wlr-randr | awk '/^eDP-1/{flag=1} flag && /Enabled:/ {print $2; exit}')

if [ "$status" = "yes" ]; then
    echo "ON"   # laptop screen ON icon
else
    echo "OFF"   # laptop screen OFF icon
fi
