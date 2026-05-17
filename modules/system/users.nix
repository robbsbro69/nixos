{pkgs, ...}: {
  users.users.alpha = {
    isNormalUser = true;
    extraGroups = ["wheel" "vboxusers" "networkmanager"];
    packages = with pkgs; [tree];
  };
  security.sudo.extraRules = [
    {
      users = ["alpha"];
      commands = [
        {
          command = "/run/current-system/sw/bin/systemctl start wg-quick-protonvpn-sys";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/systemctl stop wg-quick-protonvpn-sys";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
  environment.sessionVariables = {
    XCURSOR_SIZE = "24";
    NIXOS_OZONE_WL = "1";
    WLR_GAMMA_CONTROL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_DRM_DEVICES = "/dev/dri/card1";
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent";
  };
}
