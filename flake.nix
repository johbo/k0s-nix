{
  description = "k0s - The Zero Friction Kubernetes for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

  outputs = { self, nixpkgs }: {

    packages =
      let
        lib = nixpkgs.lib;
        allSystems = [ "armv7l-linux" "aarch64-linux" "x86_64-linux" ];
        forAllSystems = lib.genAttrs allSystems;
      in
        forAllSystems (system:
          let
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
          in rec {
            inherit (pkgs.callPackage ./k0s/default.nix {})
              k0s_1_28;
            k0s = k0s_1_28;
          }
        );

    nixosConfigurations = {
      test = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          ./nixos/k0s.nix
          ({pkgs, ... }: {
            boot.isContainer = true;

            services.k0s.enable = true;
          })
        ];
      };
    };

    nixosModules = {
      k0s = import ./nixos/k0s.nix;
    };

  };
}
