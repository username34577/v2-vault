-- Toy-like food built from parts, about 2.4 studs across (exaggerated so it reads at a glance).
-- Used for thrown food and for the shop's 3D icons. Each builder returns a Model centred on 0,0,0.
local Config = require(script.Parent.Config)
local Build = require(script.Parent.Build)

local P = Config.Palette
local C = Config.FoodColors
local SHINE = Color3.fromRGB(255, 250, 245)

local FoodModels = {}
local builders = {}

local E = Build.ellipsoid

function builders.Apple(m)
	E(Vector3.new(2.15, 1.95, 2.15), C.AppleSkin, CFrame.new(0, 0, 0), m)
	E(Vector3.new(0.7, 0.25, 0.7), C.AppleDimple, CFrame.new(0, 0.9, 0), m)
	Build.cylinder(0.2, 0.75, P.WoodDark, CFrame.new(0.05, 1.18, 0) * CFrame.Angles(0, 0, -0.25), m)
	E(Vector3.new(0.95, 0.14, 0.5), P.Grass, CFrame.new(0.45, 1.3, 0) * CFrame.Angles(0, 0.3, -0.4), m)
	E(Vector3.new(0.5, 0.32, 0.16), SHINE, CFrame.new(-0.55, 0.45, -0.88) * CFrame.Angles(0, 0.5, 0.4), m, { Transparency = 0.15 })
end

function builders.Burger(m)
	E(Vector3.new(2.5, 0.75, 2.5), C.Bun, CFrame.new(0, -0.75, 0), m)
	Build.cylinder(2.6, 0.55, C.Patty, CFrame.new(0, -0.3, 0), m)
	Build.block(Vector3.new(2.3, 0.12, 2.3), C.Cheese, CFrame.new(0, 0.02, 0) * CFrame.Angles(0, math.rad(45), 0), m)
	Build.cylinder(2.75, 0.16, P.Grass, CFrame.new(0, 0.12, 0), m)
	Build.cylinder(2.25, 0.2, C.Tomato, CFrame.new(0, 0.27, 0), m)
	E(Vector3.new(2.6, 1.6, 2.6), C.BunTop, CFrame.new(0, 0.62, 0), m)
	for k = 1, 6 do
		local a = k / 6 * math.pi * 2
		local r = if k % 2 == 0 then 0.55 else 0.85
		E(Vector3.new(0.26, 0.12, 0.14), P.Cream, CFrame.new(math.cos(a) * r, 0.62 + 0.8 * math.sqrt(1 - (r / 1.3) ^ 2) + 0.02, math.sin(a) * r) * CFrame.Angles(0, a, 0.3), m)
	end
end

function builders.Cake(m)
	Build.cylinder(2.4, 1.25, C.Sponge, CFrame.new(0, -0.35, 0), m)
	Build.cylinder(2.25, 0.18, C.Frosting, CFrame.new(0, -0.3, 0), m) -- cream layer peeking out
	Build.cylinder(2.55, 0.32, C.Frosting, CFrame.new(0, 0.42, 0), m)
	for k = 1, 7 do
		local a = k / 7 * math.pi * 2
		E(Vector3.new(0.42, 0.75, 0.42), C.Frosting, CFrame.new(math.cos(a) * 1.18, 0.18, math.sin(a) * 1.18), m)
	end
	local sprinkles = { P.Sky, P.Sunny, P.Mint, P.Lilac }
	for k = 1, 8 do
		local a = k / 8 * math.pi * 2 + 0.3
		local r = if k % 2 == 0 then 0.55 else 0.95
		Build.block(Vector3.new(0.3, 0.1, 0.1), sprinkles[(k % 4) + 1], CFrame.new(math.cos(a) * r, 0.6, math.sin(a) * r) * CFrame.Angles(0, a * 2, 0), m)
	end
	Build.ball(0.7, C.Cherry, CFrame.new(0, 0.95, 0), m)
	Build.cylinder(0.08, 0.5, P.GrassShade, CFrame.new(0.1, 1.42, 0) * CFrame.Angles(0, 0, -0.3), m)
	E(Vector3.new(0.18, 0.12, 0.1), SHINE, CFrame.new(-0.15, 1.12, -0.25), m)
end

-- Pizza slice: two mirrored wedges make an isosceles triangle, tip pointing +X.
local function slice(m, length, halfWidth, thickness, color, y)
	local rot = CFrame.fromMatrix(Vector3.zero, Vector3.yAxis, Vector3.xAxis) -- wedge X = up, Y = along the slice
	Build.wedge(Vector3.new(thickness, length, halfWidth), color, CFrame.new(0, y, halfWidth / 2) * rot, m)
	Build.wedge(Vector3.new(thickness, length, halfWidth), color, CFrame.new(0, y, -halfWidth / 2) * CFrame.Angles(math.pi, 0, 0) * rot, m)
end

function builders.Pizza(m)
	slice(m, 2.8, 1.2, 0.28, C.Dough, -0.05)
	slice(m, 2.45, 1.02, 0.16, C.Cheese, 0.12)
	Build.cylinderX(2.6, 0.6, C.Dough:Lerp(P.WoodLight, 0.35), CFrame.new(-1.38, 0.08, 0) * CFrame.Angles(0, math.pi / 2, 0), m)
	for _, p in { Vector3.new(-0.55, 0, -0.42), Vector3.new(-0.5, 0, 0.45), Vector3.new(0.35, 0, 0.02) } do
		Build.cylinder(0.55, 0.08, C.Pepperoni, CFrame.new(p.X, 0.22, p.Z), m)
	end
	E(Vector3.new(0.3, 0.5, 0.3), C.Cheese, CFrame.new(1.05, -0.12, 0), m) -- cheese drip at the tip
end

function builders.GoldenSteak(m)
	E(Vector3.new(2.7, 0.7, 1.9), C.Gold, CFrame.new(0, 0, 0) * CFrame.Angles(0, 0.2, 0), m, { Reflectance = 0.12 })
	E(Vector3.new(2.85, 0.45, 2.05), C.GoldDark, CFrame.new(0, -0.12, 0) * CFrame.Angles(0, 0.2, 0), m)
	for k = -1, 1 do
		Build.block(Vector3.new(1.5, 0.08, 0.14), C.GoldDark, CFrame.new(k * 0.55, 0.36, k * 0.1) * CFrame.Angles(0, 0.7, 0), m)
	end
	-- bone sticking out of one end
	local bone = CFrame.new(1.45, 0.05, -0.25) * CFrame.Angles(0, 0.2, 0)
	Build.cylinderX(0.9, 0.32, C.Bone, bone, m)
	Build.ball(0.42, C.Bone, bone * CFrame.new(0.45, 0, 0.14), m)
	Build.ball(0.42, C.Bone, bone * CFrame.new(0.45, 0, -0.14), m)
	for _, p in { Vector3.new(-0.9, 0.8, -0.5), Vector3.new(0.5, 0.75, 0.7) } do
		Build.ball(0.22, P.Sunny, CFrame.new(p), m, { Material = Enum.Material.Neon })
	end
end

function builders.CosmicCandy(m)
	E(Vector3.new(1.9, 1.35, 1.35), C.Candy, CFrame.new(), m)
	for _, x in { -0.45, 0, 0.45 } do
		local d = 1.38 * math.sqrt(math.max(0.05, 1 - (x / 0.95) ^ 2)) + 0.03
		Build.cylinderX(0.16, d, C.CandyBand, CFrame.new(x, 0, 0), m, { Material = Enum.Material.Neon })
	end
	for _, side in { -1, 1 } do
		E(Vector3.new(0.55, 0.55, 0.55), C.Wrapper, CFrame.new(side * 1.05, 0, 0), m)
		E(Vector3.new(0.3, 1.45, 1.45), C.Wrapper:Lerp(P.Lilac, 0.25), CFrame.new(side * 1.38, 0, 0) * CFrame.Angles(side * 0.3, 0, 0), m)
	end
	for _, p in { Vector3.new(0.3, 0.95, 0.4), Vector3.new(-0.5, -0.85, 0.3), Vector3.new(0.6, 0.2, -0.95) } do
		Build.ball(0.2, P.TextLight, CFrame.new(p), m, { Material = Enum.Material.Neon })
	end
end

-- Build a food model. Unknown ids fall back to the starting food.
function FoodModels.build(foodId: string): Model
	local builder = builders[foodId] or builders[Config.StartingFood]
	local model = Instance.new("Model")
	model.Name = foodId
	builder(model)
	model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart")
	model.WorldPivot = CFrame.new()
	return model
end

return FoodModels
