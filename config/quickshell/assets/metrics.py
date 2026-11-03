#!/usr/bin/env python3
"""metrics.py — one JSON line of CPU/GPU load + temps for the Quickshell bar.
   Reads sysfs only (never nvidia-smi → never hangs). Finds chips by name, so
   unstable hwmon numbering across reboots doesn't matter.
     metrics.py          pill data (cpu/gpu % + temp + vram)
     metrics.py detail   + per-core % and top CPU processes (for the popup)
"""
import json, os, glob, time, sys

def read(p):
    try:
        with open(p) as f: return f.read().strip()
    except Exception: return None

def find_hwmon(name):
    for n in glob.glob("/sys/class/hwmon/hwmon*/name"):
        if read(n) == name: return os.path.dirname(n)
    return None

def temp(hw, label):
    if not hw: return None
    for lbl in glob.glob(hw + "/temp*_label"):
        if read(lbl) == label:
            v = read(lbl.replace("_label", "_input"))
            if v: return round(int(v) / 1000)
    v = read(hw + "/temp1_input")
    return round(int(v) / 1000) if v else None

def cpu_times():
    out = {}
    for ln in read("/proc/stat").splitlines():
        if ln.startswith("cpu"):
            f = ln.split()
            vals = list(map(int, f[1:]))
            idle = vals[3] + (vals[4] if len(vals) > 4 else 0)
            out[f[0]] = (idle, sum(vals))
    return out

def cpu_usage(detail=False):
    a = cpu_times(); time.sleep(0.2); b = cpu_times()
    def pct(k):
        di = b[k][0] - a[k][0]; dt = b[k][1] - a[k][1]
        return round(100 * (1 - di / dt)) if dt > 0 else 0
    total = pct("cpu")
    cores = [pct(k) for k in sorted(a) if k != "cpu"] if detail else None
    return total, cores

def top_procs(n=5):
    # biggest CPU users right now (one-shot %cpu from ps)
    try:
        import subprocess
        r = subprocess.run(["ps", "-eo", "comm,%cpu", "--sort=-%cpu", "--no-headers"],
                           capture_output=True, text=True, timeout=3).stdout
        out = []
        for ln in r.splitlines()[:n]:
            p = ln.rsplit(None, 1)
            if len(p) == 2: out.append({"name": p[0], "cpu": float(p[1])})
        return out
    except Exception: return []

detail = len(sys.argv) > 1 and sys.argv[1] == "detail"
cpu_hw = find_hwmon("k10temp")
gpu_hw = find_hwmon("amdgpu")
cpu_pct, cores = cpu_usage(detail)

o = {
    "cpu_pct": cpu_pct,
    "cpu_temp": temp(cpu_hw, "Tctl") or 0,
    "gpu_pct": int(read(gpu_hw + "/device/gpu_busy_percent") or 0) if gpu_hw else 0,
    "gpu_temp": temp(gpu_hw, "edge") or 0,
}
if gpu_hw:
    u = read(gpu_hw + "/device/mem_info_vram_used")
    t = read(gpu_hw + "/device/mem_info_vram_total")
    if u and t:
        o["vram_used"] = round(int(u) / 2**20)
        o["vram_total"] = round(int(t) / 2**20)
if detail:
    o["cores"] = cores or []
    o["procs"] = top_procs()
print(json.dumps(o, separators=(",", ":")))
