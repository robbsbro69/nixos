{...}: {
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
}
