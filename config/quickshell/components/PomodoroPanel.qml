import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

// PomodoroPanel.qml — the pomodoro-bomb timer, now living inside Quickshell.
// Timer state is in shell.qml (root.pomo*) so the bar notch keeps counting while
// this panel is closed. Open: click the bomb notch, Super+P, or `qs ipc call pomodoro toggle`.

PanelWindow {
	id: pomoPanel
	screen: Quickshell.screens.length > 0 ? (root.focusedScreen ?? Quickshell.screens[0]) : undefined
	visible: true
	exclusionMode: ExclusionMode.Ignore
	anchors {
		bottom: root.barPosition !== "top"
		right: true
		top: root.barPosition === "top"
	}
	margins {
		bottom: root.pomoVisible ? root.barGapV : -(implicitHeight + 20)
		right: (6) + root.barInsetRight
		top: root.pomoVisible ? root.barGapV : -(implicitHeight + 20)
	}
	implicitWidth: 340
	implicitHeight: card.implicitHeight
	color: "transparent"
	focusable: true
	WlrLayershell.keyboardFocus: root.pomoVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

	Behavior on margins.bottom {
		NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
	}
	Behavior on margins.top {
		NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
	}

	property real shakeX: 0
	readonly property color housing: root.lightMode ? "#ccd0da" : "#313244"
	readonly property color housingEdge: root.lightMode ? "#bcc0cc" : "#45475a"
	readonly property string phaseLabel: root.pomoPhase === "focus" ? "FOCUS" : (root.pomoPhase === "long" ? "LONG BREAK" : "BREAK")

	SequentialAnimation {
		id: shakeAnim
		loops: 3
		NumberAnimation { target: pomoPanel; property: "shakeX"; to: -7; duration: 40 }
		NumberAnimation { target: pomoPanel; property: "shakeX"; to: 7; duration: 80 }
		NumberAnimation { target: pomoPanel; property: "shakeX"; to: 0; duration: 40 }
	}
	SequentialAnimation {
		id: fuseFlash
		loops: 2
		NumberAnimation { target: flashOverlay; property: "opacity"; to: 0.55; duration: 120 }
		NumberAnimation { target: flashOverlay; property: "opacity"; to: 0.0; duration: 220 }
	}

	Item {
		anchors.fill: parent
		focus: root.pomoVisible
		Keys.onPressed: function(event) {
			if (event.key === Qt.Key_Escape) { root.pomoVisible = false; event.accepted = true }
			else if (event.key === Qt.Key_Space) { root.pomoStartPause(); event.accepted = true }
			else if (event.key === Qt.Key_R) { root.pomoReset(); event.accepted = true }
			else if (event.key === Qt.Key_S) { root.pomoSkip(); event.accepted = true }
		}

		Rectangle {
			id: card
			width: parent.width
			anchors.bottom: parent.bottom
			implicitHeight: col.implicitHeight + 32
			radius: 18
			color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.95)
			border.width: 1
			border.color: Qt.rgba(root.pomoColor.r, root.pomoColor.g, root.pomoColor.b, 0.45)
			Behavior on border.color { ColorAnimation { duration: 300 } }

			ColumnLayout {
				id: col
				anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
				spacing: 12

				// ── Header ──────────────────────────────────────────────
				RowLayout {
					Layout.fillWidth: true
					spacing: 8
					Text {
						text: ""
						color: root.walPeach
						font.pixelSize: 18
						font.family: "JetBrainsMono Nerd Font"
					}
					Text {
						text: "Pomodoro"
						color: root.walColor5
						font.pixelSize: 15
						font.bold: true
						font.family: "JetBrainsMono Nerd Font"
						Layout.fillWidth: true
					}
					Rectangle {
						width: phaseText.implicitWidth + 16
						height: 20
						radius: 10
						color: Qt.rgba(root.pomoColor.r, root.pomoColor.g, root.pomoColor.b, 0.2)
						Behavior on color { ColorAnimation { duration: 300 } }
						Text {
							id: phaseText
							anchors.centerIn: parent
							text: pomoPanel.phaseLabel
							color: root.pomoColor
							font.pixelSize: 9
							font.bold: true
							font.letterSpacing: 1
							font.family: "JetBrainsMono Nerd Font"
						}
					}
				}

				// ── The bomb ────────────────────────────────────────────
				Item {
					Layout.fillWidth: true
					Layout.preferredHeight: 150

					Item {
						id: bomb
						width: 360
						height: 200
						scale: 0.75
						transformOrigin: Item.Top
						anchors.top: parent.top
						anchors.horizontalCenter: parent.horizontalCenter
						anchors.horizontalCenterOffset: pomoPanel.shakeX

						MouseArea {
							anchors.fill: parent
							cursorShape: Qt.PointingHandCursor
							acceptedButtons: Qt.LeftButton | Qt.RightButton
							onClicked: function(mouse) {
								if (mouse.button === Qt.RightButton) root.pomoReset()
								else root.pomoStartPause()
							}
							onWheel: function(wheel) {
								if (root.pomoRunning) return
								var which = root.pomoPhase === "focus" ? "focus" : root.pomoPhase
								root.pomoAdjust(which, wheel.angleDelta.y > 0 ? 1 : -1)
							}
						}

						// wires
						Shape {
							anchors.fill: parent
							antialiasing: true
							ShapePath {
								strokeColor: root.walColor4
								strokeWidth: 3
								fillColor: "transparent"
								capStyle: ShapePath.RoundCap
								startX: 40; startY: 70
								PathCubic { x: 75; y: 10; control1X: 15; control1Y: 40; control2X: 30; control2Y: 5 }
								PathCubic { x: 115; y: 45; control1X: 105; control1Y: -5; control2X: 140; control2Y: 20 }
							}
							ShapePath {
								strokeColor: root.walColor1
								strokeWidth: 3
								fillColor: "transparent"
								capStyle: ShapePath.RoundCap
								startX: 175; startY: 50
								PathCubic { x: 195; y: 5; control1X: 175; control1Y: 20; control2X: 180; control2Y: -5 }
								PathCubic { x: 230; y: 38; control1X: 218; control1Y: 8; control2X: 235; control2Y: 20 }
							}
							ShapePath {
								strokeColor: root.walColor2
								strokeWidth: 3
								fillColor: "transparent"
								capStyle: ShapePath.RoundCap
								startX: 205; startY: 52
								PathCubic { x: 245; y: 12; control1X: 215; control1Y: 25; control2X: 228; control2Y: 5 }
							}
						}

						// fuse spark at the end of the yellow wire
						Rectangle {
							x: 40 - width / 2
							y: 70 - height / 2
							z: 5
							width: 14; height: 14; radius: 7
							visible: root.pomoRunning
							color: root.walPeach
							border.width: 3
							border.color: Qt.rgba(root.walColor4.r, root.walColor4.g, root.walColor4.b, 0.6)
							SequentialAnimation on scale {
								running: root.pomoRunning
								loops: Animation.Infinite
								NumberAnimation { to: 1.5; duration: 140 }
								NumberAnimation { to: 0.8; duration: 110 }
								NumberAnimation { to: 1.2; duration: 90 }
							}
						}

						Row {
							id: sticks
							anchors.horizontalCenter: parent.horizontalCenter
							anchors.bottom: parent.bottom
							anchors.bottomMargin: 8
							spacing: -10
							z: 1
							Repeater {
								model: 5
								delegate: Rectangle {
									width: 64
									height: 148
									radius: 18
									gradient: Gradient {
										orientation: Gradient.Horizontal
										GradientStop { position: 0.0; color: "#8a6a4a" }
										GradientStop { position: 0.45; color: "#c79a68" }
										GradientStop { position: 1.0; color: "#7a5a3c" }
									}
									border.color: "#4a3624"
									border.width: 1
									Rectangle { width: parent.width; height: 12; y: 14; color: "#161016" }
									Rectangle { width: parent.width; height: 12; y: parent.height - 26; color: "#161016" }
								}
							}
						}

						Rectangle {
							id: housingRect
							width: 250
							height: 92
							radius: 9
							anchors.centerIn: sticks
							anchors.verticalCenterOffset: -8
							color: pomoPanel.housing
							border.color: pomoPanel.housingEdge
							border.width: 2
							z: 2

							Row {
								anchors.top: parent.top
								anchors.horizontalCenter: parent.horizontalCenter
								anchors.topMargin: 5
								spacing: 7
								Repeater {
									model: 7
									delegate: Rectangle {
										required property int index
										width: 4; height: 4; radius: 2
										color: index % 2 === 0 ? root.walColor13 : root.walColor5
									}
								}
							}
							Rectangle {
								width: 13; height: 13; radius: 7
								anchors.right: parent.right
								anchors.top: parent.top
								anchors.margins: 7
								color: root.pomoRunning ? root.walColor1 : root.walColor8
								SequentialAnimation on opacity {
									running: root.pomoRunning
									loops: Animation.Infinite
									NumberAnimation { to: 0.15; duration: 500 }
									NumberAnimation { to: 1.0; duration: 500 }
								}
							}
							Rectangle {
								anchors.centerIn: parent
								width: 195
								height: 50
								radius: 4
								color: root.lightMode ? "#1e1e2e" : root.walBackground
								border.color: "#000000"
								border.width: 1
								Text {
									anchors.centerIn: parent
									text: root.pomoText
									color: root.pomoColor
									font.family: "JetBrainsMono Nerd Font"
									font.pixelSize: 32
									font.bold: true
								}
							}
							Text {
								anchors.bottom: parent.bottom
								anchors.horizontalCenter: parent.horizontalCenter
								anchors.bottomMargin: 4
								text: root.pomoRunning ? pomoPanel.phaseLabel : "PAUSED · scroll to set"
								color: root.walForeground
								font.pixelSize: 10
								font.letterSpacing: 1
							}
						}

						Rectangle {
							id: flashOverlay
							anchors.fill: parent
							radius: 12
							color: root.walColor4
							opacity: 0.0
							z: 4
						}
					}
				}

				// ── Fuse (progress) ─────────────────────────────────────
				Item {
					Layout.fillWidth: true
					Layout.preferredHeight: 12
					Rectangle {
						id: fuseTrack
						anchors.verticalCenter: parent.verticalCenter
						width: parent.width
						height: 4
						radius: 2
						color: root.card(0.45)
						Rectangle {
							id: fuseFill
							width: parent.width * Math.max(0, 1 - root.pomoProgress)
							height: parent.height
							radius: 2
							color: root.pomoColor
							Behavior on width { NumberAnimation { duration: 300 } }
						}
					}
					Rectangle {
						visible: root.pomoRunning
						x: fuseFill.width - width / 2
						anchors.verticalCenter: parent.verticalCenter
						width: 10; height: 10; radius: 5
						color: root.walPeach
						SequentialAnimation on opacity {
							running: root.pomoRunning
							loops: Animation.Infinite
							NumberAnimation { to: 0.4; duration: 180 }
							NumberAnimation { to: 1.0; duration: 180 }
						}
					}
				}

				// ── Controls ────────────────────────────────────────────
				Row {
					Layout.alignment: Qt.AlignHCenter
					spacing: 14
					CtrlBtn { icon: "󰑓"; tip: "Reset"; onPicked: root.pomoReset() }
					Rectangle {
						width: 48; height: 48; radius: 24
						color: root.pomoColor
						scale: playMa.pressed ? 0.92 : (playMa.containsMouse ? 1.06 : 1.0)
						Behavior on scale { NumberAnimation { duration: 100 } }
						Behavior on color { ColorAnimation { duration: 300 } }
						Text {
							anchors.centerIn: parent
							text: root.pomoRunning ? "󰏤" : "󰐊"
							color: root.walBackground
							font.pixelSize: 22
							font.family: "JetBrainsMono Nerd Font"
						}
						MouseArea {
							id: playMa
							anchors.fill: parent
							hoverEnabled: true
							cursorShape: Qt.PointingHandCursor
							onClicked: root.pomoStartPause()
						}
					}
					CtrlBtn { icon: "󰒭"; tip: "Skip"; onPicked: root.pomoSkip() }
				}

				// ── Durations ───────────────────────────────────────────
				RowLayout {
					Layout.fillWidth: true
					spacing: 6
					Stepper { label: "Focus"; value: root.pomoWorkMin; accent: root.walPeach; onStep: function(d) { root.pomoAdjust("focus", d) } }
					Stepper { label: "Break"; value: root.pomoBreakMin; accent: root.walColor2; onStep: function(d) { root.pomoAdjust("break", d) } }
					Stepper { label: "Long"; value: root.pomoLongMin; accent: root.walColor6; onStep: function(d) { root.pomoAdjust("long", d) } }
					Stepper { label: "Long every"; unit: "×"; value: root.pomoLongEvery; accent: root.walColor13; onStep: function(d) { root.pomoAdjust("every", d) } }
				}

				// ── Sessions ────────────────────────────────────────────
				RowLayout {
					Layout.fillWidth: true
					spacing: 6
					Text {
						text: root.pomoSessions + " session" + (root.pomoSessions === 1 ? "" : "s") + " done"
						color: root.walColor8
						font.pixelSize: 10
						font.family: "JetBrainsMono Nerd Font"
						Layout.fillWidth: true
					}
					Repeater {
						model: root.pomoLongEvery
						delegate: Rectangle {
							required property int index
							readonly property int filled: root.pomoPhase === "long" ? root.pomoLongEvery : root.pomoSessions % root.pomoLongEvery
							width: 10; height: 10; radius: 5
							color: index < filled ? root.walPeach : root.card(0.45)
							Behavior on color { ColorAnimation { duration: 300 } }
						}
					}
				}

				// ── Focus timelapse (phone camera) ──────────────────────
				RowLayout {
					visible: root.focusCamAvailable
					Layout.fillWidth: true
					spacing: 8
					Text {
						text: "󰄀  Timelapse"
						color: root.walColor8
						font.pixelSize: 10
						font.family: "JetBrainsMono Nerd Font"
					}
					Rectangle {
						Layout.fillWidth: true
						Layout.preferredHeight: 26
						radius: 8
						color: root.card(0.35)
						RowLayout {
							anchors.fill: parent
							anchors.margins: 3
							spacing: 3
							Repeater {
								model: [{ k: "front", t: "Front cam" }, { k: "back", t: "Back cam" }, { k: "off", t: "Off" }]
								delegate: Rectangle {
									id: fcOpt
									required property var modelData
									readonly property bool sel: root.focusCamFacing === modelData.k
									Layout.fillWidth: true
									Layout.fillHeight: true
									radius: 6
									color: sel ? Qt.rgba(root.walPeach.r, root.walPeach.g, root.walPeach.b, 0.22)
										: (fcMa.containsMouse ? root.hover(0.06) : "transparent")
									Text {
										anchors.centerIn: parent
										text: fcOpt.modelData.t
										color: fcOpt.sel ? root.walForeground : root.walColor8
										font.pixelSize: 10
										font.bold: fcOpt.sel
										font.family: "JetBrainsMono Nerd Font"
									}
									MouseArea {
										id: fcMa
										anchors.fill: parent
										hoverEnabled: true
										cursorShape: Qt.PointingHandCursor
										onClicked: root.focusCamSetFacing(fcOpt.modelData.k)
									}
								}
							}
						}
					}
				}

				Rectangle {
					Layout.fillWidth: true
					Layout.preferredHeight: 22
					radius: 8
					color: root.card(0.3)
					RowLayout {
						anchors.fill: parent
						anchors.leftMargin: 10
						anchors.rightMargin: 10
						Text { text: "space start"; color: root.walColor8; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; opacity: 0.7 }
						Item { Layout.fillWidth: true }
						Text { text: "r reset"; color: root.walColor8; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; opacity: 0.7 }
						Item { Layout.fillWidth: true }
						Text { text: "s skip"; color: root.walColor8; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; opacity: 0.7 }
						Item { Layout.fillWidth: true }
						Text { text: "esc close"; color: root.walColor8; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; opacity: 0.7 }
					}
				}
			}
		}
	}

	component CtrlBtn: Rectangle {
		id: btn
		property string icon
		property string tip
		signal picked()
		width: 38; height: 38; radius: 12
		anchors.verticalCenter: parent ? parent.verticalCenter : undefined
		color: btnMa.containsMouse ? root.hover(0.1) : root.card(0.35)
		Behavior on color { ColorAnimation { duration: 120 } }
		Text {
			anchors.centerIn: parent
			text: btn.icon
			color: root.walForeground
			font.pixelSize: 16
			font.family: "JetBrainsMono Nerd Font"
		}
		MouseArea {
			id: btnMa
			anchors.fill: parent
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor
			onClicked: btn.picked()
		}
	}

	component Stepper: Rectangle {
		id: stp
		property string label
		property int value
		property string unit: "m"
		property color accent
		signal step(int d)
		Layout.fillWidth: true
		Layout.preferredHeight: 50
		radius: 12
		color: root.card(0.35)
		Column {
			anchors.centerIn: parent
			spacing: 2
			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				text: stp.label
				color: root.walColor8
				font.pixelSize: 9
				font.family: "JetBrainsMono Nerd Font"
			}
			Row {
				anchors.horizontalCenter: parent.horizontalCenter
				spacing: 8
				Text {
					text: "󰍴"
					color: minusMa.containsMouse ? stp.accent : root.walColor8
					font.pixelSize: 13
					font.family: "JetBrainsMono Nerd Font"
					MouseArea {
						id: minusMa
						anchors.fill: parent
						anchors.margins: -6
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: stp.step(-1)
					}
				}
				Text {
					text: stp.value + stp.unit
					color: stp.accent
					font.pixelSize: 13
					font.bold: true
					font.family: "JetBrainsMono Nerd Font"
				}
				Text {
					text: "󰐕"
					color: plusMa.containsMouse ? stp.accent : root.walColor8
					font.pixelSize: 13
					font.family: "JetBrainsMono Nerd Font"
					MouseArea {
						id: plusMa
						anchors.fill: parent
						anchors.margins: -6
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: stp.step(1)
					}
				}
			}
		}
		MouseArea {
			anchors.fill: parent
			acceptedButtons: Qt.NoButton
			onWheel: function(wheel) { stp.step(wheel.angleDelta.y > 0 ? 1 : -1) }
		}
	}

	Connections {
		target: root
		function onPomoExploded() {
			shakeAnim.restart()
			fuseFlash.restart()
		}
		function onPomoVisibleChanged() {
			if (root.pomoVisible) focusTimer.start()
		}
	}
	Timer {
		id: focusTimer
		interval: 50
		repeat: false
		onTriggered: {
			pomoPanel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive
			releaseTimer.start()
		}
	}
	Timer {
		id: releaseTimer
		interval: 100
		repeat: false
		onTriggered: pomoPanel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand
	}
}
