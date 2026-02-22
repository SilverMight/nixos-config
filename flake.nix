{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko, sops-nix, ... }@inputs: {
    nixosConfigurations.vps = nixpkgs.lib.nixosSystem {
      modules = [
        disko.nixosModules.disko
        sops-nix.nixosModules.sops
        ./configuration.nix
        ./disk-config.nix
      ];
    };
  };
}
