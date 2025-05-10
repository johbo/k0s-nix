{
  name = "basic";
  nodes = {
    node1 = { config, ... }: {
      services.k0s = {
        enable = true;
        role = "single";
        spec = {
          api = {
            address = config.networking.primaryIPAddress;
            sans = [ config.networking.primaryIPAddress ];
          };
          workerProfiles = [{
            name = "default";
            values = {
              shutdownGracePeriod = "30s";
              shutdownGracePeriodCriticalPods = "10s";
            };
          }];
        };
      };

    };
  };
  testScript = { nodes }:
    let k0s = nodes.node1.services.k0s.package;
    in ''
      start_all()
      node1.wait_for_unit("k0scontroller")
      node1.wait_for_file("/run/k0s/status.sock")
      node1.succeed("${k0s}/bin/k0s status")

      # we cannot wait for the node to be Ready because it requires access to the internet to download some containers and OpenAPI specs.
      #   so instead, we just wait until the node is created, which means the kubelet process is running
      node1.wait_until_succeeds(r"""${k0s}/bin/k0s kubectl wait --for=create nodes/node1""")

      # Assert that it has registered itself to inhibit systemd shutdown
      node1.succeed("systemd-inhibit --list --no-legend | grep \"kubelet.*shutdown\"")
    '';
}
