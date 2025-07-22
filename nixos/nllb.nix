{
  lib,
  config,
  ...
}@args:
let
  inherit (lib) mkEnableOption mkOption optionalAttrs;
  inherit (lib.types)
    enum
    port
    submodule
    nullOr
    ;
  customTypes = import ./types.nix args;
in
{
  options = {
    enabled = mkEnableOption "Indicates if node-local load balancing should be used to access Kubernetes API servers from worker nodes. Default: `false`.";

    type = mkOption {
      description = ''
        The type of the node-local load balancer to deploy on worker nodes.
        Default: `EnvoyProxy`. (This is the only option for now.)
      '';
      type = enum [ "EnvoyProxy" ];
      default = "EnvoyProxy";
    };

    envoyProxy = optionalAttrs (config.enabled && config.type == "EnvoyProxy") (mkOption {
      description = ''
        Configuration options related to the "EnvoyProxy" type of load balancing.
      '';
      type = submodule {
        options = {
          image = mkOption {
            description = "Image to use for envoy proxy. k0s sets its default if null.";
            type = nullOr customTypes.image;
            default = null;
          };
          imagePullPolicy = mkOption {
            description = "Pull policy to use when pulling the envoy proxy image. k0s sets its default if empty.";
            type = enum [
              "Always"
              "Never"
              "IfNotPresent"
              ""
            ];
            default = "";
          };
          apiServerBindPort = mkOption {
            type = port;
            default = 7443;
          };
          konnectivityServerBindPort = mkOption {
            type = port;
            default = 7132;
          };
        };
      };
      default = { };
    });
  };
}
