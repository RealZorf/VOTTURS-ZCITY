local MODE = MODE

util.AddNetworkString("HMCD_BeingVictimOfNeckBreak")
util.AddNetworkString("HMCD_BreakingOtherNeck")
util.AddNetworkString("HMCD_BeingVictimOfDisarmament")
util.AddNetworkString("HMCD_DisarmingOther")
util.AddNetworkString("HMCD_UpdateChemicalResistance")
util.AddNetworkString("HMCD_StalkerMarks")

resource.AddFile("sound/cannibal_eating.mp3")

local cannibal_body_gib_models = {
	"models/gibs/hgibs.mdl",
	"models/gibs/hgibs_spine.mdl",
	"models/gibs/hgibs_rib.mdl",
	"models/gibs/hgibs_scapula.mdl"
}

for _, model in ipairs(cannibal_body_gib_models) do
	util.PrecacheModel(model)
end

local cannibal_eating_sound = "cannibal_eating.mp3"
local cannibal_eating_volume = 0.82
local cannibal_eating_pitch_min = 118
local cannibal_eating_pitch_max = 128

local function stopCannibalEatingSound(ply, fade)
	local data = IsValid(ply) and ply.Ability_CannibalConsume or nil
	local snd = data and data.EatingSound
	if not snd then return end

	if fade then
		snd:FadeOut(0.2)
	else
		snd:Stop()
	end

	data.EatingSound = nil
end

MODE.ManiacFuryHarmThreshold = 5
MODE.ManiacFuryAdrenaline = 0.65
MODE.ManiacFuryAdrenalineMax = 0.8
MODE.ManiacFuryAnalgesia = 0.9
MODE.ManiacFuryAnalgesiaMax = 0.95
MODE.ManiacFuryStaminaRegenPerSecond = MODE.ManiacFuryStaminaRegenPerSecond or 26
MODE.ManiacFuryPainCap = MODE.ManiacFuryPainCap or 30
MODE.ManiacFurySecondWindStaminaFraction = 0.65
MODE.ManiacFurySecondWindOxygen = 30
MODE.ManiacFurySecondWindPainCap = 12
MODE.ManiacFuryNoFlinchDuration = 5
MODE.ManiacBloodFrenzyDuration = 4
MODE.ManiacBloodFrenzyMaxStacks = 3
MODE.ManiacBloodFrenzyStaminaRegenPerStack = 12
MODE.ManiacBloodFrenzyImmediateStamina = 9
MODE.ManiacBloodFrenzyImmobilizationRelief = 4
MODE.ManiacPainConversionStaminaPerHarm = 1.3
MODE.ManiacPainConversionShockRelief = 0.55
MODE.ManiacPainConversionPainRelief = 0.65
MODE.ManiacFuryPhrases = MODE.ManiacFuryPhrases or {
	"NOW IT'S MY TURN",
	"TIME TO GO CRAZY",
	"THIS FEELS UNREAL",
	"I CAN'T FEEL A THING",
	"YOU SHOULD HAVE FINISHED ME"
}
MODE.CannibalWitnessFearRadius = 850
MODE.CannibalWitnessFearCooldown = 3
MODE.CannibalWitnessFearAdd = 0.55
MODE.CannibalWitnessShockAdd = 5
MODE.CannibalWitnessViewDot = math.cos(math.rad(62))

local function canUseShadowCamouflageOnEntity(ent, tr)
	if not tr.Hit or tr.HitSky then
		return false
	end

	if tr.HitWorld then
		return true
	end

	if not IsValid(ent) then
		return false
	end

	if ent:IsPlayer() or ent:IsNPC() or ent:IsWeapon() or ent:IsRagdoll() then
		return false
	end

	if hgIsDoor and hgIsDoor(ent) then
		return true
	end

	local moveType = ent:GetMoveType()
	local isTrigger = ent.IsTrigger and ent:IsTrigger() or false

	return ent:GetSolid() ~= SOLID_NONE and not isTrigger and (moveType == MOVETYPE_NONE or moveType == MOVETYPE_PUSH)
end

function MODE.IsPlayerNearWallForShadowCamouflage(ply)
	local origin = ply:WorldSpaceCenter()
	origin.z = ply:GetPos().z + math.max(ply:OBBMaxs().z * 0.4, 35)

	for yaw = 0, 330, 30 do
		local dir = Angle(0, yaw, 0):Forward()
		local tr = util.TraceLine({
			start = origin,
			endpos = origin + dir * MODE.ShadowCamouflageWallDistance,
			filter = ply,
			mask = MASK_PLAYERSOLID,
		})

		if canUseShadowCamouflageOnEntity(tr.Entity, tr) then
			return true, tr
		end
	end

	return false
end

function MODE.SetShadowCamouflageActive(ply, state)
	if ply.Ability_ShadowCamouflage_Active == state then
		return
	end

	if state then
		ply.Ability_ShadowCamouflage_OriginalColor = ply.Ability_ShadowCamouflage_OriginalColor or ply:GetColor()
		ply.Ability_ShadowCamouflage_OriginalRenderMode = ply.Ability_ShadowCamouflage_OriginalRenderMode or ply:GetRenderMode()

		ply:SetRenderMode(RENDERMODE_TRANSCOLOR)
		local tint = MODE.ShadowCamouflageTint or Color(255, 255, 255, MODE.ShadowCamouflageAlpha)
		ply:SetColor(Color(255, 255, 255, tint.a))
		ply:DrawShadow(false)
		if ply.RemoveAllDecals then
			ply:RemoveAllDecals()
		end
	else
		local clr = ply.Ability_ShadowCamouflage_OriginalColor or color_white

		ply:SetRenderMode(ply.Ability_ShadowCamouflage_OriginalRenderMode or RENDERMODE_NORMAL)
		ply:SetColor(Color(clr.r, clr.g, clr.b, clr.a))
		ply:DrawShadow(true)
	end

	ply.Ability_ShadowCamouflage_Active = state
	ply:SetNWBool("HMCD_ShadowCamouflageActive", state)
end

function MODE.ResetShadowCamouflage(ply)
	ply.Ability_ShadowCamouflage_ChargeStart = nil
	ply.Ability_ShadowCamouflage_LastNearWall = nil
	ply:SetNWFloat("HMCD_ShadowCamouflageChargeStart", 0)
	ply:SetNWFloat("HMCD_ShadowCamouflageReadyAt", 0)

	MODE.SetShadowCamouflageActive(ply, false)
end

function MODE.IsManiacRole(subrole)
	return subrole == "traitor_maniac" or subrole == "traitor_maniac_soe"
end

local function isStalkerRoundActive()
	if(not MODE.RoleChooseRoundTypes[MODE.Type])then return false end

	local round = CurrentRound and CurrentRound()
	return round == MODE
end

local function normalizeStalkerTarget(ent)
	if not IsValid(ent) then return nil end

	local ply = hg.RagdollOwner and (hg.RagdollOwner(ent) or ent) or ent
	if not IsValid(ply) or not ply:IsPlayer() then return nil end

	return ply
end

local function normalizeStalkerAttacker(ent)
	local ply = normalizeStalkerTarget(ent)
	if IsValid(ply) then return ply end

	if IsValid(ent) and ent.GetOwner then
		ply = normalizeStalkerTarget(ent:GetOwner())
		if IsValid(ply) then return ply end
	end

	return nil
end

function MODE.CanStalkerMarkTarget(stalker, target)
	return IsValid(stalker)
		and IsValid(target)
		and stalker ~= target
		and stalker:IsPlayer()
		and target:IsPlayer()
		and stalker:Alive()
		and target:Alive()
		and stalker.isTraitor
		and not target.isTraitor
		and stalker:Team() ~= TEAM_SPECTATOR
		and target:Team() ~= TEAM_SPECTATOR
end

function MODE.GetStalkerMarks(stalker)
	stalker.Ability_StalkerMarks = stalker.Ability_StalkerMarks or {}
	return stalker.Ability_StalkerMarks
end

function MODE.CleanupStalkerMarks(stalker)
	local marks = MODE.GetStalkerMarks(stalker)

	for i = #marks, 1, -1 do
		local mark = marks[i]
		if not mark or not MODE.CanStalkerMarkTarget(stalker, mark.Target) then
			table.remove(marks, i)
		end
	end

	stalker.Ability_StalkerMarks = marks

	return marks
end

function MODE.IsStalkerTargetMarked(stalker, target)
	local marks = MODE.CleanupStalkerMarks(stalker)

	for i = 1, #marks do
		local mark = marks[i]
		if mark.Target == target then
			return true, mark
		end
	end

	return false
end

function MODE.SyncStalkerMarks(stalker)
	if not IsValid(stalker) then return end

	local valid_marks = MODE.CleanupStalkerMarks(stalker)
	local send_count = math.min(#valid_marks, MODE.StalkerMarkMax)

	net.Start("HMCD_StalkerMarks")
		net.WriteUInt(send_count, 2)
		for i = 1, send_count do
			local mark = valid_marks[i]
			net.WriteEntity(mark.Target)
			net.WriteBool(not mark.StunSpent)
			net.WriteBool(MODE.IsStalkerVictimIsolated(stalker, mark.Target))
		end
	net.Send(stalker)
end

function MODE.ResetStalkerTracking(stalker)
	if not IsValid(stalker) then return end

	stalker.Ability_StalkerMarks = nil
	stalker.Ability_StalkerGazeTarget = nil
	stalker.Ability_StalkerGazeStartedAt = nil
	stalker.Ability_StalkerPursuitTarget = nil
	stalker.Ability_StalkerPursuitLastThink = nil
	stalker.Ability_StalkerNextSenseSync = nil
	stalker:SetNWEntity("HMCD_StalkerGazeTarget", NULL)
	stalker:SetNWFloat("HMCD_StalkerGazeStartedAt", 0)
	stalker:SetNWFloat("HMCD_StalkerGazeReadyAt", 0)
	stalker:SetNWBool("HMCD_StalkerPursuitActive", false)
	stalker:SetNWEntity("HMCD_StalkerPursuitTarget", NULL)

	net.Start("HMCD_StalkerMarks")
		net.WriteUInt(0, 2)
	net.Send(stalker)
end

function MODE.GetStalkerLookTarget(stalker)
	local start_pos = stalker:GetShootPos()
	local aim = stalker:GetAimVector()
	local best_target
	local best_score = MODE.StalkerMarkAngleCos
	local tr = util.TraceLine({
		start = start_pos,
		endpos = start_pos + aim * MODE.StalkerMarkDistance,
		filter = stalker,
		mask = MASK_SHOT
	})

	local target = normalizeStalkerTarget(tr.Entity)
	if MODE.CanStalkerMarkTarget(stalker, target) then
		local offset = target:WorldSpaceCenter() - start_pos
		offset:Normalize()
		if aim:Dot(offset) >= MODE.StalkerMarkAngleCos then
			return target
		end
	end

	for _, ply in player.Iterator() do
		if not MODE.CanStalkerMarkTarget(stalker, ply) then continue end

		local center = ply:WorldSpaceCenter()
		local distance = center:Distance(start_pos)
		if distance > MODE.StalkerMarkDistance then continue end

		local offset = center - start_pos
		offset:Normalize()
		local score = aim:Dot(offset)
		if score < best_score then continue end

		local closest = util.DistanceToLine(start_pos, start_pos + aim * MODE.StalkerMarkDistance, center)
		if closest > MODE.StalkerMarkAssistDistance then continue end

		local blocker = util.TraceLine({
			start = start_pos,
			endpos = center,
			filter = stalker,
			mask = MASK_SHOT
		})

		local blocker_ply = normalizeStalkerTarget(blocker.Entity)
		if blocker.Hit and blocker_ply ~= ply then continue end

		best_score = score
		best_target = ply
	end

	return best_target
end

function MODE.UpdateStalkerTracking(stalker)
	if not isStalkerRoundActive() then return end
	if not MODE.IsStalkerRole or not MODE.IsStalkerRole(stalker.SubRole) then return end

	local now = CurTime()
	local target = MODE.GetStalkerLookTarget(stalker)

	if not IsValid(target) then
		if IsValid(stalker.Ability_StalkerGazeTarget) then
			stalker.Ability_StalkerGazeTarget = nil
			stalker.Ability_StalkerGazeStartedAt = nil
			stalker:SetNWEntity("HMCD_StalkerGazeTarget", NULL)
			stalker:SetNWFloat("HMCD_StalkerGazeStartedAt", 0)
			stalker:SetNWFloat("HMCD_StalkerGazeReadyAt", 0)
		end

		return
	end

	local already_marked = MODE.IsStalkerTargetMarked(stalker, target)
	if already_marked then
		stalker.Ability_StalkerGazeTarget = nil
		stalker.Ability_StalkerGazeStartedAt = nil
		stalker:SetNWEntity("HMCD_StalkerGazeTarget", NULL)
		stalker:SetNWFloat("HMCD_StalkerGazeStartedAt", 0)
		stalker:SetNWFloat("HMCD_StalkerGazeReadyAt", 0)
		return
	end

	local marks = MODE.CleanupStalkerMarks(stalker)
	if #marks >= MODE.StalkerMarkMax then
		stalker.Ability_StalkerGazeTarget = nil
		stalker.Ability_StalkerGazeStartedAt = nil
		stalker:SetNWEntity("HMCD_StalkerGazeTarget", NULL)
		stalker:SetNWFloat("HMCD_StalkerGazeStartedAt", 0)
		stalker:SetNWFloat("HMCD_StalkerGazeReadyAt", 0)
		return
	end

	if stalker.Ability_StalkerGazeTarget ~= target then
		stalker.Ability_StalkerGazeTarget = target
		stalker.Ability_StalkerGazeStartedAt = now
		stalker:SetNWEntity("HMCD_StalkerGazeTarget", target)
		stalker:SetNWFloat("HMCD_StalkerGazeStartedAt", now)
		stalker:SetNWFloat("HMCD_StalkerGazeReadyAt", now + MODE.StalkerMarkTime)
		return
	end

	local started_at = stalker.Ability_StalkerGazeStartedAt or now
	if started_at + MODE.StalkerMarkTime > now then return end

	marks[#marks + 1] = {
		Target = target,
		MarkedAt = now,
		StunSpent = false
	}

	stalker.Ability_StalkerGazeTarget = nil
	stalker.Ability_StalkerGazeStartedAt = nil
	stalker:SetNWEntity("HMCD_StalkerGazeTarget", NULL)
	stalker:SetNWFloat("HMCD_StalkerGazeStartedAt", 0)
	stalker:SetNWFloat("HMCD_StalkerGazeReadyAt", 0)

	if isfunction(stalker.Notify) then
		stalker:Notify("Heartbeat marked.", true, "stalker_mark", 2, nil, Color(80, 210, 255))
	else
		stalker:ChatPrint("Heartbeat marked.")
	end

	MODE.SyncStalkerMarks(stalker)
end

function MODE.IsStalkerVictimIsolated(stalker, victim)
	if not IsValid(stalker) or not IsValid(victim) then return false end

	local victim_pos = victim:GetPos()
	local radius_sqr = (MODE.StalkerIsolatedRadius or 430) ^ 2

	for _, ply in player.Iterator() do
		if ply == victim or ply == stalker then continue end
		if not IsValid(ply) or not ply:Alive() or ply:Team() == TEAM_SPECTATOR then continue end
		if ply.isTraitor then continue end

		if ply:GetPos():DistToSqr(victim_pos) <= radius_sqr then
			return false
		end
	end

	return true
end

function MODE.GetStalkerPursuitPrey(stalker)
	if not IsValid(stalker) then return nil end

	local marks = MODE.CleanupStalkerMarks(stalker)
	local stalker_pos = stalker:GetPos()
	local radius_sqr = (MODE.StalkerPursuitRadius or 1450) ^ 2
	local best_target
	local best_dist_sqr = radius_sqr

	for i = 1, #marks do
		local target = marks[i].Target
		if not MODE.CanStalkerMarkTarget(stalker, target) then continue end
		if not MODE.IsStalkerVictimIsolated(stalker, target) then continue end

		local dist_sqr = target:GetPos():DistToSqr(stalker_pos)
		if dist_sqr <= best_dist_sqr then
			best_target = target
			best_dist_sqr = dist_sqr
		end
	end

	return best_target
end

function MODE.SetStalkerPursuitTarget(stalker, target)
	if not IsValid(stalker) then return end

	local active = IsValid(target)
	if stalker.Ability_StalkerPursuitTarget == target and stalker:GetNWBool("HMCD_StalkerPursuitActive", false) == active then return end

	stalker.Ability_StalkerPursuitTarget = active and target or nil
	stalker:SetNWBool("HMCD_StalkerPursuitActive", active)
	stalker:SetNWEntity("HMCD_StalkerPursuitTarget", active and target or NULL)
end

function MODE.UpdateStalkerPursuit(stalker)
	if not isStalkerRoundActive() or not IsValid(stalker) or not stalker:Alive() then
		MODE.SetStalkerPursuitTarget(stalker, nil)
		return
	end

	local now = CurTime()
	local last_think = stalker.Ability_StalkerPursuitLastThink or now
	local delta = math.Clamp(now - last_think, 0, 0.25)
	stalker.Ability_StalkerPursuitLastThink = now

	local target = MODE.GetStalkerPursuitPrey(stalker)
	MODE.SetStalkerPursuitTarget(stalker, target)

	if not IsValid(target) or delta <= 0 then return end

	local org = stalker.organism
	local stamina = org and org.stamina
	if not stamina then return end

	local max_stamina = stamina.max or stamina.range or 0
	if max_stamina <= 0 then return end

	stamina[1] = math.min(max_stamina, (stamina[1] or max_stamina) + (MODE.StalkerPursuitStaminaRegen or 8) * delta)
end

function MODE.TryStalkerFirstHit(attacker, victim, dmg_info)
	if not isStalkerRoundActive() then return end
	if not IsValid(attacker) or not MODE.IsStalkerRole or not MODE.IsStalkerRole(attacker.SubRole) then return end

	victim = normalizeStalkerTarget(victim)
	if not MODE.CanStalkerMarkTarget(attacker, victim) then return end

	local marked, mark = MODE.IsStalkerTargetMarked(attacker, victim)
	if not marked or not mark or mark.StunSpent then return end

	mark.StunSpent = true
	local isolated = MODE.IsStalkerVictimIsolated(attacker, victim)
	local stun_time = isolated and (MODE.StalkerIsolatedFirstHitStunTime or 2.35) or (MODE.StalkerFirstHitStunTime or 1.35)
	local damage_mul = isolated and (MODE.StalkerIsolatedFirstHitDamageMultiplier or 1.4) or (MODE.StalkerFirstHitDamageMultiplier or 1.15)

	if dmg_info and damage_mul > 1 then
		dmg_info:SetDamage((dmg_info:GetDamage() or 0) * damage_mul)
	end

	if hg.LightStunPlayer then
		hg.LightStunPlayer(victim, stun_time)
	end

	local org = victim.organism
	local stamina = org and org.stamina
	if stamina then
		stamina[1] = math.max((stamina[1] or 0) - (MODE.StalkerFirstHitStaminaDrain or 45), 0)
	end

	victim:ViewPunch(Angle(math.Rand(-7, -3), math.Rand(-4, 4), math.Rand(-4, 4)))
	victim:EmitSound("player/heartbeat1.wav", 55, isolated and 70 or 82, 0.35)

	if isolated then
		if isfunction(attacker.Notify) then
			attacker:Notify("Isolated heartbeat staggered.", true, "stalker_isolated_hit", 2, nil, Color(80, 210, 255))
		else
			attacker:ChatPrint("Isolated heartbeat staggered.")
		end
	end

	MODE.SyncStalkerMarks(attacker)
end

function MODE.IsManiacFuryRoundActive()
	if(not MODE.RoleChooseRoundTypes[MODE.Type])then return false end

	local round = CurrentRound and CurrentRound()
	return round == MODE
end

function MODE.CanTriggerManiacFury(ply)
	return IsValid(ply)
		and ply:IsPlayer()
		and ply:Alive()
		and MODE.IsManiacRole(ply.SubRole)
		and not ply.Ability_ManiacFury_Active
		and not ply.Ability_ManiacFury_Triggered
		and ply.organism ~= nil
end

function MODE.ResetManiacFury(ply)
	if not IsValid(ply) then return end

	ply.Ability_ManiacFury_Active = nil
	ply.Ability_ManiacFury_Triggered = nil
	ply.Ability_ManiacFury_LastThink = nil
	ply.Ability_ManiacFury_NoFlinchUntil = nil
	ply.Ability_ManiacBloodFrenzyUntil = nil
	ply.Ability_ManiacBloodFrenzyStacks = nil
	ply:SetNWBool("HMCD_ManiacFuryActive", false)
	ply:SetNWFloat("HMCD_ManiacFuryStartedAt", 0)
end

function MODE.ActivateManiacFury(ply)
	if not IsValid(ply) or ply.Ability_ManiacFury_Triggered then return end

	local now = CurTime()
	ply.Ability_ManiacFury_Triggered = true
	ply.Ability_ManiacFury_Active = true
	ply.Ability_ManiacFury_LastThink = now
	ply.Ability_ManiacFury_NoFlinchUntil = now + (MODE.ManiacFuryNoFlinchDuration or 5)
	ply:SetNWBool("HMCD_ManiacFuryActive", true)
	ply:SetNWFloat("HMCD_ManiacFuryStartedAt", now)
	MODE.ApplyManiacSecondWind(ply)
	MODE.ApplyManiacFury(ply)

	local phrase = MODE.ManiacFuryPhrases[math.random(#MODE.ManiacFuryPhrases)]
	if isfunction(ply.Notify) then
		ply:Notify(phrase, true, "maniac_fury", 0, nil, Color(255, 45, 45))
	else
		ply:ChatPrint(phrase)
	end

	-- Keep fury feedback personal; a world-audible gasp makes the passive an audio beacon.
end

function MODE.GetManiacBloodFrenzyStacks(ply)
	if not IsValid(ply) or not ply.Ability_ManiacBloodFrenzyUntil or ply.Ability_ManiacBloodFrenzyUntil <= CurTime() then
		return 0
	end

	return math.Clamp(ply.Ability_ManiacBloodFrenzyStacks or 0, 0, MODE.ManiacBloodFrenzyMaxStacks or 3)
end

function MODE.AddManiacBloodFrenzy(ply, harm)
	if not IsValid(ply) or not ply.Ability_ManiacFury_Active then return end

	local org = ply.organism
	if not org then return end

	local now = CurTime()
	local old_stacks = MODE.GetManiacBloodFrenzyStacks(ply)
	local gain = (harm or 0) >= 12 and 2 or 1
	local stacks = math.Clamp(old_stacks + gain, 1, MODE.ManiacBloodFrenzyMaxStacks or 3)

	ply.Ability_ManiacBloodFrenzyStacks = stacks
	ply.Ability_ManiacBloodFrenzyUntil = now + (MODE.ManiacBloodFrenzyDuration or 4)

	local stamina = org.stamina
	if stamina then
		local max_stamina = stamina.max or stamina.range or 0
		if max_stamina > 0 then
			stamina[1] = math.min(max_stamina, (stamina[1] or 0) + (MODE.ManiacBloodFrenzyImmediateStamina or 9) * stacks)
		end
	end

	org.immobilization = math.max((org.immobilization or 0) - (MODE.ManiacBloodFrenzyImmobilizationRelief or 4) * stacks, 0)
end

function MODE.ApplyManiacPainConversion(ply, harm)
	if not IsValid(ply) or not ply.Ability_ManiacFury_Active then return end

	local org = ply.organism
	if not org then return end

	local amount = math.Clamp(tonumber(harm) or 0, 0, 30)
	if amount <= 0 then return end

	local shock_relief = amount * (MODE.ManiacPainConversionShockRelief or 0.55)
	local pain_relief = amount * (MODE.ManiacPainConversionPainRelief or 0.65)
	org.shock = math.max((org.shock or 0) - shock_relief, 0)
	org.painadd = math.max((org.painadd or 0) - pain_relief, 0)
	org.avgpain = math.max((org.avgpain or 0) - pain_relief * 0.5, 0)
	org.pain = math.max((org.pain or 0) - pain_relief * 0.5, 0)

	local stamina = org.stamina
	if stamina then
		local max_stamina = stamina.max or stamina.range or 0
		if max_stamina > 0 then
			stamina[1] = math.min(max_stamina, (stamina[1] or 0) + amount * (MODE.ManiacPainConversionStaminaPerHarm or 1.3))
		end
	end
end

function MODE.SuppressManiacFlinch(ply)
	if not IsValid(ply) or not ply.Ability_ManiacFury_NoFlinchUntil or ply.Ability_ManiacFury_NoFlinchUntil <= CurTime() then return end

	local org = ply.organism
	if not org then return end

	local now = CurTime()
	if (org.stun or 0) > now then
		org.stun = now
	end

	if (org.lightstun or 0) > now then
		org.lightstun = now
		ply:SetLocalVar("stun", now)
	end

	org.needfake = false
end

function MODE.ApplyManiacSecondWind(ply)
	local org = IsValid(ply) and ply.organism or nil
	if not org then return end

	local stamina = org.stamina
	if stamina then
		local max_stamina = stamina.max or stamina.range or 0
		if max_stamina > 0 then
			stamina[1] = math.max(stamina[1] or 0, max_stamina * MODE.ManiacFurySecondWindStaminaFraction)
		end
	end

	if org.o2 and org.o2[1] then
		org.o2[1] = math.max(org.o2[1], math.min(MODE.ManiacFurySecondWindOxygen, org.o2.range or MODE.ManiacFurySecondWindOxygen))
	end

	org.heartstop = false
	org.shock = math.min(org.shock or 0, MODE.ManiacFurySecondWindPainCap)
	org.avgpain = math.min(org.avgpain or 0, MODE.ManiacFurySecondWindPainCap)
	org.pain = math.min(org.pain or 0, MODE.ManiacFurySecondWindPainCap)
	org.painadd = math.min(org.painadd or 0, MODE.ManiacFurySecondWindPainCap)

	local o2 = org.o2 and org.o2[1] or 30
	local can_stand_back_up = (org.brain or 0) < 0.4 and (org.blood or 5000) >= 2700 and o2 > 5
	if can_stand_back_up then
		org.holdingbreath = false
		org.needotrub = false
		org.otrub = false
		org.uncon_timer = 0
	end
end

function MODE.TryTriggerManiacFury(ply, dmgInfo, harm)
	if not MODE.IsManiacFuryRoundActive() then return end
	if not MODE.CanTriggerManiacFury(ply) then return end

	local damage = dmgInfo and dmgInfo.GetDamage and dmgInfo:GetDamage() or 0
	local serious_harm = math.max(isnumber(harm) and harm or 0, damage)
	if serious_harm < MODE.ManiacFuryHarmThreshold then return end

	MODE.ActivateManiacFury(ply)
end

function MODE.ApplyManiacFury(ply)
	local org = IsValid(ply) and ply.organism or nil
	if not org then return end

	local now = CurTime()
	local delta = math.Clamp(now - (ply.Ability_ManiacFury_LastThink or now), 0, 0.25)
	ply.Ability_ManiacFury_LastThink = now

	org.adrenaline = math.Clamp(org.adrenaline or 0, MODE.ManiacFuryAdrenaline, MODE.ManiacFuryAdrenalineMax)
	org.adrenalineAdd = math.min(org.adrenalineAdd or 0, 0)
	org.analgesia = math.Clamp(org.analgesia or 0, MODE.ManiacFuryAnalgesia, MODE.ManiacFuryAnalgesiaMax)
	org.analgesiaAdd = math.min(org.analgesiaAdd or 0, 0)
	org.heartstop = false

	org.avgpain = math.min(org.avgpain or 0, MODE.ManiacFuryPainCap)
	org.pain = math.min(org.pain or 0, MODE.ManiacFuryPainCap)
	org.painadd = math.min(org.painadd or 0, MODE.ManiacFuryPainCap)
	org.shock = math.min(org.shock or 0, MODE.ManiacFuryPainCap)
	MODE.SuppressManiacFlinch(ply)

	local o2 = org.o2 and org.o2[1] or 30
	local can_override_blackout = (org.brain or 0) < 0.4 and (org.blood or 5000) >= 2700 and o2 > 5
	if can_override_blackout then
		org.needotrub = false
		org.otrub = false
		org.uncon_timer = 0
	end

	local stamina = org.stamina
	if stamina then
		local max_stamina = stamina.max or stamina.range or 0
		if max_stamina > 0 then
			local frenzy_stacks = MODE.GetManiacBloodFrenzyStacks(ply)
			local frenzy_regen = frenzy_stacks * (MODE.ManiacBloodFrenzyStaminaRegenPerStack or 12)
			stamina[1] = math.min(max_stamina, (stamina[1] or max_stamina) + (MODE.ManiacFuryStaminaRegenPerSecond + frenzy_regen) * delta)
		end
	end
end

function MODE.GetCannibalStacks(ply)
	if not IsValid(ply) then return 0 end

	return math.Clamp(ply.Ability_CannibalConsumedBodies or 0, 0, MODE.CannibalMaxConsumedBodies or 6)
end

local function canWitnessCannibalFeast(witness, cannibal, corpse, victim, corpse_pos)
	if not IsValid(witness) or witness == cannibal or witness == victim then return false end
	if not witness:IsPlayer() or not witness:Alive() or not witness.organism or witness.organism.otrub then return false end
	if witness:GetShootPos():DistToSqr(corpse_pos) > (MODE.CannibalWitnessFearRadius or 850) ^ 2 then return false end

	local to_corpse = corpse_pos - witness:EyePos()
	if to_corpse:IsZero() then return false end
	if witness:EyeAngles():Forward():Dot(to_corpse:GetNormalized()) < (MODE.CannibalWitnessViewDot or 0.47) then return false end

	local tr = util.TraceLine({
		start = witness:EyePos(),
		endpos = corpse_pos,
		filter = {witness, cannibal},
		mask = MASK_SHOT
	})

	return not tr.Hit or tr.Entity == corpse or tr.Fraction > 0.98
end

function MODE.PulseCannibalWitnessFear(cannibal, corpse, victim, force)
	if not IsValid(cannibal) or not IsValid(corpse) then return end

	local data = cannibal.Ability_CannibalConsume
	if not force and data and (data.NextWitnessFear or 0) > CurTime() then return end
	if data then
		data.NextWitnessFear = CurTime() + (MODE.CannibalWitnessFearCooldown or 3)
	end

	local corpse_pos = corpse:WorldSpaceCenter()
	for _, witness in player.Iterator() do
		if not canWitnessCannibalFeast(witness, cannibal, corpse, victim, corpse_pos) then continue end

		local org = witness.organism
		org.fearadd = math.min((org.fearadd or 0) + (MODE.CannibalWitnessFearAdd or 0.55), 3)
		org.shock = math.min((org.shock or 0) + (MODE.CannibalWitnessShockAdd or 5), 45)
		witness:ViewPunch(Angle(math.Rand(-4, 4), math.Rand(-5, 5), math.Rand(-5, 5)))

		if isfunction(witness.Notify) then
			witness:Notify("What the hell am I watching?", 5, "cannibal_witness_fear", 0, nil, Color(170, 45, 45))
		end
	end
end

function MODE.ApplyCannibalStacks(ply)
	if not IsValid(ply) or not ply.organism or not MODE.IsCannibalRole or not MODE.IsCannibalRole(ply.SubRole) then return end

	local stamina = ply.organism.stamina
	if not stamina then return end

	local stacks = MODE.GetCannibalStacks(ply)
	local base = ply.Ability_CannibalBaseStaminaRange or stamina.range or 180
	ply.Ability_CannibalBaseStaminaRange = base

	local new_range = base + stacks * (MODE.CannibalStaminaBonusPerBody or 22)
	stamina.range = new_range
	stamina.max = math.max(stamina.max or new_range, new_range)
	stamina[1] = math.min(math.max(stamina[1] or new_range, 0), stamina.max)
	ply:SetNWInt("HMCD_CannibalStacks", stacks)
end

function MODE.ResetCannibal(ply)
	if not IsValid(ply) then return end

	MODE.StopCannibalConsume(ply)
	ply.Ability_CannibalConsumedBodies = nil
	ply.Ability_CannibalBaseStaminaRange = nil
	ply:SetNWInt("HMCD_CannibalStacks", 0)
end

function MODE.StartCannibalConsume(ply, corpse, victim)
	if not IsValid(ply) or not MODE.IsCannibalRole or not MODE.IsCannibalRole(ply.SubRole) then return end
	if ply.Ability_CannibalConsume then return end
	if MODE.GetCannibalStacks(ply) >= (MODE.CannibalMaxConsumedBodies or 6) then
		if isfunction(ply.Notify) then
			ply:Notify("I can't stomach any more.", true, "cannibal_full", 2, nil, Color(170, 45, 45))
		else
			ply:ChatPrint("I can't stomach any more.")
		end
		return
	end

	if not IsValid(corpse) or not IsValid(victim) then return end
	if corpse.HMCDCannibalConsumed or (corpse.GetNWBool and corpse:GetNWBool("HMCD_CannibalConsumed", false)) then return end
	if victim == ply or not MODE.IsCannibalConsumableVictim or not MODE.IsCannibalConsumableVictim(victim, corpse) then return end

	local now = CurTime()
	ply.Ability_CannibalConsume = {
		Corpse = corpse,
		Victim = victim,
		StartedAt = now,
		ReadyAt = now + (MODE.GetCannibalConsumeTime and MODE.GetCannibalConsumeTime(ply) or MODE.CannibalConsumeTime or 4.5)
	}

	ply:SetNWEntity("HMCD_CannibalConsumeCorpse", corpse)
	ply:SetNWFloat("HMCD_CannibalConsumeStart", now)
	ply:SetNWFloat("HMCD_CannibalConsumeReadyAt", ply.Ability_CannibalConsume.ReadyAt)

	local eating_sound = CreateSound(corpse, cannibal_eating_sound)
	if eating_sound then
		eating_sound:PlayEx(cannibal_eating_volume, math.random(cannibal_eating_pitch_min, cannibal_eating_pitch_max))
		ply.Ability_CannibalConsume.EatingSound = eating_sound
	end

	MODE.PulseCannibalWitnessFear(ply, corpse, victim, true)
end

local function spawnCannibalBodyGibs(corpse, center, force)
	if not IsValid(corpse) then return end

	local base_velocity = corpse:GetVelocity()
	for i, model in ipairs(cannibal_body_gib_models) do
		local ent = ents.Create("prop_physics")
		if not IsValid(ent) then continue end

		local offset = VectorRand(-18, 18)
		offset.z = math.Rand(4, 20)

		ent:SetModel(model)
		ent:SetPos(center + offset)
		ent:SetAngles(AngleRand(-180, 180))
		ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		ent:DrawShadow(false)
		ent.HMCDCannibalBodyGib = true
		ent:Spawn()
		ent:Activate()

		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then
			local side_force = VectorRand(-90, 90)
			side_force.z = math.Rand(70, 180)
			phys:SetVelocity(base_velocity + side_force + (force or vector_origin) / 12)
			phys:AddAngleVelocity(VectorRand(-220, 220))
		end
	end
end

function MODE.SplatCannibalCorpse(ply, corpse, victim)
	if not IsValid(corpse) or not corpse:IsRagdoll() then return end

	corpse.HMCDCannibalConsumed = true
	if corpse.SetNWBool then
		corpse:SetNWBool("HMCD_CannibalConsumed", true)
	end

	local center = corpse:WorldSpaceCenter()
	local force = VectorRand(-250, 250) + Vector(0, 0, 450)

	sound.Play("physics/body/body_medium_break3.wav", center, 78, math.random(85, 100), 1)
	for i = 1, 7 do
		local offset = VectorRand(-22, 22)
		util.Decal("Blood", center + offset + Vector(0, 0, 30), center + offset - Vector(0, 0, 70), corpse)
	end

	if util and util.Effect then
		local effect = EffectData()
		effect:SetOrigin(center)
		effect:SetNormal(VectorRand():GetNormalized())
		effect:SetScale(16)
		util.Effect("BloodImpact", effect, true, true)
	end

	if SpawnMeatGore then
		SpawnMeatGore(corpse, center + Vector(0, 0, 14), 14, force, 0.85)
		SpawnMeatGore(corpse, center - Vector(0, 0, 8), 8, force * 0.65, 0.7)
	end
	spawnCannibalBodyGibs(corpse, center, force)

	local gib_bones = {
		"ValveBiped.Bip01_Head1",
		"ValveBiped.Bip01_Spine2",
		"ValveBiped.Bip01_L_UpperArm",
		"ValveBiped.Bip01_R_UpperArm",
		"ValveBiped.Bip01_L_Thigh",
		"ValveBiped.Bip01_R_Thigh"
	}

	for _, bone_name in ipairs(gib_bones) do
		local bone = corpse:LookupBone(bone_name)
		if not bone then continue end

		if Gib_Input and bone_name == "ValveBiped.Bip01_Head1" then
			Gib_Input(corpse, bone, force)
		elseif Gib_RemoveBone then
			local phys_bone = corpse:TranslateBoneToPhysBone(bone)
			if phys_bone and phys_bone >= 0 then
				Gib_RemoveBone(corpse, bone, phys_bone)
			else
				corpse:ManipulateBoneScale(bone, vector_origin)
			end
		else
			corpse:ManipulateBoneScale(bone, vector_origin)
		end
	end

	corpse:SetNoDraw(true)
	corpse:SetNotSolid(true)
	corpse:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	SafeRemoveEntityDelayed(corpse, 0.2)
end

function MODE.StopCannibalConsume(ply)
	if not IsValid(ply) then return end

	stopCannibalEatingSound(ply, true)

	ply.Ability_CannibalConsume = nil
	ply:SetNWEntity("HMCD_CannibalConsumeCorpse", NULL)
	ply:SetNWFloat("HMCD_CannibalConsumeStart", 0)
	ply:SetNWFloat("HMCD_CannibalConsumeReadyAt", 0)
end

function MODE.FinishCannibalConsume(ply, corpse, victim)
	if not IsValid(ply) or not IsValid(corpse) or not IsValid(victim) then return end
	if corpse.HMCDCannibalConsumed or (corpse.GetNWBool and corpse:GetNWBool("HMCD_CannibalConsumed", false)) then return end
	if victim == ply or not MODE.IsCannibalConsumableVictim or not MODE.IsCannibalConsumableVictim(victim, corpse) then return end

	corpse.HMCDCannibalConsumed = true
	if corpse.SetNWBool then
		corpse:SetNWBool("HMCD_CannibalConsumed", true)
	end

	local max_health = math.max(ply:GetMaxHealth(), 100)
	ply:SetHealth(math.min(max_health, ply:Health() + (MODE.CannibalHealthRestore or 30)))

	local org = ply.organism
	if org then
		org.blood = math.min(5000, (org.blood or 5000) + (MODE.CannibalBloodRestore or 900))
		org.shock = math.max((org.shock or 0) - 15, 0)
		org.avgpain = math.max((org.avgpain or 0) - 10, 0)
		org.pain = math.max((org.pain or 0) - 10, 0)
	end

	ply.Ability_CannibalConsumedBodies = math.min(MODE.GetCannibalStacks(ply) + 1, MODE.CannibalMaxConsumedBodies or 6)
	MODE.ApplyCannibalStacks(ply)

	local pos = corpse:WorldSpaceCenter()
	sound.Play("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", pos, 65, math.random(75, 90), 0.85)

	if victim:Alive() then
		victim.HMCD_CannibalConsumedBy = ply
		victim:Kill()
		timer.Simple(0.08, function()
			if not IsValid(victim) then return end

			local death_rag = victim:GetNWEntity("RagdollDeath", NULL)
			if not IsValid(death_rag) then
				death_rag = IsValid(victim.RagdollDeath) and victim.RagdollDeath or nil
			end
			if not IsValid(death_rag) then
				death_rag = IsValid(corpse) and corpse or nil
			end
			if IsValid(death_rag) then
				MODE.SplatCannibalCorpse(ply, death_rag, victim)
			end
		end)
	else
		MODE.SplatCannibalCorpse(ply, corpse, victim)
	end

	local stacks = MODE.GetCannibalStacks(ply)
	local msg = "Consumed. Strength growing. (" .. stacks .. "/" .. (MODE.CannibalMaxConsumedBodies or 6) .. ")"
	if isfunction(ply.Notify) then
		ply:Notify(msg, 0, "cannibal_consume_" .. stacks, 0, nil, Color(170, 45, 45))
	else
		ply:ChatPrint(msg)
	end
end

function MODE.ContinueCannibalConsume(ply)
	local data = IsValid(ply) and ply.Ability_CannibalConsume or nil
	if not data then return end

	local corpse = data.Corpse
	local victim = data.Victim
	if not IsValid(corpse) or not IsValid(victim) or not MODE.IsCannibalConsumableVictim or not MODE.IsCannibalConsumableVictim(victim, corpse) then
		MODE.StopCannibalConsume(ply)
		return
	end

	if corpse.HMCDCannibalConsumed or (corpse.GetNWBool and corpse:GetNWBool("HMCD_CannibalConsumed", false)) then
		MODE.StopCannibalConsume(ply)
		return
	end

	if ply:GetShootPos():DistToSqr(corpse:WorldSpaceCenter()) > ((MODE.CannibalConsumeReach or 95) + 35) ^ 2 then
		MODE.StopCannibalConsume(ply)
		return
	end

	if CurTime() < (data.NextSound or 0) then
		-- no-op
	else
		data.NextSound = CurTime() + 0.9
		if not data.EatingSound then
			local eating_sound = CreateSound(corpse, cannibal_eating_sound)
			if eating_sound then
				eating_sound:PlayEx(cannibal_eating_volume, math.random(cannibal_eating_pitch_min, cannibal_eating_pitch_max))
				data.EatingSound = eating_sound
			end
		end
	end
	MODE.PulseCannibalWitnessFear(ply, corpse, victim)

	if CurTime() < (data.ReadyAt or 0) then return end

	MODE.FinishCannibalConsume(ply, corpse, victim)
	MODE.StopCannibalConsume(ply)
end

function MODE.UpdateJuggernautCarryState(ply)
	local carried, victim = MODE.GetJuggernautCarryTarget(ply)
	local old_carried = ply.Ability_JuggernautCarriedEnt

	if IsValid(old_carried) and old_carried ~= carried then
		old_carried.HMCD_JuggernautCarryExpire = CurTime() + 0.75
	end

	if IsValid(carried) and IsValid(victim) then
		ply.Ability_JuggernautCarriedEnt = carried
		carried.HMCD_JuggernautCarrier = ply
		carried.HMCD_JuggernautCarryVictim = victim
		carried.HMCD_JuggernautCarryExpire = CurTime() + 0.75
	elseif not IsValid(carried) then
		ply.Ability_JuggernautCarriedEnt = nil
	end
end

function MODE.StartJuggernautStrangle(ply, carried, victim)
	if not IsValid(ply) or not IsValid(carried) or not IsValid(victim) then return end

	local now = CurTime()
	local duration = MODE.JuggernautStrangleTime or 4.25
	ply.Ability_JuggernautStrangle = {
		CarryEnt = carried,
		Victim = victim,
		StartedAt = now,
		ReadyAt = now + duration,
		NextSound = now,
	}

	victim.BeingVictimOfNeckBreak = true
	if victim.organism then
		victim.organism.neckBrainOxygenPenalty = 1
	end

	ply:SetNWFloat("HMCD_JuggernautStrangleStart", now)
	ply:SetNWFloat("HMCD_JuggernautStrangleReadyAt", now + duration)
	ply:SetNWEntity("HMCD_JuggernautStrangleVictim", victim)

	net.Start("HMCD_BeingVictimOfNeckBreak")
		net.WriteBool(true)
	net.Send(victim)

	ply:EmitSound("Flesh.ImpactSoft", 55, math.random(82, 95), 0.55)
end

function MODE.StopJuggernautStrangle(ply)
	if not IsValid(ply) then return end

	local data = ply.Ability_JuggernautStrangle
	if data and IsValid(data.Victim) then
		data.Victim.BeingVictimOfNeckBreak = false
		if data.Victim.organism then
			data.Victim.organism.neckBrainOxygenPenalty = 0
		end

		net.Start("HMCD_BeingVictimOfNeckBreak")
			net.WriteBool(false)
		net.Send(data.Victim)
	end

	ply.Ability_JuggernautStrangle = nil
	ply:SetNWFloat("HMCD_JuggernautStrangleStart", 0)
	ply:SetNWFloat("HMCD_JuggernautStrangleReadyAt", 0)
	ply:SetNWEntity("HMCD_JuggernautStrangleVictim", NULL)
end

function MODE.ResetJuggernaut(ply, force_clear_scale)
	if not IsValid(ply) then return end

	MODE.StopJuggernautStrangle(ply)
	if IsValid(ply.Ability_JuggernautCarriedEnt) then
		ply.Ability_JuggernautCarriedEnt.HMCD_JuggernautCarryExpire = CurTime() + 0.75
	end
	ply.Ability_JuggernautCarriedEnt = nil

	if force_clear_scale or not MODE.IsJuggernautRole or not MODE.IsJuggernautRole(ply.SubRole) then
		ply.HMCDTraitorRoleModelScale = nil
		if ply.HMCDJuggernautStatsApplied then
			ply.HMCDJuggernautStatsApplied = nil
			ply.MeleeDamageMul = nil
			ply.StaminaExhaustMul = nil
			ply.JumpPowerMul = nil
			if ply.organism then
				ply.organism.legstrength = 1
			end
		end

		if hg and hg.ApplyPlayerModelScale then
			hg.ApplyPlayerModelScale(ply)
		elseif ply.SetModelScale then
			ply:SetModelScale(1, 0)
		end
	end
end

function MODE.FinishJuggernautStrangle(ply, victim, carried)
	if not IsValid(ply) or not IsValid(victim) or not victim:Alive() then return end

	if IsValid(carried) then
		carried:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", 70, math.random(78, 92), 1)
	end

	local blackout_until = CurTime() + (MODE.JuggernautStrangleBlackoutTime or 12)
	victim.HMCD_JuggernautBlackoutUntil = math.max(victim.HMCD_JuggernautBlackoutUntil or 0, blackout_until)

	local org = victim.organism
	if org then
		org.neckBrainOxygenPenalty = 1
		org.brainoxygen = math.min(org.brainoxygen or 1, MODE.JuggernautStrangleMinBrainOxygen or 0.12)
		org.hypoxiaTime = math.max(org.hypoxiaTime or 0, 20)
		org.severeHypoxiaTime = math.max(org.severeHypoxiaTime or 0, 8)
		org.consciousness = math.min(org.consciousness or 1, 0.05)
		org.needotrub = true
		org.needfake = true
		org.otrub = true
		org.fake = true
		org.stun = math.max(org.stun or 0, CurTime() + (MODE.JuggernautStrangleFinishStunTime or 7))
	end

	if hg and hg.Fake then
		hg.Fake(victim, nil, true, true)
	end
end

function MODE.ContinueJuggernautStrangle(ply)
	local data = IsValid(ply) and ply.Ability_JuggernautStrangle or nil
	if not data then return end

	local can_continue, carried, victim = MODE.CanJuggernautStrangle(ply)
	if not can_continue or victim ~= data.Victim or carried ~= data.CarryEnt then
		MODE.StopJuggernautStrangle(ply)
		return
	end

	local org = victim.organism
	if org then
		local progress = math.Clamp((CurTime() - (data.StartedAt or CurTime())) / math.max((data.ReadyAt or CurTime()) - (data.StartedAt or CurTime()), 0.1), 0, 1)
		local brain_target = Lerp(progress, 0.55, MODE.JuggernautStrangleMinBrainOxygen or 0.12)
		local consciousness_target = Lerp(progress, 0.8, MODE.JuggernautStrangleMinConsciousness or 0.2)

		org.neckBrainOxygenPenalty = 1
		org.brainoxygen = math.min(org.brainoxygen or 1, brain_target)
		org.consciousness = math.min(org.consciousness or 1, consciousness_target)
		org.hypoxiaTime = math.max(org.hypoxiaTime or 0, progress * 14)
		org.severeHypoxiaTime = math.max(org.severeHypoxiaTime or 0, progress * 5)
	end

	if CurTime() >= (data.NextSound or 0) then
		data.NextSound = CurTime() + 0.85
		carried:EmitSound("player/pl_pain" .. math.random(5, 7) .. ".wav", 55, math.random(82, 96), 0.35)
	end

	if CurTime() < (data.ReadyAt or 0) then return end

	MODE.FinishJuggernautStrangle(ply, victim, carried)
	MODE.StopJuggernautStrangle(ply)
end

function MODE.FinishJuggernautStomp(ply, rag, victim)
	if not IsValid(ply) or not IsValid(rag) or not IsValid(victim) or not victim:Alive() then return end
	if not MODE.IsJuggernautRole or not MODE.IsJuggernautRole(ply.SubRole) then return end
	if not victim.organism or victim.organism.otrub ~= true then return end
	if ply:GetShootPos():DistToSqr(rag:WorldSpaceCenter()) > ((MODE.JuggernautStompReach or 105) + 45) ^ 2 then return end
	local owner = hg and hg.RagdollOwner and hg.RagdollOwner(rag) or nil
	if IsValid(owner) and owner ~= victim then return end
	if not IsValid(owner) and victim.FakeRagdoll ~= rag and victim:GetNWEntity("FakeRagdoll", NULL) ~= rag then return end

	local now = CurTime()
	if (victim.HMCD_JuggernautStompFinalizing or 0) > now or (rag.HMCD_JuggernautStompFinalizing or 0) > now then return end
	victim.HMCD_JuggernautStompFinalizing = now + 2
	rag.HMCD_JuggernautStompFinalizing = now + 2

	victim.FakeRagdoll = rag
	victim:SetNWEntity("FakeRagdoll", rag)
	victim:SetNWEntity("RagdollDeath", rag)
	victim.RagdollDeath = rag
	rag.ply = victim
	rag:SetNWEntity("ply", victim)

	local head = rag:LookupBone("ValveBiped.Bip01_Head1")
	local head_pos = head and rag:GetBonePosition(head) or rag:WorldSpaceCenter()
	local force = Vector(0, 0, -900) + ply:GetAimVector() * 180

	local phys_bone = head and rag:TranslateBoneToPhysBone(head) or -1
	local phys = phys_bone and phys_bone >= 0 and rag:GetPhysicsObjectNum(phys_bone) or rag:GetPhysicsObject()
	if IsValid(phys) then
		phys:ApplyForceOffset(force * math.max(phys:GetMass(), 1) * 3, head_pos)
		phys:Wake()
	end

	if victim.organism then
		victim.organism.brain = 1
		victim.organism.skull = 1
		victim.organism.neck = 1
	end

	rag:EmitSound("physics/body/body_medium_break3.wav", 80, math.random(82, 95), 1)
	rag:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", 78, math.random(75, 90), 1)

	if util and util.Effect then
		local effect = EffectData()
		effect:SetOrigin(head_pos)
		effect:SetNormal(Vector(0, 0, 1))
		effect:SetScale(12)
		util.Effect("BloodImpact", effect, true, true)
	end

	util.Decal("Blood", head_pos + Vector(0, 0, 12), head_pos - Vector(0, 0, 38), rag)

	if head then
		if Gib_Input then
			Gib_Input(rag, head, force)
		elseif Gib_RemoveBone and phys_bone and phys_bone >= 0 then
			Gib_RemoveBone(rag, head, phys_bone)
		elseif phys_bone and phys_bone >= 0 then
			rag:RemoveInternalConstraint(phys_bone)
			rag:ManipulateBoneScale(head, vector_origin)
		end
	end

	if zb and zb.HarmDone then
		local harm = math.max(tonumber(zb.MaximumHarm) or 100, 100)
		zb.HarmDone[victim] = zb.HarmDone[victim] or {}
		zb.HarmDone[victim][ply] = math.max(zb.HarmDone[victim][ply] or 0, harm)
		zb.HarmDoneKarma = zb.HarmDoneKarma or {}
		zb.HarmDoneKarma[victim] = zb.HarmDoneKarma[victim] or {}
		zb.HarmDoneKarma[victim][ply] = 0
		zb.HarmDoneDetailed = zb.HarmDoneDetailed or {}
		local victim_id = victim:SteamID()
		local attacker_id = ply:SteamID()
		zb.HarmDoneDetailed[victim_id] = zb.HarmDoneDetailed[victim_id] or {}
		zb.HarmDoneDetailed[victim_id][attacker_id] = {
			harm = harm,
			amt = 1,
			teamVictim = victim:Team(),
			teamAttacker = ply:Team(),
			lasthitgroup = HITGROUP_HEAD,
			lastdmgtype = DMG_CRUSH,
			lastsource = "juggernaut_stomp",
			lastattacked = CurTime(),
		}
		zb.HarmAttacked[ply] = (zb.HarmAttacked[ply] or 0) + harm
		hook.Run("HarmDone", ply, victim, harm)
	end

	victim:Kill()
end

function MODE.StartJuggernautStomp(ply, rag, victim)
	if not IsValid(ply) or not IsValid(rag) or not IsValid(victim) then return end
	if (ply.Ability_JuggernautNextStomp or 0) > CurTime() then return end
	if ply:GetNWFloat("InLegKick", 0) > CurTime() then return end
	if not ply:IsOnGround() or ply:IsSprinting() then return end
	local current_char = hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply)
	if IsValid(current_char) and current_char:IsRagdoll() then return end
	if ply:EyeAngles()[1] < (MODE.JuggernautStompMinPitch or 58) then return end

	ply.Ability_JuggernautNextStomp = CurTime() + (MODE.JuggernautStompCooldown or 1.35)
	if ply.LegAttack then
		ply:LegAttack()
	else
		ply:DoAnimationEvent(ACT_GMOD_GESTURE_MELEE_SHOVE_2HAND)
	end

	timer.Simple(0.33, function()
		if not IsValid(ply) or not IsValid(rag) or not IsValid(victim) then return end
		MODE.FinishJuggernautStomp(ply, rag, victim)
	end)
end

--\\Chemical resistance
	function MODE.NetworkChemicalResistanceOfPlayer(ply)
		ply.PassiveAbility_ChemicalAccumulation = ply.PassiveAbility_ChemicalAccumulation or {}
		
		net.Start("HMCD_UpdateChemicalResistance")
		
		for chemical_name, amt in pairs(ply.PassiveAbility_ChemicalAccumulation) do
			net.WriteString(chemical_name)
			net.WriteUInt(math.Round(amt), MODE.NetSize_ChemicalResistanceBits)
		end
		
		net.WriteString("")
		net.Send(ply)
	end
--//

hook.Add("PlayerPostThink", "HMCD_SubRoles_Abilities", function(ply)
	if(MODE.RoleChooseRoundTypes[MODE.Type])then
		if(ply:Alive() and ply.organism and not ply.organism.otrub)then
			if(MODE.IsShadowRole(ply.SubRole))then
				local current_char = hg.GetCurrentCharacter(ply)
				local is_upright = current_char == ply and not IsValid(ply.FakeRagdoll)
				local is_still = ply:IsOnGround() and ply:GetVelocity():Length2DSqr() <= (MODE.ShadowCamouflageMoveSpeed * MODE.ShadowCamouflageMoveSpeed)
				local near_wall = is_upright and is_still and not ply:InVehicle() and MODE.IsPlayerNearWallForShadowCamouflage(ply)
				local now = CurTime()

				if(near_wall)then
					ply.Ability_ShadowCamouflage_LastNearWall = now
				end

				local grace_active = ply.Ability_ShadowCamouflage_LastNearWall and (now - ply.Ability_ShadowCamouflage_LastNearWall) <= MODE.ShadowCamouflageGraceTime

				if(near_wall or grace_active)then
					local charge_start = ply.Ability_ShadowCamouflage_ChargeStart

					if(not charge_start)then
						charge_start = now
						ply.Ability_ShadowCamouflage_ChargeStart = charge_start

						ply:SetNWFloat("HMCD_ShadowCamouflageChargeStart", charge_start)
						ply:SetNWFloat("HMCD_ShadowCamouflageReadyAt", charge_start + MODE.ShadowCamouflageChargeTime)
					elseif(ply:KeyPressed(IN_RELOAD))then
						if(ply.Ability_ShadowCamouflage_Active)then
							MODE.ResetShadowCamouflage(ply)
						elseif(charge_start + MODE.ShadowCamouflageChargeTime <= now)then
							MODE.SetShadowCamouflageActive(ply, true)
						end
					end
				elseif(ply.Ability_ShadowCamouflage_ChargeStart or ply.Ability_ShadowCamouflage_Active)then
					MODE.ResetShadowCamouflage(ply)
				end
			elseif(ply.Ability_ShadowCamouflage_ChargeStart or ply.Ability_ShadowCamouflage_Active)then
				MODE.ResetShadowCamouflage(ply)
			end

			if(ply.SubRole == "traitor_infiltrator" or ply.SubRole == "traitor_infiltrator_soe")then
				if(ply:KeyDown(IN_WALK))then
					if(ply:KeyPressed(IN_RELOAD))then
						local aim_ent, other_ply = hg.eyeTrace(ply,85).Entity
						other_ply = hg.RagdollOwner(aim_ent) or aim_ent
						
						if(IsValid(aim_ent) and aim_ent:IsRagdoll())then	--; REDO
							local other_appearance = aim_ent.CurAppearance
							local your_appearance = ply.CurAppearance

							local aMdl1,aMdl2 = your_appearance.AModel,other_appearance.AModel
							
							other_appearance.AModel = aMdl1
							your_appearance.AModel = aMdl2

							local aFace1,aFace2 = your_appearance.AFacemaps,other_appearance.AFacemaps

							other_appearance.AFacemaps = aFace1
							your_appearance.AFacemaps = aFace2

							hg.Appearance.ForceApplyAppearance(ply, other_appearance, true)
							local char = hg.GetCurrentCharacter(ply)
							if char:IsRagdoll() then
								hg.Appearance.ForceApplyAppearance(char, other_appearance, true)
							end
							ply:EmitSound("snd_jack_hmcd_disguise.wav",35,math.random(90,110),0.5)

							--local duplicator_data = duplicator.CopyEntTable(ply)
							--duplicator.DoGeneric(aim_ent, duplicator_data)
							aim_ent.CurAppearance = your_appearance

							hg.Appearance.ForceApplyAppearance(aim_ent, your_appearance, true)
							
							if other_ply:IsPlayer() and other_ply:Alive() then
								hg.Appearance.ForceApplyAppearance(other_ply, your_appearance, true)
							end
						end
					end
					
					if(ply:KeyPressed(IN_USE))then
						local action = MODE.GetNeckBreakAction(ply)
						if(action == "saw_head")then
							local _, aim_ent, other_ply = MODE.GetFiberwireSawTarget(ply)
							if(IsValid(other_ply) and MODE.CanPlayerSawHeadWithFiberwire(ply, aim_ent, other_ply))then
								MODE.StartBreakingOtherNeck(ply, other_ply, action)
							end
						else
							local aim_ent, other_ply = MODE.GetPlayerTraceToOther(ply)
							
							if(IsValid(aim_ent))then
								if(other_ply and MODE.CanPlayerBreakOtherNeck(ply, aim_ent))then
									MODE.StartBreakingOtherNeck(ply, other_ply, action)
								end
							end
						end
					elseif(ply:KeyDown(IN_USE))then
						if(ply.Ability_NeckBreak)then
							MODE.ContinueBreakingOtherNeck(ply)
						end
					end
					
					if(ply:KeyReleased(IN_USE))then
						MODE.StopBreakingOtherNeck(ply)
					end
				else
					MODE.StopBreakingOtherNeck(ply)
				end
			end
			
			if(MODE.IsAssassinRole and MODE.IsAssassinRole(ply.SubRole))then
				if(ply:KeyDown(IN_WALK))then
					if(ply:KeyPressed(IN_USE))then
						local aim_ent, other_ply, trace = MODE.GetPlayerTraceToOther(ply, nil, MODE.DisarmReach)
						
						if(IsValid(aim_ent))then
							if(other_ply and MODE.CanPlayerDisarmOther(ply, aim_ent, MODE.DisarmReach) and MODE.CanPlayerDisarmOtherPly(ply, other_ply, MODE.DisarmReach))then
								MODE.StartDisarmingOther(ply, other_ply)
							end
						end
					elseif(ply:KeyDown(IN_USE))then
						if(ply.Ability_Disarm)then
							MODE.ContinueDisarmingOther(ply)
						end
					end
					
					if(ply:KeyReleased(IN_USE))then
						MODE.StopDisarmingOther(ply)
					end
				else
					MODE.StopDisarmingOther(ply)
				end
			end
			
			if(ply.SubRole == "traitor_zombie")then
				if(ply:KeyDown(IN_WALK))then
					
				end
			end

			if(MODE.IsChemistRole and MODE.IsChemistRole(ply.SubRole))then
				DegradeChemicalsOfPlayer(ply)
				
				if(!ply.PassiveAbility_ChemicalAccumulation_NextNetworkTime or ply.PassiveAbility_ChemicalAccumulation_NextNetworkTime <= CurTime())then
					MODE.NetworkChemicalResistanceOfPlayer(ply)

					ply.PassiveAbility_ChemicalAccumulation_NextNetworkTime = CurTime() + 1
				end
			end

			if(MODE.IsManiacRole(ply.SubRole))then
				if(ply.Ability_ManiacFury_Active)then
					MODE.ApplyManiacFury(ply)
				end
			elseif(ply.Ability_ManiacFury_Active or ply.Ability_ManiacFury_Triggered)then
				MODE.ResetManiacFury(ply)
			end

			if(MODE.IsStalkerRole and MODE.IsStalkerRole(ply.SubRole))then
				MODE.UpdateStalkerTracking(ply)
				MODE.UpdateStalkerPursuit(ply)

				if((ply.Ability_StalkerNextSenseSync or 0) <= CurTime())then
					MODE.SyncStalkerMarks(ply)
					ply.Ability_StalkerNextSenseSync = CurTime() + 1
				end
			elseif(ply.Ability_StalkerMarks or IsValid(ply.Ability_StalkerGazeTarget) or IsValid(ply.Ability_StalkerPursuitTarget) or ply:GetNWBool("HMCD_StalkerPursuitActive", false))then
				MODE.ResetStalkerTracking(ply)
			end

			if(MODE.IsCannibalRole and MODE.IsCannibalRole(ply.SubRole))then
				MODE.ApplyCannibalStacks(ply)

				if(ply:KeyDown(IN_WALK))then
					if(ply:KeyPressed(IN_USE))then
						local corpse, victim = MODE.GetCannibalConsumeTarget(ply)
						if(IsValid(corpse) and IsValid(victim))then
							MODE.StartCannibalConsume(ply, corpse, victim)
						end
					elseif(ply:KeyDown(IN_USE))then
						MODE.ContinueCannibalConsume(ply)
					end

					if(ply:KeyReleased(IN_USE))then
						MODE.StopCannibalConsume(ply)
					end
				else
					MODE.StopCannibalConsume(ply)
				end
			elseif(ply.Ability_CannibalConsume or (ply:GetNWInt("HMCD_CannibalStacks", 0) > 0))then
				MODE.ResetCannibal(ply)
			end

			if(MODE.IsJuggernautRole and MODE.IsJuggernautRole(ply.SubRole))then
				MODE.UpdateJuggernautCarryState(ply)

				local can_strangle, carried, victim = MODE.CanJuggernautStrangle(ply)
				if(can_strangle and ply:KeyDown(IN_WALK))then
					if(not ply.Ability_JuggernautStrangle)then
						MODE.StartJuggernautStrangle(ply, carried, victim)
					end

					MODE.ContinueJuggernautStrangle(ply)
				else
					MODE.StopJuggernautStrangle(ply)
				end

				if((not can_strangle) and ply:KeyDown(IN_WALK) and ply:KeyPressed(IN_USE))then
					local rag, stomp_victim = MODE.GetJuggernautStompTarget(ply)
					if(IsValid(rag) and IsValid(stomp_victim))then
						MODE.StartJuggernautStomp(ply, rag, stomp_victim)
					end
				end
			elseif(ply.Ability_JuggernautStrangle or IsValid(ply.Ability_JuggernautCarriedEnt))then
				MODE.ResetJuggernaut(ply)
			end
		else
			if(ply.Ability_ShadowCamouflage_ChargeStart or ply.Ability_ShadowCamouflage_Active)then
				MODE.ResetShadowCamouflage(ply)
			end

			if(ply.Ability_StalkerMarks or IsValid(ply.Ability_StalkerGazeTarget) or IsValid(ply.Ability_StalkerPursuitTarget) or ply:GetNWBool("HMCD_StalkerPursuitActive", false))then
				MODE.ResetStalkerTracking(ply)
			end

			if(ply.Ability_CannibalConsume)then
				MODE.StopCannibalConsume(ply)
			end

			if(ply.Ability_JuggernautStrangle)then
				MODE.ResetJuggernaut(ply)
			end
		end
	end
end)

hook.Add("Ragdoll Collide", "HMCD_SubRoles_JuggernautOverpowerImpact", function(rag, data)
	if not IsValid(rag) or not data then return end
	if (rag.HMCD_JuggernautCarryExpire or 0) < CurTime() then return end
	if (rag.HMCD_JuggernautNextImpact or 0) > CurTime() then return end

	local attacker = rag.HMCD_JuggernautCarrier
	local victim = rag.HMCD_JuggernautCarryVictim or (hg and hg.RagdollOwner and hg.RagdollOwner(rag))
	if not IsValid(attacker) or not MODE.IsJuggernautRole(attacker.SubRole) then return end
	if not IsValid(victim) or not victim:IsPlayer() or not victim:Alive() then return end
	if not MODE.IsJuggernautVictimSmallEnough(attacker, victim) then return end

	local speed = math.max(data.Speed or 0, data.OurOldVelocity and data.OurOldVelocity:Length() or 0)
	if speed < (MODE.JuggernautImpactMinSpeed or 340) then return end

	local hit = data.HitEntity
	if IsValid(hit) and hit:IsPlayer() then return end

	rag.HMCD_JuggernautNextImpact = CurTime() + (MODE.JuggernautImpactCooldown or 1.25)

	timer.Simple(0, function()
		if not IsValid(attacker) or not IsValid(victim) or not victim:Alive() then return end

		local dmg = DamageInfo()
		dmg:SetAttacker(attacker)
		dmg:SetInflictor(IsValid(rag) and rag or attacker)
		dmg:SetDamage(MODE.JuggernautImpactDamage or 18)
		dmg:SetDamageType(DMG_CLUB)
		dmg:SetDamagePosition(data.HitPos or victim:WorldSpaceCenter())
		dmg:SetDamageForce((data.OurOldVelocity or attacker:GetAimVector() * speed) * 0.65)
		victim:TakeDamageInfo(dmg)

		if hg and hg.LightStunPlayer then
			hg.LightStunPlayer(victim, MODE.JuggernautImpactStunTime or 1.4)
		end
	end)
end)

hook.Add("HomigradDamage", "HMCD_SubRoles_ManiacFuryTrigger", function(victim, dmgInfo, hitgroup, ent, harm)
	local ply = IsValid(victim) and victim or ent
	ply = hg.RagdollOwner and (hg.RagdollOwner(ply) or ply) or ply

	MODE.TryTriggerManiacFury(ply, dmgInfo, harm)
	MODE.ApplyManiacPainConversion(ply, harm)
	MODE.SuppressManiacFlinch(ply)
	if IsValid(ply) and ply.Ability_ManiacFury_NoFlinchUntil and ply.Ability_ManiacFury_NoFlinchUntil > CurTime() then
		timer.Simple(0, function()
			if IsValid(ply) then
				MODE.SuppressManiacFlinch(ply)
			end
		end)
	end

	local attacker = dmgInfo and dmgInfo:GetAttacker()
	attacker = normalizeStalkerAttacker(attacker)
	if not IsValid(attacker) or attacker == ply or not MODE.IsManiacRole(attacker.SubRole) or not attacker.Ability_ManiacFury_Active then return end
	if not dmgInfo or not dmgInfo.IsDamageType then return end

	local melee_damage = dmgInfo:IsDamageType(DMG_CLUB) or dmgInfo:IsDamageType(DMG_SLASH)
	if not melee_damage then return end

	MODE.AddManiacBloodFrenzy(attacker, harm)
end)

hook.Add("HG_PlayerFootstep", "HMCD_SubRoles_StalkerSilentPursuit", function(ply, pos, foot, sound, volume, rf)
	if not IsValid(ply) or not ply:GetNWBool("HMCD_StalkerPursuitActive", false) then return end
	if not MODE.IsStalkerRole or not MODE.IsStalkerRole(ply.SubRole) then return end

	EmitSound(sound, pos, ply:EntIndex(), CHAN_AUTO, (volume or 1) * (MODE.StalkerPursuitFootstepVolume or 0.28), 70, nil, math.random(92, 98))

	return true
end)

hook.Add("EntityTakeDamage", "HMCD_SubRoles_ManiacFuryFallTrigger", function(victim, dmgInfo)
	local ply = IsValid(victim) and victim or nil
	ply = hg.RagdollOwner and (hg.RagdollOwner(ply) or ply) or ply

	MODE.TryTriggerManiacFury(ply, dmgInfo)
	if IsValid(ply) and ply.Ability_ManiacFury_Active and dmgInfo then
		if dmgInfo:IsDamageType(DMG_FALL + DMG_CRUSH) then
			MODE.ApplyManiacPainConversion(ply, dmgInfo:GetDamage())
		end

		MODE.SuppressManiacFlinch(ply)
	end

	local attacker = dmgInfo and dmgInfo:GetAttacker()
	attacker = normalizeStalkerAttacker(attacker)
	MODE.TryStalkerFirstHit(attacker, victim, dmgInfo)

	if IsValid(attacker) and MODE.IsCannibalRole and MODE.IsCannibalRole(attacker.SubRole) then
		local stacks = MODE.GetCannibalStacks(attacker)
		if stacks > 0 then
			local inflictor = dmgInfo:GetInflictor()
			local damage_type = dmgInfo:GetDamageType()
			local melee_damage = bit.band(damage_type, DMG_CLUB) ~= 0 or bit.band(damage_type, DMG_SLASH) ~= 0
			local melee_weapon = IsValid(inflictor) and inflictor:IsWeapon() and (inflictor.Base == "weapon_melee" or inflictor:GetClass() == "weapon_hands_sh" or inflictor.DamagePrimary ~= nil)

			if melee_damage and melee_weapon then
				local bonus = 1 + math.min(stacks, MODE.CannibalMaxConsumedBodies or 6) * (MODE.CannibalMeleeDamageBonusPerBody or 0.08)
				dmgInfo:SetDamage(dmgInfo:GetDamage() * bonus)
			end
		end
	end
end)

hook.Add("PlayerSpawn", "HMCD_SubRoles_ShadowCamouflage", function(ply)
	ply.HMCD_JuggernautBlackoutUntil = nil
	MODE.ResetShadowCamouflage(ply)
	MODE.ResetManiacFury(ply)
	MODE.ResetStalkerTracking(ply)
	MODE.StopCannibalConsume(ply)
	MODE.ResetJuggernaut(ply)
end)

hook.Add("PlayerDeath", "HMCD_SubRoles_ShadowCamouflage", function(ply)
	ply.HMCD_JuggernautBlackoutUntil = nil
	MODE.ResetShadowCamouflage(ply)
	MODE.ResetManiacFury(ply)
	MODE.ResetStalkerTracking(ply)
	MODE.StopCannibalConsume(ply)
	MODE.ResetJuggernaut(ply, true)

	for _, stalker in player.Iterator() do
		if IsValid(stalker) and stalker.Ability_StalkerMarks then
			MODE.SyncStalkerMarks(stalker)
		end
	end
end)
