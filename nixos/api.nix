{ lib, ... }@args: let
  inherit (lib) mkOption;
  inherit (lib.types) str listOf port;
  util = import ./util.nix args;
in {
  options = {

    address = mkOption {
      # No default, has to be provided
      type = str; # TODO validate IP
      description = ''
        Required. Local address on which to bind an API.
        Also serves as one of the addresses pushed on the k0s create service certificate on the API.
      '';
    };

    externalAddress = mkOption {
      type = str;
      default = "";
      description = ''
        The loadbalancer address (for k0s controllers running behind a loadbalancer).
        Configures all cluster components to connect to this address and also configures
        this address for use when joining new nodes to the cluster.
      '';
    };

    extraArgs = util.mkStringMapOption {
      example = ''
        {
          authorization-mode = "Node,RBAC";
          enable-bootstrap-token-auth = "true";
          kubelet-preferred-address-types = "InternalIP,ExternalIP,Hostname";
          requestheader-allowed-names = "front-proxy-client";
          tls-min-version = "VersionTLS12";
          service-account-issuer = "https://kubernetes.default.svc";
          service-account-jwks-uri = "https://kubernetes.default.svc/openid/v1/jwks";
          profiling = "false";
          enable-admission-plugins = "NodeRestriction";
        }
      '';
      description = ''
        Map of key-values (strings) for any extra arguments to pass down to Kubernetes api-server process.
      '';
    };

    k0sApiPort = mkOption {
      type = port;
      default = 9443;
      description = ''
        Custom port for k0s-api server to listen on (default: 9443).
      '';
    };

    port = mkOption {
      type = port;
      default = 6443;
      description = ''
        Custom port for kube-api server to listen on (default: 6443).
      '';
    };

    sans = mkOption {
      type = listOf str;
      description = ''
        Required. List of additional addresses to push to API servers serving the certificate.
      '';
    };

  };
}