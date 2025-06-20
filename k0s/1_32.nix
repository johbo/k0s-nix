{
  version = "1.32.5+k0s.1";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.5+k0s.1/k0s-v1.32.5+k0s.1-arm";
      hash = "sha256-bRladvvT8LzV88/i1bjY9yDS5EmcN9XTc7wcGU5LFsg=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.5+k0s.1/k0s-v1.32.5+k0s.1-arm64";
      hash = "sha256-PtPdS2x0zMFktxlsjO6nJSIDSy6JZDEKkGeTFPVJO44=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.5+k0s.1/k0s-v1.32.5+k0s.1-amd64";
      hash = "sha256-CP4YAsb+hgIsj97Bcut6yGrWY4CCjhH8mCt1pp0GjQg=";
    };
  };
}
