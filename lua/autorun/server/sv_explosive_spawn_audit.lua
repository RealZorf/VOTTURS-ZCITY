local exactClasses = {
    ["bomb"] = true,
    ["ent_hg_molotov"] = true,
    ["grenade_helicopter"] = true,
    ["npc_grenade_frag"] = true,
    ["rpg_projectile"] = true
}

local classPatterns = {
    "grenade",
    "pipebomb",
    "flashbang",
    "smokenade",
    "molotov",
    "claymore",
    "breachcharge",
    "rocket"
}

local function isExplosiveEntity(class)
    class = string.lower(class or "")
    if exactClasses[class] then return true end

    for i = 1, #classPatterns do
        if string.find(class, classPatterns[i], 1, true) then return true end
    end

    return false
end

local function isExplosiveWeapon(class)
    if isExplosiveEntity(class) then return true end

    local stored = weapons.GetStored(class or "")
    local category = stored and string.lower(stored.Category or "") or ""
    return string.find(category, "explosive", 1, true) ~= nil
end

local function describeEntity(ent)
    if not IsValid(ent) then return "invalid" end
    if ent:IsPlayer() then
        return string.format("player=%q steamid=%s steamid64=%s group=%s", ent:Nick(), ent:SteamID(), ent:SteamID64(), ent:GetUserGroup())
    end

    return string.format("entity=%s[%d]", ent:GetClass(), ent:EntIndex())
end

local function appendAudit(line)
    file.CreateDir("zcity")
    file.Append("zcity/explosive_audit.txt", line .. "\n")
end

local function isTrustedPlayer(ply)
    if not IsValid(ply) then return false end
    if ply:IsAdmin() or ply:IsUserGroup("mapper") then return true end
    return HG_SANDBOX and HG_SANDBOX.IsBypassPlayer and HG_SANDBOX.IsBypassPlayer(ply) or false
end

local function logSpawnRequest(ply, class, result)
    local now = CurTime()
    if IsValid(ply) and (ply.ZCityExplosiveAuditAt or 0) > now then return end
    if IsValid(ply) then ply.ZCityExplosiveAuditAt = now + 1 end

    appendAudit(string.format(
        "[%s] request=%s class=%s actor={%s}",
        os.date("!%Y-%m-%dT%H:%M:%SZ"),
        result,
        class or "unknown",
        describeEntity(ply)
    ))
end

hook.Add("PlayerSpawnSENT", "ZCityBlockExplosiveSENTRequest", function(ply, class)
    if not isExplosiveEntity(class) or isTrustedPlayer(ply) then return end
    logSpawnRequest(ply, class, "blocked_sent")
    return false
end)

hook.Add("PlayerSpawnedSENT", "ZCityRemoveExplosiveSENTBypass", function(ply, ent)
    if not IsValid(ent) or not isExplosiveEntity(ent:GetClass()) or isTrustedPlayer(ply) then return end
    logSpawnRequest(ply, ent:GetClass(), "removed_sent_bypass")
    ent:Remove()
end)

hook.Add("PlayerSpawnSWEP", "ZCityBlockExplosiveSWEPRequest", function(ply, class)
    if not isExplosiveWeapon(class) or isTrustedPlayer(ply) then return end
    logSpawnRequest(ply, class, "blocked_swep")
    return false
end)

hook.Add("PlayerGiveSWEP", "ZCityBlockExplosiveGiveRequest", function(ply, class)
    if not isExplosiveWeapon(class) or isTrustedPlayer(ply) then return end
    logSpawnRequest(ply, class, "blocked_give")
    return false
end)

hook.Add("OnEntityCreated", "ZCityExplosiveSpawnAudit", function(ent)
    if not IsValid(ent) or not isExplosiveEntity(ent:GetClass()) then return end

    local class = ent:GetClass()
    local trace = debug and debug.traceback and debug.traceback("", 2):gsub("[\r\n]+", " <- ") or "unavailable"

    timer.Simple(0, function()
        if not IsValid(ent) then return end

        local owner = ent.GetOwner and ent:GetOwner() or NULL
        local creator = ent.GetCreator and ent:GetCreator() or NULL
        local playerVar = ent:GetVar("Player", NULL)
        local scriptedOwner = ent.owner
        local pos = ent:GetPos()
        local line = string.format(
            "[%s] class=%s index=%d pos=%.1f %.1f %.1f owner={%s} creator={%s} player_var={%s} scripted_owner={%s} trace=%s",
            os.date("!%Y-%m-%dT%H:%M:%SZ"),
            class,
            ent:EntIndex(),
            pos.x,
            pos.y,
            pos.z,
            describeEntity(owner),
            describeEntity(creator),
            describeEntity(playerVar),
            describeEntity(scriptedOwner),
            trace
        )

        appendAudit(line)
    end)
end)
