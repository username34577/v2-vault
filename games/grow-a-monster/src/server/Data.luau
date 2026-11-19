-- Player saving with a session lock (follows the vault's "Session Locking and Profile Libraries"
-- and "Saving Correctly - Autosave and BindToClose" notes):
--  * load + lock in ONE UpdateAsync, never GetAsync/SetAsync
--  * every write is fenced by this server's session token
--  * a failed load is never saved over
--  * autosave (60 s) is shorter than the lease (90 s) and renews it
--  * BindToClose saves everyone in parallel
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local STORE_NAME = "GrowAMonster_v1"
local LEASE_SECONDS = 90
local AUTOSAVE_SECONDS = 60
local CLAIM_ATTEMPTS = 6
local SAVE_ATTEMPTS = 3
local SCHEMA_VERSION = 1

local IS_STUDIO = RunService:IsStudio()
local storeOk, store = pcall(function()
	return DataStoreService:GetDataStore(STORE_NAME)
end)
if not storeOk then
	warn("[Data] DataStores unavailable (turn on 'Enable Studio Access to API Services' to test saving):", store)
	store = nil
end

local Data = {}
local profiles = {} -- [Player] = profile

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in value do
		out[deepCopy(k)] = deepCopy(v)
	end
	return out
end

local function newData()
	return {
		Version = SCHEMA_VERSION,
		Coins = 0,
		Size = 1,
		Owned = { [Config.StartingFood] = true },
		Equipped = Config.StartingFood,
		LastSeen = 0,
	}
end

-- Fill in anything missing and clean up bad values. Refuses data from a NEWER version.
local function migrate(data)
	if type(data) ~= "table" then
		error("data is not a table")
	end
	local version = tonumber(data.Version) or 0
	if version > SCHEMA_VERSION then
		error(`data version {version} is newer than this server ({SCHEMA_VERSION})`)
	end
	local fresh = newData()
	for key, default in fresh do
		if data[key] == nil then
			data[key] = default
		end
	end
	if type(data.Owned) ~= "table" then
		data.Owned = { [Config.StartingFood] = true }
	end
	data.Owned[Config.StartingFood] = true
	if not data.Owned[data.Equipped] or not Config.FoodById[data.Equipped] then
		data.Equipped = Config.StartingFood
	end
	data.Coins = math.max(0, tonumber(data.Coins) or 0)
	data.Size = math.max(1, tonumber(data.Size) or 1)
	data.Version = SCHEMA_VERSION
	return data
end

local function newSession(token)
	return {
		Token = token,
		JobId = game.JobId,
		ExpiresAt = os.time() + LEASE_SECONDS,
		Studio = if IS_STUDIO then true else nil,
	}
end

local function keyFor(userId)
	return `User_{userId}`
end

-- One attempt to load and lock. Returns "claimed", record | "locked" | "malformed" | "error".
local function tryClaim(key, userId, token)
	local outcome = "error"
	local ok, result = pcall(function()
		return store:UpdateAsync(key, function(old, keyInfo)
			outcome = "error" -- the transform can run more than once
			if old ~= nil and type(old) ~= "table" then
				outcome = "malformed"
				return nil
			end
			local record = old or { SaveVersion = 0 }
			local held = record.Session
			if type(held) == "table" and held.Token ~= token then
				local expires = tonumber(held.ExpiresAt) or 0
				local studioTakeover = IS_STUDIO and held.Studio == true
				if expires > os.time() and not studioTakeover then
					outcome = "locked"
					return nil
				end
			end
			record.Session = newSession(token)
			outcome = "claimed"
			local userIds = if keyInfo then keyInfo:GetUserIds() else { userId }
			local metadata = if keyInfo then keyInfo:GetMetadata() else nil
			return record, userIds, metadata
		end)
	end)
	if not ok then
		warn(`[Data] claim error for {key}: {result}`)
		return "error", tostring(result)
	end
	return outcome, result
end

local function releaseUnsaved(key, token)
	pcall(function()
		store:UpdateAsync(key, function(old, keyInfo)
			if type(old) ~= "table" or type(old.Session) ~= "table" or old.Session.Token ~= token then
				return nil
			end
			old.Session = nil
			return old, if keyInfo then keyInfo:GetUserIds() else nil, if keyInfo then keyInfo:GetMetadata() else nil
		end)
	end)
end

-- Loads a player's profile. Returns the profile, or nil if loading failed (player gets kicked).
function Data.load(player)
	local userId = player.UserId
	local token = HttpService:GenerateGUID(false)

	if store == nil then
		-- No DataStore access (Studio without API access): play on a temporary profile that never saves.
		local profile = { Player = player, Data = newData(), Token = token, State = "temporary", Saving = false, IsNew = true }
		profiles[player] = profile
		return profile
	end

	local key = keyFor(userId)
	for attempt = 1, CLAIM_ATTEMPTS do
		if not player.Parent then
			return nil
		end
		local outcome, record = tryClaim(key, userId, token)
		if outcome == "claimed" and type(record) == "table" then
			local isNew = record.Data == nil
			local okMigrate, data = pcall(function()
				return if isNew then newData() else migrate(record.Data)
			end)
			if not okMigrate then
				warn(`[Data] could not read save for {key}: {data}`)
				releaseUnsaved(key, token)
				return nil
			end
			local profile = {
				Player = player,
				Key = key,
				Token = token,
				Data = data,
				SaveVersion = tonumber(record.SaveVersion) or 0,
				IsNew = isNew,
				State = "active",
				Saving = false,
			}
			profiles[player] = profile
			return profile
		elseif outcome == "malformed" then
			return nil
		elseif outcome == "error" and IS_STUDIO and type(record) == "string"
			and (string.find(record, "API", 1, true) or string.find(record, "403", 1, true))
		then
			-- Studio without "Enable Studio Access to API Services": play without saving.
			warn("[Data] Saving is off in this Studio session. Turn on Game Settings > Security > Enable Studio Access to API Services to test saving.")
			local profile = { Player = player, Data = newData(), Token = token, State = "temporary", Saving = false, IsNew = true }
			profiles[player] = profile
			return profile
		end
		if attempt < CLAIM_ATTEMPTS then
			task.wait(math.min(8, attempt * 1.5) + math.random())
		end
	end
	return nil
end

-- Fenced write. Returns "saved" | "lost" | "error".
local function writeOnce(profile, release)
	if profile.State ~= "active" then
		return "lost"
	end
	while profile.Saving do
		task.wait(0.1)
	end
	if profile.State ~= "active" then
		return "lost"
	end
	profile.Saving = true
	profile.Data.LastSeen = os.time()
	local snapshot = deepCopy(profile.Data)
	local result = "error"
	local writtenVersion = profile.SaveVersion
	local ok, err = pcall(function()
		store:UpdateAsync(profile.Key, function(old, keyInfo)
			result = "error"
			if type(old) ~= "table" or type(old.Session) ~= "table" or old.Session.Token ~= profile.Token then
				result = "lost" -- another server owns this save now: never write
				return nil
			end
			writtenVersion = math.max(tonumber(old.SaveVersion) or 0, profile.SaveVersion) + 1
			old.Data = snapshot
			old.SaveVersion = writtenVersion
			old.SavedAt = os.time()
			old.Session = if release then nil else newSession(profile.Token)
			result = "saved"
			local userIds = if keyInfo then keyInfo:GetUserIds() else { profile.Player.UserId }
			local metadata = if keyInfo then keyInfo:GetMetadata() else nil
			return old, userIds, metadata
		end)
	end)
	profile.Saving = false
	if not ok then
		warn(`[Data] save error for {profile.Key}: {err}`)
		return "error"
	end
	if result == "lost" then
		profile.State = "lost"
	elseif result == "saved" then
		profile.SaveVersion = writtenVersion
		if release then
			profile.State = "released"
		end
	end
	return result
end

function Data.save(profile, release)
	if profile.State == "temporary" then
		return "saved"
	end
	for attempt = 1, SAVE_ATTEMPTS do
		local result = writeOnce(profile, release)
		if result ~= "error" then
			if result == "lost" then
				warn(`[Data] lost the session lock for {profile.Key}; this server stops saving it`)
			end
			return result
		end
		task.wait(attempt * 2)
	end
	return "error"
end

function Data.get(player)
	local profile = profiles[player]
	if profile and (profile.State == "active" or profile.State == "temporary") then
		return profile
	end
	return nil
end

function Data.release(player)
	local profile = profiles[player]
	if not profile then
		return
	end
	profiles[player] = nil
	if profile.State == "active" then
		Data.save(profile, true)
	end
end

-- Autosave loop: renews each lease well before it expires.
task.spawn(function()
	while true do
		task.wait(AUTOSAVE_SECONDS)
		for _, profile in profiles do
			if profile.State == "active" then
				task.spawn(Data.save, profile, false)
			end
		end
	end
end)

-- Save everyone in parallel when the server shuts down.
game:BindToClose(function()
	local pending = 0
	for player, profile in profiles do
		if profile.State == "active" then
			pending += 1
			task.spawn(function()
				Data.save(profile, true)
				pending -= 1
			end)
		end
	end
	local started = os.clock()
	while pending > 0 and os.clock() - started < 25 do
		task.wait(0.1)
	end
end)

Players.PlayerRemoving:Connect(Data.release)

return Data
