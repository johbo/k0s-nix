{ lib, pkgs }:
let
  pins = import ../k0s/embedded-bins/pins.nix { inherit lib; };
  components = pkgs.callPackage ../k0s/embedded-bins/components { };
  sourceBuilds = pkgs.callPackage ../k0s/source.nix { };

  manifest = lib.mapAttrsToList (minor: k0s: {
    inherit minor k0s;
    runc = components.${minor}.runc;
    k0sVersion = (pins.read minor).k0sVersion;
  }) sourceBuilds.withPayload;

  # zipfile locates the archive by its central directory, the way
  # pkg/assets/stage.go's zip.OpenReader does, so a k0s binary with a zip behind
  # it reads here exactly as it does at runtime.
  readPayload = pkgs.writeText "read-k0s-payload.py" ''
    import sys
    import zipfile

    binary, expected = sys.argv[1:]

    with zipfile.ZipFile(binary) as payload:
        names = payload.namelist()
        if names != ["runc"]:
            sys.exit(f"the payload holds {names}, expected ['runc']")
        staged = payload.read("runc")

    with open(expected, "rb") as component:
        if staged != component.read():
            sys.exit("the staged runc is not the component that was built")

    print(f"payload: runc, {len(staged)} bytes")
  '';
in
pkgs.runCommand "k0s-embedded-bins-payload"
  {
    nativeBuildInputs = [
      pkgs.jq
      pkgs.python3
    ];
    passAsFile = [ "manifest" ];
    manifest = builtins.toJSON manifest;
  }
  ''
    set -o pipefail
    failed=

    while read -r entry; do
      eval "$(jq -r '@sh "minor=\(.minor) k0s=\(.k0s) runc=\(.runc) k0sVersion=\(.k0sVersion)"' <<<"$entry")"

      # Appending a zip behind an ELF either works or leaves an executable that
      # no longer runs, so the binary is asked first.
      reported=$("$k0s"/bin/k0s version)
      echo "$minor: $reported"
      if [ "$reported" != "v$k0sVersion" ]; then
        echo "$minor: expected v$k0sVersion" >&2
        failed=1
      fi

      # k0s reads the payload out of the executable it is running, so the file
      # the wrapper execs has to be the one carrying it.
      if ! grep -qF "$k0s/libexec/k0s" "$k0s/bin/k0s"; then
        echo "$minor: the wrapper does not exec the binary carrying the payload" >&2
        failed=1
      fi

      if ! python3 ${readPayload} "$k0s/libexec/k0s" "$runc/bin/runc"; then
        echo "$minor: the payload does not read back as runc" >&2
        failed=1
      fi
    done < <(jq -c '.[]' "$manifestPath")

    [ -z "$failed" ] || exit 1
    touch $out
  ''
