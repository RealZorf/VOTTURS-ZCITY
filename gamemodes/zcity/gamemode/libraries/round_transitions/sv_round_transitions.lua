zb = zb or {}
zb.Transition = zb.Transition or {}

util.AddNetworkString("ZB_RoundTransition")
util.AddNetworkString("ZB_RoundTimes")

function zb.Transition:BroadcastTimes(roundTime, roundStart, roundBegin, ply)
	roundTime = roundTime or zb.ROUND_TIME or 300
	roundStart = roundStart or CurTime()
	roundBegin = roundBegin or roundStart

	zb.ROUND_TIME = roundTime
	zb.ROUND_START = roundStart
	zb.ROUND_BEGIN = roundBegin

	if hg and hg.UpdateRoundTime then
		hg.UpdateRoundTime(roundTime, roundStart, roundBegin)
	end

	net.Start("ZB_RoundTimes")
		net.WriteFloat(roundTime)
		net.WriteFloat(roundStart)
		net.WriteFloat(roundBegin)
	if IsValid(ply) then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

function zb.Transition:SendSync(ply)
	local mode = CurrentRound()
	local revealAt = (zb.ROUND_STATE == zb.Transition.STATE_ACTIVE and zb.ROUND_BEGIN)
		or (zb.ROUND_STATE == zb.Transition.STATE_INTERMISSION and (zb.START_TIME or (CurTime() + zb.Transition.GetIntermissionDuration(mode))))
		or 0

	net.Start("ZB_RoundTransition")
		net.WriteUInt(zb.ROUND_STATE or 0, 3)
		net.WriteFloat(CurTime())
		net.WriteFloat(revealAt or 0)
		net.WriteBool(self.IntermissionStarted and not self.SetupComplete or false)
	if IsValid(ply) then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

function zb.Transition:ApplyCurtainFade(ply, hold)
	if not IsValid(ply) then return end
	ply:ScreenFade(SCREENFADE.OUT, Color(0, 0, 0), 0.08, hold or zb.Transition.CURTAIN_HOLD)
end

function zb.Transition:ClearCurtainFade(ply)
	if not IsValid(ply) then return end
	ply:ScreenFade(SCREENFADE.IN, Color(0, 0, 0), 0.25, 0.1)
end

function zb.Transition:ScheduleRoundStart(revealAt)
	timer.Remove("ZB_IntermissionRoundStart")

	local delay = math.max(0.05, revealAt - CurTime())
	timer.Create("ZB_IntermissionRoundStart", delay, 1, function()
		if zb.ROUND_STATE ~= zb.Transition.STATE_INTERMISSION then return end
		if #player.GetAll() < 2 then return end
		zb:RoundStart()
	end)
end

function zb.Transition:BeginIntermission()
	if self.IntermissionStarted then return end
	self.IntermissionStarted = true
	self.SetupComplete = false

	zb.ROUND_STATE = zb.Transition.STATE_INTERMISSION
	zb.SHOULD_FADE = true
	zb.END_MENU_UNTIL = nil

	hook.Run("ZB_PreRoundStart")
	hook.Run("TTTPrepareRound")

	zb.CROUND = zb.nextround or "hmcd"
	if CurrentRound().shouldfreeze then zb:Freeze() end

	local mode = CurrentRound()
	local intermission = zb.Transition.GetIntermissionDuration(mode)
	local revealAt = CurTime() + intermission
	zb.START_TIME = revealAt

	net.Start("RoundInfo")
		net.WriteString(mode.name or "hmcd")
		net.WriteInt(zb.ROUND_STATE, 4)
	net.Broadcast()

	self:BroadcastTimes(mode.ROUND_TIME, CurTime(), revealAt)
	self:SendSync()

	timer.Simple(zb.Transition.SETUP_DEFER, function()
		if zb.ROUND_STATE ~= zb.Transition.STATE_INTERMISSION then return end

		zb:KillPlayers()
		zb:AutoBalance()

		if hg.PluvTown.Active then
			for _, p in player.Iterator() do
				p:SetNetVar("CurPluv", "pluv")
			end
		end

		CurrentRound().saved = {}

		CurrentRound():Intermission()
		CurrentRound():GiveEquipment()

		self.SetupComplete = true
		self:SendSync()
	end)

	self:ScheduleRoundStart(revealAt)
end

function zb.Transition:OnRoundEnd()
	timer.Remove("ZB_IntermissionRoundStart")
	self.IntermissionStarted = false
	self.SetupComplete = false
	self:SendSync()
end

function zb.Transition:OnRoundActive()
	timer.Remove("ZB_IntermissionRoundStart")

	local mode = CurrentRound()
	local now = CurTime()

	self:BroadcastTimes(mode and mode.ROUND_TIME, now, now)

	for _, ply in player.Iterator() do
		if IsValid(ply) then
			ply:ScreenFade(SCREENFADE.IN, Color(0, 0, 0), 0, 0)
		end
	end

	self.IntermissionStarted = false
	self.SetupComplete = false
	self:SendSync()
end

hook.Add("PlayerInitialSpawn", "ZB_TransitionSync", function(ply)
	timer.Simple(0.5, function()
		if not IsValid(ply) then return end

		if zb.ROUND_TIME and zb.ROUND_START and zb.ROUND_BEGIN then
			zb.Transition:BroadcastTimes(zb.ROUND_TIME, zb.ROUND_START, zb.ROUND_BEGIN, ply)
		end

		zb.Transition:SendSync(ply)
	end)
end)
