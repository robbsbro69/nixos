{pkgs, ...}: {
  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    user = "alpha";
    group = "users";
    openRPCPort = false;
    settings = {
      download-dir = "/mnt/ssd/Downloads/complete";
      incomplete-dir = "/mnt/ssd/Downloads/incomplete";
      incomplete-dir-enabled = true;
      rpc-bind-address = "0.0.0.0";
      rpc-whitelist-enabled = true;
      rpc-whitelist = "127.0.0.1,192.168.*.*";
      rpc-host-whitelist-enabled = false;

      # new: stop seeding, so Radarr/Sonarr can remove finished torrents
      ratio-limit = 1.0;
      ratio-limit-enabled = true;
      idle-seeding-limit = 30;
      idle-seeding-limit-enabled = true;
      speed-limit-down-enabled = true;
      speed-limit-down = 3000;
      speed-limit-up-enabled = true;
      speed-limit-up = 300;
      peer-limit-global = 100;
      peer-limit-per-torrent = 30;
      download-queue-size = 2;
    };
  };

  # don't start before the SSD is mounted
  systemd.services.transmission.unitConfig.RequiresMountsFor = ["/mnt/ssd"];
  systemd.services.transmission.serviceConfig.Restart = "on-failure";
}
