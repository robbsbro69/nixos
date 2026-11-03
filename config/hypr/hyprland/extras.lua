-- ~/.config/hypr/hyprland/extras.lua — scratchpads, groups, pin, swallow, workspace rules, colour picker
local mod = "SUPER"
local exec = hl.dsp.exec_cmd

-- ── Scratchpads (special workspaces) ──────────────────────────
-- SUPER+`  drop-down terminal (opens kitty itself the first time)
-- SUPER+Z  scratchpad · SUPER+SHIFT+Z sends the focused window there
hl.bind(mod .. " + grave", hl.dsp.workspace.toggle_special("term"), { description = "Scratchpad: drop-down terminal" })
hl.bind(mod .. " + Z", hl.dsp.workspace.toggle_special("magic"), { description = "Scratchpad: show / hide" })
hl.bind(mod .. " + SHIFT + Z", hl.dsp.window.move({ workspace = "special:magic", follow = false }), { description = "Scratchpad: send window" })

hl.workspace_rule({ workspace = "special:term", gaps_out = 40 })
hl.workspace_rule({ workspace = "special:magic", gaps_out = 30 })
hl.window_rule({ match = { class = "^(scratch-term)$" }, float = true })
hl.window_rule({ match = { class = "^(scratch-term)$" }, size = "monitor_w*0.7 monitor_h*0.6" })
hl.window_rule({ match = { class = "^(scratch-term)$" }, center = true })

-- ── Groups (tabbed windows) ───────────────────────────────────
hl.bind(mod .. " + G", hl.dsp.group.toggle({}), { description = "Group: make / break tab group" })
hl.bind(mod .. " + period", hl.dsp.group.next({}), { description = "Group: next tab" })
hl.bind(mod .. " + comma", hl.dsp.group.prev({}), { description = "Group: previous tab" })
hl.bind(mod .. " + SHIFT + G", hl.dsp.window.move({ out_of_group = true }), { description = "Group: pull window out" })
hl.bind(mod .. " + CTRL + G", hl.dsp.group.lock({ action = "toggle" }), { description = "Group: lock / unlock" })
-- moving a window (SUPER+SHIFT+HJKL) onto a group puts it in as a new tab
hl.config({
	group = {
		["col.border_active"] = "rgba(f5c2e7ee)",
		["col.border_inactive"] = "rgba(585b70aa)",
		groupbar = {
			font_size = 11,
			height = 16,
			["col.active"] = "rgba(f5c2e7cc)",
			["col.inactive"] = "rgba(313244cc)",
		},
	},
})

-- ── Pin (floating window stays on every workspace) ───────────
hl.bind(mod .. " + SHIFT + P", hl.dsp.window.pin({ action = "toggle" }), { description = "Window: pin (float it first with SUPER+T)" })

-- ── Swallow: a terminal hides while the GUI app it launched is open ──
hl.config({
	misc = {
		enable_swallow = true,
		swallow_regex = "^(kitty)$",
		swallow_exception_regex = "^(wev|.*scrcpy.*|journal-back|focuscam)$",
	},
})

-- ── Workspace rules ───────────────────────────────────────────
-- going to an empty workspace 3 starts Spotify there (it already lands on 3)

-- ── Colour picker ─────────────────────────────────────────────
hl.bind(mod .. " + SHIFT + C", exec('c=$(hyprpicker -a -f hex) && notify-send -a Colour "$c" "copied to clipboard"'), { description = "Pick a colour from the screen" })

-- ── Video wallpaper (mpvpaper over the normal wallpaper) ──────
hl.bind(mod .. " + ALT + W", exec("vidwall toggle"), { description = "Video wallpaper on / off" })

-- ── Scrolling layout (phase 2) ────────────────────────────────
-- workspace 4 always scrolls; SUPER+SHIFT+Space flips the default layout dwindle ↔ scrolling
hl.workspace_rule({ workspace = "4", layout = "scrolling" })
hl.bind(mod .. " + SHIFT + Space", exec("layout-toggle"), { description = "Layout: dwindle ↔ scrolling" })

-- start apps when these workspaces open empty (0.57 replacement for on_created_empty)
hl.on("workspace.created", function(ws)
if not ws or not ws.is_empty then return end
local name = tostring(ws.name or "")
if name == "special:term" or name == "term" then hl.exec_cmd("kitty --class scratch-term")
elseif ws.id == 3 then hl.exec_cmd("true") end
end)
