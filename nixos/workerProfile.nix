{lib, ...}: let
  inherit (lib) mkOption;
  inherit (lib.types) str attrsOf anything;
in {
  options = {
    name = mkOption {
      description = ''
        Name to use as profile selector for the worker process
      '';
      type = str;
    };
    values = mkOption {
      description = ''
        [Kubelet configuration](https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/) overrides.
        Note that there are several fields that cannot be overridden:
        - `clusterDNS`
        - `clusterDomain`
        - `apiVersion`
        - `kind`
        - `staticPodURL`
      '';
      type = attrsOf anything;
    };
  };
}
