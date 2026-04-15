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
		dunst = "dunst";
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
		identityFile = "~/.ssh/id_ed25519";
	};
};

programs.git = {
	enable = true;
	settings = {
	user = {
		name = " rusty067";
		email = "getrusty69@gmail.com";
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
		export FZF_DEFAULT_OPTS=" \
		--color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
		--color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
		--color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
		--color=selected-bg:#45475A \
		--color=border:#6C7086,label:#CDD6F4"
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
	yazi
	brave
	adwaita-icon-theme
	mpv
	eza
	fzf
	zoxide
	gammastep
	transmission_4-gtk
	hyprlock
	hypridle
	hyprpaper
	imv
	figlet
	tmux
	unzip
	video-downloader
];
}
