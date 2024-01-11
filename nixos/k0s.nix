{ pkgs, lib, config, ... }:

with lib;

let cfg = config.services.k0s;

in {

  options.services.k0s = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable the k0s Kubernetes distribution.
      '';
    };

    role = mkOption {
      type = types.enum [ "controller" "controller+worker" "worker" "single"];
      default = "single";
      description = ''
        The role of the node.
      '';
    };

  };


  config = mkIf cfg.enable {

  };

}
