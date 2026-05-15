import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes

PanelWindow {
	id: clockPanel
	screen: Quickshell.screens.length > 0 ? (root.focusedScreen ?? Quickshell.screens[0]) : undefined
	visible: true
	exclusionMode: ExclusionMode.Ignore
	anchors { top: true; left: true }
	margins {
		top: 40
		left: root.clockPanelVisible ? 6 : -(implicitWidth + 20)
	}
	implicitWidth: 300
	implicitHeight: card.implicitHeight + 16
	color: "transparent"
	focusable: true
	WlrLayershell.keyboardFocus: root.clockPanelVisible
		? WlrKeyboardFocus.OnDemand
		: WlrKeyboardFocus.None

	Behavior on margins.left {
		NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
	}

	property int activeTab: 0

	property int    timerHours: 0
	property int    timerMinutes: 0
	property int    timerSeconds: 0
	property string timerState: "idle"
	property real   timerRemaining: 0
	property real   timerTotal: 0
	property real   timerLastUpdate: 0
	readonly property real timerFill: timerTotal > 0 ? (1.0 - timerRemaining / timerTotal) : 0

	property bool swRunning: false
	property real swElapsedMs: 0
	property real swAccumulated: 0
	property real swStartedAt: 0
	property real swLapBase: 0
	property var  swLaps: []

	property var    alarms: []
	property string alarmHourInput: ""
	property string alarmMinInput: ""
	property bool   alarmAddMode: false

	property string clockTime: Qt.formatDateTime(new Date(), "hh:mm AP")
	property string clockDate: Qt.formatDateTime(new Date(), "dddd, MMMM d")

	function msToDisplay(ms) {
		var t  = Math.max(0, Math.floor(ms))
		var cc = Math.floor(t / 10) % 100
		var ss = Math.floor(t / 1000) % 60
		var mm = Math.floor(t / 60000) % 60
		function p2(n) { return n < 10 ? "0" + n : "" + n }
		return p2(mm) + ":" + p2(ss) + "." + p2(cc)
	}

	function timerDisplayStr() {
		var ms = timerState === "idle"
			? (timerHours * 3600 + timerMinutes * 60 + timerSeconds) * 1000
			: timerRemaining
		var h = Math.floor(ms / 3600000)
		var m = Math.floor((ms % 3600000) / 60000)
		var s = Math.floor((ms % 60000) / 1000)
		function p2(n) { return n < 10 ? "0" + n : "" + n }
		return p2(h) + ":" + p2(m) + ":" + p2(s)
	}

	function startTimer() {
		timerTotal = (timerHours * 3600 + timerMinutes * 60 + timerSeconds) * 1000
		if (timerTotal <= 0) return
		timerRemaining = timerTotal
		timerLastUpdate = Date.now()
		timerState = "running"
	}
	function toggleTimer() {
		if (timerState === "idle" || timerState === "finished") {
			startTimer()
		} else if (timerState === "running") {
			timerState = "paused"
		} else {
			timerLastUpdate = Date.now()
			timerState = "running"
		}
	}
	function resetTimer() {
		timerState = "idle"; timerRemaining = 0; timerTotal = 0
		timerHours = 0; timerMinutes = 0; timerSeconds = 0
	}

	function startStopwatch()  { swStartedAt = Date.now(); swRunning = true }
	function pauseStopwatch()  { swAccumulated = swElapsedMs; swRunning = false }
	function resetStopwatch()  {
		swRunning = false; swElapsedMs = 0; swAccumulated = 0
		swStartedAt = 0; swLapBase = 0; swLaps = []
		swCanvas.requestPaint()
	}
	function lapStopwatch() {
		if (!swRunning) return
		var lapMs = swElapsedMs - swLapBase
		var nl = swLaps.slice()
		nl.unshift({ num: nl.length + 1, lapMs: lapMs, total: swElapsedMs })
		swLaps = nl
		swLapBase = swElapsedMs
	}

	function addAlarm() {
		var h = parseInt(alarmHourInput), m = parseInt(alarmMinInput)
		if (isNaN(h) || isNaN(m)) return
		h = Math.max(0, Math.min(23, h)); m = Math.max(0, Math.min(59, m))
		var t = (h < 10 ? "0" + h : h) + ":" + (m < 10 ? "0" + m : m)
		var na = alarms.slice()
		na.push({ time: t, enabled: true, id: Date.now() })
		na.sort(function(a, b) { return a.time < b.time ? -1 : 1 })
		alarms = na; alarmHourInput = ""; alarmMinInput = ""; alarmAddMode = false
	}
	function removeAlarm(id) { alarms = alarms.filter(function(a) { return a.id !== id }) }
	function toggleAlarm(id) {
		var na = alarms.slice()
		for (var i = 0; i < na.length; i++)
			if (na[i].id === id) { na[i] = { time: na[i].time, enabled: !na[i].enabled, id: id }; break }
		alarms = na
	}

	Timer {
		interval: 1000; running: true; repeat: true; triggeredOnStart: true
		onTriggered: {
			var now = new Date()
			clockPanel.clockTime = Qt.formatDateTime(now, "hh:mm AP")
			clockPanel.clockDate = Qt.formatDateTime(now, "dddd, MMMM d")
			if (clockPanel.activeTab === 0) clockCanvas.requestPaint()
			if (now.getSeconds() === 0) {
				var ts = Qt.formatDateTime(now, "HH:mm")
				for (var i = 0; i < clockPanel.alarms.length; i++) {
					if (clockPanel.alarms[i].enabled && clockPanel.alarms[i].time === ts) {
						alarmSoundProc.running  = true
						alarmNotifyProc.running = true
					}
				}
			}
		}
	}
	Timer {
		interval: 16; running: clockPanel.timerState === "running"; repeat: true
		onTriggered: {
			var now = Date.now()
			clockPanel.timerRemaining = Math.max(0, clockPanel.timerRemaining - (now - clockPanel.timerLastUpdate))
			clockPanel.timerLastUpdate = now
			if (clockPanel.timerRemaining <= 0) {
				clockPanel.timerState = "finished"
				timerSoundProc.running  = true
				timerNotifyProc.running = true
			}
		}
	}
	Timer {
		interval: 16; running: clockPanel.swRunning; repeat: true
		onTriggered: {
			clockPanel.swElapsedMs = clockPanel.swAccumulated + (Date.now() - clockPanel.swStartedAt)
			swCanvas.requestPaint()
		}
	}

	Process {
	    id: timerSoundProc
	    command: ["pw-play", Quickshell.env("HOME") + "/.config/quickshell/assets/timer.wav"]
	}
	Process {
	    id: alarmSoundProc
	    command: ["bash", "-c",
	        "for i in 1 2 3; do " +
	        "pw-play " + Quickshell.env("HOME") + "/.config/quickshell/assets/timer.wav; " +
	        "sleep 0.3; done"
	    ]
	}
	Process { id: timerNotifyProc; command: ["bash", "-c", "notify-send -u normal '󱎫 Timer' 'Timer finished!' 2>/dev/null || true"] }
	Process { id: alarmNotifyProc; command: ["bash", "-c", "notify-send -u critical '󰂟 Alarm' 'Alarm ringing!' 2>/dev/null || true"] }
	Item {
		anchors.fill: parent
		focus: root.clockPanelVisible
		Keys.onPressed: function(event) {
			if (event.key === Qt.Key_Escape) {
				clockPanel.alarmAddMode = false
				root.clockPanelVisible = false
				event.accepted = true
			} else if (event.key === Qt.Key_Space) {
				if (clockPanel.activeTab === 1) clockPanel.toggleTimer()
				else if (clockPanel.activeTab === 2) {
					if (clockPanel.swRunning) clockPanel.pauseStopwatch()
					else clockPanel.startStopwatch()
				}
				event.accepted = true
			}
		}
		Rectangle {
			id: card
			anchors.top: parent.top; anchors.topMargin: 8
			anchors.left: parent.left; anchors.leftMargin: 16
			width: 268
			implicitHeight: cardCol.implicitHeight + 32
			radius: 18
			color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.95)
			border.width: 1
			border.color: Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.08)
			MouseArea { anchors.fill: parent }

			ColumnLayout {
				id: cardCol
				anchors { top: parent.top; left: parent.left; right: parent.right; margins: 16 }
				spacing: 0
				Rectangle {
					Layout.fillWidth: true; height: 34; radius: 10
					color: Qt.rgba(0, 0, 0, 0.25)
					Row {
						anchors.fill: parent; anchors.margins: 3; spacing: 3
						Repeater {
							model: ["󰅐", "󱎫", "󰔟", "󰂟"]
							delegate: Rectangle {
								required property string modelData
								required property int    index
								width: (parent.width - 12) / 4; height: parent.height; radius: 8
								color: clockPanel.activeTab === index
									? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.25)
									: tabMa.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"
								Behavior on color { ColorAnimation { duration: 150 } }
								Text {
									anchors.centerIn: parent; text: modelData
									color: clockPanel.activeTab === index ? root.walColor5 : root.walColor8
									font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font"
									Behavior on color { ColorAnimation { duration: 150 } }
								}
								MouseArea {
									id: tabMa; anchors.fill: parent; hoverEnabled: true
									cursorShape: Qt.PointingHandCursor
									onClicked: clockPanel.activeTab = index
								}
							}
						}
					}
				}

				Item { Layout.preferredHeight: 12 }
				Column {
					Layout.fillWidth: true
					visible: clockPanel.activeTab === 0
					spacing: 8

					Item {
						width: parent.width; height: 180
						Canvas {
							id: clockCanvas
							anchors.centerIn: parent
							width: 168; height: 168; antialiasing: true

							onPaint: {
								var ctx = getContext("2d")
								ctx.clearRect(0, 0, width, height)
								var cx = width/2, cy = height/2, R = width/2 - 4

								ctx.beginPath(); ctx.arc(cx,cy,R,0,Math.PI*2)
								ctx.strokeStyle = Qt.rgba(root.walColor5.r,root.walColor5.g,root.walColor5.b,0.18)
								ctx.lineWidth = 1.5; ctx.stroke()

								for (var i = 0; i < 12; i++) {
									var a = i/12*Math.PI*2 - Math.PI/2
									ctx.beginPath()
									ctx.moveTo(cx+R*Math.cos(a), cy+R*Math.sin(a))
									ctx.lineTo(cx+(R-9)*Math.cos(a), cy+(R-9)*Math.sin(a))
									ctx.strokeStyle = Qt.rgba(root.walColor5.r,root.walColor5.g,root.walColor5.b,0.5)
									ctx.lineWidth = 2; ctx.stroke()
								}
								for (var j = 0; j < 60; j++) {
									if (j%5===0) continue
									var a2 = j/60*Math.PI*2 - Math.PI/2
									ctx.beginPath()
									ctx.moveTo(cx+R*Math.cos(a2), cy+R*Math.sin(a2))
									ctx.lineTo(cx+(R-4)*Math.cos(a2), cy+(R-4)*Math.sin(a2))
									ctx.strokeStyle = Qt.rgba(root.walColor5.r,root.walColor5.g,root.walColor5.b,0.18)
									ctx.lineWidth = 1; ctx.stroke()
								}

								var now = new Date()
								var hr=now.getHours()%12, min=now.getMinutes(), sec=now.getSeconds()

								var hrA = (hr+min/60)/12*Math.PI*2 - Math.PI/2
								ctx.beginPath(); ctx.moveTo(cx,cy)
								ctx.lineTo(cx+R*0.50*Math.cos(hrA), cy+R*0.50*Math.sin(hrA))
								ctx.strokeStyle = root.walColor5; ctx.lineWidth = 4; ctx.lineCap = "round"; ctx.stroke()

								var minA = (min+sec/60)/60*Math.PI*2 - Math.PI/2
								ctx.beginPath(); ctx.moveTo(cx,cy)
								ctx.lineTo(cx+R*0.72*Math.cos(minA), cy+R*0.72*Math.sin(minA))
								ctx.strokeStyle = root.walForeground; ctx.lineWidth = 2.5; ctx.lineCap = "round"; ctx.stroke()

								var secA = sec/60*Math.PI*2 - Math.PI/2
								ctx.beginPath()
								ctx.moveTo(cx-R*0.15*Math.cos(secA), cy-R*0.15*Math.sin(secA))
								ctx.lineTo(cx+R*0.85*Math.cos(secA), cy+R*0.85*Math.sin(secA))
								ctx.strokeStyle = root.walColor1; ctx.lineWidth = 1.5; ctx.lineCap = "round"; ctx.stroke()

								ctx.beginPath(); ctx.arc(cx,cy,4,0,Math.PI*2)
								ctx.fillStyle = root.walColor1; ctx.fill()
							}
						}
					}

					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: clockPanel.clockTime
						color: root.walForeground
						font.pixelSize: 28; font.bold: true; font.family: "JetBrainsMono Nerd Font"
					}
					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: clockPanel.clockDate
						color: Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.55)
						font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
					}
					Item { height: 4 }
				}
				Column {
					Layout.fillWidth: true
					visible: clockPanel.activeTab === 1
					spacing: 10

					Item {
						width: parent.width; height: 168
						Shape {
							anchors.centerIn: parent; width: 168; height: 168
							preferredRendererType: Shape.CurveRenderer
							ShapePath {
								fillColor: "transparent"
								strokeColor: Qt.rgba(root.walColor5.r,root.walColor5.g,root.walColor5.b,0.12)
								strokeWidth: 6
								PathAngleArc { centerX:84; centerY:84; radiusX:70; radiusY:70; startAngle:-90; sweepAngle:360 }
							}
							ShapePath {
								fillColor: "transparent"
								strokeColor: clockPanel.timerState === "finished" ? root.walColor1 : root.walColor5
								strokeWidth: 6; capStyle: ShapePath.RoundCap
								PathAngleArc { centerX:84; centerY:84; radiusX:70; radiusY:70; startAngle:-90; sweepAngle: 360*clockPanel.timerFill }
							}
						}
						Text {
							anchors.centerIn: parent
							text: clockPanel.timerDisplayStr()
							color: clockPanel.timerState === "finished" ? root.walColor1 : root.walForeground
							font.pixelSize: 24; font.bold: true; font.family: "JetBrainsMono Nerd Font"
						}
					}

					Row {
						anchors.horizontalCenter: parent.horizontalCenter
						spacing: 6; visible: clockPanel.timerState === "idle"
						Repeater {
							model: [
								{ v: clockPanel.timerHours,   l: "H", i: 0 },
								{ v: clockPanel.timerMinutes, l: "M", i: 1 },
								{ v: clockPanel.timerSeconds, l: "S", i: 2 }
							]
							delegate: Column {
								required property var modelData
								spacing: 3
								Rectangle {
									width: 62; height: 44; radius: 8; color: Qt.rgba(0,0,0,0.3)
									Text {
										anchors.centerIn: parent
										text: modelData.v < 10 ? "0" + modelData.v : "" + modelData.v
										color: root.walForeground; font.pixelSize: 20; font.bold: true; font.family: "JetBrainsMono Nerd Font"
									}
									MouseArea {
										anchors.fill: parent; cursorShape: Qt.PointingHandCursor
										onWheel: function(w) {
											var d = w.angleDelta.y > 0 ? 1 : -1
											if (modelData.i===0) clockPanel.timerHours   = (clockPanel.timerHours   + d + 24) % 24
											else if (modelData.i===1) clockPanel.timerMinutes = (clockPanel.timerMinutes + d + 60) % 60
											else clockPanel.timerSeconds = (clockPanel.timerSeconds + d + 60) % 60
										}
										onClicked: {
											if (modelData.i===0) clockPanel.timerHours   = (clockPanel.timerHours   + 1 + 24) % 24
											else if (modelData.i===1) clockPanel.timerMinutes = (clockPanel.timerMinutes + 1 + 60) % 60
											else clockPanel.timerSeconds = (clockPanel.timerSeconds + 1 + 60) % 60
										}
									}
								}
								Text {
									anchors.horizontalCenter: parent.horizontalCenter
									text: modelData.l; color: root.walColor8
									font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"
								}
							}
						}
					}

					Row {
						anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
						Rectangle {
							width: 76; height: 32; radius: 10
							visible: clockPanel.timerState !== "idle"
							color: rTMa.containsMouse ? Qt.rgba(root.walColor1.r,root.walColor1.g,root.walColor1.b,0.22) : Qt.rgba(0,0,0,0.3)
							Behavior on color { ColorAnimation { duration: 120 } }
							Text { anchors.centerIn: parent; text: "Reset"; color: root.walColor1; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font" }
							MouseArea { id: rTMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: clockPanel.resetTimer() }
						}
						Rectangle {
							width: clockPanel.timerState !== "idle" ? 76 : 116; height: 32; radius: 10
							Behavior on width { NumberAnimation { duration: 150 } }
							color: sTMa.containsMouse ? Qt.rgba(root.walColor5.r,root.walColor5.g,root.walColor5.b,0.35) : Qt.rgba(root.walColor5.r,root.walColor5.g,root.walColor5.b,0.2)
							Behavior on color { ColorAnimation { duration: 120 } }
							Text {
								anchors.centerIn: parent
								text: clockPanel.timerState==="idle" ? "Start" : clockPanel.timerState==="running" ? "Pause" : clockPanel.timerState==="paused" ? "Resume" : "Restart"
								color: root.walForeground; font.pixelSize: 11; font.bold: true; font.family: "JetBrainsMono Nerd Font"
							}
							MouseArea { id: sTMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: clockPanel.toggleTimer() }
						}
					}
					Item { height: 4 }
				}
				Column {
					Layout.fillWidth: true
					visible: clockPanel.activeTab === 2
					spacing: 10

					Item {
						width: parent.width; height: 168
						Canvas {
							id: swCanvas; anchors.centerIn: parent
							width: 168; height: 168; antialiasing: true
							onPaint: {
								var ctx = getContext("2d")
								ctx.clearRect(0,0,width,height)
								var cx=width/2, cy=height/2, R=76

								ctx.beginPath(); ctx.arc(cx,cy,R,0,Math.PI*2)
								ctx.strokeStyle = Qt.rgba(root.walColor2.r,root.walColor2.g,root.walColor2.b,0.12)
								ctx.lineWidth = 4; ctx.stroke()

								for (var i=0; i<60; i++) {
									var a = i/60*Math.PI*2 - Math.PI/2
									var isMaj = i%5===0
									ctx.beginPath()
									ctx.moveTo(cx+R*Math.cos(a), cy+R*Math.sin(a))
									ctx.lineTo(cx+(R-(isMaj?9:4))*Math.cos(a), cy+(R-(isMaj?9:4))*Math.sin(a))
									ctx.strokeStyle = Qt.rgba(root.walColor2.r,root.walColor2.g,root.walColor2.b,isMaj?0.45:0.12)
									ctx.lineWidth = isMaj?1.5:0.8; ctx.stroke()
								}

								var frac = (clockPanel.swElapsedMs % 60000) / 60000
								if (frac > 0) {
									ctx.beginPath()
									ctx.arc(cx,cy,R,-Math.PI/2,-Math.PI/2+frac*Math.PI*2)
									ctx.strokeStyle = root.walColor2
									ctx.lineWidth = 4; ctx.lineCap = "round"; ctx.stroke()
								}
							}
						}
						Text {
							anchors.centerIn: parent
							text: clockPanel.msToDisplay(clockPanel.swElapsedMs)
							color: root.walForeground
							font.pixelSize: 20; font.bold: true; font.family: "JetBrainsMono Nerd Font"
						}
					}

					Column {
						width: parent.width; spacing: 4
						visible: clockPanel.swLaps.length > 0
						Repeater {
							model: Math.min(clockPanel.swLaps.length, 3)
							delegate: Rectangle {
								width: parent ? parent.width : 0; height: 22; radius: 6; color: Qt.rgba(0,0,0,0.2)
								Row {
									anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
									Text { width: 28; text: "L"+clockPanel.swLaps[index].num; color: root.walColor8; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; anchors.verticalCenter: parent.verticalCenter }
									Text { text: clockPanel.msToDisplay(clockPanel.swLaps[index].lapMs); color: root.walForeground; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; anchors.verticalCenter: parent.verticalCenter }
								}
							}
						}
					}

					Row {
						anchors.horizontalCenter: parent.horizontalCenter; spacing: 8
						Rectangle {
							width: 72; height: 32; radius: 10
							visible: clockPanel.swElapsedMs > 0 && !clockPanel.swRunning
							color: swRMa.containsMouse ? Qt.rgba(root.walColor1.r,root.walColor1.g,root.walColor1.b,0.22) : Qt.rgba(0,0,0,0.3)
							Behavior on color { ColorAnimation { duration: 120 } }
							Text { anchors.centerIn: parent; text: "Reset"; color: root.walColor1; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font" }
							MouseArea { id: swRMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: clockPanel.resetStopwatch() }
						}
						Rectangle {
							width: 72; height: 32; radius: 10
							visible: clockPanel.swRunning
							color: swLMa.containsMouse ? Qt.rgba(root.walColor4.r,root.walColor4.g,root.walColor4.b,0.22) : Qt.rgba(0,0,0,0.3)
							Behavior on color { ColorAnimation { duration: 120 } }
							Text { anchors.centerIn: parent; text: "Lap"; color: root.walColor4; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font" }
							MouseArea { id: swLMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: clockPanel.lapStopwatch() }
						}
						Rectangle {
							width: 80; height: 32; radius: 10
							color: swSMa.containsMouse ? Qt.rgba(root.walColor2.r,root.walColor2.g,root.walColor2.b,0.35) : Qt.rgba(root.walColor2.r,root.walColor2.g,root.walColor2.b,0.2)
							Behavior on color { ColorAnimation { duration: 120 } }
							Text {
								anchors.centerIn: parent
								text: clockPanel.swRunning ? "Pause" : (clockPanel.swElapsedMs > 0 ? "Resume" : "Start")
								color: root.walForeground; font.pixelSize: 11; font.bold: true; font.family: "JetBrainsMono Nerd Font"
							}
							MouseArea {
								id: swSMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
								onClicked: { if (clockPanel.swRunning) clockPanel.pauseStopwatch(); else clockPanel.startStopwatch() }
							}
						}
					}
					Item { height: 4 }
				}

				Column {
					Layout.fillWidth: true
					visible: clockPanel.activeTab === 3
					spacing: 8

					Rectangle {
						width: parent.width
						height: Math.max(80, Math.min(200, clockPanel.alarms.length * 50 + 10))
						radius: 12; color: Qt.rgba(0,0,0,0.3); clip: true
						ListView {
							anchors.fill: parent; anchors.margins: 6; spacing: 4
							boundsBehavior: Flickable.StopAtBounds; model: clockPanel.alarms
							delegate: Rectangle {
								required property var modelData
								required property int index
								width: parent?parent.width:0; height: 40; radius: 10; color: Qt.rgba(0,0,0,0.2)
								RowLayout {
									anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
									Text {
										text: modelData.time
										color: modelData.enabled ? root.walForeground : root.walColor8
										font.pixelSize: 18; font.bold: modelData.enabled; font.family: "JetBrainsMono Nerd Font"
									}
									Item { Layout.fillWidth: true }
									Rectangle {
										width: 38; height: 20; radius: 10
										color: modelData.enabled ? root.walColor5 : Qt.rgba(0.3,0.3,0.3,0.5)
										Behavior on color { ColorAnimation { duration: 200 } }
										Rectangle {
											width: 16; height: 16; radius: 8; y: 2
											x: modelData.enabled ? 20 : 2; color: root.walBackground
											Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
										}
										MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: clockPanel.toggleAlarm(modelData.id) }
									}
									Rectangle {
										width: 24; height: 24; radius: 6
										color: aDelMa.containsMouse ? Qt.rgba(root.walColor1.r,root.walColor1.g,root.walColor1.b,0.2) : "transparent"
										Text { anchors.centerIn: parent; text: "󰆴"; color: root.walColor1; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font" }
										MouseArea { id: aDelMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: clockPanel.removeAlarm(modelData.id) }
									}
								}
							}
						}
						Text {
							anchors.centerIn: parent; visible: clockPanel.alarms.length === 0
							text: "No alarms set"; color: root.walColor8; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
						}
					}

					Rectangle {
						width: parent.width
						height: clockPanel.alarmAddMode ? 46 : 36
						radius: 10; color: Qt.rgba(0,0,0,0.3); clip: true
						Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

						RowLayout {
							anchors.fill: parent; anchors.margins: 8; spacing: 6
							visible: clockPanel.alarmAddMode
							Text { text: "󰂟"; color: root.walColor5; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font" }
							Rectangle {
								width: 44; height: 28; radius: 6; color: Qt.rgba(0,0,0,0.3)
								TextInput {
									anchors.centerIn: parent; width: parent.width-8
									text: clockPanel.alarmHourInput; onTextChanged: clockPanel.alarmHourInput = text
									color: root.walForeground; font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font"
									horizontalAlignment: TextInput.AlignHCenter; maximumLength: 2
									validator: IntValidator { bottom: 0; top: 23 }
									Text { anchors.centerIn: parent; text: "HH"; color: root.walColor8; visible: !parent.text; font: parent.font }
								}
							}
							Text { text: ":"; color: root.walColor8; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font" }
							Rectangle {
								width: 44; height: 28; radius: 6; color: Qt.rgba(0,0,0,0.3)
								TextInput {
									anchors.centerIn: parent; width: parent.width-8
									text: clockPanel.alarmMinInput; onTextChanged: clockPanel.alarmMinInput = text
									color: root.walForeground; font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font"
									horizontalAlignment: TextInput.AlignHCenter; maximumLength: 2
									validator: IntValidator { bottom: 0; top: 59 }
									Keys.onReturnPressed: clockPanel.addAlarm()
									Text { anchors.centerIn: parent; text: "MM"; color: root.walColor8; visible: !parent.text; font: parent.font }
								}
							}
							Item { Layout.fillWidth: true }
							Rectangle {
								width: 28; height: 28; radius: 8
								color: cMa.containsMouse ? Qt.rgba(root.walColor2.r,root.walColor2.g,root.walColor2.b,0.3) : Qt.rgba(root.walColor2.r,root.walColor2.g,root.walColor2.b,0.15)
								Text { anchors.centerIn: parent; text: "󰄬"; color: root.walColor2; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font" }
								MouseArea { id: cMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: clockPanel.addAlarm() }
							}
							Rectangle {
								width: 28; height: 28; radius: 8
								color: xMa.containsMouse ? Qt.rgba(root.walColor1.r,root.walColor1.g,root.walColor1.b,0.2) : "transparent"
								Text { anchors.centerIn: parent; text: "󰅖"; color: root.walColor8; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font" }
								MouseArea { id: xMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: clockPanel.alarmAddMode = false }
							}
						}

						RowLayout {
							anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
							visible: !clockPanel.alarmAddMode
							Text { text: "Add alarm"; color: root.walColor8; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font" }
							Item { Layout.fillWidth: true }
							Text { text: ""; color: root.walColor5; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font" }
						}
						MouseArea {
							anchors.fill: parent; visible: !clockPanel.alarmAddMode; cursorShape: Qt.PointingHandCursor
							onClicked: { clockPanel.alarmAddMode = true; clockPanel.alarmHourInput = ""; clockPanel.alarmMinInput = "" }
						}
					}

					Rectangle {
						width: parent.width; height: 22; radius: 8; color: Qt.rgba(0,0,0,0.2)
						Row {
							anchors.centerIn: parent; spacing: 5
							Text { text: "󰔊"; color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; opacity: 0.6 }
							Text { text: "24h · sound + notify on alarm"; color: root.walColor8; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; opacity: 0.6 }
						}
					}
					Item { height: 4 }
				}
				Rectangle {
					Layout.fillWidth: true; height: 22; radius: 8; color: Qt.rgba(0,0,0,0.2)
					RowLayout {
						anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
						Text {
							text: clockPanel.activeTab===1||clockPanel.activeTab===2 ? "space  start/pause" : ""
							color: root.walColor8; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; opacity: 0.6
							visible: text !== ""
						}
						Item { Layout.fillWidth: true }
						Text { text: "esc  close"; color: root.walColor8; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; opacity: 0.6 }
					}
				}
				Item { Layout.preferredHeight: 4 }
			}
		}
	}

	Connections {
		target: root
		function onClockPanelVisibleChanged() {
			if (root.clockPanelVisible) focusTimer.start()
		}
	}
	Timer { id: focusTimer; interval: 50; repeat: false
		onTriggered: { clockPanel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive; releaseTimer.start() } }
	Timer { id: releaseTimer; interval: 100; repeat: false
		onTriggered: { clockPanel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand } }
}
