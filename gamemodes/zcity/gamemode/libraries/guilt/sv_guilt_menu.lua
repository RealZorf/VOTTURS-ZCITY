ZCITY_GUILT = ZCITY_GUILT or {}
ZCITY_GUILT.Data = ZCITY_GUILT.Data or {}
ZCITY_GUILT.AutoExpireRoundLoss = ZCITY_GUILT.AutoExpireRoundLoss or {}
ZCITY_GUILT.ManualPunishRoundLoss = ZCITY_GUILT.ManualPunishRoundLoss or {}
ZCITY_GUILT.DeferredPunish = ZCITY_GUILT.DeferredPunish or {}
ZCITY_GUILT.RoundSerial = tonumber(zb and zb.GuiltRoundId) or tonumber(ZCITY_GUILT.RoundSerial) or 0

local CONFIG_PATH = "zcity_guilt/config.json"
local DEFERRED_PUNISH_PATH = "zcity_guilt/deferred_punish.json"
local zb_dev = ConVarExists("zb_dev") and GetConVar("zb_dev") or CreateConVar("zb_dev", "0", FCVAR_LUA_SERVER)
local EXPIRY_TIMER_NAME = "ZCITY_GUILT_ExpireCases"
local FINALIZE_TIMER_PREFIX = "ZCITY_GUILT_Finalize_"
local FINALIZE_RETRY_DELAY = 0.15
local FINALIZE_RETRY_COUNT = 4

local function modeNameInSet(name, set)
    name = string.lower(tostring(name or ""))
    return name ~= "" and set[name] == true
end

local REPO_MODE_NAMES = {
    coop = true,
    criresp = true,
    defense = true,
    dm = true,
    eventhandler = true,
    gwars = true,
    hl2dm = true,
    hmcd = true,
    homicide = true,
    homicide_fear = true,
    pathowogen = true,
    riot = true,
    scugarena = true,
    sfd = true,
    standard = true,
    wildwest = true,
    tdm = true,
    tdm_cstrike = true,
    cstrike = true
}

local NON_PUNISHABLE_MODE_NAMES = {
    assassinsgreed = true,
    dm = true,
    event = true,
    eventhandler = true,
    sandbox = true,
    sfd = true,
    superfighters = true
}

local function roundNameInSet(modeName, roundName, set)
    return modeNameInSet(modeName, set)
        or modeNameInSet(roundName, set)
        or (zb and modeNameInSet(zb.CROUND, set))
end

local function mergeConfig(defaults, stored)
    local out = table.Copy(defaults)

    if not istable(stored) then
        return out
    end

    for k, v in pairs(stored) do
        if istable(v) and istable(out[k]) then
            out[k] = table.Copy(v)
        else
            out[k] = v
        end
    end

    if not istable(out.Presets) then
        out.Presets = table.Copy(defaults.Presets or {})
    end

    return out
end

local function getAutoExpireRoundLoss(ply)
    local steamid64 = ""

    if isstring(ply) then
        steamid64 = tostring(ply or "")
    elseif IsValid(ply) and ply:IsPlayer() then
        steamid64 = tostring(ply:SteamID64() or "")
    end

    local bySteamID64 = steamid64 ~= "" and tonumber(ZCITY_GUILT.AutoExpireRoundLoss[steamid64]) or nil
    local byEntity = IsValid(ply) and tonumber(ZCITY_GUILT.AutoExpireRoundLoss[ply]) or nil
    return math.max(0, bySteamID64 or byEntity or 0)
end

local function addAutoExpireRoundLoss(ply, amount)
    local steamid64 = ""

    if isstring(ply) then
        steamid64 = tostring(ply or "")
    elseif IsValid(ply) and ply:IsPlayer() then
        steamid64 = tostring(ply:SteamID64() or "")
    end

    if steamid64 == "" or steamid64 == "0" then
        if not IsValid(ply) then return end
        ZCITY_GUILT.AutoExpireRoundLoss[ply] = getAutoExpireRoundLoss(ply) + math.max(0, tonumber(amount) or 0)
        return
    end

    ZCITY_GUILT.AutoExpireRoundLoss[steamid64] = getAutoExpireRoundLoss(steamid64) + math.max(0, tonumber(amount) or 0)
end

local function resetAutoExpireRoundLoss(ply)
    if isstring(ply) then
        ZCITY_GUILT.AutoExpireRoundLoss[tostring(ply or "")] = 0
        return
    end

    if not IsValid(ply) then return end
    ZCITY_GUILT.AutoExpireRoundLoss[ply] = nil

    local steamid64 = tostring(ply:SteamID64() or "")
    if steamid64 ~= "" and steamid64 ~= "0" then
        ZCITY_GUILT.AutoExpireRoundLoss[steamid64] = 0
    end
end

local function getManualPunishRoundLoss(ply)
    if not IsValid(ply) then return 0 end
    return math.max(0, tonumber(ZCITY_GUILT.ManualPunishRoundLoss[ply]) or 0)
end

local function addManualPunishRoundLoss(ply, amount)
    if not IsValid(ply) then return end
    ZCITY_GUILT.ManualPunishRoundLoss[ply] = getManualPunishRoundLoss(ply) + math.max(0, tonumber(amount) or 0)
end

local function resetManualPunishRoundLoss(ply)
    if not IsValid(ply) then return end
    ZCITY_GUILT.ManualPunishRoundLoss[ply] = 0
end

local function getEffectiveConfig()
    local cfg = ZCITY_GUILT.Config or ZCITY_GUILT.DefaultConfig or {}
    cfg.PromptKey = tonumber(cfg.PromptKey) or KEY_F
    cfg.PromptText = tostring(cfg.PromptText or "Press F to open the guilt menu.")
    cfg.MinHarm = math.max(0, tonumber(cfg.MinHarm) or 1)
    cfg.HarmExpiry = math.max(1, tonumber(cfg.HarmExpiry) or 180)
    cfg.CaseExpiry = math.max(5, tonumber(cfg.CaseExpiry) or 45)
    cfg.AutoExpireMinHarm = math.max(0, tonumber(cfg.AutoExpireMinHarm) or 15)
    cfg.AutoExpireAmount = math.Clamp(math.floor(tonumber(cfg.AutoExpireAmount) or 2), 0, 120)
    cfg.AutoExpireRoundCap = math.Clamp(math.floor(tonumber(cfg.AutoExpireRoundCap) or 5), 0, 120)
    cfg.SelfDefenseWindow = math.max(0, tonumber(cfg.SelfDefenseWindow) or 12)
    cfg.SelfDefenseMinIncomingHarm = math.max(0, tonumber(cfg.SelfDefenseMinIncomingHarm) or 5)
    cfg.SelfDefenseAttackerCount = math.max(1, math.floor(tonumber(cfg.SelfDefenseAttackerCount) or 2))
    cfg.ManualPunishRoundCap = math.Clamp(math.floor(tonumber(cfg.ManualPunishRoundCap) or 15), 0, 120)
    return cfg
end

local function saveConfig()
    file.CreateDir("zcity_guilt")
    file.Write(CONFIG_PATH, util.TableToJSON(ZCITY_GUILT.Config, true))
end

local function normalizeDeferredPunishTable(tbl)
    local out = {}

    if not istable(tbl) then
        return out
    end

    for steamid64, entry in pairs(tbl) do
        steamid64 = tostring(steamid64 or "")
        if steamid64 == "" or steamid64 == "0" then continue end

        local amount = math.max(0, math.floor(tonumber(istable(entry) and entry.amount or entry) or 0))
        if amount <= 0 then continue end

        out[steamid64] = amount
    end

    return out
end

local function saveDeferredPunish()
    file.CreateDir("zcity_guilt")
    file.Write(DEFERRED_PUNISH_PATH, util.TableToJSON(normalizeDeferredPunishTable(ZCITY_GUILT.DeferredPunish), true))
end

local function loadDeferredPunish()
    if not file.Exists(DEFERRED_PUNISH_PATH, "DATA") then
        ZCITY_GUILT.DeferredPunish = {}
        return
    end

    local raw = file.Read(DEFERRED_PUNISH_PATH, "DATA")
    local parsed = util.JSONToTable(raw or "") or {}
    ZCITY_GUILT.DeferredPunish = normalizeDeferredPunishTable(parsed)
end

local function loadConfig()
    if not file.Exists(CONFIG_PATH, "DATA") then
        ZCITY_GUILT.Config = table.Copy(ZCITY_GUILT.DefaultConfig)
        saveConfig()
        return
    end

    local raw = file.Read(CONFIG_PATH, "DATA")
    local parsed = util.JSONToTable(raw or "") or {}
    ZCITY_GUILT.Config = mergeConfig(ZCITY_GUILT.DefaultConfig, parsed)
end

loadConfig()
loadDeferredPunish()
local CFG = getEffectiveConfig()

local function canEditGuiltConfig(ply)
    return IsValid(ply) and ply:IsPlayer() and ply:IsAdmin()
end

local function canUseDebugTestMenu(ply)
    return canEditGuiltConfig(ply) and zb_dev and zb_dev:GetBool()
end

local function sendConfig(target)
    net.Start("zcity_guilt_config")
    net.WriteTable(ZCITY_GUILT.Config or ZCITY_GUILT.DefaultConfig or {})

    if IsValid(target) then
        net.Send(target)
    else
        net.Broadcast()
    end
end

concommand.Add("zcity_guilt_admin", function(ply)
    if not canEditGuiltConfig(ply) then return end

    net.Start("zcity_guilt_admin_open")
    net.WriteTable(ZCITY_GUILT.Config)
    net.Send(ply)
end)

net.Receive("zcity_guilt_admin_save", function(_, ply)
    if not canEditGuiltConfig(ply) then return end

    local newCfg = net.ReadTable()
    if not istable(newCfg) then return end

    newCfg.PromptKey = tonumber(newCfg.PromptKey) or KEY_F
    newCfg.PromptText = tostring(newCfg.PromptText or "Press F to open the guilt menu.")
    newCfg.MinHarm = math.max(0, tonumber(newCfg.MinHarm) or 1)
    newCfg.HarmExpiry = math.max(1, tonumber(newCfg.HarmExpiry) or 180)
    newCfg.CaseExpiry = math.max(5, tonumber(newCfg.CaseExpiry) or 45)
    newCfg.AutoExpireMinHarm = math.max(0, tonumber(newCfg.AutoExpireMinHarm) or 15)
    newCfg.AutoExpireAmount = math.Clamp(math.floor(tonumber(newCfg.AutoExpireAmount) or 2), 0, 120)
    newCfg.AutoExpireRoundCap = math.Clamp(math.floor(tonumber(newCfg.AutoExpireRoundCap) or 5), 0, 120)
    newCfg.SelfDefenseWindow = math.max(0, tonumber(newCfg.SelfDefenseWindow) or 12)
    newCfg.SelfDefenseMinIncomingHarm = math.max(0, tonumber(newCfg.SelfDefenseMinIncomingHarm) or 5)
    newCfg.SelfDefenseAttackerCount = math.max(1, math.floor(tonumber(newCfg.SelfDefenseAttackerCount) or 2))
    newCfg.ManualPunishRoundCap = math.Clamp(math.floor(tonumber(newCfg.ManualPunishRoundCap) or 15), 0, 120)
    newCfg.AllowForgive = newCfg.AllowForgive == true
    newCfg.AllowPunish = newCfg.AllowPunish == true
    newCfg.AllowReport = newCfg.AllowReport == true
    newCfg.LogAdminActions = newCfg.LogAdminActions == true
    newCfg.StaffReportPrefix = tostring(newCfg.StaffReportPrefix or "[GUILT REPORT] ")
    newCfg.Theme = istable(newCfg.Theme) and newCfg.Theme or {}

    for key, defaults in pairs(ZCITY_GUILT.ThemeDefaults or {}) do
        local clr = istable(newCfg.Theme[key]) and newCfg.Theme[key] or {}

        newCfg.Theme[key] = {
            r = math.Clamp(math.floor(tonumber(clr.r) or defaults.r or 255), 0, 255),
            g = math.Clamp(math.floor(tonumber(clr.g) or defaults.g or 255), 0, 255),
            b = math.Clamp(math.floor(tonumber(clr.b) or defaults.b or 255), 0, 255),
            a = math.Clamp(math.floor(tonumber(clr.a) or defaults.a or 255), 0, 255)
        }
    end

    newCfg.Presets = istable(newCfg.Presets) and newCfg.Presets or {}

    for i = #newCfg.Presets, 1, -1 do
        local p = newCfg.Presets[i]
        if not istable(p) then
            table.remove(newCfg.Presets, i)
        else
            p.id = tostring(p.id or ("preset_" .. i))
            p.name = tostring(p.name or ("Preset " .. i))
            p.amount = math.Clamp(math.floor(tonumber(p.amount) or 0), 0, 120)
            p.minharm = math.max(0, tonumber(p.minharm) or 0)

            if not istable(p.color) then
                p.color = { r = 255, g = 255, b = 255 }
            end

            p.color = {
                r = math.Clamp(math.floor(tonumber(p.color.r) or 255), 0, 255),
                g = math.Clamp(math.floor(tonumber(p.color.g) or 255), 0, 255),
                b = math.Clamp(math.floor(tonumber(p.color.b) or 255), 0, 255)
            }
        end
    end

    ZCITY_GUILT.Config = mergeConfig(ZCITY_GUILT.DefaultConfig, newCfg)
    CFG = getEffectiveConfig()
    saveConfig()
    sendConfig()

    net.Start("zcity_guilt_feedback")
    net.WriteString("Guilt config saved.")
    net.Send(ply)
end)

local function logLine(text)
    if not CFG.LogAdminActions then return end

    file.CreateDir("zcity_guilt")
    file.Append("zcity_guilt/log.txt", "[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] " .. text .. "\n")
end

local function notifyPlayer(ply, msg)
    if not IsValid(ply) then return end

    net.Start("zcity_guilt_feedback")
    net.WriteString(msg or "")
    net.Send(ply)
end

local function notifyStaff(msg)
    msg = tostring(msg or "")

    for _, v in ipairs(player.GetHumans()) do
        if not IsValid(v) or not v:IsAdmin() then continue end

        if ULib and ULib.tsayColor then
            ULib.tsayColor(v, false, Color(255, 80, 80), CFG.StaffReportPrefix, color_white, msg)
        else
            v:ChatPrint(CFG.StaffReportPrefix .. msg)
        end
    end
end

local function getPlayerSteamID64(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return "" end
    return tostring(ply:SteamID64() or "")
end

local function buildConnectedPlayerCache()
    local bySteamID64 = {}

    for _, ply in player.Iterator() do
        if not IsValid(ply) or not ply:IsPlayer() then continue end

        local steamid64 = getPlayerSteamID64(ply)
        if steamid64 ~= "" and steamid64 ~= "0" then
            bySteamID64[steamid64] = ply
        end
    end

    return bySteamID64
end

local function findPlayerBySteamID64(steamid64, playerCache)
    steamid64 = tostring(steamid64 or "")
    if steamid64 == "" or steamid64 == "0" then return nil end

    if istable(playerCache) then
        local cached = playerCache[steamid64]
        if IsValid(cached) and cached:IsPlayer() then
            return cached
        end
    end

    for _, ply in player.Iterator() do
        if IsValid(ply) and ply:IsPlayer() and tostring(ply:SteamID64() or "") == steamid64 then
            return ply
        end
    end
end

local function resolvePlayerOwner(ent)
    if zb and zb.ResolveGuiltPlayer then
        local owner = zb.ResolveGuiltPlayer(ent)
        if IsValid(owner) then return owner end
    end

    if not IsValid(ent) then return nil end
    if ent:IsPlayer() then return ent end

    if hg and hg.RagdollOwner then
        local owner = hg.RagdollOwner(ent)
        if IsValid(owner) and owner:IsPlayer() then
            return owner
        end
    end

    local org = ent.organism
    if org and IsValid(org.owner) and org.owner:IsPlayer() then
        return org.owner
    end

    local owner = ent.GetOwner and ent:GetOwner() or nil
    if IsValid(owner) and owner:IsPlayer() then
        return owner
    end

    owner = ent.owner or ent.Owner
    if IsValid(owner) and owner:IsPlayer() then
        return owner
    end
end

local function collectVictimAliases(victim)
    local aliases = {}
    local seen = {}

    local function add(ent)
        if not IsValid(ent) or seen[ent] then return end
        seen[ent] = true
        aliases[#aliases + 1] = ent
    end

    add(victim)

    if IsValid(victim) and victim:IsPlayer() then
        add(victim.FakeRagdoll)
        add(victim.FakeRagdollOld)
        add(victim.OldRagdoll)

        if victim.GetNWEntity then
            add(victim:GetNWEntity("FakeRagdoll", NULL))
            add(victim:GetNWEntity("RagdollDeath", NULL))
        end

        if hg and hg.GetCurrentCharacter then
            add(hg.GetCurrentCharacter(victim))
        end
    end

    return aliases
end

local function forEachNativeVictimRows(victim, nativeRoot, callback)
    if not IsValid(victim) or not istable(nativeRoot) then return end

    local visited = {}
    local aliases = collectVictimAliases(victim)

    for _, key in ipairs(aliases) do
        if not visited[key] and istable(nativeRoot[key]) then
            visited[key] = true
            callback(key, nativeRoot[key])
        end
    end

    for key, rows in pairs(nativeRoot) do
        if visited[key] or not istable(rows) then continue end

        local owner = resolvePlayerOwner(key)
        if owner == victim then
            visited[key] = true
            callback(key, rows)
        end
    end
end

local function getNativeGuiltSnapshot(victim)
    local snapshot = {}

    local function getAttackerRow(attacker)
        if not IsValid(attacker) or not attacker:IsPlayer() then return nil end

        local steamid64 = getPlayerSteamID64(attacker)
        if steamid64 == "" or steamid64 == "0" then return nil end

        local row = snapshot[steamid64]
        if not row then
            row = {
                ent = attacker,
                steamid64 = steamid64,
                harm = 0,
                karma = 0
            }
            snapshot[steamid64] = row
        else
            row.ent = IsValid(row.ent) and row.ent or attacker
        end

        return row
    end

    forEachNativeVictimRows(victim, zb and zb.HarmDone, function(_, roundData)
        for attacker, amount in pairs(roundData) do
            local row = getAttackerRow(attacker)
            if row then
                row.harm = row.harm + (tonumber(amount) or 0)
            end
        end
    end)

    forEachNativeVictimRows(victim, zb and zb.HarmDoneKarma, function(_, roundData)
        for attacker, amount in pairs(roundData) do
            local row = getAttackerRow(attacker)
            if row then
                row.karma = row.karma + (tonumber(amount) or 0)
            end
        end
    end)

    return snapshot
end

local function getVictimData(ply)
    local steamid64 = getPlayerSteamID64(ply)
    if steamid64 == "" or steamid64 == "0" then return end

    ZCITY_GUILT.Data[steamid64] = ZCITY_GUILT.Data[steamid64] or {
        victimSteamID64 = steamid64,
        victimName = IsValid(ply) and ply:Nick() or "Unknown",
        lifeid = 0,
        attackers = {},
        recentIncoming = {},
        harmBaseline = {},
        karmaBaseline = {},
        case = nil,
        caseid = 0,
        lastFinalize = 0,
        lastPendingBool = nil,
        lastPendingCount = nil,
        roleRoundSerial = ZCITY_GUILT.RoundSerial,
        wasTraitorThisRound = false
    }

    ZCITY_GUILT.Data[steamid64].victimName = IsValid(ply) and ply:Nick() or ZCITY_GUILT.Data[steamid64].victimName
    return ZCITY_GUILT.Data[steamid64]
end

local function isSelfDefenseLockout(victim, target)
    if not IsValid(victim) or not victim:IsPlayer() then return false end
    if not IsValid(target) or not target:IsPlayer() then return false end

    local data = getVictimData(target)
    if not data or not istable(data.recentIncoming) then return false end

    local now = CurTime()
    local window = math.max(0, tonumber(CFG.SelfDefenseWindow) or 12)
    local minIncomingHarm = math.max(0, tonumber(CFG.SelfDefenseMinIncomingHarm) or 5)
    local neededAttackers = math.max(1, math.floor(tonumber(CFG.SelfDefenseAttackerCount) or 2))

    local qualifyingAttackers = 0
    local victimWasOneOfThem = false

    for steamid64, entry in pairs(data.recentIncoming) do
        local attacker = IsValid(entry.ent) and entry.ent or findPlayerBySteamID64(entry.steamid64 or steamid64)
        if not IsValid(attacker) or not attacker:IsPlayer() then
            data.recentIncoming[steamid64] = nil
            continue
        end

        if attacker == target then
            data.recentIncoming[steamid64] = nil
            continue
        end

        local lastAt = tonumber(entry.last or 0)
        local recentHarm = tonumber(entry.harm) or 0

        if (now - lastAt) > window then
            data.recentIncoming[steamid64] = nil
            continue
        end

        if recentHarm >= minIncomingHarm then
            qualifyingAttackers = qualifyingAttackers + 1

            if attacker == victim then
                victimWasOneOfThem = true
            end
        end
    end

    return victimWasOneOfThem and qualifyingAttackers >= neededAttackers
end

local function isProportionalSelfDefense(row, harm)
    if not istable(row) then return false end

    harm = math.max(0, tonumber(harm or row.harm) or 0)

    local incomingHarm = math.max(0, tonumber(row.incomingHarm) or 0)
    local responseRatio = math.max(0, tonumber(row.responseRatio) or 0)
    local selfDefenseMul = math.Clamp(tonumber(row.selfDefenseMul) or 1, 0, 1)
    local threatScore = math.Clamp(tonumber(row.threatScore) or 0, 0, 1)

    if responseRatio <= 0 and incomingHarm > 0 then
        responseRatio = harm / math.max(incomingHarm, 0.01)
    end

    if responseRatio <= 0 or responseRatio > 1.25 then return false end

    return selfDefenseMul <= 0.2 or (incomingHarm >= harm * 0.8 and threatScore >= 0.35)
end

local function getCurrentKarma(ply)
    if not IsValid(ply) then return 0 end

    local liveKarma = tonumber(ply.Karma)
    if liveKarma ~= nil then
        return liveKarma
    end

    if ply.guilt_GetValue then
        return tonumber(ply:guilt_GetValue()) or 100
    end

    return tonumber(ply.GetNetVar and ply:GetNetVar("Karma", 100)) or 100
end

local function setCurrentKarma(ply, amount)
    if zb and zb.SetPlayerKarma then
        return zb.SetPlayerKarma(ply, amount, true)
    end

    if not IsValid(ply) then return false end

    amount = math.floor(tonumber(amount) or 0)
    ply.Karma = amount

    if ply.SetNetVar then
        ply:SetNetVar("Karma", amount)
    end

    if ply.guilt_SetValue then
        ply:guilt_SetValue(amount)
    end

    return true
end

local function addKarma(ply, amount)
    return setCurrentKarma(ply, getCurrentKarma(ply) + (tonumber(amount) or 0))
end

local function subtractKarma(ply, amount)
    return setCurrentKarma(ply, getCurrentKarma(ply) - (tonumber(amount) or 0))
end

local function queueDeferredPunish(steamid64, amount)
    steamid64 = tostring(steamid64 or "")
    amount = math.max(0, math.floor(tonumber(amount) or 0))

    if steamid64 == "" or steamid64 == "0" or amount <= 0 then
        return 0
    end

    ZCITY_GUILT.DeferredPunish[steamid64] = math.max(0, math.floor(tonumber(ZCITY_GUILT.DeferredPunish[steamid64]) or 0)) + amount
    saveDeferredPunish()
    return ZCITY_GUILT.DeferredPunish[steamid64]
end

local function consumeDeferredPunish(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return 0 end

    local steamid64 = tostring(ply:SteamID64() or "")
    if steamid64 == "" or steamid64 == "0" then return 0 end

    local amount = math.max(0, math.floor(tonumber(ZCITY_GUILT.DeferredPunish[steamid64]) or 0))
    if amount <= 0 then
        ZCITY_GUILT.DeferredPunish[steamid64] = nil
        return 0
    end

    ZCITY_GUILT.DeferredPunish[steamid64] = nil
    saveDeferredPunish()
    return amount
end

local function applyDeferredPunish(ply)
    local amount = consumeDeferredPunish(ply)
    if amount <= 0 then return end

    subtractKarma(ply, amount)
    addAutoExpireRoundLoss(ply, amount)
    notifyPlayer(ply, "You received a pending guilt punishment (-" .. amount .. " karma) because you disconnected before a guilt case was resolved.")
    logLine("Applied deferred guilt punishment to " .. ply:Nick() .. " (-" .. amount .. " karma) after reconnect.")
end

local function teamsDifferLikeNative(a, b)
    if not IsValid(a) or not IsValid(b) then return false end
    if not a.Team or not b.Team then return false end

    local okA, teamA = pcall(a.Team, a)
    local okB, teamB = pcall(b.Team, b)
    if not okA or not okB then return false end

    return teamA ~= teamB
end

local function isTraitorLike(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if zb and zb.IsTraitorLike and zb.IsTraitorLike(ply) then return true end
    return ply.HMCDRoundWasTraitor == true
end

local function wasTraitorThisRound(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end

    local data = getVictimData(ply)
    if not data then return isTraitorLike(ply) end

    if tonumber(data.roleRoundSerial) ~= tonumber(ZCITY_GUILT.RoundSerial) then
        data.roleRoundSerial = ZCITY_GUILT.RoundSerial
        data.wasTraitorThisRound = false
    end

    if isTraitorLike(ply) then
        data.wasTraitorThisRound = true
    end

    return data.wasTraitorThisRound == true
end

local function getRoundInfo()
    if not CurrentRound then
        return nil, "", ""
    end

    local ok, mode, roundKey = pcall(CurrentRound)
    if not ok or not istable(mode) then
        return nil, "", ""
    end

    local modeName = string.lower(tostring(mode.name or roundKey or ""))
    local roundName = string.lower(tostring(roundKey or mode.name or ""))
    return mode, modeName, roundName
end

local function isHMCDLikeMode(mode, modeName, roundName)
    if zb and zb.IsHMCDLikeRound then
        return zb.IsHMCDLikeRound(mode, roundName or modeName or zb.CROUND)
    end

    if not istable(mode) then return false end

    if modeName == "hmcd" or roundName == "hmcd" then
        return true
    end

    if istable(mode.Types) and (mode.Types.standard or mode.Types.wildwest) then
        return true
    end

    return false
end

local function isCStrikeLikeMode(modeName, roundName)
    return modeName == "cstrike"
        or roundName == "cstrike"
        or modeName == "tdm_cstrike"
        or roundName == "tdm_cstrike"
end

local function isPunishableGuiltMode(mode, modeName, roundName)
    if not istable(mode) then return false end
    if mode.GuiltDisabled == true then return false end
    if roundNameInSet(modeName, roundName, NON_PUNISHABLE_MODE_NAMES) then return false end
    if mode.GuiltPunishable == true then return true end

    return isHMCDLikeMode(mode, modeName, roundName) or isCStrikeLikeMode(modeName, roundName)
end

local function allowsPostRoundGuiltCases(mode, modeName, roundName)
    if not istable(mode) or mode.GuiltPostRound ~= true then return false end

    return modeName == "overstimulated"
        or roundName == "overstimulated"
        or (zb and string.lower(tostring(zb.CROUND or "")) == "overstimulated")
end

local function getInteractionBlockReason(victim, attacker, allowInactiveRound)
    if not IsValid(victim) or not IsValid(attacker) then return "Invalid player." end
    if victim == attacker then return "Self damage is not punishable." end
    if not victim:IsPlayer() or not attacker:IsPlayer() then return "Invalid player." end

    local mode, modeName, roundName = getRoundInfo()

    if not mode or mode.GuiltDisabled or roundNameInSet(modeName, roundName, NON_PUNISHABLE_MODE_NAMES) then
        return "Native guilt is disabled in this mode."
    end

    if zb_dev and zb_dev:GetBool() then
        return "Developer mode disables native guilt."
    end

    local isHMCD = isHMCDLikeMode(mode, modeName, roundName)
    local isCStrike = isCStrikeLikeMode(modeName, roundName)

    if not isPunishableGuiltMode(mode, modeName, roundName) then
        return "Punishment is disabled in this round mode."
    end

    if not allowInactiveRound and zb and zb.ROUND_STATE ~= 1 and (not isCStrike or not zb.RoundsLeft) then
        return "Round was not active when this was checked."
    end

    if attacker.IsBerserk and attacker:IsBerserk() then
        return "Attacker was berserk."
    end

    local victimTraitor = wasTraitorThisRound(victim)
    local attackerTraitor = wasTraitorThisRound(attacker)

    if isHMCD then
        if victimTraitor then
            return "Victim was a traitor."
        end

        if attackerTraitor then
            return "Attacker was a traitor."
        end
    elseif teamsDifferLikeNative(attacker, victim) then
        return "Different-team combat is handled by the mode."
    end
end

local function shouldAllowGuiltInteraction(victim, attacker, allowInactiveRound)
    return getInteractionBlockReason(victim, attacker, allowInactiveRound) == nil
end

local function shouldSkipTransparencyCase(victim, attacker)
    if not IsValid(victim) or not IsValid(attacker) then return true end
    if victim == attacker then return true end
    if not victim:IsPlayer() or not attacker:IsPlayer() then return true end

    local mode, modeName, roundName = getRoundInfo()
    if isHMCDLikeMode(mode, modeName, roundName) then
        return false
    end

    if wasTraitorThisRound(victim) then return true end

    return teamsDifferLikeNative(attacker, victim)
end

local function getRoundSnapshots(victim, nativeSnapshot)
    local harmOut = {}
    local karmaOut = {}
    nativeSnapshot = nativeSnapshot or getNativeGuiltSnapshot(victim)

    for steamid64, row in pairs(nativeSnapshot) do
        harmOut[steamid64] = tonumber(row.harm) or 0
        karmaOut[steamid64] = tonumber(row.karma) or 0
    end

    return harmOut, karmaOut
end

local function clearNativeGuiltFor(victim, attacker)
    if not IsValid(victim) or not victim:IsPlayer() then return end
    if not IsValid(attacker) or not attacker:IsPlayer() then return end

    forEachNativeVictimRows(victim, zb and zb.HarmDone, function(_, rows)
        rows[attacker] = 0
    end)

    forEachNativeVictimRows(victim, zb and zb.HarmDoneKarma, function(_, rows)
        rows[attacker] = 0
    end)
end

local function getAutoExpirePreset()
    local presets = (CFG and CFG.Presets) or (ZCITY_GUILT.Config and ZCITY_GUILT.Config.Presets) or {}
    local best = nil

    for _, preset in ipairs(presets) do
        if not istable(preset) then continue end

        if preset.id == "punish_minor" then
            return preset
        end

        if not best or (tonumber(preset.amount) or math.huge) < (tonumber(best.amount) or math.huge) then
            best = preset
        end
    end

    return best
end

local function autoResolveExpiredCase(victim, data, activeCase, playerCache)
    if not istable(data) or not istable(activeCase) or not istable(activeCase.rows) then
        return
    end

    if activeCase.debug == true then
        data.case = nil
        return
    end

    if not CFG.AllowPunish then
        data.case = nil
        return
    end

    local preset = getAutoExpirePreset()
    if not preset then
        data.case = nil
        return
    end

    local presetMinHarm = tonumber(preset.minharm) or 0
    local autoExpireMinHarm = tonumber(CFG.AutoExpireMinHarm) or 0
    local requiredHarm = math.max(presetMinHarm, autoExpireMinHarm)
    local autoExpireAmount = math.max(0, math.floor(tonumber(CFG.AutoExpireAmount) or 0))
    local autoExpireRoundCap = math.max(0, math.floor(tonumber(CFG.AutoExpireRoundCap) or 0))

    if autoExpireAmount <= 0 or autoExpireRoundCap <= 0 then
        data.case = nil
        return
    end

    for steamid64, row in pairs(activeCase.rows) do
        local attacker = IsValid(row.ent) and row.ent or findPlayerBySteamID64(row.steamid64 or steamid64, playerCache)
        if not IsValid(attacker) or not attacker:IsPlayer() then
            continue
        end

        row.ent = attacker

        if row.decided == true then
            continue
        end

        local harm = tonumber(row.harm) or 0
        local nativeKarma = math.max(0, tonumber(row.nativeKarma or row.karma) or 0)
        local usedThisRound = getAutoExpireRoundLoss(attacker)
        local remainingCap = math.max(0, autoExpireRoundCap - usedThisRound)

        if nativeKarma <= 0 or row.actionAllowed == false or not shouldAllowGuiltInteraction(victim, attacker, true) then
            row.decided = true
            row.decision = "auto_expire_blocked"
            row.autoExpired = true
            continue
        end

        if isSelfDefenseLockout(victim, attacker) or isProportionalSelfDefense(row, harm) then
            row.decided = true
            row.decision = "auto_expire_self_defense"
            row.autoExpired = true
            continue
        end

        if harm < requiredHarm then
            row.decided = true
            row.decision = "auto_expire_skipped"
            row.autoExpired = true
            continue
        end

        if remainingCap <= 0 then
            row.decided = true
            row.decision = "auto_expire_capped"
            row.autoExpired = true
            continue
        end

        local applied = math.min(autoExpireAmount, remainingCap)
        if applied <= 0 then
            row.decided = true
            row.decision = "auto_expire_capped"
            row.autoExpired = true
            continue
        end

        subtractKarma(attacker, applied)
        addAutoExpireRoundLoss(attacker, applied)

        row.decided = true
        row.decision = "auto_expire_punish"
        row.autoExpired = true

        local caseAge = math.max(0, CurTime() - (tonumber(activeCase.createdAt) or CurTime()))
        local msg = victim:Nick() .. "'s unresolved guilt case auto-punished " .. attacker:Nick() .. " for -" .. applied .. " karma after " .. math.Round(caseAge, 1) .. " seconds. Harm: " .. math.Round(harm, 1)
        notifyPlayer(attacker, "You received an automatic guilt punishment (-" .. applied .. " karma) after " .. victim:Nick() .. "'s case expired unresolved.")
        logLine(msg)
    end

    data.case = nil
end

local function queueDisconnectPunish(victim, attacker, row)
    if not IsValid(victim) or not victim:IsPlayer() then
        return false
    end

    if not IsValid(attacker) or not attacker:IsPlayer() then
        return false
    end

    if not istable(row) or row.decided == true or row.debugCase == true or not CFG.AllowPunish then
        return false
    end

    if row.actionAllowed == false or not shouldAllowGuiltInteraction(victim, attacker, true) then
        return false
    end

    if math.max(0, tonumber(row.nativeKarma or row.karma) or 0) <= 0 then
        return false
    end

    local preset = getAutoExpirePreset()
    if not preset then
        return false
    end

    local autoExpireAmount = math.max(0, math.floor(tonumber(CFG.AutoExpireAmount) or 0))
    local autoExpireRoundCap = math.max(0, math.floor(tonumber(CFG.AutoExpireRoundCap) or 0))
    if autoExpireAmount <= 0 or autoExpireRoundCap <= 0 then
        return false
    end

    local harm = tonumber(row.harm) or 0
    local requiredHarm = math.max(tonumber(preset.minharm) or 0, tonumber(CFG.AutoExpireMinHarm) or 0)
    if harm < requiredHarm then
        return false
    end

    if isSelfDefenseLockout(victim, attacker) or isProportionalSelfDefense(row, harm) then
        return false
    end

    local usedThisRound = getAutoExpireRoundLoss(attacker)
    local remainingCap = math.max(0, autoExpireRoundCap - usedThisRound)
    local applied = math.min(autoExpireAmount, remainingCap)
    if applied <= 0 then
        return false
    end

    local steamid64 = tostring(row.steamid64 or attacker:SteamID64() or "")
    if steamid64 == "" or steamid64 == "0" then
        return false
    end

    queueDeferredPunish(steamid64, applied)
    addAutoExpireRoundLoss(attacker, applied)

    local victimName = IsValid(victim) and victim:Nick() or "Unknown"
    local attackerName = row.name or attacker:Nick()
    logLine(victimName .. "'s unresolved guilt case queued a disconnect punishment for " .. attackerName .. " (-" .. applied .. " karma). Harm: " .. math.Round(harm, 1))
    return true
end

local function queueDisconnectedAttackerPunish(victim, steamid64, row)
    steamid64 = tostring(steamid64 or (row and row.steamid64) or "")
    if steamid64 == "" or steamid64 == "0" then return false end
    if not IsValid(victim) or not victim:IsPlayer() then return false end
    if not istable(row) or row.deferredQueued == true or not CFG.AllowPunish then return false end
    if row.actionAllowed == false then return false end
    if math.max(0, tonumber(row.nativeKarma or row.karma) or 0) <= 0 then return false end

    local preset = getAutoExpirePreset()
    if not preset then return false end

    local autoExpireAmount = math.max(0, math.floor(tonumber(CFG.AutoExpireAmount) or 0))
    local autoExpireRoundCap = math.max(0, math.floor(tonumber(CFG.AutoExpireRoundCap) or 0))
    if autoExpireAmount <= 0 or autoExpireRoundCap <= 0 then return false end

    local harm = tonumber(row.harm) or 0
    local requiredHarm = math.max(tonumber(preset.minharm) or 0, tonumber(CFG.AutoExpireMinHarm) or 0)
    if harm < requiredHarm then return false end

    if isProportionalSelfDefense(row, harm) then
        return false
    end

    local usedThisRound = getAutoExpireRoundLoss(steamid64)
    local remainingCap = math.max(0, autoExpireRoundCap - usedThisRound)
    local applied = math.min(autoExpireAmount, remainingCap)
    if applied <= 0 then return false end

    queueDeferredPunish(steamid64, applied)
    addAutoExpireRoundLoss(steamid64, applied)

    row.deferredQueued = true
    row.decision = "disconnect_deferred"

    local victimName = IsValid(victim) and victim:Nick() or "Unknown"
    local attackerName = row.name or steamid64
    logLine(victimName .. "'s death queued a deferred disconnect punishment for " .. attackerName .. " (" .. steamid64 .. ") (-" .. applied .. " karma). Harm: " .. math.Round(harm, 1))
    return true
end

local function hasPendingRespect(activeCase)
    for _, row in pairs(activeCase.rows or {}) do
        if row.decided ~= true and row.respectEligible == true then
            return true
        end
    end

    return false
end

local function getPendingCase(victim, playerCache)
    local data = getVictimData(victim)
    if not data then return nil end

    local activeCase = data.case
    if not istable(activeCase) then return nil end

    if activeCase.debug ~= true then
        local mode, modeName, roundName = getRoundInfo()
        if zb and zb.ROUND_STATE ~= 1
            and not allowsPostRoundGuiltCases(mode, modeName, roundName)
            and not hasPendingRespect(activeCase)
        then
            data.case = nil
            return nil
        end

        local caseRoundSerial = tonumber(activeCase.roundSerial)
        if caseRoundSerial == nil or caseRoundSerial ~= ZCITY_GUILT.RoundSerial then
            data.case = nil
            return nil
        end

        local createdAt = tonumber(activeCase.createdAt)
        local expiresAt = tonumber(activeCase.expiresAt)
        if not createdAt or createdAt <= 0 or createdAt > CurTime() + 1 or not expiresAt then
            data.case = nil
            return nil
        end

        local minimumExpiry = createdAt + math.max(5, tonumber(CFG.CaseExpiry) or 45)
        if expiresAt < minimumExpiry then
            expiresAt = minimumExpiry
        end

        activeCase.createdAt = createdAt
        activeCase.expiresAt = expiresAt
    end

    if (activeCase.expiresAt or 0) <= CurTime() then
        autoResolveExpiredCase(victim, data, activeCase, playerCache)
        return nil
    end

    local hasPending = false

    for steamid64, row in pairs(activeCase.rows or {}) do
        local attacker = IsValid(row.ent) and row.ent or findPlayerBySteamID64(row.steamid64 or steamid64, playerCache)
        if not IsValid(attacker) or not attacker:IsPlayer() then
            continue
        end

        row.ent = attacker

        if row.debugCase ~= true and row.respectEligible ~= true and shouldSkipTransparencyCase(victim, attacker) then
            activeCase.rows[steamid64] = nil
            continue
        end

        if row.decided ~= true then
            hasPending = true
        end
    end

    if not next(activeCase.rows or {}) or not hasPending then
        data.case = nil
        return nil
    end

    return activeCase
end

local function getPendingCount(victim, playerCache)
    local case = getPendingCase(victim, playerCache)
    if not case then return 0 end

    local count = 0
    for steamid64, row in pairs(case.rows or {}) do
        local attacker = IsValid(row.ent) and row.ent or findPlayerBySteamID64(row.steamid64 or steamid64, playerCache)
        if row.decided ~= true and IsValid(attacker) then
            count = count + 1
        end
    end

    return count
end

local function syncVictimState(victim, playerCache)
    if not IsValid(victim) or not victim:IsPlayer() then return end

    local data = getVictimData(victim)
    if not data then return end

    local count = getPendingCount(victim, playerCache)
    local hasPending = count > 0

    if data.lastPendingBool ~= hasPending then
        victim:SetNWBool("ZCITY_GUILT_PENDING", hasPending)
        data.lastPendingBool = hasPending
    end

    if data.lastPendingCount ~= count then
        victim:SetNWInt("ZCITY_GUILT_PENDING_COUNT", count)
        data.lastPendingCount = count
    end
end

local function startTrackedLife(victim)
    local data = getVictimData(victim)
    if not data then return end

    data.lifeid = (data.lifeid or 0) + 1
    wasTraitorThisRound(victim)
    data.attackers = {}
    data.recentIncoming = {}
    data.deathAttackerSteamID64 = nil
    data.deathAttackerWasTraitor = nil
    data.harmBaseline, data.karmaBaseline = getRoundSnapshots(victim)
    data.lastFinalize = 0
end

local function clearVictimTracking(victim)
    local data = getVictimData(victim)
    if not data then return end

    data.attackers = {}
    data.recentIncoming = {}
    data.deathAttackerSteamID64 = nil
    data.deathAttackerWasTraitor = nil
    data.harmBaseline = {}
    data.karmaBaseline = {}
    data.case = nil
    data.lastFinalize = 0
    data.lastPendingBool = nil
    data.lastPendingCount = nil

    syncVictimState(victim)
end

local function getDamageRejectReason(victim, attacker, amount)
    if not IsValid(victim) or not victim:IsPlayer() then return "Invalid victim." end
    if not IsValid(attacker) or not attacker:IsPlayer() then return "Invalid attacker or unresolved damage owner." end
    if victim == attacker then return "Self damage is ignored." end
    if (tonumber(amount) or 0) <= 0 then return "Damage amount was zero or negative." end

    local mode, modeName, roundName = getRoundInfo()
    if not mode then return "No active round mode." end
    if mode.GuiltDisabled then return "Native guilt is disabled in this mode." end
    if zb_dev and zb_dev:GetBool() then return "Developer mode disables native guilt." end
    if not isPunishableGuiltMode(mode, modeName, roundName) then return "Punishment is disabled in this round mode." end

    local isCStrike = isCStrikeLikeMode(modeName, roundName)
    if zb and zb.ROUND_STATE ~= 1 and (not isCStrike or not zb.RoundsLeft) then return "Round is not active." end
    if shouldSkipTransparencyCase(victim, attacker) then return "Skipped by transparency rules." end
end

local function canTrackDamage(victim, attacker, amount)
    return getDamageRejectReason(victim, attacker, amount) == nil
end

local function refreshRoundBaselines(playerCache)
    local nativeSnapshots = {}

    for _, victim in player.Iterator() do
        if not IsValid(victim) or not victim:IsPlayer() then continue end

        local data = getVictimData(victim)
        if not data then continue end

        local nativeSnapshot = getNativeGuiltSnapshot(victim)
        nativeSnapshots[victim] = nativeSnapshot
        data.harmBaseline, data.karmaBaseline = getRoundSnapshots(victim, nativeSnapshot)
        data.lastFinalize = 0
        syncVictimState(victim, playerCache)
    end

    return nativeSnapshots
end

local function resolveVictimPlayer(victim, ent)
    if not IsValid(victim) then return nil end

    local owner = resolvePlayerOwner(victim)
    if IsValid(owner) then return owner end

    return resolvePlayerOwner(ent)
end

local function resolveAttackerPlayer(attacker, dmginfo)
    local owner = resolvePlayerOwner(attacker)
    if IsValid(owner) then return owner end

    if not dmginfo or not dmginfo.GetInflictor then return nil end

    local inflictor = dmginfo:GetInflictor()
    if not IsValid(inflictor) then return nil end

    owner = resolvePlayerOwner(inflictor)
    if IsValid(owner) then return owner end

    return nil
end

local function getDamageSource(attacker, dmginfo)
    if zb and zb.GetGuiltDamageSource then
        return zb.GetGuiltDamageSource(attacker, dmginfo)
    end

    return "damage"
end

local function normalizeThreatReasons(reasons)
    local out = {}

    if istable(reasons) then
        for _, reason in ipairs(reasons) do
            reason = tostring(reason or "")
            if reason ~= "" then
                out[#out + 1] = reason
            end

            if #out >= 5 then break end
        end
    end

    if #out <= 0 then
        out[1] = "No clear self-defense threat detected."
    end

    return out
end

local function applyThreatFields(row, victim, attacker, fallback)
    fallback = fallback or {}

    local state = zb and zb.GuiltThreatStates and zb.GuiltThreatStates[victim] and zb.GuiltThreatStates[victim][attacker] or nil
    if not istable(state) and zb and zb.GetGuiltThreatState then
        state = zb.GetGuiltThreatState(victim, attacker, nil, fallback.harm, fallback.harm)
    end

    state = istable(state) and state or {}

    row.threatScore = math.Round(math.Clamp(tonumber(state.score) or 0, 0, 1), 2)
    row.selfDefenseMul = math.Round(math.Clamp(tonumber(state.karmaMul) or 1, 0, 1), 2)
    row.incomingHarm = math.Round(math.max(0, tonumber(state.incomingHarm) or 0), 1)
    row.responseRatio = math.Round(math.max(0, tonumber(state.responseRatio) or 0), 2)
    row.damageSource = tostring(state.source or fallback.source or "damage")
    row.threatReasons = normalizeThreatReasons(state.reasons)
    row.severeSelfDefense = state.severeSelfDefense == true
    row.meleeSelfDefense = state.meleeSelfDefense == true
    row.protectedSelfDefense = state.protectedSelfDefense == true or row.severeSelfDefense

    return row
end

local function applyActionFields(row, victim, attacker)
    row.attackerWasTraitor = row.attackerWasTraitor == true or wasTraitorThisRound(attacker)
    row.victimWasTraitor = row.victimWasTraitor == true or wasTraitorThisRound(victim)
    row.respectEligible = row.victimWasTraitor == true
        and row.attackerWasTraitor ~= true
        and row.deathKiller == true

    local blockReason = getInteractionBlockReason(victim, attacker, true)

    row.actionAllowed = blockReason == nil
    row.actionLockReason = blockReason or ""

    if row.protectedSelfDefense == true or row.severeSelfDefense == true then
        row.actionAllowed = false
        row.actionLockReason = row.severeSelfDefense
            and "Protected self-defense after a recent limb amputation."
            or row.meleeSelfDefense and "Protected self-defense against a recent lethal melee attack."
            or "Protected self-defense against recent incoming gunfire."
    end

    local nativeKarma = math.max(0, tonumber(row.nativeKarma or row.karma) or 0)
    if nativeKarma <= 0 then
        local nativeNote = "Native guilt calculated no karma loss; this case is shown for transparency only."
        if row.respectEligible ~= true then
            row.actionAllowed = false
            if row.protectedSelfDefense ~= true and row.severeSelfDefense ~= true then
                row.actionLockReason = "Native guilt calculated no karma loss."
            end
        end
        row.threatReasons = normalizeThreatReasons(row.threatReasons)

        local alreadyListed = false
        for _, reason in ipairs(row.threatReasons) do
            if reason == nativeNote then
                alreadyListed = true
                break
            end
        end

        if not alreadyListed and #row.threatReasons < 5 then
            row.threatReasons[#row.threatReasons + 1] = nativeNote
        end
    end

    if blockReason and blockReason ~= "" then
        row.threatReasons = normalizeThreatReasons(row.threatReasons)

        local alreadyListed = false
        for _, reason in ipairs(row.threatReasons) do
            if reason == blockReason then
                alreadyListed = true
                break
            end
        end

        if not alreadyListed and #row.threatReasons < 5 then
            row.threatReasons[#row.threatReasons + 1] = blockReason
        end
    end

    return row
end

local function recordDamage(victim, attacker, amount, dmginfo)
    local data = getVictimData(victim)
    if not data then return end
    local attackerSteamID64 = getPlayerSteamID64(attacker)
    if attackerSteamID64 == "" or attackerSteamID64 == "0" then return end

    if (data.lifeid or 0) <= 0 then
        startTrackedLife(victim)
    end

    local now = CurTime()

    local entry = data.attackers[attackerSteamID64] or {
        harm = 0,
        last = 0,
        name = attacker:Nick(),
        steamid = attacker:SteamID(),
        steamid64 = attackerSteamID64
    }

    entry.ent = attacker
    entry.harm = (tonumber(entry.harm) or 0) + amount
    entry.last = now
    entry.name = attacker:Nick()
    entry.steamid = attacker:SteamID()
    entry.steamid64 = attackerSteamID64
    entry.source = getDamageSource(attacker, dmginfo)
    entry.attackerWasTraitor = entry.attackerWasTraitor == true or wasTraitorThisRound(attacker)
    entry.disconnected = nil
    entry.disconnectedAt = nil
    entry.deferredQueued = nil

    applyThreatFields(entry, victim, attacker, {
        harm = entry.harm,
        source = entry.source
    })
    applyActionFields(entry, victim, attacker)

    data.attackers[attackerSteamID64] = entry

    data.recentIncoming = data.recentIncoming or {}

    local recentWindow = math.max(0, tonumber(CFG.SelfDefenseWindow) or 12)
    local recent = data.recentIncoming[attackerSteamID64]

    if (not istable(recent)) or ((now - tonumber(recent.last or 0)) > recentWindow) then
        recent = {
            harm = 0,
            last = 0,
            name = attacker:Nick(),
            steamid = attacker:SteamID(),
            steamid64 = attackerSteamID64
        }
    end

    recent.ent = attacker
    recent.harm = (tonumber(recent.harm) or 0) + amount
    recent.last = now
    recent.name = attacker:Nick()
    recent.steamid = attacker:SteamID()
    recent.steamid64 = attackerSteamID64

    data.recentIncoming[attackerSteamID64] = recent
end

local function getLifeKarmaDelta(victim, attacker, data, nativeSnapshot)
    local steamid64 = getPlayerSteamID64(attacker)
    local current = 0

    if steamid64 ~= "" and steamid64 ~= "0" then
        nativeSnapshot = nativeSnapshot or getNativeGuiltSnapshot(victim)
        current = tonumber(nativeSnapshot[steamid64] and nativeSnapshot[steamid64].karma) or 0
    end

    local baseline = tonumber(data.karmaBaseline and data.karmaBaseline[steamid64]) or 0
    return math.max(0, current - baseline)
end

local function getLethalContributionHarm()
    return math.max(tonumber(zb and zb.MaximumHarm) or 10, 1)
end

local function buildNativeRows(victim, data, nativeSnapshot)
    local rows = {}
    nativeSnapshot = nativeSnapshot or getNativeGuiltSnapshot(victim)
    local now = CurTime()
    local victimWasTraitor = wasTraitorThisRound(victim)

    for steamid64, nativeRow in pairs(nativeSnapshot) do
        local attacker = nativeRow.ent
        if not IsValid(attacker) or not attacker:IsPlayer() or attacker == victim then
            continue
        end

        if shouldSkipTransparencyCase(victim, attacker) then
            continue
        end

        local tracked = data.attackers and data.attackers[steamid64] or nil
        local deathKiller = data.deathAttackerSteamID64 == steamid64
        local attackerWasTraitor = (tracked and tracked.attackerWasTraitor == true)
            or (deathKiller and data.deathAttackerWasTraitor == true)
            or wasTraitorThisRound(attacker)
        local respectEligible = victimWasTraitor and not attackerWasTraitor and deathKiller
        if (victimWasTraitor and not respectEligible) or (not victimWasTraitor and attackerWasTraitor) then
            continue
        end

        local currentHarm = tonumber(nativeRow.harm) or 0
        local currentKarma = tonumber(nativeRow.karma) or 0

        local baselineHarm = tonumber(data.harmBaseline and data.harmBaseline[steamid64]) or 0
        local harm = math.max(0, currentHarm - baselineHarm)
        if deathKiller then
            harm = math.max(harm, getLethalContributionHarm())
        end
        if harm < CFG.MinHarm and not deathKiller then
            continue
        end

        local karmaDelta = getLifeKarmaDelta(victim, attacker, data, nativeSnapshot)
        if karmaDelta <= 0 then
            karmaDelta = math.max(0, currentKarma)
        end

        rows[steamid64] = applyActionFields(applyThreatFields({
            ent = attacker,
            harm = math.Round(harm, 1),
            karma = math.Round(karmaDelta, 1),
            nativeKarma = math.Round(karmaDelta, 1),
            last = now,
            name = attacker:Nick(),
            steamid = attacker:SteamID(),
            steamid64 = attacker:SteamID64(),
            victimWasTraitor = victimWasTraitor,
            attackerWasTraitor = attackerWasTraitor,
            deathKiller = deathKiller,
            decided = false
        }, victim, attacker, {
            harm = harm,
            source = data.attackers and data.attackers[steamid64] and data.attackers[steamid64].source
        }), victim, attacker)
    end

    return rows
end

local function buildRowsFromCurrentLife(victim, data, nativeSnapshot)
    nativeSnapshot = nativeSnapshot or getNativeGuiltSnapshot(victim)
    local rows = buildNativeRows(victim, data, nativeSnapshot)
    local now = CurTime()
    local victimWasTraitor = wasTraitorThisRound(victim)

    for steamid64, entry in pairs(data.attackers or {}) do
        local attacker = IsValid(entry.ent) and entry.ent or findPlayerBySteamID64(entry.steamid64 or steamid64)
        if not IsValid(attacker) or not attacker:IsPlayer() then
            if entry.disconnected == true then
                queueDisconnectedAttackerPunish(victim, steamid64, entry)
            end

            data.attackers[steamid64] = nil
            continue
        end

        if steamid64 == "" or steamid64 == "0" or rows[steamid64] then
            continue
        end

        if shouldSkipTransparencyCase(victim, attacker) then
            continue
        end

        local deathKiller = data.deathAttackerSteamID64 == steamid64
        local attackerWasTraitor = entry.attackerWasTraitor == true
            or (deathKiller and data.deathAttackerWasTraitor == true)
            or wasTraitorThisRound(attacker)
        local respectEligible = victimWasTraitor and not attackerWasTraitor and deathKiller
        if (victimWasTraitor and not respectEligible) or (not victimWasTraitor and attackerWasTraitor) then
            continue
        end

        if now - (entry.last or 0) > CFG.HarmExpiry then
            data.attackers[steamid64] = nil
            continue
        end

        local harm = tonumber(entry.harm) or 0
        if deathKiller then
            harm = math.max(harm, getLethalContributionHarm())
        end
        if harm < CFG.MinHarm and not deathKiller then
            continue
        end

        local karmaDelta = getLifeKarmaDelta(victim, attacker, data, nativeSnapshot)

        rows[steamid64] = applyActionFields(applyThreatFields({
            ent = attacker,
            harm = math.Round(harm, 1),
            karma = math.Round(karmaDelta, 1),
            nativeKarma = math.Round(karmaDelta, 1),
            last = entry.last or now,
            name = entry.name or attacker:Nick(),
            steamid = entry.steamid or attacker:SteamID(),
            steamid64 = entry.steamid64 or attacker:SteamID64(),
            victimWasTraitor = victimWasTraitor,
            attackerWasTraitor = attackerWasTraitor,
            deathKiller = deathKiller,
            decided = false
        }, victim, attacker, {
            harm = harm,
            source = entry.source
        }), victim, attacker)
    end

    return rows
end

local function finalizeVictimDeath(victim)
    if not IsValid(victim) or not victim:IsPlayer() then return end

    local mode, modeName, roundName = getRoundInfo()
    if not isPunishableGuiltMode(mode, modeName, roundName) then
        clearVictimTracking(victim)
        return
    end

    local data = getVictimData(victim)
    if not data then return end

    local now = CurTime()
    if (data.lastFinalize or 0) + 0.05 > now then
        return
    end

    data.lastFinalize = now

    local nativeSnapshot = getNativeGuiltSnapshot(victim)
    local newRows = buildRowsFromCurrentLife(victim, data, nativeSnapshot)

    data.attackers = {}
    data.recentIncoming = {}
    data.harmBaseline, data.karmaBaseline = getRoundSnapshots(victim, nativeSnapshot)

    if not next(newRows) then
        syncVictimState(victim)
        return
    end

    local activeCase = getPendingCase(victim)
    if not activeCase then
        data.caseid = (data.caseid or 0) + 1
        activeCase = {
            id = data.caseid,
            createdAt = now,
            expiresAt = now + CFG.CaseExpiry,
            roundSerial = ZCITY_GUILT.RoundSerial,
            hmcdLike = isHMCDLikeMode(mode, modeName, roundName),
            rows = {}
        }
        data.case = activeCase
    else
        data.caseid = (data.caseid or activeCase.id or 0) + 1
        activeCase.id = data.caseid
        activeCase.createdAt = now
        activeCase.expiresAt = now + CFG.CaseExpiry
        activeCase.roundSerial = ZCITY_GUILT.RoundSerial
        activeCase.hmcdLike = activeCase.hmcdLike == true or isHMCDLikeMode(mode, modeName, roundName)
    end

    for steamid64, row in pairs(newRows) do
        activeCase.rows[steamid64] = row
    end

    syncVictimState(victim)
end

local function queueVictimDeathFinalize(victim)
    local steamid64 = getPlayerSteamID64(victim)
    if steamid64 == "" or steamid64 == "0" then return end

    local timerName = FINALIZE_TIMER_PREFIX .. steamid64

    timer.Create(timerName, FINALIZE_RETRY_DELAY, FINALIZE_RETRY_COUNT, function()
        local ply = findPlayerBySteamID64(steamid64)
        if not IsValid(ply) or not ply:IsPlayer() then return end

        finalizeVictimDeath(ply)

        local data = getVictimData(ply)
        if data and istable(data.case) and next(data.case.rows or {}) then
            timer.Remove(timerName)
        end
    end)
end

local function buildOpenPayload(victim, playerCache)
    if not IsValid(victim) or not victim:IsPlayer() then return {} end

    local activeCase = getPendingCase(victim, playerCache)
    if not activeCase then return {} end

    local mode, modeName, roundName = getRoundInfo()
    if not isPunishableGuiltMode(mode, modeName, roundName) and not hasPendingRespect(activeCase) then
        clearVictimTracking(victim)
        return {}
    end

    local out = {}

    for steamid64, row in pairs(activeCase.rows or {}) do
        local attacker = IsValid(row.ent) and row.ent or findPlayerBySteamID64(row.steamid64 or steamid64, playerCache)
        if not IsValid(attacker) or not attacker:IsPlayer() then
            continue
        end

        row.ent = attacker
        if row.deathKiller == true then
            row.harm = math.max(tonumber(row.harm) or 0, getLethalContributionHarm())
        end
        if row.debugCase ~= true and row.respectEligible ~= true then
            applyActionFields(row, victim, attacker)
        end

        if row.debugCase ~= true and row.respectEligible ~= true and shouldSkipTransparencyCase(victim, attacker) then
            continue
        end

        if row.decided == true then
            continue
        end

        out[#out + 1] = {
            ent = attacker,
            caseid = tonumber(activeCase.id) or 0,
            steamid64 = tostring(row.steamid64 or steamid64 or ""),
            harm = tonumber(row.harm) or 0,
            karma = tonumber(row.karma) or 0,
            decided = false,
            threatScore = tonumber(row.threatScore) or 0,
            selfDefenseMul = tonumber(row.selfDefenseMul) or 1,
            incomingHarm = tonumber(row.incomingHarm) or 0,
            responseRatio = tonumber(row.responseRatio) or 0,
            damageSource = tostring(row.damageSource or "damage"),
            threatReasons = normalizeThreatReasons(row.threatReasons),
            actionAllowed = row.actionAllowed ~= false,
            actionLockReason = tostring(row.actionLockReason or ""),
            respectEligible = row.respectEligible == true
        }
    end

    table.sort(out, function(a, b)
        if (a.harm or 0) == (b.harm or 0) then
            return (a.karma or 0) > (b.karma or 0)
        end

        return (a.harm or 0) > (b.harm or 0)
    end)

    if #out <= 0 then
        local data = getVictimData(victim)
        if data then
            data.case = nil
        end
        syncVictimState(victim)
    end

    return out
end

local function sendOpenPayload(victim, playerCache)
    local payload = buildOpenPayload(victim, playerCache)

    net.Start("zcity_guilt_open")
    net.WriteUInt(#payload, 8)

    for _, row in ipairs(payload) do
        net.WriteUInt(math.Clamp(math.floor(tonumber(row.caseid) or 0), 0, 4294967295), 32)
        net.WriteString(tostring(row.steamid64 or ""))
        net.WriteEntity(row.ent)
        net.WriteFloat(row.harm)
        net.WriteFloat(row.karma)
        net.WriteBool(row.decided == true)
        net.WriteFloat(row.threatScore or 0)
        net.WriteFloat(row.selfDefenseMul or 1)
        net.WriteFloat(row.incomingHarm or 0)
        net.WriteFloat(row.responseRatio or 0)
        net.WriteString(tostring(row.damageSource or "damage"))
        net.WriteBool(row.actionAllowed ~= false)
        net.WriteString(tostring(row.actionLockReason or ""))
        net.WriteBool(row.respectEligible == true)

        local reasons = normalizeThreatReasons(row.threatReasons)
        net.WriteUInt(math.min(#reasons, 5), 4)
        for i = 1, math.min(#reasons, 5) do
            net.WriteString(reasons[i])
        end
    end

    net.Send(victim)
end

hook.Add("HomigradDamage", "ZCITY_GUILT_TrackDamage", function(target, dmginfo, _, ent, harm)
    local victim = resolveVictimPlayer(target, ent)
    local rawAttacker = dmginfo and dmginfo.GetAttacker and dmginfo:GetAttacker() or nil
    local attacker = resolveAttackerPlayer(rawAttacker, dmginfo)
    local amount = tonumber(harm) or (dmginfo and dmginfo.GetDamage and dmginfo:GetDamage()) or 0

    if not canTrackDamage(victim, attacker, amount) then return end

    recordDamage(victim, attacker, amount, dmginfo)
end)

local function getTrackedDeathAttacker(victim, data)
    local bestAttacker
    local bestHarm = 0

    for steamid64, entry in pairs(data.attackers or {}) do
        local attacker = IsValid(entry.ent) and entry.ent or findPlayerBySteamID64(entry.steamid64 or steamid64)
        local harm = math.max(0, tonumber(entry.harm) or 0)

        if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim and harm > bestHarm then
            bestAttacker = attacker
            bestHarm = harm
        end
    end

    return bestAttacker
end

local function captureDeathAttacker(victim, attacker)
    if not IsValid(victim) or not victim:IsPlayer() then return end

    local data = getVictimData(victim)
    if not data then return end

    attacker = resolvePlayerOwner(attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() or attacker == victim then
        attacker = getTrackedDeathAttacker(victim, data)
    end

    if not IsValid(attacker) or not attacker:IsPlayer() or attacker == victim then return end

    local steamid64 = getPlayerSteamID64(attacker)
    if steamid64 == "" or steamid64 == "0" then return end

    data.attackers = data.attackers or {}

    local existing = data.attackers[steamid64]
    local attackerWasTraitor = wasTraitorThisRound(attacker) or (existing and existing.attackerWasTraitor == true)

    data.deathAttackerSteamID64 = steamid64
    data.deathAttackerWasTraitor = attackerWasTraitor

    local entry = existing or {
        harm = 0,
        last = CurTime(),
        name = attacker:Nick(),
        steamid = attacker:SteamID(),
        steamid64 = steamid64,
        source = "kill"
    }

    entry.ent = attacker
    entry.last = CurTime()
    entry.name = attacker:Nick()
    entry.steamid = attacker:SteamID()
    entry.steamid64 = steamid64
    entry.attackerWasTraitor = attackerWasTraitor
    entry.deathKiller = true
    data.attackers[steamid64] = entry
end

hook.Add("PostPlayerDeath", "ZCITY_GUILT_FinalizeDeath", function(victim)
    captureDeathAttacker(victim)
    queueVictimDeathFinalize(victim)
end)

hook.Add("Player_Death", "ZCITY_GUILT_FinalizeDeathEarly", function(victim)
    captureDeathAttacker(victim)
    queueVictimDeathFinalize(victim)
end)

hook.Add("PlayerDeath", "ZCITY_GUILT_FinalizeDeathEngine", function(victim, _, attacker)
    captureDeathAttacker(victim, attacker)
    queueVictimDeathFinalize(victim)
end)

hook.Add("PlayerInitialSpawn", "ZCITY_GUILT_Initialise", function(ply)
    getVictimData(ply)
    startTrackedLife(ply)
    syncVictimState(ply)
    sendConfig(ply)
    resetAutoExpireRoundLoss(ply)
    resetManualPunishRoundLoss(ply)

    timer.Simple(1, function()
        if not IsValid(ply) or not ply:IsPlayer() then return end
        applyDeferredPunish(ply)
    end)
end)

hook.Add("Player Spawn", "ZCITY_GUILT_OnRealSpawn", function(ply)
    if not IsValid(ply) or OverrideSpawn then return end
    startTrackedLife(ply)
    syncVictimState(ply)
end)

hook.Add("ZB_StartRound", "ZCITY_GUILT_ClearRoundStart", function()
    ZCITY_GUILT.RoundSerial = tonumber(zb and zb.GuiltRoundId) or ((ZCITY_GUILT.RoundSerial or 0) + 1)

    for _, ply in player.Iterator() do
        if not IsValid(ply) or not ply:IsPlayer() then continue end

        clearVictimTracking(ply)
        startTrackedLife(ply)
        resetAutoExpireRoundLoss(ply)
        resetManualPunishRoundLoss(ply)
    end

    timer.Simple(0, function()
        refreshRoundBaselines(buildConnectedPlayerCache())
    end)
end)

hook.Add("ZB_EndRound", "ZCITY_GUILT_ClearRoundEnd", function()
    local mode, modeName, roundName = getRoundInfo()
    local keepPostRoundLimits = allowsPostRoundGuiltCases(mode, modeName, roundName)

    for _, ply in player.Iterator() do
        if not IsValid(ply) or not ply:IsPlayer() then continue end

        local data = getVictimData(ply)
        local keepUnfinalizedDeath = data and not ply:Alive() and next(data.attackers or {}) ~= nil

        if data and (istable(data.case) or keepUnfinalizedDeath) then
            if istable(data.case) then
                data.attackers = {}
            end

            data.recentIncoming = {}
            data.harmBaseline = {}
            data.karmaBaseline = {}
            data.lastFinalize = 0
            syncVictimState(ply)
        else
            clearVictimTracking(ply)
        end

        if not keepPostRoundLimits then
            resetAutoExpireRoundLoss(ply)
            resetManualPunishRoundLoss(ply)
        end
    end
end)

hook.Add("PlayerDisconnected", "ZCITY_GUILT_CleanupDisconnect", function(ply)
    local leavingSteamID64 = getPlayerSteamID64(ply)
    local playerCache = buildConnectedPlayerCache()

    for victimSteamID64, data in pairs(ZCITY_GUILT.Data) do
        if victimSteamID64 == leavingSteamID64 then continue end
        if not istable(data) then continue end
        local victim = findPlayerBySteamID64(victimSteamID64, playerCache)
        if istable(data.attackers) then
            local tracked = data.attackers[leavingSteamID64]
            if istable(tracked) then
                tracked.disconnected = true
                tracked.disconnectedAt = CurTime()
                tracked.ent = nil
            end
        end
        if istable(data.recentIncoming) then
            local recent = data.recentIncoming[leavingSteamID64]
            if istable(recent) then
                recent.disconnected = true
                recent.disconnectedAt = CurTime()
                recent.ent = nil
            end
        end
        if istable(data.case) and istable(data.case.rows) then
            local row = data.case.rows[leavingSteamID64]
            if istable(row) and row.decided ~= true then
                queueDisconnectPunish(victim, ply, row)
            end
            data.case.rows[leavingSteamID64] = nil
        end
        if IsValid(victim) then
            syncVictimState(victim, playerCache)
        end
    end

    ZCITY_GUILT.Data[leavingSteamID64] = nil
    ZCITY_GUILT.AutoExpireRoundLoss[ply] = nil
    ZCITY_GUILT.ManualPunishRoundLoss[ply] = nil
end)

timer.Create(EXPIRY_TIMER_NAME, 1, 0, function()
    local playerCache = buildConnectedPlayerCache()

    for victimSteamID64, _ in pairs(ZCITY_GUILT.Data) do
        local victim = findPlayerBySteamID64(victimSteamID64, playerCache)
        if not IsValid(victim) or not victim:IsPlayer() then
            ZCITY_GUILT.Data[victimSteamID64] = nil
            continue
        end

        getPendingCase(victim, playerCache)
        syncVictimState(victim, playerCache)
    end
end)

concommand.Add("zcity_guilt_menu", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if isTraitorLike(ply) then
        clearVictimTracking(ply)
        notifyPlayer(ply, "No eligible players found for forgiveness or punishment.")
        return
    end

    local playerCache = buildConnectedPlayerCache()

    if not ply:Alive() and getPendingCount(ply, playerCache) <= 0 then
        finalizeVictimDeath(ply)
    end

    if getPendingCount(ply, playerCache) <= 0 then
        notifyPlayer(ply, "No eligible players found for forgiveness or punishment.")
        return
    end

    sendOpenPayload(ply, playerCache)
end)

local function canUseGuiltDebug(ply)
    return IsValid(ply) and ply:IsPlayer() and ply:IsAdmin()
end

local function debugOut(ply, msg)
    msg = "[GuiltDebug] " .. tostring(msg or "")

    if IsValid(ply) and ply:IsPlayer() then
        ply:PrintMessage(HUD_PRINTCONSOLE, msg)
    else
        print(msg)
    end
end

local function findDebugPlayer(text, fallback)
    text = string.Trim(tostring(text or ""))

    if text == "" then
        return fallback
    end

    local bySteamID64 = findPlayerBySteamID64(text)
    if IsValid(bySteamID64) then
        return bySteamID64
    end

    local userid = tonumber(text)
    if userid then
        for _, ply in player.Iterator() do
            if IsValid(ply) and ply:UserID() == userid then
                return ply
            end
        end
    end

    local needle = string.lower(text)
    for _, ply in player.Iterator() do
        if not IsValid(ply) or not ply:IsPlayer() then continue end

        if string.find(string.lower(ply:Nick()), needle, 1, true) then
            return ply
        end
    end

    return fallback
end

local function findDebugOtherPlayer(ply, text)
    local target = findDebugPlayer(text)
    if IsValid(target) and target ~= ply then
        return target
    end

    for _, other in player.Iterator() do
        if IsValid(other) and other:IsPlayer() and other ~= ply then
            return other
        end
    end
end

local function makeDebugRow(victim, attacker, fields)
    fields = fields or {}

    local row = {
        ent = attacker,
        harm = math.Round(math.max(0, tonumber(fields.harm) or 20), 1),
        karma = math.Round(math.max(0, tonumber(fields.karma) or 5), 1),
        nativeKarma = math.Round(math.max(0, tonumber(fields.nativeKarma or fields.karma) or 5), 1),
        last = CurTime(),
        name = IsValid(attacker) and attacker:Nick() or "Unknown",
        steamid = IsValid(attacker) and attacker:SteamID() or "",
        steamid64 = IsValid(attacker) and attacker:SteamID64() or "",
        decided = false,
        threatScore = math.Round(math.Clamp(tonumber(fields.threatScore) or 0, 0, 1), 2),
        selfDefenseMul = math.Round(math.Clamp(tonumber(fields.selfDefenseMul) or 1, 0, 1), 2),
        incomingHarm = math.Round(math.max(0, tonumber(fields.incomingHarm) or 0), 1),
        responseRatio = math.Round(math.max(0, tonumber(fields.responseRatio) or 0), 2),
        damageSource = tostring(fields.damageSource or "damage"),
        threatReasons = normalizeThreatReasons(fields.threatReasons),
        actionAllowed = fields.actionAllowed ~= false,
        actionLockReason = tostring(fields.actionLockReason or ""),
        victimWasTraitor = fields.victimWasTraitor == true,
        attackerWasTraitor = fields.attackerWasTraitor == true,
        deathKiller = fields.deathKiller == true,
        respectEligible = fields.respectEligible == true,
        debugCase = true
    }

    if fields.useNativeActionCheck then
        row = applyActionFields(row, victim, attacker)
    end

    return row
end

local function openDebugCase(victim, rows)
    if not IsValid(victim) or not victim:IsPlayer() then return false end
    if not istable(rows) or not next(rows) then return false end

    local data = getVictimData(victim)
    if not data then return false end

    data.caseid = (data.caseid or 0) + 1
    local mode, modeName, roundName = getRoundInfo()

    data.case = {
        id = data.caseid,
        createdAt = CurTime(),
        expiresAt = CurTime() + math.max(tonumber(CFG.CaseExpiry) or 45, 30),
        hmcdLike = isHMCDLikeMode(mode, modeName, roundName),
        debug = true,
        rows = rows
    }

    syncVictimState(victim)
    sendOpenPayload(victim, buildConnectedPlayerCache())
    return true
end

local function printDebugCaseStatus(ply, target)
    local playerCache = buildConnectedPlayerCache()
    local data = IsValid(target) and getVictimData(target) or nil
    local mode, modeName, roundName = getRoundInfo()

    debugOut(ply, "Target: " .. (IsValid(target) and (target:Nick() .. " / " .. target:SteamID64()) or "invalid"))
    debugOut(ply, "Round state: " .. tostring(zb and zb.ROUND_STATE)
        .. " mode=" .. tostring(modeName)
        .. " round=" .. tostring(roundName)
        .. " cround=" .. tostring(zb and zb.CROUND)
        .. " guiltDisabled=" .. tostring(mode and mode.GuiltDisabled == true)
        .. " punishable=" .. tostring(isPunishableGuiltMode(mode, modeName, roundName)))

    if not data then
        debugOut(ply, "No data table.")
        return
    end

    local pending = getPendingCase(target, playerCache)
    debugOut(ply, "lifeid=" .. tostring(data.lifeid) .. " attackers=" .. table.Count(data.attackers or {}) .. " recentIncoming=" .. table.Count(data.recentIncoming or {}) .. " pendingRows=" .. tostring(getPendingCount(target, playerCache)))

    local native = getNativeGuiltSnapshot(target)
    for steamid64, row in pairs(native) do
        debugOut(ply, "native " .. tostring(row.ent) .. " sid64=" .. steamid64 .. " harm=" .. math.Round(tonumber(row.harm) or 0, 2) .. " karma=" .. math.Round(tonumber(row.karma) or 0, 2))
    end

    for steamid64, row in pairs(data.attackers or {}) do
        local attacker = IsValid(row.ent) and row.ent or findPlayerBySteamID64(steamid64, playerCache)
        local rejectReason = getDamageRejectReason(target, attacker, tonumber(row.harm) or 0)
        if row.disconnected == true and not IsValid(attacker) then
            rejectReason = "Attacker disconnected; metadata preserved for death finalization."
        end

        debugOut(ply, "tracked " .. tostring(IsValid(attacker) and attacker:Nick() or row.name or steamid64)
            .. " harm=" .. math.Round(tonumber(row.harm) or 0, 2)
            .. " source=" .. tostring(row.source or row.damageSource or "damage")
            .. " disconnected=" .. tostring(row.disconnected == true)
            .. " allowed=" .. tostring(row.actionAllowed ~= false)
            .. " reject=" .. tostring(rejectReason or "none"))
    end

    if pending then
        debugOut(ply, "case id=" .. tostring(pending.id) .. " expiresIn=" .. math.Round((tonumber(pending.expiresAt) or 0) - CurTime(), 2))

        for steamid64, row in pairs(pending.rows or {}) do
            debugOut(ply, "case row sid64=" .. steamid64 .. " harm=" .. math.Round(tonumber(row.harm) or 0, 2) .. " karma=" .. math.Round(tonumber(row.karma) or 0, 2) .. " allowed=" .. tostring(row.actionAllowed ~= false) .. " lock=" .. tostring(row.actionLockReason or "") .. " source=" .. tostring(row.damageSource or "damage"))
        end
    end
end

concommand.Add("zcity_guilt_debug_status", function(ply, _, args)
    if not canUseGuiltDebug(ply) then return end

    printDebugCaseStatus(ply, findDebugPlayer(args and args[1], ply))
end)

concommand.Add("zcity_guilt_debug_clear", function(ply, _, args)
    if not canUseGuiltDebug(ply) then return end

    local target = findDebugPlayer(args and args[1], ply)
    if not IsValid(target) then
        debugOut(ply, "No target found.")
        return
    end

    clearVictimTracking(target)
    startTrackedLife(target)
    debugOut(ply, "Cleared guilt tracking for " .. target:Nick() .. ".")
end)

concommand.Add("zcity_guilt_debug_case", function(ply, _, args)
    if not canUseGuiltDebug(ply) then return end

    args = args or {}
    local scenario = string.lower(tostring(args[1] or "mixed"))
    local attacker = findDebugOtherPlayer(ply, args[2])

    if not IsValid(attacker) then
        debugOut(ply, "Need at least one other player/bot for debug case rows.")
        return
    end

    local steamid64 = getPlayerSteamID64(attacker)
    local rows = {}

    if scenario == "normal" then
        rows[steamid64] = makeDebugRow(ply, attacker, {
            harm = tonumber(args[3]) or 22,
            karma = 5,
            threatReasons = { "Debug normal punishable harm." }
        })
    elseif scenario == "respect" or scenario == "traitor" or scenario == "traitor_victim" then
        rows[steamid64] = makeDebugRow(ply, attacker, {
            harm = tonumber(args[3]) or 22,
            karma = 0,
            actionAllowed = false,
            actionLockReason = "Victim was a traitor.",
            victimWasTraitor = true,
            attackerWasTraitor = false,
            deathKiller = true,
            respectEligible = true,
            threatReasons = { "Debug Respect row.", "Victim was a traitor." }
        })
    elseif scenario == "locked" or scenario == "traitor_attacker" then
        rows[steamid64] = makeDebugRow(ply, attacker, {
            harm = tonumber(args[3]) or 22,
            karma = 0,
            actionAllowed = false,
            actionLockReason = "Attacker was a traitor.",
            attackerWasTraitor = true,
            deathKiller = true,
            respectEligible = false,
            threatReasons = { "Debug native-rule transparency row.", "Attacker was a traitor." }
        })
    elseif scenario == "guilty" or scenario == "guilty_victim" then
        rows[steamid64] = makeDebugRow(ply, attacker, {
            harm = tonumber(args[3]) or 18,
            karma = 0,
            actionAllowed = false,
            actionLockReason = "Victim was already marked guilty.",
            threatReasons = { "Debug native-rule transparency row.", "Victim was already marked guilty." }
        })
    elseif scenario == "selfdefense" or scenario == "proportional" then
        rows[steamid64] = makeDebugRow(ply, attacker, {
            harm = tonumber(args[3]) or 18,
            karma = 2,
            threatScore = 0.8,
            selfDefenseMul = 0.1,
            incomingHarm = tonumber(args[3]) or 18,
            responseRatio = 1,
            threatReasons = { "Victim recently harmed attacker.", "Response looks proportional to incoming harm." }
        })
    elseif scenario == "kick" or scenario == "jumpkick" then
        rows[steamid64] = makeDebugRow(ply, attacker, {
            harm = tonumber(args[3]) or 12,
            karma = 3,
            damageSource = scenario,
            threatReasons = { "Debug " .. scenario .. " source row." }
        })
    elseif scenario == "native" then
        rows[steamid64] = makeDebugRow(ply, attacker, {
            harm = tonumber(args[3]) or 18,
            karma = 4,
            useNativeActionCheck = true,
            threatReasons = { "Debug row using current native action checks." }
        })
    else
        rows[steamid64] = makeDebugRow(ply, attacker, {
            harm = 22,
            karma = 5,
            threatReasons = { "Debug normal punishable harm." }
        })

        local added = 1
        for _, other in player.Iterator() do
            if added >= 4 then break end
            if not IsValid(other) or not other:IsPlayer() or other == ply or rows[getPlayerSteamID64(other)] then continue end

            added = added + 1
            local sid = getPlayerSteamID64(other)
            local kind = added

            if kind == 2 then
                rows[sid] = makeDebugRow(ply, other, {
                    harm = 18,
                    karma = 0,
                    actionAllowed = false,
                    actionLockReason = "Attacker was a traitor.",
                    threatReasons = { "Debug native-rule transparency row.", "Attacker was a traitor." }
                })
            elseif kind == 3 then
                rows[sid] = makeDebugRow(ply, other, {
                    harm = 16,
                    karma = 2,
                    threatScore = 0.75,
                    selfDefenseMul = 0.1,
                    incomingHarm = 16,
                    responseRatio = 1,
                    threatReasons = { "Victim recently harmed attacker.", "Response looks proportional to incoming harm." }
                })
            else
                rows[sid] = makeDebugRow(ply, other, {
                    harm = 12,
                    karma = 3,
                    damageSource = "jumpkick",
                    threatReasons = { "Debug jumpkick source row." }
                })
            end
        end
    end

    if openDebugCase(ply, rows) then
        debugOut(ply, "Opened debug case scenario '" .. scenario .. "'.")
    else
        debugOut(ply, "Failed to open debug case.")
    end
end)

concommand.Add("zcity_guilt_debug_damage", function(ply, _, args)
    if not canUseGuiltDebug(ply) then return end

    args = args or {}
    local victim = findDebugPlayer(args[1], ply)
    local attacker = findDebugOtherPlayer(victim, args[2])
    local amount = math.max(0, tonumber(args[3]) or 10)
    local source = string.lower(tostring(args[4] or "damage"))

    if not IsValid(victim) or not IsValid(attacker) or victim == attacker then
        debugOut(ply, "Usage: zcity_guilt_debug_damage <victim> <attacker> [harm] [damage|kick|jumpkick]")
        return
    end

    local rejectReason = getDamageRejectReason(victim, attacker, amount)
    if rejectReason then
        debugOut(ply, "Damage was rejected: " .. rejectReason
            .. " victimValid=" .. tostring(IsValid(victim))
            .. " attackerValid=" .. tostring(IsValid(attacker))
            .. " victimTraitor=" .. tostring(isTraitorLike(victim))
            .. " attackerTraitor=" .. tostring(isTraitorLike(attacker))
            .. " transparencySkip=" .. tostring(IsValid(victim) and IsValid(attacker) and shouldSkipTransparencyCase(victim, attacker) or "n/a"))
        return
    end

    recordDamage(victim, attacker, amount)

    local data = getVictimData(victim)
    local steamid64 = getPlayerSteamID64(attacker)
    if data and data.attackers and data.attackers[steamid64] then
        data.attackers[steamid64].source = source
    end

    syncVictimState(victim)
    debugOut(ply, "Recorded " .. amount .. " debug harm from " .. attacker:Nick() .. " to " .. victim:Nick() .. " source=" .. source .. ".")
end)

concommand.Add("zcity_guilt_debug_finalize", function(ply, _, args)
    if not canUseGuiltDebug(ply) then return end

    local victim = findDebugPlayer(args and args[1], ply)
    if not IsValid(victim) then
        debugOut(ply, "No victim found.")
        return
    end

    finalizeVictimDeath(victim)
    sendOpenPayload(victim, buildConnectedPlayerCache())
    debugOut(ply, "Finalized and opened case payload for " .. victim:Nick() .. ".")
end)

local function canActOnTarget(victim, target, caseid, attackerSteamID64, action, playerCache)
    if not IsValid(victim) or not victim:IsPlayer() then return false, "Invalid victim." end

    local mode, modeName, roundName = getRoundInfo()
    if action ~= "respect" and not isPunishableGuiltMode(mode, modeName, roundName) then
        clearVictimTracking(victim)
        return false, "Punishment is disabled in this round mode."
    end

    local activeCase = getPendingCase(victim, playerCache)
    if not activeCase then return false, "No pending guilt case." end
    if tonumber(caseid) ~= tonumber(activeCase.id) then return false, "This guilt case is no longer current." end

    attackerSteamID64 = tostring(attackerSteamID64 or "")
    if attackerSteamID64 == "" or attackerSteamID64 == "0" then
        attackerSteamID64 = getPlayerSteamID64(target)
    end

    if not istable(activeCase.rows) then return false, "This guilt case is no longer current." end

    local entry = activeCase.rows[attackerSteamID64]
    if not entry then return false, "This player is not in your current guilt case." end
    if entry.decided then return false, "You already made a decision for this player." end

    if IsValid(target) and getPlayerSteamID64(target) ~= attackerSteamID64 then
        return false, "Target does not match this guilt case."
    end

    -- Resolve from the validated server case key, never from the submitted entity.
    target = findPlayerBySteamID64(attackerSteamID64, playerCache)
    if not IsValid(target) or not target:IsPlayer() then return false, "Target is no longer connected." end
    if victim == target then return false, "Invalid target." end

    entry.ent = target

    if action == "respect" then
        if activeCase.hmcdLike ~= true and not isHMCDLikeMode(mode, modeName, roundName) then
            return false, "Respect is only available for Homicide traitor kills."
        end

        if entry.respectEligible ~= true or entry.attackerWasTraitor == true or entry.deathKiller ~= true then
            return false, "This case is not an eligible traitor kill."
        end

        return true, nil, entry, activeCase, target
    end

    if wasTraitorThisRound(victim) then
        return false, "Traitor kill cases can only be resolved by giving respect."
    end

    if entry.respectEligible == true then
        return false, "Traitor kill cases can only be resolved by giving respect."
    end

    local modeBlockReason = getInteractionBlockReason(victim, target, true)
    if modeBlockReason then
        entry.actionAllowed = false
        entry.actionLockReason = modeBlockReason
        return false, modeBlockReason
    end

    if shouldSkipTransparencyCase(victim, target) then
        entry.actionAllowed = false
        entry.actionLockReason = "This case is not punishable in the current round state."
        return false, entry.actionLockReason
    end

    if entry.debugCase ~= true then
        applyActionFields(entry, victim, target)
    end

    return true, nil, entry, activeCase, target
end

local function doForgive(victim, target, entry, activeCase)
    if not CFG.AllowForgive then return false, "Forgiveness is disabled." end

    local nativeRefund = math.max(0, tonumber(entry.nativeKarma or entry.karma) or 0)
    if nativeRefund > 0 then
        addKarma(target, nativeRefund)
    end

    clearNativeGuiltFor(victim, target)

    if IsValid(target) and nativeRefund > 0 then
        target.GuiltWrongKillLossThisRound = math.max((target.GuiltWrongKillLossThisRound or 0) - nativeRefund, 0)
    end

    entry.decided = true
    entry.decision = "forgive"

    local msg = victim:Nick() .. " forgave " .. target:Nick() .. ". Harm: " .. math.Round(entry.harm or 0, 1)
    notifyPlayer(victim, "You forgave " .. target:Nick() .. ".")
    logLine(msg)
    hook.Run("ZC_RoundStars_RecordForgive", victim, target)

    return true
end

local function doRespect(victim, target, entry)
    if entry.respectEligible ~= true or entry.attackerWasTraitor == true or entry.deathKiller ~= true then
        return false, "This case is not eligible for respect."
    end

    local reward = 3
    addKarma(target, reward)
    clearNativeGuiltFor(victim, target)

    entry.decided = true
    entry.decision = "respect"

    notifyPlayer(victim, "You gave respect to " .. target:Nick() .. " (+" .. reward .. " karma).")
    notifyPlayer(target, victim:Nick() .. " gave you respect for the kill (+" .. reward .. " karma).")
    logLine(victim:Nick() .. " gave respect to " .. target:Nick() .. " for killing a traitor (+" .. reward .. " karma).")
    return true
end

local function doPunish(victim, target, action, entry, activeCase)
    if not CFG.AllowPunish then return false, "Punishment is disabled." end

    local modeBlockReason = getInteractionBlockReason(victim, target, true)
    if modeBlockReason then
        return false, modeBlockReason
    end

    local preset = ZCITY_GUILT.GetPreset(action)
    if not preset then return false, "Invalid punishment action." end

    local nativeKarma = math.max(0, tonumber(entry.nativeKarma or entry.karma) or 0)
    if nativeKarma <= 0 then
        return false, "Native guilt calculated no karma loss, so this case is transparency-only."
    end

    local harm = tonumber(entry.harm) or 0
    if entry.deathKiller == true then
        harm = math.max(harm, getLethalContributionHarm())
        entry.harm = harm
    end
    local minharm = tonumber(preset.minharm) or 0

    if harm < minharm then
        return false, "Not enough recorded harm for this punishment."
    end

    if isSelfDefenseLockout(victim, target) then
        return false, "Punishment is locked because this appears to be self-defense against multiple attackers."
    end

    if entry.actionAllowed == false then
        local reason = tostring(entry.actionLockReason or "")
        return false, reason ~= "" and reason or "Punishment is locked because native guilt did not allow this case."
    end

    if isProportionalSelfDefense(entry, harm) then
        return false, "Punishment is locked because this appears to be proportional self-defense."
    end

    local roundCap = math.max(0, math.floor(tonumber(CFG.ManualPunishRoundCap) or 0))
    local usedThisRound = getManualPunishRoundLoss(target)
    local remainingCap = math.max(0, roundCap - usedThisRound)

    if remainingCap <= 0 then
        return false, "This player's manual punish cap for the round has already been reached."
    end

    local applied = math.min(math.max(0, tonumber(preset.amount) or 0), remainingCap)
    if applied <= 0 then
        return false, "No punish amount available."
    end

    subtractKarma(target, applied)
    addManualPunishRoundLoss(target, applied)

    entry.decided = true
    entry.decision = action

    local msg = victim:Nick() .. " punished " .. target:Nick() .. " with " .. preset.name .. " for -" .. applied .. " karma. Harm: " .. math.Round(entry.harm or 0, 1)
    notifyPlayer(victim, "You punished " .. target:Nick() .. " (-" .. applied .. " karma).")
    logLine(msg)
    hook.Run("ZC_RoundStars_RecordPunish", victim, target)

    return true
end

local function doReport(victim, target, entry, activeCase)
    if not CFG.AllowReport then return false, "Reporting is disabled." end

    entry.decided = true
    entry.decision = "report"

    local msg = victim:Nick() .. " reported " .. target:Nick() .. " after death. Harm: " .. math.Round(entry.harm or 0, 1)
    notifyPlayer(victim, "Report sent for " .. target:Nick() .. ".")
    notifyStaff(msg)
    logLine(msg)

    return true
end

net.Receive("zcity_guilt_action", function(_, victim)
    if not IsValid(victim) or not victim:IsPlayer() then return end

    local caseid = net.ReadUInt(32)
    local attackerSteamID64 = net.ReadString()
    local target = net.ReadEntity()
    local action = net.ReadString()
    local playerCache = buildConnectedPlayerCache()

    local ok, err, entry, activeCase, resolvedTarget = canActOnTarget(victim, target, caseid, attackerSteamID64, action, playerCache)
    if not ok then
        notifyPlayer(victim, err or "Action rejected.")
        sendOpenPayload(victim, playerCache)
        return
    end

    if action == "respect" then
        local success, reason = doRespect(victim, resolvedTarget, entry)
        if not success then
            notifyPlayer(victim, reason or "Respect failed.")
            return
        end
    elseif action == "forgive" then
        local success, reason = doForgive(victim, resolvedTarget, entry, activeCase)
        if not success then
            notifyPlayer(victim, reason or "Forgive failed.")
            return
        end
    elseif action == "report" then
        local success, reason = doReport(victim, resolvedTarget, entry, activeCase)
        if not success then
            notifyPlayer(victim, reason or "Report failed.")
            return
        end
    else
        local success, reason = doPunish(victim, resolvedTarget, action, entry, activeCase)
        if not success then
            notifyPlayer(victim, reason or "Punish failed.")
            return
        end
    end

    syncVictimState(victim, playerCache)
    sendOpenPayload(victim, playerCache)
end)

concommand.Add("zcity_guilt_test_menu", function(ply)
    if not canUseDebugTestMenu(ply) then
        if IsValid(ply) then
            notifyPlayer(ply, "Test menu requires admin access with zb_dev enabled.")
        end
        return
    end

    local botTarget
    for _, v in ipairs(player.GetAll()) do
        if v ~= ply then
            botTarget = v
            break
        end
    end

    if not IsValid(botTarget) then
        ply:ChatPrint("No target player/bot found.")
        return
    end

    local data = getVictimData(ply)
    if not data then return end

    local activeCase = {
        id = (data.caseid or 0) + 1,
        createdAt = CurTime(),
        expiresAt = CurTime() + CFG.CaseExpiry,
        debug = true,
        rows = {}
    }

    local botSteamID64 = getPlayerSteamID64(botTarget)
    activeCase.rows[botSteamID64] = {
        ent = botTarget,
        harm = 35,
        karma = 10,
        nativeKarma = 0,
        last = CurTime(),
        name = botTarget:Nick(),
        steamid = botTarget:SteamID(),
        steamid64 = botSteamID64,
        decided = false
    }

    data.caseid = activeCase.id
    data.case = activeCase
    syncVictimState(ply)
    sendOpenPayload(ply)
end)

concommand.Add("zcity_guilt_preview", function(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:IsAdmin() then
        return
    end

    local targets = {}
    for _, v in ipairs(player.GetAll()) do
        if IsValid(v) and v ~= ply then
            targets[#targets + 1] = v
        end
    end

    if #targets <= 0 then
        notifyPlayer(ply, "Need at least one other player or bot on the server to preview the guilt menu.")
        return
    end

    local data = getVictimData(ply)
    if not data then return end

    local activeCase = {
        id = (data.caseid or 0) + 1,
        createdAt = CurTime(),
        expiresAt = CurTime() + math.max(tonumber(CFG.CaseExpiry) or 45, 30),
        debug = true,
        rows = {}
    }

    local samples = {
        { harm = 38.5, decided = false },
        { harm = 14.0, decided = false },
        { harm = 6.5, decided = false }
    }

    for i = 1, math.min(#targets, #samples) do
        local target = targets[i]
        local sample = samples[i]

        local targetSteamID64 = getPlayerSteamID64(target)

        activeCase.rows[targetSteamID64] = {
            ent = target,
            harm = sample.harm,
            karma = math.Round(sample.harm * 0.2, 1),
            nativeKarma = 0,
            last = CurTime(),
            name = target:Nick(),
            steamid = target:SteamID(),
            steamid64 = targetSteamID64,
            decided = sample.decided
        }
    end

    if not next(activeCase.rows) then
        notifyPlayer(ply, "Could not build a preview case.")
        return
    end

    data.caseid = activeCase.id
    data.case = activeCase

    syncVictimState(ply)
    sendOpenPayload(ply)
    notifyPlayer(ply, "Opened guilt menu preview.")
end)

timer.Simple(0, function()
    sendConfig()
end)
