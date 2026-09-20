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
    delfin
    telegram-desktop
    transmission_4-gtk
    video-downloader
    (pkgs.callPackage ../../../pkgs/pomodoro-bomb {})
    quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
