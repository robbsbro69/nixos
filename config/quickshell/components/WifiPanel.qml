import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// WifiPanel.qml — Wi-Fi: current connection (IP, gateway, DNS, band, speed), networks in range
// with inline password, saved networks, hidden networks, per-network settings (auto-connect,
// metered, DNS, static IP) and sharing the password (+ QR if qrencode is installed).
// All NetworkManager work goes through assets/wifi.py (arguments only, no shell strings).

PanelWindow {
	id: wp
	screen: Quickshell.screens.length > 0 ? (root.focusedScreen ?? Quickshell.screens[0]) : undefined
	visible: true
	exclusionMode: ExclusionMode.Ignore
	anchors {
		bottom: root.barPosition !== "top"
		right: true
		top: root.barPosition === "top"
	}
	margins {
		bottom: root.wifiVisible ? root.barGapV : -(implicitHeight + 20)
		right: (typeof root.popRightAt === "function" ? root.popRightAt(popC, implicitWidth, screen) : 6) + root.barInsetRight
		top: root.wifiVisible ? root.barGapV : -(implicitHeight + 20)
	}
	property real popC: -1
	Connections {
		target: root
		function onWifiVisibleChanged() {
			if (root.wifiVisible) { wp.popC = root.i3PopCenter ?? -1; wp.view = "main"; wp.refresh(false); wpFocus.start() }
			else { wp.pwFor = ""; wp.share = null; wp.hiddenOpen = false }
		}
	}
	implicitWidth: 370
	implicitHeight: card.implicitHeight
	color: "transparent"
	focusable: true
	WlrLayershell.keyboardFocus: root.wifiVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
	Behavior on margins.bottom { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
	Behavior on margins.top { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

	readonly property string script: root.configPath + "/assets/wifi.py"
	readonly property color accent: root.walColor4
	property var st: null                 // wifi.py status
	property bool scanning: false
	property string busy: ""              // "connecting to X…" etc.
	property string msg: ""
	property bool msgOk: true
	property string pwFor: ""             // network whose password box is open
	property bool showPw: false
	property bool hiddenOpen: false
	property var share: null              // { uuid, ssid, password, qr }
	property bool shareReveal: false
	property string view: "main"          // main | edit
	property var ed: null                 // details of the network being edited (+ edits)
	property string confirmForget: ""

	function refresh(rescan) {
		if (statusProc.running) return
		scanning = rescan
		statusProc.command = ["python3", script, "status"].concat(rescan ? ["rescan"] : [])
		statusProc.running = true
	}
	function act(args, busyText) {
		if (actProc.running) return
		busy = busyText || ""
		msg = ""
		actProc.command = ["python3", script].concat(args)
		actProc.running = true
	}
	function say(text, ok) { msg = text; msgOk = ok; msgTimer.restart() }
	function sigIcon(s) { return s >= 75 ? "󰤨" : s >= 50 ? "󰤥" : s >= 25 ? "󰤢" : "󰤟" }
	function joinNet(n) {
		if (n.saved && n.uuid) act(["up", n.uuid], "connecting to " + n.ssid + "…")
		else if (!n.security) act(["connect", n.ssid], "connecting to " + n.ssid + "…")
		else { pwFor = pwFor === n.ssid ? "" : n.ssid; showPw = false }
	}
	function openEdit(uuid) {
		if (!uuid || detailsProc.running) return
		detailsProc.command = ["python3", script, "details", uuid]
		detailsProc.running = true
	}
	function openShare(uuid) {
		if (!uuid) return
		if (share && share.uuid === uuid) { share = null; return }
		shareProc.command = ["python3", script, "share", uuid]
		shareProc.uuid = uuid
		shareProc.running = true
	}

	Process {
		id: statusProc
		stdout: StdioCollector {
			onStreamFinished: {
				wp.scanning = false
				try { var o = JSON.parse(this.text); if (o.ok) wp.st = o } catch (e) {}
			}
		}
	}
	Process {
		id: actProc
		stdout: StdioCollector {
			onStreamFinished: {
				wp.busy = ""
				try {
					var o = JSON.parse(this.text)
					wp.say(o.msg || (o.ok ? "done" : "failed"), !!o.ok)
					if (o.ok) { wp.pwFor = ""; wp.hiddenOpen = false; if (wp.view === "edit" && o.msg !== "saved") wp.view = "main" }
				} catch (e) { wp.say("something went wrong", false) }
				afterAct.restart()
			}
		}
	}
	Process {
		id: detailsProc
		stdout: StdioCollector {
			onStreamFinished: {
				try {
					var o = JSON.parse(this.text)
					if (!o.ok) { wp.say(o.msg || "can't open its settings", false); return }
					o.dnsMode = o.dns === "auto" ? "auto" : "custom"
					o.dnsText = o.dns === "auto" ? "" : o.dns
					o.ipMode = o.ip === "auto" ? "auto" : "static"
					o.ipText = o.ip === "auto" ? "" : o.ip
					wp.ed = o; wp.confirmForget = ""; wp.view = "edit"
				} catch (e) {}
			}
		}
	}
	Process {
		id: shareProc
		property string uuid: ""
		stdout: StdioCollector {
			onStreamFinished: {
				try {
					var o = JSON.parse(this.text)
					if (o.ok) { o.uuid = shareProc.uuid; wp.share = o; wp.shareReveal = false }
					else wp.say(o.msg || "can't read the password", false)
				} catch (e) {}
			}
		}
	}
	Timer { id: afterAct; interval: 700; onTriggered: wp.refresh(false) }
	Timer { id: msgTimer; interval: 6000; onTriggered: wp.msg = "" }
	// auto-refresh, paused while you type a password or edit (a refresh would rebuild the list)
	Timer { interval: 6000; repeat: true; running: root.wifiVisible && wp.busy === "" && wp.pwFor === "" && !wp.hiddenOpen && wp.view === "main"; onTriggered: wp.refresh(false) }
	Timer { id: forgetTimer; interval: 3000; onTriggered: wp.confirmForget = "" }

	Item {
		anchors.fill: parent
		focus: root.wifiVisible
		Keys.onPressed: function(event) {
			if (event.key === Qt.Key_Escape) {
				if (wp.view === "edit") wp.view = "main"
				else if (wp.pwFor !== "" || wp.hiddenOpen) { wp.pwFor = ""; wp.hiddenOpen = false }
				else root.wifiVisible = false
				event.accepted = true
			}
		}

		Rectangle {
			id: card
			width: parent.width
			anchors.bottom: parent.bottom
			implicitHeight: col.implicitHeight + 28
			radius: 18
			color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.95)
			border.width: 1
			border.color: Qt.rgba(wp.accent.r, wp.accent.g, wp.accent.b, 0.4)

			ColumnLayout {
				id: col
				anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
				spacing: 8

				// ── header ─────────────────────────────────────────────
				RowLayout {
					Layout.fillWidth: true
					spacing: 8
					Text { textFormat: Text.PlainText; text: wp.view === "edit" ? "󰒓" : "󰖩"; color: wp.accent; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font" }
					Text {
						textFormat: Text.PlainText
						text: wp.view === "edit" && wp.ed ? wp.ed.ssid : "Wi-Fi"
						color: root.walColor5; font.pixelSize: 15; font.bold: true; font.family: "JetBrainsMono Nerd Font"
						elide: Text.ElideRight; Layout.fillWidth: true
					}
					IconBtn { visible: wp.view === "edit"; icon: "󰁍"; onClicked: wp.view = "main" }
					IconBtn {
						visible: wp.view === "main" && wp.st && wp.st.radio
						icon: "󰑓"
						spin: wp.scanning
						onClicked: wp.refresh(true)
					}
					Switch {
						visible: wp.view === "main"
						on: !!(wp.st && wp.st.radio)
						onToggled: wp.act(["radio", on ? "off" : "on"], on ? "turning Wi-Fi off…" : "turning Wi-Fi on…")
					}
				}

				// ── Wi-Fi off ─────────────────────────────────────────
				Text {
					visible: wp.view === "main" && wp.st && !wp.st.radio
					textFormat: Text.PlainText
					text: "Wi-Fi is off. Flip the switch to turn it on."
					color: root.walColor8; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; Layout.leftMargin: 4
				}

				// ── current connection ────────────────────────────────
				Rectangle {
					id: cur
					readonly property var a: wp.st ? wp.st.active : null
					visible: wp.view === "main" && !!a
					Layout.fillWidth: true
					implicitHeight: curCol.implicitHeight + 20
					radius: 13
					color: Qt.rgba(wp.accent.r, wp.accent.g, wp.accent.b, 0.12)
					border.width: 1
					border.color: Qt.rgba(wp.accent.r, wp.accent.g, wp.accent.b, 0.4)
					ColumnLayout {
						id: curCol
						anchors { top: parent.top; left: parent.left; right: parent.right; margins: 10 }
						spacing: 7
						RowLayout {
							Layout.fillWidth: true
							spacing: 7
							Text { textFormat: Text.PlainText; text: cur.a ? wp.sigIcon(cur.a.signal) : ""; color: wp.accent; font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font" }
							Text { textFormat: Text.PlainText; text: cur.a ? cur.a.ssid : ""; color: root.walForeground; font.pixelSize: 12; font.bold: true
								font.family: "JetBrainsMono Nerd Font"; elide: Text.ElideRight; Layout.fillWidth: true }
							Chip { label: cur.a ? cur.a.signal + "%" : "" }
							Chip { visible: !!(cur.a && cur.a.band); label: cur.a ? cur.a.band : "" }
						}
						GridLayout {
							Layout.fillWidth: true
							columns: 2
							columnSpacing: 10
							rowSpacing: 3
							Repeater {
								model: cur.a ? [
									["IP", (cur.a.ip || "—").replace(/\/\d+$/, "")],
									["Gateway", cur.a.gateway || "—"],
									["DNS", (cur.a.dns && cur.a.dns.length ? cur.a.dns.join("  ") : "—")],
									["Speed", (cur.a.rate || "—") + (cur.a.chan ? "  ·  ch " + cur.a.chan : "")],
									["Security", cur.a.security || "open"]
								] : []
								delegate: Text {
									required property var modelData
									required property int index
									textFormat: Text.PlainText
									Layout.columnSpan: 2
									Layout.fillWidth: true
									text: modelData[0] + "   " + modelData[1]
									color: Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.75)
									font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"; elide: Text.ElideRight
								}
							}
						}
						RowLayout {
							Layout.fillWidth: true
							spacing: 5
							Btn { icon: "󰖪"; label: "Disconnect"; onClicked: wp.act(["disconnect"], "disconnecting…") }
							Btn { icon: "󰒓"; label: "Settings"; enabled: !!(cur.a && cur.a.uuid); onClicked: wp.openEdit(cur.a.uuid) }
							Btn { icon: "󰐲"; label: "Share"; enabled: !!(cur.a && cur.a.uuid); active: !!(wp.share && cur.a && wp.share.uuid === cur.a.uuid)
								onClicked: wp.openShare(cur.a.uuid) }
						}
						// share: password + QR
						ColumnLayout {
							visible: !!(wp.share && cur.a && wp.share.uuid === cur.a.uuid)
							Layout.fillWidth: true
							spacing: 6
							RowLayout {
								Layout.fillWidth: true
								spacing: 6
								Text { textFormat: Text.PlainText; text: "Password"; color: root.walColor8; font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font" }
								Text {
									textFormat: Text.PlainText
									text: !wp.share ? "" : wp.share.password === "" ? "(open network)" : wp.shareReveal ? wp.share.password : "•".repeat(Math.min(14, wp.share.password.length))
									color: root.walForeground; font.pixelSize: 11; font.bold: true; font.family: "JetBrainsMono Nerd Font"
									elide: Text.ElideRight; Layout.fillWidth: true
								}
								IconBtn { icon: wp.shareReveal ? "󰈉" : "󰈈"; small: true; onClicked: wp.shareReveal = !wp.shareReveal }
								IconBtn { icon: "󰆏"; small: true; onClicked: { Quickshell.execDetached(["wl-copy", wp.share.password]); wp.say("password copied", true) } }
							}
							Image {
								visible: !!(wp.share && wp.share.qr)
								Layout.alignment: Qt.AlignHCenter
								Layout.preferredWidth: 150; Layout.preferredHeight: 150
								source: wp.share && wp.share.qr ? "file://" + wp.share.qr : ""
								cache: false
								smooth: false
								fillMode: Image.PreserveAspectFit
							}
							Text {
								visible: !!(wp.share && !wp.share.qr)
								textFormat: Text.PlainText
								text: "install qrencode to get a QR code phones can scan"
								color: root.walColor8; opacity: 0.7; font.pixelSize: 8; font.family: "JetBrainsMono Nerd Font"
							}
						}
					}
				}

				// ── networks in range ─────────────────────────────────
				Text {
					visible: wp.view === "main" && wp.st && wp.st.radio
					textFormat: Text.PlainText
					text: wp.scanning ? "SCANNING…" : "NETWORKS"
					color: root.walColor8; font.pixelSize: 8; font.bold: true; font.letterSpacing: 1.2; font.family: "JetBrainsMono Nerd Font"
					Layout.topMargin: 2; Layout.leftMargin: 4
				}
				Repeater {
					model: wp.view === "main" && wp.st && wp.st.radio ? wp.st.networks.filter(function(n) { return !n.active }).slice(0, 9) : []
					delegate: ColumnLayout {
						id: nr
						required property var modelData
						readonly property bool open: wp.pwFor === modelData.ssid
						Layout.fillWidth: true
						spacing: 4
						Rectangle {
							Layout.fillWidth: true
							Layout.preferredHeight: 30
							radius: 9
							color: nr.open ? root.card(0.4) : (nMa.containsMouse ? root.hover(0.06) : "transparent")
							RowLayout {
								anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 6; spacing: 7
								Text { textFormat: Text.PlainText; text: wp.sigIcon(nr.modelData.signal); color: nr.modelData.saved ? wp.accent : root.walColor8; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font" }
								Text { textFormat: Text.PlainText; text: nr.modelData.ssid; color: root.walForeground; font.pixelSize: 10; font.bold: nr.modelData.saved
									font.family: "JetBrainsMono Nerd Font"; elide: Text.ElideRight; Layout.fillWidth: true }
								Text { textFormat: Text.PlainText; visible: nr.modelData.saved; text: "saved"; color: wp.accent; font.pixelSize: 8; font.family: "JetBrainsMono Nerd Font" }
								Chip { visible: nr.modelData.band !== ""; label: nr.modelData.band.replace(" GHz", "G") }
								Text { textFormat: Text.PlainText; text: nr.modelData.security ? "󰌾" : "󰿆"; color: root.walColor8; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font" }
								IconBtn { visible: nr.modelData.saved; icon: "󰒓"; small: true; onClicked: wp.openEdit(nr.modelData.uuid) }
							}
							MouseArea {
								id: nMa
								anchors.fill: parent
								anchors.rightMargin: nr.modelData.saved ? 30 : 0
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								onClicked: wp.joinNet(nr.modelData)
							}
						}
						// password for a new secured network
						RowLayout {
							visible: nr.open
							Layout.fillWidth: true
							Layout.leftMargin: 6
							spacing: 5
							Field {
								id: pwField
								Layout.fillWidth: true
								placeholder: "password for " + nr.modelData.ssid
								secret: !wp.showPw
								onSubmitted: if (text !== "") wp.act(["connect", nr.modelData.ssid, text], "connecting to " + nr.modelData.ssid + "…")
								Component.onCompleted: if (nr.open) forceFocus()
							}
							IconBtn { icon: wp.showPw ? "󰈉" : "󰈈"; small: true; onClicked: wp.showPw = !wp.showPw }
							Btn { icon: "󰁔"; label: "Join"; onClicked: if (pwField.text !== "") wp.act(["connect", nr.modelData.ssid, pwField.text], "connecting to " + nr.modelData.ssid + "…") }
							onVisibleChanged: if (visible) pwField.forceFocus()
						}
					}
				}

				// ── saved but not here ────────────────────────────────
				Text {
					visible: wp.view === "main" && wp.st && wp.st.saved.length > 0
					textFormat: Text.PlainText
					text: "SAVED, NOT IN RANGE"
					color: root.walColor8; font.pixelSize: 8; font.bold: true; font.letterSpacing: 1.2; font.family: "JetBrainsMono Nerd Font"
					Layout.topMargin: 2; Layout.leftMargin: 4
				}
				Repeater {
					model: wp.view === "main" && wp.st ? wp.st.saved.slice(0, 6) : []
					delegate: RowLayout {
						id: sr
						required property var modelData
						Layout.fillWidth: true
						Layout.leftMargin: 8
						spacing: 6
						Text { textFormat: Text.PlainText; text: "󰖪"; color: root.walColor8; font.pixelSize: 12; font.family: "JetBrainsMono Nerd Font" }
						Text { textFormat: Text.PlainText; text: sr.modelData.ssid; color: Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.7)
							font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"; elide: Text.ElideRight; Layout.fillWidth: true }
						IconBtn { icon: "󰒓"; small: true; onClicked: wp.openEdit(sr.modelData.uuid) }
						IconBtn {
							icon: wp.confirmForget === sr.modelData.uuid ? "󰄬" : "󰆴"
							small: true
							danger: true
							onClicked: {
								if (wp.confirmForget !== sr.modelData.uuid) { wp.confirmForget = sr.modelData.uuid; forgetTimer.restart() }
								else { wp.confirmForget = ""; wp.act(["forget", sr.modelData.uuid], "forgetting…") }
							}
						}
					}
				}

				// ── hidden network ────────────────────────────────────
				Rectangle {
					visible: wp.view === "main" && wp.st && wp.st.radio
					Layout.fillWidth: true
					Layout.preferredHeight: 26
					radius: 8
					color: hidMa.containsMouse ? root.hover(0.05) : "transparent"
					Text {
						textFormat: Text.PlainText
						anchors.verticalCenter: parent.verticalCenter; x: 8
						text: (wp.hiddenOpen ? "󰅀" : "󰅂") + "  Join a hidden network…"
						color: root.walColor8; font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
					}
					MouseArea { id: hidMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
						onClicked: { wp.hiddenOpen = !wp.hiddenOpen; if (wp.hiddenOpen) hidSsid.forceFocus() } }
				}
				ColumnLayout {
					visible: wp.view === "main" && wp.hiddenOpen
					Layout.fillWidth: true
					Layout.leftMargin: 6
					spacing: 5
					Field { id: hidSsid; Layout.fillWidth: true; placeholder: "network name (SSID)"; onSubmitted: hidPw.forceFocus() }
					RowLayout {
						Layout.fillWidth: true
						spacing: 5
						Field { id: hidPw; Layout.fillWidth: true; placeholder: "password (empty if open)"; secret: !wp.showPw
							onSubmitted: if (hidSsid.text !== "") wp.act(["hidden", hidSsid.text].concat(text !== "" ? [text] : []), "joining " + hidSsid.text + "…") }
						IconBtn { icon: wp.showPw ? "󰈉" : "󰈈"; small: true; onClicked: wp.showPw = !wp.showPw }
						Btn { icon: "󰁔"; label: "Join"; onClicked: if (hidSsid.text !== "") wp.act(["hidden", hidSsid.text].concat(hidPw.text !== "" ? [hidPw.text] : []), "joining " + hidSsid.text + "…") }
					}
				}

				// ── edit a saved network ──────────────────────────────
				ColumnLayout {
					visible: wp.view === "edit" && !!wp.ed
					Layout.fillWidth: true
					spacing: 9

					SettingRow {
						title: "Connect automatically"
						sub: "join this network whenever it's in range"
						Switch { on: !!(wp.ed && wp.ed.autoconnect); onToggled: { var e = wp.ed; e.autoconnect = !on; wp.ed = e; wp.edChanged() } }
					}
					SettingRow {
						title: "Metered connection"
						sub: "apps that respect it hold back big downloads / updates"
						Switch { on: !!(wp.ed && wp.ed.metered); onToggled: { var e = wp.ed; e.metered = !on; wp.ed = e; wp.edChanged() } }
					}

					Text { textFormat: Text.PlainText; text: "DNS"; color: root.walColor8; font.pixelSize: 8; font.bold: true; font.letterSpacing: 1.2; font.family: "JetBrainsMono Nerd Font"; Layout.leftMargin: 4 }
					Seg {
						Layout.fillWidth: true
						options: [{ k: "auto", t: "Automatic (router)" }, { k: "custom", t: "Custom" }]
						value: wp.ed ? wp.ed.dnsMode : "auto"
						onPicked: function(k) { var e = wp.ed; e.dnsMode = k; wp.ed = e; wp.edChanged(); if (k === "custom") dnsField.forceFocus() }
					}
					ColumnLayout {
						visible: !!(wp.ed && wp.ed.dnsMode === "custom")
						Layout.fillWidth: true
						spacing: 5
						Field { id: dnsField; Layout.fillWidth: true; placeholder: "e.g. 1.1.1.1 8.8.8.8"; text: wp.ed ? wp.ed.dnsText : ""
							onTextEdited: { var e = wp.ed; e.dnsText = text; wp.ed = e } }
						RowLayout {
							spacing: 5
							Repeater {
								model: [{ t: "Cloudflare", v: "1.1.1.1 1.0.0.1" }, { t: "Google", v: "8.8.8.8 8.8.4.4" }, { t: "Quad9", v: "9.9.9.9 149.112.112.112" }, { t: "AdGuard", v: "94.140.14.14 94.140.15.15" }]
								delegate: Chip {
									required property var modelData
									label: modelData.t
									clickable: true
									onClicked: { var e = wp.ed; e.dnsText = modelData.v; wp.ed = e; dnsField.setText(modelData.v) }
								}
							}
						}
					}

					Text { textFormat: Text.PlainText; text: "IP ADDRESS"; color: root.walColor8; font.pixelSize: 8; font.bold: true; font.letterSpacing: 1.2; font.family: "JetBrainsMono Nerd Font"; Layout.leftMargin: 4 }
					Seg {
						Layout.fillWidth: true
						options: [{ k: "auto", t: "Automatic (DHCP)" }, { k: "static", t: "Static" }]
						value: wp.ed ? wp.ed.ipMode : "auto"
						onPicked: function(k) { var e = wp.ed; e.ipMode = k; wp.ed = e; wp.edChanged(); if (k === "static") ipField.forceFocus() }
					}
					RowLayout {
						visible: !!(wp.ed && wp.ed.ipMode === "static")
						Layout.fillWidth: true
						spacing: 5
						Field { id: ipField; Layout.fillWidth: true; placeholder: "address, e.g. 192.168.254.50/24"; text: wp.ed ? wp.ed.ipText : ""
							onTextEdited: { var e = wp.ed; e.ipText = text; wp.ed = e } }
						Field { id: gwField; Layout.preferredWidth: 130; placeholder: "gateway"; text: wp.ed ? wp.ed.gateway : ""
							onTextEdited: { var e = wp.ed; e.gateway = text; wp.ed = e } }
					}

					RowLayout {
						Layout.fillWidth: true
						Layout.topMargin: 4
						spacing: 6
						Btn {
							icon: "󰆓"; label: "Save"; primary: true
							onClicked: {
								var e = wp.ed
								wp.act(["edit", e.uuid, JSON.stringify({
									autoconnect: e.autoconnect, metered: e.metered,
									dns: e.dnsMode === "auto" ? "auto" : e.dnsText,
									ip: e.ipMode === "auto" ? "auto" : e.ipText,
									gateway: e.ipMode === "auto" ? "" : e.gateway
								})], "saving…")
							}
						}
						Btn { icon: "󰐲"; label: "Share"; onClicked: { wp.view = "main"; wp.openShare(wp.ed.uuid) }
							visible: !!(wp.st && wp.st.active && wp.ed && wp.st.active.uuid === wp.ed.uuid) }
						Item { Layout.fillWidth: true }
						Btn {
							icon: wp.confirmForget === (wp.ed ? wp.ed.uuid : "") ? "󰄬" : "󰆴"
							label: wp.confirmForget === (wp.ed ? wp.ed.uuid : "") ? "Sure?" : "Forget"
							danger: true
							onClicked: {
								if (wp.confirmForget !== wp.ed.uuid) { wp.confirmForget = wp.ed.uuid; forgetTimer.restart() }
								else { wp.confirmForget = ""; wp.act(["forget", wp.ed.uuid], "forgetting…") }
							}
						}
					}
				}

				// ── status line ───────────────────────────────────────
				Rectangle {
					Layout.fillWidth: true
					Layout.preferredHeight: 22
					radius: 8
					color: root.card(0.3)
					Text {
						textFormat: Text.PlainText
						anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
						verticalAlignment: Text.AlignVCenter
						elide: Text.ElideRight
						text: wp.busy !== "" ? "󰔟  " + wp.busy
							: wp.msg !== "" ? (wp.msgOk ? "󰄬  " : "󰀦  ") + wp.msg
							: wp.view === "edit" ? "changes apply right away when you save · esc back"
							: "click a network to join · 󰒓 settings · esc close"
						color: wp.busy !== "" ? wp.accent : wp.msg !== "" ? (wp.msgOk ? root.walColor2 : root.walColor1) : root.walColor8
						opacity: wp.busy !== "" || wp.msg !== "" ? 1 : 0.7
						font.pixelSize: 9; font.family: "JetBrainsMono Nerd Font"
					}
				}
			}
		}
	}

	Timer { id: wpFocus; interval: 50; onTriggered: { wp.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive; wpRelease.start() } }
	Timer { id: wpRelease; interval: 100; onTriggered: wp.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand }

	// ── small building blocks ────────────────────────────────────────
	component Chip: Rectangle {
		id: chip
		property string label
		property bool clickable: false
		signal clicked()
		implicitWidth: chipText.implicitWidth + 12
		implicitHeight: 18
		radius: 6
		color: chipMa.containsMouse && clickable ? Qt.rgba(wp.accent.r, wp.accent.g, wp.accent.b, 0.25) : root.card(0.4)
		Text { id: chipText; textFormat: Text.PlainText; anchors.centerIn: parent; text: chip.label; color: root.walColor8; font.pixelSize: 8; font.family: "JetBrainsMono Nerd Font" }
		MouseArea { id: chipMa; anchors.fill: parent; hoverEnabled: chip.clickable; enabled: chip.clickable; cursorShape: Qt.PointingHandCursor; onClicked: chip.clicked() }
	}
	component IconBtn: Rectangle {
		id: ib
		property string icon
		property bool small: false
		property bool spin: false
		property bool danger: false
		signal clicked()
		implicitWidth: small ? 22 : 26
		implicitHeight: small ? 22 : 26
		radius: 7
		color: ibMa.containsMouse ? (danger ? Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.22) : root.hover(0.08)) : root.card(0.3)
		Text {
			textFormat: Text.PlainText
			anchors.centerIn: parent; text: ib.icon
			color: ib.danger ? root.walColor1 : root.walColor8; font.pixelSize: ib.small ? 11 : 13; font.family: "JetBrainsMono Nerd Font"
			RotationAnimation on rotation { running: ib.spin; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
		}
		MouseArea { id: ibMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ib.clicked() }
	}
	component Btn: Rectangle {
		id: bt
		property string icon
		property string label
		property bool primary: false
		property bool danger: false
		property bool active: false
		signal clicked()
		readonly property color tint: danger ? root.walColor1 : wp.accent
		implicitWidth: btRow.implicitWidth + 16
		implicitHeight: 26
		radius: 8
		opacity: enabled ? 1 : 0.4
		color: primary || active ? Qt.rgba(tint.r, tint.g, tint.b, btMa.containsMouse ? 0.4 : 0.28)
			: (btMa.containsMouse ? Qt.rgba(tint.r, tint.g, tint.b, 0.16) : root.card(0.35))
		Row {
			id: btRow
			anchors.centerIn: parent
			spacing: 5
			Text { textFormat: Text.PlainText; text: bt.icon; color: bt.tint; font.pixelSize: 11; font.family: "JetBrainsMono Nerd Font"; anchors.verticalCenter: parent.verticalCenter }
			Text { textFormat: Text.PlainText; text: bt.label; color: root.walForeground; font.pixelSize: 10; font.bold: bt.primary; font.family: "JetBrainsMono Nerd Font"; anchors.verticalCenter: parent.verticalCenter }
		}
		MouseArea { id: btMa; anchors.fill: parent; hoverEnabled: true; enabled: bt.enabled; cursorShape: Qt.PointingHandCursor; onClicked: bt.clicked() }
	}
	component Switch: Rectangle {
		id: sw
		property bool on: false
		signal toggled()
		implicitWidth: 34
		implicitHeight: 18
		radius: 9
		color: on ? Qt.rgba(wp.accent.r, wp.accent.g, wp.accent.b, 0.55) : root.card(0.5)
		Behavior on color { ColorAnimation { duration: 150 } }
		Rectangle {
			width: 14; height: 14; radius: 7
			anchors.verticalCenter: parent.verticalCenter
			x: sw.on ? parent.width - width - 2 : 2
			color: sw.on ? root.walForeground : root.walColor8
			Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
		}
		MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sw.toggled() }
	}
	component SettingRow: RowLayout {
		id: srow
		property string title
		property string sub
		default property alias control: slot.data
		Layout.fillWidth: true
		spacing: 8
		ColumnLayout {
			Layout.fillWidth: true
			spacing: 1
			Text { textFormat: Text.PlainText; text: srow.title; color: root.walForeground; font.pixelSize: 11; font.bold: true; font.family: "JetBrainsMono Nerd Font" }
			Text { textFormat: Text.PlainText; text: srow.sub; color: root.walColor8; font.pixelSize: 8; font.family: "JetBrainsMono Nerd Font"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
		}
		Item { id: slot; implicitWidth: 34; implicitHeight: 18 }
	}
	component Seg: Rectangle {
		id: seg
		property var options: []
		property string value: ""
		signal picked(string k)
		implicitHeight: 28
		radius: 8
		color: root.card(0.35)
		RowLayout {
			anchors.fill: parent
			anchors.margins: 3
			spacing: 3
			Repeater {
				model: seg.options
				delegate: Rectangle {
					required property var modelData
					readonly property bool sel: seg.value === modelData.k
					Layout.fillWidth: true
					Layout.fillHeight: true
					radius: 6
					color: sel ? Qt.rgba(wp.accent.r, wp.accent.g, wp.accent.b, 0.25) : (sgMa.containsMouse ? root.hover(0.06) : "transparent")
					Text { textFormat: Text.PlainText; anchors.centerIn: parent; text: modelData.t; color: parent.sel ? root.walForeground : root.walColor8
						font.pixelSize: 10; font.bold: parent.sel; font.family: "JetBrainsMono Nerd Font" }
					MouseArea { id: sgMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: seg.picked(modelData.k) }
				}
			}
		}
	}
	component Field: Rectangle {
		id: fld
		property string placeholder
		property bool secret: false
		property alias text: inp.text
		signal submitted()
		signal textEdited()
		function forceFocus() { inp.forceActiveFocus() }
		function setText(t) { inp.text = t }
		implicitHeight: 26
		radius: 7
		color: root.card(0.4)
		border.width: 1
		border.color: inp.activeFocus ? Qt.rgba(wp.accent.r, wp.accent.g, wp.accent.b, 0.55) : "transparent"
		TextInput {
			id: inp
			anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
			verticalAlignment: TextInput.AlignVCenter
			color: root.walForeground
			selectionColor: Qt.rgba(wp.accent.r, wp.accent.g, wp.accent.b, 0.4)
			font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
			echoMode: fld.secret ? TextInput.Password : TextInput.Normal
			clip: true
			selectByMouse: true
			onAccepted: fld.submitted()
			onTextEdited: fld.textEdited()
			Keys.onEscapePressed: function(event) { event.accepted = false }
		}
		Text {
			textFormat: Text.PlainText
			anchors.fill: parent; anchors.leftMargin: 8
			verticalAlignment: Text.AlignVCenter
			visible: inp.text === ""
			text: fld.placeholder
			color: root.walColor8; opacity: 0.6
			font.pixelSize: 10; font.family: "JetBrainsMono Nerd Font"
			elide: Text.ElideRight
		}
	}
}
