//@ pragma UseQApplication
//@ pragma ShellId nixos-alpha-shell
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "."
import "./components"

ShellRoot {
	id: root
	property string configPath: Quickshell.env("HOME") + "/.config/quickshell"
	property string homePath: Quickshell.env("HOME")
	property string wallpaperPath: homePath + "/wallpapers"
	property string cachePath: homePath + "/.cache"
	property string statePath: configPath + "/state"

	// ── Theme — Catppuccin Mocha (dark) / Latte (light) ── qs-update:v1 ── qs-update:v2 ── qs-update:v3 ── qs-update:v4 ── qs-update:v5 ── qs-update:v6 ── qs-update:v7 ── qs-update:v8 ── qs-update:v10 ── qs-update:v11 ── qs-update:v12 ── qs-update:v13 ── qs-update:v14 ── qs-update:v15 ── qs-update:v16 ── qs-update:v32 ── qs-update:v28 ── qs-update:v29 ── qs-update:v30 ── qs-update:v31 ── qs-update:v27 ── qs-update:v17 ── qs-update:v18 ── qs-update:v19 ── qs-update:v20 ── qs-update:v9 ── qs-update:v21 ──
	// Toggle from the dashboard or `qs ipc call theme toggle`; persisted in state/theme-mode.
	property bool lightMode: false
	onLightModeChanged: UIState.lightMode = lightMode
	readonly property var themeList: [
		{ k: "mocha", t: "Catppuccin" },
		{ k: "rosepine", t: "Rosé Pine" },
		{ k: "nord", t: "Nord" },
		{ k: "dracula", t: "Dracula" },
		{ k: "gruvbox", t: "Gruvbox" },
		{ k: "tokyonight", t: "Tokyo Night" },
		{ k: "mono", t: "Monochrome" }
	]
	readonly property var palettes: ({
		mocha: {
			dark: { bg: "#1e1e2e", bar: "#181825", crust: "#11111b", surface: "#313244", fg: "#cdd6f4", red: "#f38ba8", green: "#a6e3a1", yellow: "#f9e2af", pink: "#f5c2e7", teal: "#94e2d5", dim: "#7f849c", blue: "#89b4fa", mauve: "#cba6f7", peach: "#fab387" },
			light: { bg: "#eff1f5", bar: "#e6e9ef", crust: "#dce0e8", surface: "#ccd0da", fg: "#4c4f69", red: "#d20f39", green: "#40a02b", yellow: "#df8e1d", pink: "#ea76cb", teal: "#179299", dim: "#6c6f85", blue: "#1e66f5", mauve: "#8839ef", peach: "#fe640b" }
		},
		rosepine: {
			dark: { bg: "#191724", bar: "#1f1d2e", crust: "#12101a", surface: "#26233a", fg: "#e0def4", red: "#eb6f92", green: "#9ccfd8", yellow: "#f6c177", pink: "#ebbcba", teal: "#31748f", dim: "#6e6a86", blue: "#9ccfd8", mauve: "#c4a7e7", peach: "#f6c177" },
			light: { bg: "#faf4ed", bar: "#fffaf3", crust: "#f2e9e1", surface: "#f2e9e1", fg: "#575279", red: "#b4637a", green: "#56949f", yellow: "#ea9d34", pink: "#d7827e", teal: "#286983", dim: "#797593", blue: "#56949f", mauve: "#907aa9", peach: "#ea9d34" }
		},
		nord: {
			dark: { bg: "#2e3440", bar: "#3b4252", crust: "#242933", surface: "#434c5e", fg: "#eceff4", red: "#bf616a", green: "#a3be8c", yellow: "#ebcb8b", pink: "#88c0d0", teal: "#8fbcbb", dim: "#4c566a", blue: "#81a1c1", mauve: "#b48ead", peach: "#d08770" },
			light: { bg: "#eceff4", bar: "#e5e9f0", crust: "#d8dee9", surface: "#d8dee9", fg: "#2e3440", red: "#bf616a", green: "#a3be8c", yellow: "#ebcb8b", pink: "#5e81ac", teal: "#8fbcbb", dim: "#4c566a", blue: "#81a1c1", mauve: "#b48ead", peach: "#d08770" }
		},
		dracula: {
			dark: { bg: "#282a36", bar: "#21222c", crust: "#191a21", surface: "#44475a", fg: "#f8f8f2", red: "#ff5555", green: "#50fa7b", yellow: "#f1fa8c", pink: "#ff79c6", teal: "#8be9fd", dim: "#6272a4", blue: "#8be9fd", mauve: "#bd93f9", peach: "#ffb86c" },
			light: { bg: "#fffbeb", bar: "#f5f1e1", crust: "#ece8d6", surface: "#dedccf", fg: "#1f1f1f", red: "#cb3a2a", green: "#14710a", yellow: "#846e15", pink: "#a3144d", teal: "#036a96", dim: "#6c664b", blue: "#036a96", mauve: "#644ac9", peach: "#a34d14" }
		},
		gruvbox: {
			dark: { bg: "#282828", bar: "#1d2021", crust: "#141617", surface: "#3c3836", fg: "#ebdbb2", red: "#fb4934", green: "#b8bb26", yellow: "#fabd2f", pink: "#fe8019", teal: "#8ec07c", dim: "#928374", blue: "#83a598", mauve: "#fabd2f", peach: "#fe8019" },
			light: { bg: "#fbf1c7", bar: "#f2e5bc", crust: "#ebdbb2", surface: "#d5c4a1", fg: "#3c3836", red: "#9d0006", green: "#79740e", yellow: "#b57614", pink: "#af3a03", teal: "#427b58", dim: "#7c6f64", blue: "#076678", mauve: "#b57614", peach: "#af3a03" }
		},
		tokyonight: {
			dark: { bg: "#1a1b26", bar: "#16161e", crust: "#101014", surface: "#292e42", fg: "#c0caf5", red: "#f7768e", green: "#9ece6a", yellow: "#e0af68", pink: "#7aa2f7", teal: "#73daca", dim: "#565f89", blue: "#7dcfff", mauve: "#bb9af7", peach: "#ff9e64" },
			light: { bg: "#e1e2e7", bar: "#d0d5e3", crust: "#c4c8da", surface: "#c4c8da", fg: "#3760bf", red: "#f52a65", green: "#587539", yellow: "#8c6c3e", pink: "#2e7de9", teal: "#118c74", dim: "#6172b0", blue: "#007197", mauve: "#9854f1", peach: "#b15c00" }
		},
		mono: {
			dark: { bg: "#161616", bar: "#101010", crust: "#000000", surface: "#2a2a2a", fg: "#e0e0e0", red: "#ffffff", green: "#c4c4c4", yellow: "#d8d8d8", pink: "#f0f0f0", teal: "#b0b0b0", dim: "#7a7a7a", blue: "#cfcfcf", mauve: "#e6e6e6", peach: "#d0d0d0" },
			light: { bg: "#f5f5f5", bar: "#ebebeb", crust: "#dedede", surface: "#d4d4d4", fg: "#1f1f1f", red: "#000000", green: "#444444", yellow: "#383838", pink: "#111111", teal: "#4a4a4a", dim: "#6b6b6b", blue: "#2b2b2b", mauve: "#1a1a1a", peach: "#333333" }
		}
	})
	property string themeName: "mocha"         // see themeList; saved in state/theme-name
	readonly property var pal: (palettes[themeName] || palettes.mocha)[lightMode ? "light" : "dark"]
	Binding { target: UIState; property: "pal"; value: root.pal }
	readonly property color walBackground: pal.bg
	readonly property color walForeground: pal.fg
	readonly property color walColor1:  pal.red      // critical/urgent
	readonly property color walColor2:  pal.green    // success/connected
	readonly property color walColor4:  pal.yellow   // warning
	readonly property color walColor5:  pal.pink     // primary accent
	readonly property color walColor6:  pal.teal
	readonly property color walColor8:  pal.dim      // dim/overlay
	readonly property color walColor12: pal.blue
	readonly property color walColor13: themeName === "mocha" ? pal.pink : pal.mauve    // secondary accent
	readonly property color walPeach:   pal.peach
	readonly property color barColor:   pal.bar
	// Inset cards / hover tints that read correctly on both dark and light panels
	function card(a)  { return lightMode ? Qt.rgba(walForeground.r, walForeground.g, walForeground.b, a * 0.13) : Qt.rgba(0, 0, 0, a) }
	function hover(a) { return lightMode ? Qt.rgba(walForeground.r, walForeground.g, walForeground.b, Math.min(0.16, a * 0.3)) : Qt.rgba(1, 1, 1, a) }
	function setTheme(k) {
		if (!palettes[k]) return
		themeName = k
		saveState("theme-name", k)
	}
	function nextTheme() {
		var i = 0
		for (var j = 0; j < themeList.length; j++) if (themeList[j].k === themeName) i = j
		setTheme(themeList[(i + 1) % themeList.length].k)
	}

	// ── Bar: position + visibility ── qs-update:v13 (state/bar) ──
	property string barPosition: "bottom"      // top | bottom
	property string barStyle: "default"        // default | i3 | minimal
	property string barMode: "shown"           // shown | auto (hide until the edge is touched) | hidden
	property bool barPeek: false
	property bool barMenuVisible: false
	readonly property bool barVertical: barPosition === "left" || barPosition === "right"
	readonly property int barThicknessBase: barStyle === "i3" ? 22 : barStyle === "minimal" ? 24 : 28
	property bool barFloating: false          // floating: rounded bar with space around it
	readonly property int barThickness: barThicknessBase + (barFloating ? 8 : 0)
	// background per style (default keeps barColor)
	readonly property color barBgBase: barStyle === "islands" || barStyle === "floating" ? "transparent" : barStyle === "i3" ? "#000000" : barStyle === "minimal" ? pal.bg : barColor
	readonly property bool anyPanelOpen: dashboardVisible || musicVisible || launcherVisible || wifiVisible || btVisible
		|| calendarVisible || notifCenterVisible || clipboardVisible || clockPanelVisible
		|| recordMenuVisible || pomoVisible || eqVisible || screenTimeVisible
		|| jarvisVisible || jarvisTimelineVisible || barMenuVisible
	// pomo-zen: a running focus session hides the bar (edge-peek still works)
	property bool pomoZenEnabled: true
	readonly property bool pomoZen: pomoZenEnabled && pomoRunning && pomoPhase === "focus"
	property int pomoZenWs: 0                    // the focus workspace
	property int _zenPrevWs: 0
	property bool _zenPrevDnd: false
	property bool _zenActive: false
	// focus-cam: phone camera timelapse while a focus session runs (scripts/focuscam.sh)
	readonly property string focusCamScript: homePath + "/nixos-private/scripts/focuscam.sh"   // private; camera UI hidden when missing
	property bool focusCamAvailable: false        // true only when the private focuscam.sh exists
	Process {
		command: ["test", "-x", root.focusCamScript]
		running: true
		onExited: (code, status) => root.focusCamAvailable = code === 0
	}
	property string focusCamFacing: "front"      // front | back | off   (state/focuscam-facing)
	property bool focusCamPreview: false          // small live window in the corner (state/focuscam-preview)
	readonly property bool focusCamOn: focusCamAvailable && focusCamFacing !== "off"
	function focusCamStart() {
		if (focusCamOn) Quickshell.execDetached([focusCamScript, "start", focusCamPreview ? "1" : "0"])
	}
	function focusCamTogglePreview() {
		focusCamPreview = !focusCamPreview
		saveState("focuscam-preview", focusCamPreview ? "on" : "off")
		Quickshell.execDetached([focusCamScript, "preview", focusCamPreview ? "on" : "off"])
	}
	function focusCamSetFacing(f) {
		focusCamFacing = f
		saveState("focuscam-facing", f)
		if (!pomoZen) return
		if (f === "off") Quickshell.execDetached([focusCamScript, "finish"])
		else Quickshell.execDetached(["bash", "-c", "sleep 0.3; \"$1\" start \"$2\"", "_", focusCamScript, focusCamPreview ? "1" : "0"])
	}
	function pomoZenEnter() {
		if (_zenActive) return
		_zenActive = true
		focusCamStart()
		_zenPrevWs = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
		_zenPrevDnd = dndEnabled
		dndEnabled = true
		closeSidePanels()
		if (pomoZenWs > 0 && _zenPrevWs !== pomoZenWs)
			Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + pomoZenWs + " })"])
	}
	function pomoZenExit() {
		if (!_zenActive) return
		_zenActive = false
		focusCamSettleTimer.restart()
		dndEnabled = _zenPrevDnd
		if (pomoZenWs > 0 && _zenPrevWs > 0 && _zenPrevWs !== pomoZenWs && Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === pomoZenWs)
			Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + _zenPrevWs + " })"])
	}
	Connections {
		target: root
		function onPomoZenChanged() { root.pomoZen ? root.pomoZenEnter() : root.pomoZenExit() }
	}
	readonly property bool barShown: pomoZen ? false : (barMode === "shown" || barPeek || (barMode === "auto" && anyPanelOpen))
	// space the bar takes on each edge — panels use these to open beside it
	readonly property int barInsetTop: barPosition === "top" && barMode !== "hidden" ? barThickness : 0
	readonly property int barInsetBottom: barPosition === "bottom" && barMode !== "hidden" ? barThickness : 0
	readonly property int barInsetLeft: barPosition === "left" && barMode !== "hidden" ? barThickness : 0
	readonly property int barInsetRight: barPosition === "right" && barMode !== "hidden" ? barThickness : 0
	readonly property int barGapV: barInsetTop + barInsetBottom + 8
	function setBarPosition(p) {
		if (p === "left" || p === "right") p = "bottom"
		if (["top", "bottom"].indexOf(p) < 0) return
		barPosition = p
		saveBar()
	}
	function cycleBarPosition() {
		setBarPosition(barPosition === "top" ? "bottom" : "top")
	}
	function setBarMode(m) {
		if (["shown", "auto", "hidden"].indexOf(m) < 0) return
		barMode = m
		barPeek = false
		saveBar()
	}
	function toggleBar() { setBarMode(barMode === "hidden" ? "shown" : "hidden") }
	function barPeekNow() { if (barMode !== "shown" || pomoZen) { barPeek = true; barHideTimer.stop() } }
	function barLeave() { if (barMode !== "shown" || pomoZen) barHideTimer.restart() }
	property string barOpacity: "opaque"       // opaque | transparent | blur
	readonly property real barAlpha: barOpacity === "transparent" ? 0.55 : (barOpacity === "blur" ? 0.62 : 1)
	readonly property color barBg: Qt.rgba(barBgBase.r, barBgBase.g, barBgBase.b, barBgBase.a * barAlpha)
	readonly property string barBlurScript: homePath + "/.config/scripts/bar-blur.sh"
	property real barBlurAt: 0
	function applyBarBlur() {
		barBlurAt = Date.now()
		Quickshell.execDetached([barBlurScript, barOpacity === "blur" ? "on" : "off"])
	}
	onBarOpacityChanged: applyBarBlur()
	function setBarOpacity(o) {
		if (["opaque", "transparent", "blur"].indexOf(o) < 0) return
		barOpacity = o
		saveBar()
	}
	function saveBar() { saveState("bar", barPosition + " " + barMode + " " + barStyle + " " + barOpacity + " " + (barFloating ? "float" : "attached")) }
	function setBarFloating(f) {
		barFloating = f
		saveBar()
	}
	onBarStyleChanged: if (["default", "i3", "enjoy"].indexOf(barStyle) < 0) barStyle = "default"
	function setBarStyle(s) {
		if (["default", "i3", "enjoy"].indexOf(s) < 0) return
		barStyle = s
		saveBar()
	}
	function cycleBarStyle() {
		var order = ["default", "i3", "enjoy"]
		setBarStyle(order[(order.indexOf(barStyle) + 1) % order.length])
	}

	// ── Panel visibility ─────────────────────────────────────────────────
	property bool dashboardVisible: false
	property var _ui: UIState
	property bool musicVisible: false
	property bool launcherVisible: false
	property bool wifiVisible: false
	property bool btVisible: false
	property bool calendarVisible: false
	property bool dndEnabled: false
	onDndEnabledChanged: UIState.dndEnabled = dndEnabled
	property bool notifCenterVisible: false
	property bool clipboardVisible: false
	property bool clockPanelVisible: false
	property bool notesVisible: false
	property real musicAnchorX: -1          // screen x of the bar's music component (centre)
	property bool recordMenuVisible: false
	property bool nightLight: false
	property bool recording: false
	property real recStartedAt: 0
	property string recElapsedText: "00:00"
	readonly property string recordScript: homePath + "/.config/scripts/record.sh"
	property int nightTemp: 3000
	readonly property string nightScript: homePath + "/.config/scripts/nightlight.sh"

	// ── Pomodoro (state lives here so the bar notch keeps ticking) ──
	property bool pomoVisible: false
	property bool pomoRunning: false
	property string pomoPhase: "focus"          // focus | break | long
	property int pomoWorkMin: 30
	property int pomoLongEvery: 3          // long break after this many focus sessions
	property int pomoBreakMin: 5
	property int pomoLongMin: 15
	property int pomoSessions: 0
	property int pomoRemaining: 30 * 60
	property real pomoEndsAt: 0
	property bool pomoBlast: false
	property bool overviewVisible: false
	readonly property string themeScript: homePath + "/.config/scripts/theme.sh"

	// ── v4: overview previews, equalizer, screen time ──
	property bool overviewPreviews: true
	property bool eqVisible: false
	property bool eqEnabled: false
	property var eqGains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	property string eqPreset: "Flat"
	readonly property string eqScript: homePath + "/.config/scripts/eq.sh"
	readonly property var eqPresets: ({
		"Flat":       [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"Bass":       [6, 5, 4, 2, 0, 0, 0, 0, 0, 0],
		"Treble":     [0, 0, 0, 0, 0, 1, 2, 4, 5, 6],
		"Vocal":      [-2, -1, 0, 2, 4, 4, 3, 1, 0, -1],
		"Rock":       [4, 3, 1, -1, -2, -1, 1, 3, 4, 4],
		"Electronic": [5, 4, 1, 0, -2, 1, 0, 1, 4, 5],
		"Loudness":   [5, 3, 0, 0, -1, 0, 0, 1, 3, 4]
	})
	property bool screenTimeVisible: false
	property var stData: ({})
	property bool stLoaded: false
	property real stLastTick: Date.now()
	readonly property bool stIdle: stIdleLoader.item ? stIdleLoader.item.isIdle : false

	// ── v7: Jarvis (Pi) ──
	property bool jarvisVisible: false
	property bool jarvisTimelineVisible: false
	// Jarvis is private: everything Jarvis only shows/runs when its login file exists
	property bool jarvisEnabled: false
	Process {
		command: ["test", "-f", root.homePath + "/.config/jarvis/client.env"]
		running: true
		onExited: (code, status) => root.jarvisEnabled = code === 0
	}
	property var jarvisData: null
	property bool jarvisOnline: false
	property string jarvisError: ""
	property real jarvisSyncedAt: 0
	property bool jarvisBusy: false
	property bool jarvisAlerts: false          // desktop notifications too (Telegram always gets them)
	property bool jarvisPrimed: false
	property string jarvisMsg: ""
	property var jarvisSeen: ({})
	property var jarvisPending: ({})
	// ── v10: notification feed (everything Jarvis sends to Telegram) ──
	property var jarvisFeed: []                // newest first, last 20
	property int jarvisFeedCursor: -1          // newest id seen
	property bool jarvisFeedOk: false          // Pi has /api/notifications
	property bool jarvisFeedCursorLoaded: false
	// ── v11: clearing the "From Jarvis" list (laptop only; Telegram keeps everything) ──
	property int jarvisFeedClearedTo: 0        // everything up to this id is cleared
	property var jarvisFeedHidden: ({})        // single cleared ids above that
	readonly property var jarvisFeedShown: jarvisFeed.filter(function(f) {
		return f.id > jarvisFeedClearedTo && !jarvisFeedHidden[f.id]
	})       // id → {at, text, critical} for today's upcoming reminders
	property var jarvisQueue: []
	readonly property string jarvisScript: homePath + "/.config/scripts/jarvis.sh"
	readonly property int jarvisBadge: {
		if (!jarvisData) return 0
		var n = 0, r = jarvisData.reminders || [], t = jarvisData.tasks || []
		for (var i = 0; i < r.length; i++) if (r[i].due && !r[i].acked) n++
		for (var j = 0; j < t.length; j++) if (t[j].overdue && !t[j].done) n++
		return n
	}
	readonly property bool jarvisCritical: {
		if (!jarvisData) return false
		var r = jarvisData.reminders || []
		for (var i = 0; i < r.length; i++) if (r[i].due && !r[i].acked && r[i].critical) return true
		return false
	}
	readonly property var iconAliases: ({
		"spotify": "spotify-client", "thunar": "org.xfce.thunar", "zen": "zen-browser",
		"zen-beta": "zen-browser", "org.telegram.desktop": "telegram", "code": "vscode",
		"brave-browser": "brave-browser", "obsidian": "obsidian", "kitty": "kitty"
	})
	signal pomoExploded()
	readonly property int pomoTotal: (pomoPhase === "focus" ? pomoWorkMin : (pomoPhase === "long" ? pomoLongMin : pomoBreakMin)) * 60
	readonly property real pomoProgress: pomoTotal > 0 ? 1 - pomoRemaining / pomoTotal : 0
	readonly property bool pomoActive: pomoRunning || pomoRemaining < pomoTotal
	readonly property color pomoColor: pomoPhase === "focus" ? walPeach : (pomoPhase === "long" ? walColor6 : walColor2)
	readonly property string pomoText: {
		var m = Math.floor(pomoRemaining / 60), sec = pomoRemaining % 60
		return (m < 10 ? "0" + m : m) + ":" + (sec < 10 ? "0" + sec : sec)
	}

	// ── Misc state ────────────────────────────────────────────────────────
	property bool ethConnected: false
	property var pfpFiles: []
	property string searchTerm: ""
	property string ethDevice: ""
	property var appList: []
	property var notifications: []
	property var notificationHistory: []
	property var appUsage: ({})

	property var filteredApps: {
		var source = appList
		var usage = appUsage
		if (searchTerm !== "") {
			var result = []
			for (var i = 0; i < source.length; i++) {
				var entry = source[i]
				if (entry.name.toLowerCase().includes(searchTerm) || entry.exec.toLowerCase().includes(searchTerm))
					result.push(entry)
			}
			source = result
		}
		return source.slice().sort(function(a, b) {
			var countA = usage[a.name] || 0
			var countB = usage[b.name] || 0
			if (countB !== countA) return countB - countA
			return a.name.localeCompare(b.name)
		})
	}

	property int selectedIndex: 0
	property int activeTab: 0
	property string wallSearchTerm: ""
	property var wallpaperList: []
	property var filteredWallpapers: {
		if (wallSearchTerm === "") return wallpaperList
		var result = []
		for (var i = 0; i < wallpaperList.length; i++) {
			if (wallpaperList[i].name.toLowerCase().includes(wallSearchTerm))
				result.push(wallpaperList[i])
		}
		return result
	}
	property int wallSelectedIndex: 0
	property string currentWallpaper: ""
	property bool wallsLoaded: false
	property bool thumbsReady: false
	property bool walApplying: false
	property var wallpaperHashes: ({})

	// ── Wifi ─────────────────────────────────────────────────────────────
	property bool wifiEnabled: true
	property string wifiCurrentSSID: ""
	property int wifiSignal: 0
	property var wifiNetworks: []
	property bool wifiScanning: false
	property string wifiPasswordSSID: ""
	property bool wifiConnecting: false

	// ── Bluetooth ─────────────────────────────────────────────────────────
	property bool btEnabled: true
	property var btPairedDevices: []
	property var btAvailableDevices: []
	property bool btScanning: false
	property string btConnectingMAC: ""

	// ── Gif / state ───────────────────────────────────────────────────────
	property int savedGifIndex: 0
	property var focusedScreen: Quickshell.screens[0]

	// ── Panel toggles ─────────────────────────────────────────────────────
	function toggleLauncher() { launcherVisible = !launcherVisible }
	function toggleDashboard() {
		dashboardVisible = !dashboardVisible
		if (dashboardVisible) { wifiVisible = false; btVisible = false }
	}
	function toggleMusic() { musicVisible = !musicVisible }
	function toggleWifi() {
		wifiVisible = !wifiVisible
		if (wifiVisible) { btVisible = false; dashboardVisible = false; refreshWifi() }
	}
	function toggleBluetooth() {
		btVisible = !btVisible
		if (btVisible) { wifiVisible = false; dashboardVisible = false; refreshBluetooth() }
	}
	function closeAllPanels() {
		dashboardVisible = false; musicVisible = false; launcherVisible = false
		wifiVisible = false; btVisible = false; calendarVisible = false
		notifCenterVisible = false; clockPanelVisible = false; clipboardVisible = false
		recordMenuVisible = false; pomoVisible = false; overviewVisible = false
		eqVisible = false; screenTimeVisible = false; jarvisVisible = false; jarvisTimelineVisible = false; barMenuVisible = false
	}
	function toggleCalendar() {
		calendarVisible = !calendarVisible
		if (calendarVisible) {
			dashboardVisible = false; musicVisible = false
			launcherVisible = false; wifiVisible = false; btVisible = false
		}
	}
	function toggleNotifCenter() { notifCenterVisible = !notifCenterVisible }
	function toggleClockPanel()  { clockPanelVisible  = !clockPanelVisible  }
	function toggleClipboard()   { clipboardVisible   = !clipboardVisible   }

	// ── Notes / recorder / theme ──────────────────────────────────────
	function toggleNotes() {
		notesVisible = !notesVisible
		if (notesVisible) { clipboardVisible = false; recordMenuVisible = false }
	}
	function toggleRecordMenu() {
		recordMenuVisible = !recordMenuVisible
		if (recordMenuVisible) {
			wifiVisible = false; btVisible = false; dashboardVisible = false
			clipboardVisible = false
		}
	}
	function startRecording(mode, arg) {
		recordMenuVisible = false
		recLaunchTimer.mode = mode
		recLaunchTimer.arg = arg || ""
		recLaunchTimer.restart()
	}
	function stopRecording() {
		recordMenuVisible = false
		Quickshell.execDetached([recordScript, "stop"])
	}
	function toggleLightMode() {
		lightMode = !lightMode
		saveState("theme-mode", lightMode ? "light" : "dark")
		Quickshell.execDetached([themeScript, lightMode ? "light" : "dark"])
	}
	function toggleNightLight() {
		Quickshell.execDetached([nightScript, nightLight ? "off" : "on"])
		nightLight = !nightLight
		nightRecheck.restart()
	}
	function setNightTemp(step) {
		nightTemp = Math.max(1500, Math.min(6500, nightTemp + step * 250))
		nightTempApply.restart()
	}

	// ── App icons / names (desktop entries first, then the launcher's list) ──
	function iconFor(cls) {
		if (!cls) return ""
		var lc = ("" + cls).toLowerCase()
		var tryPath = function(name) {
			if (!name) return ""
			if (name.indexOf("/") === 0) return "file://" + name
			try { return Quickshell.iconPath(name, true) || "" } catch (e) { return "" }
		}
		try {
			var e = DesktopEntries.heuristicLookup(cls)
			if (e && e.icon) { var p = tryPath(e.icon); if (p) return p }
		} catch (err) {}
		var alias = tryPath(iconAliases[lc])
		if (alias) return alias
		for (var i = 0; i < appList.length; i++) {
			var a = appList[i]
			if (!a.icon) continue
			var ex = a.exec.toLowerCase().split(" ")[0].split("/").pop()
			if (ex === lc || a.icon.toLowerCase() === lc || a.name.toLowerCase() === lc) {
				var q = tryPath(a.icon)
				if (q) return q
			}
		}
		return tryPath(lc) || "image://icon/" + lc
	}
	function prettyName(cls) {
		if (!cls) return "Unknown"
		try {
			var e = DesktopEntries.heuristicLookup(cls)
			if (e && e.name) return e.name
		} catch (err) {}
		var lc = ("" + cls).toLowerCase()
		for (var i = 0; i < appList.length; i++) {
			var a = appList[i]
			var ex = a.exec.toLowerCase().split(" ")[0].split("/").pop()
			if (ex === lc || (a.icon && a.icon.toLowerCase() === lc)) return a.name
		}
		return cls.charAt(0).toUpperCase() + cls.slice(1)
	}
	function toggleOverviewPreviews() {
		overviewPreviews = !overviewPreviews
		saveState("overview-previews", overviewPreviews ? "on" : "off")
	}

	// ── Equalizer ──
	function eqArgs() { return eqGains.map(function(g) { return "" + g }) }
	function closeSidePanels() {
		dashboardVisible = false; wifiVisible = false; btVisible = false; recordMenuVisible = false
		pomoVisible = false; clipboardVisible = false; notifCenterVisible = false
		eqVisible = false; screenTimeVisible = false; jarvisVisible = false; jarvisTimelineVisible = false; barMenuVisible = false
	}
	function toggleEq() {
		var open = !eqVisible
		closeSidePanels()
		eqVisible = open
	}
	function setEqEnabled(on) {
		eqEnabled = on
		Quickshell.execDetached([eqScript, on ? "on" : "off"].concat(on ? eqArgs() : []))
		eqSave()
	}
	function setEqGain(i, g) {
		var a = eqGains.slice()
		a[i] = Math.max(-12, Math.min(12, g))
		eqGains = a
		eqPreset = "Custom"
		eqApply.restart()
	}
	function applyEqPreset(name) {
		var p = eqPresets[name]
		if (!p) return
		eqGains = p.slice()
		eqPreset = name
		eqApply.restart()
	}
	function eqSave() {
		saveState("eq", (eqEnabled ? "on" : "off") + " " + eqPreset + " " + eqGains.join(" "))
	}

	// ── Screen time ──
	function toggleScreenTime() {
		var open = !screenTimeVisible
		closeSidePanels()
		screenTimeVisible = open
	}
	function stToday() { return Qt.formatDate(new Date(), "yyyy-MM-dd") }
	function stDay() {
		var key = stToday()
		if (!stData[key]) stData[key] = { apps: {}, open: {}, hours: [] }
		var day = stData[key]
		if (!day.apps) day.apps = {}
		if (!day.open) day.open = {}
		if (!day.hours || day.hours.length < 24) {
			var h0 = []
			for (var i = 0; i < 24; i++) h0.push((day.hours && day.hours[i]) || 0)
			day.hours = h0
		}
		return day
	}
	// one poll from screentime-poll.sh → credit every app that was in use.
	//   apps  = active: focused, visible on any monitor, or playing media
	//   open  = has a window on any workspace (or playing media)
	//   hours = wall-clock time at the computer (not idle / locked)
	function stTick(text) {
		var now = Date.now()
		var dt = Math.min(15, (now - stLastTick) / 1000)
		stLastTick = now
		if (!stLoaded || dt <= 0) return
		var locked = false, focused = "", visibleWs = {}, clients = [], players = []
		var lines = ("" + text).split("\n")
		for (var i = 0; i < lines.length; i++) {
			var ln = lines[i]
			if (ln.length < 3) continue
			var tag = ln.charAt(0), rest = ln.substring(2).trim()
			var sp = rest.indexOf(" ")
			if (tag === "L") locked = rest === "1"
			else if (tag === "A") focused = rest
			else if (tag === "W") visibleWs[rest] = true
			else if (tag === "C" && sp > 0) clients.push({ ws: rest.substring(0, sp), cls: rest.substring(sp + 1) })
			else if (tag === "P" && sp > 0 && rest.substring(0, sp) === "Playing") players.push(rest.substring(sp + 1).toLowerCase())
		}
		// a video playing counts as being at the computer, even with no input
		var stVideoPlaying = players.some(function(pl) {
			return /firefox|zen|chrom|brave|vivaldi|librewolf|floorp|mpv|vlc|celluloid|totem|jellyfin|kodi|haruna|smplayer|freetube/.test(pl)
		})
		var away = locked || (stIdle && !stVideoPlaying)
		var active = {}, open = {}
		if (!away) {
			if (focused) active[focused] = true
			for (var c = 0; c < clients.length; c++) {
				open[clients[c].cls] = true
				if (visibleWs[clients[c].ws]) active[clients[c].cls] = true
			}
		}
		for (var p = 0; p < players.length; p++) {
			var base = players[p].split(".")[0]
			if (!base || base === "playerctld") continue
			var key = base
			for (var k = 0; k < clients.length; k++) {
				var lc = clients[k].cls.toLowerCase()
				if (lc && (lc === base || lc.indexOf(base) >= 0 || base.indexOf(lc) >= 0)) { key = clients[k].cls; break }
			}
			active[key] = true
			open[key] = true
		}
		var any = !away
		for (var a in open) { any = true; break }
		if (!any) return
		var day = stDay()
		for (var x in active) day.apps[x] = (day.apps[x] || 0) + dt
		for (var y in open) day.open[y] = (day.open[y] || 0) + dt
		if (!away) day.hours[new Date().getHours()] += dt
		stDataChanged()
	}
	function stLoad() {
		if (stLoaded) return
		try {
			var t = stFile.text()
			if (t && t.trim().length > 0) stData = JSON.parse(t)
		} catch (e) { console.warn("screentime: could not parse file", e) }
		stLoaded = true
	}
	function stSave() {
		if (!stLoaded) return
		var keys = Object.keys(stData).sort()
		while (keys.length > 35) delete stData[keys.shift()]
		stFile.setText(JSON.stringify(stData))
	}

	// ── Jarvis ──
	function toggleJarvis() {
		var open = !jarvisVisible
		closeSidePanels()
		jarvisVisible = open
	}
	function toggleJarvisTimeline() {
		var open = !jarvisTimelineVisible
		closeSidePanels()
		jarvisTimelineVisible = open
	}
	function jarvisRefresh() {
		if (jarvisProc.running) return
		jarvisBusy = true
		jarvisProc.running = true
	}
	function jarvisIngest(text) {
		jarvisBusy = false
		var j
		try { j = JSON.parse(text) } catch (e) { jarvisOnline = false; jarvisError = "no answer from jarvis.sh"; return }
		if (j.offline) { jarvisOnline = false; jarvisError = j.error || "offline"; return }
		jarvisOnline = true
		jarvisError = ""
		jarvisData = j
		jarvisSyncedAt = Date.now()
		var seen = jarvisSeen, r = j.reminders || [], pend = {}, now = Date.now()
		for (var i = 0; i < r.length; i++) {
			var x = r[i]
			if (x.acked || seen[x.id]) continue
			if (!x.due) {
				var t = Date.parse(x.at)
				if (!isNaN(t)) pend[x.id] = { at: t, text: x.text, critical: !!x.critical }
				continue
			}
			// fired and waiting for /ack (critical): alert once
			seen[x.id] = true
			if (jarvisPrimed && jarvisAlerts) jarvisNotify(x.text, !!x.critical)
		}
		// keep reminders we were waiting for that just fired and dropped out of the list
		for (var k in jarvisPending)
			if (!pend[k] && !seen[k] && jarvisPending[k].at <= now && now - jarvisPending[k].at < 600000) pend[k] = jarvisPending[k]
		jarvisPending = pend
		jarvisSeen = seen
		jarvisPrimed = true
		jarvisAlertCheck()
	}
	function jarvisNotify(text, critical) {
		if (jarvisFeedOk) return            // the feed already covers reminders
		Quickshell.execDetached(["notify-send", "-a", "Jarvis", "-u", critical ? "critical" : "normal",
			critical ? "Critical reminder" : "Reminder", text])
	}
	// called every 20 s: alert reminders whose time has come (same moment Telegram gets them)
	function jarvisAlertCheck() {
		var now = Date.now(), p = jarvisPending, seen = jarvisSeen, changed = false
		for (var id in p) {
			if (p[id].at > now) continue
			if (!seen[id]) {
				seen[id] = true
				if (jarvisAlerts && now - p[id].at < 600000) jarvisNotify(p[id].text, p[id].critical)
			}
			delete p[id]
			changed = true
		}
		if (changed) { jarvisSeen = seen; jarvisPending = p; jarvisAfterAct.restart() }
	}
	function jarvisEsc(s) { return ("" + s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;") }
	function jarvisFeedPoll() {
		if (jarvisFeedProc.running || !jarvisFeedCursorLoaded) return
		jarvisFeedProc.command = [jarvisScript, "feed"].concat(jarvisFeedCursor >= 0 ? [String(jarvisFeedCursor)] : [])
		jarvisFeedProc.running = true
	}
	function jarvisFeedIngest(text) {
		var j
		try { j = JSON.parse(text) } catch (e) { return }
		if (j.unsupported) { jarvisFeedOk = false; return }
		if (j.offline) return
		jarvisFeedOk = true
		var items = (j.items || []).slice().sort(function(a, b) { return a.id - b.id })
		var first = jarvisFeedCursor < 0, now = Date.now(), cur = jarvisFeedCursor
		for (var i = 0; i < items.length; i++) {
			var it = items[i]
			if (it.id <= cur) continue
			cur = Math.max(cur, it.id)
			var age = now - Date.parse(it.at)
			// only alert fresh messages: no flood after the laptop was asleep or off
			if (!first && jarvisAlerts && !(age > 600000))
				Quickshell.execDetached(["notify-send", "-a", "Jarvis",
					"-u", it.level === "critical" ? "critical" : "normal",
					jarvisEsc(it.title || "Jarvis"), jarvisEsc(("" + (it.text || "")).substring(0, 400))])
		}
		if (first && typeof j.latest === "number") cur = Math.max(cur, j.latest)
		var merged = items.slice().reverse().concat(jarvisFeed)
		var seenIds = {}, out = []
		for (var k = 0; k < merged.length && out.length < 20; k++)
			if (!seenIds[merged[k].id]) { seenIds[merged[k].id] = true; out.push(merged[k]) }
		jarvisFeed = out
		if (cur !== jarvisFeedCursor) {
			jarvisFeedCursor = cur
			saveState("jarvis-feed-cursor", String(cur))
		}
		if (items.length > 0 && !first) jarvisAfterAct.restart()   // refresh today's view too
	}
	function jarvisClearSave() {
		var ids = Object.keys(jarvisFeedHidden).filter(function(k) { return parseInt(k) > jarvisFeedClearedTo })
		saveState("jarvis-feed-cleared", jarvisFeedClearedTo + " " + ids.join(","))
	}
	function jarvisClearFeedItem(id) {
		var h = jarvisFeedHidden
		h[id] = true
		jarvisFeedHidden = h
		jarvisClearSave()
	}
	function jarvisClearFeed() {
		var top = jarvisFeedClearedTo
		for (var i = 0; i < jarvisFeed.length; i++) top = Math.max(top, jarvisFeed[i].id)
		jarvisFeedClearedTo = top
		jarvisFeedHidden = ({})
		jarvisClearSave()
	}
	function jarvisSay(m) { jarvisMsg = m; jarvisMsgTimer.restart() }
	function jarvisRun(argv, label) {
		var q = jarvisQueue.slice()
		q.push({ argv: argv, label: label })
		jarvisQueue = q
		jarvisNext()
	}
	function jarvisNext() {
		if (jarvisActProc.running || jarvisQueue.length === 0) return
		var q = jarvisQueue.slice(), job = q.shift()
		jarvisQueue = q
		jarvisActProc.label = job.label
		jarvisActProc.command = [jarvisScript].concat(job.argv)
		jarvisActProc.running = true
	}
	function jarvisPatch(fn) {
		if (!jarvisData) return
		var d = JSON.parse(JSON.stringify(jarvisData))
		fn(d)
		jarvisData = d
	}
	function jarvisToggleTask(t) {
		var done = !t.done
		jarvisPatch(function(d) { (d.tasks || []).forEach(function(x) { if (x.id === t.id) { x.done = done; if (done) x.overdue = false } }) })
		jarvisRun([done ? "done" : "undo", t.id], (done ? "Done: " : "Reopened: ") + t.title)
	}
	function jarvisAck(id) {
		jarvisPatch(function(d) { (d.reminders || []).forEach(function(x) { if (x.id === id) x.acked = true }) })
		jarvisRun(["ack", id], "Acknowledged")
	}
	function jarvisParseWhen(str) {
		var s = ("" + str).toLowerCase().trim(), now = new Date(), m
		m = s.match(/^in\s*(\d+)\s*(m|min|mins|minutes?|h|hr|hrs|hours?)$/)
		if (m) return new Date(now.getTime() + parseInt(m[1]) * (m[2].charAt(0) === "h" ? 3600000 : 60000))
		var shift = 0
		if (/^(tomorrow|tmr|tmrw)\b/.test(s)) { shift = 1; s = s.replace(/^(tomorrow|tmr|tmrw)\s*/, "") }
		if (s === "" && shift) s = "9:00"
		m = s.match(/^(?:at\s*)?(\d{1,2})(?:[:.](\d{2}))?\s*(am|pm)?$/)
		if (!m) return null
		var h = parseInt(m[1]), mi = parseInt(m[2] || "0")
		if (m[3] === "pm" && h < 12) h += 12
		if (m[3] === "am" && h === 12) h = 0
		if (h > 23 || mi > 59) return null
		var d = new Date(now.getFullYear(), now.getMonth(), now.getDate() + shift, h, mi, 0)
		if (!shift && d.getTime() < now.getTime() - 60000) d.setDate(d.getDate() + 1)   // already past → tomorrow
		return d
	}
	function jarvisIso(d) {
		function p(n) { return (n < 10 ? "0" : "") + n }
		var off = -d.getTimezoneOffset(), sign = off >= 0 ? "+" : "-"
		off = Math.abs(off)
		return d.getFullYear() + "-" + p(d.getMonth() + 1) + "-" + p(d.getDate()) + "T" + p(d.getHours()) + ":" + p(d.getMinutes())
			+ ":00" + sign + p(Math.floor(off / 60)) + ":" + p(off % 60)
	}
	function jarvisAdd(mode, text, when) {
		var dt = null, at = ""
		if (when !== "") {
			dt = jarvisParseWhen(when)
			if (!dt) { jarvisSay("error: can't read the time \"" + when + "\" — try 18:30, in 20m, tomorrow 9"); return false }
			at = jarvisIso(dt)
		}
		if (mode === "remind") {
			if (at === "") { jarvisSay("error: a reminder needs a time"); return false }
			jarvisRun(["remind", at, text], "Reminder set for " + Qt.formatDateTime(dt, "ddd HH:mm"))
		} else {
			jarvisRun(at !== "" ? ["task", text, at] : ["task", text], "Task added")
		}
		return true
	}
	function jarvisOpenDashboard() {
		Quickshell.execDetached(["bash", "-c", "u=$('" + jarvisScript + "' url); [ -n \"$u\" ] && xdg-open \"$u\""])
	}
	function setJarvisAlerts(on) {
		jarvisAlerts = on
		saveState("jarvis-alerts", on ? "on" : "off")
	}

	function toggleWorkspaceOverview() {
		overviewVisible = !overviewVisible
		if (overviewVisible) {
			launcherVisible = false; dashboardVisible = false; musicVisible = false
			recordMenuVisible = false; pomoVisible = false
			clipboardVisible = false; notifCenterVisible = false
		}
	}
	function focusWorkspace(n) {
		overviewVisible = false
		Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + n + " })"])
	}
	function focusWindow(addr, ws) {
		if (!/^0x[0-9a-fA-F]+$/.test("" + addr) || !/^[A-Za-z0-9:_-]*$/.test("" + ws)) return   // secfix
		overviewVisible = false
		// Lua-config dispatchers; the selector form is tried both ways, plus the legacy dispatcher
		Quickshell.execDetached(["bash", "-c",
			"hyprctl dispatch 'hl.dsp.focus({ workspace = " + ws + " })' >/dev/null 2>&1; " +
			"hyprctl dispatch \"hl.dsp.focus({ window = 'address:" + addr + "' })\" >/dev/null 2>&1; " +
			"hyprctl dispatch focuswindow address:" + addr + " >/dev/null 2>&1; true"])
	}
	function togglePomodoro() {
		pomoVisible = !pomoVisible
		if (pomoVisible) {
			recordMenuVisible = false
			wifiVisible = false; btVisible = false; dashboardVisible = false
		}
	}
	function pomoStartPause() {
		if (pomoRunning) {
			pomoRemaining = Math.max(0, Math.ceil((pomoEndsAt - Date.now()) / 1000))
			pomoRunning = false
		} else {
			if (pomoRemaining <= 0) pomoRemaining = pomoTotal
			pomoEndsAt = Date.now() + pomoRemaining * 1000
			pomoRunning = true
		}
	}
	function pomoReset() {
		pomoRunning = false
		pomoRemaining = pomoTotal
	}
	function pomoSkip() { pomoAdvance(false) }
	function pomoAdvance(natural) {
		var finished = pomoPhase
		if (pomoPhase === "focus") {
			if (natural) pomoSessions++
			pomoPhase = (natural && pomoSessions % pomoLongEvery === 0) ? "long" : "break"
		} else {
			pomoPhase = "focus"
		}
		pomoRemaining = pomoTotal
		if (pomoRunning) pomoEndsAt = Date.now() + pomoRemaining * 1000
		if (!natural) return
		if (finished === "focus")
			Quickshell.execDetached(["notify-send", "-a", "Pomodoro",
				pomoPhase === "long" ? "Long break" : "Break time",
				"Session " + pomoSessions + " done — fuse reset, go breathe."])
		else
			Quickshell.execDetached(["notify-send", "-a", "Pomodoro", "Back to work", "Break's over, the fuse is lit again."])
		Quickshell.execDetached(["python3", configPath + "/assets/boom.py"])
		pomoBlast = true
		pomoExploded()
	}
	function pomoAdjust(which, step) {
		if (which === "focus") pomoWorkMin = Math.max(1, Math.min(180, pomoWorkMin + step))
		else if (which === "long") pomoLongMin = Math.max(1, Math.min(120, pomoLongMin + step))
		else if (which === "every") pomoLongEvery = Math.max(2, Math.min(8, pomoLongEvery + step))
		else pomoBreakMin = Math.max(1, Math.min(60, pomoBreakMin + step))
		var cur = pomoPhase === "focus" ? "focus" : pomoPhase
		if (!pomoRunning && cur === which) pomoRemaining = pomoTotal
		saveState("pomodoro", pomoWorkMin + " " + pomoBreakMin + " " + pomoLongMin + " " + pomoLongEvery)
	}

	// ── Notification helpers ──────────────────────────────────────────────
	function addNotification(nid, app, title, body) {
		if (dndEnabled) return
		var dur = Math.max(5000, Math.min(30000, body.length * 80 + 3000))
		var current = notifications.slice()
		if (current.length >= 3) current.shift()
		current.push({ nid: nid, app: app, title: title, body: body, duration: dur })
		notifications = current
		var hist = notificationHistory.slice()
		hist.unshift({ nid: nid, app: app, title: title, body: body, time: new Date() })
		if (hist.length > 50) hist.pop()
		notificationHistory = hist
	}
	function clearNotifHistory() { notificationHistory = [] }
	function removeNotification(nid) {
		var current = notifications.slice()
		for (var i = 0; i < current.length; i++) {
			if (current[i].nid === nid) { current.splice(i, 1); notifications = current; return }
		}
	}

	// ── Bluetooth helpers ─────────────────────────────────────────────────
	function refreshBluetooth() {
		root.btPairedDevices = []; root.btAvailableDevices = []
		root.btScanning = false; root.btConnectingMAC = ""
		if (!btStatusProc.running) btStatusProc.running = true
	}
	function connectBt(mac) {
		if (!/^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$/.test("" + mac)) return   // secfix
		root.btConnectingMAC = mac
		btActionProc.command = ["bash", "-c",
			"(echo 'trust " + mac + "'; echo 'connect " + mac + "'; sleep 2; echo 'quit') | bluetoothctl 2>/dev/null"]
		btActionProc.running = true
	}
	function disconnectBt(mac) {
		if (!/^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$/.test("" + mac)) return   // secfix
		btActionProc.command = ["bash", "-c", "echo -e 'disconnect " + mac + "\\nquit' | bluetoothctl 2>/dev/null"]
		btActionProc.running = true
	}
	function pairBt(mac) {
		if (!/^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$/.test("" + mac)) return   // secfix
		root.btConnectingMAC = mac
		btActionProc.command = ["bash", "-c",
			"echo -e 'pair " + mac + "\\nquit' | bluetoothctl 2>/dev/null; sleep 2; " +
			"echo -e 'trust " + mac + "\\nquit' | bluetoothctl 2>/dev/null; sleep 1; " +
			"echo -e 'connect " + mac + "\\nquit' | bluetoothctl 2>/dev/null"]
		btActionProc.running = true
	}
	function forgetBt(mac) {
		if (!/^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$/.test("" + mac)) return   // secfix
		btActionProc.command = ["bash", "-c", "echo -e 'remove " + mac + "\\nquit' | bluetoothctl 2>/dev/null"]
		btActionProc.running = true
	}

	// ── Wifi helpers ──────────────────────────────────────────────────────
	function refreshWifi() {
		root.wifiNetworks = []; root.wifiScanning = true
		if (!wifiStatusProc.running)  wifiStatusProc.running  = true
		if (!wifiCurrentProc.running) wifiCurrentProc.running = true
		if (!wifiScanProc.running)    wifiScanProc.running    = true
	}

	// ── State persistence ─────────────────────────────────────────────────
	function saveState(key, value) {
		if (!/^[A-Za-z0-9._-]+$/.test("" + key)) return   // secfix
		saveStateProc.command = ["bash", "-c", 'mkdir -p "$1" && printf "%s\n" "$3" > "$1/$2"',
			"_", statePath, key, "" + value]
		saveStateProc.running = true
	}
	function loadState(key, callback) {
		loadStateProc.stateKey = key
		loadStateProc.callback = callback
		loadStateProc.command  = ["cat", statePath + "/" + key]
		loadStateProc.running  = true
	}

	// ── App launching ─────────────────────────────────────────────────────
	function launchApp(app) {
		var cmd = app.exec
		launchProc.command = ["bash", "-c", "nohup " + cmd + " >/dev/null 2>&1 & disown"]
		launchProc.running = true
		var usage = appUsage; var updated = {}
		for (var key in usage) updated[key] = usage[key]
		updated[app.name] = (updated[app.name] || 0) + 1
		appUsage = updated
		saveUsageProc.command = ["bash", "-c",
			"echo '" + JSON.stringify(updated) + "' > '" + root.configPath + "/app_usage.json'"]
		saveUsageProc.running = true
		root.launcherVisible = false
	}

	// ── Wallpaper application (swww + blur only, no wal) ─────────────────
	function applyWallpaper(wallpaper) {
		root.currentWallpaper = wallpaper.path
		root.walApplying = true
		applyWallProc.command = ["bash", "-c",   // secfix: path passed as $1
			'ln -sf -- "$1" "$2/current" && awww img "$1" --transition-type any --transition-duration 2',
			"_", wallpaper.path, root.wallpaperPath]
		applyWallProc.running = true
	}

	function loadWallpapers() {
		root.wallpaperList = []; root.wallsLoaded = false; root.thumbsReady = false
		if (!wallpaperListProc.running) wallpaperListProc.running = true
	}

	// ── Component init ────────────────────────────────────────────────────
	Component.onCompleted: {
		initStateDir.running = true
		if (Hyprland.focusedMonitor) {
			for (var i = 0; i < Quickshell.screens.length; i++) {
				if (Quickshell.screens[i].name === Hyprland.focusedMonitor.name) {
					root.focusedScreen = Quickshell.screens[i]; break
				}
			}
		}
	}
	Connections {
		target: UIState
		function onNotificationAdded(nid, app, title, body) {
			var hist = root.notificationHistory.slice()
			hist.unshift({ nid: nid, app: app, title: title, body: body, time: new Date() })
			if (hist.length > 50) hist.pop()
			root.notificationHistory = hist
		}
	}

	// ── Processes ─────────────────────────────────────────────────────────
	Process {
		id: initStateDir
		command: ["mkdir", "-p", root.statePath]
		onExited: {
			appListProc.running  = true
			loadUsageProc.running = true
			currentWallProc.running = true
			thumbDirProc.running = true
			loadGifIndexProc.running = true
			loadThemeProc.running = true
			nightCheckProc.running = true
			loadPomoProc.running = true
			loadEqProc.running = true
			loadPrevProc.running = true


		}
	}
	Process {
		id: loadGifIndexProc
		command: ["bash", "-c", "cat '" + root.statePath + "/gif-index' 2>/dev/null || echo '0'"]
		stdout: SplitParser {
			onRead: data => {
				var idx = parseInt(data.trim())
				root.savedGifIndex = isNaN(idx) ? 0 : idx
			}
		}
	}
	Process { id: saveStateProc }
	Process {
		id: loadStateProc
		property string stateKey: ""
		property var callback: null
		stdout: SplitParser {
			onRead: data => { if (loadStateProc.callback) loadStateProc.callback(data.trim()) }
		}
	}
	Process { id: launchProc }
	Process { id: saveUsageProc }

	Process {
		id: applyWallProc
		onExited: {
			if (!walStepBlur.running) walStepBlur.running = true
		}
	}
	Process {
		id: walStepBlur
		command: {
			var wp = root.currentWallpaper   // secfix: no shell
			return ["convert", wp + (wp.endsWith(".gif") ? "[0]" : ""), "-resize", "1920x", "-blur", "0x8", "-quality", "85",
				root.wallpaperPath + "/.current-blurred.jpg"]
		}
		onExited: root.walApplying = false
	}

	Process {
		id: currentWallProc
		command: ["bash", "-c", "readlink -f '" + root.wallpaperPath + "/current' 2>/dev/null || echo ''"]
		stdout: SplitParser { onRead: data => root.currentWallpaper = data.trim() }
	}
	Process {
		id: loadUsageProc
		command: ["bash", "-c", "cat '" + root.configPath + "/app_usage.json' 2>/dev/null || echo '{}'"]
		stdout: SplitParser {
			splitMarker: ""
			onRead: data => {
				try { root.appUsage = JSON.parse(data.trim()) } catch(e) { root.appUsage = {} }
			}
		}
	}

	Process {
		id: thumbDirProc
		command: ["mkdir", "-p", root.cachePath + "/wallpaper-thumbs"]
		onExited: root.loadWallpapers()
	}
	Process {
		id: wallpaperListProc
		command: ["bash", "-c",
			"find '" + root.wallpaperPath + "' -maxdepth 1 -type f " +
			"\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.png' -o -iname '*.webp' \\) " +
			"! -name '.*' 2>/dev/null | sort"]
		stdout: SplitParser {
			onRead: data => {
				var path = data.trim()
				if (path.length === 0) return
				var parts = path.split("/"); var name = parts[parts.length - 1]
				var current = root.wallpaperList.slice()
				current.push({ name: name, path: path })
				root.wallpaperList = current
			}
		}
		onExited: {
			root.wallsLoaded = true
			if (!thumbGenProc.running) thumbGenProc.running = true
		}
	}
	Process {
		id: thumbGenProc
		command: ["bash", "-c",
			"THUMB_DIR='" + root.cachePath + "/wallpaper-thumbs' && " +
			"WALL_DIR='" + root.wallpaperPath + "' && cd \"$THUMB_DIR\" && " +
			"find \"$WALL_DIR\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' " +
			"-o -iname '*.gif' -o -iname '*.png' -o -iname '*.webp' \\) ! -name '.*' 2>/dev/null | " +
			"while IFS= read -r f; do " +
			"  hash=$(echo -n \"$f\" | md5sum | cut -d' ' -f1); " +
			"  thumb=\"$THUMB_DIR/${hash}.jpg\"; " +
			"  if [ ! -f \"$thumb\" ] || [ \"$f\" -nt \"$thumb\" ]; then " +
			"    if command -v vipsthumbnail >/dev/null 2>&1; then " +
			"      case \"$f\" in " +
			"        *.gif) convert \"${f}[0]\" -thumbnail 180x120^ -gravity center -extent 180x120 -quality 85 \"$thumb\" 2>/dev/null ;; " +
			"        *) vipsthumbnail \"$f\" -s 180x120 -o \"$thumb\" 2>/dev/null || convert \"$f\" -thumbnail 180x120^ -gravity center -extent 180x120 -quality 85 \"$thumb\" 2>/dev/null ;; " +
			"      esac; " +
			"    else " +
			"      case \"$f\" in " +
			"        *.gif) convert \"${f}[0]\" -thumbnail 180x120^ -gravity center -extent 180x120 -quality 85 \"$thumb\" 2>/dev/null ;; " +
			"        *) convert \"$f\" -thumbnail 180x120^ -gravity center -extent 180x120 -quality 85 \"$thumb\" 2>/dev/null ;; " +
			"      esac; " +
			"    fi; " +
			"  fi; " +
			"done"
		]
		onExited: {
			root.thumbsReady = true
			if (!hashAllProc.running) hashAllProc.running = true
		}
	}
	Process {
		id: hashAllProc
		command: ["bash", "-c",
			"for f in '" + root.wallpaperPath + "'/*; do " +
			"[ -f \"$f\" ] && echo \"$f|$(echo -n \"$f\" | md5sum | cut -d' ' -f1)\"; done"]
		stdout: SplitParser {
			onRead: data => {
				var parts = data.trim().split("|")
				if (parts.length === 2 && parts[0] && parts[1]) {
					var updated = root.wallpaperHashes
					updated[parts[0]] = parts[1]
					root.wallpaperHashes = updated
					root.wallpaperHashesChanged()
				}
			}
		}
	}

	Process {
		id: appListProc
		command: ["bash", "-c",
			"IFS=: read -ra dirs <<< \"$XDG_DATA_DIRS\"; " +
			"dirs+=(\"$HOME/.local/share\"); " +
			"for dir in \"${dirs[@]}\"; do " +
			"  for f in \"$dir/applications\"/*.desktop; do " +
			"    [ -f \"$f\" ] || continue; " +
			"    grep -qi '^NoDisplay=true' \"$f\" && continue; " +
			"    grep -qi '^Hidden=true' \"$f\" && continue; " +
			"    name=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-); " +
			"    exec=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2- | sed 's/ %[fFuUdDnNickvm]//g'); " +
			"    icon=$(grep -m1 '^Icon=' \"$f\" | cut -d= -f2-); " +
			"    [ -z \"$name\" ] && continue; " +
			"    [ -z \"$exec\" ] && continue; " +
			"    printf '%s\\t%s\\t%s\\n' \"$name\" \"$exec\" \"$icon\"; " +
			"  done; " +
			"done | sort -f -t$'\\t' -k1,1 | awk -F'\\t' '!seen[$1]++'"]
		stdout: SplitParser {
			onRead: data => {
				var line = data.trim()
				if (line.length === 0) return
				var parts = line.split("\t")
				if (parts.length < 2) return
				var current = root.appList.slice()
				current.push({ name: parts[0], exec: parts[1], icon: parts.length > 2 ? parts[2] : "" })
				root.appList = current
			}
		}
	}

	// ── Theme / night light / recorder state ───────────────────────────
	Process {
		id: loadThemeNameProc
		running: true
		command: ["bash", "-c", "cat '" + root.statePath + "/theme-name' 2>/dev/null || echo mocha"]
		stdout: SplitParser {
			onRead: data => { var k = data.trim(); if (root.palettes[k]) root.themeName = k }
		}
	}
	Process {
		id: loadThemeProc
		command: ["bash", "-c", "cat '" + root.statePath + "/theme-mode' 2>/dev/null || echo dark"]
		stdout: SplitParser {
			onRead: data => {
				root.lightMode = data.trim() === "light"
				Quickshell.execDetached([root.themeScript, root.lightMode ? "light" : "dark"])
			}
		}
	}
	Process {
		id: nightCheckProc
		command: [root.nightScript, "status"]
		stdout: SplitParser {
			onRead: data => {
				var p = data.trim().split(" ")
				root.nightLight = p[0] === "on"
				var t = parseInt(p[1])
				if (!isNaN(t) && !nightTempApply.running) root.nightTemp = t
			}
		}
	}
	Timer { id: nightRecheck; interval: 1500; onTriggered: if (!nightCheckProc.running) nightCheckProc.running = true }
	Timer {
		id: nightTempApply
		interval: 400
		onTriggered: Quickshell.execDetached([root.nightScript, "set", "" + root.nightTemp])
	}
	Timer {
		interval: 5000; repeat: true; running: root.dashboardVisible
		onTriggered: if (!nightCheckProc.running) nightCheckProc.running = true
	}

	// ── Equalizer state ──────────────────────────────────────────────
	Timer {
		id: eqApply
		interval: 150
		onTriggered: {
			if (root.eqEnabled) Quickshell.execDetached([root.eqScript, "set"].concat(root.eqArgs()))
			root.eqSave()
		}
	}
	Process {
		id: loadEqProc
		command: ["bash", "-c", "cat '" + root.statePath + "/eq' 2>/dev/null || echo 'off Flat 0 0 0 0 0 0 0 0 0 0'"]
		stdout: SplitParser {
			onRead: data => {
				var p = data.trim().split(" ")
				if (p.length < 12) return
				var g = []
				for (var i = 2; i < 12; i++) g.push(parseFloat(p[i]) || 0)
				root.eqGains = g
				root.eqPreset = p[1]
				root.eqEnabled = p[0] === "on"
				if (root.eqEnabled) Quickshell.execDetached([root.eqScript, "on"].concat(root.eqArgs()))
			}
		}
	}
	Process {
		id: loadPrevProc
		command: ["bash", "-c", "cat '" + root.statePath + "/overview-previews' 2>/dev/null || echo on"]
		stdout: SplitParser { onRead: data => root.overviewPreviews = data.trim() !== "off" }
	}

	// ── Screen time tracking ─────────────────────────────────────────
	Process {
		id: stMkdir
		running: true
		command: ["mkdir", "-p", root.homePath + "/.local/share/quickshell"]
	}
	FileView {
		id: stFile
		path: root.homePath + "/.local/share/quickshell/screentime.json"
		onLoaded: root.stLoad()
		onLoadFailed: root.stLoaded = true
	}
	Process {
		id: stProc
		command: [root.homePath + "/.config/scripts/screentime-poll.sh"]
		stdout: StdioCollector { onStreamFinished: root.stTick(this.text) }
	}
	Timer {
		interval: 5000; running: true; repeat: true
		onTriggered: if (!stProc.running) stProc.running = true
	}
	Timer {
		interval: 60000; running: true; repeat: true
		onTriggered: root.stSave()
	}
	Loader { id: stIdleLoader; source: "components/StIdle.qml" }

	Connections {
		target: Hyprland
		function onRawEvent(event) {
			var n = event.name
			// a config reload drops the blur rule — put it back (not in a loop)
			if (n === "configreloaded" && root.barOpacity === "blur" && Date.now() - root.barBlurAt > 5000) root.applyBarBlur()
		}
	}

	// ── Jarvis ──────────────────────────────────────────────────────
	Process {
		id: jarvisProc
		command: [root.jarvisScript, "today"]
		stdout: StdioCollector { onStreamFinished: root.jarvisIngest(this.text) }
		onExited: root.jarvisBusy = false
	}
	Process {
		id: jarvisActProc
		property string label: ""
		stdout: StdioCollector {
			onStreamFinished: {
				var r = this.text.trim()
				root.jarvisSay(r === "ok" ? jarvisActProc.label : (r.indexOf("error") === 0 ? r : "error: " + (r || "no answer")))
			}
		}
		onExited: { root.jarvisNext(); jarvisAfterAct.restart() }
	}
	Timer {
		interval: 20000; running: true; repeat: true
		onTriggered: root.jarvisAlertCheck()
	}
	Process {
		id: jarvisFeedProc
		stdout: StdioCollector { onStreamFinished: root.jarvisFeedIngest(this.text) }
	}
	Process {
		id: loadJarvisCursorProc
		running: true
		command: ["bash", "-c", "cat '" + root.statePath + "/jarvis-feed-cursor' 2>/dev/null || echo -1"]
		stdout: SplitParser {
			onRead: data => {
				var n = parseInt(data.trim())
				root.jarvisFeedCursor = isNaN(n) ? -1 : n
				root.jarvisFeedCursorLoaded = true
				root.jarvisFeedPoll()
			}
		}
	}
	Timer {
		// feed poll: Telegram-like latency (~30 s)
		interval: 30000; running: true; repeat: true
		onTriggered: root.jarvisFeedPoll()
	}
	Process {
		id: loadJarvisClearedProc
		running: true
		command: ["bash", "-c", "cat '" + root.statePath + "/jarvis-feed-cleared' 2>/dev/null || echo 0"]
		stdout: SplitParser {
			onRead: data => {
				var p = data.trim().split(" ")
				root.jarvisFeedClearedTo = parseInt(p[0]) || 0
				var h = {}
				if (p[1]) p[1].split(",").forEach(function(x) { var n = parseInt(x); if (!isNaN(n)) h[n] = true })
				root.jarvisFeedHidden = h
			}
		}
	}
	Timer { id: jarvisAfterAct; interval: 500; onTriggered: root.jarvisRefresh() }
	Timer { id: jarvisMsgTimer; interval: 5000; onTriggered: root.jarvisMsg = "" }
	Timer {
		interval: root.jarvisVisible ? 20000 : 60000
		running: root.jarvisEnabled; repeat: true; triggeredOnStart: true
		onTriggered: root.jarvisRefresh()
	}
	Process {
		id: loadJarvisAlertsProc
		running: true
		command: ["bash", "-c", "cat '" + root.statePath + "/jarvis-alerts' 2>/dev/null || echo off"]
		stdout: SplitParser { onRead: data => root.jarvisAlerts = data.trim() === "on" }
	}

	// ── Bar state ─────────────────────────────────────────────────────
	Timer { id: barHideTimer; interval: 700; onTriggered: root.barPeek = false }
	Process {
		id: loadBarProc
		running: true
		command: ["bash", "-c", "cat '" + root.statePath + "/bar' 2>/dev/null || echo 'bottom shown'"]
		stdout: SplitParser {
			onRead: data => {
				var p = data.trim().split(" ")
				if (p.indexOf("float") >= 0) root.barFloating = true
				if (["top", "bottom"].indexOf(p[0]) >= 0) root.barPosition = p[0]
				else if (p[0] === "left" || p[0] === "right") root.barPosition = "bottom"
				if (["default", "i3", "enjoy"].indexOf(p[2]) >= 0) root.barStyle = p[2]
				if (["opaque", "transparent", "blur"].indexOf(p[3]) >= 0) root.barOpacity = p[3]
				if (["shown", "auto", "hidden"].indexOf(p[1]) >= 0) root.barMode = p[1]
			}
		}
	}

	// ── Pomodoro clock ────────────────────────────────────────────────
	Timer {
		interval: 250
		repeat: true
		running: root.pomoRunning
		onTriggered: {
			var r = Math.ceil((root.pomoEndsAt - Date.now()) / 1000)
			if (r <= 0) { root.pomoRemaining = 0; root.pomoAdvance(true) }
			else root.pomoRemaining = r
		}
	}
	Process {
		id: loadPomoProc
		command: ["bash", "-c", "cat '" + root.statePath + "/pomodoro' 2>/dev/null || echo '30 5 15 3'"]
		stdout: SplitParser {
			onRead: data => {
				var p = data.trim().split(" ").map(function(x) { return parseInt(x) })
				if (p[0] > 0) root.pomoWorkMin = p[0]
				if (p[1] > 0) root.pomoBreakMin = p[1]
				if (p[2] > 0) root.pomoLongMin = p[2]
				if (p[3] > 0) root.pomoLongEvery = p[3]
				// untouched old defaults (25/5/15, no 4th field) → the new 30-minute default
				if (p.length < 4 && p[0] === 25 && p[1] === 5 && p[2] === 15) root.pomoWorkMin = 30
				if (!root.pomoRunning) root.pomoRemaining = root.pomoTotal
			}
		}
	}
	Timer {
		id: recLaunchTimer
		interval: 350
		repeat: false
		property string mode: "full"
		property string arg: ""
		onTriggered: {
			var cmd = [root.recordScript, recLaunchTimer.mode]
			if (recLaunchTimer.arg !== "") cmd.push(recLaunchTimer.arg)
			Quickshell.execDetached(cmd)
		}
	}
	Process {
		id: recPollProc
		command: ["bash", "-c", "pgrep -x wf-recorder || pgrep -f 'gpu-screen-recorder(-wrapped)? -w'"]
		onExited: (code, status) => {
			var on = code === 0
			if (on && !root.recording) root.recStartedAt = Date.now()
			root.recording = on
		}
	}
	Timer {
		interval: 1000; running: true; repeat: true; triggeredOnStart: true
		onTriggered: {
			if (!recPollProc.running) recPollProc.running = true
			if (root.recording) {
				var t = Math.max(0, Math.floor((Date.now() - root.recStartedAt) / 1000))
				var h = Math.floor(t / 3600), m = Math.floor((t % 3600) / 60), sec = t % 60
				function p2(n) { return n < 10 ? "0" + n : "" + n }
				root.recElapsedText = (h > 0 ? h + ":" : "") + p2(m) + ":" + p2(sec)
			} else {
				root.recElapsedText = "00:00"
			}
		}
	}

	// ── Ethernet ──────────────────────────────────────────────────────────
	Process {
		id: ethProc
		command: ["bash", "-c",
			"result=$(nmcli -t -f device,type,state dev 2>/dev/null | grep ':ethernet:connected$' | head -1 | cut -d: -f1); " +
			"if [ -n \"$result\" ]; then echo \"1|$result\"; else echo \"0|\"; fi"]
		stdout: SplitParser {
			onRead: data => {
				var parts = data.trim().split("|")
				root.ethConnected = parts[0] === "1"
				root.ethDevice = parts.length > 1 ? parts[1] : ""
			}
		}
	}
	Timer {
		interval: 5000; running: true; repeat: true; triggeredOnStart: true
		onTriggered: { if (!ethProc.running) ethProc.running = true }
	}

	// ── Wifi processes ────────────────────────────────────────────────────
	Process {
		id: wifiStatusProc
		command: ["bash", "-c", "nmcli radio wifi 2>/dev/null || echo 'disabled'"]
		stdout: SplitParser { onRead: data => root.wifiEnabled = data.trim() === "enabled" }
	}
	Process {
		id: wifiCurrentProc
		command: ["bash", "-c", "nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes' | head -1"]
		stdout: SplitParser {
			onRead: data => {
				var parts = data.trim().split(":")
				if (parts.length >= 3) {
					root.wifiCurrentSSID = parts[1]; root.wifiSignal = parseInt(parts[2]) || 0
				} else { root.wifiCurrentSSID = ""; root.wifiSignal = 0 }
			}
		}
	}
	Process {
		id: wifiScanProc
		command: ["bash", "-c",
			"nmcli -t -f ssid,signal,security dev wifi list --rescan yes 2>/dev/null | head -20"]
		stdout: SplitParser {
			onRead: data => {
				var line = data.trim(); if (line.length === 0) return
				var parts = line.split(":"); if (parts.length < 2) return
				var ssid = parts[0]; if (ssid === "" || ssid === root.wifiCurrentSSID) return
				var signal = parseInt(parts[1]) || 0
				var security = parts.length >= 3 ? parts[2] : ""
				var current = root.wifiNetworks.slice()
				for (var i = 0; i < current.length; i++) { if (current[i].ssid === ssid) return }
				current.push({ ssid: ssid, signal: signal, security: security })
				root.wifiNetworks = current
			}
		}
		onExited: root.wifiScanning = false
	}
	Process {
		id: wifiToggleProc
		command: ["bash", "-c", root.wifiEnabled ? "nmcli radio wifi off" : "nmcli radio wifi on"]
		onExited: {
			if (!wifiStatusProc.running) wifiStatusProc.running = true
			if (!root.wifiEnabled) wifiScanDelayTimer.start()
		}
	}
	Timer {
		id: wifiScanDelayTimer; interval: 2000; repeat: false
		onTriggered: refreshWifi()
	}
	Process {
		id: wifiConnectProc
		property string ssid: ""
		property string password: ""
		command: {
			if (password !== "")
				return ["nmcli", "dev", "wifi", "connect", ssid, "password", password]   // secfix: no shell
			else
				return ["nmcli", "dev", "wifi", "connect", ssid]
		}
		onExited: {
			root.wifiConnecting = false; root.wifiPasswordSSID = ""
			if (!wifiCurrentProc.running) wifiCurrentProc.running = true
		}
	}
	Process {
		id: wifiDisconnectProc
		command: ["bash", "-c",
			"nmcli dev disconnect wlan0 2>/dev/null; nmcli dev disconnect wlp0s20f3 2>/dev/null; " +
			"nmcli dev disconnect $(nmcli -t -f device,type dev | grep ':wifi$' | cut -d: -f1 | head -1) 2>/dev/null"]
		onExited: { root.wifiCurrentSSID = ""; root.wifiSignal = 0 }
	}

	// ── Bluetooth processes ───────────────────────────────────────────────
	Process {
		id: btStatusProc
		command: ["bash", "-c",
			"echo -e 'show\\nquit' | bluetoothctl 2>/dev/null | grep -q 'Powered: yes' && echo 'true' || echo 'false'"]
		stdout: SplitParser { onRead: data => root.btEnabled = data.trim() === "true" }
		onExited: { if (root.btEnabled && !btDevicesProc.running) btDevicesProc.running = true }
	}
	Process {
		id: btToggleOnProc
		command: ["bash", "-c", "echo -e 'power on\\nquit' | bluetoothctl 2>/dev/null"]
		onExited: btToggleDelayTimer.start()
	}
	Timer { id: btToggleDelayTimer; interval: 1000; repeat: false; onTriggered: refreshBluetooth() }
	Process {
		id: btToggleOffProc
		command: ["bash", "-c", "echo -e 'power off\\nquit' | bluetoothctl 2>/dev/null"]
		onExited: { root.btEnabled = false; root.btPairedDevices = []; root.btAvailableDevices = [] }
	}
	Process {
		id: btDevicesProc
		command: ["bash", "-c",
			"echo -e 'devices\\nquit' | bluetoothctl 2>/dev/null | grep '^Device' | while read -r line; do " +
			"mac=$(echo \"$line\" | awk '{print $2}'); name=$(echo \"$line\" | cut -d' ' -f3-); " +
			"info=$(echo -e \"info $mac\\nquit\" | bluetoothctl 2>/dev/null); " +
			"paired=$(echo \"$info\" | grep -oP 'Paired: \\K\\w+'); " +
			"connected=$(echo \"$info\" | grep -oP 'Connected: \\K\\w+'); " +
			"if [ \"$paired\" = \"yes\" ]; then echo \"${mac}|${name}|${connected}\"; fi; done"]
		stdout: SplitParser {
			onRead: data => {
				var line = data.trim(); if (line.length === 0) return
				var parts = line.split("|"); if (parts.length < 3) return
				var mac = parts[0]; var name = parts[1]; var connected = parts[2] === "yes"
				var current = root.btPairedDevices.slice()
				for (var i = 0; i < current.length; i++) { if (current[i].mac === mac) return }
				current.push({ mac: mac, name: name, connected: connected })
				root.btPairedDevices = current
			}
		}
	}
	Process {
		id: btScanProc
		command: ["bash", "-c",
			"bluetoothctl scan on & SCAN_PID=$!; sleep 8; kill $SCAN_PID 2>/dev/null; " +
			"bluetoothctl devices | grep '^Device' | while read -r line; do " +
			"mac=$(echo \"$line\" | awk '{print $2}'); " +
			"name=$(echo \"$line\" | cut -d' ' -f3-); " +
			"paired=$(bluetoothctl info \"$mac\" 2>/dev/null | grep -oP 'Paired: \\K\\w+'); " +
			"[ \"$paired\" != 'yes' ] && [ -n \"$name\" ] && [ \"$name\" != \"$mac\" ] && echo \"${mac}|${name}\"; " +
			"done"]
		stdout: SplitParser {
			onRead: data => {
				var line = data.trim(); if (line.length === 0) return
				var parts = line.split("|"); if (parts.length < 2) return
				var mac = parts[0]; var name = parts[1]; if (mac.length !== 17) return
				var current = root.btAvailableDevices.slice()
				for (var j = 0; j < current.length; j++) { if (current[j].mac === mac) return }
				current.push({ mac: mac, name: name })
				root.btAvailableDevices = current
			}
		}
		onExited: root.btScanning = false
	}
	Process {
		id: btActionProc
		onExited: { root.btConnectingMAC = ""; btActionDelayTimer.start() }
	}
	Timer { id: btActionDelayTimer; interval: 1500; repeat: false; onTriggered: refreshBluetooth() }

	// ── Hyprland monitor tracking ─────────────────────────────────────────
	Connections {
		target: Hyprland
		function onRawEvent(event) {
			if (event.name === "focusedmon") {
				var parts = event.data.split(",")
				if (parts.length >= 1) {
					var monName = parts[0].trim()
					for (var i = 0; i < Quickshell.screens.length; i++) {
						if (Quickshell.screens[i].name === monName) {
							root.focusedScreen = Quickshell.screens[i]; break
						}
					}
				}
			}
		}
	}

	// ── Panels ────────────────────────────────────────────────────────────
	Variants {
		model: Quickshell.screens
		delegate: Component {
			Bar { required property var modelData; screen: modelData }
		}
	}
	Dashboard {}
	MusicPanel {}
	WifiPanel {}
	BluetoothPanel {}
	LauncherPanel {}
	CalendarPanel {}
	NotificationPopup {}
	NotifCenter {}
	ClipboardPanel {}
	ClockPanel {}
	NotesPanel {}
	RecordMenu {}
	PomodoroPanel {}
	// focus-cam: decide pause vs. finish once the pomodoro state has settled
	Timer {
		id: focusCamSettleTimer
		interval: 400
		onTriggered: {
			if (root.pomoZen || !root.focusCamAvailable) return
			var paused = root.pomoPhase === "focus" && root.pomoActive
			Quickshell.execDetached([root.focusCamScript, paused ? "pause" : "finish"])
		}
	}
	Connections {
		target: root
		function onPomoActiveChanged() {
			if (root.focusCamAvailable && !root.pomoActive && !root.pomoZen) Quickshell.execDetached([root.focusCamScript, "finish"])
		}
	}
	FileView {
		path: root.statePath + "/focuscam-facing"
		onLoaded: { var t = text().trim(); if (["front", "back", "off"].indexOf(t) >= 0) root.focusCamFacing = t }
	}
	FileView {
		path: root.statePath + "/focuscam-preview"
		watchChanges: true
		onFileChanged: reload()
		onLoaded: root.focusCamPreview = text().trim() === "on"
	}
	IpcHandler {
		target: "focuscam"
		function preview() { root.focusCamTogglePreview() }
		function front()   { root.focusCamSetFacing("front") }
		function back()    { root.focusCamSetFacing("back") }
		function off()     { root.focusCamSetFacing("off") }
	}
	PomoZen {}
	BlastOverlay {}
	WorkspaceOverview {}
	EqPanel {}
	ScreenTimePanel {}
	Loader { active: root.jarvisEnabled; source: Qt.resolvedUrl("components/JarvisPanel.qml") }
	Loader { active: root.jarvisEnabled; source: Qt.resolvedUrl("components/JarvisTimeline.qml") }
	BarMenu {}
	BarReveal {}

	// ── IPC handlers ──────────────────────────────────────────────────────
	IpcHandler { target: "notifcenter";   function toggle() { root.toggleNotifCenter() } }
	IpcHandler { target: "calendar";      function toggle() { root.toggleCalendar() } }
	IpcHandler {
		target: "launcher"
		function toggle() { root.activeTab = 0; root.toggleLauncher() }
	}
	IpcHandler { target: "dashboard";  function toggle() { root.toggleDashboard() } }
	IpcHandler { target: "music";      function toggle() { root.toggleMusic() } }
	IpcHandler {
		target: "wallpaper"
		function toggle() {
			if (!root.launcherVisible) {
				root.activeTab = 1; root.toggleLauncher()
			} else if (root.activeTab === 1) {
				root.toggleLauncher()
			} else {
				root.activeTab = 1
				if (!root.wallsLoaded) root.loadWallpapers()
			}
		}
	}
	IpcHandler {
		target: "randomwallpaper"
		function apply(path: string) {
			root.applyWallpaper({ path: path, name: path.split("/").pop() })
		}
	}
	IpcHandler { target: "wifi";      function toggle() { root.toggleWifi() } }
	IpcHandler { target: "bluetooth"; function toggle() { root.toggleBluetooth() } }
	IpcHandler { target: "clipboard"; function toggle() { root.toggleClipboard() } }
	IpcHandler {
		target: "pomozen"
		function on()     { root.pomoZenEnabled = true }
		function off()    { root.pomoZenEnabled = false }
		function toggle() { root.pomoZenEnabled = !root.pomoZenEnabled }
	}
	IpcHandler { target: "notes";      function toggle() { root.toggleNotes() } }
	IpcHandler {
		target: "record"
		function menu()   { root.toggleRecordMenu() }
		function full()   { root.startRecording("full", "") }
		function region() { root.startRecording("region", "") }
		function stop()   { root.stopRecording() }
	}
	IpcHandler {
		target: "theme"
		function toggle()          { root.toggleLightMode() }
		function set(name: string) { root.setTheme(name) }
		function next()            { root.nextTheme() }
	}
	IpcHandler { target: "nightlight"; function toggle() { root.toggleNightLight() } }
	IpcHandler {
		target: "pomodoro"
		function toggle()     { root.togglePomodoro() }
		function startPause() { root.pomoStartPause() }
		function reset()      { root.pomoReset() }
		function skip()       { root.pomoSkip() }
	}
	IpcHandler { target: "overview"; function toggle() { root.toggleWorkspaceOverview() } }
	IpcHandler { target: "eq";         function toggle() { root.toggleEq() } }
	IpcHandler { target: "screentime"; function toggle() { root.toggleScreenTime() } }
	IpcHandler {
		target: "bar"
		function toggle()                { root.toggleBar() }
		function autohide()              { root.setBarMode(root.barMode === "auto" ? "shown" : "auto") }
		function mode(m: string)         { root.setBarMode(m) }
		function position(p: string)     { root.setBarPosition(p) }
		function cycle()                 { root.cycleBarPosition() }
		function style(s: string)        { root.setBarStyle(s) }
		function nextstyle()             { root.cycleBarStyle() }
		function floating()               { root.setBarFloating(!root.barFloating) }
		function transparency(o: string) { root.setBarOpacity(o) }
		function menu()                  { root.barMenuVisible = !root.barMenuVisible }
	}
	IpcHandler {
		target: "jarvis"
		function toggle()  { root.toggleJarvis() }
		function refresh() { root.jarvisRefresh() }
		function timeline() { root.toggleJarvisTimeline() }
	}
}
