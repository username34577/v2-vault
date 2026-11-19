-- VFX Lab automated tests (server side): the multiplayer replication test and the lab-only "KillMe"
-- used by the client's camera-on-death test. LAB ONLY: never ship these remotes in a game.
--
-- Replication test (needs 2+ clients: Studio Test tab > Clients and Servers > Local Server, 2 players):
-- the server drives the real cues (VFXServer) and then ASKS every client what it actually shows,
-- so a pass means each client built the effect, not just that the server sent something.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VFXServer = require(script.Parent.VFXServer)

local LabTests = {}

local cmd = Instance.new("RemoteEvent")
cmd.Name = "VFXTestCmd"
cmd.Parent = ReplicatedStorage
local probe = Instance.new("RemoteEvent")
probe.Name = "VFXTestProbe"
probe.Parent = ReplicatedStorage

local replies = {} -- [id] = {[player] = value}
local lastCmd = {}
local probeId = 0

-- Ask every client a question; wait up to `timeout` for all answers.
local function ask(kind: string, model: Model?, timeout: number)
	probeId += 1
	local id = probeId
	replies[id] = {}
	probe:FireAllClients(id, kind, model)
	local t0 = os.clock()
	while os.clock() - t0 < timeout do
		local n = 0
		for _ in replies[id] do
			n += 1
		end
		if n >= #Players:GetPlayers() then
			break
		end
		task.wait(0.05)
	end
	local answers = replies[id]
	replies[id] = nil
	return answers
end

probe.OnServerEvent:Connect(function(player, id, value)
	if type(id) == "number" and replies[id] and (type(value) == "boolean" or type(value) == "number") then
		replies[id][player] = value
	end
end)

local results = {}
local function record(check: string, pass: boolean?, detail)
	local status = if pass == nil then "INFO" elseif pass then "PASS" else "FAIL"
	table.insert(results, { test = "replication", check = check, status = status, detail = detail })
	print(string.format("[VFXLab test] %-5s replication / %s %s", status, check, if detail ~= nil then HttpService:JSONEncode(detail) else ""))
end

local function byName(answers)
	local out = {}
	for player, v in answers do
		out[player.Name] = v
	end
	return out
end

local function all(answers, expected): boolean
	local n = 0
	for _, v in answers do
		if v ~= expected then
			return false
		end
		n += 1
	end
	return n == #Players:GetPlayers()
end

local function rootPos(model: Model): Vector3
	return (model:FindFirstChild("HumanoidRootPart") :: BasePart).Position
end

local runningRep = false
function LabTests.runReplication()
	if runningRep then
		return
	end
	runningRep = true
	table.clear(results)
	local players = Players:GetPlayers()
	if #players < 2 then
		record("at least 2 clients", false, { clients = #players, how = "Test > Clients and Servers > Local Server, 2 players" })
	else
		local a, b = players[1].Character, players[2].Character
		if not (a and b and a:FindFirstChild("HumanoidRootPart") and b:FindFirstChild("HumanoidRootPart")) then
			record("both characters spawned", false)
		else
			record("clients", nil, { count = #players })
			-- state effect appears on every client
			VFXServer.setCarrying(a, true)
			task.wait(1.5)
			local s1 = ask("state", a, 3)
			record(`aura on {players[1].Name} seen by all clients`, all(s1, true), byName(s1))

			-- steal: burst on every client, aura moves on every client
			local p0 = ask("played", nil, 3)
			VFXServer.oneShot("SunBurst", rootPos(a), 1.2)
			VFXServer.setCarrying(a, false)
			VFXServer.setCarrying(b, true)
			task.wait(1.5)
			local p1 = ask("played", nil, 3)
			local burstOk = true
			for player, n in p1 do
				if not (p0[player] and n > p0[player]) then
					burstOk = false
				end
			end
			local answered = 0
			for _ in p1 do
				answered += 1
			end
			record("steal burst played on every client", burstOk and answered == #players, { before = byName(p0), after = byName(p1) })
			local s2a, s2b = ask("state", a, 3), ask("state", b, 3)
			record("aura left the old carrier on all clients", all(s2a, false), byName(s2a))
			record(`aura on new carrier {players[2].Name} on all clients`, all(s2b, true), byName(s2b))

			-- victory reaches everyone
			local v0 = ask("played", nil, 3)
			VFXServer.oneShot("SunVictory", rootPos(b) - Vector3.new(0, 3, 0), 1)
			task.wait(0.5)
			local v1 = ask("played", nil, 3)
			local victoryOk = true
			for player, n in v1 do
				if not (v0[player] and n > v0[player]) then
					victoryOk = false
				end
			end
			record("victory played on every client", victoryOk, { before = byName(v0), after = byName(v1) })

			-- respawn: the carrier's new character must NOT inherit the aura
			VFXServer.setCarrying(b, false)
			task.wait(1.5)
			local s3 = ask("state", b, 3)
			record("aura gone everywhere after drop", all(s3, false), byName(s3))
		end
	end
	local fails = 0
	for _, r in results do
		if r.status == "FAIL" then
			fails += 1
		end
	end
	print(string.format("[VFXLab test] replication suite done: %d checks, %d FAIL", #results, fails))
	print("VFXLAB_RESULTS " .. HttpService:JSONEncode({ suite = "replication", results = results }))
	runningRep = false
end

cmd.OnServerEvent:Connect(function(player, action)
	local now = os.clock()
	if now - (lastCmd[player] or 0) < 1 then
		return -- lab-only remote, still rate limited
	end
	lastCmd[player] = now
	if action == "KillMe" then
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	elseif action == "RunReplication" then
		task.spawn(LabTests.runReplication)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastCmd[player] = nil
end)

return LabTests
