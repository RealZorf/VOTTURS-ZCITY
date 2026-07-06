-- СДЕЛАЙТЕ СИНХРУ С СКУЭЛЬ УЖЕ // ЛАДНО Я САМ СДЕЛАЮ
zb = zb or {}

zb.GuiltTable = zb.GuiltTable or {}
zb.HarmDone = zb.HarmDone or {}
zb.HarmDoneKarma = zb.HarmDoneKarma or {}
zb.HarmDoneDetailed = zb.HarmDoneDetailed or {}
zb.HarmAttacked = zb.HarmAttacked or {}
zb.GuiltSQL = zb.GuiltSQL or {}
zb.GuiltSQL.PlayerInstances = zb.GuiltSQL.PlayerInstances or {}

local hg_developer = ConVarExists("hg_developer") and GetConVar("hg_developer") or CreateConVar("hg_developer",0,FCVAR_SERVER_CAN_EXECUTE,"Toggle developer mode (enables damage traces)",0,1)
local KARMA_SUICIDE_REFUND_RATE = 0.1
local KARMA_SUICIDE_REFUND_WINDOW = 30
local PLAYER_KARMA_CAPS = {
    superadmin = 99999,
    owner = 99999,
    servermanager = 99999,
    headdeveloper = 99999,
    headadmin = 1000,
    developer = 99999,
    admin = 500,
    moderator = 250,
    supporter = 250,
    booster = 150
}

zb.GuiltRoundId = zb.GuiltRoundId or 0

local function IsHomicideRound(rnd)
    return rnd and (rnd.name == "hmcd" or rnd.name == "fear" or rnd.base == "hmcd")
end

local function GetPlayerKarmaCap(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return zb.MaxKarma end

    local userGroup = string.lower((ply.GetUserGroup and ply:GetUserGroup()) or "")
    if PLAYER_KARMA_CAPS[userGroup] then
        return PLAYER_KARMA_CAPS[userGroup]
    end

    return zb.MaxKarma
end

local IMMUNE_GROUPS = {
    "superadmin",
    "owner",
    "servermanager",
    "headdeveloper",
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

    return not attacker.isTraitor and not victim.isTraitor
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
			if (IsValid(ply) and istable(result) and #result > 0 and result[1].value) then
				local updateQuery = mysql:Update("zb_guilt")
					updateQuery:Update("steam_name", name)
					updateQuery:Where("steamid", steamID64)
				updateQuery:Execute()

				zb.GuiltSQL.PlayerInstances[steamID64] = {}

                zb.GuiltSQL.PlayerInstances[steamID64].value = tonumber(result[1].value)

                ply.Karma = ply:guilt_GetValue()
                ply:SetNetVar("Karma", ply.Karma)

                if zb.GuiltSQL.PlayerInstances[steamID64].value < 0 then
                    ply:guilt_SetValue(10)

                    ply.Karma = 10
                    ply:SetNetVar("Karma", ply.Karma)

                    timer.Simple(0, function()
                        if not IsValid(ply) then return end

                        if IsBanImmune(ply) then return end

                        ply:Ban(5, false)
                        ply:Kick("Your karma is too low: " .. math.Round(ply.Karma, 0) .. ". Try again in 5 minutes.")
                    end)
                end
			else
				local insertQuery = mysql:Insert("zb_guilt")
					insertQuery:Insert("steamid", steamID64)
					insertQuery:Insert("steam_name", name)
					insertQuery:Insert("value", 100)
				insertQuery:Execute()

				zb.GuiltSQL.PlayerInstances[steamID64] = {}

				zb.GuiltSQL.PlayerInstances[steamID64].value = 100

                ply.Karma = ply:guilt_GetValue()
                ply:SetNetVar("Karma",ply.Karma)
			end
		end)
	query:Execute()

end)

local plyMeta = FindMetaTable("Player")

function plyMeta:guilt_GetValue()

    return zb.GuiltSQL.PlayerInstances[self:SteamID64()] and zb.GuiltSQL.PlayerInstances[self:SteamID64()].value or 100

end

function plyMeta:guilt_SetValue( zb_guilt )

    local steamID64 = self:SteamID64()
	
	zb.GuiltSQL.PlayerInstances[self:SteamID64()] = zb.GuiltSQL.PlayerInstances[self:SteamID64()] or {}
	zb.GuiltSQL.PlayerInstances[self:SteamID64()].value = zb.GuiltSQL.PlayerInstances[self:SteamID64()].value or 100
	
    zb.GuiltSQL.PlayerInstances[self:SteamID64()].value = zb_guilt

	local updateQuery = mysql:Update("zb_guilt")
		updateQuery:Update("value", zb_guilt)
		updateQuery:Where("steamid", steamID64)
	updateQuery:Execute()
end

local function IsLookingAt(ply, targetVec)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local diff = targetVec - ply:GetShootPos()
    return ply:GetAimVector():Dot(diff) / diff:Length() >= 0.8
end

hook.Add("HomigradDamage", "GuiltReg", function(ply, dmgInfo, hitgroup, ent, harm) 
    local Attacker, Victim = dmgInfo:GetAttacker(), ply
    local rnd = CurrentRound()

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

    local newharm = math.min(harm + oldharmdone, maxharm)
    local harm = newharm - oldharmdone
    local amt = harm / maxharm
    
    if amt > 0.2 or newharm / maxharm > 0.8 then
        --print("Player "..Attacker:Name().." harmed player "..(Victim:IsPlayer() and Victim:Name() or (tostring(Victim))).." with "..harm.." points.")
        --print("They contributed a total of "..math.Round(newharm / maxharm * 100, 0).."% of "..(Victim:IsPlayer() and Victim:Name() or (tostring(Victim))).."'s death")
    end

    if zb and zb.hostage and Victim == zb.hostage then
        zb.hostageLastTouched = Attacker
    end

    local attackerTeam = dmgInfo:GetInflictor().team or (Attacker:IsPlayer() and Attacker:Team()) or Attacker.team
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
        Attacker:ChatPrint("Guilt done is: "..math.Round(amt * 60,3))
        Attacker:ChatPrint(" ")
    end

    hook.Run("HarmDone", Attacker, Victim, amt)

    if newharm >= maxharm and oldharmdone < newharm then
        //Attacker:AddFrags(1) -- better make it a system that counts kills and gives frags at the end of the round
    end

    if rnd.GuiltDisabled or GetConVar("zb_dev"):GetBool() then return end

    if Attacker == Victim then return end

    zb.GuiltTable[Attacker] = zb.GuiltTable[Attacker] or {}
    zb.GuiltTable[Victim] = zb.GuiltTable[Victim] or {}
    
    Attacker.LastAttacked = CurTime()

    if Victim.isTraitor and !Attacker.isTraitor and IsHomicideRound(rnd) and !zb.IsForce(Attacker) then return end
    if Attacker.isTraitor and !Victim.isTraitor and IsHomicideRound(rnd) then return end
    
    if rnd.name != "hmcd" and (Attacker.Team and Victim.Team and attackerTeam ~= Victim:Team()) then return end
    if zb.ROUND_STATE != 1 and (rnd.name != "cstrike" or !zb.RoundsLeft) then return end
    if Victim.Guilt and Victim.Guilt > 1 and !zb.IsForce(Attacker) then return end
    if Attacker:IsBerserk() then return end

    local victimWep = Victim:IsPlayer() and IsValid(Victim:GetActiveWeapon()) and Victim:GetActiveWeapon()
    
    if newharm >= maxharm and oldharmdone < newharm then
        //Attacker:AddFrags(-1)
    end
    
    amt = amt * 1
        * (Victim:IsPlayer() and math.Clamp(((Victim.Karma or 100) / 100), 1, 1.2) or 1)
        * (Victim:IsPlayer() and ((IsLookingAt(Victim, Attacker:EyePos()) and (victimWep and (ishgweapon(victimWep) or ((victimWep:GetClass() == "weapon_hands_sh" and victimWep:GetFists() or victimWep.ismelee2) and Victim:EyePos():DistToSqr(Attacker:EyePos()) <= (90 * 90))))) and 0.5 or 1) or 1)

    local add = amt * maxharm

    add = add * (Victim:IsPlayer() and Attacker:PlayerClassEvent("Guilt", Victim) or 1)
    add = add * 2

    local mul, shouldBanGuilt
    
    if rnd.GuiltCheck then
        mul, shouldBanGuilt = rnd.GuiltCheck(Attacker, Victim, add, harm, amt)

        add = add * (mul or 1)
    end
    
    local guiltadd = amt * 60
    Attacker.Guilt = (Attacker.Guilt or 0) + guiltadd
    Attacker.Karma = math.Clamp((Attacker.Karma or 100) - add * math.max(((1 - (zb.GuiltTable[Victim][Attacker] or 0)) / 1),0), -60, GetPlayerKarmaCap(Attacker))

    zb.HarmDoneKarma[Victim][Attacker] = zb.HarmDoneKarma[Victim][Attacker] + add

    if shouldBanGuilt and Attacker.Guilt >= 100 then
        if Attacker.GuiltBanSent then return end 
        Attacker.GuiltBanSent = true

        if not IsBanImmune(Attacker) then
            ULib.addBan(Attacker:SteamID(), 30, "Kicked and banned for dealing too much team damage.", Attacker:Name(), "System")

            PrintMessage(HUD_PRINTTALK,
                "Player " .. Attacker:Name() .. " has been banned for 30 minutes for RDMing in a team based gamemode."
            )
        end
    end

    Attacker:SetNetVar("Karma", Attacker.Karma)
    
    zb.GuiltTable[Attacker][Victim] = math.Clamp((zb.GuiltTable[Attacker][Victim] or 0) + guiltadd, 0, 200)

    if Attacker.Karma <= 0 then
        local steamID = Attacker:SteamID()
        local name = Attacker:Name()
        local karma = Attacker.Karma

        Attacker:guilt_SetValue( 10 )

        -- we wait one tick to make them pay for all the murders they've done
        -- also makes sure the message is displayed only once
        timer.Create("simplewaitforkarmadrop"..Attacker:EntIndex(), 0, 1, function()
            if IsValid(Attacker) then -- if the player haven't left in that exact tick then we do him dirty
                karma = Attacker.Karma
            end

            local time = math.Round(60 - karma * 4, 0)

			if not IsBanImmune(Attacker) then
                ULib.addBan(steamID, 60, "Kicked and banned for having too low karma.", name, "System")

                PrintMessage(HUD_PRINTTALK, "Player " .. name .. " has been banned for " .. time .. " minutes for having too low karma.")
            end
        end)
    end
end)

function zb.IsForce(Attacker)
    return Attacker.PlayerClassName == "police" and Attacker.PlayerClassName == "nationalguard" and Attacker.PlayerClassName == "swat"
end

local function IsLookingAt(ply, targetVec)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    local diff = targetVec - ply:GetShootPos()
    return true--ply:GetAimVector():Dot(diff) / diff:Length() >= 0.6 
end -- i dont think it should matter if he looks at you or not. just drop your weapon

function zb.ForcesAttackedInnocent(self, Victim)
    local victimWep = Victim:IsPlayer() and IsValid(Victim:GetActiveWeapon()) and Victim:GetActiveWeapon()

    return 1 * ((!Victim.LastAttacked or (Victim.LastAttacked + 10 > CurTime())) and 0 or 1) + 1 * (Victim:IsPlayer() and ((IsLookingAt(Victim, self:EyePos()) and (victimWep and (ishgweapon(victimWep) or ((victimWep:GetClass() == "weapon_hands_sh" and victimWep:GetFists() or victimWep.ismelee2) and Victim:GetPos():DistanceSqr(self:GetPos()) <= (72 * 72))))) and 0 or 1) or 1)
end

hook.Add("PlayerDisconnected","GuiltSaveOnDisconect",function(ply)
    ply:guilt_SetValue( ply.Karma or 100 )
end)

hook.Add("Player Spawn","SlowlyRestoreKarma",function(ply)
    if OverrideSpawn then return end

    ply.lastwarning = nil
    //ply.firstwarning = nil
    ply.Karma = ply.Karma or 100
    ply:SetNetVar("Karma",ply.Karma)
    //ply:guilt_SetValue( ply.Karma or 100 )
    
    ply.Guilt = 0
end)

hook.Add("Player Think", "karmagain", function(ply)
    if (ply.KarmaGainThink or 0) > CurTime() then return end
    ply.KarmaGainThink = CurTime() + 120

    ply.Karma = math.Clamp(ply.Karma + (ply.Karma > 100 and 0.1 or (ply.KarmaGain or 0.75)), 0, GetPlayerKarmaCap(ply))// * (1 + ply:HasPurchase("zpremium")), 0, zb.MaxKarma)
    
    ply:SetNetVar("Karma", ply.Karma)
    //ply:guilt_SetValue( ply.Karma or 100 )
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
    
    if (ply.Karma or 100) < 50 then
        if ((math.random(math.Clamp((ply.Karma or 100),20,zb.MaxKarma) * 300) == 1 or org.start_shaking)) then
            hg.StunPlayer(ply)
            local time = 15
            
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

    if (ply.Karma or 100) < 35 then
        if math.random(2000) == 1 then
            hg.organism.Vomit(owner)
        end
    end
end)

hook.Add("ZB_EndRound","savevalues",function()
    for i,ply in player.Iterator() do
        ply:guilt_SetValue( ply.Karma or 100 )
    end
end)

hook.Add("ZB_StartRound","NO_HARM",function()
    zb.GuiltRoundId = (zb.GuiltRoundId or 0) + 1

    for i,ply in player.Iterator() do
        if (ply.Guilt or 0) < 1 then
            ply.KarmaGain = math.Clamp((ply.KarmaGain or 0.75) + 0.25, 0.75, 1.5)
        else
            ply.KarmaGain = 0.75
        end

        ResetRoundRefundState(ply)

        //ply:guilt_SetValue( ply.Karma or 100 )
    end
    
    zb.HarmDone = {}
    zb.HarmDoneKarma = {}
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

    newply.Karma = math.Clamp(requestedKarma, -60, GetPlayerKarmaCap(newply))
    newply:SetNetVar("Karma", newply.Karma)
    newply:guilt_SetValue(newply.Karma)
end)

util.AddNetworkString("open_guilt_menu")
util.AddNetworkString("forgive_player")

hook.Add("PlayerInitialSpawn", "GuiltRefundInit", function(ply)
    ResetRoundRefundState(ply)
end)

hook.Add("PlayerDeath", "GuiltTrackWrongKillLoss", function(victim)
    timer.Simple(0, function()
        if not IsValid(victim) then return end

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

        local rnd = CurrentRound()
        if not IsHomicideRound(rnd) then return end
        if ply.GuiltSuicideRefundUsed then return end
        if suicideDamageAt <= 0 or suicideDamageAt + KARMA_SUICIDE_REFUND_WINDOW < CurTime() then return end

        local lostKarma = ply.GuiltWrongKillLossThisRound or 0
        if lostKarma <= 0 then return end

        local refund = lostKarma * KARMA_SUICIDE_REFUND_RATE
        if refund <= 0 then return end

        ply.GuiltSuicideRefundUsed = true
        ply.Karma = math.Clamp((ply.Karma or 100) + refund, 0, GetPlayerKarmaCap(ply))
        ply:SetNetVar("Karma", ply.Karma)
        ply.GuiltPendingRefundAmount = refund
        ply.GuiltPendingRefundRound = (zb.GuiltRoundId or 0) + 1

        ply:ChatPrint("You regained " .. math.Round(refund, 2) .. " karma from your round penalties.")
    end)
end)

net.Receive("open_guilt_menu",function(len, ply)
    if ply:Alive() then return end
    local tbl = zb.HarmDoneKarma[ply] or {}
    net.Start("open_guilt_menu")
    net.WriteTable(tbl)
    net.Send(ply)
    //current round guilt
end)

net.Receive("forgive_player", function(len, ply)
    local ent = net.ReadEntity()
    if not IsValid(ent) or not zb.HarmDoneKarma[ply] then return end
    local harm = zb.HarmDoneKarma[ply][ent]
    if not harm then return end

    if IsRefundableWrongKill(ent, ply, CurrentRound()) then
        ent.GuiltWrongKillLossThisRound = math.max((ent.GuiltWrongKillLossThisRound or 0) - harm, 0)
    end

    ent.Karma = math.Clamp(ent.Karma + harm, 0, GetPlayerKarmaCap(ent))
    ent:SetNetVar("Karma",ent.Karma)
    ent:guilt_SetValue(ent.Karma)

    zb.HarmDone[ply][ent] = 0
    zb.HarmDoneKarma[ply][ent] = 0
    net.Start("open_guilt_menu")
    net.WriteTable(zb.HarmDoneKarma[ply])
    net.Send(ply)
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

    ply:ChatPrint("You regained " .. math.Round(refund, 2) .. " karma because 10% of the karma you lost last round for killing innocents was refunded after your suicide.")
    ply.GuiltPendingRefundRound = nil
    ply.GuiltPendingRefundAmount = nil
end)

hook.Add("ZC_SomeoneGetFallBy","IdiotsMustBeKilled",function(Attacker,Victim)
    local rnd = CurrentRound()
    
    if rnd.GuiltDisabled or GetConVar("zb_dev"):GetBool() then return end
   
    if Attacker == Victim then return end

    if Victim.isTraitor and !Attacker.isTraitor and IsHomicideRound(rnd) and !zb.IsForce(Attacker) then return end
    if Attacker.isTraitor and !Victim.isTraitor and IsHomicideRound(rnd) then return end
    if rnd.name != "hmcd" and (Attacker.Team and Victim.Team and Attacker:Team() ~= Victim:Team()) then return end
    if zb.ROUND_STATE != 1 and (rnd.name != "cstrike" or !zb.RoundsLeft) then return end
    if Victim.Guilt and Victim.Guilt > 1 then return end

    Attacker.Guilt = Attacker.Guilt or 0
    Attacker.Guilt = Attacker.Guilt < 4 and 5 or Attacker.Guilt 
end)
