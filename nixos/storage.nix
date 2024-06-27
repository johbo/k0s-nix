{ lib, config, dataDir, ... }@args: let
  inherit (lib) mkOption optionalAttrs;
  inherit (lib.types) str enum nullOr listOf submodule addCheck;
  util = import ./util.nix args;
in {
  options = {

    type = mkOption {
      description = ''
        Type of the data store (valid values: `etcd` or `kine`).
        **Note:** Type `etcd` will cause k0s to create and manage an elastic etcd cluster within the controller nodes.
      '';
      type = enum [ "etcd" "kine" ];
      default = "etcd";
    };

    etcd = optionalAttrs (config.type == "etcd") {
      peerAddress = mkOption {
        description = ''
          Node address used for etcd cluster peering.
        '';
        type = str;
        default = "127.0.0.1";
      };

      extraArgs = util.mkStringMapOption {
        description = ''
          Map of key-values (strings) for any extra arguments to pass down to etcd process.
        '';
        example = ''
          {
            listen-client-urls = "https://127.0.0.1:2379";
            advertise-client-urls = "https://127.0.0.1:2379";
            client-cert-auth = "true";
            peer-client-cert-auth = "true";
            enable-pprof = "false";
          }
        '';
      };

      externalCluster = mkOption {
        description = ''
          Configuration when etcd is externally managed, i.e. running on dedicated nodes.
          See [`spec.storage.etcd.externalCluster`](https://docs.k0sproject.io/stable/configuration/#specstorageetcdexternalcluster)
        '';
        type = nullOr (submodule {
          options = {
            endpoints = mkOption {
              description = ''
                Array of Etcd endpoints to use.
              '';
              type = addCheck (listOf (addCheck str (s: builtins.stringLength s >= 1))) (l: builtins.length l > 0);
            };
            etcdPrefix = mkOption {
              description = ''
                Prefix to use for this cluster.
                The same external Etcd cluster can be used for several k0s clusters,
                each prefixed with unique prefix to store data with.
              '';
              type = addCheck str (s: builtins.stringLength s >= 1);
            };
            caFile = mkOption {
              description = ''
                CaFile is the host path to a file with Etcd cluster CA certificate.
              '';
              type = str;
              default = "";
            };
            clientCertFile = mkOption {
              description = ''
                ClientCertFile is the host path to a file with TLS certificate for etcd client.
              '';
              type = str;
              default = "";
            };
            clientKeyFile = mkOption {
              description = ''
                ClientKeyFile is the host path to a file with TLS key for etcd client.
              '';
              type = str;
              default = "";
            };
          };
        });
        default = null;
      };
    };

    kine = optionalAttrs (config.type == "kine") {
      dataSource = mkOption {
        description = ''
          [kine](https://github.com/k3s-io/kine) datasource URL.
        '';
        type = str;
        default = "sqlite://${dataDir}/db/state.db?mode=rwc&_journal=WAL&cache=shared";
      };
    };

  };
}