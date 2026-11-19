-- Chunky cartoon props built from parts. Used by the server map and by client-only decor.
-- Every builder takes a ground CFrame (the point where the prop touches the ground) and a scale.
local Config = require(script.Parent.Config)
local Build = require(script.Parent.Build)

local P = Config.Palette
local Props = {}

local PETALS = { P.Bubblegum, P.Sky, P.Lilac, P.Peach, P.Mint }
Props.PetalColors = PETALS

-- Giant flower: stem, leaf, sunny center, five petals.
function Props.flower(parent, ground: CFrame, s: number, petalColor: Color3?)
	local m = Build.model("Flower", parent)
	local height = 4.2 * s
	Build.cylinder(0.7 * s, height, P.GrassShade, ground * CFrame.new(0, height / 2, 0), m)
	Build.ellipsoid(
		Vector3.new(2.4, 0.45, 1.1) * s,
		P.Grass,
		ground * CFrame.new(0.9 * s, height * 0.4, 0) * CFrame.Angles(0, 0, math.rad(28)),
		m
	)
	local head = ground * CFrame.new(0, height, 0) * CFrame.Angles(math.rad(-14), 0, 0)
	Build.ball(1.9 * s, P.Sunny, head, m)
	local color = petalColor or PETALS[1]
	for k = 1, 5 do
		local a = (k - 1) / 5 * math.pi * 2
		Build.ellipsoid(
			Vector3.new(1.5, 0.5, 2.3) * s,
			color,
			head * CFrame.Angles(0, a, 0) * CFrame.new(0, -0.1 * s, -1.55 * s) * CFrame.Angles(math.rad(12), 0, 0),
			m
		)
	end
	return m
end

-- Tiny flower for scattering: stem + head.
function Props.tuft(parent, ground: CFrame, s: number, color: Color3)
	local m = Build.model("Tuft", parent)
	Build.cylinder(0.35 * s, 1.4 * s, P.GrassShade, ground * CFrame.new(0, 0.7 * s, 0), m)
	Build.ball(0.9 * s, color, ground * CFrame.new(0, 1.5 * s, 0), m)
	return m
end

-- Round chunky tree with pink fruit and a contact-shadow disc.
function Props.tree(parent, ground: CFrame, s: number)
	local m = Build.model("Tree", parent)
	local shadow = Build.lerp(P.GrassShade, P.Outline, 0.25)
	Build.cylinder(7 * s, 0.12, shadow, ground * CFrame.new(0, 0.07, 0), m)
	Build.cylinder(2.6 * s, 9 * s, P.WoodDark, ground * CFrame.new(0, 4.5 * s, 0), m, { CastShadow = true, CanCollide = true })
	local leafA = P.GrassShade
	local leafB = Build.lerp(P.GrassShade, P.Grass, 0.45)
	local blobs = {
		{ 11, Vector3.new(0, 10, 0), leafA },
		{ 8, Vector3.new(3.6, 8.6, 1), leafB },
		{ 7.5, Vector3.new(-3.3, 9, -1.4), leafB },
		{ 6.2, Vector3.new(0.4, 14.2, 0.3), leafB },
	}
	for _, b in blobs do
		Build.ball(b[1] * s, b[3], ground * CFrame.new(b[2] * s), m, { CastShadow = true })
	end
	for _, f in { Vector3.new(3.4, 11.5, -3.2), Vector3.new(-4.6, 8.2, 2.2), Vector3.new(1.2, 7.2, 4.6) } do
		Build.ball(1.5 * s, P.Bubblegum, ground * CFrame.new(f * s), m)
	end
	return m
end

function Props.bush(parent, ground: CFrame, s: number, dotColor: Color3?)
	local m = Build.model("Bush", parent)
	local c = Build.lerp(P.GrassShade, P.Grass, 0.2)
	Build.ball(5 * s, c, ground * CFrame.new(0, 1.9 * s, 0), m)
	Build.ball(4 * s, P.GrassShade, ground * CFrame.new(2.3 * s, 1.5 * s, 0.5 * s), m)
	Build.ball(3.6 * s, Build.lerp(P.GrassShade, P.Grass, 0.4), ground * CFrame.new(-2.2 * s, 1.4 * s, -0.4 * s), m)
	local dot = dotColor or P.Bubblegum
	Build.ball(0.9 * s, dot, ground * CFrame.new(0.6 * s, 4.2 * s, -1.2 * s), m)
	Build.ball(0.8 * s, P.Sunny, ground * CFrame.new(-1.6 * s, 3 * s, -1.5 * s), m)
	return m
end

function Props.rock(parent, ground: CFrame, s: number, yaw: number)
	local m = Build.model("Rock", parent)
	local base = ground * CFrame.Angles(0, yaw, 0)
	Build.ellipsoid(Vector3.new(5, 3.4, 4.4) * s, P.Rock, base * CFrame.new(0, 1.2 * s, 0) * CFrame.Angles(0, 0, 0.12), m)
	Build.ellipsoid(Vector3.new(3, 1.2, 2.6) * s, P.RockLight, base * CFrame.new(-0.4 * s, 2.5 * s, -0.2 * s), m)
	Build.ellipsoid(Vector3.new(2.4, 1.8, 2.2) * s, P.RockLight, base * CFrame.new(3 * s, 0.7 * s, 1 * s), m)
	return m
end

-- Crown: gold band, five ball points, pink gems. Used on the leaderboard and on big monsters.
function Props.crown(parent, base: CFrame, s: number, glowingGems: boolean?)
	local m = Build.model("Crown", parent)
	Build.cylinder(8 * s, 2.6 * s, P.Sunny, base * CFrame.new(0, 1.3 * s, 0), m)
	Build.cylinder(8.6 * s, 0.7 * s, Build.lerp(P.Sunny, P.Peach, 0.5), base * CFrame.new(0, 0.35 * s, 0), m)
	for k = 1, 5 do
		local a = (k - 1) / 5 * math.pi * 2
		local spot = base * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -3.4 * s)
		Build.ellipsoid(Vector3.new(1.6, 3, 1.6) * s, P.Sunny, spot * CFrame.new(0, 3.2 * s, 0), m)
		Build.ball(1.3 * s, P.Sunny, spot * CFrame.new(0, 4.9 * s, 0), m)
		Build.ball(1 * s, P.Bubblegum, spot * CFrame.new(0, 1.3 * s, -0.75 * s), m, {
			Material = if glowingGems then Enum.Material.Neon else Enum.Material.SmoothPlastic,
		})
	end
	return m
end

return Props
