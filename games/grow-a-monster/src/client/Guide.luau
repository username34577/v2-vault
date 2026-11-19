-- A glowing guide line from you to where you should go next:
--   empty hands         -> the Snack Grove gate (inside: the nearest ripe plant)
--   hands full / inside -> back out through the gate
--   carrying, outside   -> your monster
-- Shown during the objectives, and whenever you're carrying snacks. Purely visual, client-only.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local G = Config.Grove
local P = Config.Palette
local player = Players.LocalPlayer

local Guide = {}

local groveCF
do
	local dir = Vector3.new(math.cos(G.Angle), 0, math.sin(G.Angle))
	local center = dir * G.Distance
	groveCF = CFrame.lookAt(center, center - dir)
end

local function insideGrove(pos: Vector3): boolean
	local l = groveCF:PointToObjectSpace(pos)
	return (l.X * l.X + l.Z * l.Z) < (G.Radius - 3) ^ 2 and l.Y > -20
end

local gatePos = (groveCF * CFrame.new(0, 2, -G.Radius - 2)).Position

local function nearestRipePlant(from: Vector3, wantKind: string?)
	local grove = workspace:FindFirstChild("SnackGrove")
	if not grove then
		return nil
	end
	local best, bestD
	for _, m in grove:GetChildren() do
		local anchor = m:IsA("Model") and m:FindFirstChild("PromptAnchor")
		local prompt = anchor and anchor:FindFirstChildOfClass("ProximityPrompt")
		if prompt and prompt.Enabled then
			local d = (anchor.Position - from).Magnitude
			if wantKind and string.find(m.Name, wantKind, 1, true) then
				d -= 1000 -- objective wants this one
			end
			if not bestD or d < bestD then
				best, bestD = anchor.Position, d
			end
		end
	end
	return best
end

function Guide.start(myMonster)
	local target = Instance.new("Part")
	target.Name = "GuideTarget"
	target.Anchored = true
	target.CanCollide = false
	target.CanQuery = false
	target.CanTouch = false
	target.Transparency = 1
	target.Size = Vector3.one
	target.Parent = workspace
	local a1 = Instance.new("Attachment")
	a1.Parent = target

	local beam = Instance.new("Beam")
	beam.Attachment1 = a1
	beam.Color = ColorSequence.new(P.Sunny, P.Bubblegum)
	beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.85), NumberSequenceKeypoint.new(0.15, 0.25), NumberSequenceKeypoint.new(1, 0.25) })
	beam.Width0 = 0.9
	beam.Width1 = 0.9
	beam.FaceCamera = true
	beam.LightEmission = 0.4
	beam.Segments = 20
	beam.CurveSize0 = 0
	beam.Parent = target

	-- bouncing marker over the target
	local marker = Instance.new("BillboardGui")
	marker.Size = UDim2.fromOffset(46, 46)
	marker.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
	marker.AlwaysOnTop = true
	marker.LightInfluence = 0
	marker.Parent = target
	local arrow = Instance.new("TextLabel")
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.fromScale(1, 1)
	arrow.Font = Enum.Font.FredokaOne
	arrow.TextScaled = true
	arrow.TextColor3 = P.Sunny
	arrow.Text = "V"
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = P.Outline
	stroke.Parent = arrow
	arrow.Parent = marker

	local a0
	RunService.Heartbeat:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			beam.Enabled = false
			marker.Enabled = false
			return
		end
		if not a0 or a0.Parent ~= root then
			a0 = Instance.new("Attachment")
			a0.Name = "GuideFrom"
			a0.Position = Vector3.new(0, -1.5, 0)
			a0.Parent = root
			beam.Attachment0 = a0
		end
		local carrying = player:GetAttribute("Carrying") or 0
		local cap = player:GetAttribute("CarryCap") or 3
		local learning = (player:GetAttribute("ObjIndex") or 1) <= #Config.Objectives
		local objType = player:GetAttribute("ObjType")
		local pos = root.Position
		local goal
		if objType == "Backpack" and carrying == 0 and not insideGrove(pos) then
			local grove = workspace:FindFirstChild("SnackGrove")
			for _, d in (grove and grove:GetDescendants() or {}) do
				if d:IsA("ProximityPrompt") and d.ObjectText == "Backpack Stand" then
					goal = d.Parent.Position
					break
				end
			end
		elseif insideGrove(pos) then
			if carrying >= cap then
				goal = gatePos
			else
				goal = nearestRipePlant(pos, if objType == "Golden" then "GoldenMelon" else nil) or gatePos
			end
		elseif carrying > 0 then
			local monster = myMonster()
			goal = monster and monster.PrimaryPart and monster.PrimaryPart.Position
		elseif learning then
			goal = gatePos
		end
		local show = goal ~= nil and (learning or carrying > 0) and (goal - pos).Magnitude > 9
		beam.Enabled = show
		marker.Enabled = show
		if goal then
			target.Position = goal
			marker.StudsOffsetWorldSpace = Vector3.new(0, 7 + math.abs(math.sin(os.clock() * 4)) * 1.5, 0)
		end
	end)
end

return Guide
