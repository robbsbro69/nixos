#!/usr/bin/env bash

word=${1:-$(wl-paste --primary 2>/dev/null)}

if [[ -z "$word" ]]; then
    notify-send -h string:bgcolor:#bf616a -t 3000 "No text selected."
    exit 0
fi

query=$(curl -s --connect-timeout 5 --max-time 10 "https://api.dictionaryapi.dev/api/v2/entries/en_US/$(echo "$word" | sed 's/ /%20/g')")

if [[ $? -ne 0 ]]; then
    notify-send -h string:bgcolor:#bf616a -t 3000 "Connection error."
    exit 1
fi

if [[ "$query" == *"No Definitions Found"* ]]; then
    notify-send -h string:bgcolor:#bf616a -t 3000 "Invalid word."
    exit 0
fi

def=$(echo "$query" | jq -r '[.[].meanings[] | {pos: .partOfSpeech, def: .definitions[].definition}] | .[:3].[] | "\n\(.pos). \(.def)"')

# Send notification
notify-send -t 60000 "$word -" "$def"
