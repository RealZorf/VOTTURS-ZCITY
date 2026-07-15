--local Organism = hg.organism
hg.organism.module = hg.organism.module or {}
local module = hg.organism.module
hg.organism.lastindex = hg.organism.lastindex or 1000000
hook.Add("Org Clear", "Main", function(org)
	org.alive = true
	org.otrub = false
	org.entindex = IsValid(org.owner) and org.owner:EntIndex() or hg.organism.lastindex + 1
	module.pulse[1](org)
	module.blood[1](org)
	module.pain[1](org)
	module.stamina[1](org)
	module.lungs[1](org)
	module.liver[1](org)
	module.metabolism[1](org)
	module.random_events[1](org)
	org.brain = 0
	org.consciousness = 1
	org.disorientation = 0
	org.jaw = 0
	org.spine1 = 0
	org.spine2 = 0
	org.spine3 = 0
	org.chest = 0
	org.pelvis = 0
	org.skull = 0
	org.stomach = 0
	org.intestines = 0

	org.thiamine = 0

	org.lleg = 0
	org.rleg = 0
	org.larm = 0
	org.rarm = 0
	org.llegdislocation = false
	org.rlegdislocation = false
	org.rarmdislocation = false
	org.larmdislocation = false
	org.jawdislocation = false

	org.llegamputated = false
	org.rlegamputated = false
	org.rarmamputated = false
	org.larmamputated = false
	org.headamputated = false

	org.furryinfected = false

	org.health = 100
	org.canmove = true
	org.recoilmul = 1
	org.legstrength = 1
	org.meleespeed = 1
	org.temperature = 36.7
	org.superfighter = false
	org.CantCheckPulse = nil
	org.HEV = nil
	org.bleedingmul = 1

	--\\ info for rp addition
	org.last_heartbeat = CurTime()
	org.bulletwounds = 0
	org.stabwounds = 0
	org.slashwounds = 0
	org.bruises = 0
	org.burns = 0
	org.explosionwounds = 0

	org.fear = 0
	org.fearadd = 0
	--

	org.bloodpressure = 1
	org.perfusion = 1
	org.brainoxygen = 1
	org.peripheralperfusion = 1
	org.hypoxiaTime = 0
	org.severeHypoxiaTime = 0
	org.perfusionMoveMul = 1
	org.perfusionGripMul = 1
	org.throatcut = false
	org.throatCutTime = 0
	org.throatCutUntil = 0
	org.throatCutSeverity = 0
	org.throatCutPressureShock = 0
	org.neckBrainOxygenPenalty = 0
	org.bodyposition = "standing"
	org.bodyPositionPressureBonus = 0
	org.bodyPositionBleedMul = 1
	org.bodyPositionBreathingMul = 1
	org.bodyPositionThroatDrainMul = 1

	org.assimilated = 0
	org.berserk = 0
	org.noradrenaline = 0

	org.blindness = nil

	if IsValid(org.owner) then
		if org.owner:IsPlayer() and org.owner:Alive() then
			org.owner:SetHealth(100)
			org.owner:SetNetVar("wounds",{})
			org.owner:SetNetVar("arterialwounds",{})
		end

		org.owner:SetNetVar("zableval_masku", false)
	end

	org.allowholster = false
	
	org.just_damaged_bone = nil
	org.LodgedEntities = nil
	
	org.dmgstack = {}

	org.SpawnedBrainChunks = nil
end)

hook.Add("Should Fake Up", "organism", function(ply)
	local org = ply.organism
	if org.otrub or org.fake or org.spine1 >= hg.organism.fake_spine1 or org.spine2 >= hg.organism.fake_spine2 or org.spine3 >= hg.organism.fake_spine3 or (org.lleg == 1 and org.rleg == 1) and org.berserk <= 0.3 or (org.blood < 2900) or org.consciousness <= 0.4 then
		return false
	end
end)

local hg_unreliable_nets = ConVarExists("hg_unreliable_nets") and GetConVar("hg_unreliable_nets") or CreateConVar("hg_unreliable_nets", 0, FCVAR_ARCHIVE + FCVAR_SERVER_CAN_EXECUTE, "Toggle unreliable net messages for some of the expensive nets", 0, 1)

util.AddNetworkString("organism_send")
util.AddNetworkString("organism_sendply")
local CurTime = CurTime
local nullTbl = {}
local hg_developer = ConVarExists("hg_developer") and GetConVar("hg_developer") or CreateConVar("hg_developer", 0, FCVAR_SERVER_CAN_EXECUTE, "Toggle developer mode (enables damage traces)", 0, 1)
local function organism_recipient_filter(owner)
	local rf = RecipientFilter()

	if IsValid(owner) then
		rf:AddPVS(owner:GetPos())

		if owner:IsPlayer() then
			rf:AddPlayer(owner)
		end
	else
		rf:AddAllPlayers()
	end

	return rf
end

local function approachVitals(current, target, timeValue)
	current = tonumber(current) or target

	local rate = target < current and 4.5 or 1.35
	return math.Approach(current, target, (timeValue or engine.TickInterval()) * rate)
end

local function getBonePositionSafe(ent, boneName)
	if not IsValid(ent) or not ent.LookupBone then return nil end

	local bone = ent:LookupBone(boneName)
	if not bone then return nil end

	local pos = ent:GetBonePosition(bone)
	return isvector(pos) and pos or nil
end

local function getBodySideZ(ent)
	if not IsValid(ent) or not ent.LookupBone then return nil end

	local bone = ent:LookupBone("ValveBiped.Bip01_Head1") or ent:LookupBone("ValveBiped.Bip01_Spine2")
	if not bone then return nil end

	local matrix = ent:GetBoneMatrix(bone)
	if not matrix then return nil end

	return matrix:GetAngles():Right().z
end

function hg.organism.UpdateBodyPosition(owner, org, timeValue)
	if not IsValid(owner) or not org then return end

	local ent = (hg.GetCurrentCharacter and hg.GetCurrentCharacter(owner)) or owner
	if not IsValid(ent) then ent = owner end

	local isRagdoll = ent:IsRagdoll()
	local velocity = IsValid(ent) and ent:GetVelocity() or vector_origin
	local speed = velocity:Length()
	local position = "standing"
	local pressureBonus = 0
	local bleedMul = 1
	local breathingMul = 1
	local throatDrainMul = 1
	local shockRelief = 0

	if owner:IsPlayer() and not isRagdoll and not org.fake and not org.otrub then
		if speed > 125 then
			position = "walking"
			bleedMul = 1.18
		else
			position = "standing"
			bleedMul = 1.07
		end
	else
		local headPos = getBonePositionSafe(ent, "ValveBiped.Bip01_Head1")
		local pelvisPos = getBonePositionSafe(ent, "ValveBiped.Bip01_Pelvis") or ent:WorldSpaceCenter()
		local lFoot = getBonePositionSafe(ent, "ValveBiped.Bip01_L_Foot")
		local rFoot = getBonePositionSafe(ent, "ValveBiped.Bip01_R_Foot")
		local sideZ = getBodySideZ(ent) or 0

		local footZ
		if lFoot and rFoot then
			footZ = (lFoot.z + rFoot.z) * 0.5
		elseif lFoot or rFoot then
			footZ = (lFoot or rFoot).z
		end

		local headZ = headPos and headPos.z or pelvisPos.z
		local torsoZ = pelvisPos.z
		local legsElevated = footZ and footZ > math.max(headZ, torsoZ) + 8
		local lyingFlat = math.abs(headZ - torsoZ) < 22 or isRagdoll
		local faceDown = sideZ < -0.35
		local onSide = math.abs(sideZ) <= 0.35

		if legsElevated then
			pressureBonus = 0.035
			shockRelief = 0.24
		end

		if faceDown then
			position = "face_down"
			pressureBonus = math.max(pressureBonus, 0.015)
			bleedMul = 0.97
			breathingMul = org.otrub and 0.74 or 0.86
			throatDrainMul = 0.75
		elseif onSide then
			position = "recovery"
			pressureBonus = math.max(pressureBonus, 0.03)
			bleedMul = 0.95
			breathingMul = 1.06
			throatDrainMul = 0.55
		elseif legsElevated then
			position = "legs_elevated"
			pressureBonus = 0.075
			bleedMul = 0.96
			breathingMul = 1
			throatDrainMul = 0.9
		elseif lyingFlat then
			position = "lying_flat"
			pressureBonus = 0.04
			bleedMul = 0.96
			breathingMul = 1
			throatDrainMul = 0.9
		else
			position = "slumped"
			bleedMul = 1.03
			breathingMul = 0.92
			throatDrainMul = 1
		end
	end

	org.bodyposition = position
	org.bodyPositionPressureBonus = pressureBonus
	org.bodyPositionBleedMul = bleedMul
	org.bodyPositionBreathingMul = breathingMul
	org.bodyPositionThroatDrainMul = throatDrainMul

	if shockRelief > 0 and (org.shock or 0) > 0 then
		org.shock = math.max((org.shock or 0) - (timeValue or engine.TickInterval()) * shockRelief, 0)
	end
end

function hg.organism.UpdatePerfusion(owner, org, timeValue)
	if not org then return end

	local blood = math.max(org.blood or 0, 0)
	local bloodFrac = math.Clamp((blood - 1800) / 2700, 0, 1)
	local heartFunc = math.Clamp(1 - (org.heart or 0), 0, 1)
	local pulse = org.heartstop and 0 or (org.pulse or 70)
	local pulseFunc = math.Clamp((pulse - 8) / 62, 0, 1)
	local oxygen = org.o2 and math.Clamp((org.o2[1] or 0) / math.max(org.o2.range or 30, 1), 0, 1) or 1
	local arterialBleed = math.max(org.arterialBleed or 0, 0)
	local venousBleed = math.max(org.venousBleed or math.max((org.bleed or 0) - arterialBleed, 0), 0)
	local internalBleed = math.max(org.internalBleedRate or 0, 0)
	local arterialPressurePenalty = math.Clamp(arterialBleed / 18, 0, 0.5)
	local venousPressurePenalty = math.Clamp(venousBleed / 65, 0, 0.18)
	local internalPressurePenalty = math.Clamp(internalBleed / 45, 0, 0.22)
	local bleedPenalty = arterialPressurePenalty + venousPressurePenalty + internalPressurePenalty
	local shockPenalty = math.Clamp((org.shock or 0) / 100, 0, 0.35)
	local throatCutPenalty = math.Clamp(org.throatCutPressureShock or 0, 0, 1)
	local neckBrainOxygenPenalty = math.Clamp(org.neckBrainOxygenPenalty or 0, 0, 1)

	local positionPressureBonus = math.Clamp(org.bodyPositionPressureBonus or 0, 0, 0.1)
	local pressureTarget = math.Clamp(bloodFrac * heartFunc * pulseFunc - bleedPenalty - shockPenalty * 0.45 - throatCutPenalty * 0.22 + positionPressureBonus, 0, 1)
	local perfusionTarget = math.Clamp(pressureTarget * Lerp(oxygen, 0.55, 1), 0, 1)
	local brainTarget = math.Clamp(perfusionTarget * Lerp(oxygen, 0.35, 1) * Lerp(throatCutPenalty, 1, 0.45) * Lerp(neckBrainOxygenPenalty, 1, 0.05), 0, 1)
	local peripheralTarget = math.Clamp(perfusionTarget - shockPenalty * 0.35 - arterialPressurePenalty * 0.35 - venousPressurePenalty * 0.15 - throatCutPenalty * 0.2, 0, 1)

	org.bloodpressure = approachVitals(org.bloodpressure, pressureTarget, timeValue)
	org.perfusion = approachVitals(org.perfusion, perfusionTarget, timeValue)
	org.brainoxygen = approachVitals(org.brainoxygen, brainTarget, timeValue)
	org.peripheralperfusion = approachVitals(org.peripheralperfusion, peripheralTarget, timeValue)
	org.neckBrainOxygenPenalty = math.Approach(neckBrainOxygenPenalty, 0, (timeValue or engine.TickInterval()) * 1.5)

	org.perfusionMoveMul = math.Clamp(math.Remap(org.peripheralperfusion, 0.22, 0.75, 0.25, 1), 0.25, 1)
	local gripFloor = math.Clamp(org.injuryDefianceGripFloor or 0.35, 0.35, 1)
	org.perfusionGripMul = math.Clamp(math.Remap(org.peripheralperfusion, 0.18, 0.7, 0.35, 1), gripFloor, 1)

	local dt = timeValue or engine.TickInterval()
	local badHypoxia = org.brainoxygen < 0.45 or org.perfusion < 0.35
	local severeHypoxia = org.brainoxygen < 0.22 or org.perfusion < 0.16

	if badHypoxia then
		org.hypoxiaTime = math.min((org.hypoxiaTime or 0) + dt * (severeHypoxia and 2.25 or 1), 120)
	else
		org.hypoxiaTime = math.Approach(org.hypoxiaTime or 0, 0, dt * 2)
	end

	if severeHypoxia then
		org.severeHypoxiaTime = math.min((org.severeHypoxiaTime or 0) + dt, 120)
	else
		org.severeHypoxiaTime = math.Approach(org.severeHypoxiaTime or 0, 0, dt * 1.5)
	end

	if owner and owner.IsBerserk and owner:IsBerserk() then return end

	local hypoxiaTime = org.hypoxiaTime or 0
	local severeTime = org.severeHypoxiaTime or 0

	if org.brainoxygen < 0.55 and (hypoxiaTime > 8 or severeTime > 3) then
		org.consciousness = math.min(org.consciousness or 1, math.Clamp(math.Remap(org.brainoxygen, 0.18, 0.55, 0.05, 1), 0.05, 1))
	end

	if org.perfusion < 0.4 and (hypoxiaTime > 10 or severeTime > 4) then
		local timerMul = math.Clamp(hypoxiaTime / 20, 0.4, 1.4)
		org.disorientation = math.max(org.disorientation or 0, math.Remap(org.perfusion, 0.4, 0, 1.5, 6) * timerMul)
	end

	if org.peripheralperfusion < 0.32 then
		org.immobilization = math.max(org.immobilization or 0, math.Remap(org.peripheralperfusion, 0.32, 0, 1.5, 7))
	end

	if (org.perfusion < 0.32 or org.brainoxygen < 0.35) and (hypoxiaTime > 16 or severeTime > 6) then
		org.needfake = true
	end

	if (org.perfusion < 0.18 or org.brainoxygen < 0.2) and (hypoxiaTime > 26 or severeTime > 10) then
		org.needotrub = true
	end
end

local function send_organism(org, ply)
	if not IsValid(org.owner) then return end
	local sendtable = {}

	sendtable.alive = org.alive
	sendtable.otrub = org.otrub
	sendtable.owner = org.owner
	sendtable.stamina = org.stamina
	sendtable.immobilization = org.immobilization
	sendtable.adrenaline = org.adrenaline
	sendtable.adrenalineAdd = org.adrenalineAdd
	sendtable.analgesia = org.analgesia
	sendtable.lleg = org.lleg
	sendtable.rleg = org.rleg
	sendtable.rarm = org.rarm
	sendtable.larm = org.larm
	sendtable.pelvis = org.pelvis
	sendtable.disorientation = org.disorientation
	sendtable.brain = org.brain
	sendtable.o2 = org.o2
	sendtable.CO = org.CO
	sendtable.blood = org.blood
	sendtable.bloodtype = org.bloodtype
	sendtable.bleed = org.bleed
	sendtable.venousBleed = org.venousBleed
	sendtable.arterialBleed = org.arterialBleed
	sendtable.internalBleedRate = org.internalBleedRate
	sendtable.bloodpressure = org.bloodpressure
	sendtable.perfusion = org.perfusion
	sendtable.brainoxygen = org.brainoxygen
	sendtable.peripheralperfusion = org.peripheralperfusion
	sendtable.perfusionMoveMul = org.perfusionMoveMul
	sendtable.perfusionGripMul = org.perfusionGripMul
	sendtable.throatcut = org.throatcut
	sendtable.throatCutUntil = org.throatCutUntil
	sendtable.throatCutSeverity = org.throatCutSeverity
	sendtable.bodyposition = org.bodyposition
	sendtable.hurt = org.hurt
	sendtable.pain = org.pain
	sendtable.shock = org.shock
	sendtable.pulse = org.pulse
	sendtable.heartbeat = org.heartbeat
	sendtable.timeValue = org.timeValue
	sendtable.holdingbreath = org.holdingbreath
	sendtable.arteria = org.arteria
	sendtable.recoilmul = org.recoilmul
	sendtable.cigaretteAimMul = org.cigaretteAimMul or 1
	sendtable.meleespeed = org.meleespeed
	sendtable.temperature = org.temperature
	sendtable.canmove = org.canmove
	sendtable.fear = org.fear
	sendtable.llegdislocation = org.llegdislocation
	sendtable.rlegdislocation = org.rlegdislocation
	sendtable.rarmdislocation = org.rarmdislocation
	sendtable.larmdislocation = org.larmdislocation
	sendtable.jawdislocation = org.jawdislocation
	sendtable.llegamputated = org.llegamputated
	sendtable.rlegamputated = org.rlegamputated
	sendtable.rarmamputated = org.rarmamputated
	sendtable.larmamputated = org.larmamputated
	sendtable.headamputated = org.headamputated
	sendtable.lungsfunction = org.lungsfunction
	sendtable.consciousness = org.consciousness
	sendtable.assimilated = org.assimilated
	sendtable.berserk = org.berserk
	sendtable.noradrenaline = org.noradrenaline
	sendtable.LodgedEntities = org.LodgedEntities
	sendtable.CantCheckPulse = org.CantCheckPulse
	sendtable.blindness = org.blindness
	sendtable.critical = org.critical
	sendtable.incapacitated = org.incapacitated
	sendtable.berserkActive2 = org.berserkActive2
	sendtable.noradrenalineActive = org.noradrenalineActive

	sendtable.superfighter = org.superfighter

	local direct = IsValid(ply) and ply:IsPlayer()

	net.Start("organism_send", (not direct) or hg_unreliable_nets:GetBool())
	net.WriteTable(sendtable)
	net.WriteBool(org.owner.fullsend)
	net.WriteBool(false)
	net.WriteBool(true)
	net.WriteBool(false)
	if direct then
		net.Send(ply)
	else
		net.Send(organism_recipient_filter(org.owner))
	end
	if org.owner == ply or not direct then
		org.owner.fullsend = nil
	end
end

local function send_bareinfo(org)
	if not IsValid(org.owner) then return end
	local sendtable = {}

	sendtable.alive = org.alive
	sendtable.otrub = org.otrub
	sendtable.owner = org.owner
	sendtable.bloodtype = org.bloodtype
	sendtable.pulse = org.pulse
	sendtable.blood = org.blood
	sendtable.heartbeat = org.heartbeat
	sendtable.venousBleed = org.venousBleed
	sendtable.arterialBleed = org.arterialBleed
	sendtable.internalBleedRate = org.internalBleedRate
	sendtable.bloodpressure = org.bloodpressure
	sendtable.perfusion = org.perfusion
	sendtable.brainoxygen = org.brainoxygen
	sendtable.peripheralperfusion = org.peripheralperfusion
	sendtable.throatcut = org.throatcut
	sendtable.throatCutUntil = org.throatCutUntil
	sendtable.throatCutSeverity = org.throatCutSeverity
	sendtable.bodyposition = org.bodyposition
	sendtable.analgesia = org.analgesia
	sendtable.o2 = org.o2
	sendtable.timeValue = org.timeValue
	sendtable.superfighter = org.superfighter
	sendtable.lungsfunction = org.lungsfunction
	sendtable.lleg = org.lleg
	sendtable.rleg = org.rleg
	sendtable.rarm = org.rarm
	sendtable.larm = org.larm
	sendtable.llegdislocation = org.llegdislocation
	sendtable.rlegdislocation = org.rlegdislocation
	sendtable.rarmdislocation = org.rarmdislocation
	sendtable.larmdislocation = org.larmdislocation
	sendtable.jawdislocation = org.jawdislocation
	sendtable.llegamputated = org.llegamputated
	sendtable.rlegamputated = org.rlegamputated
	sendtable.rarmamputated = org.rarmamputated
	sendtable.larmamputated = org.larmamputated
	sendtable.headamputated = org.headamputated
	sendtable.LodgedEntities = org.LodgedEntities
	sendtable.berserkActive2 = org.berserkActive2
	sendtable.CantCheckPulse = org.CantCheckPulse
	sendtable.noradrenalineActive = org.noradrenalineActive

	local rf = RecipientFilter()
	--rf:AddAllPlayers()
	rf:AddPVS(org.owner:GetPos())
	if org.owner:IsPlayer() then rf:RemovePlayer(org.owner) end

	net.Start("organism_send", true)
	net.WriteTable(sendtable)
	net.WriteBool(org.owner.fullsend)
	net.WriteBool(true)
	net.WriteBool(false)
	net.WriteBool(false)
	net.Send(rf)
end

hg.send_organism = send_organism
hg.send_bareinfo = send_bareinfo

local META = FindMetaTable("Player")
function META:IsBerserk()
	if !IsValid(self) then return false end
	if self:IsPlayer() and not self:Alive() then return false end

	local org = self.organism
	return org.berserkActive2 or false
end

function META:IsStimulated()
	if !IsValid(self) then return false end
	if self:IsPlayer() and not self:Alive() then return false end

	local org = self.organism
	return org.noradrenalineActive or false
end

local META2 = FindMetaTable("Entity")
function META2:IsBerserk()
	return false
end

function META2:IsStimulated()
	return false
end

local numerical = {
	"One.",
	"Two.",
	"Three.",
	"Four.",
	"Five.",
	"Six.",
	"Seven.",
	"Eight.",
	"Nine.",
	"Ten.",
	"Eleven.",
	"Twelve.",
	"Thirteen.",
	"Fourteen.",
	"Fifteen.",
	"Sixteen.",
	"Seventeen.",
	"Eighteen.",
	"Nineteen.",
	"Twenty."
}

hook.Add("HomigradDamage", "Berserk", function(ply, dmgInfo, hitgroup, ent)
	local attacker, victim = dmgInfo:GetAttacker(), ply
	if !attacker or !IsValid(attacker) or (IsValid(attacker) and !attacker:IsPlayer()) then
		attacker = ply:GetPhysicsAttacker()
	end

	if not IsValid(attacker) or not attacker:IsPlayer() then return end
	if not IsValid(victim) or not victim:IsPlayer() then return end
	if attacker == victim then return end
	if !attacker:IsBerserk() then return end

	timer.Simple(0, function()
		if IsValid(attacker) and IsValid(victim) and not victim:Alive() then
			attacker.BerserkKills = (attacker.BerserkKills or 0) + 1
			attacker:NotifyBerserk(numerical[attacker.BerserkKills] or (attacker.BerserkKills .. "."))

			attacker.organism.berserk = attacker.organism.berserk + 0.5
		end
	end)
end)

hook.Add("Org Think", "Main", function(owner, org, timeValue)
	if not IsValid(owner) then
		hg.organism.list[owner] = nil
		return
	end

	if owner:IsPlayer() and not owner:Alive() then return end

	local isPly = owner:IsPlayer()

	org.isPly = isPly

	if isPly or org.fakePlayer then
		if not org.fakePlayer then
			org.alive = owner:Alive()
		end
	else
		org.alive = false
	end
	
	org.needotrub = false
	org.needfake = false
	if isPly then
		org.ownerFake = org.FakeRagdoll and true
	else
		org.ownerFake = false
	end

	org.timeValue = timeValue
	org.incapacitated = false
	org.critical = false
	hg.organism.UpdateBodyPosition(owner, org, timeValue)

	if isPly then
		module.stamina[2](owner, org, timeValue)
	end

	if isPly or org.fakePlayer then
		module.lungs[2](owner, org, timeValue)
	end

	if isPly then
		module.liver[2](owner, org, timeValue)
	end

	--module.blood[3](owner,org,timeValue)--arteria
	module.blood[2](owner, org, timeValue)

	module.pain[2](owner, org, timeValue)
	if isPly then
		module.metabolism[2](owner, org, timeValue)
		module.random_events[2](owner, org, timeValue)
	end
	module.pulse[2](owner, org, timeValue)
	hg.organism.UpdatePerfusion(owner, org, timeValue)

	if org.owner.PlayerClassName == "furry" then
		org.assimilated = 0
	end

	if org.owner.PlayerClassName != "furry" and org.furryinfected then
		org.assimilated = math.Approach(org.assimilated, 1, timeValue / 30 * org.pulse / 70)

		if org.assimilated == 1 then
			hg.Furrify(org.owner)

			org.furryinfected = false
		end
	else
		if (org.lightstun - CurTime()) <= 0 then
			org.assimilated = math.Approach(org.assimilated, 0, (timeValue / 60 * org.pulse / 70) * 6)
		end
	end

	if org.assimilated == 1 then
		org.assimilated = 0
		org.owner:SetPlayerClass("furry")
	end

	org.berserk = math.Approach(org.berserk, 0, timeValue / 60)
	org.noradrenaline = math.Approach(org.noradrenaline, 0, timeValue / 45)

	if org.berserk > 0 and !org.berserkActive then
		org.berserkActive = true

		owner.lastBerserkLaughSoundCD = CurTime() + 5

		timer.Simple(3.95, function()
			org.berserkActive2 = true
		end)
	elseif org.berserk <= 0 then
		org.berserkActive = false
		org.berserkActive2 = false
		owner.BerserkKills = nil
	end

	if org.noradrenaline > 0 and !org.noradrenalineActive then
		org.noradrenalineActive = true
	elseif org.noradrenaline <= 0 then
		org.noradrenalineActive = false
	end

	if (org.llegamputated or org.rlegamputated) and org.berserk <= 0.3 then
		org.needfake = true
	end

	if org.rarmamputated and org.larmamputated and owner:IsPlayer() then
		local hands = owner:GetWeapon("weapon_hands_sh")
		if owner:GetActiveWeapon() != hands then
			owner:SetActiveWeapon(hands)
		end
	end

	--[[if isPly then
		local aimed = false

		local entities = ents.FindInCone(owner:EyePos(), owner:GetAimVector(), 128, math.cos(math.rad(90)))
		for i, ent in ipairs(entities) do
			if !ent:IsPlayer() then continue end
			if ent == owner then continue end

			if ishgweapon(ent:GetActiveWeapon()) and ent:GetAimVector():Dot((ent:EyePos() - owner:EyePos()):GetNormalized()) < -0.95 then
				aimed = true
			end
		end

		if aimed then
			owner.aimed_at = owner.aimed_at or 0
			owner.aimed_at = math.Approach(owner.aimed_at, 1, timeValue / 5)
			org.fearadd = org.fearadd + timeValue * 2
		else
			owner.aimed_at = owner.aimed_at or 0
			owner.aimed_at = math.Approach(owner.aimed_at, 0, timeValue / 5)
		end
	end--]]
	--bullshit

	if org.otrub then
		org.uncon_timer = org.uncon_timer or 0
		org.uncon_timer = org.uncon_timer + timeValue
	else
		org.uncon_timer = 0
	end

	if isPly then
		local juggernautBlackoutUntil = owner.HMCD_JuggernautBlackoutUntil or 0
		local fiberwireBlackoutUntil = owner.HMCD_FiberwireBlackoutUntil or 0
		local neckBlackoutUntil = math.max(juggernautBlackoutUntil, fiberwireBlackoutUntil)
		if neckBlackoutUntil > CurTime() then
			org.needotrub = true
			org.needfake = true
			org.consciousness = math.min(org.consciousness or 1, 0.08)
			org.brainoxygen = math.min(org.brainoxygen or 1, 0.18)
			org.hypoxiaTime = math.max(org.hypoxiaTime or 0, 18)
			org.severeHypoxiaTime = math.max(org.severeHypoxiaTime or 0, 6)
			org.stun = math.max(org.stun or 0, neckBlackoutUntil)
		else
			if juggernautBlackoutUntil > 0 then
				owner.HMCD_JuggernautBlackoutUntil = nil
			end
			if fiberwireBlackoutUntil > 0 then
				owner.HMCD_FiberwireBlackoutUntil = nil
			end
		end
	end

	local just_went_uncon = not org.otrub and org.needotrub
	local just_woke_up = not org.needotrub and org.otrub and (org.uncon_timer or 0) > 6
	if isPly and just_went_uncon then hook.Run("HG_OnOtrub", owner); hook.Run("PlayerDropWeapon", owner) end
	if isPly and just_woke_up then hook.Run("HG_OnWakeOtrub", owner) end

	org.canmove = (org.spine2 < hg.organism.fake_spine2 and org.spine3 < hg.organism.fake_spine3) and not org.otrub
	org.canmovehead = (org.spine3 < hg.organism.fake_spine3) and not org.otrub
	
	if not (org.canmove and org.canmovehead and (org.stun - CurTime()) < 0) then org.needfake = true end
	if (org.blood < 2700) then org.needfake = true end

	local just_went_uncon = not org.otrub and org.needotrub

	if org.posturing then ---- the decerebrate one
		local ent = hg.GetCurrentCharacter(org.owner)

		local rleg = ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_R_Foot")))
		local lleg = ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_L_Foot")))
		local rarm = ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_R_Hand")))
		local larm = ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_L_Hand")))

		local down = -ent:GetBoneMatrix(ent:LookupBone("ValveBiped.Bip01_Spine")):GetAngles():Forward()
		if IsValid(rleg) and IsValid(rarm) and IsValid(larm) and IsValid(lleg)then
			rleg:ApplyForceCenter(down * 500)
			lleg:ApplyForceCenter(down * 500)
			rarm:ApplyForceCenter(down * 500)
			larm:ApplyForceCenter(down * 500)
		end
	end

	if org.brain < 0.4 then
		local naturalHeal = org.thiamine > 0 and timeValue / 480 or timeValue / 1800
		--full heal in ~30 minutes (really fast tho) -- Well, the round doesn’t last that long even in some scrappers, what kind of down came up with that
		--8 minutes with thiamine -- EVEN THAT DOESN'T ALWAYS LAST

		org.thiamine = math.Approach(org.thiamine, 0, timeValue / 240)
		-- you'd need to give 1 thiamine each 4 minutes

		if org.liver < 1 then org.liver = math.Approach(org.liver, 0, naturalHeal) end
		if org.heart < 1 then org.heart = math.Approach(org.heart, 0, naturalHeal) end
		if org.stomach < 1 then org.stomach = math.Approach(org.stomach, 0, naturalHeal) end
		if org.intestines < 1 then org.intestines = math.Approach(org.intestines, 0, naturalHeal) end
		if org.lungsR[1] < 1 then org.lungsR[1] = math.Approach(org.lungsR[1], 0, naturalHeal) end
		if org.lungsL[1] < 1 then org.lungsL[1] = math.Approach(org.lungsL[1], 0, naturalHeal) end
	end

	if org.otrub and isPly and org.owner:Alive() then
		--org.owner:ScreenFade(SCREENFADE.PURGE, color_black, 0.5, 0)
		--org.owner:ConCommand("soundfade 100 99999")
	end

	if not org.otrub and isPly and org.owner:Alive() then
		--org.owner:ConCommand("soundfade 0 1")
	end

	if just_went_uncon then
		org.owner.fullsend = true
	end

	if org.brain > 0.05 then
		if math.random(600) < org.brain * 20 then
			org.needfake = true
		end
	end

	org.otrub = org.needotrub
	org.fake = org.needfake
	
	if org.needfake and owner:IsNPC() then
		local dmgInfo = DamageInfo()
		dmgInfo:SetDamage(10000)
		dmgInfo:SetAttacker(owner)
		owner:TakeDamageInfo(dmgInfo)
	end

	if owner:IsPlayer() and (org.healthRegen or 0) < CurTime() then
		org.healthRegen = CurTime() + 30
		owner:SetHealth(math.min(owner:GetMaxHealth(), owner:Health() + math.max(1.5 - org.hurt, 0)))
	end

	org.health = owner:Health()
	local rag = owner:IsPlayer() and owner.FakeRagdoll or owner
	if IsValid(rag) and rag:IsRagdoll() and (not owner.lastFake or owner.lastFake == 0) then
		local wantedCollisionGroup = (rag:GetVelocity():LengthSqr() > (200 * 200)) and COLLISION_GROUP_NONE or COLLISION_GROUP_WEAPON
		if rag:GetCollisionGroup() ~= wantedCollisionGroup then
			hg.ApplySetCollisionGroupNow(rag, wantedCollisionGroup)
		end
	end
	if isPly then
		if org.otrub or org.fake then hg.Fake(owner,nil,true) end
		if not org.alive and owner:Alive() then owner:Kill() end
	end

	if not org.otrub and isPly then
		local mul = hg.likely_to_phrase(owner)

		if not org.likely_phrase then org.likely_phrase = 0 end

		org.likely_phrase = math.max(org.likely_phrase + math.Rand(0, mul) / 100, 0)
		--print(org.likely_phrase)
		if org.likely_phrase >= 1 and !hg.GetCurrentCharacter(owner):IsOnFire() then
			org.likely_phrase = 0

			local str = hg.get_status_message(owner)
			--print(str)
			-- (msg, delay, msgKey, showTime, func, clr)
			owner:Notify(str, 1, "phrase", 1, nil, Color(255, math.Clamp(1 / hg.likely_to_phrase(owner) * 255, 0, 255), math.Clamp(1 / hg.likely_to_phrase(owner) * 255, 0, 255), 255))
		end
	end

	if !org.alive then org.otrub = true end

	if !org.alive then
		org.lungsfunction = false
		org.heartstop = true
	end

	time = CurTime()

	if IsValid(owner) then
		org.sendPlyTime = org.sendPlyTime or CurTime()
		if (org.sendPlyTime > time) and !just_went_uncon then return end
		org.sendPlyTime = CurTime() + 1 + (not isPly and 2 or 0)
		send_bareinfo(org)

		org.owner:SetNetVar("wounds", org.wounds)
		org.owner:SetNetVar("arterialwounds", org.arterialwounds)

		if isPly and owner:Alive() then
			send_organism(org, owner)
		end
	end
end)

hook.Add("Org Think", "regenerationberserk", function(owner, org, timeValue)
	if not owner:IsPlayer() or not owner:Alive() then return end
	if !owner:IsBerserk() then return end
	--if org.heartstop then return end

	org.blood = math.Approach(org.blood, 5000, timeValue * 60)

	for i, wound in pairs(org.wounds) do
		wound[1] = math.max(wound[1] - timeValue * 10,0)
	end

	for i, wound in pairs(org.arterialwounds) do
		wound[1] = math.max(wound[1] - timeValue * 10,0)
	end

	org.internalBleed = math.max(org.internalBleed - timeValue * 10, 0)

	local regen = timeValue / 120 * org.berserk

	org.lleg = math.max(org.lleg - regen, 0)
	org.rleg = math.max(org.rleg - regen, 0)
	org.rarm = math.max(org.rarm - regen, 0)
	org.larm = math.max(org.larm - regen, 0)
	org.chest = math.max(org.chest - regen, 0)
	org.pelvis = math.max(org.pelvis - regen, 0)
	org.spine1 = math.max(org.spine1 - regen, 0)
	org.spine2 = math.max(org.spine2 - regen, 0)
	org.spine3 = math.max(org.spine3 - regen, 0)
	org.skull = math.max(org.skull - regen, 0)

	org.liver = math.max(org.liver - regen, 0)
	org.intestines = math.max(org.intestines - regen, 0)
	org.heart = math.max(org.heart - regen, 0)
	org.stomach = math.max(org.stomach - regen, 0)
	org.lungsR[1] = math.max(org.lungsR[1] - regen, 0)
	org.lungsL[1] = math.max(org.lungsL[1] - regen, 0)
	org.lungsR[2] = math.max(org.lungsR[2] - regen, 0)
	org.lungsL[2] = math.max(org.lungsL[2] - regen, 0)
	org.brain = math.max(org.brain - regen, 0)

	org.hungry = 0

	org.pain = math.Approach(org.pain, 0, timeValue * 10)
	org.painadd = math.Approach(org.painadd, 0, timeValue * 10)
	org.avgpain = math.Approach(org.avgpain, 0, timeValue * 10)
	org.shock = math.Approach(org.shock, 0, timeValue * 10)
	org.immobilization = math.Approach(org.immobilization, 0, timeValue * 10)
	org.disorientation = math.Approach(org.disorientation, 0, timeValue * 10)

	org.lungsfunction = true
	org.heartstop = false

	owner:SetRunSpeed(math.min(500, 400 + (25 * org.berserk)))
end)

hook.Add("Org Think", "regenerationnoradrenaline", function(owner, org, timeValue)
	if not owner:IsPlayer() or not owner:Alive() then return end
	if org.noradrenaline <= 0 then return end
	
	local regen = timeValue / 60 * org.noradrenaline

	org.lungsR[1] = math.max(org.lungsR[1] - regen, 0)
	org.lungsL[1] = math.max(org.lungsL[1] - regen, 0)
	org.lungsR[2] = math.max(org.lungsR[2] - regen, 0)
	org.lungsL[2] = math.max(org.lungsL[2] - regen, 0)

	org.hungry = 0

	org.pain = math.Approach(org.pain, 0, regen * 10)
	org.painadd = math.Approach(org.painadd, 0, regen * 10)
	org.avgpain = math.Approach(org.avgpain, 0, regen * 10)
	org.shock = math.Approach(org.shock, 0, regen * 10)
	org.immobilization = math.Approach(org.immobilization, 0, regen * 10)
	org.disorientation = math.Approach(org.disorientation, 0, regen * 10)
	org.adrenaline = math.Approach(org.adrenaline, 5, regen * 100)
	org.analgesia = math.Approach(org.analgesia, 1, regen * 10)

	if org.noradrenaline > 2 then
		org.brain = math.Approach(org.brain, 0.3, timeValue / 60)
	end

	org.pulse = math.Approach(org.pulse, 70, regen * 10)
	org.heartbeat = math.Approach(org.heartbeat, 220, regen * 10)
	--org.stamina.regen = math.Approach(org.stamina.regen, 1.2, regen * 10)

	org.lungsfunction = true
	org.heartstop = false
end)

concommand.Add("hg_organism_setvalue", function(ply, cmd, args)
	if not ply:IsAdmin() then return end

	if not args[3] then
		if isbool(ply.organism[args[1]]) then
			ply.organism[args[1]] = tonumber(args[2]) != 0
		else
			ply.organism[args[1]] = tonumber(args[2])
		end
	end

	if args[3] then
		for i,pl in pairs(player.GetListByName(args[3])) do
			if isbool(pl.organism[args[1]]) then
				pl.organism[args[1]] = tonumber(args[2]) != 0
			else
				pl.organism[args[1]] = tonumber(args[2])
			end
		end
	end
end)

concommand.Add("hg_organism_setvalue2", function(ply, cmd, args)
	if not ply:IsAdmin() then return end

	ply.organism[args[1]][tonumber(args[2])] = tonumber(args[3])
end)

concommand.Add("hg_organism_clear", function(ply, cmd, args)
	if not ply:IsAdmin() then return end

	if not args[1] then
		hg.organism.Clear(ply.organism)
	end

	if args[1] then
		for i,pl in pairs(player.GetListByName(args[1])) do
			hg.organism.Clear(pl.organism)
		end
	end
end)

hook.Add("SetupMove", "hg-speed", function(ply, mv) end) --mv:SetMaxClientSpeed(100) --mv:SetMaxSpeed(100)

hook.Add("StartCommand","hg_lol",function(ply,cmd)
	if ply.organism.otrub and ply:Alive() then
		cmd:ClearMovement()
	end
end)

hook.Add("PlayerDeath","next-respawn-full",function(ply)
	ply.fullsend = true
	ply.HMCD_FiberwireBlackoutUntil = nil
end)

hook.Add("PlayerSpawn", "fiberwire-blackout-clear", function(ply)
	ply.HMCD_FiberwireBlackoutUntil = nil
end)

hook.Add("HG_OnWakeOtrub", "afterOtrub", function( owner )
	owner.organism.after_otrub = true
	local str = hg.get_status_message(owner)
	owner.organism.after_otrub = nil
	--print(str)
	-- (msg, delay, msgKey, showTime, func, clr)
	timer.Simple(0.1,function()
		if not IsValid(owner) then return end
		owner:Notify(str, 1, "wake", 1, nil, Color(255, math.Clamp(1 / hg.likely_to_phrase(owner) * 255, 0, 255), math.Clamp(1 / hg.likely_to_phrase(owner) * 255, 0, 255)) )
	end)

	owner.organism.fearadd = owner.organism.fearadd + 5

	owner:SendLua("system.FlashWindow()")
end)

hook.Add("HG_OnOtrub", "fearful", function( plya )--European Championship
	local ent = hg.GetCurrentCharacter(plya)
	for i,ply in ipairs(ents.FindInSphere(ent:GetPos(),256)) do
		if not ply:IsPlayer() or not ply.organism or plya == ply then continue end

		local tr = {}
		tr.start = ply:GetPos()
		tr.endpos = ent:GetPos()
		tr.filter = {ply,ent}
		if not util.TraceLine(tr).Hit then
			ply.organism.adrenalineAdd = ply.organism.adrenalineAdd + 0.3
			ply.organism.fearadd = ply.organism.fearadd + 0.3
		end
	end
end)

local unlucky_dislocations = {
	"Why can't I fix this goddamn dislocation...",
	"Please... why is it so hard.",
	"Just go back in place already...",
	"This is irritating",
	"I should try again",
}

local finally_fixed = {
	"Finally.",
	"That was harder than I thought",
	"One dislocation away.",
}

local function fixlimb(org, key, fixer)
	if math.random(100) > (97 + (fixer != org.owner and (fixer.organism and fixer.organism.pain or 0) or 0) - (org.analgesia * 50 + org.painkiller * 15) - (fixer != org.owner and 30 or 0) - (fixer.tries or 0) * 10 - (fixer.Profession == "doctor" and 100 or 0) - (org.owner == fixer and (IsValid(org.owner.FakeRagdoll) or (org.owner.Crouching and org.owner:Crouching())) and 10 or 0)) then
		org[key.."dislocation"] = false
		org.painadd = org.painadd + 5 * math.random(1, 3)
		org.fearadd = org.fearadd + 0.1

		org.owner:EmitSound("physics/flesh/flesh_impact_hard6.wav", 65)

		if fixer == org.owner and (fixer.tries or 0) > 3 and math.random(3) == 1 then
			fixer:Notify(finally_fixed[math.random(#finally_fixed)], 1, "dislocations_unlucky", 1, nil, Color(255, 255, 255, 255))
		end

		fixer.tries = 0
	else
		fixer.tries = (fixer.tries or 0) + 1
		org.painadd = org.painadd + 15 * math.random(1, 3)

		org.fearadd = org.fearadd + 0.3

		org.owner:EmitSound("physics/body/body_medium_impact_soft"..math.random(7)..".wav", 65)
		
		if fixer.Profession != "doctor" and math.random(5) == 1 then
			local dmgInfo = DamageInfo()
			dmgInfo:SetDamage(50)
			dmgInfo:SetDamageType(DMG_CLUB)
			hg.organism.input_list[key.."down"](org.owner.organism, 1, 6, dmgInfo, 0, vector_up)
		end

		if fixer == org.owner and fixer.tries > 3 and math.random(3) == 1 then
			fixer:Notify(unlucky_dislocations[math.random(#unlucky_dislocations)], 1, "dislocations_unlucky", 1, nil, Color(255, 255, 255, 255))
		end
	end
end

concommand.Add("hg_fixdislocation", function(ply, cmd, args)
	local fixer = ply

	if math.Round(tonumber(args[2])) == 1 then
		ply = hg.eyeTrace(fixer).Entity
	end

	if !IsValid(ply) or !ply.organism then return end

	ply = ply.organism.owner

	local org = ply.organism
	if !fixer:Alive() or !org or fixer.organism.otrub then return end
	if (fixer.tried_fixing_limb or 0) > CurTime() then return end
	if !fixer.organism.canmove or !fixer.organism.canmovehead or fixer.organism.pain > 60 then return end
	fixer.tried_fixing_limb = CurTime() + fixer.organism.pain / 30

	if math.Round(tonumber(args[1])) == 1 then
		if org.llegdislocation then
			fixlimb(org, "lleg", fixer)
		elseif org.rlegdislocation then
			fixlimb(org, "rleg", fixer)
		end
	elseif math.Round(tonumber(args[1])) == 2 then
		if org.larmdislocation then
			fixlimb(org, "larm", fixer)
		elseif org.rarmdislocation then
			fixlimb(org, "rarm", fixer)
		end
	elseif math.Round(tonumber(args[1])) == 3 then
		if org.jawdislocation then
			fixlimb(org, "jaw", fixer)
		end
	end
end)

hook.Add("OnEntityWaterLevelChanged", "ClearBlood", function(ent, old, new)
	if new >= 2 then
		if ent:IsOnFire() then ent:Extinguish() end
		ent:RemoveAllDecals()
	end
end)
