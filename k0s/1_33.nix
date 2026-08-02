{
  version = "1.33.13+k0s.1";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.13+k0s.1/k0s-v1.33.13+k0s.1-arm";
      hash = "sha256-WBDxa0yHih/SQt0wq7E/+QWHjZ+oQ77xP+YgOaeJytI=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.13+k0s.1/k0s-v1.33.13+k0s.1-arm64";
      hash = "sha256-0HhFzDTXesBEZ8fdBwoJdFdAQQeaiXx5b4wiH3h/SSM=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.13+k0s.1/k0s-v1.33.13+k0s.1-amd64";
      hash = "sha256-0d/8Xgc3g+4y3KXYmWX4RbBjYHICNq7hkD+UOFdIqPI=";
    };
  };
}
