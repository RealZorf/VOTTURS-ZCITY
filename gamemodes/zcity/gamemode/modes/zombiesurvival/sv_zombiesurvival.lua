local MODE = MODE

function MODE.GuiltCheck(attacker, victim)
	if not IsValid(attacker) or not IsValid(victim) or attacker == victim then
		return 0, false
	end

	if zb.ROUND_STATE ~= 1 then return 0, false end
	if attacker:Team() ~= victim:Team() then return 0, false end
	if attacker:Team() == TEAM_SPECTATOR then return 0, false end

	return 1, true
end

MODE.LootTable = {
	{36, {
		{14, "weapon_bandage_sh"},
		{10, "weapon_tourniquet"},
		{9, "weapon_painkillers"},
		{8, "weapon_bigbandage_sh"},
		{7, "weapon_bloodbag"},
		{5, "weapon_medkit_sh"},
		{3, "weapon_morphine"},
		{2, "weapon_adrenaline"},
		{10, "weapon_smallconsumable"},
		{8, "weapon_bigconsumable"}
	}},
	{28, {
		{12, "weapon_hammer"},
		{14, "ent_ammo_nails"},
		{8, "weapon_ducttape"},
		{8, "hg_flashlight"},
		{5, "hg_sling"},
		{4, "weapon_walkie_talkie"},
		{3, "weapon_hg_extinguisher"},
		{2, "weapon_matches"},
		{2, "weapon_zippo_tpik"}
	}},
	{24, {
		{10, "weapon_bat"},
		{10, "weapon_brick"},
		{8, "weapon_hg_cinderblock"},
		{8, "weapon_hg_tonfa"},
		{7, "weapon_hg_crowbar"},
		{7, "weapon_leadpipe"},
		{6, "weapon_batmetal"},
		{5, "weapon_hatchethmcd"},
		{5, "weapon_hg_machete"},
		{4, "weapon_hg_axe"},
		{4, "weapon_hg_shovel"},
		{3, "weapon_hg_sledgehammer"}
	}},
	{18, {
		{12, "ent_ammo_9x19mmparabellum"},
		{8, "ent_ammo_9x18mm"},
		{7, "ent_ammo_.45acp"},
		{10, "ent_ammo_12/70gauge"},
		{3, "ent_ammo_12/70slug"},
		{4, "ent_ammo_5.56x45mm"},
		{4, "ent_ammo_7.62x39mm"}
	}},
	{14, {
		{10, "weapon_zoraki"},
		{9, "weapon_mp-80"},
		{9, "weapon_osapb"},
		{8, "weapon_makarov"},
		{7, "weapon_m1911"},
		{6, "weapon_glock17"},
		{5, "weapon_glock26"},
		{5, "weapon_cz75"}
	}},
	{8, {
		{8, "weapon_remington870"},
		{7, "weapon_m590a1"},
		{7, "weapon_ithaca37"},
		{5, "weapon_doublebarrel"},
		{4, "weapon_toz106"},
		{3, "weapon_spas12"}
	}},
	{6, {
		{8, "ent_armor_helmet5"},
		{7, "ent_armor_helmet7"},
		{6, "ent_armor_vest3"},
		{4, "ent_armor_vest4"},
		{3, "ent_armor_vest1"}
	}},
	{2, {
		{5, "weapon_adar215"},
		{4, "weapon_vpo136"},
		{3, "weapon_mini30762"}
	}}
}

util.AddNetworkString("ZCity_ZS_RequestConsume")
util.AddNetworkString("ZCity_ZS_RequestSpawn")
util.AddNetworkString("ZCity_ZS_CheckSpawn")
util.AddNetworkString("ZCity_ZS_SpawnStatus")

local survivorColor = Color(30, 220, 100)
local zombieColor = Color(190, 35, 35)
local fastZombieColor = Color(255, 65, 35)
local poisonZombieColor = Color(120, 190, 45)
local respawnTimerPrefix = "ZCityZombieSurvivalRespawn_"
local preInfectionRespawnTimerPrefix = "ZCityZombieSurvivalPreRespawn_"
local lateJoinTimerPrefix = "ZCityZombieSurvivalLateJoin_"
local consumeTimerPrefix = "ZCityZombieSurvivalConsume_"
local voiceTimerPrefix = "ZCityZombieSurvivalVoice_"
local infectionTimerName = "ZCityZombieSurvivalInfection"
local spawnHullMins = Vector(-16, -16, 4)
local spawnHullMaxs = Vector(16, 16, 72)
local spawnViewOffset = Vector(0, 0, 48)
local spawnVisibilityOffsets = {
	Vector(0, 0, 10),
	Vector(0, 0, 42),
	Vector(0, 0, 68)
}
local cameraSpawnOffsets = {vector_origin}
local zombieSpawnClasses = {
	"info_player_start", "info_player_deathmatch", "info_player_combine", "info_player_rebel",
	"info_player_counterterrorist", "info_player_terrorist", "info_player_axis", "info_player_allies",
	"gmod_player_start", "info_player_teamspawn", "ins_spawnpoint", "aoc_spawnpoint",
	"dys_spawn_point", "info_player_pirate", "info_player_viking", "info_player_knight",
	"diprip_start_team_blue", "diprip_start_team_red", "info_player_red", "info_player_blue",
	"info_player_coop", "info_player_human", "info_player_zombie", "info_player_zombiemaster",
	"info_player_fof", "info_player_desperado", "info_player_vigilante", "info_survivor_rescue"
}

for radius = 16, 64, 16 do
	for step = 0, 7 do
		local angle = math.rad(step * 45)
		cameraSpawnOffsets[#cameraSpawnOffsets + 1] = Vector(math.cos(angle) * radius, math.sin(angle) * radius, 0)
	end
end
local classicZombieVoiceSounds = {}
local fastZombieVoiceSounds = {
	"npc/fast_zombie/idle1.wav",
	"npc/fast_zombie/idle2.wav",
	"npc/fast_zombie/idle3.wav",
	"npc/fast_zombie/fz_alert_far1.wav",
	"npc/fast_zombie/fz_alert_close1.wav"
}
local poisonZombieVoiceSounds = {
	"npc/zombie_poison/pz_idle2.wav",
	"npc/zombie_poison/pz_idle3.wav",
	"npc/zombie_poison/pz_idle4.wav",
	"npc/zombie_poison/pz_alert1.wav",
	"npc/zombie_poison/pz_alert2.wav"
}

for index = 1, 14 do
	classicZombieVoiceSounds[#classicZombieVoiceSounds + 1] = "npc/zombie/zombie_voice_idle" .. index .. ".wav"
end

for index = 1, 3 do
	classicZombieVoiceSounds[#classicZombieVoiceSounds + 1] = "npc/zombie/zombie_alert" .. index .. ".wav"
end

local function RespawnTimerName(ply)
	return respawnTimerPrefix .. ply:UserID()
end

local function PreInfectionRespawnTimerName(ply)
	return preInfectionRespawnTimerPrefix .. ply:UserID()
end

local function LateJoinTimerName(ply)
	return lateJoinTimerPrefix .. ply:UserID()
end

local function ConsumeTimerName(ply)
	return consumeTimerPrefix .. ply:UserID()
end

local function VoiceTimerName(ply)
	return voiceTimerPrefix .. ply:UserID()
end

local function ClearZombieConsumeState(ply)
	if not IsValid(ply) then return end

	timer.Remove(ConsumeTimerName(ply))
	local data = ply.ZSConsumeData
	if data then
		if IsValid(data.Corpse) and data.Corpse.ZSConsumeUser == ply then
			data.Corpse.ZSConsumeUser = nil
		end
	end

	ply.ZSConsumeData = nil
	ply:SetNWEntity("ZS_ConsumeCorpse", NULL)
	ply:SetNWFloat("ZS_ConsumeStartedAt", 0)
	ply:SetNWFloat("ZS_ConsumeReadyAt", 0)
end

local RestoreZombieBuffs

local function ClearZombieState(ply)
	timer.Remove(RespawnTimerName(ply))
	timer.Remove(PreInfectionRespawnTimerName(ply))
	timer.Remove(LateJoinTimerName(ply))
	timer.Remove(VoiceTimerName(ply))
	ClearZombieConsumeState(ply)
	if RestoreZombieBuffs then RestoreZombieBuffs(ply) end
	ply.ZSIsZombie = nil
	ply.ZSIsPatientZero = nil
	ply.ZSIsPoisonZombie = nil
	ply.ZSZombieClass = nil
	ply.PreZombClass = nil
	ply.ZSDeathHandledAt = nil
	ply.ZSNextVoiceCue = nil
	ply.ZSOutbreakLateJoinSerial = nil
	ply.ZSLateJoinPendingSerial = nil
	ply.ZSLateJoinChangingTeam = nil
	ply.ZSSpawnReady = nil
	ply.ZSNextSpawnRequest = nil
	ply.ZSNextSpawnProbe = nil
	ply:SetNWBool("ZS_IsZombie", false)
	ply:SetNWBool("ZS_IsPatientZero", false)
	ply:SetNWBool("ZS_IsPoisonZombie", false)
	ply:SetNWBool("ZS_SpawnReady", false)
	ply:SetNWFloat("ZS_RespawnAt", 0)
end

local zombiePlayerClasses = {
	headcrabzombie = true,
	fastzombie = true,
	poisonzombie = true,
}

RestoreZombieBuffs = function(ply)
	if not ply.ZSModeBuffApplied then return end

	ply.MeleeDamageMul = ply.ZSModeBaseMeleeDamageMul ~= false and ply.ZSModeBaseMeleeDamageMul or nil
	ply.ClawDoorDamage = ply.ZSModeBaseDoorDamage ~= false and ply.ZSModeBaseDoorDamage or nil
	if ply.ZSModeBaseMaxHealth then ply:SetMaxHealth(ply.ZSModeBaseMaxHealth) end

	ply.ZSModeBuffApplied = nil
	ply.ZSModeBuffClass = nil
	ply.ZSModeBaseMeleeDamageMul = nil
	ply.ZSModeBaseDoorDamage = nil
	ply.ZSModeBaseMaxHealth = nil
end

local function ApplyZombieBuffs(ply, className, refillHealth)
	local buff = MODE.ZombieBuffs[className]
	if not buff then return end

	if not ply.ZSModeBuffApplied then
		ply.ZSModeBuffApplied = true
		ply.ZSModeBaseMeleeDamageMul = ply.MeleeDamageMul == nil and false or ply.MeleeDamageMul
		ply.ZSModeBaseDoorDamage = ply.ClawDoorDamage == nil and false or ply.ClawDoorDamage
		ply.ZSModeBaseMaxHealth = ply:GetMaxHealth()
	end

	local changedClass = ply.ZSModeBuffClass ~= className
	ply.ZSModeBuffClass = className
	ply.MeleeDamageMul = buff.meleeDamage
	if buff.doorDamage then ply.ClawDoorDamage = buff.doorDamage end
	ply:SetMaxHealth(buff.maxHealth)
	if ply:Alive() and (changedClass or refillHealth) then ply:SetHealth(buff.maxHealth) end
end

hook.Add("ZB_PreRoundStart", "ZombieSurvival_RestorePlayerAppearances", function()
	if CurrentRound() ~= MODE then return end

	for _, ply in player.Iterator() do
		local hadZombieClass = zombiePlayerClasses[ply.PlayerClassName] == true
		local wasZombie = ply.ZSIsZombie == true or hadZombieClass
		ClearZombieState(ply)

		if hadZombieClass then
			ply:SetPlayerClass()
		elseif wasZombie and ApplyAppearance then
			ApplyAppearance(ply, nil, nil, nil, true)
		end
	end
end)

local function IsParticipant(ply)
	return IsValid(ply) and ply:Team() ~= TEAM_SPECTATOR and ply:Team() ~= TEAM_UNASSIGNED
end

function MODE:ClearRoundTimers()
	timer.Remove(infectionTimerName)

	for _, ply in player.Iterator() do
		timer.Remove(RespawnTimerName(ply))
		timer.Remove(PreInfectionRespawnTimerName(ply))
		timer.Remove(LateJoinTimerName(ply))
		timer.Remove(VoiceTimerName(ply))
		ClearZombieConsumeState(ply)
		ply.ZSSpawnReady = nil
		ply:SetNWBool("ZS_SpawnReady", false)
		ply:SetNWFloat("ZS_RespawnAt", 0)
	end
end

local function IsZombieVoiceSpeaker(ply)
	return IsValid(ply)
		and ply:Alive()
		and ply.ZSIsZombie
		and (ply.PlayerClassName == "headcrabzombie" or ply.PlayerClassName == "fastzombie" or ply.PlayerClassName == "poisonzombie")
		and not (ply.organism and ply.organism.otrub)
end

function MODE:EmitZombieVoiceCue(speaker)
	if zb.ROUND_STATE ~= 1 or CurrentRound() ~= self or not IsZombieVoiceSpeaker(speaker) then return false end

	local source = hg.GetCurrentCharacter and hg.GetCurrentCharacter(speaker) or speaker
	if not IsValid(source) then return false end

	local recipients = RecipientFilter()
	local recipientCount = 0
	for _, listener in player.Iterator() do
		if listener == speaker or not IsParticipant(listener) or not listener:Alive() or listener.ZSIsZombie then continue end

		local canHear = hg.CanHearLocalProximityVoice and hg.CanHearLocalProximityVoice(listener, speaker)
		if not canHear then continue end

		recipients:AddPlayer(listener)
		recipientCount = recipientCount + 1
	end

	speaker.ZSNextVoiceCue = CurTime() + 1.25
	if recipientCount == 0 then return false end

	local fast = speaker.PlayerClassName == "fastzombie"
	local poison = speaker.PlayerClassName == "poisonzombie"
	local sounds = poison and poisonZombieVoiceSounds or (fast and fastZombieVoiceSounds or classicZombieVoiceSounds)
	local level = poison and 78 or (fast and 76 or 72)
	local pitchMin = poison and 88 or (fast and 96 or 92)
	local pitchMax = poison and 98 or (fast and 108 or 104)
	source:EmitSound(sounds[math.random(#sounds)], level, math.random(pitchMin, pitchMax), 0.9, CHAN_VOICE, 0, 0, recipients)
	return true
end

function MODE:QueueZombieVoiceCue(speaker, delay)
	if not IsValid(speaker) then return end

	timer.Create(VoiceTimerName(speaker), math.max(delay or 0.1, 0.1), 1, function()
		if not IsZombieVoiceSpeaker(speaker) or not speaker:IsSpeaking() or CurrentRound() ~= MODE then return end

		MODE:EmitZombieVoiceCue(speaker)
		local nextDelay = speaker.PlayerClassName == "fastzombie" and math.Rand(2.1, 3.2) or math.Rand(2.8, 4.2)
		MODE:QueueZombieVoiceCue(speaker, nextDelay)
	end)
end

function MODE:StartVoice(speaker)
	if not IsZombieVoiceSpeaker(speaker) then return end

	timer.Remove(VoiceTimerName(speaker))
	local cooldown = math.max((speaker.ZSNextVoiceCue or 0) - CurTime(), 0)
	if cooldown > 0 then
		self:QueueZombieVoiceCue(speaker, cooldown)
		return
	end

	self:EmitZombieVoiceCue(speaker)
	local nextDelay = speaker.PlayerClassName == "fastzombie" and math.Rand(2.1, 3.2) or math.Rand(2.8, 4.2)
	self:QueueZombieVoiceCue(speaker, nextDelay)
end

function MODE:EndVoice(speaker)
	if not IsValid(speaker) then return end
	timer.Remove(VoiceTimerName(speaker))
end

local function ConsumeZombieCorpse(corpse)
	if not IsValid(corpse) or not corpse:IsRagdoll() then return end

	corpse:SetNWBool("ZS_Consumed", true)
	corpse.ZSConsumeUser = nil
	local center = corpse:WorldSpaceCenter()

	sound.Play("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", center, 72, math.random(78, 92), 0.9)
	for index = 1, 5 do
		local offset = VectorRand(-18, 18)
		util.Decal("Blood", center + offset + Vector(0, 0, 24), center + offset - Vector(0, 0, 58), corpse)
	end

	local effect = EffectData()
	effect:SetOrigin(center)
	effect:SetNormal(vector_up)
	effect:SetScale(10)
	util.Effect("BloodImpact", effect, true, true)

	corpse:SetNoDraw(true)
	corpse:SetNotSolid(true)
	corpse:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	SafeRemoveEntityDelayed(corpse, 0.15)
end

function MODE:StopZombieConsume(ply)
	ClearZombieConsumeState(ply)
end

function MODE:FinishZombieConsume(ply)
	local data = IsValid(ply) and ply.ZSConsumeData
	if not data then return end

	local corpse = data.Corpse
	local victim = data.Victim
	if not IsValid(corpse) or not IsValid(victim) then return end
	if corpse:GetNWBool("ZS_Consumed", false) then return end
	if corpse.ZSConsumeUser ~= ply then return end
	if not self:IsZombieConsumableVictim(victim, corpse) then return end

	corpse:SetNWBool("ZS_Consumed", true)
	corpse.ZSConsumeUser = nil
	ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + (self.ZombieConsumeHealthRestore or 45)))

	local replenishedHeadcrab = false
	if ply.ZSIsPoisonZombie and ply.PlayerClassName == "poisonzombie" then
		local poisonClass = player.classList and player.classList.poisonzombie
		if poisonClass and poisonClass.AddThrowableHeadcrabs then
			replenishedHeadcrab = poisonClass.AddThrowableHeadcrabs(ply, 1) == true
		end
	end

	if victim:Alive() then
		victim.ZSConsumedBy = ply
		victim:Kill()

		timer.Simple(0.08, function()
			if not IsValid(victim) then return end

			local deathRagdoll = victim:GetNWEntity("RagdollDeath", NULL)
			if not IsValid(deathRagdoll) then deathRagdoll = victim.RagdollDeath end
			if not IsValid(deathRagdoll) then deathRagdoll = corpse end
			ConsumeZombieCorpse(deathRagdoll)
		end)
	else
		ConsumeZombieCorpse(corpse)
	end

	local consumeMessage = replenishedHeadcrab
		and "Fresh meat. Health restored. One headcrab replenished."
		or "Fresh meat. Health restored."
	if isfunction(ply.Notify) then
		ply:Notify(consumeMessage, 0, "zs_consumed_body", 2, nil, replenishedHeadcrab and poisonZombieColor or zombieColor)
	else
		ply:ChatPrint(consumeMessage)
	end
end

function MODE:ContinueZombieConsume(ply)
	local data = IsValid(ply) and ply.ZSConsumeData
	if not data then return false end

	local corpse = data.Corpse
	local victim = data.Victim
	local valid = zb.ROUND_STATE == 1
		and CurrentRound() == self
		and ply:Alive()
		and ply.ZSIsZombie
		and not (ply.organism and ply.organism.otrub)
		and ply:KeyDown(IN_WALK)
		and ply:KeyDown(IN_USE)
		and IsValid(corpse)
		and IsValid(victim)
		and corpse.ZSConsumeUser == ply
		and not corpse:GetNWBool("ZS_Consumed", false)
		and self:IsZombieConsumableVictim(victim, corpse)
		and ply:EyePos():DistToSqr(corpse:NearestPoint(ply:EyePos())) <= ((self.ZombieConsumeReach or 100) + 35) ^ 2

	if not valid then
		self:StopZombieConsume(ply)
		return false
	end

	if CurTime() < data.ReadyAt then
		if CurTime() >= (data.NextBiteSound or 0) then
			data.NextBiteSound = CurTime() + 0.7
			corpse:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", 62, math.random(78, 92), 0.6)
		end
		return true
	end

	self:FinishZombieConsume(ply)
	self:StopZombieConsume(ply)
	return false
end

function MODE:StartZombieConsume(ply, requestedCorpse)
	if not IsValid(ply) or not ply:Alive() or not ply.ZSIsZombie or ply.ZSConsumeData then return end
	if ply.organism and ply.organism.otrub then return end

	local corpse, victim
	if IsValid(requestedCorpse) and requestedCorpse:IsRagdoll() then
		corpse = requestedCorpse
		victim = (hg and hg.RagdollOwner and hg.RagdollOwner(corpse)) or corpse.ply
	else
		corpse, victim = self:GetZombieConsumeTarget(ply)
	end

	if not IsValid(corpse) or not IsValid(victim) then return end
	if victim == ply or not self:IsZombieConsumableVictim(victim, corpse) then return end
	if IsValid(corpse.ZSConsumeUser) and corpse.ZSConsumeUser ~= ply then return end

	local eyePos = ply:EyePos()
	local targetPos = corpse:NearestPoint(eyePos)
	if eyePos:DistToSqr(targetPos) > ((self.ZombieConsumeReach or 100) + 35) ^ 2 then return end

	local trace = util.TraceLine({
		start = eyePos,
		endpos = targetPos,
		filter = ply,
		mask = MASK_SHOT
	})
	if trace.Hit and trace.Entity ~= corpse then return end

	local now = CurTime()
	corpse.ZSConsumeUser = ply
	ply.ZSConsumeData = {
		Corpse = corpse,
		Victim = victim,
		StartedAt = now,
		ReadyAt = now + (self.ZombieConsumeTime or 4)
	}

	ply:SetNWEntity("ZS_ConsumeCorpse", corpse)
	ply:SetNWFloat("ZS_ConsumeStartedAt", now)
	ply:SetNWFloat("ZS_ConsumeReadyAt", ply.ZSConsumeData.ReadyAt)

	corpse:EmitSound("npc/barnacle/barnacle_crunch2.wav", 65, math.random(85, 100), 0.7)

	timer.Create(ConsumeTimerName(ply), 0.1, 0, function()
		if not IsValid(ply) then
			timer.Remove(ConsumeTimerName(ply))
			return
		end

		MODE:ContinueZombieConsume(ply)
	end)
end

net.Receive("ZCity_ZS_RequestConsume", function(_, ply)
	local corpse = net.ReadEntity()
	if not IsValid(corpse) or not corpse:IsRagdoll() then return end
	if zb.ROUND_STATE ~= 1 or CurrentRound() ~= MODE or not MODE.InfectionStarted then return end
	if (ply.ZSNextConsumeRequest or 0) > CurTime() then return end

	ply.ZSNextConsumeRequest = CurTime() + 0.2
	MODE:StartZombieConsume(ply, corpse)
end)

function MODE:UpdateZombieConsumeInputs()
	for _, ply in player.Iterator() do
		if not ply.ZSIsZombie or not ply:Alive() then
			if ply.ZSConsumeData then self:StopZombieConsume(ply) end
			continue
		end

		local wantsToConsume = ply:KeyDown(IN_WALK) and ply:KeyDown(IN_USE)
		if wantsToConsume then
			if not ply.ZSConsumeData then self:StartZombieConsume(ply) end
		elseif ply.ZSConsumeData then
			self:StopZombieConsume(ply)
		end
	end
end

function MODE:BuildZombieSpawnCache()
	local points = zb.GetMapPoints and zb.GetMapPoints("Spawnpoint") or {}
	local spawns = {}
	local seen = {}

	local function AddSpawn(pos)
		if not isvector(pos) then return end

		local key = math.Round(pos.x) .. ":" .. math.Round(pos.y) .. ":" .. math.Round(pos.z)
		if seen[key] then return end

		seen[key] = true
		spawns[#spawns + 1] = Vector(pos.x, pos.y, pos.z)
	end

	for _, point in ipairs(points or {}) do
		AddSpawn(point.pos or point)
	end

	if #spawns == 0 then
		for _, className in ipairs(zombieSpawnClasses) do
			for _, ent in ipairs(ents.FindByClass(className)) do
				AddSpawn(ent:GetPos())
			end
		end
	end

	self.ZombieSpawnPoints = spawns
	self.RecentZombieSpawns = {}
end

local function IsZombieSpawnClear(pos, ply)
	if not util.IsInWorld(pos + spawnViewOffset) then return false end

	local trace = util.TraceHull({
		start = pos,
		endpos = pos,
		mins = spawnHullMins,
		maxs = spawnHullMaxs,
		mask = MASK_PLAYERSOLID,
		filter = ply
	})

	return not trace.StartSolid and not trace.Hit
end

local function SurvivorCanSeeSpawn(survivor, pos, visibilityDistanceSqr, viewDot)
	local eyePos = survivor:EyePos()
	local toSpawn = pos + spawnViewOffset - eyePos
	local distanceSqr = toSpawn:LengthSqr()
	if distanceSqr > visibilityDistanceSqr then return false end

	if distanceSqr > 1 then
		local aim = survivor:GetAimVector()
		if aim:Dot(toSpawn / math.sqrt(distanceSqr)) < viewDot then return false end
	end

	local character = hg.GetCurrentCharacter and hg.GetCurrentCharacter(survivor)
	local filter = IsValid(character) and {survivor, character} or survivor

	for _, offset in ipairs(spawnVisibilityOffsets) do
		local trace = util.TraceLine({
			start = eyePos,
			endpos = pos + offset,
			mask = MASK_VISIBLE_AND_NPCS,
			filter = filter
		})

		if not trace.Hit then return true end
	end

	return false
end

local function IsFiniteSpawnVector(pos)
	if not isvector(pos) then return false end

	return pos.x == pos.x and pos.y == pos.y and pos.z == pos.z
		and math.abs(pos.x) <= 32768
		and math.abs(pos.y) <= 32768
		and math.abs(pos.z) <= 32768
end

local function GetLivingSurvivors()
	local survivors = {}

	for _, survivor in player.Iterator() do
		if IsParticipant(survivor) and survivor:Alive() and not survivor.ZSIsZombie then
			survivors[#survivors + 1] = survivor
		end
	end

	return survivors
end

local SPAWN_STATUS_VALID = 0
local SPAWN_STATUS_TOO_CLOSE = 1
local SPAWN_STATUS_VISIBLE = 2
local SPAWN_STATUS_BLOCKED = 3

function MODE:ValidateCameraZombieSpawn(ply, cameraPos)
	if not IsFiniteSpawnVector(cameraPos) or not util.IsInWorld(cameraPos) then
		return nil, "Move your camera inside the map.", SPAWN_STATUS_BLOCKED
	end

	local survivors = GetLivingSurvivors()
	local minDistanceSqr = (self.ZombieCameraSpawnMinDistance or 650) ^ 2
	local verticalTolerance = math.max(self.ZombieCameraSpawnVerticalTolerance or 96, 0)
	local visibilityDistanceSqr = (self.ZombieCameraSpawnVisibilityDistance or 2200) ^ 2
	local viewDot = math.Clamp(self.ZombieCameraSpawnViewDot or 0.3, -1, 1)
	local maxDrop = math.max(self.ZombieCameraSpawnMaxDrop or 256, 96)
	local maxRadius = math.max(self.ZombieCameraSpawnSearchRadius or 64, 0)
	local traceFilter = {ply}
	local character = hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply)
	if IsValid(character) and character ~= ply then traceFilter[#traceFilter + 1] = character end

	local sawClearGround = false
	local wasTooClose = false
	local wasVisible = false

	for _, offset in ipairs(cameraSpawnOffsets) do
		if offset.x * offset.x + offset.y * offset.y > maxRadius * maxRadius then continue end

		local trace = util.TraceLine({
			start = cameraPos + offset + Vector(0, 0, 16),
			endpos = cameraPos + offset - Vector(0, 0, maxDrop),
			mask = MASK_PLAYERSOLID,
			filter = traceFilter
		})

		if trace.StartSolid or not trace.Hit or trace.HitSky or trace.HitNormal.z < 0.55 then continue end

		local ground = trace.Entity
		if IsValid(ground) and (ground:IsPlayer() or ground:IsRagdoll()) then continue end

		local physics = IsValid(ground) and ground:GetPhysicsObject()
		if IsValid(physics) and physics:IsMotionEnabled() then continue end

		local spawnPos = trace.HitPos + Vector(0, 0, 1)
		if not IsZombieSpawnClear(spawnPos, ply) then continue end

		sawClearGround = true
		local blocked = false
		for _, survivor in ipairs(survivors) do
			local survivorPos = survivor:GetPos()
			local horizontalDelta = survivorPos - spawnPos
			horizontalDelta.z = 0
			if math.abs(survivorPos.z - spawnPos.z) <= verticalTolerance and horizontalDelta:LengthSqr() < minDistanceSqr then
				wasTooClose = true
				blocked = true
				break
			end

			if SurvivorCanSeeSpawn(survivor, spawnPos, visibilityDistanceSqr, viewDot) then
				wasVisible = true
				blocked = true
				break
			end
		end

		if not blocked then return spawnPos, nil, SPAWN_STATUS_VALID end
	end

	if wasTooClose then return nil, "You are too close to a survivor.", SPAWN_STATUS_TOO_CLOSE end
	if wasVisible then return nil, "A survivor can see this location.", SPAWN_STATUS_VISIBLE end
	if sawClearGround then return nil, "This location is not safe to spawn in.", SPAWN_STATUS_BLOCKED end

	return nil, "Aim your camera near clear, stable ground.", SPAWN_STATUS_BLOCKED
end

function MODE:SelectZombieSpawn(ply)
	if not self.ZombieSpawnPoints or #self.ZombieSpawnPoints == 0 then
		self:BuildZombieSpawnCache()
	end

	local survivors = {}
	for _, survivor in player.Iterator() do
		if IsParticipant(survivor) and survivor:Alive() and not survivor.ZSIsZombie then
			survivors[#survivors + 1] = survivor
		end
	end

	local bestPos
	local bestIndex
	local bestScore = -math.huge
	local now = CurTime()

	for index, pos in RandomPairs(self.ZombieSpawnPoints or {}) do
		if not IsZombieSpawnClear(pos, ply) then continue end

		local nearestDistance = 3200
		local visibleCount = 0
		local nearbyCount = 0

		for _, survivor in ipairs(survivors) do
			local distance = survivor:GetPos():Distance(pos)
			nearestDistance = math.min(nearestDistance, distance)

			if distance < 1200 then
				nearbyCount = nearbyCount + 1
			end

			if distance < 2800 and SurvivorCanSeeSpawn(survivor, pos) then
				visibleCount = visibleCount + 1
			end
		end

		local score = nearestDistance - visibleCount * 2400 - nearbyCount * 700 + math.Rand(0, 80)
		if visibleCount == 0 and nearestDistance >= 900 then
			score = score + 5000
		end

		local lastUsed = self.RecentZombieSpawns and self.RecentZombieSpawns[index]
		if lastUsed and now - lastUsed < 12 then
			score = score - (12 - (now - lastUsed)) * 100
		end

		if score > bestScore then
			bestScore = score
			bestPos = pos
			bestIndex = index
		end
	end

	if bestIndex then
		self.RecentZombieSpawns[bestIndex] = now
	end

	return bestPos or zb:GetRandomSpawn(ply)
end

function MODE:SetZombieState(ply, patientZero, zombieClass)
	zombieClass = patientZero and "fastzombie" or zombieClass
	if not zombiePlayerClasses[zombieClass] then zombieClass = "headcrabzombie" end

	ply.ZSIsZombie = true
	ply.ZSIsPatientZero = patientZero == true
	ply.ZSZombieClass = zombieClass
	ply.ZSIsPoisonZombie = zombieClass == "poisonzombie"
	ply:SetNWBool("ZS_IsZombie", true)
	ply:SetNWBool("ZS_IsPatientZero", patientZero == true)
	ply:SetNWBool("ZS_IsPoisonZombie", ply.ZSIsPoisonZombie == true)
	ply.ZSSpawnReady = nil
	ply:SetNWBool("ZS_SpawnReady", false)
	ply:SetTeam(1)
end

function MODE:SyncZombieStateFromPlayerClass(ply, className)
	if not IsValid(ply) or zb.ROUND_STATE ~= 1 or CurrentRound() ~= self or not self.InfectionStarted then return false end

	className = className or ply.PlayerClassName
	if not zombiePlayerClasses[className] then return false end

	local patientZero = ply.ZSIsPatientZero == true
	local poisonZombie = className == "poisonzombie"

	ply.ZSIsZombie = true
	ply.ZSIsPatientZero = patientZero
	ply.ZSIsPoisonZombie = poisonZombie
	ply.ZSZombieClass = className
	ply:SetNWBool("ZS_IsZombie", true)
	ply:SetNWBool("ZS_IsPatientZero", patientZero)
	ply:SetNWBool("ZS_IsPoisonZombie", poisonZombie)
	if ply:Team() ~= 1 then ply:SetTeam(1) end
	ApplyZombieBuffs(ply, className)

	return true
end

hook.Add("HG_PlayerClassChanged", "ZCityZombieSurvival_SyncZombieTeam", function(ply, className)
	if CurrentRound() ~= MODE then return end
	MODE:SyncZombieStateFromPlayerClass(ply, className)
end)

function MODE:PrepareZombieBody(ply, patientZero)
	if IsValid(ply.FakeRagdoll) and hg.FakeUp then
		hg.FakeUp(ply, true, true)
	end

	ply:StripWeapons()
	ply:StripAmmo()
	hg.CreateInv(ply)
	ply.PreZombClass = ply.PreZombClass or "Rebel"
	local className = ply.ZSZombieClass
	if patientZero and className ~= "poisonzombie" then className = "fastzombie" end
	if not zombiePlayerClasses[className] then
		className = ply.ZSIsPoisonZombie and "poisonzombie" or "headcrabzombie"
	end
	local poisonZombie = className == "poisonzombie"
	ply.ZSZombieClass = className
	ply.ZSIsPoisonZombie = poisonZombie
	ply:SetPlayerClass(className)
	ApplyZombieBuffs(ply, className, true)

	if poisonZombie then
		zb.GiveRole(ply, "Poison Zombie", poisonZombieColor)
		if ply.ZSPoisonAbilityTipSerial ~= self.RoundSerial then
			ply.ZSPoisonAbilityTipSerial = self.RoundSerial
			if isfunction(ply.Notify) then
				ply:Notify("RMB throws a poison headcrab. Consuming a body replenishes one.", 0, "zs_poison_ability_tip", 3, nil, poisonZombieColor)
			else
				ply:ChatPrint("RMB throws a poison headcrab. Consuming a body replenishes one.")
			end
		end
	elseif className == "fastzombie" then
		zb.GiveRole(ply, "Fast Zombie", fastZombieColor)
	else
		zb.GiveRole(ply, "Zombie", zombieColor)
	end
end

function MODE:PromotePoisonZombie()
	if not self.InfectionStarted or zb.ROUND_STATE ~= 1 or CurrentRound() ~= self then return end

	local survivors = 0
	local infected = 0
	local candidates = {}
	local livingCandidates = {}
	local patientZero

	for _, ply in player.Iterator() do
		if not IsParticipant(ply) then continue end

		if ply.ZSIsZombie then
			infected = infected + 1
			if ply.ZSIsPatientZero then patientZero = patientZero or ply end
			if not ply.ZSIsPoisonZombie and not ply.ZSIsPatientZero then
				candidates[#candidates + 1] = ply
				if ply:Alive() then livingCandidates[#livingCandidates + 1] = ply end
			end
		elseif ply:Alive() then
			survivors = survivors + 1
		end
	end

	if survivors <= infected then return end

	local promoted = table.Random(livingCandidates)
	if not IsValid(promoted) then promoted = table.Random(candidates) end
	if not IsValid(promoted) then promoted = patientZero end
	if not IsValid(promoted) then return end

	promoted.ZSIsPoisonZombie = true
	promoted.ZSZombieClass = "poisonzombie"
	promoted:SetNWBool("ZS_IsPoisonZombie", true)

	if promoted:Alive() then
		self:PrepareZombieBody(promoted, promoted.ZSIsPatientZero)
	end

	promoted:zChatPrint("The infection has mutated you into a Poison Zombie.")
	PrintMessage(HUD_PRINTTALK, "The infected have produced a poison carrier.")
	return promoted
end

function MODE:MakeZombie(ply, patientZero)
	if not IsParticipant(ply) then return false end

	self:SetZombieState(ply, patientZero)
	self:PrepareZombieBody(ply, patientZero)

	if patientZero then
		ply:zChatPrint("You are patient zero. Infect every survivor.")
	else
		ply:zChatPrint("You have joined the infected.")
	end

	return true
end

function MODE:PrepareSurvivorBody(ply, reposition)
	if not IsValid(ply) or not ply:Alive() then return false end
	if zb.ROUND_STATE ~= 1 or CurrentRound() ~= self or self.InfectionStarted then return false end
	if ply:Team() == TEAM_SPECTATOR then return false end

	local hadZombieClass = zombiePlayerClasses[ply.PlayerClassName] == true
	ClearZombieState(ply)
	if hadZombieClass then ply:SetPlayerClass() end

	ApplyAppearance(ply, nil, nil, nil, true)
	ply:SetTeam(0)
	if reposition then ply:GetRandomSpawn() end
	ply:SetSuppressPickupNotices(false)
	ply.noSound = false

	local hands = ply:Give("weapon_hands_sh")
	if IsValid(hands) then ply:SetActiveWeapon(hands) end
	zb.GiveRole(ply, "Survivor", survivorColor)
	ply.ZSRoundEnrollmentSerial = self.RoundSerial
	return true
end

function MODE:SpawnPreInfectionSurvivor(ply)
	if not IsValid(ply) or ply:Team() == TEAM_SPECTATOR then return false end
	if zb.ROUND_STATE ~= 1 or CurrentRound() ~= self or self.InfectionStarted then return false end

	ply.initialspawn = nil
	ply.ZSSurvivorSpawnInProgress = true
	ply:SetTeam(0)
	ply:Spawn()
	ply.ZSSurvivorSpawnInProgress = nil

	return self:PrepareSurvivorBody(ply, true)
end

function MODE:QueuePreInfectionRespawn(ply, delay)
	if not IsValid(ply) or ply:Team() == TEAM_SPECTATOR then return false end
	if zb.ROUND_STATE ~= 1 or CurrentRound() ~= self or self.InfectionStarted then return false end

	local roundSerial = self.RoundSerial
	local timerName = PreInfectionRespawnTimerName(ply)
	timer.Remove(timerName)
	timer.Create(timerName, math.max(tonumber(delay) or 1, 0.1), 1, function()
		if not IsValid(ply) or ply:Alive() or zb.ROUND_STATE ~= 1 then return end
		if CurrentRound() ~= MODE or MODE.RoundSerial ~= roundSerial then return end

		if MODE.InfectionStarted then
			MODE:QueueOutbreakLateJoin(ply)
		else
			MODE:SpawnPreInfectionSurvivor(ply)
		end
	end)
	return true
end

function MODE:QueueOutbreakLateJoin(ply)
	if not IsValid(ply) then return false end
	if zb.ROUND_STATE ~= 1 or CurrentRound() ~= self or not self.InfectionStarted then return false end

	ply.ZSLateJoinPendingSerial = self.RoundSerial
	ply.ZSOutbreakLateJoinSerial = self.RoundSerial
	ply.initialspawn = nil
	ply.ZSLateJoinChangingTeam = true
	ply:SetTeam(1)
	ply.ZSLateJoinChangingTeam = nil

	if ply.ZSIsZombie then
		if not ply:Alive() and not ply.ZSSpawnReady and not timer.Exists(RespawnTimerName(ply)) then
			self:QueueZombieRespawn(ply, self.ZombieRespawnDelay)
		end

		return true
	end

	if ply:Alive() then
		ply.ZSDeathHandledAt = CurTime()
		ply:KillSilent()
	end

	ply.PreZombClass = zombiePlayerClasses[ply.PlayerClassName] and "Rebel" or (ply.PlayerClassName ~= "none" and ply.PlayerClassName or "Rebel")
	self:SetZombieState(ply, false)
	self:QueueZombieRespawn(ply, self.ZombieRespawnDelay)
	ply:zChatPrint("The outbreak is already active. You will respawn with the infected.")
	return true
end

function MODE:BeginLateJoinEnrollment(ply)
	if not IsValid(ply) then return end

	local roundSerial = self.RoundSerial
	local timerName = LateJoinTimerName(ply)
	ply.ZSLateJoinPendingSerial = roundSerial
	timer.Remove(timerName)
	timer.Create(timerName, 0.5, 40, function()
		if not IsValid(ply) then
			timer.Remove(timerName)
			return
		end

		if zb.ROUND_STATE ~= 1 or CurrentRound() ~= MODE or MODE.RoundSerial ~= roundSerial then
			timer.Remove(timerName)
			return
		end

		if MODE.InfectionStarted and ply.ZSIsZombie then
			if ply:Alive() then
				ply.ZSLateJoinChangingTeam = true
				ply:SetTeam(1)
				ply.ZSLateJoinChangingTeam = nil
				ply.ZSLateJoinHandledSerial = roundSerial
				ply.ZSLateJoinPendingSerial = nil
				ply.ZSOutbreakLateJoinSerial = nil
				ply.ZSRoundEnrollmentSerial = roundSerial
				timer.Remove(timerName)
			elseif not ply.ZSSpawnReady and not timer.Exists(RespawnTimerName(ply)) then
				MODE:QueueZombieRespawn(ply, 1)
			end

			return
		end

		ply.initialspawn = nil
		ply.ZSLateJoinChangingTeam = true
		ply:SetTeam(0)
		ply.ZSLateJoinChangingTeam = nil

		local handled
		if MODE.InfectionStarted then
			handled = MODE:QueueOutbreakLateJoin(ply)
		elseif ply:Alive() then
			handled = MODE:PrepareSurvivorBody(ply, true)
		else
			handled = MODE:SpawnPreInfectionSurvivor(ply)
		end

		if handled then
			if not MODE.InfectionStarted or ply:Alive() then
				ply.ZSLateJoinHandledSerial = roundSerial
				ply.ZSLateJoinPendingSerial = nil
				ply.ZSRoundEnrollmentSerial = roundSerial
				timer.Remove(timerName)
			end
		end
	end)
end

function MODE:PlayerSpawn(ply)
	if self.SpawningRoundPlayers or ply.ZSSurvivorSpawnInProgress or ply.ZSIsZombie then return end

	local initialJoin = ply.initialspawn == true
	local roundSerial = self.RoundSerial
	timer.Simple(0, function()
		if not IsValid(ply) or zb.ROUND_STATE ~= 1 then return end
		if CurrentRound() ~= MODE or MODE.RoundSerial ~= roundSerial then return end
		if ply.ZSIsZombie then return end
		if ply:Team() == TEAM_SPECTATOR and not initialJoin then return end

		if initialJoin then
			ply.initialspawn = nil
			ply:SetTeam(0)
		end

		local handled
		if MODE.InfectionStarted then
			handled = MODE:QueueOutbreakLateJoin(ply)
		elseif ply:Alive() then
			handled = MODE:PrepareSurvivorBody(ply, true)
		else
			handled = MODE:SpawnPreInfectionSurvivor(ply)
		end

		if initialJoin and handled then ply.ZSLateJoinHandledSerial = roundSerial end
	end)
end

function MODE:PlayerInitialSpawn(ply)
	ply.ZSLateJoinPendingSerial = self.RoundSerial
	self:BeginLateJoinEnrollment(ply)
end

hook.Add("PlayerInitialSpawn", "ZCityZombieSurvival_LateJoinEnrollment", function(ply)
	timer.Simple(1, function()
		if not IsValid(ply) or zb.ROUND_STATE ~= 1 or CurrentRound() ~= MODE then return end
		ply.ZSLateJoinPendingSerial = MODE.RoundSerial
		MODE:BeginLateJoinEnrollment(ply)
	end)
end)

function MODE:OnPlayerChangedTeam(ply, oldTeam, newTeam)
	if zb.ROUND_STATE ~= 1 or CurrentRound() ~= self then return end
	if ply.ZSLateJoinChangingTeam then return end

	local freshJoin = ply.ZSLateJoinPendingSerial == self.RoundSerial
	local leftSpectators = oldTeam == TEAM_SPECTATOR and newTeam ~= TEAM_SPECTATOR
	if not freshJoin and not leftSpectators then return end

	self:BeginLateJoinEnrollment(ply)
end

hook.Add("OnPlayerChangedTeam", "ZCityZombieSurvival_LateJoinTeamChange", function(ply, oldTeam, newTeam)
	if zb.ROUND_STATE ~= 1 or CurrentRound() ~= MODE then return end
	if ply.ZSLateJoinChangingTeam then return end

	local freshJoin = ply.ZSLateJoinPendingSerial == MODE.RoundSerial
	local leftSpectators = (oldTeam == TEAM_SPECTATOR or oldTeam == TEAM_UNASSIGNED)
		and newTeam ~= TEAM_SPECTATOR
		and newTeam ~= TEAM_UNASSIGNED
	if not freshJoin and not leftSpectators then return end

	MODE:BeginLateJoinEnrollment(ply)
end)

function MODE:ZB_JoinSpectators(ply)
	if zb.ROUND_STATE ~= 1 or CurrentRound() ~= self then return end
	if ply:Team() ~= TEAM_SPECTATOR then return end

	timer.Simple(0, function()
		if not IsValid(ply) or zb.ROUND_STATE ~= 1 or CurrentRound() ~= MODE then return end
		MODE:BeginLateJoinEnrollment(ply)
	end)
end

function MODE:ReconcileLateJoiners()
	if zb.ROUND_STATE ~= 1 or CurrentRound() ~= self then return end

	for _, ply in player.Iterator() do
		if self.InfectionStarted then
			self:SyncZombieStateFromPlayerClass(ply)
		end

		local pending = ply.ZSLateJoinPendingSerial == self.RoundSerial
		local newToRound = ply.ZSRoundEnrollmentSerial ~= self.RoundSerial
		local unassigned = ply:Team() == TEAM_UNASSIGNED
		local missedOutbreakDeath = self.InfectionStarted
			and ply:Team() ~= TEAM_SPECTATOR
			and not ply:Alive()
			and not ply.ZSIsZombie

		if (pending or newToRound or unassigned or missedOutbreakDeath) and not timer.Exists(LateJoinTimerName(ply)) then
			self:BeginLateJoinEnrollment(ply)
		end
	end
end

function MODE:SpawnZombie(ply, requestedSpawnPos)
	if not IsValid(ply) or not ply.ZSIsZombie then return end
	if zb.ROUND_STATE ~= 1 or CurrentRound() ~= self then return end

	local lateJoin = ply.ZSOutbreakLateJoinSerial == self.RoundSerial
	if not lateJoin and not IsParticipant(ply) then return end

	timer.Remove(RespawnTimerName(ply))
	ply.ZSSpawnReady = nil
	ply:SetNWBool("ZS_SpawnReady", false)
	ply:SetTeam(1)
	local spawnPos = isvector(requestedSpawnPos) and requestedSpawnPos or self:SelectZombieSpawn(ply)
	ply:Spawn()
	if not ply:Alive() then
		self:QueueZombieRespawn(ply, 1)
		return
	end

	ply:SetupTeam(1)
	if isvector(spawnPos) then
		ply:SetPos(spawnPos)
		ply:SetLocalVelocity(vector_origin)
	end
	ply:SetNWFloat("ZS_RespawnAt", 0)
	self:PrepareZombieBody(ply, ply.ZSIsPatientZero)
	ply.ZSOutbreakLateJoinSerial = nil
	ply.ZSLateJoinPendingSerial = nil
	ply.ZSLateJoinHandledSerial = self.RoundSerial
	ply.ZSRoundEnrollmentSerial = self.RoundSerial
	timer.Remove(LateJoinTimerName(ply))
end

function MODE:QueueZombieRespawn(ply, delay)
	if not IsValid(ply) then return end

	delay = math.max(tonumber(delay) or self.ZombieRespawnDelay, 0.1)
	local roundSerial = self.RoundSerial
	local timerName = RespawnTimerName(ply)
	timer.Remove(timerName)
	ply.ZSSpawnReady = nil
	ply:SetNWBool("ZS_SpawnReady", false)
	ply:SetNWFloat("ZS_RespawnAt", CurTime() + delay)

	timer.Create(timerName, delay, 1, function()
		if not IsValid(ply) or zb.ROUND_STATE ~= 1 then return end
		if CurrentRound() ~= MODE or MODE.RoundSerial ~= roundSerial then return end
		if not ply.ZSIsZombie then return end
		if ply:Alive() then return end

		ply.ZSSpawnReady = true
		ply:SetNWBool("ZS_SpawnReady", true)
		ply:SetNWFloat("ZS_RespawnAt", 0)
	end)
end

net.Receive("ZCity_ZS_CheckSpawn", function(_, ply)
	local cameraPos = net.ReadVector()
	if not IsValid(ply) or zb.ROUND_STATE ~= 1 or CurrentRound() ~= MODE then return end
	if not MODE.InfectionStarted or ply:Alive() or not ply.ZSIsZombie or not ply.ZSSpawnReady then return end

	local now = CurTime()
	if now < (ply.ZSNextSpawnProbe or 0) then return end
	ply.ZSNextSpawnProbe = now + 0.45

	local spawnPos, _, status = MODE:ValidateCameraZombieSpawn(ply, cameraPos)
	net.Start("ZCity_ZS_SpawnStatus")
		net.WriteVector(cameraPos)
		net.WriteUInt(isvector(spawnPos) and SPAWN_STATUS_VALID or status or SPAWN_STATUS_BLOCKED, 2)
	net.Send(ply)
end)

net.Receive("ZCity_ZS_RequestSpawn", function(_, ply)
	local cameraPos = net.ReadVector()
	if not IsValid(ply) or zb.ROUND_STATE ~= 1 or CurrentRound() ~= MODE then return end
	if not MODE.InfectionStarted or ply:Alive() or not ply.ZSIsZombie or not ply.ZSSpawnReady then return end

	local now = CurTime()
	if now < (ply.ZSNextSpawnRequest or 0) then return end
	ply.ZSNextSpawnRequest = now + 0.3

	local spawnPos, rejection = MODE:ValidateCameraZombieSpawn(ply, cameraPos)
	if not spawnPos then
		if isfunction(ply.Notify) then
			ply:Notify(rejection or "You cannot spawn here.", 0, "zs_spawn_blocked", 1.5, nil, zombieColor)
		else
			ply:ChatPrint(rejection or "You cannot spawn here.")
		end
		return
	end

	MODE:SpawnZombie(ply, spawnPos)
end)

function MODE:GetPatientZeroCandidate()
	local candidates = {}

	for _, ply in player.Iterator() do
		if IsParticipant(ply) and ply:Alive() and not ply.ZSIsZombie then
			candidates[#candidates + 1] = ply
		end
	end

	return table.Random(candidates)
end

function MODE:PromotePatientZero()
	local infected = {}

	for _, ply in player.Iterator() do
		if IsParticipant(ply) and ply.ZSIsZombie then
			if ply.ZSIsPatientZero then return ply end
			infected[#infected + 1] = ply
		end
	end

	local promoted
	for _, ply in RandomPairs(infected) do
		if ply:Alive() then
			promoted = ply
			break
		end
	end

	promoted = promoted or infected[1]
	if IsValid(promoted) then
		promoted.ZSIsPatientZero = true
		promoted.ZSIsPoisonZombie = nil
		promoted.ZSZombieClass = "fastzombie"
		promoted:SetNWBool("ZS_IsPatientZero", true)
		promoted:SetNWBool("ZS_IsPoisonZombie", false)

		if promoted:Alive() then
			self:PrepareZombieBody(promoted, true)
		else
			self:QueueZombieRespawn(promoted, self.FastZombieRespawnDelay)
		end

		return promoted
	end

	local candidate = self:GetPatientZeroCandidate()
	if IsValid(candidate) and self:MakeZombie(candidate, true) then
		return candidate
	end
end

function MODE:StartInfection()
	if self.InfectionStarted or zb.ROUND_STATE ~= 1 or CurrentRound() ~= self then return end

	local patientZero = self:PromotePatientZero()
	if not IsValid(patientZero) then
		self.InfectionFailed = true
		return
	end

	self.InfectionStarted = true
	SetGlobalBool("ZS_InfectionStarted", true)
	PrintMessage(HUD_PRINTTALK, patientZero:Nick() .. " is patient zero.")
end

function MODE:Intermission()
	game.CleanUpMap()
	self:ClearRoundTimers()
	self.RoundSerial = (self.RoundSerial or 0) + 1
	self.InfectionStarted = false
	self.InfectionFailed = false

	SetGlobalBool("ZS_InfectionStarted", false)
	SetGlobalFloat("ZS_InfectionAt", 0)
	SetGlobalFloat("ZS_RoundEndsAt", 0)

	for _, ply in player.Iterator() do
		ClearZombieState(ply)
		ply.isPolice = false
		ply.isTraitor = false
		ply.isGunner = false
		ply.MainTraitor = false
		ply.SubRole = nil
		ply.Profession = nil

		if ply:Team() == TEAM_SPECTATOR or ply:Team() == TEAM_UNASSIGNED then
			if ply.PlayerClassName ~= "none" then ply:SetPlayerClass() end
			continue
		end

		ply:KillSilent()
		if ply.PlayerClassName ~= "none" then ply:SetPlayerClass() end
		ply:SetupTeam(0)
	end
end

function MODE:GiveEquipment()
end

function MODE:RoundStart()
	self.RoundSerial = (self.RoundSerial or 0) + 1
	self.InfectionStarted = false
	self.InfectionFailed = false
	self.InfectionAt = CurTime() + self.InfectionDelay
	self.RoundEndsAt = CurTime() + self.ROUND_TIME
	self.NextZombieAbilityUpdate = 0
	self.NextPatientZeroCheck = 0
	self.NextPoisonZombieAt = CurTime() + self.PoisonZombieInterval
	self.NextLateJoinReconcile = 0

	SetGlobalBool("ZS_InfectionStarted", false)
	SetGlobalFloat("ZS_InfectionAt", self.InfectionAt)
	SetGlobalFloat("ZS_RoundEndsAt", self.RoundEndsAt)
	self:BuildZombieSpawnCache()

	self.SpawningRoundPlayers = true
	for _, ply in player.Iterator() do
		ply.ZSRoundEnrollmentSerial = self.RoundSerial
		if ply:Team() == TEAM_SPECTATOR then continue end

		ClearZombieState(ply)
		if ply.PlayerClassName ~= "none" then ply:SetPlayerClass() end
		ApplyAppearance(ply, nil, nil, nil, true)
		ply:SetTeam(0)
		ply:Spawn()
		ply:GetRandomSpawn()
		ply:SetSuppressPickupNotices(false)
		ply.noSound = false

		local hands = ply:Give("weapon_hands_sh")
		if IsValid(hands) then ply:SetActiveWeapon(hands) end
		zb.GiveRole(ply, "Survivor", survivorColor)
	end
	self.SpawningRoundPlayers = nil

	timer.Create(infectionTimerName, self.InfectionDelay, 1, function()
		if CurrentRound() == MODE and zb.ROUND_STATE == 1 then
			MODE:StartInfection()
		end
	end)
end

function MODE:RoundThink()
	local now = CurTime()
	if now >= (self.NextLateJoinReconcile or 0) then
		self.NextLateJoinReconcile = now + 1
		self:ReconcileLateJoiners()
	end

	if not self.InfectionStarted then
		if now >= (self.InfectionAt or math.huge) then
			self:StartInfection()
		end
		return
	end

	if now >= (self.NextPatientZeroCheck or 0) then
		self.NextPatientZeroCheck = now + 0.5
		self:PromotePatientZero()
	end

	if now >= (self.NextPoisonZombieAt or math.huge) then
		self.NextPoisonZombieAt = now + self.PoisonZombieInterval
		self:PromotePoisonZombie()
	end

	if now >= (self.NextZombieAbilityUpdate or 0) then
		self.NextZombieAbilityUpdate = now + 0.1
		self:UpdateZombieConsumeInputs()
	end
end

function MODE:HandleZombieSurvivalDeath(victim)
	if zb.ROUND_STATE ~= 1 then return end
	if not IsParticipant(victim) then return end
	if CurTime() - (victim.ZSDeathHandledAt or -math.huge) < 0.25 then return end

	victim.ZSDeathHandledAt = CurTime()
	self:StopZombieConsume(victim)
	self:EndVoice(victim)
	if not victim.ZSIsZombie then
		if not self.InfectionStarted then
			self:QueuePreInfectionRespawn(victim, 1)
			return
		end

		self:SetZombieState(victim, false)
		victim.PreZombClass = victim.PlayerClassName ~= "none" and victim.PlayerClassName or "Rebel"
		self:QueueZombieRespawn(victim, self.ZombieRespawnDelay)
		return
	end

	if victim.ZSIsZombie then
		local delay = victim.ZSIsPatientZero and self.FastZombieRespawnDelay or self.ZombieRespawnDelay
		self:QueueZombieRespawn(victim, delay)
	end
end

function MODE:PlayerDeath(victim, inflictor, attacker)
	self:HandleZombieSurvivalDeath(victim)
end

function MODE:Player_Death(victim)
	self:HandleZombieSurvivalDeath(victim)
end

function MODE:PostPlayerDeath(victim)
	self:HandleZombieSurvivalDeath(victim)
end

function MODE:PlayerDisconnected(ply)
	timer.Remove(RespawnTimerName(ply))
	timer.Remove(PreInfectionRespawnTimerName(ply))
	timer.Remove(LateJoinTimerName(ply))
	timer.Remove(VoiceTimerName(ply))
	ClearZombieConsumeState(ply)
end

function MODE:ShouldRoundEnd()
	if self.InfectionFailed then return true end
	if not self.InfectionStarted then return false end

	for _, ply in player.Iterator() do
		if IsParticipant(ply) and ply:Alive() and not ply.ZSIsZombie then
			return false
		end
	end

	return true
end

function MODE:EndRound()
	self:ClearRoundTimers()

	local survivorCount = 0
	for _, ply in player.Iterator() do
		if IsParticipant(ply) and ply:Alive() and not ply.ZSIsZombie then
			survivorCount = survivorCount + 1
			ply:GiveExp(math.random(15, 30))
		end
	end

	if survivorCount > 0 then
		PrintMessage(HUD_PRINTTALK, survivorCount .. " survivor" .. (survivorCount == 1 and "" or "s") .. " held out against the infection.")
	else
		PrintMessage(HUD_PRINTTALK, "The infection consumed everyone.")
	end
end

function MODE:CanSpawn(ply)
	return zb.ROUND_STATE == 1
		and CurrentRound() == self
		and not self.InfectionStarted
		and IsValid(ply)
		and ply:Team() ~= TEAM_SPECTATOR
end
