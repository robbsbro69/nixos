{pkgs, ...}: {
  #services.mpd-mpris.enable = true;

  home.packages = with pkgs; [
    mpc
    cava
    rmpc
    ffmpeg
    yt-dlp
    mpd-mpris
    playerctl
    libnotify
  ];
}
