{pkgs, ...}: {
  services.mpd-mpris.enable = true;

  home.packages = with pkgs; [
    cava
    rmpc
    mpc
    mpd-mpris
    playerctl
    libnotify
    ffmpeg
    yt-dlp
  ];
}
