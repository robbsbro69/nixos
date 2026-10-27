{...}: {
  networking.hostName = "nixos";
  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
  };
  networking.nameservers = [];
  time.timeZone = "Asia/Kathmandu";
  networking.firewall.allowedTCPPorts = [51413];
  networking.firewall.allowedUDPPorts = [51413 5353];
}
