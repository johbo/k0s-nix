"""
Cover the parts of vendor_hashes.py that need no build.

Resolving a hash needs the network and a Go toolchain, so what is left
to a test is the reading and writing of a table and the reading of a
build log. Both are where a silent mistake would be written into a file
nobody re-reads.
"""

import tempfile
import unittest
from pathlib import Path

import vendor_hashes


TABLE = """{
  # A comment the rewrite has to leave alone.
  vendorHashes = {
    "0.13.19" = "sha256-first=";
    "0.16.3" = "sha256-third=";
  };

  inherit (component) version;
}
"""


class TableTest(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.path = Path(directory.name) / "kine.nix"
        self.path.write_text(TABLE)

    def test_reads_every_entry(self):
        self.assertEqual(
            vendor_hashes.read(self.path),
            {"0.13.19": "sha256-first=", "0.16.3": "sha256-third="},
        )

    def test_writing_what_was_read_changes_nothing(self):
        vendor_hashes.write(self.path, vendor_hashes.read(self.path))
        self.assertEqual(self.path.read_text(), TABLE)

    def test_a_new_entry_lands_in_version_order(self):
        entries = vendor_hashes.read(self.path) | {"0.14.16": "sha256-second="}
        vendor_hashes.write(self.path, entries)
        self.assertEqual(
            list(vendor_hashes.read(self.path)), ["0.13.19", "0.14.16", "0.16.3"]
        )

    def test_an_entry_left_out_is_dropped(self):
        vendor_hashes.write(self.path, {"0.16.3": "sha256-third="})
        self.assertEqual(list(vendor_hashes.read(self.path)), ["0.16.3"])

    def test_the_surrounding_file_survives(self):
        vendor_hashes.write(self.path, {"9.9.9": "sha256-only="})
        text = self.path.read_text()
        self.assertIn("# A comment the rewrite has to leave alone.", text)
        self.assertIn("inherit (component) version;", text)

    def test_a_file_without_a_table_stops_the_run(self):
        self.path.write_text("{ }\n")
        with self.assertRaises(SystemExit):
            vendor_hashes.read(self.path)


def mismatch_log(name, got):
    return (
        f"building '/nix/store/{'a' * 32}-{name}.drv'...\n"
        f"error: hash mismatch in fixed-output derivation "
        f"'/nix/store/{'b' * 32}-{name}.drv':\n"
        f"         specified: {vendor_hashes.PLACEHOLDER}\n"
        f"            got:    {got}\n"
    )


class MismatchTest(unittest.TestCase):
    def test_reads_the_hash_a_derivation_wanted(self):
        log = mismatch_log("kine-0.16.3-go-modules", "sha256-real=")
        self.assertEqual(
            vendor_hashes.mismatches(log), {"kine-0.16.3": "sha256-real="}
        )

    def test_reads_a_k0s_version_carrying_its_own_suffix(self):
        log = mismatch_log("k0s-1.36.3+k0s.2-go-modules", "sha256-real=")
        self.assertEqual(
            vendor_hashes.mismatches(log), {"k0s-1.36.3+k0s.2": "sha256-real="}
        )

    def test_reads_every_derivation_the_build_reported(self):
        log = mismatch_log(
            "k0s-1.36.3+k0s.2-go-modules", "sha256-one="
        ) + mismatch_log("kine-0.16.3-go-modules", "sha256-two=")
        self.assertEqual(len(vendor_hashes.mismatches(log)), 2)

    def test_a_mismatch_we_do_not_own_stops_the_run(self):
        log = mismatch_log("etcdserver-3.6.14-go-modules", "sha256-real=")
        with self.assertRaises(SystemExit):
            vendor_hashes.mismatches(log)

    def test_a_build_that_reported_nothing_reads_as_nothing(self):
        self.assertEqual(vendor_hashes.mismatches(""), {})


if __name__ == "__main__":
    unittest.main()
