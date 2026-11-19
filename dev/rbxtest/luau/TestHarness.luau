--!strict
-- TestHarness (server): run named test suites when Studio starts a session through
-- StudioTestService (ExecutePlayModeAsync / ExecuteMultiplayerTestAsync) with args { suite = "<name>" },
-- and return a structured report with StudioTestService:EndTest(report).
--
-- Does nothing in a normal Play session or a live game (GetTestArgs fails or has no suite).
--
--   local TestHarness = require(path.to.TestHarness)
--   TestHarness.register("replication", { side = "server", minPlayers = 2, timeout = 120, run = function(ctx) return results end })
--   TestHarness.register("local", { side = "client", timeout = 180 })   -- the client registers the run function
--   TestHarness.start()
--
-- A result is { test = string, check = string, status = "PASS" | "FAIL" | "INFO", detail = any? }.
-- Report schema 1: { schema = 1, suite, status = "completed" | "error" | "timeout" | "unknown_suite",
--                    results = {...}, error = string?, meta = { place, startedAt, durationS, players } }
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local TestHarness = {}

type Suite = { side: string, minPlayers: number?, timeout: number?, run: ((ctx: any) -> { any })? }
local suites: { [string]: Suite } = {}

local MAX_PAYLOAD_CHARS = 200000
local MAX_RESULTS = 500

local remote: RemoteEvent? = nil

function TestHarness.register(name: string, suite: Suite)
	suites[name] = suite
end

local function validResults(results: any): (boolean, string?)
	if type(results) ~= "table" then
		return false, "results is not a table"
	end
	if #results > MAX_RESULTS then
		return false, "too many results"
	end
	for i, r in results do
		if type(i) ~= "number" or type(r) ~= "table" then
			return false, "results must be an array of tables"
		end
		if type(r.test) ~= "string" or type(r.check) ~= "string" then
			return false, `result {i} missing test/check`
		end
		if r.status ~= "PASS" and r.status ~= "FAIL" and r.status ~= "INFO" then
			return false, `result {i} has bad status`
		end
	end
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, results)
	if not ok then
		return false, "results not JSON-encodable"
	end
	if #encoded > MAX_PAYLOAD_CHARS then
		return false, "results too large"
	end
	return true, nil
end

local function playerNames(): { string }
	local names = {}
	for _, p in Players:GetPlayers() do
		table.insert(names, p.Name)
	end
	return names
end

function TestHarness.start()
	if not RunService:IsStudio() or not RunService:IsServer() then
		return
	end
	local okArgs, args = pcall(function()
		return game:GetService("StudioTestService"):GetTestArgs()
	end)
	if not okArgs or type(args) ~= "table" or type(args.suite) ~= "string" then
		return -- not a harness session
	end
	local STS = game:GetService("StudioTestService")

	-- Client channel, created only in harness sessions.
	local r = Instance.new("RemoteEvent")
	r.Name = "_TestHarnessChannel"
	r.Parent = ReplicatedStorage
	remote = r

	local name: string = args.suite
	local suite = suites[name]
	local t0 = os.clock()
	local started = DateTime.now():ToIsoDate()

	local function finish(status: string, results: { any }?, err: string?)
		local report = {
			schema = 1,
			suite = name,
			status = status,
			results = results or {},
			error = err,
			meta = {
				place = game.Name,
				placeId = game.PlaceId,
				startedAt = started,
				durationS = math.floor((os.clock() - t0) * 10) / 10,
				players = playerNames(),
				args = args,
			},
		}
		STS:EndTest(report)
	end

	if not suite then
		finish("unknown_suite", nil, `no suite named "{name}"`)
		return
	end
	local timeout = suite.timeout or 120

	task.spawn(function()
		-- Wait for enough players (and their characters) before running.
		local need = suite.minPlayers or 1
		local deadline = os.clock() + 60
		while os.clock() < deadline do
			local ready = 0
			for _, p in Players:GetPlayers() do
				if p.Character then
					ready += 1
				end
			end
			if ready >= need then
				break
			end
			task.wait(0.5)
		end
		if #Players:GetPlayers() < need then
			finish("error", nil, `needed {need} players, have {#Players:GetPlayers()}`)
			return
		end

		if suite.side == "server" then
			local done = false
			task.delay(timeout, function()
				if not done then
					done = true
					finish("timeout", nil, `server suite exceeded {timeout} s`)
				end
			end)
			local ok, res = pcall(suite.run :: any, { args = args })
			if done then
				return
			end
			done = true
			if not ok then
				finish("error", nil, tostring(res))
				return
			end
			local valid, why = validResults(res)
			if valid then
				finish("completed", res)
			else
				finish("error", nil, "invalid results: " .. tostring(why))
			end
		else
			-- Client suite: ask the first player to run it; accept the reply only from that player, once.
			local target = Players:GetPlayers()[1]
			local done = false
			local conn: RBXScriptConnection
			conn = r.OnServerEvent:Connect(function(sender, kind, payload)
				if done or sender ~= target or kind ~= "result" then
					return
				end
				done = true
				conn:Disconnect()
				if type(payload) ~= "table" then
					finish("error", nil, "client sent a non-table payload")
					return
				end
				if payload.error ~= nil then
					finish("error", nil, "client error: " .. string.sub(tostring(payload.error), 1, 2000))
					return
				end
				local valid, why = validResults(payload.results)
				if valid then
					finish("completed", payload.results)
				else
					finish("error", nil, "invalid client results: " .. tostring(why))
				end
			end)
			task.delay(timeout, function()
				if not done then
					done = true
					conn:Disconnect()
					finish("timeout", nil, `client suite exceeded {timeout} s`)
				end
			end)
			r:FireClient(target, "run", name)
		end
	end)
end

return TestHarness
