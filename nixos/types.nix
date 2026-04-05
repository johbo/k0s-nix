{ lib, ... }:
let
  inherit (lib.types)
    either
    enum
    path
    addCheck
    submodule
    str
    ;

  isValidPort =
    portStr:
    lib.match "[0-9]+" portStr != null
    && (
      let
        port = lib.strings.toIntBase10 portStr;
      in
      port >= 1 && port <= 65535
    );

  isValidIpV4 =
    ipStr:
    let
      octets = lib.splitString "." ipStr;
    in
    lib.length octets == 4
    && lib.all (
      o:
      lib.match "[0-9]+" o != null
      && (
        let
          p = lib.strings.toIntBase10 o;
        in
        p >= 0 && p <= 255
      )
    ) octets;

  isValidIpV4WithPort =
    s:
    let
      parts = lib.splitString ":" s;
    in
    lib.length parts == 2 && isValidIpV4 (lib.elemAt parts 0) && isValidPort (lib.elemAt parts 1);

  isValidIpV6 =
    ipStr:
    let
      groups = lib.splitString ":" ipStr;
      nonEmpty = lib.filter (g: g != "") groups;
      numGroups = lib.length nonEmpty;
      hasDoubleColon = lib.any (g: g == "") groups;
    in
    ipStr != ""
    && (if hasDoubleColon then numGroups >= 1 && numGroups <= 7 else numGroups == 8)
    && lib.all (g: lib.match "[0-9a-fA-F]{1,4}" g != null) nonEmpty;

  isValidIpV6Brackets =
    s:
    let
      len = lib.stringLength s;
      inner = if len > 2 then lib.substring 1 (len - 2) s else "";
    in
    lib.hasPrefix "[" s && lib.hasSuffix "]" s && isValidIpV6 inner;

  splitLast =
    sep: s:
    let
      parts = lib.splitString sep s;
      len = lib.length parts;
    in
    if len <= 1 then
      [ s ]
    else
      let
        prefix = lib.concatStringsSep sep (lib.take (len - 1) parts);
        suffix = lib.last parts;
      in
      [
        prefix
        suffix
      ];

  isValidIpV6WithPort =
    s:
    let
      parts = splitLast ":" s;
    in
    lib.length parts == 2
    && isValidIpV6Brackets (lib.elemAt parts 0)
    && isValidPort (lib.elemAt parts 1);

  isValidCidrV4 =
    s:
    let
      parts = lib.splitString "/" s;
    in
    if lib.length parts != 2 then
      false
    else
      let
        ip = lib.elemAt parts 0;
        prefixStr = lib.elemAt parts 1;
      in
      lib.match "[0-9]+" prefixStr != null
      && (
        let
          prefix = lib.strings.toIntBase10 prefixStr;
        in
        prefix >= 0 && prefix <= 32
      )
      && isValidIpV4 ip;

  isValidCidrV6 =
    s:
    let
      parts = lib.splitString "/" s;
    in
    if lib.length parts != 2 then
      false
    else
      let
        ip = lib.elemAt parts 0;
        prefixStr = lib.elemAt parts 1;
      in
      lib.match "[0-9]+" prefixStr != null
      && (
        let
          prefix = lib.strings.toIntBase10 prefixStr;
        in
        prefix >= 0 && prefix <= 128
      )
      && isValidIpV6 ip;

  isValidDnsName =
    hostname:
    let
      labels = lib.splitString "." hostname;
      isValidLabel =
        l:
        lib.stringLength l > 0
        && lib.stringLength l <= 63
        && lib.match "[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?" l != null;
      isNumericLabel = l: lib.match "[0-9]+" l != null;
      allNumeric = lib.all isNumericLabel labels;
    in
    lib.stringLength hostname <= 253
    && lib.length labels >= 1
    && lib.all isValidLabel labels
    && !allNumeric;

  isValidEtcdEndpoint =
    s:
    let
      parts = lib.splitString "://" s;
    in
    if lib.length parts != 2 then
      false
    else
      let
        scheme = lib.elemAt parts 0;
        rest = splitLast ":" (lib.elemAt parts 1);
      in
      if lib.length rest != 2 then
        false
      else
        let
          host = lib.elemAt rest 0;
          port = lib.elemAt rest 1;
        in
        (scheme == "http" || scheme == "https")
        && isValidPort port
        && (isValidIpV6Brackets host || isValidIpV4 host || isValidDnsName host);
in
rec {
  ipV4 = addCheck str isValidIpV4;
  ipV6 = addCheck str isValidIpV6;
  ip = either ipV4 ipV6;
  dnsName = addCheck str isValidDnsName;
  ipOrDnsName = either ip dnsName;
  cidrV4 = addCheck str isValidCidrV4;
  cidrV6 = addCheck str isValidCidrV6;
  cidr = either cidrV4 cidrV6;
  ipV4WithPort = addCheck str isValidIpV4WithPort;
  ipV6WithPort = addCheck str isValidIpV6WithPort;
  ipWithPort = either ipV4WithPort ipV6WithPort;
  etcdEndpoint = addCheck str isValidEtcdEndpoint;
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
}
