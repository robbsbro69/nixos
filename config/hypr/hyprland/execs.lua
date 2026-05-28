-- ~/.config/hypr/hyprland/execs.lua
hl.on("hyprland.start", function()
	local startup = {
		"ssh-add /home/alpha/.ssh/id_ed25519",
		"swww-daemon",
		"wal --theme catppuccin-mocha-pink -n -q",
		"gammastep -O 3000 -m wayland",
		"systemctl --user start hypridle",
		"[workspace 1 silent] zen-beta",
		"[workspace 2 silent] obsidian",
		"[workspace 3 silent] spotify",
		"sleep 3 && env ELECTRON_OZONE_PLATFORM_HINT=auto appimage-run $(ls /home/alpha/AppImages/ticktick/*.AppImage | tail -1)",
		"wl-paste --type text --watch cliphist store",
		"wl-paste --type image --watch cliphist store",
		"/run/current-system/sw/libexec/polkit-gnome-authentication-agent-1",
		"sleep 1 && QS_DROP_EXPENSIVE_FONTS=1 quickshell -p /home/alpha/.config/quickshell",
	}

	for _, cmd in ipairs(startup) do
		hl.exec_cmd(cmd)
	end
end)
