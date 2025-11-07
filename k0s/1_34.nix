{
  version = "1.34.1+k0s.1";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.34.1+k0s.1/k0s-v1.34.1+k0s.1-arm";
      hash = "sha256-vIfsBuUbvPh7ijtWylIlmwhM3b6QkViXGRmo353XSt0=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.34.1+k0s.1/k0s-v1.34.1+k0s.1-arm64";
      hash = "sha256-QSkvCH7LztH0+nPYjcvqM66zt08oEQjPw1QLwZmUs60=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.34.1+k0s.1/k0s-v1.34.1+k0s.1-amd64";
      hash = "sha256-0ucFaw0czEynk3YUQ2IQ2HeMAuuc7ndv06odX4djJOc=";
    };
  };
}
