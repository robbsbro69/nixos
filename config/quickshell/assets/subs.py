#!/usr/bin/env python3
"""subs.py KEY TITLE CHANNEL DURATION_S MEDIA_URL
YouTube subtitles for whatever the browser is playing, for the bar ticker.
  1. uses the YouTube video ID from the actual MPRIS media URL
  2. reads its caption tracks and downloads one (English → Hindi → Nepali, real before auto)
Anonymous by default; opt in with ~/.config/quickshell/subs-cookie-profile.
The file must contain an explicit Zen/Firefox profile directory.
Prints one JSON line like lyrics.py: {"key","ok","lines":[[sec,"text"],...],"lang"} or {"key","ok":false,"why"}
Cached in ~/.cache/quickshell/subs/.
"""
import urllib.parse
import difflib, glob, hashlib, json, os, re, shutil, subprocess, sys, time, urllib.request

key = sys.argv[1] if len(sys.argv) > 1 else ""
title = sys.argv[2] if len(sys.argv) > 2 else ""
channel = sys.argv[3] if len(sys.argv) > 3 else ""
try:
    duration = float(sys.argv[4]) if len(sys.argv) > 4 else 0
except ValueError:
    duration = 0
media_url = sys.argv[5] if len(sys.argv) > 5 else ""
CACHE = os.path.expanduser("~/.cache/quickshell/subs")
LANGS = ["en", "en-US", "en-GB", "en-IN", "hi", "ne"]
DEBUG = os.environ.get("SUBS_DEBUG") == "1"
# which subtitles: "orig" = the video's own language (default), or a code like "en" / "hi"
try:
    with open(os.path.expanduser("~/.config/quickshell/subs-lang")) as _f:
        PREF = _f.read().strip() or "orig"
except Exception:
    PREF = "orig"


def dbg(*a):
    if DEBUG:
        print("[subs]", *a, file=sys.stderr)


def tidy(lines):
    """auto-captions come as rolling word fragments ("You did" / "n't leave me") —
    join them into readable chunks for the ticker"""
    res = []
    for t, txt in lines:
        txt = re.sub(r"\[(music|Music|MUSIC|संगीत)\]", "♪", txt)
        txt = re.sub(r"\s{2,}", " ", txt).strip()
        if not txt:
            continue
        cont = bool(re.match(r"^('|n't\b|[.,!?;:])", txt))      # rest of a split word
        if res and (cont or (t - res[-1][2] < 4.0 and len(res[-1][1]) + len(txt) < 80)):
            glue = "" if cont else " "
            res[-1][1] = (res[-1][1] + glue + txt).strip()
            res[-1][2] = t
        else:
            res.append([t, txt, t])
    out_l = []
    for t, txt, _ in res:
        txt = re.sub(r"(♪\s*){2,}", "♪ ", txt).strip()
        if out_l and txt == "♪" and out_l[-1][1] == "♪":
            continue
        out_l.append([t, txt])
    return out_l


def out(o):
    o["key"] = key
    if o.get("ok") and o.get("kind") == "auto":
        o = dict(o, lines=tidy(o["lines"]))
    print(json.dumps(o, ensure_ascii=False))
    sys.exit(0)


def youtube_id(value):
    try:
        parsed = urllib.parse.urlparse(value)
        if parsed.scheme not in ("https", "http"):
            return None
        host = (parsed.hostname or "").lower()
        parts = parsed.path.strip("/").split("/")
        if host in ("youtu.be", "www.youtu.be"):
            candidate = parts[0] if len(parts) == 1 else ""
        elif host in ("youtube.com", "www.youtube.com", "m.youtube.com", "music.youtube.com"):
            if parsed.path == "/watch":
                candidate = urllib.parse.parse_qs(parsed.query).get("v", [""])[0]
            elif len(parts) == 2 and parts[0] in ("shorts", "embed", "live"):
                candidate = parts[1]
            else:
                candidate = ""
        else:
            return None
        return candidate if re.fullmatch(r"[A-Za-z0-9_-]{11}", candidate) else None
    except ValueError:
        return None


vid = youtube_id(media_url)
if not vid:
    out({"ok": False, "why": "no supported YouTube media URL"})
if not shutil.which("yt-dlp"):
    out({"ok": False, "why": "yt-dlp not installed"})

CACHE = os.path.join(CACHE, "by-video", vid)
os.makedirs(CACHE, exist_ok=True)
def cookie_setting():
    try:
        with open(os.path.expanduser("~/.config/quickshell/subs-cookie-profile"), encoding="utf-8") as f:
            return f.read().strip()
    except FileNotFoundError:
        return ""


COOKIE_PROFILE = cookie_setting()
cf = os.path.join(CACHE, hashlib.sha1(f"v4|{PREF}|{title}|{channel}".encode()).hexdigest() + ".json")
# Keep authenticated and anonymous results separate, including negative cache entries.
cf = os.path.join(CACHE, hashlib.sha1((COOKIE_PROFILE + "|" + cf).encode()).hexdigest() + ".json")
try:
    with open(cf, encoding="utf-8") as f:
        c = json.load(f)
    if not DEBUG and (c.get("ok") or time.time() - c.get("at", 0) < 6 * 3600):
        out(c)
except Exception:
    pass


def cookie_args():
    profile = COOKIE_PROFILE
    if not profile:
        return []
    profile = os.path.expanduser(profile)
    if not os.path.isabs(profile) or not os.path.isfile(os.path.join(profile, "cookies.sqlite")):
        raise ValueError("subs-cookie-profile must name an existing absolute browser profile directory")
    return ["--cookies-from-browser", "firefox:" + profile]


def base_args():
    # Only the explicitly selected profile is made available to yt-dlp.
    return ["yt-dlp", "--no-warnings"] + cookie_args()


_JS = None


def js_args():
    global _JS
    if _JS is not None:
        return _JS
    _JS = []
    try:
        h = subprocess.run(["yt-dlp", "--help"], capture_output=True, text=True, timeout=15).stdout
        if "--js-runtimes" in h and shutil.which("node"):
            _JS = ["--js-runtimes", "node"]
    except Exception:
        pass
    return _JS


def run(args, timeout=60):
    dbg("run:", " ".join(a if " " not in a else repr(a) for a in args))
    p = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    if p.returncode != 0:
        err = (p.stderr or "").strip().splitlines()
        raise RuntimeError(err[-1][:90] if err else f"yt-dlp exit {p.returncode}")
    return p.stdout


def save(res):
    res["at"] = time.time()
    with open(cf, "w", encoding="utf-8") as f:
        json.dump(res, f, ensure_ascii=False)
    out(res)


try:
    BA = base_args()
    # Never guess a video from its title.
    # ── 2. its caption tracks ──
    url = "https://www.youtube.com/watch?v=" + vid
    # YouTube hides captions from the default "web" client unless it has a PO token;
    # the tv / web_embedded / android_vr clients don't need one (yt-dlp PO Token Guide)
    manual, auto, CL, vlang = {}, {}, [], ""
    for client in (None, "tv", "web_embedded", "android_vr"):
        CL = ["--extractor-args", "youtube:player_client=" + client] if client else []
        try:
            info = json.loads(run(BA + js_args() + CL + ["-J", "--skip-download", url], timeout=90))
        except Exception as e:
            dbg("client", client or "default", "failed:", e)
            continue
        manual = info.get("subtitles") or {}
        auto = info.get("automatic_captions") or {}
        dbg("client", client or "default", "→", len(manual), "subs,", len(auto), "auto")
        if manual or auto:
            vlang = (info.get("language") or "").split("-")[0]
            break

    manual.pop("live_chat", None)
    dbg("manual:", list(manual)[:20])
    dbg("auto:", len(auto), "tracks, orig:", [k for k in auto if k.endswith("-orig")])

    def choose():
        orig = [k for k in auto if k.endswith("-orig")]
        # the video's spoken language goes first among the "-orig" tracks
        if vlang and vlang + "-orig" in orig:
            orig.remove(vlang + "-orig"); orig.insert(0, vlang + "-orig")
        dbg("video language:", vlang or "?")
        # auto captions in the language you want, made from the audio itself, beat a translation
        if PREF != "orig" and PREF + "-orig" in auto and not (PREF in manual):
            return auto[PREF + "-orig"], PREF + "-orig", "auto"
        want = ([PREF] if PREF != "orig" else []) + LANGS
        if PREF == "orig":
            # real subtitles in any language first, then the video's own auto captions
            for lg in LANGS:
                if lg in manual:
                    return manual[lg], lg, "subs"
            for lg in manual:
                return manual[lg], lg, "subs"
            if orig:
                return auto[orig[0]], orig[0], "auto"
        for lg in want:
            if lg in manual:
                return manual[lg], lg, "subs"
        for lg in want:
            if lg in auto:
                return auto[lg], lg, "auto"
        if orig:
            return auto[orig[0]], orig[0], "auto"
        for lg in manual:
            return manual[lg], lg, "subs"
        return None, None, None

    fmts, lang, kind = choose()
    dbg("chose", lang, kind)
    if not fmts:
        # -J sometimes comes back without caption tracks even though the video has them;
        # ask yt-dlp to just download the captions directly (the way --list-subs sees them)
        tmp = os.path.join(CACHE, "dl")
        shutil.rmtree(tmp, ignore_errors=True)
        os.makedirs(tmp)
        langs = ([PREF] if PREF != "orig" else []) + [".*-orig", "en", "hi", "ne"]
        try:
            run(BA + js_args() + CL + ["--skip-download", "--write-subs", "--write-auto-subs",
                      "--sub-langs", ",".join(dict.fromkeys(langs)), "--sub-format", "json3",
                      "-o", os.path.join(tmp, "s.%(ext)s"), url], timeout=120)
        except Exception as e:
            dbg("direct caption download failed:", e)
        got = sorted(glob.glob(os.path.join(tmp, "*.json3")))
        dbg("downloaded:", [os.path.basename(g) for g in got])
        if not got:
            save({"ok": False, "why": "no captions on this video"})
        def rank(path):
            lg = os.path.basename(path)[2:-6]           # s.<lang>.json3
            for i, w in enumerate(langs):
                if re.fullmatch(w, lg):
                    return i
            return 99
        got.sort(key=rank)
        with open(got[0], encoding="utf-8") as f:
            data0 = json.load(f)
        lang, kind, fmts = os.path.basename(got[0])[2:-6], "auto", [{"ext": "json3", "_data": data0}]
    j3 = next((f for f in fmts if f.get("ext") == "json3"), None)

    # ── 3. download + parse ──
    # translated tracks (e.g. Hindi → English) get rate-limited much more than the
    # original-language track, so if the wanted one fails, fall back to the original
    data = j3.get("_data") if j3 else None
    tries = [(lang, kind)]
    orig = [k for k in auto if k.endswith("-orig")]
    if vlang and vlang + "-orig" in orig:
        orig.remove(vlang + "-orig"); orig.insert(0, vlang + "-orig")
    if kind == "auto" and orig and orig[0] != lang:
        tries.append((orig[0], "auto"))
    tmp = os.path.join(CACHE, "dl")
    for lg, kd in tries:
        if data is not None:
            break
        shutil.rmtree(tmp, ignore_errors=True)
        os.makedirs(tmp)
        try:
            run(BA + js_args() + CL + ["--skip-download", "--write-auto-subs" if kd == "auto" else "--write-subs",
                      "--sub-langs", lg, "--sub-format", "json3", "--retries", "3",
                      "--retry-sleep", "http:exp=1:8", "--sleep-subtitles", "1",
                      "-o", os.path.join(tmp, "s.%(ext)s"), url], timeout=120)
        except Exception as e:
            dbg("download", lg, "failed:", e)
        got = glob.glob(os.path.join(tmp, "*.json3"))
        dbg("download", lg, "→", [os.path.basename(g) for g in got])
        if got:
            with open(got[0], encoding="utf-8") as f:
                data = json.load(f)
            lang, kind = lg, kd
    if data is None:
        msg = "caption download failed"
        out({"ok": False, "why": "network: " + msg})      # not cached → the bar retries later
    lines = []
    for ev in data.get("events", []):
        segs = ev.get("segs")
        if not segs:
            continue
        text = "".join(s.get("utf8", "") for s in segs).replace("\n", " ").strip()
        text = re.sub(r"\s{2,}", " ", text)
        if not text:
            continue
        t = round(ev.get("tStartMs", 0) / 1000, 2)
        if lines and abs(lines[-1][0] - t) < 0.05:
            lines[-1][1] += " " + text
        else:
            lines.append([t, text])
    if not lines:
        save({"ok": False, "why": "captions were empty"})
    save({"ok": True, "lines": lines, "lang": lang, "kind": kind, "id": vid})
except subprocess.TimeoutExpired:
    out({"ok": False, "why": "network: yt-dlp timed out"})
except Exception as e:
    msg = str(e)
    if "429" in msg or "Too Many" in msg:
        out({"ok": False, "why": "network: YouTube rate limit (429)"})
    out({"ok": False, "why": "network: " + msg[:90]})
