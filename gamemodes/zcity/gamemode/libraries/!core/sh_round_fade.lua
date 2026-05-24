zb = zb or {}
zb.RoundFade = zb.RoundFade or {}

zb.RoundFade.BLACK_DURATION = 7.5
zb.RoundFade.INTRO_TEXT_DURATION = 8
zb.RoundFade.INTERMISSION_FADE = 7
zb.RoundFade.TDM_MOVE_BLOCK = 20

function zb.RoundFade.GetRoundStartTime()
	return zb.ROUND_START or CurTime()
end

function zb.RoundFade.GetBlackAlpha(startTime)
	startTime = startTime or zb.RoundFade.GetRoundStartTime()

	if startTime + zb.RoundFade.BLACK_DURATION < CurTime() then
		return 0
	end

	return math.Clamp(startTime + zb.RoundFade.BLACK_DURATION - CurTime(), 0, 1)
end

function zb.RoundFade.GetIntroAlpha(startTime)
	startTime = startTime or zb.RoundFade.GetRoundStartTime()

	if startTime + zb.RoundFade.INTRO_TEXT_DURATION < CurTime() then
		return 0
	end

	return math.Clamp(startTime + zb.RoundFade.INTRO_TEXT_DURATION - CurTime(), 0, 1)
end

function zb.RoundFade.PaintBlackScreen(startTime)
	if not CLIENT then return end

	local fade = zb.RoundFade.GetBlackAlpha(startTime)
	if fade <= 0 then return end

	surface.SetDrawColor(0, 0, 0, 255 * fade)
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end
