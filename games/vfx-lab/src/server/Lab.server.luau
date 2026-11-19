-- VFX Lab server: a small test arena, a dummy character, and a LAB-ONLY request remote that lets
-- the test panel ask the server to fire cues. In a real game, gameplay code calls VFXServer
-- directly after validating the action; there is no client "please play an effect" remote.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VFXServer = require(script.Parent.VFXServer)
local Cues = require(ReplicatedStorage.Shared.VFX.Cues)

---------------------------------------------------------------------------
-- Arena: neutral floor, distance markers along +X for the culling test, a sun pedestal
---------------------------------------------------------------------------
local arena = Instance.new("Folder")
arena.Name = "VFXLabArena"

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		p[k] = v
	end
	p.Parent = arena
	return p
end

local old = workspace:FindFirstChild("Baseplate")
if old and old:IsA("BasePart") then
	old:Destroy()
end

part({ Name = "Floor", Size = Vector3.new(600, 1, 160), CFrame = CFrame.new(220, -0.5, 0), Color = Color3.fromRGB(96, 104, 120) })
part({ Name = "Pedestal", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 14, 14), CFrame = CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = Color3.fromRGB(70, 76, 92) })
part({ Name = "SunProp", Shape = Enum.PartType.Ball, Size = Vector3.new(2.5, 2.5, 2.5), CFrame = CFrame.new(0, 4, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 200, 61), CanCollide = false })

for _, d in { 25, 50, 100, 150, 250, 400 } do
	local marker = part({ Name = `Marker{d}`, Size = Vector3.new(1, 8, 1), CFrame = CFrame.new(d, 4, -20), Color = Color3.fromRGB(230, 230, 240) })
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(120, 36)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 6, 0)
	gui.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Text = `{d} studs`
	label.Parent = gui
	gui.Parent = marker
end

local labSpawn = Instance.new("SpawnLocation")
labSpawn.Name = "LabSpawn"
labSpawn.Anchored = true
labSpawn.Neutral = true
labSpawn.Duration = 0
labSpawn.Size = Vector3.new(8, 1, 8)
labSpawn.CFrame = CFrame.new(0, 0.5, 26)
labSpawn.Parent = arena
arena.Parent = workspace

---------------------------------------------------------------------------
-- Dummy character (default R15 avatar, anchored so it stands still)
---------------------------------------------------------------------------
local dummy
do
	local ok, result = pcall(function()
		return Players:CreateHumanoidModelFromDescriptionAsync(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
	end)
	if ok and result then
		dummy = result
		dummy.Name = "Dummy"
		dummy:PivotTo(CFrame.new(0, 4.2, -14) * CFrame.Angles(0, math.pi, 0))
		local root = dummy:FindFirstChild("HumanoidRootPart")
		if root then
			root.Anchored = true
		end
		dummy.Parent = workspace
		VFXServer.track(dummy)
	else
		warn("[VFXLab] could not create the dummy:", result)
	end
end

---------------------------------------------------------------------------
-- Lab-only request remote (validated + rate limited like any real remote)
---------------------------------------------------------------------------
local request = Instance.new("RemoteEvent")
request.Name = "VFXLabRequest"
request.Parent = ReplicatedStorage

local ACTIONS = { Aura = true, Burst = true, Victory = true, Steal = true, FarBurst = true, Storm = true, Clear = true }
local TARGETS = { Dummy = true, Me = true }

local buckets = {}
local function allow(player: Player): boolean
	local now = os.clock()
	local b = buckets[player] or { Tokens = 6, Last = now }
	buckets[player] = b
	b.Tokens = math.min(6, b.Tokens + (now - b.Last) * 4)
	b.Last = now
	if b.Tokens < 1 then
		return false
	end
	b.Tokens -= 1
	return true
end
Players.PlayerRemoving:Connect(function(player)
	buckets[player] = nil
end)

local function modelFor(player: Player, target: string): Model?
	if target == "Dummy" then
		return dummy
	end
	return player.Character
end

local function rootOf(model: Model?): BasePart?
	return model and model:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function feet(model: Model): Vector3
	local root = rootOf(model) :: BasePart
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local hip = humanoid and humanoid.HipHeight or 2
	return root.Position - Vector3.new(0, hip + root.Size.Y / 2, 0)
end

request.OnServerEvent:Connect(function(player, action, target)
	if not allow(player) then
		return
	end
	if type(action) ~= "string" or not ACTIONS[action] or type(target) ~= "string" or not TARGETS[target] then
		return
	end
	local model = modelFor(player, target)
	local root = rootOf(model)
	if action == "Clear" then
		for _, m in { dummy, player.Character } do
			if m then
				VFXServer.setCarrying(m, false)
			end
		end
		return
	end
	if not model or not root then
		return
	end
	if action == "Aura" then
		VFXServer.setCarrying(model, model:GetAttribute(Cues.CARRY_ATTRIBUTE) ~= true)
	elseif action == "Burst" then
		VFXServer.oneShot("SunBurst", root.Position, 1)
	elseif action == "Victory" then
		VFXServer.oneShot("SunVictory", feet(model), 1)
	elseif action == "Steal" then
		-- the Snatch the Sun handoff: burst where the sun was, the aura moves to the thief
		local thief = player.Character
		if dummy and thief and rootOf(thief) then
			local fromModel = if dummy:GetAttribute(Cues.CARRY_ATTRIBUTE) then dummy else thief
			local toModel = if fromModel == dummy then thief else dummy
			VFXServer.oneShot("SunBurst", (rootOf(fromModel) :: BasePart).Position, 1.4)
			VFXServer.setCarrying(fromModel, false)
			VFXServer.setCarrying(toModel, true)
		end
	elseif action == "FarBurst" then
		VFXServer.oneShot("SunBurst", Vector3.new(150, 4, -20), 1) -- at the 150-stud marker: culled on Low
	elseif action == "Storm" then
		-- 30 requests in a second: VFXServer's MaxPerSecond (10) must drop the extras
		task.spawn(function()
			local sent = 0
			for _ = 1, 30 do
				local offset = Vector3.new(math.random(-14, 14), math.random(2, 8), math.random(-14, 14))
				if VFXServer.oneShot("SunBurst", root.Position + offset, 0.8) then
					sent += 1
				end
				task.wait(1 / 30)
			end
			print(`[VFXLab] storm: {sent} of 30 SunBurst cues sent (server cap 10/s)`)
		end)
	end
end)
