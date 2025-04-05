{
  version = "1.32.3+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.3+k0s.0/k0s-v1.32.3+k0s.0-arm";
      hash = "sha256-QDJgQER318MMDGhgFyBS8gMA8iR9rbtNRyQe6ppEChk=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.3+k0s.0/k0s-v1.32.3+k0s.0-arm64";
      hash = "sha256-Y3JAGX6n3EJOp3mOrDQA7U/ZeW5kij2knPA20PHV66o=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.32.3+k0s.0/k0s-v1.32.3+k0s.0-amd64";
      hash = "sha256-4GVUwPvBF8d5JnPlNil8Pnku78sgRXKJ71sCiUzoWy8=";
    };
  };
}
