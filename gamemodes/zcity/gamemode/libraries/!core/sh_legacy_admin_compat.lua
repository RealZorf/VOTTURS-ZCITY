--universal compatibility for workshop addons that use ply:IsAdmin() / ply:IsSuperAdmin() (hopefully)

zb = zb or {}

local LEGACY_ADMIN_GROUPS = {
	superadmin = true,
	admin = true,
	operator = true,
}

local function normalizedUserGroup(ply)
	if not IsValid(ply) or not ply.IsPlayer or not ply:IsPlayer() then return nil end
	if not ply.GetUserGroup then return nil end

	local group = ply:GetUserGroup()
	if not isstring(group) or group == "" then return nil end

	return string.lower(group)
end

function zb.PlayerHasLegacySuperAdminAccess(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end

	if ULib and ULib.ucl and ULib.ucl.query(ply, ULib.ACCESS_SUPERADMIN) == true then
		return true
	end

	return normalizedUserGroup(ply) == "superadmin"
end

function zb.PlayerHasLegacyAdminAccess(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return false end
	if zb.PlayerHasLegacySuperAdminAccess(ply) then return true end

	if ULib and ULib.ucl then
		if ULib.ucl.query(ply, ULib.ACCESS_ADMIN) == true then return true end
		if ULib.ucl.query(ply, ULib.ACCESS_OPERATOR) == true then return true end
	end

	local group = normalizedUserGroup(ply)
	return group ~= nil and LEGACY_ADMIN_GROUPS[group] == true
end

function zb.InstallLegacyAdminCompatibility()
	local meta = FindMetaTable("Player")
	if not meta then return end

	if not meta.ZCityLegacyAdminNative then
		meta.ZCityLegacyAdminNative = meta.IsAdmin
		meta.ZCityLegacySuperAdminNative = meta.IsSuperAdmin
	end

	local nativeIsAdmin = meta.ZCityLegacyAdminNative
	local nativeIsSuperAdmin = meta.ZCityLegacySuperAdminNative

	function meta:IsAdmin()
		if not IsValid(self) or not self:IsPlayer() then
			return nativeIsAdmin(self)
		end

		if nativeIsAdmin(self) then return true end

		return zb.PlayerHasLegacyAdminAccess(self)
	end

	function meta:IsSuperAdmin()
		if not IsValid(self) or not self:IsPlayer() then
			return nativeIsSuperAdmin(self)
		end

		if nativeIsSuperAdmin(self) then return true end

		return zb.PlayerHasLegacySuperAdminAccess(self)
	end

	meta.ZCityLegacyAdminPatched = true
end

local function scheduleLegacyAdminInstall()
	zb.InstallLegacyAdminCompatibility()
end

if SERVER then
	hook.Add("Initialize", "ZCity_LegacyAdminCompat", scheduleLegacyAdminInstall)
	timer.Simple(0, scheduleLegacyAdminInstall)
	timer.Simple(2, scheduleLegacyAdminInstall)

	if ULib and ULib.HOOK_UCLAUTH then
		hook.Add(ULib.HOOK_UCLAUTH, "ZCity_LegacyAdminCompat", scheduleLegacyAdminInstall)
	end

	if ulx and ulx.HOOK_ULXDONELOADING then
		hook.Add(ulx.HOOK_ULXDONELOADING, "ZCity_LegacyAdminCompat", scheduleLegacyAdminInstall)
	end

	hook.Add("PlayerInitialSpawn", "ZCity_LegacyAdminCompat", function()
		scheduleLegacyAdminInstall()
	end)
end

if CLIENT then
	hook.Add("InitPostEntity", "ZCity_LegacyAdminCompat", scheduleLegacyAdminInstall)
	timer.Simple(0, scheduleLegacyAdminInstall)

	if ULib and ULib.HOOK_UCLAUTH then
		hook.Add(ULib.HOOK_UCLAUTH, "ZCity_LegacyAdminCompat", scheduleLegacyAdminInstall)
	end
end
