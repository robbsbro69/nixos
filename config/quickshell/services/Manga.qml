pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string apiUrl: "http://127.0.0.1:5150"

    property var mangaList: []
    property bool isFetchingManga: false
    property string mangaError: ""
    property bool hasMoreManga: false
    property int currentOffset: 0
    property int latestPage: 1
    property string currentSearchText: ""
    property string currentOrigin: ""

    // signal emitted ONLY on append so GridView can save/restore scroll
    signal itemsAppended()

    property var currentManga: null
    property bool isFetchingDetail: false
    property string detailError: ""

    property var chapterPages: []
    property bool isFetchingPages: false
    property string pagesError: ""
    property string currentChapterId: ""

    property var favoritesList: []
    property bool isFetchingFavs: false
    property int favNewCount: 0

    property var libraryAll: ({
        reading: [], completed: [], planning: [],
        on_hold: [], dropped: [], rereading: []
    })
    property bool libraryLoaded: false

    readonly property var libraryStatuses: [
        { key: "reading",   label: "Reading",    icon: "󰐊", color: "#89b4fa" },
        { key: "completed", label: "Completed",  icon: "󰄬", color: "#a6e3a1" },
        { key: "planning",  label: "Planning",   icon: "󰃯", color: "#f5c2e7" },
        { key: "on_hold",   label: "On Hold",    icon: "⏸", color: "#f9e2af" },
        { key: "dropped",   label: "Dropped",    icon: "󰅖", color: "#f38ba8" },
        { key: "rereading", label: "Rereading",  icon: "󰑓", color: "#89b4fa" }
    ]

    property bool serverReady: false

    Process {
        id: serverProcess
        command: [Quickshell.env("HOME") + "/.venv/manga/bin/python3",
            Quickshell.env("HOME") + "/.config/quickshell/scripts/manga_server.py"]
        running: true
        onExited: (code) => {
            console.warn("[Manga] Server exited with code", code, "— restarting")
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
                    root.fetchByOrigin("", true)
                    root.fetchFavorites()
                    root.fetchAllLibrary()
                }
            }
            xhr.open("GET", root.apiUrl + "/health")
            xhr.send()
        }
    }

    Timer {
        id: favChecker
        interval: 900000; repeat: true
        running: root.serverReady && root.favoritesList.length > 0
        onTriggered: root.checkFavoritesForUpdates()
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

    function fetchByOrigin(origin, reset) {
        if (isFetchingManga) return
        if (reset) { mangaList = []; currentOffset = 0; latestPage = 1 }
        currentOrigin = origin; currentSearchText = ""
        isFetchingManga = true; mangaError = ""
        var url
        if (origin === "")             url = root.apiUrl + "/hot"
        else if (origin === "latest")  url = root.apiUrl + "/latest?page=" + latestPage
        else                           url = root.apiUrl + "/search?q=a&offset=" + currentOffset
                                               + "&sort=Popularity&type=" + _originType(origin)
        _get(url, function(err, body) {
            if (err) { mangaError = err; isFetchingManga = false; return }
            _parseMangaResults(body, origin === "")
        })
    }

    function searchManga(query, reset) {
        if (isFetchingManga) return
        if (reset) { mangaList = []; currentOffset = 0 }
        currentSearchText = query; isFetchingManga = true; mangaError = ""
        _get(root.apiUrl + "/search?q=" + encodeURIComponent(query) + "&offset=" + currentOffset,
            function(err, body) {
                if (err) { mangaError = err; isFetchingManga = false; return }
                _parseMangaResults(body, false)
            })
    }

    function fetchNextMangaPage() {
        if (!hasMoreManga || isFetchingManga) return
        if (currentSearchText.length > 0) searchManga(currentSearchText, false)
        else if (currentOrigin === "latest") { latestPage++; fetchByOrigin("latest", false) }
        else fetchByOrigin(currentOrigin, false)
    }

    function _originType(origin) {
        if (origin === "ko") return "Manhwa"
        if (origin === "ja") return "Manga"
        if (origin === "zh") return "Manhua"
        return ""
    }

    function _parseMangaResults(json, isHot) {
        try {
            var data  = JSON.parse(json)
            if (data.error) { mangaError = data.error; isFetchingManga = false; return }
            var raw   = isHot ? (Array.isArray(data) ? data : (data.results || []))
                              : (data.results || [])
            var items = raw.map(function(item) {
                return { id:item.id||"", title:item.title||"", thumbUrl:item.image||"",
                         status:item.status||"", type:item.type||"", score:item.score||0,
                         author:(item.authors && item.authors[0])||"" }
            })
            var isAppend = mangaList.length > 0
            mangaList    = mangaList.concat(items)
            hasMoreManga = data.hasMore || false
            if (!isHot && data.nextOffset !== undefined) currentOffset = data.nextOffset
            mangaError = ""
            if (isAppend) root.itemsAppended()
        } catch(e) { mangaError = "Parse error: " + e }
        isFetchingManga = false
    }

//    function fetchMangaDetail(mangaId) {
//        if (isFetchingDetail) return
//        isFetchingDetail = true; currentManga = null; detailError = ""
//        _get(root.apiUrl + "/info?id=" + encodeURIComponent(mangaId),
//            function(err, body) {
//                isFetchingDetail = false
//                if (err) { detailError = err; return }
//                try {
//                    var data = JSON.parse(body)
//                    if (data.error) { detailError = data.error; return }
//                    currentManga = {
//                        id:          data.id          || "",
//                        title:       data.title       || "",
//                        description: data.description || "",
//                        status:      data.status      || "",
//                        coverUrl:    data.image       || "",
//                        authors:     data.authors     || [],
//                        tags:        data.tags        || [],
//                        genres:      data.genres      || [],
//                        score:       data.score       || 0,
//                        chapters:    (data.chapters || []).map(function(ch) {
//                            return { id:ch.id||"", chapter:ch.chapter||"",
//                                     title:ch.title||"", publishAt:ch.publishAt||"" }
//                        }),
//                        extLinks:    data.extLinks    || [],
//                        allExtLinks: data.allExtLinks || [],
//                        bannerImage: data.bannerImage || ""
//                    }
//                } catch(e) { detailError = "Parse error: " + e }
//            })
//    }
function fetchMangaDetail(mangaId) {
    if (isFetchingDetail) return
    isFetchingDetail = true; currentManga = null; detailError = ""
    console.log("[Manga] fetching detail for id:", mangaId)
    _get(root.apiUrl + "/info?id=" + encodeURIComponent(mangaId),
        function(err, body) {
            isFetchingDetail = false
            if (err) { detailError = err; console.log("[Manga] detail error:", err); return }
            try {
                var data = JSON.parse(body)
                console.log("[Manga] detail response keys:", JSON.stringify(Object.keys(data)))
                console.log("[Manga] chapters count:", (data.chapters || []).length)
                console.log("[Manga] title:", data.title)
                if (data.error) { detailError = data.error; return }
                currentManga = {
                    id:          data.id          || "",
                    title:       data.title       || "",
                    description: data.description || "",
                    status:      data.status      || "",
                    coverUrl:    data.image       || "",
                    authors:     data.authors     || [],
                    tags:        data.tags        || [],
                    genres:      data.genres      || [],
                    score:       data.score       || 0,
                    chapters:    (data.chapters || []).map(function(ch) {
                        return { id:ch.id||"", chapter:ch.chapter||"",
                                 title:ch.title||"", publishAt:ch.publishAt||"" }
                    }),
                    extLinks:    data.extLinks    || [],
                    allExtLinks: data.allExtLinks || [],
                    bannerImage: data.bannerImage || ""
                }
                console.log("[Manga] currentManga set, chapters:", currentManga.chapters.length)
            } catch(e) { detailError = "Parse error: " + e; console.log("[Manga] parse error:", e) }
        })
}
    function fetchChapterPages(chapterId) {
        if (isFetchingPages) return
        isFetchingPages = true; currentChapterId = chapterId
        chapterPages = []; pagesError = ""
        _get(root.apiUrl + "/pages?chapterId=" + encodeURIComponent(chapterId),
            function(err, body) {
                isFetchingPages = false
                if (err) { pagesError = err; return }
                try {
                    var data = JSON.parse(body)
                    if (!Array.isArray(data)) { pagesError = data.error || "Invalid response"; return }
                    if (!data.length) { pagesError = "No pages available"; return }
                    chapterPages = data.map(function(p, idx) {
                        return { index:idx, url:p.img||"", ready:true }
                    })
                } catch(e) { pagesError = "Parse error: " + e }
            })
    }

    function fetchFavorites() {
        if (isFetchingFavs) return
        isFetchingFavs = true
        _get(root.apiUrl + "/favorites", function(err, body) {
            isFetchingFavs = false
            if (err) return
            try {
                var data = JSON.parse(body)
                favoritesList = Array.isArray(data) ? data : []
                favNewCount   = favoritesList.filter(function(f){ return f.has_new_chapters }).length
            } catch(e) {}
        })
    }

    function addFavorite(manga) {
        _post(root.apiUrl + "/favorites/add",
            { id:manga.id, title:manga.title||"",
              imageUrl:manga.coverUrl||manga.image||manga.thumbUrl||"" },
            function(err) { if (!err) fetchFavorites() })
    }

    function removeFavorite(mangaId) {
        _post(root.apiUrl + "/favorites/remove", { id:mangaId },
            function(err) { if (!err) fetchFavorites() })
    }

    function isFavorite(mangaId) {
        return favoritesList.some(function(f){ return f.id === mangaId })
    }

    function markChapterSeen(mangaId, chapterId) {
        _post(root.apiUrl + "/favorites/mark-seen", { id:mangaId, chapterId:chapterId },
            function(err) { if (!err) fetchFavorites() })
    }

    function checkFavoritesForUpdates() {
        _get(root.apiUrl + "/favorites/check", function(err, body) {
            if (err) return
            try {
                var data = JSON.parse(body)
                if (data.updated && data.updated.length > 0) fetchFavorites()
            } catch(e) {}
        })
    }

    function fetchAllLibrary() {
        _get(root.apiUrl + "/library/all", function(err, body) {
            libraryLoaded = true
            if (err) return
            try { root.libraryAll = JSON.parse(body) } catch(e) {}
        })
    }

    function getLibraryStatus(mangaId) {
        var ss = ["reading","completed","planning","on_hold","dropped","rereading"]
        for (var i = 0; i < ss.length; i++) {
            var list = root.libraryAll[ss[i]] || []
            for (var j = 0; j < list.length; j++)
                if (String(list[j].id) === String(mangaId)) return ss[i]
        }
        return ""
    }

    function isInLibrary(mangaId) { return getLibraryStatus(mangaId) !== "" }

    function addToLibrary(manga, status) {
        var st = status || "planning"
        var entry = { id:String(manga.id), title:manga.title||manga.name||"",
                      cover_url:manga.coverUrl||manga.image||manga.thumbUrl||"", status:st }
        var up = Object.assign({}, root.libraryAll)
        if (!up[st]) up[st] = []
        up[st] = [entry].concat((up[st]||[]).filter(function(e){ return String(e.id)!==String(manga.id) }))
        root.libraryAll = up
        _post(root.apiUrl + "/library/add",
            { id:String(manga.id), title:manga.title||manga.name||"",
              coverUrl:manga.coverUrl||manga.image||manga.thumbUrl||"", status:st },
            function(err) { if (!err) fetchAllLibrary() })
    }

    function updateLibraryStatus(mangaId, status) {
        var up = Object.assign({}, root.libraryAll)
        var existing = null
        var ss = ["reading","completed","planning","on_hold","dropped","rereading"]
        for (var i = 0; i < ss.length; i++) {
            var list = up[ss[i]] || []
            for (var j = 0; j < list.length; j++) {
                if (String(list[j].id) === String(mangaId)) {
                    existing = Object.assign({}, list[j])
                    up[ss[i]] = list.filter(function(e){ return String(e.id)!==String(mangaId) })
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
        _post(root.apiUrl + "/library/update", { id:String(mangaId), status:status },
            function(err) { if (!err) fetchAllLibrary() })
    }

    function removeFromLibrary(mangaId) {
        var up = Object.assign({}, root.libraryAll)
        var ss = ["reading","completed","planning","on_hold","dropped","rereading"]
        for (var i = 0; i < ss.length; i++)
            up[ss[i]] = (up[ss[i]]||[]).filter(function(e){ return String(e.id)!==String(mangaId) })
        root.libraryAll = up
        _post(root.apiUrl + "/library/remove", { id:String(mangaId) },
            function(err) { if (!err) fetchAllLibrary() })
    }

    function getLibraryItems(status) { return root.libraryAll[status] || [] }

    function getLibraryEntry(mangaId) {
        var ss = ["reading","completed","planning","on_hold","dropped","rereading"]
        for (var i = 0; i < ss.length; i++) {
            var list = root.libraryAll[ss[i]] || []
            for (var j = 0; j < list.length; j++)
                if (String(list[j].id) === String(mangaId)) return list[j]
        }
        return null
    }

    function clearChapterPages() { chapterPages=[]; currentChapterId=""; pagesError="" }
    function clearMangaList() {
        mangaList=[]; hasMoreManga=false; currentOffset=0; latestPage=1; mangaError=""
    }
}
