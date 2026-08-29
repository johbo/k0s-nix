import unittest

import update


def fetch(*names):
    return [{"name": name, "url": "", "unpack": True, "hash": ""} for name in names]


class DuplicateNameTest(unittest.TestCase):
    def test_names_used_once_are_accepted(self):
        update.refuse_duplicate_names(fetch("k0s", "runc", "runc/extra"))

    def test_a_name_used_twice_stops_the_run(self):
        with self.assertRaises(SystemExit):
            update.refuse_duplicate_names(fetch("k0s", "runc/extra", "runc/extra"))


if __name__ == "__main__":
    unittest.main()
