-- ~/.config/hypr/hyprland/animations.lua

-- ── Curves ────────────────────────────────────────────────────
hl.curve("expressiveFastSpatial", {
	type = "bezier",
	points = { { 0.42, 1.67 }, { 0.21, 0.90 } },
})
hl.curve("expressiveSlowSpatial", {
	type = "bezier",
	points = { { 0.39, 1.29 }, { 0.35, 0.98 } },
})
hl.curve("expressiveDefaultSpatial", {
	type = "bezier",
	points = { { 0.38, 1.21 }, { 0.22, 1.00 } },
})
hl.curve("emphasizedDecel", {
	type = "bezier",
	points = { { 0.05, 0.7 }, { 0.1, 1 } },
})
hl.curve("emphasizedAccel", {
	type = "bezier",
	points = { { 0.3, 0 }, { 0.8, 0.15 } },
})
hl.curve("standardDecel", {
	type = "bezier",
	points = { { 0, 0 }, { 0, 1 } },
})
hl.curve("menu_decel", {
	type = "bezier",
	points = { { 0.1, 1 }, { 0, 1 } },
})
hl.curve("menu_accel", {
	type = "bezier",
	points = { { 0.52, 0.03 }, { 0.72, 0.08 } },
})
hl.curve("stall", {
	type = "bezier",
	points = { { 1, -0.1 }, { 0.7, 0.85 } },
})

-- ── Windows ───────────────────────────────────────────────────
hl.animation({
	leaf = "windowsIn",
	enabled = true,
	speed = 3,
	bezier = "emphasizedDecel",
	style = "popin 80%",
})
hl.animation({
	leaf = "windowsOut",
	enabled = true,
	speed = 2,
	bezier = "emphasizedDecel",
	style = "popin 90%",
})
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "emphasizedDecel", style = "slide" })

-- ── Fade ──────────────────────────────────────────────────────
hl.animation({ leaf = "fadeIn", enabled = true, speed = 3, bezier = "emphasizedDecel" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2, bezier = "emphasizedDecel" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 4, bezier = "emphasizedDecel" })

-- ── Border ────────────────────────────────────────────────────
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "emphasizedDecel" })

-- ── Layers (Quickshell panels, overlays) ──────────────────────
hl.animation({ leaf = "layersIn", enabled = true, speed = 2.7, bezier = "emphasizedDecel", style = "popin 93%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2.4, bezier = "menu_accel", style = "popin 94%" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 0.5, bezier = "menu_decel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2.7, bezier = "stall" })

-- ── Workspaces ────────────────────────────────────────────────
hl.animation({ leaf = "workspaces", enabled = true, speed = 7, bezier = "menu_decel", style = "slide" })

-- ── Special Workspaces ────────────────────────────────────────
hl.animation({
	leaf = "specialWorkspaceIn",
	enabled = true,
	speed = 2.8,
	bezier = "emphasizedDecel",
	style = "slidevert",
})
hl.animation({
	leaf = "specialWorkspaceOut",
	enabled = true,
	speed = 1.2,
	bezier = "emphasizedAccel",
	style = "slidevert",
})

-- ── Zoom ──────────────────────────────────────────────────────
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 3, bezier = "standardDecel" })
