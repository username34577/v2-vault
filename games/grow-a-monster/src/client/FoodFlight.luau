-- Draws thrown food on this client: an arc from the thrower's hand into the monster's mouth.
-- Timing matches the server (Config.FlightTime), which decides when the hit really happens.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Build = require(ReplicatedStorage.Shared.Build)
local MonsterView = require(script.Parent.MonsterView)

local FoodFlight = {}

local flying = {}
local folder

-- Returns a Model for a food id. Replaced with real food shapes in FoodModels (step 3).
local function makeFood(foodId: string)
	local food = Config.FoodById[foodId] or Config.FoodById[Config.StartingFood]
	local model = Instance.new("Model")
	Build.ball(1.5, food.Color, CFrame.new(), model)
	model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart")
	return model
end
FoodFlight.makeFood = makeFood

function FoodFlight.launch(serverModel, foodId: string, from: Vector3)
	if typeof(from) ~= "Vector3" then
		return
	end
	local model = FoodFlight.makeFood(foodId)
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
				-- food grows a little near the end so it reads against a huge monster
				local grow = 1 + t * 0.25 * (MonsterView.scaleOf(f.Monster) - 1) / math.max(Config.MaxScale - 1, 1)
				f.Model:PivotTo(CFrame.new(pos) * CFrame.Angles(spin.X, spin.Y, spin.Z))
				if grow ~= f.LastGrow then
					f.LastGrow = grow
					f.Model:ScaleTo(grow)
				end
			end
		end
	end)
end

return FoodFlight
