-- Draws every monster on this client: a chubby jelly body with big derpy eyes, a big mouth,
-- little arms and feet. Idle breathing + hops + blinks, opens its mouth when food is coming,
-- squashes when it gulps, and wears new cosmetics at size milestones.
-- The server's invisible hitbox (workspace.Monsters.<name>.Body) is the truth; this is only looks.
-- Vault: "Game Feel and Juice" (anticipation then payoff), "Lighting Untextured Art in Roblox" (contact shadow).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(ReplicatedStorage.Shared.Build)
local Props = require(ReplicatedStorage.Shared.Props)
local Format = require(ReplicatedStorage.Shared.Format)

local P = Config.Palette
local MC = Config.Monster
local TAU = math.pi * 2
local WHITE = Color3.new(1, 1, 1) -- eyes are the only pure white/black in the game
local BLACK = Color3.fromRGB(12, 12, 18)

local BODY_CENTER = Vector3.new(0, 3.3, 0)
local BODY_RADII = Vector3.new(3.2, 2.8, 2.9)

local MonsterView = {}
MonsterView.onMilestone = nil -- set by the client: function(model, milestone, isMine)

local rng = Random.new()
local views = {} -- [serverModel] = view
local dirty = true
local allParts, allCFrames = {}, {}
local localUserId = game:GetService("Players").LocalPlayer.UserId

---------------------------------------------------------------------------
-- Geometry helpers (all in the monster's local space at scale 1, root on the ground, face toward -Z)
---------------------------------------------------------------------------

-- Point on the body surface in a direction from its centre. LookVector = outward normal.
local function onBody(dir: Vector3, push: number?): CFrame
	local d = dir.Unit
	local r = BODY_RADII
	local k = 1 / math.sqrt((d.X / r.X) ^ 2 + (d.Y / r.Y) ^ 2 + (d.Z / r.Z) ^ 2)
	local p = d * k
	local n = Vector3.new(p.X / r.X ^ 2, p.Y / r.Y ^ 2, p.Z / r.Z ^ 2).Unit
	local pos = BODY_CENTER + p + n * (push or 0)
	local up = if math.abs(n.Y) > 0.95 then -Vector3.zAxis else Vector3.yAxis
	return CFrame.lookAt(pos, pos + n, up)
end

local function easeOutBack(x: number): number
	local c1, c3 = 1.70158, 2.70158
	return 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
end

---------------------------------------------------------------------------
-- Building one monster
---------------------------------------------------------------------------
local function add(view, part, role, extra)
	local entry = {
		Part = part,
		Offset = part.CFrame,
		BaseSize = part.Size,
		Mesh = part:FindFirstChildOfClass("SpecialMesh"),
		Role = role or "Rigid",
		Alpha = part.Transparency,
	}
	if extra then
		for k, v in extra do
			entry[k] = v
		end
	end
	if entry.Unlock then
		part.Transparency = 1
		view.Locked[entry.Unlock] = view.Locked[entry.Unlock] or {}
		table.insert(view.Locked[entry.Unlock], entry)
	end
	table.insert(view.Entries, entry)
	return entry
end

local function addModel(view, model, role, extra)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			add(view, d, role, extra)
		end
	end
end

local function buildLook(view, colors)
	local m = view.Model
	local body = colors.Body
	local spot = colors.Spot
	local bodyDark = body:Lerp(P.Outline, 0.14)
	local E = Build.ellipsoid

	-- contact shadow (stays on the ground)
	add(view, Build.cylinder(7, 0.1, P.Outline, CFrame.new(0, 0.06, 0), m, { Transparency = 0.62 }), "Fixed")

	-- feet
	for _, side in { -1, 1 } do
		add(view, E(Vector3.new(1.9, 1.1, 2.4), bodyDark, CFrame.new(side * 1.45, 0.55, -0.55), m))
	end

	-- body + lighter belly + glossy highlight (the "jelly" look)
	view.BodyPart = add(view, E(Vector3.new(6.4, 5.6, 5.8), body, CFrame.new(BODY_CENTER), m, { CastShadow = true }), "Body").Part
	add(view, E(Vector3.new(3.9, 3.1, 0.9), body:Lerp(P.Cream, 0.5), onBody(Vector3.new(0, -0.6, -1), -0.3), m), "Body")
	add(view, E(Vector3.new(1.6, 0.9, 0.25), body:Lerp(WHITE, 0.75), onBody(Vector3.new(-0.5, 0.75, -0.5), 0.02), m, { Transparency = 0.2 }))

	-- spots on top and sides (cool against warm)
	for _, s in {
		{ Vector3.new(0.3, 0.6, 0.75), 1.5 },
		{ Vector3.new(-0.7, 0.45, 0.55), 1.2 },
		{ Vector3.new(-0.1, 0.8, 0.6), 1.1 },
		{ Vector3.new(-0.88, 0.05, 0.4), 1 },
		{ Vector3.new(0.9, -0.1, 0.45), 1.2 },
	} do
		add(view, E(Vector3.new(s[2], s[2], 0.35), spot, onBody(s[1], -0.08), m))
	end

	-- arms (raise when food is coming)
	for _, side in { -1, 1 } do
		local shoulder = Vector3.new(side * 2.85, 3.1, -0.5)
		local arm = E(Vector3.new(1.1, 2.1, 1.1), bodyDark, CFrame.new(shoulder) * CFrame.Angles(0, 0, side * 0.75) * CFrame.new(0, -0.85, 0), m)
		add(view, arm, "Arm", { Pivot = shoulder, Side = side })
	end

	-- big derpy eyes: one bigger than the other, pupils slightly crossed
	for _, e in { { -1, 2.35, 2.65, 0.28 }, { 1, 2.0, 2.3, -0.12 } } do
		local side, w, h, cross = e[1], e[2], e[3], e[4]
		local eyeCF = onBody(Vector3.new(side * 0.5, 0.55, -1), -0.28)
		add(view, E(Vector3.new(w, h, 1), WHITE, eyeCF, m), "Eye")
		local pupilCF = eyeCF * CFrame.new(cross, -0.22, -0.42)
		add(view, E(Vector3.new(1.05, 1.2, 0.45), BLACK, pupilCF, m), "Pupil")
		add(view, Build.ball(0.36, WHITE, pupilCF * CFrame.new(-0.22, 0.28, -0.22), m), "Pupil")
	end

	-- blush
	for _, side in { -1, 1 } do
		add(view, E(Vector3.new(1.0, 0.55, 0.3), P.Bubblegum:Lerp(body, 0.2), onBody(Vector3.new(side * 0.85, -0.2, -0.8), -0.08), m, { Transparency = 0.15 }))
	end

	-- big mouth with a tongue and one goofy tooth
	local mouthCF = onBody(Vector3.new(0, -0.25, -1), -0.22)
	add(view, E(Vector3.new(2.8, 0.85, 0.7), MC.MouthColor, mouthCF, m), "Mouth")
	add(view, E(Vector3.new(1.4, 0.42, 0.45), MC.TongueColor, mouthCF * CFrame.new(0.25, -0.12, -0.14), m), "Tongue")
	add(view, Build.block(Vector3.new(0.5, 0.5, 0.25), P.Cream, mouthCF * CFrame.new(-0.55, 0.22, -0.3), m), "Tooth")

	-- Milestone cosmetics (hidden until unlocked) -------------------------
	-- 25: a leaf sprout on top
	add(view, Build.cylinder(0.32, 1.7, P.GrassShade, CFrame.new(0, 6.75, 0.15), m), "Rigid", { Unlock = "Sprout" })
	for _, side in { -1, 1 } do
		local leaf = CFrame.new(side * 0.62, 7.55, 0.15) * CFrame.Angles(0, 0, side * -0.45)
		add(view, E(Vector3.new(1.5, 0.32, 0.8), P.Grass:Lerp(P.Mint, 0.25), leaf, m), "Rigid", { Unlock = "Sprout" })
	end
	add(view, Build.ball(0.5, P.Bubblegum, CFrame.new(0, 7.7, 0.15), m), "Rigid", { Unlock = "Sprout" })

	local hornColor = P.Cream:Lerp(P.Peach, 0.35)
	for _, side in { -1, 1 } do
		local base = CFrame.new(onBody(Vector3.new(side * 0.72, 0.68, 0.05), -0.2).Position) * CFrame.Angles(0, 0, -side * 0.38)
		add(view, E(Vector3.new(1.3, 1.3, 1.3), hornColor, base * CFrame.new(0, 0.35, 0), m), "Rigid", { Unlock = "Horns" })
		add(view, E(Vector3.new(0.95, 1.15, 0.95), hornColor, base * CFrame.new(0, 1.1, 0), m), "Rigid", { Unlock = "Horns" })
		add(view, E(Vector3.new(0.62, 0.95, 0.62), hornColor:Lerp(P.Peach, 0.4), base * CFrame.new(0, 1.8, 0), m), "Rigid", { Unlock = "Horns" })
		add(view, Build.ball(0.45, P.Peach, base * CFrame.new(0, 2.3, 0), m), "Rigid", { Unlock = "Horns" })
	end

	local wingColor = P.Cloud:Lerp(spot, 0.35)
	for _, side in { -1, 1 } do
		local pivot = Vector3.new(side * 1.3, 4.1, 2.3)
		local root = CFrame.new(pivot) * CFrame.Angles(0, side * -0.45, 0)
		for k, f in { { 3.4, 1.35, 0.55 }, { 2.9, 1.15, 0.2 }, { 2.3, 0.95, -0.15 } } do
			local feather = root * CFrame.Angles(0, 0, side * f[3]) * CFrame.new(side * f[1] / 2, -(k - 1) * 0.25, 0)
			add(view, E(Vector3.new(f[1], f[2], 0.35), wingColor:Lerp(spot, (k - 1) * 0.15), feather, m), "Wing", { Pivot = pivot, Side = side, Unlock = "Wings" })
		end
	end

	local crown = Props.crown(m, CFrame.new(0, 5.75, 0.3) * CFrame.Angles(0, 0.3, -0.15), 0.36, true)
	addModel(view, crown, "Rigid", { Unlock = "Crown" })

	for k = 1, 8 do
		local a = k / 8 * TAU
		local color = ({ P.Sunny, P.Mint, P.Bubblegum, P.Sky })[(k % 4) + 1]
		local sparkle = Build.ball(0.6, color, CFrame.new(math.cos(a) * 4.8, if k % 2 == 0 then 2.2 else 4.4, math.sin(a) * 4.8), m, {
			Material = Enum.Material.Neon,
		})
		add(view, sparkle, "Orbit", { Unlock = "Aura" })
	end
	local aura = Instance.new("ParticleEmitter")
	aura.Color = ColorSequence.new(P.Sunny, P.Bubblegum)
	aura.LightEmission = 1
	aura.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	aura.Transparency = NumberSequence.new(0.1, 1)
	aura.Lifetime = NumberRange.new(1, 1.6)
	aura.Speed = NumberRange.new(1, 3)
	aura.SpreadAngle = Vector2.new(180, 180)
	aura.Rate = 8
	aura.Enabled = false
	aura.Parent = view.BodyPart
	view.AuraEmitter = aura
end

local function buildTag(view)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Tag"
	gui.Size = UDim2.fromOffset(190, 52)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 230
	gui.LightInfluence = 0
	gui.Adornee = view.BodyPart

	local pill = Instance.new("Frame")
	pill.Size = UDim2.fromScale(1, 1)
	pill.BackgroundColor3 = P.UINavy
	pill.BackgroundTransparency = 0.1
	pill.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = pill
	local stroke = Instance.new("UIStroke")
	stroke.Color = P.Outline
	stroke.Thickness = 3
	stroke.Parent = pill

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.fromScale(0.86, 0.55)
	name.Position = UDim2.fromScale(0.07, 0.06)
	name.Font = Enum.Font.FredokaOne
	name.TextScaled = true
	name.TextColor3 = P.TextLight
	name.Text = view.Server:GetAttribute("OwnerName") or "Monster"
	name.Parent = pill

	local size = Instance.new("TextLabel")
	size.BackgroundTransparency = 1
	size.Size = UDim2.fromScale(0.86, 0.36)
	size.Position = UDim2.fromScale(0.07, 0.58)
	size.Font = Enum.Font.FredokaOne
	size.TextScaled = true
	size.TextColor3 = P.Mint
	size.Parent = pill

	gui.Parent = view.BodyPart
	view.Tag = gui
	view.TagSize = size
end

local function applyScale(view, popScale)
	local s = view.Scale
	for _, e in view.Entries do
		local mult = 1
		if e.PopStart then
			mult = popScale[e] or 0.01
		end
		e.Part.Size = e.BaseSize * s * mult
	end
	view.AppliedScale = s
	local crownExtra = if view.Unlocked.Crown then 2.4 else 0
	view.Tag.StudsOffsetWorldSpace = Vector3.new(0, (3.2 + crownExtra) * s + 1.8, 0)
	view.AuraEmitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5 * s), NumberSequenceKeypoint.new(1, 0) })
end

local function unlock(view, milestone, animate)
	if view.Unlocked[milestone.Id] then
		return
	end
	view.Unlocked[milestone.Id] = true
	local now = os.clock()
	for _, e in view.Locked[milestone.Id] or {} do
		e.Part.Transparency = e.Alpha
		if animate then
			e.PopStart = now
		end
	end
	if milestone.Id == "Aura" then
		view.AuraEmitter.Enabled = true
	end
	if animate then
		view.Pulse = -MC.GulpSquash -- stretch up proudly
		if MonsterView.onMilestone then
			task.spawn(MonsterView.onMilestone, view.Server, milestone, view.Server:GetAttribute("OwnerUserId") == localUserId)
		end
	end
	applyScale(view, {})
end

local function refreshSize(view, animate)
	local size = view.Server:GetAttribute("MonsterSize") or 1
	view.TargetScale = Config.scaleForSize(size)
	view.TagSize.Text = `Size {Format.short(size)}`
	for _, milestone in MC.Milestones do
		if size >= milestone.Size then
			unlock(view, milestone, animate)
		end
	end
end

local function createView(serverModel)
	local plot = serverModel:GetAttribute("PlotIndex") or 1
	local colors = MC.Colors[((plot - 1) % #MC.Colors) + 1]
	local model = Instance.new("Model")
	model.Name = `{serverModel.Name}_View`
	local view = {
		Server = serverModel,
		Model = model,
		Entries = {},
		Locked = {},
		Unlocked = {},
		Scale = 1,
		TargetScale = 1,
		AppliedScale = 1,
		Pulse = 0,
		PulseVel = 0,
		Open = 0,
		OpenTarget = 0,
		OpenUntil = 0,
		NextBlink = os.clock() + rng:NextNumber(MC.BlinkEvery[1], MC.BlinkEvery[2]),
		BlinkUntil = 0,
		Blinking = false,
		NextHop = os.clock() + rng:NextNumber(MC.HopEvery[1], MC.HopEvery[2]),
		HopStart = -1,
		LastMouth = -1,
	}
	buildLook(view, colors)
	buildTag(view)
	refreshSize(view, false)
	view.Scale = view.TargetScale
	applyScale(view, {})
	model.Parent = workspace:FindFirstChild("MonsterViews")
	view.Conn = serverModel:GetAttributeChangedSignal("MonsterSize"):Connect(function()
		refreshSize(view, true)
	end)
	views[serverModel] = view
	dirty = true
end

local function removeView(serverModel)
	local view = views[serverModel]
	if view then
		view.Conn:Disconnect()
		view.Model:Destroy()
		views[serverModel] = nil
		dirty = true
	end
end

---------------------------------------------------------------------------
-- Per-frame animation
---------------------------------------------------------------------------
local function stepView(view, t, dt, n)
	-- visual scale eases toward the server's size
	view.Scale += (view.TargetScale - view.Scale) * math.min(1, dt * MC.GrowSpeed)
	local popScale = {}
	local popping = false
	for _, e in view.Entries do
		if e.PopStart then
			local p = (t - e.PopStart) / 0.45
			if p >= 1 then
				e.PopStart = nil
				popping = true
			else
				popScale[e] = math.max(0.01, easeOutBack(math.max(p, 0)))
				popping = true
			end
		end
	end
	if popping or math.abs(view.Scale - view.AppliedScale) > view.AppliedScale * 0.002 then
		applyScale(view, popScale)
	end
	local s = view.Scale

	-- squash: breathing + gulp spring (positive = wider and shorter)
	view.PulseVel += (-view.Pulse * 220 - view.PulseVel * 13) * dt
	view.Pulse += view.PulseVel * dt
	local squash = math.sin(t / MC.BreathPeriod * TAU) * MC.BreathAmount + view.Pulse
	local sq = Vector3.new(1 + squash, 1 - squash, 1 + squash)

	-- happy hop now and then
	local hop = 0
	if t >= view.NextHop then
		view.HopStart = t
		view.NextHop = t + rng:NextNumber(MC.HopEvery[1], MC.HopEvery[2])
	end
	local hp = (t - view.HopStart) / 0.42
	if hp >= 0 and hp <= 1 then
		hop = math.sin(hp * math.pi) * MC.HopHeight
	end

	-- mouth: open while food is on its way
	if t > view.OpenUntil then
		view.OpenTarget = 0
	end
	view.Open += (view.OpenTarget - view.Open) * math.min(1, dt * 16)
	local open = view.Open

	-- blink
	if t >= view.NextBlink then
		view.BlinkUntil = t + MC.BlinkTime
		view.NextBlink = t + rng:NextNumber(MC.BlinkEvery[1], MC.BlinkEvery[2])
	end
	local blinking = t < view.BlinkUntil and open < 0.5
	local blinkChanged = blinking ~= view.Blinking
	view.Blinking = blinking

	local ground = view.Server:GetAttribute("Ground") or CFrame.new()
	local root = ground * CFrame.new(0, hop * s, 0)
	local armWave = math.sin(t * 2.4) * 0.12 + open * 0.75
	local flap = math.sin(t * 7) * 0.35

	for _, e in view.Entries do
		local off = e.Offset
		local role = e.Role
		if role == "Arm" then
			off = CFrame.new(e.Pivot) * CFrame.Angles(0, 0, e.Side * armWave) * CFrame.new(-e.Pivot) * off
		elseif role == "Wing" then
			off = CFrame.new(e.Pivot) * CFrame.Angles(0, 0, e.Side * flap) * CFrame.new(-e.Pivot) * off
		elseif role == "Orbit" then
			off = CFrame.Angles(0, t * 1.3, 0) * off
		end
		local pos = off.Position
		local cf
		if role == "Fixed" then
			cf = ground * CFrame.new(pos * s) * off.Rotation
		else
			pos = Vector3.new(pos.X * sq.X, pos.Y * sq.Y, pos.Z * sq.Z)
			if role == "Mouth" then
				pos -= Vector3.new(0, open * 0.42, 0)
			elseif role == "Tongue" then
				pos -= Vector3.new(0, open * 0.75, 0)
			end
			cf = root * CFrame.new(pos * s) * off.Rotation
		end
		n += 1
		allCFrames[n] = cf

		if role == "Body" then
			e.Mesh.Scale = sq
		elseif blinkChanged and role == "Eye" then
			e.Mesh.Scale = Vector3.new(1, if blinking then 0.12 else 1, 1)
		elseif blinkChanged and role == "Pupil" then
			e.Part.Transparency = if blinking then 1 else e.Alpha
		end
	end
	if math.abs(open - view.LastMouth) > 0.003 then
		view.LastMouth = open
		for _, e in view.Entries do
			if e.Role == "Mouth" then
				e.Mesh.Scale = Vector3.new(1 + open * 0.15, 1 + open * 1.9, 1)
			end
		end
	end
	return n
end

local function rebuildLists()
	table.clear(allParts)
	table.clear(allCFrames)
	for _, view in views do
		for _, e in view.Entries do
			table.insert(allParts, e.Part)
		end
	end
	dirty = false
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

-- Food is on its way: open wide and raise the arms.
function MonsterView.expect(serverModel, flightTime: number)
	local view = views[serverModel]
	if view then
		view.OpenTarget = 1
		view.OpenUntil = os.clock() + flightTime + 0.35
	end
end

-- The server says it ate: snap the mouth shut and squash, harder for bigger food.
function MonsterView.gulp(serverModel, growth: number)
	local view = views[serverModel]
	if not view then
		return
	end
	view.OpenTarget = 0
	view.OpenUntil = 0
	view.Open = math.min(view.Open, 0.3)
	view.Pulse = math.min(0.32, MC.GulpSquash * (1 + math.log10(math.max(growth, 1)) * 0.35))
	view.PulseVel = 0
end

-- Where food should fly to: just in front of the mouth (world space).
function MonsterView.mouthPosition(serverModel): Vector3?
	local view = views[serverModel]
	local ground = serverModel:GetAttribute("Ground")
	if not ground then
		return nil
	end
	local s = if view then view.Scale else Config.scaleForSize(serverModel:GetAttribute("MonsterSize") or 1)
	return (ground * CFrame.new(Vector3.new(0, 2.6, -3.0) * s)).Position
end

function MonsterView.scaleOf(serverModel): number
	local view = views[serverModel]
	return if view then view.Scale else 1
end

function MonsterView.start()
	local viewFolder = Instance.new("Folder")
	viewFolder.Name = "MonsterViews"
	viewFolder.Parent = workspace

	local folder = workspace:WaitForChild("Monsters")
	folder.ChildAdded:Connect(createView)
	folder.ChildRemoved:Connect(removeView)
	for _, child in folder:GetChildren() do
		task.spawn(createView, child)
	end

	local last = os.clock()
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		local dt = math.min(t - last, 0.1)
		last = t
		if dirty then
			rebuildLists()
		end
		local n = 0
		for _, view in views do
			n = stepView(view, t, dt, n)
		end
		if n == #allParts and n > 0 then
			workspace:BulkMoveTo(allParts, allCFrames, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end)
end

return MonsterView
