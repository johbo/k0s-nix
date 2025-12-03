{
  version = "1.32.10+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.10+k0s.0/k0s-v1.32.10+k0s.0-arm";
      hash = "sha256-2QoOVvw1sbIf6rE33udUMnlBIMrxWN8aILKNVSiC+k0=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.10+k0s.0/k0s-v1.32.10+k0s.0-arm64";
      hash = "sha256-hJtqzaZ1Lb31FQoviq78p5+ikGQBCV3bW9E0yriuNU0=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.10+k0s.0/k0s-v1.32.10+k0s.0-amd64";
      hash = "sha256-Y9AKk1oH2gygfjWQc/k6G0d02ZpGkMqG8p6YRja3dWM=";
    };
  };
}
