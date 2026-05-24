if not ulx then return end

local CATEGORY_NAME = "Voting"

if SERVER then
    util.AddNetworkString("ulx_votemode")
end

local function voteModeDone(t)
    local results = t.results
    local winner
    local winnernum = 0
    for id, numvotes in pairs(results) do
        if numvotes > winnernum then
            winner = id
            winnernum = numvotes
        end
    end

    local str
    if not winner then
        str = "Vote results: No mode won because no one voted!"
    else
        local mode = zb.modes[t.options[winner]]
        if mode and mode.CanLaunch and mode:CanLaunch() then
            str = "Vote results: Mode '" .. t.options[winner] .. "' won. (" .. winnernum .. "/" .. t.voters .. ")"
            NextRound(t.options[winner])
        else
            str = "Vote results: Mode '" .. t.options[winner] .. "' cannot be launched."
        end
    end
    ULib.tsay(_, str)
    ulx.logString(str)
    Msg(str .. "\n")
end

function ulx.votemode(calling_ply, ...)
    calling_ply.CoolDownVote = calling_ply.CoolDownVote or 0
    if calling_ply.CoolDownVote > CurTime() then -- if calling_ply.CoolDownVote or 0 > CurTime() then Useless wtf
        ULib.tsayError(calling_ply, "Wait ".. ( math.Round( calling_ply.CoolDownVote - CurTime(), 1 ) ) .." before create a new vote", true)    
    return end
    calling_ply.CoolDownVote = CurTime() + 180

    local argv = {...}

    if ulx.voteInProgress then
        ULib.tsayError(calling_ply, "There is already a vote in progress. Please wait for the current one to end.", true)
        return
    end

    for i = 2, #argv do
        if ULib.findInTable(argv, argv[i], 1, i - 1) then
            ULib.tsayError(calling_ply, "Mode " .. argv[i] .. " was listed twice. Please try again")
            return
        end
    end

    for _, modeName in ipairs(argv) do
        local mode = zb.modes[modeName]
        if not (mode and mode.CanLaunch and mode:CanLaunch()) then
            ULib.tsayError(calling_ply, "Mode '" .. modeName .. "' cannot be launched.")
            return
        end
    end

    if #argv > 1 then
        ulx.doVote("Change mode to..", argv, voteModeDone, _, _, _, argv, calling_ply)
        ulx.fancyLogAdmin(calling_ply, "#A started a votemode with options" .. string.rep(" #s", #argv), ...)
    elseif #argv == 1 then
        ulx.doVote("Change mode to " .. argv[1] .. "?", {"Yes", "No"}, function(t)
            local yesVotes = t.results[1] or 0
            local noVotes = t.results[2] or 0
            if yesVotes > noVotes then
                voteModeDone({results = {[1] = yesVotes}, options = argv, voters = t.voters})
            else
                ULib.tsay(_, "Vote results: Mode change to '" .. argv[1] .. "' was rejected.")
                ulx.logString("Vote results: Mode change to '" .. argv[1] .. "' was rejected.")
                Msg("Vote results: Mode change to '" .. argv[1] .. "' was rejected.\n")
            end
        end, _, _, _, argv, calling_ply)
        ulx.fancyLogAdmin(calling_ply, "#A started a votemode for #s", argv[1])
    else
        ULib.tsayError(calling_ply, "You must provide at least one option for the vote.", true)
    end
end

local votemode = ulx.command(CATEGORY_NAME, "ulx votemode", ulx.votemode, "!votemode")
votemode:addParam{type = ULib.cmds.StringArg, completes = {"tdm", "gwars", "riot", "criresp", "defense", "hl2dm", "hl3", "assassinsgreed", "dm", "cstrike", "ww2", "lastmanstanding", "sandbox" }, hint = "mode", ULib.cmds.restrictToCompletes, ULib.cmds.takeRestOfLine, repeat_min = 1, repeat_max = 10}
votemode:defaultAccess(ULib.ACCESS_ADMIN)
votemode:help("Starts a public mode vote.")

if SERVER then ulx.convar("votemodeSuccessratio", "0.5", _, ULib.ACCESS_ADMIN) end
if SERVER then ulx.convar("votemodeMinvotes", "3", _, ULib.ACCESS_ADMIN) end

local HMCD_CATEGORY_NAME = "Homicide"
local hmcdBuildTraitorAssistants
local hmcdSyncTraitorState
local hmcdRefreshMainTraitors
local hmcdApplyTraitorLoadout

if SERVER then
    hmcdBuildTraitorAssistants = function(mode, mainTraitor)
        local traitor_assistants = {}

        if not IsValid(mainTraitor) or not mainTraitor.MainTraitor then
            return traitor_assistants
        end

        for _, other_ply in player.Iterator() do
            if other_ply.isTraitor then
                local appearance = other_ply.CurAppearance or {}
                local color = appearance.AColor or (other_ply.GetPlayerColor and other_ply:GetPlayerColor():ToColor()) or color_white
                local name = appearance.AName or (other_ply.GetPlayerName and other_ply:GetPlayerName()) or other_ply:Nick() or "error"
                local steamID = other_ply:SteamID() or ""
                local subRole = other_ply.SubRole or ""

                if not IsColor(color) then
                    color = Color(color.r, color.g, color.b)
                end

                traitor_assistants[#traitor_assistants + 1] = {color, name, steamID, subRole}
            end
        end

        return traitor_assistants
    end

    hmcdSyncTraitorState = function(mode, ply)
        if not IsValid(ply) then return end

        local traitor_amt = 0

        if ply.isTraitor then
            for _, other_ply in player.Iterator() do
                if other_ply.isTraitor then
                    traitor_amt = traitor_amt + 1
                end
            end
        end

        local traitor_assistants = hmcdBuildTraitorAssistants(mode, ply)

        net.Start("HMCD_RoundStart")
            net.WriteBool(ply.isTraitor == true)
            net.WriteBool(ply.isGunner == true)
            net.WriteString(mode.Type or "standard")
            net.WriteBool(true)
            net.WriteString(ply.SubRole or "")
            net.WriteBool(ply.MainTraitor == true)

            if ply.isTraitor then
                net.WriteString(mode.TraitorWord or "")
                net.WriteString(mode.TraitorWordSecond or "")
                net.WriteUInt(traitor_amt, mode.TraitorExpectedAmtBits)
            else
                net.WriteString("")
                net.WriteString("")
                net.WriteUInt(0, mode.TraitorExpectedAmtBits)
            end

            if ply.MainTraitor then
                for _, traitor_info in ipairs(traitor_assistants) do
                    net.WriteColor(traitor_info[1], false)
                    net.WriteString(traitor_info[2])
                end
            end

            net.WriteString(ply.Profession or "")
        net.Send(ply)

        if ply.MainTraitor then
            timer.Simple(0.5, function()
                if not IsValid(ply) or not ply.isTraitor or not ply.MainTraitor then return end

                net.Start("HMCD_UpdateTraitorAssistants")
                    net.WriteUInt(#traitor_assistants, 8)

                    for _, info in ipairs(traitor_assistants) do
                        net.WriteColor(info[1])
                        net.WriteString(info[2])
                        net.WriteString(info[3])
                        net.WriteString(info[4] or "")
                    end
                net.Send(ply)
            end)
        end

        local role = mode.Roles[mode.Type] and mode.Roles[mode.Type][(ply.isTraitor and "traitor") or (ply.isGunner and "gunner") or "innocent"]
        if role then
            zb.GiveRole(ply, role.name, role.color)
        end
    end

    hmcdRefreshMainTraitors = function(mode)
        for _, main_traitor in player.Iterator() do
            if IsValid(main_traitor) and main_traitor.isTraitor and main_traitor.MainTraitor then
                local traitor_assistants = hmcdBuildTraitorAssistants(mode, main_traitor)

                net.Start("HMCD_UpdateTraitorAssistants")
                    net.WriteUInt(#traitor_assistants, 8)

                    for _, info in ipairs(traitor_assistants) do
                        net.WriteColor(info[1])
                        net.WriteString(info[2])
                        net.WriteString(info[3])
                        net.WriteString(info[4] or "")
                    end
                net.Send(main_traitor)
            end
        end
    end

    hmcdApplyTraitorLoadout = function(mode, ply)
        if not IsValid(ply) then return end

        ply.SubRole = nil

        ApplyAppearance(ply, nil, nil, nil, true)
        ply:Spawn()
        ply:GetRandomSpawn()

        if not ply:Alive() then return false end

        ply:SetSuppressPickupNotices(true)
        ply.noSound = true

        if mode.Type == "supermario" and mode.Types.supermario and mode.Types.supermario.CustomJump then
            mode.Types.supermario.CustomJump(ply)
        end

        local role_round = mode.RoleChooseRoundTypes and mode.RoleChooseRoundTypes[mode.Type]
        local sub_role

        if role_round then
            local convar_name = mode.Type == "soe" and mode.ConVarName_SubRole_Traitor_SOE or mode.ConVarName_SubRole_Traitor
            sub_role = (convar_name and ply:GetInfo(convar_name)) or role_round.TraitorDefaultRole or (mode.Type == "soe" and "traitor_default_soe" or "traitor_default")
            local role_info = mode.SubRoles[sub_role]

            if not role_info or not role_round.Traitor[sub_role] then
                sub_role = role_round.TraitorDefaultRole or (mode.Type == "soe" and "traitor_default_soe" or "traitor_default")
                role_info = mode.SubRoles[sub_role]
            end

            if role_info and role_info.SpawnFunction then
                ply.SubRole = sub_role
                role_info.SpawnFunction(ply)
            end
        elseif mode.Types[mode.Type] and mode.Types[mode.Type].TraitorLoot then
            mode.Types[mode.Type].TraitorLoot(ply)
        end

        if mode.Type == "soe" and ply.isTraitor then
            local walkie_talkie = ply:Give("weapon_walkie_talkie")
            if IsValid(walkie_talkie) and walkie_talkie.Frequencies then
                mode.TraitorFrequency = mode.TraitorFrequency or math.random(1, #walkie_talkie.Frequencies)
                walkie_talkie.Frequency = mode.TraitorFrequency
                ply:ChatPrint("Walkie-Talkie Frequency = " .. walkie_talkie.Frequencies[mode.TraitorFrequency])
            end
        end

        local hands = ply:Give("weapon_hands_sh")
        if IsValid(hands) then
            ply:SetActiveWeapon(hands)
        end

        ply:SetNetVar("flashlight", false)

        timer.Simple(0.1, function()
            if IsValid(ply) then
                ply.noSound = false
                ply:SetSuppressPickupNotices(false)
            end
        end)

        return true
    end
end

function ulx.hmcdtraitor(calling_ply, target_ply)
    if CLIENT then return end

    local mode = CurrentRound()
    target_ply = IsValid(target_ply) and target_ply or calling_ply

    if not mode or mode.name ~= "hmcd" then
        ULib.tsayError(calling_ply, "Dieser Command funktioniert nur in Homicide.", true)
        return
    end

    if zb.ROUND_STATE ~= 1 then
        ULib.tsayError(calling_ply, "Der Command funktioniert nur in einer laufenden Homicide-Runde.", true)
        return
    end

    if not IsValid(target_ply) or target_ply:Team() == TEAM_SPECTATOR then
        ULib.tsayError(calling_ply, "Spectators cannot be set as the main traitor.", true)
        return
    end

    for _, ply in player.Iterator() do
        if ply ~= target_ply and ply.MainTraitor then
            ply.MainTraitor = false
        end
    end

    target_ply.Profession = nil
    target_ply.isTraitor = true
    target_ply.isGunner = false
    target_ply.MainTraitor = true

    if not hmcdApplyTraitorLoadout(mode, target_ply) then
        ULib.tsayError(calling_ply, "Die Traitor-Rolle konnte nicht angewendet werden.", true)
        return
    end

    hmcdSyncTraitorState(mode, target_ply)
    hmcdRefreshMainTraitors(mode)

    local espModule = hg and hg.AdminSystem and hg.AdminSystem.GetModule and hg.AdminSystem:GetModule("esp")
    if espModule and espModule.SyncHMCDRolesForAll then
        espModule:SyncHMCDRolesForAll()
    end

    if target_ply == calling_ply then
        ulx.fancyLogAdmin(calling_ply, "#A made themselves the main traitor in Homicide")
    else
        ulx.fancyLogAdmin(calling_ply, "#A made #T the main traitor in Homicide", target_ply)
    end
end

local hmcdtraitor = ulx.command(HMCD_CATEGORY_NAME, "ulx hmcdtraitor", ulx.hmcdtraitor, "!hmcdtraitor")
hmcdtraitor:addParam{type = ULib.cmds.PlayerArg, default = "^", ULib.cmds.optional}
hmcdtraitor:help("Makes the target player the main traitor in the current Homicide round.")

local ZCITY_CATEGORY_NAME = "Z-City"
local HMCD_INNOCLASS_COMPLETES = {
    "builder",
    "cook",
    "engineer",
    "huntsman",
    "lucky guy",
    "medic",
    "thug",
}


function ulx.permamodel(calling_ply)
    if CLIENT then return end

    if not IsValid(calling_ply) then return end

    if not hg or not hg.Appearance or not hg.Appearance.TogglePermamodel then
        ULib.tsayError(calling_ply, "Permamodel ist gerade nicht verfuegbar.", true)
        return
    end

    if hg.Appearance.CanUsePermamodel and not hg.Appearance.CanUsePermamodel(calling_ply) then
        ULib.tsayError(calling_ply, "You do not have permission to use permamodel.", true)
        return
    end

    local enabled = hg.Appearance.TogglePermamodel(calling_ply)

    if enabled then
        calling_ply:ChatPrint("Permamodel aktiviert: Du spawnst mit deinem ausgewaehlten Spielermodel.")
    else
        calling_ply:ChatPrint("Permamodel deaktiviert: Du spawnst wieder normal mit Appearance.")
    end

    ulx.fancyLogAdmin(calling_ply, enabled and "#A enabled permamodel" or "#A disabled permamodel")
end

local permamodel = ulx.command(ZCITY_CATEGORY_NAME, "ulx permamodel", ulx.permamodel, "!permamodel")
permamodel:help("Toggles persistent spawning with the selected player model instead of Appearance.")

function ulx.innoclass(calling_ply, target_ply, class_name)
    if CLIENT then return end

    target_ply = IsValid(target_ply) and target_ply or calling_ply
    local homicide_mode = zb and zb.modes and zb.modes["hmcd"]

    if not homicide_mode or not homicide_mode.NormalizeProfessionId or not homicide_mode.ApplyProfessionSelection then
        ULib.tsayError(calling_ply, "The Homicide class system is not available right now.", true)
        return
    end

    local profession_id = homicide_mode.NormalizeProfessionId(class_name or "")
    local mode = CurrentRound()
    local round_type = mode and mode.name == "hmcd" and mode.Type or nil
    local available_classes = homicide_mode.GetAvailableProfessionList and homicide_mode.GetAvailableProfessionList(round_type) or ""

    if not profession_id then
        ULib.tsayError(calling_ply, "Unknown innocent class '" .. string.Trim(class_name or "") .. "'. Available classes: " .. available_classes, true)
        return
    end

    if round_type and homicide_mode.RoleChooseRoundTypes[round_type] and not homicide_mode.RoleChooseRoundTypes[round_type].Professions[profession_id] then
        ULib.tsayError(calling_ply, "The class '" .. profession_id .. "' is not available in this Homicide type. Available classes: " .. available_classes, true)
        return
    end

    homicide_mode.ApplyProfessionSelection(calling_ply, target_ply, profession_id)

    ulx.fancyLogAdmin(calling_ply, "#A set #T's innocent class to #s", target_ply, (homicide_mode.Professions[profession_id] and homicide_mode.Professions[profession_id].Name) or profession_id)
end

local innoclass = ulx.command(HMCD_CATEGORY_NAME, "ulx innoclass", ulx.innoclass, "!innoclass")
innoclass:addParam{type = ULib.cmds.PlayerArg, default = "^", ULib.cmds.optional}
innoclass:addParam{type = ULib.cmds.StringArg, hint = "class", completes = HMCD_INNOCLASS_COMPLETES, ULib.cmds.takeRestOfLine}
innoclass:help("Sets a player's preferred Homicide innocent class.")

function ulx.power(calling_ply, target_ply)
    if CLIENT then return end

    target_ply = IsValid(target_ply) and target_ply or calling_ply

    local was_enabled = target_ply.ZCPowerEnabled == true

    if not zb.RunHomigradChatCommand("power", calling_ply, target_ply) then
        return
    end

    local is_enabled = target_ply.ZCPowerEnabled == true

    if was_enabled == is_enabled then
        return
    end

    ulx.fancyLogAdmin(calling_ply, is_enabled and "#A enabled super power for #T" or "#A disabled super power for #T", target_ply)
end

local power = ulx.command(ZCITY_CATEGORY_NAME, "ulx power", ulx.power, "!power")
power:addParam{type = ULib.cmds.PlayerArg, default = "^", ULib.cmds.optional}
power:help("Toggles super power for a player.")

function ulx.zcgod(calling_ply, target_ply)
    if CLIENT then return end

    target_ply = IsValid(target_ply) and target_ply or calling_ply

    if not zb.RunHomigradChatCommand("zc_god", calling_ply, target_ply) then
        return
    end

    if target_ply == calling_ply then
        ulx.fancyLogAdmin(calling_ply, "#A toggled godmode for themselves")
    else
        ulx.fancyLogAdmin(calling_ply, "#A toggled godmode for #T", target_ply)
    end
end

local zcgod = ulx.command(ZCITY_CATEGORY_NAME, "ulx zcgod", ulx.zcgod, {"!zc_god", "!zcgod"})
zcgod:addParam{type = ULib.cmds.PlayerArg, default = "^", ULib.cmds.optional}
zcgod:help("Toggles Z-City godmode for a player.")

if SERVER and zb.FinalizeZCityPermissions then
	timer.Simple(0, zb.FinalizeZCityPermissions)
end
