{
  lib,
  fetchurl,
  fetchzip,
  containerd,
  component,
  payloadBinaries,
  sources,
}:
let
  # k0s selects the binaries with --build-arg CONTAINERD_BINS, fed from a
  # containerd_bins variable that is not one of the _build_* suffixes
  # extract.py reads. payloadBinaries is upstream's own staging list and names
  # the same set on every packaged minor, so the selection is read from there
  # rather than kept as a second table.
  commands = lib.filter (lib.hasPrefix "containerd") payloadBinaries;

  # Passing COMMANDS on the command line also suppresses the `COMMANDS +=` in
  # containerd's Makefile.linux, so `make install` places exactly these and the
  # ctr and containerd-stress the package otherwise ships stay out.
  selected =
    if commands != [ ] then
      commands
    else
      throw "no containerd binary in payloadBinaries: ${toString payloadBinaries}";

  # Not makeFlags: nixpkgs interpolates that list into its build phase
  # unquoted, and both the tags and the linker flags carry spaces - which make
  # would read as targets of their own.
  #
  # The pins replace nixpkgs' own values rather than adding to them, because
  # its list is composed with rec: VERSION and REVISION would keep naming the
  # packaged release while the source here is a different one. The tags are the
  # pin's alone for the same reason, so nixpkgs' no_btrfs is left out.
  #
  # Both Makefile dialects read GO_BUILDTAGS: 1.36's Dockerfile passes it
  # directly and the older three pass the GO_TAGS it composes, and a value
  # given here suppresses the `+= urfave_cli_no_docs` in either.
  #
  # REVISION is passed even where the pin has none, so `git rev-parse` never
  # runs in a sandbox that has no repository to read. 1.36 pins one and the
  # binary reports it; below that nothing does, which the check asserts.
  makeArgs = lib.escapeShellArgs [
    "PREFIX=${placeholder "out"}"
    "VERSION=v${component.version}"
    "REVISION=${component.revision or ""}"
    "GO_BUILDTAGS=${component.build_go_tags}"
    "SHIM_CGO_ENABLED=${component.build_shim_go_cgo_enabled}"
    "EXTRA_LDFLAGS=${import ./go-ldflags.nix component}"
    "COMMANDS=${toString selected}"
  ];
in
(containerd.override { withMan = false; }).overrideAttrs (_: {
  inherit (component) version;

  src = fetchzip { inherit (sources.containerd) url hash; };

  # 1.34 and 1.35 carry an upstream commit that 1.33, on the same containerd
  # version, does not.
  patches = lib.optional (sources ? patch) (fetchurl { inherit (sources.patch) url hash; });

  # 1.7 has no install-doc target, and a payload component wants bin/ alone.
  outputs = [ "out" ];

  buildPhase = ''
    runHook preBuild
    make ${makeArgs} binaries
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    make ${makeArgs} install
    runHook postInstall
  '';
})
