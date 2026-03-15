{
  description = "Multi-OS Nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    
    headplane.url = "github:tale/headplane";
    headplane.inputs.nixpkgs.follows = "nixpkgs";
    
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations = {
      rpi4 = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          inputs.sops-nix.nixosModules.sops
          ./hosts/rpi/configuration.nix
        ];
      };
      
      vps = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          inputs.disko.nixosModules.disko
          inputs.headplane.nixosModules.headplane
          inputs.sops-nix.nixosModules.sops
          ./hosts/vps/configuration.nix
          {
            nixpkgs.overlays = [
              inputs.headplane.overlays.default
            ];
          }
        ];
      };
    };
  };
}
