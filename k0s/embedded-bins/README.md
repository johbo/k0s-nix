# embedded-bins

A k0s release binary is `k0s.bare` with a zip of thirteen component
binaries appended to it. Upstream builds each component in its own
container image, from the versions and build parameters in
`embedded-bins/Makefile.variables`. This directory reads those pins so a
payload can be built from source here.

Nothing in this directory is on a consumer's build path yet. It supplies
the component derivations that are being built up, reachable through the
checks until the payload decides their public surface.

## The component derivations

`components/` holds one derivation per payload binary, keyed by minor:
`components/default.nix` turns a minor's JSON into the arguments each
component takes, so a component file knows the pins it needs and nothing
about the file they came from. `pins.nix` is the reader both it and
`checks/embedded-bins.nix` use.

A component overrides the nixpkgs package rather than reproducing
upstream's Dockerfile. nixpkgs already carries the build knowledge - its
`runc` sets `BUILDTAGS+=seccomp` and takes `libseccomp` as an argument -
so what the override adds is k0s's version, its linker flags and its
libseccomp pin.

Two deliberate deviations from upstream, both asserted by
`checks/embedded-bins-runc.nix` rather than left to trust:

- **Dynamic linking.** `build_go_ldflags_extra` is `-extldflags=-static`
  for every Go component and every minor, and it is not reproduced.
  nixpkgs ships no static `libc`, `libseccomp` or `libresolv`, and the
  payload is extracted onto a node whose store already holds what the
  binary links against. A component asserts that the field holds nothing
  but the static flag, so a pin this would otherwise drop stops the
  build.
- **No wrapper.** nixpkgs wraps `runc` to prepend
  `/run/current-system/systemd/bin` to `PATH`. A payload binary that
  execs a store path defeats the point of vendoring it, and k0s prepends
  its own bin directory to the `PATH` of what it supervises.

The Go toolchain is nixpkgs' rather than the `go_version` upstream pins,
which is not yet a considered decision.

## The generated files

`1_33.json` through `1_36.json` are generated. Regenerate rather than
edit them:

```
./update.py          # every minor
./update.py 1_36     # one of them
```

Each holds three things:

- `k0sVersion`, which has to agree with `k0s/<minor>.nix`.
- `upstream`, exactly what `extract.py` read out of the k0s source. Keys
  mirror upstream's own flat variable namespace, so an entry reads
  against `Makefile.variables` directly.
- `fetch`, the URLs and hashes `update.py` prefetched. A source whose URL
  has not moved keeps the hash already recorded, so a run that changes
  nothing costs no downloads.

The split is what lets `checks/embedded-bins.nix` verify the first part
offline: it re-runs `extract.py` against the pinned source and diffs.
Hashes cannot be checked that way, which is why they sit apart.

## Separate from k0s/update-script.bash

That script tracks the published release binaries. This one tracks the
sources they were built from. The two packages stand as alternatives
while the source build is being built up, so their update paths are kept
apart; the version agreement between them is asserted rather than
assumed.

## The guards

`extract.py` knows the component set, the build parameter suffixes, the
shared build arguments, the Dockerfile `ARG` defaults and the source
hosts. Anything upstream adds to one of those sets stops the run instead
of being silently dropped. `runc`'s Dockerfile carries
`ARG LIBSECCOMP_VERSION`, a pin `Makefile.variables` does not mention at
all, which is the case that motivates them.

The guards are exercised by the check rather than trusted: it mutates a
copy of the source three ways and asserts each one is refused.

## Read before packaging a component

- Upstream's container build is not reproducible on its own terms - it
  installs toolchains from live distro repositories - and does not run in
  a Nix sandbox at all. What transfers is the specification: versions,
  tags, linker flags. Not the mechanics.
- `payloadBinaries` is upstream's own list and it moves: fifteen entries
  at 1.33, thirteen at 1.36.
- `extra_urls` carries what a component fetches besides its own source -
  libseccomp for runc, and an upstream patch for containerd at 1.34 and
  1.35 which 1.36 no longer needs.
- `kubernetes/` also carries a `riscv64.patch` in the k0s tree, which is
  applied by its Dockerfile rather than fetched.
