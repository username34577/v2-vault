"""Author the lab's VFXKit recipes (roblox-vfx recipe format) from one place.

    python tools/author_recipes.py            # writes library/recipes/*.json

Why a script: roblox-vfx's verify_vfx.py fails any ParticleEmitter layer that does not list all
31 properties, so hand-written JSON drifts. Every layer here starts from DEFAULTS (Roblox's own
defaults for a new ParticleEmitter) and overrides only what the look needs.

Stock textures only (the five rbxasset paths roblox-vfx measured as rendering): nothing to
upload, nothing to moderate, works in any place. Budgets are for 10 players on phones:
see library/README.md and the Quality presets in src/shared/VFX/Quality.luau.
"""
import json
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "library" / "recipes"

SPARKLES = "rbxasset://textures/particles/sparkles_main.dds"  # soft 8-point star
FIRE = "rbxasset://textures/particles/fire_main.dds"  # noisy flame
SMOKE = "rbxasset://textures/particles/smoke_main.dds"  # soft round puff
CLOUD = "rbxasset://textures/explosion.png"  # puffy lit cloud
STAR = "rbxasset://textures/sparkle.png"  # hard 8-point star, dark rim


def hexc(h):
    h = h.lstrip("#")
    return [round(int(h[i:i + 2], 16) / 255, 4) for i in (0, 2, 4)]


def NR(a, b=None):
    return {"NumberRange": [a, a if b is None else b]}


def NS(*k):
    return {"NumberSequence": [[t, v, e] for t, v, e in ((p + (0,))[:3] for p in k)]}


def CS(*k):
    return {"ColorSequence": [[t, hexc(c)] for t, c in k]}


def V3(x, y, z):
    return {"Vector3": [x, y, z]}


def E(name):
    return {"Enum": name}


DEFAULTS = {
    "Acceleration": V3(0, 0, 0), "Brightness": 1, "Color": CS((0, "#ffffff"), (1, "#ffffff")), "Drag": 0,
    "EmissionDirection": E("NormalId.Top"), "Enabled": True,
    "FlipbookFramerate": NR(1), "FlipbookLayout": E("ParticleFlipbookLayout.None"),
    "FlipbookMode": E("ParticleFlipbookMode.Loop"), "FlipbookStartRandom": False,
    "Lifetime": NR(1), "LightEmission": 0, "LightInfluence": 0, "LockedToPart": False,
    "Orientation": E("ParticleOrientation.FacingCamera"), "Rate": 0, "RotSpeed": NR(0), "Rotation": NR(0),
    "Shape": E("ParticleEmitterShape.Box"), "ShapeInOut": E("ParticleEmitterShapeInOut.Outward"),
    "ShapeStyle": E("ParticleEmitterShapeStyle.Volume"), "Size": NS((0, 1), (1, 1)),
    "SpreadAngle": {"Vector2": [0, 0]}, "Speed": NR(5), "Squash": NS((0, 0), (1, 0)), "Texture": SPARKLES,
    "TimeScale": 1, "Transparency": NS((0, 0), (1, 0)), "VelocityInheritance": 0, "ZOffset": 0,
    "WindAffectsDrag": False,
}


def pe(name, emit, **props):
    p = json.loads(json.dumps(DEFAULTS))
    p.update(props)
    return {"name": name, "class": "ParticleEmitter", "offset": [0, 0, 0], "emit": emit, "props": p}


def light(name, emit, color, rng, brightness=0):
    return {"name": name, "class": "PointLight", "offset": [0, 0, 0], "emit": emit,
            "props": {"Brightness": brightness, "Color": {"Color3": hexc(color)}, "Enabled": True,
                      "Range": rng, "Shadows": False}}


def recipe(name, duration, layers, note):
    refs = sorted({L["props"]["Texture"] for L in layers if L["class"] == "ParticleEmitter"})
    return {"name": name, "note": note, "duration": duration, "texture_portable": True,
            "texture_refs": refs, "layers": layers}


# Palette: sun gold (dominant), hot white core, ember orange, sky-blue accent for the win.
GOLD, WHITE_HOT, EMBER, SKY = "#ffc83d", "#fff6d8", "#ff8a2a", "#7cd4ff"

RECIPES = [
    # 1. Carrier aura: continuous, cheap (16 live particles steady, measured in the sim), readable in dark hiding spots.
    recipe("SunAura", 1.0, [
        pe("Corona", {"mode": "continuous"},
           Texture=SMOKE, Rate=8, Lifetime=NR(0.7, 0.9), Speed=NR(0.4, 1),
           SpreadAngle={"Vector2": [180, 180]},
           Size=NS((0, 3), (0.5, 3.8), (1, 4.2)),
           Transparency=NS((0, 1), (0.2, 0.45), (0.7, 0.6), (1, 1)),
           Color=CS((0, WHITE_HOT), (0.4, GOLD), (1, EMBER)),
           # ZOffset > 0 draws the glow in front of the carrier (wrapped in light); 0.45+ transparency
           # keeps the character readable through it
           LightEmission=0.8, LockedToPart=True, ZOffset=1.5, Rotation=NR(0, 360), RotSpeed=NR(-30, 30)),
        pe("Motes", {"mode": "continuous"},
           Texture=SPARKLES, Rate=14, Lifetime=NR(0.6, 0.9), Speed=NR(4, 6), Drag=2,
           SpreadAngle={"Vector2": [180, 180]}, Acceleration=V3(0, 4, 0),
           Size=NS((0, 0.55), (1, 0)), Transparency=NS((0, 0), (0.7, 0.2), (1, 1)),
           Color=CS((0, WHITE_HOT), (1, GOLD)), LightEmission=1),
        light("Glow", {"mode": "constant"}, GOLD, 14, brightness=1.6),
    ], "Snatch the Sun: glow around the sun carrier. Continuous; build on the carrier's HumanoidRootPart."),

    # 2. Steal / drop burst: one flash frame, a puff, a spray of sparks, one light pulse (25 particles at peak, measured).
    recipe("SunBurst", 1.0, [
        pe("Flash", {"mode": "burst", "count": 1},
           Texture=STAR, Lifetime=NR(0.12, 0.15), Speed=NR(0),
           Size=NS((0, 3), (1, 6)), Transparency=NS((0, 0), (1, 1)),
           Color=CS((0, WHITE_HOT), (1, GOLD)), LightEmission=1, ZOffset=2, Rotation=NR(0, 45)),
        pe("Puff", {"mode": "burst", "count": 4},
           Texture=CLOUD, Lifetime=NR(0.35, 0.5), Speed=NR(2, 4), Drag=3,
           SpreadAngle={"Vector2": [180, 180]},
           Size=NS((0, 2), (0.4, 4), (1, 4.6)), Transparency=NS((0, 0), (0.6, 0.35), (1, 1)),
           Color=CS((0, WHITE_HOT), (0.35, GOLD), (1, EMBER)), LightEmission=0.4,
           Rotation=NR(0, 360), RotSpeed=NR(-60, 60)),
        pe("Sparks", {"mode": "burst", "count": 20},
           Texture=SPARKLES, Lifetime=NR(0.4, 0.7), Speed=NR(18, 28), Drag=4,
           SpreadAngle={"Vector2": [180, 180]}, Acceleration=V3(0, -20, 0),
           Size=NS((0, 0.8), (1, 0)), Transparency=NS((0, 0), (0.8, 0.3), (1, 1)),
           Color=CS((0, WHITE_HOT), (0.5, GOLD), (1, EMBER)), LightEmission=1),
        light("Pulse", {"mode": "pulse", "from": 5, "seconds": 0.25}, GOLD, 14),
    ], "Snatch the Sun: the sun is stolen or knocked loose. Burst; build at the sun's position."),

    # 3. Round winner: gold fountain + sky-blue accent + star pops + soft dome puff (56 particles at peak, once per round).
    recipe("SunVictory", 1.6, [
        pe("Fountain", {"mode": "burst", "count": 30},
           Texture=SPARKLES, Lifetime=NR(0.9, 1.2), Speed=NR(16, 22), Drag=1.5,
           SpreadAngle={"Vector2": [30, 30]}, Acceleration=V3(0, -40, 0),
           Size=NS((0, 0.6), (1, 0.25)), Transparency=NS((0, 0), (0.75, 0.2), (1, 1)),
           Color=CS((0, WHITE_HOT), (0.3, GOLD), (1, EMBER)), LightEmission=1),
        pe("Confetti", {"mode": "burst", "count": 12},
           Texture=SPARKLES, Lifetime=NR(0.9, 1.2), Speed=NR(13, 19), Drag=1.5,
           SpreadAngle={"Vector2": [40, 40]}, Acceleration=V3(0, -35, 0),
           Size=NS((0, 0.55), (1, 0.2)), Transparency=NS((0, 0), (0.8, 0.25), (1, 1)),
           Color=CS((0, "#ffffff"), (1, SKY)), LightEmission=1),
        pe("Stars", {"mode": "burst", "count": 6},
           Texture=STAR, Lifetime=NR(0.4, 0.6), Speed=NR(6, 10), SpreadAngle={"Vector2": [180, 180]},
           Size=NS((0, 0.8), (0.3, 1.3), (1, 0)), Transparency=NS((0, 0), (1, 0.6)),
           Color=CS((0, WHITE_HOT), (1, GOLD)), LightEmission=1, Rotation=NR(0, 360), RotSpeed=NR(-180, 180)),
        pe("Dome", {"mode": "burst", "count": 8},
           Texture=SMOKE, Lifetime=NR(0.5, 0.7), Speed=NR(10, 12), Drag=4,
           SpreadAngle={"Vector2": [90, 90]},
           Size=NS((0, 1.6), (1, 3.2)), Transparency=NS((0, 0.15), (1, 1)),
           Color=CS((0, "#fff1d6"), (1, GOLD)), LightEmission=0.3),
        light("Pulse", {"mode": "pulse", "from": 4, "seconds": 0.4}, GOLD, 16),
    ], "Snatch the Sun: round winner celebration. Burst; build at the winner's feet."),
]

if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for r in RECIPES:
        (OUT / f"{r['name']}.json").write_text(json.dumps(r, indent=1) + "\n", encoding="utf-8")
        print("wrote", r["name"])
