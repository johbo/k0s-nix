{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkPackageOption mkOption mkIf optionalString concatMapAttrs;
  inherit (lib.types) str enum bool path submodule;
  cfg = config.services.k0s;
in {
  options.services.k0s = {
    enable = mkEnableOption (lib.mdDoc "Enable the k0s Kubernetes distribution.");

    package = mkPackageOption pkgs "k0s" {};

    role = mkOption {
      description = ''
        The role of the node.
      '';
      type = enum ["controller" "controller+worker" "worker" "single"];
      default = "single";
    };

    isLeader = mkOption {
      description = ''
        The leader is used to generate the join tokens.
      '';
      type = bool;
      default = false;
    };

    dataDir = mkOption {
      description = ''
        The directory k0s should use to store data in.
      '';
      type = path;
      default = "/var/lib/k0s";
    };

    tokenFile = mkOption {
      description = ''
        The path where the join-token for a node is located.
      '';
      type = path;
      default = "/etc/k0s/k0stoken";
    };

    clusterName = mkOption {
      description = ''
        The name of the cluster.
      '';
      type = str;
      default = "k0s";
    };

    spec = mkOption {
      description = ''
        Defines the desired state of the cluster config.
      '';
      type = submodule (a: (import ./clusterSpec.nix (a // {inherit (cfg) dataDir;})));
      default = {};
    };

    configText = mkOption {
      description = ''
        The configuration file in YAML format.
        A default will be generated if unset.
      '';
      default = "";
      type = str;
    };

  };

  config = let
    subcommand =
      if (cfg.role == "worker")
      then "worker"
      else "controller";
    unitName = "k0s" + subcommand;
    configFile =
      if cfg.configText != ""
      then pkgs.writeText "k0s.yaml" cfg.configText
      else
        (pkgs.formats.yaml {}).generate "k0s.yaml" {
          apiVersion = "k0s.k0sproject.io/v1beta1";
          kind = "Cluster";
          metadata = {name = cfg.clusterName;};
          spec = cfg.spec;
        };
  in
    mkIf cfg.enable {
      environment.etc."k0s/k0s.yaml".source = configFile;

      environment.etc = lib.mkMerge [
        config.environment.etc
        (lib.mapAttrsToList (name: value: {
          inherit name;
          text = value;
          mode = "0644";
        }) config.spec.extensions.manifests)
      ];
      
      systemd.tmpfiles.rules = [
        "d /var/lib/k0s/manifests 0755 k0s k0s -"
        "L /var/lib/k0s/manifests - - - - /etc/k0s/manifests"
      ]

      ## END MANIFESTS

      systemd.services.${unitName} = {
        description = "k0s - Zero Friction Kubernetes";
        documentation = ["https://docs.k0sproject.io"];
        path = with pkgs; [
          kmod
          util-linux
          mount
        ];
        after = ["network-online.target"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];
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
          ExecStart =
            "${cfg.package}/bin/k0s ${subcommand} --data-dir=${cfg.dataDir}"
            + optionalString (cfg.role != "worker") " --config=${configFile}"
            + optionalString (cfg.role == "single") " --single"
            + optionalString (cfg.role == "controller+worker") " --enable-worker --no-taints"
            + optionalString (cfg.role != "single" && !cfg.isLeader) " --token-file=${cfg.tokenFile}";
        };
        unitConfig = mkIf (cfg.role != "single" && !cfg.isLeader) {
          ConditionPathExists = cfg.tokenFile;
        };
      };

      users.users =
        concatMapAttrs
        (name: value: {
          ${value} = {
            isSystemUser = true;
            group = "users";
            home = "${cfg.dataDir}";
          };
        })
        cfg.spec.installConfig.users;
    };
}
