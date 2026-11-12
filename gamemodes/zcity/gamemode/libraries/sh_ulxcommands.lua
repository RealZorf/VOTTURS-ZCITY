if not ulx then return end

local function announce(str)
	ULib.tsay(_, str)
	ulx.logString(str)
	Msg(str .. "\n")
end

local function voteModeDone(t)
	local winner, winnernum
	for id, numvotes in pairs(t.results) do
		if not winner or numvotes > winnernum then
			winner = id
			winnernum = numvotes
		end
	end

	local modeName = winner and t.options[winner]
	local mode = modeName and zb.modes[modeName]
	if mode and mode.CanLaunch and mode:CanLaunch() then
		announce("Vote results: Mode '" .. modeName .. "' won. (" .. winnernum .. "/" .. t.voters .. ")")
		NextRound(modeName)
	elseif modeName then
		announce("Vote results: Mode '" .. modeName .. "' cannot be launched.")
	else
		announce("Vote results: No mode won because no one voted!")
	end
end

function ulx.votemode(calling_ply, ...)
	if (calling_ply.CoolDownVote or 0) > CurTime() then
		ULib.tsayError(calling_ply, "Wait " .. math.Round(calling_ply.CoolDownVote - CurTime(), 1) .. " before create a new vote", true)
		return
	end
	calling_ply.CoolDownVote = CurTime() + 180

	if ulx.voteInProgress then
		ULib.tsayError(calling_ply, "There is already a vote in progress. Please wait for the current one to end.", true)
		return
	end

	local argv = {...}
	local seen = {}
	for _, modeName in ipairs(argv) do
		if seen[modeName] then
			ULib.tsayError(calling_ply, "Mode " .. modeName .. " was listed twice. Please try again")
			return
		end
		seen[modeName] = true

		local mode = zb.modes[modeName]
		if not (mode and mode.CanLaunch and mode:CanLaunch()) then
			ULib.tsayError(calling_ply, "Mode '" .. modeName .. "' cannot be launched.")
			return
		end
	end

	if #argv > 1 then
		ulx.doVote("Change mode to..", argv, voteModeDone)
		ulx.fancyLogAdmin(calling_ply, "#A started a votemode with options" .. string.rep(" #s", #argv), ...)
	elseif #argv == 1 then
		ulx.doVote("Change mode to " .. argv[1] .. "?", {"Yes", "No"}, function(t)
			if (t.results[1] or 0) > (t.results[2] or 0) then
				voteModeDone({results = {[1] = t.results[1]}, options = argv, voters = t.voters})
			else
				announce("Vote results: Mode change to '" .. argv[1] .. "' was rejected.")
			end
		end)
		ulx.fancyLogAdmin(calling_ply, "#A started a votemode for #s", argv[1])
	else
		ULib.tsayError(calling_ply, "You must provide at least one option for the vote.", true)
	end
end

local votemode = ulx.command("Voting", "ulx votemode", ulx.votemode, "!votemode")
votemode:addParam{type = ULib.cmds.StringArg, completes = {"tdm", "gwars", "riot", "criresp", "defense", "hl2dm", "hl3", "assassinsgreed", "dm", "cstrike", "ww2", "lastmanstanding", "sandbox", "tdmmelee"}, hint = "mode", ULib.cmds.restrictToCompletes, ULib.cmds.takeRestOfLine, repeat_min = 1, repeat_max = 10}
votemode:help("Starts a public mode vote.")
if SERVER then ULib.ucl.registerAccess("ulx votemode", nil, "Grants access to the ulx votemode command", "Command") end

function ulx.hmcdtraitor(calling_ply, target_ply)
	if not SERVER then return end

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
	target_ply.SubRole = nil

	ApplyAppearance(target_ply, nil, nil, nil, true)
	target_ply:Spawn()
	target_ply:GetRandomSpawn()

	if not target_ply:Alive() then
		ULib.tsayError(calling_ply, "Die Traitor-Rolle konnte nicht angewendet werden.", true)
		return
	end

	target_ply:SetSuppressPickupNotices(true)
	target_ply.noSound = true

	if mode.Type == "supermario" and mode.Types.supermario and mode.Types.supermario.CustomJump then
		mode.Types.supermario.CustomJump(target_ply)
	end

	local role_round = mode.RoleChooseRoundTypes and mode.RoleChooseRoundTypes[mode.Type]
	if role_round then
		local default_role = role_round.TraitorDefaultRole or (mode.Type == "soe" and "traitor_default_soe" or "traitor_default")
		local convar_name = mode.Type == "soe" and mode.ConVarName_SubRole_Traitor_SOE or mode.ConVarName_SubRole_Traitor
		local sub_role = (convar_name and target_ply:GetInfo(convar_name)) or default_role
		local role_info = mode.SubRoles[sub_role]

		if not role_info or not role_round.Traitor[sub_role] then
			sub_role = default_role
			role_info = mode.SubRoles[sub_role]
		end

		if role_info and role_info.SpawnFunction then
			target_ply.SubRole = sub_role
			role_info.SpawnFunction(target_ply)
		end
	elseif mode.Types[mode.Type] and mode.Types[mode.Type].TraitorLoot then
		mode.Types[mode.Type].TraitorLoot(target_ply)
	end

	if mode.Type == "soe" then
		local walkie_talkie = target_ply:Give("weapon_walkie_talkie")
		if IsValid(walkie_talkie) and walkie_talkie.Frequencies then
			mode.TraitorFrequency = mode.TraitorFrequency or math.random(1, #walkie_talkie.Frequencies)
			walkie_talkie.Frequency = mode.TraitorFrequency
			target_ply:ChatPrint("Walkie-Talkie Frequency = " .. walkie_talkie.Frequencies[mode.TraitorFrequency])
		end
	end

	local hands = target_ply:Give("weapon_hands_sh")
	if IsValid(hands) then
		target_ply:SetActiveWeapon(hands)
	end

	target_ply:SetNetVar("flashlight", false)
	timer.Simple(0.1, function()
		if not IsValid(target_ply) then return end
		target_ply.noSound = false
		target_ply:SetSuppressPickupNotices(false)
	end)

	local traitor_amt = 0
	local assistants = {}
	for _, other_ply in player.Iterator() do
		if not other_ply.isTraitor then continue end
		traitor_amt = traitor_amt + 1

		local appearance = other_ply.CurAppearance or {}
		local color = appearance.AColor or (other_ply.GetPlayerColor and other_ply:GetPlayerColor():ToColor()) or color_white
		assistants[#assistants + 1] = {
			IsColor(color) and color or Color(color.r, color.g, color.b),
			appearance.AName or (other_ply.GetPlayerName and other_ply:GetPlayerName()) or other_ply:Nick() or "error"
		}
	end

	net.Start("HMCD_RoundStart")
		net.WriteBool(true)
		net.WriteBool(false)
		net.WriteString(mode.Type or "standard")
		net.WriteBool(true)
		net.WriteString(target_ply.SubRole or "")
		net.WriteBool(true)
		net.WriteString(mode.TraitorWord or "")
		net.WriteString(mode.TraitorWordSecond or "")
		net.WriteUInt(traitor_amt, mode.TraitorExpectedAmtBits)
		for _, info in ipairs(assistants) do
			net.WriteColor(info[1], false)
			net.WriteString(info[2])
		end
		net.WriteString(target_ply.Profession or "")
	net.Send(target_ply)

	timer.Simple(0.5, function()
		if IsValid(target_ply) and target_ply.isTraitor and target_ply.MainTraitor then
			mode:SendTraitorAssistants(target_ply)
		end
	end)

	local role = mode.Roles[mode.Type] and mode.Roles[mode.Type].traitor
	if role then
		zb.GiveRole(target_ply, role.name, role.color)
	end

	mode:BroadcastTraitorAssistants()

	if target_ply == calling_ply then
		ulx.fancyLogAdmin(calling_ply, "#A made themselves the main traitor in Homicide")
	else
		ulx.fancyLogAdmin(calling_ply, "#A made #T the main traitor in Homicide", target_ply)
	end
end

local hmcdtraitor = ulx.command("Homicide", "ulx hmcdtraitor", ulx.hmcdtraitor, "!hmcdtraitor")
hmcdtraitor:addParam{type = ULib.cmds.PlayerArg, default = "^", ULib.cmds.optional}
hmcdtraitor:help("Makes the target player the main traitor in the current Homicide round.")
if SERVER then ULib.ucl.registerAccess("ulx hmcdtraitor", nil, "Grants access to the ulx hmcdtraitor command", "Command") end

function ulx.permamodel(calling_ply)
	if not SERVER or not IsValid(calling_ply) then return end

	if not hg or not hg.Appearance or not hg.Appearance.TogglePermamodel then
		ULib.tsayError(calling_ply, "Permamodel ist gerade nicht verfuegbar.", true)
		return
	end

	local enabled = hg.Appearance.TogglePermamodel(calling_ply)
	calling_ply:ChatPrint(enabled and "Permamodel aktiviert: Du spawnst mit deinem ausgewaehlten Spielermodel." or "Permamodel deaktiviert: Du spawnst wieder normal mit Appearance.")
	ulx.fancyLogAdmin(calling_ply, enabled and "#A enabled permamodel" or "#A disabled permamodel")
end

local permamodel = ulx.command("Z-City", "ulx permamodel", ulx.permamodel, "!permamodel")
permamodel:help("Toggles persistent spawning with the selected player model instead of Appearance.")
if SERVER then ULib.ucl.registerAccess("ulx permamodel", nil, "Grants access to the ulx permamodel command", "Command") end

function ulx.innoclass(calling_ply, target_ply, class_name)
	if not SERVER then return end

	target_ply = IsValid(target_ply) and target_ply or calling_ply
	local homicide_mode = zb and zb.modes and zb.modes.hmcd
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

local innoclass = ulx.command("Homicide", "ulx innoclass", ulx.innoclass)
innoclass:addParam{type = ULib.cmds.PlayerArg, default = "^", ULib.cmds.optional}
innoclass:addParam{type = ULib.cmds.StringArg, hint = "class", completes = {"builder", "cook", "engineer", "huntsman", "lucky guy", "medic", "thug"}, ULib.cmds.takeRestOfLine}
innoclass:help("Sets a player's preferred Homicide innocent class.")
if SERVER then ULib.ucl.registerAccess("ulx innoclass", nil, "Grants access to the ulx innoclass command", "Command") end

function ulx.power(calling_ply, target_ply)
	if not SERVER then return end

	target_ply = IsValid(target_ply) and target_ply or calling_ply
	if not COMMANDS or not COMMANDS.power or not COMMANDS.power[1] then
		ULib.tsayError(calling_ply, "The command 'power' is not available.", true)
		return
	end

	local was_enabled = target_ply.ZCPowerEnabled == true
	COMMANDS.power[1](calling_ply, (IsValid(target_ply) and target_ply ~= calling_ply) and {target_ply:Name()} or {})
	if was_enabled == (target_ply.ZCPowerEnabled == true) then return end

	ulx.fancyLogAdmin(calling_ply, target_ply.ZCPowerEnabled and "#A enabled super power for #T" or "#A disabled super power for #T", target_ply)
end

local power = ulx.command("Z-City", "ulx power", ulx.power)
power:addParam{type = ULib.cmds.PlayerArg, default = "^", ULib.cmds.optional}
power:help("Toggles super power for a player.")
if SERVER then ULib.ucl.registerAccess("ulx power", nil, "Grants access to the ulx power command", "Command") end

function ulx.guiltadmin(calling_ply)
	if not SERVER or not IsValid(calling_ply) then return end

	net.Start("zcity_guilt_admin_openmenu")
	net.Send(calling_ply)
	ulx.fancyLogAdmin(calling_ply, "#A opened the guilt admin menu")
end

local guiltadmin = ulx.command("Z-City", "ulx guiltadmin", ulx.guiltadmin, "!guiltadmin")
guiltadmin:help("Opens the Z-City guilt admin menu.")
if SERVER then ULib.ucl.registerAccess("ulx guiltadmin", nil, "Grants access to the ulx guiltadmin command", "Command") end
