{ pkgs, lib, config, ... }@args: let
  inherit (lib) mkEnableOption mkPackageOption mkOption optionalAttrs mkIf optionalString concatMapAttrs;
  inherit (lib.types) str enum bool path nullOr attrsOf listOf port attrTag ints int submodule addCheck anything;
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
        description = "Defines the settings for the K0s API";
        type = submodule (import ./api.nix);
        default = {};
      };

      storage = mkOption {
        description = "Defines the storage related config options";
        type = submodule (a: (import ./storage.nix (a // { inherit (cfg) dataDir; })));
        default = {};
      };

      network = {
        provider = mkOption {
          type = enum [ "calico" "kuberouter" "custom" ];
          default = "kuberouter";
          description = ''
            Network provider (valid values: `calico`, `kuberouter`, or `custom`).
            For `custom`, you can push any network provider (default: `kuberouter`).
            Be aware that it is your responsibility to configure all of the CNI-related setups,
            including the CNI provider itself and all necessary host levels setups (for example, CNI binaries).
            **Note:** Once you initialize the cluster with a network provider the only way to change providers is through a full cluster redeployment.
          '';
        };

        podCIDR = mkOption {
          type = str;
          default = "10.244.0.0/16";
          description = ''
            Pod network CIDR to use in the cluster.
          '';
        };

        serviceCIDR = mkOption {
          type = str;
          default = "10.96.0.0/12";
          description = ''
            Network CIDR to use for cluster VIP services.
          '';
        };

        clusterDomain = mkOption {
          type = str;
          default = "cluster.local";
          description = ''
            Cluster Domain to be passed to the [kubelet](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/#kubelet-config-k8s-io-v1beta1-KubeletConfiguration)
            and the coredns configuration.
          '';
        };

        calico = optionalAttrs (cfg.config.network.provider == "calico") {
          mode = mkOption {
            type = enum [ "vxlan" "ipip" "bird" ];
            default = "vxlan";
            description = ''
              `vxlan` (default), `ipip` or `bird`
            '';
          };

          overlay = mkOption {
            type = enum [ "Always" "CrossSubnet" optionalString (cfg.config.network.calico.mode == "vxlan") "Never" ];
            default = "Always";
            description = ''
              Overlay mode: `Always` (default), `CrossSubnet` or `Never` (requires `mode=vxlan` to disable calico overlay-network).
            '';
          };

          vxlanPort = mkOption {
            type = port;
            default = 4789;
            description = ''
              The UDP port for VXLAN (default: `4789`).
            '';
          };

          vxlanVNI = mkOption {
            type = ints.unsigned;
            default = 4096;
            description = ''
              The virtual network ID for VXLAN (default: `4096`).
            '';
          };

          mtu = mkOption {
            type = ints.unsigned;
            default = 0;
            description = ''
              MTU for overlay network (default: `0`, which causes Calico to detect optimal MTU during bootstrap).
            '';
          };

          wireguard = mkOption {
            type = bool;
            default = false;
            description = ''
              Enable wireguard-based encryption (default: `false`).
              Your host system must be wireguard ready (refer to the [Calico documentation](https://docs.projectcalico.org/security/encrypt-cluster-pod-traffic) for details).
            '';
          };

          flexVolumeDriverPath = mkOption {
            type = path;
            default = "/usr/libexec/k0s/kubelet-plugins/volume/exec/nodeagent~uds";
            description = ''
              The host path for Calicos flex-volume-driver (default: `/usr/libexec/k0s/kubelet-plugins/volume/exec/nodeagent~uds`).
              Change this path only if the default path is unwriteable (refer to [Project Calico Issue #2712](https://github.com/projectcalico/calico/issues/2712) for details).
              Ideally, you will pair this option with a custom `volumePluginDir` in the profile you use for your worker nodes.
            '';
          };

          ipAutodetectionMethod = mkOption {
            type = str;
            default = "";
            description = ''
              Use to force Calico to pick up the interface for pod network inter-node routing
              (default: `""`, meaning not set, so that Calico will instead use its defaults).
              For more information, refer to the [Calico documentation](https://docs.projectcalico.org/reference/node/configuration#ip-autodetection-methods).
            '';
          };

          envVars = mkStringMapOption {
            example = ''
              {
                CALICO_IPV4POOL_CIDR = "172.31.0.0/16";
                CALICO_DISABLE_FILE_LOGGING = "true";
                FELIX_DEFAULTENDPOINTTOHOSTACTION = "ACCEPT";
                FELIX_LOGSEVERITYSCREEN = "info";
                FELIX_HEALTHENABLED = "true";
                FELIX_PROMETHEUSMETRICSENABLED = "true";
                FELIX_FEATUREDETECTOVERRIDE = "ChecksumOffloadBroken=true";
                FELIX_IPV6SUPPORT = "false";
              }
            '';
            description = ''
              Map of key-values (strings) for any calico-node [environment variable](https://docs.projectcalico.org/reference/node/configuration#ip-autodetection-methods).
            '';
          };
        };

        kuberouter = optionalAttrs (cfg.config.network.provider == "kuberouter") {
          autoMTU = mkOption {
            type = bool;
            default = true;
            description = ''
              Autodetection of used MTU (default: `true`).
            '';
          };

          mtu = optionalAttrs (!cfg.config.network.kuberouter.autoMTU) (mkOption {
            type = ints.unsigned;
            description = ''
              Override MTU setting, if `autoMTU` must be set to `false`).
            '';
          });

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

          ipMasq = mkOption {
            type = bool;
            default = false;
            description = ''
              IP masquerade for traffic originating from the pod network, and destined outside of it (default: false)
            '';
          };

          extraArgs = mkStringMapOption {
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

        kubeProxy = {
          disabled = mkOption {
            type = bool;
            default = false;
            description = ''
              Disable kube-proxy altogether (default: `false`).
            '';
          };

          mode = mkOption {
            type = enum [ "iptables" "ipvs" "userspace" ];
            default = "iptables";
            description = ''
              Kube proxy operating mode, supported modes iptables, ipvs, userspace (default: iptables).
            '';
          };

          iptables = mkOption {
            type = nullOr (attrsOf (attrTag {
              masqueradeBit = mkOption {
                type = nullOr int;
              };
              masqueradeAll = mkOption {
                type = bool;
              };
              localhostNodePorts = mkOption {
                type = nullOr bool;
              };
              syncPeriod = mkOption {
                type = str;
              };
              minSyncPeriod = mkOption {
                type = str;
              };
            }));
            default = null;
            description = ''
              Kube proxy iptables settings.
            '';
          };

          ipvs = mkOption {
            type = nullOr (attrsOf (attrTag {
              syncPeriod = mkOption {
                type = str;
              };
              minSyncPeriod = mkOption {
                type = str;
              };
              scheduler = mkOption {
                type = str;
              };
              excludedCIDRs = mkOption {
                type = nullOr (listOf str);
              };
              strictARP = mkOption {
                type = bool;
              };
              tcpTimeout = mkOption {
                type = str;
              };
              tcpFinTimeout = mkOption {
                type = str;
              };
              udpTimeout = mkOption {
                type = str;
              };
            }));
            default = null;
            description = ''
              Kube proxy ipvs settings.
            '';
          };

          nodePortAddresses = mkOption {
            type = nullOr (listOf str);
            default = null;
            description = ''
              Kube proxy [nodePortAddresses](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/).
            '';
          };
        };

        nodeLocalLoadBalancing = {
          enabled = mkOption {
            type = bool;
            default = false;
            description = ''
              Indicates if node-local load balancing should be used to access Kubernetes API servers from worker nodes. Default: `false`.
            '';
          };

          type = mkOption {
            type = enum [ "EnvoyProxy" ];
            default = "EnvoyProxy";
            description = ''
              The type of the node-local load balancer to deploy on worker nodes.
              Default: `EnvoyProxy`. (This is the only option for now.)
            '';
          };

          envoyProxy = optionalAttrs (cfg.config.network.nodeLocalLoadBalancing.type == "EnvoyProxy") (mkOption {
            type = nullOr (attrsOf (attrTag {
              image = mkOption {
                type = nullOr attrsOf (attrTag {
                  image = mkOption {
                    type = str;
                  };
                  version = mkOption {
                    type = str;
                  };
                });
              };
              imagePullPolicy = mkOption {
                type = enum [ "Always" "Never" "IfNotPresent" ];
              };
              apiServerBindPort = mkOption {
                type = port;
              };
              konnectivityServerBindPort = mkOption {
                type = nullOr port;
              };
            }));
            default = null;
            description = ''
              Configuration options related to the "EnvoyProxy" type of load balancing.
            '';
          });
        };

        controlPlaneLoadBalancing = {
          enabled = mkOption {
            type = bool;
            default = false;
            description = ''
              Indicates if control plane load balancing should be enabled. Default: `false`.
            '';
          };

          type = mkOption {
            type = enum [ "Keepalived" ];
            default = "Keepalived";
            description = ''
              The type of the control plane load balancer to deploy on controller nodes.
              Currently, the only supported type is `Keepalived`.
            '';
          };

          keepalived = optionalAttrs (cfg.config.network.controlPlaneLoadBalancing.type == "Keepalived") mkOption {
            type = nullOr (submodule {
              options = {
                vrrpInstances = mkOption {
                  type = listOf submodule {
                    options = {
                      virtualIPs = mkOption {
                        type = addCheck (listOf str) (list: builtins.length list > 0);
                        description = ''
                          The list of virtual IP address used by the VRRP instance.
                          Each virtual IP must be a CIDR as defined in RFC 4632 and RFC 4291.
                        '';
                      };
                      interface = mkOption {
                        type = str;
                        default = "";
                        description = ''
                          Specifies the NIC used by the virtual router.
                          If not specified, k0s will use the interface that owns the default route.
                        '';
                      };
                      virtualRouterID = mkOption {
                        type = ints.u8;
                        default = 0;
                        description = ''
                          The VRRP router ID. If it is 0, k0s will
                          automatically number the IDs for each VRRP instance, starting with 51.
                          All the control plane nodes must use the same `virtualRouterID`.
                          Other clusters in the same network must not use the same `virtualRouterID`.
                        '';
                      };
                      advertIntervalSeconds = mkOption {
                        type = ints.positive;
                        default = 1;
                        description = ''
                          The advertisement interval in seconds.
                        '';
                      };
                      authPass = mkOption {
                        type = addCheck str (str: let len = builtins.stringLength str; in len >= 1 && len <= 8 );
                        description = ''
                          The password for accessing VRRPD. This is not a security
                          feature but a way to prevent accidental misconfigurations.
                          AuthPass must be 8 characters or less.
                        '';
                      };
                    };
                  };
                  default = [];
                  description = ''
                    Configuration options related to the VRRP. This is an array which allows
                    to configure multiple virtual IPs.
                  '';
                };
                virtualServers = mkOption {
                  type = listOf submodule {
                    options = {
                      ipAddress = mkOption {
                        type = addCheck str (str: builtins.stringLength str >= 1);
                        description = ''
                          The virtual IP address used by the virtual server.
                        '';
                      };
                      delayLoop = mkOption {
                        type = str;
                        default = "1m";
                        description = ''
                          The delay timer for check polling. DelayLoop accepts
                          microsecond precision. Further precision will be truncated without
                          warnings. Defaults to `1m`.
                        '';
                      };
                      lbAlgo = mkOption {
                        type = enum [ "rr" "wrr" "lc" "wlc" "lblc" "dh" "sh" "sed" "nq" ];
                        default = "rr";
                        description = ''
                          The load balancing algorithm. If not specified, defaults to `rr`.
                          Valid values are `rr`, `wrr`, `lc`, `wlc`, `lblc`, `dh`, `sh`, `sed`, `nq`. For further
                          details refer to [keepalived documentation](https://keepalived-pqa.readthedocs.io/en/stable/scheduling_algorithms.html).
                        '';
                      };
                      lbKind = mkOption {
                        type = enum [ "NAT" "DR" "TUN" ];
                        default = "DR";
                        description = ''
                          The load balancing kind. If not specified, defaults to `DR`.
                          Valid values are `NAT` `DR` `TUN`. For further details refer to
                          [keepalived documentation](https://keepalived-pqa.readthedocs.io/en/stable/load_balancing_techniques.html).
                        '';
                      };
                      persistenceTimeoutSeconds = mkOption {
                        type = ints.between 1 2678400;
                        default = 360;
                        description = ''
                          Specifies a timeout value for persistent
                          connections in seconds. PersistentTimeoutSeconds must be in the range of
                          1-2678400 (31 days). If not specified, defaults to 360 (6 minutes).
                        '';
                      };
                    };
                  };
                  default = [];
                  description = ''
                    Configuration options related to the virtual servers. This is an array
                    which allows to configure multiple load balancers.
                  '';
                };
              };
            });
            default = null;
            description = ''
              Contains configuration options related to the "Keepalived" type of load balancing.
            '';
          };
        };
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
        imageModule = {
          options = {
            image = mkOption {
              type = str;
            };
            version = mkOption {
              type = str;
            };
          };
        };
        imageOption = mkOption {
          type = submodule imageModule;
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
