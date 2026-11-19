-- Draws thrown food on this client: an arc from the thrower's hand into the monster's mouth.
-- Timing matches the server (Config.FlightTime), which decides when the hit really happens.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local FoodModels = require(ReplicatedStorage.Shared.FoodModels)
local Build = require(ReplicatedStorage.Shared.Build)
local MonsterView = require(script.Parent.MonsterView)

local FoodFlight = {}

local flying = {}
local folder

-- Thrown food looks exactly like the shop icon.
local function makeFood(foodId: string)
	return FoodModels.build(foodId)
end
FoodFlight.makeFood = makeFood

function FoodFlight.launch(serverModel, foodId: string, from: Vector3)
	if typeof(from) ~= "Vector3" then
		return
	end
	local model = FoodFlight.makeFood(foodId)
	-- bigger food for bigger monsters so it still reads (up to 2.5x at max size)
	local frac = (MonsterView.scaleOf(serverModel) - 1) / math.max(Config.MaxScale - 1, 1)
	Build.scaleModel(model, 1 + 1.5 * math.clamp(frac, 0, 1))
	model:PivotTo(CFrame.new(from))
	model.Parent = folder
	table.insert(flying, {
		Model = model,
		Monster = serverModel,
		From = from,
		Started = os.clock(),
		Spin = Vector3.new(math.random() * 8 - 4, math.random() * 8 - 4, math.random() * 8 - 4),
	})
end

function FoodFlight.start()
	folder = Instance.new("Folder")
	folder.Name = "FlyingFood"
	folder.Parent = workspace
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		for i = #flying, 1, -1 do
			local f = flying[i]
			local t = (now - f.Started) / Config.FlightTime
			local to = MonsterView.mouthPosition(f.Monster)
			if t >= 1 or not to or not f.Monster.Parent then
				f.Model:Destroy()
				table.remove(flying, i)
			else
				local height = math.max(8, (to - f.From).Magnitude * 0.35)
				local pos = f.From:Lerp(to, t) + Vector3.new(0, math.sin(t * math.pi) * height, 0)
				local spin = f.Spin * (now - f.Started)
				f.Model:PivotTo(CFrame.new(pos) * CFrame.Angles(spin.X, spin.Y, spin.Z))
			end
		end
	end)
end

return FoodFlight
