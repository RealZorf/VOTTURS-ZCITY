zb = zb or {}
zb.GuiltTable = zb.GuiltTable or {}
zb.HarmDone = zb.HarmDone or {}
zb.HarmDoneKarma = zb.HarmDoneKarma or {}
zb.HarmDoneDetailed = zb.HarmDoneDetailed or {}
zb.HarmAttacked = zb.HarmAttacked or {}

local Guilt = zb.GuiltSQL

local hg_developer = ConVarExists("hg_developer") and GetConVar("hg_developer") or CreateConVar(
	"hg_developer",
	0,
	FCVAR_SERVER_CAN_EXECUTE,
	"Toggle developer mode (enables damage traces)",
	0,
	1
)

local function applyKarmaNet(ply, karma)
	if not IsValid(ply) then return end

	ply.Karma = karma

	if ply.SetNetVar then
		ply:SetNetVar("Karma", karma)
	elseif ply.SetLocalVar then
		ply:SetLocalVar("Karma", karma)
	end

	if ply.SetNWFloat then
		ply:SetNWFloat("Karma", karma)
	end
end

local function IsLookingAt(ply, targetVec)
	if not IsValid(ply) or not ply:IsPlayer() then return false end

	local diff = targetVec - ply:GetShootPos()
	return ply:GetAimVector():Dot(diff) / diff:Length() >= 0.8
end

function zb.IsForce(Attacker)
	return Attacker.PlayerClassName == "police"
		or Attacker.PlayerClassName == "nationalguard"
		or Attacker.PlayerClassName == "swat"
end

hook.Add("HomigradDamage", "GuiltReg", function(ply, dmgInfo, hitgroup, ent, harm)
	local Attacker, Victim = dmgInfo:GetAttacker(), ply

	if not IsValid(Attacker) or not Attacker:IsPlayer() then return end
	if not IsValid(Victim) or not (Victim:IsPlayer() or (Victim.organism and Victim.organism.fakePlayer and Victim.organism.alive)) then return end
	if Victim:IsNPC() or Victim:IsNextBot() then return end

	local id = Victim:IsPlayer() and Victim:SteamID() or Victim:EntIndex()
	local id2 = Attacker:IsPlayer() and Attacker:SteamID() or Attacker:EntIndex()
	local maxharm = zb.MaximumHarm or 10

	zb.HarmDone[Victim] = zb.HarmDone[Victim] or {}
	zb.HarmDoneDetailed[id] = zb.HarmDoneDetailed[id] or {}
	zb.HarmDoneKarma[Victim] = zb.HarmDoneKarma[Victim] or {}
	zb.HarmDoneKarma[Victim][Attacker] = zb.HarmDoneKarma[Victim][Attacker] or 0

	local oldharmdone = zb.HarmDone[Victim][Attacker] or 0
	zb.HarmDone[Victim][Attacker] = math.Clamp((zb.HarmDone[Victim][Attacker] or 0) + harm, 0, maxharm)

	zb.HarmAttacked[Attacker] = zb.HarmAttacked[Attacker] or 0
	zb.HarmAttacked[Attacker] = zb.HarmAttacked[Attacker] + harm

	local newharm = math.min(harm + oldharmdone, maxharm)
	harm = newharm - oldharmdone
	local amt = harm / maxharm

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
		Attacker:ChatPrint("This harm done is: " .. math.Round(harm, 3))
		Attacker:ChatPrint("Overall amt done is: " .. math.Round(amt, 3))
		Attacker:ChatPrint("Overall harm done is: " .. math.Round(newharm, 3))
		Attacker:ChatPrint("Guilt done is: " .. math.Round(amt * 60, 3))
		Attacker:ChatPrint(" ")
	end

	hook.Run("HarmDone", Attacker, Victim, amt)

	Victim = hg.GetCurrentCharacter(Victim) or Victim
	Victim = hg.RagdollOwner(Victim) or Victim

	local rnd = CurrentRound and CurrentRound()

	local zbDev = GetConVar("zb_dev")
	if not rnd or rnd.GuiltDisabled or (zbDev and zbDev:GetBool()) then return end
	if Attacker == Victim then return end

	zb.GuiltTable[Attacker] = zb.GuiltTable[Attacker] or {}
	zb.GuiltTable[Victim] = zb.GuiltTable[Victim] or {}

	Attacker.LastAttacked = CurTime()

	if Victim.isTraitor and not Attacker.isTraitor and rnd.name == "hmcd" and not zb.IsForce(Attacker) then return end
	if Attacker.isTraitor and not Victim.isTraitor and rnd.name == "hmcd" then return end

	if rnd.name ~= "hmcd" and Attacker.Team and Victim.Team and attackerTeam ~= Victim:Team() then return end
	if zb.ROUND_STATE ~= 1 and (rnd.name ~= "cstrike" or not zb.RoundsLeft) then return end
	if Victim.Guilt and Victim.Guilt > 1 and not zb.IsForce(Attacker) then return end
	if Attacker.IsBerserk and Attacker:IsBerserk() then return end

	local victimWep = Victim:IsPlayer() and IsValid(Victim:GetActiveWeapon()) and Victim:GetActiveWeapon()

	amt = amt
		* 1
		* (Victim:IsPlayer() and math.Clamp(((Victim.Karma or 100) / 100), 1, 1.2) or 1)
		* (
			Victim:IsPlayer()
				and (
					(
						IsLookingAt(Victim, Attacker:EyePos())
						and (
							victimWep
							and (
								ishgweapon(victimWep)
								or (
									(
										victimWep:GetClass() == "weapon_hands_sh"
										and victimWep.GetFists
										and victimWep:GetFists()
									)
									or victimWep.ismelee2
								)
								and Victim:EyePos():DistToSqr(Attacker:EyePos()) <= (90 * 90)
							)
						)
					)
					and 0.5
					or 1
				)
			or 1
		)

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
	Attacker.Karma = math.Clamp(
		(Attacker.Karma or 100) - add * math.max(((1 - (zb.GuiltTable[Victim][Attacker] or 0)) / 1), 0),
		-60,
		zb.MaxKarma or 120
	)

	zb.HarmDoneKarma[Victim][Attacker] = zb.HarmDoneKarma[Victim][Attacker] + add

	if shouldBanGuilt and Attacker.Guilt >= 100 and ULib then
		ULib.addBan(
			Attacker:SteamID(),
			30,
			"Kicked and banned for dealing too much team damage.",
			Attacker:Name(),
			"System"
		)
		PrintMessage(HUD_PRINTTALK, "Player " .. Attacker:Name() .. " has been banned for 30 minutes for RDMing in a team based gamemode.")
	end

	applyKarmaNet(Attacker, Attacker.Karma)

	zb.GuiltTable[Attacker][Victim] = math.Clamp((zb.GuiltTable[Attacker][Victim] or 0) + guiltadd, 0, 200)

	if Attacker.Karma <= 0 then
		local steamID = Attacker:SteamID()
		local name = Attacker:Name()
		local karma = Attacker.Karma

		if Guilt and Guilt.SetPlayerKarma then
			Guilt.SetPlayerKarma(Attacker, 10, {immediate = true, skipSave = false})
		else
			Attacker:guilt_SetValue(10)
		end

		timer.Create("simplewaitforkarmadrop" .. Attacker:EntIndex(), 0, 1, function()
			if IsValid(Attacker) then
				karma = Attacker.Karma
			end

			local time = math.Round(60 - karma * 4, 0)

			if ULib then
				ULib.addBan(steamID, 60, "Kicked and banned for having too low karma.", name, "System")
			end

			PrintMessage(HUD_PRINTTALK, "Player " .. name .. " has been banned for " .. time .. " minutes for having too low karma.")
		end)
	end
end)

hook.Add("PlayerDisconnected", "GuiltSaveOnDisconect", function(ply)
	if not Guilt or not Guilt.PersistFromPlayer then return end

	Guilt.PersistFromPlayer(ply, true)
end)

hook.Add("Player Spawn", "SlowlyRestoreKarma", function(ply)
	if OverrideSpawn then return end

	ply.lastwarning = nil
	ply.Karma = ply.Karma or 100
	applyKarmaNet(ply, ply.Karma)
	ply.Guilt = 0
end)

hook.Add("Player Think", "karmagain", function(ply)
	if (ply.KarmaGainThink or 0) > CurTime() then return end

	ply.KarmaGainThink = CurTime() + 120
	ply.Karma = math.Clamp(
		ply.Karma + (ply.Karma > 100 and 0.1 or (ply.KarmaGain or 0.75)),
		0,
		zb.MaxKarma or 120
	)

	applyKarmaNet(ply, ply.Karma)
end)

hook.Add("Org Clear", "removekarmashaking", function(org)
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

hook.Add("Org Think", "Its_Karma_Bro", function(owner, org, timeValue)
	if not owner or not owner:IsPlayer() or org.otrub or not org.isPly then return end
	if not owner:IsPlayer() or not owner:Alive() then return end

	local ply = owner

	if (ply.Karma or 100) < 50 then
		if math.random(math.Clamp((ply.Karma or 100), 20, zb.MaxKarma or 120) * 300) == 1 or org.start_shaking then
			hg.StunPlayer(ply)
			local time = 15

			ply:Notify(seizuremsgs[math.random(#seizuremsgs)], 16, "seizure", 1, function()
				if not IsValid(ply) then return end
				ply:ChatPrint("You are experiencing an epileptic seizure.")
			end)

			org.start_shaking = org.start_shaking or (CurTime() + time)
			local ent = hg.GetCurrentCharacter(owner)
			local mul = ((org.start_shaking) - CurTime()) / time

			if mul > 0 then
				ent:GetPhysicsObjectNum(math.random(ent:GetPhysicsObjectCount()) - 1):ApplyForceCenter(VectorRand(-750 * mul, 750 * mul))
			else
				org.start_shaking = nil
			end
		else
			org.start_shaking = nil
		end
	end

	if (ply.Karma or 100) < 35 and math.random(2000) == 1 then
		hg.organism.Vomit(owner)
	end
end)

hook.Add("ZB_EndRound", "savevalues", function()
	for _, ply in player.Iterator() do
		if Guilt and Guilt.PersistFromPlayer then
			Guilt.PersistFromPlayer(ply, true)
		elseif ply.guilt_SetValue then
			ply:guilt_SetValue(ply.Karma or 100)
		end
	end
end)

hook.Add("ZB_StartRound", "NO_HARM", function()
	for _, ply in player.Iterator() do
		if (ply.Guilt or 0) < 1 then
			ply.KarmaGain = math.Clamp((ply.KarmaGain or 0.75) + 0.25, 0.75, 1.5)
		else
			ply.KarmaGain = 0.75
		end
	end

	zb.HarmDone = {}
	zb.HarmDoneKarma = {}
end)

util.AddNetworkString("get_karma")
net.Receive("get_karma", function(_, ply)
	if not ply:IsAdmin() then return end

	local tbl = {}

	for _, pl in player.Iterator() do
		tbl[pl:UserID()] = pl.Karma
	end

	net.Start("get_karma")
	net.WriteTable(tbl)
	net.Send(ply)
end)

concommand.Add("hg_setkarma", function(ply, _, args)
	if IsValid(ply) and not ply:IsAdmin() then return end

	local lenargs = #args
	local targetName = lenargs > 1 and args[1] or (IsValid(ply) and ply:Name() or "")
	local newply = player.GetListByName(targetName)[1]

	if not IsValid(newply) then
		for _, p in player.Iterator() do
			if string.find(string.lower(p:Nick()), string.lower(targetName), 1, true) then
				newply = p
				break
			end
		end
	end

	if not IsValid(newply) then
		if IsValid(ply) then
			ply:ChatPrint("[Karma] Player not found: " .. tostring(targetName))
		else
			print("[Karma] Player not found: " .. tostring(targetName))
		end
		return
	end

	local amount = tonumber(lenargs > 1 and args[2] or args[1]) or 100

	if not Guilt or not Guilt.AdminAdjustKarma then
		if IsValid(ply) then
			ply:ChatPrint("[Karma] Guilt module not loaded.")
		end
		return
	end

	local ok, err = Guilt.AdminAdjustKarma(ply, newply, "set", amount)
	if not ok and IsValid(ply) then
		ply:ChatPrint("[Karma] Save failed: " .. tostring(err or "unknown"))
	end
end)

util.AddNetworkString("open_guilt_menu")
util.AddNetworkString("forgive_player")

net.Receive("open_guilt_menu", function(_, ply)
	if ply:Alive() then return end

	local tbl = zb.HarmDoneKarma[ply] or {}

	net.Start("open_guilt_menu")
	net.WriteTable(tbl)
	net.Send(ply)
end)

net.Receive("forgive_player", function(_, ply)
	local ent = net.ReadEntity()
	if not IsValid(ent) or not zb.HarmDoneKarma[ply] then return end

	local harm = zb.HarmDoneKarma[ply][ent]
	if not harm then return end

	ent.Karma = math.Clamp(ent.Karma + harm, 0, zb.MaxKarma or 120)
	applyKarmaNet(ent, ent.Karma)

	zb.HarmDone[ply][ent] = 0
	zb.HarmDoneKarma[ply][ent] = 0

	net.Start("open_guilt_menu")
	net.WriteTable(zb.HarmDoneKarma[ply])
	net.Send(ply)
end)

hook.Add("Player Spawn", "GuiltKnown", function(ply)
	if ply.Karma then
		ply:ChatPrint("Your current karma is " .. tostring(math.Round(ply.Karma)))
	end
end)

hook.Add("ZC_SomeoneGetFallBy", "IdiotsMustBeKilled", function(Attacker, Victim)
	local rnd = CurrentRound()

	local zbDev = GetConVar("zb_dev")
	if not rnd or rnd.GuiltDisabled or (zbDev and zbDev:GetBool()) then return end
	if Attacker == Victim then return end

	if Victim.isTraitor and not Attacker.isTraitor and rnd.name == "hmcd" and not zb.IsForce(Attacker) then return end
	if Attacker.isTraitor and not Victim.isTraitor and rnd.name == "hmcd" then return end
	if rnd.name ~= "hmcd" and Attacker.Team and Victim.Team and Attacker:Team() ~= Victim:Team() then return end
	if zb.ROUND_STATE ~= 1 and (rnd.name ~= "cstrike" or not zb.RoundsLeft) then return end
	if Victim.Guilt and Victim.Guilt > 1 then return end

	Attacker.Guilt = Attacker.Guilt or 0
	Attacker.Guilt = Attacker.Guilt < 4 and 5 or Attacker.Guilt
end)
