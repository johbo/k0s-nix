{
  pkgs,
  nixpkgs,
  module,
}:
let
  inherit (pkgs) lib;

  sourceRoot = "${toString ../.}/";
  repository = "https://github.com/nix-community/k0s-nix/blob/main";

  linkToRepository =
    declaration:
    let
      path = toString declaration;
    in
    if lib.hasPrefix sourceRoot path then
      let
        relative = lib.removePrefix sourceRoot path;
      in
      {
        name = relative;
        url = "${repository}/${relative}";
      }
    else
      declaration;

  eval = import (nixpkgs + "/nixos/lib/eval-config.nix") {
    inherit pkgs;
    # Dropping this falls back to builtins.currentSystem, which is
    # unavailable in a pure evaluation.
    system = null;
    modules = [ module ];
  };

  doc = pkgs.nixosOptionsDoc {
    options = eval.options.services.k0s;
    transformOptions =
      option:
      option
      // {
        declarations = map linkToRepository option.declarations;
      };
    # TODO: Drop this once every option carries a description
    warningsAreErrors = false;
  };
in
doc.optionsCommonMark
