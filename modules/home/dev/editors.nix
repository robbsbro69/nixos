{pkgs, ...}: {
  home.packages = with pkgs; [
    neovim
    # LSP / formatters
    nil
    biome
    alejandra
    stylua
    prettierd
    nodePackages.prettier
    lua-language-server
  ];
}
