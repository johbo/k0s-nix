{
  version = "1.34.10+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.34.10+k0s.0/k0s-v1.34.10+k0s.0-arm";
      hash = "sha256-6IM/M+i8kWqkoWiaulKqPbaTfhEV7rJDiFENV9OaTRY=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.34.10+k0s.0/k0s-v1.34.10+k0s.0-arm64";
      hash = "sha256-AvAqNTrfD7yRuyJHyEY2mUw36606AHAy56zV8wG8VOw=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.34.10+k0s.0/k0s-v1.34.10+k0s.0-amd64";
      hash = "sha256-Gt9BztmfMIMlws/d2TYRAuhvzB/dcw+v7xjdUoU3LrA=";
    };
  };
}
