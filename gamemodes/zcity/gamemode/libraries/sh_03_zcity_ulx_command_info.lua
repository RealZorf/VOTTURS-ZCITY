zb = zb or {}
zb.UCL = zb.UCL or {}

local CAT = "Z-City"
local DEFAULT_GROUPS = {"superadmin"}

function zb.BuildPermissionTooltip(info)
	if not istable(info) then return "" end

	local lines = {}

	if isstring(info.title) and info.title ~= "" then
		lines[#lines + 1] = info.title
	end

	if isstring(info.summary) and info.summary ~= "" then
		lines[#lines + 1] = "What: " .. info.summary
	end

	if isstring(info.when) and info.when ~= "" then
		lines[#lines + 1] = "When: " .. info.when
	end

	if isstring(info.chat) and info.chat ~= "" then
		lines[#lines + 1] = "Chat: " .. info.chat
	end

	if isstring(info.console) and info.console ~= "" then
		lines[#lines + 1] = "Console: " .. info.console
	end

	if isstring(info.perm) and info.perm ~= "" then
		lines[#lines + 1] = "Permission: " .. info.perm
	end

	if isstring(info.differs) and info.differs ~= "" then
		lines[#lines + 1] = "Not the same as: " .. info.differs
	end

	if isstring(info.aliases) and info.aliases ~= "" then
		lines[#lines + 1] = "Also works as: " .. info.aliases
	end

	return table.concat(lines, "\n")
end

function zb.FormatULXHelpText(info)
	if not istable(info) then return "" end

	local lines = {}

	if isstring(info.title) and info.title ~= "" then
		lines[#lines + 1] = info.title
	end

	if isstring(info.summary) and info.summary ~= "" then
		lines[#lines + 1] = info.summary
	end

	if isstring(info.chat) and info.chat ~= "" then
		lines[#lines + 1] = "Chat: " .. info.chat
	end

	if isstring(info.console) and info.console ~= "" then
		lines[#lines + 1] = "Console: " .. info.console
	end

	if isstring(info.when) and info.when ~= "" then
		lines[#lines + 1] = "Use when: " .. info.when
	end

	if isstring(info.differs) and info.differs ~= "" then
		lines[#lines + 1] = "Not the same as: " .. info.differs
	end

	return table.concat(lines, "\n")
end

function zb.GetCommandInfo(commandKey)
	commandKey = zb.ResolveCommandName and zb.ResolveCommandName(commandKey) or commandKey
	return zb.UCL.CommandInfo and zb.UCL.CommandInfo[commandKey]
end

function zb.IterZCityHelpCommands()
	local keys = {}
	for key in pairs(zb.UCL.CommandInfo or {}) do
		if key ~= "zcityhelp" then
			keys[#keys + 1] = key
		end
	end
	table.sort(keys)
	return keys
end

function zb.PrintZCityCommandHelp(ply, commandKey)
	if not IsValid(ply) then return end

	local function say(msg)
		if ULib and ULib.tsay then
			ULib.tsay(ply, msg, true)
		else
			ply:ChatPrint(msg)
		end
	end

	if isstring(commandKey) and commandKey ~= "" then
		commandKey = string.lower(string.Trim(commandKey))
		commandKey = zb.ResolveCommandName(commandKey) or commandKey

		local info = zb.GetCommandInfo(commandKey)
		if not info then
			say("Unknown Z-City command '" .. commandKey .. "'. Try: !zcityhelp")
			return
		end

		if info.perm and not zb.HasULX(ply, info.perm) then
			say("You do not have access to '" .. commandKey .. "'.")
			return
		end

		say("—— " .. (info.title or commandKey) .. " ——")
		if info.summary then say(info.summary) end
		if info.chat then say("Chat: " .. info.chat) end
		if info.console then say("Console: " .. info.console) end
		if info.when then say("Use when: " .. info.when) end
		if info.differs then say("Not the same as: " .. info.differs) end
		if info.perm then say("Permission: " .. info.perm) end
		return
	end

	local lines = {"Z-City commands you can use:"}
	for _, key in ipairs(zb.IterZCityHelpCommands()) do
		local info = zb.UCL.CommandInfo[key]
		if info and info.perm and not zb.HasULX(ply, info.perm) then continue end

		local line = zb.GetCommandHelpLine(key)
		if line then lines[#lines + 1] = " • " .. line end
	end

	if #lines == 1 then
		say("You do not have access to any Z-City commands.")
		return
	end

	for _, line in ipairs(lines) do
		say(line)
	end

	say("Tip: !zcityhelp <command> for full details. (!help shows the same list.)")
end

function zb.GetCommandHelpLine(commandKey)
	local info = zb.GetCommandInfo(commandKey)
	if not info then return nil end

	local usage = info.chat or info.console or ""
	if usage == "" then return info.title or commandKey end

	return string.format("%s — %s | %s", info.title or commandKey, info.summary or "", usage)
end

function zb.GetPermissionInfo(perm)
	if not isstring(perm) or perm == "" then return nil end
	return zb.UCL.PermissionByString and zb.UCL.PermissionByString[perm:lower()]
end

function zb.FormatCommandAccessError(ply, commandName)
	commandName = zb.ResolveCommandName and zb.ResolveCommandName(commandName) or commandName
	local info = zb.GetCommandInfo(commandName)
	local perm = zb.UCL.CommandPermissions and zb.UCL.CommandPermissions[commandName]

	if info and perm then
		local usage = info.chat or info.console
		local msg = "You do not have access to " .. (info.title or commandName) .. "."
		msg = msg .. " Grant permission: " .. perm .. "."
		if usage then msg = msg .. " Usage: " .. usage .. "." end
		msg = msg .. " Details: !zcityhelp " .. commandName
		return msg
	end

	return "You do not have access to this command."
end

function zb.ConfigureZCityULXCommand(cmdObj, commandKey)
	if not cmdObj or not isstring(commandKey) then return end

	local info = zb.GetCommandInfo(commandKey)
	if not info then return end

	cmdObj.zcityCommandKey = commandKey
	cmdObj.zcityInfo = info
	cmdObj.zcityDisplayName = info.menuName or info.title or commandKey

	if cmdObj.help then
		cmdObj:help(zb.FormatULXHelpText(info))
	end
end

function zb.RegisterZCityPermission(info)
	if SERVER and ULib and ULib.ucl and ULib.ucl.registerAccess and istable(info) and isstring(info.perm) then
		ULib.ucl.registerAccess(
			info.perm,
			info.groups or DEFAULT_GROUPS,
			zb.BuildPermissionTooltip(info),
			info.category or CAT
		)
	end
end

local function buildCatalog()
	zb.UCL.FeatureInfo = {
		f6menu = {
			perm = zb.UCL.F6Menu,
			title = "F6 Admin Panel",
			summary = "Opens the F6 admin menu for round and server tools.",
			when = "Use when you need the in-game admin panel (mode queue, settings, etc.).",
			console = "Press F6 (requires this permission).",
		},
		roundcontrol = {
			perm = zb.UCL.RoundControl,
			title = "F6 Round Queue",
			summary = "Manage the round queue and mode list inside the F6 panel.",
			when = "Use for F6 queue controls only.",
			console = "F6 menu round queue tab.",
			differs = "!setmode, !setforcemode, !endround (separate chat commands with their own permissions)",
		},
		adminchat = {
			perm = zb.UCL.AdminChat,
			title = "Admin Spectator Mode",
			summary = "Toggle zb_adminmode (spectator admin mode for non-superadmins).",
			when = "Use when a regular admin needs to spectate and help without superadmin tools.",
			console = "zb_adminmode",
		},
		superchat = {
			perm = zb.UCL.SuperChat,
			title = "All-Player ESP Toggle",
			summary = "Use zb_allesp to see ESP on every player.",
			when = "Use for server oversight during events or investigations.",
			console = "zb_allesp 1 / zb_allesp 0",
			differs = "zb_admesp / zcity live esp (round overlays with Homicide role labels)",
		},
		allmodes = {
			perm = zb.UCL.AllModes,
			title = "All Gamemodes (F6)",
			summary = "See and pick every gamemode in the F6 mode list.",
			when = "Grant to staff who should pick any mode, not just the public rotation.",
		},
		spawnmenu = {
			perm = zb.UCL.SpawnMenu,
			title = "Spawn Menu",
			summary = "Open the Q spawn menu.",
			when = "Use on sandbox-style maps or when builders need spawn menu access.",
		},
		spawn = {
			perm = zb.UCL.Spawn,
			title = "Spawn Entities",
			summary = "Spawn props, entities, NPCs, and vehicles from the spawn menu.",
			when = "Grant with spawn menu for full sandbox spawning.",
		},
		noclip = {
			perm = zb.UCL.Noclip,
			title = "Noclip",
			summary = "Fly through the map with noclip.",
			when = "Use for investigating stuck players, mapping, or moderation.",
		},
		toolgun = {
			perm = zb.UCL.Toolgun,
			title = "Toolgun",
			summary = "Use the toolgun and toggletools sandbox utilities.",
			when = "Grant to builders or staff fixing maps and props.",
		},
		physgun = {
			perm = zb.UCL.Physgun,
			title = "Physgun",
			summary = "Use the physgun, including admin physgun features.",
			when = "Use when staff need to move props or players with the physgun.",
		},
		sandboxbypass = {
			perm = zb.UCL.SandboxBypass,
			title = "Sandbox Bypass",
			summary = "Bypass restricted sandbox limits (full sandbox admin).",
			when = "Grant only to trusted staff who need unrestricted sandbox tools.",
		},
		admintools = {
			perm = zb.UCL.AdminTools,
			title = "Admin C-Menu Tools",
			summary = "Use Homigrad admin tools from the player context (C) menu.",
			when = "Use for day-to-day player moderation from the context menu.",
		},
		mapper = {
			perm = zb.UCL.Mapper,
			groups = {},
			title = "Mapper Utilities",
			summary = "Mapper utilities such as spawn menu and noclip on non-sandbox maps.",
			when = "Grant to the mapper group only.",
		},
		liveesp = {
			perm = zb.UCL.LiveESP,
			title = "Live Admin ESP",
			summary = "Toggle zb_admesp player overlays (press O or use the console command).",
			when = "Use during rounds to see player names, roles (Homicide), weapons, and distance.",
			console = "zb_admesp (toggle) | bind O",
			differs = "zb_allesp / zcity super chat (all-player ESP, no Homicide role labels)",
		},
		doortools = {
			perm = zb.UCL.DoorTools,
			title = "Door Tools",
			summary = "Lock, unlock, and toggle doors from the C-menu.",
			when = "Use when moderating map access or event areas.",
		},
		admintimer = {
			perm = zb.UCL.AdminTimer,
			title = "Admin Timer",
			summary = "Broadcast an on-screen admin timer.",
			when = "Use for events, round countdowns, or announcements.",
		},
		voicepanels = {
			perm = zb.UCL.VoicePanels,
			title = "Voice Panels",
			summary = "See live voice activity panels for alive players.",
			when = "Use when monitoring who is speaking during rounds.",
		},
		spray = {
			perm = zb.UCL.Spray,
			groups = {},
			title = "Spray Decals",
			summary = "Allow spray decals (blocked for everyone else).",
			when = "Grant to players or staff allowed to use sprays.",
		},
		eventloot = {
			perm = zb.UCL.EventLoot,
			title = "Event Loot Editor",
			summary = "Open the event loot editor.",
			when = "Use when setting up event loot tables.",
		},
	}

	zb.UCL.CommandInfo = {
		respawn = {
			perm = zb.UCL.Respawn,
			ulx = "ulx zcrespawn",
			title = "Respawn Player",
			menuName = "Respawn",
			summary = "Soft-respawns a player at a spawn with default appearance; does not end the round.",
			when = "Player is stuck, glitched, or needs a clean respawn mid-round.",
			chat = "!respawn [player]",
			console = "ulx zcrespawn [player]",
			differs = "!sendtospawn (kills then respawns), ulx bring/goto (teleport only)",
		},
		give = {
			perm = zb.UCL.Give,
			ulx = "ulx zcgive",
			title = "Give Item",
			menuName = "Give",
			summary = "Gives a weapon or entity class to a player.",
			when = "Testing, events, or replacing lost gear for a player.",
			chat = "!give [player] <class>",
			console = "ulx zcgive [player] <class>",
			differs = "spawn menu / Q menu (sandbox spawning, not a chat command)",
		},
		sendtospawn = {
			perm = zb.UCL.SendToSpawn,
			ulx = "ulx zcsendtospawn",
			title = "Send To Spawn",
			menuName = "Send To Spawn",
			summary = "Kills and respawns a player at a random spawn point.",
			when = "Player is in the wrong place and needs a hard reset to a spawn.",
			chat = "!sendtospawn [player]",
			console = "ulx zcsendtospawn [player]",
			differs = "!respawn (soft respawn without an intentional kill), ulx send (teleport to another player)",
		},
		setmodel = {
			perm = zb.UCL.SetModel,
			ulx = "ulx zcsetmodel",
			title = "Set Model",
			menuName = "Set Model",
			summary = "Sets a player's playermodel for the current life.",
			when = "Events, cosmetics, or fixing a broken model on a player.",
			chat = "!setmodel [player] <model>",
			console = "ulx zcsetmodel [player] <model>",
			aliases = "!model, !playermodel, !setplayermodel",
			differs = "!permamodel (same model every future spawn), appearance menu (player cosmetics)",
		},
		setscale = {
			perm = zb.UCL.SetScale,
			ulx = "ulx zcsetscale",
			title = "Set Scale",
			menuName = "Set Scale",
			summary = "Sets a player's model scale for the current life.",
			when = "Events or fixing an incorrect player size.",
			chat = "!setscale [player] <scale>",
			console = "ulx zcsetscale [player] <scale>",
			aliases = "!scale, !size, !setsize, !setmodelscale, !modelscale",
		},
		zc_cloak = {
			perm = zb.UCL.Cloak,
			ulx = "ulx zccloak",
			title = "Z-City Cloak",
			menuName = "Z-City Cloak",
			summary = "Toggles Z-City invisibility (no shadow, no collision with players).",
			when = "Moderating discreetly or filming without being seen.",
			chat = "!zc_cloak",
			console = "ulx zccloak",
			aliases = "!zccloak",
			differs = "ulx cloak / !cloak (stock ULX — different permission and behavior)",
		},
		punish = {
			perm = zb.UCL.Punish,
			ulx = "ulx zcpunish",
			title = "Punish",
			menuName = "Punish",
			summary = "Strikes a matching player with lightning damage.",
			when = "Light punishment for rule-breaking; not a ban replacement.",
			chat = "!punish <name>",
			console = "ulx zcpunish <name>",
		},
		notify = {
			perm = zb.UCL.Notify,
			ulx = "ulx zcnotify",
			title = "Notify Player",
			menuName = "Notify",
			summary = "Sends a HUD notification to a player.",
			when = "Private staff message or warning visible only on the target's HUD.",
			chat = "!notify <player> <message>",
			console = "ulx zcnotify <player> <message>",
		},
		pluv = {
			ulx = "ulx zcpluv",
			title = "Pluv Effect",
			menuName = "Pluv",
			summary = "Triggers the Pluv client effect on yourself.",
			when = "Cosmetic / fun command. Public for everyone.",
			chat = "!pluv",
			console = "ulx zcpluv",
			skipRegister = true,
		},
		setmode = {
			perm = zb.UCL.SetMode,
			ulx = "ulx zcsetmode",
			title = "Set Next Mode",
			menuName = "Set Mode",
			summary = "Sets the next round gamemode (one round ahead).",
			when = "Before a round ends, pick what mode should play next.",
			chat = "!setmode <mode>",
			console = "ulx zcsetmode <mode>",
			differs = "!setforcemode (locks mode), !votemode (player vote), F6 queue (zcity round control permission)",
		},
		setforcemode = {
			perm = zb.UCL.SetForceMode,
			ulx = "ulx zcsetforcemode",
			title = "Force Mode",
			menuName = "Force Mode",
			summary = "Locks the server gamemode until changed again.",
			when = "Events or testing when one mode must stay locked in.",
			chat = "!setforcemode <mode>",
			console = "ulx zcsetforcemode <mode>",
			differs = "!setmode (next round only), !votemode (player vote)",
		},
		votemode = {
			ulx = "ulx votemode",
			title = "Vote Gamemode",
			menuName = "Vote Mode",
			summary = "Starts a server-wide vote to change the gamemode.",
			when = "When players should democratically pick the next mode.",
			chat = "!votemode <mode> [mode2...]",
			console = "ulx votemode <mode> [mode2...]",
			differs = "!setmode / !setforcemode (instant admin control, not a vote)",
			skipRegister = true,
		},
		endround = {
			perm = zb.UCL.EndRound,
			ulx = "ulx zcendround",
			title = "End Round",
			menuName = "End Round",
			summary = "Ends the current round immediately.",
			when = "Round is broken, stalled, or needs an admin stop.",
			chat = "!endround",
			console = "ulx zcendround",
		},
		zc_god = {
			perm = zb.UCL.Godmode,
			ulx = "ulx zcgod",
			title = "Z-City Godmode",
			menuName = "Z-City Godmode",
			summary = "Toggles Z-City godmode (organism invulnerability + god model).",
			when = "Filming, testing, or protecting someone from damage.",
			chat = "!zc_god [player]",
			console = "ulx zcgod [player]",
			aliases = "!zcgod",
			differs = "ulx god / !god (stock ULX — different permission and behavior)",
		},
		power = {
			perm = zb.UCL.Power,
			ulx = "ulx power",
			title = "Super Power",
			menuName = "Super Power",
			summary = "Toggles super power (enhanced melee / reduced recoil) for a player.",
			when = "Events or admin testing only — not for regular gameplay advantage.",
			chat = "!power [player]",
			console = "ulx power [player]",
			differs = "zb_allesp / zcity super chat (ESP overlay, not a combat buff)",
		},
		permamodel = {
			perm = zb.UCL.Permamodel,
			ulx = "ulx permamodel",
			title = "Permamodel",
			menuName = "Permamodel",
			summary = "Toggle spawning with a fixed playermodel every life.",
			when = "Player wants the same model every spawn; staff helping set it up.",
			chat = "!permamodel",
			console = "ulx permamodel",
			differs = "!setmodel (this life only), appearance menu (full cosmetic loadout)",
		},
		hmcdtraitor = {
			perm = zb.UCL.HmcdTraitor,
			ulx = "ulx hmcdtraitor",
			title = "Homicide Main Traitor",
			menuName = "HMCD Traitor",
			summary = "Makes a player the main traitor during an active Homicide round.",
			when = "Round setup, replacing a disconnected traitor, or event scripting.",
			chat = "!hmcdtraitor [player]",
			console = "ulx hmcdtraitor [player]",
		},
		innoclass = {
			perm = zb.UCL.Innoclass,
			ulx = "ulx innoclass",
			title = "Homicide Innocent Class",
			menuName = "Innocent Class",
			summary = "Sets a player's preferred Homicide innocent class.",
			when = "Before or between rounds when helping a player pick their class.",
			chat = "!innoclass [player] <class>",
			console = "ulx innoclass [player] <class>",
		},
		zcityhelp = {
			ulx = "ulx zcityhelp",
			title = "Z-City Command Help",
			menuName = "Command Help",
			summary = "Lists Z-City commands you can use, or shows detailed help for one command.",
			when = "Whenever you need usage, permissions, or examples without leaving the game.",
			chat = "!zcityhelp [command]",
			console = "ulx zcityhelp [command]",
			differs = "ulx help (stock ULX commands). !help shows the same Z-City list.",
			skipRegister = true,
		},
	}
end

local function buildPermissionLookup()
	zb.UCL.PermissionByString = {}

	local function add(info)
		if not istable(info) or not isstring(info.perm) or info.perm == "" then return end
		zb.UCL.PermissionByString[info.perm:lower()] = info
	end

	for _, info in pairs(zb.UCL.FeatureInfo or {}) do add(info) end
	for _, info in pairs(zb.UCL.CommandInfo or {}) do add(info) end
end

buildCatalog()
buildPermissionLookup()

local function validateZCityCommandCatalog()
	local ulxSeen = {}
	for key, info in pairs(zb.UCL.CommandInfo or {}) do
		if isstring(info.ulx) then
			local lower = info.ulx:lower()
			if ulxSeen[lower] then
				ErrorNoHalt("[Z-City] Duplicate ULX command in catalog: " .. info.ulx .. " (" .. key .. " and " .. ulxSeen[lower] .. ")\n")
			else
				ulxSeen[lower] = key
			end
		end
	end
end

validateZCityCommandCatalog()

function zb.ApplyZCityCommandCatalog()
	if not ULib or not ULib.cmds or not ULib.cmds.translatedCmds then return end

	for commandKey, info in pairs(zb.UCL.CommandInfo or {}) do
		if isstring(info.ulx) and ULib.cmds.translatedCmds[info.ulx] then
			zb.ConfigureZCityULXCommand(ULib.cmds.translatedCmds[info.ulx], commandKey)
		end
	end
end

function zb.RegisterZCityPermissionCatalog()
	if not SERVER then return end

	for _, info in pairs(zb.UCL.FeatureInfo or {}) do
		zb.RegisterZCityPermission(info)
	end

	for _, info in pairs(zb.UCL.CommandInfo or {}) do
		if info.perm and not info.skipRegister then
			zb.RegisterZCityPermission(info)
		end
	end
end

if SERVER and ulx then
	function ulx.zcityhelp(callingPly, commandKey)
		if CLIENT then return end
		zb.PrintZCityCommandHelp(callingPly, commandKey)
	end

	local zcityhelp = ulx.command("Z-City", "ulx zcityhelp", ulx.zcityhelp, "!zcityhelp")
	zcityhelp:addParam{type = ULib.cmds.StringArg, hint = "command name (optional)", ULib.cmds.optional}
	zcityhelp:help("Lists Z-City commands you can use, or shows detailed help for one command.")

	timer.Simple(0, function()
		zb.ApplyZCityCommandCatalog()
		if ULib.cmds.translatedCmds["ulx zcityhelp"] then
			zb.ConfigureZCityULXCommand(ULib.cmds.translatedCmds["ulx zcityhelp"], "zcityhelp")
		end
	end)
end

if CLIENT then
	local function patchXGuiGroupsPanel()
		if not xgui or not xgui.initialized or not groups or not groups.updateAccessPanel then return false end
		if groups._zcityPermPatched then return true end

		local oldUpdateAccessPanel = groups.updateAccessPanel
		function groups.updateAccessPanel()
			oldUpdateAccessPanel()

			for access, line in pairs(groups.access_lines or {}) do
				local info = zb.GetPermissionInfo and zb.GetPermissionInfo(access)
				if info then
					local label = info.menuName or info.title or access
					line:SetColumnText(1, label .. "  (" .. access .. ")")

					local tooltip = zb.BuildPermissionTooltip(info)
					if tooltip ~= "" then
						line:SetTooltip(xlib and xlib.wordWrap and xlib.wordWrap(tooltip, 280, "Default") or tooltip)
					end
				end
			end
		end

		groups._zcityPermPatched = true
		return true
	end

	local function patchXGuiCommandTooltips()
		if not xgui or not xgui.initialized or not cmds or not cmds.refresh then return false end
		if cmds._zcityTooltipPatched then return true end

		local oldRefresh = cmds.refresh
		function cmds.refresh(permissionChanged)
			oldRefresh(permissionChanged)

			for _, list in pairs(cmds.cmd_contents or {}) do
				for _, line in ipairs(list.Lines or {}) do
					local cmdName = line:GetColumnText(2)
					local cmdObj = ULib.cmds.translatedCmds[cmdName]
					if cmdObj and cmdObj.zcityInfo then
						if cmdObj.zcityDisplayName then
							line:SetColumnText(1, cmdObj.zcityDisplayName)
						end

						local tooltip = zb.BuildPermissionTooltip(cmdObj.zcityInfo)
						if tooltip ~= "" then
							line:SetTooltip(xlib and xlib.wordWrap and xlib.wordWrap(tooltip, 280, "Default") or tooltip)
						end
					end
				end

				if list.SortByColumn then
					list:SortByColumn(1)
				end
			end
		end

		local oldBuildArgsList = cmds.buildArgsList
		function cmds.buildArgsList(cmd)
			oldBuildArgsList(cmd)

			if not cmd or not cmd.zcityInfo then return end

			local info = cmd.zcityInfo
			local zpos = #cmds.argslist:GetChildren()

			local function addLabel(text)
				if not isstring(text) or text == "" then return end
				local panel = xlib.makelabel{ w = 160, label = text, wordwrap = true, parent = cmds.argslist }
				panel.xguiIgnore = true
				cmds.argslist:Add(panel)
				panel:SetZPos(zpos)
				zpos = zpos + 1
			end

			addLabel("—— " .. (info.title or cmd.cmd) .. " ——")
			if info.summary then addLabel(info.summary) end
			if info.chat then addLabel("Chat: " .. info.chat) end
			if info.console then addLabel("Console: " .. info.console) end
			if info.when then addLabel("Use when: " .. info.when) end
			if info.differs then addLabel("Not the same as: " .. info.differs) end
			if info.aliases then addLabel("Also works as: " .. info.aliases) end
		end

		cmds._zcityTooltipPatched = true
		return true
	end

	hook.Add("InitPostEntity", "ZCity_ULXUI", function()
		timer.Create("ZCity_ULXUI_Patch", 1, 0, function()
			local cmdsOk = patchXGuiCommandTooltips()
			local groupsOk = patchXGuiGroupsPanel()
			if cmdsOk and groupsOk then
				timer.Remove("ZCity_ULXUI_Patch")
			end
		end)
	end)
end

hook.Add("ULXLoaded", "ZCity_ApplyCommandCatalog", function()
	timer.Simple(0, function()
		if zb.ApplyZCityCommandCatalog then
			zb.ApplyZCityCommandCatalog()
		end
	end)
end)
