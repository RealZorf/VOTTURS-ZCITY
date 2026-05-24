zb = zb or {}
zb.Transition = zb.Transition or {}

-- Round states (matches zb.ROUND_STATE)
zb.Transition.STATE_INTERMISSION = 0
zb.Transition.STATE_ACTIVE = 1
zb.Transition.STATE_END = 3

zb.Transition.DEFAULT_END_MENU = 4
zb.Transition.DEFAULT_END_AFTER = 1.75
zb.Transition.DEFAULT_PREP_TIME = 4
zb.Transition.SETUP_DEFER = 0.1
zb.Transition.END_MENU_DEDUPE = 0.35

function zb.Transition.GetEndMenuDuration(mode)
	mode = mode or (CurrentRound and CurrentRound())
	if not mode then return zb.Transition.DEFAULT_END_MENU end
	return mode.end_menu_time or zb.END_MENU_DURATION or zb.Transition.DEFAULT_END_MENU
end

function zb.Transition.GetEndAfterDuration(mode)
	mode = mode or (CurrentRound and CurrentRound())
	if not mode then return zb.Transition.DEFAULT_END_AFTER end
	return mode.end_time or zb.Transition.DEFAULT_END_AFTER
end

-- Prep phase between rounds (spawn, teams, equipment). NOT the post-start buy window.
function zb.Transition.GetIntermissionDuration(mode)
	mode = mode or (CurrentRound and CurrentRound())
	if not mode then return zb.Transition.DEFAULT_PREP_TIME end

	if mode.prep_time then return mode.prep_time end
	if mode.intermission_time then return mode.intermission_time end

	-- Legacy: start_time was used for both prep and buy timers; large values are buy windows.
	local startTime = mode.start_time
	if startTime and startTime > 0 and startTime <= 10 then
		return startTime
	end

	return zb.Transition.DEFAULT_PREP_TIME
end
