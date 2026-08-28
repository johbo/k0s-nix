{
  lib,
  buildGoModule,
  fetchzip,
  component,
  sources,
}:
let
  inherit (component) version;
in
# -a rebuilds packages that are already built, which buys nothing in a sandbox
# that has built none. Dropping it holds only while it is all the pin carries.
assert component.build_go_flags == "-a";
# Upstream stamps no version and the server has no version flag, so nothing can
# be read back out of the binary. The tarball's own name is what ties a minor to
# the version it records, and this is the only place that can say so.
assert lib.hasSuffix "/v${version}.tar.gz" sources.konnectivity.url;
buildGoModule {
  pname = "konnectivity-server";
  inherit version;

  src = fetchzip { inherit (sources.konnectivity) url hash; };

  # The tarball carries vendor/, so there is no module fetch and no hash to
  # record per version - the one thing every other Go component here owes.
  vendorHash = null;

  # Upstream's Dockerfile runs `make gen` first, which is protoc and mockgen
  # installed over the network. Both write into paths the source already
  # carries - the .pb.go files and proto/agent/mocks - so the build reads them
  # out of the tarball instead and the generators never run.
  subPackages = [ "cmd/server" ];

  env.CGO_ENABLED = component.build_go_cgo_enabled;

  ldflags = lib.splitString " " (import ./go-ldflags.nix component);

  # The suite is not what upstream's Dockerfile builds, and cmd/server is the
  # only package installed.
  doCheck = false;

  # The Dockerfile builds bin/proxy-server and renames it on the way into the
  # image. The payload entry has to be the name k0s stages.
  postInstall = ''
    mv $out/bin/server $out/bin/konnectivity-server
  '';

  meta = {
    description = "Konnectivity server, the API server network proxy";
    homepage = "https://github.com/kubernetes-sigs/apiserver-network-proxy";
    license = lib.licenses.asl20;
    mainProgram = "konnectivity-server";
    platforms = lib.platforms.linux;
  };
}
