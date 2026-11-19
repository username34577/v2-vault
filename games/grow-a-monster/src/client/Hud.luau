-- The always-on HUD, mobile first.
--   top-left: coins (+income) and size chips      top-centre: next look progress
--   left-middle: big SHOP button                   bottom-right: big THROW button (clear of the jump button)
-- Every root is anchored at the corner it hugs and has one responsive UIScale.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local UI = require(script.Parent.UI)

local P = UI.P
local Hud = {}

local gui
local coinValue, incomeValue, sizeValue, coinIcon, sizeIcon
local throwRoot, throwButton, throwFoodSet, throwLabel, throwHint, farLabel
local shopButton, shopBadge
local mileTitle, mileFill, mileCount
local toastFrame, toastText
local shownCoins = 0
local countToken = 0
local onThrow, onShop

---------------------------------------------------------------------------
local function buildStats()
	local root = UI.new("Frame", {
		Name = "Stats",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(196, 124),
	}, gui)
	UI.responsive(root)
	UI.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, root)

	local coins = UI.card({ Name = "Coins", Size = UDim2.fromOffset(196, 60), LayoutOrder = 1 }, root)
	coinIcon = UI.coinIcon(coins, 42)
	coinIcon.Position = UDim2.fromOffset(9, 9)
	coinValue = UI.text({
		Position = UDim2.fromOffset(60, 5),
		Size = UDim2.new(1, -68, 0, 31),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = P.Sunny,
		Text = "0",
	}, coins)
	incomeValue = UI.text({
		Position = UDim2.fromOffset(61, 36),
		Size = UDim2.new(1, -68, 0, 18),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = P.Mint,
		Text = "+0 / sec",
	}, coins)

	local size = UI.card({ Name = "Size", Size = UDim2.fromOffset(196, 56), LayoutOrder = 2 }, root)
	sizeIcon = UI.monsterIcon(size, 40)
	sizeIcon.Position = UDim2.fromOffset(9, 8)
	sizeValue = UI.text({
		Position = UDim2.fromOffset(60, 11),
		Size = UDim2.new(1, -68, 0, 32),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Size 1",
	}, size)
end

local function buildMilestone()
	local root = UI.card({
		Name = "Objective",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 10),
		Size = UDim2.fromOffset(300, 76),
	}, gui)
	UI.responsive(root)
	mileTitle = UI.text({
		Position = UDim2.fromOffset(12, 5),
		Size = UDim2.new(1, -24, 0, 38),
		TextColor3 = P.Sunny,
		TextWrapped = true,
		Text = "",
	}, root)
	local track = UI.new("Frame", {
		Position = UDim2.fromOffset(12, 48),
		Size = UDim2.new(1, -24, 0, 18),
		BackgroundColor3 = P.UINavyLight,
	}, root)
	UI.corner(track, UDim.new(0.5, 0))
	mileFill = UI.new("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = P.Mint,
	}, track)
	UI.corner(mileFill, UDim.new(0.5, 0))
	mileCount = UI.text({
		Size = UDim2.fromScale(1, 1),
		Text = "",
		ZIndex = 2,
	}, track)
end

local function buildShopButton()
	local root = UI.new("Frame", {
		Name = "ShopRoot",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 24),
		Size = UDim2.fromOffset(92, 96),
	}, gui)
	UI.responsive(root)
	shopButton = UI.button({
		Name = "Shop",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = P.Sunny,
		Radius = UDim.new(0, 20),
	}, root, function()
		onShop()
	end)
	UI.foodIcon(shopButton, "Burger", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 2),
		Size = UDim2.fromOffset(70, 60),
		ZIndex = 3,
	})
	UI.text({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -6),
		Size = UDim2.new(1, -10, 0, 28),
		Text = "SHOP",
		ZIndex = 3,
	}, shopButton)
	UI.shine(shopButton, 3)
	shopBadge = UI.new("Frame", {
		Name = "Badge",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.fromOffset(30, 30),
		BackgroundColor3 = P.Bubblegum,
		Visible = false,
		ZIndex = 5,
	}, root)
	UI.corner(shopBadge, UDim.new(0.5, 0))
	UI.stroke(shopBadge, 2.5)
	UI.text({ Size = UDim2.fromScale(1, 0.8), Position = UDim2.fromScale(0, 0.1), Text = "!", ZIndex = 6 }, shopBadge)
	task.spawn(function()
		while shopBadge.Parent do
			if shopBadge.Visible then
				UI.pop(shopBadge, 1.25)
			end
			task.wait(1.2)
		end
	end)
end

local function buildThrow()
	throwRoot = UI.new("Frame", {
		Name = "ThrowRoot",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Size = UDim2.fromOffset(136, 180),
	}, gui)
	UI.responsive(throwRoot)
	throwButton = UI.button({
		Name = "Throw",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(68, 68),
		Size = UDim2.fromOffset(132, 132),
		BackgroundColor3 = P.Coral,
		Radius = UDim.new(0.5, 0),
	}, throwRoot, function()
		onThrow()
	end)
	local ring = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.8, 0.8),
		BackgroundColor3 = P.Coral:Lerp(P.Peach, 0.45),
		Active = false,
		ZIndex = 2,
	}, throwButton)
	UI.corner(ring, UDim.new(0.5, 0))
	local _, set = UI.foodIcon(throwButton, Config.StartingFood, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.47),
		Size = UDim2.fromScale(0.78, 0.78),
		ZIndex = 3,
	})
	throwFoodSet = set
	throwLabel = UI.text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromOffset(68, 116),
		Size = UDim2.fromOffset(128, 36),
		Text = "FEED",
		StrokeThickness = 3,
		ZIndex = 4,
	}, throwRoot)
	throwHint = UI.text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromOffset(68, 152),
		Size = UDim2.fromOffset(128, 20),
		Text = "",
		TextColor3 = P.Cream,
	}, throwRoot)
	farLabel = UI.text({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromOffset(68, -4),
		Size = UDim2.fromOffset(150, 24),
		Text = "Too far! Go home",
		TextColor3 = P.Peach,
		Visible = false,
	}, throwRoot)

	-- Keep clear of Roblox's touch jump button (bottom-right on phones and tablets).
	UI.onScale(function(_, v)
		local right, bottom = 18, 16
		if UserInputService.TouchEnabled then
			right = if math.min(v.X, v.Y) > 500 then 200 else 122
		end
		throwRoot.Position = UDim2.new(1, -right, 1, -bottom)
		if UserInputService.GamepadEnabled and not UserInputService.TouchEnabled then
			throwHint.Text = "R2"
		elseif UserInputService.KeyboardEnabled then
			throwHint.Text = "F or click"
		else
			throwHint.Text = ""
		end
	end)
end

local function buildToast()
	-- holder carries the responsive scale; the card inside carries the pop
	local holder = UI.new("Frame", {
		Name = "ToastRoot",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 96),
		Size = UDim2.fromOffset(290, 58),
	}, gui)
	UI.responsive(holder)
	toastFrame = UI.card({
		Name = "Toast",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Radius = UDim.new(0, 22),
	}, holder)
	toastText = UI.text({
		Position = UDim2.fromOffset(16, 7),
		Size = UDim2.new(1, -32, 1, -14),
		Text = "",
		TextWrapped = true,
	}, toastFrame)
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------
function Hud.build(callbacks)
	onThrow = callbacks.onThrow
	onShop = callbacks.onShop
	gui = UI.screen("HUD", 5)
	buildStats()
	buildMilestone()
	buildShopButton()
	buildThrow()
	buildToast()
end

function Hud.setStats(coins: number, income: number, size: number)
	countToken += 1
	local my = countToken
	if coins > shownCoins and shownCoins > 0 then
		local from = shownCoins
		UI.countUp(from, coins, 0.35, function(v)
			if my == countToken then
				coinValue.Text = Format.short(v)
			end
		end)
		if coins - from >= 1 then
			UI.pop(coinIcon, 1.15)
		end
	else
		coinValue.Text = Format.short(coins)
	end
	shownCoins = coins
	incomeValue.Text = `+{Format.short(income)} / sec`
	if sizeValue.Text ~= `Size {Format.short(size)}` then
		sizeValue.Text = `Size {Format.short(size)}`
		UI.pop(sizeIcon, 1.2)
	end
end

function Hud.setMonsterColor(color: Color3)
	sizeIcon.BackgroundColor3 = color
end

function Hud.setEquipped(foodId: string)
	throwFoodSet(foodId)
end

function Hud.setMilestone(size: number)
	local nextOne, prevSize = nil, 0
	for _, m in Config.Monster.Milestones do
		if size < m.Size then
			nextOne = m
			break
		end
		prevSize = m.Size
	end
	if not nextOne then
		mileTitle.Text = "All looks unlocked!"
		mileFill.Size = UDim2.fromScale(1, 1)
		mileCount.Text = "MAX"
		return
	end
	mileTitle.Text = `Next look: {nextOne.Name}`
	local t = math.clamp((size - prevSize) / (nextOne.Size - prevSize), 0, 1)
	TweenService:Create(mileFill, TweenInfo.new(0.25), { Size = UDim2.fromScale(math.max(t, 0.06), 1) }):Play()
	mileCount.Text = `{Format.short(size)} / {Format.short(nextOne.Size)}`
end

-- Current objective (v0.4): text plus a progress bar.
local lastObjective
function Hud.setObjective(text: string, progress: number, goal: number)
	mileTitle.Text = text
	local t = if goal > 0 then math.clamp(progress / goal, 0, 1) else 0
	TweenService:Create(mileFill, TweenInfo.new(0.25), { Size = UDim2.fromScale(math.max(t, 0.06), 1) }):Play()
	mileCount.Text = `{Format.short(progress)} / {Format.short(goal)}`
	if text ~= lastObjective then
		if lastObjective ~= nil then
			UI.pop(mileTitle.Parent, 1.12)
		end
		lastObjective = text
	end
end

-- What you're carrying: shows the top snack on the FEED button and a count badge.
local carryBadge
function Hud.setCarry(count: number, cap: number, topModel: string?)
	if not carryBadge then
		carryBadge = UI.new("Frame", {
			Name = "CarryBadge",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 14, 0, 14),
			Size = UDim2.fromOffset(56, 34),
			BackgroundColor3 = P.Sunny,
			ZIndex = 6,
		}, throwButton)
		UI.corner(carryBadge, UDim.new(0.5, 0))
		UI.stroke(carryBadge, 2.5)
		UI.text({ Name = "Count", Size = UDim2.fromScale(0.86, 0.8), Position = UDim2.fromScale(0.07, 0.1), Text = "", TextColor3 = P.Outline, ZIndex = 7 }, carryBadge)
	end
	carryBadge.Count.Text = `{count}/{cap}`
	carryBadge.BackgroundColor3 = if count >= cap then P.Coral else P.Sunny
	if topModel and topModel ~= "" then
		throwFoodSet(topModel)
	end
	local empty = count == 0
	throwButton.BackgroundColor3 = if empty then P.Coral:Lerp(P.UINavyLight, 0.6) else P.Coral
	for _, d in throwButton:GetDescendants() do
		if d:IsA("ViewportFrame") then
			d.ImageTransparency = if empty then 0.65 else 0
		end
	end
end

function Hud.setShopVisible(on: boolean)
	shopButton.Parent.Visible = on
end

function Hud.setShopBadge(on: boolean)
	shopBadge.Visible = on
end

function Hud.setFar(far: boolean)
	farLabel.Visible = far
	throwButton.BackgroundColor3 = if far then P.Coral:Lerp(P.UINavyLight, 0.55) else P.Coral
end

function Hud.pressThrow()
	UI.pop(throwButton, 0.88)
	UI.pop(throwLabel, 1.15)
end

local toastToken = 0
-- kind: "info" (navy), "good" (green), "warn" (coral)
function Hud.toast(text: string, kind: string?)
	toastToken += 1
	local my = toastToken
	toastText.Text = text
	toastFrame.BackgroundColor3 = if kind == "good" then P.GrassShade elseif kind == "warn" then P.Coral:Lerp(P.UINavy, 0.35) else P.UINavy
	toastFrame.Visible = true
	toastFrame.Position = UDim2.new(0.5, 0, 0.5, -14)
	TweenService:Create(toastFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.5) }):Play()
	UI.pop(toastFrame, 1.08)
	task.delay(3, function()
		if my == toastToken then
			toastFrame.Visible = false
		end
	end)
end

-- Screen positions (pixels) for flying-coin and number effects.
function Hud.coinTarget(): Vector2
	return coinIcon.AbsolutePosition + coinIcon.AbsoluteSize / 2
end

function Hud.throwCenter(): Vector2
	return throwButton.AbsolutePosition + throwButton.AbsoluteSize / 2
end

function Hud.throwButton()
	return throwButton
end

function Hud.shopButton()
	return shopButton
end

function Hud.gui()
	return gui
end

return Hud
