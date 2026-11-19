-- Cues: the one list of effects the server may ask clients to play. Both sides validate against it.
--
-- Two kinds, because they replicate differently:
--   * STATE effects (the sun carrier's aura): the server sets an attribute on the character model;
--     every client watches it. Late joiners and respawns are correct automatically, nothing to resend.
--   * ONE-SHOT effects (steal burst, victory): the server fires the "VFXCue" RemoteEvent with
--     (cueName, position, power) to players near the event. Clients build the visuals.
-- The server never builds particles itself, and clients never decide that an effect happened.
local Cues = {}

Cues.REMOTE = "VFXCue" -- RemoteEvent in ReplicatedStorage, server -> client only
Cues.ACTOR_TAG = "VFXActor" -- CollectionService tag on any model that can carry state effects
Cues.CARRY_ATTRIBUTE = "CarryingSun" -- boolean on the actor model

-- name -> recipe and send rules
Cues.OneShots = {
	SunBurst = { Recipe = "SunBurst", Radius = 250, MaxPerSecond = 10, Power = { 0.5, 2 } },
	SunVictory = { Recipe = "SunVictory", Radius = math.huge, MaxPerSecond = 2, Power = { 1, 1.5 } },
}

Cues.States = {
	CarryingSun = { Recipe = "SunAura", KeepLights = true }, -- the glow is a gameplay cue: keep its light on Low
}

-- Shared shape check for a one-shot payload (used by the client; the server builds its own payloads).
function Cues.validOneShot(name, position, power): boolean
	local cue = type(name) == "string" and Cues.OneShots[name]
	if not cue or typeof(position) ~= "Vector3" or type(power) ~= "number" then
		return false
	end
	if position.Magnitude ~= position.Magnitude or position.Magnitude > 1e5 or power ~= power then
		return false -- NaN or absurd values
	end
	return true
end

return Cues
