{ ... }:
let
  apiAddress = "10.0.1.1";
  mkNode =
    node-idx: role:
    let
      ipAddress = "10.0.1.${toString node-idx}";
    in
    {
      networking = {
        useNetworkd = true;
        useDHCP = false;
        firewall.enable = false;
      };

      systemd.network.networks."01-eth1" = {
        name = "eth1";
        networkConfig.Address = "${ipAddress}/24";
      };

      services.k0s = {
        enable = true;
        role = role;
        spec.api = {
          address = apiAddress;
          sans = [ apiAddress ];
        };
      }
      // (if role == "controller" then { controller.isLeader = true; } else { });
    };
in
{
  name = "cluster";
  nodes = {
    ctrl = mkNode 1 "controller";
    wrkr1 = mkNode 2 "worker";
    wrkr2 = mkNode 3 "worker";
  };
  testScript =
    { nodes }:
    let
      k0s = nodes.ctrl.services.k0s.package;
      tokenFile = nodes.wrkr1.services.k0s.tokenFile;
    in
    ''
      start_all()
      ctrl.wait_for_unit("k0scontroller")
      ctrl.wait_for_file("/run/k0s/status.sock")
      ctrl.succeed("${k0s}/bin/k0s status")

      def mkJoinToken():
        (exit_code, stdout) = ctrl.execute("${k0s}/bin/k0s token create --role=worker")
        if exit_code != 0:
          raise Exception("failed to create join token: {stdout}")
        return stdout.strip()

      for node in [wrkr1, wrkr2]:
        info=node.get_unit_info("k0sworker")
        assert info['ActiveState'] == "inactive"
        token = mkJoinToken()
        node.succeed(f"bash -c 'echo  {token} > ${tokenFile}'")
        node.systemctl("start k0sworker")
        node.wait_for_unit("k0sworker")
        node.wait_for_file("/run/k0s/status.sock")
        node.succeed("${k0s}/bin/k0s status")
    '';
}
