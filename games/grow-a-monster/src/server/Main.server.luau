-- Grow a Monster: server game loop.
-- Rules (vault "Server Authority and Validation"): the client only says "throw", "buy <id>",
-- or "equip <id>". Prices, growth, coins and cooldowns all live on the server.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.Data)
local Monster = require(script.Parent.Monster)
local World = require(script.Parent.World)

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
local BuyRemote = remote("BuyFood") -- client -> server: foodId (string)
local EquipRemote = remote("EquipFood") -- client -> server: foodId (string)
local NotifyRemote = remote("Notify") -- server -> client: message text
local FxRemote = remote("Fx") -- server -> client only: visual/sound cues ("Fell", ...)
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

local function validFoodId(value)
	return type(value) == "string" and #value <= 32 and Config.FoodById[value] ~= nil
end

---------------------------------------------------------------------------
-- Plots
---------------------------------------------------------------------------
local plotOwner = {} -- [index] = player
-- plotGround[i]: monster spot, looking toward the gate; plotReach[i]: furthest the player may stand
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
local state = {} -- [player] = { Profile, Plot, Monster, LastThrow, Coins, Size }

local function incomePerSecond(size)
	return math.max(Config.MinIncome, math.floor(size * Config.IncomePerSize))
end

-- Where the player stands: SpawnGap studs in front of the monster's current size, inside the fence,
-- facing the monster (so the default camera behind them frames it).
local function spawnCFrame(s)
	local ground = plotGround[s.Plot]
	local radius = Config.MonsterRadius * Config.scaleForSize(s.Profile.Data.Size)
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
	player:SetAttribute("Equipped", data.Equipped)
	for id in Config.FoodById do
		player:SetAttribute(`Owned_{id}`, data.Owned[id] == true)
	end
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Size.Value = math.floor(data.Size)
		stats.Coins.Value = math.floor(data.Coins)
	end
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

local function sendToPlot(player)
	local s = state[player]
	local character = player.Character
	if not s or not character then
		return
	end
	character:PivotTo(spawnCFrame(s))
	FxRemote:FireClient(player, "Placed") -- client frames the camera on the monster now
end

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
	local model = Monster.create(player, plot, plotGround[plot])
	state[player] = { Profile = profile, Plot = plot, Monster = model, LastThrow = 0 }
	updatePlotDecor(player, state[player], false)

	-- Studio-only test hook: in the SERVER command bar run
	--   game.Players.<Name>:SetAttribute("DebugSize", 30000)
	-- Live servers ignore it, and client-side attribute changes never reach the server.
	if RunService:IsStudio() then
		player:GetAttributeChangedSignal("DebugSize"):Connect(function()
			local value = tonumber(player:GetAttribute("DebugSize"))
			local s = state[player]
			if value and s and Data.get(player) then
				s.Profile.Data.Size = math.max(1, value)
				Monster.setSize(s.Monster, s.Profile.Data.Size)
				updatePlotDecor(player, s, true)
				publish(player)
			end
		end)
	end
	makeLeaderstats(player)
	Monster.setSize(model, data.Size)
	publish(player)

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
		task.defer(sendToPlot, player)
	end)
	if player.Character then
		sendToPlot(player)
	end
end

local function onPlayerRemoving(player)
	local s = state[player]
	state[player] = nil
	for key in buckets do
		if string.sub(key, 1, #tostring(player.UserId) + 1) == `{player.UserId}:` then
			buckets[key] = nil
		end
	end
	if s then
		if s.Monster then
			s.Monster:Destroy()
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
-- Throwing
---------------------------------------------------------------------------
ThrowRemote.OnServerEvent:Connect(function(player)
	if not allow(player, "Throw", 5, 5) then
		return
	end
	local s = state[player]
	if not s or not Data.get(player) then
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
	if (root.Position - body.Position).Magnitude > Config.ThrowRange + body.Size.X / 2 then
		return
	end
	s.LastThrow = now

	local food = Config.FoodById[s.Profile.Data.Equipped] or Config.FoodById[Config.StartingFood]
	local from = root.Position + Vector3.new(0, 2, 0) + root.CFrame.LookVector * 2
	FxRemote:FireAllClients("Throw", s.Monster, food.Id, from)
	Monster.throwFood(s.Monster, function()
		local current = state[player]
		if current ~= s or not Data.get(player) then
			return -- player left mid-throw
		end
		local data = s.Profile.Data
		data.Size += food.Growth
		data.Coins += food.Growth
		Monster.setSize(s.Monster, data.Size)
		updatePlotDecor(player, s, true)
		publish(player)
		FxRemote:FireAllClients("Eat", s.Monster, food.Id, food.Growth)
	end)
end)

---------------------------------------------------------------------------
-- Shop
---------------------------------------------------------------------------
BuyRemote.OnServerEvent:Connect(function(player, foodId)
	if not allow(player, "Buy", 2, 4) then
		return
	end
	if not validFoodId(foodId) then
		return
	end
	local s = state[player]
	if not s or not Data.get(player) then
		return
	end
	local data = s.Profile.Data
	local food = Config.FoodById[foodId]
	if data.Owned[foodId] then
		return
	end
	if data.Coins < food.Price then
		NotifyRemote:FireClient(player, `You need {food.Price - math.floor(data.Coins)} more coins for {food.Name}.`)
		return
	end
	data.Coins -= food.Price
	data.Owned[foodId] = true
	data.Equipped = foodId -- auto-equip the new food
	publish(player)
	NotifyRemote:FireClient(player, `Bought {food.Name}! +{food.Growth} size per throw.`)
end)

EquipRemote.OnServerEvent:Connect(function(player, foodId)
	if not allow(player, "Equip", 4, 6) then
		return
	end
	if not validFoodId(foodId) then
		return
	end
	local s = state[player]
	if not s or not Data.get(player) then
		return
	end
	if not s.Profile.Data.Owned[foodId] then
		return
	end
	s.Profile.Data.Equipped = foodId
	publish(player)
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
