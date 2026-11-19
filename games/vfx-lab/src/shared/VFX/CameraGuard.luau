-- CameraGuard: lets ONE cinematic own the camera at a time and always gives it back.
--
-- Why: roblox-vfx kits (sim/studio_kit.js output) set CurrentCamera.CameraType = Scriptable in
-- M.play when the effect defines a camera, and never set it back, so the player's camera stays
-- frozen after an ultimate. Fixed here, in our integration layer; the generated kits are untouched.
--
--   local token = CameraGuard.acquire("EclipseRend", maxSeconds)  -- nil if another cinematic owns it
--   ... play ...
--   CameraGuard.release(token)                                      -- restores type, subject, FOV
--
-- Restores even if the caller never calls release: after maxSeconds, when the local character
-- dies or respawns, and if workspace.CurrentCamera is replaced.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CameraGuard = {}

local owner = nil -- current token table
local saved = nil

local function restore()
	local snap = saved
	saved = nil
	owner = nil
	if not snap then
		return
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	camera.CameraType = if snap.Type == Enum.CameraType.Scriptable then Enum.CameraType.Custom else snap.Type
	local subject = snap.Subject
	if not (subject and subject.Parent) then
		local character = Players.LocalPlayer and Players.LocalPlayer.Character
		subject = character and character:FindFirstChildOfClass("Humanoid")
	end
	if subject then
		camera.CameraSubject = subject
	end
	camera.FieldOfView = snap.Fov
end

function CameraGuard.isBusy(): boolean
	return owner ~= nil
end

function CameraGuard.ownerName(): string?
	return owner and owner.Name
end

function CameraGuard.acquire(name: string, maxSeconds: number)
	if owner then
		return nil
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end
	local token = { Name = name }
	owner = token
	saved = { Type = camera.CameraType, Subject = camera.CameraSubject, Fov = camera.FieldOfView }
	-- safety net: whatever happens to the effect, the camera comes back
	task.delay(maxSeconds, function()
		CameraGuard.release(token)
	end)
	return token
end

function CameraGuard.release(token)
	if token == nil or owner ~= token then
		return -- stale token: someone newer owns the camera, or it was already restored
	end
	restore()
end

-- Force the camera back now (death, respawn, teleport, round end).
function CameraGuard.releaseAll()
	if owner then
		restore()
	end
end

local function watchCharacter(character: Model)
	CameraGuard.releaseAll()
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid then
		humanoid.Died:Connect(CameraGuard.releaseAll)
	end
end

local player = Players.LocalPlayer
if player then -- client only; on the server this module is inert
	player.CharacterAdded:Connect(watchCharacter)
	if player.Character then
		task.spawn(watchCharacter, player.Character)
	end
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(CameraGuard.releaseAll)
end

return CameraGuard
