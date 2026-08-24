{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkRemovedOptionModule
    mkOption
    mkIf
    literalMD
    optionalString
    concatMapAttrs
    ;
  inherit (lib.types)
    bool
    str
    enum
    package
    path
    submodule
    ;
  cfg = config.services.k0s;

  generatedConfig = (pkgs.formats.yaml { }).generate "k0s.yaml" {
    apiVersion = "k0s.k0sproject.io/v1beta1";
    kind = "Cluster";
    metadata = {
      name = cfg.clusterName;
    };
    inherit (cfg) spec;
  };

  validatedConfig =
    pkgs.runCommand "k0s.yaml-validated"
      {
        preferLocalBuild = true;
      }
      ''
        ln -s ${cfg.configFile} $out
        ${cfg.package}/bin/k0s config validate --config $out
      '';

  canValidate = pkgs.stdenv.buildPlatform.canExecute pkgs.stdenv.hostPlatform;

  deployedConfig =
    if cfg.validateConfig && canValidate then cfg.validatedConfigFile else cfg.configFile;
in
{
  imports = [
    (mkRemovedOptionModule [
      "services"
      "k0s"
      "isLeader"
    ] "Use services.k0s.controller.isLeader instead.")
  ];

  options.services.k0s = {
    enable = mkEnableOption "the k0s Kubernetes distribution";

    package = mkPackageOption pkgs "k0s" { };

    role = mkOption {
      description = ''
        The role of the node.
      '';
      type = enum [
        "controller"
        "controller+worker"
        "worker"
        "single"
      ];
      default = "single";
    };

    controller = lib.optionalAttrs (cfg.role == "controller" || cfg.role == "controller+worker") (
      lib.mkOption {
        description = ''
          Controller specific configuration
        '';
        type = submodule {
          options = {
            isLeader = lib.mkOption {
              description = ''
                The leader is used to generate the join tokens.
              '';
              default = false;
            };
          };
        };
        default = { };
      }
    );

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
      type = submodule (a: (import ./clusterSpec.nix (a // { inherit (cfg) dataDir; })));
      default = { };
    };

    extraArgs = mkOption {
      description = ''
        Extra arguments to pass to systemd ExecStart
      '';
      default = "";
      type = str;
    };

    configFile = mkOption {
      description = ''
        The generated k0s configuration, as it is placed in
        `/etc/k0s/k0s.yaml`. Build this to read what the module makes
        of the options set on it.
      '';
      type = package;
      readOnly = true;
      default = generatedConfig;
      defaultText = literalMD "the configuration generated from {option}`services.k0s.spec`";
    };

    validatedConfigFile = mkOption {
      description = ''
        {option}`services.k0s.configFile` with `k0s config validate`
        run over it while building. Build this attribute to get the
        validation result on its own, without making the system build
        depend on it.

        It runs the packaged k0s binary, so it needs a builder that can
        execute it, and it runs under Nix's sandbox. Configuration that
        k0s checks against the host it runs on cannot be validated
        there.
      '';
      type = package;
      readOnly = true;
      default = validatedConfig;
      defaultText = literalMD "{option}`services.k0s.configFile`, validated";
    };

    validateConfig = mkOption {
      description = ''
        Whether the system build depends on
        {option}`services.k0s.validatedConfigFile`, so that an invalid
        configuration fails the build instead of the node.

        Off by default: it runs the packaged k0s binary on the builder,
        and ties every build to the rules of one k0s version. It is
        skipped where the builder cannot execute the binary, which is
        why {option}`services.k0s.validatedConfigFile` stays the way to
        ask for an answer rather than a default.
      '';
      type = bool;
      default = false;
    };
  };

  config =
    let
      subcommand = if (cfg.role == "worker") then "worker" else "controller";
      isExternalEtcd = cfg.spec.storage.type == "etcd" && cfg.spec.storage.etcd.externalCluster != null;
      isWorker = cfg.role == "worker";
      isLeader = (cfg.role == "single") || (cfg.controller.isLeader or false);
      requireJoinToken = isWorker || (!isLeader && !isExternalEtcd);
      unitName = "k0s";
      forbiddenArgs = [
        "--data-dir"
        "--config"
        "--single"
        "--token-file"
      ];
      containsAny =
        string: searchList: builtins.any (substr: lib.strings.hasInfix substr string) searchList;
    in
    mkIf cfg.enable {
      assertions = [
        {
          assertion = !(containsAny cfg.extraArgs forbiddenArgs);
          message = "extraArgs must not include ${builtins.concatStringsSep "," forbiddenArgs}";
        }
      ];

      environment.etc."k0s/k0s.yaml".source = deployedConfig;

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
          ExecStart =
            "${cfg.package}/bin/k0s ${subcommand} --data-dir=${cfg.dataDir}"
            + optionalString (cfg.role != "worker") " --config=${deployedConfig}"
            + optionalString (cfg.role == "single") " --single"
            + optionalString (cfg.role == "controller+worker") " --enable-worker --no-taints"
            + optionalString requireJoinToken " --token-file=${cfg.tokenFile}"
            + " ${cfg.extraArgs}";
        };
        unitConfig = mkIf requireJoinToken { ConditionPathExists = cfg.tokenFile; };
      };

      users.users = concatMapAttrs (name: value: {
        ${value} = {
          isSystemUser = true;
          group = "users";
          home = "${cfg.dataDir}";
        };
      }) cfg.spec.installConfig.users;
    };
}
