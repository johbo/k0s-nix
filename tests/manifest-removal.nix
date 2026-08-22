# Experiment. Does k0s notice that a stack directory disappeared while it was
# stopped, or does it only ever see the fsnotify event?
#
# Two stacks, each a single ConfigMap. One directory is removed while k0s runs,
# which establishes that the prune works at all and that the check can see a
# deletion. The other is removed while k0s is stopped, which is the case the
# module's documentation would have to make a claim about.
#
# The probe is a ConfigMap rather than a Namespace on purpose: namespace
# finalization blocks on complete API discovery, and the metrics-server
# APIService is unavailable on a single node with no CNI, so a deleted
# namespace stays in Terminating and reports nothing about the deployer.
{
  name = "manifest-removal";
  nodes = {
    machine =
      { config, ... }:
      {
        services.k0s = {
          enable = true;
          role = "single";
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
      k0s = "${nodes.machine.services.k0s.package}/bin/k0s";
    in
    ''
      def write_stack(name):
          machine.succeed(f"mkdir -p /var/lib/k0s/manifests/{name}")
          machine.succeed(
              f"cat > /var/lib/k0s/manifests/{name}/configmap.yaml <<EOF\n"
              "apiVersion: v1\n"
              "kind: ConfigMap\n"
              "metadata:\n"
              f"  name: {name}\n"
              "  namespace: default\n"
              "EOF\n"
          )

      def api_is_up():
          machine.wait_for_file("/run/k0s/status.sock")
          machine.wait_until_succeeds("${k0s} kubectl get configmaps", timeout=300)

      start_all()
      machine.wait_for_unit("k0s")
      api_is_up()

      write_stack("while-running")
      write_stack("while-stopped")
      machine.wait_until_succeeds("${k0s} kubectl get configmap while-running", timeout=180)
      machine.wait_until_succeeds("${k0s} kubectl get configmap while-stopped", timeout=180)

      print("LABELS " + machine.succeed(
          "${k0s} kubectl get configmap while-stopped -o jsonpath='{.metadata.labels}'"
      ))

      machine.succeed("rm -r /var/lib/k0s/manifests/while-running")
      machine.wait_until_fails("${k0s} kubectl get configmap while-running", timeout=180)
      print("RESULT while-running: pruned")

      machine.succeed("systemctl stop k0s")
      machine.succeed("rm -r /var/lib/k0s/manifests/while-stopped")
      machine.succeed("systemctl start k0s")
      machine.wait_for_unit("k0s")
      api_is_up()
      machine.sleep(120)

      print("RESULT while-stopped: " + machine.succeed(
          "${k0s} kubectl get configmap while-stopped -o name || echo pruned"
      ))
    '';
}
