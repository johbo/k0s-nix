{
  description = "k0s-nix has moved to github:nix-community/k0s-nix";

  outputs =
    { ... }:
    throw ''
      k0s-nix has moved to the nix-community organization.

      This input still points at github:johbo/k0s-nix, which is a
      personal fork and does not carry the project. Change it to:

        inputs.k0s-nix.url = "github:nix-community/k0s-nix";
    '';
}
