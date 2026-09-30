local MODE = MODE

MODE.base = "cstrike"

MODE.PrintName = "World War II Frontline"
MODE.name = "ww2"
MODE.Description = "German and American squads fight through bomb and rescue objectives with period weapons and limited field equipment."
MODE.BombSiteLabel = "TARGET"
MODE.SiteInsideText = "On objective!"
MODE.HostageZoneLabel = "EXTRACTION ZONE"
MODE.SkipSpawnAppearance = true
MODE.ThemeMusicFile = "tdm_ww2_theme.mp3"
MODE.ThemeMusicVolume = 0.60
MODE.BuyMenuTheme = {
	Background = Color(0, 0, 0, 155),
	InnerBackground = Color(0, 0, 0, 140),
	Outline = Color(255, 0, 0, 128),
	Gradient = Color(155, 0, 0, 55),
	AttachmentGradient = Color(55, 155, 55, 25),
}

MODE.TeamNames = {
    [0] = "German Forces",
    [1] = "American Forces",
    [3] = "Nobody",
}

MODE.BuyItems = {}

local TEAM_GERMAN = 0
local TEAM_AMERICAN = 1

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
        Attachments = Attachments or {},
        Amount = Amount,
        TeamBased = TeamBased,
    }
end

--Pistols
AddItemToBUY("Walther PPK", "Weapon", "weapon_ppk", 400, "Pistols", {})
AddItemToBUY("Colt M1911", "Weapon", "weapon_m1911", 500, "Pistols", {}, nil, TEAM_AMERICAN)
AddItemToBUY("Walther P38", "Weapon", "weapon_p38", 500, "Pistols", {}, nil, TEAM_GERMAN)
AddItemToBUY("Mauser Red 9", "Weapon", "weapon_mauserred9", 600, "Pistols", {})
AddItemToBUY("Browning HP", "Weapon", "weapon_browninghp", 700, "Pistols", {})
AddItemToBUY("Colt Python", "Weapon", "weapon_python", 800, "Pistols", {})

--Submachine guns
AddItemToBUY("MP40", "Weapon", "weapon_mp40", 1300, "Submachine Guns", {}, nil, TEAM_GERMAN)
AddItemToBUY("STEN MK2", "Weapon", "weapon_stenmk2", 1300, "Submachine Guns", {}, nil, TEAM_AMERICAN)
AddItemToBUY("M3 Grease Gun", "Weapon", "weapon_m3greasegun", 1600, "Submachine Guns", {}, nil, TEAM_AMERICAN)
AddItemToBUY("MP34", "Weapon", "weapon_mp34smg", 1600, "Submachine Guns", {}, nil, TEAM_GERMAN)
AddItemToBUY("Thompson M1A1", "Weapon", "weapon_thompson", 1900, "Submachine Guns", {})
AddItemToBUY("PPSh-41", "Weapon", "weapon_ppsh", 2300, "Submachine Guns", {}, nil, TEAM_AMERICAN)
AddItemToBUY("MP-41 R", "Weapon", "weapon_mp41r", 2300, "Submachine Guns", {}, nil, TEAM_GERMAN)
AddItemToBUY("PPSh-41 Drum", "Weapon", "weapon_ppshboss", 2800, "Submachine Guns", {}, nil, TEAM_AMERICAN)
AddItemToBUY("Suomi KP31", "Weapon", "weapon_kp31", 2800, "Submachine Guns", {}, nil, TEAM_GERMAN)

--Shotguns
AddItemToBUY("Sawed-off IZh-43", "Weapon", "weapon_doublebarrel_short", 1600, "Shotguns", {})
AddItemToBUY("Izh-43", "Weapon", "weapon_doublebarrel", 1800, "Shotguns", {})
AddItemToBUY("Itacha Model 37", "Weapon", "weapon_ithaca37", 2000, "Shotguns", {})
AddItemToBUY("Browning Auto 5", "Weapon", "weapon_auto5", 2600, "Shotguns", {})

--Marksman Rifles (Marksman)
AddItemToBUY("Karabiner 98k", "Weapon", "weapon_kar98", 2000, "Marksman", {"optic12"}, nil, TEAM_AMERICAN)
AddItemToBUY("Karabiner 98k KM", "Weapon", "weapon_kar98kriegsmod", 2000, "Marksman", {"optic12"}, nil, TEAM_GERMAN)
AddItemToBUY("Gewehr 43", "Weapon", "weapon_gewehr43", 2400, "Marksman", {}, nil, TEAM_GERMAN)
AddItemToBUY("M1 Garand", "Weapon", "weapon_m1garand", 2400, "Marksman", {}, nil, TEAM_AMERICAN)
AddItemToBUY("PTRS-41", "Weapon", "weapon_ptrs", 5500, "Marksman", {"optic12"})

--Assault rifles
AddItemToBUY("VG 1-5", "Weapon", "weapon_vg15", 3000, "Assault", {})
AddItemToBUY("STG-45", "Weapon", "weapon_stg4567", 3200, "Assault", {})
AddItemToBUY("STG-44", "Weapon", "weapon_stg443", 3600, "Assault", {opticstg44})
AddItemToBUY("FG 42", "Weapon", "weapon_fg42", 5250, "Assault", {}, nil, TEAM_GERMAN)
AddItemToBUY("AVT-40", "Weapon", "weapon_avtsvo", 4250, "Assault", {}, nil, TEAM_AMERICAN)

--Machine guns (Heavy)
AddItemToBUY("LS M26", "Weapon", "weapon_lapti26", 4850, "Heavy", {}, nil, TEAM_GERMAN)
AddItemToBUY("FN MODEL D", "Weapon", "weapon_fnmodeld", 4850, "Heavy", {}, nil, TEAM_AMERICAN)
AddItemToBUY("MG-34", "Weapon", "weapon_mg34", 6000, "Heavy", {})
AddItemToBUY("MG-42", "Weapon", "weapon_mg42", 7000, "Heavy", {})

--Armor
AddItemToBUY("M1940 Stahlhelm", "Armor", "ent_armor_helmet1", 350, "Armor", {}, nil, TEAM_GERMAN)
AddItemToBUY("M1 Helmet", "Armor", "ent_armor_helmet7", 350, "Armor", {}, nil, TEAM_AMERICAN)

--Medical
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

--Explosives
AddItemToBUY("F1 Grenade", "Weapon", "weapon_hg_f1_tpik", 450, "Explosives", {}, nil, TEAM_AMERICAN)
AddItemToBUY("Eihandgranate", "Weapon", "weapon_hg_eihandgranat_tpik", 450, "Explosives", {}, nil, TEAM_GERMAN)
AddItemToBUY("Mk 2 Grenade", "Weapon", "weapon_hg_mk2_tpik", 500, "Explosives", {}, nil, TEAM_AMERICAN)
AddItemToBUY("Stielhandgranate 24", "Weapon", "wweapon_hg_stilya_tpik", 500, "Explosives", {}, nil, TEAM_GERMAN)
AddItemToBUY("RGD-1", "Weapon", "weapon_hg_rudg1_tpik", 350, "Explosives", {}, nil, TEAM_AMERICAN)
AddItemToBUY("M39 Nebelhandgranate", "Weapon", "weapon_hg_nebelgranate_tpik", 350, "Explosives", {}, nil, TEAM_GERMAN)
AddItemToBUY("Gebalte Ladung", "Weapon", "weapon_hg_gebalteladung_tpik", 1250, "Explosives", {})
AddItemToBUY("Panzerfaust", "Weapon", "weapon_panzerfaust", 4000, "Explosives", {})

--Melee
AddItemToBUY("M1 Bayonet", "Weapon", "weapon_buck200knife", 300, "Melee", {}, nil, TEAM_AMERICAN)
AddItemToBUY("AMES Entrenching Tool", "Weapon", "weapon_hg_crovel", 300, "Melee", {}, nil, TEAM_AMERICAN)
AddItemToBUY("S84/98 III Bayonet", "Weapon", "weapon_sogknife", 300, "Melee", {}, nil, TEAM_GERMAN)
AddItemToBUY("M1938 Klappspaten", "Weapon", "weapon_hg_crovel", 300, "Melee", {}, nil, TEAM_GERMAN)

-- Ammo
AddItemToBUY( "12/70 Gauge (12)", "Ammo", "ent_ammo_12/70gauge", 100, "Ammo", {}, 12)
AddItemToBUY("7.92x57mm (20)", "Ammo", "ent_ammo_7.92x57mmmauser", 100, "Ammo", {}, 20)
AddItemToBUY("7.92x33mm Kurz", "Ammo", "ent_ammo_7.92x33mmkurz", 100, "Ammo", {}, 30)
AddItemToBUY("7.62x54mm (20)", "Ammo", "ent_ammo_7.62x54mm", 100, "Ammo", {}, 20)
AddItemToBUY("7.62x51mm (20)", "Ammo", "ent_ammo_7.62x51mm", 100, "Ammo", {}, 20)
AddItemToBUY("9x19mm (30)", "Ammo", "ent_ammo_9x19mmparabellum", 75, "Ammo", {}, 30)
AddItemToBUY(".45 ACP (30)", "Ammo", "ent_ammo_.45acp", 75, "Ammo", {}, 30)
AddItemToBUY(".357 Magnum (20)", "Ammo", "ent_ammo_.357magnum", 75, "Ammo", {}, 20)
AddItemToBUY("7.65x17mm (30)", "Ammo", "ent_ammo_7.65x17mm", 50, "Ammo", {}, 30)
AddItemToBUY("7.62x25mm (30)", "Ammo", "ent_ammo_7.62x25mm", 50, "Ammo", {}, 30)
AddItemToBUY( ".40 Smith & Wesson (30)", "Ammo", "ent_ammo_.40sw", 75, "Ammo", {}, 30)
AddItemToBUY( ".14.5x114mm (20)", "Ammo", "ent_ammo_14.5x114mmb32", 350, "Ammo", {}, 20)