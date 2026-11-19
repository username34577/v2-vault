-- Grow a Monster: client HUD, throwing input and shop.
-- The client only ASKS the server to do things; it never decides coins, size or prices.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ThrowRemote = Remotes:WaitForChild("Throw")
local BuyRemote = Remotes:WaitForChild("BuyFood")
local EquipRemote = Remotes:WaitForChild("EquipFood")
local NotifyRemote = Remotes:WaitForChild("Notify")
local FxRemote = Remotes:WaitForChild("Fx")

local Decor = require(script.Parent.Decor)
local Sound = require(script.Parent.Sound)
local MonsterView = require(script.Parent.MonsterView)
local FoodFlight = require(script.Parent.FoodFlight)
Decor.start()
Sound.preload()
MonsterView.start()
FoodFlight.start()

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function abbreviate(n)
	n = math.floor(n or 0)
	local units = { "", "K", "M", "B", "T" }
	local i = 1
	local value = n
	while value >= 1000 and i < #units do
		value /= 1000
		i += 1
	end
	if i == 1 then
		return tostring(n)
	end
	return string.format("%.1f%s", value, units[i])
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 12)
	c.Parent = parent
end

local function label(props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextScaled = true
	for k, v in props do
		l[k] = v
	end
	return l
end

local function button(props)
	local b = Instance.new("TextButton")
	b.Font = Enum.Font.FredokaOne
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextScaled = true
	b.AutoButtonColor = true
	for k, v in props do
		b[k] = v
	end
	corner(b, 12)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(20, 20, 30)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = b
	return b
end

---------------------------------------------------------------------------
-- HUD
---------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "GrowAMonsterHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = playerGui

local stats = Instance.new("Frame")
stats.Name = "Stats"
stats.AnchorPoint = Vector2.new(0, 0.5)
stats.Position = UDim2.new(0, 12, 0.45, 0)
stats.Size = UDim2.fromOffset(200, 120)
stats.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
stats.BackgroundTransparency = 0.2
stats.Parent = gui
corner(stats, 14)

local coinsLabel = label({ Size = UDim2.new(1, -16, 0.4, 0), Position = UDim2.fromOffset(8, 6), Text = "Coins: 0", TextColor3 = Color3.fromRGB(255, 220, 80) })
coinsLabel.Parent = stats
local sizeLabel = label({ Size = UDim2.new(1, -16, 0.3, 0), Position = UDim2.new(0, 8, 0.42, 0), Text = "Size: 1" })
sizeLabel.Parent = stats
local incomeLabel = label({ Size = UDim2.new(1, -16, 0.22, 0), Position = UDim2.new(0, 8, 0.74, 0), Text = "+0 / sec", TextColor3 = Color3.fromRGB(150, 255, 150) })
incomeLabel.Parent = stats

local throwButton = button({
	Name = "Throw",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.fromOffset(150, 70),
	BackgroundColor3 = Color3.fromRGB(240, 110, 60),
	Text = "THROW",
})
throwButton.Parent = gui

local shopButton = button({
	Name = "ShopButton",
	Position = UDim2.new(0, 12, 0.45, 80),
	Size = UDim2.fromOffset(200, 50),
	BackgroundColor3 = Color3.fromRGB(70, 160, 240),
	Text = "SHOP",
})
shopButton.Parent = gui

local equippedLabel = label({
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -92),
	Size = UDim2.fromOffset(150, 26),
	Text = "Food: Apple",
})
equippedLabel.Parent = gui

local toast = label({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 12),
	Size = UDim2.fromOffset(520, 40),
	BackgroundColor3 = Color3.fromRGB(25, 25, 40),
	BackgroundTransparency = 1,
	TextTransparency = 1,
	Text = "",
})
toast.Parent = gui
corner(toast, 10)

local toastToken = 0
local function showToast(text)
	toastToken += 1
	local my = toastToken
	toast.Text = text
	toast.TextTransparency = 0
	toast.BackgroundTransparency = 0.2
	task.delay(3, function()
		if my == toastToken then
			TweenService:Create(toast, TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		end
	end)
end
NotifyRemote.OnClientEvent:Connect(function(text)
	if type(text) == "string" then
		showToast(text)
	end
end)

---------------------------------------------------------------------------
-- Shop
---------------------------------------------------------------------------
local shop = Instance.new("Frame")
shop.Name = "Shop"
shop.AnchorPoint = Vector2.new(0.5, 0.5)
shop.Position = UDim2.fromScale(0.5, 0.5)
shop.Size = UDim2.fromOffset(420, 380)
shop.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
shop.Visible = false
shop.Parent = gui
corner(shop, 16)

local title = label({ Size = UDim2.new(1, -60, 0, 44), Position = UDim2.fromOffset(16, 8), Text = "Food Shop", TextXAlignment = Enum.TextXAlignment.Left })
title.Parent = shop
local close = button({ Size = UDim2.fromOffset(40, 40), Position = UDim2.new(1, -50, 0, 10), BackgroundColor3 = Color3.fromRGB(220, 70, 70), Text = "X" })
close.Parent = shop

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(12, 60)
list.Size = UDim2.new(1, -24, 1, -72)
list.BackgroundTransparency = 1
list.ScrollBarThickness = 6
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = shop
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local rows = {}
for _, food in Config.Foods do
	local row = Instance.new("Frame")
	row.Name = food.Id
	row.LayoutOrder = food.Order
	row.Size = UDim2.new(1, -8, 0, 56)
	row.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
	row.Parent = list
	corner(row, 10)

	local swatch = Instance.new("Frame")
	swatch.Size = UDim2.fromOffset(36, 36)
	swatch.Position = UDim2.fromOffset(10, 10)
	swatch.BackgroundColor3 = food.Color
	swatch.Parent = row
	corner(swatch, 18)

	local nameLabel = label({ Position = UDim2.fromOffset(56, 4), Size = UDim2.new(0.5, -40, 0, 26), Text = food.Name, TextXAlignment = Enum.TextXAlignment.Left })
	nameLabel.Parent = row
	local info = label({
		Position = UDim2.fromOffset(56, 30),
		Size = UDim2.new(0.5, -40, 0, 20),
		Text = `+{food.Growth} size / throw`,
		TextColor3 = Color3.fromRGB(180, 220, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	info.Parent = row

	local action = button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(130, 40),
		BackgroundColor3 = Color3.fromRGB(80, 190, 90),
		Text = "",
	})
	action.Parent = row
	action.Activated:Connect(function()
		if player:GetAttribute(`Owned_{food.Id}`) then
			EquipRemote:FireServer(food.Id)
		else
			BuyRemote:FireServer(food.Id)
		end
	end)
	rows[food.Id] = { Button = action, Food = food }
end

local function refreshShop()
	local coins = player:GetAttribute("Coins") or 0
	local equipped = player:GetAttribute("Equipped")
	for id, row in rows do
		local owned = player:GetAttribute(`Owned_{id}`)
		if equipped == id then
			row.Button.Text = "EQUIPPED"
			row.Button.BackgroundColor3 = Color3.fromRGB(110, 110, 130)
		elseif owned then
			row.Button.Text = "EQUIP"
			row.Button.BackgroundColor3 = Color3.fromRGB(70, 160, 240)
		else
			row.Button.Text = `{abbreviate(row.Food.Price)} coins`
			row.Button.BackgroundColor3 = if coins >= row.Food.Price then Color3.fromRGB(80, 190, 90) else Color3.fromRGB(150, 70, 70)
		end
	end
end

shopButton.Activated:Connect(function()
	shop.Visible = not shop.Visible
	refreshShop()
end)
close.Activated:Connect(function()
	shop.Visible = false
end)

---------------------------------------------------------------------------
-- Keep the HUD in sync with server attributes
---------------------------------------------------------------------------
local function refreshHud()
	coinsLabel.Text = `Coins: {abbreviate(player:GetAttribute("Coins"))}`
	sizeLabel.Text = `Size: {abbreviate(player:GetAttribute("Size"))}`
	incomeLabel.Text = `+{abbreviate(player:GetAttribute("Income"))} / sec`
	local equipped = Config.FoodById[player:GetAttribute("Equipped") or ""]
	equippedLabel.Text = `Food: {if equipped then equipped.Name else "Apple"}`
	if shop.Visible then
		refreshShop()
	end
end
player.AttributeChanged:Connect(refreshHud)
refreshHud()

---------------------------------------------------------------------------
-- Throwing: THROW button, click/tap the world, or press F / Space-free key
---------------------------------------------------------------------------
local lastSent = 0
local function throw()
	local now = os.clock()
	if now - lastSent < Config.ThrowCooldown then
		return -- the server enforces this too; this just avoids wasted sends
	end
	lastSent = now
	ThrowRemote:FireServer()
	-- tiny button bounce so it feels responsive
	throwButton.Size = UDim2.fromOffset(140, 64)
	TweenService:Create(throwButton, TweenInfo.new(0.12), { Size = UDim2.fromOffset(150, 70) }):Play()
end

throwButton.Activated:Connect(throw)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return -- clicked a button or typing in chat
	end
	if input.KeyCode == Enum.KeyCode.F
		or input.UserInputType == Enum.UserInputType.MouseButton1
		or input.KeyCode == Enum.KeyCode.ButtonR2
	then
		throw()
	end
end)

---------------------------------------------------------------------------
-- Fell off the island: the server already put us back; fade + whoosh
---------------------------------------------------------------------------
local fadeGui = Instance.new("ScreenGui")
fadeGui.Name = "Fade"
fadeGui.IgnoreGuiInset = true
fadeGui.DisplayOrder = 50
fadeGui.ResetOnSpawn = false
fadeGui.Parent = playerGui
local fade = Instance.new("Frame")
fade.Size = UDim2.fromScale(1, 1)
fade.BackgroundColor3 = Config.Palette.Cream
fade.BackgroundTransparency = 1
fade.BorderSizePixel = 0
fade.Active = false
fade.Parent = fadeGui

MonsterView.onMilestone = function(_model, milestone, isMine)
	if isMine then
		Sound.play("Milestone")
		showToast(`New look unlocked: {milestone.Name}!`)
	end
end

FxRemote.OnClientEvent:Connect(function(kind, monster, foodId, extra)
	if kind == "Throw" and typeof(monster) == "Instance" then
		MonsterView.expect(monster, Config.FlightTime)
		FoodFlight.launch(monster, foodId, extra)
	elseif kind == "Eat" and typeof(monster) == "Instance" then
		MonsterView.gulp(monster, tonumber(extra) or 1)
	elseif kind == "Fell" then
		Sound.play("Whoosh")
		fade.BackgroundTransparency = 0
		TweenService:Create(fade, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
	end
end)
