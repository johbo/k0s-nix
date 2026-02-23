{
  version = "1.33.8+k0s.1";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.8+k0s.1/k0s-v1.33.8+k0s.1-arm";
      hash = "sha256-alSFWkahfPK5Qs1QoptVQwNPihPxEnibgN/rp6incq0=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.8+k0s.1/k0s-v1.33.8+k0s.1-arm64";
      hash = "sha256-VOej+5gxHjwc+nfRpkzTH1s2BhkTNw6Y2gTmQwLbysk=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.8+k0s.1/k0s-v1.33.8+k0s.1-amd64";
      hash = "sha256-qQ+KJk6X14g2fbTcDz9eKi4H5KRJJetEQUT0lozjxNs=";
    };
  };
}
