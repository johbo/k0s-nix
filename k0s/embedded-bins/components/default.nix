{ lib, callPackage }:
let
  pins = import ../pins.nix { inherit lib; };

  # The JSON shape stops here: a component derivation takes the pins it needs
  # as arguments and knows nothing about the file they were read from.
  forMinor = minor: {
    etcd = callPackage ./etcd.nix {
      component = (pins.read minor).upstream.components.etcd;
      sources.etcd = pins.fetch minor "etcd";
    };

    runc = callPackage ./runc.nix {
      component = (pins.read minor).upstream.components.runc;
      sources = {
        runc = pins.fetch minor "runc";
        libseccomp = pins.fetch minor "runc/extra";
      };
    };
  };
in
lib.genAttrs pins.minors forMinor
