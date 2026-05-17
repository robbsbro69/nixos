{...}: {
  networking.wg-quick.interfaces.protonvpn-sys = {
    configFile = "/etc/wireguard/protonvpn.conf";
    autostart = false;
    dns = ["10.2.0.1"];
  };
}
