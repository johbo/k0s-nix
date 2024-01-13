{
  version = "1.27.9+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.27.9+k0s.0/k0s-v1.27.9+k0s.0-arm";
      hash = "sha256-UlervwgmLn2XrdDSaDef9ChHdNFr//V1YQ0h57KduUc=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.27.9+k0s.0/k0s-v1.27.9+k0s.0-arm64";
      hash = "sha256-kSewnHBJDeRxZBp8vj4TYY+PwmOTASHLMFm7NJI7gB0=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.27.9+k0s.0/k0s-v1.27.9+k0s.0-amd64";
      hash = "sha256-rz54/akjSvrBzR+5SUFuQv7TLq1DBzt92JKyACwSaDE=";
    };
  };
}
