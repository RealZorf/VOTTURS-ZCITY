local MODE = MODE

zb = zb or {}
zb.Points = zb.Points or {}

zb.Points.HMCD_TDM_CT = zb.Points.HMCD_TDM_CT or {}
zb.Points.HMCD_TDM_CT.Color = Color(0,0,150)
zb.Points.HMCD_TDM_CT.Name = "HMCD_TDM_CT"

zb.Points.HMCD_TDM_T = zb.Points.HMCD_TDM_T or {}
zb.Points.HMCD_TDM_T.Color = Color(150,95,0)
zb.Points.HMCD_TDM_T.Name = "HMCD_TDM_T"

MODE.PrintName = "Team Deathmatch"

--[[
    ["weapon_hk_usp"] = {
        Type = "Weapon",
        Price = "600",
        Category = "Pistols",
        Attachments = {
            "supressor3", "supressor4"
        }
    },
]]

MODE.BuyItems = {}

local priority = 1
local function AddItemToBUY(ItemName, Type, ItemClass, Price, Category, Attachments, Amount, TeamBased)
    if not MODE.BuyItems[Category] then
        MODE.BuyItems[Category] = {}
        MODE.BuyItems[Category].Priority = priority
        priority = priority + 1
    end

    MODE.BuyItems[Category][ItemName] = {
        Type = Type,
        ItemClass = ItemClass,
        Price = Price,
        Category = Category,
        Attachments = Attachments,
        Amount = Amount,
        TeamBased = TeamBased,
    }
end

--Pistols
AddItemToBUY( "Walter-P22", "Weapon", "weapon_p22", 300, "Pistols", {"supressor4"}, nil, 1 )
AddItemToBUY( "Makarov", "Weapon", "weapon_makarov", 350, "Pistols", {}, nil, 0 )
AddItemToBUY( "Makarov PB", "Weapon", "weapon_makarovpistolpb", 450, "Pistols", {}, nil, 0 )
AddItemToBUY( "Colt M1911", "Weapon", "weapon_m1911", 450, "Pistols", {"supressor4"}, nil, 0 )
AddItemToBUY( "Colt M45A1", "Weapon", "weapon_m45", 450, "Pistols", {}, nil, 1 )
AddItemToBUY( "SIG P220", "Weapon", "weapon_p220", 500, "Pistols", {"supressor4"}, nil, 0 )
AddItemToBUY( "Beretta M9 Commando", "Weapon", "weapon_m9berettacommando", 500, "Pistols", {"supressor4"}, nil, 0 )
AddItemToBUY( "Beretta M9", "Weapon", "weapon_m9beretta", 500, "Pistols", {"supressor4"}, nil, 1 )
AddItemToBUY( "SIG P250", "Weapon", "weapon_p250", 500, "Pistols", {"supressor4"}, nil, 1 )
AddItemToBUY( "Glock-17", "Weapon", "weapon_glock17", 550, "Pistols", {"supressor4", "holo16", "laser3", "laser1"}, nil, 0 )
AddItemToBUY( "HK-USP", "Weapon", "weapon_hk_usp", 550, "Pistols", {"supressor3"}, nil, 1 )
AddItemToBUY( "MK-23", "Weapon", "weapon_mk23", 600, "Pistols", {}, nil, 1 )
AddItemToBUY( "FNX-45", "Weapon", "weapon_fn45", 700, "Pistols", {"supressor4", "holo16", "laser3", "laser1"}, nil, 1 )
AddItemToBUY( "Browning Hi-Power", "Weapon", "weapon_browninghp", 700, "Pistols", {"supressor4"} )
AddItemToBUY( "Colt Python", "Weapon", "weapon_python", 800, "Pistols", {}, nil, 0 )
AddItemToBUY( "Colt King Cobra", "Weapon", "weapon_revolver357", 800, "Pistols", {}, nil, 1 )
AddItemToBUY( "Desert Eagle", "Weapon", "weapon_deagle", 900, "Pistols", {} )
AddItemToBUY( "TEC-9", "Weapon", "weapon_tec9", 1000, "Pistols", {}, nil, 0 )
AddItemToBUY( "Stechkin APS", "Weapon", "weapon_apsss", 1200, "Pistols", {"supressor4"}, nil, 0 )
AddItemToBUY( "Colt 9mm Pistol", "Weapon", "weapon_colt9mm", 1200, "Pistols", {}, nil, 1 )
AddItemToBUY( "Glock-18C", "Weapon", "weapon_glock18c", 1400, "Pistols", {"supressor4", "holo16", "laser3", "laser1"}, nil, 1 )
--Carbines
AddItemToBUY( "Ruger 10/22", "Weapon", "weapon_ruger", 1000, "Carbines", {} )
AddItemToBUY( "Vepr SOK-94", "Weapon", "weapon_sok94", 1900, "Carbines", {}, nil, 0 )
AddItemToBUY( "Mini-14", "Weapon", "weapon_mini14", 2100, "Carbines", {}, nil, 1 )
AddItemToBUY( "AR-15 Semi", "Weapon", "weapon_ar15", 2400, "Carbines", {"holo1", "holo8"}, nil, 1 )
AddItemToBUY( "VPO-136", "Weapon", "weapon_vpo136", 2400, "Carbines", {"holo6"}, nil, 0 )
--Rifles
AddItemToBUY( "AKS-74U", "Weapon", "weapon_ak74u", 2700, "Assault", {"supressor1","holo6","holo2"}, nil, 0 )
AddItemToBUY( "M4A1", "Weapon", "weapon_m4a1", 2900, "Assault", {"holo1","holo2","supressor2","holo15","optic8"}, nil, 1 )
AddItemToBUY( "AK-74", "Weapon", "weapon_ak74", 2900, "Assault", {"holo6","holo1","holo2","supressor1","supressor8","optic7"}, nil, 0 )
AddItemToBUY( "HK416", "Weapon", "weapon_hk416", 3100, "Assault", {"holo1","holo2","supressor2","holo15","optic8"}, nil, 1 )
AddItemToBUY( "AKM", "Weapon", "weapon_akm", 3200, "Assault", {"holo6","holo1","holo2","supressor1","optic7"}, nil, 0 )
AddItemToBUY( "VZ58", "Weapon", "weapon_vz58", 3200, "Assault", {"supressor1"}, nil, 0 )
AddItemToBUY( "Stoner 63A", "Weapon", "weapon_stoner63", 3200, "Assault", {"supressor2"}, nil, 1 )
AddItemToBUY( "M16A4", "Weapon", "weapon_m16a4", 3400, "Assault", {"holo1","holo2","suprewssor2","holo15","optic8","optic2"}, nil, 1 )
AddItemToBUY( "AK-200", "Weapon", "weapon_ak200", 3400, "Assault", {"supressor1","holo12","holo5","optic8","optic5"}, nil, 0 )
AddItemToBUY( "F1 FAMAS", "Weapon", "weapon_famasf1", 3800, "Assault", {"holo14","holo4","optic8","supressor2"}, nil, 1 )
AddItemToBUY( "LR 300", "Weapon", "weapon_lr300", 3800, "Assault", {"holo14","holo4","optic8","supressor2"}, nil, 0 )
AddItemToBUY( "G3A3", "Weapon", "weapon_g3a3", 4200, "Assault", {"holo17","holo1"}, nil, 1 )
AddItemToBUY( "FN FAL Para", "Weapon", "weapon_fnfalpara", 4200, "Assault", {"holo12","holo8"}, nil, 0 )
--Submachine
AddItemToBUY( "Šcorpion vz. 61", "Weapon", "weapon_skorpion", 1200, "Submachine", {}, nil, 0 )
AddItemToBUY( "Uzi", "Weapon", "weapon_uzi", 1300, "Submachine", {}, nil, 0 )
AddItemToBUY( "MPL", "Weapon", "weapon_mpl", 1300, "Submachine", {}, nil, 1 )
AddItemToBUY( "MP-5", "Weapon", "weapon_mp5", 1500, "Submachine", {"supressor4"} )
AddItemToBUY( "PP-19 Vityaz", "Weapon", "weapon_vityaz", 1500, "Submachine", {"holo2"}, nil, 1)
AddItemToBUY( "MAC-11", "Weapon", "weapon_mac11", 1600, "Submachine", {"supressor4"}, nil, 0 )
AddItemToBUY( "PM-9", "Weapon", "weapon_minebea", 1600, "Submachine", {"supressor4"}, nil, 0 )
AddItemToBUY( "Steyr TMP", "Weapon", "weapon_tmp", 2100, "Submachine", {"holo1","holo2","supressor4","holo15"}, nil, 1 )
AddItemToBUY( "MP-7", "Weapon", "weapon_mp7", 2300, "Submachine", {"holo1","holo2","supressor2","holo15"} )
AddItemToBUY( "KRISS Vector", "Weapon", "weapon_vector", 2300, "Submachine", {"holo1","holo2","supressor4","holo15"} )
AddItemToBUY( "P90", "Weapon", "weapon_p90", 2300, "Submachine", {"holo1","holo2","supressor4","holo15"} )
--Special
AddItemToBUY( "\"Deer Hunter\" Bow", "Weapon", "weapon_hg_bow", 2000, "Special", {} )
--Shotguns
AddItemToBUY( "Sawed-off IZh-43", "Weapon", "weapon_doublebarrel_short", 800, "Shotguns", {} )
AddItemToBUY( "IZh-43", "Weapon", "weapon_doublebarrel", 1100, "Shotguns", {} )
AddItemToBUY( "Mossberg 500", "Weapon", "weapon_moss500", 1400, "Shotguns", {} )
AddItemToBUY( "TOZ-194", "Weapon", "weapon_toz194", 1500, "Shotguns", {} )
AddItemToBUY( "Maverick 88", "Weapon", "weapon_maverickshot", 1500, "Shotguns", {} )
AddItemToBUY( "Remington-870", "Weapon", "weapon_remington870", 1700, "Shotguns", {"holo1","holo2","supressor5","holo15"} )
AddItemToBUY( "SPAS-12", "Weapon", "weapon_spas12", 2200, "Shotguns", {"supressor5"} )
AddItemToBUY( "XM-1014", "Weapon", "weapon_xm1014", 2300, "Shotguns", {"holo14","holo3"} )
--Heavy
AddItemToBUY( "RPK-74", "Weapon", "weapon_rpk", 4000, "Heavy", {"optic4","holo6","holo13","holo14","holo6fur"}, nil, 0 )
AddItemToBUY( "MG36", "Weapon", "weapon_mg36", 4850, "Heavy", {"holo1","holo4"}, nil, 1)
AddItemToBUY( "RPD", "Weapon", "weapon_rpd", 5450, "Heavy", {"optic4"}, nil, 0 )
AddItemToBUY( "M249", "Weapon", "weapon_m249", 5750, "Heavy", {"holo1","holo2","supressor2","holo15"} )
AddItemToBUY( "M60", "Weapon", "weapon_m60", 7000, "Heavy", {} )
AddItemToBUY( "PKM", "Weapon", "weapon_pkm", 7800, "Heavy", {"optic4"} )
--Marksman/Sniper   
AddItemToBUY( "Karabiner 98k", "Weapon", "weapon_kar98", 2100, "Marksman/Sniper", {"optic12"}, nil, 1)
AddItemToBUY( "Mosin-Nagant", "Weapon", "weapon_mosin", 2100, "Marksman/Sniper", {"optic12"}, nil, 0)
AddItemToBUY( "SKS", "Weapon", "weapon_sks", 2900, "Marksman/Sniper", {"optic4"} )
AddItemToBUY( "Barrett M98B", "Weapon", "weapon_m98b", 4200, "Marksman/Sniper", {}, nil, 0 )
AddItemToBUY( "T5000", "Weapon", "weapon_t5000", 4200, "Marksman/Sniper", {"optic6"}, nil, 1 )
AddItemToBUY( "SR-25", "Weapon", "weapon_sr25", 5500, "Marksman/Sniper", {"supressor7","optic6","optic2","grip2"}, nil, 1)
AddItemToBUY( "SVDM", "Weapon", "weapon_svds", 5500, "Marksman/Sniper", {"optic6","optic2"}, nil, 0 )
--Armor
AddItemToBUY( "IIIA Vest", "Armor", "ent_armor_vest3", 450, "Equipment", {} )
AddItemToBUY( "III Vest", "Armor", "ent_armor_vest4", 650, "Equipment", {} )
AddItemToBUY( "IV Vest", "Armor", "ent_armor_vest1", 1000, "Equipment", {} )
AddItemToBUY( "ACH III Helmet", "Armor", "ent_armor_helmet1", 350, "Equipment", {} )
AddItemToBUY( "Ballistic Mask", "Armor", "ent_armor_mask1", 650, "Equipment", {} )
--Other Shit
AddItemToBUY( "NVG-GPNVG-18", "Armor", "ent_armor_nightvision1", 450, "Equipment", {} )
AddItemToBUY( "Flashlight", "Armor", "hg_flashlight", 250, "Equipment", {} )
--Melee 
AddItemToBUY( "Police Tonfa", "Weapon", "weapon_hg_tonfa", 100, "Melee", {}, nil, 1 )
AddItemToBUY( "Battering Ram", "Weapon", "weapon_ram", 100, "Melee", {}, nil, 1 )
AddItemToBUY( "Machete", "Weapon", "weapon_hg_machete", 300, "Melee", {}, nil, 0 )
AddItemToBUY( "Hatchet", "Weapon", "weapon_hatchet", 300, "Melee", {}, nil, 0 )
AddItemToBUY( "Tomahawk", "Weapon", "weapon_tomahawk", 300, "Melee", {}, nil, 1 )
-- Medical
AddItemToBUY( "Decompression needle", "Weapon", "weapon_needle", 50, "Medical", {} )
AddItemToBUY( "Naloxone", "Weapon", "weapon_naloxone", 100, "Medical", {} )
AddItemToBUY( "Tourniquet", "Weapon", "weapon_tourniquet", 150, "Medical", {} )
AddItemToBUY( "Bandage", "Weapon", "weapon_bandage_sh", 200, "Medical", {} )
AddItemToBUY( "Painkillers", "Weapon", "weapon_painkillers", 200, "Medical", {} )
AddItemToBUY( "Beta-Blocker", "Weapon", "weapon_betablock", 250, "Medical", {} )
AddItemToBUY( "Mannitol", "Weapon", "weapon_mannitol", 300, "Medical", {} )
AddItemToBUY( "Big Bandage", "Weapon", "weapon_bigbandage_sh", 400, "Medical", {} )
AddItemToBUY( "Bloodbag", "Weapon", "weapon_bloodbag", 400, "Medical", {} )
AddItemToBUY( "Medkit", "Weapon", "weapon_medkit_sh", 650, "Medical", {} )
AddItemToBUY( "Epipen", "Weapon", "weapon_adrenaline", 800, "Medical", {} )
AddItemToBUY( "Morphine", "Weapon", "weapon_morphine", 1000, "Medical", {} )
AddItemToBUY( "Fentanyl", "Weapon", "weapon_fentanyl", 2000, "Medical", {} )

-- Explosive
AddItemToBUY( "Flashbang", "Weapon", "weapon_hg_flashbang_tpik", 250, "Explosive", {} )
AddItemToBUY( "RGD-5", "Weapon", "weapon_hg_rgd_tpik", 450, "Explosive", {} )
AddItemToBUY( "M67", "Weapon", "weapon_hg_grenade_tpik", 500, "Explosive", {} )

--Ammo
AddItemToBUY( "Arrow", "Ammo", "ent_ammo_arrow", 25, "Ammo", {}, 5)
AddItemToBUY( "9x18mm (30)", "Ammo", "ent_ammo_9x18mm", 50, "Ammo", {}, 30)
AddItemToBUY( ".22 Long Rifle (60)", "Ammo", "ent_ammo_.22longrifle", 50, "Ammo", {}, 60)
AddItemToBUY( "9x19mm (30)", "Ammo", "ent_ammo_9x19mmparabellum", 75, "Ammo", {}, 30)
AddItemToBUY( ".45 ACP (30)", "Ammo", "ent_ammo_.45acp", 75, "Ammo", {}, 30)
AddItemToBUY( ".50 Action Express (20)", "Ammo", "ent_ammo_.50actionexpress", 75, "Ammo", {}, 20)
AddItemToBUY( ".357 Magnum (20)", "Ammo", "ent_ammo_.357magnum", 75, "Ammo", {}, 20)
AddItemToBUY( ".38 Special (20)", "Ammo", "ent_ammo_.38special", 75, "Ammo", {}, 20)
AddItemToBUY( ".40 Smith & Wesson (30)", "Ammo", "ent_ammo_.40sw", 75, "Ammo", {}, 30)
AddItemToBUY( ".44 Remington Magnum (20)", "Ammo", "ent_ammo_.44remingtonmagnum", 75, "Ammo", {}, 20)
AddItemToBUY( "7.62x39mm (30)", "Ammo", "ent_ammo_7.62x39mm", 100, "Ammo", {}, 30)
AddItemToBUY( ".336TKM (20)", "Ammo", "ent_ammo_.366tkm", 100, "Ammo", {}, 20)
AddItemToBUY( "7.62x54mm (20)", "Ammo", "ent_ammo_7.62x54mm", 100, "Ammo", {}, 20)
AddItemToBUY( "5.56x45mm (30)", "Ammo", "ent_ammo_5.56x45mm", 100, "Ammo", {}, 30)
AddItemToBUY( "5.45x39mm (30)", "Ammo", "ent_ammo_5.45x39mm", 100, "Ammo", {}, 30)
AddItemToBUY( "4.6x30mm (30)", "Ammo", "ent_ammo_4.6x30mm", 100, "Ammo", {}, 30)
AddItemToBUY( "5.7x28mm (30)", "Ammo", "ent_ammo_5.7x28mm", 100, "Ammo", {}, 30)
AddItemToBUY( "12/70 Gauge (12)", "Ammo", "ent_ammo_12/70gauge", 100, "Ammo", {}, 12)
AddItemToBUY( "7.62x51mm (20)", "Ammo", "ent_ammo_7.62x51mm", 150, "Ammo", {}, 20)
AddItemToBUY( ".338 Lapua Magnum (20)", "Ammo", "ent_ammo_.338lapuamagnum", 350, "Ammo", {}, 20)

function MODE:HG_MovementCalc_2( mul, ply, cmd, mv )
    if (zb.ROUND_START or 0) + 20 > CurTime() and cmd then
        cmd:RemoveKey(IN_ATTACK)
        cmd:RemoveKey(IN_FORWARD)
        cmd:RemoveKey(IN_BACK)
        cmd:RemoveKey(IN_MOVELEFT)
        cmd:RemoveKey(IN_MOVERIGHT)

        if mv then
            mv:RemoveKey(IN_ATTACK)
            mv:RemoveKey(IN_FORWARD)
            mv:RemoveKey(IN_BACK)
            mv:RemoveKey(IN_MOVELEFT)
            mv:RemoveKey(IN_MOVERIGHT)
        end

        if IsValid(ply) and IsValid(ply:GetWeapon("weapon_hands_sh")) then
            cmd:SelectWeapon(ply:GetWeapon("weapon_hands_sh"))
            if SERVER then ply:SelectWeapon("weapon_hands_sh") end
        end
        
        mul[1] = 0
    end
end

function MODE:PlayerCanLegAttack( ply )
	if zb.CROUND == "dm" and (zb.ROUND_START or 0) + 20 > CurTime() then
		return false
	end
end
