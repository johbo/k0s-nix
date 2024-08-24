{lib, ...} @ args: let
  inherit (lib) mkOption;
  inherit (lib.types) str enum bool nullOr listOf;
in {
  options = {
    name = mkOption {
      type = str;
    };
    enabled = mkOption {
      type = bool;
    };
    components = mkOption {
      type = nullOr listOf enum ["kube-apiserver" "kube-controller-manager" "kubelet" "kube-scheduler" "kube-proxy"];
      default = null;
    };
  };
}
