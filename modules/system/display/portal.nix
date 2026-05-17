{
  pkgs,
  pkgs-unstable,
  ...
}: {
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs-unstable.xdg-desktop-portal-hyprland
    ];
    config.common.default = "*";
  };
}
