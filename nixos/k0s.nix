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

    apiAddress = mkOption {
      # No default, has to be provided
      type = types.str;
      description = ''
        Required. Local address on which to bind an API.
      '';
    };

    apiSans = mkOption {
      type = types.listOf types.str;
      description = ''
        Required. List of additional addresses to push to API servers serving the certificate.
      '';
    };

    clusterName = mkOption {
      type = types.str;
      default = "k0s";
      description = ''
        The name of the cluster.
      '';
    };

    isLeader = mkOption {
      type = types.bool;
      default = false;
      description = ''
        The leader is used to generate the join tokens.
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

    configText = mkOption {
      default = "";
      type = types.str;
      description = ''
        The configuration file in YAML format.
        A default will be generated if unset.
      '';
    };

    kubeProxy = {
      disabled = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Allows to disable kubeProxy.
        '';
      };
    };

    network = {
      provider = mkOption {
        type = types.str;
        default = "kuberouter";
        description = ''
          Allows to adjust the network provider configuration.
        '';
      };
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
      configFile =
        if cfg.configText != ""
        then pkgs.writeText "k0s.yaml" cfg.configText
        else pkgs.writeText "k0s.yaml" ''
          # Generated by the k0s module
          apiVersion: k0s.k0sproject.io/v1beta1
          kind: Cluster
          metadata:
            name: ${cfg.clusterName}
          spec:
            api:
              address: ${cfg.apiAddress}
              k0sApiPort: 9443
              port: 6443
              sans:
          ${concatLines (forEach cfg.apiSans (value:
            "      - ${value}"
          ))}      - 127.0.0.1
            extensions:
              storage:
                create_default_storage_class: true
                type: openebs_local_storage
            installConfig:
              users:
                etcdUser: ${cfg.users.etcdUser}
                kineUser: ${cfg.users.kineUser}
                konnectivityUser: ${cfg.users.konnectivityUser}
                kubeAPIserverUser: ${cfg.users.kubeAPIserverUser}
                kubeSchedulerUser: ${cfg.users.kubeSchedulerUser}
            konnectivity:
              adminPort: 8133
              agentPort: 8132
            network:
              kubeProxy:
                mode: iptables
                disabled: ${if cfg.kubeProxy.disabled then "true" else "false"}
              kuberouter:
                autoMTU: true
                mtu: 0
                peerRouterASNs: ""
                peerRouterIPs: ""
              podCIDR: 10.244.0.0/16
              provider: ${cfg.network.provider}
              serviceCIDR: 10.96.0.0/12
            podSecurityPolicy:
              defaultPolicy: 00-k0s-privileged
            storage:
              type: etcd
            telemetry:
              enabled: true
        '';
    in
    mkIf cfg.enable {
      environment.etc."k0s/k0s.yaml".source = configFile;

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
          ExecStart = "${cfg.package}/bin/k0s ${subcommand} --data-dir=${cfg.dataDir}"
            + optionalString (cfg.role != "worker") " --config=${configFile}"
            + optionalString (cfg.role == "single") " --single"
            + optionalString (cfg.role == "controller+worker") " --enable-worker --no-taints"
            + optionalString (cfg.role != "single" && !cfg.isLeader) " --token-file=${cfg.tokenFile}";
        };
        unitConfig = mkIf (!cfg.isLeader) {
          ConditionPathExists = cfg.tokenFile;
        };
      };

      users.users = concatMapAttrs
        (name: value: {
          ${value} = {
            isSystemUser = true;
            group = "users";
            home = "${cfg.dataDir}";
          };
        })
        cfg.users;

    };
}
