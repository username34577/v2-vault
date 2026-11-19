-- VFXServer: the server side of multiplayer-safe effects. Gameplay code calls these AFTER it has
-- decided what happened (the steal is valid, the round is over). Nothing here trusts a client.
--
--   VFXServer.oneShot("SunBurst", position, power)   -- to players within the cue's Radius
--   VFXServer.setCarrying(model, true/false)        -- state effect via an attribute
--   VFXServer.track(model)                          -- tag a model so clients watch its state attributes
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cues = require(ReplicatedStorage.Shared.VFX.Cues)

local VFXServer = {}

local remote = ReplicatedStorage:FindFirstChild(Cues.REMOTE)
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = Cues.REMOTE
	remote.Parent = ReplicatedStorage
end
-- Nothing listens on OnServerEvent: clients cannot send through this remote.

local sentAt = {} -- [cueName] = {os.clock() of recent sends}

local function underRate(name: string, perSecond: number): boolean
	local now = os.clock()
	local list = sentAt[name] or {}
	sentAt[name] = list
	while list[1] and now - list[1] > 1 do
		table.remove(list, 1)
	end
	if #list >= perSecond then
		return false
	end
	table.insert(list, now)
	return true
end

function VFXServer.oneShot(name: string, position: Vector3, power: number?): boolean
	local cue = Cues.OneShots[name]
	if not cue then
		warn("[VFXServer] unknown cue", name)
		return false
	end
	if not underRate(name, cue.MaxPerSecond) then
		return false -- a burst storm is a bug or an exploit upstream; drop extras, never queue
	end
	local p = math.clamp(power or 1, cue.Power[1], cue.Power[2])
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		-- interest management: only players near the event receive it (no character yet = send anyway)
		if cue.Radius == math.huge or not root or (root.Position - position).Magnitude <= cue.Radius then
			remote:FireClient(player, name, position, p)
		end
	end
	return true
end

function VFXServer.track(model: Model)
	CollectionService:AddTag(model, Cues.ACTOR_TAG)
end

function VFXServer.setCarrying(model: Model, on: boolean)
	VFXServer.track(model)
	model:SetAttribute(Cues.CARRY_ATTRIBUTE, on == true)
end

-- Every player character is an actor (it can carry the sun).
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(VFXServer.track)
end)
for _, player in Players:GetPlayers() do
	if player.Character then
		VFXServer.track(player.Character)
	end
	player.CharacterAdded:Connect(VFXServer.track)
end

return VFXServer
