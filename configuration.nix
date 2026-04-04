{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];
nixpkgs.config.allowUnfree = true;
boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;
 
security.rtkit.enable = true;
services.xserver.videoDrivers = [ "amdgpu" "nvidia" ];
boot.blacklistedKernelModules = [ "nouveau" ];
hardware.nvidia = {
	open = false;
	modesetting.enable = true;
};

environment.sessionVariables = {
  NIXOS_OZONE_WL = "1";
  WLR_NO_HARDWARE_CURSORS = "1";
};

xdg.portal = {
	enable = true;
	extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
};

programs.niri.enable = true;

networking.hostName = "nixos";
networking.networkmanager.enable = true;

hardware.bluetooth.enable = true;
hardware.bluetooth.powerOnBoot = true;
services.blueman.enable = true;

time.timeZone = "Asia/Kathmandu";

services.xserver = {
	enable = true;
	autoRepeatDelay = 200;
	autoRepeatInterval = 35;
};

services.displayManager.ly.enable = true;
services.jellyfin.enable = true;
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
	extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
	packages = with pkgs; [
       				tree
	];
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
	fuzzel
	swaylock
	swayidle
	swaybg
	wl-clipboard
	grim
	slurp
	wlr-randr
	xwayland
	waybar
	playerctl
	dunst
	brightnessctl
	libnotify
	socat
];

fonts.packages = with pkgs; [ nerd-fonts.jetbrains-mono ];

   
fileSystems."/mnt/ssd" = {
	device = "/dev/disk/by-uuid/61764028-e6aa-4cd3-8bc5-44ad25df22e0";
	fsType = "ext4";
	options = [ "defaults" "nofail" ];
};


nix.settings.experimental-features = [ "nix-command" "flakes" ];

system.stateVersion = "25.11";

}

