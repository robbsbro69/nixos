{
  pkgs,
  pkgs-unstable,
  ...
}: {
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
    package = pkgs-unstable.hyprland;
  };

  home.packages = with pkgs; [
    hyprlock
    hypridle
    swww
    gammastep
    cliphist
    polkit_gnome
  ];
}
