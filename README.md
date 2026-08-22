# k0s-nix has moved

The project now lives in the nix-community organization:
<https://github.com/nix-community/k0s-nix>.

Change your flake input to:

```nix
inputs.k0s-nix.url = "github:nix-community/k0s-nix";
```

## What this branch is

The transfer left no redirect, so a flake input still naming
`github:johbo/k0s-nix` resolves this personal fork rather than the
project. This branch is the default branch so that such an input says
so instead of quietly returning code that is nobody's to maintain.

The `main` branch here carries the project as it stood at the move,
and keeps working, with a warning. A pin naming a revision is
unaffected. Nothing is removed from this repository, so no existing
pin is broken by it.
