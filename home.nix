{
  config,
  pkgs,
  pkgs-unstable,
  zen-browser,
  quickshell,
  spicetify-nix,
  ...
}: {
  imports = [
    ./modules/home/browsers
    ./modules/home/desktop
    ./modules/home/dev
    ./modules/home/media
    ./modules/home/office
    ./modules/home/shell
    ./modules/home/packages.nix
    ./modules/home/symlinks.nix
  ];

  home.username = "alpha";
  home.homeDirectory = "/home/alpha";
  home.stateVersion = "25.11";
}
