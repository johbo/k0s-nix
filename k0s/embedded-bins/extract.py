#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 gnumake
"""Read the k0s embedded-bins pins and build parameters as JSON.

    extract.py <k0s-source-dir>

Needs no network. Keys mirror upstream's own flat variable namespace, so
the output reads against embedded-bins/Makefile.variables directly.

Every set this depends on is asserted against the source. Upstream adding
a component, a build parameter or a pin stops the run instead of
producing a quietly incomplete result.
"""

import json
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlsplit

COMPONENTS = {
    "containerd", "etcd", "iptables", "keepalived",
    "kine", "konnectivity", "kubernetes", "runc",
}

SUFFIXES = {
    "_version", "_revision", "_buildimage",
    "_build_go_tags", "_build_go_cgo_enabled", "_build_go_cgo_cflags",
    "_build_shim_go_cgo_enabled", "_build_go_flags",
    "_build_go_ldflags", "_build_go_ldflags_extra",
    "_build_cflags", "_build_ldflags", "_build_configure_flags",
}

# --build-arg names the Makefile passes for every component alike.
SHARED_BUILD_ARGS = {
    "BUILDKIT_DOCKERFILE_CHECK", "CONTAINERD_BINS", "KUBERNETES_BINS",
    "SOURCE_DATE_EPOCH", "TARGET_OS",
}

# Pins living in a Dockerfile rather than in Makefile.variables, which is
# why reading that file alone is silently incomplete.
ARG_PINS = {"LIBSECCOMP_VERSION": "2.6.0"}

SOURCE_HOSTS = {"github.com", "www.netfilter.org", "www.keepalived.org"}

EXTRACT_MK = Path(__file__).resolve().parent / "extract.mk"


def extract(source_dir):
    embedded_bins = source_dir / "embedded-bins"
    makefile = (embedded_bins / "Makefile").read_text()
    variables = read_variables(embedded_bins)
    dockerfiles = {name: (embedded_bins / name / "Dockerfile").read_text()
                   for name in variables["images"].split()}

    guard(variables["images"].split(), COMPONENTS,
          "New component directories; extend COMPONENTS and package them")
    # The suffixes have to come from the Makefile's --build-arg lines, not
    # from Makefile.variables, which also holds variables no recipe reads.
    guard(re.findall(r"patsubst %/Dockerfile,%,\$<\)(_[a-z_]+)", makefile), SUFFIXES,
          "New per-component build parameters; extend SUFFIXES and extract.mk")
    guard(shared_build_args(makefile), SHARED_BUILD_ARGS,
          "New shared build arguments in embedded-bins/Makefile")
    guard(pin_set(arg_pins("\n".join(dockerfiles.values()))), pin_set(ARG_PINS),
          "New or moved Dockerfile ARG defaults")

    return {
        "global": {name: variables[name]
                   for name in ["go_version", "alpine_patch_version"]},
        "payloadBinaries": variables["posix_bins"].split(),
        "components": {name: component(name, variables, dockerfiles[name])
                       for name in sorted(dockerfiles)},
    }


def component(name, variables, dockerfile):
    prefix = f"{name}_"
    pins = arg_pins(dockerfile)
    values = {key[len(prefix):]: unquote(value)
              for key, value in variables.items()
              if key.startswith(prefix) and value}
    values.update({f"argpin_{pin}": pinned for pin, pinned in pins.items()})
    values.update(sources(name, dockerfile, values["version"], pins))
    return values


# Read from the fetches rather than assumed: a component is cloned from git
# or downloaded as a tarball, and some carry more alongside - runc pulls
# libseccomp, and containerd carried an upstream patch until 1.36. Every
# variable is substituted so the URLs stand on their own.
def sources(name, dockerfile, version, pins):
    substitutions = {"$VERSION": version}
    substitutions.update({f"${pin}": pinned for pin, pinned in pins.items()})

    fetches = "\n".join(line for line in logical_lines(dockerfile)
                        if line.startswith("RUN") and re.search(r"\b(git|curl|wget)\b", line))
    urls = [substitute(url, substitutions) for url in re.findall(r"https://\S+", fetches)]
    for url in urls:
        guard([urlsplit(url).hostname], SOURCE_HOSTS,
              f"{name} fetches from an unknown host")

    repositories = [url for url in urls if url.endswith(".git")]
    if len(repositories) > 1:
        sys.exit(f"{name}: more than one git source: {' '.join(repositories)}")
    if not repositories:
        if len(urls) != 1:
            sys.exit(f"{name}: expected one source download, found {len(urls)}")
        return {"source_url": urls[0]}

    extra = sorted(url for url in urls if url not in repositories)
    return {"source_url": repositories[0], "source_tag": f"v{version}",
            **({"extra_urls": extra} if extra else {})}


# A fetch is regularly spread over several lines joined by a backslash.
def logical_lines(text):
    return re.sub(r"\\\n\s*", " ", text).splitlines()


def substitute(text, substitutions):
    for name, value in substitutions.items():
        text = text.replace(name, value)
    return text


def guard(found, known, message):
    unknown = sorted(set(found) - set(known))
    if unknown:
        sys.exit(f"{message}: {' '.join(unknown)}")


def read_variables(embedded_bins):
    output = subprocess.run(
        ["make", "--silent", "-C", str(embedded_bins),
         "-f", "Makefile", "-f", str(EXTRACT_MK), "extract"],
        capture_output=True, text=True, check=True).stdout
    return dict(line.split("\t", 1) for line in output.splitlines())


# The per-component build arguments are the ones derived through patsubst;
# what is left is passed to every component alike.
def shared_build_args(makefile):
    lines = [line for line in makefile.splitlines()
             if "--build-arg" in line and "patsubst" not in line]
    return re.findall(r"--build-arg ([A-Z_]+)=", "\n".join(lines))


def arg_pins(text):
    return dict(re.findall(r"^ARG ([A-Z_]+)=(.*)$", text, re.MULTILINE))


def pin_set(pins):
    return {f"{name}={value}" for name, value in pins.items()}


def unquote(value):
    return value[1:-1] if value.startswith('"') and value.endswith('"') else value


if __name__ == "__main__":
    print(json.dumps(extract(Path(sys.argv[1])), indent=2, sort_keys=True))
