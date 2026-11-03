{pkgs, ...}: {
  users.users.alpha = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = ["wheel" "vboxusers" "networkmanager" "dialout" "i2c"];
    packages = with pkgs; [tree];
  };


 programs.fish.enable = true;
  environment.sessionVariables = {
    XCURSOR_SIZE = "24";
    NIXOS_OZONE_WL = "1";
    WLR_GAMMA_CONTROL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    AQ_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card2";
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent";
    "__GL_THREADED_OPTIMIZATIONS" = "0";
  };
}
