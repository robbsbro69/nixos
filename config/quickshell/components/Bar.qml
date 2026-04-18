import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

PanelWindow {
	id: bar
	visible: true
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell"
    anchors { top: true; left: true; right: true }
    margins { top: 0; left: 0; right: 0 }
    implicitHeight: 32
    color: "transparent"

    property color notchColor: Qt.rgba(0, 0, 0, 0.80)
    property color notchHoverColor: Qt.rgba(0, 0, 0, 0.90)
    property int notchRadius: 12
    property int notchHeight: 32

    property int activeWsId: 1
    property int targetWsId: 1
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

    SequentialAnimation {
        id: chargingPulseAnim
        running: bar.batteryCharging
        loops: Animation.Infinite
        NumberAnimation { target: bar; property: "chargingPulse"; to: 0.3; duration: 800; easing.type: Easing.InOutSine }
        NumberAnimation { target: bar; property: "chargingPulse"; to: 1; duration: 800; easing.type: Easing.InOutSine }
    }

    SequentialAnimation {
        id: chargingFillAnimSeq
        running: bar.batteryCharging
        loops: Animation.Infinite
        NumberAnimation { target: bar; property: "chargingFillAnim"; to: 1; duration: 2000; easing.type: Easing.InOutSine }
        NumberAnimation { target: bar; property: "chargingFillAnim"; to: 0; duration: 2000; easing.type: Easing.InOutSine }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "workspace") {
                var wsId = parseInt(event.data.trim())
                if (!isNaN(wsId)) {
                    bar.targetWsId = wsId
                    wsTransition.restart()
                }
            } else if (event.name === "focusedmon") {
                var parts = event.data.split(",")
                if (parts.length >= 2) {
                    var wsId = parseInt(parts[1])
                    if (!isNaN(wsId)) {
                        bar.targetWsId = wsId
                        wsTransition.restart()
                    }
                }
            }
        }
    }

    SequentialAnimation {
        id: wsTransition
        PropertyAnimation {
            target: wsHighlight
            property: "highlightOpacity"
            to: 0.4
            duration: 50
            easing.type: Easing.OutQuad
        }
        ScriptAction {
            script: bar.activeWsId = bar.targetWsId
        }
        ParallelAnimation {
            PropertyAnimation {
                target: wsHighlight
                property: "highlightOpacity"
                to: 1
                duration: 300
                easing.type: Easing.OutCubic
            }
            PropertyAnimation {
                target: wsHighlight
                property: "highlightScale"
                from: 0.9
                to: 1.0
                duration: 300
                easing.type: Easing.OutBack
                easing.overshoot: 1.5
            }
        }
    }

    Component.onCompleted: {
        if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace) {
            bar.activeWsId = Hyprland.focusedMonitor.activeWorkspace.id
            bar.targetWsId = bar.activeWsId
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!mediaProc.running) mediaProc.running = true }
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
        command: ["bash", "-c", "status=$(playerctl --player=%any status 2>/dev/null); pos=$(playerctl --player=%any position 2>/dev/null | cut -d. -f1); len=$(playerctl --player=%any metadata mpris:length 2>/dev/null); len=$((len / 1000000)); if [ \"$status\" = \"Playing\" ] || [ \"$status\" = \"Paused\" ]; then artist=$(playerctl --player=%any metadata artist 2>/dev/null); title=$(playerctl --player=%any metadata title 2>/dev/null); if [ -n \"$title\" ]; then text=\"$title\"; [ -n \"$artist\" ] && text=\"$artist - $title\"; if [ ${#text} -gt 35 ]; then text=\"${text:0:32}...\"; fi; echo \"$status|$text|$pos|$len\"; else echo 'stopped||0|0'; fi; else echo 'stopped||0|0'; fi"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split("|")
                if (parts.length >= 4) {
                    bar.mediaClass = parts[0].toLowerCase()
                    bar.mediaText = parts[1]
                    bar.mediaPosition = parseInt(parts[2]) || 0
                    bar.mediaLength = parseInt(parts[3]) || 0
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
        onTriggered: { if (!volumeProc.running) volumeProc.running = true }
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
        onTriggered: { if (!networkProc.running) networkProc.running = true }
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
        onTriggered: { if (!batteryProc.running) batteryProc.running = true }
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
        onExited: { if (!volumeProc.running) volumeProc.running = true }
    }

    Process {
        id: mediaPlayPauseProc
        command: ["playerctl", "play-pause"]
        onExited: { if (!mediaProc.running) mediaProc.running = true }
    }

    Process {
        id: mediaNextProc
        command: ["playerctl", "next"]
        onExited: { if (!mediaProc.running) mediaProc.running = true }
    }

    Process {
        id: mediaPrevProc
        command: ["playerctl", "previous"]
        onExited: { if (!mediaProc.running) mediaProc.running = true }
    }

    component Notch: Item {
        id: notchRoot
        property bool hovered: false
        property string tooltip: ""
        default property alias content: contentItem.data

        height: bar.notchHeight

        Item {
            anchors.fill: parent
            anchors.bottomMargin: 4
            clip: true

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: -bar.notchRadius
                width: parent.width
                height: parent.height + bar.notchRadius
                radius: bar.notchRadius
                antialiasing: true

                gradient: Gradient {
                    GradientStop { position: 0.0; color: notchRoot.hovered ? Qt.rgba(0, 0, 0, 0.45) : Qt.rgba(0, 0, 0, 0.30) }
                    GradientStop { position: 1.0; color: notchRoot.hovered ? bar.notchHoverColor : bar.notchColor }
                }
            }
        }

        Rectangle {
            id: tooltipBg
            visible: notchRoot.hovered && notchRoot.tooltip !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: 4
            width: tooltipText.implicitWidth + 16
            height: tooltipText.implicitHeight + 8
            radius: 6
            color: Qt.rgba(0, 0, 0, 0.85)
            opacity: visible ? 1 : 0
            z: 1000

            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            Text {
                id: tooltipText
                anchors.centerIn: parent
                text: notchRoot.tooltip
                color: root.walForeground
                font.pixelSize: 10
                font.family: "JetBrainsMono Nerd Font"
            }
        }

        Item {
            id: contentItem
            anchors.fill: parent
            anchors.bottomMargin: 4
        }
    }

    Item {
        anchors.fill: parent

        Row {
            id: leftSection
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 8
            height: bar.notchHeight
            spacing: 6

            Notch {
                width: 36
                hovered: appsMA.containsMouse
                tooltip: "Apps / Wallpapers"

                Item {
                    anchors.fill: parent

                    Text {
                        anchors.centerIn: parent
                        text: "󱄅"
                        color: root.walColor1
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
                            else { root.activeTab = 1; if (!root.wallsLoaded) root.loadWallpapers() }
                        } else {
                            root.activeTab = 0
                            root.toggleLauncher()
                        }
                    }
                }
            }

            Notch {
                width: clockLabel.implicitWidth + 24
                hovered: clockMA.containsMouse
                tooltip: Qt.formatDateTime(new Date(), "dddd, MMMM d, yyyy")

                Item {
                    anchors.fill: parent

                    Text {
                        id: clockLabel
                        anchors.centerIn: parent
                        text: Qt.formatDateTime(new Date(), "hh:mm AP")
                        color: root.walColor5
                        font.pixelSize: 11
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                MouseArea {
                    id: clockMA
                    anchors.fill: parent
                    hoverEnabled: true
                }

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    triggeredOnStart: true
                    onTriggered: clockLabel.text = Qt.formatDateTime(new Date(), "hh:mm AP")
                }
            }

            Notch {
                id: workspacesNotch
                width: wsContainer.width + 20

                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                Item {
                    anchors.fill: parent

                    Item {
                        id: wsContainer
                        anchors.centerIn: parent
                        width: wsRow.width
                        height: 18

                        Rectangle {
                            id: wsHighlight
                            height: 18
                            radius: 9

                            property real targetX: 0
                            property real targetWidth: 26
                            property real highlightOpacity: 1.0
                            property real highlightScale: 1.0

                            x: targetX
                            width: targetWidth
                            opacity: highlightOpacity
                            scale: highlightScale
                            transformOrigin: Item.Center
                            color: root.walColor13
                            antialiasing: true

                            Behavior on x {
                                NumberAnimation {
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on width {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Row {
                            id: wsRow
                            anchors.centerIn: parent
                            spacing: 4

                            Repeater {
                                id: wsRepeater
                                model: Hyprland.workspaces

                                delegate: Item {
                                    id: wsDelegate
                                    required property var modelData
                                    property bool isActive: bar.activeWsId === modelData.id
                                    property bool isHovered: wsMA.containsMouse

                                    visible: modelData.id > 0
                                    width: Math.max(wsText.implicitWidth + 14, 26)
                                    height: 18

                                    onIsActiveChanged: updateHighlight()
                                    onXChanged: if (isActive) updateHighlight()
                                    onWidthChanged: if (isActive) updateHighlight()
                                    Component.onCompleted: if (isActive) updateHighlight()

                                    function updateHighlight() {
                                        if (isActive) {
                                            wsHighlight.targetX = x
                                            wsHighlight.targetWidth = width
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 9
                                        color: isHovered && !isActive ? Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.3) : "transparent"
                                        antialiasing: true
                                        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                    }

                                    Text {
                                        id: wsText
                                        anchors.centerIn: parent
                                        text: modelData.name || modelData.id.toString()
                                        color: isActive ? root.walBackground : (isHovered ? root.walForeground : Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.5))
                                        font.pixelSize: 10
                                        font.bold: true
                                        font.family: "JetBrainsMono Nerd Font"

                                        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                    }

                                    MouseArea {
                                        id: wsMA
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Hyprland.dispatch("workspace " + modelData.id)
                                    }
                                }
                            }
                        }

                        Connections {
                            target: bar
                            function onActiveWsIdChanged() {
                                for (var i = 0; i < wsRepeater.count; i++) {
                                    var item = wsRepeater.itemAt(i)
                                    if (item && item.isActive) {
                                        item.updateHighlight()
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Notch {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: bar.mediaText !== "" ? mediaContent.width + 28 : 0
            visible: bar.mediaText !== ""
            hovered: mediaMA.containsMouse
            tooltip: bar.mediaText

            Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

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

                                        Behavior on height { NumberAnimation { duration: 60; easing.type: Easing.OutQuad } }
                                    }
                                }
                            }
                        }

                        Text {
                            id: mediaLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: bar.mediaText
                            color: root.walColor2
                            font.pixelSize: 10
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            opacity: bar.mediaClass === "playing" ? 1.0 : 0.7

                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 0
                                verticalOffset: 1
                                radius: 4
                                samples: 9
                                spread: 0.2
                                color: Qt.rgba(0, 0, 0, 0.8)
                                transparentBorder: true
                            }

                            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        }
                    }

                    Rectangle {
                        width: mediaContent.width
                        height: 3
                        radius: 1.5
                        color: Qt.rgba(0, 0, 0, 0.4)
                        visible: bar.mediaLength > 0

                        Rectangle {
                            width: bar.mediaLength > 0 ? parent.width * (bar.mediaPosition / bar.mediaLength) : 0
                            height: parent.height
                            radius: 1.5
                            color: root.walColor2

                            layer.enabled: true
                            layer.effect: Glow {
                                radius: 3
                                samples: 7
                                color: root.walColor2
                                transparentBorder: true
                            }

                            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.Linear } }
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

        Row {
            id: rightSection
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 8
            height: bar.notchHeight
            spacing: 6

            Notch {
                width: batteryRow.width + 24
                hovered: batteryMA.containsMouse
                tooltip: {
                    var t = bar.batteryPercent + "%"
                    if (bar.batteryCharging) t += " (Charging)"
                    if (bar.batteryTime) t += " - " + bar.batteryTime
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

                                Behavior on border.color { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }

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

                                    Behavior on width { NumberAnimation { duration: bar.batteryCharging ? 50 : 600; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
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

                                Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
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

                            Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                MouseArea {
                    id: batteryMA
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }

            Notch {
                width: volumeLabel.implicitWidth + 24
                hovered: volumeMA.containsMouse
                tooltip: bar.volumeMuted ? "Muted" : (bar.volumePercent + "%")

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

                        Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }
                }

                MouseArea {
                    id: volumeMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (!volumeToggleProc.running) volumeToggleProc.running = true }
                    onWheel: function(wheel) {
                        var delta = wheel.angleDelta.y > 0 ? 5 : -5
                        bar.adjustVolume(delta)
                    }
                }
            }

            Notch {
                width: networkRow.width + 24
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

                            Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: bar.btConnected ? "󰂱" : "󰂲"
                            color: bar.btConnected ? root.walColor5 : root.walColor8
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"

                            Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutCubic } }
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
                width: 36
                hovered: dashMA.containsMouse
                tooltip: "Dashboard"

                Item {
                    anchors.fill: parent

                    Text {
                        anchors.centerIn: parent
                        text: "󰕮"
                        color: root.walColor1
                        font.pixelSize: 15
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                MouseArea {
                    id: dashMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleDashboard()
                }
            }
        }
    }
}
