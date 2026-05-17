{pkgs, ...}: {
  home.packages = with pkgs; [
    ripgrep
    fzf
    jq
    zip
    unzip
    tmux
    htop
    mold
  ];
}
