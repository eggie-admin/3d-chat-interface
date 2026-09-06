import unittest
from unittest.mock import patch

from roleplay import RPGState, perform_action, set_role_class


class RoleplayTests(unittest.TestCase):
    def test_nat20_doubles_base_xp(self):
        s = RPGState()
        with patch("roleplay.secrets.randbelow", return_value=19):
            s = perform_action(s, "compile")
        self.assertEqual(s.last_roll, 20)
        self.assertEqual(s.xp, 24)
        self.assertIn("NATURAL 20", s.last_result)

    def test_level_up_is_bounded(self):
        s = RPGState(level=1, xp=95, xp_next=100)
        with patch("roleplay.secrets.randbelow", return_value=14):
            s = perform_action(s, "compile")
        self.assertGreaterEqual(s.level, 2)
        self.assertLessEqual(s.level, 99)

    def test_invalid_action_is_rejected(self):
        with self.assertRaises(ValueError):
            perform_action(RPGState(), "rm-rf")

    def test_job_change_whitelist(self):
        s = set_role_class(RPGState(), "Patch Mage")
        self.assertEqual(s.role_class, "Patch Mage")
        with self.assertRaises(ValueError):
            set_role_class(s, "Root Wizard")


if __name__ == "__main__":
    unittest.main()
