import Quickshell
import Quickshell.Wayland
import QtQuick

// WallCarousel.qml — skewed wallpaper carousel (Super+W).
//   ← / → / h / l / scroll : browse      Enter / click centre : apply
//   click a side card      : jump to it   Esc / click outside  : close
// The list is re-read every time it opens, so new files in ~/wallpapers show up straight away.

PanelWindow {
	id: wc
	screen: root.focusedScreen ?? Quickshell.screens[0]
	visible: root.wallCarouselVisible || fade.running
	exclusionMode: ExclusionMode.Ignore
	anchors { top: true; bottom: true; left: true; right: true }
	color: "transparent"
	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.namespace: "wallcarousel"
	WlrLayershell.keyboardFocus: root.wallCarouselVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

	readonly property real cardW: Math.min(460, width * 0.30)
	readonly property real cardH: cardW * 0.56
	readonly property real skew: -0.22          // parallelogram lean
	readonly property var walls: root.wallpaperList

	function indexOfCurrent() {
		for (var i = 0; i < walls.length; i++) if (walls[i].path === root.currentWallpaper) return i
		return 0
	}
	function close() { root.wallCarouselVisible = false }
	function applyCurrent() {
		var w = walls[list.currentIndex]
		if (w) root.applyWallpaper(w)
		close()
	}

	Connections {
		target: root
		function onWallCarouselVisibleChanged() {
			if (root.wallCarouselVisible) { list.positionViewAtIndex(wc.indexOfCurrent(), ListView.Center); list.currentIndex = wc.indexOfCurrent(); keys.forceActiveFocus() }
		}
		function onWallpaperListChanged() {
			// the list is replaced on every open; keep the view on the current wallpaper
			if (root.wallCarouselVisible) Qt.callLater(function() {
				list.currentIndex = wc.indexOfCurrent()
				list.positionViewAtIndex(list.currentIndex, ListView.Center)
			})
		}
	}

	Item {
		id: content
		anchors.fill: parent
		opacity: root.wallCarouselVisible ? 1 : 0
		Behavior on opacity { NumberAnimation { id: fade; duration: 180; easing.type: Easing.OutCubic } }

		// dim backdrop — click outside to close
		Rectangle {
			anchors.fill: parent
			color: Qt.rgba(0, 0, 0, 0.45)
			MouseArea { anchors.fill: parent; onClicked: wc.close() }
		}

		Item {
			id: keys
			anchors.fill: parent
			focus: true
			Keys.onPressed: function(e) {
				if (e.key === Qt.Key_Escape) { wc.close(); e.accepted = true }
				else if (e.key === Qt.Key_Right || e.key === Qt.Key_L) { list.incrementCurrentIndex(); e.accepted = true }
				else if (e.key === Qt.Key_Left || e.key === Qt.Key_H) { list.decrementCurrentIndex(); e.accepted = true }
				else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { wc.applyCurrent(); e.accepted = true }
			}
		}

		ListView {
			id: list
			anchors.verticalCenter: parent.verticalCenter
			width: parent.width
			height: wc.cardH * 1.5
			orientation: ListView.Horizontal
			model: wc.walls
			spacing: -wc.cardW * 0.18
			clip: false
			cacheBuffer: wc.cardW * 3
			highlightRangeMode: ListView.StrictlyEnforceRange
			preferredHighlightBegin: (width - wc.cardW) / 2
			preferredHighlightEnd: (width + wc.cardW) / 2
			highlightMoveDuration: 260
			boundsBehavior: Flickable.StopAtBounds
			keyNavigationEnabled: false
			interactive: true

			WheelHandler {
				property real acc: 0
				onWheel: function(ev) {
					acc += ev.angleDelta.y !== 0 ? ev.angleDelta.y : ev.angleDelta.x
					while (acc >= 120) { list.decrementCurrentIndex(); acc -= 120 }
					while (acc <= -120) { list.incrementCurrentIndex(); acc += 120 }
				}
			}

			delegate: Item {
				id: cell
				required property var modelData
				required property int index
				readonly property int dist: Math.abs(index - list.currentIndex)
				readonly property bool centre: dist === 0
				width: wc.cardW
				height: list.height
				z: 100 - dist

				Rectangle {
					id: card
					anchors.centerIn: parent
					width: wc.cardW
					height: wc.cardH
					radius: 6
					clip: true
					antialiasing: true
					color: root.card(0.6)
					scale: cell.centre ? 1.28 : Math.max(0.6, 0.9 - (cell.dist - 1) * 0.1)
					opacity: cell.centre ? 1 : Math.max(0.25, 0.85 - (cell.dist - 1) * 0.25)
					border.width: cell.centre ? 2 : 0
					border.color: root.walColor13
					Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
					Behavior on opacity { NumberAnimation { duration: 260 } }
					transform: Matrix4x4 {
						// shear around the card centre so it leans like a parallelogram
						matrix: Qt.matrix4x4(1, wc.skew, 0, -wc.skew * card.height / 2,
						                     0, 1, 0, 0,
						                     0, 0, 1, 0,
						                     0, 0, 0, 1)
					}

					Image {
						anchors.fill: parent
						source: "file://" + cell.modelData.path
						fillMode: Image.PreserveAspectCrop
						asynchronous: true
						cache: true
						smooth: true
						sourceSize.width: 720
					}
					// subtle tint on the non-selected ones
					Rectangle {
						anchors.fill: parent
						color: "black"
						opacity: cell.centre ? 0 : 0.25
						Behavior on opacity { NumberAnimation { duration: 260 } }
					}
					// "current" dot
					Rectangle {
						visible: cell.modelData.path === root.currentWallpaper
						width: 8; height: 8; radius: 4
						anchors { top: parent.top; right: parent.right; margins: 8 }
						color: root.walColor13
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: cell.centre ? wc.applyCurrent() : (list.currentIndex = cell.index)
					}
				}
			}
		}

		// name + position under the carousel
		Column {
			anchors.horizontalCenter: parent.horizontalCenter
			anchors.top: list.bottom
			anchors.topMargin: 6
			spacing: 4
			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				text: wc.walls.length ? (wc.walls[list.currentIndex] ? wc.walls[list.currentIndex].name : "") : "No wallpapers in ~/wallpapers"
				color: root.walForeground
				font.pixelSize: 14
				font.bold: true
				font.family: "JetBrainsMono Nerd Font"
			}
			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				text: wc.walls.length ? (list.currentIndex + 1) + " / " + wc.walls.length + "   ·   ← → browse · enter apply · esc close" : ""
				color: Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.6)
				font.pixelSize: 10
				font.family: "JetBrainsMono Nerd Font"
			}
		}
	}
}
