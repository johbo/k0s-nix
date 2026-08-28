{
  description = "k0s - The Zero Friction Kubernetes for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { self, nixpkgs, ... }:
    let

      # A hyphen rather than `k0s_source_*`: update.yml selects its matrix by
      # `contains("k0s_")` and reads the filename out of what follows, so an
      # underscore would send the weekly job at a file that does not exist.
      genPackages =
        pkgs:
        let
          sourceBuilds = pkgs.callPackage ./k0s/source.nix { };
        in
        rec {
          inherit (pkgs.callPackage ./k0s/default.nix { })
            k0s_1_33
            k0s_1_34
            k0s_1_35
            k0s_1_36
            ;
          k0s = k0s_1_35;
        }
        // lib.mapAttrs' (minor: lib.nameValuePair "k0s-source_${minor}") sourceBuilds.withPayload;

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
      forAllSystems = lib.genAttrs allSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        # k0s itself is a linux binary; the option documentation builds
        # anywhere.
        lib.optionalAttrs (lib.elem system k0sSystems) (genPackages pkgs)
        // {
          option-docs = import ./docs/options.nix {
            inherit nixpkgs pkgs;
            module = self.nixosModules.default;
          };
        }
      );

      overlays.default = final: prev: genPackages prev;

      nixosModules.default = ./nixos/k0s.nix;

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          # Empty on darwin, where there is no k0s package to test.
          versions = builtins.filter (lib.hasPrefix "k0s_") (builtins.attrNames self.packages.${system});
          tests = map (name: lib.strings.removeSuffix ".nix" name) (
            builtins.attrNames (builtins.readDir ./tests)
          );
          forAllVersionsAndTests =
            check:
            let
              nestedPairs = map (
                version:
                map (test: {
                  name = "${version}_${test}";
                  value = check version test;
                }) tests
              ) versions;
              flatPairs = builtins.concatLists nestedPairs;
            in
            builtins.listToAttrs flatPairs;
        in
        forAllVersionsAndTests (
          version: test:
          pkgs.testers.runNixOSTest {
            imports = [ ./tests/${test}.nix ];
            node = {
              pkgsReadOnly = false;
            };
            defaults = {
              imports = [ self.nixosModules.default ];
              nixpkgs.overlays = [
                self.overlays.default
                (final: prev: {
                  inherit final;
                  k0s = prev."${version}";
                })
              ];
            };
          }
        )
        // {
          option-types = import ./checks/types.nix { inherit lib pkgs; };
          option-docs = self.packages.${system}.option-docs;
          embedded-bins = import ./checks/embedded-bins.nix { inherit lib pkgs; };
          embedded-bins-containerd = import ./checks/embedded-bins-containerd.nix { inherit lib pkgs; };
          embedded-bins-etcd = import ./checks/embedded-bins-etcd.nix { inherit lib pkgs; };
          embedded-bins-iptables = import ./checks/embedded-bins-iptables.nix { inherit lib pkgs; };
          embedded-bins-keepalived = import ./checks/embedded-bins-keepalived.nix { inherit lib pkgs; };
          embedded-bins-kine = import ./checks/embedded-bins-kine.nix { inherit lib pkgs; };
          embedded-bins-konnectivity = import ./checks/embedded-bins-konnectivity.nix {
            inherit lib pkgs;
          };
          embedded-bins-kubernetes = import ./checks/embedded-bins-kubernetes.nix { inherit lib pkgs; };
          embedded-bins-runc = import ./checks/embedded-bins-runc.nix { inherit lib pkgs; };
          embedded-bins-payload = import ./checks/embedded-bins-payload.nix { inherit lib pkgs; };
          source-build = import ./checks/source-build.nix { inherit lib pkgs; };

          # One VM per assembly path rather than one per minor: 1.36 appends a
          # zip behind the finished binary, and below it the offset table is
          # compiled in. The tests/ cross product would take all four.
          source-build-vm-1_36 = import ./checks/source-build-vm.nix {
            inherit lib pkgs;
            minor = "1_36";
          };
          source-build-vm-1_35 = import ./checks/source-build-vm.nix {
            inherit lib pkgs;
            minor = "1_35";
          };
        }
      );

    };
}
