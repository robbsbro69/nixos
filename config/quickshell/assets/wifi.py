#!/usr/bin/env python3
"""wifi.py — NetworkManager helper for the Quickshell Wi-Fi panel. Prints one JSON line.

  wifi.py status [rescan]                 radio, current connection (+ IP/DNS/band…), networks in range, saved networks
  wifi.py connect SSID [PASSWORD]         join a network (saved ones reconnect without a password)
  wifi.py hidden SSID [PASSWORD]          join a hidden network
  wifi.py up UUID                         reconnect a saved network
  wifi.py disconnect                      drop the current Wi-Fi connection
  wifi.py forget UUID                     delete a saved network
  wifi.py details UUID                    editable settings of a saved network
  wifi.py edit UUID JSON                  apply settings: {"autoconnect":bool,"metered":bool,"dns":"auto"|"1.1.1.1 8.8.8.8",
                                          "ip":"auto"|"192.168.1.50/24","gateway":"192.168.1.1"}
  wifi.py share UUID                      saved password (+ a QR code PNG if qrencode is installed)
  wifi.py radio on|off

Everything is passed to nmcli as separate arguments — names and passwords never go through a shell.
"""
import json, os, re, shutil, subprocess, sys

RUN = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"


def out(o):
    print(json.dumps(o, ensure_ascii=False, separators=(",", ":")))
    sys.exit(0)


def nm(*args, timeout=20):
    try:
        r = subprocess.run(["nmcli", *args], capture_output=True, text=True, timeout=timeout)
        return r.returncode, r.stdout, r.stderr.strip()
    except FileNotFoundError:
        out({"ok": False, "msg": "nmcli not found"})
    except subprocess.TimeoutExpired:
        return 124, "", "timed out"


def split_t(line):
    """split one `nmcli -t` line: fields by ':', with '\\:' and '\\\\' escaped"""
    f, cur, i = [], [], 0
    while i < len(line):
        c = line[i]
        if c == "\\" and i + 1 < len(line):
            cur.append(line[i + 1]); i += 2; continue
        if c == ":":
            f.append("".join(cur)); cur = []
        else:
            cur.append(c)
        i += 1
    f.append("".join(cur))
    return f


def rows(text):
    return [split_t(l) for l in text.splitlines() if l.strip()]


def wifi_dev():
    _, o, _ = nm("-t", "-f", "DEVICE,TYPE,STATE", "device")
    for d, t, st in (r[:3] for r in rows(o) if len(r) >= 3):
        if t == "wifi":
            return d, st
    return "", ""


def band(freq):
    try:
        mhz = int(re.sub(r"\D", "", freq) or 0)
    except ValueError:
        return ""
    return "6 GHz" if mhz >= 5925 else "5 GHz" if mhz >= 4900 else "2.4 GHz" if mhz else ""


def saved():
    _, o, _ = nm("-t", "-f", "NAME,UUID,TYPE,AUTOCONNECT,ACTIVE", "connection", "show")
    res = []
    for r in rows(o):
        if len(r) >= 5 and r[2] in ("802-11-wireless", "wifi"):
            _, s, _ = nm("-g", "802-11-wireless.ssid", "connection", "show", "uuid", r[1])
            s = re.sub(r"\\(.)", r"\1", s.strip())
            res.append({"name": r[0], "uuid": r[1], "ssid": s or r[0],
                        "autoconnect": r[3] == "yes", "active": r[4] == "yes"})
    return res


def status(rescan=False):
    _, radio, _ = nm("radio", "wifi")
    radio_on = radio.strip() == "enabled"
    dev, devstate = wifi_dev()
    sv = saved()
    by_ssid = {s["ssid"]: s for s in sv}
    nets, active = {}, None
    if radio_on and dev:
        _, o, _ = nm("-t", "-f", "IN-USE,SSID,BSSID,SIGNAL,FREQ,RATE,SECURITY,CHAN", "device", "wifi", "list",
                     "--rescan", "yes" if rescan else "auto", timeout=30)
        for r in rows(o):
            if len(r) < 8 or not r[1]:
                continue
            inuse, ssid, bssid, sig, freq, rate, sec, chan = r[:8]
            sig = int(sig) if sig.isdigit() else 0
            n = nets.get(ssid)
            if n and n["signal"] >= sig and inuse != "*":
                continue
            nets[ssid] = {"ssid": ssid, "signal": sig, "security": sec.strip() if sec.strip() not in ("", "--") else "",
                          "band": band(freq), "freq": freq, "rate": rate, "chan": chan, "bssid": bssid,
                          "active": inuse == "*", "saved": ssid in by_ssid,
                          "uuid": by_ssid[ssid]["uuid"] if ssid in by_ssid else ""}
        cur = next((n for n in nets.values() if n["active"]), None)
        if cur:
            _, o, _ = nm("-t", "-f", "GENERAL.CONNECTION,GENERAL.HWADDR,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,IP6.ADDRESS",
                         "device", "show", dev)
            info = {}
            for r in rows(o):
                if len(r) >= 2:
                    k = re.sub(r"\[\d+\]$", "", r[0])
                    info.setdefault(k, []).append(":".join(r[1:]))
            active = dict(cur)
            active.update({"device": dev, "connection": (info.get("GENERAL.CONNECTION") or [""])[0],
                           "mac": (info.get("GENERAL.HWADDR") or [""])[0],
                           "ip": (info.get("IP4.ADDRESS") or [""])[0], "gateway": (info.get("IP4.GATEWAY") or [""])[0],
                           "dns": info.get("IP4.DNS", []),
                           "ip6": [a for a in info.get("IP6.ADDRESS", []) if not a.lower().startswith("fe80")][:1]})
            s = by_ssid.get(cur["ssid"])
            if s:
                active["uuid"] = s["uuid"]
    networks = sorted(nets.values(), key=lambda n: (not n["active"], not n["saved"], -n["signal"]))
    in_range = set(nets)
    out({"ok": True, "radio": radio_on, "device": dev, "deviceState": devstate, "active": active,
         "networks": networks[:25], "saved": [s for s in sv if s["ssid"] not in in_range]})


def result(code, msg_ok, err):
    if code == 0:
        out({"ok": True, "msg": msg_ok})
    # nmcli's messages are long; keep the useful part
    e = re.sub(r"^Error:\s*", "", err.splitlines()[-1] if err else "failed")
    if "Secrets were required" in err or "802-11-wireless-security.psk" in err or "property is invalid" in err.lower():
        e = "wrong password"
    out({"ok": False, "msg": e[:160]})


def connect(ssid, pw="", hidden=False):
    args = ["device", "wifi", "connect", ssid]
    if pw:
        args += ["password", pw]
    if hidden:
        args += ["hidden", "yes"]
    code, _, err = nm(*args, timeout=45)
    result(code, f"connected to {ssid}", err)


def details(uuid):
    keys = "connection.id,connection.autoconnect,connection.metered,ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns,ipv4.ignore-auto-dns,802-11-wireless.ssid"
    code, o, err = nm("-t", "-f", keys, "connection", "show", "uuid", uuid)
    if code != 0:
        out({"ok": False, "msg": err or "not found"})
    d = {}
    for r in rows(o):
        if len(r) >= 2:
            d[r[0]] = ":".join(r[1:])
    manual_dns = d.get("ipv4.ignore-auto-dns") == "yes" and d.get("ipv4.dns", "") not in ("", "--")
    out({"ok": True, "uuid": uuid, "name": d.get("connection.id", ""), "ssid": d.get("802-11-wireless.ssid", ""),
         "autoconnect": d.get("connection.autoconnect") == "yes",
         "metered": d.get("connection.metered") in ("yes", "guess-yes"),
         "dns": d.get("ipv4.dns", "").replace(",", " ") if manual_dns else "auto",
         "ip": d.get("ipv4.addresses", "").split(",")[0] if d.get("ipv4.method") == "manual" else "auto",
         "gateway": d.get("ipv4.gateway", "") if d.get("ipv4.gateway", "") != "--" else ""})


IP4 = re.compile(r"^(\d{1,3}\.){3}\d{1,3}$")


def edit(uuid, js):
    try:
        e = json.loads(js)
    except ValueError:
        out({"ok": False, "msg": "bad settings"})
    args = []
    if "autoconnect" in e:
        args += ["connection.autoconnect", "yes" if e["autoconnect"] else "no"]
    if "metered" in e:
        args += ["connection.metered", "yes" if e["metered"] else "no"]
    if "dns" in e:
        dns = str(e["dns"]).strip()
        if dns in ("", "auto"):
            args += ["ipv4.ignore-auto-dns", "no", "ipv4.dns", "", "ipv6.ignore-auto-dns", "no"]
        else:
            parts = re.split(r"[\s,]+", dns)
            if not all(IP4.match(p) for p in parts):
                out({"ok": False, "msg": "DNS must be IPv4 addresses, e.g. 1.1.1.1 8.8.8.8"})
            args += ["ipv4.ignore-auto-dns", "yes", "ipv4.dns", " ".join(parts), "ipv6.ignore-auto-dns", "yes"]
    if "ip" in e:
        ip = str(e["ip"]).strip()
        if ip in ("", "auto"):
            args += ["ipv4.method", "auto", "ipv4.addresses", "", "ipv4.gateway", ""]
        else:
            if "/" not in ip:
                ip += "/24"
            a, _, pre = ip.partition("/")
            gw = str(e.get("gateway", "")).strip()
            if not IP4.match(a) or not pre.isdigit() or not (0 < int(pre) <= 32) or (gw and not IP4.match(gw)):
                out({"ok": False, "msg": "static IP needs e.g. 192.168.254.50/24 and a gateway like 192.168.254.254"})
            args += ["ipv4.method", "manual", "ipv4.addresses", ip] + (["ipv4.gateway", gw] if gw else [])
    if not args:
        out({"ok": True, "msg": "nothing changed"})
    code, _, err = nm("connection", "modify", "uuid", uuid, *args)
    if code != 0:
        result(code, "", err)
    # apply now if it's the active connection
    _, o, _ = nm("-t", "-f", "UUID", "connection", "show", "--active")
    if uuid in o.split():
        dev, _ = wifi_dev()
        c2, _, e2 = nm("device", "reapply", dev) if dev else (1, "", "")
        if c2 != 0:
            nm("connection", "up", "uuid", uuid, timeout=45)
    out({"ok": True, "msg": "saved"})


def share(uuid):
    code, o, err = nm("-s", "-g", "802-11-wireless-security.psk,802-11-wireless.ssid,802-11-wireless-security.key-mgmt",
                      "connection", "show", "uuid", uuid)
    if code != 0:
        out({"ok": False, "msg": err or "can't read it"})
    unesc = lambda v: re.sub(r"\\(.)", r"\1", v.strip())
    lines = o.splitlines() + ["", "", ""]
    pw, ssid, km = unesc(lines[0]), unesc(lines[1]), unesc(lines[2])
    qr = ""
    if shutil.which("qrencode"):
        kind = "nopass" if not pw else ("SAE" if km == "sae" else "WPA")
        esc = lambda s: re.sub(r'([\\;,:"])', r"\\\1", s)
        payload = f"WIFI:T:{kind};S:{esc(ssid)};" + (f"P:{esc(pw)};" if pw else "") + ";"
        qr = os.path.join(RUN, f"qs-wifi-qr-{uuid[:8]}.png")
        try:
            subprocess.run(["qrencode", "-o", qr, "-s", "6", "-m", "2", "--foreground=000000", "--background=FFFFFF", payload],
                           check=True, timeout=10)
            os.chmod(qr, 0o600)
        except Exception:
            qr = ""
    out({"ok": True, "ssid": ssid, "password": pw, "qr": qr})


if __name__ == "__main__":
    a = sys.argv[1:]
    cmd = a[0] if a else ""
    if cmd == "status":
        status(len(a) > 1 and a[1] == "rescan")
    elif cmd == "connect" and len(a) >= 2:
        connect(a[1], a[2] if len(a) > 2 else "")
    elif cmd == "hidden" and len(a) >= 2:
        connect(a[1], a[2] if len(a) > 2 else "", hidden=True)
    elif cmd == "up" and len(a) >= 2:
        c, _, e = nm("connection", "up", "uuid", a[1], timeout=45); result(c, "connected", e)
    elif cmd == "disconnect":
        d, _ = wifi_dev()
        c, _, e = nm("device", "disconnect", d) if d else (1, "", "no Wi-Fi device"); result(c, "disconnected", e)
    elif cmd == "forget" and len(a) >= 2:
        c, _, e = nm("connection", "delete", "uuid", a[1]); result(c, "forgotten", e)
    elif cmd == "details" and len(a) >= 2:
        details(a[1])
    elif cmd == "edit" and len(a) >= 3:
        edit(a[1], a[2])
    elif cmd == "share" and len(a) >= 2:
        share(a[1])
    elif cmd == "radio" and len(a) >= 2 and a[1] in ("on", "off"):
        c, _, e = nm("radio", "wifi", a[1]); result(c, "Wi-Fi " + a[1], e)
    out({"ok": False, "msg": "unknown command"})
