--local Organism = hg.organism
local function isCrush(dmgInfo)
	return not dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT + DMG_SLASH + DMG_BLAST)
end

local function damageOrgan(org, dmg, dmgInfo, key)
	local prot = math.max(0.3 - org[key],0)
	local oldval = org[key]
	org[key] = math.Round(math.min(org[key] + dmg * (isCrush(dmgInfo) and 1 or 3), 1), 3)
	
	--local damage = org[key] - oldval
	--dmgInfo:SetDamage(dmgInfo:GetDamage() + (damage * 5))

	dmgInfo:ScaleDamage(0.8)

	return 0--isCrush(dmgInfo) and 0 or prot
end

local input_list = hg.organism.input_list
input_list.heart = function(org, bone, dmg, dmgInfo)
	local oldDmg = org.heart

	local result = damageOrgan(org, dmg * 0.3, dmgInfo, "heart")

	hg.AddHarmToAttacker(dmgInfo, (org.heart - oldDmg) * 10, "Heart damage harm")
	
	org.shock = org.shock + dmg * 20
	org.internalBleed = org.internalBleed + (org.heart - oldDmg) * 10

	return result
end

input_list.liver = function(org, bone, dmg, dmgInfo)
	local oldDmg = org.liver
	local prot = math.max(0.3 - org.liver,0)
	
	hg.AddHarmToAttacker(dmgInfo, (org.liver - oldDmg) * 3, "Liver damage harm")
	
	org.shock = org.shock + dmg * 20
	org.painadd = org.painadd + dmg * 35
	
	org.liver = math.min(org.liver + dmg, 1)
	local harmed = (org.liver - oldDmg)
	if org.analgesia < 0.4 and harmed >= 0.2 then
		timer.Simple(0, function()
			if harmed > 0 then -- wtf? whatever
				hg.StunPlayer(org.owner,2)
			else
				hg.LightStunPlayer(org.owner,2)
			end
		end)
	end

	org.internalBleed = org.internalBleed + harmed * 4
	
	dmgInfo:ScaleDamage(0.8)

	return 0
end

input_list.stomach = function(org, bone, dmg, dmgInfo)
	local oldDmg = org.stomach

	local result = damageOrgan(org, dmg, dmgInfo, "stomach")

	hg.AddHarmToAttacker(dmgInfo, (org.stomach - oldDmg) * 2, "Stomach damage harm")
	
	org.internalBleed = org.internalBleed + (org.stomach - oldDmg) * 2
	return result
end

input_list.intestines = function(org, bone, dmg, dmgInfo)
	local oldDmg = org.intestines

	local result = damageOrgan(org, dmg, dmgInfo, "intestines")

	hg.AddHarmToAttacker(dmgInfo, (org.intestines - oldDmg) * 2, "Intestines damage harm")

	org.internalBleed = org.internalBleed + (org.intestines - oldDmg) * 2
	return result
end

local brainLobeProfiles = {
	brainFrontal = {consciousness = 1.2, disorientation = 1.5, shock = 2, pain = 7, hemorrhage = 0.6},
	brainParietal = {consciousness = 1.4, disorientation = 2.2, shock = 2.5, pain = 8, hemorrhage = 0.7},
	brainTemporal = {consciousness = 1.1, disorientation = 1.3, shock = 2.5, pain = 8, hemorrhage = 0.9},
	brainOccipital = {consciousness = 1.3, disorientation = 1.1, shock = 2, pain = 7, hemorrhage = 0.75}
}

local function addBrainHemorrhage(org, amount, rate)
	if not org or not isnumber(amount) or amount <= 0 then return end

	org.brainHemorrhage = math.Clamp((org.brainHemorrhage or 0) + amount, 0, 1)
	org.brainBleedRate = math.Clamp((org.brainBleedRate or 0) + (rate or amount * 0.0015), 0, 0.008)
	org.brainSwelling = math.Clamp((org.brainSwelling or 0) + amount * 0.15, 0, 1)

	if IsValid(org.owner) then org.owner.fullsend = true end
end

hg.organism.AddBrainHemorrhage = addBrainHemorrhage

local function damageBrainLobe(org, bone, dmg, dmgInfo, key)
	local profile = brainLobeProfiles[key]
	if not profile then return 0 end
	if dmgInfo:IsDamageType(DMG_BLAST) then dmg = dmg / 50 end

	local oldDmg = org[key] or 0
	local result = damageOrgan(org, dmg, dmgInfo, key)
	local delta = math.max((org[key] or 0) - oldDmg, 0)
	local penetrating = dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT + DMG_SLASH)
	org.brainSwelling = math.Clamp((org.brainSwelling or 0) + delta * (penetrating and 0.12 or 0.08), 0, 1)

	if delta >= 0.35 then
		local permanentGain = math.Clamp(math.Remap(delta, 0.35, 1, 0.05, 0.75), 0.05, 0.75)
		org.brain = math.Clamp((org.brain or 0) + permanentGain, 0, 1)
	end
	org.consciousness = math.Approach(org.consciousness or 1, 0, delta * profile.consciousness)
	org.disorientation = (org.disorientation or 0) + delta * profile.disorientation
	org.shock = (org.shock or 0) + dmg * profile.shock
	org.painadd = (org.painadd or 0) + dmg * profile.pain

	hg.AddHarmToAttacker(dmgInfo, delta * 15, key .. " damage harm")

	local impact = dmgInfo:IsDamageType(DMG_CLUB + DMG_BLAST + DMG_CRUSH)
	local hemorrhageChance = penetrating and math.Clamp(0.25 + delta * 1.6, 0, 0.95)
		or impact and math.Clamp(0.03 + delta * profile.hemorrhage, 0, 0.6)
		or 0.01

	if delta > 0 and math.Rand(0, 1) <= hemorrhageChance then
		addBrainHemorrhage(org, delta * profile.hemorrhage, delta * (penetrating and 0.003 or 0.0012))
	end

	if hg.organism.AddSeizure and delta > 0 then
		local instability = key == "brainTemporal" and 1.8 or key == "brainParietal" and 1.45 or key == "brainFrontal" and 1.15 or 1.1
		local severeGain = delta >= 0.35 and math.Clamp(math.Remap(delta, 0.35, 0.75, 0.15, 0.5), 0.15, 0.5) or 0
		hg.organism.AddSeizure(org, delta * instability + severeGain)
	end

	if key == "brainTemporal" and delta > 0.02 and math.random(2) == 1 and IsValid(org.owner) and org.owner.AddTinnitus then
		org.owner:AddTinnitus(math.Clamp(delta * 35, 1.5, 12), true)
	end

	if dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT) then
		local dmgPos = dmgInfo:GetDamagePosition()
		local dirCool = dmgInfo:GetDamageForce():GetNormalized()

		local effdata = EffectData()
		effdata:SetOrigin(dmgPos)
		effdata:SetRadius(dmg / 10)
		effdata:SetMagnitude(dmg / 10)
		effdata:SetScale(1)
		util.Effect("BloodImpact",effdata)

		local ent = hg.GetCurrentCharacter(org.owner)

		if IsValid(ent) and ent.organism and not ent.organism.SpawnedBrainChunks and math.random(5) == 1 then
			SpawnMeatGore(ent, dmgPos + dirCool * 5, 3, dirCool * 1000, 0.4)
			ent.organism.SpawnedBrainChunks = true
		end
	end

	if (org.brain or 0) >= 0.01 and delta > 0.01 and math.random(3) == 1 then
		org.shock = 70
	end

	return result
end

input_list.brainFrontal = function(org, bone, dmg, dmgInfo) return damageBrainLobe(org, bone, dmg, dmgInfo, "brainFrontal") end
input_list.brainParietal = function(org, bone, dmg, dmgInfo) return damageBrainLobe(org, bone, dmg, dmgInfo, "brainParietal") end
input_list.brainTemporal = function(org, bone, dmg, dmgInfo) return damageBrainLobe(org, bone, dmg, dmgInfo, "brainTemporal") end
input_list.brainOccipital = function(org, bone, dmg, dmgInfo) return damageBrainLobe(org, bone, dmg, dmgInfo, "brainOccipital") end
input_list.brain = input_list.brainFrontal

hook.Add("HomigradDamage", "BrainHemorrhageTrauma", function(victim, dmgInfo, hitgroup)
	local ply = IsValid(victim) and victim:IsPlayer() and victim or hg.RagdollOwner and hg.RagdollOwner(victim)
	if not IsValid(ply) or hitgroup ~= HITGROUP_HEAD or not ply.organism then return end

	local org = ply.organism
	if (org.skull or 0) < 0.7 then return end

	local chance = dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT) and 0.18
		or dmgInfo:IsDamageType(DMG_CLUB + DMG_BLAST + DMG_CRUSH) and 0.07
		or 0

	chance = chance + math.max((org.skull or 0) - 0.7, 0) * 0.35
	if chance > 0 and math.Rand(0, 1) <= chance then
		addBrainHemorrhage(org, math.Rand(0.015, 0.05), math.Rand(0.0002, 0.001))
	end
end)

local angZero = Angle(0, 0, 0)
local vecZero = Vector(0, 0, 0)
local function getlocalshit(ent, bone, dmgInfo, dir, hit)
	if IsValid(ent) and bone then
		local ent = IsValid(ent.FakeRagdoll) and ent.FakeRagdoll or ent
		local bonePos, boneAng = ent:GetBonePosition(bone)
		local dmgPos = not isbool(hit) and hit or bonePos
		
		local localPos, localAng = WorldToLocal(dmgPos, angZero, bonePos, boneAng)
		local _, dir2 = WorldToLocal(vecZero, dir:Angle(), vecZero, boneAng)
		dir2 = dir2:Forward()
		return localPos, localAng, dir2
	end
end

local arterySize = {
	["arteria"] = 14,
	["rarmartery"] = 6,
	["larmartery"] = 6,
	["rlegartery"] = 9,
	["llegartery"] = 9,
	["spineartery"] = 10,
}

local arteryMessages ={
	"I can feel blood rushing from my neck...",
	"My neck.. it's... pumping out blood.",
	"I'm bleeding out of my neck!"
}

local applyThroatCutEffects

local function hitArtery(artery, org, dmg, dmgInfo, boneindex, dir, hit)
	if isCrush(dmgInfo) then return 1 end
	if dmgInfo:IsDamageType(DMG_BLAST) then return 1 end
	if artery ~= "arteria" and dmgInfo:IsDamageType(DMG_SLASH) and (math.random(5) != 1) and dmg < 2 then return end
	org.painadd = org.painadd + dmg * 1
	if org[artery] == 1 then return 0 end
	if org[string.Replace(artery, "artery", "").."amputated"] then return end

	if artery ~= "arteria" then
		hg.AddHarmToAttacker(dmgInfo, 4, "Random artery punctured harm")--((1 - org[artery]) - math.max((1 - org[artery]) - dmg,0)) / 4
	else
		if org.isPly and not org.otrub then
			org.owner:Notify(table.Random(arteryMessages), true, "arteria", 0)
		end
		
		hg.AddHarmToAttacker(dmgInfo, 15, "Carotid artery punctured harm")
	end

	org[artery] = math.min(org[artery] + 1, 1)

	local owner = org.owner
	local bonea = owner:LookupBone(boneindex)
	local localPos, localAng, dir2 = getlocalshit(owner, bonea, dmgInfo, dir, hit)
	table.insert(org.arterialwounds, {arterySize[artery], localPos, localAng, boneindex, CurTime(), dir2 * 100, artery})
	owner:SetNetVar("arterialwounds", org.arterialwounds)
	if artery == "arteria" and dmgInfo:IsDamageType(DMG_SLASH) and applyThroatCutEffects then
		applyThroatCutEffects(owner, org, dmgInfo, math.Clamp(dmg / 4, 0.65, 1.15))
	end
	--if IsValid(owner:GetNWEntity("RagdollDeath")) then owner:GetNWEntity("RagdollDeath"):SetNetVar("wounds",org.arterialwounds) end
	return 0
end

input_list.arteria = function(org, bone, dmg, dmgInfo, boneindex, dir, hit)
	return hitArtery("arteria", org, dmg, dmgInfo, "ValveBiped.Bip01_Neck1", dir, hit)
end

input_list.rarmartery = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitArtery("rarmartery", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.larmartery = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitArtery("larmartery", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.rlegartery = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitArtery("rlegartery", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.llegartery = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitArtery("llegartery", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.spineartery = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return 0 end--hitArtery("spineartery", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.lungsL = function(org, bone, dmg, dmgInfo)
	local prot = math.max(0.3 - org.lungsL[1],0)
	local oldval = org.lungsL[1]

	hg.AddHarmToAttacker(dmgInfo, (dmg * 0.25), "Lung left damage harm")

	org.lungsL[1] = math.min(org.lungsL[1] + dmg / 4, 1)
	if (dmgInfo:IsDamageType(DMG_BULLET+DMG_SLASH+DMG_BUCKSHOT)) or (math.random(3) == 1) then org.lungsL[2] = math.min(org.lungsL[2] + dmg * 1, 1) end

	org.internalBleed = org.internalBleed + (org.lungsL[1] - oldval) * 2
	
	dmgInfo:ScaleDamage(0.8)

	return 0--isCrush(dmgInfo) and 1 or prot
end

input_list.lungsR = function(org, bone, dmg, dmgInfo)
	local oldval = org.lungsR[1]

	hg.AddHarmToAttacker(dmgInfo, (dmg * 0.25), "Lung right damage harm")

	org.lungsR[1] = math.min(org.lungsR[1] + dmg / 4, 1)
	if (dmgInfo:IsDamageType(DMG_BULLET+DMG_SLASH+DMG_BUCKSHOT)) or (math.random(3) == 1) then org.lungsR[2] = math.min(org.lungsR[2] + dmg * 1, 1) end

	org.internalBleed = org.internalBleed + (org.lungsR[1] - oldval) * 2

	dmgInfo:ScaleDamage(0.8)

	return 0--isCrush(dmgInfo) and 1 or prot
end

input_list.trachea = function(org, bone, dmg, dmgInfo)
	do return 0 end
	local oldDmg = org.trachea

	if dmgInfo:IsDamageType(DMG_BLAST) then dmg = dmg / 5 end

	local result = damageOrgan(org, dmg * 2, dmgInfo, "trachea")

	hg.AddHarmToAttacker(dmgInfo, (org.trachea - oldDmg) * 8, "Trachea damage harm")

	--org.internalBleed = org.internalBleed + dmg * 2

	return result
end

local throatCutMessages = {
	"My throat is open...",
	"I can't breathe... my neck...",
	"Blood is pouring from my throat..."
}

hg.organism.ThroatCutGurgleSounds = {
	female = {
		"neck_slit_female1.wav",
		"neck_slit_female2.wav",
	},
	male = {
		"neck_slit_male1.wav",
		"neck_slit_male2.wav",
	}
}

function hg.organism.GetThroatCutGurgleSound(owner)
	local gender = (ThatPlyIsFemale and ThatPlyIsFemale(owner)) and "female" or "male"
	local sounds = hg.organism.ThroatCutGurgleSounds[gender] or hg.organism.ThroatCutGurgleSounds.male
	local last = IsValid(owner) and owner.HG_LastThroatCutGurgleSound or nil
	local snd = sounds[math.random(#sounds)]

	if #sounds > 1 and snd == last then
		for _, candidate in ipairs(sounds) do
			if candidate ~= last then
				snd = candidate
				break
			end
		end
	end

	if IsValid(owner) then
		owner.HG_LastThroatCutGurgleSound = snd
	end

	return snd
end

local function getThroatCutSoundEmitter(owner)
	if not IsValid(owner) then return nil end

	local ent = hg.GetCurrentCharacter and hg.GetCurrentCharacter(owner) or nil
	if IsValid(ent) then return ent end
	if IsValid(owner.FakeRagdoll) then return owner.FakeRagdoll end

	return owner
end

local function sendThroatCutSoundToClients(snd, pos, level, pitch, volume, target)
	if not SERVER or not snd or not isvector(pos) then return end

	net.Start("HG_ThroatCutSound")
		net.WriteString(snd)
		net.WriteVector(pos)
		net.WriteUInt(math.Clamp(math.floor(level or 74), 1, 255), 8)
		net.WriteUInt(math.Clamp(math.floor(pitch or 100), 1, 255), 8)
		net.WriteFloat(math.Clamp(volume or 1, 0, 1))

	if IsValid(target) then
		net.Send(target)
	else
		net.SendPVS(pos)
	end
end

function hg.organism.EmitThroatCutGurgleSound(owner, level, pitch, volume, target)
	local snd = hg.organism.GetThroatCutGurgleSound(owner)
	local emitter = getThroatCutSoundEmitter(owner)
	local pos = IsValid(emitter) and emitter:WorldSpaceCenter() or (IsValid(owner) and owner:WorldSpaceCenter()) or nil

	if IsValid(emitter) then
		emitter:EmitSound(snd, level or 74, pitch or 100, volume or 1, CHAN_AUTO)
	end
	sendThroatCutSoundToClients(snd, pos, level or 74, pitch or 100, volume or 1, target)
	return snd
end

if SERVER then
	util.AddNetworkString("HG_ThroatCutSound")

	for _, sounds in pairs(hg.organism.ThroatCutGurgleSounds) do
		for _, snd in ipairs(sounds) do
			resource.AddFile("sound/" .. snd)
			util.PrecacheSound(snd)
		end
	end

	concommand.Add("hg_debug_throat_sound", function(ply, cmd, args)
		if IsValid(ply) and not ply:IsAdmin() then return end

		local target = IsValid(ply) and ply or nil
		local gender = string.lower(args[1] or "male")
		if gender ~= "female" then gender = "male" end

		local sounds = hg.organism.ThroatCutGurgleSounds[gender] or hg.organism.ThroatCutGurgleSounds.male
		local idx = math.Clamp(tonumber(args[2]) or math.random(#sounds), 1, #sounds)
		local snd = sounds[idx]
		local pos = IsValid(target) and target:WorldSpaceCenter() or vector_origin

		if IsValid(target) then
			target:EmitSound(snd, 76, 100, 1, CHAN_AUTO)
			sendThroatCutSoundToClients(snd, pos, 76, 100, 1, target)
			target:ChatPrint("Testing throat sound: " .. snd)
		else
			sound.Play(snd, pos, 76, 100, 1)
			print("Testing throat sound: " .. snd)
		end
	end)
end

applyThroatCutEffects = function(owner, org, dmgInfo, severity)
	if not IsValid(owner) or not org or not org.alive or org.superfighter then return false end

	local firstCut = not org.throatcut
	local time = CurTime()
	severity = math.Clamp(tonumber(severity) or 1, 0.35, 1.25)

	local boostedArtery = false
	for _, wound in pairs(org.arterialwounds) do
		if wound[7] == "arteria" then
			wound[1] = math.max(wound[1] or 0, 24 * severity)
			wound[5] = math.min(wound[5] or time, time - 1)
			boostedArtery = true
		end
	end

	if boostedArtery then
		owner:SetNetVar("arterialwounds", org.arterialwounds)
	end

	local oldTrachea = org.trachea or 0
	org.trachea = math.min(math.max(oldTrachea, 0.72 * severity), 1)
	hg.AddHarmToAttacker(dmgInfo, math.max(org.trachea - oldTrachea, 0) * 12, "Throat cut trachea harm")

	org.throatcut = true
	org.throatCutTime = org.throatCutTime and org.throatCutTime > 0 and org.throatCutTime or time
	org.throatCutUntil = time + 24
	org.throatCutSeverity = math.max(org.throatCutSeverity or 0, severity)
	org.throatCutPressureShock = math.max(org.throatCutPressureShock or 0, severity)
	org.shock = math.min(math.max(org.shock or 0, 40 * severity), 90)
	org.fearadd = (org.fearadd or 0) + 1.5 * severity
	org.bloodpressure = math.min(org.bloodpressure or 1, 0.45)
	org.brainoxygen = math.min(org.brainoxygen or 1, 0.55)

	if org.o2 and org.o2[1] then
		org.o2[1] = math.max(org.o2[1] - 6 * severity, 0)
	end

	if firstCut then
		for i = 1, 3 do
			hg.organism.AddWoundManual(owner, 45 * severity, VectorRand(-1.5, 1.5), Angle(90, 0, 0), "ValveBiped.Bip01_Neck1", time + math.Rand(0, 0.25))
		end

		if org.isPly and not org.otrub and owner.Notify then
			owner:Notify(table.Random(throatCutMessages), true, "throatcut", 0)
		end

		hg.organism.EmitThroatCutGurgleSound(owner, 76, math.random(96, 102), 1)
		org.throatCutGurgleNext = time + math.Rand(10, 13)
	end

	owner:SetNWFloat("HG_ThroatCutUntil", org.throatCutUntil)
	hook.Run("HG_ThroatCut", owner, org, dmgInfo, severity)

	return true
end

function hg.organism.CutThroat(ent, dmgInfo, hitPos, dir, severity)
	local owner = hg.RagdollOwner and hg.RagdollOwner(ent) or ent
	if not IsValid(owner) or not owner.organism then return false end

	local org = owner.organism
	if not org.alive or org.superfighter then return false end

	local character = hg.GetCurrentCharacter and hg.GetCurrentCharacter(owner) or owner
	if not IsValid(character) then character = owner end
	if not character.LookupBone then return false end

	local neckBone = character:LookupBone("ValveBiped.Bip01_Neck1") or character:LookupBone("ValveBiped.Bip01_Head1")
	if not neckBone then return false end

	local bonePos, boneAng = character:GetBonePosition(neckBone)
	if not bonePos then return false end

	severity = math.Clamp(tonumber(severity) or 1, 0.35, 1.25)
	local time = CurTime()
	local cutPos = isvector(hitPos) and hitPos or (bonePos + boneAng:Forward() * 2 - boneAng:Right() * 1)
	local cutDir = isvector(dir) and dir:GetNormalized() or -boneAng:Forward()

	dmgInfo = dmgInfo or DamageInfo()
	dmgInfo:SetDamageType(DMG_SLASH)

	input_list.arteria(org, 0, 6 * severity, dmgInfo, "ValveBiped.Bip01_Neck1", cutDir, cutPos)
	if org.throatcut then return true end

	return applyThroatCutEffects(owner, org, dmgInfo, severity)
end
