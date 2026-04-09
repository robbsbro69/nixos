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
  WLR_GAMMA_CONTROL = "1";
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
	grim
	slurp
	waybar
	playerctl
	dunst
	brightnessctl
	libnotify
	socat
	swaylock
	swayidle
	swaybg
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
	kdePackages.kio # needed since 25.11
    	kdePackages.kio-fuse #to mount remote filesystems via FUSE
    	kdePackages.kio-extras #extra protocols support (sftp, fish and more)
    	kdePackages.dolphin # This is the actual dolphin package
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

