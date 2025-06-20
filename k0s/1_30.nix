{
  version = "1.30.13+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.30.13+k0s.0/k0s-v1.30.13+k0s.0-arm";
      hash = "sha256-pVGIovrWm3Fg4IFcWnqpULI1XuSYXIWZ0cpSbfmEr9w=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.30.13+k0s.0/k0s-v1.30.13+k0s.0-arm64";
      hash = "sha256-gY2vd08qRChEjnJa2GRjsjDdoRozZfydwVhYabHmkJU=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.30.13+k0s.0/k0s-v1.30.13+k0s.0-amd64";
      hash = "sha256-T0paUL1HSIJ28g2IxVQpjd2IiFmCZVez5b0ZSEcpByw=";
    };
  };
}
