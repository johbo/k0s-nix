{
  version = "1.31.5+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.31.5+k0s.0/k0s-v1.31.5+k0s.0-arm";
      hash = "sha256-PZK08+PSu6wp2aWjUuih0tjOY4GqnkUJHUmFcgVqNzc=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.31.5+k0s.0/k0s-v1.31.5+k0s.0-arm64";
      hash = "sha256-3jdGXiZG6m+khv4uedzBHdETyC439emg0mSvsmtZDcg=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.31.5+k0s.0/k0s-v1.31.5+k0s.0-amd64";
      hash = "sha256-R2bBMMSALoVqLRnqTrid2nI+PAzBryRhUnZRF66H+Sw=";
    };
  };
}
