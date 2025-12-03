{
  version = "1.33.6+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.6+k0s.0/k0s-v1.33.6+k0s.0-arm";
      hash = "sha256-m931LitrT3DuAzCmyLHvh1ZPWkVRJMdATjjOjpfXPNc=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.6+k0s.0/k0s-v1.33.6+k0s.0-arm64";
      hash = "sha256-wA2oWRTlV4/a/odTx46rXzHZTtJuUTDU+s+Z2I+Ne1U=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.6+k0s.0/k0s-v1.33.6+k0s.0-amd64";
      hash = "sha256-yiAcVa1S5sC6tZqgCXPv4aafQxZQHNCxHweeGkKdjCc=";
    };
  };
}
