HG_SANDBOX = HG_SANDBOX or {}

HG_SANDBOX.MAX_ENTITIES = 3
HG_SANDBOX.MAX_VEHICLES = 1
HG_SANDBOX.RESPAWN_DELAY = 30
HG_SANDBOX.RESTRICTED_NWVAR = "hg_sandbox_spawnmenu_restricted"
HG_SANDBOX.RESPAWN_AT_NWVAR = "hg_sandbox_respawn_at"

HG_SANDBOX.AllowedCreationTabs = {
    ["#spawnmenu.category.weapons"] = true,
    ["#spawnmenu.category.entities"] = true,
    ["#spawnmenu.category.vehicles"] = true
}

HG_SANDBOX.BypassGroups = {
	["superadmin"] = true,
	["owner"] = true,
	["servermanager"] = true,
	["headdeveloper"] = true,
	["headadmin"] = true,
	["developer"] = true,
	["admin"] = true,
}

HG_SANDBOX.BlockedWeaponClasses = {
    ["weapon_physcannon"] = true,
    ["gmod_tool"] = true,
    ["weapon_physgun"] = true,
    ["flaregun_homigrad"] = true,
    ["weapon_grapplinghook"] = true,
    ["weapon_fury13"] = true,
    ["weapon_fury16"] = true,
    ["weapon_dp27"] = true,
    ["weapon_gaussssrifffle"] = true,
    ["weapon_hk21"] = true,
    ["weapon_hla_gruntsmg"] = true,
    ["weapon_hla_suppmg"] = true,
    ["weapon_hg_bugbait"] = true,
    ["weapon_hidebox"] = true,
    ["weapon_hg_chainsaw"] = true,
    ["weapon_hg_grenade_tpik"] = true,
    ["weapon_hg_coolhands"] = true,
    ["weapon_hg_rgd_tpik"] = true,
    ["weapon_hg_flashbang_tpik"] = true,
    ["weapon_hg_motiontracker"] = true,
    ["weapon_hg_pipebomb_tpik"] = true,
    ["weapon_hg_molotov_tpik"] = true,
    ["weapon_hg_f1_tpik"] = true,
    ["weapon_hg_rpg"] = true,
    ["weapon_kord"] = true,
    ["weapon_matches"] = true,
    ["weapon_m249"] = true,
    ["weapon_m320gl"] = true,
    ["weapon_m60"] = true,
    ["weapon_mg34"] = true,
    ["weapon_mg36"] = true,
    ["weapon_milkormgl"] = true,
    ["weapon_minimi"] = true,
    ["weapon_osapb"] = true,
    ["weapon_pkm"] = true,
    ["weapon_ptrd"] = true,
    ["weapon_rpd"] = true,
    ["weapon_revolverequiem"] = true,
    ["weapon_rpk"] = true,
    ["weapon_combinesniper"] = true,
    ["weapon_bleeding_musket"] = true,
    ["weapon_bugbait"] = true,
    ["weapon_spawnmenu_pda"] = true,
    ["weapon_bombvest"] = true,
    ["weapon_taser"] = true,
    ["weapon_vfirethrower"] = true,
    ["weapon_traitor_poison3"] = true,
    ["weapon_tranquilizer"] = true,
    ["weapon_aa12"] = true,
    ["weapon_aa12labs"] = true,
    ["weapon_ttibenelli"] = true,
    ["weapon_spas12"] = true,
    ["weapon_xm1014"] = true,
    ["weapon_saiga12"] = true,
    ["vort_swep"] = true,
    ["weapon_drr_fuelcan"] = true,
    ["weapon_drr_radar"] = true,
    ["weapon_drr_remote"] = true,
    ["weapon_drr_repairtool"] = true,
    ["weapon_drr_jammer"] = true,
    ["weapon_drr_menu"] = true
}

HG_SANDBOX.BlockedWeaponClassPatterns = {
    ["grenade"] = true,
    ["molotov"] = true,
    ["pipebomb"] = true,
    ["flashbang"] = true,
    ["smokenade"] = true,
    ["rpg"] = true,
    ["rocket"] = true,
    ["c4"] = true,
    ["claymore"] = true,
    ["breachcharge"] = true,
    ["rgd"] = true,
    ["m67"] = true
}

HG_SANDBOX.BlockedWeaponCategoryLabels = {
    ["explosive"] = true,
    ["explosives"] = true
}

HG_SANDBOX.BlockedWeaponCategoryPatterns = {
    ["explosive"] = true
}

HG_SANDBOX.BlockedEntityClasses = {
    ["sent_ball"] = true,
    ["npc_swarm"] = true,
    ["npc_swarm_mother"] = true,
    ["npc_swarm_sentinel"] = true,
    ["npc_swarm_sentry"] = true,
    ["nextbot_fear"] = true,
    ["bot_fear"] = true
}

HG_SANDBOX.BlockedVehicleClasses = {
    ["glide_gtav_akula"] = true,
    ["glide_gtav_annihilator"] = true,
    ["glide_gtav_avenger"] = true,
    ["glide_gtav_buzzard2"] = true,
    ["glide_gtav_blimp"] = true,
    ["glide_gtav_blimp2"] = true,
    ["glide_gtav_hunter"] = true,
    ["glide_gtav_savage"] = true,
    ["gtav_airbus"] = true,
    ["gtav_jb700"] = true,
    ["gtav_rhino"] = true,
    ["gtav_lazer"] = true,
    ["gtav_strikeforce"] = true,
    ["gtav_insurgent"] = true,
    ["glide_ruscars_vaz2107"] = true,
    ["td_militaryapc1_glide"] = true,
    ["td2_policeapc01_glide"] = true,
    ["td2_armoredhumvee01_glide"] = true
}

HG_SANDBOX.BlockedVehicleCategoryLabels = {
    ["zenius armed vehicle"] = true,
    ["half-life 2"] = true,
    ["half life 2"] = true,
    ["stühle"] = true,
    ["stuehle"] = true,
    ["chairs"] = true
}

HG_SANDBOX.BlockedVehicleCategoryPatterns = {
    ["zenius armed vehicle"] = true,
    ["half-life 2"] = true,
    ["half life 2"] = true,
    ["stühle"] = true,
    ["stuehle"] = true,
    ["chairs"] = true
}

HG_SANDBOX.BlockedEntityCategories = {
    ["rewrite drones"] = true,
    ["zcity clothes"] = true,
    ["glide"] = true,
    ["editor"] = true,
    ["half-life 2"] = true,
    ["other"] = true,
    ["sonstiges"] = true,
    ["spass + spiele"] = true,
    ["spaß + spiele"] = true
}

HG_SANDBOX.BlockedEntityCategoryLabels = {
    ["rewrite drones"] = true,
    ["drones rewrite"] = true,
    ["zcity clothes"] = true,
    ["glide"] = true,
    ["editor"] = true,
    ["half-life 2"] = true,
    ["half life 2"] = true,
    ["sonstiges"] = true,
    ["sonstige"] = true,
    ["spass + spiele"] = true,
    ["spaß + spiele"] = true
}

HG_SANDBOX.BlockedEntityCategoryPatterns = {
    ["rewrite drones"] = true,
    ["drones rewrite"] = true,
    ["zcity clothes"] = true,
    ["glide"] = true,
    ["editor"] = true,
    ["half-life 2"] = true,
    ["half life 2"] = true,
    ["sonstige"] = true,
    ["sonstiges"] = true,
    ["spass + spiele"] = true,
    ["spaß + spiele"] = true,
    ["fun + games"] = true
}

HG_SANDBOX.BlockedSpawnEntityCategories = {
    ["rewrite drones"] = true,
    ["drones rewrite"] = true,
    ["zcity clothes"] = true,
    ["half-life 2"] = true,
    ["half life 2"] = true,
    ["sonstiges"] = true,
    ["sonstige"] = true
}

HG_SANDBOX.BlockedSpawnEntityCategoryPatterns = {
    ["rewrite drones"] = true,
    ["drones rewrite"] = true,
    ["zcity clothes"] = true,
    ["half-life 2"] = true,
    ["half life 2"] = true,
    ["sonstiges"] = true,
    ["sonstige"] = true
}

HG_SANDBOX.BlockedGlideNodeLabels = {
    ["glide settings"] = true
}

HG_SANDBOX.BlockedGlideNodePatterns = {
    ["settings"] = true
}

HG_SANDBOX.TrackedSpawns = HG_SANDBOX.TrackedSpawns or {
    entities = {},
    vehicles = {}
}

local string_find = string.find
local string_lower = string.lower
local string_trim = string.Trim

local function normalizeText(value)
    if not isstring(value) then
        value = tostring(value or "")
    end

    return string_lower(string_trim(value))
end

local function matchesBlockedText(value, exactMatches, patternMatches)
    local normalized = normalizeText(value)
    if normalized == "" then return false end
    if exactMatches and exactMatches[normalized] then return true end

    if patternMatches then
        for pattern, _ in pairs(patternMatches) do
            if string_find(normalized, pattern, 1, true) ~= nil then
                return true
            end
        end
    end

    return false
end

function HG_SANDBOX.GetCurrentModeName()
    local roundMode = zb and (zb.CROUND_MAIN or zb.CROUND)
    if isstring(roundMode) and roundMode ~= "" then
        return roundMode
    end

    return engine.ActiveGamemode() or ""
end

function HG_SANDBOX.IsSandboxModeActive()
    local mode = normalizeText(HG_SANDBOX.GetCurrentModeName())

    if mode ~= "" then
        return string_find(mode, "sandbox", 1, true) ~= nil
    end

    return engine.ActiveGamemode() == "sandbox"
end

function HG_SANDBOX.IsBypassPlayer(ply)
    if not IsValid(ply) then return false end

    if zb and zb.PlayerCanSandboxBypass and zb.PlayerCanSandboxBypass(ply) then
        return true
    end

    local group = normalizeText((ply.GetUserGroup and ply:GetUserGroup()) or "")
    return HG_SANDBOX.BypassGroups[group] or false
end

function HG_SANDBOX.IsRestrictedPlayer(ply)
    return IsValid(ply) and HG_SANDBOX.IsSandboxModeActive() and not HG_SANDBOX.IsBypassPlayer(ply)
end

function HG_SANDBOX.ShouldBlockPlayer(ply)
    return IsValid(ply) and not HG_SANDBOX.IsBypassPlayer(ply) and not HG_SANDBOX.IsSandboxModeActive()
end

function HG_SANDBOX.ShouldHideSpawnmenu(ply)
    return IsValid(ply) and not HG_SANDBOX.IsBypassPlayer(ply) and not HG_SANDBOX.IsSandboxModeActive()
end

function HG_SANDBOX.IsBlockedWeaponClass(class)
    return matchesBlockedText(class, HG_SANDBOX.BlockedWeaponClasses, HG_SANDBOX.BlockedWeaponClassPatterns)
end

function HG_SANDBOX.IsBlockedEntityClass(class)
    return HG_SANDBOX.BlockedEntityClasses[normalizeText(class)] or false
end

function HG_SANDBOX.IsBlockedVehicleClass(class)
    return HG_SANDBOX.BlockedVehicleClasses[normalizeText(class)] or false
end

function HG_SANDBOX.IsBlockedEntityCategory(category)
    return matchesBlockedText(category, HG_SANDBOX.BlockedSpawnEntityCategories, HG_SANDBOX.BlockedSpawnEntityCategoryPatterns)
end

function HG_SANDBOX.IsBlockedEntityCategoryLabel(category)
    return matchesBlockedText(category, HG_SANDBOX.BlockedEntityCategoryLabels, HG_SANDBOX.BlockedEntityCategoryPatterns)
end

function HG_SANDBOX.IsBlockedGlideNodeLabel(label)
    return matchesBlockedText(label, HG_SANDBOX.BlockedGlideNodeLabels, HG_SANDBOX.BlockedGlideNodePatterns)
end

function HG_SANDBOX.IsBlockedWeaponCategoryLabel(label)
    return matchesBlockedText(label, HG_SANDBOX.BlockedWeaponCategoryLabels, HG_SANDBOX.BlockedWeaponCategoryPatterns)
end

function HG_SANDBOX.IsBlockedVehicleCategoryLabel(label)
    return matchesBlockedText(label, HG_SANDBOX.BlockedVehicleCategoryLabels, HG_SANDBOX.BlockedVehicleCategoryPatterns)
end

function HG_SANDBOX.IsBlockedVehicleSidebarLabel(label)
    return HG_SANDBOX.IsBlockedVehicleCategoryLabel(label) or HG_SANDBOX.IsBlockedGlideNodeLabel(label)
end

local function getWeaponData(class)
    local weaponList = list.Get("Weapon") or {}
    local swep = weapons.GetStored(class)
    if istable(swep) then
        return swep
    end

    return weaponList[class]
end

local function getEntityData(class)
    local entityList = list.Get("SpawnableEntities") or {}
    local stored = scripted_ents.GetStored(class)
    if istable(stored) and istable(stored.t) then
        return stored.t
    end

    local ent = scripted_ents.Get(class)
    if istable(ent) then
        return ent
    end

    return entityList[class]
end

function HG_SANDBOX.GetWeaponCategory(class)
    local data = getWeaponData(class)
    return istable(data) and data.Category or nil
end

function HG_SANDBOX.GetVehicleCategory(class)
    local data = getVehicleData(class)
    return istable(data) and data.Category or nil
end

local function getVehicleData(class)
    local vehicleList = list.Get("Vehicles") or {}
    local vehicle = vehicleList[class]
    if istable(vehicle) then
        return vehicle
    end

    return getEntityData(class)
end

function HG_SANDBOX.IsAdminOnlyWeapon(class)
    local data = getWeaponData(class)
    return istable(data) and data.AdminOnly or false
end

function HG_SANDBOX.IsAdminOnlyEntity(class)
    local data = getEntityData(class)
    return istable(data) and data.AdminOnly or false
end

function HG_SANDBOX.IsAdminOnlyVehicle(class)
    local data = getVehicleData(class)
    return istable(data) and data.AdminOnly or false
end

function HG_SANDBOX.GetEntityCategory(class)
    local data = getEntityData(class)
    return istable(data) and data.Category or nil
end

function HG_SANDBOX.IsVehicleClass(class)
    local vehicleList = list.Get("Vehicles") or {}
    if vehicleList[class] then
        return true
    end

    local data = getEntityData(class)
    if not istable(data) then
        return false
    end

    if data.GlideCategory ~= nil then
        return true
    end

    local base = normalizeText(data.Base or "")
    return string_find(base, "base_glide", 1, true) ~= nil
end

function HG_SANDBOX.GetTrackedBucket(ply, kind)
    if not IsValid(ply) then return {} end

    local steamID = ply:SteamID64() or ("ent_" .. ply:EntIndex())
    HG_SANDBOX.TrackedSpawns[kind][steamID] = HG_SANDBOX.TrackedSpawns[kind][steamID] or {}

    return HG_SANDBOX.TrackedSpawns[kind][steamID]
end

function HG_SANDBOX.GetTrackedCount(ply, kind)
    local bucket = HG_SANDBOX.GetTrackedBucket(ply, kind)
    local count = 0

    for ent, _ in pairs(bucket) do
        if not IsValid(ent) then
            bucket[ent] = nil
        else
            count = count + 1
        end
    end

    return count
end

function HG_SANDBOX.TrackSpawn(ply, ent, kind)
    if not IsValid(ply) or not IsValid(ent) then return end

    local bucket = HG_SANDBOX.GetTrackedBucket(ply, kind)
    bucket[ent] = true

    ent:CallOnRemove("HG_SandboxTrack_" .. kind, function(removed)
        if not IsValid(ply) then return end

        local targetBucket = HG_SANDBOX.GetTrackedBucket(ply, kind)
        targetBucket[removed] = nil
    end)
end

function HG_SANDBOX.ClearTrackedSpawns(ply)
    if not IsValid(ply) then return end

    local steamID = ply:SteamID64() or ("ent_" .. ply:EntIndex())
    HG_SANDBOX.TrackedSpawns.entities[steamID] = nil
    HG_SANDBOX.TrackedSpawns.vehicles[steamID] = nil
end

function HG_SANDBOX.NotifyDenied(ply, key, message)
    if CLIENT then return end
    if not IsValid(ply) or not isstring(message) or message == "" then return end

    ply.HG_SandboxNotifyCooldowns = ply.HG_SandboxNotifyCooldowns or {}

    local cooldownKey = key or message
    local nextAllowed = ply.HG_SandboxNotifyCooldowns[cooldownKey] or 0
    if nextAllowed > CurTime() then return end

    ply.HG_SandboxNotifyCooldowns[cooldownKey] = CurTime() + 0.75
    ply:ChatPrint(message)
end

function HG_SANDBOX.CanSpawnWeapon(ply, class)
    if HG_SANDBOX.IsBypassPlayer(ply) then return end
    if not HG_SANDBOX.IsSandboxModeActive() then return false end
    if HG_SANDBOX.IsBlockedWeaponClass(class) then
        HG_SANDBOX.NotifyDenied(ply, "weapon_blocked", "This weapon is disabled in Sandbox Mode.")
        return false
    end

    if HG_SANDBOX.IsBlockedWeaponCategoryLabel(HG_SANDBOX.GetWeaponCategory(class)) then
        HG_SANDBOX.NotifyDenied(ply, "weapon_explosive", "Explosive weapons are disabled in Sandbox Mode.")
        return false
    end

    if HG_SANDBOX.IsAdminOnlyWeapon(class) then
        HG_SANDBOX.NotifyDenied(ply, "weapon_admin_only", "Admin-only spawnables are disabled in Sandbox Mode.")
        return false
    end

    return true
end

function HG_SANDBOX.CanSpawnEntity(ply, class)
    if HG_SANDBOX.IsBypassPlayer(ply) then return end
    if not HG_SANDBOX.IsSandboxModeActive() then return false end
    if HG_SANDBOX.IsBlockedEntityClass(class) then
        HG_SANDBOX.NotifyDenied(ply, "entity_blocked", "This entity is disabled in Sandbox Mode.")
        return false
    end

    if HG_SANDBOX.IsAdminOnlyEntity(class) then
        HG_SANDBOX.NotifyDenied(ply, "entity_admin_only", "Admin-only spawnables are disabled in Sandbox Mode.")
        return false
    end

    if HG_SANDBOX.IsBlockedEntityCategory(HG_SANDBOX.GetEntityCategory(class)) then
        HG_SANDBOX.NotifyDenied(ply, "entity_category_blocked", "This entity category is disabled in Sandbox Mode.")
        return false
    end

    if HG_SANDBOX.GetTrackedCount(ply, "entities") >= HG_SANDBOX.MAX_ENTITIES then
        HG_SANDBOX.NotifyDenied(ply, "entity_limit", "You can only spawn 3 entities in Sandbox Mode.")
        return false
    end

    return true
end

function HG_SANDBOX.CanSpawnVehicle(ply, class)
    if HG_SANDBOX.IsBypassPlayer(ply) then return end
    if not HG_SANDBOX.IsSandboxModeActive() then return false end

    if HG_SANDBOX.IsBlockedVehicleClass(class) then
        HG_SANDBOX.NotifyDenied(ply, "vehicle_blocked", "This vehicle is disabled in Sandbox Mode.")
        return false
    end

    if HG_SANDBOX.IsAdminOnlyVehicle(class) then
        HG_SANDBOX.NotifyDenied(ply, "vehicle_admin_only", "Admin-only spawnables are disabled in Sandbox Mode.")
        return false
    end

    if HG_SANDBOX.GetTrackedCount(ply, "vehicles") >= HG_SANDBOX.MAX_VEHICLES then
        HG_SANDBOX.NotifyDenied(ply, "vehicle_limit", "You can only spawn 1 vehicle in Sandbox Mode.")
        return false
    end

    return true
end

if SERVER then
    local lastSandboxState = nil
    local nextNetworkSync = 0

    local function updateRestrictionState(ply)
        if not IsValid(ply) then return end

        ply:SetNWBool(HG_SANDBOX.RESTRICTED_NWVAR, HG_SANDBOX.IsRestrictedPlayer(ply))
    end

    local function setRespawnTime(ply, delay)
        if not IsValid(ply) then return end

        ply:SetNWFloat(HG_SANDBOX.RESPAWN_AT_NWVAR, CurTime() + (delay or HG_SANDBOX.RESPAWN_DELAY))
    end

    local function clearRespawnTime(ply)
        if not IsValid(ply) then return end

        ply:SetNWFloat(HG_SANDBOX.RESPAWN_AT_NWVAR, 0)
    end

    local function rememberPlayableTeam(ply)
        if not IsValid(ply) then return end

        local spectatorTeam = rawget(_G, "TEAM_SPECTATOR")
        local teamID = ply:Team()
        if spectatorTeam and teamID == spectatorTeam then return end

        ply.HG_SandboxLastPlayableTeam = teamID
    end

    local function applySandboxSpawnLoadout(ply)
        if not IsValid(ply) or not ply:Alive() then return end
        if not HG_SANDBOX.IsSandboxModeActive() then return end

        ply:SetSuppressPickupNotices(true)
        ply:StripWeapons()
        ply:RemoveAllAmmo()

        local hands = ply:Give("weapon_hands_sh")
        if IsValid(hands) then
            ply:SelectWeapon("weapon_hands_sh")
        else
            ply:SelectWeapon("weapon_hands_sh")
        end

        timer.Simple(0, function()
            if not IsValid(ply) then return end

            ply:SetSuppressPickupNotices(false)
        end)
    end

    local function getSandboxSpectateTarget(ply)
        local spectatorTeam = rawget(_G, "TEAM_SPECTATOR")
        local fallback

        for _, other in ipairs(player.GetAll()) do
            if not IsValid(other) then continue end

            fallback = fallback or other

            if other ~= ply and other:Alive() and (not spectatorTeam or other:Team() ~= spectatorTeam) then
                return other
            end
        end

        return fallback or ply
    end

    local function applySandboxFreeRoamSpectator(ply)
        if not IsValid(ply) then return end
        if not HG_SANDBOX.IsSandboxModeActive() then return end

        local spectatorTeam = rawget(_G, "TEAM_SPECTATOR")
        local isSpectatorState = not ply:Alive() or (spectatorTeam and ply:Team() == spectatorTeam)
        if not isSpectatorState then return end

        local spectTarget = getSandboxSpectateTarget(ply)

        ply.viewmode = 3
        ply.chosenSpectEntity = spectTarget
        ply.chosenspect = IsValid(spectTarget) and spectTarget:EntIndex() or 1
        ply.lastSpectTarget = spectTarget
        ply:SetNWInt("viewmode", 3)

        if IsValid(spectTarget) then
            ply:SetNWEntity("spect", spectTarget)
        end

        if ply:GetObserverMode() ~= OBS_MODE_ROAMING then
            ply:Spectate(OBS_MODE_ROAMING)
        end

        if ply:GetMoveType() ~= MOVETYPE_NOCLIP then
            ply:SetMoveType(MOVETYPE_NOCLIP)
        end
    end

    local function respawnSandboxPlayer(ply)
        if not IsValid(ply) then return end

        local spectatorTeam = rawget(_G, "TEAM_SPECTATOR")
        local targetTeam = ply.HG_SandboxLastPlayableTeam or ply:Team()

        if spectatorTeam and targetTeam == spectatorTeam then
            targetTeam = 0
        end

        if not isnumber(targetTeam) then
            targetTeam = 0
        end

        if ply:Team() ~= targetTeam then
            ply:SetTeam(targetTeam)
        end

        if ply.SetupTeam then
            ply:SetupTeam(targetTeam)
        end

        clearRespawnTime(ply)
        ply:Spawn()

        timer.Simple(0, function()
            if not IsValid(ply) or not ply:Alive() then return end
            if not HG_SANDBOX.IsSandboxModeActive() then return end

            if ply.GetRandomSpawn then
                ply:GetRandomSpawn()
            end
        end)
    end

    local function canUseSandboxRespawn(ply)
        if not HG_SANDBOX.IsSandboxModeActive() then return false end

        local respawnAt = ply:GetNWFloat(HG_SANDBOX.RESPAWN_AT_NWVAR, 0)
        return respawnAt > 0 and CurTime() >= respawnAt
    end

    hook.Add("PlayerInitialSpawn", "HG_SandboxInitialState", function(ply)
        updateRestrictionState(ply)
        clearRespawnTime(ply)
    end)

    hook.Add("PlayerDisconnected", "HG_SandboxCleanupState", function(ply)
        HG_SANDBOX.ClearTrackedSpawns(ply)
    end)

    hook.Add("PlayerSpawn", "HG_SandboxSpawnState", function(ply)
        updateRestrictionState(ply)
        clearRespawnTime(ply)
        rememberPlayableTeam(ply)

        timer.Simple(0, function()
            if not IsValid(ply) then return end

            applySandboxSpawnLoadout(ply)
        end)
    end)

    hook.Add("PlayerDeath", "HG_SandboxStartRespawnTimer", function(ply)
        if not HG_SANDBOX.IsSandboxModeActive() then return end

        setRespawnTime(ply, HG_SANDBOX.RESPAWN_DELAY)

        timer.Simple(0, function()
            if not IsValid(ply) then return end

            applySandboxFreeRoamSpectator(ply)
        end)
    end)

    hook.Add("OnPlayerChangedTeam", "HG_SandboxSpectatorRespawnTimer", function(ply, oldTeam, newTeam)
        local spectatorTeam = rawget(_G, "TEAM_SPECTATOR")
        if not spectatorTeam or newTeam ~= spectatorTeam then
            rememberPlayableTeam(ply)
        end

        if not spectatorTeam or newTeam ~= spectatorTeam then return end
        if not HG_SANDBOX.IsSandboxModeActive() then return end

        if ply:GetNWFloat(HG_SANDBOX.RESPAWN_AT_NWVAR, 0) <= CurTime() then
            setRespawnTime(ply, HG_SANDBOX.RESPAWN_DELAY)
        end

        timer.Simple(0, function()
            if not IsValid(ply) then return end

            applySandboxFreeRoamSpectator(ply)
        end)
    end)

    hook.Add("Think", "HG_SandboxSyncState", function()
        if nextNetworkSync > CurTime() then return end

        nextNetworkSync = CurTime() + 1
        local spectatorTeam = rawget(_G, "TEAM_SPECTATOR")

        local sandboxState = HG_SANDBOX.IsSandboxModeActive()
        if sandboxState ~= lastSandboxState then
            lastSandboxState = sandboxState

            for _, ply in ipairs(player.GetAll()) do
                updateRestrictionState(ply)

                if sandboxState then
                    local isRespawnState = not ply:Alive() or (spectatorTeam and ply:Team() == spectatorTeam)
                    if isRespawnState and ply:GetNWFloat(HG_SANDBOX.RESPAWN_AT_NWVAR, 0) <= 0 then
                        setRespawnTime(ply, HG_SANDBOX.RESPAWN_DELAY)
                    end

                    if isRespawnState then
                        applySandboxFreeRoamSpectator(ply)
                    end
                else
                    clearRespawnTime(ply)
                end
            end

            return
        end

        for _, ply in ipairs(player.GetAll()) do
            updateRestrictionState(ply)

            if sandboxState then
                local isRespawnState = not ply:Alive() or (spectatorTeam and ply:Team() == spectatorTeam)
                if isRespawnState and ply:GetNWFloat(HG_SANDBOX.RESPAWN_AT_NWVAR, 0) <= 0 then
                    setRespawnTime(ply, HG_SANDBOX.RESPAWN_DELAY)
                end

                if isRespawnState then
                    applySandboxFreeRoamSpectator(ply)
                end
            end
        end
    end)

    hook.Add("PlayerDeathThink", "HG_SandboxDeathRespawn", function(ply)
        if not HG_SANDBOX.IsSandboxModeActive() then return end

        if canUseSandboxRespawn(ply) and ply:KeyDown(IN_JUMP) then
            respawnSandboxPlayer(ply)
            return true
        end

        return true
    end)

    hook.Add("KeyPress", "HG_SandboxSpectatorRespawn", function(ply, key)
        if key ~= IN_JUMP then return end
        if not canUseSandboxRespawn(ply) then return end
        if not ply:Alive() then return end

        local spectatorTeam = rawget(_G, "TEAM_SPECTATOR")
        if spectatorTeam and ply:Team() == spectatorTeam then
            respawnSandboxPlayer(ply)
        end
    end)

    hook.Add("PlayerSpawnedSENT", "HG_SandboxTrackSENT", function(ply, ent)
        if not HG_SANDBOX.IsRestrictedPlayer(ply) then return end

        if HG_SANDBOX.IsVehicleClass(ent:GetClass()) then
            HG_SANDBOX.TrackSpawn(ply, ent, "vehicles")
            return
        end

        HG_SANDBOX.TrackSpawn(ply, ent, "entities")
    end)

    hook.Add("PlayerSpawnedVehicle", "HG_SandboxTrackVehicle", function(ply, ent)
        if not HG_SANDBOX.IsRestrictedPlayer(ply) then return end

        HG_SANDBOX.TrackSpawn(ply, ent, "vehicles")
    end)

    hook.Add("PlayerSpawnProp", "HG_SandboxDirectBlockProp", function(ply)
        if HG_SANDBOX.ShouldBlockPlayer(ply) then return false end
        if HG_SANDBOX.IsRestrictedPlayer(ply) then
            HG_SANDBOX.NotifyDenied(ply, "props_disabled", "Props are disabled in Sandbox Mode.")
            return false
        end
    end)

    hook.Add("PlayerSpawnRagdoll", "HG_SandboxDirectBlockRagdoll", function(ply)
        if HG_SANDBOX.ShouldBlockPlayer(ply) then return false end
        if HG_SANDBOX.IsRestrictedPlayer(ply) then
            HG_SANDBOX.NotifyDenied(ply, "ragdolls_disabled", "Ragdolls are disabled in Sandbox Mode.")
            return false
        end
    end)

    hook.Add("PlayerSpawnNPC", "HG_SandboxDirectBlockNPC", function(ply)
        if HG_SANDBOX.ShouldBlockPlayer(ply) then return false end
        if HG_SANDBOX.IsRestrictedPlayer(ply) then
            HG_SANDBOX.NotifyDenied(ply, "npcs_disabled", "NPCs are disabled in Sandbox Mode.")
            return false
        end
    end)

    hook.Add("PlayerSpawnEffect", "HG_SandboxDirectBlockEffect", function(ply)
        if HG_SANDBOX.ShouldBlockPlayer(ply) then return false end
        if HG_SANDBOX.IsRestrictedPlayer(ply) then
            HG_SANDBOX.NotifyDenied(ply, "effects_disabled", "Effects are disabled in Sandbox Mode.")
            return false
        end
    end)

    hook.Add("PlayerSpawnObject", "HG_SandboxDirectBlockObject", function(ply)
        if HG_SANDBOX.ShouldBlockPlayer(ply) then return false end
        if HG_SANDBOX.IsRestrictedPlayer(ply) then
            HG_SANDBOX.NotifyDenied(ply, "objects_disabled", "You can only spawn weapons, entities, and vehicles in Sandbox Mode.")
            return false
        end
    end)

    hook.Add("PlayerSpawnSWEP", "HG_SandboxDirectSWEP", function(ply, class)
        if HG_SANDBOX.ShouldBlockPlayer(ply) then return false end
        if HG_SANDBOX.IsRestrictedPlayer(ply) then
            return HG_SANDBOX.CanSpawnWeapon(ply, class)
        end
    end)

    hook.Add("PlayerGiveSWEP", "HG_SandboxDirectGiveSWEP", function(ply, class)
        if HG_SANDBOX.ShouldBlockPlayer(ply) then return false end
        if HG_SANDBOX.IsRestrictedPlayer(ply) then
            return HG_SANDBOX.CanSpawnWeapon(ply, class)
        end
    end)

    hook.Add("PlayerSpawnVehicle", "HG_SandboxDirectVehicle", function(ply, class)
        if HG_SANDBOX.ShouldBlockPlayer(ply) then return false end
        if HG_SANDBOX.IsRestrictedPlayer(ply) then
            return HG_SANDBOX.CanSpawnVehicle(ply, class)
        end
    end)

    hook.Add("PlayerSpawnSENT", "HG_SandboxDirectSENT", function(ply, class)
        if HG_SANDBOX.ShouldBlockPlayer(ply) then return false end
        if HG_SANDBOX.IsRestrictedPlayer(ply) then
            if HG_SANDBOX.IsVehicleClass(class) then
                return HG_SANDBOX.CanSpawnVehicle(ply, class)
            end

            return HG_SANDBOX.CanSpawnEntity(ply, class)
        end
    end)

    hook.Add("CanTool", "HG_SandboxBlockTools", function(ply)
        if HG_SANDBOX.ShouldBlockPlayer(ply) then return false end
        if HG_SANDBOX.IsRestrictedPlayer(ply) then
            HG_SANDBOX.NotifyDenied(ply, "tools_disabled", "Tools are disabled in Sandbox Mode.")
            return false
        end
    end)

    hook.Add("CanProperty", "HG_SandboxBlockProperties", function(ply)
        if HG_SANDBOX.ShouldBlockPlayer(ply) then return false end
        if HG_SANDBOX.IsRestrictedPlayer(ply) then
            HG_SANDBOX.NotifyDenied(ply, "properties_disabled", "Properties and utilities are disabled in Sandbox Mode.")
            return false
        end
    end)
end

if CLIENT then
    local function getLocalPlayer()
        local ply = LocalPlayer()
        if not IsValid(ply) then return nil end

        return ply
    end

    local function isRestrictedClient()
        local ply = getLocalPlayer()
        return IsValid(ply) and ply:GetNWBool(HG_SANDBOX.RESTRICTED_NWVAR, false)
    end

    local function getSandboxModeTimeLeft()
        if zb.ROUND_STATE ~= 1 then return nil end

        local roundTime = tonumber(zb.ROUND_TIME) or 0
        local roundStart = tonumber(zb.ROUND_START) or 0
        if roundTime <= 0 or roundStart <= 0 then return nil end

        return math.max(0, math.ceil((roundStart + roundTime) - CurTime()))
    end

    local function formatSandboxModeTime(seconds)
        local minutes = math.floor(seconds / 60)
        local secs = seconds % 60

        return string.format("%02i:%02i", minutes, secs)
    end

    local function normalizeLabel(value)
        if not isstring(value) then
            value = tostring(value or "")
        end

        local translated = language.GetPhrase(value)
        if isstring(translated) and translated ~= "" then
            value = translated
        end

        return normalizeText(value)
    end

    local function forEachNode(node, callback)
        if not IsValid(node) then return end

        callback(node)

        local children = node.GetChildNodes and node:GetChildNodes()
        if not istable(children) then return end

        for _, child in ipairs(children) do
            forEachNode(child, callback)
        end
    end

    local function clickFirstVisibleNode(tree)
        if not IsValid(tree) then return end

        local root = tree:Root()
        if not IsValid(root) then return end

        local children = root.GetChildNodes and root:GetChildNodes() or {}
        for _, child in ipairs(children) do
            if IsValid(child) and child:IsVisible() then
                child:InternalDoClick()
                return
            end
        end
    end

    local function pruneIconList(panel, blockedRules)
        if not IsValid(panel) or not IsValid(panel.IconList) then return end

        for _, icon in ipairs(panel.IconList:GetChildren()) do
            if IsValid(icon) and icon.GetSpawnName then
                local spawnName = icon:GetSpawnName()
                local shouldHide = false

                if isfunction(blockedRules) then
                    shouldHide = blockedRules(spawnName)
                elseif istable(blockedRules) then
                    shouldHide = blockedRules[normalizeText(spawnName)] or false
                end

                if shouldHide then
                    icon:SetVisible(false)
                end
            end
        end
    end

    local function restrictSidebarNodes(contentPanel, isBlockedFn)
        if not IsValid(contentPanel) or not IsValid(contentPanel.ContentNavBar) then return end

        local tree = contentPanel.ContentNavBar.Tree
        if not IsValid(tree) then return end

        local root = tree:Root()
        if not IsValid(root) then return end

        local nodesToRemove = {}

        forEachNode(root, function(node)
            if node == root then return end
            if not IsValid(node) then return end
            if not isfunction(isBlockedFn) then return end

            if isBlockedFn(node:GetText()) then
                nodesToRemove[#nodesToRemove + 1] = node
            end
        end)

        for _, node in ipairs(nodesToRemove) do
            if IsValid(node) then
                node:Remove()
            end
        end

        root:InvalidateLayout(true)
        tree:InvalidateLayout(true)
        contentPanel.ContentNavBar:InvalidateLayout(true)
        contentPanel:InvalidateLayout(true)

        clickFirstVisibleNode(tree)
    end

    local function applySpawnmenuRestrictions()
        if not IsValid(g_SpawnMenu) then return end

        local restricted = isRestrictedClient()
        local creationMenu = g_SpawnMenu:GetCreationMenu()
        if not IsValid(creationMenu) then return end

        if IsValid(g_SpawnMenu.ToolMenu) and IsValid(g_SpawnMenu.ToolToggle) then
            if restricted then
                if g_SpawnMenu.ToolMenu:IsVisible() then
                    g_SpawnMenu.ToolToggle:DoClick()
                end

                g_SpawnMenu.ToolToggle:SetVisible(false)
            else
                if not g_SpawnMenu.ToolMenu:IsVisible() then
                    g_SpawnMenu.ToolToggle:DoClick()
                end

                g_SpawnMenu.ToolToggle:SetVisible(true)
            end
        end

        for id, tab in pairs(creationMenu:GetCreationTabs()) do
            local visible = not restricted or HG_SANDBOX.AllowedCreationTabs[id]
            if IsValid(tab.Tab) then
                tab.Tab:SetVisible(visible)
            end
        end

        if restricted then
            g_SpawnMenu:OpenCreationMenuTab("#spawnmenu.category.weapons")
        end

        if not restricted then return end

        local tabs = creationMenu:GetCreationTabs()
        local weaponsTab = tabs["#spawnmenu.category.weapons"]
        local entitiesTab = tabs["#spawnmenu.category.entities"]
        local vehiclesTab = tabs["#spawnmenu.category.vehicles"]

        if weaponsTab and IsValid(weaponsTab.ContentPanel) then
            restrictSidebarNodes(weaponsTab.ContentPanel, HG_SANDBOX.IsBlockedWeaponCategoryLabel)
            pruneIconList(weaponsTab.ContentPanel:GetSelectedPanel(), HG_SANDBOX.IsBlockedWeaponClass)
        end

        if entitiesTab and IsValid(entitiesTab.ContentPanel) then
            restrictSidebarNodes(entitiesTab.ContentPanel, HG_SANDBOX.IsBlockedEntityCategoryLabel)
            pruneIconList(entitiesTab.ContentPanel:GetSelectedPanel(), HG_SANDBOX.BlockedEntityClasses)
        end

        if vehiclesTab and IsValid(vehiclesTab.ContentPanel) then
            restrictSidebarNodes(vehiclesTab.ContentPanel, HG_SANDBOX.IsBlockedVehicleSidebarLabel)
            pruneIconList(vehiclesTab.ContentPanel:GetSelectedPanel(), HG_SANDBOX.IsBlockedVehicleClass)
        end
    end

    hook.Add("SpawnMenuOpen", "HG_SandboxSpawnMenuAccess", function()
        local ply = getLocalPlayer()
        if not IsValid(ply) then return end

        if not HG_SANDBOX.IsSandboxModeActive() then
            return
        end

        if HG_SANDBOX.IsBypassPlayer(ply) then
            return
        end

        if HG_SANDBOX.IsRestrictedPlayer(ply) then
            return true
        end

        return false
    end)

    hook.Add("SpawnMenuCreated", "HG_SandboxSpawnMenuCreated", function()
        timer.Simple(0, applySpawnmenuRestrictions)
    end)

    hook.Add("SpawnMenuOpened", "HG_SandboxSpawnMenuOpened", function()
        timer.Simple(0, applySpawnmenuRestrictions)
    end)

    hook.Add("ContentSidebarSelection", "HG_SandboxSidebarSelection", function(contentPanel, node)
        if not isRestrictedClient() then return end

        timer.Simple(0, function()
            if not IsValid(g_SpawnMenu) or not IsValid(node) then return end

            local creationTabs = g_SpawnMenu:GetCreationMenu():GetCreationTabs()
            for id, tab in pairs(creationTabs) do
                if tab.ContentPanel == contentPanel then
                    if id == "#spawnmenu.category.entities" and IsValid(node.PropPanel) then
                        pruneIconList(node.PropPanel, HG_SANDBOX.BlockedEntityClasses)
                    elseif id == "#spawnmenu.category.weapons" and IsValid(node.PropPanel) then
                        pruneIconList(node.PropPanel, HG_SANDBOX.IsBlockedWeaponClass)
                    elseif id == "#spawnmenu.category.vehicles" and IsValid(node.PropPanel) then
                        pruneIconList(node.PropPanel, HG_SANDBOX.IsBlockedVehicleClass)
                    end

                    break
                end
            end
        end)
    end)

    hook.Add("Think", "HG_SandboxCloseMenuOutsideMode", function()
        local ply = getLocalPlayer()
        if not IsValid(ply) or not IsValid(g_SpawnMenu) then return end

        if HG_SANDBOX.ShouldHideSpawnmenu(ply) and g_SpawnMenu:IsVisible() then
            g_SpawnMenu:Close()
        end
    end)

    hook.Add("HUDPaint", "HG_SandboxRespawnHud", function()
        local ply = getLocalPlayer()
        if not IsValid(ply) then return end
        if not HG_SANDBOX.IsSandboxModeActive() then return end

        draw.SimpleTextOutlined("Sandbox Mode", "HomigradFontBig", 24, 20, Color(255, 214, 92), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 220))

        local modeTimeLeft = getSandboxModeTimeLeft()
        if modeTimeLeft then
            local expiresText = "This mode ends in " .. formatSandboxModeTime(modeTimeLeft)
            draw.SimpleTextOutlined(expiresText, "HomigradFont", 24, 56, Color(255, 214, 92), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 220))
        end

        local spectatorTeam = rawget(_G, "TEAM_SPECTATOR")
        local isRespawnState = not ply:Alive() or (spectatorTeam and ply:Team() == spectatorTeam)
        if not isRespawnState then return end

        local respawnAt = ply:GetNWFloat(HG_SANDBOX.RESPAWN_AT_NWVAR, 0)
        if respawnAt <= 0 then return end

        local timeLeft = math.max(0, math.ceil(respawnAt - CurTime()))
        local ready = timeLeft <= 0
        local mainText = ready and "Press SPACE to respawn now" or "Press SPACE to respawn"
        local timerText = ready and "Respawn ready" or ("Respawn available in " .. tostring(timeLeft) .. "s")
        local x = ScrW() * 0.5
        local y = ScrH() * 0.82

        draw.SimpleTextOutlined(mainText, "HomigradFontBig", x, y, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, 220))
        draw.SimpleTextOutlined(timerText, "HomigradFont", x, y + 42, Color(35, 225, 110), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, 220))
    end)
end
