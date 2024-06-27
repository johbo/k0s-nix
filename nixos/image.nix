{ lib, ... }: {
  options = {
    image = lib.mkOption {
      type = lib.types.str;
    };
    version = lib.mkOption {
      type = lib.types.str;
    };
  };
}