{
  config,
  pkgs,
  pkgs-unstable,
  ...
}: {
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = false;
    package = pkgs-unstable.hyprland;
    portalPackage = pkgs-unstable.xdg-desktop-portal-hyprland;
  };

  programs.appimage.enable = true;
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = [
    pkgs.cudaPackages.cudatoolkit
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
