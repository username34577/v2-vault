-- Shared game numbers. The server reads prices and growth from HERE, never from the client.
local Config = {}

-- Foods, cheapest first. Growth = how much Size one hit adds. Coins on hit = Growth.
Config.Foods = {
	{ Id = "Apple", Name = "Apple", Price = 0, Growth = 1, Color = Color3.fromRGB(220, 40, 40) },
	{ Id = "Burger", Name = "Burger", Price = 60, Growth = 3, Color = Color3.fromRGB(170, 110, 50) },
	{ Id = "Cake", Name = "Cake", Price = 400, Growth = 10, Color = Color3.fromRGB(255, 170, 210) },
	{ Id = "Pizza", Name = "Pizza", Price = 2500, Growth = 35, Color = Color3.fromRGB(255, 190, 60) },
	{ Id = "GoldenSteak", Name = "Golden Steak", Price = 15000, Growth = 120, Color = Color3.fromRGB(255, 215, 0) },
	{ Id = "CosmicCandy", Name = "Cosmic Candy", Price = 90000, Growth = 450, Color = Color3.fromRGB(140, 80, 255) },
}

Config.FoodById = {}
for index, food in Config.Foods do
	food.Order = index
	Config.FoodById[food.Id] = food
end

Config.StartingFood = "Apple"

-- Throwing
Config.ThrowCooldown = 0.3 -- seconds between throws (server enforced)
Config.ThrowRange = 90 -- max studs from your own monster to throw
Config.FlightTime = 0.45 -- seconds the food is in the air

-- Passive income: coins per second = floor(Size * IncomePerSize)
Config.IncomePerSize = 0.5

-- Offline earnings: a share of normal income while away, capped
Config.OfflineShare = 0.25
Config.OfflineMaxSeconds = 2 * 60 * 60

-- Monster look: visual scale grows slower than Size and is capped so plots don't overlap
Config.MaxScale = 10
function Config.scaleForSize(size: number): number
	return math.min(Config.MaxScale, 1 + math.sqrt(math.max(size - 1, 0)) * 0.2)
end

-- Plots in a ring around the map center
Config.PlotCount = 8
Config.PlotRingRadius = 140
Config.PlotSize = 70

return Config
