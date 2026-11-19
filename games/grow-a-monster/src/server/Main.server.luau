-- Grow a Monster: server game loop (v0.4 Snack Grove).
-- Rules (vault "Server Authority and Validation"): the client only says "throw" (feed the top snack you
-- carry to your monster). Shaking plants and buying backpacks go through ProximityPrompts that the
-- server range-checks. Snacks, growth, coins, objectives and the Gardener all live on the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.Data)
local Companion = require(script.Parent.Companion)
local World = require(script.Parent.World)
local Grove = require(script.Parent.Grove)

---------------------------------------------------------------------------
-- Remotes (all created by the server, in one folder)
---------------------------------------------------------------------------
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local function remote(name)
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end
local ThrowRemote = remote("Throw") -- client -> server: no arguments
local NotifyRemote = remote("Notify") -- server -> client: message text
local FxRemote = remote("Fx") -- server -> client only: visual/sound cues
remotes.Parent = ReplicatedStorage

---------------------------------------------------------------------------
-- Rate limiting: a token bucket per player per remote. Checked FIRST.
---------------------------------------------------------------------------
local buckets = {}
local function allow(player, name, perSecond, burst)
	local key = `{player.UserId}:{name}`
	local now = os.clock()
	local b = buckets[key]
	if not b then
		b = { Tokens = burst, Last = now }
		buckets[key] = b
	end
	b.Tokens = math.min(burst, b.Tokens + (now - b.Last) * perSecond)
	b.Last = now
	if b.Tokens < 1 then
		return false
	end
	b.Tokens -= 1
	return true
end

---------------------------------------------------------------------------
-- Plots
---------------------------------------------------------------------------
local plotOwner = {} -- [index] = player
-- plotGround[i]: monster's home spot, looking toward the gate; plotReach[i]: furthest the player may stand
local plotGround, plotReach = World.build()

local function claimPlot(player)
	for i = 1, Config.PlotCount do
		if plotOwner[i] == nil then
			plotOwner[i] = player
			return i
		end
	end
	return nil
end

---------------------------------------------------------------------------
-- Per-player state
---------------------------------------------------------------------------
local state = {} -- [player] = { Profile, Plot, Monster, LastThrow }

local function incomePerSecond(size)
	return math.max(Config.MinIncome, math.floor(size * Config.IncomePerSize))
end

local function capacity(data)
	local pack = Config.Backpacks[data.Backpack] or Config.Backpacks[1]
	return pack.Carry
end

local function currentObjective(data)
	return Config.Objectives[data.Objective] or Config.RepeatObjective
end

-- Progress and goal of the current objective, as shown on the HUD.
local function objectiveStatus(data)
	local obj = currentObjective(data)
	if obj.Type == "Backpack" then
		return if data.Backpack >= obj.Goal then 1 else 0, 1
	elseif obj.Type == "Size" then
		return math.min(math.floor(data.Size), obj.Goal), obj.Goal
	end
	return math.min(data.ObjectiveProgress, obj.Goal), obj.Goal
end

-- Push the numbers the client needs to show (attributes replicate to everyone).
local function publish(player)
	local s = state[player]
	if not s then
		return
	end
	local data = s.Profile.Data
	player:SetAttribute("Coins", math.floor(data.Coins))
	player:SetAttribute("Size", math.floor(data.Size))
	player:SetAttribute("Income", incomePerSecond(data.Size))
	player:SetAttribute("Backpack", data.Backpack)
	player:SetAttribute("CarryCap", capacity(data))
	local obj = currentObjective(data)
	local progress, goal = objectiveStatus(data)
	player:SetAttribute("ObjText", obj.Text)
	player:SetAttribute("ObjType", obj.Type)
	player:SetAttribute("ObjProgress", progress)
	player:SetAttribute("ObjGoal", goal)
	player:SetAttribute("ObjIndex", data.Objective)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Size.Value = math.floor(data.Size)
		stats.Coins.Value = math.floor(data.Coins)
	end
end

-- Complete objectives that are done (several in a row if needed), paying their reward.
local function checkObjectives(player, s)
	local data = s.Profile.Data
	for _ = 1, 5 do
		local obj = currentObjective(data)
		local progress, goal = objectiveStatus(data)
		if progress < goal then
			break
		end
		data.Coins += obj.Coins
		data.Objective += 1
		data.ObjectiveProgress = 0
		FxRemote:FireClient(player, "Objective", obj.Text, obj.Coins)
	end
	publish(player)
end

local function makeLeaderstats(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local size = Instance.new("IntValue")
	size.Name = "Size"
	size.Parent = stats
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = stats
	stats.Parent = player
end

-- Where the player stands at spawn: SpawnGap studs in front of the monster's home spot, facing it.
local function spawnCFrame(s)
	local ground = plotGround[s.Plot]
	local radius = 2.5 * Config.companionScale(s.Profile.Data.Size)
	local dist = math.min(radius + Config.Map.SpawnGap, plotReach[s.Plot])
	local pos = (ground * CFrame.new(0, 0, -dist)).Position
	pos = Vector3.new(pos.X, Config.Map.PlotTopY + 3, pos.Z)
	return CFrame.lookAt(pos, Vector3.new(ground.Position.X, pos.Y, ground.Position.Z))
end

-- Grow the plot's decor when the monster reaches a new Config.PlotDecor size.
local function updatePlotDecor(player, s, announce)
	local level = World.decorLevelFor(s.Profile.Data.Size)
	if World.setPlotLevel(s.Plot, level) and announce then
		NotifyRemote:FireClient(player, `Your plot got {Config.PlotDecor[level].Name}!`)
	end
end

local function sendToPlot(player)
	local s = state[player]
	local character = player.Character
	if not s or not character then
		return
	end
	character:PivotTo(spawnCFrame(s))
	if s.Monster then
		s.Monster:PivotTo(plotGround[s.Plot] * CFrame.new(0, 4, 0))
	end
	FxRemote:FireClient(player, "Placed") -- client frames the camera on the monster now
end

---------------------------------------------------------------------------
-- Snack Grove hooks
---------------------------------------------------------------------------
Grove.build({
	isReady = function(player)
		return state[player] ~= nil and Data.get(player) ~= nil
	end,
	capacity = function(player)
		local s = state[player]
		return if s then capacity(s.Profile.Data) else 0
	end,
	notify = function(player, text)
		NotifyRemote:FireClient(player, text)
	end,
	fx = function(player, kind, ...)
		FxRemote:FireClient(player, kind, ...)
	end,
	caught = function(player, gardenerModel)
		FxRemote:FireClient(player, "Caught", gardenerModel)
		task.delay(0.7, function()
			local character = player.Character
			if character and state[player] then
				character:PivotTo(Grove.ejectSpot())
			end
		end)
	end,
	buyBackpack = function(player)
		if not allow(player, "Buy", 2, 3) then
			return
		end
		local s = state[player]
		if not s or not Data.get(player) then
			return
		end
		local data = s.Profile.Data
		local nextPack = Config.Backpacks[data.Backpack + 1]
		if not nextPack then
			NotifyRemote:FireClient(player, "You have the biggest backpack already!")
			return
		end
		if data.Coins < nextPack.Price then
			NotifyRemote:FireClient(player, `You need {nextPack.Price - math.floor(data.Coins)} more coins for the {nextPack.Name}.`)
			return
		end
		data.Coins -= nextPack.Price
		data.Backpack = nextPack.Level
		NotifyRemote:FireClient(player, `Bought the {nextPack.Name}! You can carry {nextPack.Carry} snacks.`)
		FxRemote:FireClient(player, "Bought")
		checkObjectives(player, s)
	end,
})

---------------------------------------------------------------------------
-- Join / leave
---------------------------------------------------------------------------
local function onPlayerAdded(player)
	local plot = claimPlot(player)
	if not plot then
		player:Kick("This server is full. Please join another one!")
		return
	end

	local profile = Data.load(player)
	if not player.Parent then
		plotOwner[plot] = nil
		return
	end
	if not profile then
		plotOwner[plot] = nil
		player:Kick("Couldn't load your save. Please rejoin in a minute (your progress is safe).")
		return
	end

	local data = profile.Data
	World.setPlotOwner(plot, player)
	local model = Companion.create(player, plot, plotGround[plot])
	state[player] = { Profile = profile, Plot = plot, Monster = model, LastThrow = 0 }
	updatePlotDecor(player, state[player], false)
	makeLeaderstats(player)
	if model then
		Companion.setSize(model, data.Size)
	end
	publish(player)

	-- Studio-only test hook: in the SERVER command bar run
	--   game.Players.<Name>:SetAttribute("DebugSize", 30000)
	-- Live servers ignore it, and client-side attribute changes never reach the server.
	if RunService:IsStudio() then
		player:GetAttributeChangedSignal("DebugSize"):Connect(function()
			local value = tonumber(player:GetAttribute("DebugSize"))
			local s = state[player]
			if value and s and Data.get(player) then
				s.Profile.Data.Size = math.max(1, value)
				if s.Monster then
					Companion.setSize(s.Monster, s.Profile.Data.Size)
				end
				updatePlotDecor(player, s, true)
				checkObjectives(player, s)
			end
		end)
	end

	-- Offline earnings (from the TikTok notes: boosts retention)
	if not profile.IsNew and (data.LastSeen or 0) > 0 then
		local away = math.clamp(os.time() - data.LastSeen, 0, Config.OfflineMaxSeconds)
		local earned = math.floor(incomePerSecond(data.Size) * away * Config.OfflineShare)
		if earned > 0 then
			data.Coins += earned
			publish(player)
			task.delay(3, function()
				if player.Parent then
					NotifyRemote:FireClient(player, `Welcome back! Your monster earned {earned} coins while you were away.`)
				end
			end)
		end
	end

	player.CharacterAdded:Connect(function()
		Grove.dropAll(player) -- respawning empties your hands
		task.defer(sendToPlot, player)
	end)
	if player.Character then
		sendToPlot(player)
	end
end

local function onPlayerRemoving(player)
	local s = state[player]
	state[player] = nil
	Grove.clear(player)
	for key in buckets do
		if string.sub(key, 1, #tostring(player.UserId) + 1) == `{player.UserId}:` then
			buckets[key] = nil
		end
	end
	if s then
		if s.Monster then
			Companion.destroy(s.Monster)
		end
		plotOwner[s.Plot] = nil
		World.setPlotOwner(s.Plot, nil)
		World.setPlotLevel(s.Plot, 0)
	end
	-- Data.lua saves and releases the profile on PlayerRemoving.
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

---------------------------------------------------------------------------
-- Feeding: throw the top carried snack to your monster
---------------------------------------------------------------------------
ThrowRemote.OnServerEvent:Connect(function(player)
	if not allow(player, "Throw", 5, 5) then
		return
	end
	local s = state[player]
	if not s or not s.Monster or not Data.get(player) then
		return
	end
	local now = os.clock()
	if now - s.LastThrow < Config.ThrowCooldown then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local body = s.Monster.PrimaryPart
	if not root or not humanoid or humanoid.Health <= 0 or not body then
		return
	end
	if (root.Position - body.Position).Magnitude > Config.Companion.FeedRange + body.Size.X then
		NotifyRemote:FireClient(player, "Get closer to your monster to feed it!")
		return
	end
	if Grove.isInside(root.Position) then
		NotifyRemote:FireClient(player, "Your monster is waiting outside the Grove. Bring the snacks out!")
		return
	end
	local snackId = Grove.takeSnack(player)
	if not snackId then
		return
	end
	s.LastThrow = now
	local snack = Config.Snacks[snackId]
	local from = root.Position + Vector3.new(0, 2, 0) + root.CFrame.LookVector * 2
	Companion.face(s.Monster, root.Position, Config.FlightTime + 0.5)
	FxRemote:FireAllClients("Throw", s.Monster, snack.Model, from)
	task.delay(Config.FlightTime * 0.55, function()
		if s.Monster and s.Monster.Parent then
			Companion.hop(s.Monster) -- jump up to catch it
		end
	end)
	task.delay(Config.FlightTime, function()
		local current = state[player]
		if current ~= s or not Data.get(player) or not s.Monster or not s.Monster.Parent then
			return -- player left mid-throw
		end
		local data = s.Profile.Data
		data.Size += snack.Growth
		data.Coins += snack.Growth * Config.CoinsPerGrowth
		data.SnacksFed += 1
		local obj = currentObjective(data)
		if obj.Type == "Deliver" or (obj.Type == "Golden" and snackId == "GoldenMelon") then
			data.ObjectiveProgress += 1
		end
		Companion.setSize(s.Monster, data.Size)
		updatePlotDecor(player, s, true)
		FxRemote:FireAllClients("Eat", s.Monster, snack.Model, snack.Growth)
		checkObjectives(player, s)
	end)
end)

---------------------------------------------------------------------------
-- Companions follow their owners (and wait outside the Grove)
---------------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(0.2)
		for player, s in state do
			if s.Monster and s.Monster.Parent then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if not root then
					Companion.follow(s.Monster, nil, 0)
				elseif Grove.isInside(root.Position) then
					Companion.follow(s.Monster, Grove.waitSpot().Position, 0)
				else
					Companion.follow(s.Monster, root.Position, Config.Companion.FollowDistance)
				end
			end
		end
	end
end)

---------------------------------------------------------------------------
-- Passive income, once per second
---------------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(1)
		for player, s in state do
			if Data.get(player) then
				s.Profile.Data.Coins += incomePerSecond(s.Profile.Data.Size)
				publish(player)
			end
		end
	end
end)

---------------------------------------------------------------------------
-- Server leaderboard board in the hub
---------------------------------------------------------------------------
task.spawn(function()
	while true do
		local entries = {}
		for player, s in state do
			if Data.get(player) then
				table.insert(entries, { Name = player.DisplayName, Size = s.Profile.Data.Size })
			end
		end
		table.sort(entries, function(a, b)
			return a.Size > b.Size
		end)
		World.setLeaderboard(entries)
		task.wait(Config.Leaderboard.RefreshSeconds)
	end
end)

---------------------------------------------------------------------------
-- Fall safety: fell off the island -> back on your own plot, no death
---------------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(Config.Map.FallCheckInterval)
		for player, s in state do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and root.Position.Y < Config.Map.FallY then
				root.AssemblyLinearVelocity = Vector3.zero
				character:PivotTo(spawnCFrame(s))
				FxRemote:FireClient(player, "Fell")
			end
		end
	end
end)
