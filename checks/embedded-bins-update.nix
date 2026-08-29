{ pkgs, ... }:
pkgs.runCommand "k0s-embedded-bins-update-tests"
  {
    preferLocalBuild = true;
    nativeBuildInputs = [ pkgs.python3 ];
  }
  ''
    cd ${../k0s/embedded-bins}
    python3 -m unittest discover --pattern 'test_*.py' --verbose
    touch $out
  ''
