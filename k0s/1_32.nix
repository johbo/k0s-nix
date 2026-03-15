{
  version = "1.32.13+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.13+k0s.0/k0s-v1.32.13+k0s.0-arm";
      hash = "sha256-cTzWaNtU0amBjoyhTBnORLJjRnmIdHMn/VtR1S5DSaQ=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.13+k0s.0/k0s-v1.32.13+k0s.0-arm64";
      hash = "sha256-tNoOnoi7L/xV8JnM7O/4CeAJMBnyznOUlvpeRWgdAug=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.13+k0s.0/k0s-v1.32.13+k0s.0-amd64";
      hash = "sha256-CSEHPTNlA0xPQF1XVVISon1KpQW/uk1oq07/72TX+f0=";
    };
  };
}
