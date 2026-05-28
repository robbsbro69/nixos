-- ~/.config/hypr/hyprland/keybinds.lua
local mod = "SUPER"
local exec = hl.dsp.exec_cmd

-- ── Applications ──────────────────────────────────────────────
hl.bind(mod .. " + Return", exec("kitty"), { description = "Launch terminal" })
hl.bind(mod .. " + D", exec("qs ipc call launcher toggle"), { description = "Toggle app launcher" })
hl.bind(mod .. " + A", exec("qs ipc call dashboard toggle"), { description = "Toggle dashboard" })
hl.bind(mod .. " + M", exec("qs ipc call music toggle"), { description = "Toggle music panel" })
hl.bind(mod .. " + W", exec("qs ipc call wallpaper toggle"), { description = "Toggle wallpaper picker" })
hl.bind(mod .. " + N", exec("qs ipc call notifcenter toggle"), { description = "Toggle notification center" })
hl.bind(mod .. " + C", exec("qs ipc call clipboard toggle"), { description = "Toggle clipboard panel" })
hl.bind(mod .. " + SHIFT + W", exec("~/.config/scripts/random-wallpaper.sh"), { description = "Random wallpaper" })
hl.bind(mod .. " + X", exec("hyprlock"), { description = "Lock screen" })

-- ── Window State ──────────────────────────────────────────────
hl.bind(mod .. " + Q", hl.dsp.window.close(), { description = "Window: Close" })
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }), { description = "Window: Fullscreen toggle" })
hl.bind(mod .. " + T", hl.dsp.window.float({ action = "toggle" }), { description = "Window: Float toggle" })

-- ── Focus — HJKL ──────────────────────────────────────────────
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "l" }), { description = "Window: Focus left" })
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "r" }), { description = "Window: Focus right" })
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "d" }), { description = "Window: Focus down" })
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "u" }), { description = "Window: Focus up" })

-- ── Focus — Arrow keys ────────────────────────────────────────
do
	local arrows = { "Left", "Right", "Up", "Down" }
	local dirs = { "l", "r", "u", "d" }
	for i = 1, 4 do
		hl.bind(
			mod .. " + " .. arrows[i],
			hl.dsp.focus({ direction = dirs[i] }),
			{ description = "Window: Focus " .. arrows[i] }
		)
	end
end

-- ── Focus — Bracket keys (left/right) ────────────────────────
hl.bind(mod .. " + BracketLeft", hl.dsp.focus({ direction = "l" }), { description = "Window: Focus left (bracket)" })
hl.bind(mod .. " + BracketRight", hl.dsp.focus({ direction = "r" }), { description = "Window: Focus right (bracket)" })

-- ── Move Windows — HJKL ───────────────────────────────────────
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }), { description = "Window: Move left" })
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }), { description = "Window: Move right" })
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }), { description = "Window: Move down" })
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }), { description = "Window: Move up" })

-- ── Move Windows — Arrow keys ─────────────────────────────────
do
	local arrows = { "Left", "Right", "Up", "Down" }
	local dirs = { "l", "r", "u", "d" }
	for i = 1, 4 do
		hl.bind(
			mod .. " + SHIFT + " .. arrows[i],
			hl.dsp.window.move({ direction = dirs[i] }),
			{ description = "Window: Move " .. arrows[i] }
		)
	end
end

-- ── Move Windows to workspace via scroll ─────────────────────
-- SUPER+SHIFT+scroll and SUPER+ALT+scroll
do
	local combos = {
		mod .. " + SHIFT + mouse_down",
		mod .. " + SHIFT + mouse_up",
		mod .. " + ALT + mouse_down",
		mod .. " + ALT + mouse_up",
	}
	local offsets = { "r-1", "r+1", "r-1", "r+1" }
	for i = 1, 4 do
		hl.bind(
			combos[i],
			hl.dsp.window.move({ workspace = offsets[i] }),
			{ description = "Window: Move to workspace " .. offsets[i] }
		)
	end
end

-- ── Resize Windows (repeating) ────────────────────────────────
hl.bind(
	mod .. " + CTRL + H",
	hl.dsp.window.resize({ x = -50, y = 0, relative = true }),
	{ repeat_key = true, description = "Window: Resize left" }
)
hl.bind(
	mod .. " + CTRL + L",
	hl.dsp.window.resize({ x = 50, y = 0, relative = true }),
	{ repeat_key = true, description = "Window: Resize right" }
)
hl.bind(
	mod .. " + CTRL + J",
	hl.dsp.window.resize({ x = 0, y = 50, relative = true }),
	{ repeat_key = true, description = "Window: Resize down" }
)
hl.bind(
	mod .. " + CTRL + K",
	hl.dsp.window.resize({ x = 0, y = -50, relative = true }),
	{ repeat_key = true, description = "Window: Resize up" }
)

-- ── Workspaces — Number keys ──────────────────────────────────
for i = 1, 9 do
	hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }), { description = "Workspace: Focus " .. i })
	hl.bind(
		mod .. " + SHIFT + " .. i,
		hl.dsp.window.move({ workspace = i }),
		{ description = "Workspace: Move window to " .. i }
	)
end
hl.bind(mod .. " + 0", hl.dsp.focus({ workspace = 10 }), { description = "Workspace: Focus 10" })
hl.bind(mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }), { description = "Workspace: Move window to 10" })

-- ── Audio ─────────────────────────────────────────────────────
hl.bind(
	"XF86AudioRaiseVolume",
	exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),
	{ repeat_key = true, description = "Audio: Volume up" }
)
hl.bind(
	"XF86AudioLowerVolume",
	exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ repeat_key = true, description = "Audio: Volume down" }
)
hl.bind("XF86AudioMute", exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { description = "Audio: Mute toggle" })

-- ── Screenshot ────────────────────────────────────────────────
hl.bind(
	mod .. " + S",
	exec('grim -g "$(slurp)" ~/Pictures/Screenshots_2026/screenshot-$(date +%Y%m%d-%H%M%S).png'),
	{ description = "Screenshot: Region" }
)

-- ── Screen Recording ──────────────────────────────────────────
hl.bind(mod .. " + R", exec("~/.config/scripts/record-external.sh"), { description = "Record: External screen" })
hl.bind(mod .. " + ALT + R", exec("~/.config/scripts/record-laptop.sh"), { description = "Record: Laptop screen" })
hl.bind(mod .. " + CTRL + R", exec("~/.config/scripts/record-region.sh"), { description = "Record: Region" })

-- ── Session ───────────────────────────────────────────────────
hl.bind(mod .. " + SHIFT + E", hl.dsp.exit(), { description = "Session: Exit Hyprland" })

-- ── Mouse ─────────────────────────────────────────────────────
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Mouse: Drag window" })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Mouse: Resize window" })
