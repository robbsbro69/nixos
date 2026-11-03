{
  config,
  pkgs,
  pkgs-unstable,
  hyprland,
  lib,
  ...
}: {
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = false;
    package = hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = pkgs-unstable.xdg-desktop-portal-hyprland;
  };


 # flake 0.57 compositor auto-adds its own 1.3.12 portal; pin to one to avoid a dup unit
 xdg.portal.extraPortals = lib.mkForce [ pkgs-unstable.xdg-desktop-portal-hyprland ];
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  programs.nix-ld.enable = true;
  programs.gpu-screen-recorder.enable = true;
  programs.nix-ld.libraries = [
    config.hardware.nvidia.package
  ];
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
    package = pkgs-unstable.virtualbox;
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
}
