import Quickshell
import Quickshell.Wayland
import QtQuick

// PomoZen.qml — tiny click-through timer pill at the top while a focus session hides the bar.
PanelWindow {
	id: zen
	screen: Quickshell.screens.length > 0 ? (root.focusedScreen ?? Quickshell.screens[0]) : undefined
	visible: pill.opacity > 0
	exclusionMode: ExclusionMode.Ignore
	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.namespace: "quickshell-pomozen"
	anchors { top: true }
	margins { top: 8 }
	implicitWidth: pill.width + 4
	implicitHeight: pill.height + 4
	color: "transparent"
	mask: Region { item: camBtn }   // only the camera button takes clicks

	Rectangle {
		id: pill
		anchors.centerIn: parent
		width: row.implicitWidth + 24
		height: 26
		radius: 13
		color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.82)
		border.width: 1
		border.color: Qt.rgba(root.pomoColor.r, root.pomoColor.g, root.pomoColor.b, 0.45)
		opacity: root.pomoZen && !root.barShown ? 0.9 : 0
		Behavior on opacity { NumberAnimation { duration: 300 } }
		Row {
			id: row
			anchors.centerIn: parent
			spacing: 8
			Text { text: "󰔟"; color: root.pomoColor; font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font"; anchors.verticalCenter: parent.verticalCenter }
			Text { text: root.pomoText; color: root.walForeground; font.pixelSize: 12; font.bold: true; font.family: "JetBrainsMono Nerd Font"; anchors.verticalCenter: parent.verticalCenter }
			Text { text: "focus · 󰂛"; color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; anchors.verticalCenter: parent.verticalCenter }
			// focus-cam: click = show / hide the live camera window
			Rectangle {
				id: camBtn
				visible: root.focusCamOn
				anchors.verticalCenter: parent.verticalCenter
				width: camRow.implicitWidth + 14
				height: 18
				radius: 9
				color: root.focusCamPreview
					? Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.25)
					: (camMa.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
				border.width: 1
				border.color: Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.5)
				Row {
					id: camRow
					anchors.centerIn: parent
					spacing: 5
					Rectangle {
						width: 6; height: 6; radius: 3
						color: root.walColor1
						anchors.verticalCenter: parent.verticalCenter
						SequentialAnimation on opacity {
							running: zen.visible
							loops: Animation.Infinite
							NumberAnimation { to: 0.25; duration: 800; easing.type: Easing.InOutSine }
							NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
						}
					}
					Text {
						text: root.focusCamPreview ? "󰄀 hide" : "󰄀 show"
						color: root.focusCamPreview ? root.walForeground : root.walColor8
						font.pixelSize: 10
						font.bold: root.focusCamPreview
						font.family: "JetBrainsMono Nerd Font"
						anchors.verticalCenter: parent.verticalCenter
					}
				}
				MouseArea {
					id: camMa
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: root.focusCamTogglePreview()
				}
			}
		}
		// thin progress line along the bottom
		Rectangle {
			anchors.bottom: parent.bottom; anchors.bottomMargin: 3
			x: 12; height: 2; radius: 1
			width: (parent.width - 24) * Math.max(0, Math.min(1, root.pomoProgress))
			color: root.pomoColor
			opacity: 0.8
		}
	}
}
