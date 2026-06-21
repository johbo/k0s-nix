{
  version = "1.35.5+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.5+k0s.0/k0s-v1.35.5+k0s.0-arm";
      hash = "sha256-J3sCYHhJU0CjkU3i+p0bje9O/bkKl1XxV7yrSeo9r+Y=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.5+k0s.0/k0s-v1.35.5+k0s.0-arm64";
      hash = "sha256-ubs+upsVNPlROIBOHB/LnhBAhTRroYi1lRHm/iFbOI8=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.5+k0s.0/k0s-v1.35.5+k0s.0-amd64";
      hash = "sha256-+h9zllyD4iYUDBe26O87lxXZeqUrvFP6kFDAabm4qxU=";
    };
  };
}
