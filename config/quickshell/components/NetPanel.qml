import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// NetPanel.qml — live network usage per app and per site (data: netmon service → root.netLive).
//   Live tab : current ↓/↑ speed per app and per site, 2-minute graph
//   Today tab: data used today per app and per site (kept per day in /var/lib/netmon/days)
// Open from the NET bar block, Super+I, or `qs ipc call net toggle`.

PanelWindow {
	id: np
	screen: Quickshell.screens.length > 0 ? (root.focusedScreen ?? Quickshell.screens[0]) : undefined
	visible: true
	exclusionMode: ExclusionMode.Ignore
	anchors {
		bottom: root.barPosition !== "top"
		right: true
		top: root.barPosition === "top"
	}
	margins {
		bottom: root.netPanelVisible ? root.barGapV : -(implicitHeight + 20)
		right: 6 + root.barInsetRight
		top: root.netPanelVisible ? root.barGapV : -(implicitHeight + 20)
	}
	implicitWidth: 440
	implicitHeight: card.implicitHeight
	color: "transparent"
	focusable: true
	WlrLayershell.keyboardFocus: root.netPanelVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

	Behavior on margins.bottom { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
	Behavior on margins.top { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

	property bool todayTab: false
	readonly property var d: root.netLive || ({})
	readonly property bool ok: d.ts !== undefined && (Date.now() / 1000 - d.ts) < 10
	readonly property var today: d.today || ({})
	readonly property var apps: (todayTab ? today.apps : d.apps) || []
	readonly property var hosts: (todayTab ? today.hosts : d.hosts) || []
	readonly property real appMax: { var m = 1; for (var i = 0; i < apps.length; i++) m = Math.max(m, apps[i][1] + apps[i][2]); return m }
	readonly property real hostMax: { var m = 1; for (var i = 0; i < hosts.length; i++) m = Math.max(m, hosts[i][1] + hosts[i][2]); return m }
	function amount(v) { return np.todayTab ? root.fmtBytes(v) : root.fmtRate(v) + "/s" }

	// one row: name (+ small sub label) · ↓ · ↑ · usage bar
	component UsageRow: Item {
		id: row
		property string name: ""
		property string sub: ""
		property real down: 0
		property real up: 0
		property real max: 1
		property color accent: root.walColor13
		Layout.fillWidth: true
		implicitHeight: 30
		Rectangle {   // share-of-top bar behind the text
			anchors { left: parent.left; verticalCenter: parent.verticalCenter }
			height: parent.height - 4
			radius: 6
			width: parent.width * Math.min(1, (row.down + row.up) / row.max)
			color: Qt.rgba(row.accent.r, row.accent.g, row.accent.b, 0.13)
			Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
		}
		RowLayout {
			anchors.fill: parent
			anchors.leftMargin: 8
			anchors.rightMargin: 8
			spacing: 8
			ColumnLayout {
				spacing: 0
				Layout.fillWidth: true
				Text {
					text: row.name
					color: root.walForeground
					font.pixelSize: 11
					font.bold: true
					font.family: "JetBrainsMono Nerd Font"
					elide: Text.ElideMiddle
					Layout.fillWidth: true
				}
				Text {
					visible: row.sub !== ""
					text: row.sub
					color: root.walColor8
					font.pixelSize: 8
					font.family: "JetBrainsMono Nerd Font"
				}
			}
			Text {
				text: "↓ " + np.amount(row.down)
				color: root.walColor13
				font.pixelSize: 10
				font.family: "JetBrainsMono Nerd Font"
				Layout.preferredWidth: 82
				horizontalAlignment: Text.AlignRight
			}
			Text {
				text: "↑ " + np.amount(row.up)
				color: root.walPeach
				font.pixelSize: 10
				font.family: "JetBrainsMono Nerd Font"
				Layout.preferredWidth: 74
				horizontalAlignment: Text.AlignRight
			}
		}
	}

	component SectionTitle: Text {
		color: root.walColor8
		font.pixelSize: 9
		font.bold: true
		font.letterSpacing: 0.8
		font.family: "JetBrainsMono Nerd Font"
	}

	Item {
		anchors.fill: parent
		focus: root.netPanelVisible
		Keys.onPressed: function(event) {
			if (event.key === Qt.Key_Escape) { root.netPanelVisible = false; event.accepted = true }
			else if (event.key === Qt.Key_Tab || event.key === Qt.Key_T) { np.todayTab = !np.todayTab; event.accepted = true }
		}

		Rectangle {
			id: card
			width: parent.width
			anchors.bottom: parent.bottom
			implicitHeight: col.implicitHeight + 32
			radius: 18
			color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.95)
			border.width: 1
			border.color: Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.45)

			ColumnLayout {
				id: col
				anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
				spacing: 12

				// ── header: live totals ───────────────────────────────
				RowLayout {
					Layout.fillWidth: true
					spacing: 10
					Text { text: "󰛳"; color: root.walColor13; font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font" }
					ColumnLayout {
						spacing: 0
						Layout.fillWidth: true
						Text { text: "Network"; color: root.walColor5; font.pixelSize: 15; font.bold: true; font.family: "JetBrainsMono Nerd Font" }
						Text {
							text: !np.ok ? "netmon isn't running — sudo systemctl status netmon"
								: (np.d.iface || "") + "  ·  today ↓ " + root.fmtBytes((np.today.total || [0, 0])[0]) + "  ↑ " + root.fmtBytes((np.today.total || [0, 0])[1])
							color: np.ok ? root.walColor8 : root.walPeach
							font.pixelSize: 9
							font.family: "JetBrainsMono Nerd Font"
							elide: Text.ElideRight
							Layout.fillWidth: true
						}
					}
					ColumnLayout {
						spacing: 0
						Text { Layout.alignment: Qt.AlignRight; text: "↓ " + root.fmtRate(np.d.down) + "/s"; color: root.walColor13; font.pixelSize: 14; font.bold: true; font.family: "JetBrainsMono Nerd Font" }
						Text { Layout.alignment: Qt.AlignRight; text: "↑ " + root.fmtRate(np.d.up) + "/s"; color: root.walPeach; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font" }
					}
				}

				// ── 2-minute graph ────────────────────────────────────
				Rectangle {
					Layout.fillWidth: true
					Layout.preferredHeight: 70
					radius: 12
					color: root.card(0.3)
					Canvas {
						id: graph
						anchors.fill: parent
						anchors.margins: 8
						property var hist: np.d.history || []
						property color cDown: root.walColor13
						property color cUp: root.walPeach
						onHistChanged: requestPaint()
						onWidthChanged: requestPaint()
						onPaint: {
							var ctx = getContext("2d")
							ctx.clearRect(0, 0, width, height)
							var h = hist
							if (!h || h.length < 2) return
							var max = 1
							for (var i = 0; i < h.length; i++) max = Math.max(max, h[i][0], h[i][1])
							var n = 120, step = width / (n - 1), off = n - h.length
							function line(idx, col, fill) {
								ctx.beginPath()
								for (var j = 0; j < h.length; j++) {
									var x = (off + j) * step, y = height - (h[j][idx] / max) * (height - 2)
									if (j === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
								}
								ctx.strokeStyle = Qt.rgba(col.r, col.g, col.b, 0.9)
								ctx.lineWidth = 1.6
								ctx.stroke()
								if (fill) {
									ctx.lineTo((off + h.length - 1) * step, height)
									ctx.lineTo(off * step, height)
									ctx.closePath()
									ctx.fillStyle = Qt.rgba(col.r, col.g, col.b, 0.15)
									ctx.fill()
								}
							}
							line(0, cDown, true)
							line(1, cUp, false)
						}
					}
					Text {
						anchors { top: parent.top; right: parent.right; margins: 6 }
						text: "last 2 min"
						color: root.walColor8; opacity: 0.6
						font.pixelSize: 8; font.family: "JetBrainsMono Nerd Font"
					}
				}

				// ── Live / Today switch ───────────────────────────────
				RowLayout {
					Layout.fillWidth: true
					spacing: 6
					Repeater {
						model: ["Live", "Today"]
						delegate: Rectangle {
							required property string modelData
							required property int index
							readonly property bool sel: (index === 1) === np.todayTab
							Layout.fillWidth: true
							height: 26
							radius: 13
							color: sel ? Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.22) : (tabMa.containsMouse ? root.hover(0.5) : root.card(0.3))
							border.width: sel ? 1 : 0
							border.color: Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.6)
							Text {
								anchors.centerIn: parent
								text: modelData
								color: parent.sel ? root.walColor13 : root.walForeground
								font.pixelSize: 10; font.bold: parent.sel; font.family: "JetBrainsMono Nerd Font"
							}
							MouseArea { id: tabMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: np.todayTab = (index === 1) }
						}
					}
				}

				// ── apps ──────────────────────────────────────────────
				SectionTitle { text: np.todayTab ? "APPS · TODAY" : "APPS · NOW" }
				ColumnLayout {
					Layout.fillWidth: true
					spacing: 2
					Repeater {
						model: np.apps.slice(0, 7)
						delegate: UsageRow {
							required property var modelData
							name: modelData[0]; down: modelData[1]; up: modelData[2]; max: np.appMax
							accent: root.walColor13
						}
					}
					Text {
						visible: np.apps.length === 0
						text: np.ok ? (np.todayTab ? "nothing yet today" : "no traffic right now") : "—"
						color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
					}
				}

				// ── sites ─────────────────────────────────────────────
				SectionTitle { text: np.todayTab ? "SITES · TODAY" : "SITES · NOW" }
				ColumnLayout {
					Layout.fillWidth: true
					spacing: 2
					Repeater {
						model: np.hosts.slice(0, 7)
						delegate: UsageRow {
							required property var modelData
							name: modelData[0]; down: modelData[1]; up: modelData[2]; max: np.hostMax
							sub: np.todayTab ? "" : (modelData[3] || "")
							accent: root.walColor5
						}
					}
					Text {
						visible: np.hosts.length === 0
						text: np.ok ? (np.todayTab ? "nothing yet today" : "no traffic right now") : "—"
						color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
					}
				}

				Text {
					Layout.alignment: Qt.AlignHCenter
					text: "tab / t switch live ↔ today · esc close"
					color: root.walColor8; opacity: 0.6
					font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"
				}
			}
		}
	}

	Connections {
		target: root
		function onNetPanelVisibleChanged() { if (root.netPanelVisible) focusTimer.start() }
	}
	Timer {
		id: focusTimer
		interval: 50
		onTriggered: { np.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive; releaseTimer.start() }
	}
	Timer {
		id: releaseTimer
		interval: 100
		onTriggered: np.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand
	}
}
