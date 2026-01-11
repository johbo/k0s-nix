{
  version = "1.34.3+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.34.3+k0s.0/k0s-v1.34.3+k0s.0-arm";
      hash = "sha256-ou0f7BrxJnjvoAdAa8vggfDm6lJOXBgREC5Ndp1oxeA=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.34.3+k0s.0/k0s-v1.34.3+k0s.0-arm64";
      hash = "sha256-oGcoUY4Bq32YatT/8cYIrH5I2nLhM+iipjgRWvZUgnc=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.34.3+k0s.0/k0s-v1.34.3+k0s.0-amd64";
      hash = "sha256-qSRR48h22ddttCtyK8w6DFuHXyNT/lQBuOJQGNppuDg=";
    };
  };
}
