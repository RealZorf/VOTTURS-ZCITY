
if !hg or !hg.AdminSystem then return end

local AS = hg.AdminSystem
local ESP = {}

local adminMode = {}
local espPlayers = {}
local syncQueue = {}
local allESP = {}
local lastToggle = {}

local ESP_PDATA_KEY = "zcity_live_esp_enabled"

local function getSteamKey( ply )
	return ply:SteamID64() or ply:SteamID()
end

local function ESP_Log(ply, msg)
	if !IsValid(ply) then return end

	local t = os.date("%H:%M:%S")
	local alive = ply:Alive()

	print(string.format(
		"[ESP %s] %s | %s | alive=%s",
		t,
		ply:Nick(),
		msg,
		tostring(alive)
	))
end

function ESP:Init()
	util.AddNetworkString("AS_Sync")
	util.AddNetworkString("AS_HMCDRoles")

	self:InitRoleSync()
	self:SetupHooks()
	self:SetupCommands()

	timer.Create("AS_AllESP_Sync", 1, 0, function()
		for steamId, enabled in pairs(allESP) do
			local ply = player.GetBySteamID64(steamId) or player.GetBySteamID(steamId)
			if !IsValid(ply) or !(zb and zb.HasULX and zb.HasULX(ply, zb.UCL.SuperChat)) then
				allESP[steamId] = nil
			end
		end
	end)

	timer.Create("AS_SyncQueue", 0.1, 0, function()
		for steamId, ply in pairs(syncQueue) do
			if IsValid(ply) then
				self:DoSync(ply)
			end

			syncQueue[steamId] = nil
		end
	end)
end

function ESP:CanUsePersistentLiveESP( ply )
	if !IsValid( ply ) then return false end
	return zb and zb.HasULX and zb.HasULX( ply, zb.UCL.LiveESP )
end

function ESP:CanUseESP( ply )
	if !IsValid( ply ) then return false end
	return self:CanUsePersistentLiveESP( ply )
end

function ESP:LoadPreference( ply )
	if !IsValid( ply ) or !self:CanUsePersistentLiveESP( ply ) then return false end
	return ply:GetPData( ESP_PDATA_KEY, "0" ) == "1"
end

function ESP:SavePreference( ply, enabled )
	if !IsValid( ply ) or !self:CanUsePersistentLiveESP( ply ) then return end
	ply:SetPData( ESP_PDATA_KEY, enabled and "1" or "0" )
end

function ESP:IsInAdminMode( ply )
	if !IsValid( ply ) then return false end
	local steamId = getSteamKey( ply )
	return adminMode[steamId] or false
end

function ESP:ToggleAdminMode( ply )
	if !IsValid(ply) then return false end
	if !ply:IsAdmin() then return false end
	if ply:IsSuperAdmin() then return false end

	local steamId = getSteamKey( ply )

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

function ESP:ToggleESP( ply )
	if !IsValid( ply ) then return false end
	if !self:CanUseESP( ply ) then return false end

	local steamId = getSteamKey( ply )

	if espPlayers[steamId] then
		espPlayers[steamId] = nil
		self:SavePreference( ply, false )
		self:QueueSync( ply )
		return false
	end

	espPlayers[steamId] = true
	self:SavePreference( ply, true )
	self:QueueSync( ply )
	return true
end

function ESP:IsEnabled( ply )
	if !IsValid( ply ) or !self:CanUseESP( ply ) then return false end

	local steamId = getSteamKey( ply )
	if ply:IsSuperAdmin() and allESP[steamId] then return true end

	return espPlayers[steamId] or false
end

function ESP:QueueSync( ply )
	if !IsValid( ply ) then return end
	local steamId = getSteamKey( ply )
	syncQueue[steamId] = ply
end

function ESP:IsAllESP( ply )
	if !IsValid( ply ) then return false end

	local steamId = getSteamKey( ply )
	return ply:IsSuperAdmin() and allESP[steamId] or false
end

function ESP:DoSync( ply )
	if !IsValid( ply ) then return end

	local steamId = getSteamKey( ply )
	local enabled = self:IsEnabled( ply )
	local inAdminMode = adminMode[steamId] or false
	local isAllESP = self:IsAllESP( ply )

	net.Start("AS_Sync")
	net.WriteBool(enabled or isAllESP)
	net.WriteBool(inAdminMode)
	net.WriteBool(isAllESP)
	net.Send(ply)

	self:SyncHMCDRoles(ply)
end

function ESP:IsHomicideRound()
	local round = CurrentRound and CurrentRound()
	return istable(round) and round.name == "hmcd"
end

function ESP:CollectHMCDPlayers()
	local players = {}

	for _, target in player.Iterator() do
		if IsValid(target) and target:IsPlayer() then
			players[#players + 1] = target
		end
	end

	return players
end

-- Homicide allows only one main traitor; duplicate MainTraitor flags are corrected here.
function ESP:ResolveMainTraitor(players)
	local mainTraitor = nil

	for _, target in ipairs(players) do
		if !IsValid(target) or target.isTraitor != true or target.MainTraitor != true then continue end

		if IsValid(mainTraitor) then
			target.MainTraitor = false
		else
			mainTraitor = target
		end
	end

	return mainTraitor
end

function ESP:SyncHMCDRoles(ply)
	if !IsValid(ply) or !self:IsEnabled(ply) then return end
	if !self:IsHomicideRound() or (zb and zb.ROUND_STATE and zb.ROUND_STATE != 1) then
		net.Start("AS_HMCDRoles")
			net.WriteUInt(0, 8)
		net.Send(ply)
		return
	end

	local players = self:CollectHMCDPlayers()
	local mainTraitor = self:ResolveMainTraitor(players)

	net.Start("AS_HMCDRoles")
		net.WriteUInt(#players, 8)
		for _, target in ipairs(players) do
			net.WriteEntity(target)
			net.WriteBool(target.isTraitor == true)
			net.WriteBool(target.isGunner == true)
			net.WriteBool(target == mainTraitor)
			net.WriteString(target.SubRole or "")
			net.WriteString(target.Profession or "")
		end
	net.Send(ply)
end

function ESP:SyncHMCDRolesForAll()
	if !self:IsHomicideRound() or (zb and zb.ROUND_STATE and zb.ROUND_STATE != 1) then return end

	for steamId, enabled in pairs(espPlayers) do
		if !enabled then continue end

		local ply = player.GetBySteamID64(steamId) or player.GetBySteamID(steamId)
		if IsValid(ply) then
			self:SyncHMCDRoles(ply)
		end
	end

	for steamId, enabled in pairs(allESP) do
		if !enabled then continue end

		local ply = player.GetBySteamID64(steamId) or player.GetBySteamID(steamId)
		if IsValid(ply) then
			self:SyncHMCDRoles(ply)
		end
	end
end

function ESP:InitRoleSync()
	timer.Create("AS_HMCDRoleSync", 1, 0, function()
		if !ESP:IsHomicideRound() or (zb and zb.ROUND_STATE and zb.ROUND_STATE != 1) then return end

		for steamId, enabled in pairs(espPlayers) do
			if !enabled then continue end

			local ply = player.GetBySteamID64(steamId) or player.GetBySteamID(steamId)
			if IsValid(ply) then
				ESP:SyncHMCDRoles(ply)
			end
		end

		for steamId, enabled in pairs(allESP) do
			if !enabled then continue end

			local ply = player.GetBySteamID64(steamId) or player.GetBySteamID(steamId)
			if IsValid(ply) then
				ESP:SyncHMCDRoles(ply)
			end
		end
	end)
end

function ESP:SetupHooks()
	hook.Remove("PlayerChangedTeam", "AS_TeamCheck")
	hook.Remove("PlayerDisconnected", "AS_Cleanup")
	hook.Remove("PlayerInitialSpawn", "AS_ESP_LoadPreference")
	hook.Remove("PlayerSpawn", "AS_ESP_PlayerSpawnSync")

	hook.Add("PlayerChangedTeam", "AS_TeamCheck", function( ply, oldTeam, newTeam )
		if !IsValid( ply ) then return end
		if !self:CanUseESP( ply ) then return end

		if newTeam != TEAM_SPECTATOR and self:IsInAdminMode( ply ) then
			local steamId = getSteamKey( ply )
			adminMode[steamId] = nil
		end

		self:QueueSync( ply )
	end)

	hook.Add("PlayerDisconnected", "AS_Cleanup", function( ply )
		if !IsValid( ply ) then return end

		local steamId = getSteamKey( ply )
		espPlayers[steamId] = nil
		adminMode[steamId] = nil
		lastToggle[steamId] = nil
		syncQueue[steamId] = nil
	end)

	hook.Add("PlayerInitialSpawn", "AS_ESP_LoadPreference", function( ply )
		timer.Simple( 1, function()
			if !IsValid( ply ) then return end

			local steamId = getSteamKey( ply )
			if ESP:LoadPreference( ply ) then
				espPlayers[steamId] = true
			else
				espPlayers[steamId] = nil
			end

			ESP:QueueSync( ply )
		end )
	end)

	hook.Add("PlayerSpawn", "AS_ESP_PlayerSpawnSync", function( ply )
		if !IsValid( ply ) then return end
		if !ESP:CanUseESP( ply ) then return end

		timer.Simple( 0, function()
			if !IsValid( ply ) then return end
			ESP:QueueSync( ply )
		end )
	end)

	hook.Add("ZB_StartRound", "AS_ESP_HMCDRoleSync", function()
		timer.Simple(0, function()
			ESP:SyncHMCDRolesForAll()
		end)
	end)
end

function ESP:SetupCommands()
	if concommand.Remove then
		concommand.Remove("zb_adminmode")
		concommand.Remove("zb_admesp")
		concommand.Remove("zb_allesp")
	end

	concommand.Add("zb_adminmode", function( ply )
		if !IsValid(ply) then return end
		if !(zb and zb.HasULX and zb.HasULX(ply, zb.UCL.AdminChat)) then return end
		if zb.HasULX(ply, zb.UCL.SuperChat) then return end

		ESP:ToggleAdminMode(ply)
	end)

	concommand.Add("zb_admesp", function( ply )
		if !IsValid( ply ) then return end
		if !ESP:CanUseESP( ply ) then return end

		local steamId = getSteamKey( ply )
		local curTime = CurTime()
		if (lastToggle[steamId] or 0) > curTime then return end
		lastToggle[steamId] = curTime + 0.3

		local enabled = ESP:ToggleESP( ply )
		local msg = enabled and "ESP | Enabled" or "ESP | Disabled"

		ply:ChatPrint(msg)
		ESP_Log(ply, msg)
	end)

	concommand.Add("zb_allesp", function( ply, cmd, args )
		if !IsValid( ply ) or !(zb and zb.HasULX and zb.HasULX(ply, zb.UCL.SuperChat)) then return end

		local steamId = getSteamKey( ply )
		local enable = tonumber(args[1] or "0") == 1
		allESP[steamId] = enable or nil
		ESP:QueueSync(ply)
	end)
end

AS:RegisterModule("esp", ESP)
