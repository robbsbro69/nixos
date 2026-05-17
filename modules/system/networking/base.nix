{...}: {
  networking.hostName = "nixos";
  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";
  };
  networking.nameservers = [];
  time.timeZone = "Asia/Kathmandu";
}
