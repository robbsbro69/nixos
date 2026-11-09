{pkgs, ...}: {
  services.mpd = {
    enable = true;
    startWhenNeeded = true;
    user = "alpha";
    settings = {
      music_directory = "/home/alpha/Music";
      auto_update = true;
      audio_output = [
        {
          type = "pipewire";
          name = "PipeWire Output";
        }
        {
          type = "fifo";
          name = "my_fifo";
          path = "/tmp/mpd.fifo";
          format = "44100:16:2";
        }
      ];
    };
  };

  systemd.services.mpd.environment = {
    XDG_RUNTIME_DIR = "/run/user/1000";
  };
}
