{
  version = "1.33.3+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.3+k0s.0/k0s-v1.33.3+k0s.0-arm";
      hash = "sha256-zzl9giJvy5sieC6VQw9vyRrHX0AUgcXms4GvFwDts54=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.3+k0s.0/k0s-v1.33.3+k0s.0-arm64";
      hash = "sha256-bmFXkQgvFhjXBbQ1B/14fSgNBV0fWvW0711JfXGWUKA=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.3+k0s.0/k0s-v1.33.3+k0s.0-amd64";
      hash = "sha256-OeorwQpF9mIuDQHxajChMTk/W0ppoKO1VNg9vAnTrUA=";
    };
  };
}
