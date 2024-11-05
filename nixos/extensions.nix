{lib, ...} @ args: let
  inherit (lib) mkOption;
  inherit (lib.types) nullOr int str enum bool listOf addCheck submodule;
  customTypes = import ./types.nix args;
in {
  options = {
    storage = {
      type = mkOption {
        type = enum ["external_storage" "openebs_local_storage"];
        default = "external_storage";
      };

      create_default_storage_class = mkOption {
        type = bool;
        default = false;
      };
    };

    helm = {
      concurrencyLevel = mkOption {
        type = int;
        default = 5;
      };

      repositories = mkOption {
        type = listOf (submodule {
          options = {
            name = mkOption {
              description = "The repository name. Required.";
              type = addCheck str (s: s != "");
            };
            url = mkOption {
              description = "The repository URL. Required.";
              type = addCheck str (s: s != "");
            };
            insecure = mkOption {
              description = "Whether to skip TLS certificate checks when connecting to the repository.";
              type = nullOr bool;
              default = null;
            };
            caFile = mkOption {
              description = "CA bundle file to use when verifying HTTPS-enabled servers.";
              type = customTypes.emptyOrPath;
              default = "";
            };
            certFile = mkOption {
              description = "The TLS certificate file to use for HTTPS client authentication.";
              type = customTypes.emptyOrPath;
              default = "";
            };
            keyFile = mkOption {
              description = "The TLS key file to use for HTTPS client authentication.";
              type = customTypes.emptyOrPath;
              default = "";
            };
            username = mkOption {
              description = "Username for Basic HTTP authentication.";
              type = str;
              default = "";
            };
            password = mkOption {
              description = "Password for Basic HTTP authentication.";
              type = str;
              default = "";
            };
          };
        });
        default = [];
      };

      charts = mkOption {
        type = listOf (submodule {
          options = {
            name = mkOption {
              description = "The release name under which the chart should be installed. Required.";
              type = addCheck str (s: s != "");
            };
            chartname = mkOption {
              description = "The name of the chart to install. Required.";
              type = addCheck str (s: s != "");
            };
            version = mkOption {
              description = "The version of the chart to install. Leaving this empty defaults to the latest.";
              type = str;
              default = "";
            };
            namespace = mkOption {
              description = "The target namespace in which to install the chart. Required.";
              type = addCheck str (s: s != "");
            };
            timeout = mkOption {
              description = ''
                Specifies the timeout for how long to wait for the chart installation to finish.
                A duration string is a sequence of decimal numbers, each with optional fraction and a unit suffix,
                such as "300ms" or "2h45m". Valid time units are "ns", "us" (or "µs"), "ms", "s", "m", "h".
              '';
              type = str;
              default = "0s";
            };
            order = mkOption {
              description = "The order in which to install the chart in relation to other charts.";
              type = int;
              default = 0;
            };
          };
        });
        default = [];
      };
    };
      
  };
}
