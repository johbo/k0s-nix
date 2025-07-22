{
  version = "1.33.2+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.2+k0s.0/k0s-v1.33.2+k0s.0-arm";
      hash = "sha256-8DTXySA2TSOcrj6Aziwh7xAn1HQFUxTR89rqNMj0XUM=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.2+k0s.0/k0s-v1.33.2+k0s.0-arm64";
      hash = "sha256-T7mvDDQvy6M/RPucTNn9EYSkNro6G7JavPdOFMWLaUg=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.2+k0s.0/k0s-v1.33.2+k0s.0-amd64";
      hash = "sha256-ZK0nLve690aLr1II1tkz2exxWqrU4oB58N80/gRZaCo=";
    };
  };
}
