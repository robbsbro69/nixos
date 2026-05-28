{
  pkgs,
  spicetify-nix,
  ...
}: let
  spicePkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    spicetify-nix.homeManagerModules.default
  ];

  programs.spicetify = {
    enable = true;
    enabledExtensions = with spicePkgs.extensions; [
      adblock
      hidePodcasts
      shuffle
    ];
    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";
  };

  xdg.desktopEntries.spotify = {
    name = "Spotify";
    exec = "spotify --no-zygote %U";
    icon = "spotify";
    terminal = false;
    categories = ["Audio" "Music"];
  };
}
