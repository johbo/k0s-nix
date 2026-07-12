{
  version = "1.33.13+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.13+k0s.0/k0s-v1.33.13+k0s.0-arm";
      hash = "sha256-ghIQNlwTBmEHo2gclDLi41h8ugVFzwGdbPMjQIeASxA=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.13+k0s.0/k0s-v1.33.13+k0s.0-arm64";
      hash = "sha256-WIcbLkEmvBnP9pyAVLJIL7VRXteu7NHzuSKCvWDtREk=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.33.13+k0s.0/k0s-v1.33.13+k0s.0-amd64";
      hash = "sha256-cdeC+kPMDJXpV/cmh2l8PAna896d232S+u9TFUFhuKg=";
    };
  };
}
