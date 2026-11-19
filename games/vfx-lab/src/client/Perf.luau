-- Perf: frame-time sampling for VFX tests (client).
--   Perf.start()                 begin sampling every rendered frame
--   Perf.snapshot() -> {fps, worstMs, memoryMb}   over the last second
--   Perf.measure(seconds) -> {avgFps, worstMs, p95Ms, frames}   blocks for `seconds` (yields)
-- Frame time is the honest metric for effects: a burst that costs 2 ms on a phone shows up as a
-- worst-frame spike long before it moves the average FPS.
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local Perf = {}

local window = {} -- {t, dt} for the last second
local recording = nil -- list of dt while Perf.measure runs
local started = false

function Perf.start()
	if started then
		return
	end
	started = true
	RunService.RenderStepped:Connect(function(dt)
		local now = os.clock()
		table.insert(window, { now, dt })
		while window[1] and now - window[1][1] > 1 do
			table.remove(window, 1)
		end
		if recording then
			table.insert(recording, dt)
		end
	end)
end

function Perf.snapshot()
	local worst, sum = 0, 0
	for _, s in window do
		worst = math.max(worst, s[2])
		sum += s[2]
	end
	return {
		fps = if sum > 0 then #window / sum else 0,
		worstMs = worst * 1000,
		memoryMb = Stats:GetTotalMemoryUsageMb(),
	}
end

function Perf.measure(seconds: number)
	Perf.start()
	recording = {}
	task.wait(seconds)
	local samples = recording
	recording = nil
	table.sort(samples)
	local sum = 0
	for _, dt in samples do
		sum += dt
	end
	local n = #samples
	return {
		frames = n,
		avgFps = if sum > 0 then n / sum else 0,
		worstMs = if n > 0 then samples[n] * 1000 else 0,
		p95Ms = if n > 0 then samples[math.max(1, math.ceil(n * 0.95))] * 1000 else 0,
	}
end

return Perf
