-- Game feel: floating "+X" numbers, crumbs, coins flying to the counter, gulp/coin sounds,
-- a small screen bump on big foods, confetti on purchases and sparkles on milestones.
-- Numbers come from the server's Eat cue (never predicted). Screen effects only for your own monster.
-- Vault: "Game Feel and Juice" (every reward: motion, number, payoff pop),
-- "Juice on a Budget - Mobile and Low-End" (pools, bounded bursts), "Camera Shake and Camera FX".
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local UI = require(script.Parent.UI)
local Sound = require(script.Parent.Sound)
local MonsterView = require(script.Parent.MonsterView)

local P = Config.Palette
local F = Config.Feel
local Feel = {}

local hud -- the Hud module (for counter positions)
local anchors = Instance.new("Folder")
anchors.Name = "FeelFx"

---------------------------------------------------------------------------
-- Particle bursts from one invisible anchor part (one emitter per kind)
---------------------------------------------------------------------------
local anchor = Instance.new("Part")
anchor.Name = "BurstAnchor"
anchor.Anchored = true
anchor.CanCollide = false
anchor.CanQuery = false
anchor.CanTouch = false
anchor.Transparency = 1
anchor.Size = Vector3.one * 0.2
anchor.Parent = anchors

local function emitter(props)
	local e = Instance.new("ParticleEmitter")
	e.Rate = 0
	e.LightEmission = 0.3
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, -40, 0)
	for k, v in props do
		e[k] = v
	end
	e.Parent = anchor
	return e
end

local crumbs = {}
for _, food in Config.Foods do
	crumbs[food.Id] = emitter({
		Color = ColorSequence.new(food.Color, food.Color:Lerp(P.Cream, 0.4)),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0) }),
		Lifetime = NumberRange.new(0.35, 0.65),
		Speed = NumberRange.new(10, 18),
		Drag = 3,
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.6, 0.1), NumberSequenceKeypoint.new(1, 1) }),
	})
end
-- one big soft flash at the mouth: the "payoff" frame of the bite
local flash = emitter({
	Color = ColorSequence.new(P.Cream),
	LightEmission = 1,
	Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5), NumberSequenceKeypoint.new(1, 5) }),
	Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1) }),
	Lifetime = NumberRange.new(0.16, 0.16),
	Speed = NumberRange.new(0, 0),
	Acceleration = Vector3.zero,
})
local confetti = emitter({
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, P.Bubblegum),
		ColorSequenceKeypoint.new(0.33, P.Sunny),
		ColorSequenceKeypoint.new(0.66, P.Mint),
		ColorSequenceKeypoint.new(1, P.Sky),
	}),
	Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0.2) }),
	Lifetime = NumberRange.new(0.9, 1.4),
	Speed = NumberRange.new(16, 26),
	Acceleration = Vector3.new(0, -30, 0),
	Rotation = NumberRange.new(0, 360),
	RotSpeed = NumberRange.new(-200, 200),
	SpreadAngle = Vector2.new(50, 50),
	EmissionDirection = Enum.NormalId.Top,
})
local sparkles = emitter({
	Color = ColorSequence.new(P.Sunny, P.Bubblegum),
	LightEmission = 1,
	Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) }),
	Lifetime = NumberRange.new(0.6, 1.1),
	Speed = NumberRange.new(14, 28),
	Acceleration = Vector3.zero,
})

local function burst(e, position: Vector3, count: number)
	anchor.CFrame = CFrame.new(position)
	e:Emit(count)
end

---------------------------------------------------------------------------
-- Floating "+X" numbers (pooled billboards)
---------------------------------------------------------------------------
local pool = {}
local function getNumber()
	for _, item in pool do
		if not item.Busy then
			return item
		end
	end
	if #pool >= 12 then
		return nil -- budget: never more than 12 numbers on screen
	end
	local part = anchor:Clone()
	part.Name = "NumberAnchor"
	part:ClearAllChildren()
	part.Parent = anchors
	local gui = Instance.new("BillboardGui")
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Size = UDim2.fromOffset(170, 64)
	gui.Adornee = part
	gui.Enabled = false
	gui.Parent = part
	local label = UI.text({ Size = UDim2.fromScale(1, 1), TextColor3 = P.Sunny, StrokeThickness = 3 }, gui)
	local pop = Instance.new("UIScale")
	pop.Parent = label
	local item = { Part = part, Gui = gui, Label = label, Pop = pop, Busy = false }
	table.insert(pool, item)
	return item
end

local function floatNumber(position: Vector3, text: string, color: Color3, big: number)
	local item = getNumber()
	if not item then
		return
	end
	item.Busy = true
	item.Part.CFrame = CFrame.new(position + Vector3.new(math.random() * 2 - 1, 0, 0))
	item.Gui.Size = UDim2.fromOffset(150 * big, 58 * big)
	item.Gui.StudsOffsetWorldSpace = Vector3.zero
	item.Label.Text = text
	item.Label.TextColor3 = color
	item.Label.TextTransparency = 0
	local stroke = item.Label:FindFirstChildOfClass("UIStroke")
	stroke.Transparency = 0
	item.Pop.Scale = 0.3
	item.Gui.Enabled = true
	TweenService:Create(item.Pop, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(item.Gui, TweenInfo.new(F.NumberTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffsetWorldSpace = Vector3.new(0, F.NumberRise * (0.8 + big * 0.4), 0),
	}):Play()
	task.delay(F.NumberTime * 0.55, function()
		local fade = TweenInfo.new(F.NumberTime * 0.45)
		TweenService:Create(item.Label, fade, { TextTransparency = 1 }):Play()
		TweenService:Create(stroke, fade, { Transparency = 1 }):Play()
	end)
	task.delay(F.NumberTime + 0.05, function()
		item.Gui.Enabled = false
		item.Busy = false
	end)
end

---------------------------------------------------------------------------
-- Coins flying from the monster to the coin counter
---------------------------------------------------------------------------
local function flyCoins(fromWorld: Vector3, count: number)
	local gui = hud.gui()
	local camera = workspace.CurrentCamera
	if not gui or not camera then
		return
	end
	local screen, onScreen = camera:WorldToScreenPoint(fromWorld)
	if not onScreen then
		Sound.play("Coin")
		return
	end
	local origin = gui.AbsolutePosition
	local start = Vector2.new(screen.X, screen.Y) - origin
	local target = hud.coinTarget() - origin
	for i = 1, count do
		task.delay((i - 1) * 0.06, function()
			local coin = UI.coinIcon(gui, 26)
			coin.AnchorPoint = Vector2.new(0.5, 0.5)
			coin.ZIndex = 20
			local jitter = Vector2.new(math.random(-30, 30), math.random(-30, 10))
			coin.Position = UDim2.fromOffset(start.X + jitter.X, start.Y + jitter.Y)
			local tween = TweenService:Create(coin, TweenInfo.new(F.CoinFlyTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.fromOffset(target.X, target.Y),
				Size = UDim2.fromOffset(18, 18),
			})
			tween:Play()
			tween.Completed:Once(function()
				coin:Destroy()
				Sound.play("Coin", 1 + i * 0.04)
			end)
		end)
	end
end

---------------------------------------------------------------------------
-- Screen bump (field-of-view punch), only for your own big foods
---------------------------------------------------------------------------
local baseFov
local function bump(growth: number)
	if not F.ScreenBump or growth < F.BumpMinGrowth then
		return
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	baseFov = baseFov or camera.FieldOfView
	local amount = math.min(F.BumpMaxFov, F.BumpFov * (1 + math.log10(growth / F.BumpMinGrowth)))
	camera.FieldOfView = baseFov - amount
	TweenService:Create(camera, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { FieldOfView = baseFov }):Play()
end

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------
function Feel.start(hudModule)
	hud = hudModule
	anchors.Parent = workspace
end

-- A monster ate. mine = it's the local player's monster.
function Feel.ate(serverModel, foodId: string, growth: number, mine: boolean)
	local mouth = MonsterView.mouthPosition(serverModel)
	if not mouth then
		return
	end
	local scale = MonsterView.scaleOf(serverModel)
	local emitterForFood = crumbs[foodId] or crumbs[Config.StartingFood]
	burst(emitterForFood, mouth, math.min(F.CrumbCount + math.floor(math.log10(math.max(growth, 1)) * 4), 24))
	flash.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5 * scale), NumberSequenceKeypoint.new(1, 5 * scale) })
	burst(flash, mouth, 1)
	if not mine then
		return
	end
	local big = math.clamp(0.8 + math.log10(math.max(growth, 1)) * 0.35, 0.8, 1.8)
	floatNumber(mouth + Vector3.new(0, 1.5 * scale, 0), `+{Format.short(growth)}`, if growth >= F.BumpMinGrowth then P.Bubblegum else P.Sunny, big)
	Sound.play("Gulp", math.clamp(1.12 - math.log10(math.max(growth, 1)) * 0.08, 0.8, 1.15))
	flyCoins(mouth, math.clamp(1 + math.floor(math.log10(math.max(growth, 1)) * 2), 1, F.CoinFlyMax))
	bump(growth)
end

-- Bought something: confetti from the player.
function Feel.purchased()
	local character = game:GetService("Players").LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		burst(confetti, root.Position + Vector3.new(0, 2, 0), 40)
	end
end

-- New look unlocked: sparkles round the monster.
function Feel.milestone(serverModel)
	local mouth = MonsterView.mouthPosition(serverModel)
	if mouth then
		burst(sparkles, mouth + Vector3.new(0, 2 * MonsterView.scaleOf(serverModel), 0), 36)
	end
end

return Feel
