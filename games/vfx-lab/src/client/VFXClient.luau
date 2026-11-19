-- VFXClient: the client side of multiplayer-safe effects.
--   * one-shots: validates every "VFXCue" payload, then Effects.burst (quality, culling, caps, cleanup)
--   * state: watches tagged actor models' attributes and attaches/detaches looping effects
-- Start once from a LocalScript: require(script.Parent.VFXClient).start()
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VFX = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VFX")
local Cues = require(VFX:WaitForChild("Cues"))
local Effects = require(VFX:WaitForChild("Effects"))

local VFXClient = {}

local keys = {} -- [model] = key
local serial = 0

local function keyFor(model: Model): string
	if not keys[model] then
		serial += 1
		keys[model] = "actor" .. serial
	end
	return keys[model]
end

local function refreshState(model: Model)
	for attribute, spec in Cues.States do
		local key = keyFor(model) .. ":" .. attribute
		local on = model:GetAttribute(attribute) == true
		local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
		if on and root and not Effects.isAttached(key) then
			Effects.attach(key, spec.Recipe, root, { keepLights = spec.KeepLights })
		elseif not on and Effects.isAttached(key) then
			Effects.detach(key)
		end
	end
end

local function watch(model: Instance)
	if not model:IsA("Model") then
		return
	end
	for attribute in Cues.States do
		model:GetAttributeChangedSignal(attribute):Connect(function()
			refreshState(model)
		end)
	end
	-- the root may stream in after the tag; retry once it exists
	if not (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart) then
		task.spawn(function()
			model:WaitForChild("HumanoidRootPart", 10)
			refreshState(model)
		end)
	end
	refreshState(model)
end

local function unwatch(model: Instance)
	local key = keys[model]
	if key then
		for attribute in Cues.States do
			Effects.detach(key .. ":" .. attribute, true)
		end
		keys[model] = nil
	end
end

-- True if this client currently shows the state effect `attribute` on `model` (tests and debugging).
function VFXClient.hasState(model: Model, attribute: string): boolean
	local key = keys[model]
	return key ~= nil and Effects.isAttached(key .. ":" .. attribute)
end

function VFXClient.start()
	local remote = ReplicatedStorage:WaitForChild(Cues.REMOTE)
	remote.OnClientEvent:Connect(function(name, position, power)
		if not Cues.validOneShot(name, position, power) then
			return
		end
		local cue = Cues.OneShots[name]
		Effects.burst(cue.Recipe, position, {
			power = math.clamp(power, cue.Power[1], cue.Power[2]),
			important = name == "SunVictory", -- the round result is never culled or capped
		})
	end)

	CollectionService:GetInstanceAddedSignal(Cues.ACTOR_TAG):Connect(watch)
	CollectionService:GetInstanceRemovedSignal(Cues.ACTOR_TAG):Connect(unwatch)
	for _, model in CollectionService:GetTagged(Cues.ACTOR_TAG) do
		task.spawn(watch, model)
	end
end

return VFXClient
