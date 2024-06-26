{ lib, config, ... }@args: let
  inherit (lib) mkOption mkEnableOption optionalAttrs;
  inherit (lib.types) enum bool port ints;
  util = import ./util.nix args;
in {
  options = {

    autoMTU = mkOption {
      type = bool;
      default = true;
      description = ''
        Autodetection of used MTU (default: `true`).
      '';
    };

    mtu = mkOption (let
      option = {
        type = ints.unsigned;
        description = ''
          Override MTU setting, if `autoMTU` must be set to `false`).
        '';
      };
    in if (!config.autoMTU) then option else option // { default = 0; }); # TODO extract this into a util

    metricsPort = mkOption {
      type = port;
      default = 8080;
      description = ''
        Kube-router metrics server port. Set to 0 to disable metrics (default: `8080`).
      '';
    };

    hairpin = mkOption {
      type = enum [ "Enabled" "Allowed" "Disabled" ];
      default = "Enabled";
      description = ''
        Hairpin mode, supported modes:
        - `Enabled`: enabled cluster wide
        - `Allowed`: must be allowed per service using [annotations](https://github.com/cloudnativelabs/kube-router/blob/master/docs/user-guide.md#hairpin-mode)
        - `Disabled`: doesn't work at all
        (default: `Enabled`)
      '';
    };

    ipMasq = mkEnableOption ''
      IP masquerade for traffic originating from the pod network, and destined outside of it (default: false)
    '';

    extraArgs = util.mkStringMapOption {
      example = ''
        {
          advertise-pod-cidr = "false";
          bgp-port = "9179";
          cache-sync-timeout = "2m";
          health-port = "0";
        }
      '';
      description = ''
        Extra arguments to pass to kube-router.
        Can be also used to override any k0s managed args.
        For reference, see kube-router [documentation](https://github.com/cloudnativelabs/kube-router/blob/master/docs/user-guide.md#command-line-options). (default: empty)
      '';
    };

  };
}