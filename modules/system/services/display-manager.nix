{pkgs, ...}: {
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "catppuccin-mocha-pink";
    package = pkgs.kdePackages.sddm;
  };
}
