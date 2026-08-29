# embedded-bins

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

## The vendorHash tables

Two hashes cannot be prefetched, only read back from a build made to
fail on them: k0s's in `../source.nix` and kine's in
`components/kine.nix`. `update.py` carries both, so the run that
regenerates the JSON leaves them in step too.

Each is keyed by the version its hash belongs to, so a moved pin reads
as a missing entry and one no minor names any more is dropped. Where
nothing is missing nothing is built.

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

`update.py` carries one of its own. `pins.nix` resolves a source by name
and takes the first match, so a name used twice hides an entry - and a
component with two `extra_urls` is what would produce one. The update
stops instead of writing data that reads as though it had one.

What needs no network is tested directly: `test_update.py` and
`test_vendor_hashes.py` run under `checks/embedded-bins-update.nix`.

