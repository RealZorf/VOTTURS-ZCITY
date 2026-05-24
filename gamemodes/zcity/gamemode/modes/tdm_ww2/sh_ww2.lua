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
    Background = Color(0, 18, 28, 165),
    InnerBackground = Color(3, 30, 44, 145),
    Outline = Color(137, 207, 240, 185),
    Gradient = Color(137, 207, 240, 75),
    AttachmentGradient = Color(165, 225, 245, 70),
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
AddItemToBUY("Colt Python", "Weapon", "weapon_python", 900, "Pistols", {})
AddItemToBUY("Colt M1911", "Weapon", "weapon_m1911", 800, "Pistols", {}, nil, TEAM_AMERICAN)
AddItemToBUY("Walther P38", "Weapon", "weapon_p38", 750, "Pistols", {}, nil, TEAM_GERMAN)
AddItemToBUY("Tokarev TT-33", "Weapon", "weapon_tokarev", 650, "Pistols", {}, nil, TEAM_AMERICAN)
AddItemToBUY("Walther PPK", "Weapon", "weapon_ppk", 600, "Pistols", {}, nil, TEAM_GERMAN)

--Submachine guns
AddItemToBUY("Suomi KP-31 Drum", "Weapon", "weapon_kp31", 4200, "Submachine Guns", {}, nil, TEAM_GERMAN)
AddItemToBUY("PPSh-41 Drum", "Weapon", "weapon_ppshboss", 4200, "Submachine Guns", {}, nil, TEAM_AMERICAN)
AddItemToBUY("Thompson M1A1", "Weapon", "weapon_thompson", 3000, "Submachine Guns", {}, nil, TEAM_AMERICAN)
AddItemToBUY("MP40", "Weapon", "weapon_mp40", 2400, "Submachine Guns", {}, nil, TEAM_GERMAN)
AddItemToBUY("M3 Grease Gun", "Weapon", "weapon_m3greasegun", 2400, "Submachine Guns", {}, nil, TEAM_AMERICAN)

--Rifles
AddItemToBUY("Gewehr 43", "Weapon", "weapon_gewehr43", 3200, "Rifles", {})
AddItemToBUY("Karabiner 98k", "Weapon", "weapon_kar98", 2000, "Rifles", {"optic12"}, nil, TEAM_GERMAN)
AddItemToBUY("Mosin-Nagant", "Weapon", "weapon_mosin", 2000, "Rifles", {"optic12"}, nil, TEAM_AMERICAN)

--Assault rifles
AddItemToBUY("FG 42", "Weapon", "weapon_fg42", 4400, "Assault Rifles", {}, nil, TEAM_GERMAN)
AddItemToBUY("M14", "Weapon", "weapon_m14", 4400, "Assault Rifles", {}, nil, TEAM_AMERICAN)

--Machine guns
AddItemToBUY("MG 34", "Weapon", "weapon_mg34", 6800, "Machine guns", {}, nil, TEAM_GERMAN)
AddItemToBUY("DP-27", "Weapon", "weapon_dp27", 6000, "Machine guns", {}, nil, TEAM_AMERICAN)

--Equipment
AddItemToBUY("M1940 Stahlhelm", "Armor", "ent_armor_helmet1", 350, "Equipment", {}, nil, TEAM_GERMAN)
AddItemToBUY("M1 Helmet", "Armor", "ent_armor_helmet7", 350, "Equipment", {}, nil, TEAM_AMERICAN)

--Medical
AddItemToBUY("Morphine", "Weapon", "weapon_morphine", 1000, "Medical", {})
AddItemToBUY("Epipen", "Weapon", "weapon_adrenaline", 800, "Medical", {})
AddItemToBUY("Medkit", "Weapon", "weapon_medkit_sh", 650, "Medical", {})
AddItemToBUY("Big Bandage", "Weapon", "weapon_bigbandage_sh", 400, "Medical", {})
AddItemToBUY("Bloodbag", "Weapon", "weapon_bloodbag", 400, "Medical", {})
AddItemToBUY("Mannitol", "Weapon", "weapon_mannitol", 300, "Medical", {})
AddItemToBUY("Bandage", "Weapon", "weapon_bandage_sh", 200, "Medical", {})
AddItemToBUY("Painkillers", "Weapon", "weapon_painkillers", 200, "Medical", {})
AddItemToBUY("Tourniquet", "Weapon", "weapon_tourniquet", 150, "Medical", {})
AddItemToBUY("Decompression needle", "Weapon", "weapon_needle", 50, "Medical", {})

--Grenades
AddItemToBUY("F1 Grenade", "Weapon", "weapon_hg_f1_tpik", 500, "Grenades", {}, nil, TEAM_AMERICAN)
AddItemToBUY("Eihandgranate 39", "Weapon", "weapon_hg_f1_tpik", 500, "Grenades", {}, nil, TEAM_GERMAN)
AddItemToBUY("Mk 2 Grenade", "Weapon", "weapon_hg_mk2_tpik", 450, "Grenades", {}, nil, TEAM_AMERICAN)
AddItemToBUY("Stielhandgranate 24", "Weapon", "weapon_hg_mk2_tpik", 450, "Grenades", {}, nil, TEAM_GERMAN)
AddItemToBUY("AN-M8 Smoke Grenade", "Weapon", "weapon_hg_m18_tpik", 350, "Grenades", {}, nil, TEAM_AMERICAN)
AddItemToBUY("M39 Nebelhandgranate", "Weapon", "weapon_hg_m18_tpik", 350, "Grenades", {}, nil, TEAM_GERMAN)

--Melee
AddItemToBUY("M1 Bayonet", "Weapon", "weapon_buck200knife", 300, "Melee", {}, nil, TEAM_AMERICAN)
AddItemToBUY("AMES Entrenching Tool", "Weapon", "weapon_hg_crovel", 300, "Melee", {}, nil, TEAM_AMERICAN)
AddItemToBUY("S84/98 III Bayonet", "Weapon", "weapon_sogknife", 300, "Melee", {}, nil, TEAM_GERMAN)
AddItemToBUY("M1938 Klappspaten", "Weapon", "weapon_hg_crovel", 300, "Melee", {}, nil, TEAM_GERMAN)

-- Ammo
AddItemToBUY("7.92x57mm (20)", "Ammo", "ent_ammo_7.92x57mmmauser", 100, "Ammo", {}, 20)
AddItemToBUY("7.62x54mm (20)", "Ammo", "ent_ammo_7.62x54mm", 100, "Ammo", {}, 20)
AddItemToBUY("7.62x51mm (20)", "Ammo", "ent_ammo_7.62x51mm", 100, "Ammo", {}, 20)
AddItemToBUY("9x19mm (30)", "Ammo", "ent_ammo_9x19mmparabellum", 75, "Ammo", {}, 30)
AddItemToBUY(".45 ACP (30)", "Ammo", "ent_ammo_.45acp", 75, "Ammo", {}, 30)
AddItemToBUY(".357 Magnum (20)", "Ammo", "ent_ammo_.357magnum", 75, "Ammo", {}, 20)
AddItemToBUY("7.65x17mm (30)", "Ammo", "ent_ammo_7.65x17mm", 50, "Ammo", {}, 30)
AddItemToBUY("7.62x25mm (30)", "Ammo", "ent_ammo_7.62x25mm", 50, "Ammo", {}, 30)