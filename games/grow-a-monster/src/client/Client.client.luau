-- Grow a Monster: client entry (v0.4 Snack Grove). Wires input, server attributes and remotes to the
-- HUD, guide line and effects. The client only ASKS the server to "throw" (feed the top carried snack);
-- it never decides snacks, coins, size or objectives.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ThrowRemote = Remotes:WaitForChild("Throw")
local NotifyRemote = Remotes:WaitForChild("Notify")
local FxRemote = Remotes:WaitForChild("Fx")

local Sound = require(script.Parent.Sound)
local Decor = require(script.Parent.Decor)
local MonsterView = require(script.Parent.MonsterView)
local FoodFlight = require(script.Parent.FoodFlight)
local UI = require(script.Parent.UI)
local Hud = require(script.Parent.Hud)
local Feel = require(script.Parent.Feel)
local Guide = require(script.Parent.Guide)

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
	return (root.Position - body.Position).Magnitude > Config.Companion.FeedRange + body.Size.X
end

---------------------------------------------------------------------------
-- Feeding
---------------------------------------------------------------------------
local lastSent = 0
local lastHint = 0
local function throw()
	local now = os.clock()
	if now - lastSent < Config.ThrowCooldown then
		return -- the server enforces this too; this just avoids wasted sends
	end
	if (player:GetAttribute("Carrying") or 0) == 0 then
		if now - lastHint > 2.5 then
			lastHint = now
			Hud.toast("Your hands are empty! Shake snack plants in the Snack Grove.", "warn")
		end
		return
	end
	local monster = myMonster()
	if not monster then
		return
	end
	if isTooFar(monster) then
		Hud.toast("Walk back to your monster to feed it!", "warn")
		return
	end
	lastSent = now
	ThrowRemote:FireServer()
	Hud.pressThrow()
	Sound.play("Throw")
end

---------------------------------------------------------------------------
-- HUD
---------------------------------------------------------------------------
Hud.build({
	onThrow = throw,
	onShop = function() end,
})
Hud.setShopVisible(false) -- v0.4: upgrades are sold at the Backpack Stand in the world
Feel.start(Hud)
Guide.start(myMonster)

local function refreshAll()
	local coins = player:GetAttribute("Coins") or 0
	local size = player:GetAttribute("Size") or 1
	Hud.setStats(coins, player:GetAttribute("Income") or 0, size)
	Hud.setObjective(player:GetAttribute("ObjText") or "", player:GetAttribute("ObjProgress") or 0, player:GetAttribute("ObjGoal") or 1)
	local top = player:GetAttribute("CarryTop")
	local snack = top and Config.Snacks[top]
	Hud.setCarry(player:GetAttribute("Carrying") or 0, player:GetAttribute("CarryCap") or 3, snack and snack.Model)
end

local queued = false
player.AttributeChanged:Connect(function()
	if not queued then
		queued = true
		task.defer(function()
			queued = false
			refreshAll()
		end)
	end
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

-- "Too far" hint only matters when you have something to feed.
task.spawn(function()
	while true do
		task.wait(0.25)
		Hud.setFar((player:GetAttribute("Carrying") or 0) > 0 and isTooFar(myMonster()))
	end
end)

NotifyRemote.OnClientEvent:Connect(function(text)
	if type(text) ~= "string" then
		return
	end
	local kind = if string.find(text, "^Bought") or string.find(text, "^Welcome") or string.find(text, "^Your plot") then "good"
		elseif string.find(text, "^You need") or string.find(text, "^Hands full") or string.find(text, "^Get closer") then "warn"
		else "info"
	Hud.toast(text, kind)
end)

---------------------------------------------------------------------------
-- Camera framing at spawn (the server tells us when we've been placed on our plot)
---------------------------------------------------------------------------
local function frameMonster()
	local monster = myMonster()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local body = monster and monster.PrimaryPart
	if not root or not body then
		return
	end
	local target = body.Position + Vector3.new(0, 1.5 * (monster:GetAttribute("Scale") or 1), 0)
	local flat = (root.Position - target) * Vector3.new(1, 0, 1)
	if flat.Magnitude < 1 then
		return
	end
	local camPos = root.Position + flat.Unit * 12 + Vector3.new(0, 5, 0)
	workspace.CurrentCamera.CFrame = CFrame.lookAt(camPos, target)
end

local function onCharacter(character)
	-- Raise the camera's focus above the head so your character doesn't cover the monster.
	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		humanoid.CameraOffset = Config.CameraOffset
	end
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then
	task.spawn(onCharacter, player.Character)
end

---------------------------------------------------------------------------
-- Input: FEED button, click/tap the world, F, gamepad R2
---------------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return -- clicked a button or typing in chat
	end
	if input.KeyCode == Enum.KeyCode.F
		or input.UserInputType == Enum.UserInputType.MouseButton1
		or input.KeyCode == Enum.KeyCode.ButtonR2
	then
		if (player:GetAttribute("Carrying") or 0) > 0 or input.KeyCode ~= Enum.KeyCode.Unknown then
			throw()
		end
	end
end)

-- Tapping the world on a phone feeds too (taps only, so walking with the thumbstick doesn't).
UserInputService.TouchTapInWorld:Connect(function(_, processedByUI)
	if not processedByUI and (player:GetAttribute("Carrying") or 0) > 0 then
		throw()
	end
end)

---------------------------------------------------------------------------
-- Server cues
---------------------------------------------------------------------------
local fadeGui = UI.screen("Fade", 50, Enum.ScreenInsets.None)
local fade = UI.new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Config.Palette.Cream,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Active = false,
}, fadeGui)

local function flash(color: Color3, from: number)
	fade.BackgroundColor3 = color
	fade.BackgroundTransparency = from
	TweenService:Create(fade, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
end

MonsterView.onMilestone = function(model, milestone, isMine)
	if isMine then
		Feel.milestone(model)
		Sound.play("Milestone")
		Hud.toast(`New look unlocked: {milestone.Name}!`, "good")
	end
end

FxRemote.OnClientEvent:Connect(function(kind, a, b, c)
	if kind == "Throw" and typeof(a) == "Instance" then
		FoodFlight.launch(a, b, c)
	elseif kind == "Eat" and typeof(a) == "Instance" then
		local growth = tonumber(c) or 1
		Feel.ate(a, b, growth, a:GetAttribute("OwnerUserId") == player.UserId)
	elseif kind == "Picked" then
		Sound.play("Shake")
		UI.pop(Hud.throwButton(), 1.15)
	elseif kind == "Caught" then
		Sound.play("Caught")
		flash(Config.Palette.Coral, 0.35)
		Hud.toast("BONK! The Gardener caught you and took your snacks. Hide in the tall grass!", "warn")
	elseif kind == "Objective" then
		Sound.play("Milestone")
		Feel.purchased()
		Hud.toast(`Done! +{tonumber(b) or 0} coins`, "good")
	elseif kind == "Bought" then
		Sound.play("Purchase")
		Feel.purchased()
	elseif kind == "Placed" then
		task.delay(0.15, frameMonster)
	elseif kind == "Fell" then
		Sound.play("Whoosh")
		task.delay(0.1, frameMonster)
		flash(Config.Palette.Cream, 0)
	end
end)
