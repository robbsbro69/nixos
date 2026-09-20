{pkgs, ...}: {
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
      # Optional but nice
      ratio-limit = 2;
      ratio-limit-enabled = true;
    };
  };

  # Keep the system wg-quick interface for manual VPN use if you want
  networking.wg-quick.interfaces.protonvpn-sys = {
    configFile = "/etc/wireguard/protonvpn.conf";
    autostart = false;
    dns = ["10.2.0.1"];
  };
}
