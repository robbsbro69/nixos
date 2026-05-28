{pkgs, ...}: {
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
      cursor-theme = "Adwaita";
      cursor-size = 24;
    };
  };

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    hyprcursor.enable = true;
    hyprcursor.size = 24;
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
  };
}
