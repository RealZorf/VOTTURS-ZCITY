local MODE = MODE
MODE.start_time = 1
MODE.end_time = 7
 
MODE.ROUND_TIME = 600
 
MODE.randomSpawns = true

MODE.shouldfreeze = true

MODE.PoliceAllowed = false
MODE.OverrideSpawn = true

MODE.LootSpawn = true
MODE.LootOnTime = true

MODE.Chance = 0.2 -- this is mostly unused
MODE.LootDivTime = 500

function MODE:SetupChances()
	for name, tbl in pairs(MODE.Types) do
		zb.ModesChances[name] = zb.ModesChances[name] or tbl.Chance
	end
end

MODE.LootTable = {
    {40,{
		{10,"weapon_tourniquet"},
		{10,"weapon_bandage_sh"},
        {10,"weapon_painkillers"},
        {7,"weapon_bloodbag"},
        {7,"weapon_bigbandage_sh"},
        {5,"weapon_medkit_sh"},
        {1,"weapon_morphine"},
        {1,"weapon_mannitol"},
        {1,"weapon_naloxone"},
        {0.5,"weapon_fentanyl"},
        {3,"weapon_betablock"},
        {1.5,"weapon_adrenaline"},
		{3,"weapon_needle"},
	}},
	{20,{
	    {8,"weapon_smallconsumable"},
        {8,"weapon_bigconsumable"},
		{4,"weapon_hg_cigarette"},
		{4,"weapon_pat_beer"},
		{1,"weapon_ducttape"},
		{1,"weapon_matches"},
		{2,"weapon_pat_whiskey"},
		{1,"weapon_zippo_tpik"},
	}},
    {20,{
		{6,"weapon_bat"},
		{10,"weapon_brick"},
		{6,"weapon_hg_cinderblock"},
		{3,"weapon_hg_crowbar"},
		{2,"weapon_hg_extinguisher"},
		{2,"weapon_hg_fubar"},
		{6,"weapon_hg_tonfa"},
		{6,"weapon_hammer"},
		{3,"weapon_hatchet"},
		{0.5,"iron_sword"},
		{3,"weapon_kitchenknife"},
		{3,"weapon_leadpipe"},
		{3,"weapon_hg_machete"},
		{3,"weapon_batmetal"},
		{10,"weapon_hg_can"},
		{4,"weapon_hatchethmcd"},
		{2,"weapon_hg_metalpot"},
		{4,"weapon_pan"},
		{8,"weapon_pocketknife"},
		{1,"weapon_hg_pickaxe"},
		{0.2,"weapon_hg_pitchfork"},
		{0.2,"weapon_hg_spear_knife"},
		{0.2,"weapon_hg_spear_pro"},
		{0.2,"weapon_hg_spear"},
		{3,"weapon_screwdriver"},
		{3,"weapon_hg_shovel"},
		{3,"weapon_hg_skateboard"},
		{2,"weapon_hg_sledgehammer"},
		{3,"weapon_hg_taiga"},
		{2,"weapon_hg_axe"},
		{6,"weapon_hg_wrench"},
	}},
    {8, {
		{3,"ent_armor_helmet5"},
		{3,"ent_armor_helmet1"},
		{1,"ent_armor_vest1"},
		{6,"ent_armor_helmet7"},
		{3,"ent_armor_vest4"},
		{8,"ent_armor_vest3"},
		{6,"ent_armor_mask3"},
		{1,"ent_armor_mask1"},
		{2,"ent_armor_vest5"},
    }},
    {7,{
		{10,"weapon_zoraki"},
		{10,"weapon_mp-80"},
		{10,"weapon_osapb"},
		{8,"weapon_makarov"},
		{7,"weapon_makarovpistolpb"},
		{7,"weapon_m70zastavapist"},
		{7,"weapon_revolversw686"},
        {7,"weapon_m1911"},
    }},
	{6,{
		{5,"weapon_hk_usp"},
		{5,"weapon_glock17"},
		{5,"weapon_glock26"},
		{3,"weapon_glock22"},
		{5,"weapon_tticglock"},
		{5,"weapon_cz75"},
		{5,"weapon_p320alligator"},
		{5,"weapon_hkp7"},
		{3,"weapon_mk23"},
		{3,"weapon_fn45"},
		{3,"weapon_browninghp"},
		{5,"weapon_p250"},
		{5,"weapon_minebeap220"},
		{5,"weapon_vp9hk"},
		{5,"weapon_p99"},
		{5,"weapon_m9beretta"},
		{5,"weapon_grach"},
    }},
    {4,	{
		{3,"weapon_fivsevn"},
		{5,"weapon_deagle"},
		{5,"weapon_grizzlymkv"},
		{5,"weapon_revolvermodel29"},
		{5,"weapon_conan357"},
		{5,"weapon_python"},
		{5,"weapon_revolver357"},
		{5,"weapon_revolver412rex"},
		{5,"weapon_revolverswr8"},
		{3,"weapon_cz75a"},
		{3,"weapon_glock18c"},
		{3,"weapon_pernachots"},
		{3,"weapon_apsss"},
		{3,"weapon_pm9"},
		{1,"weapon_draco"},
		{2,"weapon_magnumbfr"},
		{3,"weapon_colt9mm"},
		{3,"weapon_tec9"},
		{3,"weapon_uzicarbine"},
	}},
	{6, {
		{2,"ent_att_supressor4"},
		{2,"ent_att_holo16"},
		{2,"ent_att_holo9"},
		{2,"ent_att_holo4"},
		{2,"ent_att_laser5"},
		{2,"ent_att_laser1"},
		{2,"ent_att_holo7"},
		{2,"ent_att_holo5"},
		{1,"ent_att_supressor5"},
    }},
    {3, {
        {2,"weapon_adar215"},
		{4,"weapon_revolverequiem"},
		{4,"weapon_revolve50bmg"},
		{1,"weapon_dracovska"},
		{2,"weapon_vpo136"},
		{2,"weapon_vpo209"},
		{2,"weapon_mini30762"},
    }},
}

MODE.LootTableStandard = {
    {60,{
		{10,"weapon_tourniquet"},
		{10,"weapon_bandage_sh"},
        {10,"weapon_painkillers"},
        {7,"weapon_bloodbag"},
        {7,"weapon_bigbandage_sh"},
        {5,"weapon_medkit_sh"},
        {1,"weapon_morphine"},
        {1,"weapon_mannitol"},
        {1,"weapon_naloxone"},
        {0.5,"weapon_fentanyl"},
        {3,"weapon_betablock"},
        {1.5,"weapon_adrenaline"},
		{3,"weapon_needle"},
	}},
	{30,{
	    {8,"weapon_smallconsumable"},
        {8,"weapon_bigconsumable"},
		{4,"weapon_hg_cigarette"},
		{4,"weapon_pat_beer"},
		{1,"weapon_ducttape"},
		{1,"weapon_matches"},
		{2,"weapon_pat_whiskey"},
		{1,"weapon_zippo_tpik"},
	}},
    {30,{
		{6,"weapon_bat"},
		{10,"weapon_brick"},
		{6,"weapon_hg_cinderblock"},
		{3,"weapon_hg_crowbar"},
		{2,"weapon_hg_extinguisher"},
		{2,"weapon_hg_fubar"},
		{6,"weapon_hg_tonfa"},
		{6,"weapon_hammer"},
		{3,"weapon_hatchet"},
		{0.5,"iron_sword"},
		{3,"weapon_kitchenknife"},
		{3,"weapon_leadpipe"},
		{3,"weapon_hg_machete"},
		{3,"weapon_batmetal"},
		{10,"weapon_hg_can"},
		{4,"weapon_hatchethmcd"},
		{2,"weapon_hg_metalpot"},
		{4,"weapon_pan"},
		{1,"weapon_hg_pickaxe"},
		{8,"weapon_pocketknife"},
		{1,"weapon_hg_pickaxe"},
		{0.2,"weapon_hg_pitchfork"},
		{0.2,"weapon_hg_spear_knife"},
		{0.2,"weapon_hg_spear_pro"},
		{0.2,"weapon_hg_spear"},
		{3,"weapon_screwdriver"},
		{3,"weapon_hg_shovel"},
		{3,"weapon_hg_skateboard"},
		{2,"weapon_hg_sledgehammer"},
		{3,"weapon_hg_taiga"},
		{2,"weapon_hg_axe"},
		{6,"weapon_hg_wrench"},
	}},
    {2,{
		{10,"weapon_zoraki"},
		{10,"weapon_mp-80"},
		{10,"weapon_osapb"},
		{8,"weapon_makarov"},
		{7,"weapon_makarovpistolpb"},
		{7,"weapon_m70zastavapist"},
		{7,"weapon_revolversw686"},
        {7,"weapon_m1911"},
	}},
}

-- MODE.TraitorWords = {
	--"gun",
	--"treitor",
	--"gunman"
	--"Kalash (rifle)",
	--"bomb",
	--"cyanide",
	--"knife",
	--"pipe",
	--"axe",
	--"USP (pistol)",
	--"arch (rifle)",
	--"karak (rifle)",
	--"grenade",
	--"street",
	--"building",
	--"cartridges"
	--"bandage",
	--"first aid kit"
	--"painkiller"
	--"shotgun",
-- }

MODE.TraitorWordsAdjectives = {
	"pretty",
	"sad",
	"bad",
	"cool",
	"happy",
	"ugly",
	"funny",
	"red",
	"green",
	"blue",
	"yellow",
	"orange",
	"cyan",
	"pink",
	"mesmerizing",
	"",	--; yes yes
}

MODE.TraitorWords = {
	"crate",
	"death",
	"man",
	"revolver",
	"door",
	"pistol",
	"traitor",
	"gunman",
	"ak rifle",
	"bomb",
	"cyanide",
	"knife",
	"pipe",
	"axe",
	"usp pistol",
	"ar15 rifle",
	"kar98k rifle",
	"grenade",
	"outside",
	"building",
	"ammo",
	"bandage",
	"medkit",
	"painkillers",
	"shotgun",
	"melancholic",
	"poison",
	"murder",
}

MODE.TraitorActions = {
	"punch air or walls",
	"jump",
	"crouch",
	"ragdoll randomly",
	"spin around",
}

SetGlobalBool("RolesPlus_Enable", true)

util.AddNetworkString("HMCDPoliceRole")
util.AddNetworkString("HMCD(StartPlayersRoleSelection)")
util.AddNetworkString("HMCD(EndPlayersRoleSelection)")
util.AddNetworkString("HMCD(SetSubRole)")
util.AddNetworkString("HMCD(SyncTraitorRolePreferences)")
util.AddNetworkString("HMCD(SetProfession)")
util.AddNetworkString("hmcd_announce_traitor_lose")
util.AddNetworkString("HMCD_TraitorRoleStats")
util.AddNetworkString("HMCD_RequestTraitorRoleStats")

local HMCD_TRAITOR_ROLE_STATS_PATH = "zcity/hmcd_traitor_role_stats.json"
local HMCD_TRAITOR_ROLE_STATS_BITS = 24
local HMCD_TRAITOR_ROLE_STATS_MIN_PLAYERS = 15

function MODE.LoadTraitorRoleStats()
	if MODE.HMCDTraitorRoleStatsLoaded then return end
	MODE.HMCDTraitorRoleStatsLoaded = true
	MODE.HMCDTraitorRoleStats = {}

	local raw = file.Read(HMCD_TRAITOR_ROLE_STATS_PATH, "DATA")
	if not raw or raw == "" then return end

	local decoded = util.JSONToTable(raw)
	if not istable(decoded) then return end

	for role, stats in pairs(decoded) do
		local normalized_role = MODE.NormalizeTraitorSubRole and MODE.NormalizeTraitorSubRole(role) or role
		if isstring(normalized_role) and MODE.SubRoles[normalized_role] and istable(stats) then
			local wins = math.max(math.floor(tonumber(stats.wins or stats.Wins or 0) or 0), 0)
			local games = math.max(math.floor(tonumber(stats.games or stats.Games or 0) or 0), wins)

			MODE.HMCDTraitorRoleStats[normalized_role] = {
				wins = wins,
				games = games
			}
		end
	end
end

function MODE.SaveTraitorRoleStats()
	MODE.LoadTraitorRoleStats()
	file.CreateDir("zcity")
	file.Write(HMCD_TRAITOR_ROLE_STATS_PATH, util.TableToJSON(MODE.HMCDTraitorRoleStats or {}, true))
end

function MODE.SendTraitorRoleStats(ply)
	if not IsValid(ply) then return end

	MODE.LoadTraitorRoleStats()

	local entries = {}
	for role, stats in pairs(MODE.HMCDTraitorRoleStats or {}) do
		if MODE.SubRoles[role] and istable(stats) then
			entries[#entries + 1] = {
				role = role,
				wins = math.Clamp(math.floor(tonumber(stats.wins or 0) or 0), 0, 16777215),
				games = math.Clamp(math.floor(tonumber(stats.games or 0) or 0), 0, 16777215)
			}
		end
	end

	table.sort(entries, function(a, b)
		return a.role < b.role
	end)

	net.Start("HMCD_TraitorRoleStats")
		net.WriteUInt(math.min(#entries, 255), 8)

		for i = 1, math.min(#entries, 255) do
			local entry = entries[i]
			net.WriteString(entry.role)
			net.WriteUInt(entry.wins, HMCD_TRAITOR_ROLE_STATS_BITS)
			net.WriteUInt(entry.games, HMCD_TRAITOR_ROLE_STATS_BITS)
		end
	net.Send(ply)
end

function MODE.BroadcastTraitorRoleStats()
	for _, ply in player.Iterator() do
		MODE.SendTraitorRoleStats(ply)
	end
end

function MODE.RecordTraitorRoleStats(role_results, traitors_won)
	if MODE.HMCDTraitorRoleStatsRecorded then return end
	MODE.HMCDTraitorRoleStatsRecorded = true

	if player.GetCount() < HMCD_TRAITOR_ROLE_STATS_MIN_PLAYERS then return end
	if not istable(role_results) or #role_results == 0 then return end

	MODE.LoadTraitorRoleStats()

	for _, result in ipairs(role_results) do
		local role = result.role
		if isstring(role) and MODE.SubRoles[role] then
			local stats = MODE.HMCDTraitorRoleStats[role] or {wins = 0, games = 0}
			stats.games = math.max(math.floor(tonumber(stats.games or 0) or 0), 0) + 1
			stats.wins = math.max(math.floor(tonumber(stats.wins or 0) or 0), 0) + (traitors_won and 1 or 0)
			MODE.HMCDTraitorRoleStats[role] = stats
		end
	end

	MODE.SaveTraitorRoleStats()
	MODE.BroadcastTraitorRoleStats()
end

net.Receive("HMCD_RequestTraitorRoleStats", function(_, ply)
	MODE.SendTraitorRoleStats(ply)
end)

MODE.BaseProfessionHealth = 100
MODE.BaseProfessionStamina = 60 * 3
MODE.RandomTraitorRoleHealthBonus = MODE.RandomTraitorRoleHealthBonus or 50
MODE.RandomTraitorRoleStaminaBonus = MODE.RandomTraitorRoleStaminaBonus or 50

local function HMCDResetTraitorFlashlight(ply)
	if not IsValid(ply) or not ply.isTraitor then return end

	ply:SetNetVar("flashlight", false)
	if IsValid(ply.flashlight) then
		ply.flashlight:Remove()
	end

	if ply:HasWeapon("weapon_hands_sh") then
		ply:SelectWeapon("weapon_hands_sh")
		local hands = ply:GetWeapon("weapon_hands_sh")
		if IsValid(hands) then
			ply:SetActiveWeapon(hands)
		end
	end
end

local function HMCDGetTraitorDisabledToken(round_type)
	return round_type == "soe" and (MODE.SubRole_Traitor_Disabled_SOE or "traitor_disabled_soe") or (MODE.SubRole_Traitor_Disabled or "traitor_disabled")
end

local function HMCDGetTraitorRandomToken(round_type)
	return round_type == "soe" and (MODE.SubRole_Traitor_Random_SOE or "traitor_random_soe") or (MODE.SubRole_Traitor_Random or "traitor_random")
end

local function HMCDGetTraitorPreferenceKey(round_type)
	return round_type == "soe" and "soe" or "standard"
end

local function HMCDGetTraitorPreferenceConvarName(round_type)
	return round_type == "soe" and MODE.ConVarName_SubRole_Traitor_SOE or MODE.ConVarName_SubRole_Traitor
end

local function HMCDValidateTraitorRolePreference(preference, round_type)
	if not isstring(preference) or preference == "" or #preference > 64 then return nil end

	local normalized = MODE.NormalizeTraitorSubRole and MODE.NormalizeTraitorSubRole(preference) or preference
	if normalized == HMCDGetTraitorDisabledToken(round_type) or normalized == HMCDGetTraitorRandomToken(round_type) then
		return normalized
	end

	local round_config = MODE.RoleChooseRoundTypes and MODE.RoleChooseRoundTypes[round_type]
	if not round_config or not istable(round_config.Traitor) then return nil end
	if not round_config.Traitor[normalized] or not MODE.SubRoles or not MODE.SubRoles[normalized] then return nil end

	return normalized
end

local function HMCDGetPlayerTraitorRolePreference(ply, round_type)
	if not IsValid(ply) then return nil end

	local preference_key = HMCDGetTraitorPreferenceKey(round_type)
	local cached = ply.HMCDTraitorRolePreferences and ply.HMCDTraitorRolePreferences[preference_key]
	if cached then return cached end

	local convar_name = HMCDGetTraitorPreferenceConvarName(round_type)
	return HMCDValidateTraitorRolePreference(ply:GetInfo(convar_name or ""), round_type)
end

net.Receive("HMCD(SyncTraitorRolePreferences)", function(_, ply)
	if not IsValid(ply) then return end
	if (ply.HMCDNextTraitorRolePreferenceSync or 0) > CurTime() then return end

	local standard = HMCDValidateTraitorRolePreference(net.ReadString(), "standard")
	local soe = HMCDValidateTraitorRolePreference(net.ReadString(), "soe")
	if not standard or not soe then return end

	ply.HMCDNextTraitorRolePreferenceSync = CurTime() + 0.1
	ply.HMCDTraitorRolePreferences = {
		standard = standard,
		soe = soe
	}
	ply.HMCDTraitorRolePreferencesReady = true
end)

local function HMCDPlayerDisabledTraitorMode(ply, round_type)
	if not IsValid(ply) then return false end

	return HMCDGetPlayerTraitorRolePreference(ply, round_type) == HMCDGetTraitorDisabledToken(round_type)
end

local function HMCDChooseRandomTraitorSubRole(round_type)
	local round_config = MODE.RoleChooseRoundTypes and MODE.RoleChooseRoundTypes[round_type]
	if not round_config or not istable(round_config.Traitor) then return nil end

	local choices = {}
	for role, enabled in pairs(round_config.Traitor) do
		if enabled
			and role ~= round_config.TraitorDefaultRole
			and isstring(role)
			and MODE.SubRoles
			and MODE.SubRoles[role]
		then
			choices[#choices + 1] = role
		end
	end

	if #choices <= 0 then return round_config.TraitorDefaultRole end

	return choices[math.random(#choices)]
end

local function HMCDResolvePlayerTraitorSubRole(ply, round_type)
	local round_config = MODE.RoleChooseRoundTypes and MODE.RoleChooseRoundTypes[round_type]
	local default_role = round_config and round_config.TraitorDefaultRole or "traitor_default"
	local sub_role = HMCDGetPlayerTraitorRolePreference(ply, round_type) or default_role

	if sub_role == HMCDGetTraitorDisabledToken(round_type) then
		return default_role, false
	end

	if sub_role == HMCDGetTraitorRandomToken(round_type) then
		return HMCDChooseRandomTraitorSubRole(round_type) or default_role, true
	end

	return sub_role, false
end

local function HMCDApplyRandomTraitorRoleBonus(ply)
	if not IsValid(ply) or not ply.MainTraitor or not ply.HMCD_RandomTraitorRoleBonus then return end

	ply.HMCD_RandomTraitorRoleBonus = nil

	local health_bonus = math.max(tonumber(MODE.RandomTraitorRoleHealthBonus) or 0, 0)
	local stamina_bonus = math.max(tonumber(MODE.RandomTraitorRoleStaminaBonus) or 0, 0)

	if health_bonus > 0 then
		local old_max_health = math.max(ply:GetMaxHealth() or 100, 1)
		local new_max_health = old_max_health + health_bonus

		ply:SetMaxHealth(new_max_health)
		ply:SetHealth(math.Clamp((ply:Health() or old_max_health) + health_bonus, 1, new_max_health))
	end

	local org = ply.organism
	local stamina = org and org.stamina
	if stamina and stamina_bonus > 0 then
		local old_stamina_max = math.max(stamina.max or stamina.range or MODE.BaseProfessionStamina or 180, 1)
		local old_stamina_range = math.max(stamina.range or old_stamina_max, 1)
		local new_stamina_max = math.max(old_stamina_max, old_stamina_range) + stamina_bonus

		stamina.range = new_stamina_max
		stamina.max = new_stamina_max
		stamina[1] = math.Clamp((stamina[1] or old_stamina_max) + stamina_bonus, 0, new_stamina_max)
	end
end

local function HMCDSanitizeProfessionToken(text)
	return string.gsub(string.Trim(string.lower(text or "")), "[%s_%-]+", "")
end

function MODE.NormalizeProfessionId(profession_id)
	if(!isstring(profession_id))then
		return nil
	end

	local sanitized_profession_id = HMCDSanitizeProfessionToken(profession_id)

	if(sanitized_profession_id == "")then
		return nil
	end

	if(sanitized_profession_id == "doctor")then
		sanitized_profession_id = "medic"
	end

	for current_profession_id, profession_info in pairs(MODE.Professions) do
		if(HMCDSanitizeProfessionToken(current_profession_id) == sanitized_profession_id or HMCDSanitizeProfessionToken(profession_info.Name or "") == sanitized_profession_id)then
			return current_profession_id
		end
	end
end

function MODE.GetProfessionCommandName(profession_id)
	local profession_info = MODE.Professions[profession_id]

	if(profession_info and profession_info.Name)then
		return string.lower(profession_info.Name)
	end

	return string.gsub(string.lower(profession_id or ""), "_", " ")
end

function MODE.GetAvailableProfessionIds(round_type)
	local available_professions = {}
	local profession_pool = MODE.Professions

	if(round_type and MODE.RoleChooseRoundTypes[round_type] and MODE.RoleChooseRoundTypes[round_type].Professions)then
		profession_pool = MODE.RoleChooseRoundTypes[round_type].Professions
	end

	for profession_id in pairs(profession_pool) do
		if(MODE.Professions[profession_id])then
			available_professions[#available_professions + 1] = profession_id
		end
	end

	table.sort(available_professions)

	return available_professions
end

function MODE.GetAvailableProfessionList(round_type)
	local available_profession_names = {}

	for _, profession_id in ipairs(MODE.GetAvailableProfessionIds(round_type)) do
		available_profession_names[#available_profession_names + 1] = MODE.GetProfessionCommandName(profession_id)
	end

	return table.concat(available_profession_names, ", ")
end

function MODE.ClearProfessionLoadout(ply)
	if(!IsValid(ply))then
		return
	end

	local stripped_weapons = {}

	for _, profession_info in pairs(MODE.Professions or {}) do
		if(profession_info.Loadout)then
			for _, weapon_class in ipairs(profession_info.Loadout) do
				if(!stripped_weapons[weapon_class] and ply:HasWeapon(weapon_class))then
					ply:StripWeapon(weapon_class)
					stripped_weapons[weapon_class] = true
				end
			end
		end
	end
end

function MODE.ResetProfessionStats(ply)
	if(!IsValid(ply))then
		return
	end

	local base_health = MODE.BaseProfessionHealth
	local old_max_health = math.max((ply:GetMaxHealth() > 0 and ply:GetMaxHealth()) or base_health, 1)
	local current_health = math.max(ply:Health(), 0)
	local health_ratio = math.Clamp(current_health / old_max_health, 0, 1)

	ply:SetMaxHealth(base_health)
	if(hg and hg.SetPlayerModelScale)then
		hg.SetPlayerModelScale(ply, 1, "profession")
	else
		ply:SetModelScale(1, 0)
	end
	ply.MeleeDamageMul = nil
	ply.StaminaExhaustMul = nil
	ply.JumpPowerMul = nil

	if(ply:Alive())then
		ply:SetHealth(math.Clamp(math.Round(base_health * health_ratio), 1, base_health))
	end

	if(ply.organism and istable(ply.organism.stamina))then
		local stamina = ply.organism.stamina
		local old_stamina_range = math.max(stamina.range or MODE.BaseProfessionStamina, 1)
		local current_stamina = math.max(stamina[1] or old_stamina_range, 0)
		local stamina_ratio = math.Clamp(current_stamina / old_stamina_range, 0, 1)

		stamina.range = MODE.BaseProfessionStamina
		stamina.max = MODE.BaseProfessionStamina
		stamina[1] = math.Clamp(math.Round(MODE.BaseProfessionStamina * stamina_ratio), 0, stamina.max)
	end

	if(ply.organism)then
		ply.organism.legstrength = 1
	end
end

function MODE.ApplyProfessionLoadout(ply)
	if(!IsValid(ply))then
		return
	end

	MODE.ResetProfessionStats(ply)

	if(!ply.Profession)then
		return
	end

	local profession_info = MODE.Professions[ply.Profession]

	if(profession_info)then
		if(profession_info.HealthMultiplier and profession_info.HealthMultiplier != 1)then
			local max_health = math.max(1, math.Round(MODE.BaseProfessionHealth * profession_info.HealthMultiplier))
			local health_ratio = math.Clamp(ply:Health() / MODE.BaseProfessionHealth, 0, 1)

			ply:SetMaxHealth(max_health)

			if(ply:Alive())then
				ply:SetHealth(math.Clamp(math.Round(max_health * health_ratio), 1, max_health))
			end
		end

		if(profession_info.StaminaMultiplier and profession_info.StaminaMultiplier != 1 and ply.organism and istable(ply.organism.stamina))then
			local stamina = ply.organism.stamina
			local stamina_ratio = math.Clamp((stamina[1] or MODE.BaseProfessionStamina) / MODE.BaseProfessionStamina, 0, 1)
			local stamina_max = math.max(1, math.Round(MODE.BaseProfessionStamina * profession_info.StaminaMultiplier))

			stamina.range = stamina_max
			stamina.max = stamina_max
			stamina[1] = math.Clamp(math.Round(stamina_max * stamina_ratio), 0, stamina.max)
		end

		if(profession_info.ModelScale and profession_info.ModelScale != 1)then
			if(hg and hg.SetPlayerModelScale)then
				hg.SetPlayerModelScale(ply, profession_info.ModelScale, "profession")
			else
				ply:SetModelScale(profession_info.ModelScale, 0)
			end
		end

		if(profession_info.MeleeDamageMultiplier and profession_info.MeleeDamageMultiplier != 1)then
			ply.MeleeDamageMul = profession_info.MeleeDamageMultiplier
		end

		if(profession_info.StaminaExhaustMultiplier and profession_info.StaminaExhaustMultiplier != 1)then
			ply.StaminaExhaustMul = profession_info.StaminaExhaustMultiplier
		end

		if(profession_info.JumpPowerMultiplier and profession_info.JumpPowerMultiplier != 1)then
			ply.JumpPowerMul = profession_info.JumpPowerMultiplier
		end

		if(profession_info.LegStrengthMultiplier and profession_info.LegStrengthMultiplier != 1 and ply.organism)then
			ply.organism.legstrength = profession_info.LegStrengthMultiplier
		end
	end

	if(profession_info and profession_info.SpawnFunction)then
		profession_info.SpawnFunction(ply)
	end
end

function MODE.SyncProfession(ply)
	if(!IsValid(ply))then
		return
	end

	net.Start("HMCD(SetProfession)")
		net.WriteString(ply.Profession or "")
	net.Send(ply)
end

local function HMCDCanApplyProfessionNow(ply)
	local mode = CurrentRound()

	return IsValid(ply) and mode and mode.name == "hmcd" and zb.ROUND_STATE == 1 and ply:Team() != TEAM_SPECTATOR and ply:Alive() and !ply.isTraitor
end

local function HMCDGetProfessionMaxPlayers(profession_id, round_type)
	local round_info = round_type and MODE.RoleChooseRoundTypes[round_type] and MODE.RoleChooseRoundTypes[round_type].Professions and MODE.RoleChooseRoundTypes[round_type].Professions[profession_id]

	if(round_info and round_info.MaxPlayers)then
		return round_info.MaxPlayers
	end

	local profession_info = MODE.Professions[profession_id]

	if(profession_info and profession_info.MaxPlayers)then
		return profession_info.MaxPlayers
	end
end

local function HMCDCountProfessionAssignments(profession_id, field_name, exclude_ply)
	local profession_count = 0

	for _, current_ply in player.Iterator() do
		if(current_ply != exclude_ply and MODE.NormalizeProfessionId(current_ply[field_name]) == profession_id)then
			profession_count = profession_count + 1
		end
	end

	return profession_count
end

local function HMCDValidateProfessionCapacity(target_ply, profession_id, round_type)
	local max_players = HMCDGetProfessionMaxPlayers(profession_id, round_type)

	if(!max_players)then
		return true
	end

	local counting_field = HMCDCanApplyProfessionNow(target_ply) and "Profession" or "HMCDPreferredProfession"
	local current_count = HMCDCountProfessionAssignments(profession_id, counting_field, target_ply)

	if(current_count >= max_players)then
		local profession_name = (MODE.Professions[profession_id] and MODE.Professions[profession_id].Name) or profession_id

		return false, "The innocent class '" .. profession_name .. "' is limited to " .. max_players .. " players."
	end

	return true
end

local function HMCDParseCommandArguments(text)
	local arguments = {}
	local waiting_for_quote = false
	local quoted_text = nil

	for _, current_part in ipairs(string.Split(string.Trim(text or ""), " ")) do
		if(current_part == "")then
			continue
		end

		if(!waiting_for_quote and string.sub(current_part, 1, 1) == "\"")then
			if(string.sub(current_part, -1) == "\"" and #current_part > 1)then
				arguments[#arguments + 1] = string.sub(current_part, 2, -2)
			else
				waiting_for_quote = true
				quoted_text = string.sub(current_part, 2)
			end

			continue
		end

		if(waiting_for_quote)then
			if(string.sub(current_part, -1) == "\"")then
				waiting_for_quote = nil
				arguments[#arguments + 1] = (quoted_text != "" and (quoted_text .. " ") or "") .. string.sub(current_part, 1, -2)
				quoted_text = nil
			else
				quoted_text = (quoted_text != "" and (quoted_text .. " ") or "") .. current_part
			end

			continue
		end

		arguments[#arguments + 1] = current_part
	end

	if(waiting_for_quote and quoted_text and quoted_text != "")then
		arguments[#arguments + 1] = quoted_text
	end

	return arguments
end

local function HMCDFindSinglePlayerByName(name)
	local trimmed_name = string.Trim(name or "")

	if(trimmed_name == "")then
		return nil, "Please specify a player name."
	end

	local lowered_name = string.lower(trimmed_name)
	local partial_matches = {}

	for _, target_ply in player.Iterator() do
		local player_name = string.lower(target_ply:Name())

		if(player_name == lowered_name)then
			return target_ply
		end

		if(string.find(player_name, lowered_name, 1, true))then
			partial_matches[#partial_matches + 1] = target_ply
		end
	end

	if(#partial_matches == 1)then
		return partial_matches[1]
	end

	if(#partial_matches == 0)then
		return nil, "No player matches '" .. trimmed_name .. "'."
	end

	return nil, "Multiple players match '" .. trimmed_name .. "'."
end

local function HMCDParseInnoclassSelection(arguments)
	local arguments_count = #arguments

	for end_index = arguments_count, 2, -1 do
		local profession_id = MODE.NormalizeProfessionId(table.concat(arguments, " ", 2, end_index))

		if(profession_id)then
			return profession_id, string.Trim(table.concat(arguments, " ", end_index + 1))
		end
	end

	for start_index = 3, arguments_count do
		local profession_id = MODE.NormalizeProfessionId(table.concat(arguments, " ", start_index, arguments_count))

		if(profession_id)then
			return profession_id, string.Trim(table.concat(arguments, " ", 2, start_index - 1))
		end
	end
end

local function HMCDApplyProfessionSelection(actor_ply, target_ply, profession_id)
	target_ply.HMCDPreferredProfession = profession_id

	local profession_name = (MODE.Professions[profession_id] and MODE.Professions[profession_id].Name) or profession_id

	if(HMCDCanApplyProfessionNow(target_ply))then
		target_ply.Profession = profession_id
		MODE.ClearProfessionLoadout(target_ply)
		MODE.ApplyProfessionLoadout(target_ply)

		local hands = target_ply:GetWeapon("weapon_hands_sh")

		if(IsValid(hands))then
			target_ply:SetActiveWeapon(hands)
		end

		MODE.SyncProfession(target_ply)

		if(actor_ply == target_ply)then
			actor_ply:ChatPrint("Your innocent class has been set to " .. profession_name .. " and applied for this round.")
		else
			actor_ply:ChatPrint(target_ply:Name() .. "'s innocent class has been set to " .. profession_name .. " and applied for this round.")
			target_ply:ChatPrint(actor_ply:Name() .. " set your innocent class to " .. profession_name .. " and applied it for this round.")
		end
	else
		if(actor_ply == target_ply)then
			actor_ply:ChatPrint("Your innocent class has been set to " .. profession_name .. ". It will apply the next time you spawn as an innocent in Homicide.")
		else
			actor_ply:ChatPrint(target_ply:Name() .. "'s innocent class has been set to " .. profession_name .. ". It will apply the next time they spawn as an innocent in Homicide.")
			target_ply:ChatPrint(actor_ply:Name() .. " set your innocent class to " .. profession_name .. ". It will apply the next time you spawn as an innocent in Homicide.")
		end
	end
end

MODE.ApplyProfessionSelection = HMCDApplyProfessionSelection

hook.Add("HG_PlayerSay", "HMCD_InnoclassCommand", function(ply, txtTbl, text)
	if(string.sub(text or "", 1, 1) != "!")then
		return
	end

	local arguments = HMCDParseCommandArguments(string.sub(text or "", 2))
	local command = string.lower(arguments[1] or "")

	if(command != "innoclass")then
		return
	end

	txtTbl[1] = ""

	local mode = CurrentRound()
	local round_type = mode and mode.name == "hmcd" and mode.Type or nil
	local available_classes = MODE.GetAvailableProfessionList(round_type)

	if(!arguments[2])then
		ply:ChatPrint("Available innocent classes: " .. available_classes)
		return
	end

	local profession_id, target_name = HMCDParseInnoclassSelection(arguments)

	if(!profession_id)then
		local entered_class = string.Trim(table.concat(arguments, " ", 2))

		ply:ChatPrint("Unknown innocent class '" .. entered_class .. "'. Available classes: " .. available_classes)
		return
	end

	if(round_type and MODE.RoleChooseRoundTypes[round_type] and !MODE.RoleChooseRoundTypes[round_type].Professions[profession_id])then
		ply:ChatPrint("The class '" .. profession_id .. "' is not available in this Homicide type. Available classes: " .. available_classes)
		return
	end

	local target_ply = ply

	if(target_name and target_name != "")then
		if(!ply:IsAdmin())then
			ply:ChatPrint("You can only set another player's innocent class as an admin.")
			return
		end

		local find_error
		target_ply, find_error = HMCDFindSinglePlayerByName(target_name)

		if(!IsValid(target_ply))then
			ply:ChatPrint(find_error)
			return
		end
	end

	HMCDApplyProfessionSelection(ply, target_ply, profession_id)
end)

MODE.Type = MODE.Type or "standard"
MODE.Types = MODE.Types or {}
MODE.Types.standard = {
	Chance = 0.2,
	ChanceFunction = function() return zb.ModesChances["standard"] or zb.modes["hmcd"].Types.standard.Chance end,
	LootTable = MODE.LootTableStandard,
	Messages = {
		[3] = "Everyone died.",
		[1] = "The murderer has killed everyone.",
		[0] = "The murderer was",
	},
	Message = "The murderer was ",
	TraitorLoot = function(ply)
		ply:Give("weapon_buck200knife")
		ply:Give("weapon_hg_type59_tpik")
		ply:Give("weapon_adrenaline")
		ply:Give("weapon_hg_shuriken")
		ply:Give("weapon_hg_smokenade_tpik")
		ply:Give("weapon_traitor_ied")
		ply:Give("weapon_traitor_poison1")
		ply:Give("weapon_traitor_poison2")
		ply:Give("weapon_traitor_poison3")
		ply:Give("weapon_traitor_poison_consumable")
		ply:Give("weapon_traitor_suit")
		local wep = ply:Give("weapon_zoraki")
		timer.Simple(1,function() wep:ApplyAmmoChanges(2) end)

		ply.organism.stamina.range = 220

		local inv = ply:GetNetVar("Inventory")
		inv["Weapons"]["hg_flashlight"] = true
		ply:SetNetVar("Inventory",inv)
	end,
	GunManLoot = function(ply)
		ply:Give("weapon_px4beretta")
		ply.organism.recoilmul = 1
	end,
	PoliceTime = 220,
	SkillIssue = 4,
	PoliceAllowed = true,
	PoliceEquipment = function(ply)
		ply:SetPlayerClass("police")
		local glock = ply:Give("weapon_glock17")
		ply:GiveAmmo(glock:GetMaxClip1() * 3,glock:GetPrimaryAmmoType(),true)
		if math.random(0,1) then
			hg.AddAttachmentForce(ply,gun,"holo16")
		end

		if math.random(0,1) then
			hg.AddAttachmentForce(ply,gun,"laser3")
		end

		ply:Give("weapon_medkit_sh")
		ply:Give("weapon_walkie_talkie")
		ply:Give("weapon_naloxone")
		ply:Give("weapon_painkillers")
		ply:Give("weapon_handcuffs")
		ply:Give("weapon_handcuffs_key")
		ply:Give("weapon_hg_tonfa")
		
		local gun = ply:Give("weapon_taser")
		ply:GiveAmmo(gun:GetMaxClip1() * 3,gun:GetPrimaryAmmoType(),true)

		hg.AddArmor(ply, {"vest2"})

		local hands = ply:Give("weapon_hands_sh")
		ply:SetActiveWeapon( hands )

		local inv = ply:GetNetVar("Inventory")
		inv["Weapons"]["hg_flashlight"] = true
		ply:SetNetVar("Inventory",inv)
		ply.organism.recoilmul = 0.8

		ply:SetNetVar("CurPluv", "pluvberet")

		zb.GiveRole(ply, "Police Officer", Color(15,15,255))
	end
}
MODE.Types.wildwest = {
	Chance = 0.05,
	ChanceFunction = function() return zb.ModesChances["wildwest"] or zb.modes["hmcd"].Types.standard.Chance end,
	LootTable = MODE.LootTableStandard,
	Messages = {
		[3] = "The dead silence fills the empty city...",
		[1] = "The town has fallen into the hands of crime.",
		[0] = "The law was settled once again. The bastard is",
	},
	Message = "The criminal was ",
	TraitorLoot = function(ply)
		ply:Give("weapon_sogknife")
		ply:Give("weapon_hg_type59_tpik")
		ply:Give("weapon_adrenaline")
		local revolver = ply:Give(math.random(2) == 2 and "weapon_winchester" or "weapon_yellowboy")
		ply:GiveAmmo(revolver:GetMaxClip1() * 1,revolver:GetPrimaryAmmoType(),true)
		ply:Give("weapon_revolversw686")
		ply:Give("weapon_traitor_ied")
		ply:Give("weapon_hg_molotov_tpik")
		ply:Give("weapon_hg_smokenade_tpik")

		ply.organism.recoilmul = 1.0
		ply.organism.stamina.range = 220

		ply:SetNetVar("CurPluv", "pluvfancy")

		local inv = ply:GetNetVar("Inventory")
		inv["Weapons"]["hg_sling"] = true
		ply:SetNetVar("Inventory",inv)
	end,
    /*local tMdl = APmodule.PlayerModels[1][tbl.AModel] or APmodule.PlayerModels[2][tbl.AModel] or tbl.AModel
    ply:SetModel(istable(tMdl) and tMdl.mdl or tMdl)

    local clr = tbl.AColor
    if ply.SetPlayerColor then
        ply:SetPlayerColor(Vector(clr.r / 255,clr.g / 255,clr.b / 255))
    end
    ply:SetNWVector( "PlayerColor", Vector(clr.r / 255,clr.g / 255,clr.b / 255) )

    ply:SetSubMaterial()

    local mats = ply:GetMaterials()
    if istable(tMdl) then
        for k, v in pairs(tMdl.submatSlots) do
            local slot = 1
            for i = 1, #mats do
                if mats[i] == v then slot = i-1 break end
            end
            ply:SetSubMaterial(slot, hg.Appearance.Clothes[tMdl.sex and 2 or 1][tbl.AClothes[k]] )*/

	GunManLoot = function(ply)
		for k,v in player.Iterator() do
			timer.Simple(1,function()
				local Appearance = v:GetNetVar("Accessories",{"none"})
				if istable(Appearance) then
					Appearance[1] = "stetson"
				else
					Appearance = "stetson"
				end
				v:SetNetVar("Accessories", Appearance)
				local sex = ThatPlyIsFemale(v) and 2 or 1
				local tbl = v.CurAppearance
				tbl.AClothes["main"] = "formal"
				tbl.AClothes["pants"] = "formal"
				tbl.AClothes["boots"] = "formal"
				tbl.AColor = Color(1 * 255,0.690196 * 255,0.537255 * 255)
				hg.Appearance.ForceApplyAppearance(v,tbl)
				--v:SetSubMaterial(table.Flip(v:GetMaterials())[hg.Appearance.FuckYouModels[sex][v:GetModel()].submatSlots.main] - 1, hg.Appearance.Clothes[sex]["formal"])
				--v:SetPlayerColor(Vector(1,0.690196,0.537255))
			end)
			if v.isTraitor then continue end
			if v.isGunner then
				local shotgun = v:Give("weapon_ithaca37")
				v:GiveAmmo(shotgun:GetMaxClip1() * 1, shotgun:GetPrimaryAmmoType(), true)
				v:Give("weapon_revolvermodel29")
				v:Give("weapon_handcuffs")
				v:Give("weapon_handcuffs_key")
			else
				local guns = {
					"weapon_doublebarrel",
					"weapon_winchester",
					"weapon_yellowboy",
					"weapon_revolversw686"
				}

				local weapon = v:Give(guns[math.random(#guns)], true)
				weapon:SetClip1(weapon:GetMaxClip1())
				
				if IsValid(weapon) and weapon:GetClass() == "weapon_doublebarrel" then
    				v:GiveAmmo(2, weapon:GetPrimaryAmmoType(), true)
				end
			end

			v:SetNetVar("CurPluv", "pluvfancy")

			local inv = v:GetNetVar("Inventory")
			inv["Weapons"] = inv["Weapons"] or {}
			inv["Weapons"]["hg_sling"] = true
			v:SetNetVar("Inventory",inv)
		end
	end,
	PoliceTime = 220,
	PoliceAllowed = false,
	SkillIssue = 3,
	PoliceEquipment = function(ply)
		ply:SetPlayerClass("police")
		local glock = ply:Give("weapon_glock17")
		ply:GiveAmmo(glock:GetMaxClip1() * 3,glock:GetPrimaryAmmoType(),true)
		if math.random(0,1) then
			hg.AddAttachmentForce(ply,gun,"holo16")
		end

		if math.random(0,1) then
			hg.AddAttachmentForce(ply,gun,"laser3")
		end

		ply:Give("weapon_medkit_sh")
		ply:Give("weapon_walkie_talkie")
		ply:Give("weapon_naloxone")
		ply:Give("weapon_painkillers")
		ply:Give("weapon_handcuffs")
		ply:Give("weapon_handcuffs_key")
		ply:Give("weapon_hg_tonfa")

		local gun = ply:Give("weapon_taser")
		ply:GiveAmmo(gun:GetMaxClip1() * 3,gun:GetPrimaryAmmoType(),true)

		hg.AddArmor(ply, {"vest2"})

		local hands = ply:Give("weapon_hands_sh")
		ply:SetActiveWeapon( hands )

		local inv = ply:GetNetVar("Inventory")
		inv["Weapons"]["hg_flashlight"] = true
		ply:SetNetVar("Inventory",inv)

		ply:SetNetVar("CurPluv", "pluvberet")

		zb.GiveRole(ply, "Police Officer", Color(15,15,255))
	end
}

MODE.Types.gunfreezone = {
	Chance = 0.05,
	ChanceFunction = function() return zb.ModesChances["gunfreezone"] or zb.modes["hmcd"].Types.standard.Chance end,
	LootTable = MODE.LootTableStandard,
	Messages = {
		[3] = "Everyone died.",
		[1] = "The murderer has killed everyone.",
		[0] = "The murderer was",
	},
	Message = "The murderer was ",
	TraitorLoot = function(ply)
		ply:Give("weapon_buck200knife")
		ply:Give("weapon_hg_type59_tpik")
		ply:Give("weapon_adrenaline")
		ply:Give("weapon_hg_shuriken")
		ply:Give("weapon_hg_smokenade_tpik")
		ply:Give("weapon_traitor_ied")
		ply:Give("weapon_traitor_poison1")
		ply:Give("weapon_traitor_poison2")
		ply:Give("weapon_traitor_poison3")
		ply:Give("weapon_traitor_poison_consumable")
		ply:Give("weapon_traitor_suit")

		local wep = ply:Give("weapon_zoraki")
		timer.Simple(1,function() wep:ApplyAmmoChanges(2) end)

		ply.organism.stamina.range = 220

		local inv = ply:GetNetVar("Inventory")
		inv["Weapons"]["hg_flashlight"] = true
		ply:SetNetVar("Inventory",inv)
	end,
	GunManLoot = function(ply)
	end,
	PoliceTime = 120,
	PoliceAllowed = true,
	SkillIssue = 4,
	PoliceEquipment = function(ply)
		ply:SetPlayerClass("police")
		local glock = ply:Give("weapon_glock17")
		ply:GiveAmmo(glock:GetMaxClip1() * 3,glock:GetPrimaryAmmoType(),true)
		if math.random(0,1) then
			hg.AddAttachmentForce(ply,glock,"holo16")
		end

		if math.random(0,1) then
			hg.AddAttachmentForce(ply,glock,"laser3")
		end

		ply:Give("weapon_medkit_sh")
		ply:Give("weapon_walkie_talkie")
		ply:Give("weapon_naloxone")
		ply:Give("weapon_painkillers")
		ply:Give("weapon_handcuffs")
		ply:Give("weapon_handcuffs_key")
		ply:Give("weapon_hg_tonfa")

		local gun = ply:Give("weapon_taser")
		ply:GiveAmmo(gun:GetMaxClip1() * 3,gun:GetPrimaryAmmoType(),true)

		hg.AddArmor(ply, {"vest2"})

		local hands = ply:Give("weapon_hands_sh")
		ply:SetActiveWeapon( hands )

		local inv = ply:GetNetVar("Inventory")
		inv["Weapons"]["hg_flashlight"] = true
		ply:SetNetVar("Inventory",inv)
		ply.organism.recoilmul = 0.8

		zb.GiveRole(ply, "Police Officer", Color(15,15,255))

		ply:SetNetVar("CurPluv", "pluvberet")
	end
}

MODE.Types.soe = {
	Chance = 0.2,
	ChanceFunction = function() return zb.ModesChances["soe"] or zb.modes["hmcd"].Types.standard.Chance end,
	LootTable = MODE.LootTable,
	Messages = {
		[3] = "Everyone died.",
		[1] = "The traitor has killed everyone.",
		[0] = "The traitor was",
	},
	Message = "The traitor was ",
	TraitorLoot = function(ply)
		local p22 = ply:Give("weapon_p22")
		hg.AddAttachmentForce(ply,p22,"supressor4")
		ply:Give("weapon_sogknife")
		ply:Give("weapon_hg_type59_tpik")
		ply:Give("weapon_walkie_talkie")
		ply:Give("weapon_adrenaline")
		ply:Give("weapon_hg_smokenade_tpik")
		ply:Give("weapon_traitor_ied")
		ply:Give("weapon_traitor_poison2")
		ply:Give("weapon_traitor_poison3")
		ply:Give("weapon_traitor_poison_consumable")
		ply.organism.recoilmul = 1
		ply.organism.stamina.range = 220

		local inv = ply:GetNetVar("Inventory")
		inv["Weapons"]["hg_flashlight"] = true
		ply:SetNetVar("Inventory",inv)
	end,
	GunManLoot = function(ply)
		local gun = ply:Give( ( math.random(1,2) > 1 and "weapon_remington870" ) or "weapon_kar98" )
		ply.organism.recoilmul = 1.0
		if gun:GetClass() == "weapon_kar98" then
			hg.AddAttachmentForce(ply,gun,"optic12")
		end
		local inv = ply:GetNetVar("Inventory")
		inv["Weapons"]["hg_sling"] = true
		ply:SetNetVar("Inventory",inv)

		ply:SetNetVar("CurPluv", "pluvboss")
	end,
	PoliceTime = 250,
	PoliceAllowed = true,
	SkillIssue = 3,
	PoliceEquipment = function(ply)
		local inv = ply:GetNetVar("Inventory") or {}
		inv["Weapons"] = inv["Weapons"] or {}
		inv["Weapons"]["hg_flashlight"] = true
		inv["Weapons"]["hg_sling"] = true
		ply:SetNetVar("Inventory", inv)
	
		ply:SetPlayerClass("nationalguard")
		local gun = ply:Give("weapon_fn45")
		ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)
	
		gun = ply:Give("weapon_hk416")
		ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)
		hg.AddAttachmentForce(ply, gun, {"holo14", "laser3", "grip3"})
	
		ply:Give("weapon_hg_grenade_tpik")
		ply:Give("weapon_melee")
	
		ply:Give("weapon_medkit_sh")
		ply:Give("weapon_bandage_sh")
		ply:Give("weapon_walkie_talkie")
		ply:Give("weapon_painkillers")
		ply:Give("weapon_morphine")
	
		ply.organism.recoilmul = 0.5
	
		ply:Give("weapon_handcuffs")
		ply:Give("weapon_handcuffs_key")
	
		gun = ply:Give("weapon_taser")
		ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)
	
		hg.AddArmor(ply, {"vest4", "helmet1"})
	
		local hands = ply:Give("weapon_hands_sh")
		ply:SetActiveWeapon(hands)
	
		zb.GiveRole(ply, "National Guard", Color(55, 85, 0))
		ply:SetNetVar("CurPluv", "pluvberet")
	end,
	PoliceText = "National guards have arrived.",
	PoliceSound = "snd_jack_hmcd_heli2.mp3"
}

local modes = {
	"soe",
	"standard",
	"wildwest",
	"gunfreezone",
}

util.AddNetworkString("HMCD_RoundStart")

function MODE:GetPlySpawn(ply)
end

function MODE:SubModes()
	return modes
end

local homicide_traitoramount = ConVarExists("homicide_traitoramount") and GetConVar("homicide_traitoramount") or CreateConVar("homicide_traitoramount", 1, FCVAR_SERVER_CAN_EXECUTE + FCVAR_ARCHIVE, "Homicide Only: Determine how many traitors should innocents face in homicide.", 1, 20)

local function HMCDRestoreRoundAppearance(ply)
	local appearanceApi = hg and hg.Appearance
	local validate = appearanceApi and appearanceApi.AppearanceValidater
	local appearance = ply.CachedAppearance

	if not (istable(appearance) and validate and validate(appearance)) then
		appearance = ply.CurAppearance
	end

	if istable(appearance) and validate and validate(appearance) and appearanceApi.ForceApplyAppearance then
		appearanceApi.ForceApplyAppearance(ply, table.Copy(appearance))
	elseif ApplyAppearance then
		ApplyAppearance(ply, nil, nil, nil, true)
	end
end

function MODE:Intermission()
	game.CleanUpMap()

	local _, CROUND = CurrentRound()

	if not CROUND or CROUND == "hmcd" then
		CROUND = table.Random(self:SubModes())
	end

	self.Type = CROUND

	local player_count = 0

	for k, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		MODE.ClearProfessionLoadout(ply)
		MODE.ResetProfessionStats(ply)
		if ply.PlayerClassName and ply.PlayerClassName ~= "none" then
			ply:SetPlayerClass()
		end
		ply:KillSilent()

		ply.isPolice = false
		ply.isTraitor = false
		ply.isGunner = false
		ply.MainTraitor = false
		ply.SubRole = nil
		ply.Profession = nil

		ply:SetupTeam(0)

		if(ply.organism)then
			ply.organism.recoilmul = DefaultSkillIssue
		end
		player_count = player_count + 1
	end

	MODE.TraitorFrequency = nil
	MODE.TraitorWord = MODE.TraitorWords[math.random(1, #MODE.TraitorWords)]
	MODE.TraitorWordSecond = MODE.TraitorWords[math.random(1, #MODE.TraitorWords)]
	
	local traitors_needed = 1 + math.floor(player_count / 15)

	MODE.TraitorExpectedAmt = traitors_needed
	
	local main_traitor = nil
	local traitors = {}

	local function CanPickTraitor(ply, allow_disabled)
		if ply.isTraitor or ply:Team() == TEAM_SPECTATOR then return false end
		if not allow_disabled then
			if not ply.HMCDTraitorRolePreferencesReady then return false end
			if HMCDPlayerDisabledTraitorMode(ply, self.Type) then return false end
		end

		return true
	end

	-- local players = {}
	-- for i, ply in player.Iterator() do
	-- 	if ply.isTraitor or ply:Team() == TEAM_SPECTATOR then continue end

	-- 	players[#players + 1] = {ply, ply.Karma}
	-- end
	
	-- -- potom
	
	for i, ply in RandomPairs(player.GetAll()) do
		if not CanPickTraitor(ply, false) then continue end
		if math.random(100) > (ply.Karma or 100) then continue end

		if traitors_needed > 0 then
			ply.isTraitor = true
			traitors_needed = traitors_needed - 1
			traitors[#traitors + 1] = ply

			main_traitor = ply
			ply.MainTraitor = true
		end
	end

	--MODE.NextRoundMainTraitors = MODE.NextRoundMainTraitors or {}
	for i, ply in RandomPairs(player.GetAll()) do
		if not CanPickTraitor(ply, false) then continue end
		--if not MODE.NextRoundMainTraitors[ply:SteamID()] then continue end

		if traitors_needed > 0 then
			ply.isTraitor = true
			traitors_needed = traitors_needed - 1
			traitors[#traitors + 1] = ply
			
			if not main_traitor then
				main_traitor = ply
				ply.MainTraitor = true
			end
		end
	end

	if traitors_needed > 0 then
		for i, ply in RandomPairs(player.GetAll()) do
			if not CanPickTraitor(ply, true) then continue end

			if traitors_needed > 0 then
				ply.isTraitor = true
				traitors_needed = traitors_needed - 1
				traitors[#traitors + 1] = ply

				if not main_traitor then
					main_traitor = ply
					ply.MainTraitor = true
				end
			end
		end
	end

	self.saved.PoliceTime = CurTime() + math.min(self.Types[self.Type].PoliceTime * (#player.GetAll() / 4),self.Types[self.Type].PoliceTime * 2.2)
	self.PoliceSpawned = false
	self.PoliceAllowed = self.Types[self.Type].PoliceAllowed

	for k, ply in player.Iterator() do
		if(MODE.ShouldStartRoleRound())then
			net.Start("HMCD_RoundStart")	--; TODO Structure description
				net.WriteBool(ply.isTraitor)	--; Is Traitor
				net.WriteBool(ply.isGunner)	--; Is Gunner
				net.WriteString(self.Type)	--; Round Type
				net.WriteBool(false)	--; Round Started
				net.WriteString("")	--; SubRole
				net.WriteBool(ply.MainTraitor == true)	--; MainTraitor

				if(ply.isTraitor)then
					net.WriteString(MODE.TraitorWord)
					net.WriteString(MODE.TraitorWordSecond)
					net.WriteUInt(MODE.TraitorExpectedAmt, MODE.TraitorExpectedAmtBits)
				else
					net.WriteString("")
					net.WriteString("")
					net.WriteUInt(0, MODE.TraitorExpectedAmtBits)
				end
				
				net.WriteString("")	--; Profession
			net.Send(ply)

			local role = self.Roles[self.Type][(ply.isTraitor and "traitor") or (ply.isGunner and "gunner") or "innocent"]

			zb.GiveRole(ply, role.name, role.color)
		end
	end

	--local pts = zb.GetMapPoints( "RandomSpawns" )
	
	local ent = ents.Create("prop_ragdoll")
	local appearance = hg.Appearance.GetRandomAppearance()
	
	local tMdl = hg.Appearance.PlayerModels[1][appearance.AModel] or hg.Appearance.PlayerModels[2][appearance.AModel] or appearance.AModel
	local mdl = istable(tMdl) and tMdl.mdl or tMdl
	
	ent:SetModel(mdl)
	
	for i, ply in RandomPairs(player.GetAll()) do
		ent:SetPos(ply:EyePos() + vector_up * 72)
	end

	--[[local forced = false
	local cntr = 32
	for i, point in RandomPairs(pts) do
		cntr = cntr - 1
		if cntr < 0 then forced = true end

		local pos = point.pos
		local tr = {}
		tr.start = pos
		tr.endpos = pos
		tr.mins = Vector(-16, -16, 0)
		tr.maxs = Vector(16, 16, 16)
		tr.collisiongroup = COLLISION_GROUP_WORLD

		local trace = util.TraceHull(tr)
		if !trace.Hit or forced then
			ent:SetPos(pos)
			
			break
		end
	end--]]

	ent:SetAngles(AngleRand(-180, 180))
	ent:Spawn()
	ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	hg.organism.Add(ent)
	hg.organism.Clear(ent.organism)
	ent.organism.fakePlayer = true
	hg.Appearance.ForceApplyAppearance(ent, appearance)
	ent.organism.alive = false
	ent.organism.o2[1] = 0
	ent.organism.pulse = 0

	for physNum = 0, ent:GetPhysicsObjectCount() - 1 do
		local phys = ent:GetPhysicsObjectNum(physNum)
		local bone = ent:TranslatePhysBoneToBone(physNum)
		if bone < 0 then continue end
		
		phys:SetMass(hg.IdealMassPlayer[ent:GetBoneName(bone)] or 4)
		phys:SetPos(ent:GetPos() + VectorRand(-32, 32))
	end

	if self.Type == "wildwest" then
		local Appearance = ent:GetNetVar("Accessories", {"none"})

		if istable(Appearance) then
			Appearance[1] = "stetson"
		else
			Appearance = "stetson"
		end
	
		ent:SetNetVar("Accessories", Appearance)
		local sex = ThatPlyIsFemale(ent) and 2 or 1
		local tbl = ent.CurAppearance
		tbl.AClothes["main"] = "formal"
		tbl.AClothes["pants"] = "formal"
		tbl.AClothes["boots"] = "formal"
		tbl.AColor = Color(1 * 255,0.690196 * 255,0.537255 * 255)
		hg.Appearance.ForceApplyAppearance(ent, tbl)

		for i = 1, 5 do
			hg.organism.AddWoundManual(ent, 50, vector_origin, angle_zero,"ValveBiped.Bip01_Head1", CurTime() + 2)
		end
	end
end

--[[concommand.Add("hmcd_call_police", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsAdmin() then
        ply:ChatPrint("loh.")
        return
    end

    if not MODE or not MODE.saved then
        print("fake")
        return
    end

    MODE.saved.PoliceTime = CurTime() - 1
    print("true")
end)--]]

function MODE:CheckAlivePlayers()
	local AlivePlyTbl = {
		[0] = {},
		[1] = {}
	}
	
	for _, ply in player.Iterator() do
		if not zb:CanActivelyParticipate(ply) then
			continue
		end
		
		if ply.isTraitor and not ply:GetNetVar("handcuffed",false) then
			--print(ply)
			AlivePlyTbl[1][#AlivePlyTbl[1] + 1] = ply
		elseif(not ply.isPolice)then
			AlivePlyTbl[0][#AlivePlyTbl[0] + 1] = ply
		end
	end
	
	return AlivePlyTbl
end
	
local deadPoliceCount = 0
local swatDeployed = false

function MODE:GetActivePlayers()
	local valid = {}

	for _, ply in player.Iterator() do
		if ply:Alive() then continue end                        
		if ply:Team() == TEAM_SPECTATOR then continue end       
		if ply.afkTime2 and ply.afkTime2 > 60 then continue end 

		valid[#valid + 1] = ply
	end

	return valid
end


MODE.deadPoliceCount = MODE.deadPoliceCount or 0
MODE.swatDeployed = MODE.swatDeployed or false
MODE.spawnedPoliceCount = MODE.spawnedPoliceCount or 0
MODE.roundStartType = MODE.roundStartType or nil

function MODE:RoundThink()
	if not self.PoliceAllowed then return end

	if self.Type ~= "soe" and not self.PoliceSpawned and self.saved.PoliceTime < CurTime() then
		if not self.Types[self.Type] or not self.Types[self.Type].PoliceAllowed then return end
		
		local available = self:GetActivePlayers()
		local max = math.min(#available, 8)
	
		if max > 0 then
			local spawned = self:SpawnForce("police", max)
			self.spawnedPoliceCount = spawned
	
			if spawned > 0 then
				self.PoliceSpawned = true
				PrintMessage(HUD_PRINTTALK, "Police have arrived.")
				EmitSound("snd_jack_hmcd_policesiren.wav", vector_origin, 0, CHAN_AUTO, 1, 125, 0, 100)
			end
		end
	end
	

	if self.Type ~= "soe" and not self.swatDeployed and self.deadPoliceCount >= (self.spawnedPoliceCount or 4) and self.spawnedPoliceCount > 0 then
		if not self.Types[self.Type] or not self.Types[self.Type].PoliceAllowed then return end
		
		self.swatDeployed = true
		local currentType = self.Type 
		
		timer.Create("HMCDSpawnSWAT", 60, 1, function()
			if zb.ROUND_STATE ~= 1 or not MODE or MODE.Type ~= currentType then return end 
			
			if not MODE.Types[MODE.Type] or not MODE.Types[MODE.Type].PoliceAllowed then return end
			
			local available = MODE:GetActivePlayers()
			local count = math.min(#available, 8)
	
			if count > 0 then
				PrintMessage(HUD_PRINTTALK, "SWAT team incoming!")
				EmitSound("snd_jack_hmcd_heli2.mp3", vector_origin, 0, CHAN_AUTO, 1, 125, 0, 100)
				MODE:SpawnForce("swat", count)
			end
		end)
	end
	
	if self.Type == "soe" and not self.PoliceSpawned and self.saved.PoliceTime < CurTime() then
		local available = self:GetActivePlayers()
		local count = math.min(#available, 8)
	
		if count > 0 then
			local spawned = self:SpawnForce("nationalguard", count)
			if spawned > 0 then
				self.PoliceSpawned = true
				PrintMessage(HUD_PRINTTALK, self.Types[self.Type].PoliceText or "National Guard have arrived.")
				EmitSound(self.Types[self.Type].PoliceSound or "snd_jack_hmcd_heli2.mp3", vector_origin, 0, CHAN_AUTO, 1, 125, 0, 100)
			end
		end
	end
end

function MODE:SpawnForce(teamtype, count)
    local spawned = 0
    local basepos = nil

    for i, ply in RandomPairs(player.GetAll()) do
        if ply:Alive() or ply.isTraitor or ply:Team() == TEAM_SPECTATOR or ply.afkTime2 > 60 then continue end
        if spawned >= count then break end

        ply.isPolice = true
        ply.isTraitor = false
        ply.isGunner = false
        ply:Spawn()

        if not basepos then
            basepos = zb:GetRandomSpawn()            
			ply:SetPos(basepos)
		else
			hg.tpPlayer(basepos, ply, i)
		end

        if teamtype == "police" then
            self.Types[self.Type].PoliceEquipment(ply)
        elseif teamtype == "swat" then
            self:EquipSWAT(ply, spawned + 1)
        elseif teamtype == "nationalguard" then
            self:EquipNationalGuard(ply, spawned + 1)
        end

        spawned = spawned + 1
    end

    return spawned
end

local function tbl_Random(tbl) -- when you can't even say
	return tbl[math.random(#tbl)] -- my name
end
function MODE:EquipSWAT(ply, index)
    ply:SetPlayerClass("swat")
    
    local classes = {
        [1] = function() return tbl_Random({"weapon_m4a1", "weapon_hk416"}) end, --;; Team Leader
        [2] = function() ply:Give("weapon_ram") return tbl_Random({"weapon_remington870", "weapon_m590a1"}) end, --;; Breacher
        [3] = function() return "weapon_mp5" end, --;; Pointman
        [4] = function() return "weapon_sr25" end, --;; Marksman
        [5] = function()
            ply:Give("weapon_medkit_sh")
            ply:Give("weapon_painkillers")
            ply:Give("weapon_adrenaline")
            ply:Give("weapon_needle")
            ply:Give("weapon_bigbandage_sh")
            ply:Give("weapon_bandage_sh")
            ply:Give("weapon_mannitol")
            return "weapon_m4a1"
        end
    }

    local mainWep = classes[index] and classes[index]() or "weapon_m4a1"
    local pistol = ply:Give("weapon_glock17")
	ply:GiveAmmo(pistol:GetMaxClip1() * 3, pistol:GetPrimaryAmmoType(), true)
    local gun = ply:Give(mainWep)
    ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)

    ply:Give("weapon_melee")
    ply:Give("weapon_handcuffs")
    ply:Give("weapon_handcuffs_key")
    ply:Give("weapon_hg_flashbang_tpik")

	local gun = ply:Give("weapon_taser")
	ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(),true)

	hg.AddArmor(ply, {"helmet6", "vest8", tbl_Random({"mask1", "mask2", "nightvision1"})})

    local inv = ply:GetNetVar("Inventory") or {}
    inv["Weapons"] = inv["Weapons"] or {}
	inv["Weapons"]["hg_sling"] = true
    inv["Weapons"]["hg_flashlight"] = true
    ply:SetNetVar("Inventory", inv)
	ply:SetNetVar("flashlight", false)

    ply.organism.recoilmul = 0.6

    ply:SetNetVar("CurPluv", "pluvberet")
    local hands = ply:Give("weapon_hands_sh")
    ply:SetActiveWeapon(hands)

    zb.GiveRole(ply, "SWAT Operative", Color(30, 30, 100))
end

function MODE:EquipNationalGuard(ply, index)
    ply:SetPlayerClass("nationalguard")
    local gun

    if index == 1 then
        gun = ply:Give("weapon_m249")
    else
        gun = ply:Give("weapon_m4a1")
    end

    ply:GiveAmmo(gun:GetMaxClip1() * 3, gun:GetPrimaryAmmoType(), true)
	local pistol = ply:Give("weapon_m9beretta")
	ply:GiveAmmo(pistol:GetMaxClip1() * 3, pistol:GetPrimaryAmmoType(), true)
    ply:Give("weapon_melee")
    ply:Give("weapon_handcuffs")
    ply:Give("weapon_handcuffs_key")
    ply:Give("weapon_walkie_talkie")
    ply:Give("weapon_bandage_sh")
    ply:Give("weapon_medkit_sh")

	local gun = ply:Give("weapon_taser")
	ply:GiveAmmo(gun:GetMaxClip1() * 3,gun:GetPrimaryAmmoType(),true)

    hg.AddArmor(ply, {"vest4", "helmet1"})

	local inv = ply:GetNetVar("Inventory") or {}
	inv["Weapons"] = inv["Weapons"] or {}
	inv["Weapons"]["hg_flashlight"] = true
	inv["Weapons"]["hg_sling"] = true
	ply:SetNetVar("Inventory", inv)

	ply:SetNetVar("CurPluv", "pluvberet")
    local hands = ply:Give("weapon_hands_sh")
    ply:SetActiveWeapon(hands)
    zb.GiveRole(ply, "National Guard", Color(60, 90, 0))
end

--\\
MODE.ChoosingPlayersList = MODE.ChoosingPlayersList or {}

local gaymaps = {
	["zs_shelter"] = true,
	["gm_sirenmine_v2"] = true,
}

function MODE:PrepareTraitorRoleSelections()
	MODE.ChoosingPlayersList = {}

	for _, ply in player.Iterator() do
		if(ply.isTraitor and ply.MainTraitor)then	--; REDO
			net.Start("HMCD(StartPlayersRoleSelection)")
				net.WriteString("Traitor")
			net.Send(ply)

			MODE.ChoosingPlayersList[ply] = true
		end
	end
end

net.Receive("HMCD(StartPlayersRoleSelection)", function(len, ply)
	if(MODE.ChoosingPlayersList[ply])then
		MODE.ChoosingPlayersList[ply] = nil

		if(table.IsEmpty(MODE.ChoosingPlayersList))then
			MODE.StartRoundTime = 0
		end
	end
end)
-- ...


util.AddNetworkString("HMCD_TraitorDeathState")
util.AddNetworkString("HMCD_RequestTraitorStatuses")

local TRAITOR_RADIO_CLASS = "weapon_walkie_talkie"

local function HMCDGetTraitorRadioFrequency(radio)
	local blockedFrequencies = radio.FMStations or {}
	local publicFrequencies = radio.Frequencies or {}
	local availableFrequencies = {}
	local currentFrequency = math.Round(tonumber(MODE.TraitorFrequency) or 0, 1)

	for i = 1, #publicFrequencies do
		local frequency = math.Round(tonumber(publicFrequencies[i]) or 0, 1)
		if frequency >= 87.5 and frequency <= 108 and not blockedFrequencies[frequency] then
			availableFrequencies[#availableFrequencies + 1] = frequency

			if frequency == currentFrequency then
				return currentFrequency
			end
		end
	end

	local frequency
	if #availableFrequencies > 0 then
		frequency = availableFrequencies[math.random(#availableFrequencies)]
	else
		frequency = math.Round(tonumber(radio.Frequency) or 88.6, 1)
	end

	MODE.TraitorFrequency = frequency

	return frequency
end

local function HMCDConfigureTraitorRadio(ply)
	if not IsValid(ply) or not ply.isTraitor or ply:Team() == TEAM_SPECTATOR then return end

	local radio = ply:GetWeapon(TRAITOR_RADIO_CLASS)
	if not IsValid(radio) then
		radio = ply:Give(TRAITOR_RADIO_CLASS)
	end
	if not IsValid(radio) then return end

	local frequency = HMCDGetTraitorRadioFrequency(radio)
	radio.Frequency = frequency
	radio:SetHudFrequency(frequency)
	radio.isOn = true
	radio:SetIsOn(true)
	radio:SetInUsing(false)

	local roundStamp = zb.ROUND_BEGIN or 0
	if ply.HMCDTraitorRadioNoticeRound ~= roundStamp then
		ply.HMCDTraitorRadioNoticeRound = roundStamp
		ply:ChatPrint("Traitor radio online: " .. string.format("%.1f MHz", frequency))
	end
end


function MODE:SendTraitorDeathState(traitor, is_alive)
    if not traitor.CurAppearance then return end
    local name = traitor.CurAppearance.AName
    

    local recipients = {}
    for _, ply in player.Iterator() do
        if ply.isTraitor and ply.MainTraitor then
            table.insert(recipients, ply)
        end
    end
    
    net.Start("HMCD_TraitorDeathState")
    net.WriteString(name)
    net.WriteBool(is_alive)
    net.Send(recipients)
end


hook.Add("PlayerDeath", "HMCD_TraitorDeathTracking", function(ply, _)
    if ply.isTraitor then
        MODE:SendTraitorDeathState(ply, false)
    end

	if ply.Profession then
		MODE.ClearProfessionLoadout(ply)
		ply.Profession = nil
		MODE.ResetProfessionStats(ply)
		MODE.SyncProfession(ply)
	end
end)


hook.Add("PlayerSpawn", "HMCD_TraitorSpawnTracking", function(ply)
    if ply.isTraitor then
        MODE:SendTraitorDeathState(ply, true)
    end
end)

hook.Add("Player Spawn", "HMCD_TraitorRadioSpawn", function(ply)
	if zb.ROUND_STATE ~= 1 or CurrentRound() ~= MODE or not ply.isTraitor then return end

	timer.Simple(0, function()
		if not IsValid(ply) or zb.ROUND_STATE ~= 1 or CurrentRound() ~= MODE then return end

		HMCDConfigureTraitorRadio(ply)
	end)
end)

hook.Add("PlayerCanPickupWeapon", "HMCD_TraitorRadioPickup", function( ply, weapon )
    if ply.isTraitor and weapon:GetClass() == "weapon_walkie_talkie" then
        if ply:HasWeapon("weapon_walkie_talkie") then
            weapon:Remove()
			local radio = ply:GetWeapon("weapon_walkie_talkie")
			if IsValid(radio) then
				ply:SetActiveWeapon(radio)
			end
			ply:ChatPrint("You hide the additional walkie talkie.")

			return false
        end
    end
end)

net.Receive("HMCD_RequestTraitorStatuses", function(len, ply)
    if not ply.isTraitor or not ply.MainTraitor then return end
    
    MODE:SendTraitorAssistants(ply)

    for _, other_ply in player.Iterator() do
        if other_ply.isTraitor and other_ply.CurAppearance then
            local is_alive = other_ply:Alive() and (not other_ply.organism or not other_ply.organism.incapacitated)
            
            net.Start("HMCD_TraitorDeathState")
            net.WriteString(other_ply.CurAppearance.AName)
            net.WriteBool(is_alive)
            net.Send(ply)
        end
    end
end)
-- ...

function MODE.ShouldStartRoleRound()
	do return false end
	return MODE.RoleChooseRoundTypes[MODE.Type] and GetGlobalBool("RolesPlus_Enable", false)
end
--

MODE.TraitorKilledRoundEndDelay = MODE.TraitorKilledRoundEndDelay or 15
MODE.TraitorNeutralizationStart = MODE.TraitorNeutralizationStart or nil

local function HMCDTraitorIsDeadForRound(ply)
	if not ply:Alive() then return true end

	local org = ply.organism
	if org and org.alive == false then return true end

	return false
end

local function HMCDTraitorAliveNeutralized(ply)
	if HMCDTraitorIsDeadForRound(ply) then return false end

	return ply:GetNetVar("handcuffed", false) or not zb:CanActivelyParticipate(ply)
end

function MODE:RoundHasTraitors()
	for _, ply in player.Iterator() do
		if ply.isTraitor and ply:Team() ~= TEAM_SPECTATOR then
			return true
		end
	end

	return false
end

function MODE:TraitorNeutralizedDelayActive()
	if not self:RoundHasTraitors() then
		self.TraitorNeutralizationStart = nil
		return false
	end

	local latest = nil

	for _, ply in player.Iterator() do
		if not ply.isTraitor or ply:Team() == TEAM_SPECTATOR then continue end

		if not HMCDTraitorIsDeadForRound(ply)
			and not ply:GetNetVar("handcuffed", false)
			and zb:CanActivelyParticipate(ply) then
			self.TraitorNeutralizationStart = nil
			return false
		end

		if HMCDTraitorAliveNeutralized(ply) then
			ply.HMCD_TraitorNeutralizedAt = ply.HMCD_TraitorNeutralizedAt or CurTime()
			latest = math.max(latest or 0, ply.HMCD_TraitorNeutralizedAt)
		else
			ply.HMCD_TraitorNeutralizedAt = nil
		end
	end

	if not latest then
		self.TraitorNeutralizationStart = nil
		return false
	end

	self.TraitorNeutralizationStart = latest
	return (CurTime() - latest) < self.TraitorKilledRoundEndDelay
end

function MODE:ShouldRoundEnd()
	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())

	if endround and winner == 0 and self:RoundHasTraitors() and self:TraitorNeutralizedDelayActive() then
		return false
	end

	if(endround)then
		MODE.ChoosingPlayersList = {}
	end

	return endround
end

function MODE:RoundStart()
	local roles_choose = MODE.ShouldStartRoleRound()
	MODE.StartRoundTime = nil
	MODE.RoleChooseRound = roles_choose and true or false
	MODE.HMCDTraitorRoleStatsRecorded = false
	MODE.HMCDRoundKillStamp = (MODE.HMCDRoundKillStamp or 0) + 1
	

	self.roundStartType = self.Type
	MODE.TraitorNeutralizationStart = nil

	for _, ply in player.Iterator() do
		ply.HMCD_TraitorNeutralizedAt = nil
		ply.HMCDRoundKillCount = 0
		ply.HMCDRoundWasTraitor = ply.isTraitor == true
	end
	

	self.deadPoliceCount = 0
	self.swatDeployed = false
	self.spawnedPoliceCount = 0
	

	timer.Remove("HMCDSpawnSWAT")
	
	MODE.ChoosingPlayersList = {}
	if roles_choose then
		self:PrepareTraitorRoleSelections()
	end

	MODE.SpawnPlayers(true)
end

function MODE:GiveEquipment()
end

function MODE:CanSpawn()
end

util.AddNetworkString("hmcd_roundend")
util.AddNetworkString("HMCD_TraitorRoundSummary")

local function HMCDRoundKillPlayer(ent)
	if IsValid(ent) and ent:IsPlayer() then return ent end

	if IsValid(ent) and hg and hg.RagdollOwner then
		local owner = hg.RagdollOwner(ent)
		if IsValid(owner) and owner:IsPlayer() then return owner end
	end

	if IsValid(ent) and ent.GetOwner then
		local owner = ent:GetOwner()
		if IsValid(owner) and owner:IsPlayer() then return owner end
	end

	if IsValid(ent) and ent.GetParent then
		local parent = ent:GetParent()
		if IsValid(parent) and parent:IsPlayer() then return parent end
	end
end

local function HMCDResolveExecutionAttacker(victim)
	for _, ply in player.Iterator() do
		if ply == victim then continue end

		local neckData = ply.Ability_NeckBreak
		if not istable(neckData) or neckData.Victim ~= victim then continue end

		local action = tostring(neckData.Action or "neck_break")
		if action == "neck_break" or action == "saw_head" then
			return ply
		end
	end
end

local function HMCDResolveHarmAttacker(victim)
	local bestAttacker
	local bestHarm = 0

	for attacker, harm in pairs((zb.HarmDone and zb.HarmDone[victim]) or {}) do
		local playerAttacker = HMCDRoundKillPlayer(attacker)
		local amount = tonumber(harm) or 0

		if IsValid(playerAttacker) and playerAttacker ~= victim and amount > bestHarm then
			bestAttacker = playerAttacker
			bestHarm = amount
		end
	end

	return bestAttacker
end

local function HMCDCreditRoundKill(victim, attacker, roundStamp)
	attacker = HMCDRoundKillPlayer(attacker)
	if not IsValid(victim) or not IsValid(attacker) or attacker == victim then return false end
	if not attacker.HMCDRoundWasTraitor and attacker.isTraitor ~= true then return false end
	if victim.HMCDRoundKillRecorded == roundStamp then return false end

	attacker.HMCDRoundWasTraitor = true
	victim.HMCDRoundKillRecorded = roundStamp
	attacker.HMCDRoundKillCount = math.max(0, attacker.HMCDRoundKillCount or 0) + 1

	return true
end

local function HMCDTryCreditRoundKill(victim, roundStamp, ...)
	for index = 1, select("#", ...) do
		local candidate = select(index, ...)
		if HMCDCreditRoundKill(victim, candidate, roundStamp) then
			return true
		end
	end

	return false
end

hook.Add("PlayerDeath", "HMCD_RoundTraitorKillCount", function(victim, inflictor, attacker)
	local round = CurrentRound and CurrentRound()
	if round ~= MODE or zb.ROUND_STATE ~= 1 then return end

	local roundStamp = MODE.HMCDRoundKillStamp or 0
	if HMCDTryCreditRoundKill(
		victim,
		roundStamp,
		attacker,
		inflictor,
		HMCDResolveExecutionAttacker(victim),
		HMCDResolveHarmAttacker(victim)
	) then
		return
	end

	timer.Simple(0.12, function()
		if not IsValid(victim) or victim.HMCDRoundKillRecorded == roundStamp then return end

		HMCDTryCreditRoundKill(
			victim,
			roundStamp,
			HMCDResolveExecutionAttacker(victim),
			HMCDResolveHarmAttacker(victim)
		)
	end)
end)

hook.Add("Player_Death", "HMCD_RoundTraitorKillCountHomigrad", function(victim, attacker)
	local round = CurrentRound and CurrentRound()
	if round ~= MODE or zb.ROUND_STATE ~= 1 then return end

	local roundStamp = MODE.HMCDRoundKillStamp or 0
	HMCDTryCreditRoundKill(
		victim,
		roundStamp,
		attacker,
		HMCDResolveExecutionAttacker(victim),
		HMCDResolveHarmAttacker(victim)
	)
end)

local function HMCDBuildTraitorPortraitSnapshot(ply)
	local snapshot = {
		model = ply:GetModel() or "models/player/group01/male_07.mdl",
		skin = math.Clamp(ply:GetSkin() or 0, 0, 255),
		modelScale = math.Clamp(ply:GetModelScale() or 1, 0.05, 10),
		playerColor = ply.GetPlayerColor and ply:GetPlayerColor() or Vector(1, 1, 1),
		bodygroups = {},
		subMaterials = {},
		accessories = {}
	}

	for _, bodygroup in ipairs(ply:GetBodyGroups() or {}) do
		if #snapshot.bodygroups >= 31 then break end
		snapshot.bodygroups[#snapshot.bodygroups + 1] = {
			id = math.Clamp(bodygroup.id or 0, 0, 255),
			value = math.Clamp(ply:GetBodygroup(bodygroup.id or 0), 0, 255)
		}
	end

	for materialIndex = 0, math.min(#(ply:GetMaterials() or {}) - 1, 63) do
		local subMaterial = ply:GetSubMaterial(materialIndex)
		if isstring(subMaterial) and subMaterial ~= "" then
			snapshot.subMaterials[#snapshot.subMaterials + 1] = {
				index = materialIndex,
				material = string.sub(subMaterial, 1, 192)
			}
		end
	end

	local accessories = ply.GetNetVar and ply:GetNetVar("Accessories")
	if istable(accessories) then
		for _, accessory in ipairs(accessories) do
			if #snapshot.accessories >= 7 then break end
			if isstring(accessory) and accessory ~= "" then
				snapshot.accessories[#snapshot.accessories + 1] = string.sub(accessory, 1, 96)
			end
		end
	elseif isstring(accessories) and accessories ~= "" then
		snapshot.accessories[1] = string.sub(accessories, 1, 96)
	end

	return snapshot
end

local function HMCDBuildTraitorRoundSummary(traitors)
	local summary = {}

	for _, traitor in ipairs(traitors) do
		if not IsValid(traitor) then continue end

		local subRole = MODE.NormalizeTraitorSubRole and MODE.NormalizeTraitorSubRole(traitor.SubRole) or traitor.SubRole
		local roleInfo = isstring(subRole) and MODE.SubRoles[subRole]
		local appearance = traitor.CurAppearance or {}
		local characterName = appearance.AName
			or (traitor.GetPlayerName and traitor:GetPlayerName())
			or traitor:Nick()
			or "Unknown"

		summary[#summary + 1] = {
			ply = traitor,
			characterName = tostring(characterName),
			nick = tostring(traitor:Nick() or "Unknown"),
			roleKey = isstring(subRole) and subRole or "",
			roleName = roleInfo and roleInfo.Name or (traitor.MainTraitor and "Traitor" or "Accomplice"),
			kills = math.Clamp(math.floor(tonumber(traitor.HMCDRoundKillCount) or 0), 0, 4095),
			alive = traitor:Alive() and not (traitor.organism and (traitor.organism.incapacitated or traitor.organism.otrub)),
			mainTraitor = traitor.MainTraitor == true,
			portrait = HMCDBuildTraitorPortraitSnapshot(traitor)
		}
	end

	return summary
end

local function HMCDBroadcastTraitorRoundSummary(summary)
	summary = summary or {}

	net.Start("HMCD_TraitorRoundSummary")
		net.WriteUInt(math.min(#summary, 63), 6)

		for index = 1, math.min(#summary, 63) do
			local info = summary[index]
			local kills = IsValid(info.ply) and info.ply.HMCDRoundKillCount or info.kills
			net.WriteEntity(IsValid(info.ply) and info.ply or NULL)
			net.WriteString(string.sub(info.characterName or "Unknown", 1, 64))
			net.WriteString(string.sub(info.nick or "Unknown", 1, 64))
			net.WriteString(string.sub(info.roleKey or "", 1, 64))
			net.WriteString(string.sub(info.roleName or "Traitor", 1, 64))
			net.WriteUInt(math.Clamp(math.floor(tonumber(kills) or 0), 0, 4095), 12)
			net.WriteBool(info.alive == true)
			net.WriteBool(info.mainTraitor == true)

			local portrait = info.portrait or {}
			net.WriteString(string.sub(portrait.model or "models/player/group01/male_07.mdl", 1, 192))
			net.WriteUInt(math.Clamp(math.floor(tonumber(portrait.skin) or 0), 0, 255), 8)
			net.WriteFloat(math.Clamp(tonumber(portrait.modelScale) or 1, 0.05, 10))
			net.WriteVector(portrait.playerColor or Vector(1, 1, 1))

			local bodygroups = portrait.bodygroups or {}
			net.WriteUInt(math.min(#bodygroups, 31), 5)
			for bodygroupIndex = 1, math.min(#bodygroups, 31) do
				local bodygroup = bodygroups[bodygroupIndex]
				net.WriteUInt(math.Clamp(bodygroup.id or 0, 0, 255), 8)
				net.WriteUInt(math.Clamp(bodygroup.value or 0, 0, 255), 8)
			end

			local subMaterials = portrait.subMaterials or {}
			net.WriteUInt(math.min(#subMaterials, 63), 6)
			for materialIndex = 1, math.min(#subMaterials, 63) do
				local subMaterial = subMaterials[materialIndex]
				net.WriteUInt(math.Clamp(subMaterial.index or 0, 0, 255), 8)
				net.WriteString(string.sub(subMaterial.material or "", 1, 192))
			end

			local accessories = portrait.accessories or {}
			net.WriteUInt(math.min(#accessories, 7), 3)
			for accessoryIndex = 1, math.min(#accessories, 7) do
				net.WriteString(string.sub(accessories[accessoryIndex] or "", 1, 96))
			end
		end
	net.Broadcast()
end

function MODE:EndRound()
	timer.Remove("HMCDSpawnSWAT")
	timer.Remove("SpawnAdditionalPolice")
    timer.Remove("SpawnAdditionalNationalGuard")
	

	self.deadPoliceCount = 0
	self.swatDeployed = false
	self.spawnedPoliceCount = 0
	self.roundStartType = nil

	local traitors, gunners = {}, {}
	local traitor_role_results = {}
	local traitor_round_summary
	local players_alive = 0
	local endround, winner = zb:CheckWinner(self:CheckAlivePlayers())

	-- for _, ply in player.Iterator() do	--; Extreme optimization
		-- ply.SubRole = nil
	-- end

	for i, ply in player.Iterator() do
		if ply.isTraitor and ply:Team() ~= TEAM_SPECTATOR then
			traitors[#traitors + 1] = ply

			if ply.MainTraitor then
				local sub_role = ply.SubRole
				sub_role = MODE.NormalizeTraitorSubRole and MODE.NormalizeTraitorSubRole(sub_role) or sub_role

				if isstring(sub_role) and sub_role ~= "" and MODE.SubRoles[sub_role] then
					traitor_role_results[#traitor_role_results + 1] = {
						ply = ply,
						role = sub_role,
						steam_id64 = ply:SteamID64() or ""
					}
				end
			end
		end
		
		if ply.isGunner and ply:Team() ~= TEAM_SPECTATOR then
			gunners[#gunners + 1] = ply
		end
		
		if(ply:Alive() and ply.organism and !ply.organism.incapacitated)then
			players_alive = players_alive + 1
		end

	end

	traitor_round_summary = HMCDBuildTraitorRoundSummary(traitors)

	for _, ply in player.Iterator() do
		ply.isPolice = false
		ply.isTraitor = false
		ply.isGunner = false
		ply.MainTraitor = false
		ply.SubRole = nil
		ply.Profession = nil
		MODE.ClearProfessionLoadout(ply)
		MODE.ResetProfessionStats(ply)
	end
	
	if(not winner)then
		HMCDBroadcastTraitorRoundSummary(traitor_round_summary)
		net.Start("hmcd_roundend")
			net.WriteUInt(#traitors, MODE.TraitorExpectedAmtBits)
			
			for _, traitor in ipairs(traitors) do
				net.WriteEntity(traitor)
			end
			
			net.WriteUInt(#gunners, MODE.TraitorExpectedAmtBits)
			
			for _, gunner in ipairs(gunners) do
				net.WriteEntity(gunner)
			end
		net.Broadcast()
		
		return
	end

	MODE.RecordTraitorRoleStats(traitor_role_results, winner == 1)

	if self.Type then
		if(MODE.RoleChooseRound)then
			if(winner ~= 1)then
				PrintMessage(HUD_PRINTTALK, "All traitors were stopped.")
				
				for _, traitor in ipairs(traitors) do
					net.Start("hmcd_announce_traitor_lose")
						net.WriteEntity(traitor)
						net.WriteBool(traitor:Alive())
					net.Broadcast()
					
					hook.Run("ZB_TraitorWinOrNot", traitor, winner)
				end

				for _, traitor in ipairs(traitors) do
					traitor:GiveSkill( -math.Rand(0.05,0.15) )
				end
			else
				for _, traitor in ipairs(traitors) do
					traitor:GiveExp( math.random(25,40) )
					traitor:GiveSkill( math.Rand(0.1,0.3) )
					traitor:SetPData("zb_hmcd_t_wins",traitor:GetPData("zb_hmcd_t_wins",0) + 1)
				end
				PrintMessage(HUD_PRINTTALK, "Every innocent was murdered.")
			end
			
			timer.Simple(2, function()
				if(players_alive == 0)then
					PrintMessage(HUD_PRINTTALK, "No one survived.")
				else
					if(players_alive == 1)then
						PrintMessage(HUD_PRINTTALK, "Only 1 survivor left in the city.")
					else
						PrintMessage(HUD_PRINTTALK, players_alive .. " survivors left in the city.")
					end
				end
			end)
		else
			if traitor and IsValid(traitor) then
				--local CheckAlive = #self:CheckAlivePlayers()[1]
				PrintMessage(HUD_PRINTTALK, self.Types[self.Type].Messages[winner]..(winner == 0 and (traitor:Alive() and " neutralized." or " killed.") or ""))
				
				timer.Simple(2, function()
					PrintMessage(HUD_PRINTTALK, self.Types[self.Type].Message..traitor:Name())
				end)

				if winner == 1 then
					traitor:GiveExp( math.Rand(30,50) )
					traitor:GiveSkill( math.Rand(0.15,0.3) )
					traitor:SetPData("zb_hmcd_t_wins",traitor:GetPData("zb_hmcd_t_wins",0) + 1)
				else
					traitor:GiveSkill( -math.Rand(0.05,0.1) )
				end
				
				hook.Run("ZB_TraitorWinOrNot", traitor, winner)
			else
				PrintMessage(HUD_PRINTTALK, self.Types[self.Type].Messages[winner]..(winner == 0 and (" killed.") or ""))
				for _, traitor in ipairs(traitors) do
					net.Start("hmcd_announce_traitor_lose")
						net.WriteEntity(traitor)
						net.WriteBool(traitor:Alive())
					net.Broadcast()

					hook.Run("ZB_TraitorWinOrNot", traitor, winner)
				end
			end
		end
	end

	timer.Simple(2,function()
		HMCDBroadcastTraitorRoundSummary(traitor_round_summary)

		net.Start("hmcd_roundend")
			net.WriteUInt(#traitors, MODE.TraitorExpectedAmtBits)
			
			for _, traitor in ipairs(traitors) do
				net.WriteEntity(traitor)
			end
			
			net.WriteUInt(#gunners, MODE.TraitorExpectedAmtBits)
			
			for _, gunner in ipairs(gunners) do
				net.WriteEntity(gunner)
			end
		net.Broadcast()
	end)
end

-- hook.Add("Player_Death", "HMCD_PlayerDeath", function(_, ply)
hook.Add("Player_Death", "HMCD_PlayerDeath", function(ply, _)
	local most_harm,biggest_attacker = 0,nil
	local last_attacker = nil

	if ply.isPolice then
		MODE.deadPoliceCount = (MODE.deadPoliceCount or 0) + 1
	end

	timer.Simple(.1,function()
		for attacker,attacker_harm in pairs(zb.HarmDone[ply] or {}) do
			if not IsValid(attacker) then continue end
			if most_harm < attacker_harm then
				most_harm = attacker_harm
				biggest_attacker = attacker:Name()
				last_attacker = attacker
			end
		end
		

		if ply.isTraitor then
			--local Appearance = ply.CurAppearance
			--
			--if(!Appearance)then
			--	-- Appearance = GetRandomAppearance(ply)
			--	PrintMessage(HUD_PRINTTALK, "Some traitor died.")
			--else
			--	local character_name = Appearance.AName or "error"
			--	
			--	PrintMessage(HUD_PRINTTALK, "Traitor " .. character_name .. " died.")
			--end
		
			if biggest_attacker then
				if biggest_attacker == ply:Name() then
					--timer.Simple(1,function()
					--	if not IsValid(ply) then return end
					--	local msg = (ThatPlyIsFemale(ply) and "Sh" or "H").."e suicided."
					--	PrintMessage(3,msg)
					--end)
				else
					last_attacker:GiveExp( math.random(10,15) )
					last_attacker:GiveSkill( math.Rand(0.025,0.075) )
					last_attacker:SetPData("zb_hmcd_ino_t_kills", last_attacker:GetPData("zb_hmcd_ino_t_kills",0) + 1)
					--timer.Simple(1,function()
					--	if not IsValid(ply) then return end
					--	local msg = (ThatPlyIsFemale(ply) and "Sh" or "H").."e was killed by "..biggest_attacker.."."
					--	PrintMessage(3,msg)
					--end)
				end
			else
				--timer.Simple(1,function()
				--	if not IsValid(ply) then return end
				--	local msg = (ThatPlyIsFemale(ply) and "Sh" or "H").."e died in mysterious circumstances."
				--	PrintMessage(3,msg)
				--end)
			end
		else
			if not biggest_attacker or not IsValid(ply) then return end
			
			if biggest_attacker == ply:Name() then
				ply:ChatPrint("You suicided.")
			elseif not biggest_attacker then
				ply:ChatPrint("You have died.")
			else
				ply:ChatPrint("You were killed by "..biggest_attacker..".")
			end
		end
	end)
end)

function MODE:CanLaunch()
	return true
end

util.AddNetworkString("hmcd_roundend")

MODE.NextRoundMainTraitors = MODE.NextRoundMainTraitors or {}

concommand.Add("hmcd_request_main_traitor", function(ply, cmd, args)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    

    if zb.ROUND_STATE == 1 then
        ply:ChatPrint("when round end")
        return
    end
    

    MODE.NextRoundMainTraitors[ply:SteamID()] = true
    ply:ChatPrint("true")
end)

hook.Add("RoundStateChange", "ResetNextRoundMainTraitors", function(old, new)
    if new == 2 then 
        MODE.NextRoundMainTraitors = {}
    end
end)

util.AddNetworkString("HMCD_UpdateTraitorAssistants")

local function hmcd_get_traitor_assistants()
	local traitor_assistants = {}

	for _, other_ply in player.Iterator() do
		if other_ply.isTraitor then
			local Appearance = other_ply.CurAppearance or {}
			local color = Appearance.AColor or (other_ply.GetPlayerColor and other_ply:GetPlayerColor():ToColor()) or color_white
			local name = Appearance.AName or (other_ply.GetPlayerName and other_ply:GetPlayerName()) or other_ply:Nick() or "error"
			local steamID = other_ply:SteamID() or ""
			local subRole = other_ply.SubRole or ""

			if not IsColor(color) then
				color = Color(color.r, color.g, color.b)
			end

			traitor_assistants[#traitor_assistants + 1] = {color, name, steamID, subRole}
		end
	end

	return traitor_assistants
end

function MODE:SendTraitorAssistants(ply)
	if not IsValid(ply) or not ply.isTraitor or not ply.MainTraitor then return end

	local traitor_assistants = hmcd_get_traitor_assistants()

	net.Start("HMCD_UpdateTraitorAssistants")
		net.WriteUInt(#traitor_assistants, 8)

		for _, info in ipairs(traitor_assistants) do
			net.WriteColor(info[1])
			net.WriteString(info[2])
			net.WriteString(info[3])
			net.WriteString(info[4] or "")
		end
	net.Send(ply)
end

function MODE:BroadcastTraitorAssistants()
	for _, main_traitor in player.Iterator() do
		self:SendTraitorAssistants(main_traitor)
	end
end

function MODE.SpawnPlayers(spawn_with_subroles)
    local gunner_found = false

    for i, ply in RandomPairs(player.GetAll()) do
        if ply.isTraitor or ply.isGunner or ply:Team() == TEAM_SPECTATOR then continue end
        if math.random(100) > (ply.Karma or 100) then continue end

        ply.isGunner = true
        gunner_found = true
        break
    end

    if(not gunner_found)then
        for i,ply in RandomPairs(player.GetAll()) do
            if ply.isTraitor or ply.isGunner or ply:Team() == TEAM_SPECTATOR then continue end

            ply.isGunner = true
            break
        end
    end

    local player_count = 0
    for i, ply in player.Iterator() do
        if(ply:Team() != TEAM_SPECTATOR)then
            player_count = player_count + 1
			MODE.ClearProfessionLoadout(ply)
			MODE.ResetProfessionStats(ply)
			ply.Profession = nil
        end
    end

    --= Professions
    local professions = {}
    if(spawn_with_subroles and MODE.RoleChooseRoundTypes[MODE.Type])then
        local professions_possible_pre = MODE.RoleChooseRoundTypes[MODE.Type].Professions

        if(professions_possible_pre)then
            local professions_possible = {}
            local professions_count_to_satisfy = math.ceil(player_count / 2)
            local profession_counts = {}

            local function GetProfessionMaxPlayers(profession_id)
                return HMCDGetProfessionMaxPlayers(profession_id, MODE.Type)
            end

            local function CanAssignProfession(profession_id)
                local max_players = GetProfessionMaxPlayers(profession_id)

                return !max_players or (profession_counts[profession_id] or 0) < max_players
            end

            local function AssignProfession(ply, profession_id)
                if(!profession_id or !CanAssignProfession(profession_id))then
                    return false
                end

                ply.Profession = profession_id
                profession_counts[profession_id] = (profession_counts[profession_id] or 0) + 1
                professions_count_to_satisfy = professions_count_to_satisfy - 1

                return true
            end

            local function GetWeightedProfessionPool()
                local available_professions = {}

                for profession_key, profession_data in ipairs(professions_possible) do
                    local profession_chance = profession_data[1]
                    local profession_id = profession_data[2]

                    if(profession_chance > 0 and CanAssignProfession(profession_id))then
                        available_professions[#available_professions + 1] = {profession_chance, profession_id, profession_key}
                    end
                end

                return available_professions
            end

            for profession, profession_info in pairs(professions_possible_pre) do
                professions_possible[#professions_possible + 1] = {profession_info.Chance, profession}
            end

            for _, ply in RandomPairs(player.GetAll()) do
                if(ply:Team() != TEAM_SPECTATOR and !ply.isTraitor)then
					local preferred_profession = MODE.NormalizeProfessionId(ply.HMCDPreferredProfession)

					if(preferred_profession and professions_possible_pre[preferred_profession])then
						AssignProfession(ply, preferred_profession)
					end
                end
            end

			if(professions_count_to_satisfy > 0)then
				for _, ply in RandomPairs(player.GetAll()) do
					if(ply:Team() != TEAM_SPECTATOR and !ply.isTraitor and !ply.Profession)then
						if((math.random(100) <= (ply.Karma or 100)) and (math.random(1, 3) == 1 or !ply.isGunner))then
							local available_professions = GetWeightedProfessionPool()

							if(#available_professions == 0)then
								break
							end

							local available_key, profession = hg.WeightedRandomSelect(available_professions)
							local selected_profession = available_professions[available_key]
							local profession_key = selected_profession and selected_profession[3]

							if(profession_key)then
								professions_possible[profession_key][1] = professions_possible[profession_key][1] / 2
							end

							AssignProfession(ply, profession)
							
							if(professions_count_to_satisfy == 0)then
								break
							end
						end
					end
				end
			end

            if(professions_count_to_satisfy > 0)then
                for _, ply in RandomPairs(player.GetAll()) do
                    if(ply:Team() != TEAM_SPECTATOR and !ply.isTraitor and !ply.Profession)then
                        local available_professions = GetWeightedProfessionPool()

                        if(#available_professions == 0)then
                            break
                        end

                        local available_key, profession = hg.WeightedRandomSelect(available_professions)
                        local selected_profession = available_professions[available_key]
                        local profession_key = selected_profession and selected_profession[3]

                        if(profession_key)then
                            professions_possible[profession_key][1] = professions_possible[profession_key][1] / 2
                        end

                        AssignProfession(ply, profession)
                        
                        if(professions_count_to_satisfy == 0)then
                            break
                        end
                    end
                end
            end
        end
    end


    local all_players = player.GetAll()
    for idx, current_ply in player.Iterator() do
        if(current_ply:Team() != TEAM_SPECTATOR)then
            current_ply.SubRole = nil
            current_ply.HMCD_ThiefInitializing = nil
            current_ply.HMCD_IsThief = nil
            current_ply.HMCD_ThiefPickupInventory = nil

			if current_ply.PlayerClassName and current_ply.PlayerClassName ~= "none" then
				current_ply:SetPlayerClass()
			end
			current_ply:Spawn()
			HMCDRestoreRoundAppearance(current_ply)
			current_ply:GetRandomSpawn()

            if(!current_ply:Alive())then
                continue
            end

			MODE.ResetProfessionStats(current_ply)

            current_ply:SetSuppressPickupNotices(true)
            current_ply.noSound = true

            if(MODE.Type == "supermario")then
                MODE.Types.supermario.CustomJump(current_ply)
            end

            local sub_role = nil
			current_ply.HMCD_RandomTraitorRoleBonus = nil
            if(spawn_with_subroles and MODE.RoleChooseRoundTypes[MODE.Type])then
                if(current_ply.isTraitor)then
					local random_traitor_role
					sub_role, random_traitor_role = HMCDResolvePlayerTraitorSubRole(current_ply, MODE.Type)
					current_ply.HMCD_RandomTraitorRoleBonus = random_traitor_role and true or nil
                end

                if(current_ply.isGunner)then
                    MODE.Types[MODE.Type].GunManLoot(current_ply)
                end

                if(sub_role)then
                    if(current_ply.isGunner)then

                    elseif(current_ply.isTraitor)then
                        local role_info = MODE.SubRoles[sub_role]
                        if(!role_info or !MODE.RoleChooseRoundTypes[MODE.Type].Traitor[sub_role])then
                            sub_role = MODE.RoleChooseRoundTypes[MODE.Type].TraitorDefaultRole or "traitor_default"
                            role_info = MODE.SubRoles[sub_role]
                        end

                        if(current_ply.MainTraitor)then
                            local spawn_func = role_info.SpawnFunction
                            current_ply.SubRole = sub_role
                            spawn_func(current_ply)
                        end
                    end
                end
            else
                if(current_ply.isTraitor)then
                    MODE.Types[MODE.Type].TraitorLoot(current_ply)
                end

                if(current_ply.isGunner)then
                    MODE.Types[MODE.Type].GunManLoot(current_ply)
                end
            end
            
			if current_ply.isTraitor then
				HMCDConfigureTraitorRadio(current_ply)
			end

			if current_ply.isTraitor and ZCityTraps and ZCityTraps.GiveActivator then
				ZCityTraps.GiveActivator(current_ply)
			end

            if(gaymaps[game.GetMap()])then
                local inv = current_ply:GetNetVar("Inventory") or {}
                inv["Weapons"] = inv["Weapons"] or {}
                inv["Weapons"]["hg_flashlight"] = true
                current_ply:SetNetVar("Inventory", inv)
            end

            local hands = current_ply:Give("weapon_hands_sh")

			if(current_ply.Profession)then
				MODE.ApplyProfessionLoadout(current_ply)
			end

			if(current_ply.MainTraitor and MODE.IsJuggernautRole and MODE.IsJuggernautRole(current_ply.SubRole) and MODE.ApplyJuggernautStats)then
				MODE.ApplyJuggernautStats(current_ply)
			end

			HMCDApplyRandomTraitorRoleBonus(current_ply)

			if(IsValid(hands))then
				current_ply:SetActiveWeapon(hands)
			end
            HMCDResetTraitorFlashlight(current_ply)

            local this_player = current_ply

			if(current_ply.isTraitor)then
				timer.Simple(0, function()
					HMCDResetTraitorFlashlight(this_player)
				end)

				timer.Simple(0.25, function()
					HMCDResetTraitorFlashlight(this_player)
				end)
			end
            
            timer.Simple(0.1, function() 
                if IsValid(this_player) then
                    this_player.noSound = false
                    this_player:SetSuppressPickupNotices(false)
                end
            end)

            timer.Simple(0.2 * idx, function()
                if not IsValid(this_player) then return end

                local traitor_amt = 0
                local traitor_assistants = {}
                
                if (this_player.isTraitor) then
                    for _, other_ply in player.Iterator() do
                        if (other_ply.isTraitor) then
                            traitor_amt = traitor_amt + 1
                            

                            if this_player.MainTraitor then
                                local Appearance = other_ply.CurAppearance or {}
                                local color = Appearance.AColor or (other_ply.GetPlayerColor and other_ply:GetPlayerColor():ToColor()) or color_white
                                local name = Appearance.AName or (other_ply.GetPlayerName and other_ply:GetPlayerName()) or other_ply:Nick() or "error"
                                local steamID = other_ply:SteamID() or ""
                                local subRole = other_ply.SubRole or ""
                                
                                if not IsColor(color) then
                                    color = Color(color.r, color.g, color.b)
                                end
                                
                                table.insert(traitor_assistants, {color, name, steamID, subRole})
                            end
                        end
                    end
                end
                

                net.Start("HMCD_RoundStart")
                    net.WriteBool(this_player.isTraitor)
                    net.WriteBool(this_player.isGunner)
                    net.WriteString(MODE.Type)
                    net.WriteBool(true)
                    net.WriteString(this_player.SubRole or "")
                    net.WriteBool(this_player.MainTraitor == true)
                    
                    if (this_player.isTraitor) then
                        net.WriteString(MODE.TraitorWord)
                        net.WriteString(MODE.TraitorWordSecond)
                        net.WriteUInt(traitor_amt, MODE.TraitorExpectedAmtBits)
                    else
                        net.WriteString("")
                        net.WriteString("")
                        net.WriteUInt(0, MODE.TraitorExpectedAmtBits)
                    end
                    
                    if (this_player.MainTraitor) then

                        for _, traitor_info in ipairs(traitor_assistants) do
                            net.WriteColor(traitor_info[1], false)
                            net.WriteString(traitor_info[2])
                        end

                        timer.Simple(0.5, function()
                            if IsValid(this_player) and this_player.isTraitor and this_player.MainTraitor then
                                MODE:SendTraitorAssistants(this_player)
                            end
                        end)
                    end
                    
                    net.WriteString(this_player.Profession or "")
                net.Send(this_player)
                
                local role = MODE.Roles[MODE.Type][(this_player.isTraitor and "traitor") or (this_player.isGunner and "gunner") or "innocent"]
                if role then
                    zb.GiveRole(this_player, role.name, role.color)
                end
            end)
        end
    end
end

hook.Add("PlayerSpawn", "HMCD_UpdateTraitorsList", function(ply)
	if not ply.isTraitor then return end
	
	timer.Simple(0.5, function()
		MODE:BroadcastTraitorAssistants()
	end)
end)

hook.Add("PlayerDeath", "HMCD_UpdateTraitorsList", function(ply)
	if not ply.isTraitor then return end
	
	timer.Simple(0.1, function()
		if IsValid(ply) and ply.CurAppearance then
			MODE:SendTraitorDeathState(ply, false)
		end
		
		timer.Simple(0.4, function()
			MODE:BroadcastTraitorAssistants()
		end)
	end)
end)
