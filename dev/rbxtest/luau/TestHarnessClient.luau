--!strict
-- TestHarnessClient: runs a client-side suite when the server-side TestHarness asks for it.
--   local TestHarnessClient = require(path.to.TestHarnessClient)
--   TestHarnessClient.register("local", function() return results end)
--   TestHarnessClient.start()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TestHarnessClient = {}
local runners: { [string]: () -> { any } } = {}

function TestHarnessClient.register(name: string, run: () -> { any })
	runners[name] = run
end

function TestHarnessClient.start()
	if not RunService:IsStudio() then
		return
	end
	task.spawn(function()
		-- The channel exists only in harness sessions; give up quietly otherwise.
		local r = ReplicatedStorage:WaitForChild("_TestHarnessChannel", 20) :: RemoteEvent?
		if not r then
			return
		end
		r.OnClientEvent:Connect(function(kind, name)
			if kind ~= "run" or type(name) ~= "string" then
				return
			end
			local run = runners[name]
			if not run then
				r:FireServer("result", { error = `client has no suite "{name}"` })
				return
			end
			local ok, res = pcall(run)
			if ok then
				r:FireServer("result", { results = res })
			else
				r:FireServer("result", { error = tostring(res) })
			end
		end)
	end)
end

return TestHarnessClient
