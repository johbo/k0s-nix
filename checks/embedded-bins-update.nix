{ pkgs, ... }:
pkgs.runCommand "k0s-embedded-bins-update-tests"
  {
    preferLocalBuild = true;
    nativeBuildInputs = [ (pkgs.python3.withPackages (ps: [ ps.pytest ])) ];
  }
  ''
    cd ${../k0s/embedded-bins}
    pytest --verbose -p no:cacheprovider
    touch $out
  ''
