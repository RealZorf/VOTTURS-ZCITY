if not hg or not hg.AdminSystem then return end

local AS = hg.AdminSystem
local ESP = {}

local adminESPUserGroups = {
	["superadmin"] = true,
	["owner"] = true,
	["servermanager"] = true,
	["headdeveloper"] = true,
	["staffmanager"] = true,
	["headadmin"] = true,
	["developer"] = true,
	["admin"] = true,
}
local adminESPRoleModes = {
	["hmcd"] = true,
	["fear"] = true,
}
local ESP_PDATA_KEY = "zcity_live_esp_enabled"
local ROLE_SYNC_TRAITOR_KEY = "AS_ESP_IsTraitor"
local ROLE_SYNC_GUNNER_KEY = "AS_ESP_IsGunner"
local ROLE_SYNC_KNOWN_KEY = "AS_ESP_RoleKnown"

local adminMode = {}
local espPlayers = {}
local syncQueue = {}
local allESP = {}
local lastToggle = {}

local function getSteamKey(ply)
	return ply:SteamID64() or ply:SteamID()
end

local function CanUseAdminESP(ply)
	if not IsValid(ply) then return false end
	return adminESPUserGroups[string.lower(ply:GetUserGroup() or "")] == true
end

local function IsAdminESPRoleMode()
	if not AS or not AS.GetCurrentMode then return false end
	local mode = AS:GetCurrentMode()
	return mode and adminESPRoleModes[mode] == true or false
end

local function ESP_Log(ply, msg)
	if not IsValid(ply) then return end

	print(string.format(
		"[%s] [%s] | %s | alive=%s",
		os.date("%H:%M:%S"),
		ply:Nick(),
		msg,
		tostring(ply:Alive())
	))
end

function ESP:Init()
	util.AddNetworkString("AS_Sync")

	self:SetupHooks()
	self:SetupCommands()

	timer.Create("ZB_AdminESP_AllESP_Sync", 1, 0, function()
		for steamId in pairs(allESP) do
			local ply = player.GetBySteamID64(steamId) or player.GetBySteamID(steamId)
			if not IsValid(ply) or not ply:IsSuperAdmin() then
				allESP[steamId] = nil
			end
		end
	end)

	timer.Create("ZB_AdminESP_SyncQueue", 0.1, 0, function()
		for steamId, ply in pairs(syncQueue) do
			if IsValid(ply) then
				ESP:DoSync(ply)
			end

			syncQueue[steamId] = nil
		end
	end)

	timer.Create("ZB_AdminESP_RoleSync", 0.5, 0, function()
		ESP:SyncRoles()
	end)
end

local function IsRoleSyncTarget(target)
	if not IsValid(target) then return false end
	if not target:Alive() then return false end
	if target:Team() == TEAM_SPECTATOR then return false end

	return true
end

function ESP:SyncRoles()
	local useRoleSync = IsAdminESPRoleMode()
	local roundActive = zb and zb.ROUND_STATE == 1

	for _, target in player.Iterator() do
		if not IsValid(target) then continue end

		local known = useRoleSync and roundActive and IsRoleSyncTarget(target)

		target:SetNWBool(ROLE_SYNC_KNOWN_KEY, known)

		if known then
			target:SetNWBool(ROLE_SYNC_TRAITOR_KEY, target.isTraitor == true)
			target:SetNWBool(ROLE_SYNC_GUNNER_KEY, target.isGunner == true)
		else
			target:SetNWBool(ROLE_SYNC_TRAITOR_KEY, false)
			target:SetNWBool(ROLE_SYNC_GUNNER_KEY, false)
		end
	end
end

function ESP:CanUsePersistentLiveESP(ply)
	return CanUseAdminESP(ply)
end

function ESP:CanUseESP(ply)
	return CanUseAdminESP(ply)
end

function ESP:LoadPreference(ply)
	if not CanUseAdminESP(ply) then return false end
	return ply:GetPData(ESP_PDATA_KEY, "0") == "1"
end

function ESP:SavePreference(ply, enabled)
	if not CanUseAdminESP(ply) then return end
	ply:SetPData(ESP_PDATA_KEY, enabled and "1" or "0")
end

function ESP:IsInAdminMode(ply)
	if not IsValid(ply) then return false end
	return adminMode[getSteamKey(ply)] or false
end

function ESP:ToggleAdminMode(ply)
	if not IsValid(ply) or not ply:IsAdmin() or ply:IsSuperAdmin() then return false end

	local steamId = getSteamKey(ply)

	if adminMode[steamId] then
		adminMode[steamId] = nil
		ply:SetTeam(1)
	else
		if ply:Alive() then ply:Kill() end
		ply:SetTeam(TEAM_SPECTATOR)
		adminMode[steamId] = true
	end

	self:QueueSync(ply)
	return true
end

function ESP:ToggleESP(ply)
	if not CanUseAdminESP(ply) then return false end

	local steamId = getSteamKey(ply)

	if espPlayers[steamId] then
		espPlayers[steamId] = nil
		self:SavePreference(ply, false)
		self:QueueSync(ply)
		return false
	end

	espPlayers[steamId] = true
	self:SavePreference(ply, true)
	self:SyncRoles()
	self:QueueSync(ply)
	return true
end

function ESP:IsEnabled(ply)
	if not CanUseAdminESP(ply) then return false end

	local steamId = getSteamKey(ply)
	if ply:IsSuperAdmin() and allESP[steamId] then return true end

	return espPlayers[steamId] or false
end

function ESP:IsAllESP(ply)
	if not IsValid(ply) then return false end
	local steamId = getSteamKey(ply)
	return ply:IsSuperAdmin() and allESP[steamId] or false
end

function ESP:QueueSync(ply)
	if not IsValid(ply) then return end
	syncQueue[getSteamKey(ply)] = ply
end

function ESP:DoSync(ply)
	if not IsValid(ply) then return end

	local steamId = getSteamKey(ply)
	local isAllESP = self:IsAllESP(ply)

	net.Start("AS_Sync")
	net.WriteBool(self:IsEnabled(ply) or isAllESP)
	net.WriteBool(adminMode[steamId] or false)
	net.WriteBool(isAllESP)
	net.Send(ply)
end

function ESP:SetupHooks()
	hook.Remove("PlayerChangedTeam", "ZB_AdminESP_TeamCheck")
	hook.Remove("PlayerDisconnected", "ZB_AdminESP_Cleanup")
	hook.Remove("PlayerInitialSpawn", "ZB_AdminESP_LoadPreference")
	hook.Remove("PlayerSpawn", "ZB_AdminESP_PlayerSpawnSync")

	hook.Add("PlayerChangedTeam", "ZB_AdminESP_TeamCheck", function(ply, _, newTeam)
		if not CanUseAdminESP(ply) then return end

		if newTeam ~= TEAM_SPECTATOR and ESP:IsInAdminMode(ply) then
			adminMode[getSteamKey(ply)] = nil
		end

		ESP:QueueSync(ply)
	end)

	hook.Add("PlayerDisconnected", "ZB_AdminESP_Cleanup", function(ply)
		if not IsValid(ply) then return end

		local steamId = getSteamKey(ply)
		espPlayers[steamId] = nil
		adminMode[steamId] = nil
		lastToggle[steamId] = nil
		syncQueue[steamId] = nil
	end)

	hook.Add("PlayerInitialSpawn", "ZB_AdminESP_LoadPreference", function(ply)
		timer.Simple(1, function()
			if not IsValid(ply) then return end

			local steamId = getSteamKey(ply)
			espPlayers[steamId] = ESP:LoadPreference(ply) and true or nil

			if espPlayers[steamId] then
				ESP:SyncRoles()
			end

			ESP:QueueSync(ply)
		end)
	end)

	hook.Add("PlayerSpawn", "ZB_AdminESP_PlayerSpawnSync", function(ply)
		if not CanUseAdminESP(ply) then return end

		timer.Simple(0, function()
			if IsValid(ply) then
				ESP:QueueSync(ply)
			end
		end)
	end)
end

function ESP:SetupCommands()
	if concommand.Remove then
		concommand.Remove("zb_adminmode")
		concommand.Remove("zb_admesp")
		concommand.Remove("zb_allesp")
	end

	concommand.Add("zb_adminmode", function(ply)
		if not IsValid(ply) or not ply:IsAdmin() or ply:IsSuperAdmin() then return end
		ESP:ToggleAdminMode(ply)
	end)

	concommand.Add("zb_admesp", function(ply)
		if not IsValid(ply) or not CanUseAdminESP(ply) then return end

		local steamId = getSteamKey(ply)
		local curTime = CurTime()
		if (lastToggle[steamId] or 0) > curTime then return end
		lastToggle[steamId] = curTime + 0.3

		local enabled = ESP:ToggleESP(ply)
		local msg = enabled and "ESP | Enabled" or "ESP | Disabled"

		ply:ChatPrint(msg)
		ESP_Log(ply, msg)
	end)

	concommand.Add("zb_allesp", function(ply, _, args)
		if not IsValid(ply) or not ply:IsSuperAdmin() then return end

		local steamId = getSteamKey(ply)
		allESP[steamId] = tonumber(args[1] or "0") == 1 and true or nil
		ESP:QueueSync(ply)
	end)
end

AS:RegisterModule("esp", ESP)
