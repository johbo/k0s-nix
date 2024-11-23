{
  name = "basic";
  nodes = {
    node1 = { self, pkgs, ... }: {
      imports = [ self.nixosModules.default ];

      # runNixOSTest makes nixpkgs.* readonly, so we can't use this:
      # nixpkgs.overlays = [ self.overlays.default ];

      services.k0s = {
        enable = true;
        package = (pkgs.extend self.overlays.default).k0s;
        spec.api = {
          address = "192.0.2.1";
          sans = [ "192.0.2.1" ];
        };
      };
    };
  };
  testScript = ''
    start_all()
    node1.wait_for_unit("k0scontroller")
  '';
}
