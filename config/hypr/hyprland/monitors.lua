-- ~/.config/hypr/hyprland/monitors.lua

-- Both Screens
--hl.monitor({
--	output = "eDP-1",
--	mode = "1920x1080@144",
--	position = "0x0",
--	scale = 1,
--})
--hl.monitor({
--	output = "HDMI-A-1",
--	mode = "1920x1080@60",
--	position = "1920x0",
--	scale = 1,
--})

-- External monitor only ( Laptop Screen Off )
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "0x0", scale = 1 })
hl.monitor({ output = "eDP-1", disabled = true })
--
-- By Default ( Laptop Only )
-- hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
