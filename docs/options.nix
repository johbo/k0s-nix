{
  pkgs,
  nixpkgs,
  module,
}:
let
  inherit (pkgs) lib;

  sourceRoot = "${toString ../.}/";
  revision = "main";
  repository = "https://github.com/nix-community/k0s-nix/blob/${revision}";

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

  manual = pkgs.writeText "manual.md" ''
    # k0s-nix module options {#book-k0s-nix-options}
    ## Reference for the `services.k0s` NixOS module

    ```{=include=} options
    id-prefix: opt-
    list-id: configuration-variable-list
    source: ${doc.optionsJSON}/share/doc/nixos/options.json
    ```
  '';
in
pkgs.runCommand "k0s-nix-option-docs" { nativeBuildInputs = [ pkgs.nixos-render-docs ]; } ''
  mkdir $out
  cp ${pkgs.path}/doc/style.css $out/style.css
  nixos-render-docs manual html \
    --manpage-urls ${pkgs.path}/doc/manpage-urls.json \
    --revision ${revision} \
    --stylesheet style.css \
    ${manual} \
    $out/index.html
''
