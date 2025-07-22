{ lib, ... }@args:
let
  inherit (lib) mkEnableOption mkOption;
  inherit (lib.types)
    str
    enum
    bool
    nullOr
    attrsOf
    listOf
    attrTag
    int
    ;
  customTypes = import ./types.nix args;
in
{
  options = {
    disabled = mkEnableOption ''
      Disable kube-proxy altogether (default: `false`).
    '';

    mode = mkOption {
      description = ''
        Kube proxy operating mode, supported modes iptables, ipvs, userspace (default: iptables).
      '';
      type = enum [
        "iptables"
        "ipvs"
        "userspace"
      ];
      default = "iptables";
    };

    metricsBindAddress = mkOption {
      description = ''
        Address and port for exposing metrics of kube-proxy.
      '';
      type = customTypes.ipWithPort;
      default = "0.0.0.0:10249";
    };

    iptables = mkOption {
      description = ''
        Kube proxy iptables settings.
      '';
      type = nullOr (
        attrsOf (attrTag {
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
        })
      );
      default = null;
    };

    ipvs = mkOption {
      description = ''
        Kube proxy ipvs settings.
      '';
      type = nullOr (
        attrsOf (attrTag {
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
            type = nullOr (listOf customTypes.cidr);
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
        })
      );
      default = null;
    };

    nodePortAddresses = mkOption {
      description = ''
        Kube proxy [nodePortAddresses](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/).
      '';
      type = nullOr (listOf customTypes.cidr);
      default = null;
    };
  };
}
