{
  version = "1.33.1+k0s.1";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.1+k0s.1/k0s-v1.33.1+k0s.1-arm";
      hash = "sha256-LJ6JwpR89KeZtnTGfon3dqY109+YzCrxTYqwicvI03A=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.1+k0s.1/k0s-v1.33.1+k0s.1-arm64";
      hash = "sha256-HmfhK8gp5Ioy3fLigw1oldgn2lpDWHzqv0e0hhfWo/Q=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.1+k0s.1/k0s-v1.33.1+k0s.1-amd64";
      hash = "sha256-/aeaWbP0k2/gWTgkEY5CGPzMaeZv7ODlN79/GJq9p3Q=";
    };
  };
}
