{...}: {
  services.resolved = {
    enable = true;
    dnssec = "true";
    dnsovertls = "opportunistic";
    extraConfig = ''
      DNS=1.1.1.1#cloudflare-dns.com 9.9.9.9#dns.quad9.net
      FallbackDNS=8.8.8.8#dns.google
      DNSOverTLS=opportunistic
    '';
  };
}
