-- Tiny UI kit: one look for every screen (rounded navy cards, thick dark outlines, FredokaOne,
-- palette from Config), buttons with press/hover/sound, a shine sweep, icons built from frames,
-- 3D food icons, and one responsive scale number.
-- Vault: "Responsive UI for Phone Tablet Console and PC" (44 px taps, 12 px text),
-- "Safe Areas and Insets" (ScreenInsets set on every gui), "UI Design Systems" (centre-anchored pops).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local FoodModels = require(ReplicatedStorage.Shared.FoodModels)
local Sound = require(script.Parent.Sound)

local UI = {}
local P = Config.Palette
UI.P = P
UI.Font = Enum.Font.FredokaOne

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

---------------------------------------------------------------------------
-- Responsive scale: design at a 400 px short side, clamp so taps stay >= 44 px and text >= 12 px.
---------------------------------------------------------------------------
UI.Design = { ShortSide = 400, MinScale = 0.86, MaxScale = 1.35 }
UI.scale = 1
local scaleListeners = {}

function UI.isTouchFirst(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function viewport(): Vector2
	local camera = workspace.CurrentCamera
	return if camera then camera.ViewportSize else Vector2.new(1280, 720)
end
UI.viewport = viewport

local function recompute()
	local v = viewport()
	local short = math.min(v.X, v.Y)
	UI.scale = math.clamp(short / UI.Design.ShortSide, UI.Design.MinScale, UI.Design.MaxScale)
	for _, fn in scaleListeners do
		task.spawn(fn, UI.scale, v)
	end
end

-- fn(scale, viewportSize) runs now and whenever the screen size changes
function UI.onScale(fn)
	table.insert(scaleListeners, fn)
	task.spawn(fn, UI.scale, viewport())
end

-- Gives a root widget its own UIScale that follows the responsive scale.
function UI.responsive(root: GuiObject, extra: ((number, Vector2) -> number)?)
	local s = Instance.new("UIScale")
	s.Parent = root
	UI.onScale(function(scale, v)
		s.Scale = if extra then extra(scale, v) else scale
	end)
	return s
end

do
	local function hook(camera)
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(recompute)
		recompute()
	end
	if workspace.CurrentCamera then
		hook(workspace.CurrentCamera)
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if workspace.CurrentCamera then
			hook(workspace.CurrentCamera)
		end
	end)
end

---------------------------------------------------------------------------
-- Building blocks
---------------------------------------------------------------------------
function UI.new(class: string, props, parent)
	local obj = Instance.new(class)
	if props then
		for k, v in props do
			obj[k] = v
		end
	end
	obj.Parent = parent
	return obj
end

function UI.screen(name: string, order: number, insets: Enum.ScreenInsets?)
	return UI.new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		DisplayOrder = order,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = insets or Enum.ScreenInsets.CoreUISafeInsets,
		SafeAreaCompatibility = Enum.SafeAreaCompatibility.None,
	}, playerGui)
end

function UI.corner(obj, radius: UDim?)
	return UI.new("UICorner", { CornerRadius = radius or UDim.new(0, 14) }, obj)
end

function UI.stroke(obj, thickness: number?, color: Color3?)
	return UI.new("UIStroke", {
		Thickness = thickness or 3,
		Color = color or P.Outline,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, obj)
end

-- Text with a dark outline (readable on any background). Size the box; the text fills it.
function UI.text(props, parent)
	local label = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Font = UI.Font,
		TextScaled = true,
		TextColor3 = P.TextLight,
	}, nil)
	for k, v in props do
		if k ~= "StrokeThickness" then
			label[k] = v
		end
	end
	UI.new("UIStroke", {
		Thickness = props.StrokeThickness or 2,
		Color = P.Outline,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, label)
	label.Parent = parent
	return label
end

-- Navy card with rounded corners and a thick outline.
function UI.card(props, parent)
	local frame = UI.new("Frame", { BackgroundColor3 = P.UINavy, BorderSizePixel = 0 }, nil)
	for k, v in props do
		if k ~= "Radius" then
			frame[k] = v
		end
	end
	UI.corner(frame, props.Radius)
	UI.stroke(frame, 3)
	frame.Parent = parent
	return frame
end

-- Button: centre-anchored pop on press, grow on hover, click sound. onClick(button).
function UI.button(props, parent, onClick)
	local button = UI.new("TextButton", {
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		BackgroundColor3 = P.Grass,
	}, nil)
	for k, v in props do
		if k ~= "Label" and k ~= "Radius" then
			button[k] = v
		end
	end
	UI.corner(button, props.Radius)
	UI.stroke(button, 3)
	local pop = UI.new("UIScale", { Name = "Pop" }, button)
	if props.Label then
		UI.text({
			Name = "Label",
			Text = props.Label,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, -14, 0.62, 0),
			ZIndex = 3,
		}, button)
	end
	local hovering = false
	local function to(scale, time)
		TweenService:Create(pop, TweenInfo.new(time, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = scale }):Play()
	end
	button.MouseEnter:Connect(function()
		hovering = true
		to(1.05, 0.15)
	end)
	button.MouseLeave:Connect(function()
		hovering = false
		to(1, 0.15)
	end)
	button.MouseButton1Down:Connect(function()
		pop.Scale = 0.9
	end)
	button.Activated:Connect(function()
		Sound.play("ButtonClick")
		pop.Scale = 0.9
		to(if hovering then 1.05 else 1, 0.22)
		if onClick then
			onClick(button)
		end
	end)
	button.Parent = parent
	return button
end

-- A diagonal light sweep across a button every few seconds ("shine").
function UI.shine(button: GuiObject, period: number?)
	-- A full-size rounded overlay whose gradient band slides across: it keeps the button's
	-- rounded corners (ClipsDescendants would not follow UICorner).
	local overlay = UI.new("Frame", {
		Name = "Shine",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Active = false,
		ZIndex = 2,
	}, button)
	local buttonCorner = button:FindFirstChildOfClass("UICorner")
	UI.corner(overlay, if buttonCorner then buttonCorner.CornerRadius else nil)
	local gradient = UI.new("UIGradient", {
		Rotation = 20,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.44, 1),
			NumberSequenceKeypoint.new(0.5, 0.1),
			NumberSequenceKeypoint.new(0.56, 1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Offset = Vector2.new(-1, 0),
	}, overlay)
	task.spawn(function()
		while overlay.Parent do
			gradient.Offset = Vector2.new(-1, 0)
			if overlay.Visible then
				TweenService:Create(gradient, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
					Offset = Vector2.new(1, 0),
				}):Play()
			end
			task.wait(period or 2.4)
		end
	end)
	return overlay
end

-- Coin icon: gold disc with a lighter inner disc.
function UI.coinIcon(parent, size: number)
	local coin = UI.new("Frame", {
		Name = "CoinIcon",
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = P.Sunny,
	}, parent)
	UI.corner(coin, UDim.new(0.5, 0))
	UI.stroke(coin, 2.5)
	local inner = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.58, 0.58),
		BackgroundColor3 = P.Sunny:Lerp(P.Tangerine, 0.45),
	}, coin)
	UI.corner(inner, UDim.new(0.5, 0))
	UI.new("Frame", {
		Position = UDim2.fromScale(0.2, 0.14),
		Size = UDim2.fromScale(0.22, 0.16),
		BackgroundColor3 = P.TextLight,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Rotation = -30,
	}, coin)
	return coin
end

-- Monster face icon: round body with two big eyes.
function UI.monsterIcon(parent, size: number, color: Color3?)
	local face = UI.new("Frame", {
		Name = "MonsterIcon",
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = color or P.Bubblegum,
	}, parent)
	UI.corner(face, UDim.new(0.5, 0))
	UI.stroke(face, 2.5)
	for _, x in { 0.3, 0.68 } do
		local eye = UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, 0.4),
			Size = UDim2.fromScale(0.32, 0.36),
			BackgroundColor3 = Color3.new(1, 1, 1),
		}, face)
		UI.corner(eye, UDim.new(0.5, 0))
		local pupil = UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.58, 0.58),
			Size = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(12, 12, 18),
		}, eye)
		UI.corner(pupil, UDim.new(0.5, 0))
	end
	local mouth = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.76),
		Size = UDim2.fromScale(0.4, 0.14),
		BackgroundColor3 = Config.Monster.MouthColor,
	}, face)
	UI.corner(mouth, UDim.new(0.5, 0))
	return face
end

-- 3D food icon. Returns the ViewportFrame and a setter to change the food.
local spinning = {} -- [model] = viewport
function UI.foodIcon(parent, foodId: string, props)
	local vp = UI.new("ViewportFrame", {
		Name = "FoodIcon",
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(190, 190, 205),
		LightColor = Color3.fromRGB(255, 244, 228),
		LightDirection = Vector3.new(-0.6, -1, 0.5),
	}, nil)
	for k, v in props or {} do
		vp[k] = v
	end
	local camera = UI.new("Camera", { FieldOfView = 34 }, vp)
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 2.2, -5.6), Vector3.new(0, 0.15, 0))
	vp.CurrentCamera = camera
	local current
	local function set(id)
		if current then
			spinning[current] = nil
			current:Destroy()
		end
		current = FoodModels.build(id)
		current:PivotTo(CFrame.Angles(0, -0.5, 0))
		current.Parent = vp
		spinning[current] = vp
	end
	set(foodId)
	vp.Parent = parent
	return vp, set
end

-- Slow turntable for every visible food icon (one loop for all of them).
task.spawn(function()
	local angle = 0
	while true do
		local dt = task.wait(1 / 30)
		angle += dt * 0.9
		for model, vp in spinning do
			if model.Parent and vp.Visible and vp:FindFirstAncestorOfClass("ScreenGui") then
				local gui = vp:FindFirstAncestorOfClass("ScreenGui")
				if gui.Enabled then
					model:PivotTo(CFrame.Angles(0, angle, 0))
				end
			end
		end
	end
end)

-- Number tween for counters: calls set(text) while counting from -> to.
function UI.countUp(from: number, to: number, duration: number, set: (number) -> ())
	local start = os.clock()
	task.spawn(function()
		while true do
			local t = math.min(1, (os.clock() - start) / duration)
			local eased = 1 - (1 - t) ^ 3
			set(from + (to - from) * eased)
			if t >= 1 then
				break
			end
			task.wait()
		end
	end)
end

-- Pop a GuiObject that has a "Pop" UIScale (or create one).
function UI.pop(obj: GuiObject, amount: number?)
	local pop = obj:FindFirstChild("Pop")
	if not pop then
		pop = UI.new("UIScale", { Name = "Pop" }, obj)
	end
	pop.Scale = amount or 1.18
	TweenService:Create(pop, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

return UI
