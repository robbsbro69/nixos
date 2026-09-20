{pkgs, ...}: {
  home.packages = with pkgs; [
    nil
    biome
    stylua
    neovim
    alejandra
    prettierd
    lua-language-server
    prettier
    arduino-ide
  ];
}
