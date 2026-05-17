{
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./modules/system/boot
    ./modules/system/hardware
    ./modules/system/display
    ./modules/system/networking
    ./modules/system/services
    ./modules/system/fonts.nix
    ./modules/system/nix.nix
    ./modules/system/security.nix
    ./modules/system/users.nix
    ./modules/system/vpn.nix
    ./modules/system/packages.nix
  ];

  nixpkgs.config.allowUnfree = true;

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  system.stateVersion = "25.11";
}
