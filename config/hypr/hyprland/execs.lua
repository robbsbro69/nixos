-- ~/.config/hypr/hyprland/execs.lua
hl.on("hyprland.start", function()
	local startup = {
		"ssh-add /home/alpha/.ssh/id_ed25519",
		"awww-daemon",
		"wal --theme catppuccin-mocha-pink -n -q",
		"/home/alpha/.config/scripts/nightlight.sh restore",
		"systemctl --user start hypridle",
		"wl-paste --type text --watch cliphist store",
		"wl-paste --type image --watch cliphist store",
		"/run/current-system/sw/libexec/polkit-gnome-authentication-agent-1",
		"kdeconnect-indicator",
		"sleep 1 && QS_DROP_EXPENSIVE_FONTS=1 quickshell -p /home/alpha/.config/quickshell",
	}

	for _, cmd in ipairs(startup) do
		hl.exec_cmd(cmd)
	end
end)
