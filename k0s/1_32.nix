{
  version = "1.32.4+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.4+k0s.0/k0s-v1.32.4+k0s.0-arm";
      hash = "sha256-/aOHT4oXDUR2v6i/vibgk9FEqPUVfudueyovb32WFU8=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.4+k0s.0/k0s-v1.32.4+k0s.0-arm64";
      hash = "sha256-hnvGU4bnaxtpZdwzsts/swDZvgRF+RQMeCbJoz0k9dY=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.4+k0s.0/k0s-v1.32.4+k0s.0-amd64";
      hash = "sha256-fxXYT5Ddw6F+XuW6y1M7C4iZuPSip+eP627r+Zm1ly8=";
    };
  };
}
