# This file tests that the `hostNetwork` option for Calico is correctly
# processed and rendered into the final k0s configuration file.
{ pkgs, ... }:

{
  name = "k0s-calico-host-network";
  meta.maintainers = [ ]; # You can add your GitHub handle here if you like

  nodes.machine = { pkgs, ... }: {
    services.k0s = {
      enable = true;
      role = "single"; # A single node is sufficient for this config check
      spec = {
        network = {
          provider = "calico";
          calico.hostNetwork = true; # <-- The new option we are testing
        };
      };
    };
  };

  # The test script that runs inside the virtual machine.
  testScript = ''
    start_all()
    machine.wait_for_unit("k0s.service")

    # The test succeeds if the generated k0s.yaml contains the expected line.
    # We use `yq` (which is available in the test environment) to parse the YAML
    # and check the value, which is more robust than using grep.
    machine.succeed(
      "${pkgs.yq-go}/bin/yq -e '.spec.network.calico.hostNetwork == true' /etc/k0s/k0s.yaml"
    )
  '';
}