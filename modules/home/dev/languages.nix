{pkgs, ...}: {
  home.packages = with pkgs; [
    nodejs
    gcc
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer
  ];
}
