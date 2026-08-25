{
  lib,
  pkgs,
  nixpkgs,
  k0sNix,
}:
let
  parts = lib.splitString "\n```nix\n" (builtins.readFile ../README.md);
  snippet =
    if lib.length parts < 2 then "" else lib.elemAt (lib.splitString "\n```\n" (lib.elemAt parts 1)) 0;

  # A broken extraction would otherwise evaluate an empty flake and pass,
  # which is the one outcome this check must not have.
  found = lib.assertMsg (lib.hasInfix "nixosConfigurations.my-node" snippet) "checks/readme.nix found no usage example in README.md";

  # The example names the reader's own generated file, which this
  # repository cannot supply.
  hardware = builtins.toFile "readme-hardware.nix" ''
    { lib, ... }:
    {
      nixpkgs.hostPlatform = lib.mkDefault "${pkgs.stdenv.hostPlatform.system}";
      fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };
      boot.loader.grub.enable = false;
    }
  '';

  example = import (
    builtins.toFile "readme-example.nix" (
      builtins.replaceStrings [ "./hardware-configuration.nix" ] [ "${hardware}" ] snippet
    )
  );

  node =
    (example.outputs {
      inherit nixpkgs;
      k0s-nix = k0sNix;
    }).nixosConfigurations.my-node;

  # Instantiates the system without building it. Dropping the context
  # discard makes this check build a whole NixOS closure.
  toplevel = builtins.unsafeDiscardStringContext node.config.system.build.toplevel.drvPath;
in
assert found;
pkgs.runCommand "k0s-readme-example"
  {
    preferLocalBuild = true;
    inherit toplevel;
    k0sPackage = node.config.services.k0s.package.name;
  }
  ''
    echo "system: $toplevel"
    echo "services.k0s.package: $k0sPackage"
    touch $out
  ''
