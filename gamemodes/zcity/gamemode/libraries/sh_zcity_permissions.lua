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
}

local ZCITY_ULX_CMD_ALIASES = {
	["zcity godmode"] = "ulx zcgod",
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

	ULib.ucl.registerAccess(zb.UCL.F6Menu, ZCITY_DEFAULT_GRANT_GROUPS, "Open the F6 admin panel.", "Z-City")
	ULib.ucl.registerAccess(zb.UCL.RoundControl, ZCITY_DEFAULT_GRANT_GROUPS, "Set modes, manage queue, end round (F6 menu actions).", "Z-City")
	ULib.ucl.registerAccess(zb.UCL.Godmode, ZCITY_DEFAULT_GRANT_GROUPS, "Use !zc_god / ulx zcgod.", "Z-City")
	ULib.ucl.registerAccess(zb.UCL.AdminChat, ZCITY_DEFAULT_GRANT_GROUPS, "Use level-1 admin chat commands.", "Z-City")
	ULib.ucl.registerAccess(zb.UCL.SuperChat, ZCITY_DEFAULT_GRANT_GROUPS, "Use level-2 superadmin chat commands.", "Z-City")
	ULib.ucl.registerAccess(zb.UCL.AllModes, ZCITY_DEFAULT_GRANT_GROUPS, "See and pick all gamemodes in the F6 mode list.", "Z-City")
	ULib.ucl.registerAccess(zb.UCL.SpawnMenu, ZCITY_DEFAULT_GRANT_GROUPS, "Open the spawn menu (Q).", "Z-City")
	ULib.ucl.registerAccess(zb.UCL.Spawn, ZCITY_DEFAULT_GRANT_GROUPS, "Spawn props, entities, NPCs, vehicles, etc.", "Z-City")
	ULib.ucl.registerAccess(zb.UCL.Noclip, ZCITY_DEFAULT_GRANT_GROUPS, "Use noclip.", "Z-City")
	ULib.ucl.registerAccess(zb.UCL.Toolgun, ZCITY_DEFAULT_GRANT_GROUPS, "Use the toolgun.", "Z-City")
	ULib.ucl.registerAccess(zb.UCL.Physgun, ZCITY_DEFAULT_GRANT_GROUPS, "Use the physgun (including admin physgun features).", "Z-City")
	ULib.ucl.registerAccess(zb.UCL.SandboxBypass, ZCITY_DEFAULT_GRANT_GROUPS, "Full sandbox admin (bypass restricted sandbox limits).", "Z-City")
	ULib.ucl.registerAccess(zb.UCL.AdminTools, ZCITY_DEFAULT_GRANT_GROUPS, "Use admin C-menu / HG admin tools.", "Z-City")

	timer.Simple(0, function()
		removeErroneousPermissionGroups()

		if ULib.ucl.groupAllow then
			ULib.ucl.groupAllow("superadmin", ZCITY_ULX_CMD_ALIASES[zb.UCL.Godmode])
		end
	end)
end

if SERVER then
	hook.Add("Initialize", "ZCity_RegisterULXPermissions", registerZCityULXPermissions)
end

function zb.HasULX(ply, access)
	return ULib and ULib.ucl and IsValid(ply) and access and ULib.ucl.query(ply, access) == true
end

local function isMapper(ply)
	return IsValid(ply) and ply.IsUserGroup and ply:IsUserGroup("mapper")
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
