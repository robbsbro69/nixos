{...}: {
  imports = [
    ./audio.nix
    ./display-manager.nix
    ./jellyfin.nix
    ./media.nix
    ./misc.nix
    ./udev.nix
    ./transmission.nix
    ./tailscale.nix
    ./vnstat.nix
  ];
}
