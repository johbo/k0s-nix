{
  pkgs,
  nixpkgs,
  module,
}:
let
  eval = import (nixpkgs + "/nixos/lib/eval-config.nix") {
    inherit pkgs;
    # Dropping this falls back to builtins.currentSystem, which is
    # unavailable in a pure evaluation.
    system = null;
    modules = [ module ];
  };

  doc = pkgs.nixosOptionsDoc {
    options = eval.options.services.k0s;
    # TODO: Drop this once every option carries a description
    warningsAreErrors = false;
  };
in
doc.optionsCommonMark
