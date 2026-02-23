{
  version = "1.32.12+k0s.1";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.12+k0s.1/k0s-v1.32.12+k0s.1-arm";
      hash = "sha256-F9fXEzBs6EPrn8CmY9eFSKZk+cQsGKwOCYRmexmSAJ8=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.12+k0s.1/k0s-v1.32.12+k0s.1-arm64";
      hash = "sha256-SEFq9ze5ha/TqAA9gfpmfDKQJfeanDqYvpgcKdvuaYU=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.12+k0s.1/k0s-v1.32.12+k0s.1-amd64";
      hash = "sha256-HPleLjGUlpOQUWzzuUa2Mxsz4t7PSGUNcSGU6JRQQEU=";
    };
  };
}
