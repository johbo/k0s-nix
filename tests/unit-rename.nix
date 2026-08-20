# Does renaming the unit break a node that is already running? The unit sets
# KillMode=process and Delegate=yes, so a stop that leaves containerd and
# kubelet behind would have the new unit come up over processes still running.
#
# The generation before the rename is staged from the module itself: the unit
# file is identical on both sides, only the name it is written under moved, so
# the base generation attaches the rendered text under the old name and masks
# the new one. switch-to-configuration treats a masked unit and an absent one
# the same way, so the stop under test is the stop a real node takes.
{
  name = "unit-rename";
  nodes = {
    machine =
      { config, lib, ... }:
      {
        services.k0s = {
          enable = true;
          role = "single";
          spec.api = {
            address = config.networking.primaryIPAddress;
            sans = [ config.networking.primaryIPAddress ];
          };
        };

        systemd.units."k0scontroller.service" = {
          text = config.systemd.units."k0s.service".text;
          wantedBy = [ "multi-user.target" ];
        };
        systemd.services.k0s.enable = lib.mkDefault false;

        specialisation.renamed.configuration = {
          systemd.services.k0s.enable = lib.mkForce true;
          systemd.units."k0scontroller.service".enable = lib.mkForce false;
        };
      };
  };
  testScript =
    { nodes }:
    let
      k0s = nodes.machine.services.k0s.package;
    in
    ''
      def dump_state(label):
          machine.log(f"=== {label} ===")
          machine.log(machine.execute("systemd-cgls --no-pager")[1])
          machine.log(machine.execute("ps -eo pid,ppid,comm,cgroup")[1])
          machine.log(machine.execute(
              "systemctl status --no-pager k0scontroller.service k0s.service")[1])

      def pids_of(name):
          return sorted(machine.succeed(f"pgrep -x {name} || true").split())

      def k0s_processes(label):
          found = {}
          for name in ("containerd", "kubelet"):
              found[name] = pids_of(name)
              for pid in found[name]:
                  cgroup = machine.succeed(f"cat /proc/{pid}/cgroup").strip()
                  machine.log(f"{label}: {name} pid {pid} in {cgroup}")
          return found

      def line_starting_with(out, prefix):
          for index, line in enumerate(out.splitlines()):
              if line.startswith(prefix):
                  return index, line
          raise Exception(f"no line starting with {prefix!r} in:\n{out}")

      machine.wait_for_unit("k0scontroller.service")
      machine.wait_for_file("/run/k0s/status.sock")
      machine.succeed("${k0s}/bin/k0s status")

      # Waiting for the node object is how graceful-shutdown gets kubelet up
      # without needing the internet.
      machine.wait_until_succeeds(
          "${k0s}/bin/k0s kubectl wait --for=create nodes/machine")

      # The new name is not in play yet, which is what keeps the assertions
      # after the switch from passing vacuously.
      machine.fail("systemctl is-active k0s.service")
      before = k0s_processes("before the switch")
      for name, pids in before.items():
          assert len(pids) == 1, f"expected one {name} to start with, found {pids}"

      out = machine.succeed(
          "/run/current-system/specialisation/renamed/bin/"
          "switch-to-configuration test 2>&1")
      machine.log(out)

      try:
          stopped_at, stopped = line_starting_with(
              out, "stopping the following units:")
          started_at, started = line_starting_with(
              out, "the following new units were started:")
          assert "k0scontroller.service" in stopped, stopped
          assert "k0s.service" in started, started
          # The reverse order would put two k0s processes on one data directory.
          assert stopped_at < started_at, out

          machine.wait_for_unit("k0s.service")
          machine.fail("systemctl is-active k0scontroller.service")
          machine.wait_until_succeeds("${k0s}/bin/k0s status")
          machine.wait_until_succeeds("${k0s}/bin/k0s kubectl get nodes machine")

          # The controller comes up before the worker side does, so the process
          # count says nothing until containerd and kubelet are back.
          for name in before:
              machine.wait_until_succeeds(f"pgrep -x {name}")

          after = k0s_processes("after the switch")
          for name, pids in after.items():
              assert len(pids) == 1, (
                  f"expected one {name} after the switch, "
                  f"found {pids} (before: {before[name]})")
      except Exception:
          dump_state("after the switch")
          raise
    '';
}
