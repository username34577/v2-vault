-- Client helpers for the monsters. Since v0.4 each monster is a rigged R15 companion that the server
-- animates, so this module no longer draws anything. It answers "where is the mouth", "how big is it",
-- and fires onMilestone when YOUR monster crosses a look milestone (for the toast and sparkles).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local MonsterView = {}
MonsterView.onMilestone = nil -- function(model, milestone, isMine)

local lastSize = {} -- [model] = size seen last

function MonsterView.scaleOf(serverModel): number
	return serverModel:GetAttribute("Scale") or 1
end

-- Just in front of the face, in world space.
function MonsterView.mouthPosition(serverModel): Vector3?
	local head = serverModel:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return (head.CFrame * CFrame.new(0, -head.Size.Y * 0.15, -head.Size.Z * 0.55)).Position
	end
	local root = serverModel.PrimaryPart
	return root and root.Position or nil
end

-- Kept for older callers; the server now plays the catch hop.
function MonsterView.expect(_serverModel, _seconds) end
function MonsterView.gulp(_serverModel, _growth) end

local function watch(model)
	local function check()
		local size = model:GetAttribute("MonsterSize") or 1
		local before = lastSize[model]
		lastSize[model] = size
		if before == nil then
			return -- first sighting: no toasts for looks you already had
		end
		for _, milestone in Config.Monster.Milestones do
			if before < milestone.Size and size >= milestone.Size and MonsterView.onMilestone then
				MonsterView.onMilestone(model, milestone, model:GetAttribute("OwnerUserId") == Players.LocalPlayer.UserId)
			end
		end
	end
	model:GetAttributeChangedSignal("MonsterSize"):Connect(check)
	check()
end

function MonsterView.start()
	local folder = workspace:WaitForChild("Monsters")
	folder.ChildAdded:Connect(watch)
	folder.ChildRemoved:Connect(function(model)
		lastSize[model] = nil
	end)
	for _, child in folder:GetChildren() do
		task.spawn(watch, child)
	end
end

return MonsterView
