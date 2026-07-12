{
  version = "1.34.9+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.34.9+k0s.0/k0s-v1.34.9+k0s.0-arm";
      hash = "sha256-iUV2BNR8zdc+cew7MI9lkrYGIW2tOhYq/TPyn6S8Vuw=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.34.9+k0s.0/k0s-v1.34.9+k0s.0-arm64";
      hash = "sha256-vmdqtzQUUE5nzSnWnTDUJWF7kdp2X8YyBvgSb7JC0vM=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.34.9+k0s.0/k0s-v1.34.9+k0s.0-amd64";
      hash = "sha256-zeAxllPoSkS/QVgEX8+XXB/JlhrAHJDQQEwcwPCbiSk=";
    };
  };
}
