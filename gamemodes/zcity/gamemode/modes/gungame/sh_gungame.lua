local MODE = MODE

MODE.name = "gungame"
MODE.PrintName = "Gun Game"
MODE.Description = "Free-for-all, Kill to win"
MODE.Chance = 0.05
MODE.randomSpawns = true
MODE.LootSpawn = false
MODE.NoRoundStandouts = true
MODE.start_time = 8
MODE.grace_time = 5
MODE.KillsPerStage = 2
MODE.KillsPerFinal = 1
MODE.ThemeMusicFile = "gungame/gungame.mp3"
MODE.ThemeMusicVolume = 0.4
MODE.ThemeLoopFade = 2.25

function MODE:StartLockUntil()
	if (self.graceEnd or 0) > 0 then return self.graceEnd end
	return (zb.ROUND_START or 0) + (self.start_time or 8) + (self.grace_time or 5)
end

function MODE:IsStartLocked()
	return zb.ROUND_STATE ~= 3 and CurTime() < self:StartLockUntil()
end

function MODE:HG_MovementCalc_2(mul, ply, cmd, mv)
	if not self:IsStartLocked() then return end
	if mul then mul[1] = 0 end
	if not cmd then return end
	cmd:RemoveKey(IN_ATTACK)
	cmd:RemoveKey(IN_ATTACK2)
	cmd:RemoveKey(IN_FORWARD)
	cmd:RemoveKey(IN_BACK)
	cmd:RemoveKey(IN_MOVELEFT)
	cmd:RemoveKey(IN_MOVERIGHT)
	if mv then
		mv:RemoveKey(IN_ATTACK)
		mv:RemoveKey(IN_ATTACK2)
		mv:RemoveKey(IN_FORWARD)
		mv:RemoveKey(IN_BACK)
		mv:RemoveKey(IN_MOVELEFT)
		mv:RemoveKey(IN_MOVERIGHT)
	end
end

function MODE:PlayerCanLegAttack()
	if self:IsStartLocked() then return false end
end

local function RepeatSlots(pool, count)
	local slots = {}
	for i = 1, count do
		slots[i] = pool
	end
	return slots
end

MODE.Pools = {
	pistol = {
		"weapon_glock17", "weapon_cz75", "weapon_hk_usp", "weapon_m9beretta", "weapon_p22", "weapon_px4beretta",
		"weapon_makarov", "weapon_tokarev", "weapon_m1911", "weapon_browninghp", "weapon_fn45", "weapon_pl15",
		"weapon_glock26", "weapon_m45", "weapon_colt9mm", "weapon_ab10", "weapon_pm9", "weapon_cz75a",
		"weapon_osapb", "weapon_vp9hk", "weapon_ppk", "weapon_glock22", "weapon_p220", "weapon_p250",
		"weapon_mk23", "weapon_tti2011", "weapon_fivsevn", "weapon_p38", "weapon_m9berettacommando",
		"weapon_minebeap220", "weapon_tticglock", "weapon_makarovpistolpb", "weapon_rugermk3",
	},
	magnum = {
		"weapon_deagle", "weapon_revolver2", "weapon_revolver357", "weapon_glock18c", "weapon_tec9",
		"weapon_draco", "weapon_conan357", "weapon_revolversw686", "weapon_revolverswr8",
		"weapon_grizzlymkv", "weapon_magnumbfr", "weapon_apsss",
	},
	smg = {
		"weapon_mac11", "weapon_mp5", "weapon_mp7", "weapon_p90", "weapon_vector", "weapon_tmp",
		"weapon_uzi", "weapon_skorpion", "weapon_bizon", "weapon_ppsh", "weapon_microuzi", "weapon_miniuzi",
		"weapon_sterling", "weapon_devochkaump", "weapon_mp2ger", "weapon_mp34smg", "weapon_mp18smg",
		"weapon_mp510mm", "weapon_kp31", "weapon_pps", "weapon_stenmk2", "weapon_sam180",
		"weapon_m12beret", "weapon_ppk42", "weapon_scorpievo3", "weapon_blyskawichka",
		"weapon_pm63rak", "weapon_hla_gruntsmg", "weapon_armaguera", "weapon_bechowiec",
	},
	shotgun = {
		"weapon_remington870", "weapon_m590a1", "weapon_xm1014", "weapon_spas12", "weapon_saiga12",
		"weapon_doublebarrel", "weapon_doublebarrel_short", "weapon_ks23", "weapon_toz106",
		"weapon_ithaca37", "weapon_moss500", "weapon_aa12", "weapon_protecta", "weapon_izh18",
		"weapon_ttibenelli", "weapon_spasik15", "weapon_auto5", "weapon_dupletlong",
	},
	rifle = {
		"weapon_akm", "weapon_ak74", "weapon_ak74u", "weapon_m4a1", "weapon_hk416", "weapon_ar15",
		"weapon_sg552", "weapon_m16a2", "weapon_ak200", "weapon_ac556", "weapon_asval", "weapon_ak12",
		"weapon_ak15", "weapon_ak101", "weapon_ak102", "weapon_g3a3", "weapon_mk18", "weapon_fnfal",
		"weapon_scarh", "weapon_scarl", "weapon_fn2000", "weapon_famasf1", "weapon_l85a2", "weapon_qbz97",
		"weapon_g36cron", "weapon_m14", "weapon_ar10", "weapon_ia2", "weapon_colt733", "weapon_auga3",
		"weapon_ak74modern", "weapon_akalpha", "weapon_xm8", "weapon_fnfnc", "weapon_mcxspear",
		"weapon_ak103d", "weapon_ak104d", "weapon_ak105d", "weapon_abakan94", "weapon_aekzaika971",
		"weapon_rk62vel",
	},
	carbine = {
		"weapon_mini14", "weapon_sok94", "weapon_vpo209", "weapon_vpo136", "weapon_adar215",
		"weapon_ar6951", "weapon_uzicarbine",
	},
	sniper = {
		"weapon_sks", "weapon_svd", "weapon_sr25", "weapon_mosin", "weapon_kar98", "weapon_winchester",
		"weapon_m98b", "weapon_cs5", "weapon_t5000", "weapon_m24remington", "weapon_mosinm9130",
		"weapon_vss", "weapon_l42a1", "weapon_m14dmr", "weapon_zastavam93", "weapon_scarssr", "weapon_dsr1",
	},
	lmg = {
		"weapon_m249", "weapon_rpk", "weapon_pkm", "weapon_m60", "weapon_hk21",
		"weapon_rpk74m", "weapon_mg36", "weapon_dp27",
	},
	eastern = {
		"weapon_makarov", "weapon_makarovpistolpb", "weapon_tokarev", "weapon_pl15", "weapon_skorpion",
		"weapon_ppsh", "weapon_pps", "weapon_bizon", "weapon_pm63rak", "weapon_kp31", "weapon_ak74u",
		"weapon_akm", "weapon_ak74", "weapon_ak12", "weapon_ak15", "weapon_ak74modern", "weapon_asval",
		"weapon_saiga12", "weapon_ks23", "weapon_toz106", "weapon_sks", "weapon_svd", "weapon_vss",
		"weapon_mosin", "weapon_mosinm9130", "weapon_rpk", "weapon_rpk74m", "weapon_pkm",
	},
	nato = {
		"weapon_glock17", "weapon_hk_usp", "weapon_m9beretta", "weapon_m45", "weapon_fivsevn", "weapon_mk23",
		"weapon_mp5", "weapon_mp7", "weapon_p90", "weapon_vector", "weapon_tmp", "weapon_m590a1",
		"weapon_spas12", "weapon_xm1014", "weapon_m4a1", "weapon_hk416", "weapon_m16a2", "weapon_mk18",
		"weapon_scarh", "weapon_scarl", "weapon_g3a3", "weapon_fnfal", "weapon_auga3", "weapon_l85a2",
		"weapon_m14", "weapon_sr25", "weapon_m14dmr", "weapon_m249", "weapon_hk21", "weapon_m60",
	},
	vintage = {
		"weapon_flintlock", "weapon_p38", "weapon_m1911", "weapon_browninghp", "weapon_tokarev",
		"weapon_ppsh", "weapon_stenmk2", "weapon_mp18smg", "weapon_mp34smg", "weapon_kp31", "weapon_mp2ger",
		"weapon_doublebarrel", "weapon_doublebarrel_short", "weapon_auto5", "weapon_ithaca37",
		"weapon_kar98", "weapon_mosin", "weapon_mosinm9130", "weapon_winchester", "weapon_sks", "weapon_dp27",
	},
	wfa_pistol = {
		"weapon_vp9hk", "weapon_ppk", "weapon_glock22", "weapon_p220", "weapon_p250", "weapon_mk23",
		"weapon_tti2011", "weapon_fivsevn", "weapon_cz75sp01", "weapon_conan357", "weapon_tticglock",
	},
	wfa_smg = {
		"weapon_bizon", "weapon_ppsh", "weapon_microuzi", "weapon_sterling", "weapon_devochkaump",
		"weapon_mp510mm", "weapon_scorpievo3", "weapon_kp31", "weapon_vector", "weapon_p90", "weapon_mp7",
	},
	wfa_gun = {
		"weapon_ak12", "weapon_ak15", "weapon_g3a3", "weapon_mk18", "weapon_fnfal", "weapon_scarh",
		"weapon_fn2000", "weapon_famasf1", "weapon_aa12", "weapon_ithaca37", "weapon_m14",
		"weapon_l85a2", "weapon_auga3", "weapon_vss", "weapon_cs5", "weapon_mcxspear", "weapon_xm8",
		"weapon_hk416", "weapon_scarl",
	},
	ak = {
		"weapon_makarov", "weapon_tokarev", "weapon_skorpion", "weapon_bizon", "weapon_draco", "weapon_dracovska",
		"weapon_ak74u", "weapon_akm", "weapon_ak74", "weapon_ak200", "weapon_ak12", "weapon_ak15",
		"weapon_ak101", "weapon_ak102", "weapon_ak103d", "weapon_ak104d", "weapon_ak105d", "weapon_ak74modern",
		"weapon_akalpha", "weapon_saiga12", "weapon_sks", "weapon_asval", "weapon_vss", "weapon_rpk",
		"weapon_rpk74m",
	},
	swat = {
		"weapon_glock17", "weapon_glock26", "weapon_hk_usp", "weapon_m9beretta", "weapon_glock18c",
		"weapon_mp5", "weapon_mp7", "weapon_p90", "weapon_vector", "weapon_tmp", "weapon_m590a1",
		"weapon_remington870", "weapon_spas12", "weapon_xm1014", "weapon_m4a1", "weapon_hk416",
		"weapon_ar15", "weapon_mk18", "weapon_scarl", "weapon_sr25", "weapon_m14dmr", "weapon_m249",
	},
	frontier = {
		"weapon_m1911", "weapon_p22", "weapon_ab10", "weapon_revolver2", "weapon_revolver357",
		"weapon_conan357", "weapon_revolversw686", "weapon_revolverswr8", "weapon_magnumbfr",
		"weapon_grizzlymkv", "weapon_doublebarrel", "weapon_doublebarrel_short", "weapon_ithaca37",
		"weapon_moss500", "weapon_remington870", "weapon_winchester", "weapon_mini14", "weapon_ruger",
		"weapon_vpo209", "weapon_vpo136", "weapon_mosin", "weapon_kar98",
	},
	melee = {
		"weapon_pocketknife", "weapon_kitchenknife", "weapon_kabar", "weapon_sogknife",
		"weapon_switchblade", "weapon_bayonet", "weapon_hg_machete", "weapon_tomahawk",
		"weapon_hg_kukri", "weapon_hatchet", "weapon_hg_crowbar", "weapon_hg_cleaver",
	},
	melee_heavy = {
		"weapon_bat", "weapon_golfclub", "weapon_leadpipe", "weapon_hg_axe", "weapon_hg_fireaxe",
		"weapon_hg_sledgehammer", "weapon_hg_katana", "weapon_hg_slayersword", "weapon_pan",
	},
	melee_trench = {
		"weapon_bayonet", "weapon_kabar", "weapon_hg_shovel", "weapon_hatchet", "weapon_hg_crowbar", "weapon_hg_axe",
	},
	melee_operator = {
		"weapon_sogknife", "weapon_kabar", "weapon_hg_kukri", "weapon_tomahawk", "weapon_hg_machete", "weapon_bayonet",
	},
	melee_street = {
		"weapon_bat", "weapon_barbedbat", "weapon_leadpipe", "weapon_switchblade", "weapon_kitchenknife",
		"weapon_pan", "weapon_hg_cleaver", "weapon_hg_crowbar",
	},
	melee_swat = {
		"weapon_hg_stunstick", "weapon_hg_tonfa", "weapon_bat", "weapon_leadpipe", "weapon_sogknife",
	},
	melee_frontier = {
		"weapon_tomahawk", "weapon_hatchet", "weapon_hg_machete", "weapon_hg_kukri", "weapon_hg_axe", "weapon_hatchethmcd",
	},
}

MODE.Variations = {
	{
		id = "classic", name = "The Gauntlet", description = "Start small. End loud. Climb the whole armory.", meleePool = "melee",
		slots = {
			"pistol", "pistol", "pistol", "pistol", "magnum", "magnum",
			"smg", "smg", "smg", "shotgun", "shotgun", "carbine",
			"rifle", "rifle", "rifle", "lmg", "sniper", "sniper",
		},
	},
	{
		id = "warfighter", name = "Contractor", description = "PMC kit: modern sidearms into rifles and a DMR.", meleePool = "melee_operator",
		slots = {
			"wfa_pistol", "wfa_pistol", "wfa_pistol", "wfa_smg", "wfa_smg", "wfa_smg",
			"shotgun", "shotgun", "wfa_gun", "wfa_gun", "wfa_gun", "wfa_gun",
			"wfa_gun", "wfa_gun", "sniper", "sniper",
		},
	},
	{
		id = "cqc", name = "Hallway Heat", description = "Pistols, spraycans and shotguns. No long hallways required.", meleePool = "melee_heavy",
		slots = {
			"pistol", "pistol", "pistol", "magnum", "magnum",
			"smg", "smg", "smg", "smg", "smg",
			"shotgun", "shotgun", "shotgun", "shotgun", "shotgun", "shotgun",
		},
	},
	{
		id = "eastern", name = "Warsaw Winter", description = "Makarovs to PKMs. The bloc never threw anything away.", meleePool = "melee_trench",
		slots = RepeatSlots("eastern", 18),
	},
	{
		id = "nato", name = "Atlantic Issue", description = "Western service weapons from USP to SAW.", meleePool = "melee_operator",
		slots = RepeatSlots("nato", 18),
	},
	{
		id = "scatter", name = "12 Gauge Gospel", description = "A sidearm sermon then nothing but shotguns.", meleePool = "melee_heavy",
		slots = {
			"pistol", "pistol", "magnum", "smg", "smg",
			"shotgun", "shotgun", "shotgun", "shotgun", "shotgun",
			"shotgun", "shotgun", "shotgun", "shotgun", "shotgun", "rifle",
		},
	},
	{
		id = "marksman", name = "Glass Cannon", description = "Carbines, battle rifles and glass-eyed snipers.", meleePool = "melee",
		slots = {
			"pistol", "pistol", "carbine", "carbine", "carbine",
			"rifle", "rifle", "rifle", "rifle", "rifle",
			"sniper", "sniper", "sniper", "sniper", "sniper", "sniper",
		},
	},
	{
		id = "vintage", name = "Last Century", description = "Bolt guns, grease guns and wood furniture from a uglier war.", meleePool = "melee_trench",
		slots = RepeatSlots("vintage", 16),
	},
	{
		id = "arcade", name = "Arcade Riot", description = "Every flavor of stupid: magnums, LMGs and a sniper for the encore.", meleePool = "melee_street",
		slots = {
			"pistol", "pistol", "magnum", "magnum", "smg", "smg",
			"shotgun", "shotgun", "rifle", "rifle", "wfa_gun", "wfa_gun",
			"lmg", "lmg", "sniper", "sniper",
		},
	},
	{
		id = "sidearms", name = "Pocket Artillery", description = "If it fits in a coat it is legal. Machine pistols count.", meleePool = "melee_street",
		slots = {
			"pistol", "pistol", "pistol", "pistol", "pistol", "pistol",
			"magnum", "magnum", "magnum", "magnum",
			"smg", "smg", "smg", "smg", "smg", "smg",
		},
	},
	{
		id = "motherland", name = "Kalashnikov Kult", description = "One family tree. Every cousin shows up including the ugly ones.", meleePool = "melee_trench",
		slots = RepeatSlots("ak", 18),
	},
	{
		id = "swat", name = "No-Knock", description = "Breacher toys: Glocks, MP5s, entry shotguns then a rifle.", meleePool = "melee_swat",
		slots = RepeatSlots("swat", 16),
	},
	{
		id = "frontier", name = "Dust & Iron", description = "Revolvers, coach guns and lever actions.", meleePool = "melee_frontier",
		slots = RepeatSlots("frontier", 16),
	},
}

function MODE:PickAvailable(pool, used)
	local unused, any = {}, {}
	for _, class in ipairs(pool or {}) do
		if isstring(class) and class ~= "" and weapons.GetStored(class) then
			any[#any + 1] = class
			if not (used and used[class]) then unused[#unused + 1] = class end
		end
	end
	local list = #unused > 0 and unused or any
	if #list == 0 then return nil end
	return list[math.random(#list)]
end

function MODE:BuildLadder(variation)
	if not variation then return nil end

	local slots = variation.slots or {}
	if #slots == 0 then return nil end

	local used, ladder = {}, {}
	for _, slot in ipairs(slots) do
		local pool = self.Pools[slot] or (istable(slot) and slot) or {slot}
		local class = self:PickAvailable(pool, used) or self:PickAvailable(pool)
		if class then
			used[class] = true
			ladder[#ladder + 1] = class
		end
	end

	local meleePool = self.Pools[variation.meleePool or "melee"] or {variation.melee}
	local melee = self:PickAvailable(meleePool, used) or self:PickAvailable(self.Pools.melee, used) or self:PickAvailable(self.Pools.melee)
	if not melee or #ladder < 4 then return nil end

	ladder[#ladder + 1] = melee
	return ladder, melee
end
