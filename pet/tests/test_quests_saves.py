import json
import tempfile
import unittest
from dataclasses import asdict
from pathlib import Path
from unittest.mock import patch

import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import quests
import saves
from roleplay import RPGState


class QuestTests(unittest.TestCase):
    def test_generate_android_godot_task(self):
        with tempfile.TemporaryDirectory() as td:
            state_path = Path(td) / "quest.json"
            with patch.object(quests, "STATE_PATH", state_path):
                state = quests.generate_quest("Fix Godot Android export for Samsung S24 FE")
                labels = " ".join(item["label"] for item in state.objectives).lower()
                self.assertIn("godot", labels)
                self.assertIn("android", labels)
                self.assertGreaterEqual(len(state.objectives), 4)
                self.assertTrue(state_path.exists())

    def test_action_completes_matching_objective(self):
        state = quests.QuestState(
            active_task="Compile it",
            objectives=[{"label": "Compile", "action": "compile", "done": False}],
        )
        state = quests.complete_for_action(state, "compile")
        self.assertTrue(state.objectives[0]["done"])
        self.assertEqual(state.completed, 1)


class SaveSlotTests(unittest.TestCase):
    def test_three_slot_contract(self):
        with tempfile.TemporaryDirectory() as td:
            with patch.object(saves, "SAVE_DIR", Path(td)):
                snap = saves.save_slot(
                    2,
                    asdict(RPGState(level=7, role_class="Patch Mage")),
                    asdict(quests.QuestState(active_task="Ship build")),
                )
                self.assertEqual(snap["slot"], 2)
                restored = saves.load_slot(2)
                self.assertEqual(restored["rpg"]["level"], 7)
                listing = saves.list_slots()
                slot2 = [item for item in listing if item["slot"] == 2][0]
                self.assertTrue(slot2["occupied"])
                self.assertEqual(slot2["role_class"], "Patch Mage")

    def test_rejects_out_of_range_slot(self):
        with tempfile.TemporaryDirectory() as td:
            with patch.object(saves, "SAVE_DIR", Path(td)):
                with self.assertRaises(ValueError):
                    saves.save_slot(4, {}, {})


if __name__ == "__main__":
    unittest.main()
