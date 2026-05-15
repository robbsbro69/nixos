{
  pkgs,
  ...
}: {
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "robbsbro69";
        email = "robbsbro369@proton.me";
      };
      init.defaultBranch = "main";
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."github.com" = {
      hostname = "github.com";
      user = "git";
      identityFile = "~/.ssh/id_ed25519";
    };
  };

  home.packages = with pkgs; [
    # editors / lsp
    neovim
    nil
    alejandra
    nixpkgs-fmt
    stylua
    prettierd
    nodePackages.prettier

    # languages / runtimes
    nodejs
    gcc

    # search / file tools
    ripgrep
    fzf
    jq
    zip
    unzip

    # misc dev
    tmux
    htop
  ];
}
