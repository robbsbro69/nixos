#!/usr/bin/env bash
# next schedule block (or next release) from Jarvis for the lock screen; keeps last answer when offline
cache=/tmp/hyprlock-jarvis.txt
set -a; . ~/.config/jarvis/client.env 2>/dev/null; set +a
[ -n "$JARVIS_URL" ] || exit 0
json=$(curl -s -m 3 -H "Authorization: Bearer $JARVIS_TOKEN" "$JARVIS_URL/api/today") || json=""
if [ -n "$json" ]; then
  line=$(printf '%s' "$json" | python3 -c '
import sys, json, datetime
d = json.load(sys.stdin); now = datetime.datetime.now().strftime("%H:%M")
for s in d.get("schedule") or []:
    if (s.get("end") or s.get("start") or "") > now:
        t = s.get("start") or ""
        print(("󰚩  " + (t + "  ·  " if t > now else "now  ·  ") + s.get("title", ""))[:70]); sys.exit()
for u in d.get("upcoming") or []:
    print(("󰚩  " + u.get("title", "") + "  ·  " + str(u.get("when", "")))[:70]); sys.exit()
' 2>/dev/null)
  printf '%s\n' "$line" >"$cache"
fi
cat "$cache" 2>/dev/null
