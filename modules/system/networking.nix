{
  ...
}: {
  networking.hostName = "nixos";
  networking.networkmanager = {
    enable = true;
    dns = "none";
  };
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
    "one.one.one.one"
  ];

  time.timeZone = "Asia/Kathmandu";
}
