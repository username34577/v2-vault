-- First 30 seconds: no tutorial wall. New players see a bouncing arrow over their monster,
-- a "Tap to feed your monster!" pill (wording matches the device), and on phones an arrow at
-- the THROW button. It fades after a few bites. Later, the first time they can afford new food,
-- an arrow points at SHOP for a few seconds.
-- Vault: "Onboarding Accessibility and Cross-Device Prompts" (prompt per device, inside the safe area).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local UI = require(script.Parent.UI)

local P = Config.Palette
local T = Config.Tutorial
local Tutorial = {}

local player = Players.LocalPlayer
local hud
local active = false
local bites = 0
local pieces = {} -- everything to remove when the hint ends
local shopNudged = false
local wasNewPlayer = false

-- Arrow made of frames (no image assets). Points down; rotate the holder to aim it.
local function arrow(parent, size: number)
	local holder = UI.new("Frame", {
		Name = "Arrow",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(size, size * 1.25),
	}, parent)
	local shaft = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromScale(0.4, 0.6),
		BackgroundColor3 = P.Sunny,
	}, holder)
	UI.corner(shaft, UDim.new(0.3, 0))
	UI.stroke(shaft, 3)
	local head = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.62),
		Size = UDim2.fromScale(0.62, 0.5),
		Rotation = 45,
		BackgroundColor3 = P.Sunny,
	}, holder)
	UI.corner(head, UDim.new(0.15, 0))
	UI.stroke(head, 3)
	-- cover the seam so the arrow reads as one shape
	UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.fromScale(0.32, 0.36),
		BackgroundColor3 = P.Sunny,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, holder)
	return holder
end

local function bounce(obj: GuiObject, property: string, a, b, period: number)
	task.spawn(function()
		while obj.Parent do
			TweenService:Create(obj, TweenInfo.new(period / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { [property] = b }):Play()
			task.wait(period / 2)
			if not obj.Parent then
				break
			end
			TweenService:Create(obj, TweenInfo.new(period / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { [property] = a }):Play()
			task.wait(period / 2)
		end
	end)
end

local function hintText(): string
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "Tap to feed your monster!"
	elseif UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
		return "Press R2 to feed your monster!"
	end
	return "Click or press F to feed your monster!"
end

local function toLocal(gui, absolute: Vector2): Vector2
	return absolute - gui.AbsolutePosition
end

local function show(monster)
	active = true
	local gui = hud.gui()

	-- World arrow + "Feed me!" over the monster
	local body = monster.PrimaryPart
	if body then
		local board = Instance.new("BillboardGui")
		board.Name = "FeedMe"
		board.Adornee = body
		board.Size = UDim2.fromOffset(150, 120)
		board.AlwaysOnTop = true
		board.LightInfluence = 0
		board.StudsOffsetWorldSpace = Vector3.new(0, body.Size.Y / 2 + 5, 0)
		board.Parent = player:WaitForChild("PlayerGui")
		local bubble = UI.card({
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.fromOffset(130, 40),
			BackgroundColor3 = P.Cream,
			Radius = UDim.new(0.5, 0),
		}, board)
		UI.text({ Size = UDim2.new(1, -16, 1, -10), Position = UDim2.fromOffset(8, 5), Text = "Feed me!", TextColor3 = P.Outline, StrokeThickness = 0 }, bubble)
		local a = arrow(board, 46)
		a.Position = UDim2.new(0.5, 0, 0, 72)
		bounce(a, "Position", UDim2.new(0.5, 0, 0, 68), UDim2.new(0.5, 0, 0, 84), 0.7)
		table.insert(pieces, board)
	end

	-- Hint pill near the bottom centre (above the thumbstick zone, inside the safe area)
	local pill = UI.new("Frame", {
		Name = "Hint",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.7),
		Size = UDim2.fromOffset(340, 52),
	}, gui)
	UI.responsive(pill)
	local card = UI.card({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = P.Sunny,
		Radius = UDim.new(0.5, 0),
	}, pill)
	UI.text({ Size = UDim2.new(1, -24, 1, -14), Position = UDim2.fromOffset(12, 7), Text = hintText(), TextColor3 = P.Outline, StrokeThickness = 0 }, card)
	local pop = UI.new("UIScale", { Name = "Pop" }, card)
	bounce(pop, "Scale", 1, 1.06, 0.9)
	table.insert(pieces, pill)

	-- On phones: an arrow pointing at the THROW button
	if UserInputService.TouchEnabled then
		local a = arrow(gui, 46)
		a.Rotation = -90 -- point right
		a.ZIndex = 10
		local function place()
			local c = toLocal(gui, hud.throwCenter())
			local offset = hud.throwButton().AbsoluteSize.X / 2 + 44
			return UDim2.fromOffset(c.X - offset, c.Y), UDim2.fromOffset(c.X - offset - 16, c.Y)
		end
		local near, far = place()
		a.Position = near
		bounce(a, "Position", near, far, 0.6)
		table.insert(pieces, a)
	end
end

local function hide()
	if not active then
		return
	end
	active = false
	for _, piece in pieces do
		if piece:IsA("GuiObject") then
			TweenService:Create(piece, TweenInfo.new(0.25), { Size = UDim2.fromOffset(0, 0) }):Play()
		end
		task.delay(0.25, function()
			piece:Destroy()
		end)
	end
	table.clear(pieces)
	hud.toast("Nice! Keep feeding to grow!", "good")
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------
function Tutorial.start(hudModule, findMonster)
	hud = hudModule
	task.spawn(function()
		-- wait for the save to load and the monster to exist
		local monster
		repeat
			task.wait(0.3)
			monster = findMonster()
		until monster and player:GetAttribute("Size") ~= nil
		if (player:GetAttribute("Size") or 1) <= T.MaxStartSize then
			wasNewPlayer = true
			show(monster)
		end
	end)
end

-- Call when MY monster eats.
function Tutorial.onBite()
	bites += 1
	if active and bites >= T.ThrowsToHide then
		hide()
	end
end

-- Call when coins change; points at SHOP once, the first time new food is affordable.
function Tutorial.onCanBuy(canBuy: boolean)
	if shopNudged or not canBuy or not wasNewPlayer or active then
		return
	end
	shopNudged = true
	local gui = hud.gui()
	local button = hud.shopButton()
	local a = arrow(gui, 42)
	a.Rotation = 90 -- point left
	a.ZIndex = 10
	local c = toLocal(gui, button.AbsolutePosition + button.AbsoluteSize / 2)
	local x = c.X + button.AbsoluteSize.X / 2 + 40
	a.Position = UDim2.fromOffset(x, c.Y)
	bounce(a, "Position", UDim2.fromOffset(x, c.Y), UDim2.fromOffset(x + 14, c.Y), 0.6)
	hud.toast("You can buy better food! Open the SHOP", "good")
	task.delay(T.ShopNudgeSeconds, function()
		a:Destroy()
	end)
end

function Tutorial.shopOpened()
	shopNudged = true
end

return Tutorial
