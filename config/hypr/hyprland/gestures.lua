-- ~/.config/hypr/hyprland/gestures.lua

-- ── 3-Finger: Switch workspaces (swipe up/down) ───────────────
hl.gesture({
	fingers = 3,
	direction = "vertical",
	action = "workspace",
})

-- ── 3-Finger: Scroll / move content (swipe left/right) ────────
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "scroll_move",
	scale = 0.9,
})

-- ── 4-Finger: Enter fullscreen on pinch-out ───────────────────
hl.gesture({
	fingers = 4,
	direction = "pinchout",
	action = function()
		hl.dispatch(hl.dsp.window.fullscreen({ action = "set" }))
	end,
})

-- ── 4-Finger: Exit fullscreen on pinch-in ─────────────────────
hl.gesture({
	fingers = 4,
	direction = "pinchin",
	action = function()
		hl.dispatch(hl.dsp.window.fullscreen({ action = "unset" }))
	end,
})
