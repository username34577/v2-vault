-- Grow a Monster: client entry. Wires input, server attributes and remotes to the HUD, shop,
-- monster views and effects. The client only ASKS the server ("throw", "buy <id>", "equip <id>");
-- it never decides coins, size or prices.
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

local Sound = require(script.Parent.Sound)
local Decor = require(script.Parent.Decor)
local MonsterView = require(script.Parent.MonsterView)
local FoodFlight = require(script.Parent.FoodFlight)
local UI = require(script.Parent.UI)
local Hud = require(script.Parent.Hud)
local Shop = require(script.Parent.Shop)
local Feel = require(script.Parent.Feel)
local Tutorial = require(script.Parent.Tutorial)

local player = Players.LocalPlayer

Sound.preload()
Decor.start()
MonsterView.start()
FoodFlight.start()

---------------------------------------------------------------------------
-- My monster
---------------------------------------------------------------------------
local monstersFolder = workspace:WaitForChild("Monsters")

local function myMonster()
	for _, m in monstersFolder:GetChildren() do
		if m:GetAttribute("OwnerUserId") == player.UserId then
			return m
		end
	end
	return nil
end

-- Mirrors the server's range check so we can explain instead of silently failing.
local function isTooFar(monster): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local body = monster and monster.PrimaryPart
	if not root or not body then
		return false
	end
	return (root.Position - body.Position).Magnitude > Config.ThrowRange + body.Size.X / 2
end

---------------------------------------------------------------------------
-- Throwing
---------------------------------------------------------------------------
local lastSent = 0
local function throw()
	local now = os.clock()
	if now - lastSent < Config.ThrowCooldown then
		return -- the server enforces this too; this just avoids wasted sends
	end
	local monster = myMonster()
	if not monster then
		return
	end
	if isTooFar(monster) then
		Hud.setFar(true)
		Hud.toast("Walk back to your monster to feed it!", "warn")
		return
	end
	lastSent = now
	ThrowRemote:FireServer()
	Hud.pressThrow()
	Sound.play("Throw")
end

---------------------------------------------------------------------------
-- HUD + shop
---------------------------------------------------------------------------
Hud.build({
	onThrow = throw,
	onShop = function()
		Shop.toggle()
		Tutorial.shopOpened()
	end,
})
Feel.start(Hud)
Tutorial.start(Hud, myMonster)

Shop.build({
	buy = function(foodId)
		BuyRemote:FireServer(foodId)
	end,
	equip = function(foodId)
		EquipRemote:FireServer(foodId)
	end,
	cantAfford = function(food, need)
		Hud.toast(`Need {need} more coins for {food.Name}`, "warn")
	end,
})

local owned = {}
local lastEquipped = nil
local refreshQueued = false
local ready = false -- true once the first save data has arrived (no purchase sounds on join)

local function refreshAll()
	refreshQueued = false
	local coins = player:GetAttribute("Coins") or 0
	local size = player:GetAttribute("Size") or 1
	local equipped = player:GetAttribute("Equipped") or Config.StartingFood
	for _, food in Config.Foods do
		owned[food.Id] = player:GetAttribute(`Owned_{food.Id}`) == true
	end
	Hud.setStats(coins, player:GetAttribute("Income") or 0, size)
	Hud.setMilestone(size)
	if equipped ~= lastEquipped then
		lastEquipped = equipped
		Hud.setEquipped(equipped)
	end
	local canBuy = Shop.refresh({ Coins = coins, Equipped = equipped, Owned = owned })
	Hud.setShopBadge(canBuy and not Shop.isOpen())
	if ready then
		Tutorial.onCanBuy(canBuy)
	end
	if player:GetAttribute("Coins") ~= nil then
		ready = true
	end
end

local function queueRefresh()
	if not refreshQueued then
		refreshQueued = true
		task.defer(refreshAll)
	end
end

player.AttributeChanged:Connect(function(name)
	local id = string.match(name, "^Owned_(.+)$")
	if not ready then
		queueRefresh()
		return
	end
	if id and player:GetAttribute(name) == true and owned[id] == false then
		Sound.play("Purchase")
		Feel.purchased()
		Shop.confirm(id)
	elseif name == "Equipped" then
		Shop.confirm(player:GetAttribute("Equipped"))
	end
	queueRefresh()
end)
refreshAll()

-- Colour the HUD's monster icon like my monster.
task.spawn(function()
	local monster
	repeat
		monster = myMonster()
		task.wait(0.5)
	until monster
	local plot = monster:GetAttribute("PlotIndex") or 1
	local colors = Config.Monster.Colors[((plot - 1) % #Config.Monster.Colors) + 1]
	Hud.setMonsterColor(colors.Body)
end)

-- "Too far" hint follows the player around.
task.spawn(function()
	while true do
		task.wait(0.25)
		Hud.setFar(isTooFar(myMonster()))
	end
end)

NotifyRemote.OnClientEvent:Connect(function(text)
	if type(text) ~= "string" then
		return
	end
	local kind = if string.find(text, "^Bought") or string.find(text, "^Welcome") then "good"
		elseif string.find(text, "^You need") then "warn"
		else "info"
	Hud.toast(text, kind)
end)

---------------------------------------------------------------------------
-- Input: THROW button, click/tap the world, F, gamepad R2; gamepad Y = shop, B = close
---------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return -- clicked a button or typing in chat
	end
	if input.KeyCode == Enum.KeyCode.F
		or input.UserInputType == Enum.UserInputType.MouseButton1
		or input.KeyCode == Enum.KeyCode.ButtonR2
	then
		if not Shop.isOpen() then
			throw()
		end
	elseif input.KeyCode == Enum.KeyCode.ButtonY then
		Shop.toggle()
		Tutorial.shopOpened()
	elseif input.KeyCode == Enum.KeyCode.ButtonB and Shop.isOpen() then
		Shop.close()
	end
end)

-- Tapping the world on a phone throws too (taps only, so walking with the thumbstick doesn't).
UserInputService.TouchTapInWorld:Connect(function(_, processedByUI)
	if not processedByUI and not Shop.isOpen() then
		throw()
	end
end)

---------------------------------------------------------------------------
-- Server cues: food thrown / eaten (any monster), milestones, fell off
---------------------------------------------------------------------------
local fadeGui = UI.screen("Fade", 50, Enum.ScreenInsets.None)
local fade = UI.new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Config.Palette.Cream,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Active = false,
}, fadeGui)

MonsterView.onMilestone = function(model, milestone, isMine)
	if isMine then
		Feel.milestone(model)
		Sound.play("Milestone")
		Hud.toast(`New look unlocked: {milestone.Name}!`, "good")
	end
end

FxRemote.OnClientEvent:Connect(function(kind, monster, foodId, extra)
	if kind == "Throw" and typeof(monster) == "Instance" then
		MonsterView.expect(monster, Config.FlightTime)
		FoodFlight.launch(monster, foodId, extra)
	elseif kind == "Eat" and typeof(monster) == "Instance" then
		local growth = tonumber(extra) or 1
		local mine = monster:GetAttribute("OwnerUserId") == player.UserId
		MonsterView.gulp(monster, growth)
		Feel.ate(monster, foodId, growth, mine)
		if mine then
			Tutorial.onBite()
		end
	elseif kind == "Fell" then
		Sound.play("Whoosh")
		fade.BackgroundTransparency = 0
		TweenService:Create(fade, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
	end
end)
