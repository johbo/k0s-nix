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
  };


  config = mkIf cfg.enable {

  };

}
