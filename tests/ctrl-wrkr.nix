{
  name = "ctrl-wrkr";
  nodes = {
    node1 =
      { config, ... }:
      {
        services.k0s = {
          enable = true;
          role = "controller+worker";
          controller = {
            isLeader = true;
          };
          spec.api = {
            address = config.networking.primaryIPAddress;
            sans = [ config.networking.primaryIPAddress ];
          };
        };

      };
  };
  testScript =
    { nodes }:
    let
      k0s = nodes.node1.services.k0s.package;
    in
    ''
      start_all()
      node1.wait_for_unit("k0scontroller")
      node1.wait_for_file("/run/k0s/status.sock")
      node1.succeed("${k0s}/bin/k0s status")
    '';
}
