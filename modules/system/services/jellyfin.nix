{pkgs, ...}: {
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "alpha";
    group = "users";
  };

  systemd.services.jellyfin = {
    after = ["mnt-ssd.mount"];
    requires = ["mnt-ssd.mount"];
  };

  systemd.services.jellyfin-scan = {
    description = "Jellyfin library scan";
    serviceConfig = {
      Type = "oneshot";
      User = "alpha";
      ExecStart = pkgs.writeShellScript "jellyfin-scan" ''
        ${pkgs.curl}/bin/curl -sf \
          -X POST \
          "http://localhost:8096/Library/Refresh" \
          -H "Authorization: MediaBrowser Token=\"$(cat /etc/jellyfin-api-key)\"" \
          || true
      '';
    };
  };

  systemd.timers.jellyfin-scan = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "3min";
      OnUnitActiveSec = "15min";
      Unit = "jellyfin-scan.service";
    };
  };
}
