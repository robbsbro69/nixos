//@ pragma UseQApplication
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

	property bool dashboardVisible: false
	property var _ui: UIState
	property bool musicVisible: false
	property bool launcherVisible: false
	property bool wifiVisible: false
	property bool btVisible: false
	property bool calendarVisible: false
	property bool dndEnabled: false
	property bool notifCenterVisible: false
	property bool clipboardVisible: false
	property bool clockPanelVisible: false
	property bool animePanelVisible: false
	property bool moviesPanelVisible: false
	property var pfpFiles: []

	property string searchTerm: ""
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
				if (entry.name.toLowerCase().includes(searchTerm) || entry.exec.toLowerCase().includes(searchTerm)) {
					result.push(entry)
				}
			}
			source = result
		}
		var sorted = source.slice().sort(function(a, b) {
			var countA = usage[a.name] || 0
			var countB = usage[b.name] || 0
			if (countB !== countA) return countB - countA
			return a.name.localeCompare(b.name)
		})
		return sorted
	}
    	property int selectedIndex: 0
    	property int activeTab: 0
    	property string wallSearchTerm: ""
    	property var wallpaperList: []
    	property var filteredWallpapers: {
		if (wallSearchTerm === "") return wallpaperList
		var result = []
		for (var i = 0; i < wallpaperList.length; i++) {
			if (wallpaperList[i].name.toLowerCase().includes(wallSearchTerm)) {
				result.push(wallpaperList[i])
			}
		}
		return result
	}
	property int wallSelectedIndex: 0
	property string currentWallpaper: ""
	property bool wallsLoaded: false
	property bool thumbsReady: false
	property bool walApplying: false
	property var wallpaperHashes: ({})

	property bool wifiEnabled: true
	property string wifiCurrentSSID: ""
	property int wifiSignal: 0
	property var wifiNetworks: []
	property bool wifiScanning: false
	property string wifiPasswordSSID: ""
	property bool wifiConnecting: false

	property bool btEnabled: true
	property var btPairedDevices: []
	property var btAvailableDevices: []
	property bool btScanning: false
	property string btConnectingMAC: ""

	property color walBackground: "#1e1e2e"
	property color walForeground: "#cdd6f4"
	property color walColor1: "#f38ba8"
	property color walColor2: "#a6e3a1"
	property color walColor4: "#f9e2af"
	property color walColor5: "#89b4fa"
	property color walColor8: "#6c7086"
	property color walColor13: "#f5c2e7"

	property int savedGifIndex: 0
	property var focusedScreen: Quickshell.screens[0]

	function toggleLauncher() { 
		launcherVisible = !launcherVisible 
	}

	function toggleDashboard() {
		dashboardVisible = !dashboardVisible
		if (dashboardVisible) { 
			wifiVisible = false; 
			btVisible = false 
		}
    	}

	function toggleMusic() { 
		musicVisible = !musicVisible 
	}

	function toggleWifi() {
		wifiVisible = !wifiVisible
		if (wifiVisible) { 
			btVisible = false; 
			dashboardVisible = false; 
			refreshWifi() 
		}
	}

	function toggleBluetooth() {
		btVisible = !btVisible
		if (btVisible) { 
			wifiVisible = false; 
			dashboardVisible = false; 
			refreshBluetooth() 
		}
	}

	function closeAllPanels() {
		dashboardVisible = false
		musicVisible = false
		launcherVisible = false
		wifiVisible = false
		btVisible = false
		calendarVisible = false
		notifCenterVisible = false
		clockPanelVisible = false
		clipboardVisible = false
		animePanelVisible = false
		moviesPanelVisible = false
	}

	function refreshBluetooth() {
		root.btPairedDevices = []
		root.btAvailableDevices = []
		root.btScanning = false
		root.btConnectingMAC = ""
		if (!btStatusProc.running) btStatusProc.running = true
	}

	function connectBt(mac) {
		root.btConnectingMAC = mac
		btActionProc.command = ["bash", "-c", "(echo 'trust " + mac + "'; echo 'connect " + mac + "'; sleep 2; echo 'quit') | bluetoothctl 2>/dev/null"]
		btActionProc.running = true
	}

	function disconnectBt(mac) {
		btActionProc.command = ["bash", "-c", "echo -e 'disconnect " + mac + "\\nquit' | bluetoothctl 2>/dev/null"]
		btActionProc.running = true
	}

	function pairBt(mac) {
		root.btConnectingMAC = mac
		btActionProc.command = ["bash", "-c", "echo -e 'pair " + mac + "\\nquit' | bluetoothctl 2>/dev/null; sleep 2; echo -e 'trust " + mac + "\\nquit' | bluetoothctl 2>/dev/null; sleep 1; echo -e 'connect " + mac + "\\nquit' | bluetoothctl 2>/dev/null"]
		btActionProc.running = true
	}

	function forgetBt(mac) {
		btActionProc.command = ["bash", "-c", "echo -e 'remove " + mac + "\\nquit' | bluetoothctl 2>/dev/null"]
		btActionProc.running = true
	}

	function refreshWifi() {
		root.wifiNetworks = []
		root.wifiScanning = true
		if (!wifiStatusProc.running) wifiStatusProc.running = true
		if (!wifiCurrentProc.running) wifiCurrentProc.running = true
        	if (!wifiScanProc.running) wifiScanProc.running = true
	}

	function saveState(key, value) {
		saveStateProc.command = ["bash", "-c", "mkdir -p '" + statePath + "' && echo '" + value + "' > '" + statePath + "/" + key + "'"]
		saveStateProc.running = true
	}

	function loadState(key, callback) {
		loadStateProc.stateKey = key
		loadStateProc.callback = callback
        	loadStateProc.command = ["cat", statePath + "/" + key]
        	loadStateProc.running = true
	}

	function toggleCalendar() {
		calendarVisible = !calendarVisible
		if (calendarVisible) {
			dashboardVisible = false
			musicVisible = false
        		launcherVisible = false
        		wifiVisible = false
        		btVisible = false
		}
	}
	function addNotification(nid, app, title, body) {
		if (dndEnabled) return
		var dur = Math.max(5000, Math.min(30000, body.length * 80 + 3000))
		var current = notifications.slice()
		if (current.length >= 3) current.shift()
		current.push({ 
			nid: nid, 
			app: app, 
			title: title, 
			body: body, 
			duration: dur 
		})
		notifications = current

		// Also add to history
		var hist = notificationHistory.slice()
		hist.unshift({
			nid: nid,
        		app: app,
        		title: title,
        		body: body,
        		time: new Date()
    		})
		if (hist.length > 50) hist.pop()
		notificationHistory = hist
	}

	function clearNotifHistory() {
		notificationHistory = []
	}

	function removeNotification(nid) {
		var current = notifications.slice()
		for (var i = 0; i < current.length; i++) {
			if (current[i].nid === nid) {
				current.splice(i, 1)
				notifications = current
				return
			}
		}
	}

	function toggleNotifCenter() {
		notifCenterVisible = !notifCenterVisible
	}

	function toggleClockPanel() {
		clockPanelVisible = !clockPanelVisible
	}

	function toggleClipboard() {
		clipboardVisible = !clipboardVisible
	}

	function toggleAnimePanel() { 
		animePanelVisible = !animePanelVisible 
	}
	
	function toggleMoviesPanel() { 
		moviesPanelVisible = !moviesPanelVisible 
	}

	Component.onCompleted: {
		initStateDir.running = true
	}
	Connections {
		target: UIState
		function onNotificationReceived(nid, app, title, body) {
			var hist = root.notificationHistory.slice()
			hist.unshift({
				nid: nid,
            			app: app,
            			title: title,
            			body: body,
            			time: new Date()
			})
			if (hist.length > 50) hist.pop()
			root.notificationHistory = hist
		}
	}

	Process {
		id: initStateDir
		command: ["mkdir", "-p", root.statePath]
		onExited: {
			walColorsProc.running = true
            		appListProc.running = true
            		loadUsageProc.running = true
            		currentWallProc.running = true
            		thumbDirProc.running = true
            		loadGifIndexProc.running = true
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

	Process {
		id: saveStateProc
	}

	Process {
		id: loadStateProc
		property string stateKey: ""
        	property var callback: null
        	stdout: SplitParser {
			onRead: data => {
				if (loadStateProc.callback) {
					loadStateProc.callback(data.trim())
				}
			}
		}
	}

	function launchApp(app) {
		var cmd = app.exec
    		//if (cmd.startsWith("dolphin")) cmd = "dolphin --new-window"    
		launchProc.command = ["bash", "-c", "nohup " + cmd + " >/dev/null 2>&1 & disown"]
        	launchProc.running = true
        	var usage = appUsage
        	var updated = {}
        	for (var key in usage) updated[key] = usage[key]
        	updated[app.name] = (updated[app.name] || 0) + 1
        	appUsage = updated
        	saveUsageProc.command = ["bash", "-c", "echo '" + JSON.stringify(updated) + "' > '" + root.configPath + "/app_usage.json'"]
        	saveUsageProc.running = true
        	root.launcherVisible = false
	}

	function applyWallpaper(wallpaper) {
		root.currentWallpaper = wallpaper.path
        	root.walApplying = true
        	applyWallProc.command = ["bash", "-c",
			"ln -sf '" + wallpaper.path + "' '" + root.wallpaperPath + "/current' && " +
        	    	"swww img '" + wallpaper.path + "' --transition-type any --transition-duration 2 & " +
        	    	"wal -i '" + wallpaper.path + "' -n -q && " +
        	    	"sleep 0.3"
		]
		applyWallProc.running = true
	}

	function loadWallpapers() {
		root.wallpaperList = []
		root.wallsLoaded = false
		root.thumbsReady = false
		if (!wallpaperListProc.running) wallpaperListProc.running = true
	}

	Process {
		id: thumbDirProc
		command: ["mkdir", "-p", root.cachePath + "/wallpaper-thumbs"]
		onExited: root.loadWallpapers()
	}

	Process {
		id: wallpaperListProc
        	command: ["bash", "-c", "find '" + root.wallpaperPath + "' -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.png' -o -iname '*.webp' \\) ! -name '.*' 2>/dev/null | sort"]
		stdout: SplitParser {
			onRead: data => {
				var path = data.trim()
				if (path.length === 0) return
               			var parts = path.split("/")
                		var name = parts[parts.length - 1]
                		var current = root.wallpaperList.slice()
                		current.push({ 
					name: name, 
					path: path 
				})
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
            		"WALL_DIR='" + root.wallpaperPath + "' && " +
            		"cd \"$THUMB_DIR\" && " +
            		"find \"$WALL_DIR\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.png' -o -iname '*.webp' \\) ! -name '.*' 2>/dev/null | " +
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
    		command: ["bash", "-c", "for f in '" + root.wallpaperPath + "'/*; do [ -f \"$f\" ] && echo \"$f|$(echo -n \"$f\" | md5sum | cut -d' ' -f1)\"; done"]
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
		id: applyWallProc
		onExited: {
			if (!walColorsProc.running) walColorsProc.running = true
		}
	}

	Process {
		id: walColorsProc
		command: ["bash", "-c", "cat '" + root.cachePath + "/wal/colors.json' 2>/dev/null"]
		stdout: SplitParser {
			splitMarker: ""
			onRead: data => {
				try {
					var json = JSON.parse(data)
					if (json.special) {
						root.walBackground = json.special.background || root.walBackground
						root.walForeground = json.special.foreground || root.walForeground
					}
					if (json.colors) {
						root.walColor1 = json.colors.color1 || root.walColor1
						root.walColor2 = json.colors.color2 || root.walColor2
						root.walColor4 = json.colors.color4 || root.walColor4
						root.walColor5 = json.colors.color5 || root.walColor5
						root.walColor8 = json.colors.color8 || root.walColor8
						root.walColor13 = json.colors.color13 || root.walColor13
					}
				} catch(e) {}
			}
		}
		onExited: {
			if (root.walApplying) {
				if (!walStepGtk.running) walStepGtk.running = true
			}
		}
	}
	Process {
		id: walStepGtk
    	command: ["bash", "-c",
        	"ln -sf ~/.cache/wal/colors-gtk.css ~/.config/gtk-3.0/gtk.css 2>/dev/null; " +
        	"ln -sf ~/.cache/wal/colors-gtk.css ~/.config/gtk-4.0/gtk.css 2>/dev/null"
    	]
		onExited: {
			if (!walStepSwaync.running) walStepSwaync.running = true
		}
	}

	Process {
		id: walStepSwaync
		command: ["bash", "-c",
			"cp '" + root.cachePath + "/wal/colors-swaync.css' '" + root.configPath + "/../swaync/style.css' 2>/dev/null; " +
        		"echo '.notification-row { opacity: 0; min-height: 0; min-width: 0; } " +
        		".blank-window { background: transparent; }' >> '" + root.configPath + "/../swaync/style.css' 2>/dev/null; " +
        		"pkill -SIGUSR1 swaync 2>/dev/null"
		]
		onExited: {
			if (!walStepBlur.running) walStepBlur.running = true
		}
	}
	Process {
		id: walStepBlur
        	command: {
			var wp = root.currentWallpaper
			if (wp.endsWith(".gif"))
			return ["bash", "-c", "convert '" + wp + "[0]' -resize 1920x -blur 0x8 -quality 85 '" + root.wallpaperPath + "/.current-blurred.jpg' 2>/dev/null"]
			else
			return ["bash", "-c", "convert '" + wp + "' -resize 1920x -blur 0x8 -quality 85 '" + root.wallpaperPath + "/.current-blurred.jpg' 2>/dev/null"]
		}
		onExited: root.walApplying = false
	}

	Process {
		id: currentWallProc
        	command: ["bash", "-c", "readlink -f '" + root.wallpaperPath + "/current' 2>/dev/null || echo ''"]
		stdout: SplitParser { 
			onRead: data => root.currentWallpaper = data.trim() 
		}
    	}

	Process {
		id: loadUsageProc
		command: ["bash", "-c", "cat '" + root.configPath + "/app_usage.json' 2>/dev/null || echo '{}'"]
		stdout: SplitParser {
			splitMarker: ""
			onRead: data => {
				try { 
					root.appUsage = JSON.parse(data.trim()) 
				} catch(e) { 
					root.appUsage = {} 
				}
			}
		}
	}

    	Process { 
		id: saveUsageProc 
	}
	Process {
		id: focusedMonProc
		command: ["bash", "-c", "hyprctl activeworkspace -j | jq -r '.monitor'"]
		stdout: SplitParser {
			onRead: data => {
				var monName = data.trim()
				for (var i = 0; i < Quickshell.screens.length; i++) {
					if (Quickshell.screens[i].name === monName) {
						root.focusedScreen = Quickshell.screens[i]
						break
					}
				}
			}
		}
	}

	Timer {
		interval: 500
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: {
			if (!focusedMonProc.running) focusedMonProc.running = true
		}
	}
	Process { 
		id: launchProc 
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
       			"done | sort -f -t$'\\t' -k1,1 | awk -F'\\t' '!seen[$1]++'"
		]
		stdout: SplitParser {
			onRead: data => {
				var line = data.trim()
				if (line.length === 0) return
				var parts = line.split("\t")
				if (parts.length < 2) return
				var current = root.appList.slice()
				current.push({ 
					name: parts[0], 
					exec: parts[1], 
					icon: parts.length > 2 ? parts[2] : "" 
				})
				root.appList = current
			}
		}
	}

	Process {
		id: wifiStatusProc
		command: ["bash", "-c", "nmcli radio wifi 2>/dev/null || echo 'disabled'"]
		stdout: SplitParser { 
			onRead: data => root.wifiEnabled = data.trim() === "enabled" 
		}
	}

	Process {
		id: wifiCurrentProc
		command: ["bash", "-c", "nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes' | head -1"]
		stdout: SplitParser {
			onRead: data => {
				var parts = data.trim().split(":")
				if (parts.length >= 3) {
					root.wifiCurrentSSID = parts[1]
					root.wifiSignal = parseInt(parts[2]) || 0
				} else {
					root.wifiCurrentSSID = ""
					root.wifiSignal = 0
				}
			}
		}
	}

	Process {
		id: wifiScanProc
		command: ["bash", "-c", "nmcli -t -f ssid,signal,security dev wifi list --rescan yes 2>/dev/null | head -20"]
		stdout: SplitParser {
			onRead: data => {
				var line = data.trim()
				if (line.length === 0) return
				var parts = line.split(":")
				if (parts.length < 2) return
				var ssid = parts[0]
				if (ssid === "" || ssid === root.wifiCurrentSSID) return
				var signal = parseInt(parts[1]) || 0
				var security = parts.length >= 3 ? parts[2] : ""
				var current = root.wifiNetworks.slice()
				for (var i = 0; i < current.length; i++) {
					if (current[i].ssid === ssid) return
				}
				current.push({ 
					ssid: ssid, signal: signal, 
					security: security 
				})
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
		id: wifiScanDelayTimer
		interval: 2000
		repeat: false
		onTriggered: refreshWifi()
	}

	Process {
		id: wifiConnectProc
		property string ssid: ""
        	property string password: ""
        	command: {
			if (password !== "")
			return ["bash", "-c", "nmcli dev wifi connect '" + ssid + "' password '" + password + "' 2>&1"]
			else
			return ["bash", "-c", "nmcli dev wifi connect '" + ssid + "' 2>&1"]
		}
		onExited: {
			root.wifiConnecting = false
            		root.wifiPasswordSSID = ""
			if (!wifiCurrentProc.running) wifiCurrentProc.running = true
		}
	}

	Process {
		id: wifiDisconnectProc
		command: ["bash", "-c", "nmcli dev disconnect wlan0 2>/dev/null; nmcli dev disconnect wlp0s20f3 2>/dev/null; nmcli dev disconnect $(nmcli -t -f device,type dev | grep ':wifi$' | cut -d: -f1 | head -1) 2>/dev/null"]
		onExited: {
			root.wifiCurrentSSID = ""
			root.wifiSignal = 0
		}
	}

	Process {
		id: btStatusProc
		command: ["bash", "-c", "echo -e 'show\\nquit' | bluetoothctl 2>/dev/null | grep -q 'Powered: yes' && echo 'true' || echo 'false'"]
		stdout: SplitParser {
			onRead: data => root.btEnabled = data.trim() === "true"
		}
		onExited: {
			if (root.btEnabled && !btDevicesProc.running) btDevicesProc.running = true
		}
	}

	Process {
		id: btToggleOnProc
		command: ["bash", "-c", "echo -e 'power on\\nquit' | bluetoothctl 2>/dev/null"]
		onExited: btToggleDelayTimer.start()
	}

	Timer {
		id: btToggleDelayTimer
		interval: 1000
		repeat: false
		onTriggered: refreshBluetooth()
	}

	Process {
		id: btToggleOffProc
		command: ["bash", "-c", "echo -e 'power off\\nquit' | bluetoothctl 2>/dev/null"]
		onExited: {
			root.btEnabled = false
            		root.btPairedDevices = []
            		root.btAvailableDevices = []
		}
	}

	Process {
		id: btDevicesProc
        	command: ["bash", "-c", "echo -e 'devices\\nquit' | bluetoothctl 2>/dev/null | grep '^Device' | while read -r line; do mac=$(echo \"$line\" | awk '{print $2}'); name=$(echo \"$line\" | cut -d' ' -f3-); info=$(echo -e \"info $mac\\nquit\" | bluetoothctl 2>/dev/null); paired=$(echo \"$info\" | grep -oP 'Paired: \\K\\w+'); connected=$(echo \"$info\" | grep -oP 'Connected: \\K\\w+'); if [ \"$paired\" = \"yes\" ]; then echo \"${mac}|${name}|${connected}\"; fi; done"]
        	stdout: SplitParser {
            	onRead: data => {
			var line = data.trim()
                	if (line.length === 0) return
                	var parts = line.split("|")
                	if (parts.length < 3) return
                	var mac = parts[0]
                	var name = parts[1]
                	var connected = parts[2] === "yes"
                	var current = root.btPairedDevices.slice()
                	for (var i = 0; i < current.length; i++) {
				if (current[i].mac === mac) return
			}
			current.push({ 
				mac: mac, 
				name: name, 
				connected: connected 
				})
			root.btPairedDevices = current
			}
		}
	}

	Process {
		id: btScanProc
		command: ["bash", "-c", "echo -e 'scan on\\nquit' | bluetoothctl 2>/dev/null; sleep 5; echo -e 'scan off\\nquit' | bluetoothctl 2>/dev/null; sleep 1; echo -e 'devices\\nquit' | bluetoothctl 2>/dev/null | grep '^Device' | while read -r line; do mac=$(echo \"$line\" | awk '{print $2}'); name=$(echo \"$line\" | cut -d' ' -f3-); info=$(echo -e \"info $mac\\nquit\" | bluetoothctl 2>/dev/null); paired=$(echo \"$info\" | grep -oP 'Paired: \\K\\w+'); if [ \"$paired\" != \"yes\" ] && [ -n \"$name\" ] && [ \"$name\" != \"$mac\" ]; then echo \"${mac}|${name}\"; fi; done"]
		stdout: SplitParser {
		onRead: data => {
			var line = data.trim()
			if (line.length === 0) return
			var parts = line.split("|")
			if (parts.length < 2) return
			var mac = parts[0]
			var name = parts[1]
			if (mac.length !== 17) return
                	var current = root.btAvailableDevices.slice()
                	for (var j = 0; j < current.length; j++) {
				if (current[j].mac === mac) return
			}
			current.push({ 
				mac: mac, 
				name: name 
				})
			root.btAvailableDevices = current
			}
		}
		onExited: root.btScanning = false
	}

	Process {
		id: btActionProc
		onExited: {
            		root.btConnectingMAC = ""
			btActionDelayTimer.start()
		}
	}

	Timer {
		id: btActionDelayTimer
		interval: 1500
		repeat: false
		onTriggered: refreshBluetooth()
	}

	//Bar {}
	Variants {
		model: Quickshell.screens
		delegate: Component {
			Bar {
				required property var modelData
				screen: modelData
			}
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
	ClipboardPanel{}
	ClockPanel{}
	AnimePanel{}
	MoviesPanel{}



	IpcHandler {
		target: "notifcenter"
		function toggle() { 
			root.toggleNotifCenter() 
		}
	}

	IpcHandler {
		target: "calendar"
		function toggle() { 
			root.toggleCalendar() 
		}
	}
	IpcHandler {
		target: "launcher"
		function toggle() {
			root.activeTab = 0
			root.toggleLauncher()
		}
	}
	IpcHandler {
        	target: "dashboard"
		function toggle() { 
			root.toggleDashboard() 
		}
	}
	IpcHandler {
		target: "music"
		function toggle() { 
			root.toggleMusic() 
		}
	}
	IpcHandler {
		target: "wallpaper"
		function toggle() {
			if (!root.launcherVisible) {
				root.activeTab = 1
				root.toggleLauncher()
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
			root.applyWallpaper({ path: path, name: path.split("/").pop() 
			})
		}
	}
	IpcHandler {
		target: "wifi"
		function toggle() { 
			root.toggleWifi() 
		}
	}
	IpcHandler {
        	target: "bluetooth"
		function toggle() { 
			root.toggleBluetooth() 
		}
	}
	IpcHandler {
		target: "clipboard"
		function toggle() {
			root.toggleClipboard()
		}
	}
	IpcHandler {
    	target: "anime"
		function toggle() { 
			root.toggleAnimePanel() 
		}
	}
	IpcHandler {
    	target: "movies"
		function toggle() { 
			root.toggleMoviesPanel() 
		}
	}
}
