-- Builds the floating island, the hub, the 8 plots and the lighting. Server-side, once, at startup.
-- Static, collidable things live here. Moving decoration (cloud sea, bobbing mini-islands) is
-- built on each client in Decor.luau so it costs no network traffic.
-- Vault: "Lighting Untextured Art in Roblox", "Atmosphere Sky Clouds and Post-Processing".
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(ReplicatedStorage.Shared.Build)
local Props = require(ReplicatedStorage.Shared.Props)
local Format = require(ReplicatedStorage.Shared.Format)

local P = Config.Palette
local M = Config.Map
local TAU = math.pi * 2

local World = {}

local signs = {} -- [plotIndex] = { { Name = TextLabel, Sub = TextLabel }, ... }
local boardFaces = {} -- list of { rows = { { Frame, Rank, Name, Size } } }

local SOLID = { CanCollide = true, CanQuery = true, CastShadow = false }
local SOLID_SHADOW = { CanCollide = true, CanQuery = true, CastShadow = true }

---------------------------------------------------------------------------
-- Lighting (one system owns Lighting: this function, run once)
---------------------------------------------------------------------------
local function applyLighting()
	local L = Config.Lighting
	for _, child in Lighting:GetChildren() do
		if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("PostEffect") then
			child:Destroy()
		end
	end

	Lighting.ClockTime = L.ClockTime
	Lighting.GeographicLatitude = L.GeographicLatitude
	Lighting.Brightness = L.Brightness
	Lighting.ExposureCompensation = L.ExposureCompensation
	Lighting.Ambient = L.Ambient
	Lighting.OutdoorAmbient = L.OutdoorAmbient
	Lighting.ColorShift_Top = L.ColorShift_Top
	Lighting.ColorShift_Bottom = L.ColorShift_Bottom
	Lighting.EnvironmentDiffuseScale = L.EnvironmentDiffuseScale
	Lighting.EnvironmentSpecularScale = L.EnvironmentSpecularScale
	Lighting.GlobalShadows = true
	-- LightingStyle replaces the deprecated Technology property. If a script can't set it,
	-- set Lighting > LightingStyle = Realistic by hand in Studio (see README).
	pcall(function()
		Lighting.LightingStyle = Enum.LightingStyle.Realistic
	end)
	pcall(function()
		Lighting.ShadowSoftness = L.ShadowSoftness
	end)

	local atmosphere = Instance.new("Atmosphere")
	for k, v in L.Atmosphere do
		atmosphere[k] = v
	end
	atmosphere.Parent = Lighting

	local sky = Instance.new("Sky") -- default Roblox sky textures, no asset ids
	sky.SunAngularSize = L.Sky.SunAngularSize
	sky.MoonAngularSize = L.Sky.MoonAngularSize
	sky.StarCount = L.Sky.StarCount
	sky.CelestialBodiesShown = true
	sky.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = L.Bloom.Intensity
	bloom.Size = L.Bloom.Size
	bloom.Threshold = L.Bloom.Threshold
	bloom.Parent = Lighting

	local grade = Instance.new("ColorCorrectionEffect")
	for k, v in L.ColorCorrection do
		grade[k] = v
	end
	grade.Parent = Lighting

	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = L.SunRays.Intensity
	rays.Spread = L.SunRays.Spread
	rays.Parent = Lighting

	local terrain = workspace.Terrain
	local old = terrain:FindFirstChildOfClass("Clouds")
	if old then
		old:Destroy()
	end
	local clouds = Instance.new("Clouds")
	clouds.Cover = L.Clouds.Cover
	clouds.Density = L.Clouds.Density
	clouds.Color = L.Clouds.Color
	clouds.Parent = terrain
	workspace.GlobalWind = L.Wind
end

---------------------------------------------------------------------------
-- Island
---------------------------------------------------------------------------
local function buildIsland(folder, rng)
	local R = M.IslandRadius
	Build.cylinder(R * 2, 4, P.Grass, CFrame.new(0, -2, 0), folder, { Name = "Ground", CanCollide = true, CanQuery = true })
	-- A darker lip one step down reads as a soft rounded edge from above.
	Build.cylinder(R * 2 + 5, 3, P.GrassShade, CFrame.new(0, -3.6, 0), folder, SOLID)
	Build.cylinder(R * 2 - 2, 10, P.WoodDark, CFrame.new(0, -9.9, 0), folder)

	-- Soft colour patches so the grass isn't one flat sheet (each a hair taller: no z-fighting).
	for k = 1, 30 do
		local a = rng:NextNumber() * TAU
		local r = math.sqrt(rng:NextNumber()) * (R - 20)
		local tint = if k % 2 == 0 then P.GrassShade else P.Sunny
		Build.cylinder(
			rng:NextNumber(14, 34),
			0.2 + k * 0.004,
			Build.lerp(P.Grass, tint, 0.16),
			CFrame.new(math.cos(a) * r, 0.05, math.sin(a) * r),
			folder
		)
	end

	-- Chunky tapered rock underside: stacked cylinders with lumpy balls round each rim.
	local layers = { { 0.97, 16 }, { 0.8, 18 }, { 0.6, 20 }, { 0.38, 20 }, { 0.17, 18 } }
	local y = -14.9
	for li, layer in layers do
		local r = R * layer[1]
		local h = layer[2]
		local color = if li % 2 == 1 then P.Rock else P.RockDark
		Build.cylinder(r * 2, h, color, CFrame.new(0, y - h / 2, 0), folder)
		local lumps = math.max(5, math.floor(r / 14))
		for k = 1, lumps do
			local a = (k + rng:NextNumber() * 0.6) / lumps * TAU
			Build.ball(
				h * rng:NextNumber(1.3, 1.9),
				Build.lerp(color, P.RockLight, rng:NextNumber(0, 0.35)),
				CFrame.new(math.cos(a) * r * 0.93, y - h * 0.55, math.sin(a) * r * 0.93),
				folder
			)
		end
		y -= h
	end
	Build.ball(R * 0.27, P.RockDark, CFrame.new(0, y - 4, 0), folder)

	-- Hanging roots and vines round the rim.
	for k = 1, M.Vines do
		local a = (k + rng:NextNumber() * 0.5) / M.Vines * TAU
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local len = rng:NextNumber(10, 26)
		local top = dir * (R - 0.6) + Vector3.new(0, -5.5, 0)
		local vineColor = if k % 3 == 0 then P.WoodDark else P.GrassShade
		Build.block(Vector3.new(0.7, len, 0.7), vineColor, CFrame.new(top - Vector3.new(0, len / 2, 0)), folder)
		local leaves = math.floor(len / 4)
		for j = 1, leaves do
			local side = if j % 2 == 0 then 1 else -1
			Build.ellipsoid(
				Vector3.new(1.7, 0.45, 1),
				if j % 2 == 0 then P.Grass else P.Mint,
				CFrame.lookAt(top, top + dir) * CFrame.new(side * 0.8, -j * 4 + 1, -0.3) * CFrame.Angles(0, 0, side * 0.5),
				folder
			)
		end
		if k % 3 == 1 then
			Build.ball(1.3, P.Bubblegum, CFrame.new(top - Vector3.new(0, len + 0.4, 0)), folder)
		end
	end
end

---------------------------------------------------------------------------
-- Hub: plaza, paths, spawn, leaderboard tower
---------------------------------------------------------------------------
local function boardFace(part, face)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0
	gui.Brightness = 1.1
	gui.Parent = part

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(0.9, 0.12)
	title.Position = UDim2.fromScale(0.05, 0.03)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = P.Sunny
	title.Text = "BIGGEST MONSTERS"
	title.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = P.Outline
	stroke.Thickness = 6
	stroke.Parent = title

	local rows = {}
	local rowH = 0.8 / Config.Leaderboard.Rows
	for r = 1, Config.Leaderboard.Rows do
		local row = Instance.new("Frame")
		row.Size = UDim2.fromScale(0.9, rowH * 0.86)
		row.Position = UDim2.fromScale(0.05, 0.17 + (r - 1) * rowH)
		row.BackgroundColor3 = P.UINavyLight
		row.Visible = false
		row.Parent = gui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.3, 0)
		corner.Parent = row

		local badge = Instance.new("TextLabel")
		badge.Size = UDim2.fromScale(0.14, 0.86)
		badge.Position = UDim2.fromScale(0.02, 0.07)
		badge.Font = Enum.Font.FredokaOne
		badge.TextScaled = true
		badge.TextColor3 = P.Outline
		badge.BackgroundColor3 = if r == 1 then P.Sunny elseif r == 2 then P.Silver elseif r == 3 then P.Bronze else P.Mint
		badge.Text = tostring(r)
		badge.Parent = row
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0.5, 0)
		bc.Parent = badge

		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Size = UDim2.fromScale(0.55, 0.8)
		name.Position = UDim2.fromScale(0.19, 0.1)
		name.Font = Enum.Font.FredokaOne
		name.TextScaled = true
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextColor3 = P.TextLight
		name.Parent = row

		local size = Instance.new("TextLabel")
		size.BackgroundTransparency = 1
		size.Size = UDim2.fromScale(0.24, 0.8)
		size.Position = UDim2.fromScale(0.74, 0.1)
		size.Font = Enum.Font.FredokaOne
		size.TextScaled = true
		size.TextXAlignment = Enum.TextXAlignment.Right
		size.TextColor3 = P.Mint
		size.Parent = row

		rows[r] = { Frame = row, Name = name, Size = size }
	end
	table.insert(boardFaces, { Rows = rows })
end

local function buildHub(folder, rng)
	local H = M.HubRadius
	Build.cylinder(H * 2 + 4, 0.5, P.Mint, CFrame.new(0, 0.2, 0), folder, SOLID)
	Build.cylinder(H * 2, 0.6, P.Cream, CFrame.new(0, 0.3, 0), folder, SOLID)
	for k = 1, 16 do
		local a = (k - 0.5) / 16 * TAU
		Build.cylinder(
			2.6,
			0.12,
			if k % 2 == 0 then P.Sunny else P.Peach,
			CFrame.new(math.cos(a) * (H - 4), 0.62, math.sin(a) * (H - 4)),
			folder
		)
	end

	-- Paths from the plaza to each plot's gate.
	local pathEnd = Config.PlotRingRadius - Config.PlotSize / 2 + 1
	local edge = Build.lerp(P.Cream, P.Peach, 0.45)
	for i = 1, Config.PlotCount do
		local a = (i - 1) / Config.PlotCount * TAU
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local from, to = H - 1, pathEnd
		local mid = dir * (from + to) / 2
		local cf = CFrame.lookAt(mid, mid + dir)
		Build.block(Vector3.new(M.PathWidth, 0.5, to - from), P.Cream, cf * CFrame.new(0, 0.25, 0), folder, SOLID)
		for _, side in { -1, 1 } do
			Build.block(Vector3.new(1.2, 0.5, to - from), edge, cf * CFrame.new(side * (M.PathWidth / 2 + 0.6), 0.2, 0), folder, SOLID)
		end
	end

	-- Spawn pad (round, sunny) in front of the tower.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Shape = Enum.PartType.Cylinder
	spawn.Size = Vector3.new(0.6, 12, 12)
	spawn.CFrame = CFrame.new(0, 0.5, H - 11) * CFrame.Angles(0, 0, math.pi / 2)
	spawn.Color = P.Sunny
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Parent = folder
	Build.cylinder(14, 0.4, P.Peach, CFrame.new(0, 0.45, H - 11), folder, SOLID)

	-- Leaderboard tower: navy board on four sides, wood frame, pink dome, gold crown.
	local W = Config.Leaderboard.BoardWidth
	local BH = Config.Leaderboard.BoardHeight
	local tower = Build.model("Leaderboard", folder)
	Build.cylinder(W * 1.5 + 6, 1, P.WoodDark, CFrame.new(0, 1.0, 0), tower, SOLID)
	Build.cylinder(W * 1.5 + 3, 2, P.Wood, CFrame.new(0, 1.6, 0), tower, SOLID)
	local baseY = 2.6
	local board = Build.block(Vector3.new(W, BH, W), P.UINavy, CFrame.new(0, baseY + BH / 2, 0), tower, SOLID_SHADOW)
	board.Name = "Board"
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
		boardFace(board, face)
	end
	for _, y in { baseY + 0.6, baseY + BH - 0.6 } do
		Build.block(Vector3.new(W + 2, 1.6, W + 2), P.Wood, CFrame.new(0, y, 0), tower)
	end
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local x, z = sx * W / 2, sz * W / 2
			Build.cylinder(3.2, BH + 2, P.Wood, CFrame.new(x, baseY + BH / 2, z), tower, SOLID_SHADOW)
			Build.ball(4.2, P.Sunny, CFrame.new(x, baseY + BH + 1.6, z), tower)
		end
	end
	local top = baseY + BH
	Build.ellipsoid(Vector3.new(W + 6, 14, W + 6), P.Bubblegum, CFrame.new(0, top + 1, 0), tower, { CastShadow = true })
	Props.crown(tower, CFrame.new(0, top + 7, 0), 1.6, true)

	-- Flower clusters round the plaza, between the paths.
	for i = 1, Config.PlotCount do
		local a = (i - 0.5) / Config.PlotCount * TAU
		local spot = Vector3.new(math.cos(a), 0, math.sin(a)) * (H + 8)
		local ground = CFrame.new(spot) * CFrame.Angles(0, rng:NextNumber() * TAU, 0)
		Props.flower(folder, ground, 1.35, Props.PetalColors[(i % #Props.PetalColors) + 1])
		Props.bush(folder, ground * CFrame.new(4, 0, 2), 0.9)
		Props.tuft(folder, ground * CFrame.new(-3, 0, 1.5), 1, P.Sky)
	end
end

---------------------------------------------------------------------------
-- Plots
---------------------------------------------------------------------------
local function signGui(board, face)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.3
	gui.Parent = board

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.92, 0.84)
	panel.BackgroundColor3 = P.Cream
	panel.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.18, 0)
	corner.Parent = panel

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.fromScale(0.9, 0.56)
	name.Position = UDim2.fromScale(0.05, 0.08)
	name.Font = Enum.Font.FredokaOne
	name.TextScaled = true
	name.TextColor3 = P.Outline
	name.Parent = panel

	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.Size = UDim2.fromScale(0.9, 0.28)
	sub.Position = UDim2.fromScale(0.05, 0.64)
	sub.Font = Enum.Font.FredokaOne
	sub.TextScaled = true
	sub.TextColor3 = P.WoodDark
	sub.Parent = panel
	return { Name = name, Sub = sub }
end

local function buildFence(model, plotCF, top)
	local half = Config.PlotSize / 2 - M.FenceInset
	local gate = M.GateWidth / 2
	local H = M.FenceHeight
	local corners = {
		Vector3.new(-half, 0, -half), -- front left (front faces the hub)
		Vector3.new(half, 0, -half), -- front right
		Vector3.new(half, 0, half), -- back right
		Vector3.new(-half, 0, half), -- back left
	}
	local function post(localPos, isGate)
		local h = if isGate then H + 1.5 else H
		local world = plotCF * CFrame.new(localPos.X, top + h / 2, localPos.Z)
		Build.cylinder(2.2, h, P.Wood, world, model, SOLID_SHADOW)
		Build.ball(if isGate then 3.4 else 2.7, if isGate then P.Sunny else P.WoodLight, world * CFrame.new(0, h / 2 + 0.4, 0), model)
	end
	local function rails(fromLocal, toLocal)
		local a = plotCF:PointToWorldSpace(fromLocal)
		local b = plotCF:PointToWorldSpace(toLocal)
		local dir = (b - a).Unit
		for _, h in { 1.6, 3.3 } do
			local mid = (a + b) / 2 + Vector3.new(0, top + h, 0)
			Build.cylinderX((b - a).Magnitude, 1.1, P.WoodLight, CFrame.fromMatrix(mid, dir, Vector3.yAxis), model, SOLID)
		end
	end
	for side = 1, 4 do
		local from = corners[side]
		local to = corners[side % 4 + 1]
		local n = math.max(1, math.floor((to - from).Magnitude / M.FencePostSpacing + 0.5))
		for k = 0, n - 1 do
			local p = from:Lerp(to, k / n)
			if not (side == 1 and math.abs(p.X) < gate + 3) then
				post(p, false)
			end
		end
		if side == 1 then
			post(Vector3.new(-gate, 0, -half), true)
			post(Vector3.new(gate, 0, -half), true)
			rails(from, Vector3.new(-gate, 0, -half))
			rails(Vector3.new(gate, 0, -half), to)
		else
			rails(from, to)
		end
	end
end

local function buildPlot(i, folder, rng)
	local S = Config.PlotSize
	local top = M.PlotTopY
	local angle = (i - 1) / Config.PlotCount * TAU
	local center = Vector3.new(math.cos(angle), 0, math.sin(angle)) * Config.PlotRingRadius
	local inward = -center.Unit
	local plotCF = CFrame.lookAt(center, center + inward) -- local -Z faces the hub
	local model = Build.model(`Plot{i}`, folder)

	-- Raised garden bed: soil rim + grass pad.
	Build.block(Vector3.new(S + 3, 0.8, S + 3), Build.lerp(P.WoodDark, P.Wood, 0.3), plotCF * CFrame.new(0, top - 0.7, 0), model, SOLID)
	local pad = Build.block(Vector3.new(S, 1, S), Build.lerp(P.Grass, P.GrassShade, 0.22), plotCF * CFrame.new(0, top - 0.5, 0), model, SOLID)
	pad.Name = "Pad"

	buildFence(model, plotCF, top)

	-- Feeding spot under the monster and a throw mat where the player stands.
	local monsterLocal = Vector3.new(0, 0, S * 0.15)
	local spawnLocal = Vector3.new(0, 0, -S * 0.38)
	local d = M.FeedingPadDiameter
	Build.cylinder(d + 2.4, 0.2, P.Mint, plotCF * CFrame.new(monsterLocal + Vector3.new(0, top + 0.1, 0)), model)
	Build.cylinder(d, 0.3, P.Cream, plotCF * CFrame.new(monsterLocal + Vector3.new(0, top + 0.15, 0)), model)
	Build.cylinder(8, 0.25, P.Peach, plotCF * CFrame.new(spawnLocal + Vector3.new(0, top + 0.12, 0)), model)
	Build.cylinder(6.2, 0.3, P.Cream, plotCF * CFrame.new(spawnLocal + Vector3.new(0, top + 0.15, 0)), model)

	-- Giant flowers in the corners, rocks at the back, tufts along the edges.
	local half = S / 2 - M.FenceInset
	local inset = half - 5
	local corners = { Vector3.new(-inset, 0, -inset), Vector3.new(inset, 0, -inset), Vector3.new(inset, 0, inset), Vector3.new(-inset, 0, inset) }
	for k, c in corners do
		local ground = plotCF * CFrame.new(c + Vector3.new(0, top, 0)) * CFrame.Angles(0, rng:NextNumber() * TAU, 0)
		Props.flower(model, ground, 1.45, Props.PetalColors[((i + k) % #Props.PetalColors) + 1])
		Props.tuft(model, ground * CFrame.new(3, 0, 1), 1.1, Props.PetalColors[((i + k + 2) % #Props.PetalColors) + 1])
	end
	for _, sx in { -1, 1 } do
		Props.rock(model, plotCF * CFrame.new(sx * (half - 13), top, half - 4.5), 1.1, rng:NextNumber() * TAU)
	end
	for k = 1, 8 do
		local edgeX = if k % 2 == 0 then 1 else -1
		local z = rng:NextNumber(-half + 10, half - 10)
		local x = edgeX * rng:NextNumber(half - 4, half - 2)
		Props.tuft(model, plotCF * CFrame.new(x, top, z), 1, Props.PetalColors[(k % #Props.PetalColors) + 1])
	end

	-- Owner sign outside the gate, readable from the path and from inside the plot.
	local signX = -(M.GateWidth / 2 + 7)
	local signZ = -half - 4
	for _, sx in { -3.8, 3.8 } do
		Build.cylinder(0.9, 7.4, P.WoodDark, plotCF * CFrame.new(signX + sx, 3.7, signZ), model, SOLID_SHADOW)
	end
	local board = Build.block(Vector3.new(11, 4.6, 0.7), P.Wood, plotCF * CFrame.new(signX, 5.4, signZ), model, SOLID_SHADOW)
	board.Name = "Sign"
	Build.block(Vector3.new(11.8, 0.7, 1), P.WoodDark, plotCF * CFrame.new(signX, 7.9, signZ), model)
	signs[i] = { signGui(board, Enum.NormalId.Front), signGui(board, Enum.NormalId.Back) }

	local monsterPos = plotCF:PointToWorldSpace(monsterLocal) + Vector3.new(0, top + 0.3, 0)
	local spawnPos = plotCF:PointToWorldSpace(spawnLocal) + Vector3.new(0, top + 3, 0)
	local ground = CFrame.lookAt(monsterPos, Vector3.new(spawnPos.X, monsterPos.Y, spawnPos.Z))
	local spawnCF = CFrame.lookAt(spawnPos, Vector3.new(monsterPos.X, spawnPos.Y, monsterPos.Z))
	return ground, spawnCF
end

---------------------------------------------------------------------------
-- Scenery between plots and round the rim
---------------------------------------------------------------------------
local function buildScenery(folder, rng)
	local R = M.IslandRadius
	for i = 1, M.TreeCount do
		local a = (i - 0.5) / M.TreeCount * TAU
		local spot = Vector3.new(math.cos(a), 0, math.sin(a)) * 160
		local ground = CFrame.new(spot) * CFrame.Angles(0, rng:NextNumber() * TAU, 0)
		Props.tree(folder, ground, 1.45)
		Props.bush(folder, ground * CFrame.new(0, 0, 11), 1)
		-- inner ring between hub and plots
		local inner = Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(66, 88)
		local innerCF = CFrame.new(inner) * CFrame.Angles(0, rng:NextNumber() * TAU, 0)
		Props.flower(folder, innerCF, 1.2, Props.PetalColors[(i % #Props.PetalColors) + 1])
		Props.rock(folder, innerCF * CFrame.new(5, 0, 3), 0.8, rng:NextNumber() * TAU)
		Props.tuft(folder, innerCF * CFrame.new(-3, 0, -2), 1, P.Sunny)
	end
	for k = 1, M.RimBushes do
		local a = (k + rng:NextNumber() * 0.6) / M.RimBushes * TAU
		local spot = Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(R - 14, R - 7)
		Props.bush(folder, CFrame.new(spot) * CFrame.Angles(0, rng:NextNumber() * TAU, 0), rng:NextNumber(0.9, 1.3))
	end
	for k = 1, M.RimFlowers do
		local a = (k + 0.5 + rng:NextNumber() * 0.4) / M.RimFlowers * TAU
		local spot = Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(R - 22, R - 6)
		local ground = CFrame.new(spot) * CFrame.Angles(0, rng:NextNumber() * TAU, 0)
		if k % 4 == 0 then
			Props.rock(folder, ground, rng:NextNumber(0.9, 1.4), rng:NextNumber() * TAU)
		else
			Props.flower(folder, ground, rng:NextNumber(1, 1.5), Props.PetalColors[(k % #Props.PetalColors) + 1])
		end
	end
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

-- Builds everything. Returns plotGround[i] (monster spot) and plotSpawn[i] (player spot).
function World.build()
	-- The Baseplate template's floor and spawn would poke through the island.
	for _, name in { "Baseplate", "SpawnLocation" } do
		local old = workspace:FindFirstChild(name)
		if old and old:IsA("BasePart") then
			old:Destroy()
		end
	end
	applyLighting()

	local rng = Random.new(M.Seed)
	local map = Instance.new("Folder")
	map.Name = "Map"
	buildIsland(map, rng)
	buildHub(map, rng)
	buildScenery(map, rng)

	local plots = Instance.new("Folder")
	plots.Name = "Plots"
	local plotGround, plotSpawn = {}, {}
	for i = 1, Config.PlotCount do
		plotGround[i], plotSpawn[i] = buildPlot(i, plots, rng)
		World.setPlotOwner(i, nil)
	end
	map.Parent = workspace
	plots.Parent = workspace
	return plotGround, plotSpawn
end

function World.setPlotOwner(index: number, player: Player?)
	for _, sign in signs[index] or {} do
		if player then
			sign.Name.Text = player.DisplayName
			sign.Sub.Text = "'s monster"
		else
			sign.Name.Text = "Free plot"
			sign.Sub.Text = "waiting for a keeper"
		end
	end
end

-- entries: sorted list of { Name = string, Size = number }
function World.setLeaderboard(entries)
	for _, face in boardFaces do
		for r, row in face.Rows do
			local entry = entries[r]
			row.Frame.Visible = entry ~= nil
			if entry then
				row.Name.Text = entry.Name
				row.Size.Text = Format.short(entry.Size)
			end
		end
	end
end

return World
