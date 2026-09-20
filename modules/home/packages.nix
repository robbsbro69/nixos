{pkgs, ...}: {
  home.packages = with pkgs; [
    eza
    yazi
    pywal
    zoxide
    figlet
    upower
    nitch
    fastfetch
    brightnessctl
  ];
}
