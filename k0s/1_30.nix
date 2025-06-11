{
  version = "1.30.1+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.30.1+k0s.0/k0s-v1.30.1+k0s.0-arm";
      hash = "sha256-NgrRrfrnep0iH29ZsmgRFMgyXGL8B0gmpl6dMl2QHyg=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.30.1+k0s.0/k0s-v1.30.1+k0s.0-arm64";
      hash = "sha256-ICv53BQkLAjE4JHdlNKp8kzMAsE/TBtbqiuWTLUb620=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.30.1+k0s.0/k0s-v1.30.1+k0s.0-amd64";
      hash = "sha256-IuZ6AxiUUzkN8uiD2Z54JncJe+vsupk9tMvoYCT/CgI=";
    };
  };
}
