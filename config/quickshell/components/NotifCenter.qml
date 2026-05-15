import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
	id: notifCenter
    	screen: Quickshell.screens.length > 0 ? (root.focusedScreen ?? Quickshell.screens[0]) : undefined
    	visible: true
    	exclusionMode: ExclusionMode.Ignore
    	anchors { 
		top: true; 
		right: true; 
		bottom: true 
	}
	margins {
		top: 40
        	bottom: 10
        	right: root.notifCenterVisible ? 6 : -370
	}
	implicitWidth: 340
    	color: "transparent"
    	focusable: true
    	WlrLayershell.keyboardFocus: root.notifCenterVisible
	? WlrKeyboardFocus.OnDemand
	: WlrKeyboardFocus.None
	Behavior on margins.right {
		NumberAnimation { 
			duration: 300; 
			easing.type: Easing.OutCubic 
		}
	}
	function formatTime(date) {
		if (!date) return ""
        	var d = new Date(date)
        	var h = d.getHours()
        	var m = d.getMinutes()
        	var ampm = h >= 12 ? "PM" : "AM"
        	h = h % 12; h = h ? h : 12
        	return h + ":" + (m < 10 ? "0" + m : m) + " " + ampm
	}
	function formatDate(date) {
		if (!date) return ""
        	var d = new Date(date)
        	var now = new Date()
       	 	var isToday = d.toDateString() === now.toDateString()
        	if (isToday) return "Today " + formatTime(date)
        	var yesterday = new Date(now)
        	yesterday.setDate(now.getDate() - 1)
        	if (d.toDateString() === yesterday.toDateString())
            	return "Yesterday " + formatTime(date)
        	return d.toLocaleDateString() + " " + formatTime(date)
	}
	Item {
		anchors.fill: parent
        	focus: root.notifCenterVisible
		Keys.onPressed: function(event) {
			if (event.key === Qt.Key_Escape) {
				root.notifCenterVisible = false
                		event.accepted = true
			}
		}
		Rectangle {
			anchors.fill: parent
            		color: Qt.rgba(
				root.walBackground.r,
                		root.walBackground.g,
                		root.walBackground.b,
				0.95
			)
			radius: 20
			ColumnLayout {
				anchors.fill: parent
                		anchors.margins: 16
                		spacing: 12
				RowLayout {
					Layout.fillWidth: true
					Text {
						text: "󰂚"
                        			color: root.walColor5
                        			font { 
							pixelSize: 18; 
							family: "JetBrainsMono Nerd Font" 
						}
					}
					Text {
						text: "Notifications"
                        			color: root.walColor5
                        			font {
							pixelSize: 15
                            				bold: true
                            				family: "JetBrainsMono Nerd Font"
						}
						Layout.fillWidth: true
					}
					Rectangle {
						visible: root.notificationHistory.length > 0
                        			width: countText.implicitWidth + 10
                        			height: 20
                        			radius: 10
                        			color: Qt.rgba(
							root.walColor5.r,
                            				root.walColor5.g,
                            				root.walColor5.b,
                            				0.2
						)
						Text {
							id: countText
                            				anchors.centerIn: parent
                            				text: root.notificationHistory.length
                            				color: root.walColor5
                            				font {
								pixelSize: 10
                                				bold: true
                                				family: "JetBrainsMono Nerd Font"
							}
						}
					}
					Item { 
						width: 8 
					}
					Rectangle {
						width: 44; 
						height: 24; 
						radius: 12
						color: root.dndEnabled
						? root.walColor1
                               			: Qt.rgba(0.3, 0.3, 0.3, 0.5)
						Behavior on color { 
							ColorAnimation { 
								duration: 200 
							} 
						}
						Rectangle {
							width: 20; 
							height: 20; 
							radius: 10; 
							y: 2
							x: root.dndEnabled ? 22 : 2
							color: root.walBackground
							Behavior on x {
								NumberAnimation { 
									duration: 200; 
									easing.type: Easing.OutCubic 
								}
							}
						}
						MouseArea {
							anchors.fill: parent
							cursorShape: Qt.PointingHandCursor
							onClicked: {
								root.dndEnabled = !root.dndEnabled

							}
						}
					}
					Rectangle {
						visible: root.notificationHistory.length > 0
						width: 28; 
						height: 28; 
						radius: 8
						color: clearMa.containsMouse
							? Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.2)
							: "transparent"
							Behavior on color { 
								ColorAnimation { 
									duration: 150 
								} 
							}
							Text {
								anchors.centerIn: parent
                            					text: "󰆴"
                            					color: clearMa.containsMouse ? root.walColor1 : root.walColor8
                            					font { 
									pixelSize: 14; 
									family: "JetBrainsMono Nerd Font" 
								}
								Behavior on color { 
									ColorAnimation {
										duration: 150 
									} 
								}
							}
							MouseArea {
								id: clearMa
                            					anchors.fill: parent
                            					hoverEnabled: true
                            					cursorShape: Qt.PointingHandCursor
                            					onClicked: root.clearNotifHistory()
							}
						}
					}
					Rectangle {
						Layout.fillWidth: true
						height: 28
						radius: 8
						color: Qt.rgba(
							root.walColor1.r, 
							root.walColor1.g, 
							root.walColor1.b, 
							0.15
						)
						visible: root.dndEnabled
						RowLayout {
							anchors.centerIn: parent
                        				spacing: 6
                        				Text {
								text: "󰂛"
                            					color: root.walColor1
                            					font { 
									pixelSize: 12; 
									family: "JetBrainsMono Nerd Font" 
								}
							}
							Text {
								text: "Do Not Disturb is ON"
                            					color: root.walColor1
                            					font { 
									pixelSize: 10; 
									family: "JetBrainsMono Nerd Font" 
								}
							}
						}
					}
					Rectangle {
						Layout.fillWidth: true
                    				Layout.fillHeight: true
                    				color: Qt.rgba(0, 0, 0, 0.3)
                    				radius: 14
                    				clip: true
						Column {
							anchors.centerIn: parent
							spacing: 8
                        				visible: root.notificationHistory.length === 0
							Text {
								anchors.horizontalCenter: parent.horizontalCenter
                            					text: "󰂚"
                            					color: root.walColor8
                            					font { 
									pixelSize: 32; 
									family: "JetBrainsMono Nerd Font" 
								}
								opacity: 0.3
							}
							Text {
								anchors.horizontalCenter: parent.horizontalCenter
                            					text: "No notifications"
                            					color: root.walColor8
                            					font { 
									pixelSize: 12; 
									family: "JetBrainsMono Nerd Font" 
								}
								opacity: 0.5
							}
						}
						ListView {
							anchors.fill: parent
                        				anchors.margins: 8
                        				spacing: 6
                        				boundsBehavior: Flickable.StopAtBounds
                        				model: root.notificationHistory
                        				clip: true
                        				ScrollBar.vertical: ScrollBar {
								active: true; 
								width: 3
								policy: ScrollBar.AsNeeded
							}
							delegate: Rectangle {
								width: parent ? parent.width : 0
                            					height: notifCol.implicitHeight + 20
                            					radius: 12
                            					color: itemMa.containsMouse
									? Qt.rgba(1, 1, 1, 0.06)
									: Qt.rgba(0, 0, 0, 0.25)
									Behavior on color { 
										ColorAnimation { 
											duration: 120 
										} 
									}
									ColumnLayout {
										id: notifCol
										anchors {
											left: parent.left; 
											right: parent.right; 
											top: parent.top
                                    							margins: 12; 
											topMargin: 10
										}
										spacing: 4
										RowLayout {
											Layout.fillWidth: true
                                    							spacing: 6
											Rectangle {
												width: 5; 
												height: 5; 
												radius: 2.5
												color: root.walColor5
                                        							anchors.verticalCenter: parent.verticalCenter
											}
											Text {
												text: (modelData.app || "notification").toUpperCase()
												color: Qt.rgba(
													root.walColor5.r,
                                            								root.walColor5.g,
                                            								root.walColor5.b,
                                            								0.7
												)
												font {
													pixelSize: 8
                                            								bold: true
                                            								family: "JetBrainsMono Nerd Font"
                                            								letterSpacing: 1.0
												}
											}
											Item { 
												Layout.fillWidth: true
											}
											Text {
												text: notifCenter.formatDate(modelData.time)
                                        							color: root.walColor8
												font {
													pixelSize: 8
                                            								family: "JetBrainsMono Nerd Font"
												}
												opacity: 0.6
											}
										}
										Text {
											Layout.fillWidth: true
                                    							text: modelData.title || ""
                                    							color: root.walForeground
											font {
												pixelSize: 11
                                        							bold: true
                                        							family: "JetBrainsMono Nerd Font"
											}
											wrapMode: Text.WordWrap
                                    							maximumLineCount: 2
                                    							elide: Text.ElideRight
                                    							visible: (modelData.title || "") !== ""
										}
										Text {
											Layout.fillWidth: true
                                    							text: modelData.body || ""
                                    							color: Qt.rgba(
												root.walForeground.r,
                                        							root.walForeground.g,
                                        							root.walForeground.b,
                                        							0.5
											)
											font {
												pixelSize: 10
												family: "JetBrainsMono Nerd Font"
											}
											wrapMode: Text.WordWrap
                                    							maximumLineCount: 3
                                    							elide: Text.ElideRight
                                    							lineHeight: 1.3
                                    							visible: (modelData.body || "") !== ""
										}
									}
									Text {
										anchors {
											right: parent.right; 
											top: parent.top
                                    							margins: 8
										}
										text: "󰅖"
										color: dismissItemMa.containsMouse
											? root.walColor1
											: Qt.rgba(
												root.walForeground.r,
                                           							root.walForeground.g,
                                           							root.walForeground.b,
                                           							0.2
											)
											font { 
												pixelSize: 10; 
												family: "JetBrainsMono Nerd Font" 
											}
											opacity: itemMa.containsMouse ? 1.0 : 0.0
											Behavior on opacity { 
												NumberAnimation { 
													duration: 120 
												} 
											}
											Behavior on color   { 
												ColorAnimation  { 
													duration: 120 
												} 
											}
											MouseArea {
												id: dismissItemMa
                                    								anchors.fill: parent
                                    								anchors.margins: -6
                                    								hoverEnabled: true
                                    								cursorShape: Qt.PointingHandCursor
                                    								onClicked: {
													var hist = root.notificationHistory.slice()
                                        								hist.splice(index, 1)
                                        								root.notificationHistory = hist
												}
											}
										}
										MouseArea {
											id: itemMa
                                							anchors.fill: parent
                                							hoverEnabled: true
                                							z: -1
										}
									}
								}
							}
							Rectangle {
								Layout.fillWidth: true
                    						height: 24
                    						radius: 8
                    						color: Qt.rgba(0, 0, 0, 0.3)
								RowLayout {
									anchors.fill: parent
                        						anchors.leftMargin: 10
                        						anchors.rightMargin: 10
									Text {
										text: "󰂛 DND toggle"
										color: root.walColor8
                            							font { 
											pixelSize: 9; 
											family: "JetBrainsMono Nerd Font" 
										}
										opacity: 0.6
									}
									Item { 
										Layout.fillWidth: true 
									}
									Text {
										text: "esc close"
                            							color: root.walColor8
                            							font { 
											pixelSize: 9; 
											family: "JetBrainsMono Nerd Font" 
										}
										opacity: 0.6
									}
								}
							}
						}
					}
				}
				Connections {
					target: root
					function onNotifCenterVisibleChanged() {
						if (root.notifCenterVisible) focusTimer.start()
					}
				}
				Timer {
					id: focusTimer
        				interval: 50; 
					repeat: false
					onTriggered: {
						notifCenter.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive
            					releaseTimer.start()
					}
				}
				Timer {
					id: releaseTimer
					interval: 100; 
					repeat: false
					onTriggered: {
						notifCenter.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand
					}
				}
			}
