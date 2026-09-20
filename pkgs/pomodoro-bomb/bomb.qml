import QtQuick
import QtQuick.Shapes
import QtQuick.Window

// bomb.qml — standalone pomodoro window, dynamite-bomb styled.
//
// Runs as its own top-level window (see main.py), not a Quickshell widget.
// Left-click  -> start / pause
// Right-click -> reset current phase
// Scroll      -> adjust minutes for the current phase while paused

Window {
    id: win
    width: 180
    height: 100
    minimumWidth: 180
    minimumHeight: 100
    maximumWidth: 180
    maximumHeight: 100
    visible: true
    title: "pomodoro"
    color: "transparent"
    flags: Qt.FramelessWindowHint

    // ---- Tunables -------------------------------------------------------
    property int workMinutes: 25
    property int breakMinutes: 5
    property bool festiveHat: false

    // ---- Catppuccin Mocha palette ----------------------------------------
    readonly property color base: "#1e1e2e"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color textCol: "#cdd6f4"
    readonly property color pink: "#f5c2e7"
    readonly property color mauve: "#cba6f7"
    readonly property color red: "#f38ba8"
    readonly property color peach: "#fab387"
    readonly property color yellow: "#f9e2af"
    readonly property color green: "#a6e3a1"

    // ---- State ------------------------------------------------------------
    property bool isBreak: false
    property bool running: false
    property int remainingSeconds: workMinutes * 60

    function phaseTotal() {
        return (isBreak ? breakMinutes : workMinutes) * 60
    }

    function fmt(s) {
        var m = Math.floor(s / 60)
        var sec = s % 60
        return (m < 10 ? "0" + m : m) + ":" + (sec < 10 ? "0" + sec : sec)
    }

    function reset() {
        remainingSeconds = phaseTotal()
        running = false
    }

    Timer {
        id: tick
        interval: 1000
        repeat: true
        running: win.running
        onTriggered: {
            if (win.remainingSeconds > 0) {
                win.remainingSeconds -= 1
            } else {
                win.isBreak = !win.isBreak
                win.remainingSeconds = win.phaseTotal()
                fuseFlash.start()
                notifyProxy.notifyPhaseChange(win.isBreak)
            }
        }
    }

    SequentialAnimation {
        id: fuseFlash
        loops: 2
        NumberAnimation { target: flashOverlay; property: "opacity"; to: 0.55; duration: 120 }
        NumberAnimation { target: flashOverlay; property: "opacity"; to: 0.0; duration: 220 }
    }

    Item {
        id: content
        width: 360
        height: 200
        scale: 0.5
        transformOrigin: Item.TopLeft

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                win.reset()
            } else {
                win.running = !win.running
            }
        }
        onWheel: function(wheel) {
            if (win.running) return
            var delta = wheel.angleDelta.y > 0 ? 1 : -1
            if (win.isBreak) {
                win.breakMinutes = Math.max(1, win.breakMinutes + delta)
            } else {
                win.workMinutes = Math.max(1, win.workMinutes + delta)
            }
            win.remainingSeconds = win.phaseTotal()
        }
    }

    // ---- Wires ------------------------------------------------------------
    Shape {
        anchors.fill: parent
        antialiasing: true
        ShapePath {
            strokeColor: win.yellow
            strokeWidth: 3
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 40; startY: 70
            PathCubic { x: 75; y: 10; control1X: 15; control1Y: 40; control2X: 30; control2Y: 5 }
            PathCubic { x: 115; y: 45; control1X: 105; control1Y: -5; control2X: 140; control2Y: 20 }
        }
        ShapePath {
            strokeColor: win.red
            strokeWidth: 3
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 175; startY: 50
            PathCubic { x: 195; y: 5; control1X: 175; control1Y: 20; control2X: 180; control2Y: -5 }
            PathCubic { x: 230; y: 38; control1X: 218; control1Y: 8; control2X: 235; control2Y: 20 }
        }
        ShapePath {
            strokeColor: win.green
            strokeWidth: 3
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: 205; startY: 52
            PathCubic { x: 245; y: 12; control1X: 215; control1Y: 25; control2X: 228; control2Y: 5 }
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
        id: housing
        width: 250
        height: 92
        radius: 9
        anchors.centerIn: sticks
        anchors.verticalCenterOffset: -8
        color: win.surface0
        border.color: win.surface1
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
                    width: 4; height: 4; radius: 2
                    color: index % 2 === 0 ? win.mauve : win.pink
                }
            }
        }

        Rectangle {
            id: led
            width: 13; height: 13; radius: 7
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 7
            color: win.red
            SequentialAnimation on opacity {
                running: win.running
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
            color: win.base
            border.color: "#000000"
            border.width: 1
            Text {
                anchors.centerIn: parent
                text: win.fmt(win.remainingSeconds)
                color: win.red
                font.family: "monospace"
                font.pixelSize: 32
                font.bold: true
            }
        }

        Text {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 4
            text: win.isBreak ? "BREAK" : (win.running ? "FOCUS" : "PAUSED · scroll to set")
            color: win.textCol
            font.pixelSize: 10
            font.letterSpacing: 1
        }
    }

    Shape {
        visible: win.festiveHat
        z: 3
        anchors.right: sticks.right
        anchors.top: sticks.top
        anchors.rightMargin: -4
        anchors.topMargin: -20
        width: 50
        height: 38
        antialiasing: true
        ShapePath {
            fillColor: win.red
            strokeColor: "transparent"
            startX: 4; startY: 34
            PathCubic { x: 38; y: 4; control1X: 10; control1Y: 12; control2X: 24; control2Y: 2 }
            PathLine { x: 44; y: 11 }
            PathCubic { x: 11; y: 38; control1X: 33; control1Y: 22; control2X: 22; control2Y: 34 }
            PathLine { x: 4; y: 34 }
        }
        ShapePath {
            fillColor: "#ffffff"
            strokeColor: "transparent"
            startX: 0; startY: 29
            PathLine { x: 15; y: 38 }
            PathLine { x: 13; y: 42 }
            PathLine { x: -2; y: 33 }
        }
    }

    Rectangle {
        id: flashOverlay
        anchors.fill: parent
        color: win.yellow
        opacity: 0.0
        z: 4
    }

    } // content

    // Bridge to Python for desktop notifications on phase change.
    // Connected from main.py via context property `notifyProxy`.
}
