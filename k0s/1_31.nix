{
  version = "1.31.10+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.31.10+k0s.0/k0s-v1.31.10+k0s.0-arm";
      hash = "sha256-WVoVQ4xjjD8TPyQLOmRwVNqmOfgbP31GKCLuiN6LLpA=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.31.10+k0s.0/k0s-v1.31.10+k0s.0-arm64";
      hash = "sha256-D9CvltDdQCJm2yTwmyxSzfbpWU8WKN509kwSLGbSwqA=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.31.10+k0s.0/k0s-v1.31.10+k0s.0-amd64";
      hash = "sha256-XR3KmCdHhvyjp6WkpHoybh1DQS97scbNj7xg0p3K5iA=";
    };
  };
}
