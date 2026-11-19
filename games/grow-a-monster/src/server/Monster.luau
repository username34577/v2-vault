-- Builds a simple monster out of parts and resizes it. No uploaded assets needed.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Monster = {}

local BODY_SIZE = 6

local BODY_COLORS = {
	Color3.fromRGB(110, 200, 90),
	Color3.fromRGB(90, 160, 230),
	Color3.fromRGB(230, 120, 70),
	Color3.fromRGB(190, 110, 220),
	Color3.fromRGB(240, 200, 70),
	Color3.fromRGB(80, 210, 190),
	Color3.fromRGB(235, 100, 140),
	Color3.fromRGB(150, 150, 160),
}

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		p[k] = v
	end
	return p
end

-- groundCFrame: where the monster stands (center of the plot, at ground height)
function Monster.create(owner, plotIndex, groundCFrame)
	local model = Instance.new("Model")
	model.Name = `{owner.Name}_Monster`

	local color = BODY_COLORS[((plotIndex - 1) % #BODY_COLORS) + 1]
	local body = part({
		Name = "Body",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * BODY_SIZE,
		Color = color,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = true,
		CanQuery = true,
		CFrame = CFrame.new(),
	})
	body.Parent = model
	model.PrimaryPart = body

	-- Face points along the body's -Z (its LookVector)
	for _, side in { -1, 1 } do
		local eye = part({
			Name = "Eye",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 1.6,
			Color = Color3.new(1, 1, 1),
			Material = Enum.Material.SmoothPlastic,
			CFrame = CFrame.new(side * 1.2, 1, -2.4),
		})
		eye.Parent = model
		local pupil = part({
			Name = "Pupil",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.8,
			Color = Color3.new(0.05, 0.05, 0.05),
			Material = Enum.Material.SmoothPlastic,
			CFrame = CFrame.new(side * 1.2, 1, -3.1),
		})
		pupil.Parent = model
	end
	local mouth = part({
		Name = "Mouth",
		Size = Vector3.new(2.4, 0.5, 0.4),
		Color = Color3.fromRGB(60, 20, 20),
		Material = Enum.Material.SmoothPlastic,
		CFrame = CFrame.new(0, -0.8, -2.85),
	})
	mouth.Parent = model

	-- Name tag
	local tag = Instance.new("BillboardGui")
	tag.Name = "Tag"
	tag.Size = UDim2.fromOffset(220, 60)
	tag.StudsOffsetWorldSpace = Vector3.new(0, BODY_SIZE / 2 + 2, 0)
	tag.AlwaysOnTop = true
	tag.MaxDistance = 250
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.Text = owner.DisplayName
	label.Parent = tag
	tag.Adornee = body
	tag.Parent = body

	model:SetAttribute("PlotIndex", plotIndex)
	model:SetAttribute("OwnerUserId", owner.UserId)
	model:SetAttribute("Ground", groundCFrame)
	model.Parent = workspace
	return model
end

local function placeOnGround(model, scale)
	local ground = model:GetAttribute("Ground")
	model:PivotTo(ground * CFrame.new(0, BODY_SIZE * scale / 2, 0))
end

function Monster.setSize(model, size, ownerName, animate)
	local target = Config.scaleForSize(size)
	local tagLabel = model.PrimaryPart and model.PrimaryPart:FindFirstChild("Tag")
	if tagLabel then
		tagLabel.Label.Text = `{ownerName} · Size {math.floor(size)}`
	end
	if animate then
		-- quick "gulp" squash: overshoot then settle
		model:ScaleTo(target * 1.08)
		placeOnGround(model, target * 1.08)
		task.delay(0.08, function()
			if model.Parent then
				model:ScaleTo(target)
				placeOnGround(model, target)
			end
		end)
	else
		model:ScaleTo(target)
		placeOnGround(model, target)
	end
end

-- Food that arcs from a start point into the monster's mouth, then calls onHit.
local flying = {}
function Monster.throwFood(model, fromPosition, foodColor, onHit)
	local body = model.PrimaryPart
	if not body then
		return
	end
	local food = part({
		Name = "Food",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 1.5,
		Color = foodColor,
		Material = Enum.Material.SmoothPlastic,
		CastShadow = false,
		Position = fromPosition,
	})
	food.Parent = workspace
	table.insert(flying, {
		Part = food,
		From = fromPosition,
		Model = model,
		Started = os.clock(),
		OnHit = onHit,
	})
end

game:GetService("RunService").Heartbeat:Connect(function()
	local now = os.clock()
	for i = #flying, 1, -1 do
		local f = flying[i]
		local body = f.Model.PrimaryPart
		local t = (now - f.Started) / Config.FlightTime
		if not body or not f.Model.Parent then
			f.Part:Destroy()
			table.remove(flying, i)
		elseif t >= 1 then
			f.Part:Destroy()
			table.remove(flying, i)
			task.spawn(f.OnHit)
		else
			local to = body.Position
			local height = math.max(8, (to - f.From).Magnitude * 0.35)
			local pos = f.From:Lerp(to, t) + Vector3.new(0, math.sin(t * math.pi) * height, 0)
			f.Part.Position = pos
		end
	end
end)

-- Little burst of particles at the monster when it eats.
function Monster.eatEffect(model, color)
	local body = model.PrimaryPart
	if not body then
		return
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new(0.6, 0)
	emitter.Lifetime = NumberRange.new(0.3, 0.6)
	emitter.Speed = NumberRange.new(8, 14)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Rate = 0
	emitter.Parent = body
	emitter:Emit(12)
	task.delay(1, function()
		emitter:Destroy()
	end)
end

return Monster
