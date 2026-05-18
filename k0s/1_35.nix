{
  version = "1.35.4+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.4+k0s.0/k0s-v1.35.4+k0s.0-arm";
      hash = "sha256-6yuXT5A2FSHax6DnF2+WZCAvU43nzJd9fGOsCTFh3bc=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.4+k0s.0/k0s-v1.35.4+k0s.0-arm64";
      hash = "sha256-VjSX/rrtZ6A8ZPcHYxbzrQfs/zyBpMNHul3/UGzBq2M=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.35.4+k0s.0/k0s-v1.35.4+k0s.0-amd64";
      hash = "sha256-HVlzyMt2M4OLmrLDKGZDgLAr864pUt2JYdwWY4n3Vxs=";
    };
  };
}
