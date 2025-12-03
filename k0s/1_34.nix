{
  version = "1.34.2+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.34.2+k0s.0/k0s-v1.34.2+k0s.0-arm";
      hash = "sha256-mM/ihEzMvCZ+eljD5vbrdCzzsaZt//2mGn2On08yv7U=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.34.2+k0s.0/k0s-v1.34.2+k0s.0-arm64";
      hash = "sha256-+fHOCaNU3hcgRLFiIBlULlJdeS/PmY2ITX8g10yRTrk=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.34.2+k0s.0/k0s-v1.34.2+k0s.0-amd64";
      hash = "sha256-gmXO9JSlr1rG80EycA+Gc2bkVSoycTDL+DBQG+jogg4=";
    };
  };
}
