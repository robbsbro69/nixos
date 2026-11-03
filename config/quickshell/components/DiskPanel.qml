import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// DiskPanel.qml — every drive, and which folders use the space (click a folder to go inside).
// Data: assets/sysinfo.py (df + du). Opened from the bar's DISK block.

PanelWindow {
	id: dp
	screen: Quickshell.screens.length > 0 ? (root.focusedScreen ?? Quickshell.screens[0]) : undefined
	visible: true
	exclusionMode: ExclusionMode.Ignore
	anchors {
		bottom: root.barPosition !== "top"
		right: true
		top: root.barPosition === "top"
	}
	margins {
		bottom: root.diskPanelVisible ? root.barGapV : -(implicitHeight + 20)
		right: (typeof root.popRightAt === "function" ? root.popRightAt(popC, implicitWidth, screen) : 6) + root.barInsetRight
		top: root.diskPanelVisible ? root.barGapV : -(implicitHeight + 20)
	}
	property real popC: -1
	Connections { target: root; function onDiskPanelVisibleChanged() { if (root.diskPanelVisible) { dp.popC = root.i3PopCenter ?? -1; dp.opened() } } }
	implicitWidth: 360
	implicitHeight: card.implicitHeight
	color: "transparent"
	focusable: true
	WlrLayershell.keyboardFocus: root.diskPanelVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
	Behavior on margins.bottom { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
	Behavior on margins.top { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

	readonly property string script: root.configPath + "/assets/sysinfo.py"
	property var drives: []
	property string curDir: ""
	property string curRoot: ""          // the drive's starting folder (no "back" above it)
	property var listing: null
	property bool scanning: false
	property var cache: ({})

	function gib(b) {
		var g = b / 1073741824
		return g >= 100 ? Math.round(g) + " G" : g >= 1 ? g.toFixed(1) + " G" : Math.round(b / 1048576) + " M"
	}
	function opened() {
		if (!drivesProc.running) drivesProc.running = true
		if (curDir !== "") browse(curDir, false)
	}
	function browse(dir, fresh) {
		curDir = dir
		if (!fresh && cache[dir]) { listing = cache[dir]; return }
		listing = null
		scanning = true
		duProc.running = false
		duProc.command = ["python3", script, "disk", dir]
		Qt.callLater(function() { duProc.running = true })
	}

	Process {
		id: drivesProc
		command: ["python3", dp.script, "drives"]
		stdout: StdioCollector {
			onStreamFinished: {
				try {
					var o = JSON.parse(this.text)
					if (!o.ok) return
					dp.drives = o.drives
					if (dp.curDir === "" && o.drives.length > 0) { dp.curRoot = o.drives[0].start; dp.browse(o.drives[0].start, false) }
				} catch (e) {}
			}
		}
	}
	Process {
		id: duProc
		stdout: StdioCollector {
			onStreamFinished: {
				dp.scanning = false
				try {
					var o = JSON.parse(this.text)
					if (o.ok) { var c = dp.cache; c[o.dir] = o; dp.cache = c; if (o.dir === dp.curDir) dp.listing = o }
					else dp.listing = { ok: false, why: o.why, items: [] }
				} catch (e) { dp.listing = { ok: false, why: "couldn't read the folder", items: [] } }
			}
		}
	}

	Item {
		anchors.fill: parent
		focus: root.diskPanelVisible
		Keys.onPressed: function(event) {
			if (event.key === Qt.Key_Escape) { root.diskPanelVisible = false; event.accepted = true }
			else if ((event.key === Qt.Key_Backspace || event.key === Qt.Key_Left) && dp.listing && dp.listing.parent && dp.curDir !== dp.curRoot) {
				dp.browse(dp.listing.parent, false); event.accepted = true
			}
		}

		Rectangle {
			id: card
			width: parent.width
			anchors.bottom: parent.bottom
			implicitHeight: col.implicitHeight + 28
			radius: 18
			color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.95)
			border.width: 1
			border.color: Qt.rgba(root.walColor4.r, root.walColor4.g, root.walColor4.b, 0.4)

			ColumnLayout {
				id: col
				anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
				spacing: 8

				// header
				RowLayout {
					Layout.fillWidth: true
					spacing: 8
					Text { textFormat: Text.PlainText; text: "󰋊"; color: root.walColor4; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font" }
					Text { textFormat: Text.PlainText; text: "Disk"; color: root.walColor5; font.pixelSize: 15; font.bold: true; font.family: "JetBrainsMono Nerd Font"; Layout.fillWidth: true }
					Rectangle {
						width: 24; height: 24; radius: 8
						color: rfMa.containsMouse ? root.hover(0.08) : root.card(0.3)
						Text { textFormat: Text.PlainText; anchors.centerIn: parent; text: "󰑓"; color: root.walColor8; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font" }
						MouseArea { id: rfMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
							onClicked: { dp.cache = ({}); drivesProc.running = true; if (dp.curDir) dp.browse(dp.curDir, true) } }
					}
				}

				// drives
				Repeater {
					model: dp.drives
					delegate: Rectangle {
						id: drv
						required property var modelData
						readonly property bool sel: dp.curRoot === modelData.start
						readonly property real frac: modelData.total > 0 ? modelData.used / modelData.total : 0
						Layout.fillWidth: true
						Layout.preferredHeight: 44
						radius: 11
						color: sel ? Qt.rgba(root.walColor4.r, root.walColor4.g, root.walColor4.b, 0.14) : (drvMa.containsMouse ? root.hover(0.05) : root.card(0.3))
						border.width: sel ? 1 : 0
						border.color: Qt.rgba(root.walColor4.r, root.walColor4.g, root.walColor4.b, 0.45)
						ColumnLayout {
							anchors.fill: parent
							anchors.margins: 9
							spacing: 5
							RowLayout {
								Layout.fillWidth: true
								Text { textFormat: Text.PlainText; text: drv.modelData.name === "/" ? "󰋊  system  /" : "󰋊  " + drv.modelData.name + "  " + drv.modelData.mount
									color: root.walForeground; font.pixelSize: 11; font.bold: true; font.family: "JetBrainsMono Nerd Font"; Layout.fillWidth: true; elide: Text.ElideRight }
								Text { textFormat: Text.PlainText; text: dp.gib(drv.modelData.used) + " / " + dp.gib(drv.modelData.total) + "  ·  " + dp.gib(drv.modelData.free) + " free"
									color: root.walColor8; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font" }
							}
							Rectangle {
								Layout.fillWidth: true; Layout.preferredHeight: 5; radius: 2.5; color: root.card(0.5)
								Rectangle { width: parent.width * Math.min(1, drv.frac); height: parent.height; radius: 2.5
									color: drv.frac > 0.9 ? root.walColor1 : drv.frac > 0.75 ? root.walPeach : root.walColor4 }
							}
						}
						MouseArea { id: drvMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
							onClicked: { dp.curRoot = drv.modelData.start; dp.browse(drv.modelData.start, false) } }
					}
				}

				// where we are
				RowLayout {
					Layout.fillWidth: true
					Layout.topMargin: 2
					spacing: 6
					Rectangle {
						readonly property bool can: dp.listing && dp.listing.parent && dp.curDir !== dp.curRoot
						visible: can
						width: 24; height: 22; radius: 7
						color: upMa.containsMouse ? root.hover(0.08) : root.card(0.35)
						Text { textFormat: Text.PlainText; anchors.centerIn: parent; text: "󰁍"; color: root.walColor8; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font" }
						MouseArea { id: upMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dp.browse(dp.listing.parent, false) }
					}
					Text {
						textFormat: Text.PlainText
						text: dp.curDir.replace(/^\/home\/[^\/]+/, "~")
						color: root.walForeground; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
						elide: Text.ElideMiddle; Layout.fillWidth: true
					}
					Text { textFormat: Text.PlainText; visible: !!(dp.listing && dp.listing.total); text: dp.listing ? dp.gib(dp.listing.total || 0) : ""
						color: root.walColor4; font.pixelSize: 10; font.bold: true; font.family: "JetBrainsMono Nerd Font" }
					Rectangle {
						width: openRow.implicitWidth + 12; height: 22; radius: 7
						color: opMa.containsMouse ? root.hover(0.08) : root.card(0.35)
						Row { id: openRow; anchors.centerIn: parent; spacing: 4
							Text { textFormat: Text.PlainText; text: "󰉋"; color: root.walColor4; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font" }
							Text { textFormat: Text.PlainText; text: "open"; color: root.walColor8; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font" } }
						MouseArea { id: opMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
							onClicked: { root.diskPanelVisible = false
								Quickshell.execDetached(["bash", "-c", 'if command -v thunar >/dev/null; then thunar "$1"; else xdg-open "$1"; fi', "_", dp.curDir]) } }
					}
				}

				// folders
				Text {
					visible: dp.scanning
					textFormat: Text.PlainText
					text: "󰔟  measuring folders…  (big ones like ~/Videos take a few seconds)"
					color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
					Layout.fillWidth: true; wrapMode: Text.WordWrap; Layout.leftMargin: 4
				}
				Text {
					visible: !dp.scanning && dp.listing && dp.listing.ok === false
					textFormat: Text.PlainText
					text: "couldn't read this folder" + (dp.listing && dp.listing.why ? " — " + dp.listing.why : "")
					color: root.walColor1; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; Layout.leftMargin: 4
				}
				Repeater {
					model: !dp.scanning && dp.listing ? dp.listing.items : []
					delegate: Rectangle {
						id: fr
						required property var modelData
						readonly property real frac: dp.listing && dp.listing.total > 0 ? modelData.bytes / dp.listing.total : 0
						Layout.fillWidth: true
						Layout.preferredHeight: 26
						radius: 8
						color: frMa.containsMouse && modelData.dir ? root.hover(0.06) : "transparent"
						Rectangle {   // share of this folder, as a soft bar behind the row
							anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
							width: parent.width * Math.min(1, fr.frac); radius: 8
							color: Qt.rgba(root.walColor4.r, root.walColor4.g, root.walColor4.b, 0.12)
						}
						RowLayout {
							anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
							Text { textFormat: Text.PlainText; text: fr.modelData.dir ? "󰉋" : "󰈔"; color: fr.modelData.dir ? root.walColor4 : root.walColor8; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font" }
							Text { textFormat: Text.PlainText; text: fr.modelData.name; color: root.walForeground; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; elide: Text.ElideRight; Layout.fillWidth: true }
							Text { textFormat: Text.PlainText; text: Math.round(fr.frac * 100) + "%"; color: root.walColor8; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font" }
							Text { textFormat: Text.PlainText; text: dp.gib(fr.modelData.bytes); color: fr.frac > 0.3 ? root.walPeach : root.walForeground
								font.pixelSize: 10; font.bold: true; font.family: "JetBrainsMono Nerd Font"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 52 }
						}
						MouseArea { id: frMa; anchors.fill: parent; hoverEnabled: true; enabled: fr.modelData.dir
							cursorShape: fr.modelData.dir ? Qt.PointingHandCursor : Qt.ArrowCursor
							onClicked: dp.browse(fr.modelData.path, false) }
					}
				}
				Text {
					visible: !dp.scanning && dp.listing && dp.listing.more > 0
					textFormat: Text.PlainText
					text: "+ " + (dp.listing ? dp.listing.more : 0) + " smaller items"
					color: root.walColor8; opacity: 0.7; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; Layout.leftMargin: 8
				}

				// footer
				Rectangle {
					Layout.fillWidth: true; Layout.preferredHeight: 22; radius: 8; color: root.card(0.3)
					RowLayout { anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
						Text { textFormat: Text.PlainText; text: "click folder · go inside"; color: root.walColor8; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; opacity: 0.7 }
						Item { Layout.fillWidth: true }
						Text { textFormat: Text.PlainText; text: "⌫ back"; color: root.walColor8; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; opacity: 0.7 }
						Item { Layout.fillWidth: true }
						Text { textFormat: Text.PlainText; text: "esc close"; color: root.walColor8; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; opacity: 0.7 }
					}
				}
			}
		}
	}

	Connections { target: root; function onDiskPanelVisibleChanged() { if (root.diskPanelVisible) dpFocus.start() } }
	Timer { id: dpFocus; interval: 50; onTriggered: { dp.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive; dpRelease.start() } }
	Timer { id: dpRelease; interval: 100; onTriggered: dp.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand }
}
