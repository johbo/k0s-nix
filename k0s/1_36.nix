{
  version = "1.36.3+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.36.3+k0s.0/k0s-v1.36.3+k0s.0-arm";
      hash = "sha256-/jaEG8EU8EaaDH0ld9VUAY8eb829WxKnUY8R8+lksIc=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.36.3+k0s.0/k0s-v1.36.3+k0s.0-arm64";
      hash = "sha256-M8sH05BB1oCZvGBl09Sr1FHRKhTRyqZIN5jZxp1WOtI=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.36.3+k0s.0/k0s-v1.36.3+k0s.0-amd64";
      hash = "sha256-yxVgBXWwJX4juySgFwMpPpZmaUsJY2MgrEMm/m7d5vI=";
    };
  };
}
