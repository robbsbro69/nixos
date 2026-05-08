import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../services"

PanelWindow {
    id: animePanel
	screen: Quickshell.screens.length > 0 ? (root.focusedScreen ?? Quickshell.screens[0]) : undefined
	visible: true
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; left: true; bottom: true }
    margins {
        top: 40; bottom: 10
        left: root.animePanelVisible ? 6 : -560
    }
    implicitWidth: 530
    color: "transparent"
    focusable: true
    WlrLayershell.keyboardFocus: root.animePanelVisible
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Behavior on margins.left {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    // ── Main tabs: 0=Anime 1=Manga 2=Personal ──────────────────────────────
    property int mainTab: 0

    // ── Anime browse state ─────────────────────────────────────────────────
    property int browseStack: 0      // 0=grid  1=detail  2=library
    property int animeChip: 0

    // ── Manga browse state ─────────────────────────────────────────────────
    property int mangaStack: 0       // 0=grid  1=detail  2=library
    property int mangaOriginTab: 0
    property bool mangaInitialized: false

    // ── Status picker overlay (shared for anime + manga) ───────────────────
    property bool statusPickerOpen: false
    property string statusPickerFor: "anime"   // "anime" | "manga"
    property var statusPickerItem: null         // the show/manga object

    // ── AniList personal (My Lists tab) ────────────────────────────────────
    property string anilistUsername: "robbsbro69"
    property bool   usernameEditing: false
    property string usernameInput:   "robbsbro69"
    property string personalMediaKind: "ANIME"
    property string personalStatus: "CURRENT"
    property list<var> personalItems: []
    property bool isFetchingPersonal: false
    property string personalError: ""

    // ── Status definitions ─────────────────────────────────────────────────
    readonly property var animeStatuses: [
        { key: "watching",   label: "Watching",    icon: "󰐊", color: "#89b4fa" },
        { key: "completed",  label: "Completed",   icon: "󰄬", color: "#a6e3a1" },
        { key: "planning",   label: "Planning",    icon: "󰃯", color: "#f5c2e7" },
        { key: "on_hold",    label: "On Hold",     icon: "⏸", color: "#f9e2af" },
        { key: "dropped",    label: "Dropped",     icon: "󰅖", color: "#f38ba8" },
        { key: "rewatching", label: "Rewatching",  icon: "󰑓", color: "#89b4fa" }
    ]
    readonly property var mangaStatuses: [
        { key: "reading",    label: "Reading",     icon: "󰐊", color: "#89b4fa" },
        { key: "completed",  label: "Completed",   icon: "󰄬", color: "#a6e3a1" },
        { key: "planning",   label: "Planning",    icon: "󰃯", color: "#f5c2e7" },
        { key: "on_hold",    label: "On Hold",     icon: "⏸", color: "#f9e2af" },
        { key: "dropped",    label: "Dropped",     icon: "󰅖", color: "#f38ba8" },
        { key: "rereading",  label: "Rereading",   icon: "󰑓", color: "#89b4fa" }
    ]

    // AniList personal tab labels (uses AniList status names)
    readonly property var alAnimeLabels: ({
        "CURRENT":   { label: "Watching",   icon: "󰐊", color: "walColor5"  },
        "COMPLETED": { label: "Completed",  icon: "󰄬", color: "walColor2"  },
        "PLANNING":  { label: "Planning",   icon: "󰃯", color: "walColor13" },
        "PAUSED":    { label: "On Hold",    icon: "⏸", color: "walColor4"  },
        "DROPPED":   { label: "Dropped",    icon: "󰅖", color: "walColor1"  },
        "REPEATING": { label: "Rewatching", icon: "󰑓", color: "walColor5"  }
    })
    readonly property var alMangaLabels: ({
        "CURRENT":   { label: "Reading",   icon: "󰐊", color: "walColor5"  },
        "COMPLETED": { label: "Completed", icon: "󰄬", color: "walColor2"  },
        "PLANNING":  { label: "Planning",  icon: "󰃯", color: "walColor13" },
        "PAUSED":    { label: "On Hold",   icon: "⏸", color: "walColor4"  },
        "DROPPED":   { label: "Dropped",   icon: "󰅖", color: "walColor1"  },
        "REPEATING": { label: "Rereading", icon: "󰑓", color: "walColor5"  }
    })

    function statusColor(key, isAnime) {
        var list = isAnime ? animeStatuses : mangaStatuses
        for (var i = 0; i < list.length; i++)
            if (list[i].key === key) return list[i].color
        return root.walColor8
    }

    function alStatusColor(status) {
        var labels = personalMediaKind === "MANGA" ? alMangaLabels : alAnimeLabels
        var entry  = labels[status]
        if (!entry) return root.walColor8
        return root[entry.color] || root.walColor8
    }

    function fetchPersonalList() {
        if (!anilistUsername || isFetchingPersonal) return
        isFetchingPersonal = true
        personalItems      = []
        personalError      = ""
        var url = Anime.apiUrl + "/userlist?username=" + encodeURIComponent(anilistUsername)
            + "&status=" + personalStatus + "&type=" + personalMediaKind
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            isFetchingPersonal = false
            if (xhr.status === 200) {
                try {
                    var d = JSON.parse(xhr.responseText)
                    if (d.error) { personalError = d.error; return }
                    personalItems = d.entries || []
                } catch(e) { personalError = "Parse error" }
            } else { personalError = "HTTP " + xhr.status }
        }
        xhr.open("GET", url); xhr.send()
    }

    onPersonalStatusChanged:    { if (mainTab === 2) fetchPersonalList() }
    onPersonalMediaKindChanged: { if (mainTab === 2) fetchPersonalList() }

    onMainTabChanged: {
        if (mainTab === 1 && !mangaInitialized) {
            mangaInitialized = true
            Manga.fetchByOrigin("", true)
        }
        if (mainTab === 2 && personalItems.length === 0) fetchPersonalList()
    }

    // ── Open status picker ─────────────────────────────────────────────────
    function openStatusPicker(item, forType) {
        statusPickerItem  = item
        statusPickerFor   = forType
        statusPickerOpen  = true
    }

    // ── Main background ────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent; radius: 20
        color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.97)

        // ── Status picker overlay ──────────────────────────────────────────
        Rectangle {
            id: statusPickerOverlay
            visible: animePanel.statusPickerOpen
            z: 300
            anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 50 }
			width: 240; height: spCol.implicitHeight + 20
			anchors.horizontalCenter: parent.horizontalCenter
            radius: 14
            color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.98)
            border.color: animePanel.statusPickerFor === "anime"
                ? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.4)
                : Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.4)
            border.width: 1
            MouseArea { anchors.fill: parent }   // eat clicks

            Column {
                id: spCol
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 10 }
                spacing: 4

                Row {
                    width: parent.width; height: 30
                    Text {
                        text: animePanel.statusPickerFor === "anime" ? "Add Anime to Library" : "Add Manga to Library"
                        color: animePanel.statusPickerFor === "anime" ? root.walColor5 : root.walColor13
                        font.pixelSize: 11; font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 30
                    }
                    Item { width: 26; height: 26
                        Rectangle { anchors.fill: parent; radius: 13
                            color: spCloseMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent" }
                        Text { anchors.centerIn: parent; text: "󰅖"; font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"; color: root.walColor8 }
                        MouseArea { id: spCloseMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: animePanel.statusPickerOpen = false }
                    }
                }

                // If already in library, show current status + remove option
                Rectangle {
                    width: parent.width; height: 30; radius: 8; color: Qt.rgba(0,0,0,0.2)
                    visible: {
                        if (!animePanel.statusPickerItem) return false
                        return animePanel.statusPickerFor === "anime"
                            ? Anime.isInLibrary(animePanel.statusPickerItem.id)
                            : Manga.isInLibrary(animePanel.statusPickerItem.id)
                    }
                    property string curSt: {
                        if (!animePanel.statusPickerItem) return ""
                        return animePanel.statusPickerFor === "anime"
                            ? Anime.getLibraryStatus(animePanel.statusPickerItem.id)
                            : Manga.getLibraryStatus(animePanel.statusPickerItem.id)
                    }
                    Row { anchors { fill: parent; leftMargin: 10; rightMargin: 10 } spacing: 8
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "Current: "
                            font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; color: root.walColor8 }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: parent.parent.curSt
                            font.pixelSize: 10; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                            color: animePanel.statusPickerFor === "anime" ? root.walColor5 : root.walColor13 }
                    }
                }

                Repeater {
                    model: animePanel.statusPickerFor === "anime" ? animePanel.animeStatuses : animePanel.mangaStatuses
                    Rectangle {
                        width: parent.width; height: 36; radius: 8
                        property bool isActive: {
                            if (!animePanel.statusPickerItem) return false
                            var curSt = animePanel.statusPickerFor === "anime"
                                ? Anime.getLibraryStatus(animePanel.statusPickerItem.id)
                                : Manga.getLibraryStatus(animePanel.statusPickerItem.id)
                            return curSt === modelData.key
                        }
                        color: isActive
                            ? Qt.rgba(0.5, 0.5, 0.5, 0.25)
                            : spItemMa.containsMouse ? Qt.rgba(1,1,1,0.07) : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Row { anchors { fill: parent; leftMargin: 12; rightMargin: 12 } spacing: 10
                            Text { anchors.verticalCenter: parent.verticalCenter
                                text: modelData.icon; font.pixelSize: 14
                                font.family: "JetBrainsMono Nerd Font"
                                color: modelData.color }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.label
                                font.pixelSize: 12; font.bold: isActive
                                font.family: "JetBrainsMono Nerd Font"; color: root.walForeground }
                            Text { anchors.verticalCenter: parent.verticalCenter; visible: isActive
                                text: "󰄬"; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                                color: root.walColor2 }
                        }
                        MouseArea { id: spItemMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!animePanel.statusPickerItem) return
                                var item = animePanel.statusPickerItem
                                if (animePanel.statusPickerFor === "anime") {
                                    if (isActive) Anime.updateLibraryStatus(item.id, modelData.key)
                                    else Anime.addToLibrary(item, modelData.key)
                                } else {
                                    if (isActive) Manga.updateLibraryStatus(item.id, modelData.key)
                                    else Manga.addToLibrary(item, modelData.key)
                                }
                                animePanel.statusPickerOpen = false
                            }
                        }
                    }
                }

                // Remove from library
                Rectangle {
                    width: parent.width; height: 32; radius: 8
                    visible: {
                        if (!animePanel.statusPickerItem) return false
                        return animePanel.statusPickerFor === "anime"
                            ? Anime.isInLibrary(animePanel.statusPickerItem.id)
                            : Manga.isInLibrary(animePanel.statusPickerItem.id)
                    }
                    color: spRemMa.containsMouse ? Qt.rgba(root.walColor1.r,root.walColor1.g,root.walColor1.b,0.15) : "transparent"
                    Row { anchors { fill: parent; leftMargin: 12 } spacing: 8
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "󰅖"
                            font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"; color: root.walColor1 }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "Remove from Library"
                            font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: root.walColor1 }
                    }
                    MouseArea { id: spRemMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!animePanel.statusPickerItem) return
                            if (animePanel.statusPickerFor === "anime")
                                Anime.removeFromLibrary(animePanel.statusPickerItem.id)
                            else
                                Manga.removeFromLibrary(animePanel.statusPickerItem.id)
                            animePanel.statusPickerOpen = false
                        }
                    }
                }
                Item { height: 4 }
            }
        }

        // Close status picker on background click
        MouseArea {
            anchors.fill: parent; z: 200
            visible: animePanel.statusPickerOpen
            onClicked: animePanel.statusPickerOpen = false
        }

        ColumnLayout {
            anchors.fill: parent; spacing: 0

            // ── Header bar ─────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true; height: 44
                color: Qt.rgba(0,0,0,0.4); radius: 20
                Rectangle { anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    height: 20; color: parent.color }
                RowLayout {
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 } spacing: 6

                    Item { width: 30; height: 30
                        Text { anchors.centerIn: parent; text: "󰅖"; font.pixelSize: 14
                            font.family: "JetBrainsMono Nerd Font"
                            color: closeMa.containsMouse ? root.walColor1 : root.walColor8
                            Behavior on color { ColorAnimation { duration: 150 } } }
                        MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.animePanelVisible = false }
                    }

                    Text {
                        text: animePanel.mainTab === 0 ? "Anime"
                            : animePanel.mainTab === 1 ? "Manga" : "My Lists"
                        font.pixelSize: 14; font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        color: animePanel.mainTab === 0 ? root.walColor5
                             : animePanel.mainTab === 1 ? root.walColor13
                             : root.walColor2
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    // Server status dots
                    Row { spacing: 4
                        Rectangle { width: 7; height: 7; radius: 3.5
                            color: Anime.serverReady ? root.walColor2 : root.walColor1
                            Behavior on color { ColorAnimation { duration: 400 } } }
                        Rectangle { width: 7; height: 7; radius: 3.5
                            visible: animePanel.mainTab === 1
                            color: Manga.serverReady ? root.walColor2 : root.walColor1
                            Behavior on color { ColorAnimation { duration: 400 } } }
                    }

                    Item { Layout.fillWidth: true }

                    // Sub/Dub toggle (anime tab)
                    Row { spacing: 4; visible: animePanel.mainTab === 0
                        Repeater {
                            model: ["sub", "dub"]
                            Rectangle {
                                width: modeLabel.implicitWidth + 16; height: 24; radius: 12
                                color: Anime.currentMode === modelData
                                    ? Qt.rgba(root.walColor5.r,root.walColor5.g,root.walColor5.b,0.3)
                                    : Qt.rgba(0,0,0,0.3)
                                border.color: Anime.currentMode === modelData ? root.walColor5 : "transparent"
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Text { id: modeLabel; anchors.centerIn: parent
                                    text: modelData.toUpperCase(); font.pixelSize: 10; font.bold: true
                                    font.family: "JetBrainsMono Nerd Font"
                                    color: Anime.currentMode === modelData ? root.walColor5 : root.walColor8 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: Anime.setMode(modelData) }
                            }
                        }
                    }

                    // Main tabs
                    Row { spacing: 4
                        Repeater {
                            model: [
                                { label: "Anime",    idx: 0, icon: "󰎁" },
                                { label: "Manga",    idx: 1, icon: "󰂿" },
                                { label: "My Lists", idx: 2, icon: "󰋑" }
                            ]
                            Rectangle {
                                width: mainTabRow.implicitWidth + 20; height: 28; radius: 10
                                color: animePanel.mainTab === modelData.idx
                                    ? Qt.rgba(root.walColor5.r,root.walColor5.g,root.walColor5.b,0.2)
                                    : "transparent"
                                border.width: animePanel.mainTab === modelData.idx ? 1 : 0
                                border.color: root.walColor5
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Row { id: mainTabRow; anchors.centerIn: parent; spacing: 5
                                    Text { anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.icon; font.pixelSize: 11
                                        font.family: "JetBrainsMono Nerd Font"
                                        color: animePanel.mainTab === modelData.idx ? root.walColor5 : root.walColor8 }
                                    Text { anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label; font.pixelSize: 11
                                        font.bold: animePanel.mainTab === modelData.idx
                                        font.family: "JetBrainsMono Nerd Font"
                                        color: animePanel.mainTab === modelData.idx ? root.walColor5 : root.walColor8 }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: animePanel.mainTab = modelData.idx }
                            }
                        }
                    }
                }
            }

            // ── Content area ───────────────────────────────────────────────
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true

                // ════════════════════════════════════════════════════════════
                // TAB 0 — ANIME
                // ════════════════════════════════════════════════════════════
                Item {
                    anchors.fill: parent; visible: animePanel.mainTab === 0

                    ColumnLayout { anchors.fill: parent; spacing: 0

                        // Chip bar (browse/library)
                        Rectangle { Layout.fillWidth: true; height: 36
                            color: Qt.rgba(0,0,0,0.2)
                            visible: animePanel.browseStack !== 1
                            ListView {
                                anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                orientation: ListView.Horizontal; spacing: 6; clip: true
                                boundsBehavior: Flickable.StopAtBounds
                                model: ListModel {
                                    ListElement { label: "Popular"; view: "popular"; country: "ALL"; idx: 0 }
                                    ListElement { label: "Latest";  view: "latest";  country: "ALL"; idx: 1 }
                                    ListElement { label: "Japan";   view: "latest";  country: "JP";  idx: 2 }
                                    ListElement { label: "China";   view: "latest";  country: "CN";  idx: 3 }
                                    ListElement { label: "Korea";   view: "latest";  country: "KR";  idx: 4 }
                                }
                                delegate: Item {
                                    width: aChip.implicitWidth + 22; height: 36
                                    readonly property bool active: animePanel.animeChip === idx
                                    Rectangle { id: aChip; anchors.centerIn: parent
                                        implicitWidth: aChipT.implicitWidth + 20; height: 26; radius: 13
                                        color: active ? root.walColor5 : Qt.rgba(0,0,0,0.3)
                                        Behavior on color { ColorAnimation { duration: 180 } }
                                        Text { id: aChipT; anchors.centerIn: parent; text: label
                                            font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                                            color: active ? root.walBackground : root.walColor8 }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            animePanel.animeChip = idx
                                            Anime.currentCountry = country
                                            if (view === "popular") Anime.fetchPopular(true)
                                            else Anime.fetchLatest(true)
                                        }
                                    }
                                }
                                // Library button
                                footer: Item { width: libBtn.implicitWidth + 28; height: 36
                                    Rectangle { id: libBtn; anchors.centerIn: parent
                                        implicitWidth: libBtnT.implicitWidth + 20; height: 26; radius: 10
                                        color: animePanel.browseStack === 2
                                            ? Qt.rgba(root.walColor2.r,root.walColor2.g,root.walColor2.b,0.25)
                                            : Qt.rgba(0,0,0,0.3)
                                        border.width: animePanel.browseStack === 2 ? 1 : 0
                                        border.color: root.walColor2
                                        Text { id: libBtnT; anchors.centerIn: parent; text: "Library"
                                            font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                                            color: animePanel.browseStack === 2 ? root.walColor2 : root.walColor8 }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (animePanel.browseStack !== 2) {
                                                    Anime.fetchAllLibrary()
                                                }
                                                animePanel.browseStack = animePanel.browseStack === 2 ? 0 : 2
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true; Layout.fillHeight: true

                            // ── Anime grid ─────────────────────────────────
                            Item { anchors.fill: parent; visible: animePanel.browseStack === 0
                                // Loading spinner
                                Rectangle { anchors.fill: parent; color: "transparent"
                                    visible: Anime.isFetchingAnime && Anime.animeList.length === 0
                                    Column { anchors.centerIn: parent; spacing: 10
                                        Rectangle { width: 30; height: 30; radius: 15
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: "transparent"; border.color: root.walColor5; border.width: 2
                                            RotationAnimator on rotation { from: 0; to: 360; duration: 800
                                                loops: Animation.Infinite; running: parent.visible; easing.type: Easing.Linear } }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Loading..."
                                            color: root.walColor8; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font" }
                                    }
                                }
                                GridView { id: animeGrid
                                    anchors { fill: parent; margins: 8 }
                                    cellWidth: Math.floor(width/3); cellHeight: cellWidth * 1.55
                                    clip: true; boundsBehavior: Flickable.StopAtBounds; model: Anime.animeList
                                    // KEY FIX: don't use reuseItems, use displayMarginBeginning to keep position
                                    displayMarginBeginning: 0; displayMarginEnd: 0
                                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded
                                        contentItem: Rectangle { implicitWidth: 3; color: root.walColor5; opacity: 0.4; radius: 2 } }
property real _savedY: 0
    onContentYChanged: {
        if (contentY > _savedY) _savedY = contentY
        if (!Anime.isFetchingAnime && contentY > 100
                && contentY + height > contentHeight - cellHeight * 2)
            Anime.fetchNextPage()
    }
    Connections {
        target: Anime
        function onItemsAppended() { animeGrid.contentY = animeGrid._savedY }
    }
                                    delegate: Item { width: animeGrid.cellWidth; height: animeGrid.cellHeight
                                        Rectangle { id: aCard; anchors { fill: parent; margins: 4 }
                                            radius: 10; color: Qt.rgba(0,0,0,0.3); clip: true
                                            Image { anchors { top: parent.top; left: parent.left; right: parent.right }
                                                height: parent.height - aTBar.height
                                                source: modelData.thumbnail || ""; fillMode: Image.PreserveAspectCrop
                                                asynchronous: true; cache: true
                                                opacity: status === Image.Ready ? 1 : 0
                                                Behavior on opacity { NumberAnimation { duration: 250 } }
                                                Rectangle { anchors.fill: parent; color: Qt.rgba(0,0,0,0.4)
                                                    visible: parent.status !== Image.Ready }
                                                // Score badge
                                                Rectangle { visible: modelData.score !== null && modelData.score !== undefined
                                                    anchors { top: parent.top; left: parent.left; topMargin: 6; leftMargin: 6 }
                                                    height: 18; width: scoreT.implicitWidth + 10; radius: 9; color: Qt.rgba(0,0,0,0.75)
                                                    Text { id: scoreT; anchors.centerIn: parent
                                                        text: modelData.score ? "★ " + modelData.score.toFixed(1) : ""
                                                        font.pixelSize: 8; font.bold: true; font.family: "JetBrainsMono Nerd Font"; color: "#f5c518" } }
                                                // Library status dot
                                                Rectangle {
                                                    anchors { top: parent.top; right: parent.right; topMargin: 6; rightMargin: 6 }
                                                    width: 8; height: 8; radius: 4
                                                    visible: Anime.isInLibrary(modelData.id)
                                                    color: root.walColor2 }
                                                Rectangle { anchors { bottom: parent.bottom; left: parent.left; right: parent.right } height: 36
                                                    gradient: Gradient {
                                                        GradientStop { position: 0; color: "transparent" }
                                                        GradientStop { position: 1; color: Qt.rgba(0,0,0,0.6) } } }
                                            }
                                            Rectangle { id: aTBar; anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                                height: aTitleT.implicitHeight + 14; color: Qt.rgba(0,0,0,0.5)
                                                Text { id: aTitleT; anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 8; rightMargin: 8 }
                                                    text: modelData.englishName || modelData.name || ""; font.pixelSize: 10
                                                    font.family: "JetBrainsMono Nerd Font"; color: root.walForeground
                                                    wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight } }
                                            Rectangle { anchors.fill: parent; radius: 10; color: root.walColor5
                                                opacity: aCardMa.pressed ? 0.15 : (aCardMa.containsMouse ? 0.06 : 0)
                                                Behavior on opacity { NumberAnimation { duration: 120 } } }
                                            transform: Scale { origin.x: aCard.width/2; origin.y: aCard.height/2
                                                xScale: aCardMa.pressed ? 0.96 : 1; yScale: aCardMa.pressed ? 0.96 : 1
                                                Behavior on xScale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                                                Behavior on yScale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } } }
                                            MouseArea { id: aCardMa; anchors.fill: parent; hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: { Anime.fetchAnimeDetail(modelData); animePanel.browseStack = 1 } }
                                        }
                                    }
                                }
                            }

                            // ── Anime detail ───────────────────────────────
                            Item { anchors.fill: parent; visible: animePanel.browseStack === 1
                                ColumnLayout { anchors.fill: parent; spacing: 0
                                    // Detail header
                                    Rectangle { Layout.fillWidth: true; height: 46; color: Qt.rgba(0,0,0,0.3)
                                        RowLayout { anchors { fill: parent; leftMargin: 8; rightMargin: 12 } spacing: 6
                                            Item { width: 34; height: 34
                                                Rectangle { anchors.fill: parent; radius: 17
                                                    color: dBackMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent" }
                                                Text { anchors.centerIn: parent; text: "←"; font.pixelSize: 16
                                                    color: root.walColor8; font.family: "JetBrainsMono Nerd Font" }
                                                MouseArea { id: dBackMa; anchors.fill: parent; hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: { Anime.clearDetail(); animePanel.browseStack = 0 } }
                                            }
                                            Text { Layout.fillWidth: true
                                                text: Anime.currentAnime ? (Anime.currentAnime.englishName || Anime.currentAnime.name || "") : ""
                                                font.pixelSize: 13; font.bold: true
                                                font.family: "JetBrainsMono Nerd Font"; color: root.walColor5; elide: Text.ElideRight }

                                            // Library button with status picker
                                            Rectangle {
                                                visible: Anime.currentAnime !== null
                                                height: 28; radius: 14
                                                property string curSt: Anime.currentAnime ? Anime.getLibraryStatus(Anime.currentAnime.id) : ""
                                                width: libToggleRow.implicitWidth + 20
                                                color: curSt !== ""
                                                    ? Qt.rgba(root.walColor2.r,root.walColor2.g,root.walColor2.b,0.25)
                                                    : Qt.rgba(0,0,0,0.3)
                                                border.width: 1
                                                border.color: curSt !== "" ? root.walColor2 : root.walColor8
                                                Behavior on color { ColorAnimation { duration: 180 } }
                                                Row { id: libToggleRow; anchors.centerIn: parent; spacing: 5
                                                    Text { anchors.verticalCenter: parent.verticalCenter
                                                        text: parent.parent.curSt !== "" ? "✓" : "+"
                                                        font.pixelSize: 11; font.bold: true
                                                        font.family: "JetBrainsMono Nerd Font"
                                                        color: parent.parent.curSt !== "" ? root.walColor2 : root.walColor8 }
                                                    Text { anchors.verticalCenter: parent.verticalCenter
                                                        text: parent.parent.curSt !== "" ? parent.parent.curSt : "Library"
                                                        font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                                                        color: parent.parent.curSt !== "" ? root.walColor2 : root.walColor8 }
                                                }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (Anime.currentAnime)
                                                            animePanel.openStatusPicker(Anime.currentAnime, "anime")
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Loading
                                    Item { Layout.fillWidth: true; Layout.fillHeight: true
                                        visible: Anime.isFetchingDetail
                                        Column { anchors.centerIn: parent; spacing: 10
                                            Rectangle { width: 28; height: 28; radius: 14
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                color: "transparent"; border.color: root.walColor5; border.width: 2
                                                RotationAnimator on rotation { from: 0; to: 360; duration: 800
                                                    loops: Animation.Infinite; running: parent.visible; easing.type: Easing.Linear } }
                                            Text { anchors.horizontalCenter: parent.horizontalCenter
                                                text: "Loading episodes..."; color: root.walColor8
                                                font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font" }
                                        }
                                    }

                                    // Episode list
                                    ListView { Layout.fillWidth: true; Layout.fillHeight: true
                                        visible: !Anime.isFetchingDetail && Anime.currentAnime !== null
                                        clip: true; boundsBehavior: Flickable.StopAtBounds
                                        model: Anime.currentAnime ? Anime.currentAnime.episodes : []
                                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded
                                            contentItem: Rectangle { implicitWidth: 3; color: root.walColor5; opacity: 0.4; radius: 2 } }
                                        delegate: Rectangle { width: parent ? parent.width : 0; height: 50
                                            color: epMa.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"
                                            Behavior on color { ColorAnimation { duration: 100 } }
                                            Rectangle { anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 56; rightMargin: 12 }
                                                height: 1; color: root.walColor8; opacity: 0.15 }
                                            RowLayout { anchors { fill: parent; leftMargin: 14; rightMargin: 14 } spacing: 12
                                                Rectangle { width: epPill.implicitWidth + 14; height: 24; radius: 12
                                                    color: Qt.rgba(root.walColor5.r,root.walColor5.g,root.walColor5.b,0.2)
                                                    Text { id: epPill; anchors.centerIn: parent
                                                        text: "Ep " + (modelData.number || "?")
                                                        font.pixelSize: 9; font.bold: true
                                                        font.family: "JetBrainsMono Nerd Font"; color: root.walColor5 } }
                                                Text { Layout.fillWidth: true; text: "Episode " + (modelData.number || "")
                                                    font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                                                    color: root.walForeground; elide: Text.ElideRight }
                                                Text { text: "▶"; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                                                    color: epMa.containsMouse ? root.walColor5 : root.walColor8
                                                    opacity: epMa.containsMouse ? 1 : 0.4 }
                                            }
                                            MouseArea { id: epMa; anchors.fill: parent; hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (!Anime.currentAnime) return
                                                    Anime.fetchStreamLinks(Anime.currentAnime.id, modelData.number, "best")
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // ── Anime library ──────────────────────────────
                            Item { anchors.fill: parent; visible: animePanel.browseStack === 2

                                // Library status pills
                                Column { anchors.fill: parent; spacing: 0
                                    // Status selector row
                                    Rectangle { width: parent.width; height: 44; color: Qt.rgba(0,0,0,0.2)
                                        ListView { anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                            orientation: ListView.Horizontal; spacing: 6; clip: true
                                            boundsBehavior: Flickable.StopAtBounds
                                            model: animePanel.animeStatuses
                                            property string selectedStatus: "watching"
                                            id: animeLibStatusList
                                            delegate: Item { width: libStPill.implicitWidth + 22; height: 44
                                                readonly property bool active: animeLibStatusList.selectedStatus === modelData.key
                                                readonly property int cnt: (Anime.libraryAll[modelData.key] || []).length
                                                Rectangle { id: libStPill; anchors.centerIn: parent
                                                    implicitWidth: libStRow.implicitWidth + 20; height: 28; radius: 14
                                                    color: active ? Qt.rgba(0.5,0.5,0.5,0.3) : Qt.rgba(0,0,0,0.3)
                                                    border.width: active ? 1 : 0
                                                    border.color: modelData.color
                                                    Row { id: libStRow; anchors.centerIn: parent; spacing: 5
                                                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.icon
                                                            font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"; color: modelData.color }
                                                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.label
                                                            font.pixelSize: 10; font.bold: active
                                                            font.family: "JetBrainsMono Nerd Font"; color: root.walForeground }
                                                        Rectangle { visible: cnt > 0; width: cntL.implicitWidth + 8; height: 16; radius: 8
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            color: Qt.rgba(1,1,1,0.15)
                                                            Text { id: cntL; anchors.centerIn: parent; text: cnt
                                                                font.pixelSize: 8; font.bold: true
                                                                font.family: "JetBrainsMono Nerd Font"; color: root.walForeground } }
                                                    }
                                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                        onClicked: animeLibStatusList.selectedStatus = modelData.key }
                                                }
                                            }
                                        }
                                    }

                                    // Grid of items for selected status
                                    Item { width: parent.width; height: parent.height - 44
                                        property var _items: Anime.libraryAll[animeLibStatusList.selectedStatus] || []
                                        Column { anchors.centerIn: parent; spacing: 10
                                            visible: parent._items.length === 0
                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "⊡"
                                                font.pixelSize: 36; color: root.walColor8; opacity: 0.3 }
                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Nothing here yet"
                                                font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"; color: root.walColor8; opacity: 0.5 }
                                        }
                                        GridView { anchors { fill: parent; margins: 8 }
                                            visible: parent._items.length > 0
                                            cellWidth: Math.floor(width/3); cellHeight: cellWidth * 1.6
                                            clip: true; boundsBehavior: Flickable.StopAtBounds; model: parent._items
                                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded
                                                contentItem: Rectangle { implicitWidth: 3; color: root.walColor5; opacity: 0.4; radius: 2 } }
                                            delegate: Item { width: parent ? Math.floor(parent.width/3) : 0; height: width * 1.6
                                                Rectangle { id: lCard; anchors { fill: parent; margins: 4 }
                                                    radius: 10; color: Qt.rgba(0,0,0,0.3); clip: true
                                                    Image { anchors { top: parent.top; left: parent.left; right: parent.right }
                                                        height: parent.height - lTBar.height
                                                        source: modelData.thumbnail || ""; fillMode: Image.PreserveAspectCrop
                                                        asynchronous: true; cache: true
                                                        opacity: status === Image.Ready ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 250 } } }
                                                    Rectangle { id: lTBar; anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                                        height: lTitleT.implicitHeight + 14; color: Qt.rgba(0,0,0,0.5)
                                                        Text { id: lTitleT; anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 8; rightMargin: 8 }
                                                            text: modelData.name || modelData.title || ""
                                                            font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; color: root.walForeground
                                                            wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight } }
                                                    Rectangle { anchors.fill: parent; radius: 10; color: root.walColor5
                                                        opacity: lCardMa.pressed ? 0.15 : (lCardMa.containsMouse ? 0.06 : 0) }
                                                    MouseArea { id: lCardMa; anchors.fill: parent; hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: { Anime.fetchAnimeDetail(modelData); animePanel.browseStack = 1 } }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ════════════════════════════════════════════════════════════
                // TAB 1 — MANGA
                // ════════════════════════════════════════════════════════════
                Item { anchors.fill: parent; visible: animePanel.mainTab === 1
                    ColumnLayout { anchors.fill: parent; spacing: 0

                        // Origin chips — only show when on grid (stack 0)
                        Rectangle { Layout.fillWidth: true; height: 42; color: Qt.rgba(0,0,0,0.25)
                            visible: animePanel.mangaStack === 0
                            ListView { anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                orientation: ListView.Horizontal; spacing: 6; clip: true
                                boundsBehavior: Flickable.StopAtBounds
                                model: ListModel {
                                    ListElement { label: "Hot";     origin: "";       idx: 0 }
                                    ListElement { label: "Latest";  origin: "latest"; idx: 1 }
                                    ListElement { label: "Manga";   origin: "ja";     idx: 2 }
                                    ListElement { label: "Manhwa";  origin: "ko";     idx: 3 }
                                    ListElement { label: "Manhua";  origin: "zh";     idx: 4 }
                                }
                                delegate: Item { width: mgOriginChip.implicitWidth + 22; height: parent.height
                                    readonly property bool active: animePanel.mangaOriginTab === idx
                                    Rectangle { id: mgOriginChip; anchors.centerIn: parent
                                        implicitWidth: mgOriginT.implicitWidth + 20; height: 26; radius: 13
                                        color: active ? root.walColor13 : Qt.rgba(0,0,0,0.3)
                                        Behavior on color { ColorAnimation { duration: 180 } }
                                        Text { id: mgOriginT; anchors.centerIn: parent; text: label
                                            font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                                            color: active ? root.walBackground : root.walColor8 }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: { animePanel.mangaOriginTab = idx; Manga.fetchByOrigin(origin, true) }
                                    }
                                }
                                footer: Item { width: mgLibBtn.implicitWidth + 28; height: parent.height
                                    Rectangle { id: mgLibBtn; anchors.centerIn: parent
                                        implicitWidth: mgLibBtnT.implicitWidth + 20; height: 26; radius: 10
                                        color: Qt.rgba(0,0,0,0.3)
                                        border.width: 0
                                        Text { id: mgLibBtnT; anchors.centerIn: parent; text: "Library"
                                            font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                                            color: root.walColor8 }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (animePanel.mangaStack !== 2) {
                                                    Manga.fetchAllLibrary()
                                                }
                                                animePanel.mangaStack = 2
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true; Layout.fillHeight: true

                            // ── STACK 0: Manga grid ────────────────────────
                            Item {
                                anchors.fill: parent
                                visible: animePanel.mangaStack === 0

                                Rectangle { anchors.fill: parent; color: "transparent"
                                    visible: Manga.isFetchingManga && Manga.mangaList.length === 0
                                    Column { anchors.centerIn: parent; spacing: 10
                                        Rectangle { width: 30; height: 30; radius: 15
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: "transparent"; border.color: root.walColor13; border.width: 2
                                            RotationAnimator on rotation { from: 0; to: 360; duration: 800
                                                loops: Animation.Infinite; running: parent.visible; easing.type: Easing.Linear } }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Loading..."
                                            color: root.walColor8; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font" }
                                    }
                                }
                                Column { anchors.centerIn: parent; spacing: 10
                                    visible: Manga.mangaError !== "" && !Manga.isFetchingManga && Manga.mangaList.length === 0
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "⚠"
                                        font.pixelSize: 28; color: root.walColor1; opacity: 0.8 }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Manga.mangaError
                                        color: root.walColor8; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                                        wrapMode: Text.Wrap; width: 300; horizontalAlignment: Text.AlignHCenter }
                                    Rectangle { anchors.horizontalCenter: parent.horizontalCenter
                                        width: retryT.implicitWidth + 20; height: 28; radius: 10
                                        color: retryMa.containsMouse ? Qt.rgba(root.walColor13.r,root.walColor13.g,root.walColor13.b,0.3) : Qt.rgba(0,0,0,0.3)
                                        Text { id: retryT; anchors.centerIn: parent; text: "Retry"
                                            font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: root.walColor13 }
                                        MouseArea { id: retryMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: Manga.fetchByOrigin("", true) }
                                    }
                                }
                                GridView { id: mangaGrid
                                    anchors { fill: parent; margins: 8 }
                                    cellWidth: Math.floor(width/3); cellHeight: cellWidth * 1.55
                                    clip: true; boundsBehavior: Flickable.StopAtBounds; model: Manga.mangaList
                                    visible: Manga.mangaList.length > 0
                                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded
                                        contentItem: Rectangle { implicitWidth: 3; color: root.walColor13; opacity: 0.4; radius: 2 } }
    property real _savedY: 0
    onContentYChanged: {
        if (contentY > _savedY) _savedY = contentY
        if (!Manga.isFetchingManga && contentY > 100
                && contentY + height > contentHeight - cellHeight * 2)
            Manga.fetchNextMangaPage()
    }
    Connections {
        target: Manga
        function onItemsAppended() { mangaGrid.contentY = mangaGrid._savedY }
    }
                                    delegate: Item { width: mangaGrid.cellWidth; height: mangaGrid.cellHeight
                                        Rectangle { id: mgCard; anchors { fill: parent; margins: 4 }
                                            radius: 10; color: Qt.rgba(0,0,0,0.3); clip: true
                                            Image { anchors { top: parent.top; left: parent.left; right: parent.right }
                                                height: parent.height - mgTBar.height
                                                source: modelData.thumbUrl || ""; fillMode: Image.PreserveAspectCrop
                                                asynchronous: true; cache: true
                                                opacity: status === Image.Ready ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 250 } }
                                                Rectangle { anchors.fill: parent; color: Qt.rgba(0,0,0,0.4); visible: parent.status !== Image.Ready }
                                                Rectangle { visible: Manga.isInLibrary(modelData.id)
                                                    anchors { top: parent.top; right: parent.right; topMargin: 6; rightMargin: 6 }
                                                    width: 8; height: 8; radius: 4; color: root.walColor13 }
                                                Rectangle { visible: modelData.type && modelData.type !== ""
                                                    anchors { top: parent.top; left: parent.left; topMargin: 6; leftMargin: 6 }
                                                    height: 18; width: typeT2.implicitWidth + 10; radius: 9; color: Qt.rgba(0,0,0,0.75)
                                                    Text { id: typeT2; anchors.centerIn: parent; text: modelData.type || ""
                                                        font.pixelSize: 8; font.bold: true; font.family: "JetBrainsMono Nerd Font"; color: root.walColor13 } }
                                                Rectangle { anchors { bottom: parent.bottom; left: parent.left; right: parent.right } height: 36
                                                    gradient: Gradient { GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: Qt.rgba(0,0,0,0.6) } } }
                                            }
                                            Rectangle { id: mgTBar; anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                                height: mgTitleT.implicitHeight + 14; color: Qt.rgba(0,0,0,0.5)
                                                Text { id: mgTitleT; anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 8; rightMargin: 8 }
                                                    text: modelData.title || ""; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                                                    color: root.walForeground; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight } }
                                            Rectangle { anchors.fill: parent; radius: 10; color: root.walColor13
                                                opacity: mgCardMa.pressed ? 0.15 : (mgCardMa.containsMouse ? 0.06 : 0) }
                                            MouseArea { id: mgCardMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: { Manga.fetchMangaDetail(modelData.id); animePanel.mangaStack = 1 }
                                            }
                                        }
                                    }
                                }
                            }

                            // ── STACK 1: Manga detail ──────────────────────
                            Item {
                                anchors.fill: parent
                                visible: animePanel.mangaStack === 1

                                ColumnLayout { anchors.fill: parent; spacing: 0
                                    // Detail header
                                    Rectangle { Layout.fillWidth: true; height: 46; color: Qt.rgba(0,0,0,0.3)
                                        RowLayout { anchors { fill: parent; leftMargin: 8; rightMargin: 12 } spacing: 6
                                            Item { width: 34; height: 34
                                                Rectangle { anchors.fill: parent; radius: 17; color: mdBackMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent" }
                                                Text { anchors.centerIn: parent; text: "←"; font.pixelSize: 16; color: root.walColor8; font.family: "JetBrainsMono Nerd Font" }
                                                MouseArea { id: mdBackMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                    onClicked: { Manga.clearChapterPages(); animePanel.mangaStack = 0 } }
                                            }
                                            Text { Layout.fillWidth: true
                                                text: Manga.currentManga ? (Manga.currentManga.title || "") : ""
                                                font.pixelSize: 13; font.bold: true
                                                font.family: "JetBrainsMono Nerd Font"; color: root.walColor13; elide: Text.ElideRight }
                                            // Library button
                                            Rectangle {
                                                visible: Manga.currentManga !== null; height: 28; radius: 14
                                                property string curSt: Manga.currentManga ? Manga.getLibraryStatus(Manga.currentManga.id) : ""
                                                width: mgLibRow.implicitWidth + 20
                                                color: curSt !== ""
                                                    ? Qt.rgba(root.walColor13.r,root.walColor13.g,root.walColor13.b,0.25)
                                                    : Qt.rgba(0,0,0,0.3)
                                                border.width: 1; border.color: curSt !== "" ? root.walColor13 : root.walColor8
                                                Behavior on color { ColorAnimation { duration: 180 } }
                                                Row { id: mgLibRow; anchors.centerIn: parent; spacing: 5
                                                    Text { anchors.verticalCenter: parent.verticalCenter
                                                        text: parent.parent.curSt !== "" ? "✓" : "+"
                                                        font.pixelSize: 11; font.bold: true; font.family: "JetBrainsMono Nerd Font"
                                                        color: parent.parent.curSt !== "" ? root.walColor13 : root.walColor8 }
                                                    Text { anchors.verticalCenter: parent.verticalCenter
                                                        text: parent.parent.curSt !== "" ? parent.parent.curSt : "Library"
                                                        font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                                                        color: parent.parent.curSt !== "" ? root.walColor13 : root.walColor8 }
                                                }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (Manga.currentManga)
                                                            animePanel.openStatusPicker(Manga.currentManga, "manga")
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Loading spinner
									Item { 
										Layout.fillWidth: true; 
										Layout.fillHeight: true;
										clip: true
										visible: Manga.isFetchingDetail
										Column { 
											anchors.centerIn: parent; 
											spacing: 10
											Rectangle { 
												width: 28; 
												height: 28; 
												radius: 14; 
												anchors.horizontalCenter: parent.horizontalCenter
                                                color: "transparent"; border.color: root.walColor13; border.width: 2
                                                RotationAnimator on rotation { from: 0; to: 360; duration: 800; loops: Animation.Infinite; running: parent.visible; easing.type: Easing.Linear } }
                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Loading chapters..."
                                                color: root.walColor8; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font" }
                                        }
                                    }

                                    // ── FIX: Manga detail content — was empty Rectangle, now fully implemented ──
									Item { 
										Layout.fillWidth: true
										Layout.fillHeight: true
										clip: true
                                        visible: !Manga.isFetchingDetail && Manga.currentManga !== null

                                        // Empty state: no chapters indexed
                                        Column { anchors.centerIn: parent; spacing: 12
                                            visible: Manga.currentManga !== null && Manga.currentManga.chapters.length === 0

                                            Text { anchors.horizontalCenter: parent.horizontalCenter
                                                text: "󰂿"; font.pixelSize: 40
                                                font.family: "JetBrainsMono Nerd Font"
                                                color: root.walColor13; opacity: 0.4 }
                                            Text { anchors.horizontalCenter: parent.horizontalCenter
                                                text: "No chapters indexed on AniList"
                                                font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                                                color: root.walColor8; opacity: 0.6 }
                                            Text { anchors.horizontalCenter: parent.horizontalCenter
                                                text: "Read on an external site:"
                                                font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                                                color: root.walColor8; opacity: 0.4
                                                visible: Manga.currentManga && (Manga.currentManga.extLinks || []).length > 0 }

                                            // External read links
                                            Repeater {
                                                model: Manga.currentManga ? (Manga.currentManga.extLinks || []) : []
                                                Rectangle {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    height: 32; width: extLinkT.implicitWidth + 28; radius: 16
                                                    color: extLinkMa.containsMouse
                                                        ? Qt.rgba(root.walColor13.r,root.walColor13.g,root.walColor13.b,0.3)
                                                        : Qt.rgba(0,0,0,0.35)
                                                    border.color: root.walColor13; border.width: 1
                                                    Row { anchors.centerIn: parent; spacing: 6
                                                        Text { anchors.verticalCenter: parent.verticalCenter
                                                            text: "󰌷"; font.pixelSize: 12
                                                            font.family: "JetBrainsMono Nerd Font"; color: root.walColor13 }
                                                        Text { id: extLinkT; anchors.verticalCenter: parent.verticalCenter
                                                            text: "Read on " + (modelData.site || "External")
                                                            font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                                                            color: root.walColor13 }
                                                    }
                                                    MouseArea { id: extLinkMa; anchors.fill: parent; hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: Qt.openUrlExternally(modelData.url) }
                                                }
                                            }
                                        }

                                        // Chapter list — shown when chapters exist
                                        ListView {
                                            anchors {fill: parent; topMargin: 0}
                                            visible: Manga.currentManga && Manga.currentManga.chapters.length > 0
                                            clip: true; boundsBehavior: Flickable.StopAtBounds
                                            model: Manga.currentManga ? Manga.currentManga.chapters : []
                                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded
                                                contentItem: Rectangle { implicitWidth: 3; color: root.walColor13; opacity: 0.4; radius: 2 } }
                                            delegate: Rectangle {
                                                width: parent ? parent.width : 0; height: 52
                                                color: chMa.containsMouse ? Qt.rgba(1,1,1,0.05) : "transparent"
                                                Behavior on color { ColorAnimation { duration: 100 } }

                                                // Bottom divider
                                                Rectangle { anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 56; rightMargin: 12 }
                                                    height: 1; color: root.walColor8; opacity: 0.12 }

                                                RowLayout {
                                                    anchors { fill: parent; leftMargin: 14; rightMargin: 14 } spacing: 12

                                                    // Chapter number pill
                                                    Rectangle {
                                                        width: chPill.implicitWidth + 14; height: 24; radius: 12
                                                        color: Qt.rgba(root.walColor13.r,root.walColor13.g,root.walColor13.b,0.2)
                                                        Text { id: chPill; anchors.centerIn: parent
                                                            text: "Ch." + (modelData.chapter || "?")
                                                            font.pixelSize: 9; font.bold: true
                                                            font.family: "JetBrainsMono Nerd Font"; color: root.walColor13 }
                                                    }

                                                    // Chapter title
                                                    Column { Layout.fillWidth: true; spacing: 2
                                                        Text {
                                                            width: parent.width
                                                            text: modelData.title || ("Chapter " + (modelData.chapter || ""))
                                                            font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                                                            color: root.walForeground; elide: Text.ElideRight }
                                                        Text {
                                                            visible: modelData.publishAt && modelData.publishAt !== ""
                                                            text: modelData.publishAt || ""
                                                            font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"
                                                            color: root.walColor8; opacity: 0.6 }
                                                    }

                                                    // Read icon
                                                    Text { text: "󰌷"; font.pixelSize: 14
                                                        font.family: "JetBrainsMono Nerd Font"
                                                        color: chMa.containsMouse ? root.walColor13 : root.walColor8
                                                        opacity: chMa.containsMouse ? 1 : 0.4
                                                        Behavior on color { ColorAnimation { duration: 100 } } }
                                                }

                                                MouseArea { id: chMa; anchors.fill: parent; hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (!modelData) return
                                                        // Try to fetch pages; if synthetic id, open external link
                                                        var chId = modelData.id || ""
                                                        if (chId.indexOf("-ch") !== -1) {
                                                            // Synthetic chapter — look for external read link
                                                            var links = Manga.currentManga ? (Manga.currentManga.extLinks || []) : []
                                                            if (links.length > 0) {
                                                                Qt.openUrlExternally(links[0].url)
                                                            }
                                                        } else {
                                                            Manga.fetchChapterPages(chId)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // ── STACK 2: Manga library ─────────────────────
                            Item {
                                anchors.fill: parent
                                visible: animePanel.mangaStack === 2

                                ColumnLayout { anchors.fill: parent; spacing: 0

                                    // Header bar with back button
                                    Rectangle { Layout.fillWidth: true; height: 46; color: Qt.rgba(0,0,0,0.3)
                                        RowLayout { anchors { fill: parent; leftMargin: 8; rightMargin: 12 } spacing: 6
                                            Item { width: 34; height: 34
                                                Rectangle { anchors.fill: parent; radius: 17
                                                    color: mgLibBackMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent" }
                                                Text { anchors.centerIn: parent; text: "←"; font.pixelSize: 16
                                                    color: root.walColor8; font.family: "JetBrainsMono Nerd Font" }
                                                MouseArea { id: mgLibBackMa; anchors.fill: parent; hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: animePanel.mangaStack = 0 }
                                            }
                                            Text { text: "Manga Library"; font.pixelSize: 13; font.bold: true
                                                font.family: "JetBrainsMono Nerd Font"; color: root.walColor13
                                                Layout.fillWidth: true }
                                        }
                                    }

                                    // Status pill row
                                    Rectangle { Layout.fillWidth: true; height: 44; color: Qt.rgba(0,0,0,0.2)
                                        ListView {
                                            id: mangaLibStatusList
                                            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                            orientation: ListView.Horizontal; spacing: 6; clip: true
                                            boundsBehavior: Flickable.StopAtBounds
                                            model: animePanel.mangaStatuses
                                            property string selectedStatus: "reading"
                                            delegate: Item { width: mgStPill.implicitWidth + 22; height: 44
                                                readonly property bool isActive: mangaLibStatusList.selectedStatus === modelData.key
                                                readonly property int cnt: (Manga.libraryAll[modelData.key] || []).length
                                                Rectangle { id: mgStPill; anchors.centerIn: parent
                                                    implicitWidth: mgStRow.implicitWidth + 20; height: 28; radius: 14
                                                    color: isActive ? Qt.rgba(0.5,0.5,0.5,0.3) : Qt.rgba(0,0,0,0.3)
                                                    border.width: isActive ? 1 : 0; border.color: modelData.color
                                                    Row { id: mgStRow; anchors.centerIn: parent; spacing: 5
                                                        Text { anchors.verticalCenter: parent.verticalCenter
                                                            text: modelData.icon; font.pixelSize: 12
                                                            font.family: "JetBrainsMono Nerd Font"; color: modelData.color }
                                                        Text { anchors.verticalCenter: parent.verticalCenter
                                                            text: modelData.label; font.pixelSize: 10; font.bold: isActive
                                                            font.family: "JetBrainsMono Nerd Font"; color: root.walForeground }
                                                        Rectangle { visible: cnt > 0; width: mgCntL.implicitWidth + 8; height: 16; radius: 8
                                                            anchors.verticalCenter: parent.verticalCenter; color: Qt.rgba(1,1,1,0.15)
                                                            Text { id: mgCntL; anchors.centerIn: parent; text: cnt
                                                                font.pixelSize: 8; font.bold: true
                                                                font.family: "JetBrainsMono Nerd Font"; color: root.walForeground } }
                                                    }
                                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                        onClicked: mangaLibStatusList.selectedStatus = modelData.key }
                                                }
                                            }
                                        }
                                    }

                                    // Grid
                                    Item {
                                        Layout.fillWidth: true; Layout.fillHeight: true
                                        property var libItems: Manga.libraryAll[mangaLibStatusList.selectedStatus] || []

                                        Column { anchors.centerIn: parent; spacing: 10
                                            visible: parent.libItems.length === 0
                                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "⊡"
                                                font.pixelSize: 36; color: root.walColor8; opacity: 0.3 }
                                            Text { anchors.horizontalCenter: parent.horizontalCenter
                                                text: "Nothing here yet"
                                                font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                                                color: root.walColor8; opacity: 0.5 }
                                        }

                                        GridView {
                                            anchors { fill: parent; margins: 8 }
                                            visible: parent.libItems.length > 0
                                            model: parent.libItems
                                            cellWidth: Math.floor(width/3); cellHeight: cellWidth * 1.6
                                            clip: true; boundsBehavior: Flickable.StopAtBounds
                                            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded
                                                contentItem: Rectangle { implicitWidth: 3; color: root.walColor13; opacity: 0.4; radius: 2 } }
                                            delegate: Item {
                                                width: GridView.view ? Math.floor(GridView.view.width/3) : 0
                                                height: width * 1.6
                                                Rectangle { id: mgLCard; anchors { fill: parent; margins: 4 }
                                                    radius: 10; color: Qt.rgba(0,0,0,0.3); clip: true
                                                    Image { anchors { top: parent.top; left: parent.left; right: parent.right }
                                                        height: parent.height - mgLTBar.height
                                                        source: modelData.cover_url || modelData.coverUrl || ""
                                                        fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: true
                                                        opacity: status === Image.Ready ? 1 : 0
                                                        Behavior on opacity { NumberAnimation { duration: 250 } } }
                                                    Rectangle { id: mgLTBar
                                                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                                        height: mgLTitleT.implicitHeight + 14; color: Qt.rgba(0,0,0,0.5)
                                                        Text { id: mgLTitleT
                                                            anchors { left: parent.left; right: parent.right
                                                                verticalCenter: parent.verticalCenter; leftMargin: 8; rightMargin: 8 }
                                                            text: modelData.title || ""
                                                            font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                                                            color: root.walForeground; wrapMode: Text.Wrap
                                                            maximumLineCount: 2; elide: Text.ElideRight } }
                                                    Rectangle { anchors.fill: parent; radius: 10; color: root.walColor13
                                                        opacity: mgLMa.pressed ? 0.15 : (mgLMa.containsMouse ? 0.06 : 0) }
                                                    MouseArea { id: mgLMa; anchors.fill: parent; hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: { Manga.fetchMangaDetail(modelData.id); animePanel.mangaStack = 1 } }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                        }
                    }
                }

                // ════════════════════════════════════════════════════════════
                // TAB 2 — MY LISTS (AniList personal)
                // ════════════════════════════════════════════════════════════
                Item { anchors.fill: parent; visible: animePanel.mainTab === 2
                    ColumnLayout { anchors.fill: parent; spacing: 0

                        // Username + controls bar
                        Rectangle { Layout.fillWidth: true; height: 40; color: Qt.rgba(0,0,0,0.3)
                            RowLayout { anchors { fill: parent; leftMargin: 12; rightMargin: 12 } spacing: 8
                                Text { text: ""; font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font"; color: root.walColor5 }
                                Text { visible: !animePanel.usernameEditing
                                    text: animePanel.anilistUsername || "Set username"
                                    font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                                    color: animePanel.anilistUsername ? root.walForeground : root.walColor8
                                    Layout.fillWidth: true
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: { animePanel.usernameInput = animePanel.anilistUsername; animePanel.usernameEditing = true } }
                                }
                                Rectangle { visible: animePanel.usernameEditing; Layout.fillWidth: true; height: 28; radius: 8; color: Qt.rgba(0,0,0,0.4); border.width: 1; border.color: root.walColor5
                                    TextInput { anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                        text: animePanel.usernameInput; onTextChanged: animePanel.usernameInput = text
                                        color: root.walForeground; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                                        verticalAlignment: TextInput.AlignVCenter; clip: true
                                        Keys.onReturnPressed: { animePanel.anilistUsername = animePanel.usernameInput; animePanel.usernameEditing = false; animePanel.fetchPersonalList() }
                                        Keys.onEscapePressed: animePanel.usernameEditing = false }
                                }
                                // Anime/Manga kind toggle
                                Row { spacing: 4
                                    Repeater { model: [{ label: "Anime", k: "ANIME" }, { label: "Manga", k: "MANGA" }]
                                        Rectangle { width: kindT.implicitWidth + 16; height: 26; radius: 13
                                            color: animePanel.personalMediaKind === modelData.k ? root.walColor5 : Qt.rgba(0,0,0,0.35)
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            Text { id: kindT; anchors.centerIn: parent; text: modelData.label; font.pixelSize: 10; font.bold: animePanel.personalMediaKind === modelData.k; font.family: "JetBrainsMono Nerd Font"; color: animePanel.personalMediaKind === modelData.k ? root.walBackground : root.walColor8 }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: animePanel.personalMediaKind = modelData.k }
                                        }
                                    }
                                }
                                Rectangle { width: 28; height: 28; radius: 8; color: refMa.containsMouse ? Qt.rgba(root.walColor5.r,root.walColor5.g,root.walColor5.b,0.2) : "transparent"
                                    Text { anchors.centerIn: parent; text: "󰑐"; font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font"; color: root.walColor5 }
                                    MouseArea { id: refMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: animePanel.fetchPersonalList() }
                                }
                            }
                        }

                        // Status pills
                        Rectangle { Layout.fillWidth: true; height: 42; color: Qt.rgba(0,0,0,0.2)
                            ListView { anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                                orientation: ListView.Horizontal; spacing: 6; clip: true; boundsBehavior: Flickable.StopAtBounds
                                model: ["CURRENT", "COMPLETED", "PLANNING", "PAUSED", "DROPPED", "REPEATING"]
                                delegate: Item { width: sPill.implicitWidth + 22; height: parent.height
                                    readonly property var lbl: animePanel.personalMediaKind === "MANGA" ? animePanel.alMangaLabels[modelData] : animePanel.alAnimeLabels[modelData]
                                    Rectangle { id: sPill; anchors.centerIn: parent
                                        implicitWidth: sPillT.implicitWidth + 20; height: 26; radius: 13
                                        color: animePanel.personalStatus === modelData ? animePanel.alStatusColor(modelData) : Qt.rgba(0,0,0,0.3)
                                        Behavior on color { ColorAnimation { duration: 180 } }
                                        Row { anchors.centerIn: parent; spacing: 5
                                            Text { anchors.verticalCenter: parent.verticalCenter; text: lbl ? lbl.icon : ""; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; color: animePanel.personalStatus === modelData ? root.walBackground : root.walColor8 }
                                            Text { id: sPillT; anchors.verticalCenter: parent.verticalCenter; text: lbl ? lbl.label : modelData; font.pixelSize: 10; font.bold: animePanel.personalStatus === modelData; font.family: "JetBrainsMono Nerd Font"; color: animePanel.personalStatus === modelData ? root.walBackground : root.walColor8 }
                                        }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: animePanel.personalStatus = modelData }
                                }
                            }
                        }

                        // List content
                        Item { Layout.fillWidth: true; Layout.fillHeight: true
                            Rectangle { anchors.fill: parent; color: "transparent"; visible: animePanel.isFetchingPersonal && animePanel.personalItems.length === 0
                                Column { anchors.centerIn: parent; spacing: 10
                                    Rectangle { width: 30; height: 30; radius: 15; anchors.horizontalCenter: parent.horizontalCenter; color: "transparent"; border.color: root.walColor5; border.width: 2; RotationAnimator on rotation { from: 0; to: 360; duration: 800; loops: Animation.Infinite; running: parent.visible; easing.type: Easing.Linear } }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Loading..."; color: root.walColor8; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font" }
                                }
                            }
                            Column { anchors.centerIn: parent; spacing: 10; visible: animePanel.personalError !== "" && !animePanel.isFetchingPersonal
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "⚠"; font.pixelSize: 28; color: root.walColor1; opacity: 0.8 }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: animePanel.personalError; color: root.walColor8; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; wrapMode: Text.Wrap; width: 300; horizontalAlignment: Text.AlignHCenter }
                            }
                            Column { anchors.centerIn: parent; spacing: 10
                                visible: !animePanel.isFetchingPersonal && animePanel.personalItems.length === 0 && animePanel.personalError === ""
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "⊡"; font.pixelSize: 36; color: root.walColor8; opacity: 0.3 }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Nothing here yet"; color: root.walColor8; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"; opacity: 0.5 }
                            }
                            GridView { id: personalGrid
                                anchors { fill: parent; margins: 8 }
                                visible: animePanel.personalItems.length > 0 && !animePanel.isFetchingPersonal
                                cellWidth: Math.floor(width/3); cellHeight: cellWidth * 1.6
                                clip: true; boundsBehavior: Flickable.StopAtBounds; model: animePanel.personalItems
                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; contentItem: Rectangle { implicitWidth: 3; color: root.walColor5; opacity: 0.4; radius: 2 } }
                                delegate: Item { width: personalGrid.cellWidth; height: personalGrid.cellHeight
                                    Rectangle { id: pCard; anchors { fill: parent; margins: 4 } radius: 10; color: Qt.rgba(0,0,0,0.3); clip: true
                                        Image { anchors { top: parent.top; left: parent.left; right: parent.right } height: parent.height - pTBar.height
                                            source: modelData.thumbnail || ""; fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: true; opacity: status === Image.Ready ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 250 } }
                                            Rectangle { anchors.fill: parent; color: Qt.rgba(0,0,0,0.4); visible: parent.status !== Image.Ready }
                                            Rectangle { visible: modelData.userScore && modelData.userScore > 0; anchors { top: parent.top; left: parent.left; topMargin: 6; leftMargin: 6 } height: 18; width: pScoreT.implicitWidth + 10; radius: 9; color: Qt.rgba(0,0,0,0.75); Text { id: pScoreT; anchors.centerIn: parent; text: "★ " + modelData.userScore; font.pixelSize: 8; font.bold: true; font.family: "JetBrainsMono Nerd Font"; color: "#f5c518" } }
                                            Rectangle { anchors { bottom: parent.bottom; right: parent.right; bottomMargin: 6; rightMargin: 6 } height: 18; width: pProg.implicitWidth + 10; radius: 9; color: Qt.rgba(0,0,0,0.75); visible: modelData.progress !== undefined && modelData.progress > 0; Text { id: pProg; anchors.centerIn: parent; text: (modelData.progress || 0) + (animePanel.personalMediaKind === "MANGA" ? " ch" : " ep"); font.pixelSize: 8; font.family: "JetBrainsMono Nerd Font"; color: root.walForeground } }
                                            Rectangle { anchors { bottom: parent.bottom; left: parent.left; right: parent.right } height: 36; gradient: Gradient { GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: Qt.rgba(0,0,0,0.6) } } }
                                        }
                                        Rectangle { id: pTBar; anchors { bottom: parent.bottom; left: parent.left; right: parent.right } height: pTitleT.implicitHeight + 14; color: Qt.rgba(0,0,0,0.5)
                                            Text { id: pTitleT; anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 8; rightMargin: 8 } text: modelData.englishName || modelData.name || ""; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; color: root.walForeground; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight } }
                                        Rectangle { anchors.fill: parent; radius: 10; color: root.walColor5; opacity: pCardMa.pressed ? 0.15 : (pCardMa.containsMouse ? 0.06 : 0) }
                                        MouseArea { id: pCardMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                var url = "https://anilist.co/" + (animePanel.personalMediaKind === "MANGA" ? "manga" : "anime") + "/" + modelData.id
                                                Qt.openUrlExternally(url)
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
    }

    // MPV playback
    Process { id: mpvProc }
    Connections {
        target: Anime
        function onSelectedLinkChanged() {
            if (!Anime.selectedLink) return
            var lnk = Anime.selectedLink
            if (!lnk.url || lnk.url.length === 0) { Anime.clearStreamLinks(); return }
            var title = Anime.currentAnime
                ? (Anime.currentAnime.englishName || Anime.currentAnime.name) + " — Ep." + Anime.currentEpisode
                : "Anime"
            var args = ["mpv", "--fs", "--force-window=yes", "--title=" + title, "--no-terminal"]
            if (lnk.referer) args.push("--referrer=" + lnk.referer)
            args.push(lnk.url)
            mpvProc.command = args; mpvProc.running = true
            Anime.clearStreamLinks()
        }
    }

    Connections {
        target: root
        function onAnimePanelVisibleChanged() {
            if (root.animePanelVisible) {
                focusTimer.start()
                if (animePanel.mainTab === 1 && !animePanel.mangaInitialized) {
                    animePanel.mangaInitialized = true
                    Manga.fetchByOrigin("", true)
                }
                // Only fetch library if not already loaded — avoids scroll reset
                if (!Anime.libraryLoaded) Anime.fetchAllLibrary()
                if (!Manga.libraryLoaded) Manga.fetchAllLibrary()
            }
        }
    }
    Timer { id: focusTimer; interval: 50; repeat: false
        onTriggered: { animePanel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive; releaseTimer.start() } }
    Timer { id: releaseTimer; interval: 100; repeat: false
        onTriggered: animePanel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand }
}
