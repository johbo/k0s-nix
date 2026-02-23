{
  version = "1.35.1+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.1+k0s.0/k0s-v1.35.1+k0s.0-arm";
      hash = "sha256-NlQ7eYRY6YC69+C8/s5UBMAKB7qiLYhPHclXongAPNo=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.1+k0s.0/k0s-v1.35.1+k0s.0-arm64";
      hash = "sha256-Kmbh42l1GgKCT5pXKm4nObmpOt/El3L8zxzwNFVTvYA=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.1+k0s.0/k0s-v1.35.1+k0s.0-amd64";
      hash = "sha256-plznzBoGRd/OUXxYKodaFLlmC1kTq/7kwO3z3H4Wnng=";
    };
  };
}
