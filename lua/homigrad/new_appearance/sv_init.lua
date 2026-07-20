-- 
util.AddNetworkString("Get_Appearance")
util.AddNetworkString("OnlyGet_Appearance")
util.AddNetworkString("ZC_RequestPermamodelConfig")
util.AddNetworkString("ZC_SendPermamodelConfig")
hg.Appearance = hg.Appearance or {}
local APmodule = hg.Appearance

hg.PointShop = hg.PointShop or {}
local PSmodule = hg.PointShop

local PERMAMODEL_PDATA_KEY = "zcity_permamodel_enabled"
local PERMAMODEL_DEFAULT_MODEL = "models/player/kleiner.mdl"
local PERMAMODEL_ALLOWED_GROUPS = {
    superadmin = true,
    owner = true,
    servermanager = true,
    headdeveloper = true,
    headadmin = true,
    developer = true,
    admin = true,
}

local function CanUsePermamodel(ply)
    if !IsValid(ply) or !ply:IsPlayer() then return false end

    local userGroup = string.lower((ply.GetUserGroup and ply:GetUserGroup()) or "")
    return PERMAMODEL_ALLOWED_GROUPS[userGroup] == true
end

local function LoadPermamodelPreference(ply)
    if !IsValid(ply) then return false end

    if ply.ZCPermamodelEnabled == nil then
        ply.ZCPermamodelEnabled = ply:GetPData(PERMAMODEL_PDATA_KEY, "0") == "1"
    end

    return ply.ZCPermamodelEnabled == true
end

local function FindPermamodelPath(selected)
    if !isstring(selected) then return end

    selected = string.Trim(selected)
    if selected == "" then return end

    local allModels = player_manager and player_manager.AllValidModels and player_manager.AllValidModels() or {}
    local modelPath = allModels[selected] or allModels[string.lower(selected)]

    if !modelPath then
        local selectedLower = string.lower(selected)

        for _, path in pairs(allModels) do
            if isstring(path) and string.lower(path) == selectedLower then
                modelPath = path
                break
            end
        end
    end

    if !isstring(modelPath) or modelPath == "" then return end
    if util.IsValidModel and !util.IsValidModel(modelPath) then return end

    return modelPath
end

local function GetFallbackPermamodel()
    if !util.IsValidModel or util.IsValidModel(PERMAMODEL_DEFAULT_MODEL) then
        return PERMAMODEL_DEFAULT_MODEL
    end

    local allModels = player_manager and player_manager.AllValidModels and player_manager.AllValidModels() or {}

    for _, path in pairs(allModels) do
        if isstring(path) and path ~= "" then
            return path
        end
    end

    return PERMAMODEL_DEFAULT_MODEL
end

local function SanitizeBodygroups(rawValue)
    if !isstring(rawValue) then return "" end

    rawValue = string.Trim(rawValue)
    if rawValue == "" then return "" end

    return (string.gsub(rawValue, "[^0-9]", ""))
end

local function ReadVectorFromString(rawValue, fallback)
    rawValue = isstring(rawValue) and rawValue or ""
    local values = {}

    for value in string.gmatch(rawValue, "[^%s]+") do
        values[#values + 1] = tonumber(value)
    end

    return Vector(
        math.Clamp(values[1] or fallback.x, 0, 1),
        math.Clamp(values[2] or fallback.y, 0, 1),
        math.Clamp(values[3] or fallback.z, 0, 1)
    )
end

local function ReadClientVector(ply, convarName, fallback)
    return ReadVectorFromString(ply:GetInfo(convarName) or "", fallback)
end

local function BuildPermamodelConfigFromUserInfo(ply)
    return {
        modelPath = FindPermamodelPath(ply:GetInfo("cl_playermodel")) or GetFallbackPermamodel(),
        skin = math.max(tonumber(ply:GetInfo("cl_playerskin")) or 0, 0),
        bodygroups = SanitizeBodygroups(ply:GetInfo("cl_playerbodygroups") or ""),
        playerColor = ReadClientVector(ply, "cl_playercolor", Vector(1, 1, 1)),
        weaponColor = ReadClientVector(ply, "cl_weaponcolor", Vector(0.3, 1, 2))
    }
end

local function NormalizePermamodelConfig(data, fallbackConfig)
    fallbackConfig = fallbackConfig or {}
    data = istable(data) and data or {}

    local config = {
        modelPath = FindPermamodelPath(data.model or data.modelPath or data.modelName) or fallbackConfig.modelPath or GetFallbackPermamodel(),
        skin = math.max(tonumber(data.skin) or fallbackConfig.skin or 0, 0),
        bodygroups = SanitizeBodygroups(data.bodygroups or data.bodygroup or "")
    }

    if config.bodygroups == "" then
        config.bodygroups = fallbackConfig.bodygroups or ""
    end

    config.playerColor = ReadVectorFromString(data.playerColor or "", fallbackConfig.playerColor or Vector(1, 1, 1))
    config.weaponColor = ReadVectorFromString(data.weaponColor or "", fallbackConfig.weaponColor or Vector(0.3, 1, 2))

    return config
end

local function GetPermamodelConfig(ply)
    local fallbackConfig = BuildPermamodelConfigFromUserInfo(ply)

    if !istable(ply.ZCPermamodelConfig) then
        return fallbackConfig
    end

    return NormalizePermamodelConfig(ply.ZCPermamodelConfig, fallbackConfig)
end

local function RequestPermamodelConfig(ply)
    if !IsValid(ply) or !ply:IsPlayer() then return end

    net.Start("ZC_RequestPermamodelConfig")
    net.Send(ply)
end

local function ApplyPermamodel(ply)
    if !IsValid(ply) then return end

    if !istable(ply.ZCPermamodelConfig) then
        RequestPermamodelConfig(ply)
    end

    local config = GetPermamodelConfig(ply)
    local modelPath = config.modelPath or GetFallbackPermamodel()

    util.PrecacheModel(modelPath)

    if ply:GetModel() ~= modelPath then
        ply:SetModel(modelPath)
    end

    local playerColor = config.playerColor or Vector(1, 1, 1)
    local weaponColor = config.weaponColor or Vector(0.3, 1, 2)

    if ply.SetPlayerColor then
        ply:SetPlayerColor(playerColor)
    end

    if ply.SetWeaponColor then
        ply:SetWeaponColor(weaponColor)
    end

    ply:SetNWVector("PlayerColor", playerColor)
    ply:SetNWString("PlayerName", ply:Nick())
    ply:SetNetVar("Accessories", {})
    ply:SetSubMaterial()
    ply:SetSkin(config.skin or 0)

    local bodygroups = config.bodygroups or ""
    if bodygroups ~= "" then
        ply:SetBodyGroups(bodygroups)
    else
        ply:SetBodyGroups("00000000000000000000")
    end

    ply.CurAppearance = nil
end

function APmodule.IsPermamodelEnabled(ply)
    return CanUsePermamodel(ply) and LoadPermamodelPreference(ply)
end

function APmodule.SetPermamodelEnabled(ply, enabled)
    if !CanUsePermamodel(ply) then return false end

    enabled = enabled == true
    ply.ZCPermamodelEnabled = enabled
    ply:SetPData(PERMAMODEL_PDATA_KEY, enabled and "1" or "0")

    if ply:Alive() then
        timer.Simple(0, function()
            if !IsValid(ply) then return end

            if enabled then
                ApplyPermamodel(ply)
            else
                ApplyAppearance(ply)
            end
        end)
    end

    return enabled
end

function APmodule.TogglePermamodel(ply)
    if !CanUsePermamodel(ply) then return false end

    return APmodule.SetPermamodelEnabled(ply, !APmodule.IsPermamodelEnabled(ply))
end

APmodule.CanUsePermamodel = CanUsePermamodel
APmodule.ApplyPermamodel = ApplyPermamodel

hook.Add("PlayerInitialSpawn", "ZC_Permamodel_LoadPreference", function(ply)
    LoadPermamodelPreference(ply)
    RequestPermamodelConfig(ply)
end)

net.Receive("ZC_SendPermamodelConfig", function(_, client)
    if !IsValid(client) or !client:IsPlayer() then return end

    client.ZCPermamodelConfig = NormalizePermamodelConfig(net.ReadTable(), BuildPermamodelConfigFromUserInfo(client))

    if APmodule.IsPermamodelEnabled(client) and client:Alive() then
        timer.Simple(0, function()
            if !IsValid(client) or !client:Alive() then return end
            if !APmodule.IsPermamodelEnabled(client) then return end

            ApplyPermamodel(client)
        end)
    end
end)

local function CheckAttachments(ply,tbl)
    if !IsValid(ply) or !ply:IsPlayer() then return end
    --print(ply:PS_HasItem(uid))
    if hg.Appearance.GetAccessToAll(ply) then return tbl end
    for i = 1, #tbl.AAttachments do
        local uid = tbl.AAttachments[i]
        if PSmodule.Items[uid] and (!ply:PS_HasItem(uid) and ply:IsPlayer()) then
            tbl.AAttachments[i] = ""
            ply:ChatPrint(uid .. " - not bought, removed")
        end

        if hg.Accessories[uid] and hg.Accessories[uid].disallowinappearance then
            tbl.AAttachments[i] = ""
            if ply.ChatPrint then ply:ChatPrint(uid .. " - is disallowed in default appearance, removed") end
        end
    end

    local tMdl = APmodule.PlayerModels[1][tbl.AModel] or APmodule.PlayerModels[2][tbl.AModel] or tbl.AModel
    tbl.ABodygroups = tbl.ABodygroups or {}
    for k,v in pairs(tbl.ABodygroups) do
        if not hg.Appearance.Bodygroups[k] then continue end
        if not hg.Appearance.Bodygroups[k][tMdl.sex and 2 or 1] then continue end
        local bodygroup = hg.Appearance.Bodygroups[k][tMdl.sex and 2 or 1][v]

        if not bodygroup then continue end

        local uid = bodygroup["ID"]
        --print(bodygroup[2],uid,PSmodule.Items[uid],ply:PS_HasItem(uid))
        if bodygroup[2] and uid and PSmodule.Items[uid] and (!ply:PS_HasItem(uid) and ply:IsPlayer()) then
            tbl.ABodygroups[k] = nil
            ply:ChatPrint(v .. " - not bought, removed")
        end
    end

    return tbl
end

local function ForceApplyAppearance(ply, tbl, noModelChange)
    local tMdl = APmodule.PlayerModels[1][tbl.AModel] or APmodule.PlayerModels[2][tbl.AModel] or tbl.AModel
    local mdl = istable(tMdl) and tMdl.mdl or tMdl
    if mdl ~= ply:GetModel() and !noModelChange then
        ply:SetModel(mdl)
    end

    local clr = tbl.AColor
    if ply.SetPlayerColor then
        ply:SetPlayerColor(Vector(clr.r / 255,clr.g / 255,clr.b / 255))
    end
    ply:SetNWVector( "PlayerColor", Vector(clr.r / 255,clr.g / 255,clr.b / 255) )

    ply:SetSubMaterial()

    local mats = ply:GetMaterials()
    --PrintTable(mats)
    if istable(tMdl) then
        for k, v in pairs(tMdl.submatSlots) do
            --print(k)
            local slot = 1
            for i = 1, #mats do
                --print(mats[i], v,mats[i] == v, i)
                if mats[i] == v then slot = i-1 break end
            end
            ply:SetSubMaterial(slot, hg.Appearance.Clothes[tMdl.sex and 2 or 1][tbl.AClothes[k]] or hg.Appearance.Clothes[tMdl.sex and 2 or 1]["normal"] )
            ply:SetNWString("Colthes" .. k,tbl.AClothes[k] or "normal")
            --print("true")
        end
    end
    for i = 1, #mats do
        if hg.Appearance.FacemapsSlots[mats[i]] and hg.Appearance.FacemapsSlots[mats[i]][tbl.AFacemap] then
            ply:SetSubMaterial(i - 1, hg.Appearance.FacemapsSlots[mats[i]][tbl.AFacemap])
        end
    end

    ply:SetNWString("PlayerName", tbl.AName)
    ply:SetBodyGroups( "00000000000000000000" )
    --print(mdl)
    --if mdl == "models/zcity/m/male_09.mdl" and ply:SteamID() == "STEAM_0:1:163575696" then
    --    timer.Simple(0,function()
    --    ply:SetBodygroup( 1,7 )
    --    end)
    --end

    local bodygroups = ply:GetBodyGroups()
    tbl.ABodygroups = tbl.ABodygroups or {}
    for k, v in ipairs(bodygroups) do
        if !v.name then continue end
        if !tbl.ABodygroups[v.name] then continue end
        if !hg.Appearance.Bodygroups[v.name] then continue end
        --PrintTable(hg.Appearance.Bodygroups[v.name][tMdl.sex and 2 or 1])
        for i = 0, #v.submodels do
            local b = v.submodels[i]
            if !hg.Appearance.Bodygroups[v.name][tMdl.sex and 2 or 1][tbl.ABodygroups[v.name]] then continue end
            if hg.Appearance.Bodygroups[v.name][tMdl.sex and 2 or 1][tbl.ABodygroups[v.name]][1] != b then continue end
            ply:SetBodygroup(k-1,i)
        end
    end

    ply:SetNetVar("Accessories", tbl.AAttachments)

    ply.CurAppearance = {}
    table.CopyFromTo(tbl, ply.CurAppearance)
end


local function WearAppearance(ply,tbl)
    local checked = CheckAttachments(ply,tbl)
    ForceApplyAppearance(ply,checked)
end

APmodule.ForceApplyAppearance = ForceApplyAppearance

local function CopyAppearanceAccessories(value)
    if istable(value) then
        return table.Copy(value)
    end

    return value
end

local function AccessoriesStateEqual(a, b)
    if istable(a) or istable(b) then
        if !istable(a) or !istable(b) then return false end
        if table.Count(a) != table.Count(b) then return false end

        for key, value in pairs(a) do
            if b[key] != value then
                return false
            end
        end

        for key, value in pairs(b) do
            if a[key] != value then
                return false
            end
        end

        return true
    end

    return a == b
end

local function CaptureLateReplayState(ply)
    return {
        model = ply:GetModel(),
        className = ply.PlayerClassName or "",
        accessories = CopyAppearanceAccessories(ply:GetNetVar("Accessories", "none"))
    }
end

local function ClearLateReplayState(ply)
    ply.ZCLateAppearanceReplayState = nil
    ply.ZCLateAppearanceReplayExpires = nil
end

local function ShouldLateReplayCachedAppearance(ply)
    if !IsValid(ply) or !ply:IsPlayer() then return false end
    if APmodule.IsPermamodelEnabled(ply) then return false end
    if !ply:Alive() then return false end

    local state = ply.ZCLateAppearanceReplayState
    local expires = ply.ZCLateAppearanceReplayExpires or 0
    if !istable(state) or expires < CurTime() then
        ClearLateReplayState(ply)
        return false
    end

    if ply:GetModel() != state.model then
        ClearLateReplayState(ply)
        return false
    end

    if (ply.PlayerClassName or "") != (state.className or "") then
        ClearLateReplayState(ply)
        return false
    end

    if !AccessoriesStateEqual(ply:GetNetVar("Accessories", "none"), state.accessories) then
        ClearLateReplayState(ply)
        return false
    end

    return true
end

local tWaitResponse = {}

local function RoundAllowsRandomAppearance()
    local round = CurrentRound and CurrentRound()
    return round and round.name == "assassinsgreed"
end

local function GetStableAppearance(client, preferred)
    if istable(preferred) and APmodule.AppearanceValidater(preferred) then
        return table.Copy(preferred)
    end
    if istable(client.CachedAppearance) and APmodule.AppearanceValidater(client.CachedAppearance) then
        return table.Copy(client.CachedAppearance)
    end
    if istable(client.CurAppearance) and APmodule.AppearanceValidater(client.CurAppearance) then
        return table.Copy(client.CurAppearance)
    end
end

local function GetOrCreateStableAppearance(client, preferred)
    local appearance = GetStableAppearance(client, preferred)
    if appearance then return appearance end

    appearance = APmodule.GetRandomAppearance()
    client.CachedAppearance = table.Copy(appearance)

    return appearance
end

local function ApplyStableAppearance(client, preferred)
    local appearance = GetOrCreateStableAppearance(client, preferred)

    WearAppearance(client, appearance)
    return true
end

function ApplyAppearance(Client,tAppearance,bRandom,bResponeIsValid,bUseCahsed)
    if not IsValid(Client) then return end
    if APmodule.IsPermamodelEnabled(Client) then
        ApplyPermamodel(Client)
        return
    end

    local isBot = Client.IsBot and Client:IsBot()
    local isRagdoll = Client.IsRagdoll and Client:IsRagdoll()

    if isRagdoll or ((isBot or bRandom) and RoundAllowsRandomAppearance()) then
        ClearLateReplayState(Client)
        tAppearance = APmodule.GetRandomAppearance()
        WearAppearance(Client,tAppearance)
        return
    end
    if isBot then
        ApplyStableAppearance(Client, tAppearance)
        return
    end
    if bRandom then
        ApplyStableAppearance(Client, tAppearance)
        return
    end
    if bUseCahsed then
        net.Start("OnlyGet_Appearance")
        net.Send(Client)

        ApplyStableAppearance(Client, tAppearance)
        Client.ZCLateAppearanceReplayState = CaptureLateReplayState(Client)
        Client.ZCLateAppearanceReplayExpires = CurTime() + 5
        return
    end

    if !bResponeIsValid then
        tWaitResponse[Client] = CurTime() + 3
        net.Start("Get_Appearance")
        net.Send(Client)
    return end
    local responseDeadline = tWaitResponse[Client]
    if !responseDeadline then return end
    tWaitResponse[Client] = nil

    if responseDeadline < CurTime() then return end

    if !istable(tAppearance) or !APmodule.AppearanceValidater(tAppearance) then
        ApplyStableAppearance(Client)
        return
    end

    ClearLateReplayState(Client)
    Client.CachedAppearance = table.Copy(tAppearance)
    WearAppearance(Client,tAppearance)
end

net.Receive("Get_Appearance",function(len,client)
    local tAppearance = net.ReadTable()
    local bRandom = net.ReadBool()
    if !APmodule.AppearanceValidater(tAppearance) then bRandom = true end

    ApplyAppearance(client,tAppearance, table.IsEmpty(tAppearance) and true or bRandom,true)
end)

net.Receive("OnlyGet_Appearance",function(len,client)
    local tAppearance = net.ReadTable()
    if istable(tAppearance) and APmodule.AppearanceValidater(tAppearance) then
        client.CachedAppearance = table.Copy(tAppearance)
    elseif !GetStableAppearance(client) then
        client.CachedAppearance = nil
    end

    if !ShouldLateReplayCachedAppearance(client) then return end
    if !istable(client.CachedAppearance) or !APmodule.AppearanceValidater(client.CachedAppearance) then
        ClearLateReplayState(client)
        return
    end

    timer.Simple(0, function()
        if !ShouldLateReplayCachedAppearance(client) then return end
        if !istable(client.CachedAppearance) or !APmodule.AppearanceValidater(client.CachedAppearance) then
            ClearLateReplayState(client)
            return
        end

        ClearLateReplayState(client)
        WearAppearance(client, table.Copy(client.CachedAppearance))
    end)
end)

APmodule.ApplyAppearance = ApplyAppearance

-- Ragdoll apply
function ApplyAppearanceRagdoll(ent, ply)
    local Appearance = ply.CurAppearance
    if !Appearance then return end
    ent:SetNWString("PlayerName", ply:GetNWString("PlayerName", Appearance.AName))
    ent:SetNetVar("Accessories", ply:GetNetVar("Accessories",""))

    local tMdl = APmodule.PlayerModels[1][ent:GetModel()] or APmodule.PlayerModels[2][ent:GetModel()] or ent:GetModel()
    if istable(tMdl) then
        for k,v in pairs(tMdl.submatSlots) do
            ent:SetNWString("Colthes" .. k,ply:GetNWString("Colthes" .. k,"normal"))
        end
    end
end

-- Sandbox applyApperance 
if engine.ActiveGamemode() == "sandbox" then
    hook.Add("PlayerSpawn","SetAppearance",function(ply)
        if OverrideSpawn then return end
        timer.Simple(0,function()
            ApplyAppearance(ply,nil,nil,nil,true)
            --ply.OldAppearance = false
        end)
    end)
end
