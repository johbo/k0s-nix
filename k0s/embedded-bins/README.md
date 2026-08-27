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

Two deliberate deviations from upstream, each asserted rather than left
to trust - the first while the component evaluates, the second by
`checks/embedded-bins-runc.nix`:

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

A third deviation carries no assertion, because the pins hold nothing it
could be checked against: the Go toolchain is nixpkgs' rather than the
`go_version` each minor pins. ADR-0019 decided that for every component
and minor, as nixpkgs' k3s does.

### containerd

The one component whose binary set is a pin of its own. k0s passes
`--build-arg CONTAINERD_BINS`, fed from a `containerd_bins` variable that
is not one of the `_build_*` suffixes `extract.py` reads, and the set
moves with the containerd major - four binaries at k0s 1.33, two at 1.36.
The component takes the `containerd`-prefixed names out of
`payloadBinaries`, which names the same set on every packaged minor, and
passes them as `COMMANDS`. That also suppresses the `COMMANDS +=` in
containerd's `Makefile.linux`, so `ctr` and `containerd-stress` stay out.

nixpkgs' `makeFlags` are replaced rather than added to, in a build phase
of the component's own. The list is composed with `rec`, so `VERSION` and
`REVISION` would keep naming 2.3.3 while 1.33 to 1.35 build 1.7.34; and
nixpkgs interpolates it unquoted, which would split the tags and the
linker flags into `make` targets. The tags go in as `GO_BUILDTAGS`
whatever the minor: both Makefiles derive `GO_TAGS` from it, so the pin's
own spelling - `apparmor selinux` at 1.36, `apparmor,selinux` below -
passes through verbatim.

`REVISION` is always passed, so the Makefile's `git rev-parse` never runs
in a sandbox with no repository to read. 1.36 pins one and the binary
reports it; below that nothing does. Upstream uses the pin to verify its
clone rather than to stamp, and here the fetch hash makes that assertion
instead.

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

### iptables

The only component with no Go pins at all. `Makefile.variables` carries a
version and a build image and nothing else, and upstream's static linking
- `--enable-static --disable-shared` with `LDFLAGS=-all-static` - is in
the Dockerfile's own `configure` call, which `extract.py` never reads. So
there is nothing for `go-ldflags.nix` to assert against here; the
deviation is the one ADR-0016 already decided, whose reasoning does not
turn on the component being written in Go.

k0s pins 1.8.11 below 1.36 and 1.8.13 at it. The override runs on every
minor rather than only where the versions differ, so one path is
exercised instead of two that drift apart as the pins move.

`payload.nix` takes whatever `bin/` holds and the nixpkgs package
installs some forty entries, so the component installs the two multi
binaries into an output of its own. k0s stages both - it errors if either
is missing - and makes the `iptables`, `iptables-save`,
`iptables-restore` and `ip6tables` symlinks itself once it has detected a
mode, so the payload carries no symlink.

Where upstream's static build compiles the extensions in, these dlopen
them out of the `lib` output at runtime. That is the sharpest case for
`payload-closure` above: without it the extensions are what a collection
takes first, and `checks/embedded-bins-iptables.nix` loads one to prove
the path resolves.

The Go toolchain is nixpkgs' rather than the `go_version` upstream pins,
which is not yet a considered decision.

### kubernetes

The last of the single node components, and the second whose binary set
is out of band: `kubernetes_bins` is a plain variable in
`embedded-bins/Makefile`, the same class as `containerd_bins`, so
ADR-0020 applies and the component filters the `kube`-prefixed names out
of `payloadBinaries` - `kubelet`, `kube-apiserver`, `kube-scheduler` and
`kube-controller-manager` on every packaged minor, with `keepalived` not
colliding. They go in as the `components` argument the nixpkgs package
already takes, which is also what sets `WHAT`.

nixpkgs' `installPhase` is replaced rather than extended, and `outputs`
drops to `out`. It symlinks `kubectl` in, substitutes `kube-addons`,
installs man pages and generates shell completions by *running*
`kubeadm` - which an overridden `components` no longer builds, so the
phase fails on a binary that is not there. `payload.nix` takes whatever
`bin/` holds, so the symlink would have staged a binary k0s never asks
for even if it had run.

**The version stamp does not transfer as an environment variable.** The
source is a GitHub archive, so the placeholders `git archive`
substitutes are already expanded in `hack/lib/version.sh`: it carries
the commit, `KUBE_GIT_TREE_STATE="archive"` and the tag literally, reads
them before it looks at the environment, and *overwrites* what it finds.
Upstream's `export KUBE_GIT_VERSION="v$VERSION+k0s"` only survives
because its Dockerfile clones with git, where the placeholders are
unexpanded and the block is skipped. `KUBE_GIT_VERSION_FILE` is the
mechanism that does transfer - `get_version_vars` sources it and returns
ahead of everything else - so the component writes one, taking the
commit back out of the source's own archive stamp and supplying the
major and minor the skipped semver parse would have derived. The `+k0s`
suffix is upstream's, and it is what a node reports as its kubelet
version.

Because that version is stamped rather than read, no binary can report a
source other than the pinned one, and the check cannot tell the two
apart - where etcd asserts the nixpkgs package's version and containerd
reads the daemon's own. So the component asserts instead that the tag in
the archive stamp is the version the pin names, which is what would catch
a pin moved without its `fetch` entry.

`SOURCE_DATE_EPOCH` is exported in the build phase rather than set on
the derivation. k8s renders `buildDate` from it, and
`set-source-date-epoch-to-latest.sh` raises the variable to the newest
mtime under `sourceRoot` *after* unpacking - a store path carries mtime
1, so a value set any earlier comes out a second late. The constant is
`source.nix`'s, so k0s and its payload agree on the date they were not
built on.

**`riscv64.patch` is not applied.** Upstream's Dockerfile applies it
unconditionally, and all it does is append `linux/riscv64` to the four
`KUBE_SUPPORTED_*_PLATFORMS` lists and teach `kube::util::host_arch` the
name. Neither is read by a `make WHAT=` build: `build_binaries` defaults
to the host platform and never consults those lists, which belong to the
release tooling. So the patch is unreachable on every platform k0s-nix
builds, and applying it would make this component depend on the k0s
source tarball to change nothing.

`checks/embedded-bins-kubernetes.nix` reads `--version=raw` out of each
binary, which renders the whole `version.Info` struct, so one call
carries every stamp the build is meant to have set. `GitVersion` and
`GitTreeState` are the two that say the version file was read at all:
without it the archive's own values win and report the plain version and
`archive`.

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

`update.py` carries one of its own, which the check cannot reach because
an update needs the network. `pins.nix` resolves a source by name and
takes the first match, so a name used twice hides an entry - and a
component with two `extra_urls` is what would produce one. The update
stops instead of writing data that reads as though it had one.

## Read before packaging a component

- Upstream's container build is not reproducible on its own terms - it
  installs toolchains from live distro repositories - and does not run in
  a Nix sandbox at all. What transfers is the specification: versions,
  tags, linker flags. Not the mechanics.
- `payloadBinaries` is upstream's own list and it moves: fifteen entries
  at 1.33, thirteen at 1.36.
- Not every `--build-arg` comes from the suffix scheme. `CONTAINERD_BINS`
  is fed from a plain `Makefile` variable, so the guards do not cover it.
- `extra_urls` carries what a component fetches besides its own source -
  libseccomp for runc, and an upstream patch for containerd at 1.34 and
  1.35 which 1.36 no longer needs.
- `kubernetes/` also carries a `riscv64.patch` in the k0s tree, which is
  applied by its Dockerfile rather than fetched.
