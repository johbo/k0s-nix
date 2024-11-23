{
  description = "k0s - The Zero Friction Kubernetes for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

  outputs = { self, nixpkgs, ... }:
    let

      genPackages = pkgs: rec {
        inherit (pkgs.callPackage ./k0s/default.nix {})
          k0s_1_27
          k0s_1_28
          k0s_1_30
          k0s_1_31
          k0s_1_32;
        k0s = k0s_1_32;
      };

      lib = nixpkgs.lib;
      allSystems = [ "armv7l-linux" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = lib.genAttrs allSystems;
    in {
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in genPackages pkgs);

      overlays.default = final: prev: genPackages prev;

      nixosModules.default = import ./nixos/k0s.nix;

      checks = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          basic = pkgs.testers.runNixOSTest {
            imports = [ ./tests/basic.nix ];
            node = { specialArgs = { inherit self; }; };
          };
        });

    };
}
