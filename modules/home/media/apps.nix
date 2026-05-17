{
  pkgs,
  quickshell,
  ...
}: {
  home.packages = with pkgs; [
    imv
    vips
    imagemagick
    evince
    vesktop
    obsidian
    transmission_4-gtk
    video-downloader
    telegram-desktop
    quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
