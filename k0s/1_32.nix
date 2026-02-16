{
  version = "1.32.11+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.11+k0s.0/k0s-v1.32.11+k0s.0-arm";
      hash = "sha256-+mlAr1nWozg5d8tG2sRiTakSA/D3onQTuZWo7rNz080=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.11+k0s.0/k0s-v1.32.11+k0s.0-arm64";
      hash = "sha256-6j3Vc7Jf4XwqMMJa1Y3Cr4kIKebrdM3Lo9z2ESTbtF8=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.11+k0s.0/k0s-v1.32.11+k0s.0-amd64";
      hash = "sha256-iTrjfnn4H4z13N2F5EiP4gefE/TpWT1rYLK0hxvWIn4=";
    };
  };
}
