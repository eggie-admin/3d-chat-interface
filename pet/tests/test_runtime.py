from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
import sys

PET_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PET_ROOT))

import runtime


class PetRuntimeTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.old_state_path = runtime.STATE_PATH
        runtime.STATE_PATH = Path(self.tmp.name) / "state.json"

    def tearDown(self) -> None:
        runtime.STATE_PATH = self.old_state_path
        self.tmp.cleanup()

    def test_default_state_round_trip(self) -> None:
        state = runtime.load_state()
        self.assertEqual(state.state, "idle")
        self.assertEqual(state.mood, "neutral")
        runtime.save_state(state)
        loaded = runtime.load_state()
        self.assertEqual(loaded, state)

    def test_supported_events_stay_bounded(self) -> None:
        state = runtime.PetState()
        events = [
            "tap",
            "double_tap",
            "praise",
            "message",
            "ignore",
            "focus",
            "jump",
            "sleep",
            "wake",
        ]
        for _ in range(30):
            for event in events:
                state = runtime.apply_event(state, event)
                self.assertGreaterEqual(state.energy, 0)
                self.assertLessEqual(state.energy, 100)
                self.assertGreaterEqual(state.attention, 0)
                self.assertLessEqual(state.attention, 100)
                self.assertGreaterEqual(state.affection, 0)
                self.assertLessEqual(state.affection, 100)

    def test_reset_restores_canonical_state(self) -> None:
        state = runtime.PetState(state="taunt", mood="jealous", energy=1, attention=2, affection=3)
        state = runtime.apply_event(state, "reset")
        self.assertEqual(state, runtime.PetState())

    def test_unknown_event_is_rejected(self) -> None:
        with self.assertRaises(ValueError):
            runtime.apply_event(runtime.PetState(), "summon_the_void")

    def test_wake_restores_energy_without_overflow(self) -> None:
        state = runtime.PetState(energy=95)
        state = runtime.apply_event(state, "wake")
        self.assertEqual(state.energy, 100)
        self.assertEqual(state.state, "idle")


if __name__ == "__main__":
    unittest.main()
