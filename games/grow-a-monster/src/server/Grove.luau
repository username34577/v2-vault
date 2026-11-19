-- The Snack Grove: a fenced garden island where goofy snack plants grow, guarded by the Grumpy Gardener.
-- Server-authoritative: plant cooldowns, what each player carries, the Gardener's sight and the catch.
-- Players only use ProximityPrompts (range-checked here); nothing else comes from the client.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(ReplicatedStorage.Shared.Build)
local Props = require(ReplicatedStorage.Shared.Props)
local FoodModels = require(ReplicatedStorage.Shared.FoodModels)

local G = Config.Grove
local P = Config.Palette
local TAU = math.pi * 2

local Grove = {}

local groveCF -- local frame: origin = grove centre at ground level, -Z points back to the main island
local plants = {} -- { Def, Model, Fruit = {parts}, Prompt, ReadyAt }
local carry = {} -- [player] = { snackId, ... }
local carryVisual = {} -- [player] = { Model, ... }
local seenSince = {} -- [player] = os.clock() when the Gardener first saw them (this sighting)
local callbacks = {}
local gardener -- { Model, Humanoid, Root, Alert (BillboardGui) }

local SOLID = { CanCollide = true, CanQuery = true }

local function at(x, y, z)
	return groveCF * CFrame.new(x, y, z)
end

---------------------------------------------------------------------------
-- Building
---------------------------------------------------------------------------
local function buildIsland(folder)
	local R = G.Radius
	Build.cylinder(R * 2, 4, P.Grass, at(0, -2, 0), folder, SOLID)
	Build.cylinder(R * 2 + 5, 3, P.GrassShade, at(0, -3.6, 0), folder, SOLID)
	Build.cylinder(R * 2 - 2, 10, P.WoodDark, at(0, -9.9, 0), folder)
	local y = -14.9
	for li, layer in { { 0.92, 14 }, { 0.65, 16 }, { 0.36, 16 } } do
		local r = R * layer[1]
		local color = if li % 2 == 1 then P.Rock else P.RockDark
		Build.cylinder(r * 2, layer[2], color, at(0, y - layer[2] / 2, 0), folder)
		for k = 1, math.max(5, math.floor(r / 12)) do
			local a = k / math.max(5, math.floor(r / 12)) * TAU
			Build.ball(layer[2] * 1.5, Build.lerp(color, P.RockLight, (k % 3) * 0.12), at(math.cos(a) * r * 0.93, y - layer[2] * 0.55, math.sin(a) * r * 0.93), folder)
		end
		y -= layer[2]
	end
	-- warm path ring so the patrol route reads from above
	for k = 1, 28 do
		local a = k / 28 * TAU
		Build.cylinder(4.2, 0.2, Build.lerp(P.Cream, P.Peach, 0.25), at(math.cos(a) * 36, 0.1, 18 + math.sin(a) * 22), folder)
	end
end

local function buildBridge(folder, mainEdge: Vector3, groveEdge: Vector3)
	local dir = (groveEdge - mainEdge) * Vector3.new(1, 0, 1)
	local len = dir.Magnitude
	local cf = CFrame.lookAt(mainEdge, mainEdge + dir)
	local W = G.BridgeWidth
	local planks = math.floor(len / 2.2)
	for k = 0, planks - 1 do
		local z = -(k + 0.5) * len / planks
		Build.block(Vector3.new(W, 0.8, len / planks - 0.25), if k % 2 == 0 then P.Wood else P.WoodLight, cf * CFrame.new(0, -0.4, z), folder, SOLID)
	end
	for _, sx in { -1, 1 } do
		Build.block(Vector3.new(0.8, 1, len), P.WoodDark, cf * CFrame.new(sx * (W / 2 + 0.2), -0.6, -len / 2), folder, SOLID)
		for k = 0, 4 do
			local z = -k * len / 4
			Build.cylinder(1.1, 4.4, P.WoodDark, cf * CFrame.new(sx * (W / 2 + 0.2), 1.6, z), folder, SOLID)
			Build.ball(1.4, P.Sunny, cf * CFrame.new(sx * (W / 2 + 0.2), 4, z), folder)
		end
		-- rope rail (also an invisible wall so nobody falls off by accident)
		Build.cylinderX(len, 0.35, P.Cream, cf * CFrame.new(sx * (W / 2 + 0.2), 3.2, -len / 2) * CFrame.Angles(0, math.pi / 2, 0), folder)
		Build.block(Vector3.new(0.4, 6, len), P.Cream, cf * CFrame.new(sx * (W / 2 + 0.6), 3, -len / 2), folder, { CanCollide = true, Transparency = 1 })
	end
end

local function buildFence(folder)
	local R = G.Radius - 3
	local gateHalf = math.rad(9) -- gap either side of -Z
	local posts = 56
	for k = 0, posts - 1 do
		local a = k / posts * TAU
		local off = (a - (math.pi * 1.5) + math.pi) % TAU - math.pi -- -Z is angle 270 deg in local XZ
		if math.abs(off) > gateHalf then
			local p = at(math.cos(a) * R, 0, math.sin(a) * R)
			Build.cylinder(1.8, 4.2, P.Wood, p * CFrame.new(0, 2.1, 0), folder, SOLID)
			Build.ball(2.2, P.WoodLight, p * CFrame.new(0, 4.5, 0), folder)
			local a2 = (k + 1) / posts * TAU
			local off2 = (a2 - (math.pi * 1.5) + math.pi) % TAU - math.pi
			if math.abs(off2) > gateHalf then
				local q = at(math.cos(a2) * R, 0, math.sin(a2) * R)
				local mid = (p.Position + q.Position) / 2
				local d = (q.Position - p.Position)
				for _, h in { 1.5, 3.1 } do
					Build.cylinderX(d.Magnitude, 0.9, P.WoodLight, CFrame.fromMatrix(mid + Vector3.new(0, h, 0), d.Unit, Vector3.yAxis), folder, SOLID)
				end
			end
		end
	end
	-- Gate arch with the zone name
	local gx = math.sin(gateHalf) * R
	for _, sx in { -1, 1 } do
		Build.cylinder(2, 11, P.WoodDark, at(sx * gx, 5.5, -R), folder, SOLID)
		Build.ball(2.8, P.Bubblegum, at(sx * gx, 11.4, -R), folder)
	end
	local sign = Build.block(Vector3.new(gx * 2 + 4, 4, 0.8), P.Wood, at(0, 9.6, -R), folder, SOLID)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 30
		gui.LightInfluence = 0.2
		gui.Parent = sign
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextColor3 = P.Sunny
		t.Text = if face == Enum.NormalId.Front then "SNACK GROVE" else "WAY HOME"
		local s = Instance.new("UIStroke")
		s.Thickness = 4
		s.Color = P.Outline
		s.Parent = t
		t.Parent = gui
	end
	-- A little "keep quiet" sign inside
	Build.cylinder(0.6, 4, P.WoodDark, at(-gx - 5, 2, -R + 5), folder)
	local warn = Build.block(Vector3.new(6, 2.6, 0.4), P.Cream, at(-gx - 5, 4.6, -R + 5) * CFrame.Angles(0, math.pi, 0), folder)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = warn
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(0.94, 0.9)
	t.Position = UDim2.fromScale(0.03, 0.05)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = P.Coral
	t.Text = "NO SNACK THIEVES! - the Gardener"
	t.Parent = gui
end

local function buildGrass(folder)
	for i, g in G.Grass do
		local x, z, r = g[1], g[2], g[3]
		Build.cylinder(r * 2, 0.15, P.GrassShade, at(x, 0.08, z), folder)
		local blades = math.floor(r * r * 0.9)
		local rng = Random.new(i * 97)
		for _ = 1, blades do
			local a = rng:NextNumber() * TAU
			local d = math.sqrt(rng:NextNumber()) * (r - 0.6)
			local h = rng:NextNumber(5.2, 7.2)
			Build.wedge(
				Vector3.new(0.25, h, rng:NextNumber(0.9, 1.5)),
				Build.lerp(P.GrassShade, P.Grass, rng:NextNumber(0, 0.7)),
				at(x + math.cos(a) * d, h / 2, z + math.sin(a) * d) * CFrame.Angles(rng:NextNumber(-0.15, 0.15), rng:NextNumber() * TAU, 0),
				folder,
				{ Transparency = 0.05 }
			)
		end
	end
end

---------------------------------------------------------------------------
-- Plants
---------------------------------------------------------------------------
local function buildPlant(def, folder, index)
	local m = Build.model(`{def.Kind}Plant{index}`, folder)
	local ground = at(def.Pos.X, 0, def.Pos.Z) * CFrame.Angles(0, (index * 1.7) % TAU, 0)
	local fruitSpots
	if def.Kind == "Apple" then
		Props.bush(m, ground, 1.15, P.Bubblegum)
		fruitSpots = { Vector3.new(0, 5.4, 0), Vector3.new(2.4, 4.2, -1), Vector3.new(-2.3, 4, -1.2) }
	elseif def.Kind == "Burger" then
		Props.bush(m, ground, 1.35, P.Sunny)
		fruitSpots = { Vector3.new(0, 6.4, 0), Vector3.new(2.8, 4.8, -1.2), Vector3.new(-2.6, 4.6, -1) }
	elseif def.Kind == "Cake" then
		Props.tree(m, ground, 0.85)
		fruitSpots = { Vector3.new(2.6, 8, -2.6), Vector3.new(-3.2, 7, 1.4), Vector3.new(0.6, 10.5, -3.2) }
	else -- Golden Melon: a vine patch on a little mound with a glow
		Build.ellipsoid(Vector3.new(10, 2.4, 10), Build.lerp(P.WoodDark, P.Grass, 0.4), ground * CFrame.new(0, 0.4, 0), m)
		for k = 1, 6 do
			local a = k / 6 * TAU
			Build.ellipsoid(Vector3.new(2.2, 0.3, 1.2), P.GrassShade, ground * CFrame.new(math.cos(a) * 3.4, 1.55, math.sin(a) * 3.4) * CFrame.Angles(0, -a, 0), m)
		end
		fruitSpots = { Vector3.new(0, 3.2, 0) }
	end
	local fruit = {}
	local scale = if def.Kind == "GoldenMelon" then 1.2 else 0.6
	for _, spot in fruitSpots do
		local food = FoodModels.build(Config.Snacks[def.Kind].Model)
		Build.scaleModel(food, scale)
		food:PivotTo(ground * CFrame.new(spot))
		food.Parent = m
		table.insert(fruit, food)
	end
	if def.Kind == "GoldenMelon" then
		local glow = Instance.new("PointLight")
		glow.Color = P.Sunny
		glow.Range = 14
		glow.Brightness = 1.2
		glow.Parent = fruit[1]:FindFirstChildWhichIsA("BasePart")
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkle.Color = ColorSequence.new(P.Sunny)
		sparkle.LightEmission = 0.7
		sparkle.Rate = 5
		sparkle.Lifetime = NumberRange.new(0.8, 1.4)
		sparkle.Speed = NumberRange.new(1, 2)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Size = NumberSequence.new(0.7, 0)
		sparkle.Parent = fruit[1]:FindFirstChildWhichIsA("BasePart")
	end

	local anchor = Build.block(Vector3.new(1, 1, 1), P.Grass, ground * CFrame.new(0, 3, 0), m, { Transparency = 1 })
	anchor.Name = "PromptAnchor"
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Shake"
	prompt.ObjectText = Config.Snacks[def.Kind].Name .. (if def.Kind == "Cake" then " Tree" elseif def.Kind == "GoldenMelon" then "" else " Bush")
	prompt.HoldDuration = G.ShakeTime
	prompt.MaxActivationDistance = G.PromptRange
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = anchor

	local plant = { Def = def, Model = m, Fruit = fruit, Prompt = prompt, ReadyAt = 0, Ground = ground }
	prompt.Triggered:Connect(function(player)
		Grove.shake(player, plant)
	end)
	table.insert(plants, plant)
end

local function setFruitVisible(plant, visible)
	for _, food in plant.Fruit do
		for _, d in food:GetDescendants() do
			if d:IsA("BasePart") then
				if d:GetAttribute("BaseT") == nil then
					d:SetAttribute("BaseT", d.Transparency)
				end
				d.Transparency = if visible then d:GetAttribute("BaseT") else 1
			elseif d:IsA("ParticleEmitter") or d:IsA("PointLight") then
				d.Enabled = visible
			end
		end
	end
	plant.Prompt.Enabled = visible
end

---------------------------------------------------------------------------
-- Carrying (server-owned list + a welded stack above your head)
---------------------------------------------------------------------------
local function refreshCarryVisual(player)
	for _, m in carryVisual[player] or {} do
		m:Destroy()
	end
	carryVisual[player] = {}
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	local y = head.Size.Y / 2 + 0.9
	for i, snackId in carry[player] or {} do
		local food = FoodModels.build(Config.Snacks[snackId].Model)
		Build.scaleModel(food, 0.55)
		food:PivotTo(head.CFrame * CFrame.new(0, y, 0) * CFrame.Angles(0, i * 0.7, 0))
		for _, d in food:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = false
				d.CanCollide = false
				d.CanQuery = false
				d.Massless = true
				local w = Instance.new("WeldConstraint")
				w.Part0 = head
				w.Part1 = d
				w.Parent = d
			end
		end
		food.Name = "Carried"
		food.Parent = character
		table.insert(carryVisual[player], food)
		y += if snackId == "GoldenMelon" then 1.6 else 1.2
	end
	player:SetAttribute("Carrying", #(carry[player] or {}))
	player:SetAttribute("CarryTop", (carry[player] or {})[#(carry[player] or {})] or "")
end

function Grove.carried(player)
	return carry[player] or {}
end

-- Remove and return the top snack (for feeding), or nil.
function Grove.takeSnack(player): string?
	local list = carry[player]
	if not list or #list == 0 then
		return nil
	end
	local snackId = table.remove(list)
	refreshCarryVisual(player)
	return snackId
end

function Grove.dropAll(player)
	carry[player] = {}
	refreshCarryVisual(player)
end

function Grove.clear(player)
	Grove.dropAll(player)
	carry[player] = nil
	carryVisual[player] = nil
	seenSince[player] = nil
end

function Grove.onCharacter(player)
	task.defer(refreshCarryVisual, player)
end

---------------------------------------------------------------------------
-- Shaking
---------------------------------------------------------------------------
function Grove.shake(player, plant)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not callbacks.isReady(player) then
		return
	end
	if (root.Position - plant.Ground.Position).Magnitude > G.PromptRange + 6 then
		return -- too far: prompts are client-side, so re-check range here
	end
	if os.clock() < plant.ReadyAt then
		return
	end
	local list = carry[player] or {}
	carry[player] = list
	local cap = callbacks.capacity(player)
	if #list >= cap then
		callbacks.notify(player, `Hands full ({cap})! Feed your monster first, or buy a bigger backpack.`)
		return
	end
	local snackId = plant.Def.Kind
	table.insert(list, snackId)
	plant.ReadyAt = os.clock() + plant.Def.Regrow
	setFruitVisible(plant, false)
	refreshCarryVisual(player)
	callbacks.fx(player, "Picked", snackId, plant.Ground.Position + Vector3.new(0, 4, 0))
	task.delay(plant.Def.Regrow, function()
		if os.clock() >= plant.ReadyAt - 0.05 then
			setFruitVisible(plant, true)
		end
	end)
end

---------------------------------------------------------------------------
-- The Grumpy Gardener
---------------------------------------------------------------------------
local function makeGardener(folder)
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = Color3.fromHex("#E8B98F")
	desc.TorsoColor = Color3.fromHex("#5C8A3A")
	desc.LeftArmColor = Color3.fromHex("#E8B98F")
	desc.RightArmColor = Color3.fromHex("#E8B98F")
	desc.LeftLegColor = Color3.fromHex("#4A6FA5")
	desc.RightLegColor = Color3.fromHex("#4A6FA5")
	desc.WidthScale = 1.2
	desc.DepthScale = 1.15
	desc.HeadScale = 1.15
	local ok, rig = pcall(Players.CreateHumanoidModelFromDescription, Players, desc, Enum.HumanoidRigType.R15)
	if not ok then
		warn("[Grove] Gardener rig failed:", rig)
		return nil
	end
	rig.Name = "GrumpyGardener"
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	local root = rig:FindFirstChild("HumanoidRootPart")
	local animate = rig:FindFirstChild("Animate")
	local ids = {}
	if animate then
		for _, name in { "idle", "walk" } do
			local holder = animate:FindFirstChild(name)
			local anim = holder and holder:FindFirstChildOfClass("Animation")
			if anim then
				ids[name] = anim.AnimationId
			end
		end
		animate:Destroy()
	end
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid.MaxHealth = math.huge
	humanoid.Health = math.huge
	humanoid.WalkSpeed = G.GardenerSpeed
	rig.PrimaryPart = root
	rig:PivotTo(at(G.Patrol[1].X, 4, G.Patrol[1].Z))
	pcall(function()
		rig:ScaleTo(G.GardenerScale)
	end)
	local head = rig:FindFirstChild("Head")
	if head then
		-- straw hat
		local s = G.GardenerScale
		local brim = Build.cylinder(4.2 * s, 0.25 * s, Color3.fromHex("#F2D28B"), head.CFrame * CFrame.new(0, head.Size.Y * 0.28, 0), rig)
		local top = Build.cylinder(2.2 * s, 1.1 * s, Color3.fromHex("#E8C273"), head.CFrame * CFrame.new(0, head.Size.Y * 0.28 + 0.6 * s, 0), rig)
		local band = Build.cylinder(2.25 * s, 0.3 * s, P.Coral, head.CFrame * CFrame.new(0, head.Size.Y * 0.28 + 0.25 * s, 0), rig)
		for _, part in { brim, top, band } do
			part.Anchored = false
			part.Massless = true
			local w = Instance.new("WeldConstraint")
			w.Part0 = head
			w.Part1 = part
			w.Parent = part
		end
	end
	-- Vision cone on the ground: two flat wedges making a triangle, welded to the root.
	local length = G.SightRange
	local half = math.tan(math.rad(G.SightAngle)) * length
	local hip = humanoid.HipHeight + root.Size.Y / 2
	for _, sx in { -1, 1 } do
		local w = Instance.new("WedgePart")
		w.Name = "SightCone"
		w.Anchored = false
		w.CanCollide = false
		w.CanQuery = false
		w.CanTouch = false
		w.Massless = true
		w.CastShadow = false
		w.Material = Enum.Material.Neon
		w.Color = P.Sunny
		w.Transparency = 0.72
		w.Size = Vector3.new(0.12, half, length)
		-- wedge's sloped face runs from (top, back) to (bottom, front); laid flat it's a right triangle
		w.CFrame = root.CFrame * CFrame.new(sx * half / 2, -hip + 0.25, -length / 2 - 1) * CFrame.Angles(0, 0, sx * math.pi / 2) * CFrame.Angles(math.pi, 0, 0)
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = w
		weld.Parent = w
		w.Parent = rig
	end
	-- "!" when he spots someone
	local alert = Instance.new("BillboardGui")
	alert.Size = UDim2.fromOffset(60, 60)
	alert.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	alert.Enabled = false
	alert.LightInfluence = 0
	alert.Parent = head or root
	local mark = Instance.new("TextLabel")
	mark.BackgroundTransparency = 1
	mark.Size = UDim2.fromScale(1, 1)
	mark.Font = Enum.Font.FredokaOne
	mark.TextScaled = true
	mark.TextColor3 = P.Coral
	mark.Text = "!"
	local st = Instance.new("UIStroke")
	st.Thickness = 4
	st.Color = P.Outline
	st.Parent = mark
	mark.Parent = alert

	rig.Parent = folder
	for _, d in rig:GetDescendants() do
		if d:IsA("BasePart") and d:CanSetNetworkOwnership() then
			d:SetNetworkOwner(nil)
		end
	end
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	local tracks = {}
	for name, id in ids do
		local a = Instance.new("Animation")
		a.AnimationId = id
		local okT, t = pcall(animator.LoadAnimation, animator, a)
		if okT then
			t.Looped = true
			tracks[name] = t
		end
	end
	humanoid.Running:Connect(function(speed)
		if speed > 0.5 then
			if tracks.idle then
				tracks.idle:Stop(0.2)
			end
			if tracks.walk and not tracks.walk.IsPlaying then
				tracks.walk:Play(0.2)
			end
		else
			if tracks.walk then
				tracks.walk:Stop(0.2)
			end
			if tracks.idle and not tracks.idle.IsPlaying then
				tracks.idle:Play(0.2)
			end
		end
	end)
	if tracks.idle then
		tracks.idle:Play()
	end
	return { Model = rig, Humanoid = humanoid, Root = root, Alert = alert, PauseUntil = 0 }
end

local function patrol()
	local index = 1
	while gardener and gardener.Model.Parent do
		local wp = G.Patrol[index]
		local goal = at(wp.X, 0, wp.Z).Position
		gardener.Humanoid:MoveTo(goal)
		local t0 = os.clock()
		while gardener.Model.Parent and os.clock() - t0 < 12 do
			if os.clock() < gardener.PauseUntil then
				gardener.Humanoid:MoveTo(gardener.Root.Position)
				task.wait(0.1)
				gardener.Humanoid:MoveTo(goal)
			elseif ((gardener.Root.Position - goal) * Vector3.new(1, 0, 1)).Magnitude < 2.5 then
				break
			end
			task.wait(0.1)
		end
		-- pause and look around: turn toward the next point slowly
		local nextWp = G.Patrol[index % #G.Patrol + 1]
		local look = at(nextWp.X, 0, nextWp.Z).Position
		local pos = gardener.Root.Position
		gardener.Root.CFrame = CFrame.lookAt(pos, Vector3.new(look.X, pos.Y, look.Z))
		task.wait(G.PatrolPause)
		index = index % #G.Patrol + 1
	end
end

local function hiddenInGrass(pos: Vector3): boolean
	local localPos = groveCF:PointToObjectSpace(pos)
	for _, g in G.Grass do
		local dx, dz = localPos.X - g[1], localPos.Z - g[2]
		if dx * dx + dz * dz <= g[3] * g[3] then
			return true
		end
	end
	return false
end

local function canSee(pos: Vector3, rangeMult: number): boolean
	local root = gardener.Root
	local v = (pos - root.Position) * Vector3.new(1, 0, 1)
	local dist = v.Magnitude
	if dist > G.SightRange * rangeMult or dist < 0.01 then
		return dist < 3 -- bumping right into him counts
	end
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	if look.Unit:Dot(v.Unit) < math.cos(math.rad(G.SightAngle)) then
		return false
	end
	return not hiddenInGrass(pos)
end

local function watch()
	while gardener and gardener.Model.Parent do
		task.wait(G.SightCheck)
		local anyone = false
		local now = os.clock()
		for _, player in Players:GetPlayers() do
			local list = carry[player]
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if list and #list > 0 and root and Grove.isInside(root.Position) and now >= gardener.PauseUntil and canSee(root.Position, 1) then
				anyone = true
				seenSince[player] = seenSince[player] or now
				if now - seenSince[player] >= G.CaughtGrace then
					seenSince[player] = nil
					gardener.PauseUntil = now + 1.6
					local pos = gardener.Root.Position
					gardener.Root.CFrame = CFrame.lookAt(pos, Vector3.new(root.Position.X, pos.Y, root.Position.Z))
					gardener.Humanoid.Jump = true
					Grove.dropAll(player)
					callbacks.caught(player, gardener.Model)
				end
			else
				seenSince[player] = nil
			end
		end
		gardener.Alert.Enabled = anyone
	end
end

---------------------------------------------------------------------------
-- Public
---------------------------------------------------------------------------
function Grove.isInside(pos: Vector3): boolean
	if not groveCF then
		return false
	end
	local localPos = groveCF:PointToObjectSpace(pos)
	return (localPos.X * localPos.X + localPos.Z * localPos.Z) < (G.Radius - 3) ^ 2 and localPos.Y > -20
end

-- Where a monster waits for its owner: beside the main-island end of the bridge (never on it, so
-- big monsters don't block the way), facing the Grove.
local waitCF
function Grove.waitSpot(): CFrame
	return waitCF
end

-- Where a caught player is put back: outside the gate, facing the Grove.
function Grove.ejectSpot(): CFrame
	local p = at(4, 3, -G.Radius - 4)
	return CFrame.lookAt(p.Position, at(4, 3, 0).Position)
end

function Grove.gatePosition(): Vector3
	return at(0, 0, -G.Radius + 1).Position
end

function Grove.gardenerModel()
	return gardener and gardener.Model
end

-- cb: isReady(player), capacity(player) -> number, notify(player, text), fx(player, kind, ...),
--     caught(player, gardenerModel), buyBackpack(player)
function Grove.build(cb)
	callbacks = cb
	local dir = Vector3.new(math.cos(G.Angle), 0, math.sin(G.Angle))
	local center = dir * G.Distance
	groveCF = CFrame.lookAt(center, center - dir) -- -Z faces the main island

	local folder = Instance.new("Folder")
	folder.Name = "SnackGrove"
	buildIsland(folder)
	buildFence(folder)
	buildGrass(folder)
	for i, def in G.Plants do
		buildPlant(def, folder, i)
	end
	local mainEdge = dir * (Config.Map.IslandRadius - 8)
	local groveEdge = dir * (G.Distance - G.Radius + 4)
	buildBridge(folder, mainEdge, groveEdge)

	-- Backpack stand at the main-island end of the bridge
	local side = Vector3.new(-dir.Z, 0, dir.X)
	local waitPos = mainEdge - dir * (6 + G.MonsterWaitDistance) - side * 16
	waitCF = CFrame.lookAt(waitPos, waitPos + dir)
	local standPos = mainEdge - dir * 10 + side * 14
	local standCF = CFrame.lookAt(standPos, standPos + side * -1)
	Build.block(Vector3.new(8, 3.2, 3.6), P.Wood, standCF * CFrame.new(0, 1.6, 0), folder, SOLID)
	Build.block(Vector3.new(8.6, 0.5, 4.2), P.WoodLight, standCF * CFrame.new(0, 3.4, 0), folder)
	for _, sx in { -3.6, 3.6 } do
		Build.cylinder(0.6, 6, P.WoodDark, standCF * CFrame.new(sx, 6.2, 1.2), folder)
	end
	for k = -2, 2 do
		Build.wedge(Vector3.new(1.8, 1.2, 4.6), if k % 2 == 0 then P.Coral else P.Cream, standCF * CFrame.new(k * 1.8, 9.6, 0), folder)
	end
	local bag = Build.ellipsoid(Vector3.new(2.6, 2.8, 1.8), P.Tangerine, standCF * CFrame.new(0, 5, 0), folder)
	Build.block(Vector3.new(1.6, 0.9, 0.3), P.Sunny, standCF * CFrame.new(0, 5, -0.95), folder)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Upgrade backpack"
	prompt.ObjectText = "Backpack Stand"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = bag
	prompt.Triggered:Connect(function(player)
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - bag.Position).Magnitude < 16 then
			callbacks.buyBackpack(player)
		end
	end)
	local board = Build.block(Vector3.new(7, 3.4, 0.4), P.Cream, standCF * CFrame.new(0, 8.4, -1.3), folder)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 36
	gui.Parent = board
	local list = Instance.new("TextLabel")
	list.BackgroundTransparency = 1
	list.Size = UDim2.fromScale(0.94, 0.94)
	list.Position = UDim2.fromScale(0.03, 0.03)
	list.Font = Enum.Font.FredokaOne
	list.TextScaled = true
	list.TextColor3 = P.Outline
	local lines = { "BACKPACKS" }
	for _, b in Config.Backpacks do
		if b.Price > 0 then
			table.insert(lines, `{b.Name}: carry {b.Carry} - {b.Price} coins`)
		end
	end
	list.Text = table.concat(lines, "\n")
	list.Parent = gui

	folder.Parent = workspace

	-- Clear scenery props that ended up on the bridge path on the main island.
	local map = workspace:FindFirstChild("Map")
	if map then
		for _, m in map:GetChildren() do
			if m:IsA("Model") and m.Name ~= "Leaderboard" then
				local p = m:GetPivot().Position * Vector3.new(1, 0, 1)
				local along = p:Dot(dir)
				local across = math.abs(p:Dot(side))
				if along > 150 and across < 16 then
					m:Destroy()
				end
			end
		end
	end

	local gFolder = Instance.new("Folder")
	gFolder.Name = "GroveNPCs"
	gFolder.Parent = workspace
	gardener = makeGardener(gFolder)
	if gardener then
		task.spawn(patrol)
		task.spawn(watch)
	end
end

return Grove
