pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
	id: ui
	property bool dndEnabled: false
    	property string activeDropdown: ""
    	property var notifications: []
    	property int _nid: 0
    	signal notificationReceived(int nid, string app, string title, string body)
		signal notificationAdded(int nid, string app, string title, string body)

	function addNotification(app, title, body) {
		if (title === "" && body === "") return
		var id = _nid++
		var list = notifications.slice()
		list.unshift({ 
			id: id, 
			app: app, 
			title: title, 
			body: body, 
			time: Date.now() 
		})
		if (list.length > 50) list = list.slice(0, 50)
		notifications = list
		    notificationAdded(id, app, title, body)
		    if (!dndEnabled) {
        notificationReceived(id, app, title, body)
    }
	}

	function dismissNotif(id) {
		notifications = notifications.filter(n => n.id !== id)
	}

	function clearNotifs() {
		notifications = []
	}

	
	Process {
		id: killProc
		command: ["pkill", "-f", "notif-daemon.py"]
		running: true
		onExited: daemonProc.running = true  
	}
	
	Process {
		id: daemonProc
		running: false  
		command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/assets/notif-daemon.py"]
		stdout: SplitParser {
			onRead: data => {
				var line = data.trim()
				if (line.length === 0) return
				var parts = line.split("|")
				if (parts.length >= 3) {
					var app   = parts[1] || "Notification"
					var title = parts[2] || ""
					var body  = parts.length >= 4 ? parts[3] : ""
					ui.addNotification(app, title, body)
				}
			}
		}
		onExited: {
			console.log("notif daemon exited, restarting...")
			daemonRestartTimer.start()
		}
	}

	Timer {
		id: daemonRestartTimer
		interval: 1000
		repeat: false
		onTriggered: daemonProc.running = true
	}
}
