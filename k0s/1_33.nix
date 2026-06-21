{
  version = "1.33.12+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.12+k0s.0/k0s-v1.33.12+k0s.0-arm";
      hash = "sha256-U7QNdA2qvgZuaPnpsuTfbG9fq7Wl5c0X2JjyUEE9Iv0=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.12+k0s.0/k0s-v1.33.12+k0s.0-arm64";
      hash = "sha256-5atTpGy7VSXTYoq2WDAKivNXjUib62GRxeg4XAd286k=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.12+k0s.0/k0s-v1.33.12+k0s.0-amd64";
      hash = "sha256-+c5YwU7xGhLwvB25IDFqUmaI/S+D11DNW4ZO40qETYo=";
    };
  };
}
