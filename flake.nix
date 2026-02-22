{
  description = "A simple NixOS flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    headplane.url = "github:tale/headplane";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko, headplane, sops-nix, ... }@inputs: {
    nixosConfigurations.vps = nixpkgs.lib.nixosSystem {
      modules = [
        disko.nixosModules.disko
        headplane.nixosModules.headplane
        sops-nix.nixosModules.sops
        ./configuration.nix
        ./disk-config.nix
      ];
      specialArgs = { inherit inputs; };
      extraModules = [
        ({ pkgs, ... }: {
          nixpkgs.overlays = [
            headplane.overlays.default
          ];
        })
      ];
    };
  };
}
