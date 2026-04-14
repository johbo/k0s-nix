{
  version = "1.35.3+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.3+k0s.0/k0s-v1.35.3+k0s.0-arm";
      hash = "sha256-m3tsNtM5LuqnqN43JSw443CAkkMIM0kv4wJc2BVhCTc=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.3+k0s.0/k0s-v1.35.3+k0s.0-arm64";
      hash = "sha256-ch4ClDRcEDc1ZKiFnGNd/9mqwb+jEcezspv/3CWl+X4=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.3+k0s.0/k0s-v1.35.3+k0s.0-amd64";
      hash = "sha256-kYADw/aBB8szD2K+ODX/cMJpn+/JtrSa0DlJODnV0+4=";
    };
  };
}
