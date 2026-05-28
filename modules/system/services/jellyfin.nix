{...}: {
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "alpha";
    group = "users";
  };
}
