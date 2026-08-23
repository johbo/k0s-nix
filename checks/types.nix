{ lib, pkgs }:
let
  types = import ../nixos/types.nix { inherit lib; };

  isUndescribed = type: type.description == lib.types.str.description;
  undescribedTypes = lib.filterAttrs (_: isUndescribed) types;

  report = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: type: "${name}: ${type.description}") types
  );
in
pkgs.runCommand "k0s-option-type-descriptions"
  {
    preferLocalBuild = true;
    passAsFile = [ "report" ];
    inherit report;
    undescribed = lib.concatStringsSep " " (lib.attrNames undescribedTypes);
  }
  ''
    cat "$reportPath"
    echo
    if [ -n "$undescribed" ]; then
      echo "These types in nixos/types.nix describe themselves as their base type: $undescribed" >&2
      exit 1
    fi
    touch $out
  ''
