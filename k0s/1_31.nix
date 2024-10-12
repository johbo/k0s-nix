rec {
  version = "v1.31.1+k0s.1";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.31.1+k0s.1/k0s-v1.31.1+k0s.1-arm";
      hash = "sha256-6sBRVu/2j7DX6TShHxNXc3hRlNpGQdcv0T8ThAZa8zM=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.31.1+k0s.1/k0s-v1.31.1+k0s.1-arm64";
      hash = "sha256-ua1fx5o13ei8eujDuDUuRTfrNvqwjlRM3ODviABLp4U=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.31.1+k0s.1/k0s-v1.31.1+k0s.1-amd64";
      hash = "sha256-mhL8Qg0Jy3dkJ7TIA78rBEWzTQUXsFRzJKnJprNRjGg=";
    };
  };
}
