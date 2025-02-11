{
  version = "1.32.1+k0s.0";
  srcs = {
    armv7l-linux = {
      url =
        "https://github.com/k0sproject/k0s/releases/download/v1.32.1+k0s.0/k0s-v1.32.1+k0s.0-arm";
      hash = "sha256-0Zc0a1ttF5iPLF6pVN2bunmzGDvfdTC9ysT+0J2Ptp4=";
    };
    aarch64-linux = {
      url =
        "https://github.com/k0sproject/k0s/releases/download/v1.32.1+k0s.0/k0s-v1.32.1+k0s.0-arm64";
      hash = "sha256-TGvVPkVM7TpLDRrrf9UjLlqeT+QsvhLR29Js3V8Jsug=";
    };
    x86_64-linux = {
      url =
        "https://github.com/k0sproject/k0s/releases/download/v1.32.1+k0s.0/k0s-v1.32.1+k0s.0-amd64";
      hash = "sha256-M530SgkZoTphxOhGV7TrJJQVRoHmyRgDy9Q6ujt5vXM=";
    };
  };
}
