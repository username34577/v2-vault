-- Client-only decoration: the sea of puffy clouds below the island and the small floating
-- islands around it. Pure scenery: no collisions, nothing replicated, animated locally.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(ReplicatedStorage.Shared.Build)
local Props = require(ReplicatedStorage.Shared.Props)

local P = Config.Palette
local M = Config.Map
local TAU = math.pi * 2

local Decor = {}

-- Groups of parts that move together: { Parts, Offsets, Update(t) -> CFrame }
local groups = {}

local function collect(model, base: CFrame)
	local parts, offsets = {}, {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
			table.insert(offsets, base:ToObjectSpace(d.CFrame))
		end
	end
	return parts, offsets
end

local function buildCloudSea(folder, rng)
	local wind = Vector3.new(Config.Lighting.Wind.X, 0, Config.Lighting.Wind.Z).Unit
	local R = M.CloudSeaRadius
	for k = 1, M.CloudPuffs do
		local a = rng:NextNumber() * TAU
		local r = math.sqrt(rng:NextNumber()) * R
		local start = Vector3.new(math.cos(a) * r, M.CloudSeaY + rng:NextNumber(-8, 8), math.sin(a) * r)
		local tint = if k % 3 == 0 then P.Bubblegum else P.Lilac
		local color = P.Cloud:Lerp(tint, rng:NextNumber(0.03, 0.1))
		local size = Vector3.new(rng:NextNumber(60, 120), rng:NextNumber(18, 30), rng:NextNumber(50, 100))
		local model = Build.model("Puff", folder)
		local base = CFrame.new(start) * CFrame.Angles(0, rng:NextNumber() * TAU, 0)
		Build.ellipsoid(size, color, base, model)
		-- two bumps on top make it chunky instead of a flat pancake
		for b = 1, 2 do
			local bump = size * Vector3.new(rng:NextNumber(0.4, 0.55), rng:NextNumber(1.1, 1.5), rng:NextNumber(0.4, 0.55))
			local off = Vector3.new((b - 1.5) * size.X * 0.35, size.Y * 0.3, rng:NextNumber(-0.15, 0.15) * size.Z)
			Build.ellipsoid(bump, P.Cloud:Lerp(P.CloudShade, rng:NextNumber(0, 0.5)), base * CFrame.new(off), model)
		end
		local parts, offsets = collect(model, base)
		local speed = rng:NextNumber(M.CloudDriftSpeed[1], M.CloudDriftSpeed[2])
		local rotation = base - base.Position
		table.insert(groups, {
			Parts = parts,
			Offsets = offsets,
			Update = function(t)
				-- drift with the wind and wrap round so the sea never empties
				local along = start:Dot(wind) + t * speed
				local wrapped = ((along + R) % (2 * R)) - R
				local pos = start + wind * (wrapped - start:Dot(wind))
				return CFrame.new(pos) * rotation
			end,
		})
	end
end

local function buildMiniIsland(folder, rng, k)
	local d = rng:NextNumber(22, 36)
	local model = Build.model("MiniIsland", folder)
	local base = CFrame.new()
	Build.cylinder(d, 2, P.Grass, base * CFrame.new(0, -1, 0), model)
	Build.cylinder(d + 2, 1.5, P.GrassShade, base * CFrame.new(0, -2.2, 0), model)
	Build.cylinder(d - 1, 4, P.WoodDark, base * CFrame.new(0, -4.5, 0), model)
	local y = -6.5
	for li, layer in { { 0.8, 6 }, { 0.5, 6 }, { 0.25, 5 } } do
		local r = d / 2 * layer[1]
		local h = layer[2]
		local color = if li % 2 == 1 then P.Rock else P.RockDark
		Build.cylinder(r * 2, h, color, base * CFrame.new(0, y - h / 2, 0), model)
		for j = 1, 4 do
			local a = (j + rng:NextNumber() * 0.5) / 4 * TAU
			Build.ball(h * 1.5, color:Lerp(P.RockLight, 0.2), base * CFrame.new(math.cos(a) * r * 0.85, y - h * 0.5, math.sin(a) * r * 0.85), model)
		end
		y -= h
	end
	Build.ball(d * 0.18, P.RockDark, base * CFrame.new(0, y - 1, 0), model)
	if k % 2 == 1 then
		Props.tree(model, base, 0.85)
	else
		Props.flower(model, base, 1.5, Props.PetalColors[(k % #Props.PetalColors) + 1])
		Props.tuft(model, base * CFrame.new(3, 0, 2), 1.2, P.Sunny)
		Props.rock(model, base * CFrame.new(-5, 0, -3), 0.7, rng:NextNumber() * TAU)
	end

	local a = (k - 0.5) / M.MiniIslands * TAU + rng:NextNumber(-0.3, 0.3)
	local r = rng:NextNumber(M.MiniIslandRadius[1], M.MiniIslandRadius[2])
	local home = Vector3.new(math.cos(a) * r, rng:NextNumber(-25, 12), math.sin(a) * r)
	local period = rng:NextNumber(M.BobPeriod[1], M.BobPeriod[2])
	local phase = rng:NextNumber() * TAU
	local spin = rng:NextNumber(-0.04, 0.04)
	local parts, offsets = collect(model, base)
	table.insert(groups, {
		Parts = parts,
		Offsets = offsets,
		Update = function(t)
			local bob = math.sin(t / period * TAU + phase) * M.BobAmplitude
			local tilt = math.sin(t / period * TAU * 0.5 + phase) * 0.03
			return CFrame.new(home + Vector3.new(0, bob, 0)) * CFrame.Angles(tilt, phase + t * spin, 0)
		end,
	})
end

function Decor.start()
	local rng = Random.new(M.Seed + 1)
	local folder = Instance.new("Folder")
	folder.Name = "ClientDecor"
	buildCloudSea(folder, rng)
	for k = 1, M.MiniIslands do
		buildMiniIsland(folder, rng, k)
	end
	folder.Parent = workspace

	local allParts = {}
	for _, g in groups do
		for _, p in g.Parts do
			table.insert(allParts, p)
		end
	end
	local cframes = table.create(#allParts)
	RunService.Heartbeat:Connect(function()
		local t = os.clock()
		local n = 0
		for _, g in groups do
			local cf = g.Update(t)
			for i, off in g.Offsets do
				n += 1
				cframes[n] = cf * off
			end
		end
		workspace:BulkMoveTo(allParts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end)
end

return Decor
