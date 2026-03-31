{ lib, ... }:
let
  inherit (lib.types)
    strMatching
    either
    enum
    path
    addCheck
    submodule
    str
    ;
  ipV4Regex = "((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])[.]){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])";
  # nixfmt: disable
  ipV6Regex =
    "("
    + (lib.concatStringsSep "|" [
      "([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}" # Full
      "([0-9a-fA-F]{1,4}:){1,7}:" # Compressed end
      "([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}" # Compressed mid
      "([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}" # Compressed mid
      "([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}" # Compressed mid
      "([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}" # Compressed mid
      "([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}" # Compressed mid
      "[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})" # Compressed start
      ":((:[0-9a-fA-F]{1,4}){1,7}|:)" # Loopback/Leading
      "fe80:(:[0-9a-fA-F]{1,4}){0,4}%[0-9a-zA-Z]+" # Link-local
      "::(ffff(:0{1,4}){0,1}:){0,1}${ipV4Regex}" # IPv4-mapped
      "([0-9a-fA-F]{1,4}:){1,4}:${ipV4Regex}" # IPv4-embedded
    ])
    + ")";
  # nixfmt: disable
  cidrV4MaskRegex = "([1-9]|[12][0-9]|3[0-2])";
  cidrV6MaskRegex = "([1-9]|[1-9][0-9]|1[01][0-9]|12[0-8])";
  dnsNameRegex = "(([a-zA-Z0-9]|[a-zA-Z0-9][-a-zA-Z0-9]*[a-zA-Z0-9])[.])*([A-Za-z0-9]|[A-Za-z0-9][-A-Za-z0-9]*[A-Za-z0-9])";
  portRegex = "((6553[0-5])|(655[0-2][0-9])|(65[0-4][0-9]{2})|(6[0-4][0-9]{3})|([1-5][0-9]{4})|([1-9][0-9]{0,3})|(0))";
  types = rec {
    ipV4 = strMatching "^${ipV4Regex}$";
    ipV6 = strMatching "^${ipV6Regex}$";
    ip = either ipV4 ipV6;
    dnsName = addCheck (strMatching "^${dnsNameRegex}$") (a: !ip.check a);
    ipOrDnsName = either ip dnsName;
    cidrV4 = strMatching "^${ipV4Regex}/${cidrV4MaskRegex}$";
    cidrV6 = strMatching "^${ipV6Regex}/${cidrV6MaskRegex}$";
    cidr = either cidrV4 cidrV6;
    ipV4WithPort = strMatching "^${ipV4Regex}:${portRegex}$";
    ipV6WithPort = strMatching "^\\[${ipV6Regex}\\]:${portRegex}$";
    ipWithPort = either ipV4WithPort ipV6WithPort;
    etcdEndpoint = strMatching "^https?://(\\[${ipV6Regex}\\]|${ipV4Regex}|${dnsNameRegex}):${portRegex}$";
    emptyOrPath = either (enum [ "" ]) path;
    image = submodule {
      options = {
        image = lib.mkOption {
          type = str;
        };
        version = lib.mkOption {
          type = str;
        };
      };
    };
  };
in
types
