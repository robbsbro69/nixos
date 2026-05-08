pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string apiUrl: "http://127.0.0.1:5050"

    property var animeList: []
    property bool isFetchingAnime: false
    property string animeError: ""
    property bool hasMoreAnime: false
    property int popularPage: 1
    property int latestPage: 1
    property string currentSearchText: ""
    property string currentMode: "sub"
    property string currentCountry: "ALL"
    property string currentView: ""

    // signal emitted ONLY on append (not on reset) so GridView can save/restore scroll
    signal itemsAppended()

    property var currentAnime: null
    property bool isFetchingDetail: false
    property string detailError: ""

    property var streamLinks: []
    property var selectedLink: null
    property bool isFetchingLinks: false
    property string linksError: ""
    property string currentEpisode: ""

    property var libraryAll: ({
        watching: [], completed: [], planning: [],
        on_hold: [], dropped: [], rewatching: []
    })
    property bool libraryLoaded: false

    readonly property var libraryStatuses: [
        { key: "watching",   label: "Watching",    icon: "󰐊", color: "#89b4fa" },
        { key: "completed",  label: "Completed",   icon: "󰄬", color: "#a6e3a1" },
        { key: "planning",   label: "Planning",    icon: "󰃯", color: "#f5c2e7" },
        { key: "on_hold",    label: "On Hold",     icon: "⏸", color: "#f9e2af" },
        { key: "dropped",    label: "Dropped",     icon: "󰅖", color: "#f38ba8" },
        { key: "rewatching", label: "Rewatching",  icon: "󰑓", color: "#89b4fa" }
    ]

    property bool serverReady: false

    Process {
        id: serverProcess
        command: [Quickshell.env("HOME") + "/ani-env/bin/python3",
            Quickshell.env("HOME") + "/.config/quickshell/scripts/anime_server.py"]
        running: true
        onExited: (code) => {
            console.warn("[Anime] Server exited with code", code, "— restarting")
            root.serverReady = false
            serverRestartTimer.start()
        }
    }
    Timer { id: serverRestartTimer; interval: 3000; repeat: false
        onTriggered: serverProcess.running = true }

    Timer {
        id: healthPoller
        interval: 150; repeat: true; running: true
        onTriggered: {
            var xhr = new XMLHttpRequest()
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                    healthPoller.stop()
                    root.serverReady = true
                    fetchPopular()
                    fetchAllLibrary()
                }
            }
            xhr.open("GET", root.apiUrl + "/health")
            xhr.send()
        }
    }

    function _get(url, onDone) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status === 200) onDone(null, xhr.responseText)
            else onDone("HTTP " + xhr.status, null)
        }
        xhr.open("GET", url)
        xhr.send()
    }

    function _post(url, data, onDone) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status === 200) onDone(null, xhr.responseText)
            else onDone("HTTP " + xhr.status, null)
        }
        xhr.open("POST", url)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send(JSON.stringify(data))
    }

    // ── Browse — "reset" clears list, "append" emits itemsAppended signal ─
    function fetchPopular(reset) {
        if (isFetchingAnime) return
        if (reset === undefined || reset) { animeList = []; popularPage = 1 }
        currentView = "popular"; currentSearchText = ""
        isFetchingAnime = true; animeError = ""
        _get(root.apiUrl + "/popular?size=20&page=" + popularPage,
            function(err, body) {
                isFetchingAnime = false
                if (err) { animeError = err; return }
                try {
                    var d = JSON.parse(body)
                    if (d.error) { animeError = d.error; return }
                    var items = (d.shows || []).map(_normaliseShow)
                    var isAppend = animeList.length > 0
                    animeList = animeList.concat(items)
                    hasMoreAnime = (popularPage * 20) < (d.total || 0)
                    if (isAppend) root.itemsAppended()
                } catch(e) { animeError = "Parse error: " + e }
            })
    }

    function fetchLatest(reset) {
        if (isFetchingAnime) return
        if (reset === undefined || reset) { animeList = []; latestPage = 1 }
        currentView = "latest"; currentSearchText = ""
        isFetchingAnime = true; animeError = ""
        _get(root.apiUrl + "/latest?limit=26&page=" + latestPage + "&country=" + currentCountry,
            function(err, body) {
                isFetchingAnime = false
                if (err) { animeError = err; return }
                try {
                    var d = JSON.parse(body)
                    if (d.error) { animeError = d.error; return }
                    var items = (d.shows || []).map(_normaliseShow)
                    var isAppend = animeList.length > 0
                    animeList = animeList.concat(items)
                    hasMoreAnime = (latestPage * 26) < (d.total || 0)
                    if (isAppend) root.itemsAppended()
                } catch(e) { animeError = "Parse error: " + e }
            })
    }

    function searchAnime(query, reset) {
        if (isFetchingAnime) return
        if (reset === undefined || reset) animeList = []
        currentView = "search"; currentSearchText = query
        isFetchingAnime = true; animeError = ""
        _get(root.apiUrl + "/search?q=" + encodeURIComponent(query),
            function(err, body) {
                isFetchingAnime = false
                if (err) { animeError = err; return }
                try {
                    var d = JSON.parse(body)
                    if (d.error) { animeError = d.error; return }
                    animeList = (d.results || []).map(_normaliseShow)
                    hasMoreAnime = false
                } catch(e) { animeError = "Parse error: " + e }
            })
    }

    function fetchNextPage() {
        if (!hasMoreAnime || isFetchingAnime) return
        if (currentView === "popular") { popularPage++; fetchPopular(false) }
        else if (currentView === "latest") { latestPage++; fetchLatest(false) }
    }

    function _normaliseShow(s) {
        var avail = s.available_episodes || {}
        return {
            id: s.id||"", name: s.name||"",
            englishName: s.english_name||s.englishName||s.name||"",
            nativeName: s.native_name||s.nativeName||"",
            thumbnail: s.thumbnail||"",
            score: s.score !== undefined ? s.score : null,
            type: s.type||"", episodeCount: s.episode_count||"",
            availableEpisodes: { sub: avail.sub||0, dub: avail.dub||0, raw: avail.raw||0 },
            views: s.views||null, season: s.season||null, lastEpisode: s.lastEpisode||null
        }
    }

    // ── Detail ────────────────────────────────────────────────────────────
    function fetchAnimeDetail(show) {
        if (isFetchingDetail) return
        isFetchingDetail = true; detailError = ""
        currentAnime = Object.assign({}, show, { episodes: [] })
        _get(root.apiUrl + "/episodes?id=" + encodeURIComponent(show.id),
            function(err, body) {
                isFetchingDetail = false
                if (err) { detailError = err; return }
                try {
                    var d = JSON.parse(body)
                    if (d.error) { detailError = d.error; return }
                    var eps = (d.episodes || []).map(function(epNum, idx) {
                        return { id: show.id+"-"+epNum, number: epNum, index: idx }
                    })
                    currentAnime = Object.assign({}, currentAnime, {
                        episodes: eps, episodeCount: d.count || eps.length
                    })
                } catch(e) { detailError = "Parse error: " + e }
            })
    }

    function clearDetail() { currentAnime = null; detailError = ""; clearStreamLinks() }

    // ── Stream links ──────────────────────────────────────────────────────
    function fetchStreamLinks(showId, episodeNum, quality) {
        if (isFetchingLinks) return
        isFetchingLinks = true; streamLinks = []; selectedLink = null
        linksError = ""; currentEpisode = String(episodeNum)
        _get(root.apiUrl + "/links?id=" + encodeURIComponent(showId)
                + "&ep=" + encodeURIComponent(episodeNum)
                + "&mode=" + currentMode + "&quality=" + encodeURIComponent(quality||"best"),
            function(err, body) {
                isFetchingLinks = false
                if (err) { linksError = err; return }
                try {
                    var d = JSON.parse(body)
                    if (d.error) { linksError = d.error; return }
                    var valid = (d.all_links||[]).filter(function(l){ return !l.error && l.url })
                    streamLinks = valid.map(function(l){
                        return { url:l.url||"", quality:l.quality||"?", type:l.type||"mp4",
                                 provider:l.provider||"", referer:l.referer||"", subtitle:l.subtitle||"" }
                    })
                    if (!streamLinks.length) { linksError = "No working stream found"; return }
                    var sel = d.selected
                    if (sel && (sel.error || !sel.url)) sel = null
                    selectedLink = sel ? { url:sel.url||"", quality:sel.quality||"?",
                        type:sel.type||"mp4", provider:sel.provider||"",
                        referer:sel.referer||"", subtitle:sel.subtitle||"" } : streamLinks[0]
                } catch(e) { linksError = "Parse error: " + e }
            })
    }

    function selectLink(link) { selectedLink = link }
    function clearStreamLinks() { streamLinks=[]; selectedLink=null; linksError=""; currentEpisode="" }
    function clearAnimeList() { animeList=[]; hasMoreAnime=false; popularPage=1; latestPage=1; animeError="" }

    function setMode(mode) {
        if (mode === currentMode) return
        currentMode = mode
        if (currentView === "popular") fetchPopular(true)
        else if (currentView === "latest") fetchLatest(true)
        else if (currentView === "search" && currentSearchText) searchAnime(currentSearchText, true)
    }

    function setCountry(country) {
        if (country === currentCountry) return
        currentCountry = country
        if (currentView === "latest") fetchLatest(true)
    }

    // ── Library ───────────────────────────────────────────────────────────
    function fetchAllLibrary() {
        _get(root.apiUrl + "/library/all?type=anime", function(err, body) {
            libraryLoaded = true
            if (err) return
            try { root.libraryAll = JSON.parse(body) } catch(e) {}
        })
    }

    function getLibraryStatus(animeId) {
        var ss = ["watching","completed","planning","on_hold","dropped","rewatching"]
        for (var i = 0; i < ss.length; i++) {
            var list = root.libraryAll[ss[i]] || []
            for (var j = 0; j < list.length; j++)
                if (String(list[j].id) === String(animeId)) return ss[i]
        }
        return ""
    }

    function isInLibrary(animeId) { return getLibraryStatus(animeId) !== "" }

    function addToLibrary(anime, status) {
        var st = status || "planning"
        var entry = { id:String(anime.id), name:anime.englishName||anime.name||"",
                      thumbnail:anime.thumbnail||"", status:st, type:"anime" }
        var up = Object.assign({}, root.libraryAll)
        if (!up[st]) up[st] = []
        up[st] = [entry].concat((up[st]||[]).filter(function(e){ return String(e.id)!==String(anime.id) }))
        root.libraryAll = up
        _post(root.apiUrl + "/library/add",
            { id:String(anime.id), title:anime.englishName||anime.name||"",
              coverUrl:anime.thumbnail||"", status:st, type:"anime", item:anime },
            function(err) { if (!err) fetchAllLibrary() })
    }

    function updateLibraryStatus(animeId, status) {
        var up = Object.assign({}, root.libraryAll)
        var existing = null
        var ss = ["watching","completed","planning","on_hold","dropped","rewatching"]
        for (var i = 0; i < ss.length; i++) {
            var list = up[ss[i]] || []
            for (var j = 0; j < list.length; j++) {
                if (String(list[j].id) === String(animeId)) {
                    existing = Object.assign({}, list[j])
                    up[ss[i]] = list.filter(function(e){ return String(e.id)!==String(animeId) })
                    break
                }
            }
            if (existing) break
        }
        if (existing) {
            existing.status = status
            if (!up[status]) up[status] = []
            up[status] = [existing].concat(up[status])
        }
        root.libraryAll = up
        _post(root.apiUrl + "/library/update",
            { id:String(animeId), status:status, type:"anime" },
            function(err) { if (!err) fetchAllLibrary() })
    }

    function removeFromLibrary(animeId) {
        var up = Object.assign({}, root.libraryAll)
        var ss = ["watching","completed","planning","on_hold","dropped","rewatching"]
        for (var i = 0; i < ss.length; i++)
            up[ss[i]] = (up[ss[i]]||[]).filter(function(e){ return String(e.id)!==String(animeId) })
        root.libraryAll = up
        _post(root.apiUrl + "/library/remove",
            { id:String(animeId), type:"anime" },
            function(err) { if (!err) fetchAllLibrary() })
    }

    function getLibraryItems(status) { return root.libraryAll[status] || [] }

    function getLibraryEntry(animeId) {
        var ss = ["watching","completed","planning","on_hold","dropped","rewatching"]
        for (var i = 0; i < ss.length; i++) {
            var list = root.libraryAll[ss[i]] || []
            for (var j = 0; j < list.length; j++)
                if (String(list[j].id) === String(animeId)) return list[j]
        }
        return null
    }
}
