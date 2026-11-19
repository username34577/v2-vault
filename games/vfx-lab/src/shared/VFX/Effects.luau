-- Effects: the client-side runner for VFXKit recipes (roblox-vfx harvest/recipe route).
-- Adds what a multiplayer game needs on top of VFXKit.build: quality scaling, distance culling,
-- a cap on simultaneous one-shots, and cleanup that cannot leak.
--
--   Effects.burst(name, at, opts)          one-shot at a Vector3 / CFrame / BasePart; cleans itself up
--   Effects.attach(key, name, part, opts)  looping effect on a part, one per key; follows quality changes
--   Effects.detach(key, immediate?)        stop emitting, let live particles finish, then destroy
--   Effects.clear()                        destroy everything (round end, teleport)
--   Effects.stats()                        counts for a perf panel
--
-- opts: scale, tint (Color3), power (burst multiplier), lifetime_mul, rate_mul,
--       important (skip culling and the cap: e.g. your own steal), keepLights (gameplay light: never stripped)
local Workspace = game:GetService("Workspace")

local VFXKit = require(script.Parent.VFXKit)
local Quality = require(script.Parent.Quality)

local Effects = {}

local folder: Folder? = nil
local serial = 0
local activeBursts = 0
local attached = {} -- [key] = {Handle, Part, Name, Opts, Conn}
local counters = { Played = 0, Culled = 0, Capped = 0 }

local function runtimeFolder(): Folder
	if not folder or not folder.Parent then
		local f = Instance.new("Folder")
		f.Name = "VFXRuntime"
		f.Parent = Workspace
		folder = f
	end
	return folder :: Folder
end

-- How long a recipe needs before everything it emitted is gone (seconds).
local function lifeOf(name: string, lifetimeMul: number?): number
	local recipe = VFXKit.Recipes[name]
	local longest = 0
	for _, layer in recipe.layers do
		local life = layer.props.Lifetime
		if life and life.NumberRange then
			longest = math.max(longest, life.NumberRange[2])
		end
	end
	return math.max(recipe.duration or 1, longest * (lifetimeMul or 1)) + 0.25
end

-- Quality: drop flash lights the player doesn't need. Constant (gameplay) lights stay when keepLights.
local function stripLights(handle, keepConstant: boolean)
	local lights = handle.lights
	for i = #lights, 1, -1 do
		local light = lights[i]
		if not (keepConstant and light:GetAttribute("EmitMode") == "constant") then
			light:Destroy()
			table.remove(lights, i)
		end
	end
end

local function host(cf: CFrame): Part
	local p = Instance.new("Part")
	p.Name = "VFXHost"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.CFrame = cf
	p.Parent = runtimeFolder()
	return p
end

local function positionOf(at): Vector3
	if typeof(at) == "Vector3" then
		return at
	elseif typeof(at) == "CFrame" then
		return at.Position
	end
	return at.Position
end

function Effects.burst(name: string, at, opts)
	opts = opts or {}
	if not VFXKit.Recipes[name] then
		warn("[Effects] no recipe named", name)
		return false
	end
	local q = Quality.get()
	local camera = Workspace.CurrentCamera
	if not opts.important then
		if camera and (camera.CFrame.Position - positionOf(at)).Magnitude > q.CullDistance then
			counters.Culled += 1
			return false
		end
		if activeBursts >= q.MaxBursts then
			counters.Capped += 1
			return false
		end
	end

	serial += 1
	local target
	local ownHost = false
	if typeof(at) == "Instance" and at:IsA("BasePart") and opts.follow then
		target = at -- moves with the part; tagged attachments are removed afterwards
	else
		target = host(if typeof(at) == "CFrame" then at else CFrame.new(positionOf(at)))
		ownHost = true
	end
	local handle = VFXKit.build(name, target, {
		scale = opts.scale,
		tint = opts.tint,
		lifetime_mul = opts.lifetime_mul,
		suffix = "_b" .. serial, -- independent copy: never replaces another burst
	})
	if not q.DecorativeLights then
		stripLights(handle, false)
	end
	handle.emit((opts.power or 1) * q.EmitMul)
	activeBursts += 1
	counters.Played += 1

	task.delay(lifeOf(name, opts.lifetime_mul), function()
		activeBursts -= 1
		if ownHost then
			target:Destroy()
		else
			handle.destroy()
		end
	end)
	return true
end

local function build(entry)
	local q = Quality.get()
	local o = entry.Opts
	local handle = VFXKit.build(entry.Name, entry.Part, {
		scale = o.scale,
		tint = o.tint,
		lifetime_mul = o.lifetime_mul,
		rate_mul = (o.rate_mul or 1) * q.RateMul,
		suffix = "_a_" .. entry.Key,
	})
	if not q.DecorativeLights then
		stripLights(handle, o.keepLights == true)
	end
	handle.setEnabled(true)
	entry.Handle = handle
end

function Effects.detach(key: string, immediate: boolean?)
	local entry = attached[key]
	if not entry then
		return
	end
	attached[key] = nil
	entry.Conn:Disconnect()
	local handle = entry.Handle
	if immediate or not entry.Part.Parent then
		handle.destroy()
		return
	end
	handle.setEnabled(false) -- stop emitting; live particles fade out naturally
	task.delay(lifeOf(entry.Name, entry.Opts.lifetime_mul), handle.destroy)
end

function Effects.attach(key: string, name: string, part: BasePart, opts)
	if not VFXKit.Recipes[name] then
		warn("[Effects] no recipe named", name)
		return nil
	end
	Effects.detach(key, true)
	local entry = { Key = key, Name = name, Part = part, Opts = opts or {} }
	build(entry)
	-- the part (a character) can vanish at any time: never leave the entry behind
	entry.Conn = part.AncestryChanged:Connect(function()
		if not part:IsDescendantOf(game) then
			Effects.detach(key, true)
		end
	end)
	attached[key] = entry
	return entry.Handle
end

function Effects.isAttached(key: string): boolean
	return attached[key] ~= nil
end

function Effects.clear()
	for key in attached do
		Effects.detach(key, true)
	end
	if folder then
		folder:ClearAllChildren()
	end
	activeBursts = 0
end

function Effects.stats()
	local emitters = 0
	for _, d in runtimeFolder():GetDescendants() do
		if d:IsA("ParticleEmitter") then
			emitters += 1
		end
	end
	local loops = 0
	for _, entry in attached do
		loops += #entry.Handle.emitters
	end
	return {
		Quality = Quality.get().Name,
		ActiveBursts = activeBursts,
		Attached = (function()
			local n = 0
			for _ in attached do
				n += 1
			end
			return n
		end)(),
		BurstEmitters = emitters,
		LoopEmitters = loops,
		Played = counters.Played,
		Culled = counters.Culled,
		Capped = counters.Capped,
	}
end

-- A quality change rebuilds every looping effect at the new rate (bursts finish as they are).
Quality.Changed:Connect(function()
	for _, entry in attached do
		entry.Handle.destroy()
		build(entry)
	end
end)

return Effects
