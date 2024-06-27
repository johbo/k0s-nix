{ lib, config, ... }@args: let
  inherit (lib) mkEnableOption mkOption optionalAttrs;
  inherit (lib.types) str enum submodule;
  util = import ./util.nix args;
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

    kuberouter = optionalAttrs (config.provider == "kuberouter") (mkOption {
      description = "Options for the `kuberouter` network provider.";
      type = submodule (import ./kuberouter.nix);
      default = {};
    });

    calico = optionalAttrs (config.provider == "calico") (mkOption {
      description = "Options for the `calico` network provider.";
      type = submodule (import ./calico.nix);
      default = {};
    });

    dualStack = {
      enable = mkEnableOption "Defines whether or not IPv4/IPv6 dual-stack networking should be enabled.";

      IPv6podCIDR = util.mkOptionMandatoryIf config.dualStack.enable {
        type = str;
        description = ''
          IPv6 Pod network CIDR to use in the cluster.
        '';
      } "";

      IPv6serviceCIDR = util.mkOptionMandatoryIf config.dualStack.enable {
        type = str;
        description = ''
          IPv6 Network CIDR to use for cluster VIP services.
        '';
      } "";
    };

    kubeProxy = mkOption {
      description = "Defines the configuration for kube-proxy.";
      type = submodule (import ./kubeproxy.nix);
      default = {};
    };

    nodeLocalLoadBalancing = mkOption {
      description = ''
        Configuration options related to k0s's node-local load balancing feature.

        **Note:** This feature is currently unsupported on ARMv7!
      '';
      type = submodule (import ./nllb.nix);
      default = {};
    };

    controlPlaneLoadBalancing = mkOption {
      description = "ControlPlaneLoadBalancingSpec defines the configuration options related to k0s's keepalived feature.";
      type = submodule (import ./cplb.nix);
      default = {};
    };

  };
}