{
  version = "1.35.2+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.2+k0s.0/k0s-v1.35.2+k0s.0-arm";
      hash = "sha256-IlT61NhfzTekNEtWgreQvVzjrcMPi4rcVVJC0KdLUHo=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.2+k0s.0/k0s-v1.35.2+k0s.0-arm64";
      hash = "sha256-QeuUBKSYZ5mK4NoHboApBg4nPVR003hK+aZOpkwgjKc=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.2+k0s.0/k0s-v1.35.2+k0s.0-amd64";
      hash = "sha256-8U79bDGum4UGBOdpR5ayGEVXvGg+N6S/elypY6406U4=";
    };
  };
}
