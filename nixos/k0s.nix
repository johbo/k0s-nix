{ pkgs, lib, config, ... }@args: let
  inherit (lib) mkEnableOption mkPackageOption mkOption mkIf optionalString concatMapAttrs;
  inherit (lib.types) str enum bool path nullOr attrsOf listOf attrTag submodule anything;
  util = import ./util.nix args;
  inherit (util) mkStringMapOption;
  cfg = config.services.k0s;
in {

  options.services.k0s = {
    enable = mkEnableOption (lib.mdDoc "Enable the k0s Kubernetes distribution.");

    package = mkPackageOption pkgs "k0s" { };

    role = mkOption {
      type = enum [ "controller" "controller+worker" "worker" "single"];
      default = "single";
      description = ''
        The role of the node.
      '';
    };

    isLeader = mkOption {
      type = bool;
      default = false;
      description = ''
        The leader is used to generate the join tokens.
      '';
    };

    dataDir = mkOption {
      type = path;
      default = "/var/lib/k0s";
    };

    tokenFile = mkOption {
      type = path;
      default = "/etc/k0s/k0stoken";
    };

    configText = mkOption {
      default = "";
      type = str;
      description = ''
        The configuration file in YAML format.
        A default will be generated if unset.
      '';
    };

    clusterName = mkOption {
      type = str;
      default = "k0s";
      description = ''
        The name of the cluster.
      '';
    };

    config = {
      api = mkOption {
        description = "Defines the settings for the K0s API.";
        type = submodule (import ./api.nix);
        default = {};
      };

      storage = mkOption {
        description = "Defines the storage related config options.";
        type = submodule (a: (import ./storage.nix (a // { inherit (cfg) dataDir; })));
        default = {};
      };

      network = mkOption {
        description = "Defines the network related config options.";
        type = submodule (import ./network.nix);
        default = {};
      };

      controllerManager.extraArgs = mkStringMapOption {
        example = ''
          {
            flex-volume-plugin-dir = "/etc/kubernetes/kubelet-plugins/volume/exec";
          }
        '';
        description = ''
          Map of key-values (strings) for any extra arguments you want to pass down to the Kubernetes controller manager process.
        '';
      };

      scheduler.extraArgs = mkStringMapOption {
        example = ''
          {
            config = "/path/to/config-file";
          }
        '';
        description = ''
          Map of key-values (strings) for any extra arguments you want to pass down to Kubernetes scheduler process.
        '';
      };

      workerProfiles = mkOption {
        type = listOf (submodule {
          options = {
            name = mkOption {
              type = str;
              description = ''
                Name to use as profile selector for the worker process
              '';
            };
            values = mkOption {
              type = attrsOf anything;
              description = ''
                [Kubelet configuration](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/) overrides.
                Note that there are several fields that cannot be overridden:
                - `clusterDNS`
                - `clusterDomain`
                - `apiVersion`
                - `kind`
                - `staticPodURL`
              '';
            };
          };
        });
        default = [];
        description = ''
          Worker profiles are used to manage worker-specific configuration in a centralized manner.
          A ConfigMap is generated for each worker profile.
          Based on the `--profile` argument given to the `k0s worker`,
          the configuration in the corresponding ConfigMap is is picked up during startup.
        '';
      };

      featureGates = mkOption {
        type = listOf (submodule {
          options = {
            name = mkOption {
              type = str;
            };
            enabled = mkOption {
              type = bool;
            };
            components = mkOption {
              type = nullOr listOf enum [ "kube-apiserver" "kube-controller-manager" "kubelet" "kube-scheduler" "kube-proxy" ];
              default = null;
            };
          };
        });
        default = [];
      };

      images = let
        imageOption = mkOption {
          type = submodule (import ./image.nix);
        };
      in mkOption {
        type = attrsOf (attrTag {
          konnectivity = imageOption;
          pushgateway = imageOption;
          metricsserver = imageOption;
          kubeproxy = imageOption;
          coredns = imageOption;
          pause = imageOption;
          calico.cni = imageOption;
          calico.flexvolume = imageOption;
          calico.node = imageOption;
          calico.kubecontrollers = imageOption;
          kuberouter.cni = imageOption;
          kuberouter.cniInstaller = imageOption;
          repository = mkOption {
            type = str;
          };
          default_pull_policy = mkOption {
            type = enum [ "Always" "Never" "IfNotPresent" ];
          };
        });
        default = {};
      };

      installConfig.users = {
        etcdUser = mkOption {
          type = str;
          default = "etcd";
        };
        kineUser = mkOption {
          type = str;
          default = "kube-apiserver";
        };
        konnectivityUser = mkOption {
          type = str;
          default = "konnectivity-server";
        };
        kubeAPIserverUser = mkOption {
          type = str;
          default = "kube-apiserver";
        };
        kubeSchedulerUser = mkOption {
          type = str;
          default = "kube-scheduler";
        };
      };

      telemetry = mkOption {
        type = bool;
        default = false;
      };

      # TODO extensions
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
          spec: ${builtins.toJSON cfg.config}
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
        cfg.config.installConfig.users;

    };
}
