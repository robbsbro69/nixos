{
  pkgs,
  ...
}: {
  users.users.alpha = {
    isNormalUser = true;
    extraGroups = ["wheel" "vboxusers" "networkmanager"];
    packages = with pkgs; [tree];
  };

  environment.sessionVariables = {
    XCURSOR_SIZE = "24";
    NIXOS_OZONE_WL = "1";
    WLR_GAMMA_CONTROL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_DRM_DEVICES = "/dev/dri/card1";
  };
}
