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

-- MEDICAL
AddItemToBUY( "Cigarettes", "Weapon", "weapon_hg_cigarette", 20, "Medical", {} )
AddItemToBUY( "Decompression Needle", "Weapon", "weapon_needle", 50, "Medical", {} )
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


-- ARMOR
AddItemToBUY( "ACH III Helmet", "Armor", "ent_armor_helmet1", 350, "Equipment", {} )
AddItemToBUY( "IIIA Vest", "Armor", "ent_armor_vest3", 450, "Equipment", {} )
AddItemToBUY( "Ballistic Mask", "Armor", "ent_armor_mask1", 650, "Equipment", {} )
AddItemToBUY( "III Vest", "Armor", "ent_armor_vest4", 650, "Equipment", {} )
AddItemToBUY( "IV Vest", "Armor", "ent_armor_vest1", 1000, "Equipment", {} )

-- UTILITY
AddItemToBUY( "Flashlight", "Armor", "hg_flashlight", 250, "Utility", {} )
AddItemToBUY( "NVG-GPNVG-18", "Armor", "ent_armor_nightvision1", 450, "Utility", {} )
AddItemToBUY( "Flashbang", "Weapon", "weapon_hg_flashbang_tpik", 250, "Utility", {} )
AddItemToBUY( "Smoke Grenade", "Weapon", "weapon_hg_m18_tpik", 350, "Utility", {} )
AddItemToBUY( "RGD-5", "Weapon", "weapon_hg_rgd_tpik", 450, "Utility", {} )
AddItemToBUY( "M67", "Weapon", "weapon_hg_grenade_tpik", 500, "Utility", {} )

-- PISTOLS
AddItemToBUY( "Colt M1911", "Weapon", "weapon_m1911", 400, "Pistols", {}, nil, 0 )
AddItemToBUY( "Colt M45A1", "Weapon", "weapon_m45", 400, "Pistols", {}, nil, 1 )
AddItemToBUY( "Beretta M9", "Weapon", "weapon_m9berettacommando", 500, "Pistols", {"supressor4"}, nil, 0 )
AddItemToBUY( "Glock 17", "Weapon", "weapon_glock17", 500, "Pistols", {"supressor4"}, nil, 1 )
AddItemToBUY( "Browning HP", "Weapon", "weapon_browninghp", 700, "Pistols", {"supressor4"}, nil, 0 )
AddItemToBUY( "Glock 22", "Weapon", "weapon_glock22", 700, "Pistols", {"supressor4"}, nil, 1 )
AddItemToBUY( "S&W M29", "Weapon", "weapon_revolvermodel29", 800, "Pistols", {}, nil, 0 )
AddItemToBUY( "King Cobra", "Weapon", "weapon_revolver357", 800, "Pistols", {}, nil, 1 )
AddItemToBUY( "Five-Seven", "Weapon", "weapon_fivsevn", 850, "Pistols", {} )
AddItemToBUY( "Grizzly .50AE", "Weapon", "weapon_grizzlymkv", 900, "Pistols", {}, nil, 0 )
AddItemToBUY( "Deagle .50AE", "Weapon", "weapon_deagle", 900, "Pistols", {}, nil, 1 )
AddItemToBUY( "APS", "Weapon", "weapon_apsss", 950, "Pistols", {}, nil, 0 )
AddItemToBUY( "Glock 18", "Weapon", "weapon_glock18c", 950, "Pistols", {}, nil, 1 )

-- CARBINES
AddItemToBUY( "Ruger 10/22", "Weapon", "weapon_ruger", 1000, "Carbines", {} )
AddItemToBUY( "Mini-30", "Weapon", "weapon_mini30762", 2100, "Carbines", {}, nil, 0 )
AddItemToBUY( "Mini-14", "Weapon", "weapon_mini14", 2100, "Carbines", {}, nil, 1 )

-- SUBMACHINE GUNS
AddItemToBUY( "IWI UZI", "Weapon", "weapon_mp2ger", 1300, "Submachine", {"supressor4"} )
AddItemToBUY( "Skorpion", "Weapon", "weapon_skorpion", 1400, "Submachine", {} )
AddItemToBUY( "MP-5", "Weapon", "weapon_mp5", 1600, "Submachine", {"supressor4"} )
AddItemToBUY( "MP-5 10mm", "Weapon", "weapon_mp510mm", 1900, "Submachine", {"supressor8","laser5","holo4","holo14"} )
AddItemToBUY( "MP-7", "Weapon", "weapon_mp7", 2300, "Submachine", {"supressor2","laser5","holo4","holo14"} )
AddItemToBUY( "P-90", "Weapon", "weapon_p90", 2500, "Submachine", {"supressor8","holo4","holo14","holo15"} )
AddItemToBUY( "Kriss Vector", "Weapon", "weapon_vector", 2800, "Submachine", {"supressor4","holo4","holo14","holo15"} )

-- SHOTGUNS
AddItemToBUY( "Izh-18", "Weapon", "weapon_izh18", 800, "Shotguns", {} )
AddItemToBUY( "IZh-43", "Weapon", "weapon_doublebarrel", 1200, "Shotguns", {} )
AddItemToBUY( "Remington 870", "Weapon", "weapon_remington870", 1700, "Shotguns", {"holo4"}, nil, 0 )
AddItemToBUY( "Remington 870 C", "Weapon", "weapon_remington870oiblyat", 1700, "Shotguns", {"holo4"}, nil, 1 )
AddItemToBUY( "KS-23", "Weapon", "weapon_ks23", 2200, "Shotguns", {} )
AddItemToBUY( "XM-1014", "Weapon", "weapon_xm1014", 2600, "Shotguns", {"supressor5"}, nil, 0 )
AddItemToBUY( "SPAS-12", "Weapon", "weapon_spas12", 2600, "Shotguns", {"supressor5"}, nil, 1 )
AddItemToBUY( "AA-12", "Weapon", "weapon_aa12", 3300, "Shotguns", {} )

-- RIFLES
AddItemToBUY( "AK-74", "Weapon", "weapon_ak74", 3000, "Rifles", {"supressor1","holo6","holo12","optic4"}, nil, 0 )
AddItemToBUY( "AK-200", "Weapon", "weapon_ak200", 3000, "Rifles", {"supressor1","holo4","holo1","optic5"}, nil, 1 )
AddItemToBUY( "AKM", "Weapon", "weapon_akm", 3200, "Rifles", {"supressor1","holo6","holo12","optic4"}, nil, 0 )
AddItemToBUY( "AK-203", "Weapon", "weapon_ak203", 3200, "Rifles", {"supressor1","holo4","holo1","optic5"}, nil, 1 )
AddItemToBUY( "SG552", "Weapon", "weapon_sg552", 3400, "Rifles", {"supressor2","holo5","holo12","optic5"}, nil, 0 )
AddItemToBUY( "M16A4", "Weapon", "weapon_m16a4", 3400, "Rifles", {"supressor2","holo4","holo1","optic5"}, nil, 1 )
AddItemToBUY( "AS-VAL", "Weapon", "weapon_asval", 3500, "Rifles", {"optic4"} )
AddItemToBUY( "LR300", "Weapon", "weapon_lr300", 3600, "Rifles", {"supressor2","holo5","holo12","optic5"}, nil, 0 )
AddItemToBUY( "CQB-11", "Weapon", "weapon_mk1", 3600, "Rifles", {"supressor2","holo4","holo1","optic5"}, nil, 1 )
AddItemToBUY( "FN FAL", "Weapon", "weapon_fnfalpara", 4000, "Rifles", {"holo5","holo13"}, nil, 0 )
AddItemToBUY( "G3A3", "Weapon", "weapon_g3a3", 4000, "Rifles", {"holo4","holo1"}, nil, 1 )

-- HEAVY WEAPONS
AddItemToBUY( "RPK-74", "Weapon", "weapon_rpk", 4000, "Heavy", {"optic4"}, nil, 0 )
AddItemToBUY( "RPK-74M", "Weapon", "weapon_rpk74m", 4000, "Heavy", {"optic4"}, nil, 1 )
AddItemToBUY( "MG36", "Weapon", "weapon_mg36", 4000, "Heavy", {"supressor2","holo4","holo1","optic7"}, nil, 1 )
AddItemToBUY( "RPK", "Weapon", "weapon_rpk762", 4850, "Heavy", {"optic4"}, nil, 0 )
AddItemToBUY( "FN MINIMI", "Weapon", "weapon_minimi", 5750, "Heavy", {"supressor2","holo2","holo12","optic9"}, nil, 0 )
AddItemToBUY( "M249", "Weapon", "weapon_m249", 5750, "Heavy", {"supressor2","holo2","holo12","optic9"}, nil, 1 )
AddItemToBUY( "PKM", "Weapon", "weapon_pkm", 7000, "Heavy", {"optic4"}, nil, 0 )
AddItemToBUY( "PKP", "Weapon", "weapon_pechenka", 7000, "Heavy", {"optic4"}, nil, 1 )

-- MARKSMAN RIFLES
AddItemToBUY( "MP-18", "Weapon", "weapon_mp18", 800, "Marksman", {} )
AddItemToBUY( "Mosin-Nagant", "Weapon", "weapon_mosin", 2100, "Marksman", {"optic12"}, nil, 0 )
AddItemToBUY( "Karabiner 98k", "Weapon", "weapon_kar98", 2100, "Marksman", {"optic12"}, nil, 1 )
AddItemToBUY( "T5000", "Weapon", "weapon_t5000", 4200, "Marksman", {"optic6"}, nil, 0 )
AddItemToBUY( "Barrett M98B", "Weapon", "weapon_m98b", 4200, "Marksman", {}, nil, 1 )
AddItemToBUY( "SVDM", "Weapon", "weapon_svds", 5500, "Marksman", {"supressor1","optic5","optic11"}, nil, 0 )
AddItemToBUY( "SR-25", "Weapon", "weapon_sr25", 5500, "Marksman", {"supressor7","optic6","optic2"}, nil, 1 )

-- AMMO
AddItemToBUY( "9x18mm (30)", "Ammo", "ent_ammo_9x18mm", 50, "Ammo", {}, 30 )
AddItemToBUY( ".22 Long Rifle (60)", "Ammo", "ent_ammo_.22longrifle", 50, "Ammo", {}, 60 )
AddItemToBUY( "7.65x17 (30)", "Ammo", "ent_ammo_7.65x17mm", 75, "Ammo", {}, 30 )
AddItemToBUY( "9x19mm (30)", "Ammo", "ent_ammo_9x19mmparabellum", 75, "Ammo", {}, 30 )
AddItemToBUY( "10mm Auto (30)", "Ammo", "ent_ammo_10mmauto", 75, "Ammo", {}, 30 )
AddItemToBUY( ".45 ACP (30)", "Ammo", "ent_ammo_.45acp", 75, "Ammo", {}, 30 )
AddItemToBUY( ".50 Action Express (20)", "Ammo", "ent_ammo_.50actionexpress", 75, "Ammo", {}, 20 )
AddItemToBUY( ".357 Magnum (20)", "Ammo", "ent_ammo_.357magnum", 75, "Ammo", {}, 20 )
AddItemToBUY( ".38 Special (20)", "Ammo", "ent_ammo_.38special", 75, "Ammo", {}, 20 )
AddItemToBUY( ".40 Smith & Wesson (30)", "Ammo", "ent_ammo_.40sw", 75, "Ammo", {}, 30 )
AddItemToBUY( ".44 Remington Magnum (20)", "Ammo", "ent_ammo_.44remingtonmagnum", 75, "Ammo", {}, 20 )
AddItemToBUY( "7.62x39mm (30)", "Ammo", "ent_ammo_7.62x39mm", 100, "Ammo", {}, 30 )
AddItemToBUY( ".366TKM (20)", "Ammo", "ent_ammo_.366tkm", 100, "Ammo", {}, 20 )
AddItemToBUY( "7.62x54mm (20)", "Ammo", "ent_ammo_7.62x54mm", 100, "Ammo", {}, 20 )
AddItemToBUY( "5.56x45mm (30)", "Ammo", "ent_ammo_5.56x45mm", 100, "Ammo", {}, 30 )
AddItemToBUY( "5.45x39mm (30)", "Ammo", "ent_ammo_5.45x39mm", 100, "Ammo", {}, 30 )
AddItemToBUY( "4.6x30mm (30)", "Ammo", "ent_ammo_4.6x30mm", 100, "Ammo", {}, 30 )
AddItemToBUY( "5.7x28mm (30)", "Ammo", "ent_ammo_5.7x28mm", 100, "Ammo", {}, 30 )
AddItemToBUY( "12/70 Gauge (12)", "Ammo", "ent_ammo_12/70gauge", 100, "Ammo", {}, 12 )
AddItemToBUY( "23x75 SH10 (12)", "Ammo", "ent_ammo_23x75sh10", 100, "Ammo", {}, 12 )
AddItemToBUY( "7.62x51mm (20)", "Ammo", "ent_ammo_7.62x51mm", 150, "Ammo", {}, 20 )
AddItemToBUY( ".338 Lapua Magnum (20)", "Ammo", "ent_ammo_.338lapuamagnum", 350, "Ammo", {}, 20 )

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
