{
  pkgs,
  spicetify-nix,
  quickshell,
  ...
}: let
  spicePkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    spicetify-nix.homeManagerModules.default
  ];

  programs.spicetify = {
    enable = true;
    enabledExtensions = with spicePkgs.extensions; [
      adblock
      hidePodcasts
      shuffle
    ];
    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";
  };

  programs.mpv = {
    enable = true;
    scripts = [
      pkgs.mpvScripts.mpris
    ];
  };

  home.packages = with pkgs; [
    cava
    rmpc
    playerctl
    libnotify
    ffmpeg
    yt-dlp
    imv
    vips
    imagemagick
    evince
    obsidian
    transmission_4-gtk
    video-downloader
    telegram-desktop
    quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
