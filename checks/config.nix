{
  lib,
  pkgs,
  nixpkgs,
  module,
  package,
}:
let
  base = {
    services.k0s = {
      enable = true;
      inherit package;
      role = lib.mkDefault "single";
      spec.api.address = "10.0.0.1";
    };
  };

  cases = {
    kuberouter-etcd = { };

    calico-vxlan = {
      services.k0s.spec.network.provider = "calico";
    };

    calico-bird-dual-stack = {
      services.k0s.spec.network = {
        provider = "calico";
        calico.mode = "bird";
        dualStack = {
          enabled = true;
          IPv6podCIDR = "fd00::/108";
          IPv6serviceCIDR = "fd01::/108";
        };
      };
    };

    kine = {
      services.k0s.spec.storage.type = "kine";
    };

    node-local-load-balancing = {
      services.k0s.spec.network.nodeLocalLoadBalancing.enabled = true;
    };

    control-plane-load-balancing = {
      services.k0s.spec.network.controlPlaneLoadBalancing = {
        enabled = true;
        keepalived.vrrpInstances = [
          {
            virtualIPs = [ "10.0.0.2/24" ];
            authPass = "changeme";
            # Unset, k0s looks up the default route's NIC; a sandbox has none.
            interface = "eth0";
          }
        ];
      };
    };

    controller = {
      services.k0s.role = "controller";
    };
  };

  evalCase =
    extra:
    (import (nixpkgs + "/nixos/lib/eval-config.nix") {
      inherit pkgs;
      # Dropping this falls back to builtins.currentSystem, which is
      # unavailable in a pure evaluation.
      system = null;
      modules = [
        module
        base
        extra
      ];
    }).config;

  k0sOf = extra: (evalCase extra).services.k0s;

  validate = name: extra: ''
    echo "==> ${name}"
    ${package}/bin/k0s config validate --config ${(k0sOf extra).configFile}
  '';

  withCheck = evalCase { services.k0s.enableConfigCheck = true; };
  withoutCheck = evalCase { };

  isWired =
    config:
    lib.any (
      check: check.drvPath == config.services.k0s.validatedConfigFile.drvPath
    ) config.system.checks;

  deployedConfig = config: config.environment.etc."k0s/k0s.yaml".source;

  # Naming a store path in the build would make this check depend on the
  # derivation it is asserting about, and on all of system.checks with it.
  report = value: builtins.unsafeDiscardStringContext (toString value);
in
pkgs.runCommand "k0s-config-cases"
  {
    preferLocalBuild = true;

    wiredWhenEnabled = lib.boolToString (isWired withCheck);
    wiredWhenDefault = lib.boolToString (isWired withoutCheck);
    enabledChecks = lib.concatMapStringsSep " " (check: check.name) withCheck.system.checks;
    deployedWithCheck = report (deployedConfig withCheck);
    deployedWithoutCheck = report (deployedConfig withoutCheck);
  }
  ''
    echo "==> system.checks with enableConfigCheck: $enabledChecks"
    echo "==> deployed with the check:    $deployedWithCheck"
    echo "==> deployed without the check: $deployedWithoutCheck"

    if [ "$wiredWhenEnabled" != "true" ]; then
      echo "enableConfigCheck does not add validatedConfigFile to system.checks" >&2
      exit 1
    fi
    if [ "$wiredWhenDefault" != "false" ]; then
      echo "validatedConfigFile is in system.checks without enableConfigCheck" >&2
      exit 1
    fi
    if [ "$deployedWithCheck" != "$deployedWithoutCheck" ]; then
      echo "enableConfigCheck changes the deployed /etc/k0s/k0s.yaml" >&2
      exit 1
    fi

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList validate cases)}

    echo "==> validatedConfigFile"
    test -s ${(k0sOf { }).validatedConfigFile}

    touch $out
  ''
