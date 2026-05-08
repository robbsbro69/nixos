pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string apiUrl: "http://127.0.0.1:5250"

    // ── Browse ────────────────────────────────────────────────────────────────
   property list<var> itemList: []
	property bool isFetching: false
    property string fetchError: ""
	property bool hasMore: false
	signal itemsAppended()
    property int currentPage: 1
    property string currentType: "movie"
    property string currentView: "trending"
    property string currentSearch: ""
    property string currentGenreId: ""
    property list<var> genreList: []

    // ── Detail ────────────────────────────────────────────────────────────────
    property var currentItem: null
    property bool isFetchingDetail: false
    property string detailError: ""

    // ── Account ───────────────────────────────────────────────────────────────
    property bool hasAccount: false
    property string accountId: ""

    // ── Local DB watchlist / favorites — separate named props per type ─────────
    property var watchlistMovie: []
    property var watchlistTv: []
    property var favoritesMovie: []
    property var favoritesTv: []

    property bool isFetchingWatchlist: false
    property bool isFetchingFavorites: false

    // ── Local userlist — stored as flat arrays per status+type ────────────────
    property var userListMovieWatching:  []
    property var userListMovieCompleted: []
    property var userListMoviePlanning:  []
    property var userListMovieOnHold:    []
    property var userListMovieDropped:   []

    property var userListTvWatching:  []
    property var userListTvCompleted: []
    property var userListTvPlanning:  []
    property var userListTvOnHold:    []
    property var userListTvDropped:   []

    property bool isFetchingUserList: false

    readonly property var userListStatuses: [
        { key: "watching",  label: "Watching",   icon: "󰐊", color: "#89b4fa" },
        { key: "completed", label: "Completed",  icon: "󰄬", color: "#a6e3a1" },
        { key: "planning",  label: "Planning",   icon: "󰃯", color: "#f5c2e7" },
        { key: "on_hold",   label: "On Hold",    icon: "⏸", color: "#f9e2af" },
        { key: "dropped",   label: "Dropped",    icon: "󰅖", color: "#f38ba8" }
    ]

    // ── Local quick-save library ──────────────────────────────────────────────
    property list<var> libraryList: []
    property bool libraryLoaded: false
    readonly property string _libPath:
        Quickshell.env("HOME") + "/.local/share/quickshell/movies_library.json"

    FileView { id: libFile; path: root._libPath
        onLoaded: {
            try { root.libraryList = JSON.parse(libFile.text()) || [] }
            catch(e) { root.libraryList = [] }
            root.libraryLoaded = true
        }
        onLoadFailed: { root.libraryList = []; root.libraryLoaded = true }
    }
    FileView { id: libWriter; path: root._libPath }

    function _saveLib() {
        libWriter.setText(JSON.stringify(root.libraryList, null, 2))
        libWriter.save()
    }
    function addToLibrary(item) {
        if (isInLibrary(item.id, item.type)) return
        var entry = Object.assign({}, item, { addedAt: new Date().toISOString() })
        root.libraryList = [entry, ...root.libraryList]
        _saveLib()
    }
    function removeFromLibrary(id, type) {
        root.libraryList = root.libraryList.filter(e => !(e.id === id && e.type === type))
        _saveLib()
    }
    function isInLibrary(id, type) {
        return root.libraryList.some(e => String(e.id) === String(id) && e.type === type)
    }

    Component.onCompleted: {
        libFile.reload()
    }

    // ── Backend server ────────────────────────────────────────────────────────
    property bool serverReady: false

    Process {
        id: serverProc
        command: [Quickshell.env("HOME") + "/.venv/movies/bin/python3",
                  Quickshell.env("HOME") + "/.config/quickshell/scripts/movies_server.py"]
        running: true
        onExited: (code) => {
            console.warn("[Movies] server exited", code, "— restarting in 2s")
            root.serverReady = false
            serverRestartTimer.start()
        }
    }
    Timer {
        id: serverRestartTimer; interval: 2000; repeat: false
        onTriggered: serverProc.running = true
    }

    Timer {
        id: healthPoll; interval: 200; repeat: true; running: true
        onTriggered: {
            var xhr = new XMLHttpRequest()
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                    healthPoll.stop()
                    try {
                        var d = JSON.parse(xhr.responseText)
                        root.hasAccount = d.hasAccount || false
                        root.accountId  = d.accountId  || ""
                    } catch(e) {}
                    root.serverReady = true
                    root.fetchGenres("movie")
                    root.fetchGenres("tv")
                    root.fetchTrending("movie", true)
                    root.fetchLocalWatchlist("movie")
                    root.fetchLocalWatchlist("tv")
                    root.fetchLocalFavorites("movie")
                    root.fetchLocalFavorites("tv")
                    root.fetchAllUserLists("movie")
                    root.fetchAllUserLists("tv")
                }
            }
            xhr.open("GET", root.apiUrl + "/health")
            xhr.send()
        }
    }

    // ── HTTP helpers ──────────────────────────────────────────────────────────
    function _get(url, cb) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status === 200) cb(null, xhr.responseText)
            else cb("HTTP " + xhr.status, null)
        }
        xhr.open("GET", url)
        xhr.send()
    }

    function _post(url, data, cb) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status === 200) cb(null, xhr.responseText)
            else cb("HTTP " + xhr.status, null)
        }
        xhr.open("POST", url)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send(JSON.stringify(data))
    }

    // ── Genre cache ───────────────────────────────────────────────────────────
    property var _movieGenres: ({})
    property var _tvGenres: ({})

    function fetchGenres(type) {
        _get(apiUrl + "/genres?type=" + type, function(err, body) {
            if (err) return
            try {
                var list = JSON.parse(body)
                var map  = {}
                list.forEach(function(g) { map[g.id] = g.name })
                if (type === "movie") root._movieGenres = map
                else root._tvGenres = map
                root.genreList = list
            } catch(e) {}
        })
    }

    function genreName(id, type) {
        var map = type === "tv" ? root._tvGenres : root._movieGenres
        return map[id] || ""
    }

    // ── Browse ────────────────────────────────────────────────────────────────
    function fetchTrending(type, reset) {
        if (isFetching) return
        if (reset) { itemList = []; currentPage = 1 }
        currentType    = type
        currentView    = "trending"
        currentSearch  = ""
        currentGenreId = ""
        isFetching = true; fetchError = ""
        _get(apiUrl + "/trending?type=" + type + "&page=" + currentPage,
            function(err, body) {
                if (err) { fetchError = err; isFetching = false; return }
                _parseList(body)
            })
    }

    function search(query, type, reset) {
        if (isFetching) return
        if (reset) { itemList = []; currentPage = 1 }
        currentType   = type || currentType
        currentView   = "search"
        currentSearch = query
        isFetching = true; fetchError = ""
        _get(apiUrl + "/search?q=" + encodeURIComponent(query)
                + "&type=" + currentType + "&page=" + currentPage,
            function(err, body) {
                if (err) { fetchError = err; isFetching = false; return }
                _parseList(body)
            })
    }

    function discover(type, genreId, reset) {
        if (isFetching) return
        if (reset) { itemList = []; currentPage = 1 }
        currentType    = type
        currentView    = "discover"
        currentSearch  = ""
        currentGenreId = genreId || ""
        isFetching = true; fetchError = ""
        var url = apiUrl + "/discover?type=" + currentType + "&page=" + currentPage
        if (genreId) url += "&genre=" + genreId
        _get(url, function(err, body) {
            if (err) { fetchError = err; isFetching = false; return }
            _parseList(body)
        })
    }

function _parseList(json) {
    try {
        var data = JSON.parse(json)
        if (data.error) { fetchError = data.error; isFetching = false; return }
        var incoming = data.results || []
        var isAppend = itemList.length > 0
        if (!isAppend) {
            itemList = incoming
        } else {
            var seen = {}
            for (var k = 0; k < itemList.length; k++)
                seen[String(itemList[k].id) + ":" + (itemList[k].type||"")] = true
            var fresh = []
            for (var j = 0; j < incoming.length; j++) {
                var key = String(incoming[j].id) + ":" + (incoming[j].type||"")
                if (!seen[key]) fresh.push(incoming[j])
            }
            if (fresh.length > 0)
                itemList = itemList.concat(fresh)
        }
        hasMore    = currentPage < (data.totalPages || 1)
        fetchError = ""
    } catch(e) { fetchError = "Parse error: " + e }
    isFetching = false
}

    function fetchNextPage() {
        if (!hasMore || isFetching) return
        currentPage++
        if (currentView === "trending")      fetchTrending(currentType, false)
        else if (currentView === "search")   search(currentSearch, currentType, false)
        else if (currentView === "discover") discover(currentType, currentGenreId, false)
    }

    // ── Detail ────────────────────────────────────────────────────────────────
    function fetchDetail(id, type) {
        if (isFetchingDetail) return
        isFetchingDetail = true
        currentItem      = null
        detailError      = ""
        _get(apiUrl + "/detail?id=" + id + "&type=" + type, function(err, body) {
            if (err) { detailError = err; isFetchingDetail = false; return }
            try {
                var data = JSON.parse(body)
                if (data.error) detailError = data.error
                else currentItem = data
            } catch(e) { detailError = "Parse error: " + e }
            isFetchingDetail = false
        })
    }

    function clearDetail() { currentItem = null; detailError = "" }

    // ── Local DB watchlist ────────────────────────────────────────────────────
    function fetchLocalWatchlist(type) {
        _get(apiUrl + "/local/watchlist?type=" + type, function(err, body) {
            if (err) { console.warn("[Movies] watchlist fetch error:", err); return }
            try {
                var d = JSON.parse(body)
                var results = d.results || []
                // Always assign to both props to keep bindings alive
                if (type === "movie") root.watchlistMovie = results
                else root.watchlistTv = results
            } catch(e) { console.warn("[Movies] watchlist parse error:", e) }
        })
    }

    function fetchLocalFavorites(type) {
        _get(apiUrl + "/local/favorites?type=" + type, function(err, body) {
            if (err) { console.warn("[Movies] favorites fetch error:", err); return }
            try {
                var d = JSON.parse(body)
                var results = d.results || []
                if (type === "movie") root.favoritesMovie = results
                else root.favoritesTv = results
            } catch(e) { console.warn("[Movies] favorites parse error:", e) }
        })
    }

    function getWatchlist(type) {
        return type === "tv" ? root.watchlistTv : root.watchlistMovie
    }

    function getFavorites(type) {
        return type === "tv" ? root.favoritesTv : root.favoritesMovie
    }

    function isInWatchlist(id, type) {
        var list = type === "tv" ? root.watchlistTv : root.watchlistMovie
        return list.some(e => String(e.id) === String(id))
    }

    function isInFavorites(id, type) {
        var list = type === "tv" ? root.favoritesTv : root.favoritesMovie
        return list.some(e => String(e.id) === String(id))
    }

    // ── Watchlist add/remove ───────────────────────────────────────────────────
    function addToWatchlist(item) {
        var mt = item.type || "movie"
        // Optimistic update
        if (!isInWatchlist(item.id, mt)) {
            var entry = Object.assign({}, item)
            if (mt === "movie") root.watchlistMovie = [entry, ...root.watchlistMovie]
            else root.watchlistTv = [entry, ...root.watchlistTv]
        }
        if (hasAccount) {
            _post(apiUrl + "/account/watchlist/add",
                { media_id: item.id, media_type: mt },
                function(err) { root.fetchLocalWatchlist(mt) })
        } else {
            _post(apiUrl + "/local/watchlist/add",
                { item: item, media_type: mt },
                function(err) { root.fetchLocalWatchlist(mt) })
        }
    }

    function removeFromWatchlist(item) {
        var mt = item.type || "movie"
        // Optimistic update
        if (mt === "movie")
            root.watchlistMovie = root.watchlistMovie.filter(e => String(e.id) !== String(item.id))
        else
            root.watchlistTv = root.watchlistTv.filter(e => String(e.id) !== String(item.id))

        if (hasAccount) {
            _post(apiUrl + "/account/watchlist/remove",
                { media_id: item.id, media_type: mt },
                function(err) { root.fetchLocalWatchlist(mt) })
        } else {
            _post(apiUrl + "/local/watchlist/remove",
                { id: item.id, media_type: mt },
                function(err) { root.fetchLocalWatchlist(mt) })
        }
    }

    // ── Favorites add/remove ──────────────────────────────────────────────────
    function addToFavorites(item) {
        var mt = item.type || "movie"
        // Optimistic update
        if (!isInFavorites(item.id, mt)) {
            var entry = Object.assign({}, item)
            if (mt === "movie") root.favoritesMovie = [entry, ...root.favoritesMovie]
            else root.favoritesTv = [entry, ...root.favoritesTv]
        }
        if (hasAccount) {
            _post(apiUrl + "/account/favorites/add",
                { media_id: item.id, media_type: mt },
                function(err) { root.fetchLocalFavorites(mt) })
        } else {
            _post(apiUrl + "/local/favorites/add",
                { item: item, media_type: mt },
                function(err) { root.fetchLocalFavorites(mt) })
        }
    }

    function removeFromFavorites(item) {
        var mt = item.type || "movie"
        // Optimistic update
        if (mt === "movie")
            root.favoritesMovie = root.favoritesMovie.filter(e => String(e.id) !== String(item.id))
        else
            root.favoritesTv = root.favoritesTv.filter(e => String(e.id) !== String(item.id))

        if (hasAccount) {
            _post(apiUrl + "/account/favorites/remove",
                { media_id: item.id, media_type: mt },
                function(err) { root.fetchLocalFavorites(mt) })
        } else {
            _post(apiUrl + "/local/favorites/remove",
                { id: item.id, media_type: mt },
                function(err) { root.fetchLocalFavorites(mt) })
        }
    }

    function syncFromTmdb(type) {
        if (!hasAccount) return
        _get(apiUrl + "/local/sync?type=" + type, function(err, body) {
            if (!err) {
                Qt.callLater(function() {
                    fetchLocalWatchlist(type)
                    fetchLocalFavorites(type)
                })
            }
        })
    }

    // ── Local userlist — named properties so QML bindings react ──────────────
    function fetchAllUserLists(type) {
        _get(apiUrl + "/userlist/all?type=" + type, function(err, body) {
            if (err) { console.warn("[Movies] userlist fetch error:", err); return }
            try {
                var d = JSON.parse(body)
                if (type === "movie") {
                    root.userListMovieWatching  = d.watching  || []
                    root.userListMovieCompleted = d.completed || []
                    root.userListMoviePlanning  = d.planning  || []
                    root.userListMovieOnHold    = d.on_hold   || []
                    root.userListMovieDropped   = d.dropped   || []
                } else {
                    root.userListTvWatching  = d.watching  || []
                    root.userListTvCompleted = d.completed || []
                    root.userListTvPlanning  = d.planning  || []
                    root.userListTvOnHold    = d.on_hold   || []
                    root.userListTvDropped   = d.dropped   || []
                }
            } catch(e) { console.warn("[Movies] userlist parse error:", e) }
        })
    }

    // Return the named property for a given status+type — keeps bindings reactive
    function getUserListProperty(status, type) {
        var t = type || "movie"
        if (t === "movie") {
            if (status === "watching")  return root.userListMovieWatching
            if (status === "completed") return root.userListMovieCompleted
            if (status === "planning")  return root.userListMoviePlanning
            if (status === "on_hold")   return root.userListMovieOnHold
            if (status === "dropped")   return root.userListMovieDropped
        } else {
            if (status === "watching")  return root.userListTvWatching
            if (status === "completed") return root.userListTvCompleted
            if (status === "planning")  return root.userListTvPlanning
            if (status === "on_hold")   return root.userListTvOnHold
            if (status === "dropped")   return root.userListTvDropped
        }
        return []
    }

    // Status badge lookup — reads named props so bindings stay reactive
    function getUserListStatus(id, type) {
        var t = type || "movie"
        var allBuckets = t === "movie"
            ? [root.userListMovieWatching, root.userListMovieCompleted,
               root.userListMoviePlanning, root.userListMovieOnHold,
               root.userListMovieDropped]
            : [root.userListTvWatching, root.userListTvCompleted,
               root.userListTvPlanning, root.userListTvOnHold,
               root.userListTvDropped]
        var keys = ["watching", "completed", "planning", "on_hold", "dropped"]
        for (var i = 0; i < allBuckets.length; i++) {
            var bucket = allBuckets[i]
            for (var j = 0; j < bucket.length; j++) {
                if (String(bucket[j].id) === String(id)) return keys[i]
            }
        }
        return ""
    }

    function addToUserList(item, status) {
        var mt = item.type || "movie"
        // Optimistic update
        var entry = Object.assign({}, item, { status: status, type: mt })
        _setUserListBucket(mt, status, [entry, ...getUserListProperty(status, mt)])

        _post(apiUrl + "/userlist/add",
            { id: item.id, type: mt, status: status, item: item },
            function(err, body) {
                if (err) { console.warn("[Movies] userlist add error:", err); return }
                root.fetchAllUserLists(mt)
            })
    }

    function updateUserListStatus(item, newStatus) {
        var mt     = item.type || "movie"
        var oldSt  = getUserListStatus(item.id, mt)
        // Optimistic: remove from old bucket, add to new
        if (oldSt) {
            _setUserListBucket(mt, oldSt,
                getUserListProperty(oldSt, mt).filter(e => String(e.id) !== String(item.id)))
        }
        var entry = Object.assign({}, item, { status: newStatus, type: mt })
        _setUserListBucket(mt, newStatus, [entry, ...getUserListProperty(newStatus, mt)])

        _post(apiUrl + "/userlist/update",
            { id: item.id, type: mt, status: newStatus },
            function(err, body) {
                if (err) { console.warn("[Movies] userlist update error:", err); return }
                root.fetchAllUserLists(mt)
            })
    }

    function removeFromUserList(item) {
        var mt   = item.type || "movie"
        var oldSt = getUserListStatus(item.id, mt)
        // Optimistic removal
        if (oldSt) {
            _setUserListBucket(mt, oldSt,
                getUserListProperty(oldSt, mt).filter(e => String(e.id) !== String(item.id)))
        }

        _post(apiUrl + "/userlist/remove",
            { id: item.id, type: mt },
            function(err, body) {
                if (err) { console.warn("[Movies] userlist remove error:", err); return }
                root.fetchAllUserLists(mt)
            })
    }

    // Helper: set a named bucket property so QML bindings fire
    function _setUserListBucket(type, status, arr) {
        if (type === "movie") {
            if (status === "watching")  { root.userListMovieWatching  = arr; return }
            if (status === "completed") { root.userListMovieCompleted = arr; return }
            if (status === "planning")  { root.userListMoviePlanning  = arr; return }
            if (status === "on_hold")   { root.userListMovieOnHold    = arr; return }
            if (status === "dropped")   { root.userListMovieDropped   = arr; return }
        } else {
            if (status === "watching")  { root.userListTvWatching  = arr; return }
            if (status === "completed") { root.userListTvCompleted = arr; return }
            if (status === "planning")  { root.userListTvPlanning  = arr; return }
            if (status === "on_hold")   { root.userListTvOnHold    = arr; return }
            if (status === "dropped")   { root.userListTvDropped   = arr; return }
        }
    }

    function totalUserListCount(type) {
        var t = type || "movie"
        if (t === "movie") {
            return root.userListMovieWatching.length + root.userListMovieCompleted.length
                 + root.userListMoviePlanning.length + root.userListMovieOnHold.length
                 + root.userListMovieDropped.length
        } else {
            return root.userListTvWatching.length + root.userListTvCompleted.length
                 + root.userListTvPlanning.length + root.userListTvOnHold.length
                 + root.userListTvDropped.length
        }
    }

    function setType(type) {
        if (type === currentType) return
        currentType = type
        if (currentView === "trending") fetchTrending(type, true)
        else if (currentView === "discover") discover(type, currentGenreId, true)
    }
}
