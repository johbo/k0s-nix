{
  version = "1.30.14+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.30.14+k0s.0/k0s-v1.30.14+k0s.0-arm";
      hash = "sha256-aXbPxmAdxgxNtRLb9SGPe1haLcj6ztf7tuauU7PdG50=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.30.14+k0s.0/k0s-v1.30.14+k0s.0-arm64";
      hash = "sha256-xmiPq/gd+nF42bLsxnkB9QyLL2ejZ+GZMnhsyarMu+0=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.30.14+k0s.0/k0s-v1.30.14+k0s.0-amd64";
      hash = "sha256-TF1LtBVZPeLb2YCXyAcX3rkzgS5FbIM1hS4HAaJuK5w=";
    };
  };
}
