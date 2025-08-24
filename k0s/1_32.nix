{
  version = "1.32.8+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.8+k0s.0/k0s-v1.32.8+k0s.0-arm";
      hash = "sha256-wfUoHMMP2Cbbqjld8uSBMzT10M17VqABiB2oMUGMq0g=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.8+k0s.0/k0s-v1.32.8+k0s.0-arm64";
      hash = "sha256-/TCqJQrltQd+vDEih2GNIFXfMdl4QSweYRGB3pBEigQ=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.8+k0s.0/k0s-v1.32.8+k0s.0-amd64";
      hash = "sha256-7MqOBMlm9x1BVD+OlWh2jXPNiGuXw5EbbSsgWqZFLDg=";
    };
  };
}
