{
  version = "1.32.7+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.7+k0s.0/k0s-v1.32.7+k0s.0-arm";
      hash = "sha256-rcVmOeebGge1mSEk27fiyVBhHqGnV/JszjtQn5JiGzY=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.7+k0s.0/k0s-v1.32.7+k0s.0-arm64";
      hash = "sha256-Yl2JwA6CNrgSoklViUB3GI6RIT6dHclEDw5Obm21P/s=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.7+k0s.0/k0s-v1.32.7+k0s.0-amd64";
      hash = "sha256-3COD7InqAj36aWgRFmgNngQf1TwPA4spTT8uRS1Tf/I=";
    };
  };
}
