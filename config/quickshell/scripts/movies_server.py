#!/usr/bin/env python3
"""
TMDB-backed Movies & TV server for QuickShell.
Port: 5250
"""

import json
import os
import sqlite3
import threading
import time
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from socketserver import ThreadingMixIn
from urllib.parse import urlparse, parse_qs, quote, unquote

import requests

PORT     = 5250
TMDB_URL = "https://api.themoviedb.org/3"
IMG_URL  = "https://image.tmdb.org/t/p"

# ── Token & Account ───────────────────────────────────────────────────────────
TOKEN = os.environ.get("TMDB_TOKEN", "")
if not TOKEN:
    for _f in ["~/.config/quickshell/tmdb_token"]:
        _p = os.path.expanduser(_f)
        if os.path.exists(_p):
            TOKEN = open(_p).read().strip()
            break

ACCOUNT_ID = os.environ.get("TMDB_ACCOUNT_ID", "")
if not ACCOUNT_ID:
    for _f in ["~/.config/quickshell/tmdb_account_id",
               "~/.config/quickshell/tmdb_account"]:
        _p = os.path.expanduser(_f)
        if os.path.exists(_p):
            ACCOUNT_ID = open(_p).read().strip()
            break

HEADERS = {
    "Authorization": f"Bearer {TOKEN}",
    "Accept": "application/json",
}

# ── Local SQLite DB ───────────────────────────────────────────────────────────
DATA_DIR = Path.home() / ".local/share/quickshell-movies"
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
        CREATE TABLE IF NOT EXISTS userlist (
            id         TEXT NOT NULL,
            media_type TEXT NOT NULL,
            status     TEXT NOT NULL,
            title      TEXT,
            poster     TEXT,
            rating     REAL,
            release_date TEXT,
            added_at   TEXT,
            updated_at TEXT,
            item_json  TEXT,
            PRIMARY KEY (id, media_type)
        );

        CREATE TABLE IF NOT EXISTS watchlist (
            id         TEXT NOT NULL,
            media_type TEXT NOT NULL,
            title      TEXT,
            poster     TEXT,
            rating     REAL,
            release_date TEXT,
            added_at   TEXT,
            item_json  TEXT,
            PRIMARY KEY (id, media_type)
        );

        CREATE TABLE IF NOT EXISTS favorites (
            id         TEXT NOT NULL,
            media_type TEXT NOT NULL,
            title      TEXT,
            poster     TEXT,
            rating     REAL,
            release_date TEXT,
            added_at   TEXT,
            item_json  TEXT,
            PRIMARY KEY (id, media_type)
        );
        """)
        conn.commit()
        conn.close()


_init_db()

STATUSES = ["watching", "completed", "planning", "on_hold", "dropped"]


# ── TTL cache ─────────────────────────────────────────────────────────────────
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


# ── Image cache ───────────────────────────────────────────────────────────────
_img_cache = {}
_img_lock  = threading.Lock()
_img_sem   = threading.Semaphore(8)


def _img_get(key):
    with _img_lock:
        return _img_cache.get(key)

def _img_put(key, body, ct):
    with _img_lock:
        total = sum(len(v[0]) for v in _img_cache.values())
        while _img_cache and (len(_img_cache) >= 50 or total + len(body) > 50 * 1024 * 1024):
            evicted = _img_cache.pop(next(iter(_img_cache)))
            total -= len(evicted[0])
        _img_cache[key] = (body, ct)

# ── TMDB helpers ──────────────────────────────────────────────────────────────
def tmdb(path, params=None):
    r = requests.get(f"{TMDB_URL}{path}", headers=HEADERS,
                     params=params or {}, timeout=15)
    r.raise_for_status()
    return r.json()


def tmdb_post(path, body):
    r = requests.post(f"{TMDB_URL}{path}", headers=HEADERS,
                      json=body, timeout=15)
    r.raise_for_status()
    return r.json()


def poster(path, size="w342"):
    if not path:
        return ""
    return f"http://127.0.0.1:{PORT}/image?path={quote(path, safe='')}&size={size}"


def norm_item(m, media_type):
    return {
        "id":          m.get("id"),
        "type":        media_type,
        "title":       m.get("title") or m.get("name") or "",
        "overview":    m.get("overview", ""),
        "poster":      poster(m.get("poster_path")),
        "backdrop":    poster(m.get("backdrop_path"), "w1280"),
        "rating":      round(m.get("vote_average", 0), 1),
        "votes":       m.get("vote_count", 0),
        "releaseDate": m.get("release_date") or m.get("first_air_date") or "",
        "genreIds":    m.get("genre_ids", []),
        "popularity":  m.get("popularity", 0),
        "language":    m.get("original_language", ""),
    }


# ── Browse ────────────────────────────────────────────────────────────────────
def trending(media_type="movie", page=1):
    def _f():
        data  = tmdb(f"/trending/{media_type}/week",
                     {"page": page, "language": "en-US"})
        items = [norm_item(r, media_type) for r in data.get("results", [])]
        return {"results": items, "totalPages": data.get("total_pages", 1), "page": page}
    return _cached(f"trending:{media_type}:{page}", 600, _f)


def search_tmdb(query, media_type="movie", page=1):
    def _f():
        data  = tmdb(f"/search/{media_type}",
                     {"query": query, "page": page, "language": "en-US"})
        items = [norm_item(r, media_type) for r in data.get("results", [])]
        return {"results": items, "totalPages": data.get("total_pages", 1), "page": page}
    return _cached(f"search:{query}:{media_type}:{page}", 300, _f)


def discover(media_type="movie", genre_id=None, page=1, sort_by="popularity.desc"):
    def _f():
        params = {"page": page, "language": "en-US", "sort_by": sort_by,
                  "include_adult": "false", "vote_count.gte": 50}
        if genre_id:
            params["with_genres"] = genre_id
        data  = tmdb(f"/discover/{media_type}", params)
        items = [norm_item(r, media_type) for r in data.get("results", [])]
        return {"results": items, "totalPages": data.get("total_pages", 1), "page": page}
    return _cached(f"discover:{media_type}:{genre_id}:{page}:{sort_by}", 600, _f)


def genres(media_type="movie"):
    def _f():
        data = tmdb(f"/genre/{media_type}/list", {"language": "en-US"})
        return data.get("genres", [])
    return _cached(f"genres:{media_type}", 86400, _f)


def detail(item_id, media_type="movie"):
    def _f():
        data = tmdb(f"/{media_type}/{item_id}", {
            "language":           "en-US",
            "append_to_response": "credits,videos,watch/providers,similar",
        })
        genre_names = [g["name"] for g in data.get("genres", [])]
        cast = [
            {"name": p["name"], "character": p.get("character", ""),
             "photo": poster(p.get("profile_path"), "w185")}
            for p in data.get("credits", {}).get("cast", [])[:10]
        ]
        videos = [
            {"key": v["key"], "name": v["name"], "type": v["type"], "site": v["site"]}
            for v in data.get("videos", {}).get("results", [])
            if v.get("site") == "YouTube" and v.get("type") in ("Trailer", "Teaser")
        ]
        us_prov   = data.get("watch/providers", {}).get("results", {}).get("US", {})
        streaming = [
            {"name": p["provider_name"], "logo": poster(p.get("logo_path"), "w92")}
            for p in us_prov.get("flatrate", [])
        ]
        similar = [norm_item(s, media_type)
                   for s in data.get("similar", {}).get("results", [])[:10]]
        base = norm_item(data, media_type)
        base.update({
            "genres":    genre_names,
            "tagline":   data.get("tagline", ""),
            "status":    data.get("status", ""),
            "runtime":   data.get("runtime") or
                         (data.get("episode_run_time") or [None])[0],
            "budget":    data.get("budget"),
            "revenue":   data.get("revenue"),
            "cast":      cast,
            "trailers":  videos,
            "streaming": streaming,
            "similar":   similar,
            "seasons":   data.get("number_of_seasons"),
            "episodes":  data.get("number_of_episodes"),
            "networks":  [n["name"] for n in data.get("networks", [])],
        })
        return base
    return _cached(f"detail:{media_type}:{item_id}", 1800, _f)


# ── TMDB account watchlist / favorites ────────────────────────────────────────
def _require_account():
    if not ACCOUNT_ID:
        raise ValueError("TMDB_ACCOUNT_ID not configured")


def _fetch_tmdb_watchlist(media_type, page=1):
    """Fetch watchlist from TMDB. media_type: 'movie' or 'tv'"""
    _require_account()
    # TMDB endpoint: /account/{id}/watchlist/movies  or  /account/{id}/watchlist/tv
    endpoint = f"/account/{ACCOUNT_ID}/watchlist/{'movies' if media_type == 'movie' else 'tv'}"
    data  = tmdb(endpoint, {"page": page, "language": "en-US", "sort_by": "created_at.desc"})
    items = [norm_item(r, media_type) for r in data.get("results", [])]
    return items, data.get("total_pages", 1)


def _fetch_tmdb_favorites(media_type, page=1):
    """Fetch favorites from TMDB. media_type: 'movie' or 'tv'"""
    _require_account()
    # TMDB endpoint: /account/{id}/favorite/movies  or  /account/{id}/favorite/tv
    endpoint = f"/account/{ACCOUNT_ID}/favorite/{'movies' if media_type == 'movie' else 'tv'}"
    data  = tmdb(endpoint, {"page": page, "language": "en-US", "sort_by": "created_at.desc"})
    items = [norm_item(r, media_type) for r in data.get("results", [])]
    return items, data.get("total_pages", 1)


def _sync_tmdb_watchlist_to_db(media_type):
    """Pull ALL pages of TMDB watchlist and upsert into the local DB."""
    now  = datetime.now(timezone.utc).isoformat()
    page = 1
    with _db_lock:
        conn = _get_db()
        conn.execute("DELETE FROM watchlist WHERE media_type=?", (media_type,))
        while True:
            try:
                items, total = _fetch_tmdb_watchlist(media_type, page)
                for item in items:
                    conn.execute("""
                    INSERT OR REPLACE INTO watchlist
                    (id,media_type,title,poster,rating,release_date,added_at,item_json)
                    VALUES(?,?,?,?,?,?,?,?)
                    """, (str(item["id"]), media_type, item["title"],
                          item["poster"], item["rating"], item["releaseDate"],
                          now, json.dumps(item)))
                if page >= total:
                    break
                page += 1
            except Exception as e:
                print(f"[movies] sync watchlist/{media_type} page {page} error: {e}")
                break
        conn.commit()
        conn.close()
    _invalidate(f"local:watchlist:{media_type}")


def _sync_tmdb_favorites_to_db(media_type):
    """Pull ALL pages of TMDB favorites and upsert into the local DB."""
    now  = datetime.now(timezone.utc).isoformat()
    page = 1
    with _db_lock:
        conn = _get_db()
        conn.execute("DELETE FROM favorites WHERE media_type=?", (media_type,))
        while True:
            try:
                items, total = _fetch_tmdb_favorites(media_type, page)
                for item in items:
                    conn.execute("""
                    INSERT OR REPLACE INTO favorites
                    (id,media_type,title,poster,rating,release_date,added_at,item_json)
                    VALUES(?,?,?,?,?,?,?,?)
                    """, (str(item["id"]), media_type, item["title"],
                          item["poster"], item["rating"], item["releaseDate"],
                          now, json.dumps(item)))
                if page >= total:
                    break
                page += 1
            except Exception as e:
                print(f"[movies] sync favorites/{media_type} page {page} error: {e}")
                break
        conn.commit()
        conn.close()
    _invalidate(f"local:favorites:{media_type}")


def _db_list(table, media_type):
    key = f"local:{table}:{media_type}"
    def _f():
        with _db_lock:
            conn = _get_db()
            rows = conn.execute(
                f"SELECT item_json FROM {table} WHERE media_type=? ORDER BY added_at DESC",
                (media_type,)).fetchall()
            conn.close()
        result = []
        for row in rows:
            try:
                result.append(json.loads(row["item_json"]))
            except Exception:
                pass
        return result
    return _cached(key, 60, _f)


def _db_in_list(table, item_id, media_type):
    with _db_lock:
        conn = _get_db()
        row  = conn.execute(
            f"SELECT 1 FROM {table} WHERE id=? AND media_type=?",
            (str(item_id), media_type)).fetchone()
        conn.close()
    return row is not None


def _db_add_to_list(table, item, media_type):
    now = datetime.now(timezone.utc).isoformat()
    item_copy = dict(item)
    item_copy["type"] = media_type
    with _db_lock:
        conn = _get_db()
        conn.execute(f"""
        INSERT OR REPLACE INTO {table}
        (id,media_type,title,poster,rating,release_date,added_at,item_json)
        VALUES(?,?,?,?,?,?,?,?)
        """, (str(item.get("id")), media_type,
              item.get("title", ""), item.get("poster", ""),
              item.get("rating", 0), item.get("releaseDate", ""),
              now, json.dumps(item_copy)))
        conn.commit()
        conn.close()
    _invalidate(f"local:{table}:{media_type}")


def _db_remove_from_list(table, item_id, media_type):
    with _db_lock:
        conn = _get_db()
        conn.execute(f"DELETE FROM {table} WHERE id=? AND media_type=?",
                     (str(item_id), media_type))
        conn.commit()
        conn.close()
    _invalidate(f"local:{table}:{media_type}")


# TMDB-backed add/remove that also update DB
def add_to_watchlist_tmdb(item_id, media_type):
    _require_account()
    result = tmdb_post(f"/account/{ACCOUNT_ID}/watchlist",
                       {"media_type": media_type,
                        "media_id":   int(item_id),
                        "watchlist":  True})
    try:
        d = detail(int(item_id), media_type)
        _db_add_to_list("watchlist", d, media_type)
    except Exception:
        pass
    _invalidate(f"local:watchlist:{media_type}")
    return result


def remove_from_watchlist_tmdb(item_id, media_type):
    _require_account()
    result = tmdb_post(f"/account/{ACCOUNT_ID}/watchlist",
                       {"media_type": media_type,
                        "media_id":   int(item_id),
                        "watchlist":  False})
    _db_remove_from_list("watchlist", item_id, media_type)
    return result


def add_to_favorites_tmdb(item_id, media_type):
    _require_account()
    result = tmdb_post(f"/account/{ACCOUNT_ID}/favorite",
                       {"media_type": media_type,
                        "media_id":   int(item_id),
                        "favorite":   True})
    try:
        d = detail(int(item_id), media_type)
        _db_add_to_list("favorites", d, media_type)
    except Exception:
        pass
    _invalidate(f"local:favorites:{media_type}")
    return result


def remove_from_favorites_tmdb(item_id, media_type):
    _require_account()
    result = tmdb_post(f"/account/{ACCOUNT_ID}/favorite",
                       {"media_type": media_type,
                        "media_id":   int(item_id),
                        "favorite":   False})
    _db_remove_from_list("favorites", item_id, media_type)
    return result


# ── Local userlist ────────────────────────────────────────────────────────────
def ul_get_all(media_type):
    with _db_lock:
        conn = _get_db()
        rows = conn.execute(
            "SELECT * FROM userlist WHERE media_type=? ORDER BY updated_at DESC",
            (media_type,)).fetchall()
        conn.close()
    result = {s: [] for s in STATUSES}
    for row in rows:
        s = row["status"]
        if s not in result:
            result[s] = []
        try:
            item = json.loads(row["item_json"] or "{}")
        except Exception:
            item = {}
        item.update({
            "id":     row["id"],
            "type":   row["media_type"],
            "status": s,
            "title":  row["title"] or item.get("title", ""),
            "poster": row["poster"] or item.get("poster", ""),
            "rating": row["rating"] or item.get("rating", 0),
        })
        result[s].append(item)
    return result


def ul_get_status(item_id, media_type):
    with _db_lock:
        conn = _get_db()
        row  = conn.execute(
            "SELECT status FROM userlist WHERE id=? AND media_type=?",
            (str(item_id), media_type)).fetchone()
        conn.close()
    return row["status"] if row else ""


def ul_add(item_id, media_type, status, item_data):
    now = datetime.now(timezone.utc).isoformat()
    with _db_lock:
        conn = _get_db()
        conn.execute("""
        INSERT OR REPLACE INTO userlist
        (id,media_type,status,title,poster,rating,release_date,added_at,updated_at,item_json)
        VALUES(?,?,?,?,?,?,?,?,?,?)
        """, (str(item_id), media_type, status,
              item_data.get("title", ""), item_data.get("poster", ""),
              item_data.get("rating", 0), item_data.get("releaseDate", ""),
              now, now, json.dumps(item_data)))
        conn.commit()
        conn.close()
        _invalidate(f"ul:{media_type}")
        print(f"[movies] ul_add: {item_id} {media_type} {status}")
        return {"ok": True, "id": str(item_id), "status": status}


def ul_update(item_id, media_type, new_status):
    now = datetime.now(timezone.utc).isoformat()
    with _db_lock:
        conn = _get_db()
        conn.execute(
            "UPDATE userlist SET status=?,updated_at=? WHERE id=? AND media_type=?",
            (new_status, now, str(item_id), media_type))
        conn.commit()
        conn.close()
    _invalidate(f"ul:{media_type}")
    return {"ok": True}


def ul_remove(item_id, media_type):
    with _db_lock:
        conn = _get_db()
        conn.execute("DELETE FROM userlist WHERE id=? AND media_type=?",
                     (str(item_id), media_type))
        conn.commit()
        conn.close()
    _invalidate(f"ul:{media_type}")
    return {"ok": True}


# ── Background sync ───────────────────────────────────────────────────────────
def _background_sync():
    if not ACCOUNT_ID or not TOKEN:
        return
    for mt in ("movie", "tv"):
        try:
            _sync_tmdb_watchlist_to_db(mt)
            print(f"[movies] synced watchlist/{mt}")
        except Exception as e:
            print(f"[movies] watchlist/{mt} sync failed: {e}")
        try:
            _sync_tmdb_favorites_to_db(mt)
            print(f"[movies] synced favorites/{mt}")
        except Exception as e:
            print(f"[movies] favorites/{mt} sync failed: {e}")


# ── HTTP Server ───────────────────────────────────────────────────────────────
class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads      = True
    allow_reuse_address = True


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print(f"[movies] {fmt % args}")

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

    def _body(self):
        length = int(self.headers.get("Content-Length", 0))
        return json.loads(self.rfile.read(length)) if length else {}

    def do_GET(self):
        parsed = urlparse(self.path)
        qs     = parse_qs(parsed.query)

        def p(k, d=""):
            return (qs.get(k) or [d])[0]

        try:
            path = parsed.path

            if path == "/health":
                if not TOKEN:
                    return self._json({"error": "No TMDB token"}, 503)
                self._json({"ok": True,
                            "hasAccount": bool(ACCOUNT_ID),
                            "accountId":  ACCOUNT_ID or None})

            elif path == "/trending":
                self._json(trending(p("type", "movie"), int(p("page", "1"))))

            elif path == "/search":
                q = p("q")
                if not q:
                    return self._error("missing q", 400)
                self._json(search_tmdb(q, p("type", "movie"), int(p("page", "1"))))

            elif path == "/detail":
                iid = p("id")
                if not iid:
                    return self._error("missing id", 400)
                self._json(detail(int(iid), p("type", "movie")))

            elif path == "/genres":
                self._json(genres(p("type", "movie")))

            elif path == "/discover":
                gid = p("genre") or None
                self._json(discover(p("type", "movie"), gid,
                                    int(p("page", "1")), p("sort", "popularity.desc")))

            # ── TMDB account lists (live read) ─────────────────────────────
            elif path == "/account/watchlist":
                _require_account()
                mt   = p("type", "movie")
                pg   = int(p("page", "1"))
                items, total = _fetch_tmdb_watchlist(mt, pg)
                self._json({"results": items, "totalPages": total, "page": pg})

            elif path == "/account/favorites":
                _require_account()
                mt   = p("type", "movie")
                pg   = int(p("page", "1"))
                items, total = _fetch_tmdb_favorites(mt, pg)
                self._json({"results": items, "totalPages": total, "page": pg})

            # ── Local DB mirrors (fast, offline-capable) ───────────────────
            elif path == "/local/watchlist":
                mt = p("type", "movie")
                self._json({"results": _db_list("watchlist", mt), "type": mt})

            elif path == "/local/favorites":
                mt = p("type", "movie")
                self._json({"results": _db_list("favorites", mt), "type": mt})

            elif path == "/local/in_watchlist":
                self._json({"result": _db_in_list("watchlist", p("id"), p("type", "movie"))})

            elif path == "/local/in_favorites":
                self._json({"result": _db_in_list("favorites", p("id"), p("type", "movie"))})

            # ── Sync triggers ──────────────────────────────────────────────
            elif path == "/local/sync":
                mt = p("type", "movie")
                threading.Thread(target=_sync_tmdb_watchlist_to_db,
                                 args=(mt,), daemon=True).start()
                threading.Thread(target=_sync_tmdb_favorites_to_db,
                                 args=(mt,), daemon=True).start()
                self._json({"ok": True, "message": "sync started"})

            # ── Userlist ───────────────────────────────────────────────────
            elif path == "/userlist/all":
                self._json(ul_get_all(p("type", "movie")))

            elif path == "/userlist/status":
                iid = p("id")
                if not iid:
                    return self._error("missing id", 400)
                self._json({"status": ul_get_status(iid, p("type", "movie"))})

            # ── Image proxy ────────────────────────────────────────────────
            elif path == "/image":
                img_path = unquote(p("path"))
                size     = p("size", "w342")
                if not img_path:
                    return self._error("missing path", 400)
                full_url = f"{IMG_URL}/{size}{img_path}"
                cached   = _img_get(full_url)
                if cached:
                    body, ct = cached
                else:
                    with _img_sem:
                        r = requests.get(full_url, timeout=15)
                        r.raise_for_status()
                        body = r.content
                        ct   = r.headers.get("Content-Type", "image/jpeg")
                    _img_put(full_url, body, ct)
                self.send_response(200)
                self.send_header("Content-Type", ct)
                self.send_header("Content-Length", str(len(body)))
                self.send_header("Cache-Control", "public, max-age=86400")
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(body)

            else:
                self._error("not found", 404)

        except ValueError as e:
            self._json({"error": str(e), "needsAccountId": True}, 400)
        except (BrokenPipeError, ConnectionResetError):
            pass
        except Exception as e:
            import traceback; traceback.print_exc()
            self._error(str(e))

    def do_POST(self):
        parsed = urlparse(self.path)
        try:
            body = self._body()
            path = parsed.path

            # ── TMDB account watchlist ─────────────────────────────────────
            if path == "/account/watchlist/add":
                mid = body.get("media_id")
                mt  = body.get("media_type", "movie")
                if not mid:
                    return self._error("missing media_id", 400)
                self._json(add_to_watchlist_tmdb(mid, mt))

            elif path == "/account/watchlist/remove":
                mid = body.get("media_id")
                mt  = body.get("media_type", "movie")
                if not mid:
                    return self._error("missing media_id", 400)
                self._json(remove_from_watchlist_tmdb(mid, mt))

            elif path == "/account/favorites/add":
                mid = body.get("media_id")
                mt  = body.get("media_type", "movie")
                if not mid:
                    return self._error("missing media_id", 400)
                self._json(add_to_favorites_tmdb(mid, mt))

            elif path == "/account/favorites/remove":
                mid = body.get("media_id")
                mt  = body.get("media_type", "movie")
                if not mid:
                    return self._error("missing media_id", 400)
                self._json(remove_from_favorites_tmdb(mid, mt))

            # ── Userlist ───────────────────────────────────────────────────
            elif path == "/userlist/add":
                iid    = body.get("id")
                mt     = body.get("type", "movie")
                status = body.get("status", "planning")
                item   = body.get("item", {})
                if not iid:
                    return self._error("missing id", 400)
                self._json(ul_add(iid, mt, status, item))

            elif path == "/userlist/update":
                iid    = body.get("id")
                mt     = body.get("type", "movie")
                status = body.get("status", "watching")
                if not iid:
                    return self._error("missing id", 400)
                self._json(ul_update(iid, mt, status))

            elif path == "/userlist/remove":
                iid = body.get("id")
                mt  = body.get("type", "movie")
                if not iid:
                    return self._error("missing id", 400)
                self._json(ul_remove(iid, mt))

            # ── Local DB direct add/remove (no TMDB call, no account needed) ──
            elif path == "/local/watchlist/add":
                item = body.get("item", {})
                mt   = body.get("media_type", item.get("type", "movie"))
                _db_add_to_list("watchlist", item, mt)
                self._json({"ok": True})

            elif path == "/local/watchlist/remove":
                _db_remove_from_list("watchlist",
                                     body.get("id"),
                                     body.get("media_type", "movie"))
                self._json({"ok": True})

            elif path == "/local/favorites/add":
                item = body.get("item", {})
                mt   = body.get("media_type", item.get("type", "movie"))
                _db_add_to_list("favorites", item, mt)
                self._json({"ok": True})

            elif path == "/local/favorites/remove":
                _db_remove_from_list("favorites",
                                     body.get("id"),
                                     body.get("media_type", "movie"))
                self._json({"ok": True})

            else:
                self._error("not found", 404)

        except ValueError as e:
            self._json({"error": str(e), "needsAccountId": True}, 400)
        except (BrokenPipeError, ConnectionResetError):
            pass
        except Exception as e:
            import traceback; traceback.print_exc()
            self._error(str(e))


if __name__ == "__main__":
    if not TOKEN:
        print("[movies] WARNING: No TMDB token found!")
        print("[movies]   → echo 'YOUR_TOKEN' > ~/.config/quickshell/tmdb_token")
    else:
        print(f"[movies] Token loaded ({len(TOKEN)} chars)")
    if not ACCOUNT_ID:
        print("[movies] INFO: No account ID — TMDB watchlist/favorites sync disabled")
    else:
        print(f"[movies] Account ID: {ACCOUNT_ID}")
        threading.Thread(target=_background_sync, daemon=True).start()

    print(f"[movies] Local DB: {DB_PATH}")
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"[movies] Listening on http://127.0.0.1:{PORT}")
    server.serve_forever()
