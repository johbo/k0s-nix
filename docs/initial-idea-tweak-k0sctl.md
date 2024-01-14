
# Dropped Idea - Adjust `k0sctl` and `k0s`

The original idea was to adjust `k0sctl` so that it knows more about NixOS. This
did turn out to be a rabbit hole.

See the related discussions on Github:
- <https://github.com/k0sproject/k0s/issues/1318>
- <https://github.com/NixOS/nixpkgs/issues/247158>

The notes from the investigation are included below and give a fairly good
overview of the insights which I got.


## Usage scenarios on NixOS

I see two valid use cases how to use `k0s` on NixOS:


### The NixOS way as a "NixOS service"

The this use case we would leave the management of `k0s` to NixOS and its
install and update process via `nixos-rebuild switch`.

As a user if I want to use `k0s` this way I would enable a configuration option
like `services.k0s.enable` and set a few more `k0s` related configuration
options.

In this use case `k0s` is managed together with the operation system.

This use case is NOT in scope of this issue and should be considered as a
separate topic if one wants to implement this. This use case would have to be
implemented on the side of NixOS within the Nixpkgs package collection.


### The `k0sctl` way

The use case of this issue is about managing `k0s` with `k0sctl` separately from
managing the operating system. The main intention of this case is to keep the
concerns of "providing the base operating system" and "managing the kubernetes
cluster" separate from each other.

In this use case I see the split of concerns as follows:

-   NixOS provides the base operation system for the machines. As a user I can
    configure it to my needs and preference and use its built-in features to have
    exactly the system which I want to have.

-   `k0sctl` provides the handling of `k0s` in a very dynamic way, where I can use
    a bunch of existing nodes and roll `k0s` into them based on the single
    configuration file of `k0sctl`.

In this approach I can consider to replace the base operation system without
having to worry about `k0sctl`. This is why I consider this case to have both
concerns separated.


### Conclusion

As mentioned above, I consider both cases equally valid. The choice has to be
made by the user based on her specific context and needs.

This issue focuses only on this use case.


## Solution and implementation ideas

I have the following early ideas about how to approach this:


### Detect NixOS as OS in `k0sctl`

`k0sctl` has the concept of detecting the OS and then adjusting how it manages
`k0s` based on this.

As a first steps this would mean adding support to add an new OS type `"nixos"`
which is detected by `k0sctl`.


### NixOS specific behavior

1.  Option: Skip the install step

    The simplest option is to skip the install step and leave this aspect to the
    user.

    This means the user has to ensure that the following things are handled:

    -   The `systemd` unit has to be prepared. This changes depending on the role
        which the node has, e.g. `worker`, `controller` or `controller+worker`.

    -   Needed users on the system. I assume those are only needed on `controller` nodes.

    Instead of the install step, `k0sctl` could verify if the pre-conditions are met
    and error out if not.

2.  Option: Provide custom parameters to `k0s`

    During the call to `k0s install` adjusted parameters would be passed so that the
    install does not fail on a NixOS system. These parameters would have to be added
    to `k0s install` most likely.

    One option would be to allow to skip the creation of the `systemd` unit. This is
    nearly the same as the option to skip the install step entirely. If the user has
    to prepare the `systemd` unit, then I think that the user can also manage to
    have the needed user accounts prepared. That's why I think this option is not a
    good one.

    Another option which I see is to allow to specify the directory where `k0s
    install` shall place the `systemd` unit files. This would go together with a
    NixOS configuration which allows to configure additional directories for
    `systemd` units. This approach would make the management via `k0sctl` fully
    functional and meet all needs of this use case.


## Proposal

My current proposal is to go with the following:

1.  Add support to detect NixOS into `k0sctl`, use the string `"nixos"`.

2.  Add a parameter `--systemd-unit-path` to `k0s` so that the `systemd` units
    can be installed into a user specified directory.

3.  Add a configuration option to specify the desired `systemd` unit path into
    the `k0sctl` configuration file.


# Test implementation - Stopped

Stopped because the needed adjustments in `k0sctl`, `k0s` and `service` are too
much work at the moment.

Going the NixOS way to reach the status "working" faster.


## Plan

-   [X] clone `k0s` and `k0sctl`
-   [X] build `k0s`
    -   thanks to docker usage the `make` just works
-   [X] add parameter into `k0s`
    -   did hardcode the changed path into the `service` library for the test
-   [X] tweak the service library if needed
    -   <https://github.com/kardianos/service/blob/master/service_systemd_linux.go#L74>
    -   Fork: <https://github.com/johbo/fork-kardianos-service/tree/test-nixos>
-   [X] build everything
-   [ ] find out how to use the custom `k0s` in the `k0sctl` calls
-   [ ] add mutable systemd unit path into NixOS configuration
-   [ ] deploy nodes
-   [ ] test run with the customized tooling
-   [ ] Using the parameter `installFlags` in the `k0sctl` configuration file
    could be an alternative
-   [ ] create the issue based on the insights


## Repos

-   <https://github.com/kardianos/service> also cloned, it has the hardcoded path


## build on NixOS `linux/amd64`

    nix profile install nixpkgs#go

    go mod edit -replace=github.com/kardianos/service@v1.2.2=github.com/johbo/fork-kardianos-service@test-nixos

    go mod tidy

    go build


## Test run on NixOS

Found that the approach works except for one aspect: The
`multi-user.target.wants` symlink would have to be created manually in
`/etc/systemd-mutable/system` instead of in `/etc/systemd/system`.

This means the call to `systemctl enable k0scontroller` from the `service`
library would have to be replaced with manually creating the symlink.


## Conclusion

To make it work the `services` library would have to be changed:

-   Allow to use a different path to store the unit files
-   Create the symlink for the target wants instead of using `systemctl enable`

With this adjusted the changes in `k0s` and also in `k0sctl` could be made:

-   `k0sctl` recognize NixOS
-   `k0sctl` systemd path configurable
-   `k0sctl` to put a special parameter to `k0s` calls regarding the systemd unit
    path location

This is basically a lot of complication to make it work for a special case.
