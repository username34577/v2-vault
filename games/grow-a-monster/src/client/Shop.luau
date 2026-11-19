-- Food shop: one centred panel, cards with a spinning 3D food, "BEST VALUE" / "NEXT UP" tags,
-- "x faster" chips, a progress fill on what you're saving for, and a shine on buys you can afford.
-- The client only sends "buy <id>" / "equip <id>"; the server checks price and coins.
-- Vault: "Menu Archetypes - Shop Settings Codes Rewards" (one panel, big close top-right,
-- gamepad B closes, buy buttons have a pending state).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local UI = require(script.Parent.UI)

local P = UI.P
local Shop = {}

local PANEL_W = 580
local CARD_W, CARD_H = 172, 176

local dimGui, gui, holder, panel, panelPop, dim, coinLabel
local cards = {} -- [foodId] = { ... }
local isOpen = false
local callbacks
local state = { Coins = 0, Equipped = Config.StartingFood, Owned = {} }
local pending = {} -- [foodId] = os.clock() of the request

local function tag(card, text, color)
	card.Tag.Visible = text ~= nil
	if text then
		card.Tag.BackgroundColor3 = color
		card.TagText.Text = text
	end
end

local function buildCard(food, parent)
	local frame = UI.card({
		Name = food.Id,
		LayoutOrder = food.Order,
		Size = UDim2.fromOffset(CARD_W, CARD_H),
		BackgroundColor3 = P.UINavyLight,
		Radius = UDim.new(0, 18),
	}, parent)
	local stroke = frame:FindFirstChildOfClass("UIStroke")

	UI.foodIcon(frame, food.Id, {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(92, 62),
	})
	UI.text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 68),
		Size = UDim2.new(1, -14, 0, 24),
		Text = food.Name,
	}, frame)
	UI.text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 92),
		Size = UDim2.new(1, -14, 0, 18),
		Text = `+{Format.short(food.Growth)} size / throw`,
		TextColor3 = P.Mint,
	}, frame)

	local tagFrame = UI.new("Frame", {
		Name = "Tag",
		Position = UDim2.fromOffset(-6, -8),
		Size = UDim2.fromOffset(98, 24),
		Rotation = -6,
		Visible = false,
		ZIndex = 5,
	}, frame)
	UI.corner(tagFrame, UDim.new(0.5, 0))
	UI.stroke(tagFrame, 2.5)
	local tagText = UI.text({ Size = UDim2.new(1, -10, 1, -6), Position = UDim2.fromOffset(5, 3), ZIndex = 6, TextColor3 = P.Outline, StrokeThickness = 0 }, tagFrame)

	local faster = UI.new("Frame", {
		Name = "Faster",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.fromOffset(52, 22),
		BackgroundColor3 = P.Mint,
		Visible = false,
		ZIndex = 5,
	}, frame)
	UI.corner(faster, UDim.new(0.5, 0))
	UI.stroke(faster, 2)
	local fasterText = UI.text({ Size = UDim2.new(1, -8, 1, -6), Position = UDim2.fromOffset(4, 3), ZIndex = 6, TextColor3 = P.Outline, StrokeThickness = 0 }, faster)

	local button = UI.button({
		Name = "Action",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(1, -16, 0, 52),
		BackgroundColor3 = P.Grass,
		Radius = UDim.new(0, 14),
	}, frame, function()
		local now = os.clock()
		if pending[food.Id] and now - pending[food.Id] < 1.5 then
			return
		end
		if state.Owned[food.Id] then
			if state.Equipped ~= food.Id then
				pending[food.Id] = now
				callbacks.equip(food.Id)
				Shop.refresh()
			end
		elseif state.Coins >= food.Price then
			pending[food.Id] = now
			callbacks.buy(food.Id)
			Shop.refresh()
		else
			callbacks.cantAfford(food, food.Price - math.floor(state.Coins))
			UI.pop(frame, 0.95)
		end
	end)
	local progress = UI.new("Frame", {
		Name = "Progress",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = P.GrassShade,
		BackgroundTransparency = 0.2,
		ZIndex = 1,
	}, button)
	UI.corner(progress, UDim.new(0, 14))
	local coin = UI.coinIcon(button, 24)
	coin.AnchorPoint = Vector2.new(0, 0.5)
	coin.ZIndex = 3
	for _, d in coin:GetDescendants() do
		if d:IsA("GuiObject") then
			d.ZIndex = 3
		end
	end
	local label = UI.text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -16, 0, 28),
		ZIndex = 3,
		Text = "",
	}, button)
	local shine = UI.shine(button, 2.2)

	cards[food.Id] = {
		Frame = frame,
		Stroke = stroke,
		Button = button,
		Label = label,
		Coin = coin,
		Progress = progress,
		Shine = shine,
		Tag = tagFrame,
		TagText = tagText,
		Faster = faster,
		FasterText = fasterText,
		Food = food,
	}
end

local function setButton(card, text, color, showCoin)
	card.Button.BackgroundColor3 = color
	card.Label.Text = text
	card.Coin.Visible = showCoin
	if showCoin then
		card.Label.Position = UDim2.new(0.5, 14, 0.5, 0)
		card.Label.Size = UDim2.new(1, -52, 0, 28)
		card.Coin.Position = UDim2.new(0, 12, 0.5, 0)
	else
		card.Label.Position = UDim2.fromScale(0.5, 0.5)
		card.Label.Size = UDim2.new(1, -16, 0, 28)
	end
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------
function Shop.build(cb)
	callbacks = cb

	-- dim the whole screen edge to edge (separate gui with no insets)
	dimGui = UI.screen("ShopDim", 9, Enum.ScreenInsets.None)
	dimGui.Enabled = false
	dim = UI.new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = P.Outline,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Selectable = false,
	}, dimGui)
	dim.Activated:Connect(function()
		Shop.close()
	end)

	gui = UI.screen("Shop", 10)
	gui.Enabled = false
	holder = UI.new("Frame", {
		Name = "ShopHolder",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(PANEL_W, 420),
	}, gui)
	-- Fit the panel on screen: shrink a little on small phones, but keep taps >= 44 px.
	local fitScale = UI.new("UIScale", {}, holder)
	UI.onScale(function(scale, v)
		local s = math.min(scale, (v.X - 24) / PANEL_W)
		fitScale.Scale = s
		local height = math.clamp((v.Y - 70) / s, 280, 430)
		holder.Size = UDim2.fromOffset(PANEL_W, height)
	end)

	panel = UI.card({
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Radius = UDim.new(0, 24),
	}, holder)
	panelPop = UI.new("UIScale", { Name = "Pop" }, panel)

	UI.text({
		Position = UDim2.fromOffset(20, 12),
		Size = UDim2.fromOffset(230, 40),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "FOOD SHOP",
		TextColor3 = P.Sunny,
		StrokeThickness = 3,
	}, panel)
	local coinChip = UI.new("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -84, 0, 14),
		Size = UDim2.fromOffset(160, 38),
		BackgroundColor3 = P.UINavyLight,
	}, panel)
	UI.corner(coinChip, UDim.new(0.5, 0))
	UI.stroke(coinChip, 2.5)
	local chipCoin = UI.coinIcon(coinChip, 28)
	chipCoin.Position = UDim2.fromOffset(6, 5)
	coinLabel = UI.text({
		Position = UDim2.fromOffset(40, 5),
		Size = UDim2.new(1, -50, 1, -10),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = P.Sunny,
		Text = "0",
	}, coinChip)

	local close = UI.button({
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 8),
		Size = UDim2.fromOffset(56, 52),
		BackgroundColor3 = P.Coral,
		Label = "X",
		Radius = UDim.new(0, 16),
	}, panel, function()
		Shop.close()
	end)
	close.Label.Size = UDim2.new(1, -14, 0.7, 0)

	local list = UI.new("ScrollingFrame", {
		Name = "Cards",
		Position = UDim2.fromOffset(14, 70),
		Size = UDim2.new(1, -28, 1, -82),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = P.Mint,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ClipsDescendants = true,
	}, panel)
	UI.new("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 8),
	}, list)
	UI.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(CARD_W, CARD_H),
		CellPadding = UDim2.fromOffset(10, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
	}, list)
	for _, food in Config.Foods do
		buildCard(food, list)
	end
end

-- Recolour every card from the latest state (cheap: 6 cards, only on change).
-- stateOnly = true just stores the state (the shop recolours itself when it opens).
function Shop.refresh(newState, stateOnly: boolean?)
	if newState then
		for k, v in newState do
			state[k] = v
		end
	end
	if stateOnly then
		return false
	end
	coinLabel.Text = Format.short(state.Coins)
	local equippedFood = Config.FoodById[state.Equipped] or Config.FoodById[Config.StartingFood]

	-- BEST VALUE: the biggest upgrade you can buy right now. NEXT UP: the next one to save for.
	local best, nextUp
	for _, food in Config.Foods do
		if not state.Owned[food.Id] then
			if state.Coins >= food.Price then
				best = food
			elseif not nextUp then
				nextUp = food
			end
		end
	end

	local now = os.clock()
	for id, card in cards do
		local food = card.Food
		local owned = state.Owned[id] == true
		local isPending = pending[id] and now - pending[id] < 1.5
		card.Progress.Visible = false
		card.Shine.Visible = false
		card.Stroke.Color = P.Outline
		card.Stroke.Thickness = 3
		if isPending then
			setButton(card, "...", P.UINavy, false)
		elseif state.Equipped == id then
			setButton(card, "EQUIPPED", P.Lilac:Lerp(P.UINavy, 0.35), false)
			card.Stroke.Color = P.Mint
			card.Stroke.Thickness = 4
		elseif owned then
			setButton(card, "EQUIP", P.Sky:Lerp(P.UINavy, 0.15), false)
		elseif state.Coins >= food.Price then
			setButton(card, Format.short(food.Price), P.Grass:Lerp(P.GrassShade, 0.3), true)
			card.Shine.Visible = true
		else
			setButton(card, Format.short(food.Price), P.UINavy, true)
			card.Progress.Visible = true
			card.Progress.Size = UDim2.fromScale(math.clamp(state.Coins / math.max(food.Price, 1), 0.04, 1), 1)
		end

		if not owned and food == best then
			tag(card, "BEST VALUE", P.Sunny)
		elseif not owned and food == nextUp then
			tag(card, "NEXT UP", P.Sky)
		else
			tag(card, nil)
		end
		local mult = food.Growth / math.max(equippedFood.Growth, 1)
		card.Faster.Visible = not owned and mult >= 2
		card.FasterText.Text = `x{Format.short(mult)} fast`
	end
	return best ~= nil
end

-- Call when the server confirms a purchase or equip (clears the pending state, pops the card).
function Shop.confirm(foodId: string)
	pending[foodId] = nil
	local card = cards[foodId]
	if card then
		UI.pop(card.Frame, 1.1)
	end
	Shop.refresh()
end

function Shop.open()
	if isOpen then
		return
	end
	isOpen = true
	Shop.refresh()
	gui.Enabled = true
	dimGui.Enabled = true
	panelPop.Scale = 0.82
	TweenService:Create(panelPop, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	dim.BackgroundTransparency = 1
	TweenService:Create(dim, TweenInfo.new(0.2), { BackgroundTransparency = 0.45 }):Play()
	if UserInputService.GamepadEnabled then
		GuiService.SelectedObject = cards[Config.Foods[1].Id].Button
	end
	-- B arrives as "game processed" while a button is selected, so bind it above the UI.
	ContextActionService:BindActionAtPriority("CloseShop", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			Shop.close()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonB)
end

function Shop.close()
	if not isOpen then
		return
	end
	isOpen = false
	ContextActionService:UnbindAction("CloseShop")
	TweenService:Create(panelPop, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.85 }):Play()
	task.delay(0.14, function()
		if not isOpen then
			gui.Enabled = false
			dimGui.Enabled = false
		end
	end)
	if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(gui) then
		GuiService.SelectedObject = nil
	end
end

function Shop.toggle()
	if isOpen then
		Shop.close()
	else
		Shop.open()
	end
end

-- True if any unowned food is affordable (no recolouring; used while the shop is closed).
function Shop.canBuyAny(coins: number, owned): boolean
	for _, food in Config.Foods do
		if not owned[food.Id] and coins >= food.Price then
			return true
		end
	end
	return false
end

function Shop.isOpen(): boolean
	return isOpen
end

return Shop
