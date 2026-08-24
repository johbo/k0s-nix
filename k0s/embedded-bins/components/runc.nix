{
  stdenv,
  fetchFromGitHub,
  fetchurl,
  libseccomp,
  runc,
  component,
  sources,
}:
let
  # k0s pins libseccomp in runc's Dockerfile rather than in
  # Makefile.variables, so it moves independently of the nixpkgs package and
  # has to be pinned here to be honoured at all.
  pinnedLibseccomp = libseccomp.overrideAttrs (_: {
    version = component.argpin_LIBSECCOMP_VERSION;
    src = fetchurl { inherit (sources.libseccomp) url hash; };
  });

  # Upstream's build_go_ldflags_extra carries static linking and nothing else,
  # for every Go component and every minor. It is deliberately not reproduced,
  # so anything else appearing there would be a pin this build drops without
  # saying so.
  staticLinking = "-extldflags=-static";
  ldflags =
    assert component.build_go_ldflags_extra == staticLinking;
    component.build_go_ldflags;
in
(runc.override { libseccomp = pinnedLibseccomp; }).overrideAttrs (_: {
  inherit (component) version;

  src = fetchFromGitHub {
    owner = "opencontainers";
    repo = "runc";
    tag = "v${component.version}";
    inherit (sources.runc) hash;
  };

  # nixpkgs interpolates makeFlags into its own build phase unquoted, which
  # would split EXTRA_LDFLAGS on its spaces. Passing the pins here keeps them
  # whole, and makes the pinned build tags the only ones in play rather than
  # leaving nixpkgs' BUILDTAGS+=seccomp beside them.
  buildPhase = ''
    runHook preBuild
    patchShebangs .
    make \
      BUILDTAGS="${component.build_go_tags}" \
      EXTRA_LDFLAGS="${ldflags}" \
      SHELL=${stdenv.shell} \
      runc man
    runHook postBuild
  '';

  # Upstream's runc carries no wrapper, and one that execs a store path would
  # defeat the point of vendoring it into the payload. k0s prepends its own
  # bin directory to the PATH of every process it supervises.
  installPhase = ''
    runHook preInstall
    install -Dm755 runc $out/bin/runc
    installManPage man/*/*.[1-9]
    runHook postInstall
  '';
})
