{...}: {
  programs.bash = {
    enable = true;
    shellAliases = {
      btw = "echo i use nixos, btw";
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos";
      nuprs = "nix flake update && sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos";
      gnrs = "git add . && git commit -m \"update\" && nrs";
      ls = "eza --icons";
      ll = "eza -l --icons";
      ff = "fastfetch --logo \"$(find ~/.config/fastfetch/logo -type f | shuf -n 1)\" --logo-type kitty --logo-height 18";
      gf = "fastfetch --logo \"$(find ~/Pictures/Dump_fastfetch_logo/FastFetch -type f | shuf -n 1)\" --logo-type kitty --logo-height 18";
      webp2png = ''
        for f in *.webp; do
          magick "$f" "''${f%.webp}.png" && rm "$f"
        done
      '';
      zip2cbz = ''
        for f in *.zip; do
          mv -- "$f" "''${f%.zip}.cbz"
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
}
