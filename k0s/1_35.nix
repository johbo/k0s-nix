{
  version = "1.35.7+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.7+k0s.0/k0s-v1.35.7+k0s.0-arm";
      hash = "sha256-7mQNiBwmi2gPXwMen390LZGB3/AphEkyI3hGXXZXNCM=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.7+k0s.0/k0s-v1.35.7+k0s.0-arm64";
      hash = "sha256-etbp8RPG432hQGzpxc1y6eKEOEOvvkdoEIweucxhi2Y=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.7+k0s.0/k0s-v1.35.7+k0s.0-amd64";
      hash = "sha256-RGW1phSwPpTmeyOedEiyndIabbtBWVe8zPiZtDFKmME=";
    };
  };
}
