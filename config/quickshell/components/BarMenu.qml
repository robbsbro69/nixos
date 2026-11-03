import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// BarMenu.qml — right-click an empty part of the bar. Position (top / bottom), style
// (default / i3 / minimal), colour theme, visibility (always / auto-hide / hidden) and light/dark.
// Saved in state/bar.

PanelWindow {
	id: bm
	screen: Quickshell.screens.length > 0 ? (root.focusedScreen ?? Quickshell.screens[0]) : undefined
	visible: root.barMenuVisible || slide > 0.01
	exclusionMode: ExclusionMode.Ignore
	// opens at the right end of the bar, by its button
	anchors {
		top: root.barPosition === "top"
		bottom: root.barPosition === "bottom"
		right: true
	}
	margins {
		top: root.barInsetTop + 6
		bottom: root.barInsetBottom + 6
		right: 8
	}
	implicitWidth: 320
	implicitHeight: card.implicitHeight
	color: "transparent"
	focusable: true
	WlrLayershell.keyboardFocus: root.barMenuVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

	property real slide: root.barMenuVisible ? 1 : 0
	Behavior on slide { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

	Item {
		anchors.fill: parent
		focus: root.barMenuVisible
		Keys.onPressed: function(event) {
			if (event.key === Qt.Key_Escape) { root.barMenuVisible = false; event.accepted = true }
		}

		Rectangle {
			id: card
			width: parent.width
			implicitHeight: col.implicitHeight + 28
			radius: 16
			opacity: bm.slide
			scale: 0.94 + 0.06 * bm.slide
			color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.97)
			border.width: 1
			border.color: Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.4)

			ColumnLayout {
				id: col
				anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
				spacing: 12

				Text {
					text: "󰒓  Bar"
					color: root.walColor5
					font.pixelSize: 14
					font.bold: true
					font.family: "JetBrainsMono Nerd Font"
				}

				// position + style
				Text { text: "POSITION"; color: root.walColor8; font.pixelSize: 9; font.bold: true; font.letterSpacing: 0.8; font.family: "JetBrainsMono Nerd Font" }
				Seg {
					model: [{ k: "top", t: "󰁝  Top" }, { k: "bottom", t: "󰁅  Bottom" }]
					current: root.barPosition
					onPicked: k => root.setBarPosition(k)
				}

				Text { text: "STYLE"; color: root.walColor8; font.pixelSize: 9; font.bold: true; font.letterSpacing: 0.8; font.family: "JetBrainsMono Nerd Font" }
				RowLayout {
					Layout.fillWidth: true
					spacing: 6
					Repeater {
						model: [
							{ k: "default", t: "Default" },
							{ k: "i3", t: "i3bar" }
						]
						delegate: Rectangle {
							id: sCard
							required property var modelData
							readonly property bool sel: root.barStyle === modelData.k
							readonly property string k: modelData.k
							Layout.fillWidth: true
							Layout.preferredHeight: 58
							radius: 10
							color: sel ? Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.18) : (sMa.containsMouse ? root.hover(0.4) : root.card(0.35))
							border.width: sel ? 1 : 0
							border.color: root.walColor13
							Behavior on color { ColorAnimation { duration: 150 } }
							// tiny preview of the bar
							Rectangle {
								id: pv
								anchors { top: parent.top; left: parent.left; right: parent.right; margins: 7 }
								height: sCard.k === "i3" ? 12 : sCard.k === "minimal" ? 13 : 15
								radius: sCard.k === "i3" ? 0 : sCard.k === "floating" ? 7 : 3
								color: sCard.k === "i3" ? (root.lightMode ? "#dce0e8" : "#11111b")
									: sCard.k === "minimal" ? (root.lightMode ? "#eff1f5" : "#1e1e2e") : sCard.k === "xp" ? "#245edb" : sCard.k === "islands" ? "transparent" : root.barColor
								border.width: sCard.k === "minimal" ? 1 : 0
								border.color: root.card(0.6)
								Rectangle {   // accent line (default only)
									visible: sCard.k === "default" || sCard.k === "enjoy"
									width: parent.width; height: 1
									color: Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.5)
								}
								Row {
									anchors.verticalCenter: parent.verticalCenter
									x: 4
									spacing: sCard.k === "i3" ? 2 : sCard.k === "minimal" ? 3 : 4
									Repeater {
										model: 4
										Row {
											required property int index
											spacing: sCard.k === "i3" ? 2 : 4
											Rectangle {
												visible: index > 0 && sCard.k !== "minimal" && sCard.k !== "islands"
												width: 1
												height: sCard.k === "i3" ? pv.height - 2 : 5
												anchors.verticalCenter: parent.verticalCenter
												color: root.walColor8
												opacity: 0.6
											}
											Rectangle {
												width: (index === 1 ? 10 : 5) + (sCard.k === "islands" ? 4 : 0)
												height: sCard.k === "islands" ? 9 : 4
												radius: sCard.k === "i3" ? 0 : sCard.k === "islands" ? 3 : 2
												border.width: sCard.k === "islands" ? 1 : 0
												border.color: Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.25)
												anchors.verticalCenter: parent.verticalCenter
												color: index === 1 ? root.walColor13 : root.walColor8
											}
										}
									}
								}
							}
							Text {
								anchors { bottom: parent.bottom; bottomMargin: 7; horizontalCenter: parent.horizontalCenter }
								text: modelData.t
								color: sCard.sel ? root.walColor13 : root.walForeground
								font.pixelSize: 10
								font.bold: sCard.sel
								font.family: "JetBrainsMono Nerd Font"
							}
							MouseArea {
								id: sMa
								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								onClicked: root.setBarStyle(sCard.k)
							}
						}
					}
				}

				Text { text: "LAYOUT"; color: root.walColor8; font.pixelSize: 9; font.bold: true; font.letterSpacing: 0.8; font.family: "JetBrainsMono Nerd Font" }
				Seg {
					model: [{ k: "attached", t: "Attached" }, { k: "floating", t: "Floating" }]
					current: root.barFloating ? "floating" : "attached"
					onPicked: k => root.setBarFloating(k === "floating")
				}

				Text { text: "TRANSPARENCY"; color: root.walColor8; font.pixelSize: 9; font.bold: true; font.letterSpacing: 0.8; font.family: "JetBrainsMono Nerd Font" }
				Seg {
					model: [{ k: "opaque", t: "Opaque" }, { k: "transparent", t: "Transparent" }, { k: "blur", t: "Blur" }]
					current: root.barOpacity
					onPicked: k => root.setBarOpacity(k)
				}

				// colour theme — the whole shell follows it
				Text { text: "THEME"; color: root.walColor8; font.pixelSize: 9; font.bold: true; font.letterSpacing: 0.8; font.family: "JetBrainsMono Nerd Font" }
				GridLayout {
					Layout.fillWidth: true
					columns: 2
					rowSpacing: 6
					columnSpacing: 6
					Repeater {
						model: root.themeList
						delegate: Rectangle {
							id: tCard
							required property var modelData
							readonly property bool sel: root.themeName === modelData.k
							readonly property var p: root.palettes[modelData.k][root.lightMode ? "light" : "dark"]
							Layout.fillWidth: true
							Layout.preferredHeight: 34
							radius: 10
							color: sel ? Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.18) : (tMa.containsMouse ? root.hover(0.4) : root.card(0.35))
							border.width: sel ? 1 : 0
							border.color: root.walColor13
							Behavior on color { ColorAnimation { duration: 150 } }
							Row {
								anchors.verticalCenter: parent.verticalCenter
								x: 7
								spacing: 8
								// swatch: the theme's background with its accents
								Rectangle {
									width: 40; height: 20; radius: 6
									anchors.verticalCenter: parent.verticalCenter
									color: tCard.p.bg
									border.width: 1
									border.color: root.card(0.6)
									Row {
										anchors.centerIn: parent
										spacing: 3
										Repeater {
											model: [tCard.p.pink, tCard.p.mauve, tCard.p.green, tCard.p.red]
											Rectangle { required property var modelData; width: 6; height: 6; radius: 3; color: modelData }
										}
									}
								}
								Text {
									anchors.verticalCenter: parent.verticalCenter
									text: tCard.modelData.t
									color: tCard.sel ? root.walColor13 : root.walForeground
									font.pixelSize: 10
									font.bold: tCard.sel
									font.family: "JetBrainsMono Nerd Font"
								}
							}
							MouseArea {
								id: tMa
								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								onClicked: root.setTheme(tCard.modelData.k)
							}
						}
					}
				}

				// visibility mode
				Text { text: "VISIBILITY"; color: root.walColor8; font.pixelSize: 9; font.bold: true; font.letterSpacing: 0.8; font.family: "JetBrainsMono Nerd Font" }
				Seg {
					model: [{ k: "shown", t: "Always" }, { k: "auto", t: "Auto-hide" }, { k: "hidden", t: "Hidden" }]
					current: root.barMode
					onPicked: k => root.setBarMode(k)
				}
				Text {
					Layout.fillWidth: true
					wrapMode: Text.WordWrap
					text: root.barMode === "auto" ? "Touch the screen edge to show it."
						: root.barMode === "hidden" ? "Bring it back with your keybind or: qs ipc call bar toggle"
						: "Windows keep clear of the bar."
					color: root.walColor8
					opacity: 0.8
					font.pixelSize: 9
					font.family: "JetBrainsMono Nerd Font"
				}

				// theme
				RowLayout {
					Layout.fillWidth: true
					spacing: 8
					Text {
						text: root.lightMode ? "󰖙" : "󰖔"
						color: root.lightMode ? root.walPeach : root.walColor13
						font.pixelSize: 15
						font.family: "JetBrainsMono Nerd Font"
					}
					Text {
						Layout.fillWidth: true
						text: root.lightMode ? "Light mode" : "Dark mode"
						color: root.walForeground
						font.pixelSize: 11
						font.family: "JetBrainsMono Nerd Font"
					}
					Rectangle {
						width: 44; height: 24; radius: 12
						color: root.lightMode ? root.walPeach : Qt.rgba(0.3, 0.3, 0.3, 0.5)
						Rectangle {
							width: 20; height: 20; radius: 10; y: 2
							x: root.lightMode ? 22 : 2
							color: root.walBackground
							Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
						}
						MouseArea {
							anchors.fill: parent
							cursorShape: Qt.PointingHandCursor
							onClicked: root.toggleLightMode()
						}
					}
				}
			}
		}
	}

	component Seg: Rectangle {
		id: segRoot
		property var model: []
		property string current: ""
		signal picked(string k)
		Layout.fillWidth: true
		Layout.preferredHeight: 30
		radius: 15
		color: root.card(0.35)
		Row {
			anchors.fill: parent
			anchors.margins: 3
			spacing: 3
			Repeater {
				model: segRoot.model
				delegate: Rectangle {
					required property var modelData
					readonly property bool sel: segRoot.current === modelData.k
					width: (parent.width - 3 * (segRoot.model.length - 1)) / segRoot.model.length
					height: parent.height
					radius: height / 2
					color: sel ? Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.25) : (segMa.containsMouse ? root.hover(0.4) : "transparent")
					Behavior on color { ColorAnimation { duration: 150 } }
					Text {
						anchors.centerIn: parent
						text: modelData.t
						color: sel ? root.walColor13 : root.walColor8
						font.pixelSize: 10
						font.bold: sel
						font.family: "JetBrainsMono Nerd Font"
					}
					MouseArea {
						id: segMa
						anchors.fill: parent
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: segRoot.picked(modelData.k)
					}
				}
			}
		}
	}

	Connections {
		target: root
		function onBarMenuVisibleChanged() { if (root.barMenuVisible) focusTimer.start() }
	}
	Timer {
		id: focusTimer
		interval: 50
		onTriggered: { bm.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive; releaseTimer.start() }
	}
	Timer {
		id: releaseTimer
		interval: 100
		onTriggered: bm.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand
	}
}
