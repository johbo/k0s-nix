{
  lib,
  stdenv,
  pkgs,
  buildPackages,
  fetchurl,
  installShellFiles,
  testers,
}:
let
  releases = {
    k0s_1_27 = import ./1_27.nix;
    k0s_1_28 = import ./1_28.nix;
    k0s_1_30 = import ./1_30.nix;
    k0s_1_31 = import ./1_31.nix;
    k0s_1_32 = import ./1_32.nix;
  };
in
builtins.mapAttrs (
  name: release:
  stdenv.mkDerivation rec {
    pname = "k0s";
    inherit (release) version;

    src = fetchurl {
      inherit
        (release.srcs."${stdenv.hostPlatform.system}"
          or (throw "Missing source for host system: ${stdenv.hostPlatform.system}")
        )
        url
        hash
        ;
    };

    nativeBuildInputs = [ installShellFiles ];

    phases = [ "installPhase" ];

    installPhase =
      let
        k0s =
          if stdenv.buildPlatform.canExecute stdenv.hostPlatform then
            placeholder "out"
          else
            buildPackages."${name}";
      in
      ''
        install -m 755 -D -- "$src" "$out"/bin/k0s

        # Generate shell completions
        installShellCompletion --cmd k0s \
          --bash <(${k0s}/bin/k0s completion bash) \
          --fish <(${k0s}/bin/k0s completion fish) \
          --zsh <(${k0s}/bin/k0s completion zsh)
      '';

    passthru.tests.version = testers.testVersion {
      package = pkgs."${name}";
      command = "k0s version";
      version = "v${version}";
    };

    passthru.updateScript = ./update-script.bash;

    meta = with lib; {
      description = "k0s - The Zero Friction Kubernetes";
      homepage = "https://k0sproject.io";
      license = licenses.asl20;
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      mainProgram = pname;
      maintainers = with maintainers; [ twz123 ];
      platforms = builtins.attrNames release.srcs;
    };
  }
) releases
