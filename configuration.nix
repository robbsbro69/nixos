{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
  ];
  nixpkgs.config.allowUnfree = true;

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  boot.kernelPackages = pkgs.linuxPackages;
  boot.blacklistedKernelModules = ["nouveau"];
  boot.kernelModules = ["vboxdrv" "vboxnetflt" "vboxnetadp"];

  security.rtkit.enable = true;
  security.pam.services.hyprlock = {};

  hardware.nvidia = {
    open = false;
    modesetting.enable = true;
  };
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  programs.appimage.enable = true;

  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };

  networking.hostName = "nixos";
  networking.networkmanager = {
    enable = true;
    dns = "none";
  };
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
    "one.one.one.one"
  ];
  time.timeZone = "Asia/Kathmandu";

  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "alpha";
    group = "users";
  };

  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    videoDrivers = ["amdgpu" "nvidia"];
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
        matches = [{"device.name" = "~bluez_card.*";}];
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
    extraGroups = ["wheel" "vboxusers"];
    packages = with pkgs; [
      tree
    ];
  };

  environment.sessionVariables = {
    XCURSOR_SIZE = "24";
    NIXOS_OZONE_WL = "1";
    WLR_GAMMA_CONTROL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_DRM_DEVICES = "/dev/dri/card1";
  };

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    htop
    grim
    gvfs
    kitty
    nitch
    rustc
    cargo
    slurp
    mtpfs
    jmtpfs
    libmtp
    clippy
    rustfmt
    usbutils
    xwayland
    jellyfin
    playerctl
    wlr-randr
    libnotify
    xfce.thunar
    wf-recorder
    pavucontrol
    imagemagick
    xfce.tumbler
    wl-clipboard
    jellyfin-web
    android-tools
    qt6.qt5compat
    brightnessctl
    rust-analyzer
    jellyfin-ffmpeg
    jellyfin-desktop
    qt6.qtimageformats
    xfce.thunar-volman
    xfce.thunar-archive-plugin
    (python3.withPackages (ps:
      with ps; [
        dbus-python
        pygobject3
        flask
        requests
      ]))
  ];

  fonts.packages = with pkgs; [nerd-fonts.jetbrains-mono];

  fileSystems."/mnt/ssd" = {
    device = "/dev/disk/by-uuid/61764028-e6aa-4cd3-8bc5-44ad25df22e0";
    fsType = "ext4";
    options = ["defaults" "nofail"];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nix.optimise.automatic = true;

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  system.stateVersion = "25.11";
}
