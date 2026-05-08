{
  config,
  pkgs,
  zen-browser,
  quickshell,
  spicetify-nix,
  ...
}: let
  spicePkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    wal = "wal";
    mpv = "mpv";
    cava = "cava";
    nvim = "nvim";
    hypr = "hypr";
    yazi = "yazi";
    kitty = "kitty";
    scripts = "scripts";
    starship = "starship";
    fastfetch = "fastfetch";
    quickshell = "quickshell";
  };
in {
  imports = [
    zen-browser.homeModules.default
    spicetify-nix.homeManagerModules.default
  ];
  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;
    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DisablePocket = true;
    };
  };
  programs.spicetify = {
    enable = true;
    enabledExtensions = with spicePkgs.extensions; [
      adblock
      hidePodcasts
      shuffle
    ];
    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";
  };

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = false;
  };

  home.username = "alpha";
  home.homeDirectory = "/home/alpha";
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."github.com" = {
      hostname = "github.com";
      user = "git";
      identityFile = "~/.ssh/id_ed25519";
    };
  };

  programs.mpv = {
    enable = true;
    scripts = [
      pkgs.mpvScripts.mpris
    ];
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "robbsbro69";
        email = "robbsbro369@proton.me";
      };
      init.defaultBranch = "main";
    };
  };

  home.stateVersion = "25.11";
  programs.bash = {
    enable = true;
    shellAliases = {
      btw = "echo i use nixos, btw";
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos";
      nuprs = "nix flake update && sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos";
      gnrs = "git add . && git commit -m \"update\" && nrs";
      ls = "eza --icons";
      ff = "fastfetch --logo \"$(find ~/.config/fastfetch/logo -type f | shuf -n 1)\" --logo-type kitty --logo-height 18";
      gf = "fastfetch --logo \"$(find ~/Pictures/Dump_fastfetch_logo/FastFetch -type f | shuf -n 1)\" --logo-type kitty --logo-height 18";
      ll = "eza -l --icons";
      webp2png = ''
        		for f in *.webp; do
        magick "$f" "''${f%.webp}.png" && rm "$f"
        done
      '';
    };
    initExtra = ''
       	export PATH="$HOME/.cargo/bin:$PATH"
      export FZF_DEFAULT_OPTS=" \
      --color=bg+:#313244,bg:#1E1E2E,spinner:#F5E0DC,hl:#F38BA8 \
      --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC \
      --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8 \
      --color=selected-bg:#45475A \
      --color=border:#6C7086,label:#CDD6F4"
    '';
  };

  programs.starship = {
    enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
      cursor-theme = "Adwaita";
      cursor-size = 24;
    };
  };
  home.pointerCursor = {
    gtk.enable = true;
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
  };

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

  home.packages = with pkgs; [
    jq
    zip
    nil
    gcc
    eza
    fzf
    imv
    mpd
    htop
    yazi
    tmux
    swww
    rmpc
    vips
    cava
    pywal
    unzip
    brave
    neovim
    nodejs
    evince
    upower
    figlet
    ffmpeg
    zoxide
    stylua
    yt-dlp
    ripgrep
    cmatrix
    adw-gtk3
    cliphist
    hyprlock
    hypridle
    obsidian
    fastfetch
    gammastep
    playerctl
    libnotify
    alejandra
    prettierd
    librewolf
    libreoffice
    imagemagick
    nixpkgs-fmt
    brightnessctl
    qt6.qt5compat
    video-downloader
    transmission_4-gtk
    qt6.qtimageformats
    nodePackages.prettier
    quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
