-- Your monster as a living companion: a rigged R15 creature that follows you around, waits at the
-- Snack Grove gate, catches the snacks you throw, and grows with Size.
--
-- The rig comes from ServerStorage.MonsterRig (a rigged model made in Studio) when it exists;
-- otherwise a default R15 body tinted in the plot's colours, so the game always runs.
-- Animations are Roblox's default R15 ones, read from the Animate script that Roblox puts in the rig
-- (no asset ids are typed here). The server plays them, so every client sees the same motion.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(ReplicatedStorage.Shared.Build)
local Props = require(ReplicatedStorage.Shared.Props)
local Format = require(ReplicatedStorage.Shared.Format)

local C = Config.Companion
local P = Config.Palette

local Companion = {}

local folder = Instance.new("Folder")
folder.Name = "Monsters"
folder.Parent = workspace

local records = {} -- [model] = { Owner, Humanoid, Root, Tracks, Scale, Tag, Cosmetics, ... }

---------------------------------------------------------------------------
-- Rig
---------------------------------------------------------------------------
local function fallbackRig(colors)
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = colors.Body
	desc.TorsoColor = colors.Body
	desc.LeftArmColor = colors.Body
	desc.RightArmColor = colors.Body
	desc.LeftLegColor = colors.Spot
	desc.RightLegColor = colors.Spot
	desc.BodyTypeScale = 0
	desc.ProportionScale = 0
	desc.HeightScale = 0.9
	desc.WidthScale = 1.35
	desc.DepthScale = 1.3
	desc.HeadScale = 1.6
	return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
end

local function makeRig(colors)
	local template = ServerStorage:FindFirstChild("MonsterRig")
	local ok, rig = pcall(function()
		if template and template:IsA("Model") and template:FindFirstChildOfClass("Humanoid") then
			return template:Clone()
		end
		return fallbackRig(colors)
	end)
	if ok and rig then
		return rig
	end
	warn("[Companion] could not build a rig:", rig)
	return nil
end

-- Animation ids come from the rig's own Animate script (Roblox's defaults for that body).
local function readAnimationIds(rig)
	local ids = {}
	local animate = rig:FindFirstChild("Animate")
	if not animate then
		return ids
	end
	for _, name in { "idle", "walk", "run", "jump", "fall" } do
		local holder = animate:FindFirstChild(name)
		local anim = holder and holder:FindFirstChildOfClass("Animation")
		if anim and anim.AnimationId ~= "" then
			ids[name] = anim.AnimationId
		end
	end
	animate:Destroy() -- a LocalScript can't drive a server-owned NPC; we play the tracks below
	return ids
end

local function loadTracks(humanoid, ids)
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = humanoid
	local tracks = {}
	for name, id in ids do
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		local ok, track = pcall(animator.LoadAnimation, animator, anim)
		if ok then
			track.Priority = if name == "jump" or name == "fall" then Enum.AnimationPriority.Action else Enum.AnimationPriority.Core
			track.Looped = name ~= "jump"
			tracks[name] = track
		end
	end
	return tracks
end

local function play(rec, name, speed)
	local track = rec.Tracks[name]
	if not track then
		return
	end
	if rec.Playing ~= name then
		if rec.Playing and rec.Tracks[rec.Playing] then
			rec.Tracks[rec.Playing]:Stop(0.2)
		end
		track:Play(0.2)
		rec.Playing = name
	end
	if speed then
		track:AdjustSpeed(speed)
	end
end

---------------------------------------------------------------------------
-- Name tag + cosmetics
---------------------------------------------------------------------------
local function makeTag(rec, head)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Tag"
	gui.Size = UDim2.fromOffset(200, 54)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 160
	gui.LightInfluence = 0
	gui.Parent = head
	local function label(text, y, h, color)
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.new(1, 0, 0, h)
		t.Position = UDim2.fromOffset(0, y)
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextColor3 = color
		t.Text = text
		local s = Instance.new("UIStroke")
		s.Thickness = 2
		s.Color = P.Outline
		s.Parent = t
		t.Parent = gui
		return t
	end
	label(`{rec.Owner.DisplayName}'s monster`, 0, 24, P.TextLight)
	rec.SizeLabel = label("Size 1", 26, 26, P.Mint)
	rec.Tag = gui
end

local function weldTo(part, anchor)
	part.Anchored = false
	part.CanCollide = false
	part.Massless = true
	local w = Instance.new("WeldConstraint")
	w.Part0 = anchor
	w.Part1 = part
	w.Parent = part
end

-- Milestone looks, built at the rig's current scale and welded on.
local cosmeticBuilders = {
	Sprout = function(m, head, s)
		local top = head.CFrame * CFrame.new(0, head.Size.Y * 0.5, 0)
		local stem = Build.cylinder(0.25 * s, 0.8 * s, P.GrassShade, top * CFrame.new(0, 0.35 * s, 0), m)
		local leafA = Build.ellipsoid(Vector3.new(1.2, 0.2, 0.6) * s, P.Grass, top * CFrame.new(0.45 * s, 0.75 * s, 0) * CFrame.Angles(0, 0, -0.4), m)
		local leafB = Build.ellipsoid(Vector3.new(1, 0.2, 0.55) * s, P.Mint, top * CFrame.new(-0.4 * s, 0.7 * s, 0) * CFrame.Angles(0, 0, 0.45), m)
		return { stem, leafA, leafB }, head
	end,
	Horns = function(m, head, s)
		local parts = {}
		for _, sx in { -1, 1 } do
			local base = head.CFrame * CFrame.new(sx * head.Size.X * 0.3, head.Size.Y * 0.42, 0) * CFrame.Angles(0, 0, -sx * 0.35)
			table.insert(parts, Build.ellipsoid(Vector3.new(0.45, 1.1, 0.45) * s, P.Cream, base * CFrame.new(0, 0.45 * s, 0), m))
			table.insert(parts, Build.ball(0.4 * s, P.Cream, base * CFrame.new(0, 0.95 * s, 0), m))
		end
		return parts, head
	end,
	Wings = function(m, torso, s)
		local parts = {}
		for _, sx in { -1, 1 } do
			local cf = torso.CFrame * CFrame.new(sx * 0.9 * s, 0.4 * s, torso.Size.Z * 0.5 + 0.2) * CFrame.Angles(0, sx * 0.5, sx * 0.4)
			table.insert(parts, Build.ellipsoid(Vector3.new(2.4, 1.6, 0.2) * s, P.Sky, cf, m, { Transparency = 0.15 }))
		end
		return parts, torso
	end,
	Crown = function(m, head, s)
		local before = {}
		for _, d in m:GetChildren() do
			before[d] = true
		end
		Props.crown(m, head.CFrame * CFrame.new(0, head.Size.Y * 0.45, 0), 0.22 * s)
		local parts = {}
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") and not before[d] then
				table.insert(parts, d)
			end
		end
		return parts, head
	end,
	Aura = function(m, torso, s)
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds" -- built-in Roblox texture
		e.Color = ColorSequence.new(P.Sunny, P.Bubblegum)
		e.LightEmission = 0.6
		e.Rate = 6
		e.Lifetime = NumberRange.new(1, 1.6)
		e.Speed = NumberRange.new(1, 2)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Size = NumberSequence.new(0.6 * s, 0)
		e.Parent = torso
		return {}, torso
	end,
}

local function applyCosmetics(rec)
	local size = rec.Size or 1
	for _, milestone in Config.Monster.Milestones do
		if size >= milestone.Size and not rec.Cosmetics[milestone.Id] then
			local builder = cosmeticBuilders[milestone.Id]
			local anchorName = if milestone.Id == "Wings" or milestone.Id == "Aura" then "UpperTorso" else "Head"
			local anchor = rec.Model:FindFirstChild(anchorName) or rec.Root
			if builder and anchor then
				local holder = Instance.new("Model")
				holder.Name = milestone.Id
				holder.Parent = rec.Model
				local parts = builder(holder, anchor, rec.Scale)
				for _, part in parts do
					weldTo(part, anchor)
				end
			end
			rec.Cosmetics[milestone.Id] = true
		end
	end
end

---------------------------------------------------------------------------
-- Public API (same shape as the old Monster module)
---------------------------------------------------------------------------
function Companion.create(owner, plotIndex, groundCFrame)
	local colors = Config.Monster.Colors[((plotIndex - 1) % #Config.Monster.Colors) + 1]
	local rig = makeRig(colors)
	if not rig then
		return nil
	end
	rig.Name = `{owner.Name}_Monster`
	local humanoid = rig:FindFirstChildOfClass("Humanoid")
	local root = rig:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		rig:Destroy()
		return nil
	end
	local ids = readAnimationIds(rig)
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	humanoid.MaxHealth = math.huge
	humanoid.Health = math.huge
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
	humanoid.WalkSpeed = C.WalkSpeed
	rig.PrimaryPart = root

	for _, d in rig:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanTouch = false
			d.CastShadow = true
		end
	end

	rig:SetAttribute("PlotIndex", plotIndex)
	rig:SetAttribute("OwnerUserId", owner.UserId)
	rig:SetAttribute("OwnerName", owner.DisplayName)
	rig:SetAttribute("Ground", groundCFrame)
	rig:SetAttribute("MonsterSize", 1)
	rig:SetAttribute("Scale", 1)

	local rec = {
		Owner = owner,
		Model = rig,
		Humanoid = humanoid,
		Root = root,
		Tracks = {},
		Scale = 1,
		Size = 1,
		Cosmetics = {},
		Home = groundCFrame,
		LastPos = root.Position,
		StuckSince = nil,
		HoldUntil = 0,
	}
	records[rig] = rec

	rig:PivotTo(groundCFrame * CFrame.new(0, 4, 0))
	rig.Parent = folder
	for _, d in rig:GetDescendants() do
		if d:IsA("BasePart") and d:CanSetNetworkOwnership() then
			d:SetNetworkOwner(nil) -- server drives it: smooth and consistent for every player
		end
	end
	rec.Tracks = loadTracks(humanoid, ids)
	makeTag(rec, rig:FindFirstChild("Head") or root)

	humanoid.Running:Connect(function(speed)
		if speed > 0.5 then
			local walkScale = speed / (16 * math.max(rec.Scale, 1) * 0.8)
			if speed > C.WalkSpeed + 2 and rec.Tracks.run then
				play(rec, "run", math.clamp(walkScale, 0.6, 1.6))
			else
				play(rec, "walk", math.clamp(walkScale * 1.25, 0.6, 1.8))
			end
		else
			play(rec, "idle", 1)
		end
	end)
	humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Jumping then
			play(rec, "jump", 1)
		elseif new == Enum.HumanoidStateType.Freefall then
			play(rec, "fall", 1)
		elseif new == Enum.HumanoidStateType.Landed then
			play(rec, "idle", 1)
		end
	end)
	play(rec, "idle", 1)
	return rig
end

function Companion.setSize(model, size)
	local rec = records[model]
	if not rec then
		return
	end
	rec.Size = size
	local scale = Config.companionScale(size)
	if math.abs(scale - rec.Scale) > 0.01 then
		local ok = pcall(function()
			model:ScaleTo(scale)
		end)
		if ok then
			rec.Scale = scale
			model:SetAttribute("Scale", scale)
		end
	end
	rec.Humanoid.WalkSpeed = C.WalkSpeed * math.sqrt(rec.Scale)
	model:SetAttribute("MonsterSize", math.floor(size))
	if rec.SizeLabel then
		rec.SizeLabel.Text = `Size {Format.short(size)}`
	end
	applyCosmetics(rec)
end

-- Stop and face this point for a moment (catching a snack).
function Companion.face(model, point: Vector3, seconds: number)
	local rec = records[model]
	if not rec then
		return
	end
	rec.HoldUntil = os.clock() + seconds
	rec.Humanoid:MoveTo(rec.Root.Position)
	local pos = rec.Root.Position
	rec.Root.CFrame = CFrame.lookAt(pos, Vector3.new(point.X, pos.Y, point.Z))
end

function Companion.hop(model)
	local rec = records[model]
	if rec then
		rec.Humanoid.Jump = true
	end
end

-- Called often by Main: walk toward target (or stay home if nil). Handles run, stuck and teleport.
function Companion.follow(model, target: Vector3?, standOff: number)
	local rec = records[model]
	if not rec or not model.Parent then
		return
	end
	local now = os.clock()
	if now < rec.HoldUntil then
		return
	end
	local root = rec.Root
	local pos = root.Position
	local goal = target or rec.Home.Position
	local flat = (goal - pos) * Vector3.new(1, 0, 1)
	local dist = flat.Magnitude
	local stand = standOff + rec.Scale * 1.2
	if dist > C.TeleportDistance or pos.Y < Config.Map.FallY then
		local dir = if dist > 0 then flat.Unit else Vector3.zAxis
		model:PivotTo(CFrame.lookAt(goal - dir * stand + Vector3.new(0, 3 * rec.Scale, 0), goal))
		rec.StuckSince = nil
		return
	end
	if dist <= stand then
		rec.Humanoid:MoveTo(pos)
		rec.StuckSince = nil
		return
	end
	rec.Humanoid.WalkSpeed = (if dist > C.RunDistance then C.RunSpeed else C.WalkSpeed) * math.sqrt(rec.Scale)
	rec.Humanoid:MoveTo(goal - flat.Unit * stand)
	-- Stuck on a fence? Hop, then pop next to the target.
	if (pos - rec.LastPos).Magnitude < 0.4 then
		rec.StuckSince = rec.StuckSince or now
		local stuckFor = now - rec.StuckSince
		if stuckFor > 0.6 and stuckFor < 0.8 then
			rec.Humanoid.Jump = true
		elseif stuckFor > 2.2 then
			model:PivotTo(CFrame.lookAt(goal - flat.Unit * stand + Vector3.new(0, 3 * rec.Scale, 0), goal))
			rec.StuckSince = nil
		end
	else
		rec.StuckSince = nil
	end
	rec.LastPos = pos
end

function Companion.destroy(model)
	records[model] = nil
	model:Destroy()
end

return Companion
