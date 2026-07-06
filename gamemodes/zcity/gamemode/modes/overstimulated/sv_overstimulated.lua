local MODE = MODE

MODE.name = "overstimulated"
MODE.PrintName = "Overstimulated"
MODE.ForBigMaps = false
MODE.ROUND_TIME = 900
MODE.LootSpawn = true
MODE.Chance = 0

local START_SCREEN_DELAY = 10
local SHOOTER_COUNTDOWN_DELAY = 60
local SHOOTER_MUSIC_BEFORE_SPAWN = 45
local ROUND_END_DELAY = 8
local LAST_STAND_DELAY = 90

local shooterRoleNames = {
	[1] = "overstimulated",
	[2] = "trigger happy",
	[3] = "irrelevant"
}

local swatWeapons = {
	{"weapon_m4a1", {"holo15","grip3","laser4"}},
	{"weapon_hk416", {"holo15","grip3","laser4"}},
	{"weapon_p90", {}},
	{"weapon_mp7", {"holo14"}},
	{"weapon_m4a1", {"optic2","grip3","supressor7"}}
}

local swatItems = {
	"weapon_medkit_sh",
	"weapon_tourniquet",
	"weapon_walkie_talkie",
	"weapon_melee",
	"weapon_handcuffs",
	"weapon_hg_flashbang_tpik"
}

local swatArmor = {
	"ent_armor_vest8",
	"ent_armor_helmet6"
}

util.AddNetworkString("overstimulated_round_report")
util.AddNetworkString("overstimulated_audio_cue")

function MODE.GuiltCheck(attacker, victim)
	if not IsValid(attacker) or not IsValid(victim) then
		return 1, true
	end

	if attacker == victim then
		return 1, true
	end

	if attacker:Team() == victim:Team() and attacker:Team() ~= TEAM_SPECTATOR then
		return 4, true
	end

	return 1, true
end

local function shuffle(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
end

function MODE:GetShooterCount(playerCount)
	if playerCount >= 15 then
		return 3
	end
	if playerCount >= 10 then
		return 2
	end
	return 1
end

function MODE:GetCopCount(playerCount, shooterCount)
	local cops = 1

	if playerCount >= 16 then
		cops = 4
	elseif playerCount >= 12 then
		cops = 3
	elseif playerCount >= 8 then
		cops = 2
	end

	local remaining = playerCount - shooterCount
	if remaining <= 1 then
		return 0
	end

	return math.Clamp(cops, 1, remaining - 1)
end

function MODE:GetCopArrivalDelay(playerCount)
	if playerCount <= 4 then
		return 480
	elseif playerCount <= 8 then
		return 420
	elseif playerCount <= 12 then
		return 360
	elseif playerCount <= 16 then
		return 300
	end

	return 240
end

function MODE:AssignTeams()
	local players = player.GetAll()
	local playerCount = #players

	if playerCount == 0 then return end

	shuffle(players)

	local shooterCount = self:GetShooterCount(playerCount)
	local copCount = self:GetCopCount(playerCount, shooterCount)

	self.ShooterIndex = {}
	self.PendingCopCount = copCount

	local index = 1
	for i = 1, shooterCount do
		local ply = players[index]
		index = index + 1
		if not IsValid(ply) then continue end

		ply:SetTeam(2)
		self.ShooterIndex[ply] = i
		ply:SetNWString("OverstimulatedRole", shooterRoleNames[i] or shooterRoleNames[1])
	end

	for i = index, playerCount do
		local ply = players[i]
		if not IsValid(ply) then continue end

		ply:SetTeam(1)
		ply:SetNWString("OverstimulatedRole", "")
	end
end

function MODE:Intermission()
	game.CleanUpMap()
	hg.UpdateRoundTime(self.ROUND_TIME)

	self:AssignTeams()

	self.CopsArrived = false
	self.ShootersActivated = false
	self.EndDelayActive = false
	self.EndDelayAt = nil
	self.PendingWinner = nil
	self.LastStandEndAt = 0
	self.ShooterCountdownStartAt = CurTime() + START_SCREEN_DELAY
	self.ShooterSpawnAt = self.ShooterCountdownStartAt + SHOOTER_COUNTDOWN_DELAY
	self.MusicCueAt = self.ShooterSpawnAt - SHOOTER_MUSIC_BEFORE_SPAWN
	self.CopsArrivalDelay = self:GetCopArrivalDelay(#player.GetAll())
	self.CopsArrivalAt = self.ShooterSpawnAt + self.CopsArrivalDelay

	SetGlobalFloat("overstimulated_shooter_countdown_start_at", self.ShooterCountdownStartAt)
	SetGlobalFloat("overstimulated_shooter_spawn_at", self.ShooterSpawnAt)
	SetGlobalFloat("overstimulated_music_cue_at", self.MusicCueAt)
	SetGlobalFloat("overstimulated_cops_arrival_delay", self.CopsArrivalDelay)
	SetGlobalFloat("overstimulated_cops_arrival_at", self.CopsArrivalAt)
	SetGlobalFloat("overstimulated_laststand_end_at", self.LastStandEndAt)

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR or ply:Team() == 2 then
			ply:KillSilent()
			continue
		end

		ply:SetupTeam(ply:Team())
	end

end

function MODE:CheckAlivePlayers()
	local cops = {}
	local victims = {}
	local shooters = {}

	for _, ply in ipairs(team.GetPlayers(0)) do
		if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
			table.insert(cops, ply)
		end
	end

	for _, ply in ipairs(team.GetPlayers(1)) do
		if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
			table.insert(victims, ply)
		end
	end

	for _, ply in ipairs(team.GetPlayers(2)) do
		if ply:Alive() and not ply:GetNetVar("handcuffed", false) then
			table.insert(shooters, ply)
		end
	end

	return {cops, victims, shooters}
end

function MODE:BuildRoundReport(winner)
	local deceased = {}
	local survivors = {}

	for _, ply in player.Iterator() do
		if not IsValid(ply) or ply:Team() == TEAM_SPECTATOR then continue end

		if ply:Alive() then
			table.insert(survivors, ply:Name())
		else
			table.insert(deceased, ply:Name())
		end
	end

	local winnerText = "No one"
	if winner == 0 then
		winnerText = "SWAT"
	elseif winner == 1 then
		winnerText = "Victims"
	elseif winner == 2 then
		winnerText = "Overstimulated"
	end

	return {
		title = "Incident Report",
		winner = "Outcome: " .. winnerText,
		deceased = deceased,
		survivors = survivors
	}
end

function MODE:ShouldRoundEnd()
	if not self.ShootersActivated then
		return false
	end

	if self.EndDelayActive then
		return CurTime() >= (self.EndDelayAt or 0)
	end

	local aliveTeams = self:CheckAlivePlayers()
	local endRound, winner = false, nil

	if table.Count(aliveTeams[3]) == 0 then
		endRound = true
		winner = self.CopsArrived and 0 or 1
	else
		endRound, winner = zb:CheckWinner(aliveTeams)
	end

	if endRound then
		self.EndDelayActive = true
		self.EndDelayAt = CurTime() + ROUND_END_DELAY
		self.PendingWinner = winner

		net.Start("overstimulated_round_report")
			net.WriteTable(self:BuildRoundReport(winner))
		net.Broadcast()

		return false
	end

	return false
end

function MODE:RoundStart()
end

MODE.LootTable = {
	{100, {
		{10,"weapon_ducttape"},
		{10,"weapon_matches"},
		{10,"weapon_zippo_tpik"},
		{10,"weapon_bigconsumable"},
		{10,"weapon_smallconsumable"},
		{8,"weapon_painkillers"},
		{8,"weapon_bandage_sh"},
		{5,"weapon_medkit_sh"},
		{5,"weapon_pocketknife"},
		{5,"weapon_bat"},
		{5,"weapon_leadpipe"},
		{5,"weapon_hammer"},
		{5,"weapon_hg_bottle"},
	}}
}

function MODE:CanLaunch()
	return true
end

function MODE:GiveVictimLoadout(ply)
	if not IsValid(ply) then return end
	if not ply:Alive() then return end

	ply:SetSuppressPickupNotices(true)
	ply.noSound = true

	ply:SetPlayerClass("default")
	zb.GiveRole(ply, "victim", Color(255,255,255))

	ply:StripWeapons()
	ply:Give("weapon_hands_sh")
	ply:SelectWeapon("weapon_hands_sh")

	ply:SetSuppressPickupNotices(false)
	ply.noSound = false
end

local function GiveWeaponWithReserve(ply, class, reserveMags)
	local wep = ply:Give(class)
	if not IsValid(wep) or not wep.GetMaxClip1 or not wep.GetPrimaryAmmoType then
		return nil
	end

	local maxClip = wep:GetMaxClip1()
	local ammoType = wep:GetPrimaryAmmoType()
	if maxClip and maxClip > 0 and ammoType and ammoType >= 0 then
		ply:GiveAmmo(maxClip * (reserveMags or 3), ammoType, true)
	end

	return wep
end

local function SetMaskMaterial(ply, materialPath)
	if not IsValid(ply) or not materialPath then return end
	ply:SetNWString("ArmorMaterialsmask1", materialPath)
end

function MODE:GetShooterSpawnData(shooterIndex)
	local points = zb.GetMapPoints("HMCD_OVERSTIM_SHOOTER") or {}
	if #points <= 0 then return nil end

	local idx = ((shooterIndex or 1) - 1) % #points + 1
	return points[idx]
end

function MODE:SpawnShooter(ply)
	if not IsValid(ply) or ply:Team() != 2 then return end

	ply:Spawn()
	ply:SetSuppressPickupNotices(true)
	ply.noSound = true

	ply:SetupTeam(2)
	ply:SetPlayerClass("default")

	local shooterIndex = (self.ShooterIndex and self.ShooterIndex[ply]) or 1
	local roleName = shooterRoleNames[shooterIndex] or shooterRoleNames[1]
	zb.GiveRole(ply, roleName, Color(190,0,0))

	local spawnData = self:GetShooterSpawnData(shooterIndex)
	if spawnData and spawnData.pos then
		ply:SetPos(spawnData.pos)
		if spawnData.ang then
			ply:SetEyeAngles(Angle(0, spawnData.ang.y, 0))
		end
	end

	ply:StripWeapons()

	if shooterIndex == 1 then
		GiveWeaponWithReserve(ply, "weapon_ruger", 3)
		GiveWeaponWithReserve(ply, "weapon_p22", 3)
		ply:Give("weapon_hammer")
		ply:Give("weapon_painkillers")
		ply:Give("weapon_bandage_sh")
		ply:Give("weapon_fentanyl")
		hg.AddArmor(ply, {"ent_armor_mask1", "ent_armor_vest3"})
		SetMaskMaterial(ply, "napas/models/ballistic_mask_smiley")
	elseif shooterIndex == 2 then
		local ks23 = GiveWeaponWithReserve(ply, "weapon_ks23", 3)
		if IsValid(ks23) and ks23.GetPrimaryAmmoType then
			local ammoType = ks23:GetPrimaryAmmoType()
			if ammoType and ammoType >= 0 then
				ply:GiveAmmo(20, ammoType, true)
			end
		end
		GiveWeaponWithReserve(ply, "weapon_makarov", 3)
		ply:Give("weapon_sogknife")
		ply:Give("weapon_hg_molotov_tpik")
		ply:Give("weapon_hg_pipebomb_tpik")
		hg.AddArmor(ply, {"ent_armor_mask1", "ent_armor_vest4", "ent_armor_helmet7"})
		SetMaskMaterial(ply, "napas/models/ballistic_mask_hockey")
	else
		GiveWeaponWithReserve(ply, "weapon_ar15", 3)
		GiveWeaponWithReserve(ply, "weapon_revolver2", 3)
		ply:Give("weapon_buck200knife")
		ply:Give("weapon_hg_type59_tpik")
		ply:Give("weapon_traitor_ied")
		ply:Give("weapon_medkit_sh")
		hg.AddArmor(ply, {"ent_armor_mask1", "ent_armor_vest3"})
		SetMaskMaterial(ply, "griggs/models/ballistic_mask_collector")
	end

	ply:Give("weapon_hands_sh")
	ply:SelectWeapon("weapon_hands_sh")

	ply:SetSuppressPickupNotices(false)
	ply.noSound = false
end

function MODE:SpawnCop(ply)
	if not IsValid(ply) or ply:Team() != 0 then return end

	ply:Spawn()
	ply:SetSuppressPickupNotices(true)
	ply.noSound = true

	ply:SetupTeam(0)
	ply:SetPlayerClass("swat")

	local inv = ply:GetNetVar("Inventory")
	if istable(inv) and istable(inv.Weapons) then
		inv.Weapons.hg_sling = true
		ply:SetNetVar("Inventory", inv)
	end

	hg.AddArmor(ply, swatArmor)
	zb.GiveRole(ply, "SWAT", Color(0,0,190))

	local wepData = swatWeapons[math.random(#swatWeapons)]
	local gun = ply:Give(wepData[1])
	if IsValid(gun) and gun.GetMaxClip1 then
		hg.AddAttachmentForce(ply, gun, wepData[2])
		ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)
	end

	local sidearm = ply:Give("weapon_glock17")
	if IsValid(sidearm) and sidearm.GetMaxClip1 then
		ply:GiveAmmo(sidearm:GetMaxClip1() * 3, sidearm:GetPrimaryAmmoType(), true)
	end

	for _, item in ipairs(swatItems) do
		ply:Give(item)
	end

	ply:Give("weapon_hands_sh")
	ply:SelectWeapon("weapon_hands_sh")

	ply:SetSuppressPickupNotices(false)
	ply.noSound = false
end

function MODE:GiveEquipment()
	timer.Simple(0.5, function()
		for _, ply in player.Iterator() do
			if ply:Team() == TEAM_SPECTATOR then continue end

			if ply:Team() == 1 then
				self:GiveVictimLoadout(ply)
			end
		end

		local musicDelay = math.max((self.MusicCueAt or CurTime()) - CurTime(), 0)
		timer.Create("OverstimulatedMusicCue", musicDelay, 1, function()
			net.Start("overstimulated_audio_cue")
				net.WriteString("round45")
			net.Broadcast()
		end)

		local shooterDelay = math.max((self.ShooterSpawnAt or CurTime()) - CurTime(), 0)
		timer.Create("OverstimulatedShooterSpawnAll", shooterDelay, 1, function()
			self.ShootersActivated = true
			for _, ply in ipairs(team.GetPlayers(2)) do
				self:SpawnShooter(ply)
			end
		end)

		local copsDelay = math.max((self.CopsArrivalAt or CurTime()) - CurTime(), 1)
		timer.Create("OverstimulatedCopArrival", copsDelay, 1, function()
			self.CopsArrived = true

			local candidates = {}
			for _, ply in player.Iterator() do
				if not IsValid(ply) or ply:Team() ~= 1 or ply:Alive() then continue end
				table.insert(candidates, ply)
			end

			shuffle(candidates)

			local copCount = math.min(self.PendingCopCount or 0, #candidates)
			for i = 1, copCount do
				local ply = candidates[i]
				if not IsValid(ply) then continue end
				ply:SetTeam(0)
				self:SpawnCop(ply)
			end

			net.Start("overstimulated_audio_cue")
				net.WriteString("laststand")
			net.Broadcast()

			self.LastStandEndAt = CurTime() + LAST_STAND_DELAY
			SetGlobalFloat("overstimulated_laststand_end_at", self.LastStandEndAt)

			timer.Create("OverstimulatedLastStandDetonation", LAST_STAND_DELAY, 1, function()
				for _, shooter in ipairs(team.GetPlayers(2)) do
					if not IsValid(shooter) or not shooter:Alive() then continue end

					local center = shooter:WorldSpaceCenter()
					sound.Play("nokia.mp3", center, 70, 100, 1)

					timer.Simple(0.4, function()
						if not IsValid(shooter) then return end

						local detPos = shooter:WorldSpaceCenter()
						sound.Play("ied/ied_detonate_01.wav", detPos, 120, 100, 1)
						ParticleEffect("pcf_jack_groundsplode_medium", detPos, Angle(0, 0, 0))
						if hg and hg.ExplosionEffect then
							hg.ExplosionEffect(detPos, 500, 80)
						end
						util.BlastDamage(game.GetWorld(), game.GetWorld(), detPos, 600, 100000)

						if IsValid(shooter) and shooter:Alive() then
							shooter:SetHealth(1)
							shooter:TakeDamage(100000, game.GetWorld(), game.GetWorld())
						end

						if IsValid(shooter) and shooter:Alive() then
							shooter:Kill()
						end
					end)
				end
			end)
		end)
	end)
end

function MODE:RoundThink()
end

function MODE:GetTeamSpawn()
	return {zb:GetRandomSpawn()}, {zb:GetRandomSpawn()}
end

function MODE:CanSpawn()
end

function MODE:EndRound()
	timer.Remove("OverstimulatedShooterSpawnAll")
	timer.Remove("OverstimulatedMusicCue")
	timer.Remove("OverstimulatedCopArrival")
	timer.Remove("OverstimulatedLastStandDetonation")

	local winner = self.PendingWinner
	if winner == nil then
		local endRound
		endRound, winner = zb:CheckWinner(self:CheckAlivePlayers())
		if not endRound then
			return
		end
	end

	for _, ply in player.Iterator() do
		if ply:Team() == winner then
			ply:GiveExp(math.random(15, 30))
			ply:GiveSkill(math.Rand(0.1, 0.15))
		else
			ply:GiveSkill(-math.Rand(0.05, 0.1))
		end
	end

	self.EndDelayActive = false
	self.EndDelayAt = nil
	self.PendingWinner = nil
end

function MODE:PlayerDeath()
end
