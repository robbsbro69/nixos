#!/usr/bin/env python3
"""calendar-events.py — holidays + events for the Quickshell calendar panel.

  calendar-events.py list                 JSON of every event in a ~15-month window (cached, refreshes stale sources)
  calendar-events.py refresh              same, but re-download everything now
  calendar-events.py add DATE TITLE [yearly] [HH:MM]   add your own event (DATE = YYYY-MM-DD)
  calendar-events.py del ID               delete one of your own events

Sources (each can be switched off in ~/.config/quickshell/state/calendar-sources,
one name per line or space separated; default = all):
  nepal   Nepal public holidays + festivals (Google's public "Holidays in Nepal" calendar)
  india   Indian festivals (Google's public "Holidays in India" calendar)
  intl    International days (computed locally: New Year, Valentine's, Mother's Day, Easter, Christmas…)
  ics     Your own calendar links, one per line in ~/.config/quickshell/state/calendar-ics
          ("Name|https://…ics" or just the URL; webcal:// works)
  mine    Events you add from the calendar panel (~/.config/quickshell/state/calendar-events.json)
  …       extra sources: any plugin file in ~/.local/share/quickshell/calendar-plugins/ or
          ~/nixos-private/calendar/ (NAME = "x", TTL = seconds, def fetch(h) -> [(YYYY-MM-DD, h.ev(...))])

Output: {"ok": true, "events": {"YYYY-MM-DD": [{"t": title, "k": kind, "src": source, "time": "HH:MM", "id": …}]},
         "sources": {name: {"ok": bool, "n": count, "err": "…"}}}
kind ∈ holiday (public holiday) | festival | india | intl | task | reminder | release | ics | mine
"""
import datetime as dt
import json
import os
import re
import sys
import threading
import time
import urllib.parse
import urllib.request

HOME = os.path.expanduser("~")
STATE = os.path.join(HOME, ".config/quickshell/state")
CACHE = os.path.join(HOME, ".cache/quickshell/calendar")
MINE = os.path.join(STATE, "calendar-events.json")
ICS_LIST = os.path.join(STATE, "calendar-ics")
SOURCES_FILE = os.path.join(STATE, "calendar-sources")
PLUGIN_DIRS = [os.path.join(HOME, ".local/share/quickshell/calendar-plugins"), os.path.join(HOME, "nixos-private/calendar")]

GOOGLE = "https://calendar.google.com/calendar/ical/{}/public/basic.ics"
GOOGLE_IDS = {"nepal": "en.np#holiday@group.v.calendar.google.com",
              "india": "en.indian#holiday@group.v.calendar.google.com"}
ALL_SOURCES = ["nepal", "india", "intl", "ics", "mine"]
TTL = {"nepal": 86400, "india": 86400, "ics": 3600}
RETRY = 1800  # after a failed download, try again after this long (old data is kept meanwhile)
ORDER = {"holiday": 0, "festival": 1, "india": 2, "intl": 3, "mine": 4, "task": 5, "reminder": 6, "release": 7, "ics": 8}

TODAY = dt.date.today()
START = TODAY - dt.timedelta(days=120)
END = TODAY + dt.timedelta(days=430)
LOCAL_TZ = dt.datetime.now().astimezone().tzinfo


def ev(title, kind, src, time_="", **extra):
    e = {"t": title.strip(), "k": kind, "src": src, "time": time_}
    e.update(extra)
    return e


def in_window(d):
    return START <= d <= END


def http_get(url, headers=None, timeout=12):
    req = urllib.request.Request(url, headers={"User-Agent": "quickshell-calendar/1.0", **(headers or {})})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read().decode("utf-8", "replace")


# ── ICS ──────────────────────────────────────────────────────────────────────
def ics_unescape(s):
    return re.sub(r"\\([\\,;nN])", lambda m: "\n" if m.group(1) in "nN" else m.group(1), s)


def ics_events(text):
    """yield dicts of raw properties for each VEVENT (unfolded, params kept)"""
    lines = re.split(r"\r?\n", text)
    unfolded = []
    for ln in lines:
        if ln[:1] in (" ", "\t") and unfolded:
            unfolded[-1] += ln[1:]
        else:
            unfolded.append(ln)
    cur = None
    for ln in unfolded:
        if ln == "BEGIN:VEVENT":
            cur = {}
        elif ln == "END:VEVENT":
            if cur is not None:
                yield cur
            cur = None
        elif cur is not None and ":" in ln:
            head, val = ln.split(":", 1)
            name, *params = head.split(";")
            p = dict(x.split("=", 1) for x in params if "=" in x)
            cur.setdefault(name.upper(), []).append((p, val))


def ics_time(p, val):
    """→ (date, 'HH:MM' or '') in local time"""
    val = val.strip()
    if p.get("VALUE") == "DATE" or re.fullmatch(r"\d{8}", val):
        return dt.datetime.strptime(val[:8], "%Y%m%d").date(), ""
    m = re.fullmatch(r"(\d{8})T(\d{4})(\d{2})?(Z)?", val)
    if not m:
        raise ValueError("bad time " + val)
    t = dt.datetime.strptime(m.group(1) + m.group(2), "%Y%m%d%H%M")
    if m.group(4):
        t = t.replace(tzinfo=dt.timezone.utc).astimezone(LOCAL_TZ)
    elif p.get("TZID"):
        try:
            from zoneinfo import ZoneInfo
            t = t.replace(tzinfo=ZoneInfo(p["TZID"].strip('"'))).astimezone(LOCAL_TZ)
        except Exception:
            pass  # unknown zone: treat as local
    return t.date(), t.strftime("%H:%M")


WD = {"MO": 0, "TU": 1, "WE": 2, "TH": 3, "FR": 4, "SA": 5, "SU": 6}


def add_months(d, n):
    y, m = divmod(d.month - 1 + n, 12)
    y += d.year
    m += 1
    import calendar
    last = calendar.monthrange(y, m)[1]
    return d.replace(year=y, month=m, day=d.day) if d.day <= last else None


def expand(start, rrule, exdates):
    """dates of a recurring event (DAILY/WEEKLY/MONTHLY/YEARLY, INTERVAL, COUNT, UNTIL, BYDAY for weekly)"""
    r = dict(x.split("=", 1) for x in rrule.split(";") if "=" in x)
    freq = r.get("FREQ", "")
    step = max(1, int(r.get("INTERVAL", "1") or 1))
    count = int(r["COUNT"]) if r.get("COUNT", "").isdigit() else None
    until = None
    if r.get("UNTIL"):
        try:
            until = dt.datetime.strptime(r["UNTIL"][:8], "%Y%m%d").date()
        except ValueError:
            pass
    stop = min(END, until) if until else END
    out, n = [], 0

    def take(d):
        nonlocal n
        if count is not None and n >= count:
            return False
        n += 1
        if d not in exdates and in_window(d):
            out.append(d)
        return True

    if freq == "WEEKLY":
        days = sorted(WD[x[-2:]] for x in r.get("BYDAY", "").split(",") if x[-2:] in WD) or [start.weekday()]
        week0 = start - dt.timedelta(days=start.weekday())
        w = 0
        while True:
            base = week0 + dt.timedelta(weeks=w)
            if base > stop:
                break
            for wd in days:
                d = base + dt.timedelta(days=wd)
                if d < start or d > stop:
                    continue
                if not take(d):
                    return out
            w += step
            if w > 5000:
                break
    elif freq in ("DAILY", "MONTHLY", "YEARLY"):
        i = 0
        while i < 20000:
            if freq == "DAILY":
                d = start + dt.timedelta(days=i * step)
            elif freq == "MONTHLY":
                d = add_months(start, i * step)
            else:
                try:
                    d = start.replace(year=start.year + i * step)
                except ValueError:
                    d = None  # Feb 29 in a non-leap year
            i += 1
            if d is None:
                continue
            if d > stop:
                break
            if not take(d):
                break
    else:
        if in_window(start):
            out.append(start)
    return out


def parse_ics(text, kind_fn, src):
    events = []
    for e in ics_events(text):
        try:
            if e.get("STATUS", [({}, "")])[0][1].strip().upper() == "CANCELLED":
                continue
            title = ics_unescape(e.get("SUMMARY", [({}, "(no title)")])[0][1])
            p, v = e["DTSTART"][0]
            d0, t0 = ics_time(p, v)
            kind = kind_fn(e)
            days_long = 1
            if "DTEND" in e and t0 == "":
                d1, _ = ics_time(*e["DTEND"][0])
                days_long = max(1, min(30, (d1 - d0).days))
            ex = set()
            for ep, ev_ in e.get("EXDATE", []):
                for one in ev_.split(","):
                    try:
                        ex.add(ics_time(ep, one)[0])
                    except ValueError:
                        pass
            starts = expand(d0, e["RRULE"][0][1], ex) if "RRULE" in e and "RECURRENCE-ID" not in e else [d0]
            for s in starts:
                for k in range(days_long):
                    d = s + dt.timedelta(days=k)
                    if in_window(d):
                        events.append((d.isoformat(), ev(title, kind, src, t0)))
        except (KeyError, ValueError, IndexError):
            continue
    return events


# ── sources ──────────────────────────────────────────────────────────────────
def google_kind(name):
    def f(e):
        desc = " ".join(v for _, v in e.get("DESCRIPTION", [])).lower()
        if name == "india":
            return "india"
        return "holiday" if "public holiday" in desc else "festival"
    return f


def src_google(name):
    url = GOOGLE.format(urllib.parse.quote(GOOGLE_IDS[name], safe=""))
    return parse_ics(http_get(url), google_kind(name), name)


def nth_weekday(y, m, wd, n):
    d = dt.date(y, m, 1)
    d += dt.timedelta(days=(wd - d.weekday()) % 7)
    return d + dt.timedelta(weeks=n - 1)


def easter(y):
    a, b, c = y % 19, y // 100, y % 100
    d, e = b // 4, b % 4
    f = (b + 8) // 25
    g = (b - f + 1) // 3
    h = (19 * a + b - d - g + 15) % 30
    i, k = c // 4, c % 4
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * l) // 451
    month = (h + l - 7 * m + 114) // 31
    day = ((h + l - 7 * m + 114) % 31) + 1
    return dt.date(y, month, day)


FIXED_INTL = [
    (1, 1, "New Year's Day"), (2, 4, "World Cancer Day"), (2, 14, "Valentine's Day"),
    (3, 8, "International Women's Day"), (3, 14, "Pi Day"), (3, 20, "International Day of Happiness"),
    (4, 1, "April Fools' Day"), (4, 7, "World Health Day"), (4, 22, "Earth Day"),
    (5, 1, "International Labour Day"), (6, 5, "World Environment Day"), (6, 21, "International Yoga Day"),
    (8, 12, "International Youth Day"), (9, 21, "International Day of Peace"),
    (10, 10, "World Mental Health Day"), (10, 31, "Halloween"), (11, 19, "International Men's Day"),
    (12, 24, "Christmas Eve"), (12, 25, "Christmas Day"), (12, 31, "New Year's Eve"),
]


def src_intl():
    out = []
    for y in range(START.year, END.year + 1):
        days = [(dt.date(y, m, d), t) for m, d, t in FIXED_INTL]
        days += [(nth_weekday(y, 5, 6, 2), "Mother's Day"), (nth_weekday(y, 6, 6, 3), "Father's Day"),
                 (nth_weekday(y, 8, 6, 1), "Friendship Day"),
                 (easter(y), "Easter Sunday"), (easter(y) - dt.timedelta(days=2), "Good Friday")]
        out += [(d.isoformat(), ev(t, "intl", "intl")) for d, t in days if in_window(d)]
    return out


def read_env(path):
    env = {}
    try:
        with open(path, encoding="utf-8") as f:
            for ln in f:
                ln = ln.strip()
                if ln and not ln.startswith("#") and "=" in ln:
                    k, v = ln.split("=", 1)
                    env[k.strip().removeprefix("export ").strip()] = v.strip().strip('"').strip("'")
    except FileNotFoundError:
        pass
    return env


ISO_RE = re.compile(r"^(\d{4}-\d{2}-\d{2})(?:[T ](\d{2}:\d{2}))?")
def iso_local(s):
    """'2026-10-27T18:00:00+05:45' / '...Z' / '2026-10-27' → (date, 'HH:MM')"""
    m = ISO_RE.match(s or "")
    if not m:
        return None, ""
    if m.group(2):
        try:
            t = dt.datetime.fromisoformat(s.replace("Z", "+00:00"))
            if t.tzinfo:
                t = t.astimezone(LOCAL_TZ)
            return t.date(), t.strftime("%H:%M")
        except ValueError:
            pass
    return dt.date.fromisoformat(m.group(1)), (m.group(2) or "")


def src_ics():
    out, errs = [], []
    try:
        with open(ICS_LIST, encoding="utf-8") as f:
            lines = [ln.strip() for ln in f if ln.strip() and not ln.strip().startswith("#")]
    except FileNotFoundError:
        return []
    for ln in lines:
        name, url = (ln.split("|", 1) if "|" in ln else ("", ln))
        url = re.sub(r"^webcal://", "https://", url.strip(), flags=re.I)
        try:
            evs = parse_ics(http_get(url), lambda e: "ics", "ics")
            for _, e in evs:
                if name.strip():
                    e["note"] = name.strip()
            out += evs
        except Exception as e:  # keep the other links working
            errs.append(f"{name or url[:40]}: {e}")
    if errs and not out:
        raise RuntimeError("; ".join(errs))
    return out


def load_mine():
    try:
        with open(MINE, encoding="utf-8") as f:
            data = json.load(f)
        return data if isinstance(data, list) else []
    except (FileNotFoundError, ValueError):
        return []


def save_mine(items):
    os.makedirs(STATE, exist_ok=True)
    tmp = MINE + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(items, f, ensure_ascii=False, indent=1)
    os.replace(tmp, MINE)


def src_mine():
    out = []
    for it in load_mine():
        try:
            d0 = dt.date.fromisoformat(it["date"])
        except (KeyError, ValueError):
            continue
        dates = [d0]
        if it.get("yearly"):
            dates = []
            for y in range(START.year, END.year + 1):
                try:
                    dates.append(d0.replace(year=y))
                except ValueError:
                    dates.append(dt.date(y, 2, 28))
        for d in dates:
            if in_window(d):
                out.append((d.isoformat(), ev(it.get("title", ""), "mine", "mine", it.get("time", ""),
                                              id=it.get("id", ""), yearly=bool(it.get("yearly")))))
    return out


FETCHERS = {"nepal": lambda: src_google("nepal"), "india": lambda: src_google("india"), "ics": src_ics}


def load_plugins():
    """optional extra sources (kept outside the repo); a broken plugin is skipped, never fatal"""
    import importlib.util, types
    helpers = types.SimpleNamespace(ev=ev, http_get=http_get, in_window=in_window, iso_local=iso_local,
                                    read_env=read_env, TODAY=TODAY, START=START, END=END, dt=dt, json=json, re=re)
    for d in PLUGIN_DIRS:
        try:
            files = sorted(f for f in os.listdir(d) if f.endswith(".py") and not f.startswith("_"))
        except OSError:
            continue
        for f in files:
            try:
                spec = importlib.util.spec_from_file_location("calplugin_" + f[:-3], os.path.join(d, f))
                mod = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(mod)
                name = getattr(mod, "NAME", f[:-3])
                if name in FETCHERS or name in ("intl", "mine"):
                    continue
                FETCHERS[name] = (lambda m: lambda: m.fetch(helpers))(mod)
                TTL[name] = int(getattr(mod, "TTL", 900))
                ALL_SOURCES.append(name)
            except Exception as e:
                print(f"calendar plugin {f}: {e}", file=sys.stderr)


load_plugins()
LOCAL = {"intl": src_intl, "mine": src_mine}


# ── cache + main ─────────────────────────────────────────────────────────────
def cache_path(name):
    return os.path.join(CACHE, name + ".json")


def read_cache(name):
    try:
        with open(cache_path(name), encoding="utf-8") as f:
            return json.load(f)
    except (FileNotFoundError, ValueError):
        return None


def write_cache(name, data):
    os.makedirs(CACHE, exist_ok=True)
    tmp = cache_path(name) + f".{os.getpid()}.tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False)
    os.replace(tmp, cache_path(name))


def enabled_sources():
    try:
        with open(SOURCES_FILE, encoding="utf-8") as f:
            words = re.findall(r"[a-z]+", f.read().lower())
        chosen = [w for w in words if w in ALL_SOURCES]
        return chosen or ALL_SOURCES
    except FileNotFoundError:
        return ALL_SOURCES


def fetch(name, force):
    c = read_cache(name)
    now = time.time()
    if c and not force:
        age = now - c.get("at", 0)
        fresh = age < TTL[name] if c.get("ok") else age < RETRY
        if fresh:
            return c
    try:
        evs = FETCHERS[name]()
        c = {"at": now, "ok": True, "events": evs, "err": ""}
    except Exception as e:  # keep the last good events, remember the failure
        old = c.get("events", []) if c else []
        c = {"at": now, "ok": False, "events": old, "err": str(e)[:200]}
    write_cache(name, c)
    return c


def build(force=False):
    names = enabled_sources()
    results = {}

    def run(n):
        results[n] = fetch(n, force)

    threads = [threading.Thread(target=run, args=(n,)) for n in names if n in FETCHERS]
    for t in threads:
        t.start()
    for n in names:
        if n in LOCAL:
            try:
                results[n] = {"ok": True, "events": LOCAL[n](), "err": ""}
            except Exception as e:
                results[n] = {"ok": False, "events": [], "err": str(e)[:200]}
    for t in threads:
        t.join(timeout=20)

    days, sources = {}, {}
    for n in names:
        r = results.get(n) or {"ok": False, "events": [], "err": "timed out"}
        sources[n] = {"ok": bool(r.get("ok")), "n": len(r.get("events", [])), "err": r.get("err", "")}
        for d, e in r.get("events", []):
            days.setdefault(d, []).append(e)
    for d, lst in days.items():
        seen, uniq = set(), []
        for e in sorted(lst, key=lambda e: (0 if ORDER.get(e["k"], 9) <= 3 else 1, e.get("time") or "", ORDER.get(e["k"], 9))):
            key = re.sub(r"[^a-z0-9]", "", e["t"].lower())
            if key in seen:
                continue
            seen.add(key)
            uniq.append(e)
        days[d] = uniq
    return {"ok": True, "today": TODAY.isoformat(), "events": days, "sources": sources}


def main(argv):
    cmd = argv[1] if len(argv) > 1 else "list"
    if cmd in ("list", "refresh"):
        print(json.dumps(build(force=cmd == "refresh"), ensure_ascii=False, separators=(",", ":")))
    elif cmd == "add":
        if len(argv) < 4:
            sys.exit("usage: add YYYY-MM-DD TITLE [yearly] [HH:MM]")
        d = dt.date.fromisoformat(argv[2]).isoformat()
        title = argv[3].strip()[:120]
        if not title:
            sys.exit("empty title")
        yearly = len(argv) > 4 and argv[4] in ("1", "yearly", "true")
        tm = argv[5] if len(argv) > 5 and re.fullmatch(r"\d{2}:\d{2}", argv[5]) else ""
        items = load_mine()
        eid = "e%d" % int(time.time() * 1000)
        items.append({"id": eid, "date": d, "title": title, "yearly": yearly, "time": tm})
        save_mine(items)
        print(json.dumps({"ok": True, "id": eid}))
    elif cmd == "del":
        items = load_mine()
        keep = [i for i in items if i.get("id") != (argv[2] if len(argv) > 2 else "")]
        save_mine(keep)
        print(json.dumps({"ok": len(keep) != len(items)}))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv)
