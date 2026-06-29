zb = zb or {}
zb.BanEscalation = zb.BanEscalation or {}
zb.BanEscalation.PlayerInstances = zb.BanEscalation.PlayerInstances or {}
zb.BanEscalation.PendingWrites = zb.BanEscalation.PendingWrites or {}
zb.BanEscalation.Active = zb.BanEscalation.Active or false

local TABLE_NAME = "zb_ban_escalation"
local pendingLoads = {}

local function getConfig()
	return zb.BanEscalation.Config or {}
end

local function getMonthKey()
	return tonumber(os.date("%Y%m")) or 0
end

local function defaultInstance()
	return {
		strikes = 0,
		strike_month = 0,
		last_ban_time = 0,
		stored = false,
		loaded = false,
		dirty = false,
	}
end

local function updateLocalCache(steamID64, strikes, strikeMonth, lastBanTime, stored)
	zb.BanEscalation.PlayerInstances[steamID64] = {
		strikes = tonumber(strikes) or 0,
		strike_month = tonumber(strikeMonth) or 0,
		last_ban_time = tonumber(lastBanTime) or 0,
		stored = stored == true,
		loaded = true,
		dirty = false,
	}
end

function zb.BanEscalation.GetMonthKey()
	return getMonthKey()
end

function zb.BanEscalation.IsDatabaseReady()
	local cfg = getConfig()

	if not cfg.Enabled then
		return false
	end

	if not mysql then
		return false
	end

	return zb.BanEscalation.Active and mysql:IsConnected()
end

function zb.BanEscalation.CanUseLocalFallback()
	local cfg = getConfig()

	return cfg.Enabled and cfg.LocalFallback
end

function zb.BanEscalation.GetInstance(steamID64)
	local inst = zb.BanEscalation.PlayerInstances[steamID64]

	if not inst then
		inst = defaultInstance()
		zb.BanEscalation.PlayerInstances[steamID64] = inst
	end

	return inst
end

function zb.BanEscalation.MaybeResetMonthly(steamID64)
	local cfg = getConfig()

	if not cfg.MonthlyReset then
		return
	end

	local inst = zb.BanEscalation.GetInstance(steamID64)
	local monthKey = getMonthKey()

	if inst.strike_month ~= 0 and inst.strike_month ~= monthKey then
		inst.strikes = 0
		inst.strike_month = monthKey

		if inst.stored then
			inst.dirty = true
			zb.BanEscalation.QueueSave(steamID64)
		else
			inst.dirty = false
		end
	elseif inst.strike_month == 0 then
		inst.strike_month = monthKey
	end
end

function zb.BanEscalation.GetBanDuration(strikes)
	local cfg = getConfig()
	local baseDuration = math.max(tonumber(cfg.BaseDuration) or 45, 1)
	local strikeCount = math.max(tonumber(strikes) or 1, 1)

	return baseDuration * math.pow(2, strikeCount - 1)
end

function zb.BanEscalation.SaveInstance(steamID64, callback)
	local inst = zb.BanEscalation.PlayerInstances[steamID64]

	if not inst then
		if callback then
			callback(false)
		end

		return
	end

	if not zb.BanEscalation.IsDatabaseReady() then
		if callback then
			callback(false)
		end

		return
	end

	local now = os.time()
	local steamName = ""

	for _, ply in player.Iterator() do
		if ply:SteamID64() == steamID64 then
			steamName = ply:Name()
			break
		end
	end

	if inst.stored then
		local updateQuery = mysql:Update(TABLE_NAME)
			updateQuery:Update("strikes", inst.strikes)
			updateQuery:Update("strike_month", inst.strike_month)
			updateQuery:Update("last_ban_time", inst.last_ban_time)
			updateQuery:Update("updated_at", now)

			if steamName ~= "" then
				updateQuery:Update("steam_name", steamName)
			end

			updateQuery:Where("steamid", steamID64)
			updateQuery:Callback(function()
				inst.dirty = false
				zb.BanEscalation.PendingWrites[steamID64] = nil

				if callback then
					callback(true)
				end
			end)
		updateQuery:Execute()
	else
		local insertQuery = mysql:Insert(TABLE_NAME)
			insertQuery:Insert("steamid", steamID64)
			insertQuery:Insert("steam_name", steamName)
			insertQuery:Insert("strikes", inst.strikes)
			insertQuery:Insert("strike_month", inst.strike_month)
			insertQuery:Insert("last_ban_time", inst.last_ban_time)
			insertQuery:Insert("updated_at", now)
			insertQuery:Callback(function()
				inst.stored = true
				inst.dirty = false
				zb.BanEscalation.PendingWrites[steamID64] = nil

				if callback then
					callback(true)
				end
			end)
		insertQuery:Execute()
	end
end

function zb.BanEscalation.QueueSave(steamID64)
	local inst = zb.BanEscalation.PlayerInstances[steamID64]

	if not inst then
		return
	end

	if inst.strikes <= 0 and not inst.stored then
		inst.dirty = false
		return
	end

	if zb.BanEscalation.IsDatabaseReady() then
		zb.BanEscalation.SaveInstance(steamID64)
	elseif zb.BanEscalation.CanUseLocalFallback() then
		inst.dirty = true
		zb.BanEscalation.PendingWrites[steamID64] = true
	end
end

function zb.BanEscalation.FlushPendingWrites()
	if not zb.BanEscalation.IsDatabaseReady() then
		return
	end

	for steamID64 in pairs(zb.BanEscalation.PendingWrites) do
		zb.BanEscalation.SaveInstance(steamID64)
	end
end

function zb.BanEscalation.MergeLoadedInstance(steamID64, remoteStrikes, remoteMonth, remoteLastBan)
	local localInst = zb.BanEscalation.PlayerInstances[steamID64]
	local wasDirty = localInst and localInst.dirty
	local monthKey = getMonthKey()
	local cfg = getConfig()

	local strikes = tonumber(remoteStrikes) or 0
	local strikeMonth = tonumber(remoteMonth) or 0
	local lastBanTime = tonumber(remoteLastBan) or 0

	if cfg.MonthlyReset and strikeMonth ~= 0 and strikeMonth ~= monthKey then
		strikes = 0
		strikeMonth = monthKey
	end

	if localInst and localInst.loaded and wasDirty then
		if strikeMonth == localInst.strike_month then
			strikes = math.max(strikes, localInst.strikes)
		elseif localInst.strike_month == monthKey then
			strikes = localInst.strikes
			strikeMonth = localInst.strike_month
		end

		lastBanTime = math.max(lastBanTime, localInst.last_ban_time)
	end

	updateLocalCache(steamID64, strikes, strikeMonth, lastBanTime, true)

	if wasDirty then
		zb.BanEscalation.PlayerInstances[steamID64].dirty = true
		zb.BanEscalation.QueueSave(steamID64)
	end
end

function zb.BanEscalation.LoadPlayer(ply)
	if not getConfig().Enabled then
		return
	end

	if not IsValid(ply) or not ply:IsPlayer() then
		return
	end

	local steamID64 = ply:SteamID64()

	if pendingLoads[steamID64] then
		return
	end

	if not zb.BanEscalation.IsDatabaseReady() then
		if zb.BanEscalation.CanUseLocalFallback() then
			zb.BanEscalation.GetInstance(steamID64)
		end

		return
	end

	pendingLoads[steamID64] = true

	local query = mysql:Select(TABLE_NAME)
		query:Select("strikes")
		query:Select("strike_month")
		query:Select("last_ban_time")
		query:Where("steamid", steamID64)
		query:Callback(function(result)
			pendingLoads[steamID64] = nil

			if not IsValid(ply) then
				return
			end

			if istable(result) and #result > 0 then
				zb.BanEscalation.MergeLoadedInstance(
					steamID64,
					result[1].strikes,
					result[1].strike_month,
					result[1].last_ban_time
				)

				local updateQuery = mysql:Update(TABLE_NAME)
					updateQuery:Update("steam_name", ply:Name())
					updateQuery:Where("steamid", steamID64)
				updateQuery:Execute()
			else
				local inst = zb.BanEscalation.GetInstance(steamID64)
				inst.loaded = true
				inst.stored = false
				zb.BanEscalation.MaybeResetMonthly(steamID64)
			end
		end)
	query:Execute()
end

function zb.BanEscalation.IncrementStrike(steamID64)
	zb.BanEscalation.MaybeResetMonthly(steamID64)

	local inst = zb.BanEscalation.GetInstance(steamID64)
	inst.strikes = math.max((tonumber(inst.strikes) or 0) + 1, 1)
	inst.last_ban_time = os.time()
	inst.loaded = true
	inst.dirty = true
	zb.BanEscalation.QueueSave(steamID64)

	return inst.strikes
end

function zb.BanEscalation.BuildBanReason(reason, strikes)
	return string.format("%s (Strikes: %d)", reason, strikes)
end

function zb.BanEscalation.ApplyAutoBan(ply, reason)
	local cfg = getConfig()

	if not cfg.Enabled then
		return nil
	end

	if not IsValid(ply) or not ply:IsPlayer() then
		return nil
	end

	local steamID64 = ply:SteamID64()
	local steamID = ply:SteamID()
	local name = ply:Name()

	local strikes = zb.BanEscalation.IncrementStrike(steamID64)
	local duration = zb.BanEscalation.GetBanDuration(strikes)
	local banReason = zb.BanEscalation.BuildBanReason(reason, strikes)

	if ULib and ULib.addBan then
		ULib.addBan(steamID, duration, banReason, name, "System")
	else
		ply:Ban(duration, false)
	end

	return duration, strikes, banReason
end

function zb.BanEscalation.ApplyAutoBanBySteam(steamID, name, reason)
	local cfg = getConfig()

	if not cfg.Enabled then
		return nil
	end

	if not isstring(steamID) or steamID == "" then
		return nil
	end

	local steamID64 = util.SteamIDTo64(steamID)

	if not steamID64 or steamID64 == "0" then
		return nil
	end

	local strikes = zb.BanEscalation.IncrementStrike(steamID64)
	local duration = zb.BanEscalation.GetBanDuration(strikes)
	local banReason = zb.BanEscalation.BuildBanReason(reason, strikes)

	if ULib and ULib.addBan then
		ULib.addBan(steamID, duration, banReason, name or steamID, "System")
	else
		return nil
	end

	return duration, strikes, banReason
end

hook.Add("DatabaseConnected", "BanEscalationCreateData", function()
	local query = mysql:Create(TABLE_NAME)
		query:Create("steamid", "VARCHAR(20) NOT NULL")
		query:Create("steam_name", "VARCHAR(32) NOT NULL")
		query:Create("strikes", "INT NOT NULL DEFAULT 0")
		query:Create("strike_month", "INT NOT NULL DEFAULT 0")
		query:Create("last_ban_time", "INT UNSIGNED NOT NULL DEFAULT 0")
		query:Create("updated_at", "INT UNSIGNED NOT NULL DEFAULT 0")
		query:PrimaryKey("steamid")
	query:Execute()

	zb.BanEscalation.Active = true
	zb.BanEscalation.FlushPendingWrites()

	for _, ply in player.Iterator() do
		zb.BanEscalation.LoadPlayer(ply)
	end
end)

hook.Add("DatabaseConnectionFailed", "BanEscalationOffline", function()
	zb.BanEscalation.Active = false
end)

hook.Add("PlayerInitialSpawn", "BanEscalationLoad", function(ply)
	zb.BanEscalation.LoadPlayer(ply)
end)

hook.Add("HG_PlayerDBLoaded", "BanEscalationLegacyCache", function(ply, storeId, data)
	if storeId ~= "ban_escalation" or not IsValid(ply) or not data then
		return
	end

	zb.BanEscalation.MergeLoadedInstance(
		ply:SteamID64(),
		data.strikes,
		data.strike_month,
		data.last_ban_time
	)
end)

hook.Add("HG_PlayerDBSynced", "BanEscalationLegacyCacheResync", function(ply, storeId, data)
	hook.Run("HG_PlayerDBLoaded", ply, storeId, data)
end)
