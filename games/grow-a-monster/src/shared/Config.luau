-- Shared game numbers. The server reads prices and growth from HERE, never from the client.
-- To rebalance or restyle the game, edit only this file.
local Config = {}

local function hex(value: string): Color3
	return Color3.fromHex(value)
end

---------------------------------------------------------------------------
-- Gameplay
---------------------------------------------------------------------------

-- Foods, cheapest first. Growth = how much Size one hit adds. Coins on hit = Growth.
Config.Foods = {
	{ Id = "Apple", Name = "Apple", Price = 0, Growth = 1, Color = Color3.fromRGB(232, 65, 75) },
	{ Id = "Burger", Name = "Burger", Price = 60, Growth = 3, Color = Color3.fromRGB(232, 162, 74) },
	{ Id = "Cake", Name = "Cake", Price = 400, Growth = 10, Color = Color3.fromRGB(255, 143, 199) },
	{ Id = "Pizza", Name = "Pizza", Price = 2500, Growth = 35, Color = Color3.fromRGB(255, 216, 74) },
	{ Id = "GoldenSteak", Name = "Golden Steak", Price = 15000, Growth = 120, Color = Color3.fromRGB(245, 197, 66) },
	{ Id = "CosmicCandy", Name = "Cosmic Candy", Price = 90000, Growth = 450, Color = Color3.fromRGB(183, 156, 255) },
}

-- Food part colours (shapes are built in Shared/FoodModels.luau)
Config.FoodColors = {
	AppleSkin = hex("#E8414B"),
	AppleDimple = hex("#B02A38"),
	Bun = hex("#E8A24A"),
	BunTop = hex("#F0B35E"),
	Patty = hex("#7A3E22"),
	Tomato = hex("#FF5A4E"),
	Sponge = hex("#FFB3D6"),
	Frosting = hex("#FFF4E8"),
	Cherry = hex("#E8414B"),
	Dough = hex("#F2C27B"),
	Cheese = hex("#FFD84A"),
	Pepperoni = hex("#D9443A"),
	Gold = hex("#F5C542"),
	GoldDark = hex("#D9A322"),
	Bone = hex("#FFF1D6"),
	Candy = hex("#B79CFF"),
	CandyBand = hex("#7FE8C8"),
	Wrapper = hex("#FF8FC7"),
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

-- Monster scale: visual scale grows slower than Size and is capped so plots don't overlap
Config.MaxScale = 10
function Config.scaleForSize(size: number): number
	return math.min(Config.MaxScale, 1 + math.sqrt(math.max(size - 1, 0)) * 0.2)
end

-- Plots in a ring around the map center
Config.PlotCount = 8
Config.PlotRingRadius = 140
Config.PlotSize = 70

---------------------------------------------------------------------------
-- Look: one palette for the whole game (world, monsters, food, UI)
---------------------------------------------------------------------------
Config.Palette = {
	Grass = hex("#7BD45A"), -- main ground
	GrassShade = hex("#4FA83D"), -- shading, bushes, tree canopies
	Wood = hex("#A8703F"), -- fences, signs
	WoodLight = hex("#C98E55"),
	WoodDark = hex("#7A4E2B"), -- trunks, dirt layer
	Mint = hex("#7FE8C8"),
	Bubblegum = hex("#FF8FC7"),
	Sunny = hex("#FFD84A"),
	Sky = hex("#6EC6FF"),
	Lilac = hex("#B79CFF"),
	Peach = hex("#FFB38A"),
	Coral = hex("#FF7A6B"),
	Tangerine = hex("#FFA94D"),
	Cream = hex("#FFF1D6"), -- paths, plaza
	Rock = hex("#A89A92"), -- warm stone, never grey-black
	RockDark = hex("#8A7C7A"),
	RockLight = hex("#C4B8AE"),
	Cloud = hex("#FAF6FF"), -- near-white with a lilac tint
	CloudShade = hex("#EDE3FA"),
	UINavy = hex("#23233A"), -- UI panels
	UINavyLight = hex("#33335A"),
	Outline = hex("#1A1A2A"), -- outlines and text stroke
	TextLight = hex("#FFF8EE"),
	Silver = hex("#DDE3F0"),
	Bronze = hex("#E8A15C"),
}

-- Lighting: sunny early afternoon (~2:30 PM), warm sun, cool blue-lavender shadows.
-- Vault: "Lighting Untextured Art in Roblox", "Atmosphere Sky Clouds and Post-Processing".
Config.Lighting = {
	ClockTime = 14.5,
	GeographicLatitude = 30, -- puts the sun roughly 45 degrees up at 2:30 PM
	Brightness = 2.6,
	ExposureCompensation = 0.1,
	Ambient = hex("#7C82A6"), -- cool, indoor/shadow fill
	OutdoorAmbient = hex("#9AA3CC"), -- blue-lavender shadows, well above black
	ColorShift_Top = hex("#FFE2B8"), -- warm sunlit faces
	ColorShift_Bottom = hex("#9CCB7E"), -- green bounce from the grass
	EnvironmentDiffuseScale = 0.35,
	EnvironmentSpecularScale = 0.2,
	ShadowSoftness = 0.35,

	Atmosphere = {
		Density = 0.3,
		Offset = 0.08, -- low: the edge blends into the sky so the world never "ends"
		Color = hex("#C9C6F2"), -- blue-lavender haze
		Decay = hex("#FFC9B5"), -- peach-pink horizon away from the sun
		Glare = 0.35,
		Haze = 1.6,
	},
	Sky = {
		SunAngularSize = 16,
		MoonAngularSize = 9,
		StarCount = 0,
	},
	Clouds = { -- Terrain clouds high in the sky
		Cover = 0.55,
		Density = 0.55,
		Color = hex("#FFF9FC"),
	},
	Wind = Vector3.new(3, 0, 1.5), -- moves the sky clouds
	Bloom = { Intensity = 0.35, Size = 22, Threshold = 1.6 }, -- threshold >= 1.5 so white parts don't glow
	ColorCorrection = { Brightness = 0.02, Contrast = 0.06, Saturation = 0.14, TintColor = hex("#FFF7EC") },
	SunRays = { Intensity = 0.04, Spread = 0.5 },
}

---------------------------------------------------------------------------
-- Map
---------------------------------------------------------------------------
Config.Map = {
	Seed = 2026, -- same decoration layout on every server
	IslandRadius = 215,
	PlotTopY = 0.6, -- top of each plot pad (the monster stands here)
	HubRadius = 44,
	PathWidth = 11,
	FenceInset = 1.5, -- fence distance from the plot edge
	FencePostSpacing = 8.75,
	FenceHeight = 4.5,
	GateWidth = 14,
	FeedingPadDiameter = 20,
	TreeCount = 8, -- one between each pair of plots
	RimBushes = 18,
	RimFlowers = 22,
	Vines = 22,
	-- Decoration below and around the island (built on each client, no collisions)
	CloudSeaY = -170,
	CloudSeaRadius = 760,
	CloudPuffs = 70,
	CloudDriftSpeed = { 0.6, 1.8 }, -- studs per second
	MiniIslands = 4,
	MiniIslandRadius = { 265, 310 },
	BobAmplitude = 2.2, -- studs
	BobPeriod = { 6, 9 }, -- seconds
	-- Fall safety: below this height the server puts you back on your plot
	FallY = -60,
	FallCheckInterval = 0.2,
}

Config.Leaderboard = {
	Rows = 8,
	RefreshSeconds = 2,
	BoardWidth = 30,
	BoardHeight = 36,
}

---------------------------------------------------------------------------
-- Monster look (client-side visuals; the server only owns Size)
---------------------------------------------------------------------------
Config.Monster = {
	-- One colour pair per plot: warm body + cool spots (or the reverse).
	Colors = {
		{ Body = Config.Palette.Bubblegum, Spot = Config.Palette.Mint },
		{ Body = Config.Palette.Sunny, Spot = Config.Palette.Sky },
		{ Body = Config.Palette.Mint, Spot = Config.Palette.Bubblegum },
		{ Body = Config.Palette.Sky, Spot = Config.Palette.Sunny },
		{ Body = Config.Palette.Peach, Spot = Config.Palette.Lilac },
		{ Body = Config.Palette.Lilac, Spot = Config.Palette.Peach },
		{ Body = Config.Palette.Coral, Spot = Config.Palette.Mint },
		{ Body = Config.Palette.Tangerine, Spot = Config.Palette.Sky },
	},
	MouthColor = hex("#5A2236"),
	TongueColor = hex("#FF6F9E"),
	-- Idle motion
	BreathPeriod = 1.6, -- seconds per squash cycle
	BreathAmount = 0.045, -- squash fraction
	HopEvery = { 4, 8 }, -- seconds between happy hops
	HopHeight = 0.7, -- studs at scale 1
	BlinkEvery = { 2.2, 5 },
	BlinkTime = 0.12,
	GulpSquash = 0.18, -- how hard the body squashes when it eats
	GrowSpeed = 6, -- how fast the visual scale catches up (per second)
	-- Cosmetic unlocks at size milestones (in order)
	Milestones = {
		{ Size = 25, Id = "Sprout", Name = "Leaf Sprout" },
		{ Size = 100, Id = "Horns", Name = "Horns" },
		{ Size = 1000, Id = "Wings", Name = "Wings" },
		{ Size = 10000, Id = "Crown", Name = "Crown" },
		{ Size = 100000, Id = "Aura", Name = "Sparkle Aura" },
	},
}

---------------------------------------------------------------------------
-- Game feel and the first 30 seconds
---------------------------------------------------------------------------
Config.Feel = {
	NumberRise = 4.5, -- studs the "+X" floats up
	NumberTime = 0.9, -- seconds on screen
	CrumbCount = 10, -- particles when a monster eats
	CoinFlyMax = 5, -- coins that fly to the counter per bite
	CoinFlyTime = 0.55,
	BumpMinGrowth = 10, -- foods this big (Cake and up) bump the screen
	BumpFov = 2, -- field-of-view punch in degrees for the smallest bump
	BumpMaxFov = 5,
	ScreenBump = true, -- set false to turn the bump off for everyone
}

Config.Tutorial = {
	MaxStartSize = 10, -- show the hint only to monsters this small (new players)
	ThrowsToHide = 3, -- bites before the hint goes away
	ShopNudgeSeconds = 6, -- how long the "buy better food" arrow stays
}

---------------------------------------------------------------------------
-- Sounds: paste Creator Store audio IDs here (number or "rbxassetid://123").
-- Empty or broken slots are skipped silently, so the game works before they're filled.
---------------------------------------------------------------------------
Config.Sounds = {
	Throw = { Id = "", Volume = 0.5, PitchVariance = 0.08 }, -- short soft "whoosh/swish" as food leaves your hand
	Gulp = { Id = "", Volume = 0.7, PitchVariance = 0.1 }, -- cartoon "gulp" or "nom" when the monster eats
	Coin = { Id = "", Volume = 0.35, PitchVariance = 0.05 }, -- tiny bright "ting" when coins are earned
	Purchase = { Id = "", Volume = 0.6, PitchVariance = 0 }, -- happy "cha-ching" / register when you buy food
	Milestone = { Id = "", Volume = 0.7, PitchVariance = 0 }, -- short fanfare/jingle when a new look unlocks
	ButtonClick = { Id = "", Volume = 0.4, PitchVariance = 0.04 }, -- soft "pop" UI click
	Whoosh = { Id = "", Volume = 0.6, PitchVariance = 0 }, -- airy "whoosh" when you fall off and get put back
}

return Config
