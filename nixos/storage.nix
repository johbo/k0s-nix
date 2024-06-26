{ lib, config, dataDir, ... }@args: let
  inherit (lib) mkOption optionalAttrs;
  inherit (lib.types) str enum path nullOr attrsOf listOf port attrTag;
  util = import ./util.nix args;
in {
  options = {

    type = mkOption {
      type = enum [ "etcd" "kine" ];
      default = "etcd";
      description = ''
        Type of the data store (valid values: `etcd` or `kine`).
        **Note:** Type `etcd` will cause k0s to create and manage an elastic etcd cluster within the controller nodes.
      '';
    };

    etcd = optionalAttrs (config.type == "etcd") {
      peerAddress = mkOption {
        type = str;
        default = "127.0.0.1";
        description = ''
          Node address used for etcd cluster peering.
        '';
      };

      extraArgs = util.mkStringMapOption {
        example = ''
          {
            listen-client-urls = "https://127.0.0.1:2379";
            advertise-client-urls = "https://127.0.0.1:2379";
            client-cert-auth = "true";
            peer-client-cert-auth = "true";
            enable-pprof = "false";
          }
        '';
        description = ''
          Map of key-values (strings) for any extra arguments to pass down to etcd process.
        '';
      };

      externalCluster = mkOption {
        type = nullOr (attrsOf (attrTag {
          endpoints = {
            type = listOf str;
            description = ''
              Array of Etcd endpoints to use.
            '';
          };
          etcdPrefix = {
            type = str;
            description = ''
              Prefix to use for this cluster.
              The same external Etcd cluster can be used for several k0s clusters,
              each prefixed with unique prefix to store data with.
            '';
          };
          caFile = {
            type = path;
            description = ''
              CaFile is the host path to a file with Etcd cluster CA certificate.
            '';
          };
          clientCertFile = {
            type = path;
            description = ''
              ClientCertFile is the host path to a file with TLS certificate for etcd client.
            '';
          };
          clientKeyFile = {
            type = path;
            description = ''
              ClientKeyFile is the host path to a file with TLS key for etcd client.
            '';
          };
        }));
        default = null;
        description = ''
          Configuration when etcd is externally managed, i.e. running on dedicated nodes.
          See [`spec.storage.etcd.externalCluster`](https://docs.k0sproject.io/stable/configuration/#specstorageetcdexternalcluster)
        '';
      };
    };

    kine = optionalAttrs (config.type == "kine") {
      dataSource = mkOption {
        type = str;
        default = "sqlite://${dataDir}/db/state.db?mode=rwc&_journal=WAL&cache=shared";
        description = ''
          [kine](https://github.com/k3s-io/kine) datasource URL.
        '';
      };
    };

  };
}