# embedded-bins

A k0s release binary is `k0s.bare` with a payload of component binaries
carried behind it. Upstream builds each component in its own container
image, from the versions and build parameters in
`embedded-bins/Makefile.variables`. This directory reads those pins so a
payload can be built from source here.

Nothing in this directory is on a consumer's build path yet. It supplies
the component derivations that are being built up, reachable through the
checks until the payload decides their public surface.

## The payload mechanism differs by minor

There are two of them, and which one a minor uses decides how the
payload is assembled.

- **1.36** appends a zip. `hack/zip-files` writes it, `cat` puts it
  behind `k0s.bare`, and `pkg/assets/stage.go` opens the running
  executable with `zip.OpenReader`, matching an entry by the plain
  binary name. A zip's index sits at its end, so both formats stay
  readable. The Go build knows nothing about the payload, which is what
  makes `k0s.bare` reusable: a component can move into the archive
  without rebuilding k0s.
- **1.33 to 1.35** compile an index in. `hack/gen-bindata` gzips each
  staged binary into one `bindata_linux` blob and generates
  `pkg/assets/zz_generated_offsets_linux.go`, an offset and size table
  that is compiled into the binary before the blob is appended. So the
  Go build depends on the components, and moving one into the payload
  rebuilds k0s.

`EMBEDDED_BINS_BUILDMODE=none` covers both: at 1.36 the `cat` is
skipped, and below it the `noembedbins` build tag selects the empty
`pkg/assets/offsets_other.go` stub instead of the generated table.
Without that tag a payload-less build below 1.36 does not compile at
all.

## The source build

`../source.nix` builds `k0s.bare` itself, one derivation per minor,
against the k0s source each minor's JSON already pins under the name
`k0s`. It carries no payload: the components are being built up
separately, and nothing from nixpkgs is put on `PATH` to stand in for
the archive, because that would run a combination upstream never ships.
`checks/source-build.nix` is what proves it, diffing `k0s version
--json` against the pins the binary was stamped from.

It needs no codegen phase. The Makefile regenerates deepcopy functions,
CRDs and the clientset before every build, but only because the stamp
files it uses as targets are untracked - the generated sources
themselves are committed, and each generator runs through `go run
<tool>@<version>`, which wants the network.

**`CGO_ENABLED` is per minor, and it is not in `Makefile.variables`.**
The Makefile sets it on the `k0s` target itself: 1 at 1.33 and 1.34, 0
at 1.35 and 1.36. Below 1.35 `pkg/backup` reaches
`github.com/rqlite/rqlite/db` behind nothing but a `unix` build
constraint, and rqlite needs the real `mattn/go-sqlite3`, which without
cgo compiles to a stub carrying none of the methods it calls. 1.36
dropped rqlite altogether. This is the same trap as runc's libseccomp
`ARG` - a build parameter living outside the file the extractor reads -
except that this one is a per-target `make` variable rather than a
Dockerfile `ARG`, so the guards do not cover it.

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
