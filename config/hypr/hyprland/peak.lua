-- ~/.config/hypr/hyprland/peak.lua
-- "Peak" look: active window = rotating Catppuccin gradient border + soft pink glow,
-- inactive windows = quiet grey border, faint shadow, gently dimmed.
-- Loaded LAST from hyprland.lua so it overrides general.lua / animations.lua.
-- To turn it all off: comment out  require("hyprland/peak")  in hyprland.lua.

-- ── Borders, gaps ─────────────────────────────────────────────
hl.config({
	general = {
		gaps_in = 4,
		gaps_out = 8,
		border_size = 2,
		col = {
			-- pink → mauve → blue, rotated by the "borderangle" animation below
			active_border = { colors = { "rgba(f5c2e7ff)", "rgba(cba6f7ff)", "rgba(89b4faff)", "rgba(f5c2e7ff)" }, angle = 45 },
			inactive_border = "rgba(585b7088)", -- surface2, translucent
		},
	},
})

-- ── Glow + dimming ────────────────────────────────────────────
hl.config({
	decoration = {
		rounding = 10,
		rounding_power = 2.5,
		active_opacity = 1.0,
		inactive_opacity = 0.92,
		fullscreen_opacity = 1.0,
		dim_inactive = true,
		dim_strength = 0.08, -- gentle; raise to 0.15 for stronger focus
		shadow = {
			enabled = true,
			range = 18,
			render_power = 3,
			color = "rgba(f5c2e755)",          -- active: soft pink glow
			color_inactive = "rgba(11111b44)", -- inactive: faint dark shadow, no glow
		},
	},
})

-- ── Animations ────────────────────────────────────────────────
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("peakPop", { type = "bezier", points = { { 0.34, 1.56 }, { 0.64, 1.0 } } })

-- gradient border slowly rotates around the active window (loops forever)
hl.animation({ leaf = "borderangle", enabled = true, speed = 80, bezier = "linear", style = "loop" })
-- colour change between active/inactive borders + glow
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "emphasizedDecel" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 6, bezier = "emphasizedDecel" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 6, bezier = "emphasizedDecel" })
-- slightly bouncier window pop-in
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.5, bezier = "peakPop", style = "popin 85%" })
