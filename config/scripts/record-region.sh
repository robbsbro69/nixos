#!/usr/bin/env bash
if pgrep -x wf-recorder > /dev/null; then
    	pkill -INT -x wf-recorder
    	notify-send "Recording Stopped"
else
    	REGION=$(slurp)
    	[ -z "$REGION" ] && exit 0  # cancelled selection
    	notify-send "Recording Started (Region)"
    	wf-recorder -g "$REGION" -f ~/Videos/screen-recordings/$(date +%Y-%m-%d_%H-%M-%S).mp4
fi
