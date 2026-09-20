{
  pkgs,
  kopuz,
  ...
}: {
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
    gammastep
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
    thunar
    tumbler
    thunar-volman
    thunar-archive-plugin
    podman-compose

    # jellyfin stack
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg

    # terminal
    kitty

    # android
    android-tools

    # qt / gtk
    qt6.qt5compat
    qt6.qtimageformats
    (pkgs.catppuccin-sddm.override {
      flavor = "mocha";
      accent = "pink";
      font = "JetBrainsMono Nerd Font";
      fontSize = "10";
    })

    # python (for scripts / quickshell servers)
    (python3.withPackages (ps:
      with ps; [
        dbus-python
        pygobject3
        flask
        requests
      ]))

    kopuz.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
