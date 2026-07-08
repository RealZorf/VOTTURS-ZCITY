local MODE = MODE
MODE.NetSize_ChemicalResistanceBits = 8
local chemical_degrade_speeds = {
	["HCN"] = 1,
	["KCN"] = 0.5,
}

MODE.DisarmReach = 70
MODE.NoDisarmWeapons = {
	["weapon_hands_sh"] = true,
}
MODE.ShadowCamouflageChargeTime = 4
MODE.ShadowCamouflageWallDistance = 25
MODE.ShadowCamouflageMoveSpeed = 15
MODE.ShadowCamouflageGraceTime = 1
MODE.ShadowCamouflageAlpha = 82
MODE.ShadowCamouflageTint = Color(190, 205, 220, 82)
MODE.ShadowCamouflageBlend = 0.52
MODE.ShadowCamouflageColorModulation = {
	0.78,
	0.84,
	0.94
}
MODE.FiberwireHeadSawTime = 3.5
MODE.StalkerMarkMax = 3
MODE.StalkerMarkTime = 0.85
MODE.StalkerMarkDistance = 3300
MODE.StalkerMarkAngleCos = math.cos(math.rad(24))
MODE.StalkerMarkAssistDistance = 105
MODE.StalkerFirstHitStunTime = 1.65
MODE.StalkerIsolatedFirstHitStunTime = 2.75
MODE.StalkerIsolatedRadius = 360
MODE.StalkerFirstHitStaminaDrain = 60
MODE.StalkerFirstHitDamageMultiplier = 1.15
MODE.StalkerIsolatedFirstHitDamageMultiplier = 1.4
MODE.StalkerPursuitRadius = 1750
MODE.StalkerPursuitStaminaRegen = 14
MODE.StalkerPursuitFootstepVolume = 0.18
MODE.CannibalConsumeTime = 4.5
MODE.CannibalCleaverConsumeTime = 3
MODE.CannibalConsumeReach = 95
MODE.CannibalHealthRestore = 30
MODE.CannibalBloodRestore = 900
MODE.CannibalStaminaBonusPerBody = 25
MODE.CannibalMeleeDamageBonusPerBody = 0.10
MODE.CannibalMaxConsumedBodies = 10
MODE.JuggernautModelScale = 1.15
MODE.JuggernautStaminaMultiplier = 2
MODE.JuggernautMeleeDamageMultiplier = 1.5
MODE.JuggernautLegStrengthMultiplier = 1.5
MODE.JuggernautJumpPowerMultiplier = 1.15
MODE.JuggernautStaminaExhaustMultiplier = 0.7
MODE.JuggernautStrangleTime = 3.25
MODE.JuggernautStrangleMinBrainOxygen = 0.12
MODE.JuggernautStrangleMinConsciousness = 0.2
MODE.JuggernautStrangleFinishStunTime = 7
MODE.JuggernautStrangleBlackoutTime = 12
MODE.JuggernautImpactMinSpeed = 340
MODE.JuggernautImpactCooldown = 1.25
MODE.JuggernautImpactDamage = 18
MODE.JuggernautImpactStunTime = 1.4
MODE.JuggernautStompReach = 105
MODE.JuggernautStompCooldown = 1.35
MODE.JuggernautStompMinPitch = 58

function MODE.IsShadowRole(subrole)
	return subrole == "traitor_shadow" or subrole == "traitor_shadow_soe"
end

function MODE.IsStalkerRole(subrole)
	return subrole == "traitor_stalker" or subrole == "traitor_stalker_soe"
end

function MODE.IsCannibalRole(subrole)
	return subrole == "traitor_cannibal" or subrole == "traitor_cannibal_soe"
end

function MODE.IsJuggernautRole(subrole)
	return subrole == "traitor_juggernaut" or subrole == "traitor_juggernaut_soe"
end

function MODE.GetPlayerScaleForJuggernaut(ply)
	if not IsValid(ply) then return 1 end
	if hg and hg.GetPlayerModelScale then return hg.GetPlayerModelScale(ply) or 1 end

	return ply.GetModelScale and ply:GetModelScale() or 1
end

function MODE.IsJuggernautVictimSmallEnough(juggernaut, victim)
	if not IsValid(juggernaut) or not IsValid(victim) then return false end
	if victim.Profession == "athlete" then return false end

	local juggernaut_scale = MODE.GetPlayerScaleForJuggernaut(juggernaut)
	local victim_scale = MODE.GetPlayerScaleForJuggernaut(victim)

	return victim_scale < juggernaut_scale - 0.04
end

function MODE.GetJuggernautCarryTarget(ply)
	if not IsValid(ply) or not MODE.IsJuggernautRole(ply.SubRole) then return nil end

	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) or wep:GetClass() ~= "weapon_hands_sh" or not wep.GetCarrying then return nil end

	local carried = wep:GetCarrying()
	if not IsValid(carried) then
		carried = ply:GetNetVar("carryent")
	end

	if not IsValid(carried) then return nil end

	local victim = carried:IsPlayer() and carried or ((hg and hg.RagdollOwner and hg.RagdollOwner(carried)) or carried.ply)
	if not IsValid(victim) or not victim:IsPlayer() or victim == ply or not victim:Alive() then return nil end
	if not MODE.IsJuggernautVictimSmallEnough(ply, victim) then return nil end

	return carried, victim
end

function MODE.CanJuggernautStrangle(ply)
	local carried, victim = MODE.GetJuggernautCarryTarget(ply)
	return IsValid(carried) and IsValid(victim), carried, victim
end

function MODE.GetJuggernautStrangleProgress(ply)
	if not IsValid(ply) then return 0 end

	local ready_at = ply:GetNWFloat("HMCD_JuggernautStrangleReadyAt", 0)
	local start_at = ply:GetNWFloat("HMCD_JuggernautStrangleStart", 0)
	if ready_at <= start_at or ready_at <= 0 then return 0 end

	return math.Clamp(1 - ((ready_at - CurTime()) / (ready_at - start_at)), 0, 1)
end

function MODE.GetJuggernautStompTarget(ply)
	if not IsValid(ply) or not MODE.IsJuggernautRole(ply.SubRole) then return nil end
	if ply:EyeAngles()[1] < (MODE.JuggernautStompMinPitch or 58) then return nil end

	local trace = hg and hg.eyeTrace and hg.eyeTrace(ply, MODE.JuggernautStompReach or 105)
	if not trace then return nil end

	local ent = trace.Entity
	if not IsValid(ent) then return nil end

	local victim
	local rag
	if ent:IsPlayer() then
		victim = ent
		rag = IsValid(victim.FakeRagdoll) and victim.FakeRagdoll or (victim.GetNWEntity and victim:GetNWEntity("FakeRagdoll", NULL))
	elseif ent:IsRagdoll() then
		rag = ent
		victim = (hg and hg.RagdollOwner and hg.RagdollOwner(ent)) or ent.ply
	else
		return nil
	end

	if not IsValid(victim) or not victim:IsPlayer() or victim == ply or not victim:Alive() then return nil end
	if not IsValid(rag) or not rag:IsRagdoll() then return nil end
	if not victim.organism or victim.organism.otrub ~= true then return nil end

	local head = rag:LookupBone("ValveBiped.Bip01_Head1")
	if head then
		local head_pos = rag:GetBonePosition(head)
		if head_pos and trace.HitPos:DistToSqr(head_pos) > 34 ^ 2 then return nil end
	end

	return rag, victim, trace, head
end

function MODE.IsCannibalCleaverEquipped(ply)
	local wep = IsValid(ply) and ply:GetActiveWeapon() or nil
	return IsValid(wep) and wep:GetClass() == "weapon_hg_cleaver"
end

function MODE.GetCannibalConsumeTime(ply)
	if MODE.IsCannibalCleaverEquipped and MODE.IsCannibalCleaverEquipped(ply) then
		return MODE.CannibalCleaverConsumeTime or 3
	end

	return MODE.CannibalConsumeTime or 4.5
end

function MODE.IsCannibalConsumableVictim(victim, corpse)
	if not IsValid(victim) or not victim:IsPlayer() then return false end
	if IsValid(corpse) and (corpse.HMCDCannibalConsumed or (corpse.GetNWBool and corpse:GetNWBool("HMCD_CannibalConsumed", false))) then return false end
	if not victim:Alive() then return true end

	local fake_ragdoll = IsValid(victim.FakeRagdoll) and victim.FakeRagdoll or (victim.GetNWEntity and victim:GetNWEntity("FakeRagdoll", NULL))
	if not IsValid(fake_ragdoll) then return false end
	if IsValid(corpse) and fake_ragdoll ~= corpse then return false end

	local org = victim.organism
	if SERVER then
		return org and org.otrub == true
	end

	return not org or org.otrub == true
end

function MODE.GetCannibalConsumeTarget(ply)
	if not IsValid(ply) then return nil end

	local trace = hg and hg.eyeTrace and hg.eyeTrace(ply, MODE.CannibalConsumeReach or 95)
	if not trace then return nil end

	local corpse = trace.Entity
	if not IsValid(corpse) then return nil end

	local victim
	if corpse:IsPlayer() then
		victim = corpse
		corpse = IsValid(victim.FakeRagdoll) and victim.FakeRagdoll or (victim.GetNWEntity and victim:GetNWEntity("FakeRagdoll", NULL))
	elseif corpse:IsRagdoll() then
		victim = (hg and hg.RagdollOwner and hg.RagdollOwner(corpse)) or corpse.ply
	else
		return nil
	end

	if not IsValid(corpse) or not corpse:IsRagdoll() then return nil end
	if not IsValid(victim) or not victim:IsPlayer() or victim == ply then return nil end
	if not MODE.IsCannibalConsumableVictim(victim, corpse) then return nil end

	return corpse, victim, trace
end

function MODE.GetCannibalConsumeProgress(ply)
	if not IsValid(ply) then return 0 end

	local ready_at = ply:GetNWFloat("HMCD_CannibalConsumeReadyAt", 0)
	local start_at = ply:GetNWFloat("HMCD_CannibalConsumeStart", 0)
	if ready_at <= start_at or ready_at <= 0 then return 0 end

	return math.Clamp(1 - ((ready_at - CurTime()) / (ready_at - start_at)), 0, 1)
end

function MODE.GetActiveFiberwire(ply)
	local wep = IsValid(ply) and ply:GetActiveWeapon() or nil
	if not IsValid(wep) or wep:GetClass() ~= "weapon_hg_fiberwire" then return nil end

	return wep
end

function MODE.IsPlayerUsingFiberwire(ply)
	return IsValid(MODE.GetActiveFiberwire(ply))
end

function MODE.GetFiberwireSawTarget(ply)
	local wep = MODE.GetActiveFiberwire(ply)
	if not IsValid(wep) or not wep.GetStrangling or not wep:GetStrangling() then return nil end

	local rag = wep.StrangleRag
	if not IsValid(rag) or not rag:IsRagdoll() then return nil end

	local victim = (hg and hg.RagdollOwner and hg.RagdollOwner(rag)) or rag.ply
	if not IsValid(victim) or not victim:IsPlayer() or not victim:Alive() then return nil end

	return wep, rag, victim
end

function MODE.CanPlayerSawHeadWithFiberwire(ply, aim_ent, other_ply)
	local _, rag, victim = MODE.GetFiberwireSawTarget(ply)
	if not IsValid(rag) or not IsValid(victim) then return false end
	if IsValid(aim_ent) and aim_ent ~= rag and aim_ent ~= victim then return false end
	if IsValid(other_ply) and other_ply ~= victim then return false end

	return true
end

function MODE.GetNeckBreakAction(ply)
	if ply.Ability_NeckBreak and ply.Ability_NeckBreak.Action then
		return ply.Ability_NeckBreak.Action
	end

	local wep = MODE.GetActiveFiberwire(ply)
	return (IsValid(wep) and wep.GetStrangling and wep:GetStrangling()) and "saw_head" or "neck_break"
end

--\\
function MODE.GetPlayerTraceToOtherVictim(ply, victim, dist)
	if(IsValid(victim))then
		local ragdoll = victim.FakeRagdoll or victim:GetNWEntity("RagdollDeath", victim.FakeRagdoll)
		
		if(IsValid(ragdoll))then
			--
		else
			ragdoll = victim
		end
		
		local bone_id = ragdoll:LookupBone("ValveBiped.Bip01_Spine2")
		
		if(bone_id)then
			local bone_matrix = ragdoll:GetBoneMatrix(bone_id)
			
			if(bone_matrix)then
				local pos, ang = bone_matrix:GetTranslation(), bone_matrix:GetAngles()
				local ply_offset_normal = pos - ply:GetShootPos()
				local ply_aim_normal = ply:GetAimVector()
					
				ply_offset_normal:Normalize()
				ply_aim_normal:Normalize()
				
				local ang_diff = -(math.deg(math.acos(ply_aim_normal:DotProduct(-ply_offset_normal))) - 180)
				
				if(ang_diff < 80)then
					local aim_ent, other_ply, trace = MODE.GetPlayerTraceToOther(ply, ply_offset_normal, dist)
					
					if(IsValid(aim_ent))then
						return aim_ent, other_ply, trace
					else
						return MODE.GetPlayerTraceToOther(ply, dist)
					end
				else
					return MODE.GetPlayerTraceToOther(ply, dist)
				end
			end
		end
	end
end
--

--\\Neck Break
function MODE.CanPlayerBreakOtherNeck(ply, aim_ent)
	local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "weapon_hands_sh" then return false end

	if(aim_ent:IsRagdoll())then
		local bone_id = aim_ent:LookupBone("ValveBiped.Bip01_Head1")
		
		if(bone_id)then
			local bone_matrix = aim_ent:GetBoneMatrix(bone_id)
			
			if(bone_matrix)then
				local pos, ang = bone_matrix:GetTranslation(), bone_matrix:GetAngles()
				local other_normal = -ang:Right()
				local ply_normal = pos - ply:GetShootPos()
				local dist_z = math.abs(pos.z - ply:GetShootPos().z)
				
				if(dist_z < 50) then
					ply_normal:Normalize()
					
					local ang_diff = -(math.deg(math.acos(ply_normal:DotProduct(other_normal))) - 180)
					
					if(ang_diff < 100)then
						return true
					end
				end
			end
		end
	elseif(aim_ent:IsPlayer())then
		local other_angle = aim_ent:EyeAngles()[2]
		local ply_angle = (aim_ent:GetPos() - ply:GetPos()):Angle()[2] --ply:EyeAngles()[2]
		local ang_diff = math.abs(math.AngleDifference(other_angle, ply_angle))
		
		if(ang_diff < 100)then
			return true
		end
	end
	
	return false
end

function MODE.BreakOtherNeck(ply, other_ply, aim_ent)
	if(other_ply:Alive())then
		other_ply:Kill()
		other_ply:ViewPunch(Angle(0, 0, -10))
		
		aim_ent.organism.spine3 = 1
		
		aim_ent:EmitSound("neck_snap_01.wav", 60, 100, 1, CHAN_AUTO)

		timer.Simple(0.1, function()
			local ent = other_ply:GetNWEntity("RagdollDeath")

			if IsValid(ent) then
				ent:RemoveInternalConstraint(ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_Head1")))

				local spine = ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_Spine2"))
				local head = ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_Head1"))

				local pspine = ent:GetPhysicsObjectNum(spine)
				local phead = ent:GetPhysicsObjectNum(head)

				local lpos, lang = WorldToLocal(phead:GetPos() + phead:GetAngles():Forward() * -2 + phead:GetAngles():Up() * -1.5, angle_zero, pspine:GetPos(), pspine:GetAngles())
                
				phead:SetPos(pspine:GetPos() + pspine:GetAngles():Forward() * 12.9 + pspine:GetAngles():Right() * -1)

				local cons = constraint.AdvBallsocket(ent, ent, spine, head, lpos, nil, 0, 0, -55, -90, -50, 55, 35, 50, 0, 0, 0, 0, 0)
			end
		end)
	end
end

function MODE.SawOffOtherHead(ply, other_ply, aim_ent)
	local function resolveRagdoll(allow_fallback)
		if IsValid(other_ply) then
			local death_rag = other_ply:GetNWEntity("RagdollDeath")
			if IsValid(death_rag) and death_rag:IsRagdoll() then return death_rag end

			if IsValid(other_ply.RagdollDeath) and other_ply.RagdollDeath:IsRagdoll() then
				return other_ply.RagdollDeath
			end
		end

		if allow_fallback and IsValid(aim_ent) and aim_ent:IsRagdoll() then return aim_ent end
	end

	local function finishRagdoll(rag)
		if not IsValid(rag) or not rag:IsRagdoll() then return end
		if rag.FiberwireHeadSawDone then return end

		local head = rag:LookupBone("ValveBiped.Bip01_Head1")
		if not head then return end

		local phys_bone = rag:TranslateBoneToPhysBone(head)
		if not phys_bone or phys_bone < 0 then return end
		local phys = rag:GetPhysicsObjectNum(phys_bone)
		rag.FiberwireHeadSawDone = true

		if IsValid(phys) then
			phys:AddVelocity((ply:GetAimVector() + Vector(0, 0, 0.35)) * 90)
		end

		local force = IsValid(ply) and ((ply:GetAimVector() + Vector(0, 0, 0.25)) * 450) or vector_origin
		if Gib_Input then
			Gib_Input(rag, head, force)
		elseif Gib_RemoveBone then
			Gib_RemoveBone(rag, head, phys_bone)
		else
			rag:RemoveInternalConstraint(phys_bone)
			rag:ManipulateBoneScale(head, vector_origin)
		end

		local pos = rag:GetBonePosition(head) or rag:WorldSpaceCenter()
		if SpawnMeatGore and not Gib_Input then
			SpawnMeatGore(rag, pos or rag:WorldSpaceCenter(), 6)
		end

		rag:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", 70, math.random(75, 90), 1)
	end

	if IsValid(aim_ent) and aim_ent.organism then
		aim_ent.organism.spine3 = 1
	end

	if IsValid(other_ply) and other_ply:Alive() then
		other_ply:Kill()
	end

	local timer_id = "HMCD_FiberwireHeadSaw_" .. tostring(IsValid(other_ply) and other_ply:EntIndex() or IsValid(aim_ent) and aim_ent:EntIndex() or 0)
	local tries = 0
	timer.Create(timer_id, 0.05, 24, function()
		tries = tries + 1
		local rag = resolveRagdoll(tries > 6)
		if not IsValid(rag) then return end

		finishRagdoll(rag)
		timer.Remove(timer_id)
	end)
end

function MODE.StartBreakingOtherNeck(ply, other_ply, action)
	ply.Ability_NeckBreak = {
		Victim = other_ply,
		Progress = 0,
		Action = action or "neck_break",
	}
	other_ply.BeingVictimOfNeckBreak = true
	
	if(SERVER)then
		other_ply:ViewPunch(Angle(0, -10, -10))
		
		net.Start("HMCD_BeingVictimOfNeckBreak")
			net.WriteBool(true)
		net.Send(other_ply)
		
		net.Start("HMCD_BreakingOtherNeck")
			net.WriteBool(true)
			net.WriteEntity(ply)
			net.WriteEntity(other_ply)
			net.WriteString(ply.Ability_NeckBreak.Action)
		net.SendPVS(ply:GetShootPos())
	end
end

function MODE.StopBreakingOtherNeck(ply)
	if(ply.Ability_NeckBreak and IsValid(ply.Ability_NeckBreak.Victim))then
		ply.Ability_NeckBreak.Victim.BeingVictimOfNeckBreak = false
	end
	
	if(SERVER and ply.Ability_NeckBreak and IsValid(ply.Ability_NeckBreak.Victim))then
		net.Start("HMCD_BeingVictimOfNeckBreak")
			net.WriteBool(false)
		net.Send(ply.Ability_NeckBreak.Victim)

		net.Start("HMCD_BreakingOtherNeck")
			net.WriteBool(false)
			net.WriteEntity(ply)
		net.SendPVS(ply:GetShootPos())
	end
	
	ply.Ability_NeckBreak = nil
end

function MODE.ContinueBreakingOtherNeck(ply)
	local break_data = ply.Ability_NeckBreak
	local victim = break_data.Victim
	local action = break_data.Action or "neck_break"
	local aim_ent, other_ply, trace

	if action == "saw_head" then
		local _, rag, saw_victim = MODE.GetFiberwireSawTarget(ply)
		aim_ent, other_ply = rag, saw_victim
	else
		aim_ent, other_ply, trace = MODE.GetPlayerTraceToOtherVictim(ply, victim)
	end
	
	if(IsValid(aim_ent) and (aim_ent:IsPlayer() or aim_ent:IsRagdoll()))then
		local can_continue = IsValid(victim) and victim:Alive() and other_ply == victim
		if action == "saw_head" then
			can_continue = can_continue and MODE.CanPlayerSawHeadWithFiberwire(ply, aim_ent, other_ply)
		else
			can_continue = can_continue and MODE.CanPlayerBreakOtherNeck(ply, aim_ent)
		end

		if(can_continue)then
			local progress_speed = action == "saw_head" and (100 / MODE.FiberwireHeadSawTime) or 300
			break_data.Progress = break_data.Progress + FrameTime() * progress_speed

			if(SERVER and action == "saw_head" and (break_data.NextSawSound or 0) <= CurTime())then
				break_data.NextSawSound = CurTime() + 0.75
				aim_ent:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", 55, math.random(80, 95), 0.45)

				if hg and hg.organism and hg.organism.AddWoundManual and aim_ent.organism then
					local head = aim_ent:LookupBone("ValveBiped.Bip01_Head1")
					if head then
						hg.organism.AddWoundManual(aim_ent, 18, vector_origin, angle_zero, head, CurTime())
					end
				end
			end
			
			if(break_data.Progress >= 100)then
				if(SERVER)then
					if(action == "saw_head")then
						MODE.SawOffOtherHead(ply, break_data.Victim, aim_ent)
					else
						MODE.BreakOtherNeck(ply, break_data.Victim, aim_ent)
					end
				end
				
				
				MODE.StopBreakingOtherNeck(ply)
			end
		else
			MODE.StopBreakingOtherNeck(ply)
		end
	else
		MODE.StopBreakingOtherNeck(ply)
	end
end

hook.Add("HG_MovementCalc_2", "HMCD_SubRole_Abilities", function(mul, ply, cmd)
	if(ply.BeingVictimOfNeckBreak or ply.BeingVictimOfDisarmament)then
		mul[1] = mul[1] * 0.3
	end

	if(ply.Ability_CannibalConsume)then
		mul[1] = mul[1] * 0.25
	end

	if(ply.Ability_JuggernautStrangle)then
		mul[1] = mul[1] * 0.45
	end
end)
--

--\\Disarm
function MODE.CanPlayerDisarmOtherPly(ply, other_ply)
	--[[if(other_ply and IsValid(other_ply:GetActiveWeapon()))then
		if(MODE.NoDisarmWeapons[other_ply:GetActiveWeapon():GetClass()])then
			return false
		end
	else
		return false
	end--]]
	
	return true
end

function MODE.CanPlayerDisarmOther(ply, aim_ent)
	if(aim_ent:IsRagdoll())then
		local bone_id = aim_ent:LookupBone("ValveBiped.Bip01_Spine2")
		
		if(bone_id)then
			local bone_matrix = aim_ent:GetBoneMatrix(bone_id)
			
			if(bone_matrix)then
				local pos, ang = bone_matrix:GetTranslation(), bone_matrix:GetAngles()
				local other_normal = ang:Right()
				local ply_normal = pos - ply:GetShootPos()
				local dist_z = math.abs(pos.z - ply:GetShootPos().z)
				
				if(dist_z < 50) then
					ply_normal:Normalize()
					
					local ang_diff = -(math.deg(math.acos(ply_normal:DotProduct(other_normal))) - 180)
					
					if(ang_diff < 90)then
						return 2
					else
						return 1.5
					end
				end
			end
		end
	elseif(aim_ent:IsPlayer())then
		local other_angle = aim_ent:EyeAngles()[2]
		local ply_angle = (aim_ent:GetPos() - ply:GetPos()):Angle()[2] --ply:EyeAngles()[2]
		local ang_diff = math.abs(math.AngleDifference(other_angle, ply_angle))
		
		if(ang_diff < 70)then
			return 2
		else
			return 1.5
		end
	end
	
	return false
end

function MODE.DisarmOther(ply, other_ply, aim_ent)
	if(other_ply:Alive())then
		local weapon = other_ply:GetActiveWeapon()

		if(IsValid(weapon) and !weapon.NoDrop)then
			other_ply:DropWeapon(weapon)
			ply:PickupWeapon(weapon, false)
		end

		hg.LightStunPlayer(other_ply)
		timer.Simple(0,function()
			local rag = hg.GetCurrentCharacter(other_ply)
			if IsValid(rag) and rag ~= other_ply then
				local bon = rag:LookupBone("ValveBiped.Bip01_Head1")
				local physnum = rag:TranslateBoneToPhysBone(bon)
				local phys = rag:GetPhysicsObjectNum(physnum)
				local dist = 25--phys:GetPos():Distance(ply:EyePos())
				
				hg.SetCarryEnt2(ply, rag, bon, phys:GetMass(), Vector(-2,0,0), ply:GetAimVector() * dist + ply:EyeAngles():Up() * 5 + ply:EyeAngles():Right() * -5 + ply:GetShootPos(), ply:EyeAngles() + Angle(-90, 90, 0))
			end
		end)
	end
end

function MODE.StartDisarmingOther(ply, other_ply)
	ply.Ability_Disarm = {
		Victim = other_ply,
		Progress = 0,
	}
	other_ply.BeingVictimOfDisarmament = true
	
	if(SERVER)then
		-- other_ply:ViewPunch(Angle(0, -10, -10))
		
		net.Start("HMCD_BeingVictimOfDisarmament")
			net.WriteBool(true)
		net.Send(other_ply)
		
		net.Start("HMCD_DisarmingOther")
			net.WriteBool(true)
			net.WriteEntity(other_ply)
		net.Send(ply)
	end
end

function MODE.StopDisarmingOther(ply)
	if(ply.Ability_Disarm and IsValid(ply.Ability_Disarm.Victim))then
		ply.Ability_Disarm.Victim.BeingVictimOfDisarmament = false
	end
	
	if(SERVER and ply.Ability_Disarm and IsValid(ply.Ability_Disarm.Victim))then
		net.Start("HMCD_BeingVictimOfDisarmament")
			net.WriteBool(false)
		net.Send(ply.Ability_Disarm.Victim)

		net.Start("HMCD_DisarmingOther")
			net.WriteBool(false)
		net.Send(ply)
	end
	
	ply.Ability_Disarm = nil
end

function MODE.ContinueDisarmingOther(ply)
	local ability_data = ply.Ability_Disarm
	local victim = ability_data.Victim
	local aim_ent, other_ply, trace = MODE.GetPlayerTraceToOtherVictim(ply, victim, MODE.DisarmReach)
	
	if(IsValid(aim_ent) and (aim_ent:IsPlayer() or aim_ent:IsRagdoll()))then
		local disarm_strength = MODE.CanPlayerDisarmOther(ply, aim_ent)
		
		if(IsValid(victim) and victim:Alive() and disarm_strength and other_ply == victim and MODE.CanPlayerDisarmOtherPly(ply, other_ply))then
			ability_data.Progress = ability_data.Progress + FrameTime() * 250 * disarm_strength
			
			if(ability_data.Progress >= 100)then
				if(SERVER)then
					MODE.DisarmOther(ply, victim, aim_ent)
				end
				
				
				MODE.StopDisarmingOther(ply)
			end
		else
			MODE.StopDisarmingOther(ply)
		end
	else
		MODE.StopDisarmingOther(ply)
	end
end

hook.Add("PlayerSwitchWeapon", "HMCD_SubRole_Abilities", function(ply)
	if(ply.BeingVictimOfDisarmament)then
		return true
	end
end)
--
