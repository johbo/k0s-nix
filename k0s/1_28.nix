{
  version = "1.28.15+k0s.0";
  srcs = {
    armv7l-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.28.15+k0s.0/k0s-v1.28.15+k0s.0-arm";
      hash = "sha256-FHz6/WQcafliPC22bYsNUakJkeCvf9ZrYmtOK90boOM=";
    };
    aarch64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.28.15+k0s.0/k0s-v1.28.15+k0s.0-arm64";
      hash = "sha256-AcVY7SRkYKXmOYnI+yj2xoR6yasP0HSDNDLaDRmiCF4=";
    };
    x86_64-linux = {
      url = "https://github.com/k0sproject/k0s/releases/download/v1.28.15+k0s.0/k0s-v1.28.15+k0s.0-amd64";
      hash = "sha256-CeiatQs/qPYy15CdwAZ7bRNpMb02diqke5zMikOX5fw=";
    };
  };
}
