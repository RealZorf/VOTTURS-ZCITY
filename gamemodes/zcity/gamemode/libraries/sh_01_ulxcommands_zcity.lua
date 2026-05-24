if not ulx then return end

local ZCITY_CATEGORY = "Z-City"

function zb.RunHomigradChatCommand(commandName, callingPly, targetPly)
	if CLIENT then return false end

	if not COMMANDS or not COMMANDS[commandName] or not COMMANDS[commandName][1] then
		if IsValid(callingPly) then
			ULib.tsayError(callingPly, "The command '" .. tostring(commandName) .. "' is not available.", true)
		end
		return false
	end

	if not zb.PlayerHasCommandAccess(callingPly, commandName) then
		if IsValid(callingPly) then
			ULib.tsayError(callingPly, zb.FormatCommandAccessError and zb.FormatCommandAccessError(callingPly, commandName) or "You do not have access to this command.", true)
		end
		return false
	end

	local arguments = {}
	if IsValid(targetPly) and targetPly ~= callingPly then
		arguments[1] = targetPly:Name()
	end

	COMMANDS[commandName][1](callingPly, arguments)
	return true
end

local function runChatCommand(cmdName, callingPly, targetPly, extraArgs)
	if not zb.RunHomigradChatCommand(cmdName, callingPly, targetPly) then return end

	if istable(extraArgs) and #extraArgs > 0 and IsValid(callingPly) then
		COMMANDS[cmdName][1](callingPly, extraArgs)
	end
end

-- Respawn
function ulx.zcrespawn(callingPly, targetPly)
	if CLIENT then return end
	targetPly = IsValid(targetPly) and targetPly or callingPly
	if not zb.RunHomigradChatCommand("respawn", callingPly, targetPly) then return end
	ulx.fancyLogAdmin(callingPly, "#A respawned #T", targetPly)
end

local zcrespawn = ulx.command(ZCITY_CATEGORY, "ulx zcrespawn", ulx.zcrespawn, "!respawn")
zcrespawn:addParam{type = ULib.cmds.PlayerArg, default = "^", ULib.cmds.optional}
zcrespawn:help("Respawns a player at a spawn point with default appearance.")

-- Give
function ulx.zcgive(callingPly, targetPly, className)
	if CLIENT then return end
	targetPly = IsValid(targetPly) and targetPly or callingPly
	local args = {targetPly:Name(), className}
	if not zb.PlayerHasCommandAccess(callingPly, "give") then
		ULib.tsayError(callingPly, "You do not have access to this command.", true)
		return
	end
	COMMANDS.give[1](callingPly, args)
	ulx.fancyLogAdmin(callingPly, "#A gave #s to #T", className, targetPly)
end

local zcgive = ulx.command(ZCITY_CATEGORY, "ulx zcgive", ulx.zcgive, "!give")
zcgive:addParam{type = ULib.cmds.PlayerArg, default = "^", ULib.cmds.optional}
zcgive:addParam{type = ULib.cmds.StringArg, hint = "entity or weapon class"}
zcgive:help("Gives a weapon or entity class to a player.")

-- Send to spawn
function ulx.zcsendtospawn(callingPly, targetPly)
	if CLIENT then return end
	targetPly = IsValid(targetPly) and targetPly or callingPly
	if not zb.RunHomigradChatCommand("sendtospawn", callingPly, targetPly) then return end
	ulx.fancyLogAdmin(callingPly, "#A sent #T to a random spawn", targetPly)
end

local zcsendtospawn = ulx.command(ZCITY_CATEGORY, "ulx zcsendtospawn", ulx.zcsendtospawn, "!sendtospawn")
zcsendtospawn:addParam{type = ULib.cmds.PlayerArg, default = "^", ULib.cmds.optional}
zcsendtospawn:help("Kills and respawns a player at a random spawn point.")

-- Set model
function ulx.zcsetmodel(callingPly, targetPly, modelPath)
	if CLIENT then return end
	targetPly = IsValid(targetPly) and targetPly or callingPly
	if not zb.PlayerHasCommandAccess(callingPly, "setmodel") then
		ULib.tsayError(callingPly, "You do not have access to this command.", true)
		return
	end
	COMMANDS.setmodel[1](callingPly, {targetPly:Name(), modelPath})
	ulx.fancyLogAdmin(callingPly, "#A set #T's model to #s", targetPly, modelPath)
end

local zcsetmodel = ulx.command(ZCITY_CATEGORY, "ulx zcsetmodel", ulx.zcsetmodel, {"!setmodel", "!model", "!playermodel", "!setplayermodel"})
zcsetmodel:addParam{type = ULib.cmds.PlayerArg, default = "^", ULib.cmds.optional}
zcsetmodel:addParam{type = ULib.cmds.StringArg, hint = "model path"}
zcsetmodel:help("Sets a player's playermodel path.")

-- Set scale
function ulx.zcsetscale(callingPly, targetPly, scale)
	if CLIENT then return end
	targetPly = IsValid(targetPly) and targetPly or callingPly
	if not zb.PlayerHasCommandAccess(callingPly, "setscale") then
		ULib.tsayError(callingPly, "You do not have access to this command.", true)
		return
	end
	COMMANDS.setscale[1](callingPly, {targetPly:Name(), tostring(scale)})
	ulx.fancyLogAdmin(callingPly, "#A set #T's scale to #s", targetPly, tostring(scale))
end

local zcsetscale = ulx.command(ZCITY_CATEGORY, "ulx zcsetscale", ulx.zcsetscale, {"!setscale", "!scale", "!size", "!setsize", "!setmodelscale", "!modelscale"})
zcsetscale:addParam{type = ULib.cmds.PlayerArg, default = "^", ULib.cmds.optional}
zcsetscale:addParam{type = ULib.cmds.NumArg, min = 0.01, max = 10, hint = "scale"}
zcsetscale:help("Sets a player's model scale.")

-- Cloak
function ulx.zccloak(callingPly)
	if CLIENT then return end
	if not zb.RunHomigradChatCommand("zc_cloak", callingPly, callingPly) then return end
	ulx.fancyLogAdmin(callingPly, "#A toggled cloak")
end

local zccloak = ulx.command(ZCITY_CATEGORY, "ulx zccloak", ulx.zccloak, {"!zc_cloak", "!zccloak"})
zccloak:help("Toggles invisibility (no shadow, no collision with players).")

-- Punish
function ulx.zcpunish(callingPly, targetName)
	if CLIENT then return end
	if not zb.PlayerHasCommandAccess(callingPly, "punish") then
		ULib.tsayError(callingPly, "You do not have access to this command.", true)
		return
	end
	COMMANDS.punish[1](callingPly, {targetName})
	ulx.fancyLogAdmin(callingPly, "#A punished #s", targetName)
end

local zcpunish = ulx.command(ZCITY_CATEGORY, "ulx zcpunish", ulx.zcpunish, "!punish")
zcpunish:addParam{type = ULib.cmds.StringArg, hint = "player name (partial match)"}
zcpunish:help("Strikes a matching player with lightning damage.")

-- Notify
function ulx.zcnotify(callingPly, targetPly, message)
	if CLIENT then return end
	if not zb.PlayerHasCommandAccess(callingPly, "notify") then
		ULib.tsayError(callingPly, "You do not have access to this command.", true)
		return
	end
	COMMANDS.notify[1](callingPly, {targetPly:Name(), message})
	ulx.fancyLogAdmin(callingPly, "#A notified #T", targetPly)
end

local zcnotify = ulx.command(ZCITY_CATEGORY, "ulx zcnotify", ulx.zcnotify, "!notify")
zcnotify:addParam{type = ULib.cmds.PlayerArg}
zcnotify:addParam{type = ULib.cmds.StringArg, hint = "message", ULib.cmds.takeRestOfLine}
zcnotify:help("Sends a HUD notification to a player.")

-- Pluv (client effect; public)
function ulx.zcpluv(callingPly)
	if CLIENT then return end
	if not zb.RunHomigradChatCommand("pluv", callingPly, callingPly) then return end
end

local zcpluv = ulx.command(ZCITY_CATEGORY, "ulx zcpluv", ulx.zcpluv, "!pluv")
zcpluv:help("Triggers the Pluv client effect on yourself.")

-- Round control
function ulx.zcsetmode(callingPly, modeName)
	if CLIENT then return end
	if not zb.PlayerHasCommandAccess(callingPly, "setmode") then
		ULib.tsayError(callingPly, "You do not have access to this command.", true)
		return
	end
	COMMANDS.setmode[1](callingPly, {modeName})
	ulx.fancyLogAdmin(callingPly, "#A set the next mode to #s", modeName)
end

local zcsetmode = ulx.command(ZCITY_CATEGORY, "ulx zcsetmode", ulx.zcsetmode, "!setmode")
zcsetmode:addParam{type = ULib.cmds.StringArg, hint = "mode name or random"}
zcsetmode:help("Sets the next round gamemode.")

function ulx.zcsetforcemode(callingPly, modeName)
	if CLIENT then return end
	if not zb.PlayerHasCommandAccess(callingPly, "setforcemode") then
		ULib.tsayError(callingPly, "You do not have access to this command.", true)
		return
	end
	COMMANDS.setforcemode[1](callingPly, {modeName})
	ulx.fancyLogAdmin(callingPly, "#A set forced mode to #s", modeName)
end

local zcsetforcemode = ulx.command(ZCITY_CATEGORY, "ulx zcsetforcemode", ulx.zcsetforcemode, "!setforcemode")
zcsetforcemode:addParam{type = ULib.cmds.StringArg, hint = "mode name or random"}
zcsetforcemode:help("Forces the server mode convar until changed.")

function ulx.zcendround(callingPly)
	if CLIENT then return end
	if not zb.PlayerHasCommandAccess(callingPly, "endround") then
		ULib.tsayError(callingPly, "You do not have access to this command.", true)
		return
	end
	COMMANDS.endround[1](callingPly, {})
	ulx.fancyLogAdmin(callingPly, "#A ended the round")
end

local zcendround = ulx.command(ZCITY_CATEGORY, "ulx zcendround", ulx.zcendround, "!endround")
zcendround:help("Ends the current round immediately.")
