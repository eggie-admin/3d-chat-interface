#!/usr/bin/env python3

import json
import sys
from pathlib import Path

baseline = Path(sys.argv[1] if len(sys.argv) > 1 else "manifests/pet-quality.baseline.json")
quality = json.loads(baseline.read_text(encoding="utf-8"))
errors = list(quality.get("errors", []))
warnings = list(quality.get("warnings", []))
jump = quality.get("jump", {})
look = quality.get("look_registration", {})

if jump.get("airborne_lift_pixels", 0) <= 0:
    errors.append("jump never leaves baseline")
if abs(jump.get("landing_delta_pixels", 999)) > 2:
    errors.append("jump does not return to baseline")
if look.get("maximum_center_drift_pixels", 999) > 4:
    errors.append("look center drift exceeds 4px")
if look.get("maximum_width_ratio", 999) > 1.15:
    errors.append("look width ratio exceeds 1.15")

print(json.dumps({"ok": not errors, "errors": errors, "warnings": warnings}, indent=2))
raise SystemExit(0 if not errors else 1)
