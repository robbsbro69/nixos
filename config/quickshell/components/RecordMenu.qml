import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// RecordMenu.qml — screen recorder picker, opened from the bar's record notch.
// Focused monitor / a specific output (laptop or external) / a slurp region.
// Recording itself runs through ~/.config/scripts/record.sh (wf-recorder).

PanelWindow {
	id: recMenu
	screen: Quickshell.screens.length > 0 ? (root.focusedScreen ?? Quickshell.screens[0]) : undefined
	visible: true
	exclusionMode: ExclusionMode.Ignore
	anchors {
		bottom: root.barPosition !== "top"
		right: true
		top: root.barPosition === "top"
	}
	margins {
		bottom: root.recordMenuVisible ? root.barGapV : -(implicitHeight + 20)
		right: (6) + root.barInsetRight
		top: root.recordMenuVisible ? root.barGapV : -(implicitHeight + 20)
	}
	implicitWidth: 300
	property string recCamera: "off"            // off | front | back  (state/record-camera)
	FileView {
		path: root.statePath + "/record-camera"
		onLoaded: { var t = text().trim(); if (["off", "front", "back"].indexOf(t) >= 0) recMenu.recCamera = t }
	}
	// live camera preview (focuscam.sh overlay) — state read back from the script
	property bool camPreview: false
	property real camClickAt: 0
	readonly property string camFacing: recCamera === "back" ? "back" : "front"
	function setCamPreview(on) {
		camPreview = on
		camClickAt = Date.now()
		Quickshell.execDetached(on ? [root.focusCamScript, "overlay", "on", camFacing] : [root.focusCamScript, "overlay", "off"])
	}
	Process {
		id: camStatProc
		command: [root.focusCamScript, "status"]
		stdout: StdioCollector {
			onStreamFinished: {
				if (Date.now() - recMenu.camClickAt < 2500) return
				recMenu.camPreview = text.indexOf("overlay=1") >= 0
			}
		}
	}
	Timer {
		interval: 1500
		repeat: true
		triggeredOnStart: true
		running: root.recordMenuVisible && root.focusCamAvailable
		onTriggered: if (!camStatProc.running) camStatProc.running = true
	}
	property string recAudio: "desktop"          // desktop | both | none  (state/record-audio)
	FileView {
		path: root.statePath + "/record-audio"
		onLoaded: { var t = text().trim(); if (["desktop", "both", "none"].indexOf(t) >= 0) recMenu.recAudio = t }
	}
	implicitHeight: card.implicitHeight
	color: "transparent"
	focusable: true
	WlrLayershell.keyboardFocus: root.recordMenuVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

	Behavior on margins.bottom {
		NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
	}
	Behavior on margins.top {
		NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
	}

	readonly property var outputs: {
		var o = []
		for (var i = 0; i < Quickshell.screens.length; i++) {
			var n = Quickshell.screens[i].name
			o.push({ name: n, laptop: n.indexOf("eDP") === 0 || n.indexOf("LVDS") === 0 })
		}
		return o
	}

	Item {
		anchors.fill: parent
		focus: root.recordMenuVisible
		Keys.onPressed: function(event) {
			if (event.key === Qt.Key_Escape) {
				root.recordMenuVisible = false
				event.accepted = true
			} else if (event.key === Qt.Key_F && !root.recording) {
				root.startRecording("full", "")
				event.accepted = true
			} else if (event.key === Qt.Key_R && !root.recording) {
				root.startRecording("region", "")
				event.accepted = true
			} else if (event.key === Qt.Key_S && root.recording) {
				root.stopRecording()
				event.accepted = true
			}
		}

		Rectangle {
			id: card
			width: parent.width
			anchors.bottom: parent.bottom
			implicitHeight: col.implicitHeight + 32
			radius: 18
			color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.95)
			border.width: 1
			border.color: Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, root.recording ? 0.6 : 0.4)

			ColumnLayout {
				id: col
				anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
				spacing: 10

				// ── Header ──────────────────────────────────────────────
				RowLayout {
					Layout.fillWidth: true
					spacing: 8
					Text {
						text: "󰑋"
						color: root.walColor1
						font.pixelSize: 20
						font.family: "JetBrainsMono Nerd Font"
					}
					Text {
						text: "Screen Recorder"
						color: root.walColor5
						font.pixelSize: 15
						font.bold: true
						font.family: "JetBrainsMono Nerd Font"
						Layout.fillWidth: true
					}
					Rectangle {
						width: statusText.implicitWidth + 16
						height: 20
						radius: 10
						color: root.recording
							? Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.22)
							: root.card(0.35)
						Text {
							id: statusText
							anchors.centerIn: parent
							text: root.recording ? "REC " + root.recElapsedText : "IDLE"
							color: root.recording ? root.walColor1 : root.walColor8
							font.pixelSize: 9
							font.bold: true
							font.letterSpacing: 1
							font.family: "JetBrainsMono Nerd Font"
						}
					}
				}

				// ── Recording in progress ───────────────────────────────
				Rectangle {
					visible: root.recording
					Layout.fillWidth: true
					Layout.preferredHeight: 58
					radius: 14
					color: stopMa.containsMouse
						? Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.30)
						: Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.16)
					border.width: 1
					border.color: Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.5)
					Behavior on color { ColorAnimation { duration: 150 } }
					RowLayout {
						anchors.fill: parent
						anchors.leftMargin: 14
						anchors.rightMargin: 14
						spacing: 12
						Rectangle {
							width: 30; height: 30; radius: 15
							color: root.walColor1
							Rectangle {
								anchors.centerIn: parent
								width: 10; height: 10; radius: 2
								color: root.walBackground
							}
							SequentialAnimation on scale {
								running: root.recording
								loops: Animation.Infinite
								NumberAnimation { to: 1.12; duration: 700; easing.type: Easing.InOutSine }
								NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
							}
						}
						ColumnLayout {
							Layout.fillWidth: true
							spacing: 1
							Text {
								text: "Stop recording"
								color: root.walForeground
								font.pixelSize: 13
								font.bold: true
								font.family: "JetBrainsMono Nerd Font"
							}
							Text {
								text: root.recElapsedText + " elapsed"
								color: root.walColor8
								font.pixelSize: 10
								font.family: "JetBrainsMono Nerd Font"
							}
						}
					}
					MouseArea {
						id: stopMa
						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: root.stopRecording()
					}
				}

				// ── Options ─────────────────────────────────────────────
				ColumnLayout {
					visible: !root.recording
					Layout.fillWidth: true
					spacing: 6

					RecOption {
						icon: "󰍹"
						title: "Full screen"
						sub: "Focused monitor"
						hotkey: "F"
						onPicked: root.startRecording("full", "")
					}
					Repeater {
						model: recMenu.outputs.length > 1 ? recMenu.outputs : []
						delegate: RecOption {
							required property var modelData
							icon: modelData.laptop ? "󰌢" : "󰍺"
							title: modelData.laptop ? "Laptop screen" : "Monitor"
							sub: modelData.name
							onPicked: root.startRecording("output", modelData.name)
						}
					}
					RecOption {
						icon: "󰩭"
						title: "Select region"
						sub: "Drag to choose an area"
						hotkey: "R"
						onPicked: root.startRecording("region", "")
					}
				}

				// ── Sound ───────────────────────────────────────────────
				ColumnLayout {
					visible: !root.recording
					Layout.fillWidth: true
					spacing: 6
					Text {
						text: "SOUND"
						color: root.walColor8
						font.pixelSize: 9
						font.bold: true
						font.letterSpacing: 1.2
						font.family: "JetBrainsMono Nerd Font"
					}
					Rectangle {
						Layout.fillWidth: true
						Layout.preferredHeight: 32
						radius: 9
						color: root.card(0.35)
						RowLayout {
							anchors.fill: parent
							anchors.margins: 3
							spacing: 3
							Repeater {
								model: [{ k: "desktop", i: "󰕾", t: "Laptop" }, { k: "both", i: "󰍬", t: "+ Mic" }, { k: "none", i: "󰖁", t: "Off" }]
								delegate: Rectangle {
									id: aOpt
									required property var modelData
									readonly property bool sel: recMenu.recAudio === modelData.k
									Layout.fillWidth: true
									Layout.fillHeight: true
									radius: 7
									color: sel ? Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.22)
										: (aMa.containsMouse ? root.hover(0.06) : "transparent")
									Row {
										anchors.centerIn: parent
										spacing: 6
										Text { text: aOpt.modelData.i; color: aOpt.sel ? root.walColor1 : root.walColor8; font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font"; anchors.verticalCenter: parent.verticalCenter }
										Text { text: aOpt.modelData.t; color: aOpt.sel ? root.walForeground : root.walColor8; font.pixelSize: 11; font.bold: aOpt.sel; font.family: "JetBrainsMono Nerd Font"; anchors.verticalCenter: parent.verticalCenter }
									}
									MouseArea {
										id: aMa
										anchors.fill: parent
										hoverEnabled: true
										cursorShape: Qt.PointingHandCursor
										onClicked: { recMenu.recAudio = aOpt.modelData.k; root.saveState("record-audio", aOpt.modelData.k) }
									}
								}
							}
						}
					}
				}

				// ── Camera (phone facecam) ──────────────────────────────
				ColumnLayout {
					visible: !root.recording && root.focusCamAvailable
					Layout.fillWidth: true
					spacing: 6
					Text {
						text: "CAMERA  ·  PHONE"
						color: root.walColor8
						font.pixelSize: 9
						font.bold: true
						font.letterSpacing: 1.2
						font.family: "JetBrainsMono Nerd Font"
					}
					Rectangle {
						Layout.fillWidth: true
						Layout.preferredHeight: 32
						radius: 9
						color: root.card(0.35)
						RowLayout {
							anchors.fill: parent
							anchors.margins: 3
							spacing: 3
							Repeater {
								model: [{ k: "off", i: "󰗟", t: "Off" }, { k: "front", i: "󰄀", t: "Front" }, { k: "back", i: "󰄀", t: "Back" }]
								delegate: Rectangle {
									id: cOpt
									required property var modelData
									readonly property bool sel: recMenu.recCamera === modelData.k
									Layout.fillWidth: true
									Layout.fillHeight: true
									radius: 7
									color: sel ? Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.22)
										: (cMa.containsMouse ? root.hover(0.06) : "transparent")
									Row {
										anchors.centerIn: parent
										spacing: 6
										Text { text: cOpt.modelData.i; color: cOpt.sel ? root.walColor1 : root.walColor8; font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font"; anchors.verticalCenter: parent.verticalCenter }
										Text { text: cOpt.modelData.t; color: cOpt.sel ? root.walForeground : root.walColor8; font.pixelSize: 11; font.bold: cOpt.sel; font.family: "JetBrainsMono Nerd Font"; anchors.verticalCenter: parent.verticalCenter }
									}
									MouseArea {
										id: cMa
										anchors.fill: parent
										hoverEnabled: true
										cursorShape: Qt.PointingHandCursor
										onClicked: {
											recMenu.recCamera = cOpt.modelData.k
											root.saveState("record-camera", cOpt.modelData.k)
											if (recMenu.camPreview) recMenu.setCamPreview(true)   // switch the live view
										}
									}
								}
							}
						}
					}
					// live preview toggle
					Rectangle {
						Layout.fillWidth: true
						Layout.preferredHeight: 30
						radius: 9
						color: recMenu.camPreview
							? Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.22)
							: (pvMa.containsMouse ? root.hover(0.06) : root.card(0.35))
						border.width: recMenu.camPreview ? 1 : 0
						border.color: Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.5)
						Behavior on color { ColorAnimation { duration: 120 } }
						Row {
							anchors.centerIn: parent
							spacing: 8
							Text {
								text: recMenu.camPreview ? "󰈉" : "󰈈"
								color: recMenu.camPreview ? root.walColor1 : root.walColor8
								font.pixelSize: 13
								font.family: "JetBrainsMono Nerd Font"
								anchors.verticalCenter: parent.verticalCenter
							}
							Text {
								text: recMenu.camPreview ? "Hide camera preview" : "Live preview  ·  " + recMenu.camFacing + " cam"
								color: recMenu.camPreview ? root.walForeground : root.walColor8
								font.pixelSize: 11
								font.bold: recMenu.camPreview
								font.family: "JetBrainsMono Nerd Font"
								anchors.verticalCenter: parent.verticalCenter
							}
						}
						MouseArea {
							id: pvMa
							anchors.fill: parent
							hoverEnabled: true
							cursorShape: Qt.PointingHandCursor
							onClicked: recMenu.setCamPreview(!recMenu.camPreview)
						}
					}
				}

				// ── Footer ──────────────────────────────────────────────
				Rectangle {
					Layout.fillWidth: true
					Layout.preferredHeight: 26
					radius: 8
					color: folderMa.containsMouse ? root.hover(0.06) : root.card(0.3)
					RowLayout {
						anchors.fill: parent
						anchors.leftMargin: 10
						anchors.rightMargin: 10
						spacing: 6
						Text {
							text: "󰉋"
							color: root.walColor4
							font.pixelSize: 11
							font.family: "JetBrainsMono Nerd Font"
						}
						Text {
							text: "~/Videos/screen-recordings"
							color: root.walColor8
							font.pixelSize: 9
							font.family: "JetBrainsMono Nerd Font"
							Layout.fillWidth: true
							elide: Text.ElideMiddle
						}
						Text {
							text: "open"
							color: root.walColor5
							font.pixelSize: 9
							font.bold: true
							font.family: "JetBrainsMono Nerd Font"
						}
					}
					MouseArea {
						id: folderMa
						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: {
							root.recordMenuVisible = false
							Quickshell.execDetached(["bash", "-c", "d=\"$HOME/Videos/screen-recordings\"; mkdir -p \"$d\"; if command -v thunar >/dev/null; then thunar \"$d\"; else xdg-open \"$d\"; fi"])
						}
					}
				}
			}
		}
	}

	component RecOption: Rectangle {
		id: opt
		property string icon
		property string title
		property string sub
		property string hotkey: ""
		signal picked()
		Layout.fillWidth: true
		Layout.preferredHeight: 50
		radius: 12
		color: optMa.containsMouse
			? Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.14)
			: root.card(0.35)
		border.width: optMa.containsMouse ? 1 : 0
		border.color: Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.45)
		Behavior on color { ColorAnimation { duration: 120 } }
		RowLayout {
			anchors.fill: parent
			anchors.leftMargin: 10
			anchors.rightMargin: 12
			spacing: 10
			Rectangle {
				width: 32; height: 32; radius: 9
				color: Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.18)
				Text {
					anchors.centerIn: parent
					text: opt.icon
					color: root.walColor1
					font.pixelSize: 16
					font.family: "JetBrainsMono Nerd Font"
				}
			}
			ColumnLayout {
				Layout.fillWidth: true
				spacing: 1
				Text {
					text: opt.title
					color: root.walForeground
					font.pixelSize: 12
					font.bold: true
					font.family: "JetBrainsMono Nerd Font"
				}
				Text {
					text: opt.sub
					color: root.walColor8
					font.pixelSize: 9
					font.family: "JetBrainsMono Nerd Font"
					elide: Text.ElideRight
					Layout.fillWidth: true
				}
			}
			Rectangle {
				visible: opt.hotkey !== ""
				width: 18; height: 18; radius: 5
				color: root.card(0.35)
				Text {
					anchors.centerIn: parent
					text: opt.hotkey
					color: root.walColor8
					font.pixelSize: 9
					font.bold: true
					font.family: "JetBrainsMono Nerd Font"
				}
			}
		}
		MouseArea {
			id: optMa
			anchors.fill: parent
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor
			onClicked: opt.picked()
		}
	}

	Connections {
		target: root
		function onRecordMenuVisibleChanged() {
			if (root.recordMenuVisible) focusTimer.start()
		}
	}
	Timer {
		id: focusTimer
		interval: 50
		repeat: false
		onTriggered: {
			recMenu.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive
			releaseTimer.start()
		}
	}
	Timer {
		id: releaseTimer
		interval: 100
		repeat: false
		onTriggered: recMenu.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand
	}
}
