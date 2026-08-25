# embedded-bins

A k0s release binary is the k0s executable with a payload of component
binaries carried behind it. Upstream builds each component in its own
container image, from the versions and build parameters in
`embedded-bins/Makefile.variables`. This directory reads those pins so a
payload can be built from source here.

Nothing in this directory is on a consumer's build path yet. It supplies
the component derivations that are being built up, and the payload they
are assembled into, reachable through the checks until that payload
decides their public surface.

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

`../source.nix` builds k0s itself, one derivation per minor, against the
k0s source each minor's JSON already pins under the name `k0s`. It
offers two sets: `bare` carries no payload, and `withPayload` carries
whatever `components/` has for that minor. `checks/source-build.nix`
proves the first, diffing `k0s version --json` against the pins the
binary was stamped from; `checks/embedded-bins-payload.nix` proves the
second, below. Nothing from nixpkgs is put on `PATH` to stand in for a
component the payload does not carry yet, because that would run a
combination upstream never ships.

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

## How the payload is attached

The two mechanisms above are two assembly paths, and `../source.nix`
carries both.

At **1.36** the components are zipped by `payload.nix` and the archive
is appended to the finished binary. The Go build takes no argument from
it, so it is the same derivation `bare` builds and a component moving
into the payload does not rebuild k0s.

**Below 1.36** the components are staged into
`embedded-bins/staging/linux/bin` in `preBuild` and `hack/gen-bindata`
is run over them, exactly as the Makefile does. It writes both halves of
the payload at once: the blob, and the offset table that locates entries
in it. The table is compiled in, so `noembedbins` comes off and the
build depends on the components; the blob leaves through a second
output, `bindata`.

Appending is a step of its own in both cases rather than part of the Go
build, because `fixupPhase` strips `$out/bin` and shrinks its RPATHs -
each of which rewrites the ELF and would discard whatever sits behind
it. That step also wraps the binary, and the order matters: `k0s` reads
the payload out of the executable it is running, and a wrapper is not
that executable. The real binary is `libexec/k0s`, which is what carries
the payload, and `bin/k0s` is the wrapper that execs it.

The components are named again in `$out/nix-support/payload-closure`,
which is what makes them references of the package. Compressed into the
payload, a store path is not a string the reference scanner can find, so
without that file a collection takes the libraries the staged binaries
were linked against and leaves the payload unrunnable - the very thing
dynamic linking assumes will not happen. References are transitive, so
naming the component is enough to hold its own closure with it.

`checks/embedded-bins-payload.nix` reads the payload back the way the
minor's runtime does - through `zipfile`, which finds a prefixed archive
by its central directory as `zip.OpenReader` does, or from the tail of
the binary where `stage.go` seeks - and compares it against the
component that was built. Below 1.36 it also greps the binary for an
entry name, because a build that kept `noembedbins` carries an empty
table and would fall back to `PATH` without saying so.

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
  wherever it is set at all, and it is not reproduced. nixpkgs ships no
  static `libc`, `libseccomp` or `libresolv`, and the payload is
  extracted onto a node whose store already holds what the binary links
  against. `components/go-ldflags.nix` asserts that the field is absent
  or holds nothing but the static flag, so a pin this would otherwise
  drop stops the build. etcd is the component that leaves it unset.
- **No wrapper.** nixpkgs wraps `runc` to prepend
  `/run/current-system/systemd/bin` to `PATH`. A payload binary that
  execs a store path defeats the point of vendoring it, and k0s prepends
  its own bin directory to the `PATH` of what it supervises.

### etcd

nixpkgs keeps a package per etcd minor series, and both k0s pins land on
one: 3.5.33 at k0s 1.33, 3.6.14 above it. `components/etcd.nix` selects
on the pinned series rather than on the k0s minor, and asserts that the
package it picked carries the pinned version - a nixpkgs bump has to fail
there rather than on a vendor hash built for another version.

Only the server is a payload binary. nixpkgs joins it with `etcdctl` and
`etcdutl`, each a derivation of its own, and the component takes
`deps.etcdserver`, whose `bin/` holds `etcd` alone. `payload.nix` takes
whatever `bin/` holds, so the join reaching the payload would stage two
binaries k0s never asks for; `checks/embedded-bins-etcd.nix` asserts it
does not.

The binary reports `Git SHA: GitNotFound`. Upstream's Dockerfile clones
the repository and stamps the short SHA, but the source here is a tarball
with no repository in it - git in the sandbox would find nothing to read,
and cloning wants a network it does not have. nixpkgs stamps upstream's
own no-git fallback deliberately, and the check asserts it so it stays a
decision rather than a surprise.

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
