from __future__ import annotations

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "godot" / "jrpg" / "assets" / "lum" / "puppet" / "lum_puppet.json"
RIG = ROOT / "godot" / "jrpg" / "LumPuppet2D.gd"
STAGE = ROOT / "godot" / "jrpg" / "LumAvatarStage.gd"


class LumPuppetContractTests(unittest.TestCase):
    def test_config_shape_and_rights_firewall(self) -> None:
        data = json.loads(CONFIG.read_text(encoding="utf-8"))
        self.assertEqual(data["schema"], "kai9000.lum.puppet2d.v1")
        self.assertEqual(data["engine"], "Godot 4")
        self.assertEqual(data["fallback_order"], ["puppet2d", "glb3d", "procedural3d"])
        self.assertIn("breath", data["parameters"])
        self.assertIn("eye_open", data["parameters"])
        self.assertIn("wing_open", data["parameters"])
        self.assertIn("victory", data["states"])
        self.assertGreaterEqual(len(data["layers"]), 10)

        banned = (".pck", ".moc", ".mtn", ".moc3")
        for layer in data["layers"]:
            texture = layer["texture"].lower()
            self.assertTrue(texture.endswith(".png"))
            self.assertFalse(texture.endswith(banned))

        rights = data["rights"]["destiny_child"].lower()
        self.assertIn("reference-only", rights)
        self.assertIn("no .pck", rights)

    def test_rig_exposes_parameter_animation(self) -> None:
        text = RIG.read_text(encoding="utf-8")
        for token in (
            "angle_x",
            "angle_y",
            "body_sway",
            "breath",
            "eye_open",
            "mouth_open",
            "hair_sway",
            "tail_sway",
            "wing_open",
            "play_state",
        ):
            self.assertIn(token, text)

    def test_stage_prefers_puppet_then_keeps_fallbacks(self) -> None:
        text = STAGE.read_text(encoding="utf-8")
        self.assertIn("_try_load_puppet2d", text)
        self.assertIn('"puppet2d"', text)
        self.assertIn('"glb3d"', text)
        self.assertIn('"procedural3d"', text)
        self.assertIn("res://assets/lum/lum.glb", text)


if __name__ == "__main__":
    unittest.main()
