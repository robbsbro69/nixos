{ config, pkgs, zen-browser, ... }:
let
	dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
	create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
	configs = {
		nvim = "nvim";
		kitty = "kitty";
		hypr = "hypr";
		waybar = "waybar";
		fuzzel = "fuzzel";
		mpv = "mpv";
		yazi = "yazi";
		starship = "starship";
  };
in {
	imports = [ zen-browser.homeModules.default ];

	programs.zen-browser = {
		enable = true;
		setAsDefaultBrowser = true;
		policies = {
			DisableAppUpdate = true;
			DisableTelemetry = true;
			DisablePocket = true;
		};
	};

wayland.windowManager.hyprland = {
	enable = true;
	systemd.enable = false;
};

home.username = "alpha";
home.homeDirectory = "/home/alpha";
programs.ssh = {
	enable = true;
	enableDefaultConfig = false;
	matchBlocks."github.com" = {
		hostname = "github.com";
		user = "git";
		identityFile = "~/.ssh/id_ed25519_main";
	};
};

programs.git = {
	enable = true;
	settings = {
	user = {
		name = "robbsbro69";
		email = "robbsbro369@proton.me";
		};
	init.defaultBranch =  "main";
	};
  };

home.stateVersion = "25.11";
programs.bash = {
	enable = true;
	shellAliases = {
		btw = "echo i use nixos, btw";
		nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos";
		nuprs = "nix flake update && sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos";
		gnrs = "git add . && git commit -m \"update\" && nrs";
		ls = "eza --icons";
		ll = "eza -l --icons";
};
	initExtra = ''
	  	export PATH="$HOME/.cargo/bin:$PATH"
		'';
};

programs.starship = {
	enable = true;
};

xdg.configFile = builtins.mapAttrs
  (name: subpath: {
    source = create_symlink "${dotfiles}/${subpath}";
    recursive = true;
})
configs;

home.packages = with  pkgs; [
	neovim
	ripgrep
	nil
	nixpkgs-fmt
	nodejs
	gcc
  	fuzzel
  	obsidian
  	spotify
	evince
	blueman
	yazi
	brave
	adwaita-icon-theme
	mpv
	eza
	fzf
	zoxide
	gammastep
	fastfetch
	transmission_4-gtk
	telegram-desktop
	hyprlock
	hypridle
	hyprpaper
	btop
	imv
];
}
