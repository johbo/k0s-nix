{
  version = "1.33.10+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.10+k0s.0/k0s-v1.33.10+k0s.0-arm";
      hash = "sha256-/aXehKbZ9QtG/mPMyt/m00zU/RkPOl6zd/4OiiRWK0U=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.10+k0s.0/k0s-v1.33.10+k0s.0-arm64";
      hash = "sha256-pro5ETzZNSo3qXH+vU7iC+lUcOYO02YLVb97A+oh05Q=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.10+k0s.0/k0s-v1.33.10+k0s.0-amd64";
      hash = "sha256-rM8H4bfy/g7GCiCrlgOGW/wpVrTzXvzupusJDvIFlUQ=";
    };
  };
}
