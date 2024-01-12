# k0s-nix Flake

This repository contains a Nix Flake which provides the necessary utilities to
use `k0s` inside of a NixOS system.


## Status - EXPERIMENTAL

The implementation is in its early phase. It is possible to use and make work
(with a few manual twists) for early inspection.


## Contributions

Both contributions and forks are welcome, also if this should ever reach a state
which could be integrated upstream into Nixpkgs then I would happy archive this
Flake for it.


## Usage

### Build the test system configuration

```sh
nix build .#nixosConfigurations.test.config.system.build.toplevel
```

Inspect the result in `./result`.


## Credit

- The `k0s` package definition tool the work from this PR as input:
  <https://github.com/NixOS/nixpkgs/pull/258846>


## Contact

- <johannes@bornhold.name>


## Pointers

### Projects and Documentation

- [k0s](https://k0sproject.io/)
- [NixOS](https://nixos.org/)
- [Nix Flakes - Wiki](https://nixos.wiki/wiki/Flakes)
- [Nix Flakes - Reference documentation](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#flake-references)

### Other attempts to bring `k0s` to NixOS

- Packaging request in NixOS - https://github.com/NixOS/nixpkgs/issues/247158
- Pull Request to add the binary `k0s` into Nixpkgs -
  https://github.com/NixOS/nixpkgs/pull/258846
- Systemd unit handling related PR in `k0s` -
  https://github.com/k0sproject/k0s/issues/1318
