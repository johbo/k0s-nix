{
  description = "k0s - The Zero Friction Kubernetes for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

  outputs = { self, nixpkgs }: rec {

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

    overlays.default = final: prev: rec {
      inherit (prev.callPackage ./k0s/default.nix {})
        k0s_1_28;
      k0s = k0s_1_28;
    };

    nixosConfigurations = {
      test = nixpkgs.lib.nixosSystem {
        modules = [
          ({
            nixpkgs.system = "x86_64-linux";
            nixpkgs.pkgs = import nixpkgs {
              system = "x86_64-linux";
              overlays = [
                overlays.default
              ];
            };
          })
          ./nixos/k0s.nix
          ({pkgs, ... }: {
            boot.isContainer = true;

            services.k0s = {
              enable = true;
              apiAddress = "192.0.2.1";
              apiSans = [
                "192.0.2.1"
                "192.0.2.2"
              ];
            };
          })
        ];
      };
    };

    nixosModules.default = import ./nixos/k0s.nix;

  };
}
