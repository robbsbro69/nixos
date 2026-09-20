pragma Singleton
import QtQuick

QtObject {
	// Monochrome — grayscale
	readonly property color bg:      "#1a1a1a"
	readonly property color fg:      "#e0e0e0"
	readonly property color accent:  "#d9d9d9"  // light gray, was pink
	readonly property color green:   "#b0b0b0"
	readonly property color red:     "#f2f2f2"
	readonly property color yellow:  "#999999"
	readonly property color surface: "#2a2a2a"
	readonly property color dim:     "#6c6c6c"

	function a(c, o) {
		return Qt.rgba(c.r, c.g, c.b, o)
	}
}
