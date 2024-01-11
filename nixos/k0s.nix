{ pkgs, lib, config, ... }:

with lib;

let cfg = config.services.k0s;

in {

  options.services.k0s = {
    enable = mkEnableOption (lib.mdDoc "Enable the k0s Kubernetes distribution.");

    package = mkPackageOption pkgs "k0s" { };

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
