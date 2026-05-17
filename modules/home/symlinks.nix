{config, ...}: let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    wal = "wal";
    mpv = "mpv";
    cava = "cava";
    nvim = "nvim";
    hypr = "hypr";
    yazi = "yazi";
    rmpc = "rmpc";
    kitty = "kitty";
    scripts = "scripts";
    starship = "starship";
    fastfetch = "fastfetch";
    quickshell = "quickshell";
  };
in {
  xdg.configFile =
    (builtins.mapAttrs
      (name: subpath: {
        source = create_symlink "${dotfiles}/${subpath}";
        recursive = true;
      })
      configs)
    // {
      "gtk-3.0/gtk.css".enable = false;
      "gtk-4.0/gtk.css".enable = false;
    };
}
