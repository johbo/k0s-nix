{
  description = "k0s - The Zero Friction Kubernetes for NixOS";

  outputs = { self, nixpkgs }: {

    nixosModules = {
      k0s = import ./k0s-module.nix;
    };

  };
}
