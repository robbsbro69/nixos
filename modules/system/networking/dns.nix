{...}: {
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "true";
      DNSOverTLS = "opportunistic";
      Domains = ["~."];
      FallbackDNS = ["8.8.8.8#dns.google"];
    };
  };
  networking.nameservers = [
    "1.1.1.1#cloudflare-dns.com"
    "9.9.9.9#dns.quad9.net"
  ];
}
