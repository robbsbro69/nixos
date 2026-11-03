#!/usr/bin/env python3
"""sysinfo.py — data for the Quickshell DISK and MEM panels (one JSON line on stdout).

  sysinfo.py drives          every real drive: mount, used, total
  sysinfo.py disk DIR        biggest folders directly inside DIR (du, same drive only)
  sysinfo.py mem             RAM / swap totals + programs grouped by name, biggest first
"""
import json, os, re, subprocess, sys


def out(o):
    print(json.dumps(o, ensure_ascii=False, separators=(",", ":")))
    sys.exit(0)


def drives():
    res, seen = [], set()
    try:
        txt = subprocess.run(["df", "-B1", "-P", "-x", "vfat", "-x", "tmpfs", "-x", "devtmpfs", "-x", "efivarfs"],
                             capture_output=True, text=True, timeout=10).stdout
    except Exception:
        txt = ""
    for ln in txt.splitlines()[1:]:
        p = ln.split(None, 5)
        if len(p) < 6 or not p[0].startswith("/dev/") or p[0] in seen:
            continue
        seen.add(p[0])
        mnt = p[5]
        res.append({"dev": p[0], "mount": mnt, "name": "/" if mnt == "/" else os.path.basename(mnt) or mnt,
                    "total": int(p[1]), "used": int(p[2]), "free": int(p[3]),
                    # where browsing starts: your home on the system drive, the mount point otherwise
                    "start": os.path.expanduser("~") if mnt == "/" else mnt})
    out({"ok": True, "drives": res})


def disk(d):
    d = os.path.abspath(os.path.expanduser(d))
    if not os.path.isdir(d):
        out({"ok": False, "why": "not a folder", "dir": d})
    try:
        r = subprocess.run(["du", "-x", "-B1", "-d1", "--", d], capture_output=True, text=True, timeout=240)
        txt = r.stdout
    except subprocess.TimeoutExpired:
        out({"ok": False, "why": "took too long", "dir": d})
    items, total = [], 0
    for ln in txt.splitlines():
        b, _, path = ln.partition("\t")
        if not b.isdigit():
            continue
        if os.path.normpath(path) == d:
            total = int(b)
            continue
        items.append({"name": os.path.basename(path), "path": path, "bytes": int(b), "dir": True})
    items.sort(key=lambda x: -x["bytes"])
    loose = total - sum(i["bytes"] for i in items)
    if loose > 0:
        items.append({"name": "(files here)", "path": d, "bytes": loose, "dir": False})
        items.sort(key=lambda x: -x["bytes"])
    parent = os.path.dirname(d) if d != "/" else ""
    out({"ok": True, "dir": d, "parent": parent, "total": total, "items": items[:10],
         "more": max(0, len(items) - 10)})


# never offer to kill these — the desktop would break or log you out
PROTECTED = {"systemd", "Hyprland", ".Hyprland-wrapp", "quickshell", ".quickshell-wra", "Xwayland", "dbus-daemon",
             "dbus-broker", "dbus-broker-lau", "pipewire", "wireplumber", "pipewire-pulse", "sddm", "login", "bash",
             "sshd", "NetworkManager", "polkitd", "systemd-journal", "systemd-logind", "kdeconnectd",
             "xdg-desktop-por", "xdg-desktop-portal", "xdg-document-p", "xdg-permission-"}


GENERIC = {"electron", "python", "python3", "node", "bash", "sh", "java", "perl", "ruby", "env", "bwrap", "steam-runtime"}


def clean(n):
    n = n.strip().lstrip(".")
    for suf in ("-wrapped", "-wrapp", "-wrap", "-wra", "-bin"):
        if n.endswith(suf):
            n = n[: -len(suf)]
    return n or "?"


def mem():
    info = {}
    try:
        for ln in open("/proc/meminfo"):
            k, v = ln.split(":", 1)
            info[k] = int(v.split()[0]) * 1024
    except Exception:
        pass
    me = os.getuid()
    apps = {}
    for pid in os.listdir("/proc"):
        if not pid.isdigit():
            continue
        try:
            st = os.stat(f"/proc/{pid}")
            with open(f"/proc/{pid}/comm") as f:
                comm = f.read().strip()
            with open(f"/proc/{pid}/status") as f:
                rss = 0
                for ln in f:
                    if ln.startswith("VmRSS:"):
                        rss = int(ln.split()[1]) * 1024
                        break
        except (OSError, ValueError, IndexError):
            continue
        if rss <= 0:
            continue
        # group an app's helper processes by its program file (Zen's "Isolated Web Co" tabs → zen)
        try:
            exe = os.path.basename(os.readlink(f"/proc/{pid}/exe"))
        except OSError:
            exe = ""
        e = clean(exe)
        generic = not exe or exe.startswith("memfd:") or e in GENERIC or re.match(r"python\d", e)
        name = clean(comm) if generic else e
        a = apps.setdefault(name, {"name": name, "bytes": 0, "pids": [], "mine": True, "safe": True})
        a["bytes"] += rss
        a["pids"].append(int(pid))
        if st.st_uid != me:
            a["mine"] = False
        if comm in PROTECTED or name in PROTECTED:
            a["safe"] = False
    lst = sorted(apps.values(), key=lambda a: -a["bytes"])[:15]
    for a in lst:
        a["count"] = len(a["pids"])
        a["killable"] = a["mine"] and a["safe"]
        a.pop("mine"); a.pop("safe")
    total, avail = info.get("MemTotal", 0), info.get("MemAvailable", 0)
    out({"ok": True, "total": total, "used": total - avail, "swapTotal": info.get("SwapTotal", 0),
         "swapUsed": info.get("SwapTotal", 0) - info.get("SwapFree", 0), "apps": lst})


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    if cmd == "drives":
        drives()
    elif cmd == "disk":
        disk(sys.argv[2] if len(sys.argv) > 2 else "~")
    elif cmd == "mem":
        mem()
    out({"ok": False, "why": "usage: sysinfo.py drives | disk DIR | mem"})
