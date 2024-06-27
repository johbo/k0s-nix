{
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkOption optionalAttrs;
  inherit (lib.types) enum port submodule;
in {
  options = {
    enabled = mkEnableOption "Indicates if node-local load balancing should be used to access Kubernetes API servers from worker nodes. Default: `false`.";

    type = mkOption {
      description = ''
        The type of the node-local load balancer to deploy on worker nodes.
        Default: `EnvoyProxy`. (This is the only option for now.)
      '';
      type = enum ["EnvoyProxy"];
      default = "EnvoyProxy";
    };

    envoyProxy = optionalAttrs (config.enabled && config.type == "EnvoyProxy") (mkOption {
      description = ''
        Configuration options related to the "EnvoyProxy" type of load balancing.
      '';
      type = submodule {
        options = {
          image = mkOption {
            type = submodule (import ./image.nix);
            default = {};
          };
          imagePullPolicy = mkOption {
            type = enum ["Always" "Never" "IfNotPresent" ""];
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
      default = {};
    });
  };
}
