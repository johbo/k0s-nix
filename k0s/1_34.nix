{
  version = "1.34.4+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.34.4+k0s.0/k0s-v1.34.4+k0s.0-arm";
      hash = "sha256-gUIt3HGOqM2I7TBtcLM4Exs2aj5uJ5OlVsTAPjmo684=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.34.4+k0s.0/k0s-v1.34.4+k0s.0-arm64";
      hash = "sha256-fOJkhfkBrrz2XlD6Zi+uijXNR6UTdE3dW4uJlNawO28=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.34.4+k0s.0/k0s-v1.34.4+k0s.0-amd64";
      hash = "sha256-ae5IVtW4XutjPaIAuBQARBVMA8DJcdsWijKSyIZzAcE=";
    };
  };
}
