{
description = "NixOS Flake";

inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
	home-manager = {
		url = "github:nix-community/home-manager/release-25.11";
		inputs.nixpkgs.follows = "nixpkgs";
    };
	zen-browser = {
    		url = "github:0xc000022070/zen-browser-flake";
		inputs.nixpkgs.follows = "nixpkgs";
    };
  };

outputs = { self, nixpkgs, home-manager, zen-browser, ... }:
	let
		system = "x86_64-linux";
	in {
nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
	inherit system;
	modules = [
		./configuration.nix
		home-manager.nixosModules.home-manager
	{
	home-manager = {
		useGlobalPkgs = true;
		useUserPackages = true;
		users.alpha = import ./home.nix;
		extraSpecialArgs = { inherit zen-browser; };
		backupFileExtension = "backup";
          };
        }
      ];
    };
  };
}
