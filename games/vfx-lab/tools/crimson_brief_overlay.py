"""Investigate the Crimson Detonation critic-gate failure without touching the upstream skill.

    python tools/crimson_brief_overlay.py
    python <skill>/scripts/critic_gate.py library/effects/explosion_crimson.briefed.json

roblox-vfx's shipped example sim/effects/explosion_crimson.json has no "brief" block (its builder,
build_explosion.py, predates the brief rule in references/DESIGN.md), so critic_gate.py stops at
"FAIL brief" and never runs its other checks. This writes a copy with a brief built ONLY from facts
the repo states: the phase table in build_explosion.py's docstring and the colours the builder uses.
It is an investigation aid; nothing here changes the effect itself.
"""
import json
import os
from pathlib import Path

SKILL = Path(os.environ.get("ROBLOX_VFX_SKILL", Path.home() / ".claude" / "skills" / "roblox-vfx")).expanduser()
OUT = Path(__file__).resolve().parent.parent / "library" / "effects" / "explosion_crimson.briefed.json"

BRIEF = {
    "name": "Crimson Detonation",
    "category": "explosion",
    "tier": "ultimate",
    "style": "anime_cel",
    "shape": "sky circles -> fireball dome -> mushroom",
    "dominant": "#c35673",  # crimson circles (build_explosion.py hexc)
    "accent": "#f2ea1e",  # yellow fireball core
    "darks": "#867671",  # grey-brown mushroom smoke
    "signature_beats": ["stacked circles scale in", "one-frame white flash", "held whiteout then cooling",
                        "mushroom rise with ember rain"],
    # build_explosion.py docstring, seconds: P0-P1 circles, P3 light point, P4 flash, P5 fireball,
    # P7-P8 whiteout/cooling, P9 burn, P10-P11 mushroom + ember rain
    "phases": [
        {"name": "anticipation", "t0": 0.0, "t1": 3.5},
        {"name": "release", "t0": 3.5, "t1": 3.52},
        {"name": "sustain", "t0": 3.52, "t1": 9.0},
        {"name": "residue", "t0": 9.0, "t1": 14.5},
    ],
}

if __name__ == "__main__":
    d = json.loads((SKILL / "sim" / "effects" / "explosion_crimson.json").read_text(encoding="utf-8"))
    d["brief"] = BRIEF
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(d) + "\n", encoding="utf-8")
    print("wrote", OUT)
