local MODE = MODE

zb = zb or {}
zb.Points = zb.Points or {}

zb.Points.HMCD_CRI_CT = zb.Points.HMCD_CRI_CT or {}
zb.Points.HMCD_CRI_CT.Color = Color(0,0,150)
zb.Points.HMCD_CRI_CT.Name = "HMCD_CRI_CT"

zb.Points.HMCD_CRI_T = zb.Points.HMCD_CRI_T or {}
zb.Points.HMCD_CRI_T.Color = Color(237,13,13)
zb.Points.HMCD_CRI_T.Name = "HMCD_CRI_T"

zb.Points.SNIPERZONE_CRI = zb.Points.SNIPERZONE_CRI or {}
zb.Points.SNIPERZONE_CRI.Color = Color(255,150,0)
zb.Points.SNIPERZONE_CRI.Name = "SNIPERZONE_CRI"

zb.Points.SNIPERSPAWN_CRI = zb.Points.SNIPERSPAWN_CRI or {}
zb.Points.SNIPERSPAWN_CRI.Color = Color(0,220,255)
zb.Points.SNIPERSPAWN_CRI.Name = "SNIPERSPAWN_CRI"

MODE.SWATModel = "models/css_seb_swat/css_swat.mdl"

MODE.SWATPrimaries = {
	{name = "M4A1 Holo", wep = "weapon_m4a1", atts = {"holo15", "grip3", "laser4"}},
	{name = "HK416 Holo", wep = "weapon_hk416", atts = {"holo15", "grip3", "laser4"}},
	{name = "P90", wep = "weapon_p90", atts = {}},
	{name = "MP7 Holo", wep = "weapon_mp7", atts = {"holo14"}},
	{name = "M4A1 Suppressed", wep = "weapon_m4a1", atts = {"optic2", "grip3", "supressor7"}},
}

MODE.SWATGear = {
	{name = "Medkit", item = "weapon_medkit_sh"},
	{name = "Tourniquet", item = "weapon_tourniquet"},
	{name = "Walkie Talkie", item = "weapon_walkie_talkie"},
	{name = "Knife", item = "weapon_melee"},
	{name = "Flashbang", item = "weapon_hg_flashbang_tpik"},
	{name = "Bloodbag", item = "weapon_bloodbag"},
	{name = "Ballistic Shield", item = "weapon_ballistic_shield"},
	{name = "Big Bandage", item = "weapon_bigbandage_sh"},
}

MODE.SWATGearSlots = 5
MODE.SWATDefaultGear = {1, 2, 3, 5}