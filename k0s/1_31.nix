{
  version = "1.31.12+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.31.12+k0s.0/k0s-v1.31.12+k0s.0-arm";
      hash = "sha256-9mL3zX4KfO14MJS999r3U+dRoiWjC4plE9CsyxizKSE=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.31.12+k0s.0/k0s-v1.31.12+k0s.0-arm64";
      hash = "sha256-hvih4on/R05s63P43nxj5yRSOiuHcSA7iOFtFazo1aM=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.31.12+k0s.0/k0s-v1.31.12+k0s.0-amd64";
      hash = "sha256-0ZWRbUFZdaPfxY3fB7Blpta6QP/WYL64YmZIQSHi5uY=";
    };
  };
}
