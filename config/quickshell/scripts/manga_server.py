#!/usr/bin/env python3
"""
AniList-backed Manga server for QuickShell.
Port: 5150
"""

import json
import sqlite3
import threading
import time
import urllib.parse
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer
from socketserver import ThreadingMixIn
from pathlib import Path

import requests

PORT        = 5150
ANILIST_GQL = "https://graphql.anilist.co"
MANGADEX    = "https://api.mangadex.org"

HEADERS = {
    "Content-Type": "application/json",
    "Accept":       "application/json",
    "User-Agent":   "QuickShell/2.0",
}

# ── AniList token ──────────────────────────────────────────────────────────
AL_TOKEN = ""
_tok_path = Path.home() / ".config/quickshell/anilist_token"
if _tok_path.exists():
    AL_TOKEN = _tok_path.read_text().strip()

AL_HEADERS = {
    "Content-Type": "application/json",
    "Accept":       "application/json",
    **({"Authorization": f"Bearer {AL_TOKEN}"} if AL_TOKEN else {}),
}

# ── Persistent storage ─────────────────────────────────────────────────────
DATA_DIR = Path.home() / ".local/share/quickshell-manga"
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
            id        TEXT PRIMARY KEY,
            title     TEXT NOT NULL,
            cover_url TEXT,
            status    TEXT NOT NULL DEFAULT 'planning',
            progress  INTEGER DEFAULT 0,
            added_at  TEXT,
            updated_at TEXT
        );
        CREATE TABLE IF NOT EXISTS favorites (
            id                       TEXT PRIMARY KEY,
            title                    TEXT NOT NULL,
            image_url                TEXT,
            added_at                 TEXT,
            last_known_chapter_count INTEGER DEFAULT 0,
            latest_seen_chapter_id   TEXT DEFAULT '',
            has_new_chapters         INTEGER DEFAULT 0
        );
        """)
        conn.commit()
        conn.close()

_init_db()

STATUSES = ["reading","completed","planning","on_hold","dropped","rereading"]

LOCAL_TO_AL = {
    "reading":   "CURRENT",
    "completed": "COMPLETED",
    "planning":  "PLANNING",
    "on_hold":   "PAUSED",
    "dropped":   "DROPPED",
    "rereading": "REPEATING",
}

# ── AniList mutations ──────────────────────────────────────────────────────
SAVE_Q = """
mutation($mediaId:Int,$status:MediaListStatus,$progress:Int){
  SaveMediaListEntry(mediaId:$mediaId,status:$status,progress:$progress){
    id status progress updatedAt
  }
}"""

DELETE_Q = """
mutation($id:Int){
  DeleteMediaListEntry(id:$id){ deleted }
}"""

GET_ENTRY_Q = """
query($mediaId:Int){
  Media(id:$mediaId,type:MANGA){
    mediaListEntry{ id status }
  }
}"""

# ── TTL cache ──────────────────────────────────────────────────────────────
_cache = {}
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
        if len(_cache) > 200:  # cap at 200 entries
            # evict oldest expired first, then oldest overall
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

# ── Image cache ────────────────────────────────────────────────────────────
_img_cache = {}
_img_lock  = threading.Lock()
_img_sem   = threading.Semaphore(10)

def _img_get(url):
    with _img_lock: return _img_cache.get(url)

def _img_put(url, body, ct):
    with _img_lock:
        total = sum(len(v[0]) for v in _img_cache.values())
        while _img_cache and (len(_img_cache) >= 50 or total + len(body) > 50 * 1024 * 1024):
            evicted = _img_cache.pop(next(iter(_img_cache)))
            total -= len(evicted[0])
        _img_cache[url] = (body, ct)

# ── GQL helper ─────────────────────────────────────────────────────────────
def _gql(query, variables, use_auth=False):
    hdrs = AL_HEADERS if use_auth else HEADERS
    r = requests.post(ANILIST_GQL, json={"query": query, "variables": variables},
                      headers=hdrs, timeout=15)
    if not r.ok:
        print(f"[manga] GQL error {r.status_code}: {r.text}")
    r.raise_for_status()
    return r.json()

# ── AniList write ──────────────────────────────────────────────────────────
def al_save(media_id, al_status, progress=0):
    if not AL_TOKEN:
        return {"ok": False, "error": "No AniList token"}
    try:
        res = _gql(SAVE_Q, {"mediaId": int(media_id), "status": al_status, "progress": progress}, True)
        errs = res.get("errors")
        if errs:
            return {"ok": False, "error": errs[0].get("message","AniList error")}
        e = res["data"]["SaveMediaListEntry"]
        print(f"[manga] AniList saved {media_id} → {e['status']}")
        return {"ok": True, "entryId": e["id"], "status": e["status"]}
    except Exception as ex:
        return {"ok": False, "error": str(ex)}

def al_delete(media_id):
    if not AL_TOKEN:
        return {"ok": False, "error": "No AniList token"}
    try:
        res = _gql(GET_ENTRY_Q, {"mediaId": int(media_id)}, True)
        entry = (res.get("data") or {}).get("Media", {}).get("mediaListEntry")
        if not entry:
            return {"ok": False, "error": "Not in list"}
        d = _gql(DELETE_Q, {"id": entry["id"]}, True)
        errs = d.get("errors")
        if errs:
            return {"ok": False, "error": errs[0].get("message","AniList error")}
        return {"ok": True, "deleted": d["data"]["DeleteMediaListEntry"]["deleted"]}
    except Exception as ex:
        return {"ok": False, "error": str(ex)}

# ── Normalise ──────────────────────────────────────────────────────────────
def _norm(media):
    title = media.get("title") or {}
    cover = media.get("coverImage") or {}
    return {
        "id":          str(media.get("id","")),
        "title":       title.get("english") or title.get("romaji") or title.get("native") or "",
        "image":       cover.get("large") or cover.get("medium") or "",
        "status":      media.get("status") or "",
        "type":        _fmt(media.get("format") or ""),
        "score":       (media.get("averageScore") or 0) / 10,
        "chapters":    media.get("chapters") or 0,
        "volumes":     media.get("volumes") or 0,
        "description": _strip(media.get("description") or ""),
        "tags":        [t["name"] for t in (media.get("tags") or [])[:8]],
        "authors":     [e["node"]["name"]["full"] for e in (media.get("staff") or {}).get("edges",[])
                        if e.get("role","").lower() in ("story","art","story & art")][:3],
        "genres":      media.get("genres") or [],
        "country":     media.get("countryOfOrigin") or "",
    }

def _fmt(f):
    return {"MANGA":"Manga","MANHWA":"Manhwa","MANHUA":"Manhua",
            "ONE_SHOT":"One Shot","NOVEL":"Novel"}.get(f,f)

def _strip(s):
    import re
    return re.sub(r"<[^>]+>","",s).strip()[:800]

# ── Browse queries ─────────────────────────────────────────────────────────
_BROWSE_Q = """
query($page:Int,$perPage:Int,$sort:[MediaSort],$country:CountryCode,$format_in:[MediaFormat]){
  Page(page:$page,perPage:$perPage){
    pageInfo{hasNextPage total}
    media(type:MANGA,isAdult:false,sort:$sort,countryOfOrigin:$country,format_in:$format_in){
      id title{romaji english native}
      coverImage{large medium}
      averageScore chapters volumes status format countryOfOrigin genres
    }
  }
}"""

def _browse(page, per_page, sort, country=None, fmt_in=None):
    v = {"page": page, "perPage": per_page, "sort": sort}
    if country: v["country"] = country
    if fmt_in:  v["format_in"] = fmt_in
    data = _gql(_BROWSE_Q, v)
    pg   = data["data"]["Page"]
    return {
        "results": [_norm(m) for m in pg["media"]],
        "hasMore":  pg["pageInfo"]["hasNextPage"],
        "total":    pg["pageInfo"]["total"],
    }

def hot():
    return _cached("hot", 600, lambda: _browse(1, 30, ["TRENDING_DESC"]))

def latest(page=1):
    return _cached(f"latest:{page}", 300, lambda: _browse(page, 26, ["UPDATED_AT_DESC"]))

_SEARCH_Q = """
query($q:String,$page:Int,$format_in:[MediaFormat]){
  Page(page:$page,perPage:40){
    pageInfo{hasNextPage}
    media(search:$q,type:MANGA,isAdult:false,format_in:$format_in){
      id title{romaji english native}
      coverImage{large medium}
      averageScore chapters volumes status format countryOfOrigin genres
    }
  }
}"""

def search(q, mtype=None, offset=0):
    page   = (offset // 40) + 1
    fmt_in = {"Manga":["MANGA","ONE_SHOT"],"Manhwa":["MANHWA"],"Manhua":["MANGA"]}.get(mtype)
    def _f():
        v = {"q": q, "page": page}
        if fmt_in: v["format_in"] = fmt_in
        data    = _gql(_SEARCH_Q, v)
        pg      = data["data"]["Page"]
        results = [_norm(m) for m in pg["media"]]
        return {"results": results, "hasMore": pg["pageInfo"]["hasNextPage"],
                "nextOffset": offset + len(results)}
    return _cached(f"search:{q}:{mtype}:{page}", 600, _f)

# ── Info — fetches chapters from MangaDex when AniList has none ───────────
_INFO_Q = """
query($id:Int){
  Media(id:$id,type:MANGA){
    id title{romaji english native}
    coverImage{large medium}
    bannerImage description averageScore
    chapters volumes status format countryOfOrigin genres
    tags{name}
    staff(perPage:8){edges{role node{name{full}}}}
    externalLinks{url site}
  }
}"""

_MD_SEARCH_Q = "https://api.mangadex.org/manga"
_MD_CHAPTERS  = "https://api.mangadex.org/manga/{}/feed"

def _mangadex_chapters(title, anilist_id):
    try:
        import re, unicodedata
        titles_to_try = [title]
        if ":" in title:
            titles_to_try.append(title.split(":")[0].strip())
        plain = re.sub(r"[^\w\s]", "", title).strip()
        if plain != title:
            titles_to_try.append(plain)

        md_id = None
        for t in titles_to_try:
            r = requests.get(_MD_SEARCH_Q, params={
                "title": t, "limit": 5,
                "contentRating[]": ["safe","suggestive","erotica"],
                "availableTranslatedLanguage[]": ["en"],
            }, headers={"User-Agent": "QuickShell/2.0"}, timeout=10)
            r.raise_for_status()
            results = r.json().get("data", [])
            if results:
                md_id = results[0]["id"]
                print(f"[manga] MangaDex matched '{t}' → {md_id}")
                break

        if not md_id:
            return []

        seen_nums = {}
        offset    = 0
        while True:
            cr = requests.get(_MD_CHAPTERS.format(md_id), params={
                "order[chapter]": "asc",
                "limit": 100,
                "offset": offset,
                "contentRating[]": ["safe","suggestive","erotica"],
            }, headers={"User-Agent": "QuickShell/2.0"}, timeout=10)
            cr.raise_for_status()
            cd    = cr.json()
            batch = cd.get("data", [])
            if not batch:
                break
            for ch in batch:
                attr  = ch.get("attributes", {})
                chnum = attr.get("chapter") or ""
                lang  = attr.get("translatedLanguage") or "?"
                title_raw = attr.get("title") or ""
                # Drop non-ASCII titles (Korean/Japanese scanlation group names)
                try:
                    title_raw.encode("ascii")
                except UnicodeEncodeError:
                    title_raw = ""
                display = title_raw or (f"Chapter {chnum}" if chnum else "Oneshot")
                entry = {
                    "id":        ch["id"],
                    "chapter":   chnum,
                    "title":     display,
                    "publishAt": (attr.get("publishAt") or "")[:10],
                    "lang":      lang,
                }
                if chnum not in seen_nums:
                    seen_nums[chnum] = entry
                elif lang == "en" and seen_nums[chnum]["lang"] != "en":
                    seen_nums[chnum] = entry
            total  = cd.get("total", 0)
            offset += len(batch)
            if offset >= total:
                break

        def _ch_key(e):
            try:    return float(e["chapter"])
            except: return 0.0
        return sorted(seen_nums.values(), key=_ch_key, reverse=True)

    except Exception as e:
        print(f"[manga] MangaDex fetch failed: {e}")
        return []

def info(manga_id):
    def _fetch():
        data  = _gql(_INFO_Q, {"id": int(manga_id)})
        media = data["data"]["Media"]
        base  = _norm(media)

        al_count = media.get("chapters") or 0
        chapters = []

        if al_count > 0:
            # AniList knows the chapter count — build synthetic list
            for i in range(al_count, 0, -1):
                chapters.append({
                    "id":        f"{manga_id}-ch{i}",
                    "chapter":   str(i),
                    "title":     f"Chapter {i}",
                    "publishAt": "",
                })
        else:
            # AniList has no chapter data (ongoing) — try MangaDex
            title = base.get("title", "")
            if title:
                print(f"[manga] AniList chapters=0 for '{title}', querying MangaDex...")
                chapters = _mangadex_chapters(title, manga_id)
                print(f"[manga] MangaDex returned {len(chapters)} chapters")

        # External links
        ext_links = [e for e in (media.get("externalLinks") or [])
                     if e.get("site","").lower() in
                     ("mangadex","mangaplus","comicwalker","comic walker")]
        all_ext   = media.get("externalLinks") or []

        base.update({
            "chapters":    chapters,
            "extLinks":    ext_links,
            "allExtLinks": all_ext,
            "bannerImage": media.get("bannerImage") or "",
        })
        return base
    return _cached(f"info:{manga_id}", 1800, _fetch)

# ── MangaDex pages ─────────────────────────────────────────────────────────
def pages(chapter_id):
    # Synthetic ids like "12345-ch3" → no pages available
    if "-ch" in chapter_id and not _is_uuid(chapter_id):
        return []
    def _fetch():
        r = requests.get(f"{MANGADEX}/at-home/server/{chapter_id}", timeout=15)
        r.raise_for_status()
        d    = r.json()
        base = d["baseUrl"]
        ch   = d["chapter"]
        out  = []
        for fn in ch["data"]:
            out.append({
                "page": len(out) + 1,
                "img":  f"http://127.0.0.1:{PORT}/image?url="
                        + urllib.parse.quote(f"{base}/data/{ch['hash']}/{fn}", safe=""),
            })
        return out
    return _cached(f"pages:{chapter_id}", 3600, _fetch)

def _is_uuid(s):
    import re
    return bool(re.match(
        r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", s))

# ── Image proxy ────────────────────────────────────────────────────────────
def proxy_image(handler, url):
    cached = _img_get(url)
    if cached:
        body, ct = cached
    else:
        with _img_sem:
            r = requests.get(url, headers={"User-Agent":"QuickShell/2.0"}, timeout=15)
            r.raise_for_status()
            body = r.content
            ct   = r.headers.get("Content-Type","image/jpeg")
        _img_put(url, body, ct)
    handler.send_response(200)
    handler.send_header("Content-Type", ct)
    handler.send_header("Content-Length", str(len(body)))
    handler.send_header("Cache-Control", "public, max-age=86400")
    handler.send_header("Access-Control-Allow-Origin", "*")
    handler.end_headers()
    try:    handler.wfile.write(body)
    except: pass

# ── Local library ──────────────────────────────────────────────────────────
def lib_all():
    with _db_lock:
        conn = _get_db()
        rows = conn.execute("SELECT * FROM library ORDER BY updated_at DESC").fetchall()
        conn.close()
    result = {s: [] for s in STATUSES}
    for row in rows:
        d = dict(row)
        s = d.get("status","planning")
        if s not in result: result[s] = []
        result[s].append(d)
    return result

def lib_status(manga_id):
    with _db_lock:
        conn = _get_db()
        row  = conn.execute("SELECT status FROM library WHERE id=?", (manga_id,)).fetchone()
        conn.close()
    return row["status"] if row else ""

def lib_add(manga_id, title, cover_url, status="planning"):
    now = datetime.now(timezone.utc).isoformat()
    with _db_lock:
        conn = _get_db()
        conn.execute("""
        INSERT INTO library(id,title,cover_url,status,added_at,updated_at)
        VALUES(?,?,?,?,?,?)
        ON CONFLICT(id) DO UPDATE SET status=excluded.status, updated_at=excluded.updated_at
        """, (manga_id, title, cover_url, status, now, now))
        conn.commit(); conn.close()
    return {"ok": True}

def lib_update(manga_id, status):
    now = datetime.now(timezone.utc).isoformat()
    with _db_lock:
        conn = _get_db()
        conn.execute("UPDATE library SET status=?,updated_at=? WHERE id=?", (status,now,manga_id))
        conn.commit(); conn.close()
    return {"ok": True}

def lib_remove(manga_id):
    with _db_lock:
        conn = _get_db()
        conn.execute("DELETE FROM library WHERE id=?", (manga_id,))
        conn.commit(); conn.close()
    return {"ok": True}

# ── Favorites ──────────────────────────────────────────────────────────────
def fav_list():
    with _db_lock:
        conn = _get_db()
        rows = conn.execute("SELECT * FROM favorites ORDER BY added_at DESC").fetchall()
        conn.close()
    return [dict(r) for r in rows]

def fav_add(manga_id, title, image_url):
    now = datetime.now(timezone.utc).isoformat()
    with _db_lock:
        conn = _get_db()
        conn.execute("INSERT OR IGNORE INTO favorites(id,title,image_url,added_at) VALUES(?,?,?,?)",
                     (manga_id, title, image_url, now))
        conn.commit(); conn.close()
    return {"ok": True}

def fav_remove(manga_id):
    with _db_lock:
        conn = _get_db()
        conn.execute("DELETE FROM favorites WHERE id=?", (manga_id,))
        conn.commit(); conn.close()
    return {"ok": True}

def fav_mark_seen(manga_id, chapter_id):
    with _db_lock:
        conn = _get_db()
        conn.execute("UPDATE favorites SET latest_seen_chapter_id=?,has_new_chapters=0 WHERE id=?",
                     (chapter_id, manga_id))
        conn.commit(); conn.close()
    return {"ok": True}

def fav_check():
    favs = fav_list(); updated = []
    for fav in favs:
        try:
            _invalidate(f"info:{fav['id']}")
            d = info(fav["id"])
            count = len(d.get("chapters") or [])
            if count > (fav.get("last_known_chapter_count") or 0):
                updated.append({"id": fav["id"], "title": fav["title"]})
                with _db_lock:
                    conn = _get_db()
                    conn.execute("UPDATE favorites SET has_new_chapters=1,last_known_chapter_count=? WHERE id=?",
                                 (count, fav["id"]))
                    conn.commit(); conn.close()
        except: pass
    return {"checked": len(favs), "updated": updated}

# ── HTTP Server ────────────────────────────────────────────────────────────
class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True; allow_reuse_address = True

class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args): print(f"[manga] {fmt%args}")

    def _json(self, data, status=200):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Content-Type","application/json")
        self.send_header("Content-Length",str(len(body)))
        self.send_header("Access-Control-Allow-Origin","*")
        self.end_headers(); self.wfile.write(body)

    def _error(self, msg, status=500): self._json({"error": msg}, status)

    def _body(self):
        n = int(self.headers.get("Content-Length",0))
        return json.loads(self.rfile.read(n)) if n else {}

    def do_HEAD(self):
        p = urllib.parse.urlparse(self.path).path
        self.send_response(200 if p == "/image" else 404)
        if p == "/image": self.send_header("Content-Type","image/jpeg")
        self.end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        qs     = urllib.parse.parse_qs(parsed.query)
        def p(k, d=""): return (qs.get(k) or [d])[0]
        try:
            path = parsed.path
            if path == "/health":
                self._json({"ok":True,"backend":"anilist","hasToken":bool(AL_TOKEN)})
            elif path == "/hot":
                self._json(hot())
            elif path == "/latest":
                self._json(latest(int(p("page","1"))))
            elif path == "/search":
                q = p("q")
                if not q: return self._error("missing q",400)
                self._json(search(q, p("type") or None, int(p("offset","0"))))
            elif path == "/info":
                mid = p("id")
                if not mid: return self._error("missing id",400)
                self._json(info(mid))
            elif path == "/pages":
                cid = p("chapterId")
                if not cid: return self._error("missing chapterId",400)
                self._json(pages(cid))
            elif path == "/image":
                url = urllib.parse.unquote(p("url"))
                if not url: return self._error("missing url",400)
                proxy_image(self, url)
            elif path == "/favorites":          self._json(fav_list())
            elif path == "/favorites/check":    self._json(fav_check())
            elif path == "/library/all":        self._json(lib_all())
            elif path == "/library/status":
                mid = p("id")
                if not mid: return self._error("missing id",400)
                self._json({"status": lib_status(mid)})
            elif path == "/dl/list":            self._json([])
            elif path == "/dl/progress":        self._json({"status":"not_started","total":0,"done":0})
            elif path == "/dl/pages":           self._json([])
            else: self._error("not found",404)
        except (BrokenPipeError, ConnectionResetError): pass
        except Exception as e:
            import traceback; traceback.print_exc(); self._error(str(e))

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        try:
            body = self._body()
            path = parsed.path

            if path == "/favorites/add":
                mid = body.get("id","")
                if not mid: return self._error("missing id",400)
                self._json(fav_add(mid, body.get("title",""), body.get("imageUrl","")))

            elif path == "/favorites/remove":
                mid = body.get("id","")
                if not mid: return self._error("missing id",400)
                self._json(fav_remove(mid))

            elif path == "/favorites/mark-seen":
                mid = body.get("id","")
                if not mid: return self._error("missing id",400)
                self._json(fav_mark_seen(mid, body.get("chapterId","")))

            elif path == "/library/add":
                mid    = body.get("id","")
                status = body.get("status","planning")
                if not mid: return self._error("missing id",400)
                result = lib_add(mid, body.get("title",""), body.get("coverUrl",""), status)
                al_r = None
                if AL_TOKEN:
                    al_r = al_save(mid, LOCAL_TO_AL.get(status,"PLANNING"))
                    _invalidate("userlist:")
                result["anilist"] = al_r
                self._json(result)

            elif path == "/library/update":
                mid    = body.get("id","")
                status = body.get("status","planning")
                if not mid: return self._error("missing id",400)
                result = lib_update(mid, status)
                al_r = None
                if AL_TOKEN:
                    al_r = al_save(mid, LOCAL_TO_AL.get(status,"PLANNING"))
                    _invalidate("userlist:")
                result["anilist"] = al_r
                self._json(result)

            elif path == "/library/remove":
                mid = body.get("id","")
                if not mid: return self._error("missing id",400)
                result = lib_remove(mid)
                al_r = None
                if AL_TOKEN:
                    al_r = al_delete(mid)
                    _invalidate("userlist:")
                result["anilist"] = al_r
                self._json(result)

            elif path == "/dl/start":   self._json({"ok":False,"message":"not supported"})
            elif path == "/dl/delete":  self._json({"ok":False,"error":"not found"})
            else: self._error("not found",404)

        except (BrokenPipeError, ConnectionResetError): pass
        except Exception as e:
            import traceback; traceback.print_exc(); self._error(str(e))

if __name__ == "__main__":
    print(f"[manga] AniList backend on http://127.0.0.1:{PORT}")
    print(f"[manga] DB: {DB_PATH}")
    if AL_TOKEN:
        print(f"[manga] AniList token loaded ({len(AL_TOKEN)} chars) — writes enabled")
    else:
        print("[manga] No AniList token — local-only mode")
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    server.serve_forever()
