import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// MemPanel.qml — RAM use per app (helper processes grouped), with a two-click "close app".
// Data: assets/sysinfo.py mem (refreshes every 3 s while open). Opened from the bar's MEM block.

PanelWindow {
	id: mp
	screen: Quickshell.screens.length > 0 ? (root.focusedScreen ?? Quickshell.screens[0]) : undefined
	visible: true
	exclusionMode: ExclusionMode.Ignore
	anchors {
		bottom: root.barPosition !== "top"
		right: true
		top: root.barPosition === "top"
	}
	margins {
		bottom: root.memPanelVisible ? root.barGapV : -(implicitHeight + 20)
		right: (typeof root.popRightAt === "function" ? root.popRightAt(popC, implicitWidth, screen) : 6) + root.barInsetRight
		top: root.memPanelVisible ? root.barGapV : -(implicitHeight + 20)
	}
	property real popC: -1
	Connections { target: root; function onMemPanelVisibleChanged() { if (root.memPanelVisible) { mp.popC = root.i3PopCenter ?? -1; mp.armed = ""; mp.refresh() } } }
	implicitWidth: 340
	implicitHeight: card.implicitHeight
	color: "transparent"
	focusable: true
	WlrLayershell.keyboardFocus: root.memPanelVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
	Behavior on margins.bottom { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
	Behavior on margins.top { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

	readonly property string script: root.configPath + "/assets/sysinfo.py"
	property var info: null
	property string armed: ""            // app name waiting for the confirming second click
	property string msg: ""

	function gib(b) { var g = b / 1073741824; return g >= 1 ? g.toFixed(1) + " G" : Math.round(b / 1048576) + " M" }
	function refresh() { if (!memProc.running) memProc.running = true }
	function killApp(a) {
		if (!a.killable) return
		if (armed !== a.name) { armed = a.name; armTimer.restart(); return }
		var pids = a.pids.filter(function(p) { return /^[0-9]+$/.test("" + p) }).map(function(p) { return "" + p })
		if (pids.length === 0) return
		Quickshell.execDetached(["kill", "-TERM"].concat(pids))
		armed = ""
		msg = "closed " + a.name + " (" + gib(a.bytes) + " freed)"
		msgTimer.restart()
		afterKill.restart()
	}

	Process {
		id: memProc
		command: ["python3", mp.script, "mem"]
		stdout: StdioCollector { onStreamFinished: { try { var o = JSON.parse(this.text); if (o.ok) mp.info = o } catch (e) {} } }
	}
	Timer { interval: 3000; repeat: true; running: root.memPanelVisible; onTriggered: mp.refresh() }
	Timer { id: afterKill; interval: 900; onTriggered: mp.refresh() }
	Timer { id: armTimer; interval: 3000; onTriggered: mp.armed = "" }
	Timer { id: msgTimer; interval: 4000; onTriggered: mp.msg = "" }

	Item {
		anchors.fill: parent
		focus: root.memPanelVisible
		Keys.onPressed: function(event) {
			if (event.key === Qt.Key_Escape) { root.memPanelVisible = false; event.accepted = true }
		}

		Rectangle {
			id: card
			width: parent.width
			anchors.bottom: parent.bottom
			implicitHeight: col.implicitHeight + 28
			radius: 18
			color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.95)
			border.width: 1
			border.color: Qt.rgba(root.walColor2.r, root.walColor2.g, root.walColor2.b, 0.4)

			ColumnLayout {
				id: col
				anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
				spacing: 8

				RowLayout {
					Layout.fillWidth: true
					spacing: 8
					Text { textFormat: Text.PlainText; text: "󰍛"; color: root.walColor2; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font" }
					Text { textFormat: Text.PlainText; text: "Memory"; color: root.walColor5; font.pixelSize: 15; font.bold: true; font.family: "JetBrainsMono Nerd Font"; Layout.fillWidth: true }
					Text { textFormat: Text.PlainText; text: mp.info ? mp.gib(mp.info.used) + " / " + mp.gib(mp.info.total) : "…"
						color: root.walForeground; font.pixelSize: 11; font.bold: true; font.family: "JetBrainsMono Nerd Font" }
				}
				// RAM + swap bars
				Repeater {
					model: mp.info ? [{ l: "RAM", u: mp.info.used, t: mp.info.total }].concat(mp.info.swapTotal > 0 ? [{ l: "swap", u: mp.info.swapUsed, t: mp.info.swapTotal }] : []) : []
					delegate: RowLayout {
						id: br
						required property var modelData
						readonly property real frac: modelData.t > 0 ? modelData.u / modelData.t : 0
						Layout.fillWidth: true
						spacing: 8
						Text { textFormat: Text.PlainText; text: br.modelData.l; color: root.walColor8; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; Layout.preferredWidth: 30 }
						Rectangle {
							Layout.fillWidth: true; Layout.preferredHeight: 6; radius: 3; color: root.card(0.5)
							Rectangle { width: parent.width * Math.min(1, br.frac); height: parent.height; radius: 3
								color: br.frac > 0.9 ? root.walColor1 : br.frac > 0.75 ? root.walPeach : root.walColor2 }
						}
						Text { textFormat: Text.PlainText; text: Math.round(br.frac * 100) + "%"; color: root.walColor8; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; Layout.preferredWidth: 30; horizontalAlignment: Text.AlignRight }
					}
				}

				Text { textFormat: Text.PlainText; text: "BIGGEST APPS"; color: root.walColor8; font.pixelSize: 8; font.bold: true; font.letterSpacing: 1.2
					font.family: "JetBrainsMono Nerd Font"; Layout.topMargin: 4; Layout.leftMargin: 4 }

				Repeater {
					model: mp.info ? mp.info.apps : []
					delegate: Rectangle {
						id: ar
						required property var modelData
						readonly property real frac: mp.info && mp.info.total > 0 ? modelData.bytes / mp.info.total : 0
						readonly property bool isArmed: mp.armed === modelData.name
						Layout.fillWidth: true
						Layout.preferredHeight: 28
						radius: 8
						color: isArmed ? Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.15) : (arMa.containsMouse ? root.hover(0.05) : "transparent")
						Rectangle {
							anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
							width: parent.width * Math.min(1, ar.frac * 3); radius: 8   // ×3 so small apps still show a bar
							color: Qt.rgba(root.walColor2.r, root.walColor2.g, root.walColor2.b, 0.10)
						}
						RowLayout {
							anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 4; spacing: 8
							Text { textFormat: Text.PlainText; text: ar.modelData.name; color: root.walForeground; font.pixelSize: 10; font.bold: ar.frac > 0.1
								font.family: "JetBrainsMono Nerd Font"; elide: Text.ElideRight; Layout.fillWidth: true }
							Text { textFormat: Text.PlainText; visible: ar.modelData.count > 1; text: "×" + ar.modelData.count; color: root.walColor8; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font" }
							Text { textFormat: Text.PlainText; text: mp.gib(ar.modelData.bytes); color: ar.frac > 0.15 ? root.walPeach : root.walForeground
								font.pixelSize: 10; font.bold: true; font.family: "JetBrainsMono Nerd Font"; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 46 }
							Rectangle {
								Layout.preferredWidth: ar.isArmed ? killRow.implicitWidth + 12 : 22
								Layout.preferredHeight: 20
								radius: 6
								opacity: ar.modelData.killable ? 1 : 0.25
								color: ar.isArmed ? root.walColor1 : (kMa.containsMouse && ar.modelData.killable ? Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.25) : root.card(0.35))
								Row { id: killRow; anchors.centerIn: parent; spacing: 4
									Text { textFormat: Text.PlainText; text: ar.modelData.killable ? "󰅖" : "󰌾"; color: ar.isArmed ? root.walBackground : root.walColor1; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font" }
									Text { textFormat: Text.PlainText; visible: ar.isArmed; text: "close?"; color: root.walBackground; font.pixelSize: 9; font.bold: true; font.family: "JetBrainsMono Nerd Font" } }
								MouseArea { id: kMa; anchors.fill: parent; hoverEnabled: true; enabled: ar.modelData.killable
									cursorShape: Qt.PointingHandCursor; onClicked: mp.killApp(ar.modelData) }
							}
						}
						MouseArea { id: arMa; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
					}
				}

				Rectangle {
					Layout.fillWidth: true; Layout.preferredHeight: 22; radius: 8; color: root.card(0.3)
					Text {
						textFormat: Text.PlainText
						anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
						verticalAlignment: Text.AlignVCenter
						text: mp.msg !== "" ? mp.msg : "󰅖 twice = close app (all its windows) · 󰌾 = system, protected"
						color: mp.msg !== "" ? root.walColor2 : root.walColor8
						opacity: mp.msg !== "" ? 1 : 0.7
						font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; elide: Text.ElideRight
					}
				}
			}
		}
	}

	Connections { target: root; function onMemPanelVisibleChanged() { if (root.memPanelVisible) mpFocus.start() } }
	Timer { id: mpFocus; interval: 50; onTriggered: { mp.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive; mpRelease.start() } }
	Timer { id: mpRelease; interval: 100; onTriggered: mp.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand }
}
