{pkgs, ...}: {
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "alpha";
    group = "users";
  };

  services.blueman.enable = true;
  services.gvfs.enable = true;
  services.dbus.enable = true;
  services.udisks2.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "catppuccin-mocha-mauve";
    package = pkgs.kdePackages.sddm;
  };
  services.udev.packages = with pkgs; [libmtp];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.pipewire.wireplumber.extraConfig."99-bluetooth-default" = {
    "monitor.bluez.rules" = [
      {
        matches = [{"device.name" = "~bluez_card.*";}];
        actions = {
          update-props = {
            "priority.session" = 2000;
          };
        };
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    # core utils
    vim
    git
    wget
    xdg-utils

    # wayland / display
    grim
    slurp
    xwayland
    wlr-randr
    wf-recorder
    wl-clipboard

    # audio / media
    pavucontrol

    # file management
    gvfs
    mtpfs
    jmtpfs
    libmtp
    usbutils
    xfce.thunar
    xfce.tumbler
    xfce.thunar-volman
    xfce.thunar-archive-plugin

    # jellyfin stack
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    jellyfin-desktop

    # display / notifications
    kitty
    nitch

    # android
    android-tools

    # qt / gtk
    qt6.qt5compat
    qt6.qtimageformats
    (pkgs.catppuccin-sddm.override {
      flavor = "mocha";
      accent = "mauve";
      font = "JetBrainsMono Nerd Font";
      fontSize = "10";
    })

    # rust toolchain
    rustc
    cargo
    clippy
    rustfmt
    rust-analyzer

    # python (for scripts / quickshell servers)
    (python3.withPackages (ps:
      with ps; [
        dbus-python
        pygobject3
        flask
        requests
      ]))
  ];
}
