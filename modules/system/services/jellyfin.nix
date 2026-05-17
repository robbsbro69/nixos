{...}: {
  services.jellyfin = {
    enable = true;
    openFirewall = false;
    user = "alpha";
    group = "users";
  };
}
