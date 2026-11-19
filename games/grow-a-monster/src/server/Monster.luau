-- Server side of a monster: an invisible, collidable hitbox ball plus attributes.
-- The server owns Size; every client draws the cute monster itself (client/MonsterView.luau),
-- so animation is smooth and costs no network traffic.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Monster = {}

local BODY_SIZE = 6 -- hitbox diameter at scale 1 (the drawn body matches it)

local folder = Instance.new("Folder")
folder.Name = "Monsters"
folder.Parent = workspace

-- groundCFrame: where the monster stands (centre of its feeding spot), facing the player's spot
function Monster.create(owner, plotIndex, groundCFrame)
	local model = Instance.new("Model")
	model.Name = `{owner.Name}_Monster`

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.one * BODY_SIZE
	body.Transparency = 1
	body.Anchored = true
	body.CanCollide = true
	body.CanQuery = true
	body.CanTouch = false
	body.CastShadow = false
	body.CFrame = groundCFrame * CFrame.new(0, BODY_SIZE / 2, 0)
	body.Parent = model
	model.PrimaryPart = body

	model:SetAttribute("PlotIndex", plotIndex)
	model:SetAttribute("OwnerUserId", owner.UserId)
	model:SetAttribute("OwnerName", owner.DisplayName)
	model:SetAttribute("Ground", groundCFrame)
	model:SetAttribute("MonsterSize", 1)
	model.Parent = folder
	return model
end

function Monster.setSize(model, size)
	local body = model.PrimaryPart
	if not body then
		return
	end
	local scale = Config.scaleForSize(size)
	local ground = model:GetAttribute("Ground")
	body.Size = Vector3.one * BODY_SIZE * scale
	body.CFrame = ground * CFrame.new(0, BODY_SIZE * scale / 2, 0)
	model:SetAttribute("MonsterSize", math.floor(size))
end

-- The food is drawn by clients; the server only waits out the flight, then applies the hit.
function Monster.throwFood(model, onHit)
	task.delay(Config.FlightTime, function()
		if model.Parent then
			onHit()
		end
	end)
end

return Monster
