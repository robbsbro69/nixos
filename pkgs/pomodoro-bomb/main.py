#!/usr/bin/env python3
"""
pomodoro-bomb: a standalone, solo-purpose pomodoro timer window
styled as a bundle of dynamite, for Hyprland/NixOS desktops.

Left-click  : start / pause
Right-click : reset current phase
Scroll      : adjust minutes for the current (paused) phase

Usage:
    python main.py [--work 25] [--break 5]
"""
import argparse
import subprocess
import sys
from pathlib import Path

from PySide6.QtCore import QObject, Slot
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine


class NotifyProxy(QObject):
    """Exposed to QML as `notifyProxy` — fires a desktop notification
    (via notify-send, if available) when a phase completes."""

    @Slot(bool)
    def notifyPhaseChange(self, is_break: bool) -> None:
        title = "Break time" if is_break else "Back to work"
        body = "Fuse reset — pomodoro's lit again." if is_break else "Break's over, get back to it."
        try:
            subprocess.Popen(
                ["notify-send", "-a", "pomodoro-bomb", title, body],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except FileNotFoundError:
            pass  # notify-send not installed; fail silently


def main() -> int:
    parser = argparse.ArgumentParser(description="Solo-purpose bomb-styled pomodoro timer")
    parser.add_argument("--work", type=int, default=25, help="work minutes (default 25)")
    parser.add_argument("--break", dest="brk", type=int, default=5, help="break minutes (default 5)")
    parser.add_argument("--hat", action="store_true", help="show the festive santa hat")
    args = parser.parse_args()

    app = QGuiApplication(sys.argv)
    app.setApplicationName("pomodoro-bomb")
    app.setDesktopFileName("pomodoro-bomb")

    engine = QQmlApplicationEngine()

    notify_proxy = NotifyProxy()
    engine.rootContext().setContextProperty("notifyProxy", notify_proxy)

    qml_path = Path(__file__).resolve().parent / "bomb.qml"
    engine.load(str(qml_path))

    if not engine.rootObjects():
        return 1

    root = engine.rootObjects()[0]
    root.setProperty("workMinutes", args.work)
    root.setProperty("breakMinutes", args.brk)
    root.setProperty("festiveHat", args.hat)
    root.setProperty("remainingSeconds", args.work * 60)

    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
