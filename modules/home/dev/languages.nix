{pkgs, ...}: {
  home.packages = with pkgs; [
    nodejs
    gcc
    rustup
  ];
}
