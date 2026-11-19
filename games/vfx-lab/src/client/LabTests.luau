-- VFX Lab automated tests (client side). Run inside a Studio play test; results print as one line
--   VFXLAB_RESULTS {json}
-- so they can be pasted into the Test Lab note or read with the Studio MCP's get_console_output.
--
-- Start from the panel ([T] local tests, [Y] replication test) or from Studio MCP execute_luau (Client):
--   require(game.Players.LocalPlayer.PlayerScripts.VFXLabClient.LabTests).runLocal()
--   require(game.Players.LocalPlayer.PlayerScripts.VFXLabClient.LabTests).freeze("SunBurst", 0.15)  -- for screenshots
--
-- Automated checks can prove instances, timing, camera state, counts and frame times. They cannot
-- judge LOOKS: take screenshots (freeze()) and look at them.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")

local VFX = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VFX")
local Quality = require(VFX:WaitForChild("Quality"))
local Effects = require(VFX:WaitForChild("Effects"))
local CameraGuard = require(VFX:WaitForChild("CameraGuard"))
local KitRunner = require(VFX:WaitForChild("KitRunner"))
local Assets = require(VFX:WaitForChild("Assets"))
local Cues = require(VFX:WaitForChild("Cues"))
local EclipseRend = require(VFX:WaitForChild("Kits"):WaitForChild("EclipseRend"))
local VFXClient = require(script.Parent:WaitForChild("VFXClient"))
local Perf = require(script.Parent:WaitForChild("Perf"))

local player = Players.LocalPlayer
local LabTests = {}

local testRemote = ReplicatedStorage:WaitForChild("VFXTestCmd")
local probeRemote = ReplicatedStorage:WaitForChild("VFXTestProbe")

local results = {}
-- Most extra p95 frame time (ms) a Snatch-the-Sun-sized effect load may add over the no-effects baseline.
local PERF_P95_BUDGET_MS = 2
local function record(test: string, name: string, pass: boolean?, detail)
	local status = if pass == nil then "INFO" elseif pass then "PASS" else "FAIL"
	table.insert(results, { test = test, check = name, status = status, detail = detail })
	print(string.format("[VFXLab test] %-5s %s / %s %s", status, test, name, if detail ~= nil then HttpService:JSONEncode(detail) else ""))
end

local function dummyRoot(): BasePart?
	local d = workspace:FindFirstChild("Dummy")
	return d and d:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function waitFor(cond: () -> boolean, timeout: number): boolean
	local t0 = os.clock()
	while os.clock() - t0 < timeout do
		if cond() then
			return true
		end
		task.wait(0.05)
	end
	return cond()
end

---------------------------------------------------------------------------
-- 1. Rendering: what each effect actually builds, per quality preset
---------------------------------------------------------------------------
local function testRendering()
	local root = dummyRoot()
	if not root then
		record("render", "dummy present", false)
		return
	end
	for _, preset in Quality.Order do
		Quality.set(preset)
		for _, name in { "SunBurst", "SunVictory" } do
			Effects.burst(name, root.Position, { important = true })
			task.wait(0.05)
			local emitters, lights, textures = 0, 0, {}
			for _, d in (workspace:FindFirstChild("VFXRuntime") or workspace):GetDescendants() do
				if d:IsA("ParticleEmitter") then
					emitters += 1
					textures[d.Texture] = true
				elseif d:IsA("PointLight") then
					lights += 1
				end
			end
			local n = 0
			for _ in textures do
				n += 1
			end
			record("render", `{name} builds on {preset}`, emitters > 0, { emitters = emitters, lights = lights, distinctTextures = n })
			task.wait(2)
		end
	end
	Quality.set("Medium")
end

-- Phase-frozen capture (the roblox-vfx verify-loop technique): play, wait `age` seconds, then
-- TimeScale = 0 on every emitter so a screenshot lands on that exact phase. Call unfreeze() after.
function LabTests.freeze(name: string, age: number)
	local root = dummyRoot()
	if not root then
		return false
	end
	Effects.clear()
	if name == "SunAura" then
		Effects.attach("freeze", "SunAura", root, { keepLights = true })
	else
		Effects.burst(name, root.Position, { important = true, lifetime_mul = 1 })
	end
	task.wait(age)
	for _, d in workspace:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			d.TimeScale = 0
		end
	end
	return true
end

function LabTests.unfreeze()
	for _, d in workspace:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			d.TimeScale = 1
		end
	end
	Effects.clear()
end

---------------------------------------------------------------------------
-- 3. Camera: restored after a cinematic, never two owners, restored on death and respawn
---------------------------------------------------------------------------
local function cameraOk(camera: Camera): boolean
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return camera.CameraType == Enum.CameraType.Custom and camera.CameraSubject == humanoid
end

local function kitOrigin(): CFrame?
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root and root.CFrame * CFrame.new(0, -3, 0)
end

local function testCamera(template)
	local camera = workspace.CurrentCamera
	if not template then
		record("camera", "kit template ready", false)
		return
	end
	Quality.set("High") -- screen effects allowed
	local fov0 = camera.FieldOfView

	-- a) restored after the effect
	local origin = kitOrigin()
	local _, got = KitRunner.play(EclipseRend, template, origin :: CFrame, { cinematic = true })
	record("camera", "cinematic took the camera", got)
	local tookScriptable = waitFor(function()
		return camera.CameraType == Enum.CameraType.Scriptable
	end, 0.5)
	record("camera", "kit switched camera to Scriptable", tookScriptable)
	local restored = waitFor(function()
		return not CameraGuard.isBusy() and cameraOk(camera)
	end, EclipseRend.DURATION + 2)
	record("camera", "restored after effect", restored, { type = camera.CameraType.Name, fovBefore = fov0, fovAfter = camera.FieldOfView })
	record("camera", "FOV restored", math.abs(camera.FieldOfView - fov0) < 0.01, { before = fov0, after = camera.FieldOfView })

	-- b) a second cinematic while one is running gets no camera
	task.wait(0.5)
	KitRunner.play(EclipseRend, template, kitOrigin() :: CFrame, { cinematic = true })
	task.wait(0.2)
	local _, got2 = KitRunner.play(EclipseRend, template, kitOrigin() :: CFrame, { cinematic = true })
	record("camera", "second cinematic denied the camera", got2 == false)
	waitFor(function()
		return not CameraGuard.isBusy()
	end, EclipseRend.DURATION + 2)
	task.wait(1.5)

	-- c) death during a cinematic: restored at once, and still right after respawn
	local oldCharacter = player.Character
	KitRunner.play(EclipseRend, template, kitOrigin() :: CFrame, { cinematic = true })
	task.wait(0.4)
	testRemote:FireServer("KillMe")
	local died = waitFor(function()
		local h = oldCharacter and oldCharacter:FindFirstChildOfClass("Humanoid")
		return h == nil or h.Health <= 0
	end, 3)
	task.wait(0.15)
	record("camera", "death released the guard", died and not CameraGuard.isBusy(), { died = died, type = camera.CameraType.Name })
	local respawned = waitFor(function()
		return player.Character ~= nil and player.Character ~= oldCharacter
			and player.Character:FindFirstChildOfClass("Humanoid") ~= nil
	end, Players.RespawnTime + 6)
	task.wait(1)
	record("camera", "correct after respawn", respawned and cameraOk(camera), { respawned = respawned, type = camera.CameraType.Name })
	Quality.set("Medium")
end

---------------------------------------------------------------------------
-- 4. Sun visibility: the carrier aura keeps its emitters and its light on every preset
---------------------------------------------------------------------------
local function testVisibility()
	local root = dummyRoot()
	if not root then
		record("visibility", "dummy present", false)
		return
	end
	local spec = Cues.States.CarryingSun
	for _, preset in Quality.Order do
		Quality.set(preset)
		local handle = Effects.attach("vis", spec.Recipe, root, { keepLights = spec.KeepLights })
		task.wait(1)
		local enabled, rate = 0, 0
		for _, e in handle.emitters do
			if e.Enabled then
				enabled += 1
				rate += e.Rate
			end
		end
		local lightOn = false
		for _, l in handle.lights do
			if l.Enabled and l.Brightness > 0 then
				lightOn = true
			end
		end
		record("visibility", `aura emitters on {preset}`, enabled == #handle.emitters and enabled > 0, { enabled = enabled, totalRate = rate })
		record("visibility", `aura light on {preset}`, lightOn)
		Effects.detach("vis", true)
	end
	Quality.set("Medium")
end

---------------------------------------------------------------------------
-- 5. Performance: frame times on Low and Medium under a Snatch-the-Sun-sized load
---------------------------------------------------------------------------
local function testPerformance()
	local root = dummyRoot()
	if not root then
		return
	end
	-- Baseline with no effects. Studio (and most devices) cap the frame rate, so absolute
	-- frame time sits at the cap plus jitter (e.g. p95 ~17.9 ms at a 60 FPS cap) whether or not
	-- effects run. We judge the cost the effects ADD on top of this baseline instead.
	Effects.clear()
	task.wait(1)
	local base = Perf.measure(5)
	record("performance", "baseline (no effects)", nil, {
		avgFps = math.floor(base.avgFps),
		p95Ms = math.floor(base.p95Ms * 10) / 10,
		worstMs = math.floor(base.worstMs * 10) / 10,
	})
	for _, preset in { "Low", "Medium", "High" } do
		Quality.set(preset)
		Effects.attach("perf", "SunAura", root, { keepLights = true })
		local running = true
		task.spawn(function()
			while running do
				Effects.burst("SunBurst", root.Position + Vector3.new(math.random(-10, 10), math.random(1, 5), math.random(-10, 10)))
				task.wait(0.25) -- ~4 steals a second: far above a real round
			end
		end)
		local m = Perf.measure(5)
		running = false
		Effects.detach("perf", true)
		-- Pass if the effects add at most PERF_P95_BUDGET_MS to p95 frame time and keep at least
		-- 95 % of the baseline frame rate.
		local addedMs = m.p95Ms - base.p95Ms
		local fpsRatio = if base.avgFps > 0 then m.avgFps / base.avgFps else 1
		record("performance", `{preset}: 1 aura + SunBurst every 0.25 s`, addedMs <= PERF_P95_BUDGET_MS and fpsRatio >= 0.95, {
			avgFps = math.floor(m.avgFps),
			p95Ms = math.floor(m.p95Ms * 10) / 10,
			addedP95Ms = math.floor(addedMs * 10) / 10,
			fpsVsBaseline = math.floor(fpsRatio * 100) / 100,
			worstMs = math.floor(m.worstMs * 10) / 10,
			savedQuality = (function()
				local ok, v = pcall(function()
					return UserSettings():GetService("UserGameSettings").SavedQualityLevel.Name
				end)
				return if ok then v else "?"
			end)(),
		})
		task.wait(1.5)
	end
	Quality.set("Medium")
end

---------------------------------------------------------------------------
-- 6. Cleanup and memory: hundreds of effects, then nothing left behind
---------------------------------------------------------------------------
local function snapshot()
	local root = dummyRoot()
	local attachments = 0
	if root then
		for _, c in root:GetChildren() do
			if c:IsA("Attachment") then
				attachments += 1
			end
		end
	end
	local kitFolders = 0
	for _, c in workspace:GetChildren() do
		if c:IsA("Folder") and c.Name == EclipseRend.NAME then
			kitFolders += 1
		end
	end
	return {
		instances = Stats.InstanceCount,
		runtimeChildren = (function()
			local f = workspace:FindFirstChild("VFXRuntime")
			return if f then #f:GetChildren() else 0
		end)(),
		dummyAttachments = attachments,
		kitFolders = kitFolders,
		particleMb = math.floor(Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.GraphicsParticles) * 100) / 100,
		totalMb = math.floor(Stats:GetTotalMemoryUsageMb()),
	}
end

local function testCleanup(template)
	local root = dummyRoot()
	if not root then
		return
	end
	Effects.clear()
	Quality.set("High")
	task.wait(2)
	local before = snapshot()
	local names = { "SunBurst", "SunVictory" }
	for i = 1, 200 do
		Effects.burst(names[i % 2 + 1], root.Position + Vector3.new(0, i % 5, 0), { important = true })
		if i % 4 == 0 then
			Effects.attach("cycle", "SunAura", root, { keepLights = true })
		elseif i % 4 == 2 then
			Effects.detach("cycle")
		end
		task.wait(0.02)
	end
	if template then
		for _ = 1, 3 do
			KitRunner.play(EclipseRend, template, kitOrigin() :: CFrame, {})
			task.wait(0.3)
		end
	end
	local during = snapshot()
	Effects.detach("cycle")
	task.wait(EclipseRend.DURATION + 3) -- longest particle life + kit cleanup
	local after = snapshot()
	local s = Effects.stats()
	record("cleanup", "runtime folder empty", after.runtimeChildren == 0, { before = before.runtimeChildren, during = during.runtimeChildren, after = after.runtimeChildren })
	record("cleanup", "no attachments left on dummy", after.dummyAttachments == before.dummyAttachments, { before = before.dummyAttachments, after = after.dummyAttachments })
	record("cleanup", "no kit folders left", after.kitFolders == 0, { after = after.kitFolders })
	record("cleanup", "runner counters back to zero", s.ActiveBursts == 0 and s.Attached == 0, { activeBursts = s.ActiveBursts, attached = s.Attached })
	record("cleanup", "instance count returns to baseline (+/-50)", math.abs(after.instances - before.instances) <= 50, { before = before.instances, during = during.instances, after = after.instances })
	record("cleanup", "memory (informational)", nil, { totalMbBefore = before.totalMb, totalMbAfter = after.totalMb, particleMbBefore = before.particleMb, particleMbDuring = during.particleMb, particleMbAfter = after.particleMb })
	Quality.set("Medium")
end

---------------------------------------------------------------------------
-- Entry points
---------------------------------------------------------------------------
local running = false
function LabTests.runLocal()
	if running then
		return nil
	end
	running = true
	table.clear(results)
	Effects.clear()
	local templates = ReplicatedStorage:FindFirstChild("VFXTemplates")
	local template = templates and KitRunner.prepare(EclipseRend, templates, Assets)
	local startLighting = Lighting.ClockTime
	record("env", "client", nil, { device = if game:GetService("UserInputService").TouchEnabled then "touch" else "desktop", quality = Quality.get().Name })
	testRendering()
	testVisibility()
	testCleanup(template)
	testPerformance()
	testCamera(template) -- last: it kills and respawns the character
	Lighting.ClockTime = startLighting
	local fails = 0
	for _, r in results do
		if r.status == "FAIL" then
			fails += 1
		end
	end
	print(string.format("[VFXLab test] local suite done: %d checks, %d FAIL", #results, fails))
	print("VFXLAB_RESULTS " .. HttpService:JSONEncode({ suite = "local", results = results }))
	running = false
	return results
end

function LabTests.runReplication()
	testRemote:FireServer("RunReplication")
end

-- Replication probes from the server: report what THIS client actually shows.
probeRemote.OnClientEvent:Connect(function(id, kind, model)
	if kind == "state" then
		probeRemote:FireServer(id, typeof(model) == "Instance" and VFXClient.hasState(model, Cues.CARRY_ATTRIBUTE))
	elseif kind == "played" then
		probeRemote:FireServer(id, Effects.stats().Played)
	end
end)

return LabTests
