{pkgs, ...}: {
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  home.packages = with pkgs; [
    adwaita-qt
    qt6.qt5compat
    qt6.qtimageformats
  ];
}
