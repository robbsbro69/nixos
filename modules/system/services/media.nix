{...}: {
  services.mpd = {
    enable = true;
    startWhenNeeded = true;
    user = "alpha";
    musicDirectory = "/home/alpha/Music";
    extraConfig = ''
      auto_update "yes"
      audio_output {
        type "pipewire"
        name "PipeWire Output"
      }
      audio_output {
        type "fifo"
        name "my_fifo"
        path "/tmp/mpd.fifo"
        format "44100:16:2"
      }
    '';
  };

  systemd.services.mpd.environment = {
    XDG_RUNTIME_DIR = "/run/user/1000";
  };
}
