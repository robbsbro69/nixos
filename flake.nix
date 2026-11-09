{
  description = "NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    reel = {
      url = "git+file:///home/alpha/projects/reel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland/v0.57.2";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    zen-browser,
    quickshell,
    spicetify-nix,
    reel,
    hyprland,
    nix-index-database,
    hyprland-plugins,
    ...
  }: let
    system = "x86_64-linux";

    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit pkgs-unstable hyprland reel;
      };
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        spicetify-nix.nixosModules.default
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.alpha = import ./home.nix;
            extraSpecialArgs = {
              inherit
                zen-browser
                quickshell
                spicetify-nix
                pkgs-unstable
                hyprland
                hyprland-plugins
                ;
            };
            backupFileExtension = "backup";
            sharedModules = [
              nix-index-database.homeModules.nix-index
              {
                # `, cowsay` runs anything without installing it; unknown commands suggest the package
                programs.nix-index.enable = true;
                programs.nix-index.enableFishIntegration = true;
                programs.nix-index-database.comma.enable = true;
                # nh: nicer rebuilds (live build tree via nix-output-monitor + diff of what changed)
                programs.nh = {
                  enable = true;
                  flake = "/home/alpha/nixos-dotfiles";
                };
              }
            ];
          };
        }
      ];
    };
  };
}
