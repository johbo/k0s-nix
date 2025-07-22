{ lib, ... }:
let
  inherit (lib) mkOption literalExpression;
  inherit (lib.types) str attrsOf;
in
{
  mkStringMapOption =
    {
      example,
      description,
    }:
    (mkOption {
      type = attrsOf str;
      default = { };
      example = literalExpression example;
      description = description;
    });

  mkOptionMandatoryIf =
    condition: option: default:
    mkOption (if condition then option else option // { inherit default; });
}
