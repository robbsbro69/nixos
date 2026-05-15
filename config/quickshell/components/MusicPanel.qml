import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

PanelWindow {
	id: musicPanel
	screen: Quickshell.screens.length > 0 ? (root.focusedScreen ?? Quickshell.screens[0]) : undefined
	visible: true
	exclusionMode: ExclusionMode.Ignore
	anchors {
		top: true
		left: true
		right: true
	}
	margins {
		top: root.musicVisible ? 50 : -350
		left: 0
		right: 0
	}
	implicitWidth: 400
	implicitHeight: musicPanel.gifSelectorOpen
		? 460
		: (musicPanel.playerDropdownOpen
			? 188 + 8 + 28 + 1 + 34 + (musicPanel.availablePlayers.length * 34) + 16
			: 188)
	color: "transparent"
	focusable: true
	WlrLayershell.keyboardFocus: root.musicVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
	Behavior on margins.top {
		NumberAnimation {
			duration: 300
			easing.type: Easing.OutCubic
		}
	}
	Behavior on implicitHeight {
		NumberAnimation {
			duration: 200
			easing.type: Easing.OutCubic
		}
	}
	property string configPath: root.configPath
	property string gifPath: configPath + "/assets/gifs"
	property string vinylAsset: "file://" + configPath + "/assets/Vinyl.png"
	property string playerStatus: "Stopped"
	property string trackTitle: ""
	property string trackArtist: ""
	property string trackArtUrl: ""
	property real position: 0
	property real lastPosition: 0
	property real length: 0
	property bool hasTrack: playerStatus === "Playing" || playerStatus === "Paused"
	property int displayMode: 0
	property bool vinylWithArt: true
	property real vinylRotation: 0
	property bool vinylHeld: false
	property real dragStartPos: 0
	property real dragStartAngle: 0
	property real lastDragX: 0
	property real totalDrag: 0
	property bool vinylWasPlaying: false
	property var gifFiles: []
	property int currentGifIndex: root.savedGifIndex
	property int previewGifIndex: 0
	property bool gifSelectorOpen: false
	property bool gifsLoaded: false
	property int gifReloadCounter: 0
	property bool isApplyingGif: false
	property string currentGifSource: "file://" + gifPath + "/current.gif"
	property int pendingGifIndex: -1
	property int pickerTab: 0
	property string activePlayer: "%any"
	property string resolvedPlayer: "%any"
	property var availablePlayers: []
	property bool playerDropdownOpen: false

	function formatTime(seconds) {
		var mins = Math.floor(seconds / 60)
		var secs = Math.floor(seconds % 60)
		return mins + ":" + (secs < 10 ? "0" : "") + secs
	}
	function gifFileName(path) {
		var parts = path.split("/")
		var name = parts[parts.length - 1]
		return name.replace(".gif", "")
	}
	function playerDisplayName(player) {
		if (!player || player === "%any") return "Auto"
		var name = player
		var dotIdx = name.indexOf(".")
		if (dotIdx > 0) name = name.substring(0, dotIdx)
		return name.charAt(0).toUpperCase() + name.slice(1)
	}
	function playerIcon(player) {
		if (!player || player === "%any") return "󰝚"
		var n = player.toLowerCase()
		if (n.indexOf("firefox") >= 0 || n.indexOf("mozilla") >= 0) return "󰈹"
		if (n.indexOf("chromium") >= 0 || n.indexOf("chrome") >= 0) return ""
		if (n.indexOf("spotify") >= 0) return "󰓇"
		if (n.indexOf("mpv") >= 0) return "󰐌"
		if (n.indexOf("vlc") >= 0) return "󰕼"
		if (n.indexOf("rhythmbox") >= 0 || n.indexOf("clementine") >= 0) return "󰝚"
		if (n.indexOf("cmus") >= 0 || n.indexOf("ncmpcpp") >= 0 || n.indexOf("mpd") >= 0) return "󰎆"
		if (n.indexOf("youtube") >= 0) return "󰗃"
		return "󰝚"
	}
	function refreshPlayers() {
		if (!playerListProc.running) playerListProc.running = true
	}
	function grabVinyl(mx) {
		vinylSpinAnim.stop()
		vinylWasPlaying = playerStatus === "Playing"
		vinylHeld = true
		totalDrag = 0
		lastDragX = mx
		dragStartPos = position
		dragStartAngle = vinylRotation
		if (vinylWasPlaying) {
			playPauseProc.command = ["playerctl", "--player=" + activePlayer, "play-pause"]
			playPauseProc.running = true
		}
	}
	function scrubVinyl(mx) {
		if (!vinylHeld) return
		var dx = mx - lastDragX
		lastDragX = mx
		totalDrag += dx
		vinylRotation = dragStartAngle + totalDrag * 0.8
		var newPos = Math.max(0, Math.min(length, dragStartPos + totalDrag * (length / 600)))
		position = newPos
		vinylSeekDebounce.restart()
	}
	function releaseVinyl() {
		if (!vinylHeld) return
		vinylSeekDebounce.stop()
		vinylHeld = false
		var finalPos = Math.max(0, Math.min(length, dragStartPos + totalDrag * (length / 600)))
		position = finalPos
		seekProc.command = ["playerctl", "--player=" + activePlayer, "position", Math.floor(finalPos).toString()]
		seekProc.running = true
		if (vinylWasPlaying) vinylResumeTimer.start()
	}
	Timer {
		id: vinylResumeTimer
		interval: 200
		onTriggered: {
			playPauseProc.command = ["playerctl", "--player=" + musicPanel.resolvedPlayer, "play-pause"]
			playPauseProc.running = true
		}
	}
	Timer {
		id: vinylSeekDebounce
		interval: 60
		onTriggered: {
			if (!vinylHeld || length <= 0) return
			var pos = Math.floor(Math.max(0, Math.min(length, dragStartPos + totalDrag * (length / 600))))
			seekProc.command = ["playerctl", "--player=" + musicPanel.resolvedPlayer, "position", pos.toString()]
			seekProc.running = true
		}
	}
	NumberAnimation {
		id: vinylSpinAnim
		target: musicPanel
		property: "vinylRotation"
		to: vinylRotation + 36000
		duration: 36000 * 120
		loops: Animation.Infinite
		easing.type: Easing.Linear
		function kickoff() {
			stop()
			from = vinylRotation
			to = vinylRotation + 36000
			start()
		}
	}
	function nextGif() {
		if (gifFiles.length > 0) previewGifIndex = (previewGifIndex + 1) % gifFiles.length
	}
	function prevGif() {
		if (gifFiles.length > 0) previewGifIndex = (previewGifIndex - 1 + gifFiles.length) % gifFiles.length
	}
	function applyGif() {
		if (isApplyingGif) return
		if (gifFiles.length > 0 && previewGifIndex < gifFiles.length) {
			isApplyingGif = true
			pendingGifIndex = previewGifIndex
			danceGifLoader.active = false
			setGifProc.selFile = gifFiles[previewGifIndex]
			setGifProc.running = true
		}
	}
	function loadGifs() {
		if (gifListProc.running) return
		musicPanel.gifFiles = []
		musicPanel.gifsLoaded = false
		musicPanel.previewGifIndex = 0
		gifListProc.running = true
	}
	function reloadMainGif() {
		musicPanel.gifReloadCounter++
		musicPanel.currentGifSource = "file://" + gifPath + "/current.gif?v=" + musicPanel.gifReloadCounter + "&t=" + Date.now()
		danceGifLoader.active = true
		musicPanel.isApplyingGif = false
		musicPanel.pendingGifIndex = -1
	}
	function saveGifIndex() {
		root.saveState("gif-index", currentGifIndex.toString())
		root.savedGifIndex = currentGifIndex
	}
	onGifSelectorOpenChanged: {
		if (!gifSelectorOpen) {
			previewGifIndex = currentGifIndex
			pickerTab = 0
		}
	}
	Timer {
		id: gifReloadTimer
		interval: 250
		repeat: false
		onTriggered: musicPanel.reloadMainGif()
	}
	Timer {
		id: playerRefreshTimer
		interval: 3000
		running: root.musicVisible
		repeat: true
		triggeredOnStart: true
		onTriggered: musicPanel.refreshPlayers()
	}
	Process {
		id: playerListProc
		command: ["bash", "-c", "playerctl --list-all 2>/dev/null | tr '\\n' '|' | sed 's/|$//'"]
		stdout: SplitParser {
			onRead: data => {
				var line = data.trim()
				if (line.length === 0) {
					musicPanel.availablePlayers = []
					return
				}
				var players = line.split("|").filter(function(p) { return p.length > 0 })
				musicPanel.availablePlayers = players
				if (musicPanel.activePlayer !== "%any") {
					var found = players.indexOf(musicPanel.activePlayer) >= 0
					if (!found) musicPanel.activePlayer = "%any"
				}
			}
		}
	}
	Item {
		anchors.fill: parent
		focus: root.musicVisible
		Keys.onPressed: function(event) {
			if (event.key === Qt.Key_Escape) {
				if (musicPanel.playerDropdownOpen) {
					musicPanel.playerDropdownOpen = false
				} else if (musicPanel.gifSelectorOpen) {
					musicPanel.gifSelectorOpen = false
				} else {
					root.musicVisible = false
				}
				event.accepted = true
			} else if (event.key === Qt.Key_Space && !musicPanel.gifSelectorOpen && !musicPanel.playerDropdownOpen) {
				if (!playPauseProc.running) playPauseProc.running = true
				event.accepted = true
			} else if (event.key === Qt.Key_N && !musicPanel.gifSelectorOpen && !musicPanel.playerDropdownOpen) {
				if (!nextProc.running) nextProc.running = true
				event.accepted = true
			} else if (event.key === Qt.Key_P && !musicPanel.gifSelectorOpen && !musicPanel.playerDropdownOpen) {
				if (!prevProc.running) prevProc.running = true
				event.accepted = true
			} else if (event.key === Qt.Key_Left && musicPanel.gifSelectorOpen && musicPanel.pickerTab === 0) {
				musicPanel.prevGif()
				event.accepted = true
			} else if (event.key === Qt.Key_Right && musicPanel.gifSelectorOpen && musicPanel.pickerTab === 0) {
				musicPanel.nextGif()
				event.accepted = true
			} else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && musicPanel.gifSelectorOpen && musicPanel.pickerTab === 0) {
				if (musicPanel.previewGifIndex !== musicPanel.currentGifIndex) musicPanel.applyGif()
				event.accepted = true
			}
		}
		Column {
			anchors.horizontalCenter: parent.horizontalCenter
			spacing: 8
			Rectangle {
				width: 400
				height: 180
				color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.95)
				radius: 15
				clip: true
				RowLayout {
					anchors.fill: parent
					anchors.margins: 15
					spacing: 15
					ColumnLayout {
						Layout.fillWidth: true
						Layout.fillHeight: true
						Layout.minimumWidth: 180
						spacing: 6
						RowLayout {
							Layout.fillWidth: true
							spacing: 6
							Text {
								text: musicPanel.trackTitle || "Nothing is playing"
								color: root.walColor5
								font.pixelSize: 15
								font.bold: true
								font.family: "JetBrainsMono Nerd Font"
								Layout.fillWidth: true
								elide: Text.ElideRight
							}
							Rectangle {
								width: playerBtnRow.width + 14
								height: 22
								radius: 7
								color: playerBtnMa.containsMouse || musicPanel.playerDropdownOpen
									? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.25)
									: Qt.rgba(0, 0, 0, 0.35)
								border.width: musicPanel.playerDropdownOpen ? 1 : 0
								border.color: Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.5)
								Behavior on color {
									ColorAnimation { duration: 150 }
								}
								Row {
									id: playerBtnRow
									anchors.centerIn: parent
									spacing: 5
									Text {
										text: musicPanel.playerIcon(musicPanel.activePlayer)
										color: root.walColor5
										font.pixelSize: 11
										font.family: "JetBrainsMono Nerd Font"
										anchors.verticalCenter: parent.verticalCenter
									}
									Text {
										text: musicPanel.playerDisplayName(musicPanel.activePlayer)
										color: root.walColor5
										font.pixelSize: 10
										font.family: "JetBrainsMono Nerd Font"
										anchors.verticalCenter: parent.verticalCenter
									}
									Text {
										text: musicPanel.playerDropdownOpen ? "󰅃" : "󰅀"
										color: root.walColor5
										font.pixelSize: 9
										font.family: "JetBrainsMono Nerd Font"
										anchors.verticalCenter: parent.verticalCenter
									}
								}
								MouseArea {
									id: playerBtnMa
									anchors.fill: parent
									hoverEnabled: true
									cursorShape: Qt.PointingHandCursor
									onClicked: {
										musicPanel.gifSelectorOpen = false
										musicPanel.playerDropdownOpen = !musicPanel.playerDropdownOpen
										if (musicPanel.playerDropdownOpen) musicPanel.refreshPlayers()
									}
								}
							}
						}
						Text {
							text: musicPanel.trackArtist || ""
							color: root.walForeground
							font.pixelSize: 12
							font.family: "JetBrainsMono Nerd Font"
							opacity: 0.7
							Layout.fillWidth: true
							elide: Text.ElideRight
							visible: musicPanel.trackArtist !== ""
						}
						Item { Layout.fillHeight: true }
						RowLayout {
							Layout.fillWidth: true
							spacing: 8
							visible: musicPanel.hasTrack

							Text {
								text: musicPanel.formatTime(musicPanel.position)
								color: root.walColor8
								font.pixelSize: 10
								font.family: "JetBrainsMono Nerd Font"
							}
							Rectangle {
								Layout.fillWidth: true
								height: 4
								radius: 2
								color: Qt.rgba(0, 0, 0, 0.5)
								Rectangle {
									width: musicPanel.length > 0 ? parent.width * (musicPanel.position / musicPanel.length) : 0
									height: parent.height
									radius: 2
									color: root.walColor5
								}
								MouseArea {
									anchors.fill: parent
									cursorShape: Qt.PointingHandCursor
									onClicked: function(mouse) {
										if (musicPanel.length > 0 && !seekProc.running) {
											var seekPos = (mouse.x / parent.width) * musicPanel.length
											seekProc.command = ["playerctl", "--player=" + musicPanel.resolvedPlayer, "position", seekPos.toString()]
											seekProc.running = true
										}
									}
								}
							}
							Text {
								text: musicPanel.formatTime(musicPanel.length)
								color: root.walColor8
								font.pixelSize: 10
								font.family: "JetBrainsMono Nerd Font"
							}
						}
						Row {
							Layout.alignment: Qt.AlignHCenter
							spacing: 12
							opacity: musicPanel.hasTrack ? 1.0 : 0.5
							Rectangle {
								width: 32
								height: 32
								radius: 8
								color: prevMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
								Text {
									anchors.centerIn: parent
									text: "󰒮"
									color: root.walForeground
									font.pixelSize: 16
									font.family: "JetBrainsMono Nerd Font"
								}
								MouseArea {
									id: prevMa
									anchors.fill: parent
									hoverEnabled: true
									cursorShape: Qt.PointingHandCursor
									onClicked: if (!prevProc.running) prevProc.running = true
								}
							}
							Rectangle {
								width: 40
								height: 40
								radius: 20
								color: root.walColor5
								Text {
									anchors.centerIn: parent
									text: musicPanel.playerStatus === "Playing" ? "󰏤" : "󰐊"
									color: root.walBackground
									font.pixelSize: 18
									font.family: "JetBrainsMono Nerd Font"
								}
								MouseArea {
									anchors.fill: parent
									cursorShape: Qt.PointingHandCursor
									onClicked: if (!playPauseProc.running) playPauseProc.running = true
								}
							}
							Rectangle {
								width: 32
								height: 32
								radius: 8
								color: nextMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
								Text {
									anchors.centerIn: parent
									text: "󰒭"
									color: root.walForeground
									font.pixelSize: 16
									font.family: "JetBrainsMono Nerd Font"
								}
								MouseArea {
									id: nextMa
									anchors.fill: parent
									hoverEnabled: true
									cursorShape: Qt.PointingHandCursor
									onClicked: if (!nextProc.running) nextProc.running = true
								}
							}
						}
					}
					Item {
						Layout.preferredWidth: 160
						Layout.maximumWidth: 160
						Layout.fillHeight: true
						Item {
							anchors.fill: parent
							visible: musicPanel.displayMode === 0
							Item {
								id: gifContainer
								anchors.bottom: parent.bottom
								anchors.horizontalCenter: parent.horizontalCenter
								width: 200
								height: 160
								Loader {
									id: danceGifLoader
									anchors.fill: parent
									active: true
									sourceComponent: AnimatedImage {
										anchors.centerIn: parent
										width: parent.width
										height: parent.height
										source: musicPanel.currentGifSource
										fillMode: Image.PreserveAspectFit
										smooth: true
										playing: musicPanel.playerStatus === "Playing"
										paused: musicPanel.playerStatus !== "Playing"
										cache: false
										asynchronous: true
									}
								}
							}
						}
						Item {
							anchors.fill: parent
							visible: musicPanel.displayMode === 1
							Item {
								id: vinylDisc
								anchors.centerIn: parent
								width: Math.min(parent.width, parent.height) - 4
								height: width
								rotation: musicPanel.vinylRotation
								Rectangle {
									anchors.centerIn: parent
									width: parent.width
									height: parent.width
									radius: width / 2
									color: "#0d0d0d"
								}
								Repeater {
									model: 8
									Rectangle {
										anchors.centerIn: parent
										width: parent.width * (0.97 - index * 0.016)
										height: width
										radius: width / 2
										color: "transparent"
										border.width: index % 2 === 0 ? 1 : 0.5
										border.color: index % 2 === 0 ? Qt.rgba(1,1,1,0.055) : Qt.rgba(1,1,1,0.022)
									}
								}
								Item {
									anchors.centerIn: parent
									width: parent.width * 0.75
									height: width
									Image {
										id: vinylArtImage
										anchors.fill: parent
										source: musicPanel.vinylWithArt && musicPanel.trackArtUrl !== ""
											? musicPanel.trackArtUrl
											: musicPanel.vinylAsset
										fillMode: Image.PreserveAspectCrop
										smooth: true
										asynchronous: true
										sourceSize: Qt.size(300, 300)
										visible: false
									}
									Rectangle {
										id: vinylArtMask
										anchors.fill: parent
										radius: width / 2
										visible: false
									}
									OpacityMask {
										anchors.fill: vinylArtImage
										source: vinylArtImage
										maskSource: vinylArtMask
									}
									Rectangle {
										anchors.fill: parent
										radius: width / 2
										color: "transparent"
										border.width: 1
										border.color: Qt.rgba(1,1,1,0.07)
									}
								}
								Rectangle {
									anchors.centerIn: parent
									width: parent.width * 0.08
									height: width
									radius: width / 2
									color: "#1e1e1e"
									border.width: 1
									border.color: Qt.rgba(1,1,1,0.1)
								}
								Rectangle {
									anchors.centerIn: parent
									width: 4
									height: 4
									radius: 2
									color: root.walColor5
									opacity: 0.9
								}
							}
							MouseArea {
								anchors.centerIn: parent
								width: Math.min(parent.width, parent.height) - 4
								height: width
								hoverEnabled: true
								cursorShape: musicPanel.vinylHeld ? Qt.ClosedHandCursor : Qt.OpenHandCursor
								onPressed: musicPanel.grabVinyl(mouseX)
								onReleased: musicPanel.releaseVinyl()
								onCanceled: musicPanel.releaseVinyl()
								onPositionChanged: musicPanel.scrubVinyl(mouseX)
							}
						}
						Rectangle {
							anchors.top: parent.top
							anchors.right: parent.right
							anchors.topMargin: 5
							anchors.rightMargin: 5
							width: 24
							height: 24
							radius: 12
							color: gifEditMa.containsMouse ? Qt.rgba(1,1,1,0.2) : Qt.rgba(0,0,0,0.3)
							Behavior on color {
								ColorAnimation { duration: 150 }
							}
							Text {
								anchors.centerIn: parent
								text: "󰏫"
								color: root.walForeground
								font.pixelSize: 12
								font.family: "JetBrainsMono Nerd Font"
							}
							MouseArea {
								id: gifEditMa
								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								onClicked: {
									musicPanel.playerDropdownOpen = false
									if (!musicPanel.gifSelectorOpen) {
										musicPanel.loadGifs()
										musicPanel.gifSelectorOpen = true
										musicPanel.pickerTab = musicPanel.displayMode
									} else {
										musicPanel.gifSelectorOpen = false
									}
								}
							}
						}
					}
				}
				Connections {
					target: musicPanel
					function onPlayerStatusChanged() {
						if (musicPanel.playerStatus === "Playing" && musicPanel.displayMode === 1 && root.musicVisible && !musicPanel.vinylHeld)
							vinylSpinAnim.kickoff()
						else if (musicPanel.playerStatus !== "Playing")
							vinylSpinAnim.stop()
					}
					function onDisplayModeChanged() {
						if (musicPanel.displayMode === 1 && musicPanel.playerStatus === "Playing" && root.musicVisible && !musicPanel.vinylHeld)
							vinylSpinAnim.kickoff()
						else if (musicPanel.displayMode !== 1)
							vinylSpinAnim.stop()
					}
				}
				Rectangle {
					id: playerDropdownCard
					width: 380
					anchors.horizontalCenter: parent.horizontalCenter
					height: visible ? (28 + 1 + 34 + (musicPanel.availablePlayers.length * 34) + 16) : 0
					radius: 12
					color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.92)
					border.color: Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.25)
					border.width: 1
					visible: musicPanel.playerDropdownOpen && !musicPanel.gifSelectorOpen
					clip: true
					Item {
						id: pdHeader
						anchors.top: parent.top
						anchors.left: parent.left
						anchors.right: parent.right
						anchors.margins: 8
						height: 28
						Text {
							anchors.left: parent.left
							anchors.verticalCenter: parent.verticalCenter
							anchors.leftMargin: 6
							text: "󰝚  Select Player"
							color: root.walColor5
							font.pixelSize: 11
							font.bold: true
							font.family: "JetBrainsMono Nerd Font"
						}
						Text {
							anchors.right: parent.right
							anchors.verticalCenter: parent.verticalCenter
							anchors.rightMargin: 6
							text: musicPanel.availablePlayers.length === 0 ? "No players" : musicPanel.availablePlayers.length + " found"
							color: root.walColor8
							font.pixelSize: 9
							font.family: "JetBrainsMono Nerd Font"
							opacity: 0.6
						}
					}
					Rectangle {
						id: pdDivider
						anchors.top: pdHeader.bottom
						anchors.left: parent.left
						anchors.right: parent.right
						anchors.leftMargin: 8
						anchors.rightMargin: 8
						height: 1
						color: Qt.rgba(1,1,1,0.06)
					}
					Column {
						id: pdRows
						anchors.top: pdDivider.bottom
						anchors.left: parent.left
						anchors.right: parent.right
						anchors.leftMargin: 8
						anchors.rightMargin: 8
						anchors.topMargin: 2
						spacing: 2
						Rectangle {
							width: parent.width
							height: 34
							radius: 8
							color: musicPanel.activePlayer === "%any"
								? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.18)
								: autoMa.containsMouse ? Qt.rgba(1,1,1,0.07) : "transparent"
							Behavior on color {
								ColorAnimation { duration: 120 }
							}
							Row {
								anchors.fill: parent
								anchors.leftMargin: 10
								anchors.rightMargin: 10
								spacing: 8
								Text {
									anchors.verticalCenter: parent.verticalCenter
									text: "󰝚"
									color: musicPanel.activePlayer === "%any" ? root.walColor5 : root.walColor8
									font.pixelSize: 14
									font.family: "JetBrainsMono Nerd Font"
								}
								Text {
									anchors.verticalCenter: parent.verticalCenter
									text: "Auto"
									color: musicPanel.activePlayer === "%any" ? root.walColor5 : root.walForeground
									font.pixelSize: 12
									font.bold: musicPanel.activePlayer === "%any"
									font.family: "JetBrainsMono Nerd Font"
									width: 120
								}
								Text {
									anchors.verticalCenter: parent.verticalCenter
									text: "any active"
									color: root.walColor8
									font.pixelSize: 9
									font.family: "JetBrainsMono Nerd Font"
									opacity: 0.5
								}
								Text {
									anchors.verticalCenter: parent.verticalCenter
									visible: musicPanel.activePlayer === "%any"
									text: "󰄬"
									color: root.walColor5
									font.pixelSize: 12
									font.family: "JetBrainsMono Nerd Font"
								}
							}
							MouseArea {
								id: autoMa
								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								onClicked: {
									musicPanel.activePlayer = "%any"
									musicPanel.playerDropdownOpen = false
									if (!musicStatusProc.running) musicStatusProc.running = true
								}
							}
						}
						Repeater {
							model: musicPanel.availablePlayers
							Rectangle {
								width: pdRows.width
								height: 34
								radius: 8
								color: musicPanel.activePlayer === modelData
									? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.18)
									: playerItemMa.containsMouse ? Qt.rgba(1,1,1,0.07) : "transparent"
								Behavior on color {
									ColorAnimation { duration: 120 }
								}
								Row {
									anchors.fill: parent
									anchors.leftMargin: 10
									anchors.rightMargin: 10
									spacing: 8
									Text {
										anchors.verticalCenter: parent.verticalCenter
										text: musicPanel.playerIcon(modelData)
										color: musicPanel.activePlayer === modelData ? root.walColor5 : root.walColor8
										font.pixelSize: 14
										font.family: "JetBrainsMono Nerd Font"
									}
									Text {
										anchors.verticalCenter: parent.verticalCenter
										text: musicPanel.playerDisplayName(modelData)
										color: musicPanel.activePlayer === modelData ? root.walColor5 : root.walForeground
										font.pixelSize: 12
										font.bold: musicPanel.activePlayer === modelData
										font.family: "JetBrainsMono Nerd Font"
										width: 200
										elide: Text.ElideRight
									}
									Text {
										anchors.verticalCenter: parent.verticalCenter
										visible: musicPanel.activePlayer === modelData
										text: "󰄬"
										color: root.walColor5
										font.pixelSize: 12
										font.family: "JetBrainsMono Nerd Font"
									}
								}
								MouseArea {
									id: playerItemMa
									anchors.fill: parent
									hoverEnabled: true
									cursorShape: Qt.PointingHandCursor
									onClicked: {
										musicPanel.activePlayer = modelData
										musicPanel.playerDropdownOpen = false
										if (!musicStatusProc.running) musicStatusProc.running = true
									}
								}
							}
						}
					}
				}
			}
			Rectangle {
				id: dropdownCard
				width: 380
				height: 260
				anchors.horizontalCenter: parent.horizontalCenter
				radius: 14
				color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.85)
				border.color: Qt.rgba(1,1,1,0.1)
				border.width: 1
				visible: musicPanel.gifSelectorOpen
				clip: true
				ColumnLayout {
					anchors.fill: parent
					anchors.margins: 14
					spacing: 10
					RowLayout {
						Layout.fillWidth: true
						Layout.preferredHeight: 20
						Text {
							text: musicPanel.pickerTab === 0 ? "Select Animation" : "Vinyl Display"
							color: root.walColor5
							font.pixelSize: 12
							font.bold: true
							font.family: "JetBrainsMono Nerd Font"
							Layout.fillWidth: true
						}
						Text {
							visible: musicPanel.pickerTab === 0 && musicPanel.gifFiles.length > 0
							text: (musicPanel.previewGifIndex + 1) + " / " + musicPanel.gifFiles.length
							color: root.walColor8
							font.pixelSize: 10
							font.family: "JetBrainsMono Nerd Font"
							opacity: 0.6
						}
						Item { width: 6 }
						Rectangle {
							width: 20
							height: 20
							radius: 10
							color: dropCloseMa.containsMouse
								? Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.5)
								: Qt.rgba(1,1,1,0.08)
							Behavior on color {
								ColorAnimation { duration: 150 }
							}
							Text {
								anchors.centerIn: parent
								text: "󰅖"
								color: dropCloseMa.containsMouse ? root.walColor1 : root.walForeground
								font.pixelSize: 10
								font.family: "JetBrainsMono Nerd Font"
								Behavior on color {
									ColorAnimation { duration: 150 }
								}
							}
							MouseArea {
								id: dropCloseMa
								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								onClicked: musicPanel.gifSelectorOpen = false
							}
						}
					}
					Row {
						spacing: 6
						Rectangle {
							width: gifTabText.implicitWidth + 20
							height: 26
							radius: 8
							color: musicPanel.pickerTab === 0
								? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.2)
								: gifTabMa.containsMouse ? Qt.rgba(1,1,1,0.06) : Qt.rgba(1,1,1,0.03)
							border.width: musicPanel.pickerTab === 0 ? 1 : 0
							border.color: Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.4)
							Behavior on color {
								ColorAnimation { duration: 120 }
							}
							Text {
								id: gifTabText
								anchors.centerIn: parent
								text: "GIF"
								color: musicPanel.pickerTab === 0
									? root.walColor5
									: Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.35)
								font.pixelSize: 9
								font.family: "JetBrainsMono Nerd Font"
								font.bold: true
								font.letterSpacing: 0.8
								Behavior on color {
									ColorAnimation { duration: 120 }
								}
							}
							MouseArea {
								id: gifTabMa
								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								onClicked: musicPanel.pickerTab = 0
							}
						}
						Rectangle {
							width: vinylTabText.implicitWidth + 20
							height: 26
							radius: 8
							color: musicPanel.pickerTab === 1
								? Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.2)
								: vinylTabMa.containsMouse ? Qt.rgba(1,1,1,0.06) : Qt.rgba(1,1,1,0.03)
							border.width: musicPanel.pickerTab === 1 ? 1 : 0
							border.color: Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.4)
							Behavior on color {
								ColorAnimation { duration: 120 }
							}
							Text {
								id: vinylTabText
								anchors.centerIn: parent
								text: "VINYL"
								color: musicPanel.pickerTab === 1
									? root.walColor13
									: Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.35)
								font.pixelSize: 9
								font.family: "JetBrainsMono Nerd Font"
								font.bold: true
								font.letterSpacing: 0.8
								Behavior on color {
									ColorAnimation { duration: 120 }
								}
							}
							MouseArea {
								id: vinylTabMa
								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								onClicked: musicPanel.pickerTab = 1
							}
						}
					}
					Item {
						Layout.fillWidth: true
						Layout.fillHeight: true
						Rectangle {
							anchors.fill: parent
							radius: 12
							color: Qt.rgba(0,0,0,0.2)
							border.color: Qt.rgba(1,1,1,0.08)
							border.width: 1
							clip: true
							visible: musicPanel.pickerTab === 0
							Loader {
								id: previewGifLoader
								anchors.fill: parent
								anchors.margins: 8
								active: musicPanel.gifSelectorOpen && musicPanel.gifsLoaded && musicPanel.gifFiles.length > 0 && musicPanel.pickerTab === 0
								sourceComponent: AnimatedImage {
									anchors.centerIn: parent
									width: parent.width
									height: parent.height
									source: (musicPanel.gifFiles.length > 0 && musicPanel.previewGifIndex < musicPanel.gifFiles.length)
										? "file://" + musicPanel.gifFiles[musicPanel.previewGifIndex]
										: ""
									fillMode: Image.PreserveAspectFit
									smooth: true
									playing: musicPanel.gifSelectorOpen
									cache: false
									asynchronous: true
								}
							}
							Text {
								anchors.centerIn: parent
								visible: musicPanel.gifFiles.length === 0 && musicPanel.gifsLoaded
								text: "No gifs found"
								color: root.walColor8
								font.pixelSize: 11
								font.family: "JetBrainsMono Nerd Font"
								opacity: 0.5
							}
							Text {
								anchors.centerIn: parent
								visible: !musicPanel.gifsLoaded && musicPanel.gifSelectorOpen
								text: "Loading..."
								color: root.walColor8
								font.pixelSize: 11
								font.family: "JetBrainsMono Nerd Font"
								opacity: 0.5
							}
							Rectangle {
								anchors.bottom: parent.bottom
								anchors.horizontalCenter: parent.horizontalCenter
								anchors.bottomMargin: 6
								visible: musicPanel.gifFiles.length > 0 && musicPanel.gifsLoaded
								width: gifNameLabel2.implicitWidth + 12
								height: 18
								radius: 9
								color: Qt.rgba(0,0,0,0.6)
								Text {
									id: gifNameLabel2
									anchors.centerIn: parent
									text: musicPanel.gifFiles.length > 0 ? musicPanel.gifFileName(musicPanel.gifFiles[musicPanel.previewGifIndex]) : ""
									color: root.walForeground
									font.pixelSize: 9
									font.family: "JetBrainsMono Nerd Font"
									opacity: 0.9
								}
							}
						}
						Item {
							anchors.fill: parent
							visible: musicPanel.pickerTab === 1
							Item {
								anchors.centerIn: parent
								width: Math.min(parent.width, parent.height) - 16
								height: width
								Rectangle {
									anchors.centerIn: parent
									width: parent.width
									height: parent.width
									radius: width / 2
									color: "#0d0d0d"
									rotation: musicPanel.vinylRotation
									Repeater {
										model: 8
										Rectangle {
											anchors.centerIn: parent
											width: parent.width * (0.97 - index * 0.016)
											height: width
											radius: width / 2
											color: "transparent"
											border.width: index % 2 === 0 ? 1 : 0.5
											border.color: index % 2 === 0 ? Qt.rgba(1,1,1,0.055) : Qt.rgba(1,1,1,0.022)
										}
									}
									Item {
										anchors.centerIn: parent
										width: parent.width * 0.75
										height: width
										Image {
											id: vinylPickerArt
											anchors.fill: parent
											source: musicPanel.vinylWithArt && musicPanel.trackArtUrl !== ""
												? musicPanel.trackArtUrl
												: musicPanel.vinylAsset
											fillMode: Image.PreserveAspectCrop
											smooth: true
											asynchronous: true
											sourceSize: Qt.size(200, 200)
											visible: false
										}
										Rectangle {
											id: vinylPickerMask
											anchors.fill: parent
											radius: width / 2
											visible: false
										}
										OpacityMask {
											anchors.fill: vinylPickerArt
											source: vinylPickerArt
											maskSource: vinylPickerMask
										}
										Rectangle {
											anchors.fill: parent
											radius: width / 2
											color: "transparent"
											border.width: 1
											border.color: Qt.rgba(1,1,1,0.07)
										}
									}
									Rectangle {
										anchors.centerIn: parent
										width: parent.width * 0.08
										height: width
										radius: width / 2
										color: "#1e1e1e"
										border.width: 1
										border.color: Qt.rgba(1,1,1,0.1)
									}
									Rectangle {
										anchors.centerIn: parent
										width: 4
										height: 4
										radius: 2
										color: root.walColor13
										opacity: 0.9
									}
								}
							}
							Row {
								anchors.bottom: parent.bottom
								anchors.horizontalCenter: parent.horizontalCenter
								anchors.bottomMargin: 6
								spacing: 8
								Rectangle {
									width: withArtLabel.implicitWidth + 16
									height: 24
									radius: 8
									color: musicPanel.vinylWithArt
										? Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.18)
										: withArtMa.containsMouse ? Qt.rgba(1,1,1,0.06) : Qt.rgba(1,1,1,0.03)
									border.width: musicPanel.vinylWithArt ? 1 : 0
									border.color: Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.4)
									Behavior on color {
										ColorAnimation { duration: 120 }
									}
									Text {
										id: withArtLabel
										anchors.centerIn: parent
										text: "With Art"
										color: musicPanel.vinylWithArt
											? root.walColor13
											: Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.35)
										font.pixelSize: 9
										font.family: "JetBrainsMono Nerd Font"
										Behavior on color {
											ColorAnimation { duration: 120 }
										}
									}
									MouseArea {
										id: withArtMa
										anchors.fill: parent
										hoverEnabled: true
										cursorShape: Qt.PointingHandCursor
										onClicked: musicPanel.vinylWithArt = true
									}
								}
								Rectangle {
									width: noArtLabel.implicitWidth + 16
									height: 24
									radius: 8
									color: !musicPanel.vinylWithArt
										? Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.18)
										: noArtMa.containsMouse ? Qt.rgba(1,1,1,0.06) : Qt.rgba(1,1,1,0.03)
									border.width: !musicPanel.vinylWithArt ? 1 : 0
									border.color: Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.4)
									Behavior on color {
										ColorAnimation { duration: 120 }
									}
									Text {
										id: noArtLabel
										anchors.centerIn: parent
										text: "No Art"
										color: !musicPanel.vinylWithArt
											? root.walColor13
											: Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.35)
										font.pixelSize: 9
										font.family: "JetBrainsMono Nerd Font"
										Behavior on color {
											ColorAnimation { duration: 120 }
										}
									}
									MouseArea {
										id: noArtMa
										anchors.fill: parent
										hoverEnabled: true
										cursorShape: Qt.PointingHandCursor
										onClicked: musicPanel.vinylWithArt = false
									}
								}
							}
						}
					}
					RowLayout {
						Layout.fillWidth: true
						Layout.preferredHeight: 32
						spacing: 8
						visible: musicPanel.pickerTab === 0
						Rectangle {
							Layout.preferredWidth: 36
							Layout.preferredHeight: 32
							radius: 8
							color: prevGifMa.containsMouse
								? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.25)
								: Qt.rgba(1,1,1,0.08)
							border.color: prevGifMa.containsMouse
								? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.4)
								: Qt.rgba(1,1,1,0.05)
							border.width: 1
							opacity: musicPanel.gifFiles.length > 1 ? 1.0 : 0.3
							Behavior on color { ColorAnimation { duration: 150 } }
							Behavior on border.color { ColorAnimation { duration: 150 } }
							Text {
								anchors.centerIn: parent
								text: "󰅁"
								color: prevGifMa.containsMouse ? root.walColor5 : root.walForeground
								font.pixelSize: 16
								font.family: "JetBrainsMono Nerd Font"
								Behavior on color { ColorAnimation { duration: 150 } }
							}
							MouseArea {
								id: prevGifMa
								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								enabled: musicPanel.gifFiles.length > 1 && !musicPanel.isApplyingGif
								onClicked: musicPanel.prevGif()
							}
						}
						Rectangle {
							Layout.preferredWidth: 36
							Layout.preferredHeight: 32
							radius: 8
							color: nextGifMa.containsMouse
								? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.25)
								: Qt.rgba(1,1,1,0.08)
							border.color: nextGifMa.containsMouse
								? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.4)
								: Qt.rgba(1,1,1,0.05)
							border.width: 1
							opacity: musicPanel.gifFiles.length > 1 ? 1.0 : 0.3
							Behavior on color { ColorAnimation { duration: 150 } }
							Behavior on border.color { ColorAnimation { duration: 150 } }
							Text {
								anchors.centerIn: parent
								text: "󰅂"
								color: nextGifMa.containsMouse ? root.walColor5 : root.walForeground
								font.pixelSize: 16
								font.family: "JetBrainsMono Nerd Font"
								Behavior on color { ColorAnimation { duration: 150 } }
							}
							MouseArea {
								id: nextGifMa
								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								enabled: musicPanel.gifFiles.length > 1 && !musicPanel.isApplyingGif
								onClicked: musicPanel.nextGif()
							}
						}
						Item { Layout.fillWidth: true }
						Rectangle {
							Layout.preferredWidth: 85
							Layout.preferredHeight: 32
							radius: 8
							color: {
								if (musicPanel.isApplyingGif) return Qt.rgba(1,1,1,0.03)
								if (musicPanel.previewGifIndex === musicPanel.currentGifIndex) return Qt.rgba(1,1,1,0.05)
								return applyGifMa.pressed
									? root.walColor5
									: applyGifMa.containsMouse
										? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.35)
										: Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.18)
							}
							border.color: {
								if (musicPanel.isApplyingGif) return Qt.rgba(1,1,1,0.05)
								if (musicPanel.previewGifIndex === musicPanel.currentGifIndex) return Qt.rgba(1,1,1,0.08)
								return applyGifMa.containsMouse ? root.walColor5 : Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.4)
							}
							border.width: 1
							Behavior on color { ColorAnimation { duration: 150 } }
							Behavior on border.color { ColorAnimation { duration: 150 } }
							Text {
								anchors.centerIn: parent
								text: {
									if (musicPanel.isApplyingGif) return "Applying..."
									if (musicPanel.previewGifIndex === musicPanel.currentGifIndex) return "󰄬 Current"
									return "󰸞 Apply"
								}
								color: {
									if (musicPanel.isApplyingGif) return Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.4)
									if (musicPanel.previewGifIndex === musicPanel.currentGifIndex) return Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.3)
									return applyGifMa.pressed ? root.walBackground : root.walColor5
								}
								font.pixelSize: 11
								font.bold: true
								font.family: "JetBrainsMono Nerd Font"
								Behavior on color { ColorAnimation { duration: 150 } }
							}
							MouseArea {
								id: applyGifMa
								anchors.fill: parent
								hoverEnabled: true
								cursorShape: (musicPanel.previewGifIndex !== musicPanel.currentGifIndex && !musicPanel.isApplyingGif)
									? Qt.PointingHandCursor : Qt.ArrowCursor
								enabled: musicPanel.previewGifIndex !== musicPanel.currentGifIndex && !musicPanel.isApplyingGif
								onClicked: musicPanel.applyGif()
							}
						}
					}
					RowLayout {
						Layout.fillWidth: true
						Layout.preferredHeight: 32
						visible: musicPanel.pickerTab === 1

						Item { Layout.fillWidth: true }

						Rectangle {
							width: vinylApplyLabel.implicitWidth + 18
							height: 32
							radius: 8
							color: vinylApplyMa.containsMouse
								? Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.25)
								: Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.12)
							border.width: 1
							border.color: Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, vinylApplyMa.containsMouse ? 0.5 : 0.3)
							Behavior on color { ColorAnimation { duration: 150 } }
							Text {
								id: vinylApplyLabel
								anchors.centerIn: parent
								text: "󰸞 Apply"
								color: root.walColor13
								font.pixelSize: 11
								font.bold: true
								font.family: "JetBrainsMono Nerd Font"
							}
							MouseArea {
								id: vinylApplyMa
								anchors.fill: parent
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								onClicked: {
									musicPanel.displayMode = 1
									musicPanel.gifSelectorOpen = false
									if (musicPanel.playerStatus === "Playing" && !musicPanel.vinylHeld)
										vinylSpinAnim.kickoff()
								}
							}
						}
					}
					Rectangle {
						Layout.fillWidth: true
						height: 22
						radius: 6
						color: Qt.rgba(0,0,0,0.2)
						RowLayout {
							anchors.fill: parent
							anchors.leftMargin: 10
							anchors.rightMargin: 10
							Text {
								text: musicPanel.pickerTab === 0 ? "←→ nav" : "toggle art"
								color: root.walColor8
								font.pixelSize: 9
								font.family: "JetBrainsMono Nerd Font"
								opacity: 0.6
							}
							Item { Layout.fillWidth: true }
							Text {
								text: musicPanel.pickerTab === 0 ? "↵ apply" : ""
								color: root.walColor8
								font.pixelSize: 9
								font.family: "JetBrainsMono Nerd Font"
								opacity: 0.6
							}
							Item { Layout.fillWidth: true }
							Text {
								text: "esc close"
								color: root.walColor8
								font.pixelSize: 9
								font.family: "JetBrainsMono Nerd Font"
								opacity: 0.6
							}
						}
					}
				}
			}
		}
		Connections {
			target: root
			function onMusicVisibleChanged() {
				if (root.musicVisible) {
					if (musicPanel.displayMode === 1 && musicPanel.playerStatus === "Playing" && !musicPanel.vinylHeld)
						vinylSpinAnim.kickoff()
				} else {
					musicPanel.playerDropdownOpen = false
					musicPanel.gifSelectorOpen = false
					vinylSpinAnim.stop()
				}
			}
		}
		Process {
			id: gifListProc
			command: ["sh", "-c", "find '" + musicPanel.gifPath + "' -maxdepth 1 -name '*.gif' ! -name 'current.gif' -type f 2>/dev/null | sort"]
			stdout: SplitParser {
				onRead: data => {
					var file = data.trim()
					if (file.length > 0) {
						var current = musicPanel.gifFiles.slice()
						current.push(file)
						musicPanel.gifFiles = current
					}
				}
			}
			onExited: {
				musicPanel.gifsLoaded = true
				if (musicPanel.gifFiles.length > 0)
					musicPanel.previewGifIndex = Math.min(musicPanel.currentGifIndex, musicPanel.gifFiles.length - 1)
			}
		}
		Process {
			id: setGifProc
			property string selFile: ""
			command: ["cp", selFile, musicPanel.gifPath + "/current.gif"]
			onExited: code => {
				if (code === 0 && musicPanel.pendingGifIndex >= 0) {
					musicPanel.currentGifIndex = musicPanel.pendingGifIndex
					musicPanel.displayMode = 0
					musicPanel.gifSelectorOpen = false
					musicPanel.saveGifIndex()
					gifReloadTimer.start()
				} else {
					musicPanel.isApplyingGif = false
					musicPanel.pendingGifIndex = -1
					danceGifLoader.active = true
				}
			}
		}
		Timer {
			id: playerPollTimer
			interval: 1000
			running: root.musicVisible && !musicPanel.gifSelectorOpen
			repeat: true
			triggeredOnStart: true
			onTriggered: { if (!musicStatusProc.running) musicStatusProc.running = true }
		}
		Timer {
			interval: 1000
			running: musicPanel.playerStatus === "Playing" && !musicPanel.vinylHeld
			repeat: true
			onTriggered: {
				if (musicPanel.position < musicPanel.length)
					musicPanel.position += 1
			}
		}
	Process {
	    id: musicStatusProc
	    command: [musicPanel.configPath + "/assets/get-player.sh", musicPanel.activePlayer]
	    stdout: SplitParser {
	        splitMarker: ""
	        onRead: data => {
	            var lines = data.split("\n")
	            for (var i = 0; i < lines.length; i++) {
	                var line = lines[i].trim()
	                var idx = line.indexOf(":")
	                if (idx < 0) continue
	                var key = line.substring(0, idx)
	                var val = line.substring(idx + 1)
	                switch (key) {
	                    case "player": musicPanel.resolvedPlayer = val; break
	                    case "status": musicPanel.playerStatus = val || "Stopped"; break
	                    case "title":  musicPanel.trackTitle  = val; break
	                    case "artist": musicPanel.trackArtist = val; break
	                    case "arturl": musicPanel.trackArtUrl = val; break
	                    case "pos":    musicPanel.position    = parseFloat(val) || 0; break
	                    case "len":    musicPanel.length      = parseFloat(val) || 0; break
	                }
	            }
	        }
	    }
	    onExited: code => {
	        if (code !== 0) {
	            musicPanel.playerStatus = "Stopped"
	            musicPanel.trackTitle   = ""
	            musicPanel.trackArtist  = ""
	            musicPanel.trackArtUrl  = ""
	        }
	    }
	}
		Process {
			id: playPauseProc
			command: ["playerctl", "--player=" + musicPanel.resolvedPlayer, "play-pause"]
			onExited: { if (!musicStatusProc.running) musicStatusProc.running = true }
		}
		Process {
			id: nextProc
			command: ["playerctl", "--player=" + musicPanel.resolvedPlayer, "next"]
			onExited: { if (!musicStatusProc.running) musicStatusProc.running = true }
		}
		Process {
			id: prevProc
			command: ["playerctl", "--player=" + musicPanel.resolvedPlayer, "previous"]
			onExited: { if (!musicStatusProc.running) musicStatusProc.running = true }
		}
		Process {
			id: seekProc
			command: ["playerctl", "--player=" + musicPanel.resolvedPlayer, "position", "0"]
		}
	}
}
