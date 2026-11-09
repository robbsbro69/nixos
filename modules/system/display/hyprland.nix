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
    portalPackage = hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };


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
