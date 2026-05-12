#!/usr/bin/env python3
"""
AniList-backed Anime server for QuickShell.
Port: 5050
"""

import json
import sqlite3
import threading
import time
import urllib.parse
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from socketserver import ThreadingMixIn
import requests

PORT        = 5050
ANILIST_GQL = "https://graphql.anilist.co"

HEADERS = {
    "Content-Type": "application/json",
    "Accept":       "application/json",
}

DATA_DIR = Path.home() / ".local/share/quickshell-anime"
DATA_DIR.mkdir(parents=True, exist_ok=True)
DB_PATH  = DATA_DIR / "library.db"
_db_lock = threading.Lock()

def _get_db():
    conn = sqlite3.connect(str(DB_PATH), check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn

def _init_db():
    with _db_lock:
        conn = _get_db()
        conn.executescript("""
        CREATE TABLE IF NOT EXISTS library (
            id          TEXT NOT NULL,
            media_type  TEXT NOT NULL DEFAULT 'anime',
            title       TEXT NOT NULL,
            cover_url   TEXT,
            status      TEXT NOT NULL DEFAULT 'planning',
            progress    INTEGER DEFAULT 0,
            score       REAL,
            added_at    TEXT,
            updated_at  TEXT,
            item_json   TEXT,
            PRIMARY KEY (id, media_type)
        );
        """)
        conn.commit()
        conn.close()
_init_db()

ANIME_STATUSES = ["watching", "completed", "planning", "on_hold", "dropped", "rewatching"]
MANGA_STATUSES = ["reading", "completed", "planning", "on_hold", "dropped", "rereading"]

LOCAL_TO_AL_ANIME = {
    "watching":   "CURRENT",
    "completed":  "COMPLETED",
    "planning":   "PLANNING",
    "on_hold":    "PAUSED",
    "dropped":    "DROPPED",
    "rewatching": "REPEATING",
}
LOCAL_TO_AL_MANGA = {
    "reading":    "CURRENT",
    "completed":  "COMPLETED",
    "planning":   "PLANNING",
    "on_hold":    "PAUSED",
    "dropped":    "DROPPED",
    "rereading":  "REPEATING",
}

AL_TOKEN = ""
for _f in ["~/.config/quickshell/anilist_token"]:
    _p = Path(_f).expanduser()
    if _p.exists():
        AL_TOKEN = _p.read_text().strip()
        break

AL_HEADERS = {
    "Content-Type":  "application/json",
    "Accept":        "application/json",
    **({"Authorization": f"Bearer {AL_TOKEN}"} if AL_TOKEN else {}),
}

_cache      = {}
_cache_lock = threading.Lock()

def _cached(key, ttl, fn):
    with _cache_lock:
        entry = _cache.get(key)
    if entry:
        val, exp = entry
        if time.monotonic() < exp:
            return val
    val = fn()
    with _cache_lock:
        if len(_cache) > 200:
            now = time.monotonic()
            expired = [k for k, (_, e) in _cache.items() if e < now]
            for k in expired[:50]:
                del _cache[k]
            if len(_cache) > 200:
                for k in list(_cache)[:50]:
                    del _cache[k]
        _cache[key] = (val, time.monotonic() + ttl)
    return val

def _invalidate(prefix):
    with _cache_lock:
        for k in list(_cache):
            if k.startswith(prefix):
                del _cache[k]


_img_cache = {}
_img_lock  = threading.Lock()
_img_sem   = threading.Semaphore(8)

def _img_get(url):
    with _img_lock:
        return _img_cache.get(url)

def _img_put(url, body, ct):
    with _img_lock:
        total = sum(len(v[0]) for v in _img_cache.values())
        while _img_cache and (len(_img_cache) >= 50 or total + len(body) > 50 * 1024 * 1024):
            evicted = _img_cache.pop(next(iter(_img_cache)))
            total -= len(evicted[0])
        _img_cache[url] = (body, ct)

def gql(query, variables, use_auth=False):
    hdrs = AL_HEADERS if use_auth else HEADERS
    r = requests.post(
        ANILIST_GQL,
        json={"query": query, "variables": variables},
        headers=hdrs,
        timeout=15,
    )
    r.raise_for_status()
    return r.json()

def _norm(media, mode="sub"):
    title = media.get("title") or {}
    avail = media.get("episodes") or 0
    return {
        "id":          str(media.get("id", "")),
        "name":        title.get("romaji") or title.get("english") or title.get("native") or "",
        "english_name": title.get("english") or title.get("romaji") or "",
        "native_name": title.get("native") or "",
        "thumbnail":   (media.get("coverImage") or {}).get("large") or "",
        "score":       (media.get("averageScore") or 0) / 10,
        "type":        media.get("format") or "",
        "episode_count": avail,
        "available_episodes": {"sub": avail, "dub": avail, "raw": 0},
        "views":       None,
        "season": {
            "quarter": media.get("season"),
            "year":    media.get("seasonYear"),
        },
        "lastEpisode": None,
    }

def _norm_list_entry(entry, media_type="ANIME"):
    media = entry.get("media") or {}
    base  = _norm(media)
    base["listStatus"]  = entry.get("status", "")
    base["progress"]    = entry.get("progress", 0)
    base["userScore"]   = entry.get("score", 0)
    base["updatedAt"]   = entry.get("updatedAt", 0)
    if media_type == "MANGA":
        base["chapters"] = media.get("chapters") or 0
        base["volumes"]  = media.get("volumes") or 0
    return base

POPULAR_Q = """
query($page:Int,$perPage:Int){
  Page(page:$page,perPage:$perPage){
    pageInfo{total currentPage lastPage}
    media(sort:TRENDING_DESC,type:ANIME,isAdult:false){
      id title{romaji english native}
      coverImage{large}
      averageScore episodes format season seasonYear
    }
  }
}
"""

def popular(size=20, page=1):
    def _fetch():
        data      = gql(POPULAR_Q, {"page": page, "perPage": size})
        page_data = data["data"]["Page"]
        info      = page_data["pageInfo"]
        shows     = [_norm(m) for m in page_data["media"]]
        return {"page": page, "size": size, "total": info["total"],
                "count": len(shows), "shows": shows}
    return _cached(f"popular:{page}:{size}", 600, _fetch)

LATEST_Q = """
query($page:Int,$perPage:Int,$country:CountryCode){
  Page(page:$page,perPage:$perPage){
    pageInfo{total currentPage lastPage}
    media(sort:UPDATED_AT_DESC,type:ANIME,isAdult:false,countryOfOrigin:$country){
      id title{romaji english native}
      coverImage{large}
      averageScore episodes format season seasonYear
    }
  }
}
"""

def latest(limit=26, page=1, country="ALL"):
    def _fetch():
        variables = {"page": page, "perPage": limit}
        if country and country != "ALL":
            variables["country"] = country
        data      = gql(LATEST_Q, variables)
        page_data = data["data"]["Page"]
        info      = page_data["pageInfo"]
        shows     = [_norm(m) for m in page_data["media"]]
        return {"page": page, "limit": limit, "total": info["total"],
                "count": len(shows), "shows": shows}
    return _cached(f"latest:{page}:{limit}:{country}", 300, _fetch)

SEARCH_Q = """
query($q:String,$page:Int){
  Page(page:$page,perPage:40){
    media(search:$q,type:ANIME,isAdult:false){
      id title{romaji english native}
      coverImage{large}
      averageScore episodes format season seasonYear
    }
  }
}
"""

def search(query):
    def _fetch():
        data = gql(SEARCH_Q, {"q": query, "page": 1})
        return [_norm(m) for m in data["data"]["Page"]["media"]]
    return _cached(f"search:{query}", 600, _fetch)

DETAIL_Q = """
query($id:Int){
  Media(id:$id,type:ANIME){
    id
    title{romaji english native}
    coverImage{large extraLarge}
    bannerImage
    description
    averageScore
    episodes
    format
    season
    seasonYear
    status
    genres
    tags{name}
    studios(isMain:true){nodes{name}}
    staff{edges{role node{name}}}
    relations{edges{relationType(version:2) node{id title{english romaji} format type}}}
    nextAiringEpisode{episode airingAt}
    trailer{id site}
    externalLinks{url site}
    rankings{rank type allTime context}
  }
}
"""

def detail(show_id):
    def _fetch():
        data  = gql(DETAIL_Q, {"id": int(show_id)})
        media = data["data"]["Media"]
        title = media.get("title") or {}
        cover = media.get("coverImage") or {}

        import re
        def strip_html(s):
            return re.sub(r"<[^>]+>", "", s or "").strip()

        studios = [n["name"] for n in (media.get("studios") or {}).get("nodes", [])]
        tags    = [t["name"] for t in (media.get("tags") or [])[:10]]

        next_ep = media.get("nextAiringEpisode")
        trailer = media.get("trailer")
        trailer_url = ""
        if trailer and trailer.get("site") == "youtube":
            trailer_url = f"https://www.youtube.com/watch?v={trailer['id']}"

        ext_links = media.get("externalLinks") or []

        relations = []
        for edge in (media.get("relations") or {}).get("edges", []):
            node = edge.get("node") or {}
            t    = node.get("title") or {}
            relations.append({
                "id":           str(node.get("id", "")),
                "relationType": edge.get("relationType", ""),
                "title":        t.get("english") or t.get("romaji") or "",
                "format":       node.get("format") or "",
                "type":         node.get("type") or "",
            })

        top_rank = None
        for r in (media.get("rankings") or []):
            if r.get("allTime") and r.get("type") == "RATED":
                top_rank = r.get("rank")
                break

        ep_count = media.get("episodes") or 0
        episodes = [str(i) for i in range(1, ep_count + 1)]

        return {
            "id":           str(media.get("id", "")),
            "name":         title.get("romaji") or title.get("english") or "",
            "englishName":  title.get("english") or title.get("romaji") or "",
            "nativeName":   title.get("native") or "",
            "thumbnail":    cover.get("extraLarge") or cover.get("large") or "",
            "bannerImage":  media.get("bannerImage") or "",
            "score":        (media.get("averageScore") or 0) / 10,
            "type":         media.get("format") or "",
            "episode_count": ep_count,
            "episodes":     episodes,
            "status":       media.get("status") or "",
            "season":       {"quarter": media.get("season"), "year": media.get("seasonYear")},
            "genres":       media.get("genres") or [],
            "tags":         tags,
            "studios":      studios,
            "description":  strip_html(media.get("description") or ""),
            "trailerUrl":   trailer_url,
            "extLinks":     ext_links,
            "relations":    relations,
            "topRank":      top_rank,
            "nextAiring":   next_ep,
        }
    return _cached(f"detail:{show_id}", 1800, _fetch)

EP_Q = "query($id:Int){Media(id:$id,type:ANIME){episodes}}"

def episodes(show_id):
    def _fetch():
        data  = gql(EP_Q, {"id": int(show_id)})
        count = data["data"]["Media"]["episodes"] or 0
        return [str(i) for i in range(1, count + 1)]
    return _cached(f"eps:{show_id}", 1800, _fetch)

def stream_links(show_id, ep_no, mode="sub"):
    def _fetch_name():
        data = gql("query($id:Int){Media(id:$id){title{romaji}}}", {"id": int(show_id)})
        return data["data"]["Media"]["title"]["romaji"]

    name = _cached(f"name:{show_id}", 86400, _fetch_name)
    slug = name.lower().replace(" ", "-").replace(":", "").replace("'", "")
    gogo_url = f"https://gogoanime3.co/{slug}-episode-{ep_no}"
    link = {
        "url": gogo_url, "quality": "best", "type": "m3u8",
        "provider": "gogoanime", "referer": "https://gogoanime3.co/", "subtitle": "",
    }
    return {
        "show_id": show_id, "episode": ep_no, "mode": mode,
        "providers": {"gogoanime": [link]},
        "all_links": [link], "selected": link, "requested_quality": "best",
    }

USER_LIST_Q = """
query($username:String,$status:MediaListStatus,$type:MediaType){
  MediaListCollection(userName:$username,status:$status,type:$type){
    lists{
      entries{
        status progress
        score(format:POINT_10)
        updatedAt
        media{
          id title{romaji english native}
          coverImage{large}
          averageScore episodes format season seasonYear status
        }
      }
    }
  }
}
"""

MANGA_USER_LIST_Q = """
query($username:String,$status:MediaListStatus,$type:MediaType){
  MediaListCollection(userName:$username,status:$status,type:$type){
    lists{
      entries{
        status progress progressVolumes
        score(format:POINT_10)
        updatedAt
        media{
          id title{romaji english native}
          coverImage{large}
          averageScore chapters volumes format status
        }
      }
    }
  }
}
"""

SAVE_MEDIA_LIST_Q = """
mutation($mediaId:Int,$status:MediaListStatus,$progress:Int){
  SaveMediaListEntry(mediaId:$mediaId,status:$status,progress:$progress){
    id
    status
    progress
    updatedAt
  }
}
"""

DELETE_MEDIA_LIST_Q = """
mutation($id:Int){
  DeleteMediaListEntry(id:$id){
    deleted
  }
}
"""

GET_LIST_ENTRY_Q = """
query($mediaId:Int,$type:MediaType){
  Media(id:$mediaId,type:$type){
    mediaListEntry{
      id
      status
    }
  }
}
"""

def _norm_manga_entry(entry):
    media = entry.get("media") or {}
    title = media.get("title") or {}
    return {
        "id":              str(media.get("id", "")),
        "name":            title.get("romaji") or title.get("english") or title.get("native") or "",
        "english_name":    title.get("english") or title.get("romaji") or "",
        "native_name":     title.get("native") or "",
        "thumbnail":       (media.get("coverImage") or {}).get("large") or "",
        "score":           (media.get("averageScore") or 0) / 10,
        "type":            media.get("format") or "",
        "chapters":        media.get("chapters") or 0,
        "volumes":         media.get("volumes") or 0,
        "status":          media.get("status") or "",
        "listStatus":      entry.get("status", ""),
        "progress":        entry.get("progress", 0),
        "progressVolumes": entry.get("progressVolumes", 0),
        "userScore":       entry.get("score", 0),
        "updatedAt":       entry.get("updatedAt", 0),
    }

def get_user_list(username, status, media_type="ANIME"):
    cache_key = f"userlist:{username}:{status}:{media_type}"
    def _fetch():
        q = MANGA_USER_LIST_Q if media_type == "MANGA" else USER_LIST_Q
        try:
            data       = gql(q, {"username": username, "status": status, "type": media_type})
            collection = data.get("data", {}).get("MediaListCollection")
            if not collection:
                return {"entries": [], "error": "User not found or list is private"}
            entries = []
            for lst in collection.get("lists", []):
                for e in lst.get("entries", []):
                    if media_type == "MANGA":
                        entries.append(_norm_manga_entry(e))
                    else:
                        entries.append(_norm_list_entry(e, media_type))
            entries.sort(key=lambda x: x.get("updatedAt", 0), reverse=True)
            return {"entries": entries, "count": len(entries)}
        except Exception as ex:
            return {"entries": [], "error": str(ex)}
    return _cached(cache_key, 300, _fetch)

def get_all_user_lists(username, media_type="ANIME"):
    statuses = ["CURRENT", "COMPLETED", "PLANNING", "PAUSED", "DROPPED", "REPEATING"]
    result   = {}
    for s in statuses:
        d = get_user_list(username, s, media_type)
        result[s] = d.get("entries", [])
    return {"lists": result, "total": sum(len(v) for v in result.values()), "username": username}

def al_save_entry(media_id, al_status, progress=0):
    """
    Save or update a media list entry on AniList.
    SaveMediaListEntry is an upsert — works for both add and update.
    Requires AL_TOKEN.
    """
    if not AL_TOKEN:
        return {"ok": False, "error": "No AniList token — set ~/.config/quickshell/anilist_token"}
    try:
        result = gql(SAVE_MEDIA_LIST_Q,
                     {"mediaId": int(media_id), "status": al_status, "progress": progress},
                     use_auth=True)
        errors = result.get("errors")
        if errors:
            msg = errors[0].get("message", "AniList error")
            print(f"[anime-server] AniList save error for {media_id}: {msg}")
            return {"ok": False, "error": msg}
        entry = result["data"]["SaveMediaListEntry"]
        print(f"[anime-server] AniList saved: id={media_id} status={entry['status']}")
        return {"ok": True, "entryId": entry["id"], "status": entry["status"]}
    except Exception as e:
        print(f"[anime-server] AniList save exception for {media_id}: {e}")
        return {"ok": False, "error": str(e)}

def al_delete_entry(media_id, media_type="ANIME"):
    """Delete a media list entry from AniList. Requires AL_TOKEN."""
    if not AL_TOKEN:
        return {"ok": False, "error": "No AniList token"}
    try:
        res = gql(GET_LIST_ENTRY_Q, {"mediaId": int(media_id), "type": media_type}, use_auth=True)
        entry = (res.get("data") or {}).get("Media", {}).get("mediaListEntry")
        if not entry:
            return {"ok": False, "error": "Not in list"}
        del_res = gql(DELETE_MEDIA_LIST_Q, {"id": entry["id"]}, use_auth=True)
        errors  = del_res.get("errors")
        if errors:
            return {"ok": False, "error": errors[0].get("message", "AniList error")}
        return {"ok": True, "deleted": del_res["data"]["DeleteMediaListEntry"]["deleted"]}
    except Exception as e:
        print(f"[anime-server] AniList delete exception for {media_id}: {e}")
        return {"ok": False, "error": str(e)}

def lib_get_all(media_type="anime"):
    statuses = ANIME_STATUSES if media_type == "anime" else MANGA_STATUSES
    with _db_lock:
        conn = _get_db()
        rows = conn.execute(
            "SELECT * FROM library WHERE media_type=? ORDER BY updated_at DESC",
            (media_type,)).fetchall()
        conn.close()
    result = {s: [] for s in statuses}
    for row in rows:
        d      = dict(row)
        status = d.get("status", "planning")
        if status not in result:
            result[status] = []
        try:
            item = json.loads(d.get("item_json") or "{}")
        except Exception:
            item = {}
        item.update({
            "id":        d["id"],
            "type":      d["media_type"],
            "status":    status,
            "title":     d.get("title", "") or item.get("name", ""),
            "thumbnail": d.get("cover_url", "") or item.get("thumbnail", ""),
            "name":      d.get("title", "") or item.get("name", ""),
        })
        result[status].append(item)
    return result

def lib_get_status(item_id, media_type="anime"):
    with _db_lock:
        conn = _get_db()
        row  = conn.execute(
            "SELECT status FROM library WHERE id=? AND media_type=?",
            (str(item_id), media_type)).fetchone()
        conn.close()
    return row["status"] if row else ""

def lib_add(item_id, title, cover_url, status, media_type="anime", item_data=None):
    now = datetime.now(timezone.utc).isoformat()
    with _db_lock:
        conn = _get_db()
        conn.execute("""
        INSERT INTO library(id,media_type,title,cover_url,status,added_at,updated_at,item_json)
        VALUES(?,?,?,?,?,?,?,?)
        ON CONFLICT(id,media_type) DO UPDATE SET
            status=excluded.status, updated_at=excluded.updated_at,
            item_json=excluded.item_json
        """, (str(item_id), media_type, title, cover_url, status,
              now, now, json.dumps(item_data or {})))
        conn.commit()
        conn.close()
    return {"ok": True}

def lib_update(item_id, status, media_type="anime"):
    now = datetime.now(timezone.utc).isoformat()
    with _db_lock:
        conn = _get_db()
        conn.execute(
            "UPDATE library SET status=?,updated_at=? WHERE id=? AND media_type=?",
            (status, now, str(item_id), media_type))
        conn.commit()
        conn.close()
    return {"ok": True}

def lib_remove(item_id, media_type="anime"):
    with _db_lock:
        conn = _get_db()
        conn.execute("DELETE FROM library WHERE id=? AND media_type=?",
                     (str(item_id), media_type))
        conn.commit()
        conn.close()
    return {"ok": True}

class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads      = True
    allow_reuse_address = True

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print(f"[anime-server] {fmt % args}")

    def _json(self, data, status=200):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def _error(self, msg, status=500):
        self._json({"error": msg}, status)

    def _send_image(self, body, ct):
        self.send_response(200)
        self.send_header("Content-Type", ct)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "public, max-age=86400")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        try:
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def _body(self):
        length = int(self.headers.get("Content-Length", 0))
        return json.loads(self.rfile.read(length)) if length else {}

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        qs     = urllib.parse.parse_qs(parsed.query)

        def p(key, default=""):
            return (qs.get(key) or [default])[0]

        try:
            path = parsed.path

            if path == "/health":
                self._json({
                    "status": "ok", "backend": "anilist", "db": str(DB_PATH),
                    "hasToken": bool(AL_TOKEN),
                })

            elif path == "/popular":
                self._json(popular(int(p("size", "20")), int(p("page", "1"))))

            elif path == "/latest":
                self._json(latest(int(p("limit", "26")), int(p("page", "1")), p("country", "ALL")))

            elif path == "/search":
                q = p("q")
                if not q:
                    return self._error("missing q", 400)
                results = search(q)
                self._json({"query": q, "count": len(results), "results": results})

            elif path == "/detail":
                show_id = p("id")
                if not show_id:
                    return self._error("missing id", 400)
                self._json(detail(show_id))

            elif path == "/episodes":
                show_id = p("id")
                if not show_id:
                    return self._error("missing id", 400)
                eps = episodes(show_id)
                self._json({"id": show_id, "count": len(eps), "episodes": eps})

            elif path == "/links":
                show_id = p("id")
                ep_no   = p("ep")
                mode    = p("mode", "sub")
                if not show_id or not ep_no:
                    return self._error("missing id or ep", 400)
                self._json(stream_links(show_id, ep_no, mode))

            elif path == "/userlist":
                username   = p("username")
                status_val = p("status", "CURRENT")
                media_type = p("type", "ANIME").upper()
                if not username:
                    return self._error("missing username", 400)
                if status_val == "ALL":
                    self._json(get_all_user_lists(username, media_type))
                else:
                    self._json(get_user_list(username, status_val.upper(), media_type))

            elif path == "/library/all":
                mt = p("type", "anime")
                self._json(lib_get_all(mt))

            elif path == "/library/status":
                item_id = p("id")
                mt      = p("type", "anime")
                if not item_id:
                    return self._error("missing id", 400)
                self._json({"status": lib_get_status(item_id, mt)})

            elif path == "/image":
                img_url = urllib.parse.unquote(p("url"))
                if not img_url:
                    return self._error("missing url", 400)
                cached = _img_get(img_url)
                if cached:
                    self._send_image(*cached)
                    return
                with _img_sem:
                    r = requests.get(img_url, timeout=15,
                                     headers={"User-Agent": "QuickShell/2.0"})
                    r.raise_for_status()
                    body = r.content
                    ct   = r.headers.get("Content-Type", "image/jpeg")
                _img_put(img_url, body, ct)
                self._send_image(body, ct)

            else:
                self._error("not found", 404)

        except (BrokenPipeError, ConnectionResetError):
            pass
        except Exception as e:
            import traceback; traceback.print_exc()
            self._error(str(e))

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        try:
            body = self._body()
            path = parsed.path

            if path == "/library/add":
                item_id    = body.get("id", "")
                media_type = body.get("type", "anime")
                status_key = body.get("status", "planning")
                if not item_id:
                    return self._error("missing id", 400)

                result = lib_add(
                    item_id,
                    body.get("title", ""),
                    body.get("coverUrl", ""),
                    status_key,
                    media_type,
                    body.get("item", {}),
                )

                al_result = None
                if AL_TOKEN:
                    al_map    = LOCAL_TO_AL_ANIME if media_type == "anime" else LOCAL_TO_AL_MANGA
                    al_status = al_map.get(status_key, "PLANNING")
                    al_result = al_save_entry(item_id, al_status)
                    _invalidate("userlist:")

                result["anilist"] = al_result
                self._json(result)

            elif path == "/library/update":
                item_id    = body.get("id", "")
                media_type = body.get("type", "anime")
                status_key = body.get("status", "planning")
                if not item_id:
                    return self._error("missing id", 400)

                result = lib_update(item_id, status_key, media_type)

                al_result = None
                if AL_TOKEN:
                    al_map    = LOCAL_TO_AL_ANIME if media_type == "anime" else LOCAL_TO_AL_MANGA
                    al_status = al_map.get(status_key, "PLANNING")
                    al_result = al_save_entry(item_id, al_status)
                    _invalidate("userlist:")

                result["anilist"] = al_result
                self._json(result)

            elif path == "/library/remove":
                item_id    = body.get("id", "")
                media_type = body.get("type", "anime")
                if not item_id:
                    return self._error("missing id", 400)

                result = lib_remove(item_id, media_type)

                al_result = None
                if AL_TOKEN:
                    al_media_type = "ANIME" if media_type == "anime" else "MANGA"
                    al_result = al_delete_entry(item_id, al_media_type)
                    _invalidate("userlist:")

                result["anilist"] = al_result
                self._json(result)

            else:
                self._error("not found", 404)

        except (BrokenPipeError, ConnectionResetError):
            pass
        except Exception as e:
            import traceback; traceback.print_exc()
            self._error(str(e))

if __name__ == "__main__":
    print(f"[anime-server] AniList backend on http://127.0.0.1:{PORT}")
    print(f"[anime-server] Local DB: {DB_PATH}")
    if AL_TOKEN:
        print(f"[anime-server] AniList token loaded ({len(AL_TOKEN)} chars) — list writes enabled")
    else:
        print("[anime-server] No AniList token — local-only mode")
        print("[anime-server]   → echo 'YOUR_TOKEN' > ~/.config/quickshell/anilist_token")
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    server.serve_forever()
