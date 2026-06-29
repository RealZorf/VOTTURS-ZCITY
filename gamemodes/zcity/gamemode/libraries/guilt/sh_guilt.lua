zb = zb or {}
zb.MaximumHarm = 10
zb.MaxKarma = 120
zb.GuiltTraitorSteamIDs = zb.GuiltTraitorSteamIDs or {}

function zb.IsHomicideRound(rnd)
	if not rnd and CurrentRound then
		rnd = CurrentRound()
	end

	if not rnd then return false end
	if rnd.name == "hmcd" or rnd.name == "fear" or rnd.base == "hmcd" then return true end

	if istable(rnd.Types) and (rnd.Types.standard or rnd.Types.wildwest or rnd.Types.soe or rnd.Types.gunfreezone) then
		return true
	end

	return false
end

function zb.IsTraitorPlayer(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if ply.isTraitor == true or ply.MainTraitor == true then return true end

	local steamID64 = ply:SteamID64()
	if steamID64 and steamID64 ~= "0" and zb.GuiltTraitorSteamIDs[steamID64] then
		return true
	end

	return false
end

function zb.IsForce(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end

	local className = ply.PlayerClassName
	return className == "police" or className == "nationalguard" or className == "swat"
end

function zb.ShouldSkipHomicideRoleGuilt(attacker, victim, rnd)
	if not zb.IsHomicideRound(rnd) then return false end
	if not IsValid(attacker) or not IsValid(victim) then return false end
	if not attacker:IsPlayer() or not victim:IsPlayer() then return false end

	local attackerTraitor = zb.IsTraitorPlayer(attacker)
	local victimTraitor = zb.IsTraitorPlayer(victim)

	if attackerTraitor and not victimTraitor then return true end
	if victimTraitor and not attackerTraitor and not zb.IsForce(attacker) then return true end

	return false
end
