#!/usr/bin/env bash
# record.sh — wf-recorder wrapper used by the Quickshell recorder menu.
#
#   record.sh full            record the focused monitor
#   record.sh output NAME     record a specific output (e.g. HDMI-A-1, eDP-1)
#   record.sh region          pick an area with slurp
#   record.sh stop            stop the running recording
#   record.sh toggle          stop if recording, otherwise record the focused monitor
#   record.sh status          prints "recording" or "idle"
#
# Recorder: gpu-screen-recorder when installed (hardware encoding, correct timestamps —
# wf-recorder on this Hyprland stops advancing timestamps after ~40 s), else wf-recorder.
#
# Why it's built like this:
#   * records to .mkv first — an .mkv is still playable even if wf-recorder hangs or has to be
#     killed (an .mp4 without its ending is unplayable). After stopping it's remuxed to .mp4
#     (no re-encode, takes a second).
#   * constant 30 fps + x264 "ultrafast" so the encoder never falls behind and stalls.
#   * a watchdog stops + saves the recording if the file stops growing for 20 s, and tells you.
#   * stop escalates INT → TERM → KILL, so the timer in the bar can't keep running forever.
#   * wf-recorder's own messages go to ~/.cache/qs-record.log

DIR="$HOME/Videos/screen-recordings"
RUN="${XDG_RUNTIME_DIR:-/tmp}"
STATE="$RUN/qs-record.last"
LOG="$HOME/.cache/qs-record.log"
mkdir -p "$DIR" "$(dirname "$LOG")"

# NixOS runs gsr as ".gpu-screen-recorder-wrapped", so match both names
GSR_RE='gpu-screen-recorder(-wrapped)? -w'
is_recording() { pgrep -x wf-recorder >/dev/null || pgrep -f "$GSR_RE" >/dev/null; }
rec_kill() { pkill "-$1" -x wf-recorder 2>/dev/null; pkill "-$1" -f "$GSR_RE" 2>/dev/null; true; }
# sound: what's playing on the laptop is recorded by default.
#   RECORD_AUDIO=none   no sound      RECORD_AUDIO=both   laptop sound + microphone
AUDIO="${RECORD_AUDIO:-$(cat "$HOME/.config/quickshell/state/record-audio" 2>/dev/null || echo desktop)}"
have_gsr() { command -v gpu-screen-recorder >/dev/null; }
notify() { notify-send -a Recorder "$@" 2>/dev/null || true; }
# facecam: phone camera window in the corner while recording (state/record-camera: off|front|back)
FOCUSCAM="$HOME/nixos-private/scripts/focuscam.sh"
CAMERA="${RECORD_CAMERA:-$(cat "$HOME/.config/quickshell/state/record-camera" 2>/dev/null || echo off)}"
cam_on() {
	case "$CAMERA" in front | back) ;; *) [ -x "$FOCUSCAM" ] && "$FOCUSCAM" overlay off; return 0 ;; esac
	[ -x "$FOCUSCAM" ] || return 0
	"$FOCUSCAM" overlay on "$CAMERA"
	sleep 2.5 # let the window appear before the recording starts
}
cam_off() { [ -x "$FOCUSCAM" ] && "$FOCUSCAM" overlay off; true; }

start() {
	# start -o OUTPUT | start -g "X,Y WxH" | start   (whole screen)
	if is_recording; then
		notify "Already recording" "Stop the current recording first."
		exit 0
	fi
	cam_on
	local base="$DIR/$(date +%Y-%m-%d_%H-%M-%S)"
	echo "$base" >"$STATE"
	if have_gsr; then
		local target="screen" extra=()
		if [ "$1" = "-o" ]; then target="$2"
		elif [ "$1" = "-g" ]; then
			# slurp "X,Y WxH" → gsr "WxH+X+Y"
			local xy="${2%% *}" wh="${2##* }"
			target="region"; extra=(-region "${wh}+${xy%,*}+${xy#*,}")
		fi
		echo "=== $(date) — gpu-screen-recorder -w $target ${extra[*]}" >>"$LOG"
		local aud=()
		case "$AUDIO" in
			desktop) aud=(-a default_output) ;;
			both) aud=(-a "default_output|default_input") ;;
		esac
		setsid -f gpu-screen-recorder -w "$target" "${extra[@]}" -f 60 "${aud[@]}" -c mkv -o "$base.mkv" >>"$LOG" 2>&1
	else
		echo "=== $(date) — wf-recorder $*" >>"$LOG"
		local aud=()
		[ "$AUDIO" != none ] && aud=("--audio=$(pactl get-default-sink 2>/dev/null).monitor")
		setsid -f wf-recorder "$@" "${aud[@]}" -r 30 -c libx264 -p preset=ultrafast -p crf=23 -x yuv420p \
			-f "$base.mkv" >>"$LOG" 2>&1
	fi
	sleep 1.5
	if ! is_recording; then
		notify -u critical "Recording didn't start" "See ~/.cache/qs-record.log"
		rm -f "$STATE"
		cam_off
		exit 1
	fi
	setsid -f "$0" _watchdog "$base.mkv" >/dev/null 2>&1
}

finish() {
	# turn the .mkv into an .mp4 (stream copy); keep the .mkv if that fails
	local base mkv mp4
	base=$(cat "$STATE" 2>/dev/null)
	[ -z "$base" ] && return
	mkv="$base.mkv"; mp4="$base.mp4"
	[ -s "$mkv" ] || { notify -u critical "Recording failed" "Nothing was written — see ~/.cache/qs-record.log"; return; }
	if ffmpeg -nostdin -loglevel error -y -i "$mkv" -c copy -movflags +faststart "$mp4" >>"$LOG" 2>&1; then
		rm -f "$mkv"
		notify "Recording saved" "${mp4/#$HOME/\~}"
	else
		notify "Recording saved (mkv)" "${mkv/#$HOME/\~}"
	fi
	rm -f "$STATE"
}

stop() {
	is_recording || { [ -f "$STATE" ] && finish; cam_off; exit 0; }
	rec_kill INT
	for _ in $(seq 1 60); do is_recording || break; sleep 0.1; done
	if is_recording; then
		echo "--- recorder ignored SIGINT, sending TERM" >>"$LOG"
		rec_kill TERM
		for _ in $(seq 1 20); do is_recording || break; sleep 0.1; done
	fi
	if is_recording; then
		echo "--- recorder ignored TERM, killing" >>"$LOG"
		rec_kill KILL
		sleep 0.3
	fi
	finish
	cam_off
}

watchdog() {
	# runs next to the recording: if the file stops growing for 20 s, stop and save it
	local f="$1" last=-1 same=0 size
	sleep 6
	while is_recording; do
		size=$(stat -c %s "$f" 2>/dev/null || echo 0)
		if [ "$size" = "$last" ]; then same=$((same + 1)); else same=0; fi
		last=$size
		if [ "$same" -ge 4 ]; then
			echo "--- watchdog: $f stopped growing at $size bytes" >>"$LOG"
			notify -u critical "Recording stalled" "the recorder stopped writing — saved what was recorded."
			"$0" stop
			exit 0
		fi
		sleep 5
	done
}

focused_output() {
	hyprctl monitors -j | jq -r '.[] | select(.focused) | .name' | head -n1
}

case "$1" in
full)
	out=$(focused_output)
	if [ -n "$out" ]; then start -o "$out"; else start; fi
	;;
output)
	[ -z "$2" ] && { echo "usage: record.sh output NAME" >&2; exit 1; }
	start -o "$2"
	;;
region)
	is_recording && exit 0
	sleep 0.2 # let the menu slide away before slurp grabs the screen
	geom=$(slurp) || exit 0
	[ -z "$geom" ] && exit 0
	start -g "$geom"
	;;
stop) stop ;;
toggle)
	if is_recording; then stop; else "$0" full; fi
	;;
status)
	is_recording && echo recording || echo idle
	;;
_watchdog) watchdog "$2" ;;
*)
	echo "usage: record.sh {full|output NAME|region|stop|toggle|status}" >&2
	exit 1
	;;
esac
