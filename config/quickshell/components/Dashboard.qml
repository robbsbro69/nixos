import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: dashboard
    screen: root.focusedScreen ?? Quickshell.screens[0]  // add this
    visible: true
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; right: true }
    margins { top: 40; bottom: 10; right: root.dashboardVisible ? 6 : -450 }
    implicitWidth: 420
    color: "transparent"
    focusable: true
    WlrLayershell.keyboardFocus: root.dashboardVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    Behavior on margins.right { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    property int cpuVal: 0
    property int ramVal: 0
    property int diskVal: 0
    property int batVal: 100
    property int volVal: 50
    property int brightVal: 100
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
                    color: Qt.rgba(0, 0, 0, 0.5)
                    radius: 15
                    clip: true
                    property bool pfpPickerOpen: false
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
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
                            color: Qt.rgba(0, 0, 0, 0.5)
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
                                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
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
                                                    Behavior on border.color { ColorAnimation { duration: 150 } }
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
                        command: ["bash", "-c", "cp '" + selFile + "' " + dashboard.configPath + "/assets/pfps/pfp.jpg"]
                        onExited: {
                            pfpImage.reload()
                            profileSection.pfpPickerOpen = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    color: Qt.rgba(0, 0, 0, 0.5)
                    radius: 15
                    Row {
                        anchors.centerIn: parent
                        spacing: 25
                        PowerBtn { icon: "⏻"; iconColor: root.walColor2; cmd: "systemctl poweroff" }
                        PowerBtn { icon: "󰜉"; iconColor: root.walColor13; cmd: "systemctl reboot" }
                        PowerBtn { icon: "󰌾"; iconColor: root.walColor5; cmd: "hyprlock" }
                        PowerBtn { icon: "󰒲"; iconColor: root.walColor4; cmd: "systemctl suspend" }
                        PowerBtn { icon: "󰍃"; iconColor: root.walColor1; cmd: "hyprctl dispatch exit" }
                    }
	    }
	    Rectangle {
                    id: laptopScreenToggle
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    color: Qt.rgba(0, 0, 0, 0.5)
                    radius: 15

                    property bool laptopScreenEnabled: true

                    Component.onCompleted: checkScreenProc.running = true

                Process {
    id: checkScreenProc
    command: ["bash", "-c", "hyprctl monitors | grep -q '^Monitor eDP-1' && echo on || echo off"]
    stdout: SplitParser {
        onRead: data => {
            laptopScreenToggle.laptopScreenEnabled = data.trim() === "on"
        }
    }
}

Process {
    id: toggleScreenProc
    command: {
        if (laptopScreenToggle.laptopScreenEnabled)
            return ["bash", "-c", "hyprctl keyword monitor eDP-1,disable"]
        else
            return ["bash", "-c", "hyprctl keyword monitor eDP-1,1920x1080@60,0x0,1"]
    }
    onExited: {
        checkScreenProc.running = true
    }
}
Timer {
    interval: 1000
    running: root.dashboardVisible
    repeat: true
    triggeredOnStart: true
    onTriggered: {
        if (!checkScreenProc.running) checkScreenProc.running = true
    }
}

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 10

                        Text {
                            text: "󰍹"
                            color: laptopScreenToggle.laptopScreenEnabled ? root.walColor5 : root.walColor8
                            font.pixelSize: 18
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Text {
                            text: "Laptop Screen"
                            color: root.walForeground
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"
                            Layout.fillWidth: true
                        }

                        Text {
                            text: laptopScreenToggle.laptopScreenEnabled ? "ON" : "OFF"
                            color: laptopScreenToggle.laptopScreenEnabled ? root.walColor2 : root.walColor8
                            font.pixelSize: 10
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                        }

                        Rectangle {
                            width: 44
                            height: 24
                            radius: 12
                            color: laptopScreenToggle.laptopScreenEnabled ? root.walColor5 : Qt.rgba(0.3, 0.3, 0.3, 0.5)
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                width: 20
                                height: 20
                                radius: 10
                                y: 2
                                x: laptopScreenToggle.laptopScreenEnabled ? 22 : 2
                                color: root.walBackground
                                Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!toggleScreenProc.running)
                                        toggleScreenProc.running = true
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70
                    color: Qt.rgba(0, 0, 0, 0.5)
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
                    Layout.preferredHeight: 140
                    color: Qt.rgba(0, 0, 0, 0.5)
                    radius: 15
                    Row {
                        anchors.centerIn: parent
                        spacing: 30
                        CircularStat { label: "CPU"; icon: ""; barColor: root.walColor1; value: dashboard.cpuVal }
                        CircularStat { label: "RAM"; icon: ""; barColor: root.walColor5; value: dashboard.ramVal }
                        CircularStat { label: "DISK"; icon: ""; barColor: root.walColor4; value: dashboard.diskVal }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    color: Qt.rgba(0, 0, 0, 0.5)
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
                                color: Qt.rgba(0,0,0,0.3)
                                Rectangle {
                                    width: parent.width * dashboard.volVal / 100
                                    height: parent.height
                                    radius: 4
                                    color: root.walColor4
                                    Behavior on width { NumberAnimation { duration: 100 } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
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
                                Process { id: volSetProc }
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
                                color: Qt.rgba(0,0,0,0.3)
                                Rectangle {
                                    width: parent.width * dashboard.brightVal / 100
                                    height: parent.height
                                    radius: 4
                                    color: root.walColor13
                                    Behavior on width { NumberAnimation { duration: 100 } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        var percent = Math.round((mouse.x / parent.width) * 100)
                                        percent = Math.max(1, Math.min(100, percent))
                                        dashboard.brightVal = percent
                                        brightSetProc.command = ["bash", "-c", "brightnessctl set " + percent + "%"]
                                        brightSetProc.running = true
                                    }
                                    onPositionChanged: function(mouse) {
                                        if (pressed) {
                                            var percent = Math.round((mouse.x / parent.width) * 100)
                                            percent = Math.max(1, Math.min(100, percent))
                                            dashboard.brightVal = percent
                                            brightSetProc.command = ["bash", "-c", "brightnessctl set " + percent + "%"]
                                            brightSetProc.running = true
                                        }
                                    }
                                }
                                Process { id: brightSetProc }
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
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Qt.rgba(0, 0, 0, 0.5)
                    radius: 15
                    Column {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 10
                        Text {
                            id: timeDisplay
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "12:00:00 AM"
                            color: root.walColor5
                            font.pixelSize: 40
                            font.family: "JetBrainsMono Nerd Font"
                        }
                        Text {
                            id: dateDisplay
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "01.01.2026, Friday"
                            color: root.walForeground
                            font.pixelSize: 14
                            font.family: "JetBrainsMono Nerd Font"
                        }
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
        property string label
        property string icon
        property color barColor
        property int value
        width: 90
        height: 110
        Column {
            anchors.centerIn: parent
            spacing: 8
            Item {
                width: 70
                height: 70
                anchors.horizontalCenter: parent.horizontalCenter
                Canvas {
                    anchors.fill: parent
                    property int statValue: value
                    onStatValueChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        ctx.lineWidth = 5
                        ctx.lineCap = "round"
                        ctx.strokeStyle = Qt.rgba(0, 0, 0, 0.5)
                        ctx.beginPath()
                        ctx.arc(35, 35, 32, 0, 2 * Math.PI)
                        ctx.stroke()
                        ctx.strokeStyle = barColor
                        ctx.beginPath()
                        ctx.arc(35, 35, 32, -Math.PI / 2, -Math.PI / 2 + (statValue / 100) * 2 * Math.PI)
                        ctx.stroke()
                    }
                }
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: icon
                        color: barColor
                        font.pixelSize: 16
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: value + "%"
                        color: root.walForeground
                        font.pixelSize: 14
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: label
                color: root.walColor8
                font.pixelSize: 11
                font.family: "JetBrainsMono Nerd Font"
            }
        }
    }

    component PowerBtn: Rectangle {
        property string icon
        property color iconColor
        property string cmd
        width: 40
        height: 40
        radius: 10
        color: powerMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }
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
            onClicked: cmdProc.running = true
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
            timeDisplay.text = h + ':' + m + ':' + s + ' ' + ampm
            dateDisplay.text = Qt.formatDate(now, "dd.MM.yyyy, dddd")
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
        command: ["bash", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print int($2 + $4)}'"]
        stdout: SplitParser { onRead: data => dashboard.cpuVal = parseInt(data) || 0 }
    }
    Process {
        id: ramProc
        command: ["bash", "-c", "free | awk '/Mem:/ {printf \"%.0f\", $3/$2*100}'"]
        stdout: SplitParser { onRead: data => dashboard.ramVal = parseInt(data) || 0 }
    }
    Process {
        id: diskProc
        command: ["bash", "-c", "df / | awk 'NR==2 {gsub(/%/,\"\"); print $5}'"]
        stdout: SplitParser { onRead: data => dashboard.diskVal = parseInt(data) || 0 }
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
        stdout: SplitParser { onRead: data => dashboard.volVal = parseInt(data) || 0 }
    }
    Process {
        id: brightProc
        command: ["bash", "-c", "brightnessctl -m | awk -F, '{gsub(/%/,\"\"); print $4}'"]
        stdout: SplitParser { onRead: data => dashboard.brightVal = parseInt(data) || 100 }
    }
    Process {
        id: uptimeProc
        command: ["bash", "-c", "awk '{s=int($1); m=s/60; h=s/3600; d=s/86400; mo=s/2592000; if (mo>=1) printf \"up %d month%s %d day%s\", mo, (mo==1?\"\":\"s\"), (d%30), ((d%30)==1?\"\":\"s\"); else if (d>=1) printf \"up %d day%s %d hour%s\", d, (d==1?\"\":\"s\"), (h%24), ((h%24)==1?\"\":\"s\"); else if (h>=1) printf \"up %d hour%s %d min\", h, (h==1?\"\":\"s\"), (m%60); else printf \"up %d min\", m}' /proc/uptime"]
        stdout: SplitParser { onRead: data => uptimeText.text = data.trim() }
    }
}
