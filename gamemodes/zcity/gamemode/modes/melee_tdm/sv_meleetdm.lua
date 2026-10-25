MODE.name = "tdmmelee"
MODE.PrintName = MODE.PrintName or "Hooligans vs Roadmen"

MODE.OverideSpawnPos = true
MODE.LootSpawn = false
MODE.Chance = 0.03
MODE.ROUND_TIME = 300

local TEAM_HOOLIGANS = 0
local TEAM_ROADMEN = 1

local meleeWeapons = {
	"weapon_bat",
	"weapon_barbedbat",
	"weapon_batmetal",
	"weapon_leadpipe",
	"weapon_hammer",
	"weapon_heavy_wrench",
	"weapon_hg_wrench",
	"weapon_hg_crowbar",
	"weapon_hg_shovel",
	"weapon_pan",
	"weapon_hg_metalpot",
	"weapon_hg_skateboard",
	"weapon_pocketknife",
	"weapon_switchblade",
	"weapon_kitchenknife",
	"weapon_screwdriver",
	"weapon_sogknife",
	"weapon_kabar",
	"weapon_buck200knife",
	"weapon_hg_cleaver",
	"weapon_hg_machete",
	"weapon_hg_nunchuks",
}

local smokeWeapons = {
	"weapon_hg_smokenade_tpik",
	"weapon_hg_m18_tpik",
}

local extras = {
	"weapon_brick",
	"weapon_hg_bottle",
	"weapon_hg_cinderblock",
}

function MODE.GuiltCheck(Attacker, Victim, add, harm, amt)
	return 1, true
end

util.AddNetworkString("tdmmelee_start")
util.AddNetworkString("tdmmelee_end")

function MODE:CanLaunch()
	return true
end

function MODE:Intermission()
	game.CleanUpMap()

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		ply:SetupTeam(ply:Team())
	end

	net.Start("tdmmelee_start")
	net.Broadcast()
end

function MODE:CheckAlivePlayers()
	return zb:CheckAliveTeams(true)
end

function MODE:ShouldRoundEnd()
	local endround = zb:CheckWinner(self:CheckAlivePlayers())
	return endround
end

function MODE:RoundStart()
end

local function GiveSling(ply)
	local inv = ply:GetNetVar("Inventory") or {}
	inv["Weapons"] = inv["Weapons"] or {}
	inv["Weapons"]["hg_sling"] = true
	ply:SetNetVar("Inventory", inv)
end

local function GiveLoadout(ply, meleeClass, smokeClass, extraClass)
	GiveSling(ply)

	ply:SetSuppressPickupNotices(true)
	ply.noSound = true

	ply:Give("weapon_hands_sh")
	ply:Give("weapon_bandage_sh")
	ply:Give("weapon_tourniquet")

	if ply.organism then
		ply.organism.allowholster = true
	end

	local radio = ply:Give("weapon_walkie_talkie")
	if IsValid(radio) then
		radio.Frequency = ply:Team() == TEAM_ROADMEN and 91.2 or 105.4
	end

	ply:Give(smokeClass)

	if extraClass then
		ply:Give(extraClass)
	end

	local wep = ply:Give(meleeClass)
	if IsValid(wep) then
		ply:SelectWeapon(wep:GetClass())
	else
		ply:SelectWeapon("weapon_hands_sh")
	end

	timer.Simple(0.1, function()
		if IsValid(ply) then
			ply.noSound = false
		end
	end)

	ply:SetSuppressPickupNotices(false)
end

function MODE:GiveEquipment()
	timer.Simple(0.1, function()
		local teams = {[TEAM_HOOLIGANS] = {}, [TEAM_ROADMEN] = {}}
		for _, ply in player.Iterator() do
			if ply:Team() == TEAM_SPECTATOR or not ply:Alive() then continue end

			if ply:Team() == TEAM_ROADMEN then
				ply:SetPlayerClass("roadman")
				zb.GiveRole(ply, "Roadmen", Color(40, 40, 45))
				ply:SetNetVar("CurPluv", "pluvberet")
			else
				ply:SetPlayerClass("hooligan")
				zb.GiveRole(ply, "Hooligans", Color(150, 20, 45))
				ply:SetNetVar("CurPluv", "pluvmajima")
			end

			local roster = teams[ply:Team()]
			roster[#roster + 1] = ply
		end

		local slots = math.max(#teams[TEAM_HOOLIGANS], #teams[TEAM_ROADMEN])
		for i = 1, slots do
			local meleeClass = meleeWeapons[math.random(#meleeWeapons)]
			local smokeClass = smokeWeapons[math.random(#smokeWeapons)]
			local extraClass = math.random() < 0.35 and extras[math.random(#extras)] or nil
			local hooligan = teams[TEAM_HOOLIGANS][i]
			local roadman = teams[TEAM_ROADMEN][i]
			if IsValid(hooligan) then GiveLoadout(hooligan, meleeClass, smokeClass, extraClass) end
			if IsValid(roadman) then GiveLoadout(roadman, meleeClass, smokeClass, extraClass) end
		end
	end)
end

function MODE:GetTeamSpawn()
	return zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_T")),
		zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_CT"))
end

function MODE:RoundThink()
end

function MODE:EndRound()
	timer.Simple(2, function()
		net.Start("tdmmelee_end")
		net.Broadcast()
	end)

	local _, winner = zb:CheckWinner(self:CheckAlivePlayers())
	for _, ply in player.Iterator() do
		if ply:Team() == winner then
			ply:GiveExp(math.random(15, 30))
			ply:GiveSkill(math.Rand(0.1, 0.15))
		elseif ply:Team() ~= TEAM_SPECTATOR then
			ply:GiveSkill(-math.Rand(0.05, 0.1))
		end
	end
end

return MODE
