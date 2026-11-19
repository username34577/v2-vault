-- VFX quality presets (client). Every number that trades looks for frame time lives here.
-- Default comes from the player's own Roblox graphics setting; Quality.set() overrides it.
--
--   EmitMul           multiplies burst particle counts (VFXKit handle.emit(mult); kits' EmitCount)
--   RateMul           multiplies continuous Rate (VFXKit opts.rate_mul; kits' starting Rate)
--   MaxBursts         one-shot effects alive at once; extra ones are skipped (never queued)
--   MaxKits           authored Studio kits playing at once
--   CullDistance      one-shots further than this from the camera are skipped (studs)
--   DecorativeLights  false = drop pulse/flash PointLights; gameplay lights (constant) stay
--   ScreenEffects     allow camera moves, FOV punch, grades and overlays for YOUR OWN cinematics
local Quality = {}

export type Preset = {
	Name: string,
	EmitMul: number,
	RateMul: number,
	MaxBursts: number,
	MaxKits: number,
	CullDistance: number,
	DecorativeLights: boolean,
	ScreenEffects: boolean,
}

Quality.Presets = {
	Low = {
		Name = "Low",
		EmitMul = 0.45,
		RateMul = 0.5,
		MaxBursts = 4,
		MaxKits = 1,
		CullDistance = 120,
		DecorativeLights = false,
		ScreenEffects = false,
	} :: Preset,
	Medium = {
		Name = "Medium",
		EmitMul = 0.75,
		RateMul = 0.75,
		MaxBursts = 8,
		MaxKits = 2,
		CullDistance = 220,
		DecorativeLights = true,
		ScreenEffects = true,
	} :: Preset,
	High = {
		Name = "High",
		EmitMul = 1,
		RateMul = 1,
		MaxBursts = 16,
		MaxKits = 3,
		CullDistance = 400,
		DecorativeLights = true,
		ScreenEffects = true,
	} :: Preset,
}
Quality.Order = { "Low", "Medium", "High" }

local changed = Instance.new("BindableEvent")
Quality.Changed = changed.Event -- fires (preset)

-- Roblox graphics level 1-3 -> Low, 4-7 -> Medium, 8-10 -> High; Automatic -> Medium.
local function fromUserSettings(): string
	local ok, level = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel
	end)
	if not ok or level == Enum.SavedQualitySetting.Automatic then
		return "Medium"
	end
	local n = tonumber(string.match(level.Name, "%d+")) or 5
	if n <= 3 then
		return "Low"
	elseif n <= 7 then
		return "Medium"
	end
	return "High"
end

local current: Preset = Quality.Presets[fromUserSettings()]

function Quality.get(): Preset
	return current
end

function Quality.set(name: string)
	local preset = Quality.Presets[name]
	if not preset or preset == current then
		return
	end
	current = preset
	changed:Fire(preset)
end

-- Low -> Medium -> High -> Low
function Quality.cycle(): Preset
	for i, name in Quality.Order do
		if name == current.Name then
			Quality.set(Quality.Order[i % #Quality.Order + 1])
			break
		end
	end
	return current
end

return Quality
