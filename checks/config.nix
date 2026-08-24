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
      role = lib.mkDefault "single";
      spec.api.address = "10.0.0.1";
    };
    services.k0s.package = package;
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
    }).config.services.k0s;

  validate = name: extra: ''
    echo "==> ${name}"
    ${package}/bin/k0s config validate --config ${(evalCase extra).configFile}
  '';
in
pkgs.runCommand "k0s-config-cases"
  {
    preferLocalBuild = true;
  }
  ''
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList validate cases)}

    echo "==> validatedConfigFile"
    test -s ${(evalCase { }).validatedConfigFile}

    touch $out
  ''
