{ lib, config, ... }@args: let
  inherit (lib) mkEnableOption mkOption optionalAttrs;
  inherit (lib.types) str enum nullOr attrsOf listOf port attrTag ints submodule addCheck;
in {
  options = {

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
      default = "10.244.0.0/16"; # TODO validate CIDR
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
      default = "cluster.local"; # TODO validate domain
      description = ''
        Cluster Domain to be passed to the [kubelet](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/#kubelet-config-k8s-io-v1beta1-KubeletConfiguration)
        and the coredns configuration.
      '';
    };

    calico = optionalAttrs (config.provider == "calico") (mkOption {
      description = "Options for the `calico` network provider.";
      type = submodule (import ./calico.nix);
      default = {};
    });

    dualStack = {
      enable = mkEnableOption "Defines whether or not IPv4/IPv6 dual-stack networking should be enabled.";

      IPv6podCIDR = mkOption (let
        option = {
          type = str;
          description = ''
            IPv6 Pod network CIDR to use in the cluster.
          '';
        };
      in if config.dualStack.enable then option else option // { default = ""; });

      IPv6serviceCIDR = mkOption (let
        option = {
          type = str;
          description = ''
            IPv6 Network CIDR to use for cluster VIP services.
          '';
        };
      in if config.dualStack.enable then option else option // { default = ""; });
    };

    kuberouter = optionalAttrs (config.provider == "kuberouter") (mkOption {
      description = "Options for the `kuberouter` network provider.";
      type = submodule (import ./kuberouter.nix);
      default = {};
    });

    kubeProxy = mkOption {
      description = "Defines the configuration for kube-proxy.";
      type = submodule (import ./kubeproxy.nix);
      default = {};
    };

    nodeLocalLoadBalancing = {
      enabled = mkEnableOption "Indicates if node-local load balancing should be used to access Kubernetes API servers from worker nodes. Default: `false`.";

      type = mkOption {
        type = enum [ "EnvoyProxy" ];
        default = "EnvoyProxy";
        description = ''
          The type of the node-local load balancer to deploy on worker nodes.
          Default: `EnvoyProxy`. (This is the only option for now.)
        '';
      };

      envoyProxy = optionalAttrs (config.nodeLocalLoadBalancing.type == "EnvoyProxy") (mkOption {
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
      enabled = mkEnableOption "Indicates if control plane load balancing should be enabled. Default: `false`.";

      type = mkOption {
        type = enum [ "Keepalived" ];
        default = "Keepalived";
        description = ''
          The type of the control plane load balancer to deploy on controller nodes.
          Currently, the only supported type is `Keepalived`.
        '';
      };

      keepalived = optionalAttrs (config.controlPlaneLoadBalancing.type == "Keepalived") mkOption {
        type = nullOr (submodule {
          options = {
            vrrpInstances = mkOption {
              type = listOf submodule {
                options = {
                  virtualIPs = mkOption {
                    type = addCheck (listOf str) (l: builtins.length l > 0);
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
                    type = addCheck str (s: let len = builtins.stringLength s; in len >= 1 && len <= 8 );
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
                    type = addCheck str (s: builtins.stringLength s >= 1);
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
}