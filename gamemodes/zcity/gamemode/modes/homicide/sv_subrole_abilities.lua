local MODE = MODE

util.AddNetworkString("HMCD_BeingVictimOfNeckBreak")
util.AddNetworkString("HMCD_BreakingOtherNeck")
util.AddNetworkString("HMCD_BeingVictimOfDisarmament")
util.AddNetworkString("HMCD_DisarmingOther")
util.AddNetworkString("HMCD_UpdateChemicalResistance")
util.AddNetworkString("HMCD_StalkerMarks")

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
MODE.ManiacFuryPhrases = MODE.ManiacFuryPhrases or {
	"NOW IT'S MY TURN",
	"TIME TO GO CRAZY",
	"THIS FEELS UNREAL",
	"I CAN'T FEEL A THING",
	"YOU SHOULD HAVE FINISHED ME"
}

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

	net.Start("HMCD_StalkerMarks")
		net.WriteUInt(math.min(#valid_marks, MODE.StalkerMarkMax), 2)
		for i = 1, math.min(#valid_marks, MODE.StalkerMarkMax) do
			net.WriteEntity(valid_marks[i].Target)
			net.WriteBool(not valid_marks[i].StunSpent)
		end
	net.Send(stalker)
end

function MODE.ResetStalkerTracking(stalker)
	if not IsValid(stalker) then return end

	stalker.Ability_StalkerMarks = nil
	stalker.Ability_StalkerGazeTarget = nil
	stalker.Ability_StalkerGazeStartedAt = nil
	stalker:SetNWEntity("HMCD_StalkerGazeTarget", NULL)
	stalker:SetNWFloat("HMCD_StalkerGazeStartedAt", 0)
	stalker:SetNWFloat("HMCD_StalkerGazeReadyAt", 0)

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

function MODE.TryStalkerFirstHit(attacker, victim)
	if not isStalkerRoundActive() then return end
	if not IsValid(attacker) or not MODE.IsStalkerRole or not MODE.IsStalkerRole(attacker.SubRole) then return end

	victim = normalizeStalkerTarget(victim)
	if not MODE.CanStalkerMarkTarget(attacker, victim) then return end

	local marked, mark = MODE.IsStalkerTargetMarked(attacker, victim)
	if not marked or not mark or mark.StunSpent then return end

	mark.StunSpent = true
	if hg.LightStunPlayer then
		hg.LightStunPlayer(victim, MODE.StalkerFirstHitStunTime)
	end

	victim:ViewPunch(Angle(math.Rand(-4, -2), math.Rand(-2, 2), math.Rand(-2, 2)))
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
	ply:SetNWBool("HMCD_ManiacFuryActive", false)
	ply:SetNWFloat("HMCD_ManiacFuryStartedAt", 0)
end

function MODE.ActivateManiacFury(ply)
	if not IsValid(ply) or ply.Ability_ManiacFury_Triggered then return end

	local now = CurTime()
	ply.Ability_ManiacFury_Triggered = true
	ply.Ability_ManiacFury_Active = true
	ply.Ability_ManiacFury_LastThink = now
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

	ply:EmitSound("player/breathe1.wav", 75, 75, 0.8)
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
			stamina[1] = math.min(max_stamina, (stamina[1] or max_stamina) + MODE.ManiacFuryStaminaRegenPerSecond * delta)
		end
	end
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
					elseif(not ply.Ability_ShadowCamouflage_Active and charge_start + MODE.ShadowCamouflageChargeTime <= now)then
						MODE.SetShadowCamouflageActive(ply, true)
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
						local aim_ent, other_ply = MODE.GetPlayerTraceToOther(ply)
						
						if(IsValid(aim_ent))then
							local action = MODE.GetNeckBreakAction(ply)
							local can_start
							if(action == "saw_head")then
								can_start = MODE.CanPlayerSawHeadWithFiberwire(ply, aim_ent, other_ply)
							else
								can_start = MODE.CanPlayerBreakOtherNeck(ply, aim_ent)
							end

							if(other_ply and can_start)then
								MODE.StartBreakingOtherNeck(ply, other_ply, action)
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
			elseif(ply.Ability_StalkerMarks or IsValid(ply.Ability_StalkerGazeTarget))then
				MODE.ResetStalkerTracking(ply)
			end
		elseif(ply.Ability_ShadowCamouflage_ChargeStart or ply.Ability_ShadowCamouflage_Active)then
			MODE.ResetShadowCamouflage(ply)
			MODE.ResetStalkerTracking(ply)
		end
	end
end)

hook.Add("HomigradDamage", "HMCD_SubRoles_ManiacFuryTrigger", function(victim, dmgInfo, hitgroup, ent, harm)
	local ply = IsValid(victim) and victim or ent
	ply = hg.RagdollOwner and (hg.RagdollOwner(ply) or ply) or ply

	MODE.TryTriggerManiacFury(ply, dmgInfo, harm)
end)

hook.Add("EntityTakeDamage", "HMCD_SubRoles_ManiacFuryFallTrigger", function(victim, dmgInfo)
	local ply = IsValid(victim) and victim or nil
	ply = hg.RagdollOwner and (hg.RagdollOwner(ply) or ply) or ply

	MODE.TryTriggerManiacFury(ply, dmgInfo)

	local attacker = dmgInfo and dmgInfo:GetAttacker()
	attacker = normalizeStalkerAttacker(attacker)
	MODE.TryStalkerFirstHit(attacker, victim)
end)

hook.Add("PlayerSpawn", "HMCD_SubRoles_ShadowCamouflage", function(ply)
	MODE.ResetShadowCamouflage(ply)
	MODE.ResetManiacFury(ply)
	MODE.ResetStalkerTracking(ply)
end)

hook.Add("PlayerDeath", "HMCD_SubRoles_ShadowCamouflage", function(ply)
	MODE.ResetShadowCamouflage(ply)
	MODE.ResetManiacFury(ply)
	MODE.ResetStalkerTracking(ply)

	for _, stalker in player.Iterator() do
		if IsValid(stalker) and stalker.Ability_StalkerMarks then
			MODE.SyncStalkerMarks(stalker)
		end
	end
end)
