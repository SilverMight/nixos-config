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

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
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

    deploy.nodes = {


      rpi4 = {
        hostname = "rpi.local";
        profiles.system = {
          sshUser = "silvermight";
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.rpi4;
          user = "root";
        };
      };

      vps = {
        hostname = "vps.silvermight.com";
        profiles.system = {
          sshUser = "silvermight";
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.vps;
          user = "root";
        };
      };
    };

    # This is highly recommended by deploy-rs
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;
  };
}
