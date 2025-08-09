{
  description = "k0s - The Zero Friction Kubernetes for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs =
    { self, nixpkgs, ... }:
    let

      genPackages = pkgs: rec {
        inherit (pkgs.callPackage ./k0s/default.nix { })
          k0s_1_27
          k0s_1_28
          k0s_1_30
          k0s_1_31
          k0s_1_32
          k0s_1_33
          ;
        k0s = k0s_1_33;
      };

      lib = nixpkgs.lib;
      k0sSystems = [
        "armv7l-linux"
        "aarch64-linux"
        "x86_64-linux"
      ];
      darwinSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      allSystems = k0sSystems ++ darwinSystems;
      forAllK0sSystems = lib.genAttrs k0sSystems;
    in
    {
      packages = forAllK0sSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        genPackages pkgs
      );

      overlays.default = final: prev: genPackages prev;

      nixosModules.default = import ./nixos/k0s.nix;

      formatter = (lib.genAttrs allSystems) (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      checks = forAllK0sSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          forAllTests = lib.genAttrs [
            "single"
            "ctrl-wrkr"
            "graceful-shutdown"
          ];
        in
        forAllTests (
          test:
          pkgs.testers.runNixOSTest {
            imports = [ ./tests/${test}.nix ];
            node = {
              pkgsReadOnly = false;
            };
            defaults = {
              imports = [ self.nixosModules.default ];
              nixpkgs.overlays = [ self.overlays.default ];
            };
          }
        )
      );

    };
}
