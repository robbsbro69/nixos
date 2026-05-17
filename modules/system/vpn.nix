{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    wireguard-tools
    iproute2
    gnugrep
    socat
  ];

  # 1. Create the isolated network namespace
  systemd.services.vpn-netns = {
    description = "VPN network namespace for Transmission";
    before = ["transmission.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.iproute2}/bin/ip netns add vpnns";
      ExecStop = "${pkgs.iproute2}/bin/ip netns del vpnns";
    };
  };

  # 2. Bring ProtonVPN WireGuard up inside the namespace
  systemd.services.protonvpn-netns = {
    description = "ProtonVPN WireGuard inside vpnns namespace";
    after = ["vpn-netns.service" "network-online.target"];
    before = ["transmission.service"];
    requires = ["vpn-netns.service"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "10s";
      ExecStart = pkgs.writeShellScript "protonvpn-up" ''
        # Create in root namespace, then move into vpnns
        ${pkgs.iproute2}/bin/ip link add dev protonvpn type wireguard
        ${pkgs.iproute2}/bin/ip link set protonvpn netns vpnns

        # Strip wg-quick-only directives (Address=, DNS=, etc.)
        ${pkgs.gnugrep}/bin/grep -v -E '^\s*(Address|DNS|PostUp|PostDown|Table|MTU)\s*=' \
          /etc/wireguard/protonvpn.conf > /tmp/protonvpn-wg.conf

        # Apply peer config
        ${pkgs.iproute2}/bin/ip netns exec vpnns \
          ${pkgs.wireguard-tools}/bin/wg setconf protonvpn /tmp/protonvpn-wg.conf

        ${pkgs.iproute2}/bin/ip netns exec vpnns \
          ${pkgs.iproute2}/bin/ip addr add 10.2.0.2/32 dev protonvpn
        ${pkgs.iproute2}/bin/ip netns exec vpnns \
          ${pkgs.iproute2}/bin/ip link set protonvpn up
        ${pkgs.iproute2}/bin/ip netns exec vpnns \
          ${pkgs.iproute2}/bin/ip route add default dev protonvpn
        ${pkgs.iproute2}/bin/ip netns exec vpnns \
          ${pkgs.iproute2}/bin/ip link set lo up
      '';

      ExecStop = pkgs.writeShellScript "protonvpn-down" ''
        ${pkgs.iproute2}/bin/ip netns exec vpnns \
          ${pkgs.iproute2}/bin/ip link del protonvpn
      '';
    };
  };

  # 3. Transmission locked inside the namespace (kill-switch built-in)
  services.transmission = {
    enable = true;
    openFirewall = false;
    user = "alpha";
    group = "users";
    settings = {
      rpc-bind-address = "127.0.0.1";
      rpc-whitelist-enabled = false;
      rpc-enabled = true;
      rpc-port = 9091;
      download-dir = "/home/alpha/Downloads";
      incomplete-dir-enabled = true;
      incomplete-dir = "/home/alpha/Downloads/.incomplete";
    };
  };

  # Override the transmission unit to run inside vpnns
  systemd.services.transmission = {
    after = ["protonvpn-netns.service"];
    requires = ["protonvpn-netns.service"];
    serviceConfig = {
      NetworkNamespacePath = "/var/run/netns/vpnns";
    };
  };

  # Proxy localhost:9091 on host → 127.0.0.1:9091 inside namespace
  systemd.services.transmission-proxy = {
    description = "Proxy host:9091 into transmission namespace";
    after = ["transmission.service"];
    requires = ["transmission.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "transmission-proxy" ''
        exec ${pkgs.socat}/bin/socat \
          TCP-LISTEN:9091,fork,reuseaddr \
          EXEC:"${pkgs.iproute2}/bin/ip netns exec vpnns ${pkgs.socat}/bin/socat STDIO TCP\:127.0.0.1\:9091"
      '';
      Restart = "always";
      RestartSec = "2s";
    };
  };
}
