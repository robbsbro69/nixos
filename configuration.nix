{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];
nixpkgs.config.allowUnfree = true;

boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
boot.blacklistedKernelModules = [ "nouveau" ];

security.rtkit.enable = true;
security.pam.services.hyprlock = {};

hardware.nvidia = {
	open = false;
	modesetting.enable = true;
};
hardware.bluetooth.enable = true;
hardware.bluetooth.powerOnBoot = true;

programs.hyprland = {
	enable = true;
	xwayland.enable = true;
};
programs.firefox = {
	enable = true;
	languagePacks = [ "en-US" ];
};
xdg.portal = {
	enable = true;
	wlr.enable = true;
	extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
};

networking.hostName = "nixos";
networking.networkmanager.enable = true;

time.timeZone = "Asia/Kathmandu";

services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];
services.xserver = {
	enable = true;
	autoRepeatDelay = 200;
	autoRepeatInterval = 35;
};
services.blueman.enable = true;
services.displayManager.ly.enable = true;
services.gvfs.enable = true;
services.udev.packages = with pkgs; [
  libmtp
];
services.pipewire.wireplumber.extraConfig."99-bluetooth-default" = {
	"monitor.bluez.rules" = [
		{
			matches = [{ "device.name" = "~bluez_card.*"; }];
			actions = {
			update-props = {
	"priority.session" = 2000;
        };
      };
    }
  ];
 };

users.users.alpha = {
	isNormalUser = true;
	extraGroups = [ "wheel" ];
	packages = with pkgs; [
       		tree
	];
};

environment.sessionVariables = {
  NIXOS_OZONE_WL = "1";
  WLR_NO_HARDWARE_CURSORS = "1";
  WLR_GAMMA_CONTROL = "1";
  WLR_DRM_DEVICES = "/dev/dri/card1";
  XCURSOR_SIZE = "24";
    QML2_IMPORT_PATH = "/run/current-system/sw/lib/qt-6/qml";  # add this
};

environment.systemPackages = with pkgs; [
	vim
     	wget
	kitty
	nitch
    	pavucontrol
	git
	rustc
	cargo
	rustfmt
	clippy
	grim
	slurp
	playerctl
	brightnessctl
	libnotify
	wl-clipboard
	wlr-randr
	xwayland
	gvfs
	mtpfs
	jmtpfs
	libmtp
	usbutils
	android-tools
	kdePackages.qtsvg
	kdePackages.kio
    	kdePackages.kio-fuse
    	kdePackages.kio-extras
    	kdePackages.dolphin
	kdePackages.kservice
	imagemagick
	qt6.qt5compat
  	qt6.qtimageformats
];

fonts.packages = with pkgs; [ nerd-fonts.jetbrains-mono ];

   
fileSystems."/mnt/ssd" = {
	device = "/dev/disk/by-uuid/61764028-e6aa-4cd3-8bc5-44ad25df22e0";
	fsType = "ext4";
	options = [ "defaults" "nofail" ];
};

fileSystems."/mnt/hdd" = {
	device = "/dev/disk/by-uuid/b0c8283c-f138-4045-9479-71159cea34f7";
	fsType = "ext4";
	options = [ "defaults" "nofail" ];
};


nix.gc = {
	automatic = true;
	dates = "monthly";             
	options = "--delete-older-than 7d";
  };

nix.optimise.automatic = true;



nix.settings = { 
	experimental-features = [ "nix-command" "flakes" ];
    	substituters = [ "https://hyprland.cachix.org" ];
    	trusted-public-keys = [
      		"hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    	];
};

system.stateVersion = "25.11";

}

