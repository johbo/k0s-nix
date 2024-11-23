{
  version = "1.31.2+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.31.2+k0s.0/k0s-v1.31.2+k0s.0-arm";
      hash = "sha256-T2W95NwTxHlUrWffEjXRsEw+nGByYdJsYJguC+J1yIY=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.31.2+k0s.0/k0s-v1.31.2+k0s.0-arm64";
      hash = "sha256-DR1Qm0NFXwyKJTImh+Csj0tgk4M76RycHTMI/t7sbOs=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.31.2+k0s.0/k0s-v1.31.2+k0s.0-amd64";
      hash = "sha256-wY3VpSLpj6lDx18AnQ1jTtCIuydgaGX7R5qUtkFRIIU=";
    };
  };
}
