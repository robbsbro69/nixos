{
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports =
    [
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
      ./modules/system/packages.nix
    ]
    ++ (
      # private extras (not in this repo) - loaded only if present; needs --impure
      let
        priv = /home/alpha/nixos-private;
      in
        if builtins.pathExists (priv + "/default.nix")
        then [priv]
        else []
    );

  nixpkgs.config.allowUnfree = true;

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  system.stateVersion = "26.05";
}
