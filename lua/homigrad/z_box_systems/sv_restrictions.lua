ZBox = ZBox or {}
ZBox.Plugins = ZBox.Plugins or {}
ZBox.Plugins["Restrictions"] = ZBox.Plugins["Restrictions"] or {}

local PLUGIN = ZBox.Plugins["Restrictions"]
PLUGIN.Name = "Restrictions"
PLUGIN.Hooks = {}

local Hook = PLUGIN.Hooks

local function shouldBlockPlayer(ply)
    return HG_SANDBOX and HG_SANDBOX.ShouldBlockPlayer and HG_SANDBOX.ShouldBlockPlayer(ply)
end

local function isRestrictedPlayer(ply)
    return HG_SANDBOX and HG_SANDBOX.IsRestrictedPlayer and HG_SANDBOX.IsRestrictedPlayer(ply)
end

local function canSpawnWeapon(ply, class)
    return HG_SANDBOX and HG_SANDBOX.CanSpawnWeapon and HG_SANDBOX.CanSpawnWeapon(ply, class)
end

local function canSpawnEntity(ply, class)
    return HG_SANDBOX and HG_SANDBOX.CanSpawnEntity and HG_SANDBOX.CanSpawnEntity(ply, class)
end

local function canSpawnVehicle(ply, class)
    return HG_SANDBOX and HG_SANDBOX.CanSpawnVehicle and HG_SANDBOX.CanSpawnVehicle(ply, class)
end

local function isVehicleClass(class)
    return HG_SANDBOX and HG_SANDBOX.IsVehicleClass and HG_SANDBOX.IsVehicleClass(class)
end

local spawnDenyMessages = {
    PlayerSpawnRagdoll = {"ragdolls_disabled", "Ragdolls are disabled in Sandbox Mode."},
    PlayerSpawnNPC = {"npcs_disabled", "NPCs are disabled in Sandbox Mode."},
    PlayerSpawnEffect = {"effects_disabled", "Effects are disabled in Sandbox Mode."},
    PlayerSpawnObject = {"objects_disabled", "You can only spawn weapons, entities, and vehicles in Sandbox Mode."}
}

for _, hookName in ipairs({
    "PlayerSpawnRagdoll",
    "PlayerSpawnNPC",
    "PlayerSpawnEffect",
    "PlayerSpawnObject"
}) do
    Hook[hookName] = function(ply)
        if shouldBlockPlayer(ply) then return false end
        if isRestrictedPlayer(ply) then
            local messageData = spawnDenyMessages[hookName]
            if messageData and HG_SANDBOX and HG_SANDBOX.NotifyDenied then
                HG_SANDBOX.NotifyDenied(ply, messageData[1], messageData[2])
            end

            return false
        end
    end
end

function Hook.PlayerSpawnProp(ply)
    if shouldBlockPlayer(ply) then return false end
    if isRestrictedPlayer(ply) then
        if HG_SANDBOX and HG_SANDBOX.NotifyDenied then
            HG_SANDBOX.NotifyDenied(ply, "props_disabled", "Props are disabled in Sandbox Mode.")
        end

        return false
    end
end

function Hook.PlayerSpawnVehicle(ply, class)
    if shouldBlockPlayer(ply) then return false end
    if isRestrictedPlayer(ply) then
        return canSpawnVehicle(ply, class)
    end
end

function Hook.PlayerSpawnSWEP(ply, class)
    if shouldBlockPlayer(ply) then return false end
    if isRestrictedPlayer(ply) then
        return canSpawnWeapon(ply, class)
    end
end

function Hook.PlayerGiveSWEP(ply, class)
    if shouldBlockPlayer(ply) then return false end
    if isRestrictedPlayer(ply) then
        return canSpawnWeapon(ply, class)
    end
end

function Hook.PlayerSpawnSENT(ply, class)
    if shouldBlockPlayer(ply) then return false end
    if isRestrictedPlayer(ply) then
        if isVehicleClass(class) then
            return canSpawnVehicle(ply, class)
        end

        return canSpawnEntity(ply, class)
    end
end

function Hook.PlayerNoClip(ply)
    if HG_SANDBOX and HG_SANDBOX.IsBypassPlayer and HG_SANDBOX.IsBypassPlayer(ply) then
        return true
    end

    return false
end
