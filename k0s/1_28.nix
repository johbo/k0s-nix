{
  version = "1.28.4+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.28.4+k0s.0/k0s-v1.28.4+k0s.0-arm";
      hash = "sha256-vAJ7jWQtQz/gVSey91cUtsGyqqFxjimmZKsUFVbMcl0=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.28.4+k0s.0/k0s-v1.28.4+k0s.0-arm64";
      hash = "sha256-VlAyXag1eMZMKsH1UUQeAqXhYBQq7BH3gSezxDxfS8o=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.28.4+k0s.0/k0s-v1.28.4+k0s.0-amd64";
      hash = "sha256-kmvLaEePDrW7hHm/AdOVJBAjRtnyS59Tau3fcf3VqXU=";
    };
  };
}
