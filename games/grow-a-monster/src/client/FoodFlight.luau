-- Draws thrown food on this client: an arc from the thrower's hand into the monster's mouth.
-- Timing matches the server (Config.FlightTime), which decides when the hit really happens.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local FoodModels = require(ReplicatedStorage.Shared.FoodModels)
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
				-- food swells on the way in so it still reads against a huge monster
				local grow = 1 + t * 1.5 * (MonsterView.scaleOf(f.Monster) - 1) / math.max(Config.MaxScale - 1, 1)
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
