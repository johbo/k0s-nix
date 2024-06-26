{ lib, config, ... }@args: let
  inherit (lib) mkEnableOption mkOption optionalString;
  inherit (lib.types) str enum path port ints addCheck;
  util = import ./util.nix args;
in {
  options = {

    mode = mkOption {
      type = enum [ "vxlan" "ipip" "bird" ];
      default = "vxlan";
      description = ''
        `vxlan` (default), `ipip` or `bird`
      '';
    };

    overlay = mkOption {
      type = addCheck (enum [ "Always" "CrossSubnet" "Never" ]) (v: config.mode == "vxlan" || v != "Never");
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

    wireguard = mkEnableOption ''
      Enable wireguard-based encryption (default: `false`).
      Your host system must be wireguard ready (refer to the [Calico documentation](https://docs.projectcalico.org/security/encrypt-cluster-pod-traffic) for details).
    '';

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

    ipV6AutodetectionMethod = mkOption {
      type = str;
      default = "";
      description = ''
        Use to force Calico to pick up the interface for IPv6 pod network inter-node routing
        (default: `""`, meaning not set, so that Calico will instead use its defaults).
        For more information, refer to the [Calico documentation](https://docs.projectcalico.org/reference/node/configuration#ip-autodetection-methods).
      '';
    };

    envVars = util.mkStringMapOption {
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
}