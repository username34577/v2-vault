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
local plotInfo = {} -- [plotIndex] = { CF, Top, Half, Model, Level, Decor }
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

	local half = S / 2 - M.FenceInset
	local function at(x, y, z)
		return plotCF * CFrame.new(x, top + y, z)
	end

	-- Monster stage: a chunky round wooden bed with a cream top and sunny studs round the rim.
	local mz = M.MonsterZ
	local SD, SH = M.StageDiameter, M.StageHeight
	Build.cylinder(SD + 2, SH * 0.6, P.WoodDark, at(0, SH * 0.3, mz), model, SOLID_SHADOW)
	Build.cylinder(SD, SH, P.Wood, at(0, SH / 2 + 0.05, mz), model, SOLID)
	Build.cylinder(SD - 2.6, 0.3, P.Cream, at(0, SH + 0.15, mz), model, SOLID)
	Build.cylinder(SD - 1.2, 0.2, P.Mint, at(0, SH + 0.08, mz), model)
	for k = 1, 12 do
		local a = k / 12 * TAU
		Build.ball(1.3, if k % 2 == 0 then P.Sunny else P.Bubblegum, at(math.cos(a) * (SD / 2 - 0.1), SH * 0.55, mz + math.sin(a) * (SD / 2 - 0.1)), model)
	end

	-- A stepping-stone path from the gate to the stage.
	for k = 0, 5 do
		local z = -half + 3 + k * 5
		Build.cylinder(3.6 - (k % 2) * 0.6, 0.25, P.Cream, at((k % 2 - 0.5) * 1.6, 0.12, z), model)
	end

	-- Food crate beside the player (the "pantry"; Snack Thief will raid it later).
	local cl = M.CrateLocal
	Props.crate(model, at(cl.X, 0, cl.Z) * CFrame.Angles(0, math.rad(-20), 0), 1)

	-- Flowers only at the BACK corners so nothing blocks the camera at spawn; low tufts at the front.
	for _, sx in { -1, 1 } do
		local ground = at(sx * (half - 5), 0, half - 5) * CFrame.Angles(0, rng:NextNumber() * TAU, 0)
		Props.flower(model, ground, 1.45, Props.PetalColors[((i + sx) % #Props.PetalColors) + 1])
		Props.tuft(model, ground * CFrame.new(3, 0, 1), 1.1, Props.PetalColors[((i + 2) % #Props.PetalColors) + 1])
		Props.tuft(model, at(sx * (half - 4), 0, -half + 4), 1, Props.PetalColors[((i + 3) % #Props.PetalColors) + 1])
		Props.rock(model, at(sx * (half - 14), 0, half - 4.5), 1.1, rng:NextNumber() * TAU)
	end
	for k = 1, 8 do
		local edgeX = if k % 2 == 0 then 1 else -1
		local z = rng:NextNumber(-half + 10, half - 10)
		local x = edgeX * rng:NextNumber(half - 4, half - 2)
		Props.tuft(model, at(x, 0, z), 1, Props.PetalColors[(k % #Props.PetalColors) + 1])
	end

	-- Gate: an arch over the opening with the owner's name (both sides), and two doors swung open.
	local gate = M.GateWidth / 2
	local archY = M.FenceHeight + 5.5
	for _, sx in { -1, 1 } do
		Build.cylinder(1.6, archY + 1, P.WoodDark, at(sx * (gate + 0.2), (archY + 1) / 2, -half), model, SOLID_SHADOW)
		-- door: a little picket panel hinged on the gate post, swung 70 degrees inward
		local hinge = at(sx * gate, 0, -half) * CFrame.Angles(0, sx * math.rad(70), 0)
		local doorW = gate - 1
		for p = 0, 3 do
			local px = -sx * (0.9 + p * (doorW - 1) / 3)
			Build.block(Vector3.new(0.9, 3.4, 0.5), P.WoodLight, hinge * CFrame.new(px, 1.9, 0), model)
			Build.ball(0.9, P.WoodLight, hinge * CFrame.new(px, 3.6, 0), model)
		end
		for _, h in { 1.2, 2.8 } do
			Build.block(Vector3.new(doorW, 0.5, 0.4), P.Wood, hinge * CFrame.new(-sx * doorW / 2, h, 0), model)
		end
	end
	local arch = Build.block(Vector3.new(M.GateWidth + 3, 4.2, 0.8), P.Wood, at(0, archY, -half), model, SOLID_SHADOW)
	arch.Name = "Sign"
	Build.block(Vector3.new(M.GateWidth + 5, 0.9, 1.4), P.WoodDark, at(0, archY + 2.5, -half), model)
	for _, sx in { -1, 1 } do
		Build.ball(2.2, P.Sunny, at(sx * (gate + 2.2), archY + 3.1, -half), model)
	end

	-- Owner sign in the back-left corner, turned to face the player's spot.
	local signPos = Vector3.new(-(half - 7), 0, half - 9)
	local facing = Vector3.new(0, 0, mz - Config.MinScale * Config.MonsterRadius - M.SpawnGap)
	local signCF = plotCF * CFrame.lookAt(signPos, Vector3.new(facing.X, 0, facing.Z)) * CFrame.new(0, top, 0)
	for _, sx in { -4.2, 4.2 } do
		Build.cylinder(1, 11, P.WoodDark, signCF * CFrame.new(sx, 5.5, 0.2), model, SOLID_SHADOW)
	end
	local board = Build.block(Vector3.new(12, 5, 0.7), P.Wood, signCF * CFrame.new(0, 8.6, 0), model, SOLID_SHADOW)
	board.Name = "Sign"
	Build.block(Vector3.new(12.8, 0.7, 1), P.WoodDark, signCF * CFrame.new(0, 11.4, 0), model)
	signs[i] = { signGui(arch, Enum.NormalId.Front), signGui(arch, Enum.NormalId.Back), signGui(board, Enum.NormalId.Front) }

	plotInfo[i] = { CF = plotCF, Top = top, Half = half, Model = model, Level = 0 }

	local monsterPos = plotCF:PointToWorldSpace(Vector3.new(0, 0, mz)) + Vector3.new(0, top + SH + 0.3, 0)
	local toHub = plotCF:PointToWorldSpace(Vector3.new(0, 0, -S))
	local ground = CFrame.lookAt(monsterPos, Vector3.new(toHub.X, monsterPos.Y, toHub.Z))
	-- Furthest the player can stand in front of the monster and still be inside the fence.
	local reach = mz - M.SpawnMinZ
	return ground, reach
end

---------------------------------------------------------------------------
-- Plot decor that grows with the monster (Config.PlotDecor)
---------------------------------------------------------------------------
local decorBuilders = {}

function decorBuilders.Flowerbeds(info, parent)
	local h = info.Half
	for _, sx in { -1, 1 } do
		local x = sx * (h - 3.5)
		Build.block(Vector3.new(4, 0.7, 30), Build.lerp(P.WoodDark, P.Wood, 0.2), info.CF * CFrame.new(x, info.Top + 0.3, -6), parent)
		for k = 0, 9 do
			local z = -20 + k * 3.1
			Props.tuft(parent, info.CF * CFrame.new(x + (k % 2 - 0.5) * 1.6, info.Top + 0.6, z), 1.15, Props.PetalColors[(k % #Props.PetalColors) + 1])
		end
	end
end

function decorBuilders.Lanterns(info, parent)
	for _, spot in { Vector3.new(-6, 0, -27), Vector3.new(6, 0, -27), Vector3.new(-16, 0, -6), Vector3.new(16, 0, -6) } do
		Props.lantern(parent, info.CF * CFrame.new(spot + Vector3.new(0, info.Top, 0)), 1)
	end
end

function decorBuilders.Bunting(info, parent)
	local h = info.Half
	local colors = { P.Bubblegum, P.Sunny, P.Mint, P.Sky, P.Lilac }
	local runs = {
		{ Vector3.new(-h, 0, -h), Vector3.new(-M.GateWidth / 2, 0, -h) },
		{ Vector3.new(M.GateWidth / 2, 0, -h), Vector3.new(h, 0, -h) },
		{ Vector3.new(-h, 0, -h), Vector3.new(-h, 0, h) },
		{ Vector3.new(h, 0, -h), Vector3.new(h, 0, h) },
	}
	for r, run in runs do
		local a, b = run[1], run[2]
		local n = math.floor((b - a).Magnitude / 2.6)
		for k = 1, n - 1 do
			local p = a:Lerp(b, k / n)
			local sag = math.sin(k / n * math.pi) * 0.9
			local cf = info.CF * CFrame.lookAt(p, p + (b - a).Unit:Cross(Vector3.yAxis))
			Build.block(Vector3.new(1.3, 1.3, 0.15), colors[(k + r) % #colors + 1], cf * CFrame.new(0, info.Top + M.FenceHeight + 1.2 - sag, 0) * CFrame.Angles(0, 0, math.rad(45)), parent)
		end
	end
end

function decorBuilders.Trees(info, parent)
	for _, sx in { -1, 1 } do
		Props.tree(parent, info.CF * CFrame.new(sx * (info.Half - 7), info.Top, -14), 0.75)
	end
end

function decorBuilders.Statue(info, parent)
	local base = info.CF * CFrame.new(info.Half - 8, info.Top, -info.Half + 8) * CFrame.Angles(0, math.rad(200), 0)
	Build.cylinder(5.5, 2, P.RockLight, base * CFrame.new(0, 1, 0), parent, SOLID)
	Build.cylinder(6.2, 0.6, P.Rock, base * CFrame.new(0, 0.3, 0), parent)
	local gold = { Material = Enum.Material.Metal, Reflectance = 0.15 }
	Build.ellipsoid(Vector3.new(4.6, 4, 4.2), P.Sunny, base * CFrame.new(0, 4, 0), parent, gold)
	for _, ex in { -0.9, 0.9 } do
		Build.ball(1.2, P.TextLight, base * CFrame.new(ex, 4.6, -1.9), parent)
	end
	Props.crown(parent, base * CFrame.new(0, 5.8, 0), 0.32)
end

function decorBuilders.Rainbow(info, parent)
	local bands = { P.Coral, P.Tangerine, P.Sunny, P.Grass, P.Sky, P.Lilac }
	local radius = info.Half - 3
	local center = info.CF * CFrame.new(0, info.Top, info.Half - 1.5)
	for b, color in bands do
		local r = radius - (b - 1) * 1.6
		local steps = 28
		for k = 0, steps - 1 do
			local a0 = k / steps * math.pi
			local a1 = (k + 1) / steps * math.pi
			local p0 = Vector3.new(math.cos(a0) * r, math.sin(a0) * r, 0)
			local p1 = Vector3.new(math.cos(a1) * r, math.sin(a1) * r, 0)
			local mid = (p0 + p1) / 2
			local cf = CFrame.lookAt(mid, mid + Vector3.zAxis, (p1 - p0).Unit)
			Build.block(Vector3.new(1.7, (p1 - p0).Magnitude + 0.15, 0.8), color, center * cf, parent)
		end
	end
	for _, sx in { -1, 1 } do
		for k = 0, 2 do
			Build.ball(4.5 - k * 0.6, P.Cloud, center * CFrame.new(sx * (radius - 4) + k * 1.8 * sx, 1.3, (k - 1) * 1.4), parent)
		end
	end
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

-- Builds everything. Returns plotGround[i] (monster spot, looking toward the gate) and
-- plotReach[i] (furthest studs in front of the monster the player may stand).
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
	local plotGround, plotReach = {}, {}
	for i = 1, Config.PlotCount do
		plotGround[i], plotReach[i] = buildPlot(i, plots, rng)
		World.setPlotOwner(i, nil)
	end
	map.Parent = workspace
	plots.Parent = workspace
	return plotGround, plotReach
end

-- How many Config.PlotDecor tiers a monster of this size has unlocked.
function World.decorLevelFor(size: number): number
	local level = 0
	for k, tier in Config.PlotDecor do
		if size >= tier.Size then
			level = k
		end
	end
	return level
end

-- Builds (or clears, with level 0) the decor tiers on a plot. Returns true if new tiers appeared.
function World.setPlotLevel(index: number, level: number): boolean
	local info = plotInfo[index]
	if not info or info.Level == level then
		return false
	end
	if level < info.Level then
		if info.Decor then
			info.Decor:Destroy()
			info.Decor = nil
		end
		info.Level = 0
	end
	if not info.Decor then
		info.Decor = Build.model("Decor", info.Model)
	end
	local grew = level > info.Level
	for k = info.Level + 1, level do
		local tier = Config.PlotDecor[k]
		local builder = tier and decorBuilders[tier.Id]
		if builder then
			local tierModel = Instance.new("Model")
			tierModel.Name = tier.Id
			builder(info, tierModel)
			tierModel.Parent = info.Decor
		end
	end
	info.Level = level
	return grew
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
