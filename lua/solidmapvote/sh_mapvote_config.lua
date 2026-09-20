SolidMapVote = SolidMapVote or {}
SolidMapVote["Config"] = SolidMapVote["Config"] or {}

-- Time in seconds until the mapvote is over from when it starts.
SolidMapVote["Config"]["Length"] = 25

-- The time in seconds that the vote will stay on the screen after the winning map has been chosen.
SolidMapVote["Config"]["Post Vote Length"] = 5

-- Map Button Size (1 = Tall, 2 = Square)
SolidMapVote["Config"]["Map Button Size"] = 0.5

-- Autostart Settings [I recommend leaving it like this]
SolidMapVote["Config"]["Enable Vote Autostart"] = false
SolidMapVote["Config"]["Vote Autostart Delay"] = 60 * 60 -- 60 Minutes
SolidMapVote["Config"]["Autostart Reminder"] = 3 * 60 -- 3 minutes
SolidMapVote["Config"]["Time Left Commands"] = {"!timeleft", "/timeleft", ".timeleft"}

-- Map Prefixes to include
SolidMapVote["Config"]["Map Prefix"] = {"ttt", "rp", "gm", "mu", "hmcd", "de", "cs", "zc"}

-- Helper Colors 
local namecolor = {
    default = Color(255, 255, 255),
    owner = Color(200, 0, 0),
	servermanager = Color(200, 0, 0),
	headdeveloper = Color(200, 0, 0),
	staffmanager = Color(200, 0, 0),
	superadmin = Color(200, 0, 0),
    headadmin = Color(255, 165, 0),
    admin = Color(0, 170, 255),
    moderator = Color(0, 170, 255),
    booster = Color(0, 200, 20),
    special = Color(0, 200, 20),
    trusted = Color(255, 204, 0),
	og = Color(255, 204, 0)
}


-- Avatar Border Color
SolidMapVote["Config"]["Avatar Border Color"] = function(ply)
    if ply:IsSuperAdmin() then
        return HSVToColor(math.sin(2 * RealTime()) * 128 + 127, 1, 1)
    end
    local group = ply:GetUserGroup()

    if namecolor[group] then
        return namecolor[group]
    end
    return color_white
end

-- Vote Power
SolidMapVote["Config"]["Vote Power"] = function(ply)
	if ply:IsAdmin() then return 1 end 
	return 1
end

-- Fair Map Recycling
SolidMapVote["Config"]["Fair Map Recycling"] = true

-- Show Map Play Count
SolidMapVote["Config"]["Show Map Play Count"] = true

-- Custom/manual map pool. When true, maps are loaded from playable_maps.json
-- (garrysmod/data/map_registry/playable_maps.json). When false, maps are
-- collected from maps/*.bsp using Map Prefix / Ignore Prefix.
SolidMapVote["Config"]["Custom Map Pool"] = true
SolidMapVote["Config"]["Manual Map Pool"] = true
SolidMapVote["Config"]["Playable Maps Path"] = "map_registry/playable_maps.json"

-- Fallback Map Pool used only if the JSON file is missing or empty
SolidMapVote["Config"]["Map Pool"] = {
    "gm_flatgrass",
    "gm_construct",
}

SolidMapVote["Config"]["Construct Map Pool"] = {"gm_construct", "gm_flatgrass"}

-- Enable Voice/Chat
SolidMapVote["Config"]["Enable Voice"] = true
SolidMapVote["Config"]["Enable Chat"] = true

-- Force Vote Permission
SolidMapVote["Config"]["Force Vote Permission"] = function(ply) return ply:IsAdmin() end
SolidMapVote["Config"]["Force Vote Commands"] = {"!forcertv", "/forcertv", ".forcertv"}

-- RTV Settings
SolidMapVote["Config"]["RTV Percentage"] = 0.6
SolidMapVote["Config"]["RTV Delay"] = 60
SolidMapVote["Config"]["Enable UnVote"] = true
SolidMapVote["Config"]["Vote Commands"] = {"!rtv", "/rtv", ".rtv"}

-- Nomination Settings
SolidMapVote["Config"]["Ignore Prefix"] = true
SolidMapVote["Config"]["Nomination Commands"] = {"!nominate", "/nominate", ".nominate"}
SolidMapVote["Config"]["Allow Nominations"] = true
SolidMapVote["Config"]["Nomination Permissions"] = function(ply) return true end

-- Extend/Random Settings
SolidMapVote["Config"]["Enable Extend"] = true
SolidMapVote["Config"]["Extend Image"] = "http://i.imgur.com/zzBeMid.png"
SolidMapVote["Config"]["Enable Random"] = false
SolidMapVote["Config"]["Random Mode"] = 2
SolidMapVote["Config"]["Random Image"] = "http://i.imgur.com/oqeqWhl.png"

-- Missing Image
SolidMapVote["Config"]["Missing Image"] = ""
SolidMapVote["Config"]["Missing Image Size"] = { width = 1920, height = 1080 }

-- In this table you can add information for the map to make it more appealing on the mapvote. These are the configs i made over time you get to automatically use yay
-- Probably contains all maps you have on the server
SolidMapVote["Config"]["Specific Maps"] = {
    {
        filename = "d1_trainstation_02_csm",
        displayname = "Trainstation 02",
        image = "https://images.steamusercontent.com/ugc/9802753925406487711/40ADB32EE89EFB8A71AC96CBD934A77EC717C3AB/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "freeway_thicc_v3",
        displayname = "Freeway Thicc V3",
        image = "https://images.steamusercontent.com/ugc/2451740164185127624/79BA8D5F474E08BF8E8236F8D0545DAD038FF72B/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_bbicotka_hmcd",
        displayname = "Bbicotka HMCD",
        image = "https://images.steamusercontent.com/ugc/1848170935364477114/4F2ED51C7E9FC390FA14F32D3B12BB138F639080/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_bbicotka_snow_hmcd",
        displayname = "Bbicotka Snow HMCD",
        image = "https://images.steamusercontent.com/ugc/10793773218923862/A38402121BF0249425993B44511565DA26CF86E9/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_betac17",
        displayname = "Betac17",
        image = "https://images.steamusercontent.com/ugc/2122941877487314224/63F2365BD95477864FD57432B74D586CC6E7933C/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_broadcasting_station",
        displayname = "Broadcasting Station",
        image = "https://images.steamusercontent.com/ugc/32192049026217129/C8E76D593FA7EC49586D75E4F14DD071AAAF5F78/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_broadcasting_station_night",
        displayname = "Broadcasting Station Night",
        image = "https://images.steamusercontent.com/ugc/17203362106224614909/5153A4801B8056A9E69DC3A861DF42382C227D4B/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_brutalist_mcdonalds",
        displayname = "Brutalist McDonalds",
        image = "https://images.steamusercontent.com/ugc/2467488268105900201/86C7C6F9A2120C908478DB7C389623475B1956C1/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_building_v2",
        displayname = "Building V2",
        image = "https://images.steamusercontent.com/ugc/32195215392191746/DD2033A1D797F6F1C1FB32F4A7C5493D8C61E7B3/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_building_v2_war",
        displayname = "Building V2 War",
        image = "https://images.steamusercontent.com/ugc/32195849048916194/895E2DEDD0259309FA12797BC22BEE14586C9315/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_concrete_rooms_ext_b2",
        displayname = "Concrete Rooms Ext B2",
        image = "https://images.steamusercontent.com/ugc/2076765822719820691/F1B540E8D96AE6DBB7338AED1CE92F49CFA5FC8C/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_construct_cccp",
        displayname = "Construct CCCP",
        image = "https://images.steamusercontent.com/ugc/9731817735718161906/D728F87DF1C395A3A10236AAE10CCEBC40537632/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_cs_office_ext",
        displayname = "Office Ext",
        image = "https://images.steamusercontent.com/ugc/2300843578711308737/68538C8BF10E907D7A63EFD4B2F681E07095D985/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_denizen",
        displayname = "Denizen",
        image = "https://images.steamusercontent.com/ugc/2467485005083675045/E91FCEDF8D880190DAB9827D31877E729597A6D1/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "gm_funkis",
        displayname = "Funkis",
        image = "https://images.steamusercontent.com/ugc/14170847377989121/6304577EFB7EF559F0A9464378975E1FE119CFED/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_gleb",
        displayname = "Gleb",
        image = "https://images.steamusercontent.com/ugc/1696156397363076866/9FA5CA22F9EB9738B37E65DE0580097706E2F13A/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_hetveer_hmcd",
        displayname = "Hetveer HMCD",
        image = "https://images.steamusercontent.com/ugc/15337037532585591182/F12CF9699F451603E69B63B17839BDD70BDAF919/?imw=268imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "gm_hmcd_rooftops",
        displayname = "Rooftops",
        image = "https://images.steamusercontent.com/ugc/2064382254384662113/7C05073FC3C2C77C1E5EBD8451CDFCB0E474E4F1/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_l4d_hotel",
        displayname = "L4D Hotel",
        image = "https://images.steamusercontent.com/ugc/766110096610613815/ABE8431F41FE9FE31E6A0F8D5B64627162CCEB95/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_lakeview",
        displayname = "Lakeview",
        image = "https://images.steamusercontent.com/ugc/10228648626065670040/C2FDE1F2C704DF6C144009E49F7A1BF37CCA5A67/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_ploschadka",
        displayname = "Ploschadka",
        image = "https://images.steamusercontent.com/ugc/1728793836129392395/81FE8AB672EA7C9F52CAA08C005D912DCB52688B/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_sad",
        displayname = "Sad",
        image = "https://images.steamusercontent.com/ugc/2514781045786381714/BB2AD9063F2E1DA929CCBE5B13C842FEE112B464/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_secretcamp_hmcd",
        displayname = "Secretcamp HMCD",
        image = "https://images.steamusercontent.com/ugc/18006821206638836066/1B8EE8DD7E94FFC26D4F1F37FB6D7E9A4E718188/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_sentimental98v3night",
        displayname = "Sentimental98v3 Night",
        image = "https://images.steamusercontent.com/ugc/2429215823849531105/867F0A353FB57B9B5930AAF351F69C5C9190E28E/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_sosnovka2",
        displayname = "Sosnovka2",
        image = "https://images.steamusercontent.com/ugc/5097543432676715890/92AF29A00F527C0225B6D4B854FAA293BAFE1BAF/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_sosnovka2_night",
        displayname = "Sosnovka2 Night",
        image = "https://images.steamusercontent.com/ugc/5097543432676798407/13FD2F29AA8F8763E4FAAC7230B90EB9F1AF587A/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_starcatcher",
        displayname = "Starcatcher",
        image = "https://images.steamusercontent.com/ugc/9658284846745366154/F51F99D143AF9A5AAC911A4FCFED40F831A927E3/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_voidtown",
        displayname = "Voidtown",
        image = "https://images.steamusercontent.com/ugc/11370003479100549407/636B804891DD5FF2350D0922E31D3427ED87A14C/?imw=637&imh=358&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 637,
        height = 358
    },
    {
        filename = "gm_wawa",
        displayname = "Wawa",
        image = "https://images.steamusercontent.com/ugc/10783380683989782532/B20781F28B60A80D45D45DA02BA6139E8E5AB107/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_zabroshka",
        displayname = "Zabroshka",
        image = "https://images.steamusercontent.com/ugc/13806280998941577069/8AD1F0C5244D74856A683C6D91876CC2D01BE5AC/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "gm_zabroshka_winter",
        displayname = "Zabroshka Winter",
        image = "https://images.steamusercontent.com/ugc/13806280998941577069/8AD1F0C5244D74856A683C6D91876CC2D01BE5AC/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "hmcd_examen",
        displayname = "Examen",
        image = "https://images.steamusercontent.com/ugc/10189177580700526406/67D22B06296FCEF3C11920BB2F78ADAA0AE8AE0C/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "hmcd_lighthouse",
        displayname = "Lighthouse",
        image = "https://images.steamusercontent.com/ugc/1827906003950856164/B450685AE6055D3676216A66F64D009E9CC36256/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "hmcd_metropolis",
        displayname = "Metropolis",
        image = "https://images.steamusercontent.com/ugc/10451292611810889755/8802C03DF4364243BF40364CAF8D6875922AB998/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "hmcd_metropolis_extended",
        displayname = "Metropolis Extended",
        image = "https://images.steamusercontent.com/ugc/12187769889599501732/CFF0CB4F6564D34B7077C216E63E0A05B9BC3FF4/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "hmcd_rooftops",
        displayname = "Rooftops",
        image = "https://images.steamusercontent.com/ugc/2512529245984378257/50CB50DD6314554DDBF18A5D16F0CB8167BE3995/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "hmcd_rooftops_snow",
        displayname = "Rooftops Snow",
        image = "https://images.steamusercontent.com/ugc/2003569220438620196/8571993BA01D8943B7EBF5F4DC7A3918CE8A4E42/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "hmcd_trainstation_01",
        displayname = "Trainstation 01",
        image = "https://images.steamusercontent.com/ugc/9802753925406487711/40ADB32EE89EFB8A71AC96CBD934A77EC717C3AB/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "mu_aughts_v1",
        displayname = "Aughts V1",
        image = "https://images.steamusercontent.com/ugc/7423600155094026/B10B762D7E4F6607EA3442F3A8207DADE4B4B13A/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "mu_riverside_snow",
        displayname = "Riverside Snow",
        image = "https://images.steamusercontent.com/ugc/5078403134256844427/B68723FBEA0F47BD019BF72B1DB4A38CADAA89EE/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "mu_smallotown_v2_13",
        displayname = "Smallotown V2 13",
        image = "https://images.steamusercontent.com/ugc/2471991866894659249/A0F128F6C566343ACCE2E812A57AAD6D4C03E1DF/?imw=637&imh=358&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 637,
        height = 358
    },
    {
        filename = "mu_smallotown_v2_13_night",
        displayname = "Smallotown V2 13 Night",
        image = "https://images.steamusercontent.com/ugc/2471991866894665268/E0386560E0ACE770E6C7A0D966B96FCBAB0993E9/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "mu_smallotown_v2_hl2",
        displayname = "Smallotown V2 HL2",
        image = "https://images.steamusercontent.com/ugc/11295102507391337094/31F23F258682CD4E2B550C0905789149FD425822/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "mu_smallotown_v2_snow",
        displayname = "Smallotown V2 Snow",
        image = "https://images.steamusercontent.com/ugc/1865048991158163986/EA6448CBA9512A329E3B196EF5413EC6C88AF259/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "mu_smallotown_waste_v2_13",
        displayname = "Smallotown Waste V2 13",
        image = "https://images.steamusercontent.com/ugc/17431744911684215036/05BCA5C9ED5021221F05D1A61AF0F0A71D63C320/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ph_hostel_a6",
        displayname = "Hostel A6",
        image = "https://images.steamusercontent.com/ugc/2412326690219557364/E30A9AA41B9A288BE94A24F7C85EB53E529E2347/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "rp_unioncity",
        displayname = "Union City",
        image = "https://images.steamusercontent.com/ugc/1020573716200538091/4B985575C110CBABD14D4BBF755CB84C3295B4F7/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "tdm_bangclaw",
        displayname = "TDM Bangclaw",
        image = "https://images.steamusercontent.com/ugc/2286206932758967522/359022E4C767BC9CC743FB1C36A42A092B3795AA/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_67thway_2022",
        displayname = "67thway 2022",
        image = "https://images.steamusercontent.com/ugc/1868445746588379171/99B8F9ADE56ACF83F2A1202E94D5B33AA85CFF83/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_backyard_v2",
        displayname = "Backyard V2",
        image = "https://images.steamusercontent.com/ugc/1862812087885375985/67B2EC061B120C8EB107F330CECF386C45DC2D7E/?imw=637&imh=358&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 637,
        height = 358
    },
    {
        filename = "ttt_clue_2022",
        displayname = "Clue 2022",
        image = "https://images.steamusercontent.com/ugc/1848170393446499953/D13723BB0F5F4A6182AFD57098EAC87A0E66B57E/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_countryside_militia",
        displayname = "Countryside Militia",
        image = "https://images.steamusercontent.com/ugc/1814363346980494536/7F8CB5DEB37F5E457E857666634DE91D62BBE530/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_csgobank",
        displayname = "CSGO Bank",
        image = "https://images.steamusercontent.com/ugc/780658650791512143/C9C4EAA21E44B505D8B31A4210F972F73428C506/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_denizen",
        displayname = "Denizen",
        image = "https://images.steamusercontent.com/ugc/15259941341008403565/2AC449D809065748801EFB7829E8F50987650775/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_diescraper",
        displayname = "Diescraper",
        image = "https://images.steamusercontent.com/ugc/44573776974951198/778F67FB3832787CD679C8B58622BA34EB593B63/?imw=637&imh=358&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 637,
        height = 358
    },
    {
        filename = "ttt_fastfood_a6",
        displayname = "Fastfood A6",
        image = "https://images.steamusercontent.com/ugc/1082266720654625692/9B1BB2378B56F7380C9CA9C8886DE404BAC72CF1/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_fernwood",
        displayname = "Fernwood",
        image = "https://images.steamusercontent.com/ugc/11849208252616526998/73F5B9B3BC2E370C830C3D726EBD0D402FA0E14A/?imw=637&imh=358&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 637,
        height = 358
    },
    {
        filename = "ttt_forest_final",
        displayname = "Forest Final",
        image = "https://images.steamusercontent.com/ugc/1081141639034896046/52B76044A9C8D020C942EC6BB1B070E87A533F61/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_gas_station",
        displayname = "Gas Station",
        image = "https://images.steamusercontent.com/ugc/1862812795116674409/19B860A87DE46E5E527542885F98AC624E0B50F7/?imw=637&imh=358&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 637,
        height = 358
    },
    {
        filename = "ttt_grovestreet_extended_v2",
        displayname = "Grovestreet Extended V2",
        image = "https://images.steamusercontent.com/ugc/2450600311733794701/E4CF8A45A36259460C2B14F53B38FAF748F5D63C/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_ile_v4",
        displayname = "Ile V4",
        image = "https://images.steamusercontent.com/ugc/1653342851335529532/5D15AA9D9245E0043FA8A10B32AB747F3E8AE944/?imw=637&imh=358&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 637,
        height = 358
    },
    {
        filename = "ttt_island_2013",
        displayname = "Island 2013",
        image = "https://images.steamusercontent.com/ugc/1101419736384485992/193AAD378CBAF2867B0D91A3151A479F62ABFC48/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_libertycity",
        displayname = "Liberty City",
        image = "https://images.steamusercontent.com/ugc/2247920665249635045/9452454D4D0EBC03C0BD3F6F92168285E60DED2D/?imw=637&imh=358&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 637,
        height = 358
    },
    {
        filename = "ttt_lifetheroof",
        displayname = "Life The Roof",
        image = "https://images.steamusercontent.com/ugc/447331671887795106/C3E3FEFC0891E25424F7D4427AE18A4EACE57564/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_metropolis_v2a",
        displayname = "Metropolis V2A",
        image = "https://images.steamusercontent.com/ugc/34107558747918466/FEC922C4C71BF7176327B15C8017967BE239093C/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_plaza_b7",
        displayname = "Plaza B7",
        image = "https://images.steamusercontent.com/ugc/1082263151422293339/61E21584DAC52137415445208A5BBA6AA1AF9F25/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_rooftops_2016_v1",
        displayname = "Rooftops 2016 V1",
        image = "https://images.steamusercontent.com/ugc/574565056145859159/06E58BDE9EF0C629D8D82BA4BD6827291173245E/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_scarisland_2026",
        displayname = "Scarisland 2026",
        image = "https://images.steamusercontent.com/ugc/13217810416007657664/462482500D7286EAA1FA31A4E2C14C58E4FF72EC/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_skyscraper",
        displayname = "Skyscraper",
        image = "https://images.steamusercontent.com/ugc/451793768186031535/588EE152F7ECB18368C9C9E8A7A714459D55402A/?imw=268imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_terrortown",
        displayname = "Terrortown",
        image = "https://images.steamusercontent.com/ugc/702857494015515228/2293B11359399CAA10386DCB71CB9989683C29F8/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_terrortrain_2020_b5",
        displayname = "Terrortrain 2020 B5",
        image = "https://images.steamusercontent.com/ugc/776244746791253891/85A02E0FB1B26022CE52B8EC83561EB402E79925/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_tokyodistrict",
        displayname = "Tokyo District",
        image = "https://images.steamusercontent.com/ugc/1622940218343051002/5C7023EC25F23CF1298E5D6A3DED1623CC344027/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_vessel",
        displayname = "Vessel",
        image = "https://images.steamusercontent.com/ugc/921252182285605587/EDC7B9E5F22D5E7B0C503F67C98383D2E980C745/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_waterworld",
        displayname = "Waterworld",
        image = "https://images.steamusercontent.com/ugc/884113875133407628/7F51840432A611A18D7128DCCB386C3D8CA32881/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "zm_roy_the_ship",
        displayname = "Roy The Ship",
        image = "https://images.steamusercontent.com/ugc/541902544728987099/68425F22C203840BFFE354062BE3C8BEA09FD988/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "zs_cursed_woods_v3",
        displayname = "Cursed Woods V3",
        image = "https://images.steamusercontent.com/ugc/1868444887206710904/205B5E3005CAC6051FD42F3A22836906F979F48C/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "zs_intercity_mall_v16",
        displayname = "Intercity Mall V16",
        image = "https://images.steamusercontent.com/ugc/16207663677117756333/8117DE24F728B2405564AD1DDE5FE941A07417F5/?imw=637&imh=358&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 637,
        height = 358
    },
    {
        filename = "zs_muhosransk_v3",
        displayname = "Muhosransk V3",
        image = "https://images.steamusercontent.com/ugc/270588452671698521/8EB7FCF62A4E333A9AA7E4D2A14C998D886F184C/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "zs_richland_remix_v1a",
        displayname = "Richland Remix V1A",
        image = "https://images.steamusercontent.com/ugc/51322921726310732/97DA1CEB09E9D3A645BDE695656A72E00141FE4A/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "rp_richland_day",
        displayname = "Richland Day",
        image = "https://images.steamusercontent.com/ugc/12185183278346750382/B59354F9A06F43D0B68232FA52BAC294056C6E2C/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "rp_richland_night",
        displayname = "Richland Night",
        image = "https://images.steamusercontent.com/ugc/11523570438222361708/BD07EEDFD556508C8EE319106B80A64D1B959A0F/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "zb_cabin_v8",
        displayname = "Cabin V8",
        image = "https://images.steamusercontent.com/ugc/10597378782888453612/ECA46D3D92F4ADDC6F8B5C8DC81D4CE184C3AFF0/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "gm_stage_6",
        displayname = "Stage 6",
        image = "https://images.steamusercontent.com/ugc/2527164217048938626/B53B6BEF3DAB865A6C34AEB386B5D87935A3BA00/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height  = 268
    },
    {
        filename = "gm_apartments_hl2",
        displayname = "Apartments HL2",
        image = "https://images.steamusercontent.com/ugc/1860551708876058001/24A8DA717AD0EEA05644EB01F782356F316CC9E7/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height  = 268
    },
    {
        filename = "mu_hmcd_mansion",
        displayname = "Mansion",
        image = "https://images.steamusercontent.com/ugc/1773833637273123826/E8D631B099460902C6523E470787ECD7153ADCC3/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height  = 268
    },
    {
        filename = "cs_drugbust",
        displayname = "Drugbust",
        image = "https://images.steamusercontent.com/ugc/430446696393215262/821104756DC6BB9C6E8E3DF45FC4C0C4E2229F01/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height  = 268
    },
    {
        filename = "cs_crackhouse",
        displayname = "Crackhouse",
        image = "https://images.steamusercontent.com/ugc/1750232228698514116/6E2654B0E3F4E6E80D0DC12A3633B0910A24F751/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height  = 268
    },
    {
        filename = "tdm_city18",
        displayname = "TDM City 18",
        image = "https://images.steamusercontent.com/ugc/2527164217078965837/B38DB5B6DA32203F20A731E37FFEA14C1A255EEC/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height  = 268
    },
    {
        filename = "gm_school",
        displayname = "School",
        image = "https://images.steamusercontent.com/ugc/775121485789043482/74EFA9D4F62E3F78319D43D07FBFEFE48623D0B1/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "cs_drugbust_winter",
        displayname = "Drugbust Winter",
        image = "https://images.steamusercontent.com/ugc/2006946920142316635/11DDD4E2D8633F8C61E5E094E3EA14EA27EF31F2/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "gm_trainride_v1",
        displayname = "Trainride V1",
        image = "https://images.steamusercontent.com/ugc/1832406284767492757/322E3E13BCC78CBB0B77D9FEEEB9B20A911462E9/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "gm_trainride_v1_day",
        displayname = "Trainride V1 Day",
        image = "https://images.steamusercontent.com/ugc/1832406284767492757/322E3E13BCC78CBB0B77D9FEEEB9B20A911462E9/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=true",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_silence_v3",
        displayname = "Silence V3",
        image = "https://images.steamusercontent.com/ugc/379784372259838181/EBCA7705D20FAEE2789FA44259EEDD28A49F5D89/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_forest_final_winter",
        displayname = "Winter Forest",
        image = "https://images.steamusercontent.com/ugc/1957405421774596902/82DF313BD6A0D71F195DD4AC39D3C1BF93082980/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "zs_last_mansion_v3",
        displayname = "Last Mansion V3",
        image = "https://images.steamusercontent.com/ugc/46502257633427922/0E6DAE34CA47274A0C978DBFC774F4C48A87A83F/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "gm_eliden_hmcd",
        displayname = "Eliden",
        image = "https://images.steamusercontent.com/ugc/1870709225849737923/FB608035E31262C7BC4B6E89719DF5954A9DDD87/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "gm_militia_big",
        displayname = "Militia",
        image = "https://images.steamusercontent.com/ugc/134374981574693361/719D17E1DC24EA80EF4FF0732A614957565F664E/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_67thway_2022_snow",
        displayname = "67th Way Snow",
        image = "https://images.steamusercontent.com/ugc/15720291948107546497/420C51782B8FB7E34C1A4F195C091D3D4EDF1882/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "gm_ridgemont",
        displayname = "Ridgemont",
        image = "https://images.steamusercontent.com/ugc/1662354326143992504/DC27B1E7B90389B0A7A18512A9E527C8AE66CF34/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "gm_everpine_mall",
        displayname = "Everpine Mall",
        image = "https://images.steamusercontent.com/ugc/19810950073279739/4F41E5B6AD43B40ABE556970E81DC1DE9847B4DC/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "zs_sawdust_v1",
        displayname = "Sawdust",
        image = "https://images.steamusercontent.com/ugc/35570581922085632/DBBF90E30189B1B51EF3536183663D890EF7C2D6/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "hmcd_aircraft",
        displayname = "Aircraft",
        image = "https://images.steamusercontent.com/ugc/2523786576349586926/768C156E22C1B9B9E0D86E74649F3F067BC65226/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "hmcd_govnova_reborn",
        displayname = "GovNova Bunker",
        image = "https://images.steamusercontent.com/ugc/11068454583659878848/226E6743282A415FC2BE9CA549E375DBF7038DC0/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_hydropower_a2",
        displayname = "Hydropower",
        image = "https://images.steamusercontent.com/ugc/529509313124806019/46E596F5DB6E68A58DBB88353DDDE065EB83FBCC/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_amsterville_open",
        displayname = "Amsterville",
        image = "https://images.steamusercontent.com/ugc/2028364316137680198/05C5B9E1F6E75093EEAC61EC3D2232DFC2A279CB/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "zs_voshod",
        displayname = "Voshod",
        image = "https://images.steamusercontent.com/ugc/1805375036512604172/8993238103DAAD42114F78D84C95B3559B7BDCC5/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "zs_drifting",
        displayname = "Drifting",
        image = "https://images.steamusercontent.com/ugc/2026096911684949585/8BA635AF188EC5245B7C8F44AC20C87553B621D1/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "zs_heat_b1",
        displayname = "Heat",
        image = "https://images.steamusercontent.com/ugc/1649970773457070498/4A284D00D3928781535A4D4BB0C41181A46602BB/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "mu_rascal",
        displayname = "Rascal",
        image = "https://images.steamusercontent.com/ugc/13296198065049929233/31F2A869169F79FEAF15C26BFA9A2E2E601B822F/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "mu_powerhermit",
        displayname = "Powerhermit",
        image = "https://images.steamusercontent.com/ugc/703985853899817204/7664C9E0912978F352997C6C1FB08EDCB7BA5368/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "gm_starcatcher",
        displayname = "Starcatcher",
        image = "https://images.steamusercontent.com/ugc/9658284846745366154/F51F99D143AF9A5AAC911A4FCFED40F831A927E3/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "gm_harkov",
        displayname = "Harkov",
        image = "https://images.steamusercontent.com/ugc/10112306132558120889/66CAE8C7C6D5CD8651CD202A36699B9F3211330B/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "gm_prahovsk",
        displayname = "Prahovsk",
        image = "https://images.steamusercontent.com/ugc/11139530370730097225/BDCE57D39C846409CE5A26C8D68BA1E6F32A097F/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_solitude",
        displayname = "Solitude",
        image = "https://images.steamusercontent.com/ugc/10601187286189225885/5625BC0039636F283E187B21C778326E819A501D/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "gm_favela_rio_remastered",
        displayname = "Favela",
        image = "https://images.steamusercontent.com/ugc/12435126454723187248/C811B039A4AEE055B033773E3625FCFBC8F480B1/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "gm_insanitation",
        displayname = "Insanitation",
        image = "https://images.steamusercontent.com/ugc/13879621759954751612/F9BF2247A1D265DB23E6CFB9E4C0A7E212E5FFE3/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "gm_tiny_town",
        displayname = "Tiny Town",
        image = "https://images.steamusercontent.com/ugc/2398818428207620639/978B5063A89D8E45F423530E31DC1C3ADA5E15E2/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "gm_punchinello_manor",
        displayname = "Punchinello Manor",
        image = "https://images.steamusercontent.com/ugc/2058745927407280277/F1A0F91F4A5D33DA338788AF6E5C560C8044BD39/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "mu_silence",
        displayname = "Silence",
        image = "https://images.steamusercontent.com/ugc/379784372259838181/EBCA7705D20FAEE2789FA44259EEDD28A49F5D89/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "gm_k9",
        displayname = "K-9 Storage Facility",
        image = "https://images.steamusercontent.com/ugc/16469160010025932565/92BE750EFD0765A3E8A8B6A454D52EC3797944E9/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "gm_ivaylograd_kv_evn",
        displayname = "Kvartal",
        image = "https://images.steamusercontent.com/ugc/16350658120426497129/FCB662A6C98A4EE0611C6F71FEDC3ACD497319F9/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 637,
        height = 358
    },
	{
        filename = "ttt_clue_2018_b7",
        displayname = "Clue 2018",
        image = "https://images.steamusercontent.com/ugc/950710827589021653/19843C74E5344457E7CBCAE5672FA4184A640622/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 637,
        height = 358
    },
	{
        filename = "zc_vottur_day",
        displayname = "VOTTUR'S CITY Day",
        image = "https://images.steamusercontent.com/ugc/12318784542214988163/6E469D4D369C4E87CE708EEC76E422557CC8F16B/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 637,
        height = 358
    },
	{
        filename = "zc_vottur_night",
        displayname = "VOTTUR'S CITY Night",
        image = "https://images.steamusercontent.com/ugc/16225326713038200949/316C8CAD9506C1AC90B996B7A91ED234FD804D74/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 637,
        height = 358
    },
    {
        filename = "zc_vottur_tower",
        displayname = "VOTTUR'S TOWER",
        image = "https://images.steamusercontent.com/ugc/13858793403075668525/C5F2045E0777AF35BAA119330997110269709CFA/?imw=268&imh=268&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "gm_home_alone",
        displayname = "Home Alone",
        image = "https://images.steamusercontent.com/ugc/11917605550046938/74FD21CCB04ADB8A16C4DD9E83E234F4C5324D76/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "gm_snowyisolation_v3",
        displayname = "Snowy Isolation v3",
        image = "https://images.steamusercontent.com/ugc/13046857339538012/173BA5FD5BFF427DB42511BAE9E74293C785267B/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "hdn_greenhouse_ghs_v1",
        displayname = "Greenhouse GHS v1",
        image = "https://images.steamusercontent.com/ugc/964242373530407479/4830B71D50238139FDD9F072F3282F432388AE74/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_airship_toppat",
        displayname = "Airship Toppat",
        image = "https://images.steamusercontent.com/ugc/1769328768782642745/0B10FA042C9D0D7F79BE6905681C40CB826DB213/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_auskeld_v1_1",
        displayname = "Auskeld v1.1",
        image = "https://images.steamusercontent.com/ugc/1678114490700753156/44E5D230B47B1ADC8EC533B8404DB570DB6952E2/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_casino_b2",
        displayname = "Casino B2",
        image = "https://images.steamusercontent.com/ugc/578997538652521602/F150D0E8F3A92FCAC0A0D90A253DC22D949A981F/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_foundation_v2_d",
        displayname = "Foundation v2 D",
        image = "https://images.steamusercontent.com/ugc/796491922828695312/44906C9A38011ECF313B2F3008A62129559C481C/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 637,
        height = 358
    },
    {
        filename = "ttt_nuclear_power_v4_fix",
        displayname = "Nuclear Power v4 Fix",
        image = "https://images.steamusercontent.com/ugc/860612763730484377/63134A9AD6772B47ECC23F9ED72CBC436EB61FD4/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_orange_v7",
        displayname = "Orange v7",
        image = "https://images.steamusercontent.com/ugc/456284853358485263/1BC20FD267A29D77F3398BE5E0183912433970B6/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_pizzeria",
        displayname = "Pizzeria",
        image = "https://images.steamusercontent.com/ugc/2453979000636834132/3B99366A8D18DC067E3762CBF3C13B8AD57E2D42/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_vault",
        displayname = "Vault",
        image = "https://images.steamusercontent.com/ugc/544149264727946531/AF6AB253D5B8DE7C170CD1CC2D6E35A45F7B4957/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "ttt_stargate_v3",
        displayname = "Stargate",
        image = "https://images.steamusercontent.com/ugc/903259359322881771/27E4F438461B6A1928BB0F77F67232B26B5E0C89/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "gm_oxxo",
        displayname = "Oxxo",
        image = "https://images.steamusercontent.com/ugc/781867987194137120/6BC3A0146FD3AFCE440C9F5DE859FFF69B2C3256/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "ttt_canyon_a4",
        displayname = "Canyon",
        image = "https://images.steamusercontent.com/ugc/486689151667383992/2F35B07C595F7580367536643F3B2FC6275FA1BA/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "ttt_stage_v3_0",
        displayname = "Stage",
        image = "https://images.steamusercontent.com/ugc/865110520232480888/33476932CD1C0CBE29B73C24942E8F566F7B0E45/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "ttt_winterplant_v4",
        displayname = "Winterplant",
        image = "https://images.steamusercontent.com/ugc/770601643786475721/B7CFF52C85407BF9AB8572C46F96418AF9758C4E/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "zs_shelter",
        displayname = "Shelter",
        image = "https://images.steamusercontent.com/ugc/3317202693785667339/ED1E063C82378F027AE73A93AD22E1F1F6A96364/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "gm_home_alone_1990",
        displayname = "Home Alone Christmas",
        image = "https://images.steamusercontent.com/ugc/17736287768451493774/2D769405A112DF5D0D4DBC670002EA5CE0133FDE/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "gm_building",
        displayname = "Building",
        image = "https://images.steamusercontent.com/ugc/2079019096598879715/04051FF541403AA374D7444166DDDE8928D60E0F/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "gm_snowyisolation",
        displayname = "Snowy Isolation",
        image = "https://images.steamusercontent.com/ugc/2057623194783765116/8CDA3A4B53A2FE21C94BE28791F650D11A0A832B/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "ttt_bank_change",
        displayname = "Bank Change",
        image = "https://images.steamusercontent.com/ugc/1825645452877242835/452F6141EDC92A7F4FA60A65B464D0FB70533295/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "ttt_clue_se_2017",
        displayname = "Clue 2017",
        image = "https://images.steamusercontent.com/ugc/830203174351645012/1EF3CBCE35D954F4C3991628EB814A41C6B98E91/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "ttt_drugbust",
        displayname = "Drugbust",
        image = "https://images.steamusercontent.com/ugc/2036226847537466967/E84DB419F4464D26836DEE2416BA1CAC9E9BA73A/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "ttt_grovestreet_los",
        displayname = "Grovestreet, Home",
        image = "https://images.steamusercontent.com/ugc/1495712445435603756/BB9A9C5240FA0A5B1A2E267DC7E7989A2B610D17/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "ttt_scarisland_withframes_a4",
        displayname = "Scarisland",
        image = "https://images.steamusercontent.com/ugc/101728956006096828/2FF30995F6F574164B8B4D044275DC4797EED4A1/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "ttt_terrortown_smaller",
        displayname = "Terrortown Small",
        image = "https://images.steamusercontent.com/ugc/1018317674975166176/25404DB0CA607A9F2C2E3D338EF4D7128D2D6D95/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "ttt_terrortrain_2019_b1",
        displayname = "Terrortrain 2019",
        image = "https://images.steamusercontent.com/ugc/780727133410252428/7A6E26CE724A63369569429E808AC32082840D1E/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "ttt_vessel_opt_v4",
        displayname = "Vessel V4",
        image = "https://images.steamusercontent.com/ugc/921252182285605587/EDC7B9E5F22D5E7B0C503F67C98383D2E980C745/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "ttt_waterworld_dd",
        displayname = "Waterworld DD",
        image = "https://images.steamusercontent.com/ugc/1874075510967167742/12DAC2DFF0D48F9AD47BBBA20BA942C1E64109B6/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "zgr_freeway_thicc_v3",
        displayname = "Freeway Thicc",
        image = "https://images.steamusercontent.com/ugc/2451740164185127624/79BA8D5F474E08BF8E8236F8D0545DAD038FF72B/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "zm_ship_r1",
        displayname = "Ship R1",
        image = "https://images.steamusercontent.com/ugc/2503513338727146746/68C70C99BC4859C3C94DE691DE90ED1602ABBBC1/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "zm_skyscraper_v1",
        displayname = "Skyscraper",
        image = "https://images.steamusercontent.com/ugc/2496773622393982083/6485EEB9398711B6CF102EDC8DF30619C4FC5900/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "zs_dezecrated",
        displayname = "Dezcrated",
        image = "https://images.steamusercontent.com/ugc/1003682826604697114/2AEE28C402EDC5A259D08A82B8426F963E5EEAB4/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "ttt_plaza_b7_opt_v2",
        displayname = "Plaza B7",
        image = "https://images.steamusercontent.com/ugc/1082263151422293339/61E21584DAC52137415445208A5BBA6AA1AF9F25/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "gm_oceantown_night",
        displayname = "Oceantown",
        image = "https://images.steamusercontent.com/ugc/1298674972288966682/66C4C0D3362A998CBBB7956BE3275F3A28DBA649/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
	{
        filename = "gm_oxxo_redux",
        displayname = "Oxxo",
        image = "https://images.steamusercontent.com/ugc/15197703179410690339/464028E62BA2E8D7016B79A558DE4248DBCF47C9/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "rp_subterranean",
        displayname = "Subterranean",
        image = "https://images.steamusercontent.com/ugc/29590816171676392/83A0399EAB5C46B653905F728656530EE0941066/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "ttt_bank_b13",
        displayname = "Bank B13",
        image = "https://images.steamusercontent.com/ugc/359528430872164382/EF54E01134232D78C3DE5AD842FD6905D0F22DDE/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "zgr_ragcom_highway_valley_edit",
        displayname = "Highway Valley",
        image = "https://images.steamusercontent.com/ugc/10881871353073246912/E83099DC61D187A8A7D7D21643AAB72549C4208E/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "zs_krusty_krab_large_v5",
        displayname = "Krusty Krab",
        image = "https://images.steamusercontent.com/ugc/305489015290412097/69041FC3CE61AAF1F5FA8934C58330A90A5C7611/?imw=5000&imh=5000&ima=fit&impolicy=Letterbox&imcolor=%23000000&letterbox=false",
        width = 268,
        height = 268
    },
    {
        filename = "example",
        displayname = "yes",
        image = "",
        width = 268,
        height = 268
    },
}