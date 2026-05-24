zb = zb or {}

zb.UCL = zb.UCL or {
	F6Menu = "zcity f6 menu",
	RoundControl = "zcity round control",
	Godmode = "zcity godmode",
	AdminChat = "zcity admin chat",
	SuperChat = "zcity super chat",
	AllModes = "zcity all modes",
	SpawnMenu = "zcity spawnmenu",
	Spawn = "zcity spawn",
	Noclip = "zcity noclip",
	Toolgun = "zcity toolgun",
	Physgun = "zcity physgun",
	SandboxBypass = "zcity sandbox bypass",
	AdminTools = "zcity admin tools",
	Mapper = "zcity mapper",
	Cloak = "zcity cloak",
	Punish = "zcity punish",
	Notify = "zcity notify",
	Power = "zcity power",
	SetMode = "zcity setmode",
	SetForceMode = "zcity setforcemode",
	EndRound = "zcity endround",
	Respawn = "zcity respawn",
	Give = "zcity give",
	SendToSpawn = "zcity send to spawn",
	SetModel = "zcity setmodel",
	SetScale = "zcity setscale",
	LiveESP = "zcity live esp",
	DoorTools = "zcity door tools",
	AdminTimer = "zcity admin timer",
	VoicePanels = "zcity voice panels",
	Spray = "zcity spray",
	EventLoot = "zcity event loot",
	Permamodel = "zcity permamodel",
	HmcdTraitor = "zcity hmcd traitor",
	Innoclass = "zcity innoclass",
}

zb.UCL.ULXCommandToZCityPerm = {
	["ulx zcrespawn"] = zb.UCL.Respawn,
	["ulx zcgive"] = zb.UCL.Give,
	["ulx zcsendtospawn"] = zb.UCL.SendToSpawn,
	["ulx zcsetmodel"] = zb.UCL.SetModel,
	["ulx zcsetscale"] = zb.UCL.SetScale,
	["ulx zccloak"] = zb.UCL.Cloak,
	["ulx zcpunish"] = zb.UCL.Punish,
	["ulx zcnotify"] = zb.UCL.Notify,
	["ulx zcsetmode"] = zb.UCL.SetMode,
	["ulx zcsetforcemode"] = zb.UCL.SetForceMode,
	["ulx zcendround"] = zb.UCL.EndRound,
	["ulx zcgod"] = zb.UCL.Godmode,
	["ulx power"] = zb.UCL.Power,
	["ulx permamodel"] = zb.UCL.Permamodel,
	["ulx hmcdtraitor"] = zb.UCL.HmcdTraitor,
	["ulx innoclass"] = zb.UCL.Innoclass,
}

zb.UCL.PublicULXCommands = {
	["ulx zcpluv"] = true,
	["ulx zcityhelp"] = true,
}

zb.UCL.CommandNameAliases = {
	zccloak = "zc_cloak",
	zcgod = "zc_god",
	model = "setmodel",
	playermodel = "setmodel",
	setplayermodel = "setmodel",
	scale = "setscale",
	setsize = "setscale",
	size = "setscale",
	setmodelscale = "setscale",
	modelscale = "setscale",
}

zb.UCL.CommandPermissions = {
	help = nil,
	pluv = nil,
	zc_god = zb.UCL.Godmode,
	power = zb.UCL.Power,
	permamodel = zb.UCL.Permamodel,
	hmcdtraitor = zb.UCL.HmcdTraitor,
	innoclass = zb.UCL.Innoclass,
	zc_cloak = zb.UCL.Cloak,
	punish = zb.UCL.Punish,
	notify = zb.UCL.Notify,
	setmodel = zb.UCL.SetModel,
	setscale = zb.UCL.SetScale,
	respawn = zb.UCL.Respawn,
	give = zb.UCL.Give,
	sendtospawn = zb.UCL.SendToSpawn,
	setmode = zb.UCL.SetMode,
	setforcemode = zb.UCL.SetForceMode,
	endround = zb.UCL.EndRound,
}

local ZCITY_DEFAULT_GRANT_GROUPS = {"superadmin"}

local function removeErroneousPermissionGroups()
	if not ULib or not ULib.ucl or not ULib.ucl.removeGroup then return end

	local permissionNames = {}
	for _, perm in pairs(zb.UCL) do
		if isstring(perm) then
			permissionNames[string.lower(perm)] = true
		end
	end

	for groupName in pairs(ULib.ucl.groups) do
		if permissionNames[string.lower(groupName)] then
			ULib.ucl.removeGroup(groupName)
			MsgC(Color(255, 180, 80), "[Z-City] Removed mistaken ULX group \"", groupName, "\" (it is a permission, not a rank).\n")
		end
	end
end

local function registerZCityULXPermissions()
	if not ULib or not ULib.ucl or not ULib.ucl.registerAccess then return end

	timer.Simple(0, function()
		removeErroneousPermissionGroups()

		if zb.RegisterZCityPermissionCatalog then
			zb.RegisterZCityPermissionCatalog()
		end
	end)
end

function zb.MigrateBundledPermissionGrants()
	if not ULib or not ULib.ucl or not ULib.ucl.groups or not ULib.ucl.groupAllow then return end

	local bundledMap = {
		[zb.UCL.RoundControl] = {zb.UCL.SetMode, zb.UCL.SetForceMode, zb.UCL.EndRound},
		[zb.UCL.SuperChat] = {zb.UCL.Power},
		[zb.UCL.AdminChat] = {},
	}

	for groupName, groupInfo in pairs(ULib.ucl.groups) do
		for bundledPerm, splitPerms in pairs(bundledMap) do
			local lowerBundled = bundledPerm:lower()
			local hasGrant = table.HasValue(groupInfo.allow, lowerBundled)
				or table.HasValue(groupInfo.allow, bundledPerm)
				or groupInfo.allow[lowerBundled] ~= nil
				or groupInfo.allow[bundledPerm] ~= nil

			if not hasGrant then continue end

			for _, splitPerm in ipairs(splitPerms) do
				ULib.ucl.groupAllow(groupName, splitPerm)
			end
		end
	end
end

function zb.CleanupDuplicateULXAccessStrings()
	if not ULib or not ULib.ucl or not ULib.ucl.accessStrings then return end

	for ulxCmd in pairs(zb.UCL.ULXCommandToZCityPerm or {}) do
		ULib.ucl.accessStrings[ulxCmd] = nil
		ULib.ucl.accessStrings[ulxCmd:lower()] = nil
	end

	for ulxCmd in pairs(zb.UCL.PublicULXCommands or {}) do
		ULib.ucl.accessStrings[ulxCmd] = nil
		ULib.ucl.accessStrings[ulxCmd:lower()] = nil
	end
end

function zb.MigrateULXCommandGrantsToZCity()
	if not ULib or not ULib.ucl or not ULib.ucl.groups or not ULib.ucl.groupAllow then return end

	local map = zb.UCL.ULXCommandToZCityPerm
	if not map then return end

	for groupName, groupInfo in pairs(ULib.ucl.groups) do
		for ulxCmd, zcityPerm in pairs(map) do
			local lowerCmd = ulxCmd:lower()
			local hasGrant = table.HasValue(groupInfo.allow, lowerCmd)
				or table.HasValue(groupInfo.allow, ulxCmd)
				or groupInfo.allow[lowerCmd] ~= nil
				or groupInfo.allow[ulxCmd] ~= nil

			if hasGrant then
				ULib.ucl.groupAllow(groupName, zcityPerm)

				for i = #groupInfo.allow, 1, -1 do
					local allowed = groupInfo.allow[i]
					if isstring(allowed) and allowed:lower() == lowerCmd then
						table.remove(groupInfo.allow, i)
					end
				end

				groupInfo.allow[lowerCmd] = nil
				groupInfo.allow[ulxCmd] = nil
			end
		end
	end
end

function zb.WrapUCLQueryForZCityCommands()
	if not ULib or not ULib.ucl or not ULib.ucl.query or ULib.ucl._zcityQueryWrapped then return end

	local oldQuery = ULib.ucl.query

	function ULib.ucl.query(ply, access, hide)
		if isstring(access) then
			local lowerAccess = access:lower()

			if zb.UCL.PublicULXCommands and zb.UCL.PublicULXCommands[lowerAccess] then
				return oldQuery(ply, nil, hide)
			end

			local zcityPerm = zb.UCL.ULXCommandToZCityPerm and zb.UCL.ULXCommandToZCityPerm[lowerAccess]
			if zcityPerm then
				access = zcityPerm
			end
		end

		return oldQuery(ply, access, hide)
	end

	ULib.ucl._zcityQueryWrapped = true
end

function zb.FinalizeZCityPermissions()
	zb.WrapUCLQueryForZCityCommands()
	zb.CleanupDuplicateULXAccessStrings()
	zb.MigrateULXCommandGrantsToZCity()
	if zb.MigrateBundledPermissionGrants then
		zb.MigrateBundledPermissionGrants()
	end
	if zb.RegisterZCityPermissionCatalog then
		zb.RegisterZCityPermissionCatalog()
	end
	if zb.ApplyZCityCommandCatalog then
		zb.ApplyZCityCommandCatalog()
	end
end

function zb.ResolveCommandName(commandName)
	if not isstring(commandName) then return commandName end
	local aliases = zb.UCL.CommandNameAliases
	if aliases and aliases[commandName] then
		return aliases[commandName]
	end
	return commandName
end

if SERVER then
	hook.Add("Initialize", "ZCity_RegisterULXPermissions", registerZCityULXPermissions)

	timer.Simple(0, zb.FinalizeZCityPermissions)

	if ulx and ulx.HOOK_ULXDONELOADING then
		hook.Add(ulx.HOOK_ULXDONELOADING, "ZCity_FinalizePermissions", zb.FinalizeZCityPermissions)
	end
end

function zb.HasULX(ply, access)
	return ULib and ULib.ucl and IsValid(ply) and isstring(access) and access ~= "" and ULib.ucl.query(ply, access) == true
end

function zb.PlayerHasCommandAccess(ply, commandName)
	if not IsValid(ply) then return false end
	if ply == Entity(0) then return true end

	commandName = zb.ResolveCommandName(commandName)

	local perm = zb.UCL.CommandPermissions and zb.UCL.CommandPermissions[commandName]
	if perm == nil then return true end

	return zb.HasULX(ply, perm)
end

local function isMapper(ply)
	return zb.HasULX(ply, zb.UCL.Mapper)
end

function zb.PlayerCanSpawnMenu(ply)
	if not IsValid(ply) then return false end
	if game.SinglePlayer() then return true end
	if isMapper(ply) then return true end

	return zb.HasULX(ply, zb.UCL.SpawnMenu)
end

function zb.PlayerCanSpawn(ply)
	if not IsValid(ply) then return false end
	if game.SinglePlayer() then return true end
	if isMapper(ply) then return true end

	return zb.HasULX(ply, zb.UCL.Spawn)
end

function zb.PlayerCanNoclip(ply)
	if not IsValid(ply) then return false end
	if isMapper(ply) then return true end

	return zb.HasULX(ply, zb.UCL.Noclip)
end

function zb.PlayerCanToolgun(ply)
	if not IsValid(ply) then return false end
	if game.SinglePlayer() then return true end

	return zb.HasULX(ply, zb.UCL.Toolgun)
end

function zb.PlayerCanPhysgun(ply)
	if not IsValid(ply) then return false end
	if game.SinglePlayer() then return true end

	return zb.HasULX(ply, zb.UCL.Physgun)
end

function zb.PlayerCanSandboxBypass(ply)
	if not IsValid(ply) then return false end

	return zb.HasULX(ply, zb.UCL.SandboxBypass)
end

function zb.PlayerCanAdminTools(ply, needsSuper)
	if not IsValid(ply) then return false end

	if needsSuper then
		return zb.HasULX(ply, zb.UCL.SuperChat) or zb.HasULX(ply, zb.UCL.AdminTools)
	end

	return zb.HasULX(ply, zb.UCL.AdminTools)
end
