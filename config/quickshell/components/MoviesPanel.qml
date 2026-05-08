import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../services"

PanelWindow {
    id: moviesPanel
    screen: Quickshell.screens.length > 0 ? (root.focusedScreen ?? Quickshell.screens[0]) : undefined
	visible: true
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; right: true; bottom: true }
    margins {
        top: 40; bottom: 10
        right: root.moviesPanelVisible ? 6 : -560
    }
    implicitWidth: 530
    color: "transparent"
    focusable: true
    WlrLayershell.keyboardFocus: root.moviesPanelVisible
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Behavior on margins.right {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    // ── State ─────────────────────────────────────────────────────────────
    property int mainTab: 0
    property int stack: 0
    property bool searchOpen: false
    property string searchQuery: ""

    property string myListStatus: "watching"
    property string myListType: "movie"
    onMyListTypeChanged: Movies.fetchAllUserLists(myListType)

    property string wlFavType: "movie"
    onWlFavTypeChanged: {
        Movies.fetchLocalWatchlist(wlFavType)
        Movies.fetchLocalFavorites(wlFavType)
    }

    property bool statusMenuOpen: false

    property string currentItemListStatus: ""

    function _refreshCurrentStatus() {
        if (!Movies.currentItem) { currentItemListStatus = ""; return }
        currentItemListStatus = Movies.getUserListStatus(
            Movies.currentItem.id, Movies.currentItem.type)
    }

    Connections {
        target: Movies
        function onCurrentItemChanged()            { moviesPanel._refreshCurrentStatus() }
        function onUserListMovieWatchingChanged()  { moviesPanel._refreshCurrentStatus() }
        function onUserListMovieCompletedChanged() { moviesPanel._refreshCurrentStatus() }
        function onUserListMoviePlanningChanged()  { moviesPanel._refreshCurrentStatus() }
        function onUserListMovieOnHoldChanged()    { moviesPanel._refreshCurrentStatus() }
        function onUserListMovieDroppedChanged()   { moviesPanel._refreshCurrentStatus() }
        function onUserListTvWatchingChanged()     { moviesPanel._refreshCurrentStatus() }
        function onUserListTvCompletedChanged()    { moviesPanel._refreshCurrentStatus() }
        function onUserListTvPlanningChanged()     { moviesPanel._refreshCurrentStatus() }
        function onUserListTvOnHoldChanged()       { moviesPanel._refreshCurrentStatus() }
        function onUserListTvDroppedChanged()      { moviesPanel._refreshCurrentStatus() }
    }

    readonly property var statusDefs: [
        { key: "watching",  label: "Watching",   icon: "󰐊", color: "#89b4fa" },
        { key: "completed", label: "Completed",  icon: "󰄬", color: "#a6e3a1" },
        { key: "planning",  label: "Planning",   icon: "󰃯", color: "#f5c2e7" },
        { key: "on_hold",   label: "On Hold",    icon: "⏸", color: "#f9e2af" },
        { key: "dropped",   label: "Dropped",    icon: "󰅖", color: "#f38ba8" }
    ]

    readonly property var statusColors: ({
        "watching":  root.walColor5,
        "completed": root.walColor2,
        "planning":  root.walColor13,
        "on_hold":   root.walColor4,
        "dropped":   root.walColor1
    })

    function statusLabel(key) {
        for (var i = 0; i < statusDefs.length; i++)
            if (statusDefs[i].key === key) return statusDefs[i].label
        return key
    }
    function statusIcon(key) {
        for (var i = 0; i < statusDefs.length; i++)
            if (statusDefs[i].key === key) return statusDefs[i].icon
        return "?"
    }
    function statusColor(key) { return statusColors[key] || root.walColor8 }

    readonly property var _tabs: [
        { label: "Movies",    idx: 0, icon: "󰿎" },
        { label: "TV Shows",  idx: 1, icon: "󰺶" },
        { label: "Watchlist", idx: 2, icon: "󰄲" },
        { label: "Favorites", idx: 3, icon: "󰋑" },
        { label: "My List",   idx: 4, icon: "󰝚" },
        { label: "Saved",     idx: 5, icon: "󰐚" }
    ]

    // ── Root rectangle ────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent; radius: 20
        color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.97)

        // ── Background click-away for status dropdown ──────────────────────
        MouseArea {
            anchors.fill: parent; z: 499
            visible: moviesPanel.statusMenuOpen
            onClicked: moviesPanel.statusMenuOpen = false
        }

        // ── Status dropdown — direct child of root rect so z works globally ─
        Rectangle {
            id: statusDropdown
            visible: moviesPanel.statusMenuOpen
            z: 500
            anchors { top: parent.top; right: parent.right; topMargin: 94; rightMargin: 12 }
            width: 180; radius: 12
            color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.98)
            border.color: Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.3)
            border.width: 1
            height: sdCol.implicitHeight + 16
            MouseArea { anchors.fill: parent }  // eat background clicks

            Column {
                id: sdCol
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
                spacing: 4

                Text { text: "Add to My List"
                    color: root.walColor8; font.pixelSize: 9; font.bold: true
                    font.letterSpacing: 1; font.family: "JetBrainsMono Nerd Font"
                    opacity: 0.6; leftPadding: 4; topPadding: 4 }

                Repeater {
                    model: moviesPanel.statusDefs
                    Rectangle {
                        width: parent.width; height: 36; radius: 8
                        readonly property bool isActive: moviesPanel.currentItemListStatus === modelData.key
                        color: isActive
                            ? Qt.rgba(moviesPanel.statusColor(modelData.key).r,
                                      moviesPanel.statusColor(modelData.key).g,
                                      moviesPanel.statusColor(modelData.key).b, 0.2)
                            : sdItemMa.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Row { anchors { fill: parent; leftMargin: 10; rightMargin: 10 } spacing: 8
                            Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.icon
                                font.pixelSize: 13; font.family: "JetBrainsMono Nerd Font"
                                color: isActive ? moviesPanel.statusColor(modelData.key) : root.walColor8 }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.label
                                font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                                color: isActive ? moviesPanel.statusColor(modelData.key) : root.walForeground }
                            Text { anchors.verticalCenter: parent.verticalCenter
                                visible: isActive; text: "󰄬"; font.pixelSize: 11
                                font.family: "JetBrainsMono Nerd Font"
                                color: moviesPanel.statusColor(modelData.key) }
                        }
                        MouseArea { id: sdItemMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                console.log("[debug] status clicked id=" + (Movies.currentItem ? Movies.currentItem.id : "null") + " cur=" + moviesPanel.currentItemListStatus + " key=" + modelData.key)
                                if (!Movies.currentItem) return
                                var cur = moviesPanel.currentItemListStatus
                                if (cur === modelData.key) {
                                    Movies.removeFromUserList(Movies.currentItem)
                                } else if (cur === "") {
                                    Movies.addToUserList(Movies.currentItem, modelData.key)
                                } else {
                                    Movies.updateUserListStatus(Movies.currentItem, modelData.key)
                                }
                                moviesPanel.statusMenuOpen = false
                            }
                        }
                    }
                }

                // Remove row
                Rectangle {
                    width: parent.width; height: 32; radius: 8
                    visible: moviesPanel.currentItemListStatus !== ""
                    color: rmMa.containsMouse
                        ? Qt.rgba(root.walColor1.r,root.walColor1.g,root.walColor1.b,0.15) : "transparent"
                    Row { anchors { fill: parent; leftMargin: 10 } spacing: 8
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "󰅖"
                            font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"; color: root.walColor1 }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "Remove from list"
                            font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; color: root.walColor1 }
                    }
                    MouseArea { id: rmMa; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (Movies.currentItem) Movies.removeFromUserList(Movies.currentItem)
                            moviesPanel.statusMenuOpen = false
                        }
                    }
                }
                Item { height: 4 }
            }
        }

        ColumnLayout {
            anchors.fill: parent; spacing: 0

            // ── Header ────────────────────────────────────────────────────
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
                            color: mCloseMa.containsMouse ? root.walColor1 : root.walColor8
                            Behavior on color { ColorAnimation { duration: 150 } } }
                        MouseArea { id: mCloseMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.moviesPanelVisible = false }
                    }

                    Text { text: "Movies & TV"; font.pixelSize: 14; font.bold: true
                        font.family: "JetBrainsMono Nerd Font"; color: root.walColor13 }

                    Rectangle { width: 7; height: 7; radius: 3.5
                        color: Movies.serverReady ? root.walColor2 : root.walColor1
                        Behavior on color { ColorAnimation { duration: 400 } } }

                    Rectangle {
                        visible: Movies.hasAccount
                        height: 20; width: acctLbl.implicitWidth + 12; radius: 10
                        color: Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.2)
                        Text { id: acctLbl; anchors.centerIn: parent; text: "TMDB ✓"
                            font.pixelSize: 8; font.bold: true
                            font.family: "JetBrainsMono Nerd Font"; color: root.walColor13 }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.fillWidth: true; height: 30; radius: 15
                        color: Qt.rgba(0,0,0,0.4)
                        visible: moviesPanel.searchOpen && moviesPanel.stack === 0
                            && (moviesPanel.mainTab === 0 || moviesPanel.mainTab === 1)
                        border.color: mSearchField.activeFocus ? root.walColor13 : root.walColor8
                        border.width: 1
                        TextInput {
                            id: mSearchField
                            anchors { verticalCenter: parent.verticalCenter
                                left: parent.left; right: parent.right
                                leftMargin: 12; rightMargin: 10 }
                            color: root.walForeground; font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"; clip: true
                            Text { anchors { verticalCenter: parent.verticalCenter; left: parent.left }
                                text: "Search..."; color: root.walColor8; font: parent.font
                                visible: !parent.text; opacity: 0.6 }
                            onTextChanged: searchDebounce.restart()
                            Keys.onEscapePressed: {
                                moviesPanel.searchOpen = false; text = ""
                                Movies.fetchTrending(moviesPanel.mainTab === 0 ? "movie" : "tv", true)
                            }
                        }
                        Timer { id: searchDebounce; interval: 400
                            onTriggered: {
                                if (mSearchField.text.trim().length > 0) {
                                    moviesPanel.searchQuery = mSearchField.text.trim()
                                    Movies.search(moviesPanel.searchQuery,
                                        moviesPanel.mainTab === 0 ? "movie" : "tv", true)
                                }
                            }
                        }
                    }

                    Item {
                        width: 32; height: 32
                        visible: moviesPanel.stack === 0
                            && (moviesPanel.mainTab === 0 || moviesPanel.mainTab === 1)
                        Rectangle { anchors.fill: parent; radius: 16
                            color: moviesPanel.searchOpen
                                ? Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.25)
                                : "transparent" }
                        Text { anchors.centerIn: parent; text: "⌕"; font.pixelSize: 16
                            color: moviesPanel.searchOpen ? root.walColor13 : root.walColor8 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                moviesPanel.searchOpen = !moviesPanel.searchOpen
                                if (moviesPanel.searchOpen) mSearchField.forceActiveFocus()
                                else {
                                    mSearchField.text = ""
                                    Movies.fetchTrending(moviesPanel.mainTab === 0 ? "movie" : "tv", true)
                                }
                            }
                        }
                    }
                }
            }

            // ── Tab bar ────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true; height: 38; color: Qt.rgba(0,0,0,0.25)
                ListView {
                    anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                    orientation: ListView.Horizontal; spacing: 4; clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: moviesPanel._tabs
                    delegate: Item {
                        width: mTabR.implicitWidth + 22; height: parent.height
                        readonly property bool active: moviesPanel.mainTab === modelData.idx
                        Rectangle {
                            id: mTabR; anchors.centerIn: parent
                            implicitWidth: mTabRow.implicitWidth + 20; height: 28; radius: 10
                            color: active
                                ? Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.25)
                                : mTabMa.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"
                            border.width: active ? 1 : 0; border.color: root.walColor13
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Row { id: mTabRow; anchors.centerIn: parent; spacing: 5
                                Text { anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.icon; font.pixelSize: 12
                                    font.family: "JetBrainsMono Nerd Font"
                                    color: active ? root.walColor13 : root.walColor8 }
                                Text { anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label; font.pixelSize: 10; font.bold: active
                                    font.family: "JetBrainsMono Nerd Font"
                                    color: active ? root.walColor13 : root.walColor8 }
                            }
                        }
                        MouseArea { id: mTabMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var idx = modelData.idx
                                moviesPanel.mainTab = idx
                                moviesPanel.stack   = 0
                                moviesPanel.searchOpen = false
                                mSearchField.text   = ""
                                Movies.clearDetail()
                                moviesPanel.statusMenuOpen = false

                                if (idx === 0) Movies.fetchTrending("movie", true)
                                else if (idx === 1) Movies.fetchTrending("tv", true)
                                else if (idx === 2) {
                                    Movies.fetchLocalWatchlist("movie")
                                    Movies.fetchLocalWatchlist("tv")
                                    if (Movies.hasAccount) {
                                        Movies.syncFromTmdb("movie")
                                        Movies.syncFromTmdb("tv")
                                    }
                                } else if (idx === 3) {
                                    Movies.fetchLocalFavorites("movie")
                                    Movies.fetchLocalFavorites("tv")
                                    if (Movies.hasAccount) {
                                        Movies.syncFromTmdb("movie")
                                        Movies.syncFromTmdb("tv")
                                    }
                                } else if (idx === 4) {
                                    Movies.fetchAllUserLists("movie")
                                    Movies.fetchAllUserLists("tv")
                                }
                            }
                        }
                    }
                }
            }

            // ── Type switcher for watchlist & favorites ────────────────────
            Rectangle {
                Layout.fillWidth: true; height: 38; color: Qt.rgba(0,0,0,0.15)
                visible: moviesPanel.stack === 0 &&
                    (moviesPanel.mainTab === 2 || moviesPanel.mainTab === 3)
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                    Row { spacing: 8
                        Repeater {
                            model: [{ label: "Movies", t: "movie" }, { label: "TV Shows", t: "tv" }]
                            Rectangle {
                                width: swLbl.implicitWidth + 20; height: 26; radius: 13
                                color: moviesPanel.wlFavType === modelData.t
                                    ? root.walColor13 : swMa.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(0,0,0,0.3)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Text { id: swLbl; anchors.centerIn: parent; text: modelData.label
                                    font.pixelSize: 10; font.bold: moviesPanel.wlFavType === modelData.t
                                    font.family: "JetBrainsMono Nerd Font"
                                    color: moviesPanel.wlFavType === modelData.t ? root.walBackground : root.walColor8 }
                                MouseArea { id: swMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: moviesPanel.wlFavType = modelData.t }
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        visible: Movies.hasAccount
                        width: syncLbl.implicitWidth + 16; height: 24; radius: 8
                        color: syncMa.containsMouse ? Qt.rgba(root.walColor5.r,root.walColor5.g,root.walColor5.b,0.25) : Qt.rgba(0,0,0,0.3)
                        Text { id: syncLbl; anchors.centerIn: parent; text: "󰑐 Sync TMDB"
                            font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; color: root.walColor5 }
                        MouseArea { id: syncMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Movies.syncFromTmdb("movie"); Movies.syncFromTmdb("tv")
                                syncFeedbackTimer.restart()
                            }
                        }
                    }
                    Timer { id: syncFeedbackTimer; interval: 3000; repeat: false
                        onTriggered: {
                            Movies.fetchLocalWatchlist("movie"); Movies.fetchLocalWatchlist("tv")
                            Movies.fetchLocalFavorites("movie"); Movies.fetchLocalFavorites("tv")
                        }
                    }
                }
            }

            // ── Genre chips ────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true; height: 42; color: Qt.rgba(0,0,0,0.2)
                visible: moviesPanel.stack === 0
                    && (moviesPanel.mainTab === 0 || moviesPanel.mainTab === 1)
                clip: true
                ListView {
                    anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                    orientation: ListView.Horizontal; spacing: 6; clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    header: Item { width: 4 }
                    model: {
                        var all = [{ id: "", name: "All" }]
                        var map = moviesPanel.mainTab === 0 ? Movies._movieGenres : Movies._tvGenres
                        for (var k in map) all.push({ id: k, name: map[k] })
                        return all
                    }
                    delegate: Item {
                        width: gChip.implicitWidth + 22; height: parent.height
                        readonly property bool active: Movies.currentGenreId === (modelData.id || "")
                        Rectangle {
                            id: gChip; anchors.centerIn: parent
                            implicitWidth: gChipT.implicitWidth + 20; height: 26; radius: 13
                            color: active ? root.walColor13 : Qt.rgba(0,0,0,0.3)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text { id: gChipT; anchors.centerIn: parent; text: modelData.name
                                font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                                color: active ? root.walBackground : root.walColor8 }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var t = moviesPanel.mainTab === 0 ? "movie" : "tv"
                                Movies.discover(t, modelData.id || null, true)
                            }
                        }
                    }
                }
            }

            // ── My List sub-bar ────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true; height: 78; color: Qt.rgba(0,0,0,0.2)
                visible: moviesPanel.mainTab === 4 && moviesPanel.stack === 0
                ColumnLayout {
                    anchors.fill: parent; spacing: 0
                    Row {
                        Layout.alignment: Qt.AlignHCenter; spacing: 8; Layout.topMargin: 6
                        Repeater {
                            model: [{ label: "Movies", t: "movie" }, { label: "TV Shows", t: "tv" }]
                            Rectangle {
                                width: myTypeLbl.implicitWidth + 20; height: 24; radius: 12
                                color: moviesPanel.myListType === modelData.t
                                    ? root.walColor13 : myTypeMa.containsMouse ? Qt.rgba(1,1,1,0.08) : Qt.rgba(0,0,0,0.3)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Text { id: myTypeLbl; anchors.centerIn: parent; text: modelData.label
                                    font.pixelSize: 10; font.bold: moviesPanel.myListType === modelData.t
                                    font.family: "JetBrainsMono Nerd Font"
                                    color: moviesPanel.myListType === modelData.t ? root.walBackground : root.walColor8 }
                                MouseArea { id: myTypeMa; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: moviesPanel.myListType = modelData.t }
                            }
                        }
                    }
                    ListView {
                        Layout.fillWidth: true; height: 42
                        orientation: ListView.Horizontal; spacing: 6; clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: moviesPanel.statusDefs
                        delegate: Item {
                            width: stPill.implicitWidth + 22; height: 42
                            readonly property bool active: moviesPanel.myListStatus === modelData.key
                            readonly property int cnt:
                                Movies.getUserListProperty(modelData.key, moviesPanel.myListType).length
                            Rectangle {
                                id: stPill; anchors.centerIn: parent
                                implicitWidth: stPillRow.implicitWidth + 20; height: 26; radius: 13
                                color: active ? moviesPanel.statusColor(modelData.key) : Qt.rgba(0,0,0,0.3)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Row { id: stPillRow; anchors.centerIn: parent; spacing: 5
                                    Text { anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.icon; font.pixelSize: 10
                                        font.family: "JetBrainsMono Nerd Font"
                                        color: active ? root.walBackground : root.walColor8 }
                                    Text { anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label; font.pixelSize: 10; font.bold: active
                                        font.family: "JetBrainsMono Nerd Font"
                                        color: active ? root.walBackground : root.walColor8 }
                                    Rectangle {
                                        visible: cnt > 0; width: cntLbl.implicitWidth + 8; height: 16; radius: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: active ? Qt.rgba(0,0,0,0.25) : Qt.rgba(1,1,1,0.15)
                                        Text { id: cntLbl; anchors.centerIn: parent; text: cnt
                                            font.pixelSize: 8; font.bold: true
                                            font.family: "JetBrainsMono Nerd Font"
                                            color: active ? root.walBackground : root.walColor8 }
                                    }
                                }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: moviesPanel.myListStatus = modelData.key }
                        }
                    }
                }
            }

            // ── Content area ───────────────────────────────────────────────
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true

                // ── Reusable media card ────────────────────────────────────
                component MediaCard: Item {
                    id: cardRoot
                    property var itemData: null
                    signal clicked()

                    Rectangle {
                        id: mCard; anchors { fill: parent; margins: 4 }
                        radius: 10; color: Qt.rgba(0,0,0,0.3); clip: true
                        Image {
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: parent.height - mTBar.height
                            source: cardRoot.itemData ? (cardRoot.itemData.poster || "") : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true; cache: false
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 250 } }
                            Rectangle { anchors.fill: parent; color: Qt.rgba(0,0,0,0.4)
                                visible: parent.status !== Image.Ready
                                Text { anchors.centerIn: parent; text: "◫"
                                    font.pixelSize: 24; color: root.walColor8; opacity: 0.3 } }
                            Rectangle {
                                anchors { top: parent.top; left: parent.left; topMargin: 6; leftMargin: 6 }
                                height: 18; width: ratT.implicitWidth + 10; radius: 9
                                color: Qt.rgba(0,0,0,0.75)
                                visible: cardRoot.itemData && cardRoot.itemData.rating > 0
                                Text { id: ratT; anchors.centerIn: parent
                                    text: cardRoot.itemData ? "★ " + (cardRoot.itemData.rating || 0).toFixed(1) : ""
                                    font.pixelSize: 8; font.bold: true
                                    font.family: "JetBrainsMono Nerd Font"; color: "#f5c518" }
                            }
                            Rectangle {
                                anchors { top: parent.top; right: parent.right; topMargin: 6; rightMargin: 6 }
                                height: 18; width: typeT.implicitWidth + 10; radius: 9
                                color: Qt.rgba(0,0,0,0.7)
                                visible: cardRoot.itemData && cardRoot.itemData.type
                                Text { id: typeT; anchors.centerIn: parent
                                    text: cardRoot.itemData
                                        ? (cardRoot.itemData.type === "tv" ? "TV" : "FILM") : ""
                                    font.pixelSize: 8; font.bold: true; font.letterSpacing: 1
                                    font.family: "JetBrainsMono Nerd Font"; color: root.walColor13 }
                            }
                            Rectangle { anchors { bottom: parent.bottom; left: parent.left; right: parent.right } height: 36
                                gradient: Gradient {
                                    GradientStop { position: 0; color: "transparent" }
                                    GradientStop { position: 1; color: Qt.rgba(0,0,0,0.6) } } }
                        }
                        Rectangle { id: mTBar
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                            height: mTitleT.implicitHeight + 14; color: Qt.rgba(0,0,0,0.5)
                            Text { id: mTitleT
                                anchors { left: parent.left; right: parent.right
                                    verticalCenter: parent.verticalCenter; leftMargin: 8; rightMargin: 8 }
                                text: cardRoot.itemData ? (cardRoot.itemData.title || "") : ""
                                font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                                color: root.walForeground; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight }
                        }
                        Rectangle { anchors.fill: parent; radius: 10; color: root.walColor13
                            opacity: cardMa.pressed ? 0.15 : (cardMa.containsMouse ? 0.06 : 0)
                            Behavior on opacity { NumberAnimation { duration: 120 } } }
                        transform: Scale {
                            origin.x: mCard.width/2; origin.y: mCard.height/2
                            xScale: cardMa.pressed ? 0.96 : 1; yScale: cardMa.pressed ? 0.96 : 1
                            Behavior on xScale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                            Behavior on yScale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } } }
                        MouseArea { id: cardMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cardRoot.clicked() }
                    }
                }

                component EmptyState: Column {
                    property string icon: "⊡"
                    property string message: "Nothing here yet"
                    property string hint: ""
                    anchors.centerIn: parent; spacing: 10
                    Text { anchors.horizontalCenter: parent.horizontalCenter
                        text: parent.icon; font.pixelSize: 40; color: root.walColor8; opacity: 0.3
                        font.family: "JetBrainsMono Nerd Font" }
                    Text { anchors.horizontalCenter: parent.horizontalCenter
                        text: parent.message; font.pixelSize: 13
                        font.family: "JetBrainsMono Nerd Font"; color: root.walColor8; opacity: 0.5 }
                    Text { anchors.horizontalCenter: parent.horizontalCenter
                        text: parent.hint; visible: parent.hint !== ""
                        font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                        color: root.walColor8; opacity: 0.35 }
                }

                component MediaGrid: GridView {
                    id: gridRoot
                    property var sourceModel: []
                    signal itemClicked(var item)
                    anchors { fill: parent; margins: 8 }
                    cellWidth: Math.floor(width / 3); cellHeight: cellWidth * 1.65
                    clip: true; boundsBehavior: Flickable.StopAtBounds
                    model: sourceModel
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded
                        contentItem: Rectangle { implicitWidth: 3; color: root.walColor13; opacity: 0.4; radius: 2 } }
                    delegate: Item { width: gridRoot.cellWidth; height: gridRoot.cellHeight
                        MediaCard { anchors.fill: parent; itemData: modelData
                            onClicked: gridRoot.itemClicked(modelData) }
                    }
                }

                // ── TAB 0/1 — BROWSE ──────────────────────────────────────
                Item {
                    anchors.fill: parent
                    visible: moviesPanel.stack === 0
                        && (moviesPanel.mainTab === 0 || moviesPanel.mainTab === 1)

                    Rectangle { anchors.fill: parent; color: "transparent"
                        visible: Movies.isFetching && Movies.itemList.length === 0
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

MediaGrid {
    id: browseGrid
    sourceModel: Movies.itemList
    visible: Movies.itemList.length > 0
    onItemClicked: function(item) {
        Movies.fetchDetail(item.id, item.type); moviesPanel.stack = 1
    }
    property real _savedY: 0
    onContentYChanged: {
        if (contentY > _savedY) _savedY = contentY
        if (!Movies.isFetching && contentY > 100
                && contentY + height > contentHeight - cellHeight * 2)
            Movies.fetchNextPage()
    }
    Connections {
        target: Movies
        function onIsFetchingChanged() {
            if (!Movies.isFetching && browseGrid.contentY < browseGrid._savedY)
                browseGrid.contentY = browseGrid._savedY
        }
        function onCurrentViewChanged() {
            browseGrid._savedY = 0
        }
        function onCurrentTypeChanged() {
            browseGrid._savedY = 0
        }
    }
}
                }

                // ── TAB 2 — WATCHLIST ─────────────────────────────────────
                Item {
                    anchors.fill: parent
                    visible: moviesPanel.stack === 0 && moviesPanel.mainTab === 2

                    EmptyState {
                        visible: (moviesPanel.wlFavType === "tv"
                            ? Movies.watchlistTv.length : Movies.watchlistMovie.length) === 0
                        icon: "󰄲"; message: "Watchlist is empty"
                        hint: "Open any movie/show → Watchlist button"
                    }
                    MediaGrid {
                        sourceModel: Movies.watchlistMovie
                        visible: moviesPanel.wlFavType === "movie" && Movies.watchlistMovie.length > 0
                        onItemClicked: function(item) {
                            Movies.fetchDetail(item.id, item.type); moviesPanel.stack = 1 }
                    }
                    MediaGrid {
                        sourceModel: Movies.watchlistTv
                        visible: moviesPanel.wlFavType === "tv" && Movies.watchlistTv.length > 0
                        onItemClicked: function(item) {
                            Movies.fetchDetail(item.id, item.type); moviesPanel.stack = 1 }
                    }
                }

                // ── TAB 3 — FAVORITES ─────────────────────────────────────
                Item {
                    anchors.fill: parent
                    visible: moviesPanel.stack === 0 && moviesPanel.mainTab === 3

                    EmptyState {
                        visible: (moviesPanel.wlFavType === "tv"
                            ? Movies.favoritesTv.length : Movies.favoritesMovie.length) === 0
                        icon: "󰋑"; message: "Favorites is empty"
                        hint: "Open any movie/show → Favorite button"
                    }
                    MediaGrid {
                        sourceModel: Movies.favoritesMovie
                        visible: moviesPanel.wlFavType === "movie" && Movies.favoritesMovie.length > 0
                        onItemClicked: function(item) {
                            Movies.fetchDetail(item.id, item.type); moviesPanel.stack = 1 }
                    }
                    MediaGrid {
                        sourceModel: Movies.favoritesTv
                        visible: moviesPanel.wlFavType === "tv" && Movies.favoritesTv.length > 0
                        onItemClicked: function(item) {
                            Movies.fetchDetail(item.id, item.type); moviesPanel.stack = 1 }
                    }
                }

                // ── TAB 4 — MY LIST ───────────────────────────────────────
                Item {
                    anchors.fill: parent
                    visible: moviesPanel.stack === 0 && moviesPanel.mainTab === 4

                    property var currentBucket: {
                        // Touch all properties unconditionally so QML tracks all as dependencies
                        var _mw  = Movies.userListMovieWatching
                        var _mc  = Movies.userListMovieCompleted
                        var _mp  = Movies.userListMoviePlanning
                        var _moh = Movies.userListMovieOnHold
                        var _md  = Movies.userListMovieDropped
                        var _tw  = Movies.userListTvWatching
                        var _tc  = Movies.userListTvCompleted
                        var _tp  = Movies.userListTvPlanning
                        var _toh = Movies.userListTvOnHold
                        var _td  = Movies.userListTvDropped
                        var t = moviesPanel.myListType
                        var s = moviesPanel.myListStatus
                        if (t === "movie") {
                            if (s === "watching")  return _mw
                            if (s === "completed") return _mc
                            if (s === "planning")  return _mp
                            if (s === "on_hold")   return _moh
                            if (s === "dropped")   return _md
                        } else {
                            if (s === "watching")  return _tw
                            if (s === "completed") return _tc
                            if (s === "planning")  return _tp
                            if (s === "on_hold")   return _toh
                            if (s === "dropped")   return _td
                        }
                        return []
                    }

                    EmptyState {
                        visible: parent.currentBucket.length === 0
                        icon: moviesPanel.statusIcon(moviesPanel.myListStatus)
                        message: "Nothing " + moviesPanel.statusLabel(moviesPanel.myListStatus).toLowerCase() + " yet"
                        hint: "Open any movie/show → My List button"
                    }

                    MediaGrid {
                        sourceModel: parent.currentBucket
                        visible: parent.currentBucket.length > 0
                        onItemClicked: function(i) {
                            Movies.fetchDetail(i.id, i.type)
                            moviesPanel.stack = 1
                        }
                    }
                }

                // ── TAB 5 — SAVED ─────────────────────────────────────────
                Item {
                    anchors.fill: parent
                    visible: moviesPanel.stack === 0 && moviesPanel.mainTab === 5

                    EmptyState {
                        visible: Movies.libraryList.length === 0
                        icon: "⊡"; message: "Nothing saved locally"
                        hint: "Open any movie → + Saved"
                    }
                    MediaGrid {
                        sourceModel: Movies.libraryList
                        visible: Movies.libraryList.length > 0
                        onItemClicked: function(item) {
                            Movies.fetchDetail(item.id, item.type); moviesPanel.stack = 1 }
                    }
                }

                // ── DETAIL VIEW ───────────────────────────────────────────
                Item {
                    anchors.fill: parent
                    visible: moviesPanel.stack === 1

                    ColumnLayout {
                        anchors.fill: parent; spacing: 0

                        // Back + action header
                        Rectangle {
                            Layout.fillWidth: true; height: 46; color: Qt.rgba(0,0,0,0.3)
                            RowLayout {
                                anchors { fill: parent; leftMargin: 8; rightMargin: 12 } spacing: 6
                                Item { width: 34; height: 34
                                    Rectangle { anchors.fill: parent; radius: 17
                                        color: detBackMa.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent" }
                                    Text { anchors.centerIn: parent; text: "←"; font.pixelSize: 16
                                        color: root.walColor8; font.family: "JetBrainsMono Nerd Font" }
                                    MouseArea { id: detBackMa; anchors.fill: parent; hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Movies.clearDetail()
                                            moviesPanel.stack = 0
                                            moviesPanel.statusMenuOpen = false
                                        }
                                    }
                                }

                                Text { Layout.fillWidth: true
                                    text: Movies.currentItem ? Movies.currentItem.title : ""
                                    font.pixelSize: 13; font.bold: true
                                    font.family: "JetBrainsMono Nerd Font"; color: root.walColor13; elide: Text.ElideRight }

                                Row { spacing: 6
                                    // My List button
                                    Rectangle {
                                        visible: Movies.currentItem !== null; height: 28; radius: 14
                                        width: myListBtnRow.implicitWidth + 16
                                        color: moviesPanel.currentItemListStatus !== ""
                                            ? Qt.rgba(moviesPanel.statusColor(moviesPanel.currentItemListStatus).r,
                                                      moviesPanel.statusColor(moviesPanel.currentItemListStatus).g,
                                                      moviesPanel.statusColor(moviesPanel.currentItemListStatus).b, 0.2)
                                            : myListBtnMa.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(0,0,0,0.3)
                                        border.width: 1
                                        border.color: moviesPanel.currentItemListStatus !== ""
                                            ? moviesPanel.statusColor(moviesPanel.currentItemListStatus)
                                            : root.walColor8
                                        Behavior on color { ColorAnimation { duration: 180 } }
                                        Row { id: myListBtnRow; anchors.centerIn: parent; spacing: 4
                                            Text { anchors.verticalCenter: parent.verticalCenter
                                                text: moviesPanel.currentItemListStatus !== ""
                                                    ? moviesPanel.statusIcon(moviesPanel.currentItemListStatus) : "󰝚"
                                                font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                                                color: moviesPanel.currentItemListStatus !== ""
                                                    ? moviesPanel.statusColor(moviesPanel.currentItemListStatus) : root.walColor8 }
                                            Text { anchors.verticalCenter: parent.verticalCenter
                                                text: moviesPanel.currentItemListStatus !== ""
                                                    ? moviesPanel.statusLabel(moviesPanel.currentItemListStatus) : "My List"
                                                font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                                                color: moviesPanel.currentItemListStatus !== ""
                                                    ? moviesPanel.statusColor(moviesPanel.currentItemListStatus) : root.walColor8 }
                                        }
                                        MouseArea { id: myListBtnMa; anchors.fill: parent; hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: moviesPanel.statusMenuOpen = !moviesPanel.statusMenuOpen }
                                    }

                                    // Watchlist button
                                    Rectangle {
                                        visible: Movies.currentItem !== null; height: 28; radius: 14
                                        property bool inWl: Movies.currentItem
                                            ? Movies.isInWatchlist(Movies.currentItem.id, Movies.currentItem.type) : false
                                        width: wlRow.implicitWidth + 16
                                        color: inWl ? Qt.rgba(root.walColor5.r,root.walColor5.g,root.walColor5.b,0.25) : Qt.rgba(0,0,0,0.3)
                                        border.width: 1; border.color: inWl ? root.walColor5 : root.walColor8
                                        Behavior on color { ColorAnimation { duration: 180 } }
                                        Row { id: wlRow; anchors.centerIn: parent; spacing: 4
                                            Text { anchors.verticalCenter: parent.verticalCenter; text: "󰄲"
                                                font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                                                color: parent.parent.inWl ? root.walColor5 : root.walColor8 }
                                            Text { anchors.verticalCenter: parent.verticalCenter
                                                text: parent.parent.inWl ? "Listed" : "Watchlist"
                                                font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                                                color: parent.parent.inWl ? root.walColor5 : root.walColor8 }
                                        }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                            onClicked: {
                                                if (!Movies.currentItem) return
                                                if (parent.inWl) Movies.removeFromWatchlist(Movies.currentItem)
                                                else Movies.addToWatchlist(Movies.currentItem)
                                            }
                                        }
                                    }

                                    // Favorites button
                                    Rectangle {
                                        visible: Movies.currentItem !== null; height: 28; radius: 14
                                        property bool inFav: Movies.currentItem
                                            ? Movies.isInFavorites(Movies.currentItem.id, Movies.currentItem.type) : false
                                        width: favRow.implicitWidth + 16
                                        color: inFav ? Qt.rgba(root.walColor1.r,root.walColor1.g,root.walColor1.b,0.25) : Qt.rgba(0,0,0,0.3)
                                        border.width: 1; border.color: inFav ? root.walColor1 : root.walColor8
                                        Behavior on color { ColorAnimation { duration: 180 } }
                                        Row { id: favRow; anchors.centerIn: parent; spacing: 4
                                            Text { anchors.verticalCenter: parent.verticalCenter; text: "󰋑"
                                                font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                                                color: parent.parent.inFav ? root.walColor1 : root.walColor8 }
                                            Text { anchors.verticalCenter: parent.verticalCenter
                                                text: parent.parent.inFav ? "Faved" : "Favorite"
                                                font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                                                color: parent.parent.inFav ? root.walColor1 : root.walColor8 }
                                        }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                            onClicked: {
                                                if (!Movies.currentItem) return
                                                if (parent.inFav) Movies.removeFromFavorites(Movies.currentItem)
                                                else Movies.addToFavorites(Movies.currentItem)
                                            }
                                        }
                                    }

                                    // Local Save
                                    Rectangle {
                                        visible: Movies.currentItem !== null; height: 28; radius: 14
                                        property bool saved: Movies.currentItem
                                            ? Movies.isInLibrary(Movies.currentItem.id, Movies.currentItem.type) : false
                                        width: savedRow.implicitWidth + 16
                                        color: saved ? Qt.rgba(root.walColor2.r,root.walColor2.g,root.walColor2.b,0.25) : Qt.rgba(0,0,0,0.3)
                                        border.width: 1; border.color: saved ? root.walColor2 : root.walColor8
                                        Behavior on color { ColorAnimation { duration: 180 } }
                                        Row { id: savedRow; anchors.centerIn: parent; spacing: 4
                                            Text { anchors.verticalCenter: parent.verticalCenter
                                                text: parent.parent.saved ? "✓" : "+"
                                                font.pixelSize: 11; font.bold: true
                                                font.family: "JetBrainsMono Nerd Font"
                                                color: parent.parent.saved ? root.walColor2 : root.walColor8 }
                                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Saved"
                                                font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
                                                color: parent.parent.saved ? root.walColor2 : root.walColor8 }
                                        }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                            onClicked: {
                                                if (!Movies.currentItem) return
                                                if (parent.saved) Movies.removeFromLibrary(Movies.currentItem.id, Movies.currentItem.type)
                                                else Movies.addToLibrary(Movies.currentItem)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Loading
                        Item { Layout.fillWidth: true; Layout.fillHeight: true
                            visible: Movies.isFetchingDetail
                            Column { anchors.centerIn: parent; spacing: 10
                                Rectangle { width: 28; height: 28; radius: 14
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: "transparent"; border.color: root.walColor13; border.width: 2
                                    RotationAnimator on rotation { from: 0; to: 360; duration: 800
                                        loops: Animation.Infinite; running: parent.visible; easing.type: Easing.Linear } }
                                Text { anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Loading details..."; color: root.walColor8
                                    font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font" }
                            }
                        }

                        // Detail scroll content
                        ScrollView {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            visible: !Movies.isFetchingDetail && Movies.currentItem !== null
                            clip: true; ScrollBar.vertical.policy: ScrollBar.AsNeeded

                            ColumnLayout {
                                width: moviesPanel.implicitWidth - 20; spacing: 12
                                Item { height: 8 }

                                Rectangle {
                                    Layout.fillWidth: true; Layout.leftMargin: 10; Layout.rightMargin: 10
                                    height: 180; radius: 12; clip: true; color: Qt.rgba(0,0,0,0.3)
                                    Image {
                                        anchors.fill: parent
                                        source: Movies.currentItem ? Movies.currentItem.backdrop : ""
                                        fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: false
                                        opacity: status === Image.Ready ? 0.7 : 0
                                        Behavior on opacity { NumberAnimation { duration: 300 } }
                                    }
                                    Rectangle { anchors.fill: parent
                                        gradient: Gradient {
                                            GradientStop { position: 0; color: "transparent" }
                                            GradientStop { position: 0.6; color: Qt.rgba(0,0,0,0.8) } } }
                                    Column {
                                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right
                                            margins: 14; bottomMargin: 12 } spacing: 4
                                        Row { spacing: 8
                                            Rectangle { height: 20; width: ratBadge.implicitWidth + 12; radius: 10
                                                color: Qt.rgba(0,0,0,0.7)
                                                Text { id: ratBadge; anchors.centerIn: parent
                                                    text: Movies.currentItem ? "★ " + Movies.currentItem.rating.toFixed(1) : ""
                                                    font.pixelSize: 10; font.bold: true
                                                    font.family: "JetBrainsMono Nerd Font"; color: "#f5c518" } }
                                            Rectangle { height: 20; width: yrBadge.implicitWidth + 12; radius: 10
                                                color: Qt.rgba(0,0,0,0.7)
                                                visible: Movies.currentItem && Movies.currentItem.releaseDate.length > 0
                                                Text { id: yrBadge; anchors.centerIn: parent
                                                    text: Movies.currentItem ? Movies.currentItem.releaseDate.substring(0,4) : ""
                                                    font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; color: root.walForeground } }
                                            Rectangle { height: 20; width: rtBadge.implicitWidth + 12; radius: 10
                                                color: Qt.rgba(0,0,0,0.7)
                                                visible: Movies.currentItem && Movies.currentItem.runtime
                                                Text { id: rtBadge; anchors.centerIn: parent
                                                    text: Movies.currentItem && Movies.currentItem.runtime ? Movies.currentItem.runtime + " min" : ""
                                                    font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; color: root.walForeground } }
                                        }
                                        Text { text: Movies.currentItem ? (Movies.currentItem.tagline || "") : ""
                                            font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"
                                            color: root.walColor13; opacity: 0.85
                                            visible: Movies.currentItem && Movies.currentItem.tagline }
                                    }
                                }

                                Flow { Layout.fillWidth: true; Layout.leftMargin: 12; Layout.rightMargin: 12; spacing: 6
                                    visible: Movies.currentItem && Movies.currentItem.genres.length > 0
                                    Repeater { model: Movies.currentItem ? Movies.currentItem.genres.slice(0,5) : []
                                        Rectangle { height: 22; width: gT.implicitWidth + 16; radius: 11
                                            color: Qt.rgba(root.walColor13.r,root.walColor13.g,root.walColor13.b,0.15)
                                            border.color: Qt.rgba(root.walColor13.r,root.walColor13.g,root.walColor13.b,0.4); border.width: 1
                                            Text { id: gT; anchors.centerIn: parent; text: modelData
                                                font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; color: root.walColor13 } }
                                    }
                                }

                                Text { Layout.fillWidth: true; Layout.leftMargin: 14; Layout.rightMargin: 14
                                    text: Movies.currentItem ? Movies.currentItem.overview : ""
                                    font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font"
                                    color: root.walForeground; wrapMode: Text.Wrap; lineHeight: 1.5; opacity: 0.85 }

                                Column { Layout.fillWidth: true; Layout.leftMargin: 12; Layout.rightMargin: 12; spacing: 8
                                    visible: Movies.currentItem && Movies.currentItem.streaming.length > 0
                                    Text { text: "STREAMING ON"; font.pixelSize: 9; font.bold: true
                                        font.letterSpacing: 1.5; font.family: "JetBrainsMono Nerd Font"
                                        color: root.walColor8; opacity: 0.7 }
                                    Row { spacing: 8
                                        Repeater { model: Movies.currentItem ? Movies.currentItem.streaming.slice(0,5) : []
                                            Column { spacing: 4
                                                Rectangle { width: 48; height: 48; radius: 10
                                                    color: Qt.rgba(0,0,0,0.3); clip: true
                                                    Image { anchors.fill: parent; source: modelData.logo
                                                        fillMode: Image.PreserveAspectFit; asynchronous: true; cache: true } }
                                                Text { anchors.horizontalCenter: parent.horizontalCenter
                                                    text: modelData.name; font.pixelSize: 8
                                                    font.family: "JetBrainsMono Nerd Font"; color: root.walColor8
                                                    width: 52; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter }
                                            }
                                        }
                                    }
                                }

                                Row { Layout.leftMargin: 14; spacing: 16
                                    visible: Movies.currentItem && Movies.currentItem.type === "tv"
                                    Column { spacing: 2
                                        Text { text: Movies.currentItem ? String(Movies.currentItem.seasons || "?") : "?"
                                            font.pixelSize: 22; font.bold: true
                                            font.family: "JetBrainsMono Nerd Font"; color: root.walColor13 }
                                        Text { text: "seasons"; font.pixelSize: 10
                                            font.family: "JetBrainsMono Nerd Font"; color: root.walColor8 }
                                    }
                                    Column { spacing: 2
                                        Text { text: Movies.currentItem ? String(Movies.currentItem.episodes || "?") : "?"
                                            font.pixelSize: 22; font.bold: true
                                            font.family: "JetBrainsMono Nerd Font"; color: root.walColor5 }
                                        Text { text: "episodes"; font.pixelSize: 10
                                            font.family: "JetBrainsMono Nerd Font"; color: root.walColor8 }
                                    }
                                }

                                Rectangle { Layout.leftMargin: 12
                                    height: 36; width: trailerRow.implicitWidth + 24; radius: 18
                                    color: Qt.rgba(root.walColor1.r,root.walColor1.g,root.walColor1.b,0.2)
                                    border.color: root.walColor1; border.width: 1
                                    visible: Movies.currentItem && Movies.currentItem.trailers.length > 0
                                    Row { id: trailerRow; anchors.centerIn: parent; spacing: 8
                                        Text { anchors.verticalCenter: parent.verticalCenter; text: "▶"; font.pixelSize: 14; color: root.walColor1 }
                                        Text { anchors.verticalCenter: parent.verticalCenter; text: "Watch Trailer"
                                            font.pixelSize: 12; font.bold: true; font.family: "JetBrainsMono Nerd Font"; color: root.walColor1 }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (!Movies.currentItem || Movies.currentItem.trailers.length === 0) return
                                            trailerProc.command = ["xdg-open",
                                                "https://www.youtube.com/watch?v=" + Movies.currentItem.trailers[0].key]
                                            trailerProc.running = true
                                        }
                                    }
                                }

                                Column { Layout.fillWidth: true; Layout.leftMargin: 12; Layout.rightMargin: 12; spacing: 8
                                    visible: Movies.currentItem && Movies.currentItem.cast.length > 0
                                    Text { text: "CAST"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.5
                                        font.family: "JetBrainsMono Nerd Font"; color: root.walColor8; opacity: 0.7 }
                                    ListView { width: parent.width; height: 80
                                        orientation: ListView.Horizontal; spacing: 10; clip: true
                                        boundsBehavior: Flickable.StopAtBounds
                                        model: Movies.currentItem ? Movies.currentItem.cast.slice(0,8) : []
                                        delegate: Column { spacing: 5
                                            Rectangle { width: 52; height: 52; radius: 26
                                                color: Qt.rgba(0,0,0,0.4); clip: true
                                                Image { anchors.fill: parent; source: modelData.photo
                                                    fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: true } }
                                            Text { width: 60; text: modelData.name; font.pixelSize: 8
                                                font.family: "JetBrainsMono Nerd Font"; color: root.walForeground
                                                wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                                                horizontalAlignment: Text.AlignHCenter }
                                        }
                                    }
                                }

                                Column { Layout.fillWidth: true; Layout.leftMargin: 12; Layout.rightMargin: 12; spacing: 8
                                    visible: Movies.currentItem && Movies.currentItem.similar.length > 0
                                    Text { text: "SIMILAR"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1.5
                                        font.family: "JetBrainsMono Nerd Font"; color: root.walColor8; opacity: 0.7 }
                                    ListView { width: parent.width; height: 140
                                        orientation: ListView.Horizontal; spacing: 8; clip: true
                                        boundsBehavior: Flickable.StopAtBounds
                                        model: Movies.currentItem ? Movies.currentItem.similar.slice(0,8) : []
                                        delegate: Item { width: 90; height: 140
                                            Rectangle { id: simCard; anchors.fill: parent; radius: 8; color: Qt.rgba(0,0,0,0.3); clip: true
                                                Image { anchors { top: parent.top; left: parent.left; right: parent.right }
                                                    height: parent.height - simTBar.height; source: modelData.poster
                                                    fillMode: Image.PreserveAspectCrop; asynchronous: true; cache: true }
                                                Rectangle { id: simTBar; anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                                    height: simT.implicitHeight + 10; color: Qt.rgba(0,0,0,0.5)
                                                    Text { id: simT; anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 5; rightMargin: 5 }
                                                        text: modelData.title; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; color: root.walForeground
                                                        wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight } }
                                                Rectangle { anchors.fill: parent; radius: 8; color: root.walColor13
                                                    opacity: simMa.pressed ? 0.15 : (simMa.containsMouse ? 0.06 : 0) }
                                                MouseArea { id: simMa; anchors.fill: parent; hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: Movies.fetchDetail(modelData.id, modelData.type) }
                                            }
                                        }
                                    }
                                }
                                Item { height: 16 }
                            }
                        }
                    }
                }
            }
        }
    }

    Process { id: trailerProc }

    Connections {
        target: root
        function onMoviesPanelVisibleChanged() {
            if (root.moviesPanelVisible) {
                moviesPanel.stack = 0
                moviesPanel.statusMenuOpen = false
                mFocusTimer.start()
                Movies.fetchLocalWatchlist("movie")
                Movies.fetchLocalWatchlist("tv")
                Movies.fetchLocalFavorites("movie")
                Movies.fetchLocalFavorites("tv")
                Movies.fetchAllUserLists("movie")
                Movies.fetchAllUserLists("tv")
            } else {
                moviesPanel.stack = 0
                moviesPanel.statusMenuOpen = false
            }
        }
    }

    Timer { id: mFocusTimer; interval: 50; repeat: false
        onTriggered: { moviesPanel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive; mRelTimer.start() } }
    Timer { id: mRelTimer; interval: 100; repeat: false
        onTriggered: moviesPanel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand }
}
