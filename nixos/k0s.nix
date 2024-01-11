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

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/k0s";
    };

    tokenFile = mkOption {
      type = types.path;
      default = "/etc/k0s/k0stoken";
    };

    users = {
      etcdUser = mkOption {
        type = types.str;
        default = "etcd";
      };
      kineUser = mkOption {
        type = types.str;
        default = "kube-apiserver";
      };
      konnectivityUser = mkOption {
        type = types.str;
        default = "konnectivity-server";
      };
      kubeAPIserverUser = mkOption {
        type = types.str;
        default = "kube-apiserver";
      };
      kubeSchedulerUser = mkOption {
        type = types.str;
        default = "kube-scheduler";
      };
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
          ExecStart = "${cfg.package}/bin/k0s ${subcommand} --config=/etc/k0s/k0s.yaml --data-dir=${cfg.dataDir}"
            + optionalString (cfg.role == "single") " --single"
            + optionalString (cfg.role == "controller+worker") " --enable-worker"
            # TODO: Verify assumption that the usage of a token on the leader will not
            # cause any problems.
            + optionalString (cfg.role != "single") " --token-file=${cfg.tokenFile}";
        };
      };

      users.users = {
        ${cfg.users.etcdUser} = {
          isSystemUser = true;
          group = "users";
          home = "${cfg.dataDir}";
        };
      } // {
        ${cfg.users.kineUser} = {
          isSystemUser = true;
          group = "users";
          home = "${cfg.dataDir}";
        };
      } // {
        ${cfg.users.konnectivityUser} = {
          isSystemUser = true;
          group = "users";
          home = "${cfg.dataDir}";
        };
      } // {
        ${cfg.users.kubeAPIserverUser} = {
          isSystemUser = true;
          group = "users";
          home = "${cfg.dataDir}";
        };
      } // {
        ${cfg.users.kubeSchedulerUser} = {
          isSystemUser = true;
          group = "users";
          home = "${cfg.dataDir}";
        };
      };

    };
}
