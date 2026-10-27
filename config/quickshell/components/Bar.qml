import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Services.SystemTray

PanelWindow {
	id: bar
	visible: true
    	WlrLayershell.layer: WlrLayer.Top
    	WlrLayershell.namespace: "quickshell"
	// ── v13: any edge, auto-hide ──
	readonly property string barPosition: root.barPosition
	readonly property bool vertical: root.barVertical
	readonly property int thickness: root.barThickness
	readonly property real hideOffset: root.barShown ? 0 : -(thickness + 6)
	// shrink both ends a little if they'd overlap (long titles on a side bar)
	readonly property real sectionScale: vertical
		? Math.min(1, (height - 20) / Math.max(1, bar.vertNeed))
		: Math.min(1, (width - 20) / Math.max(1, leftSection.width + rightSection.width + 12))
	exclusionMode: root.barMode === "shown" && !root.pomoZen ? ExclusionMode.Auto : ExclusionMode.Ignore
	anchors {
		top: bar.barPosition !== "bottom"
		bottom: bar.barPosition !== "top"
		left: bar.barPosition !== "right"
		right: bar.barPosition !== "left"
	}
	margins {
		top: bar.barPosition === "top" ? bar.hideOffset : 0
		bottom: bar.barPosition === "bottom" ? bar.hideOffset : 0
		left: bar.barPosition === "left" ? bar.hideOffset : 0
		right: bar.barPosition === "right" ? bar.hideOffset : 0
	}
	Behavior on margins.top { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
	Behavior on margins.bottom { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
	Behavior on margins.left { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
	Behavior on margins.right { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
	implicitHeight: bar.thickness
	implicitWidth: bar.thickness
	property date nowTime: new Date()
	Timer { interval: 1000; running: bar.vertical; repeat: true; triggeredOnStart: true; onTriggered: bar.nowTime = new Date() }
	// side bar: shrink both ends + media only if they'd overlap
	readonly property bool enjoy: root.barStyle === "enjoy"   // Enjoy = Default look minus the work stuff
	readonly property string style: enjoy ? "default" : root.barStyle
	readonly property int secGap: style === "islands" ? 6 : style === "i3" ? 1 : style === "minimal" ? 2 : 4   // space between components
	readonly property int pad: style === "i3" ? 10 : style === "minimal" ? 8 : 12    // padding inside a component
	readonly property int iconW: style === "default" || style === "islands" ? 28 : 24                        // icon-only components
	readonly property real vertNeed: leftSection.height + rightSection.height + (bar.mediaText !== "" ? mediaNotch.height + 2 * secGap + 6 : 0) + 16
	// side bar: media goes in the free space between both ends, never on top of them
	readonly property real mediaLo: leftSection.y + leftSection.height * sectionScale + secGap + 3
	readonly property real mediaHi: rightSection.y + rightSection.height * (1 - sectionScale) - secGap - 3
	readonly property real mediaVis: mediaNotch.height * sectionScale
	readonly property real mediaY: Math.max(mediaLo, Math.min(mediaHi - mediaVis, (height - mediaVis) / 2))
	readonly property bool mediaFits: !vertical || mediaHi - mediaLo >= mediaVis
    	color: "transparent"   // qs-update v33: window stays transparent; colour drawn below
	Rectangle {
		anchors.fill: parent
		anchors.topMargin: bar.floatGap
		anchors.bottomMargin: bar.floatGap
		anchors.leftMargin: bar.floatSide
		anchors.rightMargin: bar.floatSide
		radius: 0
		border.width: root.barFloating ? 1 : 0
		border.color: Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, root.lightMode ? 0.12 : 0.07)
		z: -1
		color: root.barBg
	}
	Rectangle {
		// faint accent line on the edge that faces the windows (default style)
		z: 5
		visible: bar.style === "default" && !root.barFloating
		readonly property color c: root.walColor13
		color: Qt.rgba(c.r, c.g, c.b, root.lightMode ? 0.40 : 0.28)
		width: bar.vertical ? 1 : bar.width
		height: bar.vertical ? bar.height : 1
		x: bar.barPosition === "left" ? bar.width - 1 : 0
		y: bar.barPosition === "top" ? bar.height - 1 : 0
	}
Item {
		id: barCavaBackdrop
		anchors.centerIn: parent
		width: bar.vertical ? parent.height : parent.width
		height: bar.vertical ? parent.width : parent.height
		rotation: bar.barPosition === "left" ? 90 : bar.barPosition === "right" ? -90 : bar.barPosition === "top" ? 180 : 0
		opacity: bar.bgActive && bar.style === "default" && !root.barFloating ? 1 : 0
		visible: opacity > 0
		Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
		Row {
			id: barCavaRow
			anchors.fill: parent
			anchors.leftMargin: 2
			anchors.rightMargin: 2
			spacing: 2
			Repeater {
				model: bar.bgBarCount * 2
				delegate: Rectangle {
					required property int index
					// mirrored: bass in the middle, treble towards both edges
					readonly property int src: index < bar.bgBarCount ? bar.bgBarCount - 1 - index : index - bar.bgBarCount
					readonly property real level: bar.bgVals[src] || 0
					width: (barCavaRow.width - (bar.bgBarCount * 2 - 1) * barCavaRow.spacing) / (bar.bgBarCount * 2)
					height: Math.max(2, level * barCavaRow.height)
					anchors.bottom: parent.bottom
					radius: Math.min(width / 2, 3)
					color: bar.bgColors[src] || root.walColor5
					opacity: 0.22 + level * 0.33
					antialiasing: true
					Behavior on height { NumberAnimation { duration: 70; easing.type: Easing.OutQuad } }
					Behavior on color { ColorAnimation { duration: 700 } }
				}
			}
		}
	}
    	property color notchColor: root.card(0.88)
    	property color notchHoverColor: root.card(0.90)
    	property int notchRadius: 12
		property int notchHeight: bar.vertical ? 28 : bar.thickness - 2 * bar.floatGap
		readonly property int floatGap: root.barFloating && !bar.vertical ? 4 : 0
		readonly property int floatSide: root.barFloating && !bar.vertical ? 4 : 0
		property string mediaPlayer: "%any"
		// tell the music panel where the music component sits, so it opens right under it
		Binding {
			target: root
			property: "musicAnchorX"
			value: !bar.vertical && bar.style !== "i3" && mediaNotch.visible && mediaNotch.width > 0
				? bar.floatSide + mediaNotch.x + mediaNotch.width / 2 : -1
		}
		// media keys for the bar: the player that is PLAYING wins; no next/prev → seek 10 s
		function mediaCtl() {
			return 'want="$1"; act="$2"; p=""; '
				+ 'for x in $(playerctl -l 2>/dev/null); do [ "$(playerctl -p "$x" status 2>/dev/null)" = Playing ] && { p=$x; break; }; done; '
				+ 'if [ -z "$p" ]; then case "$(playerctl -p "$want" status 2>/dev/null)" in Paused) p=$want ;; *) for x in $(playerctl -l 2>/dev/null); do [ "$(playerctl -p "$x" status 2>/dev/null)" = Paused ] && { p=$x; break; }; done ;; esac; fi; '
				+ '[ -z "$p" ] && p="$want"; [ -z "$p" ] && p=%any; '
				+ 'case $act in '
				+ 'next) playerctl -p "$p" next || playerctl -p "$p" position 10+ ;; '
				+ 'previous) playerctl -p "$p" previous || playerctl -p "$p" position 10- ;; '
				+ '*) playerctl -p "$p" "$act" ;; esac; rc=$?; '
				+ 'mkdir -p ~/.cache/quickshell; echo "$(date +%T) $act -> $p (rc=$rc)" >> ~/.cache/quickshell/media.log; '
				+ 'tail -n 200 ~/.cache/quickshell/media.log > ~/.cache/quickshell/media.log.tmp && mv ~/.cache/quickshell/media.log.tmp ~/.cache/quickshell/media.log'
		}

		property string _pendingTitle: ""
		property string mediaUrl: ""
		property string _pendingArtist: ""

    	property string mediaText: ""
    	property string mediaClass: "stopped"
    	property real mediaPosition: 0
    	property real mediaLength: 0
    	property string volumeStr: "󰕾 0%"
    	property int volumePercent: 50
    	property bool volumeMuted: false
    	property bool wifiConnected: false
    	property string wifiSSID: ""
    	property int wifiStrength: 0
    	property bool btConnected: false
    	property int batteryPercent: 0
    	property bool batteryCharging: false
    	property string batteryClass: ""
    	property string batteryTime: ""
    	property var cavaValues: [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1]
    	property real chargingPulse: 1.0
    	property real chargingFillAnim: 0.0
    	property bool volumeAdjusting: false
    	property real pendingVolume: 0

	// ── Full-width cava backdrop (only while playing) ── qs-update:v2 ──
	property int bgBarCount: 48
	property var bgVals: []
	property var bgColors: []
	readonly property bool bgActive: bar.mediaClass === "playing"
	function shuffleBgColors() {
		var pal = [root.walColor5, root.walColor13, root.walColor2, root.walColor4,
		           root.walColor6, root.walColor12, root.walPeach, root.walColor1]
		var c = []
		for (var i = 0; i < bgBarCount; i++) c.push(pal[Math.floor(Math.random() * pal.length)])
		bgColors = c
	}
	Component.onCompleted: {
		var v = []
		for (var i = 0; i < bgBarCount; i++) v.push(0)
		bgVals = v
		shuffleBgColors()
	}
	onMediaTextChanged: shuffleBgColors()
	Connections {
		target: root
		function onLightModeChanged() { bar.shuffleBgColors() }
	}
	Process {
		id: barBgCavaProc
		running: bar.bgActive
		command: ["cava", "-p", Quickshell.env("HOME") + "/.config/cava/config_barbg"]
		stdout: SplitParser {
			onRead: data => {
				var parts = data.trim().split(";")
				var vals = []
				for (var i = 0; i < bar.bgBarCount; i++) {
					var n = parseInt(parts[i])
					vals.push(isNaN(n) ? 0 : Math.min(1, n / 1000))
				}
				bar.bgVals = vals
			}
		}
	}

	SequentialAnimation {
		id: chargingPulseAnim
		running: bar.batteryCharging
        	loops: Animation.Infinite
		NumberAnimation { 
			target: bar; property: "chargingPulse"; 
			to: 0.3; 
			duration: 800; 
			easing.type: Easing.InOutSine 
		}
		NumberAnimation { 
			target: bar; property: "chargingPulse"; 
			to: 1; 
			duration: 800; 
			easing.type: Easing.InOutSine 
		}
	}
	SequentialAnimation {
		id: chargingFillAnimSeq
		running: bar.batteryCharging
        	loops: Animation.Infinite
		NumberAnimation { 
			target: bar; property: "chargingFillAnim"; 
			to: 1; 
			duration: 2000; 
			easing.type: Easing.InOutSine 
		}
		NumberAnimation { 
			target: bar; property: "chargingFillAnim"; 
			to: 0; 
			duration: 2000; 
			easing.type: Easing.InOutSine 
		}
	}

	Timer {
		interval: 1500
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: { 
			if (!mediaProc.running) mediaProc.running = true 
		}
	}

	Process {
		id: cavaProc
		running: bar.mediaClass === "playing"
		command: ["cava", "-p", Quickshell.env("HOME") + "/.config/cava/config_raw"]
		stdout: SplitParser {
			onRead: data => {
				var parts = data.trim().split(";")
				var vals = []
				for (var i = 0; i < 12 && i < parts.length; i++) {
					vals.push(parseInt(parts[i]) / 255)
				}
				while (vals.length < 12) vals.push(0.1)
				bar.cavaValues = vals
			}
		}
	}

	Timer {
		interval: 80
		running: bar.mediaClass !== "playing"
		repeat: true
		onTriggered: {
			var newVals = []
			for (var i = 0; i < 12; i++) {
				newVals.push(bar.cavaValues[i] * 0.85)
			}
			bar.cavaValues = newVals
		}
	}

	Process {
	  id: mediaProc
	  command: [Quickshell.env("HOME") + "/.config/quickshell/assets/get-player.sh", "%any"]
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
	                  case "player": bar.mediaPlayer = val; break
	                  case "status": bar.mediaClass = val.toLowerCase(); break
	                  case "pos":    bar.mediaPosition = parseInt(val) || 0; break
	                  case "len":    bar.mediaLength = parseInt(val) || 0; break
	                  case "url":    bar.mediaUrl = val; break
	                  case "title":  bar._pendingTitle = val; break
	                  case "artist":
	                      bar._pendingArtist = val
	                      var text = bar._pendingArtist
	                          ? bar._pendingArtist + " - " + bar._pendingTitle
	                          : bar._pendingTitle
	                      if (text.length > 35) text = text.substring(0, 32) + "..."
	                      bar.mediaText = text
	                      break
	              }
	          }
	      }
	  }
	}
	

	Timer {
		interval: 1000
		running: bar.mediaClass === "playing"
		repeat: true
		onTriggered: {
			if (bar.mediaPosition < bar.mediaLength) {
				bar.mediaPosition += 1
			}
		}
	}

	Timer {
		interval: 800
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: { 
			if (!volumeProc.running) volumeProc.running = true 
		}
	}
	Process {
		id: volumeProc
		command: ["bash", "-c", "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null); muted=$(echo \"$vol\" | grep -q MUTED && echo 1 || echo 0); pct=$(echo \"$vol\" | awk '{printf \"%.0f\", $2 * 100}'); echo \"$pct|$muted\""]
		stdout: SplitParser {
			onRead: data => {
				var parts = data.trim().split("|")
				bar.volumePercent = parseInt(parts[0]) || 0
				bar.volumeMuted = parts[1] === "1"
				if (bar.volumeMuted) {
					bar.volumeStr = "󰝟 mute"
				} else {
					var icon = bar.volumePercent > 50 ? "󰕾" : (bar.volumePercent > 0 ? "󰖀" : "󰕿")
					bar.volumeStr = icon + " " + bar.volumePercent + "%"
				}
			}
		}
	}

	Timer {
		id: volumeDebounce
		interval: 150
		repeat: false
		onTriggered: {
			volumeSetProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", bar.pendingVolume + "%"]
			volumeSetProc.running = true
		}
	}

	Process {
		id: volumeSetProc
		onExited: {
			bar.volumeAdjusting = false
			if (!volumeProc.running) volumeProc.running = true
		}
	}

	function adjustVolume(delta) {
		bar.volumeAdjusting = true
		bar.pendingVolume = Math.max(0, Math.min(100, bar.volumePercent + delta))
		bar.volumePercent = bar.pendingVolume
        	var icon = bar.volumePercent > 50 ? "󰕾" : (bar.volumePercent > 0 ? "󰖀" : "󰕿")
        	bar.volumeStr = icon + " " + bar.volumePercent + "%"
		volumeDebounce.restart()
	}

	Timer {
		interval: 5000
        	running: true
        	repeat: true
        	triggeredOnStart: true
        	onTriggered: { 
			if (!networkProc.running) networkProc.running = true 
		}
	}

	Process {
		id: networkProc
        	command: ["bash", "-c", "wifi=$(nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes' | head -1); if [ -n \"$wifi\" ]; then ssid=$(echo \"$wifi\" | cut -d: -f2); sig=$(echo \"$wifi\" | cut -d: -f3); echo \"1|$ssid|$sig\"; else echo '0||0'; fi; bt='0'; devices=$(echo -e 'devices\\nquit' | bluetoothctl 2>/dev/null | grep '^Device' | awk '{print $2}'); for mac in $devices; do if echo -e \"info $mac\\nquit\" | bluetoothctl 2>/dev/null | grep -q 'Connected: yes'; then bt='1'; break; fi; done; echo \"bt:$bt\""]
        	stdout: SplitParser {
			onRead: data => {
				var line = data.trim()
				if (line.startsWith("bt:")) {
					bar.btConnected = line.endsWith("1")
				} else {
					var parts = line.split("|")
					bar.wifiConnected = parts[0] === "1"
					bar.wifiSSID = parts.length > 1 ? parts[1] : ""
					bar.wifiStrength = parts.length > 2 ? parseInt(parts[2]) : 0
				}
			}
		}
	}

	Timer {
		interval: 30000
		running: true
        	repeat: true
        	triggeredOnStart: true
        	onTriggered: { 
			if (!batteryProc.running) batteryProc.running = true 
		}
	}
	
	Process {
		id: batteryProc
		command: ["bash", "-c", "cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1); status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1); time=''; if command -v upower >/dev/null 2>&1; then if [ \"$status\" = \"Discharging\" ]; then time=$(upower -i $(upower -e | grep BAT) 2>/dev/null | grep 'time to empty' | awk '{print $4 $5}'); elif [ \"$status\" = \"Charging\" ]; then time=$(upower -i $(upower -e | grep BAT) 2>/dev/null | grep 'time to full' | awk '{print $4 $5}'); fi; fi; [ -z \"$cap\" ] && cap=0; echo \"$cap|$status|$time\""]
        	stdout: SplitParser {
			onRead: data => {
				var parts = data.trim().split("|")
               			bar.batteryPercent = parseInt(parts[0]) || 0
                		var status = parts.length > 1 ? parts[1] : ""
                		bar.batteryCharging = status === "Charging"
                		bar.batteryTime = parts.length > 2 ? parts[2] : ""
                		if (bar.batteryCharging) bar.batteryClass = "charging"
                		else if (bar.batteryPercent <= 10) bar.batteryClass = "critical"
                		else if (bar.batteryPercent <= 25) bar.batteryClass = "warning"
                		else bar.batteryClass = ""
			}
		}
	}

	Process {
		id: volumeToggleProc
        	command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
		onExited: { 
			if (!volumeProc.running) volumeProc.running = true 
		}
	}

    	Process {
        	id: mediaPlayPauseProc
        	command: ["bash", "-c", bar.mediaCtl(), "media", bar.mediaPlayer, "play-pause"]
		onExited: { 
			if (!mediaProc.running) mediaProc.running = true 
		}
    	}

    	Process {
        	id: mediaNextProc
        	command: ["bash", "-c", bar.mediaCtl(), "media", bar.mediaPlayer, "next"]
		onExited: { 
			if (!mediaProc.running) mediaProc.running = true 
		}
    	}

    	Process {
        	id: mediaPrevProc
        	command: ["bash", "-c", bar.mediaCtl(), "media", bar.mediaPlayer, "previous"]
        	onExited: {
			if (!mediaProc.running) mediaProc.running = true 
		}
	}


 component Notch: Item {
    id: notchRoot
    property bool hovered: false
    property string tooltip: ""
    property real natWidth: 36                  // the notch's length along a horizontal bar
    property Component vert: null               // upright layout for a side bar (optional)
    default property alias content: contentItem.data
    readonly property bool hasVert: bar.vertical && vert !== null
    // side bar without its own layout: narrow notches stay upright, wide ones turn sideways
    readonly property bool rot: bar.vertical && !hasVert && natWidth > bar.thickness * 1.15
    readonly property real vertLen: vertLoader.item ? vertLoader.item.implicitHeight + 8 : 30
    property bool sep: true                     // divider before this notch (not on the first one)
    property bool pill: false                   // Floating style: this notch gets its own box (music)
    Rectangle {
        // Islands style: each component in its own rounded box
        visible: (bar.style === "islands" || (bar.style === "floating" && notchRoot.pill)) && notchRoot.width > 0
        anchors.fill: parent
        anchors.topMargin: 2
        anchors.bottomMargin: 2
        radius: 9
        color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.88)
        border.width: 1
        border.color: Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, root.lightMode ? 0.14 : 0.08)
    }
    // a notch with no length (e.g. media while nothing plays) takes no space either way
    width: bar.vertical ? (natWidth > 0 ? bar.thickness : 0) : natWidth
    height: bar.vertical ? (natWidth <= 0 ? 0 : (hasVert ? vertLen : (rot ? natWidth : bar.notchHeight))) : bar.notchHeight

    Rectangle {
        id: tooltipBg
        visible: notchRoot.hovered && notchRoot.tooltip !== "" && !bar.vertical
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 4
        width: tooltipText.implicitWidth + 16
        height: tooltipText.implicitHeight + 8
        radius: 6
        color: root.card(0.85)
        opacity: visible ? 1 : 0
        z: 1000
        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: notchRoot.tooltip
            color: root.walForeground
            font.pixelSize: 10
            font.family: "JetBrainsMono Nerd Font"
        }
    }

    Rectangle {
        // divider in the gap before this notch
        visible: notchRoot.sep && bar.style !== "minimal" && bar.style !== "islands" && notchRoot.width > 0 && notchRoot.height > 0
                 && (bar.vertical ? notchRoot.y : notchRoot.x) > bar.secGap + 0.5
        readonly property color c: root.walForeground
        color: Qt.rgba(c.r, c.g, c.b, bar.style === "i3" ? (root.lightMode ? 0.40 : 0.28) : (root.lightMode ? 0.28 : 0.16))
        width: bar.vertical ? Math.min(16, notchRoot.width * 0.5) : 1
        height: bar.vertical ? 1 : (bar.style === "i3" ? notchRoot.height - 6 : Math.min(12, notchRoot.height * 0.45))
        x: bar.vertical ? (notchRoot.width - width) / 2 : -Math.ceil(bar.secGap / 2)
        y: bar.vertical ? -Math.ceil(bar.secGap / 2) : (notchRoot.height - height) / 2
    }
    Rectangle {
        // soft hover highlight
        anchors.fill: parent
        anchors.margins: bar.style === "i3" ? 1 : 2
        radius: bar.style === "i3" ? 0 : 8
        color: root.hover(0.07)
        opacity: notchRoot.hovered ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
    }
    // horizontal content; on a side bar with `vert` it stays (invisible) only to take the clicks
    Item {
        id: contentItem
        anchors.centerIn: parent
        width: notchRoot.hasVert ? notchRoot.width : notchRoot.natWidth
        height: notchRoot.hasVert ? notchRoot.height : bar.notchHeight
        rotation: notchRoot.rot ? 90 : 0
        opacity: notchRoot.hasVert ? 0 : 1
        clip: notchRoot.hasVert
    }
    Loader {
        id: vertLoader
        anchors.centerIn: parent
        active: notchRoot.hasVert
        sourceComponent: notchRoot.vert
    }
}
	// ── i3status look (style "i3"): workspace buttons left, i3status text line right ──
	Item {
		id: i3Layout
		visible: bar.style === "i3" && !bar.vertical
		anchors.fill: parent
		anchors.topMargin: bar.floatGap
		anchors.bottomMargin: bar.floatGap
		anchors.leftMargin: bar.floatSide
		anchors.rightMargin: bar.floatSide
		readonly property string mono: "DejaVu Sans Mono"
		readonly property int fs: 12
		readonly property color good: "#00ff00"
		readonly property color degraded: "#ffff00"
		readonly property color bad: "#ff0000"
		readonly property color txt: "#ffffff"
		property string load: "0.00"
		property string disk: "?"
		property string mem: "?"
		property string clock: ""

		HoverHandler { onHoveredChanged: hovered ? root.barPeekNow() : root.barLeave() }
		// right-click on empty bar space → bar menu (so you can switch style back)
		MouseArea {
			anchors.fill: parent
			acceptedButtons: Qt.RightButton
			onClicked: root.barMenuVisible = !root.barMenuVisible
		}

		Timer {
			interval: 1000; running: i3Layout.visible; repeat: true; triggeredOnStart: true
			onTriggered: i3Layout.clock = Qt.formatDateTime(new Date(), "yyyy-MM-dd HH:mm:ss")
		}
		Timer {
			interval: 5000; running: i3Layout.visible; repeat: true; triggeredOnStart: true
			onTriggered: if (!i3SysProc.running) i3SysProc.running = true
		}
		Process {
			id: i3SysProc
			command: ["sh", "-c", "read a b c r < /proc/loadavg; echo $a; "
				+ "df -B1 -P / | awk 'NR==2{printf \"%.1f GiB\\n\", $4/1073741824}'; "
				+ "free -b | awk '/^Mem:/{printf \"%.1f GiB\\n\", $3/1073741824}'"]
			stdout: StdioCollector {
				onStreamFinished: {
					var l = this.text.trim().split("\n")
					if (l.length >= 3) { i3Layout.load = l[0]; i3Layout.disk = l[1]; i3Layout.mem = l[2] }
				}
			}
		}

		// ── workspaces (only ones that exist, like i3) ──
		Row {
			id: i3Left
			x: 0
			height: parent.height
			spacing: 0
			I3Block {
				sep: false
				label: "󱄅"
				fontFamily: "JetBrainsMono Nerd Font"
				onLeftClick: { root.activeTab = 0; root.toggleLauncher() }
				onRightClick: {
					root.activeTab = 1
					if (!root.launcherVisible) root.toggleLauncher()
					else if (!root.wallsLoaded) root.loadWallpapers()
				}
			}
		Row {
			id: i3Ws
			anchors.verticalCenter: parent.verticalCenter
			spacing: 1
			Repeater {
				model: {
					var a = []
					var v = Hyprland.workspaces.values
					for (var i = 0; i < v.length; i++) if (v[i].id > 0) a.push(v[i])
					a.sort(function(x, y) { return x.id - y.id })
					return a
				}
				delegate: Rectangle {
					id: i3wsBtn
					required property var modelData
					readonly property bool focusedWs: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id === modelData.id : false
					readonly property bool urgentWs: modelData.urgent === true
					readonly property bool activeWs: modelData.active === true
					height: i3Layout.height - 2
					width: Math.max(height, i3wsLabel.implicitWidth + 10)
					color: urgentWs ? "#900000" : focusedWs ? "#285577" : activeWs ? "#5f676a" : "#222222"
					border.width: 1
					border.color: urgentWs ? "#2f343a" : focusedWs ? "#4c7899" : "#333333"
					Text {
						id: i3wsLabel
						anchors.centerIn: parent
						text: i3wsBtn.modelData.id
						color: i3wsBtn.focusedWs || i3wsBtn.urgentWs || i3wsBtn.activeWs ? "#ffffff" : "#888888"
						font.family: i3Layout.mono
						font.pixelSize: i3Layout.fs
					}
					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + i3wsBtn.modelData.id + " })"])
						onWheel: function(wheel) {
							Quickshell.execDetached(["hyprctl", "dispatch",
								wheel.angleDelta.y > 0 ? "hl.dsp.focus({ workspace = 'e-1' })" : "hl.dsp.focus({ workspace = 'e+1' })"])
						}
					}
				}
			}
		}

		}

		// ── status line ──
		Row {
			id: i3Status
			anchors.right: parent.right
			anchors.rightMargin: 4
			anchors.verticalCenter: parent.verticalCenter
			height: parent.height
			spacing: 0

			I3Block {
				visible: bar.mediaText !== ""
				sep: false
				label: (bar.mediaClass === "playing" ? "♪ " : "❚❚ ") + (bar.mediaText.length > 40 ? bar.mediaText.substring(0, 39) + "…" : bar.mediaText)
				onLeftClick: if (!mediaPlayPauseProc.running) mediaPlayPauseProc.running = true
				onRightClick: root.toggleMusic()
				onMiddleClick: if (!mediaNextProc.running) mediaNextProc.running = true
				onScrolled: function(up) {
					if (up) { if (!mediaNextProc.running) mediaNextProc.running = true }
					else if (!mediaPrevProc.running) mediaPrevProc.running = true
				}
			}
			I3Block {
				sep: bar.mediaText !== ""
				label: root.pomoActive ? "POMO " + root.pomoText : "POMO"
				tint: root.pomoActive ? (root.pomoRunning ? i3Layout.good : i3Layout.degraded) : "#888888"
				onLeftClick: root.togglePomodoro()
				onRightClick: root.pomoStartPause()
				onMiddleClick: root.pomoReset()
				onScrolled: function(up) { if (!root.pomoRunning) root.pomoAdjust(root.pomoPhase, up ? 1 : -1) }
			}
			I3Block {
				visible: root.jarvisEnabled
				label: !root.jarvisOnline ? "J: offline" : root.jarvisBadge > 0 ? "J: " + root.jarvisBadge : "J: ok"
				tint: !root.jarvisOnline ? "#888888" : root.jarvisCritical ? i3Layout.bad : root.jarvisBadge > 0 ? i3Layout.degraded : i3Layout.good
				onLeftClick: root.toggleJarvis()
				onRightClick: root.toggleJarvisTimeline()
				onMiddleClick: root.jarvisOpenDashboard()
			}
			I3Block {
				label: root.recording ? "REC " + root.recElapsedText : "REC"
				tint: root.recording ? i3Layout.bad : "#888888"
				onLeftClick: root.recording ? root.stopRecording() : root.toggleRecordMenu()
				onRightClick: root.toggleRecordMenu()
			}
			I3Block {
				label: bar.wifiConnected ? "W: (" + bar.wifiStrength + "% at " + bar.wifiSSID + ")" : "W: down"
				tint: bar.wifiConnected ? i3Layout.good : i3Layout.bad
				onLeftClick: root.toggleWifi()
				onRightClick: root.toggleBluetooth()
			}
			I3Block {
				label: bar.btConnected ? "BT: on" : "BT: off"
				tint: bar.btConnected ? i3Layout.good : "#888888"
				onLeftClick: root.toggleBluetooth()
			}
			I3Block {
				label: root.ethConnected ? "E: up" : "E: down"
				tint: root.ethConnected ? i3Layout.good : i3Layout.bad
				onLeftClick: root.toggleWifi()
			}
			I3Block { label: "/: " + i3Layout.disk }
			I3Block {
				label: "load: " + i3Layout.load
				tint: parseFloat(i3Layout.load) > 5 ? i3Layout.bad : i3Layout.txt
			}
			I3Block { label: "MEM: " + i3Layout.mem }
			I3Block {
				label: bar.volumeMuted ? "VOL: muted (" + bar.volumePercent + "%)" : "VOL: " + bar.volumePercent + "%"
				tint: bar.volumeMuted ? i3Layout.degraded : i3Layout.txt
				onLeftClick: if (!volumeToggleProc.running) volumeToggleProc.running = true
				onRightClick: root.toggleEq()
				onScrolled: function(up) { bar.adjustVolume(up ? 5 : -5) }
			}
			I3Block {
				label: (bar.batteryCharging ? "CHR " : bar.batteryPercent >= 99 ? "FULL " : "BAT ")
					+ bar.batteryPercent + "%" + (bar.batteryTime !== "" ? " " + bar.batteryTime : "")
				tint: bar.batteryCharging ? i3Layout.good
					: bar.batteryClass === "critical" || bar.batteryPercent <= 10 ? i3Layout.bad
					: bar.batteryClass === "warning" || bar.batteryPercent <= 25 ? i3Layout.degraded : i3Layout.txt
				onLeftClick: root.toggleScreenTime()
			}
			I3Block {
				label: i3Layout.clock
				onLeftClick: root.toggleClockPanel()
				onRightClick: root.toggleCalendar()
			}
			// tray
			Row {
				visible: SystemTray.items.values.length > 0
				anchors.verticalCenter: parent.verticalCenter
				leftPadding: 8
				rightPadding: 4
				spacing: 4
				Repeater {
					model: SystemTray.items
					delegate: Item {
						id: i3tray
						required property var modelData
						width: 16; height: 16
						anchors.verticalCenter: parent ? parent.verticalCenter : undefined
						Image {
							anchors.fill: parent
							source: i3tray.modelData.icon
							sourceSize.width: 32; sourceSize.height: 32
							smooth: true
						}
						MouseArea {
							anchors.fill: parent
							acceptedButtons: Qt.LeftButton | Qt.RightButton
							cursorShape: Qt.PointingHandCursor
							onClicked: function(mouse) {
								var m = i3tray.modelData
								if (mouse.button === Qt.LeftButton && !m.onlyMenu) { m.activate(); return }
								if (m.hasMenu) {
									var p = i3tray.mapToItem(null, 0, i3tray.height)
									m.display(bar, p.x, p.y)
								}
							}
						}
					}
				}
			}
			I3Block {
				label: "NOTE"
				tint: root.notesVisible ? "#ffff00" : "#ffffff"
				onLeftClick: root.toggleNotes()
			}
			I3Block {
				label: "CLIP"
				onLeftClick: root.toggleClipboard()
				onRightClick: root.toggleNotes()
			}
			I3Block {
				label: "DASH"
				onLeftClick: root.toggleDashboard()
				onRightClick: root.toggleNotifCenter()
			}
			I3Block {
				label: "≡"
				onLeftClick: root.barMenuVisible = !root.barMenuVisible
				onRightClick: root.nextTheme()
			}
		}
	}

	component I3Block: Item {
		id: blk
		property string label: ""
		property color tint: "#ffffff"
		signal leftClick()
		signal rightClick()
		signal middleClick()
		signal scrolled(bool up)
		property bool sep: true
		property string fontFamily: "DejaVu Sans Mono"
		width: visible ? blkText.implicitWidth + 18 : 0
		height: parent ? parent.height : 20
		Rectangle {
			// i3bar separator
			visible: blk.sep
			x: 0
			width: 1
			height: parent.height - 8
			anchors.verticalCenter: parent.verticalCenter
			color: "#666666"
		}
		Text {
			id: blkText
			anchors.centerIn: parent
			text: blk.label
			color: blk.tint
			font.family: blk.fontFamily
			font.pixelSize: 12
		}
		MouseArea {
			anchors.fill: parent
			cursorShape: Qt.PointingHandCursor
			acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
			onClicked: function(mouse) {
				if (mouse.button === Qt.RightButton) blk.rightClick()
				else if (mouse.button === Qt.MiddleButton) blk.middleClick()
				else blk.leftClick()
			}
			onWheel: function(wheel) { blk.scrolled(wheel.angleDelta.y > 0) }
		}
	}
	// ── end i3status look ──
	Item {
		anchors.fill: parent
		anchors.topMargin: bar.floatGap
		anchors.bottomMargin: bar.floatGap
		anchors.leftMargin: bar.floatSide
		anchors.rightMargin: bar.floatSide
		visible: bar.style !== "i3" || bar.vertical
		HoverHandler {
			// auto-hide: keep the bar out while the pointer is on it
			onHoveredChanged: hovered ? root.barPeekNow() : root.barLeave()
		}
		
		// Floating style: one box behind each side of the bar
		Rectangle {
			visible: bar.style === "floating" && !bar.vertical && leftSection.width > 0
			x: leftSection.x - 8
			y: 2
			width: leftSection.width * leftSection.scale + 16
			height: parent.height - 4
			radius: 10
			color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.88)
			border.width: 1
			border.color: Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, root.lightMode ? 0.14 : 0.08)
		}
		Rectangle {
			visible: bar.style === "floating" && !bar.vertical && rightSection.width > 0
			x: rightSection.x + rightSection.width * (1 - rightSection.scale) - 8
			y: 2
			width: rightSection.width * rightSection.scale + 16
			height: parent.height - 4
			radius: 10
			color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.88)
			border.width: 1
			border.color: Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, root.lightMode ? 0.14 : 0.08)
		}
		Grid {
			id: leftSection
			x: bar.vertical ? (parent.width - width) / 2 : (bar.style === "floating" ? 14 : 8)
			y: bar.vertical ? 8 : (parent.height - height) / 2
			rows: bar.vertical ? -1 : 1
			columns: bar.vertical ? 1 : -1
			flow: bar.vertical ? Grid.TopToBottom : Grid.LeftToRight
			horizontalItemAlignment: Grid.AlignHCenter
			verticalItemAlignment: Grid.AlignVCenter
			scale: bar.sectionScale
			transformOrigin: bar.vertical ? Item.Top : Item.Left
			spacing: bar.secGap
			Notch {
				natWidth: bar.iconW
				hovered: appsMA.containsMouse
				tooltip: "Apps / Wallpapers"
				Item {
					anchors.fill: parent
					Text {
						anchors.centerIn: parent
						text: "󱄅"
                        			color: root.walColor13
                        			font.pixelSize: 16
                        			font.family: "JetBrainsMono Nerd Font"
					}
				}
				MouseArea {
					id: appsMA
                    			anchors.fill: parent
                    			hoverEnabled: true
                    			cursorShape: Qt.PointingHandCursor
                    			acceptedButtons: Qt.LeftButton | Qt.RightButton
                    			onClicked: function(mouse) {
						if (mouse.button === Qt.RightButton) {
							root.activeTab = 1
							if (!root.launcherVisible) root.toggleLauncher()
							else { 
								root.activeTab = 1; if (!root.wallsLoaded) root.loadWallpapers() 
							}
						} else {
							root.activeTab = 0
							root.toggleLauncher()
						}
					}
				}
			}
			Notch {
			  natWidth: clockRow.implicitWidth + bar.pad
			 vert: Component {
				 Column {
					 spacing: 0
					 Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(bar.nowTime, "hh"); color: root.walColor5; font.pixelSize: 15; font.bold: true; font.family: "JetBrainsMono Nerd Font" }
					 Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(bar.nowTime, "mm"); color: root.walColor5; font.pixelSize: 15; font.bold: true; font.family: "JetBrainsMono Nerd Font" }
					 Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(bar.nowTime, "AP"); color: root.walColor8; font.pixelSize: 8; font.family: "JetBrainsMono Nerd Font" }
					 Item { width: 1; height: 4 }
					 Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 16; height: 1; color: Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.35) }
					 Item { width: 1; height: 4 }
					 Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(bar.nowTime, "d"); color: root.walForeground; font.pixelSize: 11; font.bold: true; font.family: "JetBrainsMono Nerd Font" }
					 Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(bar.nowTime, "MMM"); color: root.walColor8; font.pixelSize: 8; font.family: "JetBrainsMono Nerd Font" }
				 }
			 }
			  hovered: clockMA.containsMouse
			  tooltip: Qt.formatDateTime(new Date(), "dddd, MMMM d, yyyy")
			  Item {
			      anchors.fill: parent
			      Row {
			          id: clockRow
			          anchors.centerIn: parent
			          spacing: 8
			          Text {
			              id: clockLabel
			              anchors.verticalCenter: parent.verticalCenter
			              text: Qt.formatDateTime(new Date(), "hh:mm AP")
			              color: root.walColor5
			              font.pixelSize: 11
			              font.bold: true
			              font.family: "JetBrainsMono Nerd Font"
			          }
			          Rectangle {
			              width: 1
			              height: 14
			              anchors.verticalCenter: parent.verticalCenter
			              color: Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.3)
			          }
			          Text {
			              id: dateLabel
			              anchors.verticalCenter: parent.verticalCenter
			              text: Qt.formatDateTime(new Date(), "MMM d, ddd")
			              color: root.walColor5
						font.pixelSize: 11
						font.bold: true
						font.family: "JetBrainsMono Nerd Font"
			          }
			      }
			  }
			  MouseArea {
			      id: clockMA
			      anchors.fill: parent
			      hoverEnabled: true
			      cursorShape: Qt.PointingHandCursor
			      acceptedButtons: Qt.LeftButton | Qt.RightButton
			      onClicked: function(mouse) {
			          if (mouse.button === Qt.RightButton) {
			              root.toggleCalendar()
			          } else {
			              root.toggleClockPanel()
			          }
			      }
			  }
			  Timer {
			      interval: 1000
			      running: true
			      repeat: true
			      triggeredOnStart: true
			      onTriggered: {
			          clockLabel.text = Qt.formatDateTime(new Date(), "hh:mm AP")
			          dateLabel.text  = Qt.formatDateTime(new Date(), "MMM d, ddd")
			      }
			  }
			}
Notch {
    id: workspacesNotch
    natWidth: wsContainer.width + 1
    vert: Component {
        Column {
            spacing: 3
            Repeater {
                model: 10
                Rectangle {
                    id: vws
                    readonly property int wsId: index + 1
                    readonly property bool isActive: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id === wsId : false
                    readonly property bool hasWindows: {
                        var vals = Hyprland.workspaces.values
                        for (var i = 0; i < vals.length; i++) if (vals[i].id === wsId) return true
                        return false
                    }
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 26
                    height: isActive ? 30 : 20
                    radius: 10
                    color: isActive ? root.walColor13 : (vwsMa.containsMouse ? Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.3) : "transparent")
                    Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Text {
                        anchors.centerIn: parent
                        text: vws.wsId
                        color: vws.isActive ? root.walBackground : vws.hasWindows ? root.walForeground
                            : Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.35)
                        font.pixelSize: 10
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    MouseArea {
                        id: vwsMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) root.toggleWorkspaceOverview()
                            else Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + vws.wsId + " })"])
                        }
                        onWheel: function(wheel) {
                            Quickshell.execDetached(["hyprctl", "dispatch",
                                wheel.angleDelta.y > 0 ? "hl.dsp.focus({ workspace = 'e-1' })" : "hl.dsp.focus({ workspace = 'e+1' })"])
                        }
                    }
                }
            }
        }
    }
    Behavior on natWidth {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    Item {
        anchors.fill: parent
        Item {
            id: wsContainer
            anchors.centerIn: parent
            width: wsRow.implicitWidth
            height: 18

            Rectangle {
                id: wsHighlight
                height: bar.style === "i3" ? bar.thickness - 4 : 18
                radius: bar.style === "i3" ? 2 : 9
                z: 0
                property real targetX: 0
                property real targetWidth: 26
                x: targetX
                width: targetWidth
                color: root.walColor13
                antialiasing: true
                Behavior on x {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }
                Behavior on width {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }
            }

            Row {
                id: wsRow
                anchors.centerIn: parent
                spacing: 4

                Repeater {
                    id: wsRepeater
                    model: 10

                    Item {
                        id: wsDelegate
                        readonly property int wsId: index + 1
                        readonly property bool isActive: Hyprland.focusedWorkspace
                            ? Hyprland.focusedWorkspace.id === wsId
                            : false
                        readonly property bool hasWindows: {
                            var found = false
                            var vals = Hyprland.workspaces.values
                            for (var i = 0; i < vals.length; i++) {
                                if (vals[i].id === wsId) { found = true; break }
                            }
                            return found
                        }

                        width: Math.max(wsText.implicitWidth + 14, 26)
                        height: 18
                        z: 1

                        onIsActiveChanged: if (isActive) updateHighlight()
                        onXChanged: if (isActive) updateHighlight()
                        onWidthChanged: if (isActive) updateHighlight()
                        Component.onCompleted: if (isActive) updateHighlight()

                        function updateHighlight() {
                            wsHighlight.targetX = x
                            wsHighlight.targetWidth = width
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 9
                            color: wsMa.containsMouse && !wsDelegate.isActive
                                ? Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.3)
                                : "transparent"
                            antialiasing: true
                            Behavior on color {
                                ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                        }

                        Text {
                            id: wsText
                            anchors.centerIn: parent
                            text: wsDelegate.wsId.toString()
                            color: wsDelegate.isActive
                                ? root.walBackground
                                : wsDelegate.hasWindows
                                    ? root.walForeground
                                    : Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.35)
                            font.pixelSize: 10
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            Behavior on color {
                                ColorAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                        }

						MouseArea {
						  id: wsMa
						  anchors.fill: parent
						  hoverEnabled: true
						  cursorShape: Qt.PointingHandCursor
						  acceptedButtons: Qt.LeftButton | Qt.RightButton
						 onClicked: function(mouse) {
						     if (mouse.button === Qt.RightButton) root.toggleWorkspaceOverview()
						     else Quickshell.execDetached([
						      "hyprctl", "dispatch",
						      "hl.dsp.focus({ workspace = " + wsDelegate.wsId + " })"
						  ])
						 }
							onWheel: function(wheel) {
							  var current = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
							  var maxWs = 1
							  var vals = Hyprland.workspaces.values
							  for (var i = 0; i < vals.length; i++) {
							      if (vals[i].id > maxWs) maxWs = vals[i].id
							  }
							  if (wheel.angleDelta.y > 0) {
							      if (current > 1)
							          Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = 'e-1' })"])
							  } else {
							      if (current < maxWs)
							          Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = 'e+1' })"])
							  }
							}
						}
                    }
                }
            }
        }
    }
}
		}
		Notch {
			id: mediaNotch
			x: bar.vertical ? (parent.width - width) / 2 : leftSection.x + leftSection.width * leftSection.scale + bar.secGap + 8
			y: bar.vertical ? bar.mediaY - height * (1 - bar.sectionScale) / 2 : 0
			sep: false
			pill: true
			scale: bar.sectionScale
            		natWidth: bar.mediaText !== "" ? mediaContent.width + bar.pad + 6 : 0
			vert: Component {
				Column {
					spacing: 3
					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: "󰎈"
						color: root.walColor5
						font.pixelSize: 15
						font.family: "JetBrainsMono Nerd Font"
						scale: bar.mediaClass === "playing" ? 1 + ((bar.cavaValues[0] || 0) + (bar.cavaValues[1] || 0)) * 0.12 : 1
						Behavior on scale { NumberAnimation { duration: 90 } }
					}
					Text {
						anchors.horizontalCenter: parent.horizontalCenter
						text: bar.mediaClass === "playing" ? "󰏤" : "󰐊"
						color: root.walColor8
						font.pixelSize: 10
						font.family: "JetBrainsMono Nerd Font"
					}
				}
			}
            		visible: bar.mediaText !== "" && bar.mediaFits
            		hovered: mediaMA.containsMouse
            		tooltip: bar.mediaText
			Behavior on natWidth { 
				NumberAnimation { 
					duration: 350; 
					easing.type: Easing.OutCubic 
				} 
			}
			Item {
				anchors.fill: parent
				Column {
					id: mediaContent
					anchors.centerIn: parent
					spacing: 2
					Row {
						anchors.horizontalCenter: parent.horizontalCenter
						spacing: 10
						Item {
							width: cavaRow.width
							height: 14
							anchors.verticalCenter: parent.verticalCenter
							Row {
								id: cavaRow
								anchors.centerIn: parent
								spacing: 2
								Repeater {
									model: 12
									Rectangle {
										width: 2.5
										height: Math.max(3, bar.cavaValues[index] * 14)
										radius: 1.25
										anchors.verticalCenter: parent.verticalCenter
										color: root.walColor5
										antialiasing: true
										Behavior on height { 
											NumberAnimation { 
												duration: 60; 
												easing.type: Easing.OutQuad 
											} 
										}
									}
								}
							}
						}
					Text {
					  id: mediaLabel
					  anchors.verticalCenter: parent.verticalCenter
					  text: bar.mediaText
					  color: root.walColor13
					  font.pixelSize: 10
					  font.bold: true
					  font.family: "JetBrainsMono Nerd Font"
					  opacity: 1.0
					  Behavior on opacity {
					      NumberAnimation {
					          duration: 300;
					          easing.type: Easing.OutCubic
					      }
					  }
					}
									}
					Rectangle {
						width: 200
						height: 3
						radius: 1.5
						color: root.card(0.4)
						visible: bar.mediaLength > 0
						Rectangle {
							width: bar.mediaLength > 0 ? parent.width * (bar.mediaPosition / bar.mediaLength) : 0
							height: parent.height
							radius: 1.5
							color: root.walColor2
							Behavior on width {
								NumberAnimation {
									duration: 200
									easing.type: Easing.Linear
								}
							}
						}
					}

					}
				}
								MouseArea {
				id: mediaMA
                		anchors.fill: parent
                		hoverEnabled: true
                		cursorShape: Qt.PointingHandCursor
                		acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                		onClicked: function(mouse) {
					if (mouse.button === Qt.RightButton)
                        		root.toggleMusic()
                    			else if (mouse.button === Qt.MiddleButton) {
						if (!mediaNextProc.running) mediaNextProc.running = true
					} else {
						if (!mediaPlayPauseProc.running) mediaPlayPauseProc.running = true
					}
				}
				onWheel: function(wheel) {
					if (wheel.angleDelta.y > 0) {
						if (!mediaNextProc.running) mediaNextProc.running = true
					} else {
						if (!mediaPrevProc.running) mediaPrevProc.running = true
					}
				}
			}
			}
		// ── bar-lyrics3 (ticker) + subs v2: synced lyrics (LRCLIB) / YouTube subtitles in the free space between music and the right side ──
		Item {
			id: lyricStrip
			readonly property real leftEdge: mediaNotch.visible && mediaNotch.width > 0
				? mediaNotch.x + mediaNotch.width + 14
				: leftSection.x + leftSection.width * leftSection.scale + 14
			readonly property real rightEdge: rightSection.x + rightSection.width * (1 - rightSection.scale) - 14
			readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/assets/lyrics.py"
			readonly property string subsScript: Quickshell.env("HOME") + "/.config/quickshell/assets/subs.py"
			readonly property bool isBrowser: /firefox|zen|chrom|brave|vivaldi|librewolf|floorp/i.test(bar.mediaPlayer)
			property bool triedSubs: false
			property int retries: 0
			property string source: ""        // "lyrics" | "subs"
			x: leftEdge
			y: 0
			width: Math.max(0, rightEdge - leftEdge)
			height: parent.height
			clip: true
			visible: !bar.vertical && bar.style !== "i3" && width > 80 && bar.mediaText !== "" && lines.length > 0

			property string key: ""
			property var lines: []
			property int lyrIdx: -1
			property real basePos: 0
			property real baseAt: 0
			property real pos: 0
			property bool playing: false
			property real progress: 0
			readonly property string cur: lyrIdx >= 0 && lyrIdx < lines.length ? lines[lyrIdx][1] : ""

			function refetch() {
				var k = JSON.stringify([bar._pendingArtist, bar._pendingTitle, bar.mediaLength, bar.mediaUrl])
				if (bar._pendingTitle === "" || k === key) return
				key = k
				lines = []
				lyrIdx = -1
				w0 = 0
				triedSubs = false
				retries = 0
				source = ""
				runLyrics()
			}
			function runLyrics() {
				lyrProc.running = false
				lyrProc.command = ["python3", script, key, bar._pendingArtist, bar._pendingTitle, "" + bar.mediaLength]
				Qt.callLater(function() { lyrProc.running = true })
			}
			function runSubs() {
				triedSubs = true
				retries = 0
				subsProc.running = false
				subsProc.command = ["python3", subsScript, key, bar._pendingTitle, bar._pendingArtist, "" + bar.mediaLength, bar.mediaUrl]
				Qt.callLater(function() { subsProc.running = true })
			}
			function gotResult(o, kind) {
				if (o.key !== key) return
				if (o.ok) {
					source = kind
					lyrIdx = -1
					w0 = 0
					lines = o.lines
					locate()
					return
				}
				var net = ("" + o.why).indexOf("network") === 0
				if (net && retries < 3) { retries++; retryTimer.kind = kind; retryTimer.restart(); return }
				if (kind === "lyrics" && isBrowser && !triedSubs) runSubs()
			}
			Timer {
				id: retryTimer
				property string kind: "lyrics"
				interval: 30000
				onTriggered: kind === "subs" ? lyricStrip.runSubs() : lyricStrip.runLyrics()
			}
			function locate() {
				var p = pos + 0.2, i = lyrIdx
				if (i < 0 || i >= lines.length || lines[i][0] > p) i = -1
				while (i + 1 < lines.length && lines[i + 1][0] <= p) i++
				if (i !== lyrIdx) lyrIdx = i
				if (i < 0) { progress = 0; return }
				var st = lines[i][0]
				var en = i + 1 < lines.length ? lines[i + 1][0] : st + 5
				progress = Math.max(0, Math.min(1, (pos - st) / Math.max(0.5, en - st)))
			}
			
			Connections {
				target: bar
				function onMediaTextChanged() { lyrDebounce.restart() }
				function onMediaUrlChanged() { lyrDebounce.restart() }
				function onMediaLengthChanged() { lyrDebounce.restart() }
			}
			Timer { id: lyrDebounce; interval: 700; onTriggered: lyricStrip.refetch() }
			Process {
				id: lyrProc
				stdout: StdioCollector {
					onStreamFinished: {
						try { lyricStrip.gotResult(JSON.parse(this.text.trim().split("\n").pop()), "lyrics") } catch (e) {}
					}
				}
			}
			Process {
				id: subsProc
				stdout: StdioCollector {
					onStreamFinished: {
						try { lyricStrip.gotResult(JSON.parse(this.text.trim().split("\n").pop()), "subs") } catch (e) {}
					}
				}
			}
			// real playback position, re-synced every second
			Process {
				id: lyrPosProc
				// status + position straight from the player (falls back to any player)
				command: ["bash", "-c",
					"f='{{status}} {{position}}'; playerctl -p \"$1\" metadata --format \"$f\" 2>/dev/null || playerctl metadata --format \"$f\"",
					"_", bar.mediaPlayer]
				stdout: StdioCollector {
					onStreamFinished: {
						var parts = this.text.trim().split(/\s+/)
						var v = parseFloat(parts[1]) / 1e6
						if (parts.length < 2 || isNaN(v)) return
						lyricStrip.playing = parts[0] === "Playing"
						lyricStrip.basePos = v
						lyricStrip.baseAt = Date.now()
						lyricStrip.pos = v
						lyricStrip.locate()
					}
				}
			}
			Timer {
				interval: 1000
				running: lyricStrip.lines.length > 0 && bar.mediaText !== ""
				repeat: true
				triggeredOnStart: true
				onTriggered: if (!lyrPosProc.running) lyrPosProc.running = true
			}
			Timer {
				interval: 16
				running: lyricStrip.lines.length > 0 && lyricStrip.playing && lyricStrip.baseAt > 0
				repeat: true
				onTriggered: {
					lyricStrip.pos = lyricStrip.basePos + (Date.now() - lyricStrip.baseAt) / 1000
					lyricStrip.locate()
				}
			}

			// one long joined line of lyrics, moving right → left, synced to the song
			readonly property real anchorX: width * 0.30     // where the line being sung sits
			property var starts: []
			property real offset: 0
			property int w0: 0                                  // first line that has an item
			readonly property int w1: Math.min(lines.length, w0 + 30)
			readonly property var shown: lines.slice(w0, w1)
			onLyrIdxChanged: {
				if (lyrIdx < 0) { if (w0 !== 0) { w0 = 0; starts = [] } return }
				if (lyrIdx < w0 || lyrIdx - w0 > 10 || lyrIdx >= w1 - 8) {
					var nw = Math.max(0, lyrIdx - 3)
					if (nw !== w0) { w0 = nw; starts = [] }
				}
			}
			function measure() {
				var st = []
				for (var i = 0; i < lyrRep.count; i++) {
					var it = lyrRep.itemAt(i)
					st.push(it ? it.x : 0)
				}
				starts = st
			}
			function place() {
				var n = lines.length
				if (n === 0 || starts.length !== shown.length) return
				var t = pos, s
				if (w0 === 0 && t < lines[0][0]) {
					// intro: first line drifts in from the right edge
					var f = lines[0][0] > 0 ? Math.max(0, t) / lines[0][0] : 1
					s = -(width - anchorX) * (1 - f)
				} else {
					var i = Math.max(0, lyrIdx)
					var t0 = lines[i][0]
					var t1 = i + 1 < n ? lines[i + 1][0] : t0 + 4
					var li = i - w0
					if (li < 0 || li >= starts.length) return
					var a = starts[li]
					var b = li + 1 < starts.length ? starts[li + 1] : lyrRow.width
					s = a + (b - a) * Math.min(1.5, (t - t0) / Math.max(0.3, t1 - t0))
				}
				offset = s
			}
			onPosChanged: place()
			onWidthChanged: place()

			Row {
				id: lyrRow
				x: lyricStrip.anchorX - lyricStrip.offset
				anchors.verticalCenter: parent.verticalCenter
				spacing: 0
				onWidthChanged: Qt.callLater(function() { lyricStrip.measure(); lyricStrip.place() })
				Repeater {
					id: lyrRep
					model: lyricStrip.shown
					delegate: Row {
						required property var modelData
						required property int index
						readonly property int gi: index + lyricStrip.w0
						readonly property bool now: gi === lyricStrip.lyrIdx
						readonly property bool past: gi < lyricStrip.lyrIdx
						spacing: 0
						Text {
							text: modelData[1] !== "" ? modelData[1] : "♪"
							color: now ? (lyricStrip.source === "subs" ? root.walColor6 : root.walColor5) : root.walForeground
							opacity: now ? 1 : (past ? 0.30 : 0.55)
							font.pixelSize: 11
							font.family: "JetBrainsMono Nerd Font"
							Behavior on opacity { NumberAnimation { duration: 250 } }
						}
						Text {
							text: "   •   "
							color: root.walColor8
							opacity: 0.45
							font.pixelSize: 11
							font.family: "JetBrainsMono Nerd Font"
						}
					}
				}
			}
			// soft fade at both ends (solid bar only)
			Rectangle {
				visible: root.barOpacity === "opaque" && !root.barFloating
				anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
				width: 28
				gradient: Gradient {
					orientation: Gradient.Horizontal
					GradientStop { position: 0; color: root.barBg }
					GradientStop { position: 1; color: Qt.rgba(root.barBg.r, root.barBg.g, root.barBg.b, 0) }
				}
			}
			Rectangle {
				visible: root.barOpacity === "opaque" && !root.barFloating
				anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
				width: 28
				gradient: Gradient {
					orientation: Gradient.Horizontal
					GradientStop { position: 0; color: Qt.rgba(root.barBg.r, root.barBg.g, root.barBg.b, 0) }
					GradientStop { position: 1; color: root.barBg }
				}
			}
		}


		
		Grid {
			id: rightSection
			x: bar.vertical ? (parent.width - width) / 2 : parent.width - width - (bar.style === "floating" ? 14 : 8)
			y: bar.vertical ? parent.height - height - 8 : (parent.height - height) / 2
			rows: bar.vertical ? -1 : 1
			columns: bar.vertical ? 1 : -1
			flow: bar.vertical ? Grid.TopToBottom : Grid.LeftToRight
			horizontalItemAlignment: Grid.AlignHCenter
			verticalItemAlignment: Grid.AlignVCenter
			scale: bar.sectionScale
			transformOrigin: bar.vertical ? Item.Bottom : Item.Right
			spacing: bar.secGap
			Notch {
				natWidth: batteryRow.width + bar.pad
				vert: Component {
					Column {
						spacing: 1
						readonly property color tint: bar.batteryClass === "charging" ? root.walColor2
							: bar.batteryClass === "critical" ? root.walColor1
							: bar.batteryClass === "warning" ? root.walColor4 : root.walColor13
						Text {
							anchors.horizontalCenter: parent.horizontalCenter
							text: bar.batteryCharging ? "󰂄"
								: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][Math.max(0, Math.min(9, Math.floor(bar.batteryPercent / 10.01)))]
							color: parent.tint
							font.pixelSize: 15
							font.family: "JetBrainsMono Nerd Font"
						}
						Text { anchors.horizontalCenter: parent.horizontalCenter; text: bar.batteryPercent; color: parent.tint; font.pixelSize: 9; font.bold: true; font.family: "JetBrainsMono Nerd Font" }
					}
				}
				hovered: batteryMA.containsMouse
				tooltip: {
					var t = bar.batteryPercent + "%"
					if (bar.batteryCharging) t += " (Charging)"
					if (bar.batteryTime) t += " - " + bar.batteryTime
					t += " · click: screen time"

					return t
				}
				Item {
					anchors.fill: parent
					Row {
						id: batteryRow
						anchors.centerIn: parent
						spacing: 8
						Item {
							width: 20
							height: 12
							anchors.verticalCenter: parent.verticalCenter
							Rectangle {
								id: batteryBody
                        					anchors.left: parent.left
                        					anchors.verticalCenter: parent.verticalCenter
                       						width: 16
                        					height: 10
                        					radius: 3
    								color: "transparent"
                        					border.width: bar.batteryPercent >= 100 ? 0 : 1.5
                        					border.color: {
									if (bar.batteryClass === "charging") return root.walColor2
									if (bar.batteryClass === "critical") return root.walColor1
                                					if (bar.batteryClass === "warning") return root.walColor4
                                					return root.walColor13
								}
								antialiasing: true
								Behavior on border.color { 
									ColorAnimation { 
										duration: 400; 
										easing.type: Easing.OutCubic 
									} 
								}
								Rectangle {
									id: batteryFill
                                					anchors.left: parent.left
                                					anchors.leftMargin: bar.batteryPercent >= 100 ? 0 : 2
                                					anchors.verticalCenter: parent.verticalCenter
                                					width: {
										if (bar.batteryPercent >= 100) return parent.width
										var base = Math.max(0, (parent.width - 5) * bar.batteryPercent / 100)
										if (bar.batteryCharging) {
											var extra = (parent.width - 5 - base) * bar.chargingFillAnim * 0.3
											return base + extra
										}
										return base
									}
									height: bar.batteryPercent >= 100 ? parent.height : parent.height - 4
									radius: bar.batteryPercent >= 100 ? 3 : 1.5
									color: {
										if (bar.batteryClass === "charging") return root.walColor2
                                        					if (bar.batteryClass === "critical") return root.walColor1
                                        					if (bar.batteryClass === "warning") return root.walColor4
                                        					return root.walColor13
									}
									antialiasing: true
									Behavior on width { 
										NumberAnimation { 
											duration: bar.batteryCharging ? 50 : 600; 
											easing.type: Easing.OutCubic 
										} 
									}
									Behavior on color { 
										ColorAnimation { 
											duration: 400; 
											easing.type: Easing.OutCubic 
										} 
									}
								}
							}
							Rectangle {
								anchors.left: batteryBody.right
								anchors.leftMargin: 1
								anchors.verticalCenter: parent.verticalCenter
								width: 2
								height: 5
								radius: 1
								color: batteryFill.color
								visible: bar.batteryPercent < 100
								antialiasing: true
								Behavior on color { 
									ColorAnimation { 
										duration: 400; 
										easing.type: Easing.OutCubic 
									}
								}
							}
							Text {
								anchors.centerIn: batteryBody
                                				text: "󱐋"
                                				color: root.walBackground
                                				font.pixelSize: 7
                                				font.family: "JetBrainsMono Nerd Font"
                               					visible: bar.batteryCharging && bar.batteryPercent < 100
                                				opacity: bar.chargingPulse
							}
							Text {
								anchors.centerIn: batteryBody
								text: "󰄬"
								color: root.walBackground
								font.pixelSize: 8
								font.family: "JetBrainsMono Nerd Font"
								visible: bar.batteryPercent >= 100
							}
						}
						Text {
							anchors.verticalCenter: parent.verticalCenter
                            				text: bar.batteryPercent + "%"
                            				color: batteryFill.color
                            				font.pixelSize: 11
                            				font.bold: true
                            				font.family: "JetBrainsMono Nerd Font"
                            				Behavior on color {
								ColorAnimation { 
									duration: 400; 
									easing.type: Easing.OutCubic 
								} 
							}
						}
					}
				}
				MouseArea {
					id: batteryMA
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: root.toggleScreenTime()
				}
			}
			Notch {
				natWidth: volumeLabel.implicitWidth + bar.pad
				vert: Component {
					Column {
						spacing: 1
						Text {
							anchors.horizontalCenter: parent.horizontalCenter
							text: bar.volumeMuted ? "󰝟" : (bar.volumePercent < 35 ? "󰕿" : bar.volumePercent < 70 ? "󰖀" : "󰕾")
							color: bar.volumeMuted ? root.walColor8 : root.walColor5
							font.pixelSize: 15
							font.family: "JetBrainsMono Nerd Font"
						}
						Text { anchors.horizontalCenter: parent.horizontalCenter; text: bar.volumeMuted ? "–" : bar.volumePercent; color: bar.volumeMuted ? root.walColor8 : root.walColor5; font.pixelSize: 9; font.bold: true; font.family: "JetBrainsMono Nerd Font" }
					}
				}
				hovered: volumeMA.containsMouse
				tooltip: (bar.volumeMuted ? "Muted" : (bar.volumePercent + "%")) + (root.eqEnabled ? " · EQ " + root.eqPreset : "") + " · right-click: equalizer"
				Item {
					anchors.fill: parent
					Text {
						id: volumeLabel
                        			anchors.centerIn: parent
                        			text: bar.volumeStr
                        			color: bar.volumeMuted ? root.walColor8 : root.walColor5
                        			font.pixelSize: 11
                        			font.bold: true
                        			font.family: "JetBrainsMono Nerd Font"
						Behavior on color { 
							ColorAnimation { 
								duration: 200; 
								easing.type: Easing.OutCubic 
							} 
						}
					}
				}
				MouseArea {
					id: volumeMA
                    			anchors.fill: parent
                    			hoverEnabled: true
                    			cursorShape: Qt.PointingHandCursor
                    			acceptedButtons: Qt.LeftButton | Qt.RightButton
					onClicked: function(mouse) {
						if (mouse.button === Qt.RightButton) root.toggleEq()
						else if (!volumeToggleProc.running) volumeToggleProc.running = true
					}
					onWheel: function(wheel) {
						var delta = wheel.angleDelta.y > 0 ? 5 : -5
						bar.adjustVolume(delta)
					}
				}
			}
			Notch {
				natWidth: networkRow.width + bar.pad
				vert: Component {
					Column {
						spacing: 4
						Text {
							anchors.horizontalCenter: parent.horizontalCenter
							text: root.ethConnected ? "󰈀" : !bar.wifiConnected ? "󰤭" : bar.wifiStrength > 75 ? "󰤨" : bar.wifiStrength > 50 ? "󰤥" : bar.wifiStrength > 25 ? "󰤢" : "󰤟"
							color: root.ethConnected || bar.wifiConnected ? root.walColor2 : root.walColor8
							font.pixelSize: 14
							font.family: "JetBrainsMono Nerd Font"
						}
						Text {
							anchors.horizontalCenter: parent.horizontalCenter
							text: bar.btConnected ? "󰂱" : "󰂲"
							color: bar.btConnected ? root.walColor5 : root.walColor8
							font.pixelSize: 13
							font.family: "JetBrainsMono Nerd Font"
						}
					}
				}
				hovered: networkMA.containsMouse
				tooltip: {
					var t = ""
					if (bar.wifiConnected) t += bar.wifiSSID + " (" + bar.wifiStrength + "%)"
					else t += "Not connected"
					t += "\nBluetooth: " + (bar.btConnected ? "Connected" : "Off")
					return t
				}
				Item {
					anchors.fill: parent
					Row {
						id: networkRow
						anchors.centerIn: parent
						spacing: 8
						Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.ethConnected
        text: "󰈀"
        color: root.walColor2
        font.pixelSize: 14
        font.family: "JetBrainsMono Nerd Font"
    }
						Text {
							anchors.verticalCenter: parent.verticalCenter
							text: {
								if (!bar.wifiConnected) return "󰤭"
                                				if (bar.wifiStrength > 75) return "󰤨"
                                				if (bar.wifiStrength > 50) return "󰤥"
                                				if (bar.wifiStrength > 25) return "󰤢"
                                				return "󰤟"
							}
							color: bar.wifiConnected ? root.walColor2 : root.walColor8
                            				font.pixelSize: 14
                            				font.family: "JetBrainsMono Nerd Font"
							Behavior on color { 
								ColorAnimation { 
									duration: 300; 
									easing.type: Easing.OutCubic 
								} 
							}
						}
						Text {
							anchors.verticalCenter: parent.verticalCenter
							text: bar.btConnected ? "󰂱" : "󰂲"
                            				color: bar.btConnected ? root.walColor5 : root.walColor8
                            				font.pixelSize: 13
                            				font.family: "JetBrainsMono Nerd Font"
							Behavior on color { 
								ColorAnimation { 
									duration: 300; 
									easing.type: Easing.OutCubic 
								} 
							}
						}
					}
				}
				MouseArea {
					id: networkMA
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					acceptedButtons: Qt.LeftButton | Qt.RightButton
					onClicked: function(mouse) {
						if (mouse.button === Qt.RightButton)
						root.toggleBluetooth()
						else
						root.toggleWifi()
					}
				}
			}
			Notch {
				id: trayNotch
				visible: trayRow.implicitWidth > 0
				natWidth: visible ? trayRow.implicitWidth + bar.pad : 0
				hovered: false
				Behavior on natWidth {
					NumberAnimation {
						duration: 200
						easing.type: Easing.OutCubic
					}
				}

				property var stableTrayItems: []
				property int _lastCount: 0

				Connections {
					target: SystemTray.items
					function onValuesChanged() {
						traySnapshotTimer.restart()
					}
				}
				Timer {
					id: traySnapshotTimer
					interval: 1500
					repeat: false
					onTriggered: {
						  trayNotch.stableTrayItems = SystemTray.items.values.filter(function(item) {
        return item && item.id && item.id !== ""
    })
					}
				}
				Component.onCompleted: {
					trayNotch.stableTrayItems = SystemTray.items.values.slice()
				}

				Process {
					id: trayCleanupProc
					command: ["bash", "-c",
						"sleep 1 && " +
						"for name in $(qdbus 2>/dev/null | grep -E 'spotify|Spotify'); do " +
						"  qdbus $name / org.freedesktop.Application.Quit 2>/dev/null || true; " +
						"done"
					]
				}

				QsMenuAnchor {
					id: trayMenu
					anchor.window: bar
					anchor.rect: bar.vertical ? Qt.rect(bar.barPosition === "left" ? bar.width : 0, trayMenu.menuX, 1, 1) : Qt.rect(trayMenu.menuX, bar.barPosition === "top" ? bar.height : 0, 1, 1)
					property real menuX: 0
					onClosed: {
						traySnapshotTimer.restart()
						trayCleanupProc.running = true
					}
				}

				Item {
					anchors.fill: parent
					Row {
						id: trayRow
						anchors.centerIn: parent
						spacing: 6

						Repeater {
							model: trayNotch.stableTrayItems

							delegate: Item {
								id: trayDelegate
								required property SystemTrayItem modelData
								width: 20
								height: 20
								anchors.verticalCenter: parent ? parent.verticalCenter : undefined

								property string iconSrc: {
									var icon = trayDelegate.modelData?.icon ?? ""
									if (typeof icon !== "string") return ""
									if (icon.includes("?path=")) {
										var parts = icon.split("?path=")
										if (parts.length !== 2) return icon
										var name = parts[0]
										var path = parts[1]
										var file = name.substring(name.lastIndexOf("/") + 1)
										return "file://" + path + "/" + file
									}
									return icon
								}

								Rectangle {
									anchors.fill: parent
									radius: 4
									color: trayItemMa.containsMouse
										? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.2)
										: "transparent"
									Behavior on color {
										ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
									}
								}

								Image {
									rotation: trayNotch.rot ? -90 : 0
									anchors.centerIn: parent
									width: 14; height: 14
									source: trayDelegate.iconSrc
									fillMode: Image.PreserveAspectFit
									smooth: true; asynchronous: true; cache: true
									visible: status !== Image.Error
								}

								Text {
									anchors.centerIn: parent
									visible: trayDelegate.children[1].status === Image.Error
									text: "󰀻"
									color: root.walColor8
									font.pixelSize: 12
									font.family: "JetBrainsMono Nerd Font"
								}

								MouseArea {
									id: trayItemMa
									anchors.fill: parent
									hoverEnabled: true
									cursorShape: Qt.PointingHandCursor
									acceptedButtons: Qt.LeftButton | Qt.RightButton

									onClicked: function(mouse) {
										if (!trayDelegate.modelData) return
										if (mouse.button === Qt.LeftButton
												&& !trayDelegate.modelData.onlyMenu) {
											trayDelegate.modelData.activate()
											return
										}
										if (trayDelegate.modelData.hasMenu) {
											var mapped = trayItemMa.mapToItem(null, 0, 0)
											trayMenu.menu = trayDelegate.modelData.menu
											trayMenu.menuX = mapped.x + trayItemMa.width / 2
											trayMenu.open()
										}
									}

									onWheel: function(wheel) {
										if (trayDelegate.modelData)
											trayDelegate.modelData.activate()
									}
								}
							}
						}
					}
				}
			}
			Notch {
				id: pomoNotch
				natWidth: pomoRow.implicitWidth + bar.pad
				vert: Component {
					Column {
						spacing: 1
						Text {
							anchors.horizontalCenter: parent.horizontalCenter
							text: ""
							color: root.pomoActive || root.pomoVisible ? root.pomoColor : root.walColor13
							font.pixelSize: 14
							font.family: "JetBrainsMono Nerd Font"
						}
						Text { visible: root.pomoActive; anchors.horizontalCenter: parent.horizontalCenter; text: root.pomoText.split(":")[0]; color: root.pomoColor; font.pixelSize: 10; font.bold: true; font.family: "JetBrainsMono Nerd Font" }
						Text { visible: root.pomoActive; anchors.horizontalCenter: parent.horizontalCenter; text: root.pomoText.split(":")[1] || ""; color: root.pomoColor; opacity: 0.7; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font" }
						Rectangle {
							visible: root.pomoActive
							anchors.horizontalCenter: parent.horizontalCenter
							width: 3; height: 18; radius: 1.5
							color: root.card(0.4)
							Rectangle { anchors.bottom: parent.bottom; width: parent.width; radius: 1.5; height: parent.height * Math.max(0, 1 - root.pomoProgress); color: root.pomoColor }
						}
					}
				}
				hovered: pomoMA.containsMouse
				visible: !bar.enjoy
				tooltip: root.pomoActive
					? (root.pomoRunning ? "Pomodoro running" : "Pomodoro paused") + " · right-click start/pause"
					: "Pomodoro · right-click to start"
				Behavior on natWidth { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
				Item {
					anchors.fill: parent
					Row {
						id: pomoRow
						anchors.centerIn: parent
						spacing: 6
						Text {
							anchors.verticalCenter: parent.verticalCenter
							text: ""
							color: root.pomoActive || root.pomoVisible ? root.pomoColor : root.walColor13
							font.pixelSize: 14
							font.family: "JetBrainsMono Nerd Font"
							SequentialAnimation on rotation {
								running: root.pomoRunning && root.pomoRemaining <= 10
								loops: Animation.Infinite
								NumberAnimation { to: -12; duration: 60 }
								NumberAnimation { to: 12; duration: 120 }
								NumberAnimation { to: 0; duration: 60 }
							}
						}
						Text {
							visible: root.pomoActive
							anchors.verticalCenter: parent.verticalCenter
							text: root.pomoText
							color: root.pomoColor
							opacity: root.pomoRunning ? 1 : 0.6
							font.pixelSize: 11
							font.bold: true
							font.family: "JetBrainsMono Nerd Font"
						}
					}
					// burning fuse
					Rectangle {
						visible: root.pomoActive
						anchors.bottom: parent.bottom
						anchors.bottomMargin: 4
						anchors.horizontalCenter: parent.horizontalCenter
						width: pomoRow.implicitWidth
						height: 2
						radius: 1
						color: root.card(0.4)
						Rectangle {
							width: parent.width * Math.max(0, 1 - root.pomoProgress)
							height: parent.height
							radius: 1
							color: root.pomoColor
						}
					}
				}
				MouseArea {
					id: pomoMA
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
					onClicked: function(mouse) {
						if (mouse.button === Qt.RightButton) root.pomoStartPause()
						else if (mouse.button === Qt.MiddleButton) root.pomoReset()
						else root.togglePomodoro()
					}
					onWheel: function(wheel) {
						if (!root.pomoRunning) root.pomoAdjust(root.pomoPhase, wheel.angleDelta.y > 0 ? 1 : -1)
					}
				}
			}
			Notch {
				id: jarvisNotch
				natWidth: jarvisRow.implicitWidth + bar.pad
				vert: Component {
					Column {
						spacing: 2
						Text {
							anchors.horizontalCenter: parent.horizontalCenter
							text: "󰚩"
							color: !root.jarvisOnline ? root.walColor8 : (root.jarvisCritical ? root.walColor1 : (root.jarvisVisible ? root.walColor6 : root.walColor13))
							opacity: root.jarvisOnline ? 1 : 0.55
							font.pixelSize: 14
							font.family: "JetBrainsMono Nerd Font"
						}
						Rectangle {
							visible: root.jarvisOnline && root.jarvisBadge > 0
							anchors.horizontalCenter: parent.horizontalCenter
							width: 16; height: 14; radius: 7
							color: root.jarvisCritical ? root.walColor1 : root.walPeach
							Text { anchors.centerIn: parent; text: root.jarvisBadge > 9 ? "9+" : root.jarvisBadge; color: root.walBackground; font.pixelSize: 8; font.bold: true; font.family: "JetBrainsMono Nerd Font" }
						}
					}
				}
				hovered: jarvisMA.containsMouse
				visible: root.jarvisEnabled && (!bar.enjoy)
				tooltip: !root.jarvisOnline ? "Jarvis offline" + (root.jarvisError !== "" ? " · " + root.jarvisError : "")
					: (root.jarvisBadge > 0 ? root.jarvisBadge + " need" + (root.jarvisBadge === 1 ? "s" : "") + " attention" : "Jarvis · all clear")
					  + " · right-click timeline · middle-click dashboard"
				Behavior on natWidth { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
				Item {
					anchors.fill: parent
					Row {
						id: jarvisRow
						anchors.centerIn: parent
						spacing: 5
						Text {
							anchors.verticalCenter: parent.verticalCenter
							text: "󰚩"
							color: !root.jarvisOnline ? root.walColor8
								: (root.jarvisCritical ? root.walColor1 : (root.jarvisVisible ? root.walColor6 : root.walColor13))
							opacity: root.jarvisOnline ? 1 : 0.55
							font.pixelSize: 14
							font.family: "JetBrainsMono Nerd Font"
							SequentialAnimation on opacity {
								running: root.jarvisCritical
								loops: Animation.Infinite
								NumberAnimation { to: 0.35; duration: 600 }
								NumberAnimation { to: 1; duration: 600 }
							}
						}
						Rectangle {
							visible: root.jarvisOnline && root.jarvisBadge > 0
							anchors.verticalCenter: parent.verticalCenter
							width: Math.max(16, badgeText.implicitWidth + 8)
							height: 16
							radius: 8
							color: root.jarvisCritical ? root.walColor1 : root.walPeach
							Text {
								id: badgeText
								anchors.centerIn: parent
								text: root.jarvisBadge > 9 ? "9+" : root.jarvisBadge
								color: root.walBackground
								font.pixelSize: 9
								font.bold: true
								font.family: "JetBrainsMono Nerd Font"
							}
						}
					}
				}
				MouseArea {
					id: jarvisMA
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
					onClicked: function(mouse) {
						if (mouse.button === Qt.RightButton) root.toggleJarvisTimeline()
						else if (mouse.button === Qt.MiddleButton) root.jarvisOpenDashboard()
						else root.toggleJarvis()
					}
				}
			}
			Notch {
				id: recNotch
				natWidth: recRow.implicitWidth + bar.pad
				vert: Component {
					Column {
						spacing: 1
						Text {
							anchors.horizontalCenter: parent.horizontalCenter
							text: "󰑋"
							color: root.recording ? root.walColor1 : root.walColor13
							font.pixelSize: 14
							font.family: "JetBrainsMono Nerd Font"
						}
						Text { visible: root.recording; anchors.horizontalCenter: parent.horizontalCenter; text: root.recElapsedText.split(":")[0]; color: root.walColor1; font.pixelSize: 9; font.bold: true; font.family: "JetBrainsMono Nerd Font" }
						Text { visible: root.recording; anchors.horizontalCenter: parent.horizontalCenter; text: root.recElapsedText.split(":")[1] || ""; color: root.walColor1; opacity: 0.7; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font" }
					}
				}
				hovered: recMA.containsMouse
				visible: !bar.enjoy || root.recording
				tooltip: root.recording ? "Recording — click to stop" : "Screen recorder"
				Behavior on natWidth { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
				Item {
					anchors.fill: parent
					Row {
						id: recRow
						anchors.centerIn: parent
						spacing: 6
						Rectangle {
							visible: root.recording
							width: 8; height: 8; radius: 4
							anchors.verticalCenter: parent.verticalCenter
							color: root.walColor1
							SequentialAnimation on opacity {
								running: root.recording
								loops: Animation.Infinite
								NumberAnimation { to: 0.25; duration: 600; easing.type: Easing.InOutSine }
								NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
							}
						}
						Text {
							anchors.verticalCenter: parent.verticalCenter
							text: root.recording ? root.recElapsedText : "󰑋"
							color: root.recording ? root.walColor1 : (root.recordMenuVisible ? root.walColor1 : root.walColor13)
							font.pixelSize: root.recording ? 11 : 15
							font.bold: root.recording
							font.family: "JetBrainsMono Nerd Font"
						}
					}
				}
				MouseArea {
					id: recMA
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					acceptedButtons: Qt.LeftButton | Qt.RightButton
					onClicked: function(mouse) {
						if (root.recording && mouse.button === Qt.LeftButton) root.stopRecording()
						else root.toggleRecordMenu()
					}
				}
			}
			Notch {
				natWidth: bar.iconW
				hovered: stickyMA.containsMouse
				tooltip: root.notesVisible ? "Hide sticky notes" : "Sticky notes"
				Item {
					anchors.fill: parent
					Text {
						anchors.centerIn: parent
						text: "󰎚"
						color: root.notesVisible ? root.walColor4 : root.walColor13
						font.pixelSize: 15
						font.family: "JetBrainsMono Nerd Font"
					}
				}
				MouseArea {
					id: stickyMA
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: root.toggleNotes()
				}
			}
			Notch {
				natWidth: bar.iconW
      				hovered: clipMA.containsMouse
      				tooltip: "Clipboard · right-click for notes"
				Item {
					anchors.fill: parent
					Text {
						anchors.centerIn: parent
              				text: "󰅍"
              				color: root.walColor13
              				font.pixelSize: 15
              				font.family: "JetBrainsMono Nerd Font"
					}
				}
				MouseArea {
					id: clipMA
          				anchors.fill: parent
          				hoverEnabled: true
          				cursorShape: Qt.PointingHandCursor
          				acceptedButtons: Qt.LeftButton | Qt.RightButton
					onClicked: function(mouse) {
						if (mouse.button === Qt.RightButton) root.toggleNotes()
						else root.toggleClipboard()
					}
				}
			}
		Notch {
			natWidth: bar.iconW
			hovered: barMenuMA.containsMouse
			tooltip: "Bar & theme  ·  right-click: next theme"
			Item {
				anchors.fill: parent
				Text {
					anchors.centerIn: parent
					text: "󰏘"
					color: root.barMenuVisible ? root.walColor5 : root.walColor13
					font.pixelSize: 15
					font.family: "JetBrainsMono Nerd Font"
				}
			}
			MouseArea {
				id: barMenuMA
				anchors.fill: parent
				hoverEnabled: true
				cursorShape: Qt.PointingHandCursor
				acceptedButtons: Qt.LeftButton | Qt.RightButton
				onClicked: function(mouse) {
					if (mouse.button === Qt.RightButton) root.nextTheme()
					else root.barMenuVisible = !root.barMenuVisible
				}
			}
		}
		Notch {
			natWidth: bar.iconW
			hovered: dashMA.containsMouse
			tooltip: "Dashboard"
			Item {
				anchors.fill: parent
				Text {
					anchors.centerIn: parent
					text: "󰕮"
					color: root.walColor13
					font.pixelSize: 15
					font.family: "JetBrainsMono Nerd Font"
				}
			}
			MouseArea {
				id: dashMA
				anchors.fill: parent
				hoverEnabled: true
				cursorShape: Qt.PointingHandCursor
				acceptedButtons: Qt.LeftButton | Qt.RightButton
				onClicked: function(mouse) {
					if (mouse.button === Qt.RightButton)
					root.toggleNotifCenter()
					else
					root.toggleDashboard()
				}
			}
		}
	}
}
}
