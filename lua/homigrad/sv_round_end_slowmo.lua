local slowmoDuration = 6
local slowmoScale = 0.35
local slowmoInDuration = 0.4
local slowmoOutDuration = 1.5
local slowmoStarted

local function stopRoundEndSlowmo()
	slowmoStarted = nil
	hook.Remove("Think", "ZCity.RoundEndSlowmo")

	if game.GetTimeScale() ~= 1 then
		game.SetTimeScale(1)
	end
end

local function updateRoundEndSlowmo()
	if not slowmoStarted then
		stopRoundEndSlowmo()
		return
	end

	local elapsed = SysTime() - slowmoStarted
	if elapsed >= slowmoDuration then
		stopRoundEndSlowmo()
		return
	end

	local scale
	if elapsed < slowmoInDuration then
		scale = Lerp(elapsed / slowmoInDuration, 1, slowmoScale)
	elseif elapsed < slowmoDuration - slowmoOutDuration then
		scale = slowmoScale
	else
		local restoreFraction = (elapsed - (slowmoDuration - slowmoOutDuration)) / slowmoOutDuration
		scale = Lerp(restoreFraction, slowmoScale, 1)
	end

	game.SetTimeScale(math.Clamp(scale, slowmoScale, 1))
end

hook.Add("ZB_EndRound", "ZCity.RoundEndSlowmo", function()
	stopRoundEndSlowmo()
	slowmoStarted = SysTime()
	hook.Add("Think", "ZCity.RoundEndSlowmo", updateRoundEndSlowmo)
end)

hook.Add("ZB_PreRoundStart", "ZCity.RoundEndSlowmo.Reset", stopRoundEndSlowmo)
hook.Add("PostCleanupMap", "ZCity.RoundEndSlowmo.Reset", stopRoundEndSlowmo)
hook.Add("ShutDown", "ZCity.RoundEndSlowmo.Reset", stopRoundEndSlowmo)

stopRoundEndSlowmo()
