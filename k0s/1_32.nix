{
  version = "1.32.2+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.2+k0s.0/k0s-v1.32.2+k0s.0-arm";
      hash = "sha256-An8Zu/chu9DkM+D6Q9+k4L88y5VY4Y72peyY8IjaJt4=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.2+k0s.0/k0s-v1.32.2+k0s.0-arm64";
      hash = "sha256-cJph00MYEtWNJoOu0htYqemjBxUZv/gW02dt+Cge8RE=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.2+k0s.0/k0s-v1.32.2+k0s.0-amd64";
      hash = "sha256-pMYqtOrjvDa/LPpDH56pkH7dMDQ+MltKmkJhCqfkPy8=";
    };
  };
}
