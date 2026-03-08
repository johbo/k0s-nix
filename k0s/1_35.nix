{
  version = "1.35.1+k0s.1";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.1+k0s.1/k0s-v1.35.1+k0s.1-arm";
      hash = "sha256-t2G1wMsiUVlK07Q6rnDeZZLouz4t2wDkOwn3XfiH634=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.1+k0s.1/k0s-v1.35.1+k0s.1-arm64";
      hash = "sha256-IiYpEJjHDLNlY9vvTskGgPnBuPjFIypBSCHkIEI3WVM=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.1+k0s.1/k0s-v1.35.1+k0s.1-amd64";
      hash = "sha256-DpTCL03ENR8ndwqFU8kiXEOmNrBMj9wrjH+nmz4FVn0=";
    };
  };
}
