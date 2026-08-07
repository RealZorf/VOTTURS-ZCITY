local MODE = MODE

MODE.name = "zombiesurvival"
MODE.PrintName = "Zombie Survival"

MODE.start_time = 5
MODE.end_time = 7
MODE.ROUND_TIME = 600
MODE.InfectionDelay = 59
MODE.FastZombieRespawnDelay = 5
MODE.ZombieRespawnDelay = 15
MODE.PoisonZombieInterval = 150
MODE.ZombieConsumeTime = 4
MODE.ZombieConsumeReach = 100
MODE.ZombieConsumeHealthRestore = 45

MODE.randomSpawns = true
MODE.shouldfreeze = true
MODE.OverrideSpawn = true
MODE.LootSpawn = true
MODE.LootOnTime = false
MODE.Chance = 0.12

function MODE:CanLaunch()
	return player.GetCount() >= 2
end

function MODE:IsZombieConsumableVictim(victim, corpse)
	if not IsValid(victim) or not victim:IsPlayer() then return false end
	if IsValid(corpse) and corpse:GetNWBool("ZS_Consumed", false) then return false end
	if not victim:Alive() then return true end

	local fakeRagdoll = IsValid(victim.FakeRagdoll) and victim.FakeRagdoll or victim:GetNWEntity("FakeRagdoll", NULL)
	if not IsValid(fakeRagdoll) or (IsValid(corpse) and corpse ~= fakeRagdoll) then return false end

	local org = victim.organism
	if SERVER then
		return org and org.otrub == true
	end

	return not org or org.otrub == true
end

function MODE:GetZombieConsumeTarget(ply)
	if not IsValid(ply) then return nil end

	local trace = hg and hg.eyeTrace and hg.eyeTrace(ply, self.ZombieConsumeReach or 100)
	if not trace or not IsValid(trace.Entity) then return nil end

	local corpse = trace.Entity
	local victim
	if corpse:IsPlayer() then
		victim = corpse
		corpse = IsValid(victim.FakeRagdoll) and victim.FakeRagdoll or victim:GetNWEntity("FakeRagdoll", NULL)
	elseif corpse:IsRagdoll() then
		victim = (hg and hg.RagdollOwner and hg.RagdollOwner(corpse)) or corpse.ply
	else
		return nil
	end

	if not IsValid(corpse) or not corpse:IsRagdoll() then return nil end
	if not IsValid(victim) or victim == ply then return nil end
	if not self:IsZombieConsumableVictim(victim, corpse) then return nil end

	return corpse, victim, trace
end

function MODE:GetZombieConsumeProgress(ply)
	if not IsValid(ply) then return 0 end

	local startedAt = ply:GetNWFloat("ZS_ConsumeStartedAt", 0)
	local readyAt = ply:GetNWFloat("ZS_ConsumeReadyAt", 0)
	if readyAt <= startedAt or readyAt <= 0 then return 0 end

	return math.Clamp((CurTime() - startedAt) / (readyAt - startedAt), 0, 1)
end
