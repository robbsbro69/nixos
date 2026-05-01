#!/usr/bin/env bash
if pgrep -x wf-recorder > /dev/null; then
    	pkill -INT -x wf-recorder
    	notify-send "Recording Stopped"
else
    	notify-send "Recording Started (Laptop)"
    	wf-recorder -o eDP-1 -f ~/Videos/screen-recordings/$(date +%Y-%m-%d_%H-%M-%S).mp4
fi
