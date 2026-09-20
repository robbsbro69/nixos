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
  virtualisation.oci-containers.backend = "podman";

  virtualisation.oci-containers.containers.honne = {
    image = "ghcr.io/gmkonan/honne:latest"; # ← replace with the exact tag from compose.yaml
    autoStart = true;
    ports = ["7417:7417"];
    volumes = ["honne-data:/data"]; # ← match compose.yaml's mount path
    environmentFiles = ["/etc/honne.env"];
  };

  environment.systemPackages = with pkgs; [
    wireguard-tools
    iproute2
  ];

  # Simple Transmission — no VPN namespace
  services.transmission = {
    enable = true;
    openFirewall = true;
    user = "alpha";
    group = "users";
    settings = {
      rpc-bind-address = "127.0.0.1";
      rpc-whitelist-enabled = false;
      rpc-enabled = true;
      rpc-port = 9091;
      download-dir = "/mnt/ssd/torrents/downloads";
      incomplete-dir-enabled = true;
      incomplete-dir = "/mnt/ssd/torrents/incomplete";
      ratio-limit = 2;
      ratio-limit-enabled = true;
    };
  };

  networking.wg-quick.interfaces.protonvpn-sys = {
    configFile = "/etc/wireguard/protonvpn.conf";
    autostart = false;
    dns = ["10.2.0.1"];
  };
}
