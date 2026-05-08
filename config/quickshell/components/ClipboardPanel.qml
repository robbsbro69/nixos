import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: clipPanel
    screen: Quickshell.screens.length > 0 ? (root.focusedScreen ?? Quickshell.screens[0]) : undefined
    visible: true
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        right: true
        bottom: true
    }
    margins {
        top: 40
        bottom: 10
        right: root.clipboardVisible ? 6 : -420
    }
    implicitWidth: 390
    color: "transparent"
    focusable: true
    WlrLayershell.keyboardFocus: root.clipboardVisible
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    Behavior on margins.right {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

	property int    currentTab: 0
	property string searchText: ""

    property var    clipAllEntries: []
    property int    _thumbGen:     0

    FileView {
        id: emojiFile
        path: Quickshell.env("HOME") + "/.config/quickshell/files/emoji.json"
    }

    FileView {
        id: kaomojiFile
        path: Quickshell.env("HOME") + "/.config/quickshell/files/kaomoji.json"
    }

    readonly property var _emojiRaw: {
        const t = emojiFile.text()
        if (!t || !t.trim()) return {}
        try { return JSON.parse(t) } catch(e) { return {} }
    }

    readonly property var _kaoRaw: {
        const t = kaomojiFile.text()
        if (!t || !t.trim()) return []
        try { return JSON.parse(t) } catch(e) { return [] }
    }

    readonly property var emojiAllItems: {
        const out = []
        for (const emoji in _emojiRaw) {
            const entry = _emojiRaw[emoji]
            out.push({
                e:   emoji,
                n:   entry.name     ?? "",
                cat: entry.group    ?? ""
            })
        }
        return out
    }

    readonly property var kaoAllItems: {
        const out = []
        for (const group of _kaoRaw)
            for (const cat of group.categories)
                for (const text of cat.emoticons)
                    out.push({ t: text, group: group.name, cat: cat.name })
        return out
    }

    readonly property var clipFiltered: {
        const q = searchText.trim().toLowerCase()
        if (!q) return clipAllEntries
        return clipAllEntries.filter(function(e) {
            return e.preview.toLowerCase().indexOf(q) >= 0
        })
    }

    readonly property var emojiFiltered: {
        const q = searchText.trim().toLowerCase()
        if (!q) return emojiAllItems
        return emojiAllItems.filter(function(e) {
            return e.n.toLowerCase().indexOf(q)   >= 0 ||
                   e.cat.toLowerCase().indexOf(q) >= 0 ||
                   e.e === q
        })
    }

    readonly property var kaoFiltered: {
        const q = searchText.trim().toLowerCase()
        if (!q) return kaoAllItems
        return kaoAllItems.filter(function(e) {
            return e.t.toLowerCase().indexOf(q)     >= 0 ||
                   e.group.toLowerCase().indexOf(q) >= 0 ||
                   e.cat.toLowerCase().indexOf(q)   >= 0
        })
    }


    readonly property string _clipTmp: "/tmp/qs_cliplist.txt"

    FileView {
        id: clipDumpFile
        path: clipPanel._clipTmp
    }

    Process {
        id: loadClipboard
        command: ["bash", "-c", "cliphist list > " + clipPanel._clipTmp]
        running: false
        onExited: function(code) {
            if (code !== 0) {
                console.warn("cliphist list failed with code", code)
                return
            }
            clipDumpFile.reload()
            parseTimer.restart()
        }
    }

    Timer {
        id: parseTimer
        interval: 30
        repeat: false
        onTriggered: {
            const raw = clipDumpFile.text()
            if (!raw || !raw.trim()) return

            const lines = raw.split("\n").filter(function(l) {
                return l.trim() !== ""
            })
            const entries = lines.map(function(line, idx) {
                const tab     = line.indexOf("\t")
                const preview = tab === -1 ? line : line.substring(tab + 1).replace(/\s+/g, " ").trim()
                const isImg   = preview.startsWith("[[ binary") || preview.startsWith("[[ img")
                return {
                    lineIdx:   idx + 1,
                    preview:   isImg ? "Image" : preview,
                    isImage:   isImg,
                    thumbPath: isImg ? "/tmp/qs_clip_thumb_" + (idx + 1) + ".png" : ""
                }
            })
            clipPanel.clipAllEntries = entries

            const imgs = entries.filter(function(e) { return e.isImage }).slice(0, 20)
            if (imgs.length > 0) {
                const cmd = imgs.map(function(e) {
                    return "cliphist list | sed -n '" + e.lineIdx + "p' | cliphist decode > " + e.thumbPath
                }).join(" & ")
                thumbDecoder.command = ["bash", "-c", cmd + "; wait"]
                thumbDecoder.running = true
            }
        }
    }

    Process {
        id: thumbDecoder
        running: false
        onExited: {
            clipPanel._thumbGen++
            const tmp = clipPanel.clipAllEntries
            clipPanel.clipAllEntries = []
            clipPanel.clipAllEntries = tmp
        }
    }

    Process { id: pasteProcess; running: false }
    Process { id: copyProcess;  running: false }
    Process {
        id: wipeProcess
        command: ["bash", "-c", "cliphist wipe"]
        running: false
        onExited: {
            clipPanel.clipAllEntries = []
        }
    }

    Timer {
        id: reloadTimer
        interval: 0
        repeat: false
        onTriggered: { loadClipboard.running = true }
    }

    function reloadClipboard() {
        clipPanel.clipAllEntries = []
        loadClipboard.running = false
        reloadTimer.start()
    }

    function pasteClipEntry(entry) {
        if (!entry) return
        pasteProcess.command = ["bash", "-c",
            "cliphist list | sed -n '" + entry.lineIdx + "p' | cliphist decode | wl-copy"]
        pasteProcess.running = true
        root.clipboardVisible = false
    }

    function copyText(text) {
        const esc = text.replace(/'/g, "'\\''")
        copyProcess.command = ["bash", "-c", "printf '%s' '" + esc + "' | wl-copy"]
        copyProcess.running = true
        root.clipboardVisible = false
    }

    Item {
        anchors.fill: parent
        focus: root.clipboardVisible

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.clipboardVisible = false
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (clipPanel.currentTab === 0 && clipPanel.clipFiltered.length > 0)
                    clipPanel.pasteClipEntry(clipPanel.clipFiltered[Math.max(0, clipList.currentIndex)])
                else if (clipPanel.currentTab === 1 && clipPanel.emojiFiltered.length > 0)
                    clipPanel.copyText(clipPanel.emojiFiltered[Math.max(0, emojiGrid.currentIndex)].e)
                else if (clipPanel.currentTab === 2 && clipPanel.kaoFiltered.length > 0)
                    clipPanel.copyText(clipPanel.kaoFiltered[Math.max(0, kaoListView.currentIndex)].t)
                event.accepted = true
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.95)
            radius: 20

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "󰅍"
                        color: root.walColor5
                        font.pixelSize: 20
                        font.family: "JetBrainsMono Nerd Font"
                    }
                    Text {
                        text: clipPanel.currentTab === 0 ? "Clipboard"
                            : clipPanel.currentTab === 1 ? "Emoji"
                            :                              "Kaomoji"
                        color: root.walColor5
                        font.pixelSize: 15
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        visible: clipPanel.currentTab === 0 && clipPanel.clipAllEntries.length > 0
                        width: 28; height: 28; radius: 8
                        color: wipeMa.containsMouse
                            ? Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.2)
                            : "transparent"
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Text {
                            anchors.centerIn: parent
                            text: "󰩺"
                            color: wipeMa.containsMouse ? root.walColor1 : root.walColor8
                            font.pixelSize: 14
                            font.family: "JetBrainsMono Nerd Font"
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                        MouseArea {
                            id: wipeMa; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: wipeProcess.running = true
                            ToolTip.visible: containsMouse
                            ToolTip.text: "Wipe clipboard history"
                            ToolTip.delay: 500
                        }
                    }

                    Rectangle {
                        width: badgeText.implicitWidth + 10; height: 20; radius: 10
                        color: Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.2)
                        Text {
                            id: badgeText
                            anchors.centerIn: parent
                            text: clipPanel.currentTab === 0 ? clipPanel.clipFiltered.length
                                : clipPanel.currentTab === 1 ? clipPanel.emojiFiltered.length
                                : clipPanel.kaoFiltered.length
                            color: root.walColor5
                            font.pixelSize: 10
                            font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 10
                    color: Qt.rgba(0, 0, 0, 0.4)

                    Row {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 3

                        Repeater {
                            model: [
                                { label: "Clipboard", icon: "󰅍", idx: 0 },
                                { label: "Emoji",     icon: "󰞅", idx: 1 },
                                { label: "Kaomoji",   icon: "󰙃", idx: 2 }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                property bool active: clipPanel.currentTab === modelData.idx
                                width: (parent.width - 6) / 3
                                height: parent.height
                                radius: 8
                                color: active
                                    ? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.25)
                                    : tabHovMa.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 5
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.icon
                                        color: active ? root.walColor5 : root.walColor8
                                        font.pixelSize: 13
                                        font.family: "JetBrainsMono Nerd Font"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label
                                        color: active ? root.walColor5 : root.walColor8
                                        font.pixelSize: 11
                                        font.bold: active
                                        font.family: "JetBrainsMono Nerd Font"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                }
                                MouseArea {
                                    id: tabHovMa; anchors.fill: parent
                                    hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        clipPanel.currentTab = modelData.idx
                                        searchField.text = ""
                                        searchField.forceActiveFocus()
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 10
                    color: Qt.rgba(0, 0, 0, 0.5)
                    border.width: searchField.activeFocus ? 1 : 0
                    border.color: root.walColor5

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: ""
                            color: searchField.activeFocus ? root.walColor5 : root.walColor8
                            font.pixelSize: 14
                            font.family: "JetBrainsMono Nerd Font"
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        TextInput {
                            id: searchField
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: root.walForeground
                            font.pixelSize: 13
                            font.family: "JetBrainsMono Nerd Font"
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            clip: true

                            Text {
                                text: clipPanel.currentTab === 0 ? "Search clipboard…"
                                    : clipPanel.currentTab === 1 ? "Search emoji…"
                                    :                              "Search kaomoji…"
                                color: root.walColor8
                                visible: !parent.text
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                font: parent.font
                                opacity: 0.6
                            }

                            onTextChanged: {
                                clipPanel.searchText = text
                                clipList.currentIndex    = -1
                                emojiGrid.currentIndex   = -1
                                kaoListView.currentIndex = -1
                            }

                            Keys.onEscapePressed: root.clipboardVisible = false
                            Keys.onDownPressed: {
                                if (clipPanel.currentTab === 0)      clipList.forceActiveFocus()
                                else if (clipPanel.currentTab === 1) emojiGrid.forceActiveFocus()
                                else                                 kaoListView.forceActiveFocus()
                            }
                            Keys.onReturnPressed: {
                                if (clipPanel.currentTab === 0 && clipPanel.clipFiltered.length > 0)
                                    clipPanel.pasteClipEntry(clipPanel.clipFiltered[0])
                                else if (clipPanel.currentTab === 1 && clipPanel.emojiFiltered.length > 0)
                                    clipPanel.copyText(clipPanel.emojiFiltered[0].e)
                                else if (clipPanel.currentTab === 2 && clipPanel.kaoFiltered.length > 0)
                                    clipPanel.copyText(clipPanel.kaoFiltered[0].t)
                            }
                        }

                        Rectangle {
                            visible: searchField.text.length > 0
                            width: 22; height: 22; radius: 11
                            color: clrHovMa.containsMouse
                                ? Qt.rgba(1,1,1,0.1) : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text {
                                anchors.centerIn: parent; text: "󰅖"
                                color: root.walColor8
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"
                            }
                            MouseArea {
                                id: clrHovMa; anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: searchField.text = ""
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ListView {
                        id: clipList
                        anchors.fill: parent
                        visible: clipPanel.currentTab === 0
                        clip: true
                        spacing: 4
                        currentIndex: -1
                        boundsBehavior: Flickable.StopAtBounds
                        model: clipPanel.clipFiltered

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            contentItem: Rectangle {
                                implicitWidth: 3; radius: 2
                                color: root.walColor5
                                opacity: 0.5
                            }
                            background: Item {}
                        }

                        Keys.onReturnPressed: {
                            if (currentIndex >= 0)
                                clipPanel.pasteClipEntry(clipPanel.clipFiltered[currentIndex])
                        }
                        Keys.onEscapePressed: root.clipboardVisible = false
                        Keys.onUpPressed: {
                            if (currentIndex <= 0) searchField.forceActiveFocus()
                            else decrementCurrentIndex()
                        }

                        delegate: Item {
                            width: clipList.width
                            required property int index
                            property var  entry: clipPanel.clipFiltered[index]
                            property bool isHov: false
                            property bool isFoc: ListView.isCurrentItem

                            height: entry && entry.isImage
                                ? Math.min(clipList.width * 0.6, 180)
                                : Math.max(46, clipItemText.implicitHeight + 20)

                            Behavior on height { NumberAnimation { duration: 80 } }

                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                clip: true
                                color: isFoc
                                    ? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.18)
                                    : isHov ? Qt.rgba(1,1,1,0.06) : Qt.rgba(0,0,0,0.25)
                                border.width: isFoc ? 1 : 0
                                border.color: Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.5)
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Image {
                                    id: thumbImg
                                    anchors.fill: parent
                                    source: entry && entry.isImage && entry.thumbPath !== ""
                                        ? "file://" + entry.thumbPath + "?gen=" + clipPanel._thumbGen
                                        : ""
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true; mipmap: true; asynchronous: true; cache: false
                                    visible: entry && entry.isImage
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: "🖼"
                                    font.pixelSize: 26
                                    visible: entry && entry.isImage && thumbImg.status !== Image.Ready
                                }

                                Text {
                                    id: clipItemText
                                    visible: entry && !entry.isImage
                                    anchors {
                                        left: parent.left; right: parent.right
                                        leftMargin: 12; rightMargin: 12
                                        top: parent.top; topMargin: 10
                                    }
                                    text: entry ? entry.preview : ""
                                    font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                    color: isFoc ? root.walColor5 : root.walForeground
                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                    maximumLineCount: 6
                                    elide: Text.ElideRight
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: { isHov = true; clipList.currentIndex = index }
                                    onExited:  isHov = false
                                    onClicked: clipPanel.pasteClipEntry(clipPanel.clipFiltered[index])
                                }
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            visible: clipPanel.clipFiltered.length === 0
                            spacing: 8
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "󰅍"
                                color: root.walColor8
                                font.pixelSize: 28
                                font.family: "JetBrainsMono Nerd Font"
                                opacity: 0.3
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: clipPanel.clipAllEntries.length === 0
                                    ? "No clipboard history" : "No matches"
                                color: root.walColor8
                                font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"
                                opacity: 0.5
                            }
                        }
                    }

                    GridView {
                        id: emojiGrid
                        anchors.fill: parent
                        visible: clipPanel.currentTab === 1
                        clip: true
                        cellWidth: 52; cellHeight: 52
                        currentIndex: -1
                        boundsBehavior: Flickable.StopAtBounds
                        model: clipPanel.emojiFiltered

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            contentItem: Rectangle {
                                implicitWidth: 3; radius: 2
                                color: root.walColor5
                                opacity: 0.5
                            }
                            background: Item {}
                        }

                        Keys.onReturnPressed: {
                            if (currentIndex >= 0)
                                clipPanel.copyText(clipPanel.emojiFiltered[currentIndex].e)
                        }
                        Keys.onEscapePressed: root.clipboardVisible = false
                        Keys.onUpPressed: {
                            const cols = Math.max(1, Math.floor(emojiGrid.width / emojiGrid.cellWidth))
                            if (currentIndex < cols) searchField.forceActiveFocus()
                            else moveCurrentIndexUp()
                        }

                        delegate: Item {
                            width: emojiGrid.cellWidth; height: emojiGrid.cellHeight
                            required property int index
                            property var  item:  clipPanel.emojiFiltered[index]
                            property bool isHov: false
                            property bool isFoc: GridView.isCurrentItem

                            Rectangle {
                                anchors { fill: parent; margins: 3 }
                                radius: 10
                                color: isFoc
                                    ? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.2)
                                    : isHov ? Qt.rgba(1,1,1,0.08) : "transparent"
                                border.width: isFoc ? 1 : 0
                                border.color: Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.5)
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: item ? item.e : ""
                                    font.pixelSize: 24
                                    scale: isHov ? 1.2 : 1.0
                                    Behavior on scale {
                                        NumberAnimation { duration: 120; easing.type: Easing.OutBack }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: { isHov = true; emojiGrid.currentIndex = index }
                                onExited:  isHov = false
                                onClicked: {
                                    if (item) clipPanel.copyText(item.e)
                                }
                                ToolTip.visible: containsMouse && item
                                ToolTip.text:    item ? item.n + (item.cat ? "\n" + item.cat : "") : ""
                                ToolTip.delay:   500
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            visible: clipPanel.emojiFiltered.length === 0
                            spacing: 8
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "󰞅"
                                color: root.walColor8; font.pixelSize: 28
                                font.family: "JetBrainsMono Nerd Font"; opacity: 0.3
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No emoji found"
                                color: root.walColor8; font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"; opacity: 0.5
                            }
                        }
                    }

                    ListView {
                        id: kaoListView
                        anchors.fill: parent
                        visible: clipPanel.currentTab === 2
                        clip: true
                        spacing: 4
                        currentIndex: -1
                        boundsBehavior: Flickable.StopAtBounds
                        model: clipPanel.kaoFiltered

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            contentItem: Rectangle {
                                implicitWidth: 3; radius: 2
                                color: root.walColor5
                                opacity: 0.5
                            }
                            background: Item {}
                        }

                        Keys.onReturnPressed: {
                            if (currentIndex >= 0)
                                clipPanel.copyText(clipPanel.kaoFiltered[currentIndex].t)
                        }
                        Keys.onEscapePressed: root.clipboardVisible = false
                        Keys.onUpPressed: {
                            if (currentIndex <= 0) searchField.forceActiveFocus()
                            else decrementCurrentIndex()
                        }

                        delegate: Rectangle {
                            width: kaoListView.width; height: 44
                            radius: 10
                            required property int index
                            property var  item:  clipPanel.kaoFiltered[index]
                            property bool isHov: false
                            property bool isFoc: ListView.isCurrentItem

                            color: isFoc
                                ? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.18)
                                : isHov ? Qt.rgba(1,1,1,0.06) : Qt.rgba(0,0,0,0.2)
                            border.width: isFoc ? 1 : 0
                            border.color: Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.5)
                            Behavior on color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 10

                                Text {
                                    Layout.fillWidth: true
                                    text: item ? item.t : ""
                                    font.pixelSize: 14
                                    font.family: "JetBrainsMono Nerd Font"
                                    color: isFoc ? root.walColor5 : root.walForeground
                                    elide: Text.ElideRight
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }

                                Rectangle {
                                    visible: item && item.cat !== ""
                                    height: 18
                                    width: catLbl.implicitWidth + 12
                                    radius: 6
                                    color: Qt.rgba(0,0,0,0.3)
                                    Text {
                                        id: catLbl
                                        anchors.centerIn: parent
                                        text: item ? item.cat : ""
                                        font.pixelSize: 9
                                        font.family: "JetBrainsMono Nerd Font"
                                        color: root.walColor8
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: { isHov = true; kaoListView.currentIndex = index }
                                onExited:  isHov = false
                                onClicked: { if (item) clipPanel.copyText(item.t) }
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            visible: clipPanel.kaoFiltered.length === 0
                            spacing: 8
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "󰙃"
                                color: root.walColor8; font.pixelSize: 28
                                font.family: "JetBrainsMono Nerd Font"; opacity: 0.3
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No kaomoji found"
                                color: root.walColor8; font.pixelSize: 12
                                font.family: "JetBrainsMono Nerd Font"; opacity: 0.5
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    radius: 8
                    color: Qt.rgba(0, 0, 0, 0.3)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        Rectangle {
                            width: 5; height: 5; radius: 3
                            color: root.walColor5; opacity: 0.6
                        }
                        Text {
                            text: clipPanel.currentTab === 0
                                ? clipPanel.clipFiltered.length + " item" + (clipPanel.clipFiltered.length !== 1 ? "s" : "")
                                : clipPanel.currentTab === 1
                                ? clipPanel.emojiFiltered.length + " emoji"
                                : clipPanel.kaoFiltered.length + " kaomoji"
                            color: root.walColor8; font.pixelSize: 9
                            font.family: "JetBrainsMono Nerd Font"; opacity: 0.7
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: clipPanel.currentTab === 0 ? "↵ paste" : "↵ copy"
                            color: root.walColor8; font.pixelSize: 9
                            font.family: "JetBrainsMono Nerd Font"; opacity: 0.6
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "↑↓ nav"
                            color: root.walColor8; font.pixelSize: 9
                            font.family: "JetBrainsMono Nerd Font"; opacity: 0.6
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "esc close"
                            color: root.walColor8; font.pixelSize: 9
                            font.family: "JetBrainsMono Nerd Font"; opacity: 0.6
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: root
        function onClipboardVisibleChanged() {
            if (root.clipboardVisible) {
                clipPanel.currentTab = 0
                clipPanel.searchText = ""
                searchField.text     = ""
                clipPanel.reloadClipboard()
                focusTimer.start()
            }
        }
    }

    Timer {
        id: focusTimer; interval: 50; repeat: false
        onTriggered: {
            clipPanel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive
            releaseTimer.start()
        }
    }
    Timer {
        id: releaseTimer; interval: 100; repeat: false
        onTriggered: {
            searchField.forceActiveFocus()
            clipPanel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand
        }
    }
}
