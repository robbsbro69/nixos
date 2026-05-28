{pkgs, ...}: {
  home.packages = with pkgs; [
    libreoffice-fresh
    obsidian
    xournalpp
  ];
}
