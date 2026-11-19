-- KitRunner: plays roblox-vfx Studio kits (sim/studio_kit.js output) safely in a game.
-- Uses only the kit's own API: Kit.buildTemplate, Kit.preload, Kit.spawn, Kit.play, Kit.DURATION, Kit.NEEDS.
--
--   local template = KitRunner.prepare(Kit, templatesFolder, Assets)   -- once, at join (yields)
--   KitRunner.play(Kit, template, origin, { caster = character, cinematic = true })
--
-- What it adds:
--   * cinematic = false (default): spawn(..., {screen = false}) - no camera, grade or overlay. Use it
--     for every ordinary move and for anything another player casts.
--   * cinematic = true: the screen layer plays only if quality allows it AND CameraGuard grants the
--     camera; the camera is restored after Kit.DURATION (kits never restore it themselves).
--   * quality: kits' burst counts (EmitCount attribute) and starting Rate scale with the preset;
--     flash lights are dropped on Low. Timeline "set Rate" events inside a kit are NOT scaled.
--   * a cap on kits playing at once (Quality MaxKits).
local Workspace = game:GetService("Workspace")

local Quality = require(script.Parent.Quality)
local CameraGuard = require(script.Parent.CameraGuard)

local KitRunner = {}

local playing = 0
local prepared = {} -- [Kit.NAME] = template

-- Find the template built in Edit mode, or build it now when the kit can be built at runtime.
-- A kit that needs meshes (Kit.NEEDS.meshes) must be built in Edit mode: game scripts may not
-- set MeshPart.MeshId or SurfaceAppearance maps (roblox-vfx studio_kit.js).
function KitRunner.prepare(Kit, templatesFolder: Instance, assets)
	if prepared[Kit.NAME] then
		return prepared[Kit.NAME]
	end
	local template = templatesFolder:FindFirstChild(Kit.NAME)
	if not template then
		if #Kit.NEEDS.meshes > 0 then
			warn(`[KitRunner] {Kit.NAME} needs meshes: build its template in Edit mode (command bar) and save the place`)
			return nil
		end
		local ok, result = pcall(Kit.buildTemplate, assets, templatesFolder)
		if not ok then
			warn(`[KitRunner] building {Kit.NAME} at runtime failed: {result}`)
			return nil
		end
		template = result
	end
	local failed = Kit.preload(template)
	if failed > 0 then
		warn(`[KitRunner] {Kit.NAME}: {failed} asset(s) failed to preload (missing ids draw blank)`)
	end
	prepared[Kit.NAME] = template
	return template
end

local function applyQuality(h, q)
	for _, d in h.folder:GetDescendants() do
		if d:IsA("ParticleEmitter") then
			local count = d:GetAttribute("EmitCount")
			if count then
				d:SetAttribute("EmitCount", math.max(1, math.floor(count * q.EmitMul)))
			end
			d.Rate *= q.RateMul
		elseif (d:IsA("PointLight") or d:IsA("SpotLight")) and not q.DecorativeLights then
			d:Destroy()
		end
	end
end

function KitRunner.play(Kit, template: Instance, origin: CFrame, opts)
	opts = opts or {}
	local q = Quality.get()
	if playing >= q.MaxKits then
		return nil
	end
	local token = nil
	if opts.cinematic and q.ScreenEffects then
		token = CameraGuard.acquire(Kit.NAME, Kit.DURATION + 3)
	end
	local h = Kit.spawn(origin, template, { game = true, screen = token ~= nil })
	applyQuality(h, q)
	h.caster = opts.caster
	h.target = opts.target
	playing += 1
	Kit.play(h) -- returns at once; the kit destroys h.folder DURATION + 1 s later
	task.delay(Kit.DURATION + 1.2, function()
		playing -= 1
		if h.folder and h.folder.Parent then
			h.folder:Destroy() -- belt and braces: never leave a kit folder in the world
		end
	end)
	if token then
		task.delay(Kit.DURATION + 0.5, function()
			CameraGuard.release(token)
		end)
	end
	return h, token ~= nil
end

function KitRunner.playing(): number
	return playing
end

-- Count kit folders currently in workspace (for the perf panel).
function KitRunner.liveFolders(kitNames: { string }): number
	local n = 0
	for _, name in kitNames do
		for _, child in Workspace:GetChildren() do
			if child.Name == name and child:IsA("Folder") then
				n += 1
			end
		end
	end
	return n
end

return KitRunner
