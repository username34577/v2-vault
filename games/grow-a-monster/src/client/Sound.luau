-- Plays the sounds listed in Config.Sounds, on this client only.
-- Empty slots do nothing. A slot that fails to load warns ONCE and is skipped after that.
-- Vault: "Sound Fundamentals" (preload, play feedback sounds on clients, pitch variance).
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local Sound = {}

local templates = {} -- [name] = Sound | false
local lastPlayed = {} -- [name] = os.clock()
local MIN_GAP = 0.04 -- seconds; caps machine-gun repeats of one sound
local rng = Random.new()

local function normalize(id)
	if type(id) == "number" then
		return if id > 0 then `rbxassetid://{id}` else nil
	end
	if type(id) ~= "string" or id == "" then
		return nil
	end
	if string.match(id, "^%d+$") then
		return `rbxassetid://{id}`
	end
	return id
end

function Sound.preload()
	local list = {}
	for name, slot in Config.Sounds do
		local id = normalize(slot.Id)
		if id then
			local s = Instance.new("Sound")
			s.Name = `Sfx_{name}`
			s.SoundId = id
			s.Volume = slot.Volume or 0.5
			s.Parent = SoundService
			templates[name] = s
			table.insert(list, s)
		else
			templates[name] = false
		end
	end
	if #list == 0 then
		return
	end
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(list, function(contentId, status)
				if status == Enum.AssetFetchStatus.Success then
					return
				end
				for name, s in templates do
					if s and s.SoundId == contentId then
						warn(`[Sounds] "{name}" ({contentId}) didn't load, so it is skipped. Check the id in Config.Sounds.`)
						s:Destroy()
						templates[name] = false
					end
				end
			end)
		end)
	end)
end

-- pitch: optional extra speed multiplier (e.g. bigger food = lower gulp)
function Sound.play(name: string, pitch: number?)
	local template = templates[name]
	if not template or not template.IsLoaded then
		return
	end
	local now = os.clock()
	if now - (lastPlayed[name] or 0) < MIN_GAP then
		return
	end
	lastPlayed[name] = now
	local slot = Config.Sounds[name]
	local variance = slot.PitchVariance or 0
	local s = template:Clone()
	s.PlaybackSpeed = (pitch or 1) * (1 + rng:NextNumber(-variance, variance))
	s.Parent = SoundService
	s:Play()
	s.Ended:Once(function()
		s:Destroy()
	end)
	task.delay(8, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

return Sound
