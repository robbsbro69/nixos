{
description = "NixOS Flake";

inputs = {
	nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
	nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
	home-manager = {
		url = "github:nix-community/home-manager/release-25.11";
		inputs.nixpkgs.follows = "nixpkgs";
    	};
	  quickshell = {
    		url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
    		inputs.nixpkgs.follows = "nixpkgs-unstable";  # point at unstable
  	};
  };

outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, quickshell, ... }:
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
		extraSpecialArgs = { 
			inherit quickshell;
			pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
		};
		backupFileExtension = "backup";
          };
        }
      ];
    };
  };
}
