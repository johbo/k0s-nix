{
  version = "1.27.16+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.27.16+k0s.0/k0s-v1.27.16+k0s.0-arm";
      hash = "sha256-SXE26mAyQn7+A5v3x3Eyd3CSb7GJ+KMplCYuhh8mLLk=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.27.16+k0s.0/k0s-v1.27.16+k0s.0-arm64";
      hash = "sha256-oELj8TU9iGHHDXRTYCaLhwf7CRLg5kyhLwfaIu03X3Y=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.27.16+k0s.0/k0s-v1.27.16+k0s.0-amd64";
      hash = "sha256-Xi3Gcn+DxmEnwWTCzvs4PVAJJToKCYOd2KfZ8/7r8Ts=";
    };
  };
}
