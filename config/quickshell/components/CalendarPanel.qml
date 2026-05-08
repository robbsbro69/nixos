import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
	id: calendarPanel
    	screen: Quickshell.screens.length > 0 ? (root.focusedScreen ?? Quickshell.screens[0]) : undefined
    	visible: true
    	exclusionMode: ExclusionMode.Ignore
    	anchors { 
		top: true; 
		left: true 
	}
    	margins {
		top: 40
		left: root.calendarVisible ? 6 : -(implicitWidth + 20)
	}
    	implicitWidth: 312
    	implicitHeight: card.height + 16
    	color: "transparent"
    	focusable: true
    	WlrLayershell.keyboardFocus: root.calendarVisible
	? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None
	Behavior on margins.left {
		NumberAnimation { 
			duration: 300; 
			easing.type: Easing.OutCubic 
		}
	}
	property int calMode: 0
    	property int viewMonth:  new Date().getMonth()
    	property int viewYear:   new Date().getFullYear()
    	property int todayDay:   new Date().getDate()
    	property int todayMonth: new Date().getMonth()
    	property int todayYear:  new Date().getFullYear()
    	property bool isCurrentMonth: viewMonth === todayMonth && viewYear === todayYear
    	property int bsViewMonth:  1
    	property int bsViewYear:   2081
    	property int bsTodayDay:   1
    	property int bsTodayMonth: 1
    	property int bsTodayYear:  2081
    	property bool bsIsCurrentMonth: bsViewMonth === bsTodayMonth && bsViewYear === bsTodayYear

    	property var dayNames:    ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    	property var monthNames:  ["January","February","March","April","May","June","July","August","September","October","November","December"]
    	property var longDayNames: ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
    	property var bsMonthNames: ["Baisakh","Jestha","Ashadh","Shrawan","Bhadra","Ashwin","Kartik","Mangsir","Poush","Magh","Falgun","Chaitra"]
    	property var bsMonthNamesNep: ["बैशाख","जेठ","असार","श्रावण","भाद्र","आश्विन","कार्तिक","मंसिर","पौष","माघ","फाल्गुन","चैत्र"]
    	property var nepaliNums: ["०","१","२","३","४","५","६","७","८","९"]
    	property var bsYearData: [
        	[2000,30,32,31,32,31,30,30,30,29,30,29,31],
        	[2001,31,31,32,31,31,31,30,29,30,29,30,30],
        	[2002,31,31,32,32,31,30,30,29,30,29,30,30],
        	[2003,31,32,31,32,31,30,30,30,29,29,30,31],
        	[2004,30,32,31,32,31,30,30,30,29,30,29,31],
        	[2005,31,31,32,31,31,30,30,30,29,30,29,31],
        	[2006,31,31,32,31,31,30,30,30,29,30,30,30],
        	[2007,31,32,31,32,31,30,30,30,29,30,30,30],
        	[2008,30,32,31,32,31,30,30,30,29,30,30,31],
        	[2009,31,31,32,31,31,31,30,29,30,29,30,30],
        	[2010,31,31,32,31,31,30,30,29,30,29,30,30],
        	[2011,31,31,32,32,31,30,30,29,30,29,30,30],
        	[2012,31,32,31,32,31,30,30,30,29,29,30,31],
        	[2013,30,32,31,32,31,30,30,30,29,30,29,31],
        	[2014,31,31,32,31,31,30,30,30,29,30,29,31],
        	[2015,31,31,32,31,31,30,30,30,29,30,30,30],
        	[2016,31,32,31,32,31,30,30,30,29,30,30,30],
        	[2017,31,32,31,32,31,30,30,30,29,30,30,30],
        	[2018,30,32,31,32,31,30,30,30,29,30,30,31],
        	[2019,31,31,32,31,31,31,30,29,30,29,30,30],
        	[2020,31,31,32,31,31,30,30,29,30,29,30,30],
        	[2021,31,32,31,32,31,30,30,29,30,29,30,31],
        	[2022,30,32,31,32,31,30,30,30,29,29,30,31],
        	[2023,31,31,32,31,31,30,30,30,29,30,29,31],
        	[2024,31,31,32,31,31,30,30,30,29,30,29,31],
        	[2025,31,31,32,31,31,30,30,30,29,30,30,30],
        	[2026,31,32,31,32,31,30,30,30,29,30,30,30],
        	[2027,30,32,31,32,31,30,30,30,29,30,30,31],
        	[2028,31,31,32,31,31,31,30,29,30,29,30,30],
        	[2029,31,31,32,31,31,30,30,29,30,29,30,30],
        	[2030,31,32,31,32,31,30,30,29,30,29,30,31],
        	[2031,30,32,31,32,31,30,30,30,29,29,30,31],
        	[2032,31,31,32,31,31,30,30,30,29,30,29,31],
        	[2033,31,31,32,31,31,30,30,30,29,30,29,31],
        	[2034,31,31,32,31,31,30,30,30,29,30,30,30],
        	[2035,31,32,31,32,31,30,30,30,29,30,30,30],
        	[2036,31,32,31,32,31,30,30,30,29,30,30,30],
        	[2037,30,32,31,32,31,30,30,30,29,30,30,31],
        	[2038,31,31,32,31,31,31,30,29,30,29,30,30],
        	[2039,31,31,32,31,31,30,30,29,30,29,30,30],
        	[2040,31,32,31,32,31,30,30,29,30,29,30,31],
        	[2041,30,32,31,32,31,30,30,30,29,29,30,31],
        	[2042,31,31,32,31,31,30,30,30,29,30,29,31],
        	[2043,31,31,32,31,31,30,30,30,29,30,29,31],
       	 	[2044,31,31,32,31,31,30,30,30,29,30,30,30],
        	[2045,31,32,31,32,31,30,30,30,29,30,30,30],
        	[2046,31,32,31,32,31,30,30,30,29,30,30,30],
        	[2047,30,32,31,32,31,30,30,30,29,30,30,31],
        	[2048,31,31,32,31,31,31,30,29,30,29,30,30],
        	[2049,31,31,32,31,31,30,30,29,30,29,30,30],
        	[2050,31,32,31,32,31,30,30,29,30,29,30,31],
        	[2051,30,32,31,32,31,30,30,30,29,29,30,31],
        	[2052,31,31,32,31,31,30,30,30,29,30,29,31],
        	[2053,31,31,32,31,31,30,30,30,29,30,29,31],
        	[2054,31,31,32,31,31,30,30,30,29,30,30,30],
        	[2055,31,32,31,32,31,30,30,30,29,30,30,30],
        	[2056,31,32,31,32,31,30,30,30,29,30,30,30],
        	[2057,30,32,31,32,31,30,30,30,29,30,30,31],
        	[2058,31,31,32,31,31,31,30,29,30,29,30,30],
        	[2059,31,31,32,31,31,30,30,29,30,29,30,30],
        	[2060,31,32,31,32,31,30,30,29,30,29,30,31],
        	[2061,30,32,31,32,31,30,30,30,29,29,30,31],
        	[2062,31,31,32,31,31,30,30,30,29,30,29,31],
        	[2063,31,31,32,31,31,30,30,30,29,30,29,31],
        	[2064,31,31,32,31,32,29,30,30,29,30,30,30],
        	[2065,31,32,31,32,31,30,30,30,29,30,30,30],
        	[2066,31,32,31,32,31,30,30,30,29,30,30,30],
        	[2067,30,32,31,32,31,30,30,30,29,30,30,31],
        	[2068,31,31,32,31,31,31,30,29,30,29,30,30],
        	[2069,31,31,32,31,31,30,30,29,30,29,30,30],
        	[2070,31,32,31,32,31,30,30,29,30,29,30,31],
        	[2071,31,31,32,31,31,30,30,30,29,29,30,31],
        	[2072,31,31,32,31,31,30,30,30,29,30,29,31],
        	[2073,31,31,32,31,31,30,30,30,29,30,29,31],
        	[2074,31,31,32,31,32,29,30,29,30,29,30,30],
        	[2075,31,32,31,32,31,30,30,29,30,29,30,30],
        	[2076,31,32,31,32,31,30,30,30,29,30,30,30],
        	[2077,30,32,31,32,31,30,30,30,29,30,30,31],
        	[2078,31,31,32,31,31,31,30,29,30,29,30,30],
        	[2079,31,31,32,31,31,30,30,29,30,29,30,30],
        	[2080,31,32,31,32,31,30,30,29,30,29,30,31],
        	[2081,31,31,32,31,31,30,30,30,29,29,30,31],
        	[2082,31,31,32,31,31,30,30,30,29,30,29,31],
        	[2083,31,31,32,31,31,30,30,30,29,30,29,31],
        	[2084,31,31,32,31,32,29,30,29,30,29,30,30],
        	[2085,31,32,31,32,31,30,30,29,30,29,30,30],
        	[2086,31,32,31,32,31,30,30,30,29,30,30,30],
        	[2087,30,32,31,32,31,30,30,30,29,30,30,31],
        	[2088,31,31,32,31,31,31,30,29,30,29,30,30],
        	[2089,31,31,32,31,31,30,30,29,30,29,30,30],
        	[2090,31,32,31,32,31,30,30,29,30,29,30,31]
    	]
	property var bsCells: []
    	function getBsDaysInMonth(year, month) {
		for (var i = 0; i < bsYearData.length; i++) {
			if (bsYearData[i][0] === year) return bsYearData[i][month]
		}
		return 30
	}
	function isLeapYear(y) {
		return (y % 4 === 0 && y % 100 !== 0) || (y % 400 === 0)
	}
	function daysInAdMonth(year, month) {
		var days = [0,31,28,31,30,31,30,31,31,30,31,30,31]
        	if (month === 2 && isLeapYear(year)) return 29
        	return days[month]
	}
    	function bsToAd(bsYear, bsMonth, bsDay) {
		var refBsYear = 2000, refBsMonth = 1, refBsDay = 1
        	var refAdYear = 1943, refAdMonth = 4, refAdDay = 14
        	var totalDays = 0
        	var cy = refBsYear, cm = refBsMonth
        	while (cy < bsYear || (cy === bsYear && cm < bsMonth)) {
			totalDays += getBsDaysInMonth(cy, cm)
            		cm++
            		if (cm > 12) { 
				cm = 1; cy++ 
			}
		}
		totalDays += bsDay - refBsDay
        	var ay = refAdYear, am = refAdMonth, ad = refAdDay
        	var remaining = totalDays
        	while (remaining > 0) {
			var daysLeft = daysInAdMonth(ay, am) - ad
			if (remaining <= daysLeft) {
				ad += remaining
                		remaining = 0
			} else {
				remaining -= (daysLeft + 1)
                		ad = 1; am++
                		if (am > 12) { 
					am = 1; ay++ 
				}
			}
		}
		return { 
			year: ay, 
			month: am, 
			day: ad 
		}
	}
	function adToBs(adYear, adMonth, adDay) {
		var refAdYear = 1943, refAdMonth = 4, refAdDay = 14
        	var refBsYear = 2000, refBsMonth = 1, refBsDay = 1
        	var adDays = 0
        	var cy = refAdYear, cm = refAdMonth

        	while (cy < adYear || (cy === adYear && cm < adMonth)) {
			adDays += daysInAdMonth(cy, cm)
            		cm++
			if (cm > 12) { 
				cm = 1; cy++ 
			}
		}
		adDays += adDay - refAdDay
		var bsYear = refBsYear, bsMonth = refBsMonth, bsDay = refBsDay
        	var rem = adDays
        	while (rem > 0) {
			var daysInMonth = getBsDaysInMonth(bsYear, bsMonth)
			var daysLeft = daysInMonth - bsDay
            		if (rem <= daysLeft) {
				bsDay += rem; rem = 0
			} else {
				rem -= (daysLeft + 1)
                		bsDay = 1; bsMonth++
				if (bsMonth > 12) { 
					bsMonth = 1; bsYear++ 
				}
			}
		}
		return { 
			year: bsYear, 
			month: bsMonth, 
			day: bsDay 
		}
	}
	function bsFirstDayOfWeek(bsYear, bsMonth) {
		var adDate = bsToAd(bsYear, bsMonth, 1)
        	var d = new Date(adDate.year, adDate.month - 1, adDate.day)
        	var day = d.getDay()
        	return day === 0 ? 6 : day - 1
	}
	function buildBsCells(bsYear, bsMonth) {
		var first     = bsFirstDayOfWeek(bsYear, bsMonth)
        	var total     = getBsDaysInMonth(bsYear, bsMonth)
        	var prevM     = bsMonth === 1 ? 12 : bsMonth - 1
        	var prevY     = bsMonth === 1 ? bsYear - 1 : bsYear
        	var prevTotal = getBsDaysInMonth(prevY, prevM)
        	var cells = []
        	for (var i = first - 1; i >= 0; i--)
		cells.push({ 
			day: prevTotal - i, 
			current: false, 
			adDay: 0 
		})
        	var ad1 = bsToAd(bsYear, bsMonth, 1)
        	var startMs = new Date(ad1.year, ad1.month - 1, ad1.day).getTime()
        	var msPerDay = 86400000
        	for (var j = 0; j < total; j++) {
			var d = new Date(startMs + j * msPerDay)
			cells.push({ 
				day: j + 1, 
				current: true, 
				adDay: d.getDate() 
			})
		}
		var rem = 42 - cells.length
        	for (var k = 1; k <= rem; k++)
            	cells.push({ 
			day: k, 
			current: false, 
			adDay: 0 
		})
		return cells
	}
	function toNepaliNum(n) {
		var s = n.toString(), r = ""
        	for (var i = 0; i < s.length; i++) r += nepaliNums[parseInt(s[i])]
        	return r
	}
	function prevMonth() {
		if (calMode === 0) {
			if (viewMonth === 0) { 
				viewMonth = 11; viewYear-- 
			} else viewMonth--
		} else {
			if (bsViewMonth === 1) { 
				bsViewMonth = 12; bsViewYear-- 
			} else bsViewMonth--
		}
	}
	function nextMonth() {
		if (calMode === 0) {
			if (viewMonth === 11) { 
				viewMonth = 0; viewYear++ 
			} else viewMonth++
		} else {
			if (bsViewMonth === 12) { 
				bsViewMonth = 1; bsViewYear++ 
			} else bsViewMonth++
		}
	}
	function goToday() {
		var now    = new Date()
        	viewMonth  = now.getMonth()
        	viewYear   = now.getFullYear()
        	todayDay   = now.getDate()
        	todayMonth = now.getMonth()
        	todayYear  = now.getFullYear()
        	var bs = adToBs(now.getFullYear(), now.getMonth() + 1, now.getDate())
        	bsTodayYear  = bs.year
        	bsTodayMonth = bs.month
        	bsTodayDay   = bs.day
        	bsViewYear   = bs.year
        	bsViewMonth  = bs.month
	}
	function daysInMonth(m, y) { 
		return new Date(y, m + 1, 0).getDate() 
	}
	function firstDayOfWeek(m, y) {
		var d = new Date(y, m, 1).getDay()
        	return d === 0 ? 6 : d - 1
	}
	function gridDays() {
		var first     = firstDayOfWeek(viewMonth, viewYear)
        	var total     = daysInMonth(viewMonth, viewYear)
        	var prevTotal = daysInMonth(viewMonth === 0 ? 11 : viewMonth - 1,viewMonth === 0 ? viewYear - 1 : viewYear)
        	var cells = []
        	for (var i = first - 1; i >= 0; i--) cells.push({ 
			day: prevTotal - i, 
			current: false 
		})
        	for (var j = 1; j <= total; j++) cells.push({ 
			day: j, 
			current: true 
		})
        	var rem = 42 - cells.length
        	for (var k = 1; k <= rem; k++) cells.push({ day: k, current: false })
        	return cells
	}
	Component.onCompleted: {
		goToday()
        	bsCells = buildBsCells(bsViewYear, bsViewMonth)
	}
	onBsViewYearChanged:  bsCells = buildBsCells(bsViewYear, bsViewMonth)
	onBsViewMonthChanged: bsCells = buildBsCells(bsViewYear, bsViewMonth)
	Timer {
		interval: 60000; 
		running: true; 
		repeat: true
        	onTriggered: calendarPanel.goToday()
	}
	Item {
		anchors.fill: parent
		focus: root.calendarVisible
		Keys.onPressed: function(event) {
			if (event.key === Qt.Key_Escape) {
				root.calendarVisible = false; event.accepted = true
			} else if (event.key === Qt.Key_Left) {
				prevMonth(); event.accepted = true
			} else if (event.key === Qt.Key_Right) {
				nextMonth(); event.accepted = true
			} else if (event.key === Qt.Key_T || event.key === Qt.Key_Home) {
				goToday(); event.accepted = true
			} else if (event.key === Qt.Key_Tab) {
				calMode = calMode === 0 ? 1 : 0; event.accepted = true
			}
		}
		Rectangle {
			id: card
            		width: 280
            		anchors.top: parent.top
            		anchors.topMargin: 8
            		anchors.left: parent.left
            		anchors.leftMargin: 16
            		height: contentCol.implicitHeight + 32
            		radius: 16
            		color: Qt.rgba(root.walBackground.r, root.walBackground.g, root.walBackground.b, 0.95)
            		border.width: 1
            		border.color: Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.08)
            		MouseArea { 
				anchors.fill: parent 
			}
			ColumnLayout {
				id: contentCol
				anchors { 
					top: parent.top; 
					left: parent.left; 
					right: parent.right; 
					margins: 16 
				}
				spacing: 4
				Rectangle {
					Layout.fillWidth: true; height: 32; radius: 10
                    			color: Qt.rgba(0, 0, 0, 0.2)
                    			Row {
						anchors.fill: parent; anchors.margins: 3; spacing: 3
						Rectangle {
							width: (parent.width - 6) / 2; height: parent.height; radius: 8
                            				color: calMode === 0 ? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.25) : "transparent"
                           				Behavior on color { 
								ColorAnimation { 
									duration: 150 
								} 
							}
							Text {
								anchors.centerIn: parent; text: "AD"
                                				color: calMode === 0 ? root.walColor5 : root.walColor8
                                				font { 
									pixelSize: 11; 
									bold: calMode === 0; 
									family: "JetBrainsMono Nerd Font" 
								}
                               	 				Behavior on color { 
									ColorAnimation { 
										duration: 150 
									} 
								}
							}
                            				MouseArea { 
								anchors.fill: parent; 
								cursorShape: Qt.PointingHandCursor; 
								onClicked: calMode = 0 
							}
						}
						Rectangle {
							width: (parent.width - 6) / 2; 
							height: parent.height; 
							radius: 8
                            				color: calMode === 1 ? Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.25) : "transparent"
                            				Behavior on color { 
								ColorAnimation { 
									duration: 150 
								} 
							}
                            				Text {
								anchors.centerIn: parent; text: "BS  वि.सं."
                                				color: calMode === 1 ? root.walColor13 : root.walColor8
                                				font { 
									pixelSize: 11; 
									bold: calMode === 1; 
									family: "JetBrainsMono Nerd Font" 
								}
                                				Behavior on color { 
									ColorAnimation { 
										duration: 150 
									} 
								}
							}
                            				MouseArea { 
								anchors.fill: parent; 
								cursorShape: Qt.PointingHandCursor; 
								onClicked: calMode = 1 
							}
						}
					}
				}
				Item {
					Layout.fillWidth: true; implicitHeight: 56
                    			Column {
						visible: calMode === 0; 
						spacing: 2
						Text { 
							text: longDayNames[new Date().getDay()]; 
							color: root.walColor5; 
							font { 
								pixelSize: 16; 
								family: "JetBrainsMono Nerd Font"; 
								bold: true 
							} 
						}
                        			Text { 
							text: monthNames[todayMonth] + " " + todayDay + ", " + todayYear; 
							color: Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.4); 
							font { 
								pixelSize: 11; 
								family: "JetBrainsMono Nerd Font" 
							} 
						}
					}
					Column {
						visible: calMode === 1; 
						spacing: 2
						Row {
							spacing: 8
                            				Text { 
								text: bsMonthNamesNep[bsTodayMonth - 1]; 
								color: root.walColor13; 
								font { 
									pixelSize: 16; 
									family: "JetBrainsMono Nerd Font"; 
									bold: true 
								} 
							}
                            				Text { 
								text: toNepaliNum(bsTodayDay); 
								color: root.walColor13; 
								font { 
									pixelSize: 16; 
									family: "JetBrainsMono Nerd Font"; 
									bold: true 
								} 
							}
						}
						Text { 
							text: bsMonthNames[bsTodayMonth - 1] + " " + bsTodayDay + ", " + bsTodayYear + " BS"; 
							color: Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.4); 
							font { 
								pixelSize: 11; 
								family: "JetBrainsMono Nerd Font" 
							} 
						}
					}
				}
				RowLayout {
					Layout.fillWidth: true; height: 28; spacing: 6
					Text {
						text: calMode === 0
						? (monthNames[viewMonth] + " " + viewYear)
						: (bsMonthNames[bsViewMonth - 1] + " " + bsViewYear + " BS")
						color: root.walForeground
                        			font { 
							pixelSize: 12; 
							family: "JetBrainsMono Nerd Font"; 
							bold: true 
						}
						Layout.fillWidth: true
					}
					Rectangle {
						visible: calMode === 0 ? !(viewMonth === todayMonth && viewYear === todayYear)
						: !(bsViewMonth === bsTodayMonth && bsViewYear === bsTodayYear)
						width: 18; 
						height: 18; 
						radius: 9
						color: todayDotMa.containsMouse ? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.3) : Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.12)
                        			Behavior on color { 
							ColorAnimation { 
								duration: 150 
							} 
						}
                        			Rectangle { 
							anchors.centerIn: parent; 
							width: 6; 
							height: 6; 
							radius: 3; 
							color: root.walColor5 
						}
                        			MouseArea { 
							id: todayDotMa; 
							anchors.fill: parent; 
							anchors.margins: -4; 
							hoverEnabled: true; 
							cursorShape: Qt.PointingHandCursor; 
							onClicked: goToday() 
						}
					}
					Rectangle {
						width: 26; 
						height: 26; 
						radius: 8
                        			color: prevMa.containsMouse ? Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.08) : "transparent"
                        			scale: prevMa.pressed ? 0.88 : 1.0
                        			Behavior on color { 
							ColorAnimation { 
								duration: 150 
							} 
						}
                        			Behavior on scale { 
							NumberAnimation { 
								duration: 80 
							} 
						}
                        			Text { 
							anchors.centerIn: parent; 
							text: "󰅁"; 
							color: prevMa.containsMouse ? root.walForeground : Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.4); 
							font { 
								pixelSize: 12; 
								family: "JetBrainsMono Nerd Font" 
							} 
						}
						MouseArea { 
							id: prevMa; 
							anchors.fill: parent; 
							hoverEnabled: true;
							cursorShape: Qt.PointingHandCursor; 
							onClicked: prevMonth() 
						}
					}
					Rectangle {
						width: 26; 
						height: 26; 
						radius: 8
                        			color: nextMa.containsMouse ? Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.08) : "transparent"
                        			scale: nextMa.pressed ? 0.88 : 1.0
                        			Behavior on color { 
							ColorAnimation { 
								duration: 150 
							} 
						}
                        			Behavior on scale { 
							NumberAnimation { 
								duration: 80 
							} 
						}
                        			Text { 
							anchors.centerIn: parent; 
							text: "󰅂"; 
							color: nextMa.containsMouse ? root.walForeground : Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.4); 
							font { 
								pixelSize: 12; 
								family: "JetBrainsMono Nerd Font" 
							} 
						}
						MouseArea { 
							id: nextMa; 
							anchors.fill: parent; 
							hoverEnabled: true; 
							cursorShape: Qt.PointingHandCursor; 
							onClicked: nextMonth() 
						}
					}
				}
				Row {
					Layout.fillWidth: true; height: 20
                    			Repeater {
						model: dayNames
                        			Item {
							required property string modelData; 
							required property int index
                            				width: (card.width - 32) / 7; 
							height: 20
                            				Text {
								anchors.centerIn: parent; 
								text: modelData
                                				color: index >= 5 ? Qt.rgba((calMode === 0 ? root.walColor5 : root.walColor13).r, (calMode === 0 ? root.walColor5 : root.walColor13).g, (calMode === 0 ? root.walColor5 : root.walColor13).b, 0.5): Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.25)
                                				font { 
									pixelSize: 9; 
									family: "JetBrainsMono Nerd Font"; 
									bold: true 
								}
							}
						}
					}
				}
				Grid {
					id: adGrid
                    			Layout.fillWidth: true; 
					visible: calMode === 0; 
					columns: 7
                    			property var cells: gridDays()
                    			property real cellW: (card.width - 32) / 7
                    			property int todayWeekRow: Math.floor((firstDayOfWeek(viewMonth, viewYear) + todayDay - 1) / 7)
					Connections {
						target: calendarPanel
                        			function onViewMonthChanged() { 
							adGrid.cells = calendarPanel.gridDays() 
						}
                        			function onViewYearChanged()  { 
							adGrid.cells = calendarPanel.gridDays() 
						}
					}
					Repeater {
						model: adGrid.cells
						Item {
							required property int index; 
							required property var modelData
							property bool isToday: modelData.current && modelData.day === todayDay && isCurrentMonth
                            				property bool isWeekend: (index % 7) >= 5
                            				property bool isCurrentWeek: Math.floor(index / 7) === adGrid.todayWeekRow && isCurrentMonth
                            				property bool hov: adDayMa.containsMouse && modelData.current
							width: adGrid.cellW; 
							height: 32
                            				Rectangle { 
								anchors.fill: parent; 
								color: isCurrentWeek ? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.04) : "transparent"; 
								radius: 4 
							}
							Rectangle {
								anchors.centerIn: parent
                                				width: isToday ? 26 : hov ? 24 : 0; 
								height: width; 
								radius: width / 2
                                				color: isToday ? Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.2) : Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.06)
                                				border.width: isToday ? 1.5 : 0
                                				border.color: Qt.rgba(root.walColor5.r, root.walColor5.g, root.walColor5.b, 0.5)
                                				Behavior on width { 
									NumberAnimation { 
										duration: 120; 
										easing.type: Easing.OutBack; 
										easing.overshoot: 1.6 
									} 
								}
							}
							Text {
								anchors.centerIn: parent; 
								text: modelData.day
                                				color: isToday ? root.walColor5 : !modelData.current ? Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.12) : isWeekend ? Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.7) : Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.7)
								font { 
									pixelSize: 11; 
									family: "JetBrainsMono Nerd Font"; 
									bold: isToday 
								}
							}
							MouseArea { 
								id: adDayMa; 
								anchors.fill: parent; 
								hoverEnabled: true; 
								enabled: modelData.current; 
								cursorShape: modelData.current ? Qt.PointingHandCursor : Qt.ArrowCursor 
							}
						}
					}
				}
				Grid {
					id: bsGrid
                    			Layout.fillWidth: true; 
					visible: calMode === 1; 
					columns: 7
                    			property real cellW: (card.width - 32) / 7
                    			property int todayWeekRow: {
						if (!bsIsCurrentMonth) return -1
                        			var first = bsFirstDayOfWeek(bsViewYear, bsViewMonth)
                        			return Math.floor((first + bsTodayDay - 1) / 7)
					}
					Repeater {
						model: calendarPanel.bsCells
						Item {
							required property int index; 
							required property var modelData
							property bool isToday: modelData.current && modelData.day === bsTodayDay && bsIsCurrentMonth
							property bool isWeekend: (index % 7) >= 5
                            				property bool isCurrentWeek: Math.floor(index / 7) === bsGrid.todayWeekRow && bsIsCurrentMonth
                            				property bool hov: bsDayMa.containsMouse && modelData.current
                            				width: bsGrid.cellW; 
							height: 36
							Rectangle { 
								anchors.fill: parent; 
								color: isCurrentWeek ? Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.05) : "transparent"; 
								radius: 4 
							}
							Rectangle {
								anchors.centerIn: parent
                                				width: isToday ? 28 : hov ? 26 : 0; 
								height: width; 
								radius: width / 2
                                				color: isToday ? Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.2) : Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.06)
                                				border.width: isToday ? 1.5 : 0
                                				border.color: Qt.rgba(root.walColor13.r, root.walColor13.g, root.walColor13.b, 0.5)
                                				Behavior on width { 
									NumberAnimation { 
										duration: 120; 
										easing.type: Easing.OutBack; 
										easing.overshoot: 1.6 
									} 
								}
							}
							Text {
								anchors.centerIn: parent; 
								anchors.verticalCenterOffset: -5
                                				text: toNepaliNum(modelData.day)
                                				color: isToday ? root.walColor13 : !modelData.current ? Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.12) : isWeekend ? Qt.rgba(root.walColor1.r, root.walColor1.g, root.walColor1.b, 0.8) : Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, 0.85)
                                				font { 
									pixelSize: 12; 
									family: "JetBrainsMono Nerd Font"; 
									bold: isToday 
								}
							}
							Text {
								anchors.centerIn: parent; 
								anchors.verticalCenterOffset: 7
                                				visible: modelData.current && modelData.adDay > 0
                                				text: modelData.adDay
                                				color: Qt.rgba(root.walForeground.r, root.walForeground.g, root.walForeground.b, isToday ? 0.6 : 0.25)
                                				font { 
									pixelSize: 7; 
									family: "JetBrainsMono Nerd Font" 
								}
							}
							MouseArea { 
								id: bsDayMa; 
								anchors.fill: parent; 
								hoverEnabled: true; 
								enabled: modelData.current; 
								cursorShape: modelData.current ? Qt.PointingHandCursor : Qt.ArrowCursor 
							}
						}
					}
				}
				Rectangle {
					Layout.fillWidth: true; 
					height: 24; 
					radius: 8; 
					color: Qt.rgba(0, 0, 0, 0.3)
					RowLayout {
						anchors.fill: parent; 
						anchors.leftMargin: 10;
						anchors.rightMargin: 10
						Text { 
							text: "←→ month"; 
							color: root.walColor8; 
							font { 
								pixelSize: 9; 
								family: "JetBrainsMono Nerd Font" } 
								opacity: 0.6
							}
							Item { 
								Layout.fillWidth: true 
							}
							Text { 
								text: "tab switch"; 
								color: root.walColor8; 
								font { 
									pixelSize: 9; 
									family: "JetBrainsMono Nerd Font" 
								} 
								opacity: 0.6 
							}
							Item { 
								Layout.fillWidth: true 
							}
							Text { 
								text: "esc close"; 
								color: root.walColor8; 
								font { 
									pixelSize: 9; 
									family: "JetBrainsMono Nerd Font" 
								} 
								opacity: 0.6 
							}
						}
					}
					Item { 
						implicitHeight: 4 
					}
				}
			}
		}
		Connections {
			target: root
			function onCalendarVisibleChanged() {
				if (root.calendarVisible) { 
					calendarPanel.goToday(); focusTimer.start() 
				}
			}
		}
		Timer { 
			id: focusTimer; 
			interval: 50; 
			repeat: false
        		onTriggered: { 
				calendarPanel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive; releaseTimer.start() 
			}
		}
		Timer { 
			id: releaseTimer; 
			interval: 100; 
			repeat: false
        		onTriggered: { 
				calendarPanel.WlrLayershell.keyboardFocus = WlrKeyboardFocus.OnDemand 
			}
		}
	}
