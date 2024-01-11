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


  config =
    let
      subcommand = if (cfg.role == "worker") then "worker" else "controller";
      unitName = "k0s" + subcommand;
    in
    {
      systemd.services.${unitName} = {
        description = "k0s - Zero Friction Kubernetes";
        documentation = [ "https://docs.k0sproject.io" ];
        path = with pkgs; [
          kmod
          util-linux
          mount
        ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        startLimitIntervalSec = 5;
        startLimitBurst = 10;
        serviceConfig = {
          RestartSec = 120;
          Delegate = "yes";
          KillMode = "process";
          LimitCORE = "infinity";
          TasksMax = "infinity";
          TimeoutStartSec = 0;
          LimitNOFILE = 999999;
          Restart = "always";
          ExecStart = "${cfg.package}/bin/k0s ${subcommand} --config=/etc/k0s/k0s.yaml --data-dir=/var/lib/k0s"
            + optionalString (cfg.role == "single") " --single"
            + optionalString (cfg.role == "controller+worker") " --enable-worker"
            + optionalString (cfg.role == "worker") " --token-file=/etc/k0s/k0stoken";
        };
      };
    };

}
