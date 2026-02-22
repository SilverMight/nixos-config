{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko, ... }@inputs: {
    nixosConfigurations.vps = nixpkgs.lib.nixosSystem {
      modules = [
        disko.nixosModules.disko        
        ./configuration.nix
        ./disk-config.nix
      ];
    };
  };
}
