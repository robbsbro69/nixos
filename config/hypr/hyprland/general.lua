-- ~/.config/hypr/hyprland/general.lua

hl.config({
	input = {
		kb_layout = "us",
		repeat_delay = 200,
		repeat_rate = 35,
		follow_mouse = 1,
		sensitivity = 0,
		touchpad = {
			natural_scroll = true,
			disable_while_typing = true,
			clickfinger_behavior = true,
			scroll_factor = 0.7,
			tap_to_click = true,
		},
	},
})

hl.config({
	general = {
		gaps_in = 4,
		gaps_out = 6,
		border_size = 1,
		["col.active_border"] = "rgba(f5c2e7ff)",
		["col.inactive_border"] = "rgba(505050ff)",
		resize_on_border = false,
		no_focus_fallback = true,
		allow_tearing = false,
		layout = "dwindle",
		snap = {
			enabled = true,
			window_gap = 2,
			monitor_gap = 2,
			respect_gaps = true,
		},
	},
})

hl.config({
	gestures = {
		workspace_swipe_distance = 700,
		workspace_swipe_cancel_ratio = 0.2,
		workspace_swipe_min_speed_to_force = 5,
		workspace_swipe_direction_lock = true,
		workspace_swipe_direction_lock_threshold = 10,
		workspace_swipe_create_new = true,
	},
})

hl.config({
	decoration = {
		rounding = 10,
		rounding_power = 2,
		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = "rgba(00000027)",
		},
		blur = {
			enabled = true,
			size = 1,
			passes = 3,
			vibrancy = 0.5,
		},
	},
})

hl.config({
	dwindle = {
		preserve_split = true,
	},
})

hl.config({
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		mouse_move_enables_dpms = true,
		key_press_enables_dpms = true,
		animate_manual_resizes = false,
		animate_mouse_windowdragging = false,
		enable_swallow = false,
		swallow_regex = "(bash|kitty)",
		allow_session_lock_restore = true,
		session_lock_xray = true,
		initial_workspace_tracking = false,
		focus_on_activate = true,
	},
})

hl.config({
	binds = {
		scroll_event_delay = 0,
		hide_special_on_workspace_change = true,
	},
})

hl.config({
	cursor = {
		no_hardware_cursors = 2,
		zoom_factor = 1,
		zoom_rigid = false,
		zoom_disable_aa = true,
		hotspot_padding = 1,
	},
})
