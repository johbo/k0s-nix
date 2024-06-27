{ lib, ... }: {
  options = {
    image = lib.mkOption {
      type = lib.types.str;
      default = ""; # k0s knows better what images to use than us
    };
    version = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };
}