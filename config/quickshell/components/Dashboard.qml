import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

PanelWindow {
	id: dashboard
    	screen: Quickshell.screens.length > 0 ? (root.focusedScreen ?? Quickshell.screens[0]) : undefined
    	visible: true
    	exclusionMode: ExclusionMode.Ignore
    	anchors {
    		top: true
    		bottom: true
    		right: true
    	}
    	margins {
    		top: (10) + root.barInsetTop
    		bottom: (root.barInsetBottom + 8)
    		right: (root.dashboardVisible ? 6 : -450) + root.barInsetRight
    	}
    	implicitWidth: 420
    	color: "transparent"
    	focusable: true
    	WlrLayershell.keyboardFocus: root.dashboardVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    	Behavior on margins.right { 
		NumberAnimation { 
			duration: 300; 
			easing.type: Easing.OutCubic 
		} 
	}
    	property int cpuVal: 0
    	property int ramVal: 0
    	property int diskVal: 0
	property string cpuUsed: ""
	property string cpuDetail: ""
	property string ramUsed: ""
	property string ramDetail: ""
	property string diskUsed: ""
	property string diskDetail: ""
    	property int batVal: 100
    	property int volVal: 50
    	property int brightVal: 100
	// ── v9: weather (~/.config/scripts/weather.sh, Open-Meteo) ──
	property var wx: null
	property real wxFetchedAt: 0
	function wxRefresh(force) {
		if (wxProc.running) return
		wxProc.command = [root.homePath + "/.config/scripts/weather.sh"].concat(force ? ["--force"] : [])
		wxProc.running = true
	}
	function wxIcon(c, day) {
		if (c === 0 || c === 1) return day ? "󰖙" : "󰖔"
		if (c === 2) return day ? "󰖕" : "󰼱"
		if (c === 3) return "󰖐"
		if (c === 45 || c === 48) return "󰖑"
		if (c === 65 || c === 82) return "󰖖"
		if (c === 66 || c === 67) return "󰙿"
		if ((c >= 51 && c <= 63) || c === 80 || c === 81) return "󰖗"
		if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "󰖘"
		if (c === 95) return "󰙾"
		if (c === 96 || c === 99) return "󰖒"
		return "󰖐"
	}
	function wxDesc(c) {
		var d = { 0: "Clear", 1: "Mostly clear", 2: "Partly cloudy", 3: "Overcast", 45: "Fog", 48: "Freezing fog",
		          51: "Light drizzle", 53: "Drizzle", 55: "Heavy drizzle", 56: "Freezing drizzle", 57: "Freezing drizzle",
		          61: "Light rain", 63: "Rain", 65: "Heavy rain", 66: "Freezing rain", 67: "Freezing rain",
		          71: "Light snow", 73: "Snow", 75: "Heavy snow", 77: "Snow grains", 80: "Showers", 81: "Showers",
		          82: "Heavy showers", 85: "Snow showers", 86: "Snow showers", 95: "Thunderstorm",
		          96: "Thunderstorm, hail", 99: "Thunderstorm, hail" }
		return d[c] || "—"
	}
	function wxTint(c, day) {
		if (c <= 1) return day ? root.walPeach : root.walColor13
		if (c === 2) return day ? root.walColor4 : root.walColor13
		if (c === 3 || c === 45 || c === 48) return root.walColor8
		if (c >= 95) return root.walColor5
		if ((c >= 71 && c <= 77) || c === 85 || c === 86) return root.walForeground
		return root.walColor6
	}
	function aqiLabel(v) {
		return v <= 50 ? "good" : v <= 100 ? "moderate" : v <= 150 ? "sensitive" : v <= 200 ? "unhealthy" : v <= 300 ? "very unhealthy" : "hazardous"
	}
	function aqiTint(v) {
		return v <= 50 ? root.walColor2 : v <= 100 ? root.walColor4 : v <= 150 ? root.walPeach : root.walColor1
	}
	// ── v6: network speed (physical interfaces that are up; VPN tunnels skipped so
	//    traffic isn't counted twice) ──
	property real netRx: -1
	property real netTx: -1
	property string netIface: ""
	property var netHist: []
	property var netPrev: null
	function fmtRate(b) {
		if (b < 0) return "—"
		if (b < 1024) return Math.round(b) + " B/s"
		if (b < 1048576) return (b / 1024).toFixed(b < 10240 ? 1 : 0) + " KB/s"
		return (b / 1048576).toFixed(b < 10485760 ? 2 : 1) + " MB/s"
	}
	function fmtBits(b) {
		if (b < 0) return ""
		var m = b * 8 / 1e6
		return (m < 10 ? m.toFixed(1) : Math.round(m)) + " Mbps"
	}
	function netSample(text) {
		var rx = 0, tx = 0, best = "", bestBytes = -1, now = Date.now()
		var lines = ("" + text).split("\n")
		for (var i = 0; i < lines.length; i++) {
			var f = lines[i].trim().split(/\s+/)
			if (f.length < 3) continue
			var r = parseFloat(f[1]) || 0, t = parseFloat(f[2]) || 0
			rx += r; tx += t
			if (r + t > bestBytes) { bestBytes = r + t; best = f[0] }
		}
		netIface = best
		var p = netPrev
		netPrev = { rx: rx, tx: tx, t: now }
		if (!p || now - p.t > 3500 || rx < p.rx || tx < p.tx) return
		var dt = (now - p.t) / 1000
		netRx = (rx - p.rx) / dt
		netTx = (tx - p.tx) / dt
		var h = netHist.slice()
		h.push({ rx: netRx, tx: netTx })
		while (h.length > 40) h.shift()
		netHist = h
	}
	// ── v5: wheel steps are queued and sent one command at a time (relative ±5%),
	//    and the 2 s poll doesn't overwrite the value while you're scrolling
	property int volPending: 0
	property int brightPending: 0
	property real volAcc: 0
	property real brightAcc: 0
	property real volHold: 0
	property real brightHold: 0
	function wheelSteps(wheel, which) {
		var dy = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y * 4
		var acc = (which === "vol" ? volAcc : brightAcc) + dy
		var steps = acc >= 0 ? Math.floor(acc / 120) : Math.ceil(acc / 120)
		acc -= steps * 120
		if (which === "vol") volAcc = acc; else brightAcc = acc
		return steps
	}
	function scrollVol(wheel) {
		var n = wheelSteps(wheel, "vol")
		if (n === 0) return
		volVal = Math.max(0, Math.min(100, volVal + n * 5))
		volPending += n
		flushVol()
	}
	function scrollBright(wheel) {
		var n = wheelSteps(wheel, "bright")
		if (n === 0) return
		brightVal = Math.max(1, Math.min(100, brightVal + n * 5))
		brightPending += n
		flushBright()
	}
	function flushVol() {
		volHold = Date.now() + 1500
		if (volPending === 0 || volStepProc.running) return
		var n = volPending
		volPending = 0
		volStepProc.command = ["bash", "-c", "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ " + Math.abs(n * 5) + "%" + (n > 0 ? "+" : "-")
			+ "; wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf \"%.0f\\n\", $2*100}'"]
		volStepProc.running = true
	}
	function flushBright() {
		brightHold = Date.now() + 1500
		if (brightPending === 0 || brightStepProc.running) return
		var n = brightPending
		brightPending = 0
		brightStepProc.command = ["brightnessctl", "-m", "--min-value=1", "set", Math.abs(n * 5) + "%" + (n > 0 ? "+" : "-")]
		brightStepProc.running = true
	}
    	property string configPath: Quickshell.env("HOME") + "/.config/quickshell"
	Item {
		anchors.fill: parent
        	focus: root.dashboardVisible
		Keys.onPressed: function(event) {
			if (event.key === Qt.Key_Escape) {
				if (profileSection.pfpPickerOpen) {
					profileSection.pfpPickerOpen = false
				} else {
					root.dashboardVisible = false
				}
				event.accepted = true
			}
		}
		Rectangle {
			anchors.fill: parent
            		color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.95)
					radius: 20
					border.width: 1
    border.color: Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.45)
			MouseArea {
				anchors.fill: parent
                		visible: profileSection.pfpPickerOpen
                		onClicked: profileSection.pfpPickerOpen = false
                		z: 50
			}
			ColumnLayout {
				anchors.fill: parent
                		anchors.margins: 20
                		spacing: 15
                		z: 100
				Rectangle {
					id: profileSection
                    			Layout.fillWidth: true
                    			Layout.preferredHeight: pfpPickerOpen ? 280 : 100
                    			color: root.card(0.5)
                    			radius: 15
                    			clip: true
                    			property bool pfpPickerOpen: false
                    			Behavior on Layout.preferredHeight { 
						NumberAnimation { 
							duration: 200; 
							easing.type: Easing.OutCubic 
						} 
					}
					ColumnLayout {
						anchors.fill: parent
                        			anchors.margins: 15
                        			spacing: 15
						RowLayout {
							Layout.fillWidth: true
							spacing: 15
                            				Item {
								id: pfpContainer
                                				width: 74
                                				height: 74
                                				Rectangle {
									id: pfpBorder
                                    					anchors.fill: parent
                                    					radius: 37
                                    					color: "transparent"
                                    					border.width: 3
                                    					border.color: root.walColor5
								}
								Image {
									id: pfpImage
                                   					anchors.centerIn: parent
                                    					width: 68
                                    					height: 68
                                    					source: "file://" + dashboard.configPath + "/assets/pfps/pfp.jpg"
                                    					fillMode: Image.PreserveAspectCrop
                                    					smooth: true
                                    					cache: false
                                    					sourceSize.width: 256
                                    					sourceSize.height: 256
                                    					visible: false
                                    					property int reloadTrigger: 0
                                    					function reload() {
										reloadTrigger++
                                        					source = ""
                                        					source = "file://" + dashboard.configPath + "/assets/pfps/pfp.jpg?" + reloadTrigger
									}
								}
								Rectangle {
									id: pfpMask
                                    					anchors.centerIn: parent
                                    					width: 68
                                    					height: 68
                                    					radius: 34
                                    					visible: false
								}
								OpacityMask {
									anchors.centerIn: parent
                                    					width: 68
                                    					height: 68
                                    					source: pfpImage
                                    					maskSource: pfpMask
								}
								Rectangle {
									anchors.right: parent.right
                                    					anchors.bottom: parent.bottom
                                    					width: 22
                                    					height: 22
                                    					radius: 11
                                    					color: root.walColor5
                                    					border.width: 2
                                    					border.color: root.walBackground
                                    					Text {
										anchors.centerIn: parent
                                        					text: "󰏫"
                                        					color: root.walBackground
                                        					font.pixelSize: 12
                                        					font.family: "JetBrainsMono Nerd Font"
									}
								}
								MouseArea {
									anchors.fill: parent
                                    					cursorShape: Qt.PointingHandCursor
                                    					onClicked: {
										profileSection.pfpPickerOpen = !profileSection.pfpPickerOpen
                                        					if (profileSection.pfpPickerOpen) {
											root.pfpFiles = []
                                            						pfpListProc.running = true
										}
									}
								}
							}
							ColumnLayout {
								Layout.fillWidth: true
                                				spacing: 5
                                				Text {
									text: Quickshell.env("USER")
                                    					color: root.walColor5
                                    					font.pixelSize: 26
                                    					font.bold: true
                                    					font.family: "JetBrainsMono Nerd Font"
								}
								Text {
									id: uptimeText
                                    					text: "up ..."
                                   					color: root.walForeground
                                    					font.pixelSize: 12
                                    					font.family: "JetBrainsMono Nerd Font"
								}
							}
						}
						Rectangle {
							Layout.fillWidth: true
                            				Layout.fillHeight: true
                            				color: root.card(0.5)
                            				radius: 10
                            				visible: profileSection.pfpPickerOpen
							ColumnLayout {
								anchors.fill: parent
                               					anchors.margins: 10
                                				spacing: 8
								Text {
									text: "Choose Avatar"
                                    					color: root.walColor5
                                    					font.pixelSize: 12
                                    					font.bold: true
                                    					font.family: "JetBrainsMono Nerd Font"
                                    					Layout.alignment: Qt.AlignHCenter
								}
								Flickable {
									Layout.fillWidth: true
                                    					Layout.fillHeight: true
                                    					contentWidth: width
                                    					contentHeight: pfpGrid.height
                                    					clip: true
                                    					ScrollBar.vertical: ScrollBar { 
										policy: ScrollBar.AsNeeded 
									}
									GridLayout {
										id: pfpGrid
                                        					width: parent.width
                                       						columns: 6
                                        					rowSpacing: 8
                                        					columnSpacing: 8
                                        					Repeater {
											model: root.pfpFiles
											Item {
												width: 48
                                                						height: 48
                                                						Layout.alignment: Qt.AlignHCenter
                                                						Rectangle {
												anchors.fill: parent
                                                    						radius: 24
                                                    						color: "transparent"
                                                    						border.width: 2
                                                   						border.color: thumbMa.containsMouse ? root.walColor13 : root.walColor5
                                                    						Behavior on border.color { 
												ColorAnimation { 
												duration: 150 
												} 
												}
												}
												Image {
												id: thumbImg
                                                    						anchors.centerIn: parent
                                                    						width: 44
                                                    						height: 44
                                                  						source: "file://" + modelData
                                                    						fillMode: Image.PreserveAspectCrop
                                                   						smooth: true
                                                    						sourceSize.width: 128
                                                    						sourceSize.height: 128
                                                   						visible: false
												}
												Rectangle {
												id: thumbMask
                                                    						anchors.centerIn: parent
                                                    						width: 44
                                                    						height: 44
                                                    						radius: 22
                                                    						visible: false
												}
												OpacityMask {
												anchors.centerIn: parent
                                                    						width: 44
                                                    						height: 44
                                                    						source: thumbImg
                                                    						maskSource: thumbMask
												}
												MouseArea {
												id: thumbMa
                                                    						anchors.fill: parent
                                                   						hoverEnabled: true
                                                    						cursorShape: Qt.PointingHandCursor
                                                    						onClicked: {
												setPfpProc.selFile = modelData
                                                        					setPfpProc.running = true
												}
												}
											}
										}
									}
								}
							}
						}
					}
					Process {
						id: pfpListProc
                        			command: ["bash", "-c", "find " + dashboard.configPath + "/assets/pfps -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.png' -o -iname '*.gif' \\) ! -name 'pfp.jpg' | sort"]
                        			stdout: SplitParser {
							onRead: data => {
								var file = data.trim()
                                				if (file.length > 0) {
									var current = root.pfpFiles.slice()
                                    					current.push(file)
                                   					root.pfpFiles = current
								}
							}
						}
					}
					Process {
						id: setPfpProc
                        			property string selFile: ""
                        			command: ["cp", "--", selFile, dashboard.configPath + "/assets/pfps/pfp.jpg"]   // secfix
                        			onExited: {
							pfpImage.reload()
                            				profileSection.pfpPickerOpen = false
						}
					}
				}
				Rectangle {
					Layout.fillWidth: true
                    			Layout.preferredHeight: 50
                    			color: root.card(0.5)
                    			radius: 15
					Row {
						anchors.centerIn: parent
                        			spacing: 25
						PowerBtn { 
							icon: "⏻"; 
							iconColor: root.walColor2; 
							cmd: '"$HOME/.config/scripts/power.sh" poweroff' 
						}
						PowerBtn { 
							icon: "󰜉"; 
							iconColor: root.walColor13; 
							cmd: '"$HOME/.config/scripts/power.sh" reboot' 
						}
						PowerBtn { 
							icon: "󰌾"; 
							iconColor: root.walColor5; 
							cmd: '"$HOME/.config/scripts/power.sh" lock' 
						}
						PowerBtn { 
							icon: "󰒲"; 
							iconColor: root.walColor4; 
							cmd: '"$HOME/.config/scripts/power.sh" suspend' 
						}
						PowerBtn { 
							icon: "󰍃"; 
							iconColor: root.walColor1; 
							cmd: '"$HOME/.config/scripts/power.sh" logout' 
						}
					}
				}
				Rectangle {
					id: modeToggles
					Layout.fillWidth: true
					Layout.preferredHeight: 62
					color: root.card(0.5)
					radius: 15
					RowLayout {
						anchors.fill: parent
						anchors.margins: 7
						spacing: 7
						ModeChip {
							icon: "󰛨"
							label: "Night light"
							sub: (root.nightLight ? "On · " : "Off · ") + root.nightTemp + "K · scroll"
							active: root.nightLight
							accent: root.walColor4
							onToggled: root.toggleNightLight()
							onScrolled: function(step) { root.setNightTemp(step) }
						}
						ModeChip {
							icon: root.lightMode ? "󰖨" : "󰖔"
							label: root.lightMode ? "Light theme" : "Dark theme"
							sub: root.lightMode ? "Latte · tap for dark" : "Mocha · tap for light"
							active: root.lightMode
							accent: root.walColor13
							onToggled: root.toggleLightMode()
						}
					}
				}
				Rectangle {
					Layout.fillWidth: true
                   			Layout.preferredHeight: 70
                    			color: root.card(0.5)
                    			radius: 15
                    			RowLayout {
						anchors.fill: parent
                        			anchors.margins: 15
                        			spacing: 15
                       				Text {
							id: batIcon
                            				text: "󰁹"
                            				color: root.walColor2
                            				font.pixelSize: 32
                            				font.family: "JetBrainsMono Nerd Font"
						}
						ColumnLayout {
							Layout.fillWidth: true
                            				spacing: 3
                            				Text {
								text: "Battery " + dashboard.batVal + "%"
                                				color: root.walForeground
                                				font.pixelSize: 18
                                				font.family: "JetBrainsMono Nerd Font"
							}
							Text {
								id: batStatus
                                				text: "Checking..."
                                				color: root.walColor8
                                				font.pixelSize: 12
                                				font.family: "JetBrainsMono Nerd Font"
							}
						}
					}
				}
				Rectangle {
					Layout.fillWidth: true
                    			Layout.preferredHeight: 164
                    			color: root.card(0.5)
                    			radius: 15
                    			Row {
						anchors.centerIn: parent
                        			spacing: 22

                        			CircularStat { 
							label: "CPU"; 
							icon: ""; 
							barColor: root.walColor1; 
							value: dashboard.cpuVal; used: dashboard.cpuUsed; detail: dashboard.cpuDetail 
						}
                        			CircularStat { 
							label: "RAM"; 
							icon: ""; 
							barColor: root.walColor5; 
							value: dashboard.ramVal; used: dashboard.ramUsed; detail: dashboard.ramDetail 
						}
                      				CircularStat { 
							label: "DISKS"; 
							icon: ""; 
							barColor: root.walColor4; 
							value: dashboard.diskVal; used: dashboard.diskUsed; detail: dashboard.diskDetail 
						}
					}
				}
				Rectangle {
					Layout.fillWidth: true
                    			Layout.preferredHeight: 100
                    			color: root.card(0.5)
                    			radius: 15
                    			Column {
						anchors.fill: parent
                        			anchors.margins: 15
                        			spacing: 15
						Row {
							width: parent.width
                            				spacing: 10
							Text {
								width: 25
                                				text: dashboard.volVal == 0 ? "󰝟" : dashboard.volVal < 50 ? "󰖀" : "󰕾"
                                				color: root.walColor4
                                				font.pixelSize: 18
                                				font.family: "JetBrainsMono Nerd Font"
                                				verticalAlignment: Text.AlignVCenter
                                				height: 24
                                				MouseArea {
									anchors.fill: parent
                                    					cursorShape: Qt.PointingHandCursor
                                    					onClicked: volMuteProc.running = true
								}
								Process {
									id: volMuteProc
                                    					command: ["bash", "-c", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"]
                                    					onExited: volProc.running = true
								}
							}
							Rectangle {
								id: volSlider
                                				width: parent.width - 75
                                				height: 8
                               					anchors.verticalCenter: parent.verticalCenter
                                				radius: 4
                                				color: root.card(0.3)
                                				Rectangle {
									width: parent.width * dashboard.volVal / 100
                                    					height: parent.height
                                    					radius: 4
                                    					color: root.walColor4
                                    					Behavior on width { 
										NumberAnimation { 
											duration: 100 
										} 
									}
								}
								MouseArea {
									anchors.fill: parent
                                    					cursorShape: Qt.PointingHandCursor
                                    					anchors.topMargin: -6
									anchors.bottomMargin: -6
									onWheel: function(wheel) { dashboard.scrollVol(wheel) }
									onClicked: function(mouse) {
										var percent = Math.round((mouse.x / parent.width) * 100)
                                        					percent = Math.max(0, Math.min(100, percent))
                                        					dashboard.volVal = percent
                                        					volSetProc.command = ["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (percent / 100).toFixed(2)]
                                        					volSetProc.running = true
									}
									onPositionChanged: function(mouse) {
										if (pressed) {
											var percent = Math.round((mouse.x / parent.width) * 100)
                                            						percent = Math.max(0, Math.min(100, percent))
                                            						dashboard.volVal = percent
                                            						volSetProc.command = ["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + (percent / 100).toFixed(2)]
                                            						volSetProc.running = true
										}
									}
								}
								Process { 
									id: volSetProc 
								}
							}
							Text {
								width: 40
								text: dashboard.volVal + "%"
                                				color: root.walColor8
                                				font.pixelSize: 11
                                				font.family: "JetBrainsMono Nerd Font"
                                				horizontalAlignment: Text.AlignRight
                                				verticalAlignment: Text.AlignVCenter
                                				height: 24
							}
						}
						Row {
							width: parent.width
                            				spacing: 10
                            				Text {
								width: 25
                                				text: dashboard.brightVal < 30 ? "󰃞" : dashboard.brightVal < 70 ? "󰃟" : "󰃠"
                                				color: root.walColor13
                                				font.pixelSize: 18
                                				font.family: "JetBrainsMono Nerd Font"
                                				verticalAlignment: Text.AlignVCenter
                                				height: 24
							}
							Rectangle {
								id: brightSlider
                                				width: parent.width - 75
                                				height: 8
                                				anchors.verticalCenter: parent.verticalCenter
                                				radius: 4
                                				color: root.card(0.3)
                                				Rectangle {
									width: parent.width * dashboard.brightVal / 100
                                    					height: parent.height
                                    					radius: 4
                                    					color: root.walColor13
                                    					Behavior on width { 
										NumberAnimation { 
											duration: 100 
										} 
									}
								}
								MouseArea {
									anchors.fill: parent
                                    					cursorShape: Qt.PointingHandCursor
                                    					anchors.topMargin: -6
									anchors.bottomMargin: -6
									onWheel: function(wheel) { dashboard.scrollBright(wheel) }
									onClicked: function(mouse) {
										var percent = Math.round((mouse.x / parent.width) * 100)
                                        					percent = Math.max(1, Math.min(100, percent))
                                        					dashboard.brightVal = percent
                                        					brightSetProc.command = ["bash", "-c", "$HOME/.config/scripts/brightness.sh set " + percent]
                                        					brightSetProc.running = true
									}
									onPositionChanged: function(mouse) {
										if (pressed) {
											var percent = Math.round((mouse.x / parent.width) * 100)
                                            						percent = Math.max(1, Math.min(100, percent))
                                            						dashboard.brightVal = percent
                                           						brightSetProc.command = ["bash", "-c", "$HOME/.config/scripts/brightness.sh set " + percent]
                                            						brightSetProc.running = true	
										}
									}
								}
								Process { 
									id: brightSetProc 
								}
							}
							Text {
								width: 40
                                				text: dashboard.brightVal + "%"
                                				color: root.walColor8
                                				font.pixelSize: 11
                                				font.family: "JetBrainsMono Nerd Font"
                                				horizontalAlignment: Text.AlignRight
                                				verticalAlignment: Text.AlignVCenter
                                				height: 24
							}
						}
					}
				}
				Rectangle {
					// ── network speed ──
					Layout.fillWidth: true
					Layout.preferredHeight: 74
					color: root.card(0.5)
					radius: 15
					RowLayout {
						anchors.fill: parent
						anchors.leftMargin: 15
						anchors.rightMargin: 12
						anchors.topMargin: 10
						anchors.bottomMargin: 10
						spacing: 14
						Repeater {
							model: [
								{ icon: "󰇚", label: "DOWN", key: "rx" },
								{ icon: "󰕒", label: "UP", key: "tx" }
							]
							delegate: ColumnLayout {
								required property var modelData
								readonly property real rate: modelData.key === "rx" ? dashboard.netRx : dashboard.netTx
								readonly property color tint: modelData.key === "rx" ? root.walColor2 : root.walPeach
								spacing: 1
								Layout.preferredWidth: 92
								Row {
									spacing: 5
									Text {
										text: modelData.icon
										color: tint
										font.pixelSize: 12
										font.family: "JetBrainsMono Nerd Font"
									}
									Text {
										text: modelData.label
										color: root.walColor8
										font.pixelSize: 9
										font.bold: true
										font.letterSpacing: 0.6
										font.family: "JetBrainsMono Nerd Font"
										anchors.verticalCenter: parent.verticalCenter
									}
								}
								Text {
									text: dashboard.fmtRate(rate)
									color: root.walForeground
									font.pixelSize: 15
									font.bold: true
									font.family: "JetBrainsMono Nerd Font"
								}
								Text {
									text: dashboard.fmtBits(rate)
									color: root.walColor8
									font.pixelSize: 9
									font.family: "JetBrainsMono Nerd Font"
								}
							}
						}
						Item {
							Layout.fillWidth: true
							Layout.fillHeight: true
							Canvas {
								id: netCanvas
								anchors.fill: parent
								property var hist: dashboard.netHist
								onHistChanged: requestPaint()
								onPaint: {
									var ctx = getContext("2d")
									ctx.reset()
									var h = hist
									if (!h || h.length < 2) return
									var max = 4096
									for (var i = 0; i < h.length; i++) max = Math.max(max, h[i].rx, h[i].tx)
									var step = width / 39
									function trace(key, col, fill) {
										ctx.beginPath()
										for (var i = 0; i < h.length; i++) {
											var x = width - (h.length - 1 - i) * step
											var y = height - 2 - (height - 6) * h[i][key] / max
											if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
										}
										ctx.strokeStyle = col
										ctx.lineWidth = 1.6
										ctx.stroke()
										if (fill) {
											ctx.lineTo(width, height)
											ctx.lineTo(width - (h.length - 1) * step, height)
											ctx.closePath()
											ctx.fillStyle = Qt.rgba(col.r, col.g, col.b, 0.15)
											ctx.fill()
										}
									}
									trace("rx", root.walColor2, true)
									trace("tx", root.walPeach, false)
								}
							}
							Text {
								anchors.top: parent.top
								anchors.right: parent.right
								text: dashboard.netIface
								color: root.walColor8
								opacity: 0.7
								font.pixelSize: 9
								font.family: "JetBrainsMono Nerd Font"
							}
						}
					}
					Timer {
						interval: 1000
						running: root.dashboardVisible
						repeat: true
						triggeredOnStart: true
						onTriggered: if (!netProc.running) netProc.running = true
					}
					Process {
						id: netProc
						command: ["bash", "-c", "for i in /sys/class/net/*; do n=${i##*/}; [ -e \"$i/device\" ] || continue; [ \"$(cat \"$i/operstate\" 2>/dev/null)\" = up ] || continue; echo \"$n $(cat \"$i/statistics/rx_bytes\") $(cat \"$i/statistics/tx_bytes\")\"; done"]
						stdout: StdioCollector { onStreamFinished: dashboard.netSample(this.text) }
					}
				}
				Rectangle {
					// ── weather (replaces the clock — it lives in the calendar panel) ──
					id: wxCard
					Layout.fillWidth: true
					Layout.fillHeight: true
					Layout.minimumHeight: 110
					color: root.card(0.5)
					radius: 15
					clip: true
					readonly property var w: dashboard.wx
					readonly property bool ok: w !== null && w.ok === true
					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: dashboard.wxRefresh(true)
					}
					ColumnLayout {
						visible: wxCard.ok
						anchors.fill: parent
						anchors.margins: 14
						spacing: 10
						// now
						RowLayout {
							Layout.fillWidth: true
							spacing: 12
							Text {
								text: wxCard.ok ? dashboard.wxIcon(wxCard.w.now.code, wxCard.w.now.day) : ""
								color: wxCard.ok ? dashboard.wxTint(wxCard.w.now.code, wxCard.w.now.day) : root.walColor8
								font.pixelSize: 46
								font.family: "JetBrainsMono Nerd Font"
							}
							ColumnLayout {
								Layout.fillWidth: true
								spacing: 0
								Row {
									spacing: 2
									Text {
										text: wxCard.ok ? wxCard.w.now.temp + "°" : ""
										color: root.walForeground
										font.pixelSize: 34
										font.bold: true
										font.family: "JetBrainsMono Nerd Font"
									}
								}
								Text {
									Layout.fillWidth: true
									elide: Text.ElideRight
									text: wxCard.ok ? dashboard.wxDesc(wxCard.w.now.code) + " · feels " + wxCard.w.now.feels + "°" : ""
									color: root.walColor8
									font.pixelSize: 11
									font.family: "JetBrainsMono Nerd Font"
								}
							}
							ColumnLayout {
								spacing: 1
								Layout.alignment: Qt.AlignTop
								Text {
									Layout.alignment: Qt.AlignRight
									text: wxCard.ok ? wxCard.w.place : ""
									color: root.walColor5
									font.pixelSize: 11
									font.bold: true
									font.family: "JetBrainsMono Nerd Font"
								}
								Text {
									Layout.alignment: Qt.AlignRight
									text: wxCard.ok ? "H " + wxCard.w.today.max + "°  L " + wxCard.w.today.min + "°" : ""
									color: root.walForeground
									font.pixelSize: 11
									font.family: "JetBrainsMono Nerd Font"
								}
								Text {
									Layout.alignment: Qt.AlignRight
									text: wxCard.ok ? (wxCard.w.stale ? "offline · " : "") + "at " + wxCard.w.updated : ""
									color: wxCard.ok && wxCard.w.stale ? root.walColor1 : root.walColor8
									opacity: 0.7
									font.pixelSize: 9
									font.family: "JetBrainsMono Nerd Font"
								}
							}
						}
						// details
						Flow {
							Layout.fillWidth: true
							spacing: 6
							Repeater {
								model: !wxCard.ok ? [] : [
									{ i: "󰖎", t: wxCard.w.now.humidity + "%", c: root.walColor6 },
									{ i: "󰖝", t: wxCard.w.now.wind + " " + wxCard.w.wind_unit, c: root.walColor13 },
									{ i: "󰕊", t: wxCard.w.today.pop + "% rain", c: root.walColor4 },
									{ i: "󰖙", t: "UV " + wxCard.w.today.uv, c: wxCard.w.today.uv >= 6 ? root.walPeach : root.walColor2 }
								].concat(wxCard.w.aqi ? [{ i: "󰌪", t: "AQI " + wxCard.w.aqi.us + " · " + dashboard.aqiLabel(wxCard.w.aqi.us), c: dashboard.aqiTint(wxCard.w.aqi.us) }] : [])
								delegate: Rectangle {
									required property var modelData
									width: chipRow.implicitWidth + 14
									height: 22
									radius: 11
									color: Qt.rgba(modelData.c.r, modelData.c.g, modelData.c.b, 0.14)
									Row {
										id: chipRow
										anchors.centerIn: parent
										spacing: 4
										Text { text: modelData.i; color: modelData.c; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font" }
										Text { text: modelData.t; color: root.walForeground; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; anchors.verticalCenter: parent.verticalCenter }
									}
								}
							}
						}
						// next hours
						Row {
							id: hourRow
							visible: wxCard.height > 230
							Layout.fillWidth: true
							Repeater {
								model: wxCard.ok ? wxCard.w.hours : []
								delegate: Column {
									required property var modelData
									required property int index
									width: hourRow.width / Math.max(1, wxCard.w.hours.length)
									spacing: 2
									Text {
										anchors.horizontalCenter: parent.horizontalCenter
										text: index === 0 ? "now" : modelData.h
										color: index === 0 ? root.walColor5 : root.walColor8
										font.pixelSize: 9
										font.bold: index === 0
										font.family: "JetBrainsMono Nerd Font"
									}
									Text {
										anchors.horizontalCenter: parent.horizontalCenter
										text: dashboard.wxIcon(modelData.code, modelData.day)
										color: dashboard.wxTint(modelData.code, modelData.day)
										font.pixelSize: 16
										font.family: "JetBrainsMono Nerd Font"
									}
									Text {
										anchors.horizontalCenter: parent.horizontalCenter
										text: modelData.temp + "°"
										color: root.walForeground
										font.pixelSize: 10
										font.family: "JetBrainsMono Nerd Font"
									}
									Text {
										anchors.horizontalCenter: parent.horizontalCenter
										text: modelData.pop >= 20 ? modelData.pop + "%" : " "
										color: root.walColor6
										font.pixelSize: 8
										font.family: "JetBrainsMono Nerd Font"
									}
								}
							}
						}
						// next days
						ColumnLayout {
							visible: wxCard.height > 340
							Layout.fillWidth: true
							spacing: 4
							Repeater {
								model: wxCard.ok ? wxCard.w.days : []
								delegate: RowLayout {
									required property var modelData
									Layout.fillWidth: true
									spacing: 8
									readonly property real lo: Math.min.apply(null, wxCard.w.days.map(function(d) { return d.min }))
									readonly property real hi: Math.max.apply(null, wxCard.w.days.map(function(d) { return d.max }))
									Text {
										text: Qt.formatDate(new Date(modelData.date + "T12:00:00"), "ddd")
										color: root.walColor8
										font.pixelSize: 10
										font.family: "JetBrainsMono Nerd Font"
										Layout.preferredWidth: 30
									}
									Text {
										text: dashboard.wxIcon(modelData.code, true)
										color: dashboard.wxTint(modelData.code, true)
										font.pixelSize: 14
										font.family: "JetBrainsMono Nerd Font"
										Layout.preferredWidth: 20
									}
									Text {
										text: modelData.pop >= 20 ? modelData.pop + "%" : ""
										color: root.walColor6
										font.pixelSize: 9
										font.family: "JetBrainsMono Nerd Font"
										Layout.preferredWidth: 28
									}
									Text {
										text: modelData.min + "°"
										color: root.walColor8
										font.pixelSize: 10
										font.family: "JetBrainsMono Nerd Font"
										Layout.preferredWidth: 26
										horizontalAlignment: Text.AlignRight
									}
									Item {
										Layout.fillWidth: true
										height: 4
										Rectangle {
											anchors.fill: parent
											radius: 2
											color: root.card(0.6)
										}
										Rectangle {
											readonly property real span: Math.max(1, parent.parent.hi - parent.parent.lo)
											x: parent.width * (modelData.min - parent.parent.lo) / span
											width: Math.max(4, parent.width * (modelData.max - modelData.min) / span)
											height: parent.height
											radius: 2
											gradient: Gradient {
												orientation: Gradient.Horizontal
												GradientStop { position: 0; color: root.walColor6 }
												GradientStop { position: 1; color: root.walPeach }
											}
										}
									}
									Text {
										text: modelData.max + "°"
										color: root.walForeground
										font.pixelSize: 10
										font.family: "JetBrainsMono Nerd Font"
										Layout.preferredWidth: 26
									}
								}
							}
						}
						Item { Layout.fillHeight: true }
						// sun
						RowLayout {
							Layout.fillWidth: true
							spacing: 12
							Text {
								text: "󰖜 " + (wxCard.ok ? wxCard.w.sun.rise : "")
								color: root.walPeach
								font.pixelSize: 10
								font.family: "JetBrainsMono Nerd Font"
							}
							Text {
								text: "󰖛 " + (wxCard.ok ? wxCard.w.sun.set : "")
								color: root.walColor13
								font.pixelSize: 10
								font.family: "JetBrainsMono Nerd Font"
							}
							Item { Layout.fillWidth: true }
							Text {
								text: wxProc.running ? "󰑐 updating…" : "tap to refresh"
								color: root.walColor8
								opacity: 0.6
								font.pixelSize: 9
								font.family: "JetBrainsMono Nerd Font"
							}
						}
					}
					// loading / error
					Column {
						visible: !wxCard.ok
						anchors.centerIn: parent
						spacing: 6
						Text {
							anchors.horizontalCenter: parent.horizontalCenter
							text: "󰖐"
							color: root.walColor8
							font.pixelSize: 34
							font.family: "JetBrainsMono Nerd Font"
						}
						Text {
							anchors.horizontalCenter: parent.horizontalCenter
							text: dashboard.wx && dashboard.wx.error ? dashboard.wx.error + " · tap to retry" : "loading weather…"
							color: root.walColor8
							font.pixelSize: 10
							font.family: "JetBrainsMono Nerd Font"
						}
					}
					Process {
						id: wxProc
						stdout: StdioCollector {
							onStreamFinished: {
								try {
									var j = JSON.parse(this.text)
									if (j.ok || !dashboard.wx || !dashboard.wx.ok) dashboard.wx = j
									if (j.ok) dashboard.wxFetchedAt = Date.now()
								} catch (e) {
									if (!dashboard.wx || !dashboard.wx.ok) dashboard.wx = { ok: false, error: "weather.sh failed" }
								}
							}
						}
					}
					Timer {
						// on open, then every 10 min while the dashboard is open (the script caches 15 min)
						interval: 600000
						running: root.dashboardVisible
						repeat: true
						triggeredOnStart: true
						onTriggered: dashboard.wxRefresh(false)
					}
				}
			}
		}
	}
	Connections {
		target: root
		function onDashboardVisibleChanged() {
			if (root.dashboardVisible) {
				focusTimer.start()
			}
		}
	}
	Timer {
		id: focusTimer
		interval: 50
        	repeat: false
        	onTriggered: {
			dashboard.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive
            		releaseTimer.start()
		}
	}
	Timer {
		id: releaseTimer
        	interval: 100
        	repeat: false
        	onTriggered: {
			dashboard.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand
		}
	}
	component CircularStat: Item {
		id: stat
		property string label
		property string icon
		property color barColor
		property int value
		property string used: ""
		property string detail: ""
		readonly property bool hovered: statMa.containsMouse
		width: 100
		height: 132
		Column {
			anchors.centerIn: parent
			spacing: 8
			Item {
				width: 76
				height: 76
				anchors.horizontalCenter: parent.horizontalCenter
				scale: stat.hovered ? 1.06 : 1.0
				Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
				Canvas {
					anchors.fill: parent
					property int statValue: stat.value
					property bool hov: stat.hovered
					property color track: root.card(0.5)
					property color fg: stat.barColor
					onStatValueChanged: requestPaint()
					onHovChanged: requestPaint()
					onTrackChanged: requestPaint()
					onFgChanged: requestPaint()
					onPaint: {
						var ctx = getContext("2d")
						ctx.clearRect(0, 0, width, height)
						var r = width / 2 - 5
						ctx.lineWidth = hov ? 7 : 5
						ctx.lineCap = "round"
						ctx.strokeStyle = track
						ctx.beginPath()
						ctx.arc(width / 2, height / 2, r, 0, 2 * Math.PI)
						ctx.stroke()
						ctx.strokeStyle = fg
						ctx.beginPath()
						ctx.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + (statValue / 100) * 2 * Math.PI)
						ctx.stroke()
					}
				}
				Column {
					anchors.centerIn: parent
					spacing: 1
					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: stat.icon
						color: stat.barColor
						font.pixelSize: stat.hovered ? 12 : 16
						font.family: "JetBrainsMono Nerd Font"
					}
					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: stat.hovered && stat.used !== "" ? stat.used : stat.value + "%"
						color: root.walForeground
						font.pixelSize: stat.hovered ? 11 : 14
						font.bold: stat.hovered
						font.family: "JetBrainsMono Nerd Font"
					}
					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						visible: stat.hovered
						text: stat.value + "%"
						color: stat.barColor
						font.pixelSize: 9
						font.family: "JetBrainsMono Nerd Font"
					}
				}
			}
			Text {
				width: stat.width
				horizontalAlignment: Text.AlignHCenter
				text: stat.hovered && stat.detail !== "" ? stat.detail : stat.label
				color: stat.hovered ? stat.barColor : root.walColor8
				font.pixelSize: stat.hovered ? 10 : 11
				font.bold: stat.hovered
				font.family: "JetBrainsMono Nerd Font"
				lineHeight: 0.95
			}
		}
		MouseArea {
			id: statMa
			anchors.fill: parent
			hoverEnabled: true
		}
	}
	component ModeChip: Rectangle {
		id: chip
		property string icon
		property string label
		property string sub
		property bool active: false
		property color accent: root.walColor5
		signal toggled()
		signal scrolled(int step)
		Layout.fillWidth: true
		Layout.fillHeight: true
		radius: 12
		color: active
			? Qt.rgba(accent.r, accent.g, accent.b, 0.22)
			: (chipMa.containsMouse ? root.hover(0.06) : "transparent")
		border.width: active ? 1 : 0
		border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.55)
		Behavior on color { ColorAnimation { duration: 200 } }
		RowLayout {
			anchors.fill: parent
			anchors.leftMargin: 12
			anchors.rightMargin: 12
			spacing: 10
			Text {
				text: chip.icon
				color: chip.active ? chip.accent : root.walColor8
				font.pixelSize: 20
				font.family: "JetBrainsMono Nerd Font"
				Behavior on color { ColorAnimation { duration: 200 } }
			}
			ColumnLayout {
				Layout.fillWidth: true
				spacing: 1
				Text {
					text: chip.label
					color: root.walForeground
					font.pixelSize: 12
					font.bold: true
					font.family: "JetBrainsMono Nerd Font"
				}
				Text {
					text: chip.sub
					color: root.walColor8
					font.pixelSize: 9
					font.family: "JetBrainsMono Nerd Font"
					elide: Text.ElideRight
					Layout.fillWidth: true
				}
			}
		}
		MouseArea {
			id: chipMa
			anchors.fill: parent
			hoverEnabled: true
			cursorShape: Qt.PointingHandCursor
			onClicked: chip.toggled()
			onWheel: function(wheel) { chip.scrolled(wheel.angleDelta.y > 0 ? 1 : -1) }
		}
	}
	component PowerBtn: Rectangle {
		property string icon
        	property color iconColor
        	property string cmd
        	width: 40
        	height: 40
        	radius: 10
        	color: powerMa.containsMouse ? root.hover(0.1) : "transparent"
		Behavior on color { 
			ColorAnimation { 
				duration: 150 
			} 
		}
		Text {
			anchors.centerIn: parent
            		text: icon
            		color: iconColor
            		font.pixelSize: 18
            		font.family: "JetBrainsMono Nerd Font"
		}
		MouseArea {
			id: powerMa
            		anchors.fill: parent
            		hoverEnabled: true
           		cursorShape: Qt.PointingHandCursor
            		onClicked: { root.dashboardVisible = false; Quickshell.execDetached(["bash", "-c", cmd]) }
		}
		Process {
			id: cmdProc
            		command: ["bash", "-c", cmd]
		}
	}
	Timer {
		interval: 1000
        	running: true
        	repeat: true
        	triggeredOnStart: true
        	onTriggered: {
			var now = new Date()
            		var hours = now.getHours()
            		var minutes = now.getMinutes()
            		var seconds = now.getSeconds()
            		var ampm = hours >= 12 ? 'PM' : 'AM'
            		hours = hours % 12
            		hours = hours ? hours : 12
            		var h = hours < 10 ? '0' + hours : hours
            		var m = minutes < 10 ? '0' + minutes : minutes
            		var s = seconds < 10 ? '0' + seconds : seconds
            		// clock moved to the calendar panel (v9)
            		
		}
	}
	Timer {
		interval: 2000
        	running: root.dashboardVisible
        	repeat: true
        	triggeredOnStart: true
        	onTriggered: {
			if (!cpuProc.running) cpuProc.running = true
            		if (!ramProc.running) ramProc.running = true
            		if (!diskProc.running) diskProc.running = true
            		if (!batProc.running) batProc.running = true
            		if (!batStatusProc.running) batStatusProc.running = true
            		if (!volProc.running) volProc.running = true
            		if (!brightProc.running) brightProc.running = true
            		if (!uptimeProc.running) uptimeProc.running = true
		}
	}
	Process {
		id: cpuProc
		command: ["bash", "-c", "c=$(top -bn1 | awk '/Cpu\\(s\\)/ {print int($2 + $4)}'); n=$(nproc); f=$(awk '/^cpu MHz/ {s+=$4; k++} END {if (k) printf \"%.1f\", s/k/1000}' /proc/cpuinfo); echo \"${c:-0}|$n|${f:-?}\""]
		stdout: SplitParser {
			onRead: data => {
				var p = data.trim().split("|")
				dashboard.cpuVal = parseInt(p[0]) || 0
				var n = parseInt(p[1]) || 1
				dashboard.cpuUsed = (dashboard.cpuVal * n / 100).toFixed(1) + " cores"
				dashboard.cpuDetail = "of " + n + " · " + p[2] + " GHz"
			}
		}
	}
	Process {
		id: ramProc
		command: ["bash", "-c", "free -b | awk '/Mem:/ {printf \"%.0f|%.1f|%.1f\", $3/$2*100, $3/1073741824, $2/1073741824}'"]
		stdout: SplitParser {
			onRead: data => {
				var p = data.trim().split("|")
				dashboard.ramVal = parseInt(p[0]) || 0
				dashboard.ramUsed = p[1] + " GiB"
				dashboard.ramDetail = "of " + p[2] + " GiB"
			}
		}
	}
	Process {
		id: diskProc
		// every real block device once (/ and /nix/store share one), boot/vfat and tmpfs skipped
		command: ["bash", "-c", "df -B1 -x tmpfs -x devtmpfs -x efivarfs -x vfat -x overlay -x squashfs --output=source,size,used,target 2>/dev/null | awk 'NR>1 && $1 ~ /^\\/dev\\// && !seen[$1]++ {s+=$2; u+=$3; n=$4; if (n==\"/\") n=\"root\"; else sub(/.*\\//,\"\",n); d=d sprintf(\"%s%s %.0fG\", (d==\"\"?\"\":\" · \"), n, $3/1e9); k++} END {printf \"%.0f|%.0f|%.0f|%d|%s\", (s?u/s*100:0), u/1e9, s/1e9, k, d}'"]
		stdout: SplitParser {
			onRead: data => {
				var p = data.trim().split("|")
				dashboard.diskVal = parseInt(p[0]) || 0
				var used = parseInt(p[1]) || 0, total = parseInt(p[2]) || 0, count = parseInt(p[3]) || 1
				function fmt(gb) { return gb >= 1000 ? (gb / 1000).toFixed(2) + " TB" : gb + " GB" }
				dashboard.diskUsed = fmt(used)
				dashboard.diskDetail = "of " + fmt(total) + (count > 1 ? " · " + count + " disks\n" + (p[4] || "") : "")
			}
		}
	}
	Process {
		id: batProc
        	command: ["bash", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo 100"]
        	stdout: SplitParser {
			onRead: data => {
				dashboard.batVal = parseInt(data) || 100
                		var cap = dashboard.batVal
                		if (cap >= 90) batIcon.text = "󰁹"
                		else if (cap >= 80) batIcon.text = "󰂂"
                		else if (cap >= 70) batIcon.text = "󰂁"
                		else if (cap >= 60) batIcon.text = "󰂀"
                		else if (cap >= 50) batIcon.text = "󰁿"
                		else if (cap >= 40) batIcon.text = "󰁾"
                		else if (cap >= 30) batIcon.text = "󰁽"
                		else if (cap >= 20) batIcon.text = "󰁼"
                		else if (cap >= 10) batIcon.text = "󰁻"
                		else batIcon.text = "󰁺"
			}
		}
	}
	Process {
		id: batStatusProc
        	command: ["bash", "-c", "cat /sys/class/power_supply/BAT*/status 2>/dev/null || echo Unknown"]
		stdout: SplitParser {
			onRead: data => {
				var status = data.trim()
                		if (status === "Charging") {
					batStatus.text = "Charging"
                    			batIcon.text = "󰂄"
				} else if (status === "Full") {
					batStatus.text = "Fully charged"
				} else {
					batStatus.text = "Discharging"
				}
			}
		}
	}
	Process {
		id: volProc
		command: ["bash", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf \"%.0f\", $2*100}'"]
        	stdout: SplitParser { 
			onRead: data => { if (Date.now() > dashboard.volHold) dashboard.volVal = parseInt(data) || 0 } 
		}
	}
	Process {
		id: volStepProc
		stdout: SplitParser { onRead: data => { var v = parseInt(data); if (!isNaN(v)) dashboard.volVal = v } }
		onExited: dashboard.flushVol()
	}
	Process {
		id: brightStepProc
		stdout: SplitParser {
			onRead: data => {
				var f = data.split(",")
				if (f.length > 3) { var v = parseInt(f[3]); if (!isNaN(v)) dashboard.brightVal = Math.max(1, v) }
			}
		}
		onExited: dashboard.flushBright()
	}
	Process {
		id: brightProc
        command: ["bash", "-c", "$HOME/.config/scripts/brightness.sh get"]
		stdout: SplitParser { 
			onRead: data => { if (Date.now() > dashboard.brightHold) dashboard.brightVal = parseInt(data) || 100 } 
		}
	}
	Process {
		id: uptimeProc
		command: ["bash", "-c", "awk '{s=int($1); m=s/60; h=s/3600; d=s/86400; mo=s/2592000; if (mo>=1) printf \"up %d month%s %d day%s\", mo, (mo==1?\"\":\"s\"), (d%30), ((d%30)==1?\"\":\"s\"); else if (d>=1) printf \"up %d day%s %d hour%s\", d, (d==1?\"\":\"s\"), (h%24), ((h%24)==1?\"\":\"s\"); else if (h>=1) printf \"up %d hour%s %d min\", h, (h==1?\"\":\"s\"), (m%60); else printf \"up %d min\", m}' /proc/uptime"]
		stdout: SplitParser { 
			onRead: data => uptimeText.text = data.trim() 
		}
	}
}
