#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3 gnumake nix
"""Regenerate the embedded-bins data for the packaged k0s minors.

    update.py [1_36 ...]

Fetches each k0s source, extracts its pins and build parameters with
extract.py, and prefetches the source hashes the component derivations
need. A source whose URL has not moved keeps the hash already recorded,
so a run that changes nothing costs no downloads.

This is deliberately not part of k0s/update-script.bash: that one tracks
the release binaries, and the two packages stand as alternatives while
the source build is being built up.
"""

import json
import re
import subprocess
import sys
from pathlib import Path

import extract

HERE = Path(__file__).resolve().parent
K0S_DIR = HERE.parent
K0S_ARCHIVE = "https://github.com/k0sproject/k0s/archive/refs/tags/v{}.tar.gz"


def update(minor):
    version = read_version(K0S_DIR / f"{minor}.nix")
    known = read_hashes(HERE / f"{minor}.json")

    source, k0s_hash = prefetch(K0S_ARCHIVE.format(version), unpack=True, known=known)
    upstream = extract.extract(Path(source))

    fetch = [entry("k0s", K0S_ARCHIVE.format(version), True, k0s_hash)]
    for name, component in upstream["components"].items():
        fetch.append(fetch_entry(name, archive_url(component), True, known))
        for url in component.get("extra_urls", []):
            fetch.append(fetch_entry(f"{name}/extra", url, False, known))

    write(HERE / f"{minor}.json",
          {"k0sVersion": version, "upstream": upstream, "fetch": fetch})


# A git source is fetched as its forge's tag archive rather than cloned,
# so the hash is one fetchzip can use.
def archive_url(component):
    if "source_tag" not in component:
        return component["source_url"]
    repository = component["source_url"].removesuffix(".git")
    return f"{repository}/archive/refs/tags/{component['source_tag']}.tar.gz"


def fetch_entry(name, url, unpack, known):
    _, hash_ = prefetch(url, unpack, known)
    return entry(name, url, unpack, hash_)


def entry(name, url, unpack, hash_):
    return {"name": name, "url": url, "unpack": unpack, "hash": hash_}


def prefetch(url, unpack, known):
    command = ["nix-prefetch-url", "--print-path", "--quiet"]
    if unpack:
        command.append("--unpack")
    if url in known:
        command += ["--type", "sha256", url, to_base32(known[url])]
    else:
        command.append(url)

    output = run(command).splitlines()
    return output[1], known.get(url) or to_sri(output[0])


def read_version(path):
    match = re.search(r'version\s*=\s*"([^"]+)"', path.read_text())
    if not match:
        sys.exit(f"no version in {path}")
    return match.group(1)


def read_hashes(path):
    if not path.exists():
        return {}
    return {item["url"]: item["hash"] for item in json.loads(path.read_text())["fetch"]}


def to_sri(base32):
    return run(["nix", "hash", "to-sri", "--type", "sha256", base32]).strip()


def to_base32(sri):
    return run(["nix", "hash", "to-base32", sri]).strip()


def run(command):
    return subprocess.run(command, capture_output=True, text=True, check=True).stdout


def write(path, data):
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
    print(f"wrote {path.name}", file=sys.stderr)


if __name__ == "__main__":
    for name in sys.argv[1:] or sorted(p.stem for p in K0S_DIR.glob("1_*.nix")):
        update(name)
