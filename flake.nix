{
  description = "Multi-OS Nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    deploy-rs.url = "github:serokell/deploy-rs";
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    system = "aarch64-linux";
    pkgs = import nixpkgs { inherit system; };
    deployPkgs = import nixpkgs {
      inherit system;
      overlays = [
        inputs.deploy-rs.overlays.default
        (self: super: {
          deploy-rs = {
            inherit (pkgs) deploy-rs;
            lib = super.deploy-rs.lib;
          };
        })
      ];
    };
  in {
    nixosConfigurations = {
      rpi4 = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          inputs.sops-nix.nixosModules.sops
          ./hosts/rpi/configuration.nix
        ];
      };
      
      vps = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          inputs.disko.nixosModules.disko
          inputs.sops-nix.nixosModules.sops
          ./hosts/vps/configuration.nix
        ];
      };
    };

    deploy.nodes = {
      rpi4 = {
        hostname = "rpi.local";
        profiles.system = {
          remoteBuild = true;
          sshUser = "silvermight";
          path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.rpi4;
          user = "root";
        };
      };

      vps = {
        hostname = "vps.silvermight.com";
        profiles.system = {
          remoteBuild = true;
          sshUser = "silvermight";
          path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.vps;
          user = "root";
        };
      };
    };

    # This is highly recommended by deploy-rs
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) inputs.deploy-rs.lib;
  };
}
