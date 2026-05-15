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
    ./modules/browsers.nix
    ./modules/desktop.nix
    ./modules/dev.nix
    ./modules/media.nix
    ./modules/packages.nix
    ./modules/shell.nix
    ./modules/symlinks.nix
  ];

  home.username = "alpha";
  home.homeDirectory = "/home/alpha";
  home.stateVersion = "25.11";
}
