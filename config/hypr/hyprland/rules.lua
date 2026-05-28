-- ~/.config/hypr/hyprland/rules.lua

-- No shadow for tiled windows
hl.window_rule({
	match = { float = false },
	no_shadow = true,
})

-- Rounding for all floating windows
hl.window_rule({
	match = { float = true },
	rounding = 4,
})

-- Screen sharing indicator — float, pin, bottom-center
hl.window_rule({
	match = { title = ".*is sharing (a window|your screen).*" },
	float = true,
})
hl.window_rule({
	match = { title = ".*is sharing (a window|your screen).*" },
	pin = true,
})
hl.window_rule({
	match = { title = ".*is sharing (a window|your screen).*" },
	move = { "(monitor_w*0.5-window_w*0.5)", "(monitor_h-window_h-12)" },
})

-- Picture-in-Picture — float, pin, aspect-locked, bottom-right
hl.window_rule({
	match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
	float = true,
	pin = true,
	keep_aspect_ratio = true,
})
hl.window_rule({
	match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
	move = { "(monitor_w*0.73)", "(monitor_h*0.72)" },
})
hl.window_rule({
	match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
	size = { "(monitor_w*0.25)", "(monitor_h*0.25)" },
})

-- Telegram media viewer
hl.window_rule({ match = { title = "^(Media viewer)$" }, float = true })

-- Idle inhibit while watching videos
hl.window_rule({ match = { class = "^(mpv|.+exe|celluloid)$" }, idle_inhibit = "focus" })
hl.window_rule({ match = { class = "^(zen)$", title = "^(.*YouTube.*)$" }, idle_inhibit = "focus" })
hl.window_rule({ match = { class = "^(zen)$" }, idle_inhibit = "fullscreen" })

-- Zen Beta in workspace 1
hl.window_rule({ match = { class = "^(zen-beta|zen)$" }, workspace = "1 silent" })
hl.window_rule({ match = { class = "^(zen-beta|zen)$" }, suppress_event = "activate" })

-- Obsidian in workspace 2
hl.window_rule({ match = { class = "^(obsidian)$" }, workspace = "2 silent" })
hl.window_rule({ match = { class = "^(obsidian)$" }, suppress_event = "activate" })

-- Start Spotify in workspace 3
hl.window_rule({ match = { title = "^(Spotify( Premium)?)$" }, workspace = "3 silent" })

-- TickTick in workspace 4
hl.window_rule({ match = { class = "^(ticktick|TickTick)$" }, workspace = "4 silent" })
hl.window_rule({ match = { class = "^(ticktick)$" }, suppress_event = "activate" })

-- Fix XWayland apps
hl.window_rule({ match = { xwayland = true }, rounding = 0 })
hl.window_rule({
	match = { class = "^(.*jetbrains.*)$", title = "^(Confirm Exit|Open Project|win424|win201|splash)$" },
	center = true,
})
hl.window_rule({ match = { class = "^(.*jetbrains.*)$", title = "^(splash)$" }, size = "640 400" })

-- Dim around dialogs
hl.window_rule({ match = { class = "^(gcr-prompter)$" }, dim_around = true })
hl.window_rule({ match = { class = "^(xdg-desktop-portal-gtk)$" }, dim_around = true })
hl.window_rule({ match = { class = "^(polkit-gnome-authentication-agent-1)$" }, dim_around = true })
hl.window_rule({ match = { class = "^(zen)$", title = "^(File Upload)$" }, dim_around = true })

-- ── Layer Rules ───────────────────────────────────────────────
hl.layer_rule({
	match = {
		namespace = "^(quickshell:notifications:overlay|quickshell:osd|vicinae|logout_dialog|quickshell:sidebar|quickshell:popup)$",
	},
	blur = true,
})
hl.layer_rule({
	match = { namespace = "^(quickshell:notifications:overlay|quickshell:osd)$" },
	ignore_alpha = 0.2,
})
hl.layer_rule({
	match = { namespace = "^(vicinae|logout_dialog|quickshell:sidebar|quickshell:popup)$" },
	ignore_alpha = 0.5,
})
hl.layer_rule({
	match = { namespace = "^quickshell.*$" },
	blur_popups = true,
})
hl.layer_rule({
	match = { namespace = "^(quickshell:bar)$" },
	ignore_alpha = 0.1,
})
hl.layer_rule({
	match = { namespace = "^(quickshell:notifications:overlay|quickshell:sidebar|quickshell:popup)$" },
	no_anim = true,
})
