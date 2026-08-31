{
  lib,
  pkgs,
  nixpkgs,
  k0sNix,
}:
let
  marker = "<!-- readme-example -->";
  parts = lib.splitString "${marker}\n```nix\n" (builtins.readFile ../README.md);
  snippet = lib.optionalString (lib.length parts > 1) (
    lib.elemAt (lib.splitString "\n```\n" (lib.elemAt parts 1)) 0
  );

  found = lib.assertMsg (lib.hasInfix "nixosConfigurations.my-node" snippet) "checks/readme.nix found no ${marker} block in README.md";

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

  # Without the context discard this check builds a whole NixOS closure.
  toplevel = builtins.unsafeDiscardStringContext node.config.system.build.toplevel.drvPath;
in
assert found;
pkgs.runCommand "k0s-readme-example"
  {
    preferLocalBuild = true;
    allowSubstitutes = false;
    inherit toplevel;
    k0sPackage = node.config.services.k0s.package.name;
  }
  ''
    echo "system: $toplevel"
    echo "services.k0s.package: $k0sPackage"
    touch $out
  ''
