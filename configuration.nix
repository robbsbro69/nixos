{
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./modules/system/hardware.nix
    ./modules/system/networking.nix
    ./modules/system/nix.nix
    ./modules/system/services.nix
    ./modules/system/users.nix
  ];

  nixpkgs.config.allowUnfree = true;

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  system.stateVersion = "25.11";
}
