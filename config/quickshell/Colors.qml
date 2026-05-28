pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
	id: colors
	property color bg:      "#1e1e2e"
    property color fg:      "#cdd6f4"
    property color accent:  "#f5c2e7"
    property color green:   "#a6e3a1"
    property color red:     "#f38ba8"
    property color yellow:  "#f9e2af"
    property color surface: "#313244"
    property color dim:     "#6c7086"
    	function a(c, o) { 
		return Qt.rgba(c.r, c.g, c.b, o) 
	}
	Process {
		id: walProc
		command: ["bash", "-c", "cat ~/.cache/wal/colors.json 2>/dev/null"]
		running: true
		stdout: SplitParser {
			splitMarker: ""
			onRead: data => {
				try {
					var j = JSON.parse(data)
					if (j.special) {
						colors.bg = j.special.background
						colors.fg = j.special.foreground
					}
					if (j.colors) {
						colors.accent  = j.colors.color5
						colors.green   = j.colors.color2
						colors.red     = j.colors.color1
						colors.yellow  = j.colors.color4
						colors.surface = j.colors.color0
						colors.dim     = j.colors.color8
					}
				} catch(e) {}
			}
		}
	}
}
