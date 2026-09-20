#!/usr/bin/env bash
# ~/.config/scripts/toggle-pomodoro-bomb.sh
if pgrep -x pomodoro-bomb >/dev/null; then
    pkill -x pomodoro-bomb
else
    pomodoro-bomb &
    disown
fi
