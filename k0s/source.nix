{
  lib,
  buildGoModule,
  callPackage,
  fetchzip,
  makeWrapper,
  runCommand,
  util-linuxMinimal,
}:
let
  pins = import ./embedded-bins/pins.nix { inherit lib; };
  components = callPackage ./embedded-bins/components { };
  mkPayload = callPackage ./embedded-bins/payload.nix { };

  # 1.36 moved the payload from an offset table generated into the binary to a
  # zip appended behind it.
  hasZipPayload = minor: lib.versionAtLeast (pins.read minor).k0sVersion "1.36";

  # Refreshed when a k0s pin moves: build the source-build check and take the
  # hash the failing fixed-output derivation reports.
  vendorHashes = {
    "1_33" = "sha256-t31v/A4EsaPph1QOd/0h3qTfL5poItP6k2ULLqCMEms=";
    "1_34" = "sha256-QdPO/qYxNSPEkJnB6VPmsmDPHSEd2Hql/ZdgMR1IzRo=";
    "1_35" = "sha256-AfAtrHoMdAbVoloNvj/785uy8Pa1PrlOCfEh2iEA8u4=";
    "1_36" = "sha256-+ZME6rqB0GU6cKCPB3KgxgHyUN5QnmcIW8UgLsER5G8=";
  };

  # Upstream sets this per target and per minor, in the Makefile rather than in
  # Makefile.variables, so extract.py does not see it. 1.33 and 1.34 need cgo
  # because pkg/backup reaches github.com/rqlite/rqlite/db behind nothing but a
  # `unix` build constraint, and rqlite needs the real mattn/go-sqlite3 - which
  # without cgo compiles to a stub carrying none of the methods it calls. 1.36
  # dropped rqlite altogether.
  cgoEnabled = {
    "1_33" = 1;
    "1_34" = 1;
    "1_35" = 0;
    "1_36" = 0;
  };

  # k0s has no clock, and upstream derives BUILD_DATE from the last commit date,
  # falling back to the wall clock when there is no git - which a fetched
  # tarball never has. A constant is what keeps the build reproducible; nixpkgs'
  # k3s stamps one for the same reason.
  buildDate = "1970-01-01T00:00:00Z";

  buildPkg = "github.com/k0sproject/k0s/pkg/build";
  componentBase = "k8s.io/component-base/version";

  buildK0s =
    minor:
    let
      pin = pins.read minor;
      component = pin.upstream.components;
      kubernetesVersion = component.kubernetes.version;

      # Below 1.36 a build without the generated table needs the noembedbins tag
      # to compile at all, and containerd's stamp still lives on the pre-v2
      # module path.
      zipPayload = hasZipPayload minor;
      containerdVersionPkg =
        if zipPayload then
          "github.com/containerd/containerd/v2/version"
        else
          "github.com/containerd/containerd/version";

    in
    buildGoModule {
      pname = "k0s";
      version = pin.k0sVersion;

      src = fetchzip { inherit (pins.fetch minor "k0s") url hash; };

      vendorHash = vendorHashes.${minor} or (throw "no vendorHash recorded for ${minor}");

      # No codegen phase. The Makefile regenerates deepcopy functions, CRDs and
      # the clientset before every build, because the stamp files it uses as
      # targets are not tracked - the generated sources themselves are. Each
      # generator runs through `go run <tool>@<version>`, which wants the
      # network, so go build is both sufficient here and the only option.
      subPackages = [ "." ];

      env.CGO_ENABLED = cgoEnabled.${minor} or (throw "no CGO_ENABLED recorded for ${minor}");

      tags = [ "osusergo" ] ++ lib.optional (!zipPayload) "noembedbins";

      # Upstream's -extldflags=-static is deliberately absent: inert where cgo
      # is off, and where it is on it is the same decision the component
      # derivations take, since nixpkgs ships no static libc to link against.
      ldflags = [
        "-w"
        "-s"
        "-X ${buildPkg}.Version=v${pin.k0sVersion}"
        "-X ${buildPkg}.RuncVersion=${component.runc.version}"
        "-X ${buildPkg}.ContainerdVersion=${component.containerd.version}"
        "-X ${buildPkg}.KubernetesVersion=${kubernetesVersion}"
        "-X ${buildPkg}.KineVersion=${component.kine.version}"
        "-X ${buildPkg}.EtcdVersion=${component.etcd.version}"
        "-X ${buildPkg}.KonnectivityVersion=${component.konnectivity.version}"
        "-X ${componentBase}.gitVersion=v${kubernetesVersion}"
        "-X ${componentBase}.gitMajor=${lib.versions.major kubernetesVersion}"
        "-X ${componentBase}.gitMinor=${lib.versions.minor kubernetesVersion}"
        "-X ${componentBase}.gitCommit=not_available"
        "-X ${componentBase}.buildDate=${buildDate}"
        "-X ${containerdVersionPkg}.Version=${component.containerd.version}"
      ]
      # Below 1.36 upstream reads this out of the staged containerd binary, and
      # only when it built a payload at all, so a payload-less build has nothing
      # to read and upstream's own leaves it empty too.
      ++ lib.optional zipPayload "-X ${containerdVersionPkg}.Revision=${component.containerd.revision}";

      # The suite wants a cluster, a container runtime and root for a good part
      # of itself. What this package has to get right is the binary's identity,
      # and checks/source-build.nix asserts that instead.
      doCheck = false;

      meta = {
        description = "k0s - The Zero Friction Kubernetes, built from source";
        homepage = "https://k0sproject.io";
        license = lib.licenses.asl20;
        mainProgram = "k0s";
        platforms = lib.platforms.linux;
      };
    };

  # k0s reads its payload out of its own executable, which a wrapper is not:
  # os.Executable() resolves to whatever the wrapper execs. So the real binary
  # sits at libexec/k0s, where a payload can be appended to it, and bin/k0s is
  # the wrapper.
  #
  # util-linux is a host tool k0s expects to find rather than something it
  # carries. No payload component is put on PATH to stand in for the archive,
  # because staging one out of nixpkgs would run a combination nobody ships.
  #
  # The payload is attached here rather than in the Go build because fixupPhase
  # strips $out/bin and shrinks its RPATHs, and both rewrite the ELF - which
  # would discard whatever sits behind it.
  assemble =
    payload: k0s:
    runCommand k0s.name
      {
        nativeBuildInputs = [ makeWrapper ];
        inherit (k0s) meta;
      }
      ''
        install -Dm755 ${k0s}/bin/k0s $out/libexec/k0s
        ${lib.optionalString (payload != null) "cat ${payload} >>$out/libexec/k0s"}
        makeWrapper $out/libexec/k0s $out/bin/k0s \
          --prefix PATH : ${lib.makeBinPath [ util-linuxMinimal ]}
      '';

  payloadFor = minor: mkPayload (pins.read minor).k0sVersion (lib.attrValues components.${minor});
in
{
  bare = lib.genAttrs pins.minors (minor: assemble null (buildK0s minor));

  # Below 1.36 the payload is an input to the Go build rather than something
  # appended to the finished binary, so those minors are not carried yet.
  withPayload = lib.genAttrs (lib.filter hasZipPayload pins.minors) (
    minor: assemble (payloadFor minor) (buildK0s minor)
  );
}
