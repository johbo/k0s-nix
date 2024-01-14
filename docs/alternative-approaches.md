# Alternative approaches


## Tweak NixOS towards the expectations of `k0sctl`

Rough idea:

- [ ] During activation, copy symlinks into `/etc/systemd/system` so that it
  becomes a regular directory.
- [ ] During activation copy `multi-user.target.wants` so that it becomes a
  regular directory
- [ ] Check if the same happens during boot (activation script is called) or if
      something has to be done there as well
- [ ] Check if `systemd enable` works
- [ ] Test if `k0sctl` works now


This approach might be interesting if one wants to use the `k0sctl` based
workflow and manage `k0s` outside of the NixOS configuration.
