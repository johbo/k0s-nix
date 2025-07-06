{
  version = "1.32.6+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.6+k0s.0/k0s-v1.32.6+k0s.0-arm";
      hash = "sha256-mo8Fn86oHi6HMArQa/dH827ZXukrqEE1d1P5cHNGAl0=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.6+k0s.0/k0s-v1.32.6+k0s.0-arm64";
      hash = "sha256-NovjffI/U32tAtaBYYYKFA4L43XTcNycVkPlw0HxVKo=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.6+k0s.0/k0s-v1.32.6+k0s.0-amd64";
      hash = "sha256-+Ijx4gFrWtFTXxYL27wsi5xbjpVhK7ukHeGM5o2vZ6s=";
    };
  };
}
