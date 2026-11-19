-- VFX Lab client: the test panel. Every effect goes through the same code a game uses:
-- server cues -> VFXClient -> Effects (VFXKit recipes), and KitRunner + CameraGuard for Studio kits.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local VFX = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VFX")
local Quality = require(VFX:WaitForChild("Quality"))
local Cues = require(VFX:WaitForChild("Cues"))
local Effects = require(VFX:WaitForChild("Effects"))
local CameraGuard = require(VFX:WaitForChild("CameraGuard"))
local KitRunner = require(VFX:WaitForChild("KitRunner"))
local Assets = require(VFX:WaitForChild("Assets"))
local EclipseRend = require(VFX:WaitForChild("Kits"):WaitForChild("EclipseRend"))
local VFXClient = require(script.Parent:WaitForChild("VFXClient"))
local Perf = require(script.Parent:WaitForChild("Perf"))
local LabTests = require(script.Parent:WaitForChild("LabTests"))

-- Automated runs (dev/rbxtest): the server-side harness asks this client to run the local suite.
local TestHarnessClient = require(game:GetService("ReplicatedStorage"):WaitForChild("TestHarness"):WaitForChild("TestHarnessClient"))
TestHarnessClient.register("local", function()
	return LabTests.runLocal() or {}
end)
TestHarnessClient.start()

local player = Players.LocalPlayer
local request = ReplicatedStorage:WaitForChild("VFXLabRequest")

VFXClient.start()
Perf.start()

---------------------------------------------------------------------------
-- Kit template (Studio-kit route). EclipseRend needs no meshes, so it can be built at runtime;
-- textures without an uploaded id (library/manifest.json) draw blank but timing and camera still test.
---------------------------------------------------------------------------
local templates = ReplicatedStorage:FindFirstChild("VFXTemplates")
if not templates then
	templates = Instance.new("Folder")
	templates.Name = "VFXTemplates"
	templates.Parent = ReplicatedStorage -- client-local copy; a real game builds it in Edit mode and saves it
end
local eclipseTemplate = nil
task.spawn(function()
	eclipseTemplate = KitRunner.prepare(EclipseRend, templates, Assets)
end)

local function dummy(): Model?
	return workspace:FindFirstChild("Dummy") :: Model?
end

local function kitOrigin(): CFrame?
	-- the move is cast from the player's feet toward the dummy
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local d = dummy()
	local target = d and d:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return nil
	end
	local feet = root.Position - Vector3.new(0, 3, 0)
	local look = if target then Vector3.new(target.Position.X, feet.Y, target.Position.Z) else feet + root.CFrame.LookVector
	return CFrame.lookAt(feet, look)
end

---------------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------------
local status = "" -- last message shown in the panel
local function say(text: string)
	status = text
	print("[VFXLab] " .. text)
end

local function ask(action: string, target: string)
	request:FireServer(action, target)
end

local function playKit(cinematic: boolean)
	if not eclipseTemplate then
		say("kit template not ready (see Output for warnings)")
		return
	end
	local origin = kitOrigin()
	if not origin then
		return
	end
	local h, gotCamera = KitRunner.play(EclipseRend, eclipseTemplate, origin, { cinematic = cinematic })
	if not h then
		say("kit skipped: MaxKits reached for " .. Quality.get().Name)
	elseif cinematic and not gotCamera then
		say("cinematic played WITHOUT camera (busy, or quality " .. Quality.get().Name .. " has ScreenEffects off)")
	else
		say(if cinematic then "cinematic: camera guarded, restores after " .. EclipseRend.DURATION .. " s" else "kit played, no screen effects")
	end
end

-- Reproduces the upstream bug on purpose: the raw kit takes the camera and never gives it back.
local function rawKitRepro()
	local origin = kitOrigin()
	if not (origin and eclipseTemplate) then
		return
	end
	local h = EclipseRend.spawn(origin, eclipseTemplate)
	EclipseRend.play(h)
	say("raw kit: camera will stay Scriptable after it ends. Press 'Reset camera' to recover.")
end

local function resetCamera()
	CameraGuard.releaseAll()
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
	say("camera reset to Custom")
end

local dusk = false
local function toggleLighting()
	dusk = not dusk
	Lighting.ClockTime = if dusk then 19.6 else 14
	Lighting.Brightness = if dusk then 0.8 else 2
	say(if dusk then "dusk: check the carrier glow reads in the dark" else "day")
end

local stressModels = {}
local function clearStress()
	for _, m in stressModels do
		m:Destroy() -- Effects detaches their auras via AncestryChanged
	end
	table.clear(stressModels)
end

local function stressCarriers(count: number)
	clearStress()
	local d = dummy()
	if not d then
		return
	end
	d.Archivable = true
	for i = 1, count do
		local clone = d:Clone()
		local a = i / count * math.pi * 2
		clone:PivotTo(CFrame.new(math.cos(a) * 18, 4.2, math.sin(a) * 18 - 14))
		clone.Name = "StressCarrier"
		-- a clone copies the dummy's tag and attribute; strip them so VFXClient doesn't add a second aura
		CollectionService:RemoveTag(clone, Cues.ACTOR_TAG)
		clone:SetAttribute(Cues.CARRY_ATTRIBUTE, nil)
		clone.Parent = workspace
		table.insert(stressModels, clone)
		Effects.attach("stress" .. i, "SunAura", clone:FindFirstChild("HumanoidRootPart"), { keepLights = true })
	end
	say(count .. " local carriers with SunAura (client-only stress test)")
end

local benchmarking = false
local function benchmark()
	if benchmarking then
		return
	end
	benchmarking = true
	local before = Quality.get().Name
	local lines = { "preset | avg FPS | p95 ms | worst ms | bursts played/culled/capped" }
	stressCarriers(10)
	local d = dummy()
	local center = if d then d:GetPivot().Position else Vector3.zero
	for _, name in Quality.Order do
		Quality.set(name)
		task.wait(0.5)
		local s0 = Effects.stats()
		local running = true
		task.spawn(function()
			while running do
				local offset = Vector3.new(math.random(-12, 12), math.random(1, 6), math.random(-12, 12))
				Effects.burst("SunBurst", center + offset)
				task.wait(0.15)
			end
		end)
		local m = Perf.measure(5)
		running = false
		local s1 = Effects.stats()
		table.insert(lines, string.format("%s | %.0f | %.1f | %.1f | %d/%d/%d", name, m.avgFps, m.p95Ms, m.worstMs,
			s1.Played - s0.Played, s1.Culled - s0.Culled, s1.Capped - s0.Capped))
		task.wait(1)
	end
	clearStress()
	Quality.set(before)
	print("[VFXLab] benchmark (10 aura carriers + a SunBurst every 0.15 s, 5 s per preset):\n" .. table.concat(lines, "\n"))
	say("benchmark done: results in Output (F9)")
	benchmarking = false
end

---------------------------------------------------------------------------
-- Panel
---------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "VFXLab"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Position = UDim2.fromOffset(10, 10)
panel.Size = UDim2.fromOffset(300, 0)
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
panel.BackgroundTransparency = 0.1
panel.Parent = gui
Instance.new("UICorner").Parent = panel
local pad = Instance.new("UIPadding")
pad.PaddingTop, pad.PaddingBottom, pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 8)
pad.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel

local order = 0
local function label(text: string, height: number?)
	order += 1
	local l = Instance.new("TextLabel")
	l.LayoutOrder = order
	l.Size = UDim2.new(1, 0, 0, height or 18)
	l.BackgroundTransparency = 1
	l.TextColor3 = Color3.fromRGB(255, 214, 110)
	l.Font = Enum.Font.GothamBold
	l.TextSize = 14
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Top
	l.TextWrapped = true
	l.Text = text
	l.Parent = panel
	return l
end

local bindings = {}
local function button(text: string, key: Enum.KeyCode?, fn: () -> ())
	order += 1
	local b = Instance.new("TextButton")
	b.LayoutOrder = order
	b.Size = UDim2.new(1, 0, 0, 30)
	b.BackgroundColor3 = Color3.fromRGB(52, 56, 78)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.Gotham
	b.TextSize = 14
	b.Text = if key then `[{key.Name}] {text}` else text
	b.Parent = panel
	Instance.new("UICorner").Parent = b
	b.Activated:Connect(fn)
	if key then
		bindings[key] = fn
	end
	return b
end

label("SNATCH THE SUN EFFECTS (server cues)")
button("Aura on dummy (toggle)", Enum.KeyCode.One, function() ask("Aura", "Dummy") end)
button("Steal burst on dummy", Enum.KeyCode.Two, function() ask("Burst", "Dummy") end)
button("Victory on dummy", Enum.KeyCode.Three, function() ask("Victory", "Dummy") end)
button("Steal: sun moves dummy <-> me", Enum.KeyCode.Four, function() ask("Steal", "Me") end)
button("Burst at 150 studs (culling)", Enum.KeyCode.Five, function() ask("FarBurst", "Me") end)
button("Burst storm (server cap test)", Enum.KeyCode.Six, function() ask("Storm", "Dummy") end)
label("QUALITY")
local qualityLabel = label("")
button("Cycle Low / Medium / High", Enum.KeyCode.Q, function() say("quality: " .. Quality.cycle().Name) end)
label("CAMERA (Studio kit: EclipseRend)")
button("Kit, gameplay mode (no camera)", Enum.KeyCode.Seven, function() playKit(false) end)
button("Kit, cinematic (guarded camera)", Enum.KeyCode.C, function() playKit(true) end)
button("Two cinematics at once (guard test)", Enum.KeyCode.V, function()
	playKit(true)
	task.delay(0.4, function() playKit(true) end)
end)
button("Repro: raw kit (camera gets stuck)", nil, rawKitRepro)
button("Reset camera", Enum.KeyCode.R, resetCamera)
label("PERFORMANCE")
button("Day / dusk lighting", Enum.KeyCode.L, toggleLighting)
button("Stress: 10 local carriers", Enum.KeyCode.Eight, function() stressCarriers(10) end)
button("Benchmark all presets (~20 s)", Enum.KeyCode.B, function() task.spawn(benchmark) end)
button("Clear all effects", Enum.KeyCode.X, function()
	clearStress()
	Effects.clear()
	ask("Clear", "Me")
	say("cleared")
end)
label("AUTOMATED TESTS (results: VFXLAB_RESULTS line in Output)")
button("Run local test suite (~60 s, kills you once)", Enum.KeyCode.T, function()
	say("local test suite running...")
	task.spawn(function()
		local r = LabTests.runLocal()
		if r then
			local fails = 0
			for _, x in r do
				if x.status == "FAIL" then
					fails += 1
				end
			end
			say(string.format("local suite: %d checks, %d FAIL (Output has details)", #r, fails))
		end
	end)
end)
button("Run replication test (2+ clients)", Enum.KeyCode.Y, function()
	LabTests.runReplication()
	say("replication test running on the server; see the server Output")
end)
local statsLabel = label("", 150)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	local fn = bindings[input.KeyCode]
	if fn then
		fn()
	end
end)

task.spawn(function()
	while gui.Parent do
		local p = Perf.snapshot()
		local s = Effects.stats()
		local camera = workspace.CurrentCamera
		qualityLabel.Text = "Current: " .. Quality.get().Name
		statsLabel.Text = string.format(
			"FPS %.0f  worst %.1f ms  mem %.0f MB\nbursts live %d  loops %d (%d emitters)\nplayed %d  culled %d  capped %d\nkits playing %d\ncamera %s%s\n%s",
			p.fps, p.worstMs, p.memoryMb, s.ActiveBursts, s.Attached, s.LoopEmitters,
			s.Played, s.Culled, s.Capped, KitRunner.playing(),
			camera.CameraType.Name, if CameraGuard.isBusy() then " (guarded: " .. CameraGuard.ownerName() .. ")" else "",
			status
		)
		task.wait(0.25)
	end
end)

say("ready. Press 1-8, Q, C, V, R, L, B, X or use the buttons.")
