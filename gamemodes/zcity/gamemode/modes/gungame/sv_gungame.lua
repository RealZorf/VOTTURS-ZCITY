local MODE = MODE

MODE.name = "gungame"
MODE.ROUND_TIME = 600
MODE.end_time = 10
MODE.GuiltDisabled = true

util.AddNetworkString("gungame_start")
util.AddNetworkString("gungame_progress")
util.AddNetworkString("gungame_final")
util.AddNetworkString("gungame_end")
util.AddNetworkString("gungame_grace")
util.AddNetworkString("gungame_killfeed")
util.AddNetworkString("gungame_respawn")

local respawnDelay = CreateConVar("zb_gungame_respawn_delay", "3", FCVAR_LUA_SERVER, "Gun Game respawn delay")
local rewardHP = CreateConVar("zb_gungame_kill_reward_hp", "25", FCVAR_LUA_SERVER, "Gun Game kill reward HP")
local roundDuration = CreateConVar("zb_gungame_round_time", "600", FCVAR_LUA_SERVER, "Gun Game round duration")
local ammoMags = CreateConVar("zb_gungame_ammo_mags", "3", FCVAR_LUA_SERVER, "Reserve magazines given with each gun")
local variationCvar = CreateConVar("zb_gungame_variation", "", FCVAR_LUA_SERVER, "Force a gun game variation id or blank for random")
local incapKillTime = CreateConVar("zb_gungame_incap_kill_time", "15", FCVAR_LUA_SERVER, "Kill player if downed for this many seconds")

local GRACE_TIMER = "gungame_grace_give"
local ROLE_COLOR = Color(220, 140, 40)
local KARMA_REWARDS = { [1] = "max", [2] = 100, [3] = 70, [4] = 40, [5] = 10 }

MODE.PlayerProgress = {}
MODE.DamageLog = {}
MODE.generation = MODE.generation or 0
MODE.respawnDue = {}
MODE.granting = {}
MODE.incapSince = {}
MODE.corpses = {}

local function ActiveRound(generation)
	return generation == MODE.generation and CurrentRound() and CurrentRound().name == "gungame" and zb.ROUND_STATE == 1
end

local function LockFake(ply, untilTime)
	if IsValid(ply) then ply.fakecd = math.max(ply.fakecd or 0, untilTime or MODE:StartLockUntil()) end
end

local function ResetProgress()
	MODE.PlayerProgress = {}
	MODE.DamageLog = {}
	MODE.winner = nil
	MODE.respawnDue = {}
	MODE.granting = {}
	MODE.incapSince = {}
	MODE.corpses = {}
	MODE.graceEnd = 0
	MODE.nextCorpseThink = 0
	MODE.startGiven = false
	MODE.roundLadder = nil
	MODE.roundFinalWeapon = nil
	MODE.allowed = nil
	timer.Remove(GRACE_TIMER)
	SetGlobalInt("ZB_GGStages", 0)
	for _, ply in player.Iterator() do
		ply:SetNWInt("GGStage", 0)
		ply:SetNWInt("GGKills", 0)
	end
end

local function CurrentClass(progress)
	if not progress then return nil end
	if progress.stage >= (progress.stagesTotal or 1) then return progress.finalWeapon end
	return progress.unlocked[progress.stage]
end

local function InitPlayer(ply)
	local ladder = MODE.roundLadder
	if not ladder or #ladder < 2 then return end
	MODE.PlayerProgress[ply] = {
		stage = 1, kills = 0, stageKills = 0,
		unlocked = table.Copy(ladder),
		finalWeapon = MODE.roundFinalWeapon,
		stagesTotal = MODE.roundStagesTotal
	}
	ply:SetNWInt("GGStage", 1)
	ply:SetNWInt("GGKills", 0)
end

local function SyncHUD(ply)
	local progress = MODE.PlayerProgress[ply]
	if not IsValid(ply) or not progress then return end
	ply:SetNWInt("GGStage", progress.stage or 1)
	ply:SetNWInt("GGKills", progress.kills or 0)
	local needed = (progress.stage >= (progress.stagesTotal or 1)) and (MODE.KillsPerFinal or 1) or (MODE.KillsPerStage or 2)
	net.Start("gungame_progress")
		net.WriteUInt(progress.stage, 12)
		net.WriteUInt(progress.stagesTotal or 1, 12)
		net.WriteUInt(progress.stageKills or 0, 4)
		net.WriteUInt(needed, 4)
		net.WriteString(CurrentClass(progress) or "")
		net.WriteBool(progress.stage >= (progress.stagesTotal or 1))
		net.WriteString((progress.stage >= (progress.stagesTotal or 1)) and "" or (progress.unlocked[progress.stage + 1] or progress.finalWeapon or ""))
	net.Send(ply)
end

local function GrantClasses(ply, class)
	local handsClass = hg.GetHandsWeaponClass and hg.GetHandsWeaponClass(ply) or "weapon_hands_sh"
	local allowed = { [handsClass] = true }
	if class then allowed[class] = true end
	if weapons.GetStored("weapon_bandage_sh") then allowed["weapon_bandage_sh"] = true end
	if weapons.GetStored("weapon_tourniquet") then allowed["weapon_tourniquet"] = true end
	return handsClass, allowed
end

local function RemoveOwnedWeapons(ply)
	local owned = ply:GetWeapons()
	for i = 1, #owned do
		local weapon = owned[i]
		if IsValid(weapon) then weapon:Remove() end
	end
end

local function RemoveUnownedWeapon(weapon)
	timer.Simple(0, function()
		if IsValid(weapon) and not IsValid(weapon:GetOwner()) then weapon:Remove() end
	end)
end

local function GiveProgressWeapon(ply, class)
	if not IsValid(ply) or not ply:Alive() or not class or not weapons.GetStored(class) then return false end

	local handsClass, allowed = GrantClasses(ply, class)
	MODE.granting[ply] = allowed
	ply.force_pickup = true
	RemoveOwnedWeapons(ply)
	ply:StripAmmo()

	local hands = ply:Give(handsClass)
	if allowed["weapon_bandage_sh"] then
		local bandage = ply:Give("weapon_bandage_sh")
		if IsValid(bandage) then bandage.NoDrop = true end
	end
	if allowed["weapon_tourniquet"] then
		local tourni = ply:Give("weapon_tourniquet")
		if IsValid(tourni) then tourni.NoDrop = true end
	end
	local weapon = ply:Give(class)
	if IsValid(weapon) then
		weapon.NoHolster = false
		weapon.NoDrop = true
		if weapon:GetClass() ~= MODE.roundFinalWeapon then
			local clip = weapon.GetMaxClip1 and weapon:GetMaxClip1() or 0
			local ammoType = weapon.GetPrimaryAmmoType and weapon:GetPrimaryAmmoType() or -1
			if ammoType and ammoType ~= -1 then
				local reserve = math.max(clip, 1) * math.max(1, ammoMags:GetInt())
				if clip > 0 then
					weapon:SetClip1(clip)
					ply:GiveAmmo(reserve, ammoType, true)
				else
					ply:GiveAmmo(math.max(reserve, 24), ammoType, true)
				end
			end
		end
	end

	local inv = ply:GetNetVar("Inventory")
	if istable(inv) then
		inv.Weapons = inv.Weapons or {}
		if not inv.Weapons["hg_sling"] then
			inv.Weapons["hg_sling"] = true
			ply:SetNetVar("Inventory", inv)
		end
	end
	if ply.organism then ply.organism.recoilmul = 0.55 end

	local function ForceEquip()
		if not IsValid(ply) or not ply:Alive() then return end
		if IsValid(weapon) then
			ply:SetActiveWeapon(weapon)
			ply:SelectWeapon(class)
		elseif IsValid(hands) then
			ply:SetActiveWeapon(hands)
			ply:SelectWeapon(handsClass)
		end
	end
	ForceEquip()
	timer.Simple(0, ForceEquip)
	timer.Simple(0.1, ForceEquip)
	ply.force_pickup = nil
	MODE.granting[ply] = nil
	return IsValid(weapon)
end

local function AdvanceStage(ply)
	local progress = MODE.PlayerProgress[ply]
	if not progress or not ply:Alive() then return end
	if progress.stage >= progress.stagesTotal - 1 then
		progress.stage = progress.stagesTotal
		progress.stageKills = 0
		GiveProgressWeapon(ply, progress.finalWeapon)
		SyncHUD(ply)
		net.Start("gungame_final")
			net.WriteEntity(ply)
		net.Broadcast()
		return
	end
	progress.stage = progress.stage + 1
	progress.stageKills = 0
	GiveProgressWeapon(ply, progress.unlocked[progress.stage])
	SyncHUD(ply)
end

local function RewardKill(victim, attacker)
	if MODE.winner or not IsValid(victim) or not victim:IsPlayer() then return end

	local bestAttacker, killClass, maxDamage = nil, "", 0
	for candidate, data in pairs(MODE.DamageLog[victim] or {}) do
		if IsValid(candidate) and candidate:IsPlayer() and data.damage > maxDamage then
			bestAttacker, killClass, maxDamage = candidate, data.weapon, data.damage
		end
	end
	if IsValid(bestAttacker) then
		attacker = bestAttacker
	elseif not (IsValid(attacker) and attacker:IsPlayer()) then
		return
	end
	if attacker == victim then return end

	local progress = MODE.PlayerProgress[attacker]
	if not progress then return end
	if killClass == "" or killClass ~= CurrentClass(progress) then return end

	progress.kills = (progress.kills or 0) + 1
	progress.stageKills = (progress.stageKills or 0) + 1
	local organism = attacker.organism
	if organism then
		if organism.stamina and organism.stamina[1] and organism.stamina.max then
			organism.stamina[1] = math.min(organism.stamina.max, organism.stamina[1] + math.max(20, organism.stamina.max * 0.45))
		end
		if organism.bleed then organism.bleed = math.max(organism.bleed - 10, 0) end
		if organism.internalBleed then organism.internalBleed = math.max(organism.internalBleed - 5, 0) end
	end
	local maxHealth = attacker:GetMaxHealth() > 0 and attacker:GetMaxHealth() or 100
	attacker:SetHealth(math.min(maxHealth, attacker:Health() + math.max(0, rewardHP:GetInt())))

	local needed = (progress.stage >= (progress.stagesTotal or 1)) and (MODE.KillsPerFinal or 1) or (MODE.KillsPerStage or 2)
	if progress.stageKills >= needed then
		progress.stageKills = 0
		if progress.stage >= progress.stagesTotal then
			MODE.winner = attacker
		else
			AdvanceStage(attacker)
		end
	end
	SyncHUD(attacker)

	net.Start("gungame_killfeed")
		net.WriteString(attacker:Nick() or "")
		net.WriteString(victim:Nick() or "")
	net.Broadcast()
end

function MODE:CanLaunch()
	return true
end

function MODE:Intermission()
	self.generation = self.generation + 1
	ResetProgress()
	game.CleanUpMap()

	self.ROUND_TIME = math.max(120, roundDuration:GetInt())
	if hg.UpdateRoundTime then hg.UpdateRoundTime(self.ROUND_TIME) end

	local variation, ladder, melee
	local forcedId = string.Trim(variationCvar:GetString() or "")
	if forcedId ~= "" then
		for _, entry in ipairs(self.Variations) do
			if entry.id == forcedId then
				ladder, melee = self:BuildLadder(entry)
				if ladder then variation = entry end
				break
			end
		end
	end
	if not variation then
		local order = {}
		for index, entry in ipairs(self.Variations) do order[index] = entry end
		for index = #order, 2, -1 do
			local swap = math.random(index)
			order[index], order[swap] = order[swap], order[index]
		end
		for _, entry in ipairs(order) do
			ladder, melee = self:BuildLadder(entry)
			if ladder then variation = entry break end
		end
	end
	if not variation or not ladder or not melee then
		ErrorNoHalt("[Gun Game] No usable weapon ladder: ending round.\n")
		self.winner = NULL
		return
	end

	self.roundLadder = ladder
	self.roundFinalWeapon = melee
	self.roundStagesTotal = #ladder
	self.allowed = { [melee] = true, weapon_hands_sh = true }
	for _, class in ipairs(ladder) do self.allowed[class] = true end
	SetGlobalInt("ZB_GGStages", #ladder)

	local lockUntil = self:StartLockUntil()
	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		ApplyAppearance(ply)
		ply:SetupTeam(0)
		InitPlayer(ply)
		zb.GiveRole(ply, "Contender", ROLE_COLOR)
		LockFake(ply, lockUntil)
	end

	net.Start("gungame_start")
		net.WriteUInt(self.ROUND_TIME, 16)
		net.WriteString(variation.name or "Gun Game")
		net.WriteString(variation.description or "")
		net.WriteUInt(#ladder, 8)
		for _, class in ipairs(ladder) do
			net.WriteString(class)
		end
	net.Broadcast()
end

function MODE:RoundStart()
	local generation = self.generation
	self.graceEnd = CurTime() + math.max(0, self.grace_time or 0)
	net.Start("gungame_grace")
		net.WriteFloat(self.graceEnd)
	net.Broadcast()

	for _, ply in player.Iterator() do
		ply:Freeze(false)
		LockFake(ply, self.graceEnd)
		if ply:Team() ~= TEAM_SPECTATOR then
			zb.GiveRole(ply, "Contender", ROLE_COLOR)
		end
	end

	local function StartCombat()
		if not ActiveRound(generation) or MODE.startGiven then return end
		for _, ply in player.Iterator() do
			local progress = MODE.PlayerProgress[ply]
			if ply:Alive() and ply:Team() ~= TEAM_SPECTATOR and progress then
				GiveProgressWeapon(ply, CurrentClass(progress))
				SyncHUD(ply)
			end
		end
		MODE.startGiven = true
	end

	if (self.grace_time or 0) <= 0 then
		StartCombat()
	else
		timer.Create(GRACE_TIMER, self.grace_time, 1, StartCombat)
	end
end

function MODE:GiveEquipment()
	for _, ply in player.Iterator() do
		if not ply:Alive() or ply:Team() == TEAM_SPECTATOR then continue end
		RemoveOwnedWeapons(ply)
		local handsClass = hg.GetHandsWeaponClass and hg.GetHandsWeaponClass(ply) or "weapon_hands_sh"
		ply:Give(handsClass)
		ply:SelectWeapon(handsClass)
	end
end

local function IsSpectator(ply)
	return not IsValid(ply) or ply:Team() == TEAM_SPECTATOR
end

local function CancelRespawn(ply)
	MODE.respawnDue[ply] = nil
end

local function IsLiveFake(ent)
	local owner = ent.ply
	if not IsValid(owner) or not owner:IsPlayer() or not owner:Alive() then return false end
	return owner.FakeRagdoll == ent or owner:GetNWEntity("FakeRagdoll") == ent
end

local function IsPlayerDebris(ent)
	if not IsValid(ent) then return false end
	if IsLiveFake(ent) then return false end
	if ent.severedLimb or ent.IsSeveredPart or (ent.GetNWBool and ent:GetNWBool("IsSeveredPart", false)) then return true end
	if not ent:IsRagdoll() then return false end
	if IsValid(ent.ply) and ent.ply:IsPlayer() then return true end
	if ent.organism then return true end
	return false
end

local CORPSE_CLEANUP_DELAY = 5
local CORPSE_CLEANUP_RANGE_SQR = (5 * 39.37) ^ 2

local function TrackDebris(ent)
	if not IsPlayerDebris(ent) or MODE.corpses[ent] then return end
	MODE.corpses[ent] = { createdAt = CurTime() }
	ent:CallOnRemove("gungame_debris", function(removed)
		if MODE.corpses then MODE.corpses[removed] = nil end
	end)
end

local function DebrisNearAnyone(ent)
	local pos = ent:WorldSpaceCenter()
	for _, ply in player.Iterator() do
		if not IsValid(ply) then continue end
		if ply:GetPos():DistToSqr(pos) <= CORPSE_CLEANUP_RANGE_SQR then return true end
	end
	return false
end

local function ThinkCorpses(now)
	if (MODE.nextCorpseThink or 0) > now then return end
	MODE.nextCorpseThink = now + 0.35

	for ent, data in pairs(MODE.corpses) do
		if not IsValid(ent) or IsLiveFake(ent) then
			MODE.corpses[ent] = nil
			continue
		end
		if now - (data.createdAt or now) < CORPSE_CLEANUP_DELAY then continue end
		if DebrisNearAnyone(ent) then continue end
		MODE.corpses[ent] = nil
		ent:Remove()
	end
end

function MODE:RoundThink()
	local now = CurTime()
	ThinkCorpses(now)
	local threshold = math.max(1, incapKillTime:GetFloat())
	for _, ply in player.Iterator() do
		if not ply:Alive() or ply:Team() == TEAM_SPECTATOR then self.incapSince[ply] = nil continue end
		local organism = ply.organism
		if organism and organism.incapacitated then self.incapSince[ply] = nil ply:Kill() continue end
		if not (organism and organism.otrub) then self.incapSince[ply] = nil continue end
		self.incapSince[ply] = self.incapSince[ply] or now
		if now - self.incapSince[ply] >= threshold then self.incapSince[ply] = nil ply:Kill() end
	end
end

function MODE:ShouldRoundEnd()
	if self.winner == NULL then return true end
	return IsValid(self.winner) or false
end

function MODE:CanSpawn(ply)
	return false
end

function MODE:ZB_JoinSpectators(ply)
	CancelRespawn(ply)
end

local function WritePortrait(ply)
	local model = IsValid(ply) and ply:GetModel() or "models/player/group01/male_07.mdl"
	net.WriteString(string.sub(model or "models/player/group01/male_07.mdl", 1, 192))
	net.WriteUInt(IsValid(ply) and math.Clamp(ply:GetSkin() or 0, 0, 255) or 0, 8)
	net.WriteFloat(IsValid(ply) and math.Clamp(ply:GetModelScale() or 1, 0.05, 10) or 1)
	net.WriteVector((IsValid(ply) and ply.GetPlayerColor and ply:GetPlayerColor()) or Vector(1, 1, 1))

	local bodygroups = {}
	if IsValid(ply) then
		for _, bodygroup in ipairs(ply:GetBodyGroups() or {}) do
			if #bodygroups >= 31 then break end
			bodygroups[#bodygroups + 1] = { id = math.Clamp(bodygroup.id or 0, 0, 255), value = math.Clamp(ply:GetBodygroup(bodygroup.id or 0), 0, 255) }
		end
	end
	net.WriteUInt(#bodygroups, 5)
	for _, bodygroup in ipairs(bodygroups) do
		net.WriteUInt(bodygroup.id, 8)
		net.WriteUInt(bodygroup.value, 8)
	end

	local subMaterials = {}
	if IsValid(ply) then
		for materialIndex = 0, math.min(#(ply:GetMaterials() or {}) - 1, 63) do
			local subMaterial = ply:GetSubMaterial(materialIndex)
			if isstring(subMaterial) and subMaterial ~= "" then
				subMaterials[#subMaterials + 1] = { index = materialIndex, material = string.sub(subMaterial, 1, 192) }
			end
		end
	end
	net.WriteUInt(math.min(#subMaterials, 63), 6)
	for index = 1, math.min(#subMaterials, 63) do
		net.WriteUInt(subMaterials[index].index, 8)
		net.WriteString(subMaterials[index].material)
	end

	local accessories = {}
	local stored = IsValid(ply) and ply.GetNetVar and ply:GetNetVar("Accessories")
	if istable(stored) then
		for _, accessory in ipairs(stored) do
			if #accessories >= 7 then break end
			if isstring(accessory) and accessory ~= "" then accessories[#accessories + 1] = string.sub(accessory, 1, 96) end
		end
	elseif isstring(stored) and stored ~= "" then
		accessories[1] = string.sub(stored, 1, 96)
	end
	net.WriteUInt(#accessories, 3)
	for _, accessory in ipairs(accessories) do
		net.WriteString(accessory)
	end
end

function MODE:EndRound()
	local generation = self.generation
	local ranks = {}
	for ply, progress in pairs(self.PlayerProgress) do
		if IsValid(ply) then
			ranks[#ranks + 1] = { ply = ply, kills = progress.kills or 0, stage = progress.stage or 1 }
		end
	end
	table.sort(ranks, function(a, b)
		if a.stage ~= b.stage then return a.stage > b.stage end
		return a.kills > b.kills
	end)

	local winner = IsValid(self.winner) and self.winner or (ranks[1] and ranks[1].ply) or NULL
	local top = {}
	for index, rank in ipairs(ranks) do
		local amount = KARMA_REWARDS[index]
		local karma = 0
		if amount and IsValid(rank.ply) then
			if amount == "max" then amount = zb.MaxKarma or 120 end
			local before = tonumber(rank.ply.Karma) or 100
			if zb.SetPlayerKarma then
				zb.SetPlayerKarma(rank.ply, before + amount, true)
			else
				rank.ply.Karma = math.Clamp(before + amount, -60, (zb.GetPlayerKarmaCap and zb.GetPlayerKarmaCap(rank.ply)) or (zb.MaxKarma or 120))
				if rank.ply.SetNetVar then rank.ply:SetNetVar("Karma", rank.ply.Karma) end
				if rank.ply.guilt_SetValue then rank.ply:guilt_SetValue(rank.ply.Karma) end
			end
			karma = math.max(0, math.Round((tonumber(rank.ply.Karma) or before) - before))
		end
		top[index] = {
			ply = rank.ply,
			name = rank.ply:Nick() or "",
			kills = rank.kills,
			stage = rank.stage,
			karma = karma
		}
	end

	if IsValid(winner) then
		if winner.GiveExp then winner:GiveExp(math.random(80, 140)) end
		if winner.GiveSkill then winner:GiveSkill(math.Rand(0.1, 0.25)) end
		if hg.achievements and hg.achievements.SetPlayerAchievement and hg.achievements.GetAchievementInfo and hg.achievements.GetAchievementInfo("gungame") then
			hg.achievements.SetPlayerAchievement(winner, "gungame", 1)
		end
	end

	timer.Remove(GRACE_TIMER)
	timer.Simple(2, function()
		if generation ~= MODE.generation or not CurrentRound() or CurrentRound().name ~= "gungame" then return end
		net.Start("gungame_end")
			net.WriteEntity(winner)
			net.WriteUInt(math.min(#top, 26), 7)
			for index = 1, math.min(#top, 26) do
				net.WriteString(top[index].name)
				net.WriteUInt(top[index].kills, 16)
				net.WriteUInt(top[index].stage or 1, 12)
				net.WriteUInt(math.Clamp(top[index].karma or 0, 0, 1023), 10)
				net.WriteEntity(IsValid(top[index].ply) and top[index].ply or NULL)
				local portrait = index <= 3
				net.WriteBool(portrait)
				if portrait then WritePortrait(top[index].ply) end
			end
		net.Broadcast()
	end)
end

function MODE:PlayerCanPickupWeapon(ply, weapon)
	if not IsValid(ply) or not IsValid(weapon) then return false end
	local class = weapon:GetClass()
	local granting = self.granting[ply]
	if istable(granting) then return granting[class] == true end
	if granting then return true end
	local handsClass = hg.GetHandsWeaponClass and hg.GetHandsWeaponClass(ply) or "weapon_hands_sh"
	return class == handsClass or weapon:GetOwner() == ply
end

function MODE:PlayerCanDropWeapon()
	return false
end

function MODE:PlayerSpawn(ply)
	if not IsValid(ply) then return end
	self.incapSince[ply] = nil
	self.DamageLog[ply] = nil
	if IsSpectator(ply) then
		CancelRespawn(ply)
		return
	end

	local progress = self.PlayerProgress[ply]
	if not progress then
		InitPlayer(ply)
		progress = self.PlayerProgress[ply]
		zb.GiveRole(ply, "Contender", ROLE_COLOR)
	end
	if not progress then return end

	local isRespawn = self.respawnDue[ply]
	if isRespawn then self.respawnDue[ply] = nil end
	local generation = self.generation
	timer.Simple(0, function()
		if not ActiveRound(generation) or not IsValid(ply) or not ply:Alive() or IsSpectator(ply) then return end
		if MODE:IsStartLocked() then LockFake(ply) end
		if isRespawn then
			ply:SetupTeam(0)
			zb.GiveRole(ply, "Contender", ROLE_COLOR)
		end
		if MODE.startGiven then GiveProgressWeapon(ply, CurrentClass(progress)) end
		SyncHUD(ply)
	end)
end

function MODE:PlayerDeath(victim, inflictor, attacker)
	if not ActiveRound(self.generation) or self.winner then return end
	if not IsValid(victim) or not victim:IsPlayer() or IsSpectator(victim) then return end
	self.incapSince[victim] = nil
	RewardKill(victim, attacker)
	RemoveOwnedWeapons(victim)
	victim:StripAmmo()

	local progress = self.PlayerProgress[victim]
	if not progress then return end
	local generation = self.generation
	local deathPos = victim:GetPos()
	timer.Simple(0, function()
		if not ActiveRound(generation) or not IsValid(victim) then return end
		TrackDebris(victim:GetNWEntity("RagdollDeath") or victim.RagdollDeath)
	end)

	if IsSpectator(victim) then return end
	self.respawnDue[victim] = true
	local delay = math.max(0, respawnDelay:GetFloat())
	net.Start("gungame_respawn")
		net.WriteFloat(CurTime() + delay)
	net.Send(victim)

	if progress.stage >= progress.stagesTotal then
		progress.stage = math.max(progress.stagesTotal - 1, 1)
		progress.stageKills = 0
		SyncHUD(victim)
	end

	timer.Simple(0.05, function()
		if not ActiveRound(generation) then return end
		for _, entity in ipairs(ents.FindInSphere(deathPos, 96)) do
			if entity:IsWeapon() and not IsValid(entity:GetOwner()) then entity:Remove() end
			TrackDebris(entity)
		end
	end)
	timer.Simple(delay, function()
		if not ActiveRound(generation) or not IsValid(victim) or victim:Alive() or IsSpectator(victim) then return end
		if not MODE.respawnDue[victim] then return end
		victim:Spawn()
	end)
end

hook.Add("HomigradDamage", "gungame_track_damage", function(victim, damageInfo, hitgroup, entity, harm)
	if not CurrentRound() or CurrentRound().name ~= "gungame" or (harm or 0) <= 0 then return end
	local attacker = damageInfo:GetAttacker()
	local weapon = IsValid(attacker) and attacker:IsPlayer() and attacker:GetActiveWeapon()
	if not IsValid(weapon) then return end
	local class = weapon:GetClass()
	if not (MODE.allowed and MODE.allowed[class]) then return end
	if not IsValid(victim) then return end
	if not victim:IsPlayer() then
		victim = victim.ply or (victim.organism and victim.organism.owner)
		if not IsValid(victim) or not victim:IsPlayer() then return end
	end
	local log = MODE.DamageLog[victim]
	if not log then
		log = {}
		MODE.DamageLog[victim] = log
	end
	local entry = log[attacker]
	if not entry then
		entry = { damage = 0, weapon = class }
		log[attacker] = entry
	end
	entry.damage = entry.damage + harm
	entry.weapon = class
end)

hook.Add("RagdollDeath", "gungame_track_corpse", function(_, ragdoll)
	if not CurrentRound() or CurrentRound().name ~= "gungame" then return end
	TrackDebris(ragdoll)
end)

hook.Add("OnEntityCreated", "gungame_track_corpses", function(ent)
	if not CurrentRound() or CurrentRound().name ~= "gungame" then return end
	if not IsValid(ent) or ent:GetClass() ~= "prop_ragdoll" then return end
	timer.Simple(0, function()
		if CurrentRound() and CurrentRound().name == "gungame" then TrackDebris(ent) end
	end)
end)

hook.Add("PlayerChangedTeam", "gungame_cancel_spectator_respawn", function(ply, _, newTeam)
	if not CurrentRound() or CurrentRound().name ~= "gungame" then return end
	if newTeam == TEAM_SPECTATOR then CancelRespawn(ply) end
end)

hook.Add("PlayerDroppedWeapon", "gungame_remove_dropped", function(owner, weapon)
	if not CurrentRound() or CurrentRound().name ~= "gungame" then return end
	RemoveUnownedWeapon(weapon)
end)

hook.Add("PlayerDisconnected", "gungame_cleanup_player", function(ply)
	MODE.PlayerProgress[ply] = nil
	ply:SetNWInt("GGStage", 0)
	ply:SetNWInt("GGKills", 0)
	MODE.DamageLog[ply] = nil
	MODE.respawnDue[ply] = nil
	MODE.granting[ply] = nil
	MODE.incapSince[ply] = nil
end)
