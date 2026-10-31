-- DO A SYNC WITH SQL ALREADY // OKAY I'LL DO IT MYSELF
zb = zb or {}

zb.GuiltTable = zb.GuiltTable or {}
zb.HarmDone = zb.HarmDone or {}
zb.HarmDoneKarma = zb.HarmDoneKarma or {}
zb.HarmDoneDetailed = zb.HarmDoneDetailed or {}
zb.HarmAttacked = zb.HarmAttacked or {}
zb.GuiltCombatHistory = zb.GuiltCombatHistory or {}
zb.GuiltThreatStates = zb.GuiltThreatStates or {}
zb.GuiltSQL = zb.GuiltSQL or {}
zb.GuiltSQL.PlayerInstances = zb.GuiltSQL.PlayerInstances or {}
zb.GuiltLowKarmaBans = zb.GuiltLowKarmaBans or {}

local hg_developer = ConVarExists("hg_developer") and GetConVar("hg_developer") or CreateConVar("hg_developer",0,FCVAR_SERVER_CAN_EXECUTE,"Toggle developer mode (enables damage traces)",0,1)

local function cfg()
    return ZCITY_GUILT.Config or ZCITY_GUILT.DefaultConfig
end

local PLAYER_KARMA_CAPS = {
    superadmin = 99999,
    owner = 99999,
    servermanager = 99999,
    headdeveloper = 99999,
    staffmanager = 250,
    headadmin = 250,
    developer = 99999,
    admin = 250,
    moderator = 250,
    supporter = 250,
    booster = 150
}

zb.GuiltRoundId = zb.GuiltRoundId or 0

local function IsHomicideRound(rnd)
    return rnd and (rnd.name == "hmcd" or rnd.name == "fear" or rnd.base == "hmcd")
end

local function isTraitorSubRole(value)
    if not isstring(value) then return false end

    value = string.lower(value)
    return string.sub(value, 1, 8) == "traitor_" and value ~= "traitor_disabled" and value ~= "traitor_disabled_soe"
end

function zb.IsTraitorLike(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if ply.isTraitor == true or ply.MainTraitor == true then return true end
    if isTraitorSubRole(ply.SubRole) then return true end

    if ply.GetNWBool and (ply:GetNWBool("isTraitor", false) or ply:GetNWBool("IsTraitor", false)) then
        return true
    end

    return false
end

function zb.IsRoundGuiltActive()
    return zb.ROUND_STATE == 1
end

function zb.IsHMCDLikeRound(rnd, cround)
    if not rnd then return false end

    cround = cround or zb.CROUND

    if rnd.name == "hmcd" or cround == "hmcd" then return true end
    if istable(rnd.Types) and (rnd.Types.standard or rnd.Types.wildwest) then return true end

    return false
end

local function ShouldSkipHmcdGuiltPenalty(attacker, victim, rnd)
    if not zb.IsHMCDLikeRound(rnd) then return false end
    if zb.IsTraitorLike(victim) and not zb.IsTraitorLike(attacker) then return true end
    if zb.IsTraitorLike(attacker) then return true end

    return false
end

local function GetPlayerKarmaCap(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return zb.MaxKarma end

    local userGroup = string.lower((ply.GetUserGroup and ply:GetUserGroup()) or "")
    if PLAYER_KARMA_CAPS[userGroup] then
        return PLAYER_KARMA_CAPS[userGroup]
    end

    return zb.MaxKarma
end

function zb.GetPlayerKarmaCap(ply)
    return GetPlayerKarmaCap(ply)
end

local IMMUNE_GROUPS = {
    "superadmin",
    "owner",
    "servermanager",
    "headdeveloper",
    "staffmanager",
    "headadmin",
    "developer",
    "admin",
    "moderator",
}

local function IsBanImmune(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local grp = string.lower(ply:GetUserGroup() or "")
    return table.HasValue(IMMUNE_GROUPS, grp)
end

local function IsRefundableWrongKill(attacker, victim, rnd)
    if not IsValid(attacker) or not attacker:IsPlayer() then return false end
    if not IsValid(victim) or not victim:IsPlayer() then return false end
    if attacker == victim then return false end
    if not IsHomicideRound(rnd) then return false end
    if attacker:Team() == TEAM_SPECTATOR or victim:Team() == TEAM_SPECTATOR then return false end

    return not zb.IsTraitorLike(attacker) and not zb.IsTraitorLike(victim)
end

local function GetBiggestAttacker(victim)
    local mostHarm, biggestAttacker = 0, nil

    for attacker, attackerHarm in pairs(zb.HarmDone[victim] or {}) do
        if not IsValid(attacker) then continue end
        if mostHarm < attackerHarm then
            mostHarm = attackerHarm
            biggestAttacker = attacker
        end
    end

    return biggestAttacker, mostHarm
end

local function ResetRoundRefundState(ply)
    if not IsValid(ply) then return end

    ply.GuiltWrongKillLossThisRound = 0
    ply.GuiltSuicideRefundUsed = false
    ply.GuiltSuicideDamageAt = 0
end

function zb.IsKarmaExemptWeapon(weapon)
    return IsValid(weapon) and weapon.GetClass and weapon:GetClass() == "weapon_taser"
end

function zb.IsKarmaExemptDamage(dmgInfo)
    if dmgInfo and dmgInfo.GetDamageCustom and dmgInfo:GetDamageCustom() == 9204 then return true end
    return dmgInfo and dmgInfo.GetInflictor and zb.IsKarmaExemptWeapon(dmgInfo:GetInflictor()) or false
end

local function GetGuiltDamageSource(attacker, dmgInfo)
    if zb.IsKarmaExemptDamage(dmgInfo) then return "taser" end
    local custom = dmgInfo and dmgInfo.GetDamageCustom and dmgInfo:GetDamageCustom() or 0

    if custom == 9203 then return "fentanyl" end
    if custom == 9202 then return "jumpkick" end
    if custom == 9201 then return "kick" end

    if IsValid(attacker) and attacker:IsPlayer() then
        if (attacker.PAT_JumpKickActiveUntil or 0) > CurTime() then return "jumpkick" end
        if attacker:GetNWFloat("InLegKick", 0) > CurTime() or (attacker.InLegKick or 0) > CurTime() then return "kick" end
    end

    return "damage"
end

zb.GetGuiltDamageSource = GetGuiltDamageSource

local function GetPairHarm(from, to)
    if not IsValid(from) or not IsValid(to) then return 0 end

    local harmTable = zb.HarmDone[from]
    return harmTable and (tonumber(harmTable[to]) or 0) or 0
end

local function GetCombatEntry(from, to)
    local history = zb.GuiltCombatHistory[from]
    local entry = history and history[to]
    if not istable(entry) then return nil end

    local age = CurTime() - (tonumber(entry.last) or 0)
    if age < 0 or age > cfg().SelfDefenseSeconds then return nil end

    return entry
end

local function GetStrikeContext(attacker, victim, threatIncoming)
    local atkCombat = GetCombatEntry(victim, attacker)
    local vicCombat = GetCombatEntry(attacker, victim)
    local atkFirst = atkCombat and (tonumber(atkCombat.first) or math.huge) or math.huge
    local vicFirst = vicCombat and (tonumber(vicCombat.first) or math.huge) or math.huge
    local recentIncoming = vicCombat and (tonumber(vicCombat.harm) or 0) or 0
    local victimStruckFirst = vicFirst < atkFirst
    if vicFirst == atkFirst and vicCombat and atkCombat and vicCombat.firstSequence and atkCombat.firstSequence then
        victimStruckFirst = vicCombat.firstSequence < atkCombat.firstSequence
    end

    threatIncoming = tonumber(threatIncoming) or 0
    if recentIncoming < threatIncoming then
        recentIncoming = threatIncoming
    end

    return {
        victimStruckFirst = victimStruckFirst,
        recentIncoming = recentIncoming,
        blockedAttack = vicCombat and tonumber(vicCombat.blockedMeleeAt) ~= nil
            and CurTime() >= vicCombat.blockedMeleeAt and CurTime() - vicCombat.blockedMeleeAt <= cfg().SelfDefenseSeconds,
    }
end

local function RecordGuiltCombatHarm(victim, attacker, amount, source)
    if not IsValid(victim) or not IsValid(attacker) then return end

    amount = math.max(0, tonumber(amount) or 0)
    if amount <= 0 and source ~= "gunfire" and source ~= "melee_threat" and source ~= "blocked_melee" then return end

    local now = CurTime()
    zb.GuiltCombatHistory[victim] = zb.GuiltCombatHistory[victim] or {}

    local entry = zb.GuiltCombatHistory[victim][attacker]
    if not istable(entry) or now - (tonumber(entry.last) or 0) > cfg().SelfDefenseSeconds then
        entry = { harm = 0, first = now }
    end

    entry.first = entry.first or now
    if not entry.firstSequence then
        zb.GuiltCombatSequence = (zb.GuiltCombatSequence or 0) + 1
        entry.firstSequence = zb.GuiltCombatSequence
    end

    entry.harm = math.min((tonumber(entry.harm) or 0) + amount, zb.MaximumHarm or 10)
    entry.last = now
    entry.source = tostring(source or "damage")
    zb.GuiltCombatHistory[victim][attacker] = entry
end

local function IsLethalMeleeWeapon(weapon)
    if not IsValid(weapon) or not weapon:IsWeapon() then return false end
    if not weapon.ismelee and not weapon.ismelee2 then return false end

    local primary = math.max(0, tonumber(weapon.DamagePrimary) or 0)
    local secondary = math.max(0, tonumber(weapon.DamageSecondary) or 0)
    local heavy = weapon.CanHeavyAttack and primary * math.max(1, tonumber(weapon.HeavyAttackDamageMul) or 1) or 0
    return math.max(primary, secondary, heavy) >= cfg().LethalMeleeMinDamage
end

local function RecordGuiltMeleeThreat(victim, attacker, dmgInfo, harm)
    if not IsValid(victim) or not IsValid(attacker) or victim == attacker then return end
    if (tonumber(harm) or 0) <= 0 or not dmgInfo then return end
    if not dmgInfo:IsDamageType(DMG_CLUB + DMG_SLASH) then return end

    -- Use the weapon responsible for this injury, not a later active-weapon swap.
    local inflictor = dmgInfo:GetInflictor()
    if not IsLethalMeleeWeapon(inflictor) then return end
    local weaponName = tostring(inflictor.PrintName or "lethal melee weapon")

    -- A glancing hit is evidence of a lethal attack, without inflating harm totals.
    RecordGuiltCombatHarm(victim, attacker, 0, "melee_threat")
    local entry = zb.GuiltCombatHistory[victim][attacker]
    entry.meleeThreatAt = CurTime()
    entry.meleeThreatWeapon = weaponName
end

local function GetSelfDefenseKarmaMul(responseRatio, retaliation)
    local c = cfg()
    responseRatio = math.max(0, tonumber(responseRatio) or 0)

    if responseRatio <= c.ProportionalResponseMaxRatio then
        return retaliation and c.SDKarmaProportionalRetaliation or c.SDKarmaProportional
    end

    if responseRatio <= c.ModerateResponseMaxRatio then
        return retaliation and c.SDKarmaModerateRetaliation or c.SDKarmaModerate
    end

    return math.Clamp(c.SDKarmaExcessive + (responseRatio - c.ModerateResponseMaxRatio) * c.SDKarmaExcessivePerRatio, c.SDKarmaExcessive, 1)
end


function zb.GetGuiltThreatState(victim, attacker, source, responseHarm)
    local state = {
        score = 0,
        karmaMul = 1,
        incomingHarm = 0,
        responseRatio = 0,
        source = tostring(source or "damage"),
        reasons = { "You had not hurt them recently." }
    }

    if not IsValid(victim) or not IsValid(attacker) then return state end

    local reciprocal = zb.GuiltCombatHistory[attacker] and zb.GuiltCombatHistory[attacker][victim]
    if not istable(reciprocal) then return state end

    local c = cfg()
    local threatWindow = c.SelfDefenseSeconds
    local age = CurTime() - (tonumber(reciprocal.last) or 0)
    if age < 0 or age > threatWindow then
        zb.GuiltCombatHistory[attacker][victim] = nil
        return state
    end

    local maxHarm = math.max(tonumber(zb.MaximumHarm) or c.MaxHarm, 1)
    local incomingHarm = math.Clamp(tonumber(reciprocal.harm) or 0, 0, maxHarm)
    local gunfireAt = tonumber(reciprocal.firearmThreatAt)
    local recentGunfire = gunfireAt and CurTime() >= gunfireAt and CurTime() - gunfireAt <= threatWindow
    local meleeAt = tonumber(reciprocal.meleeThreatAt)
    local recentMelee = meleeAt and CurTime() >= meleeAt and CurTime() - meleeAt <= threatWindow
    local blockedAt = tonumber(reciprocal.blockedMeleeAt)
    local recentBlock = blockedAt and CurTime() >= blockedAt and CurTime() - blockedAt <= threatWindow
    if incomingHarm < c.ThreatMinIncomingHarm and not recentGunfire and not recentMelee and not recentBlock then return state end

    local nativeResponse = zb.HarmDone[victim] and zb.HarmDone[victim][attacker] or 0
    local response = math.Clamp(tonumber(responseHarm) or tonumber(nativeResponse) or 0, 0, maxHarm)
    local ratio = response / math.max(incomingHarm, c.ThreatMinIncomingHarm)
    local recency = 1 - math.Clamp(age / math.max(threatWindow, 0.01), 0, 1)
    local severity = math.Clamp(incomingHarm / maxHarm, 0, 1)

    state.score = math.Clamp(0.15 + recency * 0.45 + severity * 0.4, 0, 1)
    state.incomingHarm = incomingHarm
    state.responseRatio = ratio
    state.source = tostring(source or reciprocal.source or "damage")

    local strike = GetStrikeContext(attacker, victim, incomingHarm)
    state.karmaMul = GetSelfDefenseKarmaMul(ratio, strike.victimStruckFirst)
    state.proportional = ratio <= c.ProportionalResponseMaxRatio
    state.excessive = ratio > c.ModerateResponseMaxRatio

    state.reasons = {
        recentBlock and incomingHarm == 0 and "You swung at them and they blocked it."
            or "You had already hurt them (" .. math.Round(incomingHarm, 1) .. " harm) before they hit you.",
        ratio <= c.ProportionalResponseMaxRatio and "Their hit-back was in line with how hard you hit them." or "They hit you harder than you had hit them.",
        strike.victimStruckFirst and "You hit them first in this fight." or "They hit you before you had hit them.",
        "This was " .. math.Round(age, 1) .. " seconds after the last hit between you."
    }

    local severeAt = tonumber(reciprocal.severeInjuryAt)
    if strike.victimStruckFirst and severeAt and CurTime() >= severeAt and CurTime() - severeAt <= threatWindow then
        state.severeSelfDefense = true
        state.protectedSelfDefense = true
        state.karmaMul = 0
        state.reasons = {
            "You took a limb off them and hit first.",
            "Their reply is treated as protected self-defense."
        }
    end

    if strike.victimStruckFirst and recentGunfire then
        state.protectedSelfDefense = true
        state.karmaMul = 0
        state.reasons = {
            "You shot at them or very close to them and started this fight.",
            "Their reply is treated as protected self-defense."
        }
    end

    if strike.victimStruckFirst and recentMelee then
        state.protectedSelfDefense = true
        state.meleeSelfDefense = true
        state.karmaMul = 0
        state.reasons = {
            "You hit first with a " .. tostring(reciprocal.meleeThreatWeapon or "lethal melee weapon") .. ".",
            "Even a glancing hit from that weapon is treated as a lethal threat.",
            "Their reply is treated as protected self-defense."
        }
    end

    return state
end

local SyncKarmaRuntime, EnforceLowKarma

hook.Add("DatabaseConnected", "GuiltCreateData", function()
	local query

	query = mysql:Create("zb_guilt")
		query:Create("steamid", "VARCHAR(20) NOT NULL")
		query:Create("steam_name", "VARCHAR(32) NOT NULL")
		query:Create("value", "FLOAT NOT NULL")
		query:PrimaryKey("steamid")
	query:Execute()

    zb.GuiltSQL.Active = true
end)

hook.Add( "PlayerInitialSpawn","ZB_GuiltSQL", function( ply )
    ply.GuiltKarmaLoaded = false
    local name = ply:Name()
	local steamID64 = ply:SteamID64()

    --if not zb.GuiltSQL.Active then
    --    zb.GuiltSQL.PlayerInstances[steamID64] = {}
    --    return
    --end 

	local query = mysql:Select("zb_guilt")
		query:Select("value")
		query:Where("steamid", steamID64)
		query:Callback(function(result)
			if not IsValid(ply) then return end
			if (IsValid(ply) and istable(result) and #result > 0 and result[1].value ~= nil) then
				local updateQuery = mysql:Update("zb_guilt")
					updateQuery:Update("steam_name", name)
					updateQuery:Where("steamid", steamID64)
				updateQuery:Execute()

				zb.GuiltSQL.PlayerInstances[steamID64] = {}

                zb.GuiltSQL.PlayerInstances[steamID64].value = tonumber(result[1].value)

                ply.Karma = ply:guilt_GetValue()
                ply:SetNetVar("Karma", ply.Karma)

                if zb.GuiltSQL.PlayerInstances[steamID64].value < 0 then
                    -- Finish the existing join reset before pending decisions are applied.
                    if IsBanImmune(ply) then SyncKarmaRuntime(ply, cfg().BanResetKarma)
                    else EnforceLowKarma(ply, cfg().BanResetKarma) end
                end
			else
				local insertQuery = mysql:Insert("zb_guilt")
					insertQuery:Insert("steamid", steamID64)
					insertQuery:Insert("steam_name", name)
					insertQuery:Insert("value", cfg().DefaultKarma)
				insertQuery:Execute()

				zb.GuiltSQL.PlayerInstances[steamID64] = {}

				zb.GuiltSQL.PlayerInstances[steamID64].value = cfg().DefaultKarma

                ply.Karma = ply:guilt_GetValue()
                ply:SetNetVar("Karma",ply.Karma)
			end

            if IsValid(ply) then
                ply.GuiltKarmaLoaded = true
                hook.Run("ZB_KarmaLoaded", ply)
            end
		end)
	query:Execute()

end)

local plyMeta = FindMetaTable("Player")

function plyMeta:guilt_GetValue()

    return zb.GuiltSQL.PlayerInstances[self:SteamID64()] and zb.GuiltSQL.PlayerInstances[self:SteamID64()].value or cfg().DefaultKarma

end

function plyMeta:guilt_SetValue( zb_guilt )

    zb_guilt = tonumber(zb_guilt) or cfg().DefaultKarma
    if zb_guilt <= 0 and not IsBanImmune(self) then
        SyncKarmaRuntime(self, math.max(zb_guilt, cfg().MinKarma))
        if EnforceLowKarma(self) then return end
    end

    local steamID64 = self:SteamID64()
	
	zb.GuiltSQL.PlayerInstances[self:SteamID64()] = zb.GuiltSQL.PlayerInstances[self:SteamID64()] or {}
	zb.GuiltSQL.PlayerInstances[self:SteamID64()].value = zb.GuiltSQL.PlayerInstances[self:SteamID64()].value or cfg().DefaultKarma
	
    zb.GuiltSQL.PlayerInstances[self:SteamID64()].value = zb_guilt

	local updateQuery = mysql:Update("zb_guilt")
		updateQuery:Update("value", zb_guilt)
		updateQuery:Where("steamid", steamID64)
	updateQuery:Execute()
end

SyncKarmaRuntime = function(ply, karma)
    ply.Karma = karma
    ply:SetNetVar("Karma", karma)

    local steamID64 = ply:SteamID64()
    zb.GuiltSQL.PlayerInstances[steamID64] = zb.GuiltSQL.PlayerInstances[steamID64] or {}
    zb.GuiltSQL.PlayerInstances[steamID64].value = karma
end

EnforceLowKarma = function(ply, resetKarma, banMinutes)
    if not IsValid(ply) or not ply:IsPlayer() or IsBanImmune(ply) then return false end
    local c = cfg()
    local karma = tonumber(ply.Karma) or c.DefaultKarma
    if karma > 0 then return false end

    local steamID64 = ply:SteamID64()
    local minutes = banMinutes or math.max(5, math.Round(c.BanMinutesBase - math.max(karma, c.MinKarma) * c.BanMinutesPerNegativeKarma, 0))
    local pending = zb.GuiltLowKarmaBans[steamID64]
    if pending then
        pending.minutes = math.max(pending.minutes, minutes)
    else
        zb.GuiltLowKarmaBans[steamID64] = {steamID = ply:SteamID(), name = ply:Name(), minutes = minutes}
        timer.Simple(0, function()
            local ban = zb.GuiltLowKarmaBans[steamID64]
            zb.GuiltLowKarmaBans[steamID64] = nil
            if not ban or (IsValid(ply) and IsBanImmune(ply)) then return end
            -- ULib records offline SteamIDs too; disconnecting cannot cancel this decision.
            ULib.addBan(ban.steamID, ban.minutes, "Kicked and banned for having too low karma.", ban.name, "System")
            PrintMessage(HUD_PRINTTALK, "Player " .. ban.name .. " has been banned for " .. ban.minutes .. " minutes for having too low karma.")
        end)
    end

    -- Persist the existing post-ban reset before later case decisions or disconnect saves.
    resetKarma = resetKarma or c.BanResetKarma
    SyncKarmaRuntime(ply, resetKarma)
    ply:guilt_SetValue(resetKarma)
    return true
end

function zb.SetPlayerKarma(ply, amount, persist)
    if not IsValid(ply) or not ply:IsPlayer() then return false end

    amount = math.Clamp(tonumber(amount) or 0, cfg().MinKarma, GetPlayerKarmaCap(ply))
    SyncKarmaRuntime(ply, amount)
    if EnforceLowKarma(ply) then return true end

    if persist ~= false and ply.guilt_SetValue then
        ply:guilt_SetValue(amount)
    end

    return true
end

local function IsLookingAt(ply, targetVec)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local diff = targetVec - ply:GetShootPos()
    return ply:GetAimVector():Dot(diff) / diff:Length() >= cfg().AimDotThreshold
end

local function ResolveGuiltPlayer(ent)
    if not IsValid(ent) then return nil end
    if ent:IsPlayer() then return ent end

    local owner = hg.RagdollOwner and hg.RagdollOwner(ent)
    if IsValid(owner) and owner:IsPlayer() then return owner end

    local org = ent.organism
    owner = org and org.owner
    if IsValid(owner) and owner:IsPlayer() then return owner end

    owner = ent.ply
    if IsValid(owner) and owner:IsPlayer() then return owner end

    return nil
end

zb.ResolveGuiltPlayer = ResolveGuiltPlayer

function zb.RecordGuiltBlockedMelee(attacker, victim, weapon)
    if not zb.IsRoundGuiltActive() then return end
    if zb.IsKarmaExemptWeapon(weapon) then return end
    local rnd = CurrentRound()
    if not rnd or rnd.GuiltDisabled or GetConVar("zb_dev"):GetBool() then return end
    attacker, victim = ResolveGuiltPlayer(attacker), ResolveGuiltPlayer(victim)
    if not IsValid(attacker) or not IsValid(victim) or attacker == victim then return end
    if not attacker:Alive() or not victim:Alive() or attacker:Team() == TEAM_SPECTATOR or victim:Team() == TEAM_SPECTATOR then return end
    if not IsValid(weapon) or not weapon:IsWeapon() or weapon:GetOwner() ~= attacker then return end

    -- A successful block is evidence of an attack, not damage to charge again.
    RecordGuiltCombatHarm(victim, attacker, 0, "blocked_melee")
    local entry = zb.GuiltCombatHistory[victim][attacker]
    entry.blockedMeleeAt = CurTime()
    if IsLethalMeleeWeapon(weapon) then
        entry.meleeThreatAt = CurTime()
        entry.meleeThreatWeapon = tostring(weapon.PrintName or "lethal melee weapon")
    end
end

-- Called only for a server-simulated, unobstructed bullet travel segment.
function zb.RecordGuiltBulletThreat(shooter, trace, damage, inflictor)
    if not zb.IsRoundGuiltActive() or (tonumber(damage) or 0) <= 0 then return end
    if zb.IsKarmaExemptWeapon(inflictor) then return end
    if not istable(trace) or trace.StartSolid or trace.AllSolid then return end
    if not isvector(trace.StartPos) or not isvector(trace.HitPos) then return end
    local rnd = CurrentRound()
    if not rnd or rnd.GuiltDisabled or GetConVar("zb_dev"):GetBool() then return end
    if IsValid(inflictor) and inflictor.RubberBullets then return end
    shooter = ResolveGuiltPlayer(shooter)
    if not IsValid(shooter) then return end

    local radius = cfg().GunfireNearMissRadius
    local delta = trace.HitPos - trace.StartPos
    local lengthSqr = delta:LengthSqr()
    if lengthSqr <= 0 then return end
    local seen = {}
    local hitPlayer = ResolveGuiltPlayer(trace.Entity)
    for _, candidate in ipairs(ents.FindAlongRay(trace.StartPos, trace.HitPos, Vector(-radius, -radius, -radius), Vector(radius, radius, radius))) do
        local victim = ResolveGuiltPlayer(candidate)
        local character = IsValid(victim) and hg.GetCurrentCharacter(victim) or nil
        if IsValid(victim) and victim ~= shooter and not seen[victim] and victim:Alive() and victim:Team() ~= TEAM_SPECTATOR
            and (candidate == victim or candidate == character) then
            seen[victim] = true
            if not IsValid(character) then character = victim end
            local head = victim:EyePos()
            if character ~= victim then
                local bone = character:LookupBone("ValveBiped.Bip01_Head1")
                head = bone and character:GetBonePosition(bone) or character:WorldSpaceCenter()
            end

            local threatened = hitPlayer == victim
            for _, point in ipairs({head, character:WorldSpaceCenter()}) do
                if not threatened and isvector(point) then
                    -- Do not extend the trajectory behind the muzzle or beyond its impact.
                    local fraction = (point - trace.StartPos):Dot(delta) / lengthSqr
                    if fraction >= 0 and fraction <= 1 then
                        local closest = trace.StartPos + delta * fraction
                        if closest:DistToSqr(point) <= radius * radius then
                            local visibility = util.TraceLine({start = closest, endpos = point,
                                filter = {shooter, victim, character}, mask = MASK_SHOT})
                            threatened = not visibility.Hit and not visibility.StartSolid
                        end
                    end
                end
            end
            if threatened then
                RecordGuiltCombatHarm(victim, shooter, 0, "gunfire")
                zb.GuiltCombatHistory[victim][shooter].firearmThreatAt = CurTime()
            end
        end
    end
end

hook.Add("PostEntityFireBullets", "GuiltIncomingGunfire", function(ent, bullet)
    if not istable(bullet) then return end
    local shooter = ResolveGuiltPlayer(bullet.Attacker) or ResolveGuiltPlayer(ent)
    if not IsValid(shooter) and IsValid(ent) then shooter = ResolveGuiltPlayer(ent:GetOwner()) end
    zb.RecordGuiltBulletThreat(shooter, bullet.Trace, bullet.Damage, ent)
end)

hook.Add("OnAmputateLimb", "GuiltSevereInjury", function(org, ent, limb, attacker, damageContext)
    if not zb.IsRoundGuiltActive() then return end
    if istable(damageContext) and zb.IsKarmaExemptWeapon(damageContext.inflictor) then return end
    local fatal = limb == "head" or limb == "torso"
    if not fatal and limb ~= "lleg" and limb ~= "rleg" and limb ~= "larm" and limb ~= "rarm" then return end

    local victim = ResolveGuiltPlayer(ent) or ResolveGuiltPlayer(org and org.owner)
    attacker = ResolveGuiltPlayer(attacker)
    if not IsValid(victim) or not IsValid(attacker) or attacker == victim then return end
    if not fatal and (not victim:Alive() or not org or org.alive == false) then return end

    -- Some amputation paths run before HomigradDamage. Seed only combat evidence,
    -- not native harm/karma totals, so even those injuries have an attributed threat.
    RecordGuiltCombatHarm(victim, attacker, cfg().ThreatMinIncomingHarm, "amputation")
    zb.GuiltCombatHistory[victim][attacker].severeInjuryAt = CurTime()

    if limb ~= "torso" then return end
    local maxHarm = math.max(tonumber(zb.MaximumHarm) or 10, 1)
    local oldHarm = zb.HarmDone[victim] and tonumber(zb.HarmDone[victim][attacker]) or 0
    local missingHarm = math.max(maxHarm - oldHarm, 0)
    if missingHarm <= 0 then return end

    local context = istable(damageContext) and damageContext or {}
    local fatalDamage = DamageInfo()
    fatalDamage:SetAttacker(attacker)
    fatalDamage:SetInflictor(IsValid(context.inflictor) and context.inflictor or attacker)
    fatalDamage:SetDamageType(tonumber(context.damageType) or DMG_SLASH)
    fatalDamage:SetDamage(missingHarm * 100)
    fatalDamage:SetDamagePosition(isvector(context.position) and context.position or ent:WorldSpaceCenter())
    fatalDamage:SetDamageForce(isvector(context.force) and context.force or vector_origin)
    hook.Run("HomigradDamage", victim, fatalDamage, HITGROUP_STOMACH, ent, missingHarm)
end)

local function GetPlayerLifeGuilt(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return 0 end

    local guilt = tonumber(ply.Guilt) or 0
    local guiltTable = zb.GuiltTable and zb.GuiltTable[ply]

    if istable(guiltTable) then
        for _, amount in pairs(guiltTable) do
            guilt = math.max(guilt, tonumber(amount) or 0)
        end
    end

    return guilt
end

local function forceArmedReason()
    return "Law enforcement shot a player holding a firearm or lethal melee weapon: " .. math.Round(cfg().ForceArmedPenaltyMul * 100) .. "% of the otherwise applicable penalty."
end

local function IsForceArmedTargetShot(attacker, victim, dmgInfo)
    if not zb.IsForce(attacker) or not dmgInfo or not dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT) then return false end
    victim = ResolveGuiltPlayer(victim)
    if not IsValid(victim) or victim == attacker or zb.IsForce(victim) or victim == zb.hostage then return false end

    local weapon = victim:GetActiveWeapon()
    if not IsValid(weapon) or not weapon:IsWeapon() then return false end
    return ishgweapon(weapon) or IsLethalMeleeWeapon(weapon)
end

function zb.EvaluateEngagement(attacker, victim, opts)
    opts = opts or {}

    local result = {
        karmaMultiplier = 1,
        guiltMultiplier = 1,
        aggressor = nil,
        defender = nil,
        confidence = 0,
        retaliation = false,
        maxKarmaPenalty = nil,
        reasons = {}
    }

    if not IsValid(attacker) or not IsValid(victim) or attacker == victim then
        result.karmaMultiplier = 0
        result.guiltMultiplier = 0
        return result
    end

    local c = cfg()
    local maxHarm = math.max(tonumber(zb.MaximumHarm) or c.MaxHarm, 1)
    local responseHarm = opts.responseHarm
    local threatState = opts.threatState or zb.GetGuiltThreatState(victim, attacker, opts.source, responseHarm)

    local atkHarm = GetPairHarm(victim, attacker)
    local vicHarm = GetPairHarm(attacker, victim)
    local totalExchange = atkHarm + vicHarm
    local atkShare = totalExchange > 0 and (atkHarm / totalExchange) or 1

    local incomingHarm = tonumber(threatState.incomingHarm) or 0
    local responseRatio = tonumber(threatState.responseRatio) or 0
    local threatScore = tonumber(threatState.score) or 0
    local victimAggression = tonumber(victim.GuiltAggressionScore) or 0
    local strike = GetStrikeContext(attacker, victim, incomingHarm)
    local victimStruckFirst = strike.victimStruckFirst
    local activeThreat = threatScore >= c.ActiveThreatScore and incomingHarm >= c.ThreatMinIncomingHarm
    local retaliation = victimStruckFirst and (strike.recentIncoming >= c.ThreatMinIncomingHarm or strike.blockedAttack == true)

    result.retaliation = retaliation

    local karmaMul = 1
    local guiltMul = 1
    local confidence = 0.35
    local reasons = result.reasons

    if victimAggression >= c.AggressionScoreThreshold and not zb.IsForce(attacker) then
        karmaMul = math.Clamp(0.03 + (1 - victimAggression) * 0.04, 0.03, 0.08)
        guiltMul = karmaMul
        result.aggressor = victim
        result.defender = attacker
        reasons[#reasons + 1] = "Victim has an elevated aggression score from prior unjustified harm."
        confidence = 0.65 + victimAggression * 0.35
    elseif activeThreat or retaliation then
        result.aggressor = victim
        result.defender = attacker
        karmaMul = math.max(GetSelfDefenseKarmaMul(responseRatio, retaliation), tonumber(threatState.karmaMul) or 1)
        guiltMul = retaliation and karmaMul or math.max(karmaMul, 0.35)
        reasons[#reasons + 1] = retaliation
            and "Retaliation within the threat window after the victim struck first."
            or "Victim recently harmed the attacker."
        confidence = math.max(threatScore, retaliation and 0.55 or 0.5)
    elseif vicHarm >= maxHarm * 0.15 and atkHarm >= maxHarm * 0.15 then
        local balance = 1 - math.abs(atkShare - 0.5) * 2
        karmaMul = 0.20 + (1 - balance) * 0.20
        guiltMul = karmaMul

        if victimStruckFirst then
            result.aggressor = victim
            result.defender = attacker
        else
            result.aggressor = attacker
            result.defender = victim
        end

        reasons[#reasons + 1] = "Both players exchanged significant damage."
        confidence = 0.45 + balance * 0.45
    elseif vicHarm <= maxHarm * 0.05 and strike.recentIncoming < c.ThreatMinIncomingHarm then
        karmaMul = 1
        guiltMul = 1
        result.aggressor = attacker
        result.defender = victim
        result.retaliation = false
        reasons[#reasons + 1] = "No meaningful prior harm from the victim."
        confidence = math.Clamp(atkHarm / maxHarm, 0.35, 1)
    else
        karmaMul = 0.45
        guiltMul = 0.45
        result.aggressor = victimStruckFirst and victim or attacker
        result.defender = victimStruckFirst and attacker or victim
        reasons[#reasons + 1] = "Mixed engagement with limited reciprocity."
        confidence = 0.4
    end

    local oldHarmDone = tonumber(opts.oldHarmDone) or 0
    local victimAlreadyDown = oldHarmDone >= maxHarm
    local victimAlive = opts.victimAlive

    if victimAlive == nil and victim:IsPlayer() then
        victimAlive = victim:Alive()
    end

    if victimAlreadyDown or victimAlive == false then
        if retaliation and responseRatio <= c.ProportionalResponseMaxRatio then
            reasons[#reasons + 1] = "Proportional retaliation against the player who initiated the fight."
        elseif incomingHarm >= c.ThreatMinIncomingHarm and responseRatio > c.ProportionalResponseMaxRatio then
            local excess = math.Clamp((responseRatio - 1.5) / 2, 0, 1)
            karmaMul = math.max(karmaMul, 0.5 + excess * 0.5)
            guiltMul = math.max(guiltMul, karmaMul)
            reasons[#reasons + 1] = "Excessive damage continued after the threat was neutralized."
        elseif incomingHarm < c.ThreatMinIncomingHarm then
            karmaMul = math.max(karmaMul, 0.85)
            guiltMul = math.max(guiltMul, karmaMul)
            reasons[#reasons + 1] = "Additional harm dealt to an incapacitated victim."
        end
    end

    if result.retaliation and opts.lethalContribution then
        local incomingSeverity = math.Clamp(incomingHarm / maxHarm, 0, 1)
        local credibleLethalDefense = incomingSeverity >= c.LethalDefenseMinIncoming
            and responseRatio <= c.LethalDefenseMaxRatio

        if credibleLethalDefense then
            result.maxKarmaPenalty = c.RetaliationKillKarmaCap
            reasons[#reasons + 1] = "Lethal force followed substantial incoming harm."
        else
            local ratioExcess = math.Clamp((responseRatio - c.ProportionalResponseMaxRatio) / 2, 0, 1)
            local severityShortfall = math.Clamp((c.LethalDefenseMinIncoming - incomingSeverity) / math.max(c.LethalDefenseMinIncoming, 0.01), 0, 1)
            local lethalMul = 0.75 + math.max(ratioExcess, severityShortfall) * 0.25

            karmaMul = math.max(karmaMul, lethalMul)
            guiltMul = math.max(guiltMul, lethalMul)
            result.maxKarmaPenalty = nil
            reasons[#reasons + 1] = "Lethal force was disproportionate to the incoming threat."
        end
    end

    if zb.IsForce(attacker) and victimAggression >= c.AggressionScoreThreshold then
        karmaMul = 1
        guiltMul = 1
        result.retaliation = false
        result.maxKarmaPenalty = nil
    end

    if IsForceArmedTargetShot(attacker, victim, opts.dmgInfo) then
        karmaMul = karmaMul * c.ForceArmedPenaltyMul
        if result.maxKarmaPenalty ~= nil then result.maxKarmaPenalty = result.maxKarmaPenalty * c.ForceArmedPenaltyMul end
        result.forceArmedTarget = true
        reasons[#reasons + 1] = forceArmedReason()
    end

    if threatState.protectedSelfDefense == true or threatState.severeSelfDefense == true then
        karmaMul = 0
        guiltMul = 0
        result.retaliation = true
        result.aggressor = victim
        result.defender = attacker
        result.maxKarmaPenalty = 0
        reasons[#reasons + 1] = "Protected response to a recent lethal threat from the initiator."
    end

    result.karmaMultiplier = math.Clamp(karmaMul, 0, 1.25)
    result.guiltMultiplier = math.Clamp(guiltMul, 0, 1.25)
    result.confidence = math.Clamp(confidence, 0, 1)

    return result
end

local function UpdateAggressionScore(ply, amt, engagement)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if engagement.aggressor ~= ply then return end
    if (engagement.karmaMultiplier or 1) < 0.35 then return end

    local delta = amt * engagement.karmaMultiplier * math.max(engagement.confidence or 0.25, 0.25) * 0.6
    local score = (ply.GuiltAggressionScore or 0) + delta

    if engagement.karmaMultiplier >= 0.95 then
        score = math.max(score, cfg().AggressionScoreThreshold + amt * 0.35)
    end

    ply.GuiltAggressionScore = math.Clamp(score, 0, 1)
end

function zb.IsPlayerGuiltyThisLife(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end

    if (ply.GuiltAggressionScore or 0) >= cfg().AggressionScoreThreshold then
        return true
    end

    return GetPlayerLifeGuilt(ply) > cfg().GuiltyThisLifeThreshold
end

hook.Add("HomigradDamage", "GuiltReg", function(ply, dmgInfo, hitgroup, ent, harm) 
    local Attacker, Victim = dmgInfo:GetAttacker(), ply
    local rnd = CurrentRound()

    if not zb.IsRoundGuiltActive() then return end
    -- Skip before harm totals, rewards, aggression, and ban accounting are updated.
    if zb.IsKarmaExemptDamage(dmgInfo) then return end

    if IsValid(Attacker) and Attacker == Victim and Attacker:IsPlayer() and Attacker.suiciding and IsHomicideRound(rnd) then
        Attacker.GuiltSuicideDamageAt = CurTime()
    end
    
    --[[if !IsValid(Attacker) and dmgInfo:GetInflictor().steamid then
        local steamid = dmgInfo:GetInflictor().steamid
        
        ULib.addBan( steamid, 60, "Kicked and banned for trying to exploit karma system.", steamid, "System" )
    end--]]

    if not IsValid(Attacker) or not Attacker:IsPlayer() then return end
    if not IsValid(Victim) or not (Victim:IsPlayer() or (Victim.organism.fakePlayer and Victim.organism.alive)) then return end
	if Victim:IsNPC() or Victim:IsNextBot() then return end

    Victim = hg.GetCurrentCharacter(Victim) or Victim
    Victim = hg.RagdollOwner(Victim) or Victim

    local id = Victim:IsPlayer() and Victim:SteamID() or Victim:EntIndex()
    local id2 = Attacker:IsPlayer() and Attacker:SteamID() or Attacker:EntIndex()
    local maxharm = zb.MaximumHarm
    zb.HarmDone[Victim] = zb.HarmDone[Victim] or {}
    zb.HarmDoneDetailed[id] = zb.HarmDoneDetailed[id] or {}
    zb.HarmDoneKarma[Victim] = zb.HarmDoneKarma[Victim] or {}
    zb.HarmDoneKarma[Victim][Attacker] = zb.HarmDoneKarma[Victim][Attacker] or 0
    
    local oldharmdone = zb.HarmDone[Victim][Attacker] or 0
    zb.HarmDone[Victim][Attacker] = math.Clamp((zb.HarmDone[Victim][Attacker] or 0) + harm, 0, maxharm)
    
    zb.HarmAttacked[Attacker] = zb.HarmAttacked[Attacker] or 0
    zb.HarmAttacked[Attacker] = zb.HarmAttacked[Attacker] + harm

    local reportedHarm = harm
    local newharm = math.min(harm + oldharmdone, maxharm)
    local harm = newharm - oldharmdone
    local amt = harm / maxharm
    local damageSource = GetGuiltDamageSource(Attacker, dmgInfo)

    RecordGuiltCombatHarm(Victim, Attacker, harm, damageSource)
    RecordGuiltMeleeThreat(Victim, Attacker, dmgInfo, reportedHarm)
    zb.GuiltThreatStates[Victim] = zb.GuiltThreatStates[Victim] or {}
    local threatState = zb.GetGuiltThreatState(Victim, Attacker, damageSource, newharm)
    zb.GuiltThreatStates[Victim][Attacker] = threatState
    
    if amt > 0.2 or newharm / maxharm > 0.8 then
        --print("Player "..Attacker:Name().." harmed player "..(Victim:IsPlayer() and Victim:Name() or (tostring(Victim))).." with "..harm.." points.")
        --print("They contributed a total of "..math.Round(newharm / maxharm * 100, 0).."% of "..(Victim:IsPlayer() and Victim:Name() or (tostring(Victim))).."'s death")
    end

    if zb and zb.hostage and Victim == zb.hostage then
        zb.hostageLastTouched = Attacker
    end

    local attackerTeam = Attacker:Team()
    zb.HarmDoneDetailed[id][id2] = {
        harm = newharm,
        amt = newharm / maxharm,
        teamVictim = Victim:IsPlayer() and Victim:Team() or Victim.team or -1,
        teamAttacker = attackerTeam or -1,
        lasthitgroup = hitgroup,
        lastdmgtype = dmgInfo:GetDamageType(),
        lastattacked = CurTime(),
    }

    if hg_developer:GetBool() then
        Attacker:ChatPrint("This harm done is: "..math.Round(harm,3))
        Attacker:ChatPrint("Overall amt done is: "..math.Round(amt,3))
        Attacker:ChatPrint("Overall harm done is: "..math.Round(newharm,3))
        Attacker:ChatPrint("Guilt done is: "..math.Round(amt * cfg().NativeGuiltScale,3))
        Attacker:ChatPrint(" ")
    end

    hook.Run("HarmDone", Attacker, Victim, amt)

    if newharm >= maxharm and oldharmdone < newharm then
        --Attacker:AddFrags(1) -- better make it a system that counts kills and gives frags at the end of the round
    end

    if not rnd or rnd.GuiltDisabled or GetConVar("zb_dev"):GetBool() then return end

    if Attacker == Victim then return end

    zb.GuiltTable[Attacker] = zb.GuiltTable[Attacker] or {}
    zb.GuiltTable[Victim] = zb.GuiltTable[Victim] or {}
    
    Attacker.LastAttacked = CurTime()

    local c = cfg()
    if newharm >= maxharm and oldharmdone < newharm and player.GetCount() >= c.HelpfulActionMinPlayers and zb.IsTraitorLike(Victim) and not zb.IsTraitorLike(Attacker) then
        Attacker.Karma = math.Clamp((Attacker.Karma or c.DefaultKarma) + c.TraitorKillKarmaReward, c.MinKarma, GetPlayerKarmaCap(Attacker))
        Attacker:SetNetVar("Karma", Attacker.Karma)
    end

    if ShouldSkipHmcdGuiltPenalty(Attacker, Victim, rnd) then return end
    
    if rnd.name != "hmcd" and attackerTeam ~= Victim:Team() then return end

    local guiltVictim = ResolveGuiltPlayer(ply) or ResolveGuiltPlayer(Victim) or (Victim:IsPlayer() and Victim or nil)

    if Attacker:IsBerserk() then return end

    local victimWep = Victim:IsPlayer() and IsValid(Victim:GetActiveWeapon()) and Victim:GetActiveWeapon()
    
    if newharm >= maxharm and oldharmdone < newharm then
        --Attacker:AddFrags(-1)
    end
    
    local lookDist = c.ArmedMeleeLookDistance
    amt = amt
        * (Victim:IsPlayer() and math.Clamp(((Victim.Karma or c.DefaultKarma) / GetPlayerKarmaCap(Victim)), 1, 1.2) or 1)
        * (Victim:IsPlayer() and ((IsLookingAt(Victim, Attacker:EyePos()) and (victimWep and (ishgweapon(victimWep) or ((victimWep:GetClass() == "weapon_hands_sh" and victimWep:GetFists() or victimWep.ismelee2) and Victim:EyePos():DistToSqr(Attacker:EyePos()) <= (lookDist * lookDist))))) and c.ArmedLookPenaltyMul or 1) or 1)

    local add = amt * maxharm

    add = add * (Victim:IsPlayer() and Attacker:PlayerClassEvent("Guilt", Victim) or 1)
    add = add * c.NativeGuiltMul

    local mul, shouldBanGuilt = 1, false

    if rnd.GuiltCheck then
        local guiltMul, guiltBan = rnd.GuiltCheck(Attacker, Victim, add, harm, amt)

        mul = guiltMul or 1
        shouldBanGuilt = guiltBan == true
    end

    add = add * mul

    local engagement = zb.EvaluateEngagement(Attacker, guiltVictim or Victim, {
        dmgInfo = dmgInfo,
        responseHarm = newharm,
        threatState = threatState,
        source = damageSource,
        oldHarmDone = oldharmdone,
        victimAlive = Victim:IsPlayer() and Victim:Alive() or true,
        lethalContribution = newharm >= maxharm and oldharmdone < newharm,
    })

    if engagement.forceArmedTarget then
        threatState.reasons[#threatState.reasons + 1] = forceArmedReason()
    end

    add = add * engagement.karmaMultiplier

    local guiltadd = amt * c.NativeGuiltScale * engagement.guiltMultiplier
    UpdateAggressionScore(engagement.aggressor, amt, engagement)

    if hg_developer:GetBool() then
        Attacker:ChatPrint("Engagement karma x" .. math.Round(engagement.karmaMultiplier, 2) .. " (" .. table.concat(engagement.reasons, " | ") .. ")")
    end
    Attacker.Guilt = (Attacker.Guilt or 0) + guiltadd
    local priorGuilt = zb.GuiltTable[Attacker][Victim] or 0
    local karmaPenalty = add * math.max((1 - priorGuilt / c.NativeGuiltScale), 0)
    if engagement.maxKarmaPenalty then
        karmaPenalty = math.min(karmaPenalty, engagement.maxKarmaPenalty)
    end
    Attacker.Karma = math.Clamp((Attacker.Karma or c.DefaultKarma) - karmaPenalty, c.MinKarma, GetPlayerKarmaCap(Attacker))

    zb.HarmDoneKarma[Victim][Attacker] = zb.HarmDoneKarma[Victim][Attacker] + karmaPenalty

    if shouldBanGuilt and Attacker.Guilt >= c.TeamDamageGuiltLimit then
        if Attacker.GuiltBanSent then return end 
        Attacker.GuiltBanSent = true

        if not IsBanImmune(Attacker) then
            ULib.addBan(Attacker:SteamID(), c.TeamDamageBanMinutes, "Kicked and banned for dealing too much team damage.", Attacker:Name(), "System")

            PrintMessage(HUD_PRINTTALK,
                "Player " .. Attacker:Name() .. " has been banned for " .. c.TeamDamageBanMinutes .. " minutes for RDMing in a team based gamemode."
            )
        end
    end

    Attacker:SetNetVar("Karma", Attacker.Karma)
    
    zb.GuiltTable[Attacker][Victim] = math.Clamp((zb.GuiltTable[Attacker][Victim] or 0) + guiltadd, 0, c.NativeGuiltPairCap)

    EnforceLowKarma(Attacker)
end)

function zb.IsForce(Attacker)
    local class = Attacker.PlayerClassName
    return class == "police" or class == "nationalguard" or class == "swat"
end

function zb.ForcesAttackedInnocent(self, Victim)
    local victimWep = Victim:IsPlayer() and IsValid(Victim:GetActiveWeapon()) and Victim:GetActiveWeapon()

    local c = cfg()
    local lookDist = c.PoliceLookDistance
    return 1 * ((!Victim.LastAttacked or (Victim.LastAttacked + c.PoliceRecentAttackWindow > CurTime())) and 0 or 1) + 1 * (Victim:IsPlayer() and ((IsLookingAt(Victim, self:EyePos()) and (victimWep and (ishgweapon(victimWep) or ((victimWep:GetClass() == "weapon_hands_sh" and victimWep:GetFists() or victimWep.ismelee2) and Victim:GetPos():DistToSqr(self:GetPos()) <= (lookDist * lookDist))))) and 0 or 1) or 1)
end

hook.Add("PlayerDisconnected","GuiltSaveOnDisconect",function(ply)
    if ply.GuiltKarmaLoaded == false then return end
    ply:guilt_SetValue( ply.Karma or cfg().DefaultKarma )
end)

hook.Add("Player Spawn","SlowlyRestoreKarma",function(ply)
    if OverrideSpawn then return end

    ply.lastwarning = nil
    --ply.firstwarning = nil
    ply.Karma = ply.Karma or cfg().DefaultKarma
    ply:SetNetVar("Karma",ply.Karma)
    --ply:guilt_SetValue( ply.Karma or 100 )
    
    ply.Guilt = 0
    ply.GuiltAggressionScore = 0
    -- Combat justification belongs to this life, including attributed limb loss.
    zb.GuiltCombatHistory[ply] = nil
    for _, history in pairs(zb.GuiltCombatHistory) do
        history[ply] = nil
    end
end)

hook.Add("Player Think", "karmagain", function(ply)
    if not zb.IsRoundGuiltActive() then return end
    if (ply.KarmaGainThink or 0) > CurTime() then return end
    local c = cfg()
    ply.KarmaGainThink = CurTime() + c.KarmaRegenInterval

    ply.Karma = math.Clamp(ply.Karma + (ply.KarmaGain or c.KarmaRegenDefault), c.MinKarma, GetPlayerKarmaCap(ply))
    
    ply:SetNetVar("Karma", ply.Karma)
    --ply:guilt_SetValue( ply.Karma or 100 )
end)

hook.Add("Org Clear","removekarmashaking",function(org)
    org.start_shaking = nil
end)

hook.Add("Should Fake Up", "karma", function(ply)
    if ply.organism and ply.organism.start_shaking then return false end
end)

local seizuremsgs = {
    "bllllhlhmmmbmmmmbmbmb",
    "bbb b-bbbbbb bllmbmmbb",
    "ddgdgg-d bbbglgggg",
    "mmmmammmm aaghbgbblllb",
    "hhel-bbbphphpppph",
    "zzzzblzzzmzzzzz",
}
hook.Add("Org Think", "Its_Karma_Bro",function(owner, org, timeValue)
    if not owner or not owner:IsPlayer() or org.otrub or not org.isPly then return end
    if not owner:IsPlayer() or not owner:Alive() then return end
    if IsBanImmune(owner) then return end
    
    local ply = owner
    local c = cfg()
    
    if (ply.Karma or c.DefaultKarma) < c.SeizureKarmaBelow then
        if ((math.random(math.Clamp((ply.Karma or c.DefaultKarma),20,zb.MaxKarma) * 300) == 1 or org.start_shaking)) then
            hg.StunPlayer(ply)
            local time = c.SeizureDuration
            
            ply:Notify(seizuremsgs[math.random(#seizuremsgs)], 16, "seizure", 1, function()
                if !IsValid(ply) then return end
                
                ply:ChatPrint("You are experiencing an epileptic seizure.")
            end)

            org.start_shaking = org.start_shaking or (CurTime() + time)
            local ent = hg.GetCurrentCharacter(owner)
            local mul = ((org.start_shaking) - CurTime()) / time
            
            if mul > 0 then
                ent:GetPhysicsObjectNum(math.random(ent:GetPhysicsObjectCount()) - 1):ApplyForceCenter(VectorRand(-750 * mul,750 * mul))
            else
                org.start_shaking = nil
            end
        else
            org.start_shaking = nil
        end
	end

    if (ply.Karma or c.DefaultKarma) < c.VomitKarmaBelow then
        if math.random(c.VomitChance) == 1 then
            hg.organism.Vomit(owner)
        end
    end
end)

hook.Add("ZB_EndRound","savevalues",function()
    local c = cfg()
    if player.GetCount() >= c.HelpfulActionMinPlayers then
        for _, ply in player.Iterator() do
            if not IsValid(ply) or not ply:Alive() or ply:Team() == TEAM_SPECTATOR or zb.IsTraitorLike(ply) then continue end

            ply.Karma = math.Clamp((ply.Karma or c.DefaultKarma) + c.RoundSurviveKarma, c.MinKarma, GetPlayerKarmaCap(ply))
            ply:SetNetVar("Karma", ply.Karma)
        end
    end

    for i,ply in player.Iterator() do
        if ply.GuiltKarmaLoaded == false then continue end
        ply:guilt_SetValue( ply.Karma or c.DefaultKarma )
    end
end)

hook.Add("ZB_PlayerBandaged", "GuiltReg", function(healer, patient)
    local c = cfg()
    if not zb.IsRoundGuiltActive() or player.GetCount() < c.HelpfulActionMinPlayers then return end

    patient = hg.RagdollOwner and hg.RagdollOwner(patient) or patient
    if not IsValid(healer) or not healer:IsPlayer() or not IsValid(patient) or not patient:IsPlayer() or healer == patient then return end

    healer.Karma = math.Clamp((healer.Karma or c.DefaultKarma) + c.BandageKarma, c.MinKarma, GetPlayerKarmaCap(healer))
    healer:SetNetVar("Karma", healer.Karma)
end)

hook.Add("ZB_StartRound","NO_HARM",function()
    zb.GuiltRoundId = (zb.GuiltRoundId or 0) + 1
    local c = cfg()

    for i,ply in player.Iterator() do
        if (ply.Guilt or 0) < c.CleanRoundGuiltThreshold then
            ply.KarmaGain = math.Clamp((ply.KarmaGain or c.KarmaRegenDefault) + c.KarmaRegenCleanBonus, c.KarmaRegenMin, c.KarmaRegenMax)
        else
            ply.KarmaGain = c.KarmaRegenDefault
        end

        ResetRoundRefundState(ply)
        ply.GuiltAggressionScore = 0

        --ply:guilt_SetValue( ply.Karma or 100 )
    end
    
    zb.HarmDone = {}
    zb.HarmDoneKarma = {}
    zb.GuiltTable = {}
    zb.GuiltCombatHistory = {}
    zb.GuiltThreatStates = {}
end)

util.AddNetworkString("get_karma")
net.Receive("get_karma",function(len, ply)
    if not ply:IsAdmin() then return end

    local tbl = {}

    for i,pl in player.Iterator() do
        tbl[pl:UserID()] = pl.Karma
    end

    net.Start("get_karma")
    net.WriteTable(tbl)
    net.Send(ply)
end)

concommand.Add("hg_setkarma",function(ply,cmd,args)
    if not ply:IsAdmin() then return end
    
    local lenargs = #args
    local newply = player.GetListByName(lenargs > 1 and args[1] or ply:Name())[1]
    if not IsValid(newply) then return end

    local requestedKarma = tonumber(lenargs > 1 and args[2] or args[1])
    if not requestedKarma then return end

    zb.SetPlayerKarma(newply, requestedKarma, true)
end)

hook.Add("PlayerInitialSpawn", "GuiltRefundInit", function(ply)
    ResetRoundRefundState(ply)
end)

hook.Add("PlayerDeath", "GuiltTrackWrongKillLoss", function(victim)
    timer.Simple(0, function()
        if not IsValid(victim) then return end
        if not zb.IsRoundGuiltActive() then return end

        local rnd = CurrentRound()
        if not IsHomicideRound(rnd) then return end

        local attacker = GetBiggestAttacker(victim)
        if not IsRefundableWrongKill(attacker, victim, rnd) then return end

        local harm = zb.HarmDoneKarma[victim] and zb.HarmDoneKarma[victim][attacker] or 0
        if harm <= 0 then return end

        attacker.GuiltWrongKillLossThisRound = (attacker.GuiltWrongKillLossThisRound or 0) + harm
    end)
end)

hook.Add("PlayerDeath", "GuiltRefundOnSuicide", function(ply)
    local suicideDamageAt = ply.GuiltSuicideDamageAt or 0
    ply.GuiltSuicideDamageAt = 0

    timer.Simple(0, function()
        if not IsValid(ply) then return end
        if not zb.IsRoundGuiltActive() then return end

        local rnd = CurrentRound()
        if not IsHomicideRound(rnd) then return end
        if ply.GuiltSuicideRefundUsed then return end
        local c = cfg()
        if suicideDamageAt <= 0 or suicideDamageAt + c.SuicideRefundWindow < CurTime() then return end

        local lostKarma = ply.GuiltWrongKillLossThisRound or 0
        if lostKarma <= 0 then return end

        local refund = lostKarma * c.SuicideRefundRate
        if refund <= 0 then return end

        ply.GuiltSuicideRefundUsed = true
        ply.Karma = math.Clamp((ply.Karma or c.DefaultKarma) + refund, 0, GetPlayerKarmaCap(ply))
        ply:SetNetVar("Karma", ply.Karma)
        ply.GuiltPendingRefundAmount = refund
        ply.GuiltPendingRefundRound = (zb.GuiltRoundId or 0) + 1

        ply:ChatPrint("You regained " .. math.Round(refund, 2) .. " karma from your round penalties.")
    end)
end)

hook.Add("Player Spawn", "GuiltKnown",function(ply)
    if zb.ROUND_STATE ~= 1 then return end
    if ply.Karma then
        local roundStamp = zb.ROUND_BEGIN or zb.ROUND_START or 0
        if ply.GuiltKnownRoundStamp == roundStamp then return end

        ply.GuiltKnownRoundStamp = roundStamp
        ply:ChatPrint("Your current karma is "..tostring(math.Round(ply.Karma)).."")
    end
end)

hook.Add("Player Spawn", "GuiltRefundReminder", function(ply)
    if (ply.GuiltPendingRefundRound or 0) ~= (zb.GuiltRoundId or 0) then return end

    local refund = ply.GuiltPendingRefundAmount or 0
    if refund <= 0 then
        ply.GuiltPendingRefundRound = nil
        ply.GuiltPendingRefundAmount = nil
        return
    end

    ply:ChatPrint("You regained " .. math.Round(refund, 2) .. " karma because " .. math.Round(cfg().SuicideRefundRate * 100) .. "% of the karma you lost last round for killing innocents was refunded after your suicide.")
    ply.GuiltPendingRefundRound = nil
    ply.GuiltPendingRefundAmount = nil
end)

hook.Add("ZC_SomeoneGetFallBy","IdiotsMustBeKilled",function(Attacker,Victim)
    local rnd = CurrentRound()
    
    if not rnd or rnd.GuiltDisabled or GetConVar("zb_dev"):GetBool() then return end
    if not zb.IsRoundGuiltActive() then return end
   
    if Attacker == Victim then return end

    if ShouldSkipHmcdGuiltPenalty(Attacker, Victim, rnd) then return end
    if rnd.name != "hmcd" and (Attacker.Team and Victim.Team and Attacker:Team() ~= Victim:Team()) then return end

    local guiltVictim = ResolveGuiltPlayer(Victim) or (Victim:IsPlayer() and Victim or nil)
    local engagement = zb.EvaluateEngagement(Attacker, guiltVictim or Victim)

    Attacker.Guilt = (Attacker.Guilt or 0) + cfg().FallPushGuilt * engagement.guiltMultiplier
end)
