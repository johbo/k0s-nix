{
  version = "1.33.9+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.9+k0s.0/k0s-v1.33.9+k0s.0-arm";
      hash = "sha256-txLr170cI5oBe6DjNYgtS9pqcnalo3rkcnhAsvQzCD4=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.9+k0s.0/k0s-v1.33.9+k0s.0-arm64";
      hash = "sha256-zo5T5H6zBSXyW7+M3DaGMg4Jo1Mn25JarJT/kXd6OV4=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.9+k0s.0/k0s-v1.33.9+k0s.0-amd64";
      hash = "sha256-ykfmx/GavaJ0H96QJquCo7VowzNyFu5dqI46xD30J1M=";
    };
  };
}
