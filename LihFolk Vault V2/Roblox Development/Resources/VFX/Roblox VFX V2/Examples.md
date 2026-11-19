---
tags: [resources, vfx, tool, examples, luau, roblox-vfx, type/guide, area/vfx, level/intermediate]
source: https://github.com/1nird/roblox-vfx-v2
researched: 2026-11-19
---
# Examples

<!-- tldr:start -->
> [!tldr] TL;DR
> - A hand-authored 3-layer impact (white-hot core, sparks, light pulse) using only stock textures the verifier knows exist.
> - `VFXKit.build` needs a BasePart to hang on.
> - local VFXKit = require(ReplicatedStorage:WaitForChild("VFXKit"))
> - After `node sim/studio_kit.js sim/effects/eclipse_rend.json out`, put `out/eclipse_rend.luau` in Studio as a ModuleScript...
>
> Cost: TL;DR ~130 tok · whole note ~3.5k tok. Read more: ## 1. A recipe that passes the verifier · ## 7. Server decides, every client renders
<!-- tldr:end -->

Part of [[Roblox VFX V2]]. Previous: [[Roblox VFX V2/API Reference|API Reference]] · Next: [[Roblox VFX V2/Integration|Integration]]

Every call below uses the API exactly as it exists in the repo ([[Roblox VFX V2/API Reference|API Reference]]). Recipe and kit names such as `DemoSparkBurst` and `EclipseRend` are examples: use names from **your** emitted `VFXKit` or your exported kits.

**Status:** the recipe in example 1 passed `verify_vfx.py` and `emit_luau.py` built a `VFXKit` from it (2026-11-19, cloud). The Luau examples were syntax-checked only. **None has run in Studio yet.**

## 1. A recipe that passes the verifier

A hand-authored 3-layer impact (white-hot core, sparks, light pulse) using only stock textures the verifier knows exist. Save it as `<your library>/recipes/DemoSparkBurst.json`, then:

```bash
python scripts/verify_vfx.py --lib "<your library>/recipes"     # 1 clean, 0 failure(s), 0 warning(s)
python scripts/emit_luau.py --lib "<your library>/recipes" VFXKit.lua
```

```json
{
 "name": "DemoSparkBurst",
 "duration": 0.8,
 "texture_portable": true,
 "texture_refs": [
  "rbxasset://textures/particles/fire_main.dds",
  "rbxasset://textures/particles/sparkles_main.dds"
 ],
 "layers": [
  {
   "name": "Core",
   "class": "ParticleEmitter",
   "offset": [
    0,
    0,
    0
   ],
   "emit": {
    "mode": "burst",
    "count": 4
   },
   "props": {
    "Acceleration": {
     "Vector3": [
      0,
      0,
      0
     ]
    },
    "Brightness": 1,
    "Color": {
     "ColorSequence": [
      [
       0,
       [
        1,
        0.95,
        0.75
       ]
      ],
      [
       1,
       [
        1,
        0.5,
        0.15
       ]
      ]
     ]
    },
    "Drag": 0,
    "EmissionDirection": {
     "Enum": "NormalId.Top"
    },
    "Enabled": true,
    "FlipbookFramerate": {
     "NumberRange": [
      1,
      1
     ]
    },
    "FlipbookLayout": {
     "Enum": "ParticleFlipbookLayout.None"
    },
    "FlipbookMode": {
     "Enum": "ParticleFlipbookMode.Loop"
    },
    "FlipbookStartRandom": false,
    "Lifetime": {
     "NumberRange": [
      0.15,
      0.25
     ]
    },
    "LightEmission": 1,
    "LightInfluence": 0,
    "LockedToPart": false,
    "Orientation": {
     "Enum": "ParticleOrientation.FacingCamera"
    },
    "Rate": 0,
    "RotSpeed": {
     "NumberRange": [
      -90,
      90
     ]
    },
    "Rotation": {
     "NumberRange": [
      0,
      360
     ]
    },
    "Shape": {
     "Enum": "ParticleEmitterShape.Box"
    },
    "ShapeInOut": {
     "Enum": "ParticleEmitterShapeInOut.Outward"
    },
    "ShapeStyle": {
     "Enum": "ParticleEmitterShapeStyle.Volume"
    },
    "Size": {
     "NumberSequence": [
      [
       0,
       1.5,
       0
      ],
      [
       0.2,
       3,
       0
      ],
      [
       1,
       0.5,
       0
      ]
     ]
    },
    "SpreadAngle": {
     "Vector2": [
      180,
      180
     ]
    },
    "Speed": {
     "NumberRange": [
      0,
      1
     ]
    },
    "Squash": {
     "NumberSequence": [
      [
       0,
       0,
       0
      ],
      [
       1,
       0,
       0
      ]
     ]
    },
    "Texture": "rbxasset://textures/particles/fire_main.dds",
    "TimeScale": 1,
    "Transparency": {
     "NumberSequence": [
      [
       0,
       0,
       0
      ],
      [
       0.6,
       0.4,
       0
      ],
      [
       1,
       1,
       0
      ]
     ]
    },
    "VelocityInheritance": 0,
    "ZOffset": 1,
    "WindAffectsDrag": false
   }
  },
  {
   "name": "Sparks",
   "class": "ParticleEmitter",
   "offset": [
    0,
    0,
    0
   ],
   "emit": {
    "mode": "burst",
    "count": 24
   },
   "props": {
    "Acceleration": {
     "Vector3": [
      0,
      -30,
      0
     ]
    },
    "Brightness": 1,
    "Color": {
     "ColorSequence": [
      [
       0,
       [
        1,
        0.9,
        0.4
       ]
      ],
      [
       1,
       [
        1,
        0.45,
        0.1
       ]
      ]
     ]
    },
    "Drag": 3,
    "EmissionDirection": {
     "Enum": "NormalId.Top"
    },
    "Enabled": true,
    "FlipbookFramerate": {
     "NumberRange": [
      1,
      1
     ]
    },
    "FlipbookLayout": {
     "Enum": "ParticleFlipbookLayout.None"
    },
    "FlipbookMode": {
     "Enum": "ParticleFlipbookMode.Loop"
    },
    "FlipbookStartRandom": false,
    "Lifetime": {
     "NumberRange": [
      0.3,
      0.6
     ]
    },
    "LightEmission": 1,
    "LightInfluence": 0,
    "LockedToPart": false,
    "Orientation": {
     "Enum": "ParticleOrientation.FacingCamera"
    },
    "Rate": 0,
    "RotSpeed": {
     "NumberRange": [
      -90,
      90
     ]
    },
    "Rotation": {
     "NumberRange": [
      0,
      360
     ]
    },
    "Shape": {
     "Enum": "ParticleEmitterShape.Box"
    },
    "ShapeInOut": {
     "Enum": "ParticleEmitterShapeInOut.Outward"
    },
    "ShapeStyle": {
     "Enum": "ParticleEmitterShapeStyle.Volume"
    },
    "Size": {
     "NumberSequence": [
      [
       0,
       0.6,
       0
      ],
      [
       1,
       0,
       0
      ]
     ]
    },
    "SpreadAngle": {
     "Vector2": [
      180,
      180
     ]
    },
    "Speed": {
     "NumberRange": [
      12,
      20
     ]
    },
    "Squash": {
     "NumberSequence": [
      [
       0,
       0,
       0
      ],
      [
       1,
       0,
       0
      ]
     ]
    },
    "Texture": "rbxasset://textures/particles/sparkles_main.dds",
    "TimeScale": 1,
    "Transparency": {
     "NumberSequence": [
      [
       0,
       0,
       0
      ],
      [
       1,
       1,
       0
      ]
     ]
    },
    "VelocityInheritance": 0,
    "ZOffset": 0,
    "WindAffectsDrag": false
   }
  },
  {
   "name": "Flash",
   "class": "PointLight",
   "offset": [
    0,
    0,
    0
   ],
   "emit": {
    "mode": "pulse",
    "from": 6,
    "seconds": 0.25
   },
   "props": {
    "Brightness": 0,
    "Color": {
     "Color3": [
      1,
      0.8,
      0.4
     ]
    },
    "Enabled": true,
    "Range": 10,
    "Shadows": false
   }
  }
 ]
}
```

Why all 31 properties are listed: `verify_vfx.py` fails any ParticleEmitter layer that is missing one. That is how it catches recipes read through Studio's generic property reader, which sees only 6 of them.

## 2. One-shot impact at a position (VFXKit, LocalScript)

`VFXKit.build` needs a **BasePart** to hang on. For a hit point in the world, use a small invisible anchored part and clean it up afterwards.

```lua
-- StarterPlayerScripts/ImpactFx.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local VFXKit = require(ReplicatedStorage:WaitForChild("VFXKit"))

local function playImpactAt(position: Vector3, power: number)
	local host = Instance.new("Part")
	host.Name = "ImpactHost"
	host.Anchored = true
	host.CanCollide = false
	host.CanQuery = false
	host.CanTouch = false
	host.Transparency = 1
	host.Size = Vector3.new(0.2, 0.2, 0.2)
	host.CFrame = CFrame.new(position)
	host.Parent = workspace

	local fx = VFXKit.build("DemoSparkBurst", host, { scale = 1 })
	fx.emit(power) -- multiplies burst counts and the light's peak
	-- the recipe's duration is 0.8 s; leave room for the longest particle
	Debris:AddItem(host, 1.5)
end

playImpactAt(Vector3.new(0, 5, 0), 1)
```

## 3. A looping aura on your character (VFXKit)

```lua
-- StarterCharacterScripts/AuraFx.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VFXKit = require(ReplicatedStorage:WaitForChild("VFXKit"))

local character = script.Parent
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

-- "MyAura" must be a recipe with continuous layers in YOUR kit
local aura = VFXKit.build("MyAura", root, {
	tint = Color3.fromRGB(120, 200, 255), -- keeps the bright-core-to-dark-tail ramp
	rate_mul = 0.7,
})
aura.setEnabled(true)

humanoid.Died:Connect(function()
	aura.setEnabled(false)
	task.delay(1, aura.destroy)
end)
```

## 4. Building a Studio kit's template (command bar, Edit mode)

After `node sim/studio_kit.js sim/effects/eclipse_rend.json out`, put `out/eclipse_rend.luau` in Studio as a ModuleScript named `EclipseRend` under `ReplicatedStorage.VFX`. Upload every texture listed in `eclipse_rend.assets.json` (as Images) and note each id. Then run this once in the **command bar**:

```lua
-- Command bar, Edit mode. Prints what the kit needs, then builds its template.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local vfxFolder = ReplicatedStorage:WaitForChild("VFX")
local Kit = require(vfxFolder:WaitForChild("EclipseRend"))

for _, id in Kit.NEEDS.textures do
	print("needs texture", id)
end

local assets = {
	textures = {
		-- one line per id printed above; 0 is a placeholder for YOUR uploaded Image id
		["sim:eclipse_paint"] = "rbxassetid://0",
		["sim:slash_paint_4x4"] = "rbxassetid://0",
	},
	meshes = {}, -- this kit needs none; others need the MESH id, not the model id
}

local templates = vfxFolder:FindFirstChild("Templates")
if not templates then
	templates = Instance.new("Folder")
	templates.Name = "Templates"
	templates.Parent = vfxFolder
end
local old = templates:FindFirstChild(Kit.NAME)
if old then
	old:Destroy()
end
Kit.buildTemplate(assets, templates)
print("built", Kit.NAME, "property failures:", Kit.PROP_FAILS)
```

A missing texture id warns `[EclipseRend] missing texture sim:...` and leaves that slot blank, so fill every id before you save the place.

## 5. Playing a kit at runtime (LocalScript)

```lua
-- StarterPlayerScripts/MoveFx.client.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vfxFolder = ReplicatedStorage:WaitForChild("VFX")
local Kit = require(vfxFolder:WaitForChild("EclipseRend"))
local template = vfxFolder:WaitForChild("Templates"):WaitForChild(Kit.NAME)

local failed = Kit.preload(template) -- at join, before the first play (yields)
if failed > 0 then
	warn(Kit.NAME, "assets that failed to preload:", failed)
end

local function playMove(origin: CFrame, caster: Model?, target: Model?)
	-- screen = false: no camera takeover, no screen grade (right for normal gameplay)
	local h = Kit.spawn(origin, template, { screen = false, game = true })
	h.caster = caster
	h.target = target
	Kit.play(h) -- returns at once; cleans itself up DURATION + 1 s later
end

local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart") :: BasePart
playMove(root.CFrame * CFrame.new(0, -3, 0), character, nil)
```

`origin` is the effect's floor point: the sim authors effects around a caster standing at the origin, so pass the floor under the caster, facing the way the move should go.

## 6. Cinematic ultimate with the camera, then give the camera back

`M.play` takes the camera (`Scriptable`) when the effect defines one and does not restore it. For an ultimate where you want the kit's camera:

```lua
local function playUltimate(Kit, template, origin: CFrame, caster: Model)
	local camera = workspace.CurrentCamera
	local previousFov = camera.FieldOfView
	local h = Kit.spawn(origin, template) -- screen pieces on
	h.caster = caster
	Kit.play(h)
	task.delay(Kit.DURATION, function()
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = previousFov
	end)
end
```

## 7. Server decides, every client renders

Effects are visuals, so build them on clients. The server only says *which* effect and *where*, after validating the action. For the full pattern (caster prediction, range checks, rate limits) see [[Replicating VFX - Server Validates, Clients Render]].

```lua
-- ServerScriptService/MoveFx.luau (ModuleScript): your server ability code calls broadcastFx after validating
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playFx = Instance.new("RemoteEvent")
playFx.Name = "PlayFx"
playFx.Parent = ReplicatedStorage

local ALLOWED = { DemoSparkBurst = true }

local function broadcastFx(effectName: string, position: Vector3, power: number)
	if not ALLOWED[effectName] then
		return
	end
	playFx:FireAllClients(effectName, position, math.clamp(power, 0.5, 2))
end

return broadcastFx
```

```lua
-- StarterPlayerScripts/FxListener.client.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local VFXKit = require(ReplicatedStorage:WaitForChild("VFXKit"))
local playFx = ReplicatedStorage:WaitForChild("PlayFx")

playFx.OnClientEvent:Connect(function(effectName, position, power)
	if type(effectName) ~= "string" or typeof(position) ~= "Vector3" or not VFXKit.Recipes[effectName] then
		return
	end
	local host = Instance.new("Part")
	host.Anchored = true
	host.CanCollide = false
	host.CanQuery = false
	host.CanTouch = false
	host.Transparency = 1
	host.Size = Vector3.new(0.2, 0.2, 0.2)
	host.CFrame = CFrame.new(position)
	host.Parent = workspace
	VFXKit.build(effectName, host).emit(tonumber(power) or 1)
	Debris:AddItem(host, 2)
end)
```

## 8. Curate a few harvested recipes into a game, then emit

From the repo's own `curate.py` help (the names after `=` come from your library):

```bash
python scripts/curate.py --lib "<lib>" --out "<game>/vfx/recipes" \
  --pick "SplashHit=WaterBurst|ToonLiquidAlpha,ToonLiquidColor" \
  --pick "PopBurst=Burst_4|Realistic*0.6"
python scripts/emit_luau.py --lib "<game>/vfx/recipes" "<game>/src/shared/VFXKit.luau"
```

Then call `VFXKit.build("SplashHit", part)` in the game: the game calls an effect by its role, not by its pack name.

Continue with [[Roblox VFX V2/Integration|Integration]].
