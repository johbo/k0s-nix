{ lib, ... }@args: let
  inherit (lib) mkEnableOption mkOption;
  inherit (lib.types) str enum bool nullOr attrsOf listOf attrTag int;
in {
  options = {
    disabled = mkEnableOption ''
      Disable kube-proxy altogether (default: `false`).
    '';

    mode = mkOption {
      type = enum [ "iptables" "ipvs" "userspace" ];
      default = "iptables";
      description = ''
        Kube proxy operating mode, supported modes iptables, ipvs, userspace (default: iptables).
      '';
    };

    metricsBindAddress = mkOption {
      type = str;
      default = "0.0.0.0:10249";
      description = ''
        Address and port for exposing metrics of kube-proxy.
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
}