{
  description = "k0s - The Zero Friction Kubernetes for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

  outputs = { self, nixpkgs }: {

    nixosModules = {
      k0s = import ./k0s-module.nix;
    };

  };
}
