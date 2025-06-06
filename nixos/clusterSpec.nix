{
  lib,
  dataDir,
  ...
}@args:
let
  inherit (lib) mkEnableOption mkOption;
  inherit (lib.types)
    str
    port
    enum
    attrsOf
    listOf
    attrTag
    submodule
    ;
  util = import ./util.nix args;
  inherit (util) mkStringMapOption;
  customTypes = import ./types.nix args;
in
{
  options = {
    api = mkOption {
      description = "Defines the settings for the K0s API.";
      type = submodule (import ./api.nix);
      default = { };
    };

    storage = mkOption {
      description = "Defines the storage related config options.";
      type = submodule (a: (import ./storage.nix (a // { inherit dataDir; })));
      default = { };
    };

    network = mkOption {
      description = "Defines the network related config options.";
      type = submodule (import ./network.nix);
      default = { };
    };

    extensions = mkOption {
      description = "Specifies cluster extensions.";
      type = submodule (import ./extensions.nix);
      default = { };
    };

    konnectivity = {
      adminPort = mkOption {
        description = "Admin port to listen on.";
        type = port;
        default = 8133;
      };
      agentPort = mkOption {
        description = "Agent port to listen on.";
        type = port;
        default = 8132;
      };
    };

    controllerManager.extraArgs = mkStringMapOption {
      description = ''
        Map of key-values (strings) for any extra arguments you want to pass down to the Kubernetes controller manager process.
      '';
      example = ''
        {
          flex-volume-plugin-dir = "/etc/kubernetes/kubelet-plugins/volume/exec";
        }
      '';
    };

    scheduler.extraArgs = mkStringMapOption {
      description = ''
        Map of key-values (strings) for any extra arguments you want to pass down to Kubernetes scheduler process.
      '';
      example = ''
        {
          config = "/path/to/config-file";
        }
      '';
    };

    workerProfiles = mkOption {
      description = ''
        Worker profiles are used to manage worker-specific configuration in a centralized manner.
        A ConfigMap is generated for each worker profile.
        Based on the `--profile` argument given to the `k0s worker`,
        the configuration in the corresponding ConfigMap is is picked up during startup.
      '';
      type = listOf (submodule (import ./workerProfile.nix));
      default = [ ];
    };

    featureGates = mkOption {
      type = listOf (submodule (import ./featureGate.nix));
      default = [ ];
    };

    images =
      let
        imageOption = mkOption {
          type = customTypes.image;
        };
      in
      mkOption {
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
            type = enum [
              "Always"
              "Never"
              "IfNotPresent"
            ];
          };
        });
        default = { };
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

    telemetry.enabled = mkEnableOption "Wether or not telemetry should be sent to the k0s developers.";
  };
}
