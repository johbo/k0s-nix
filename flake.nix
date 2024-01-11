{
  description = "k0s - The Zero Friction Kubernetes for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

  outputs = { self, nixpkgs }: {

    nixosConfigurations = {
      test = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./k0s-module.nix
          ({pkgs, ... }: {
            boot.isContainer = true;

            services.k0s.enable = true;
          })
        ];
      };
    };

    nixosModules = {
      k0s = import ./k0s-module.nix;
    };

  };
}
