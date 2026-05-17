{pkgs, ...}: {
  home.packages = with pkgs; [
    yazi
    eza
    zoxide
    pywal
    fastfetch
    figlet
    upower
    brightnessctl
  ];
}
