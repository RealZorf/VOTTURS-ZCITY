if not SERVER then return end

zb = zb or {}
zb.KarmaBan = zb.KarmaBan or {}

local KarmaBan = zb.KarmaBan

KarmaBan.BASE_MINUTES = zb.KarmaBanBaseMinutes or 45
KarmaBan.REASON_TAG = "[KARMA BAN]"
KarmaBan.LEGACY_REASON_TAG = "[ZB-KB]"
KarmaBan.FALLBACK_FILE = "zbattle/karma_ban_escalation.json"
KarmaBan.TABLE_NAME = "zb_karma_ban"

KarmaBan.REASONS = {
	low_karma = {
		reason = "Kicked and banned for having too low karma.",
		announce = function(name, minutes, level)
			return "Player " .. name .. " has been banned for " .. minutes
				.. " minutes for having too low karma. (Strike " .. level .. " this month)"
		end,
	},
	team_damage = {
		reason = "Kicked and banned for dealing too much team damage.",
		announce = function(name, minutes, level)
			return "Player " .. name .. " has been banned for " .. minutes
				.. " minutes for RDMing in a team based gamemode. (Strike " .. level .. " this month)"
		end,
	},
	--[[karma_exploit = {
		reason = "Kicked and banned for trying to exploit karma system.",
		announce = function(name, minutes, level)
			return "Player " .. name .. " has been banned for " .. minutes
				.. " minutes for trying to exploit the karma system. (Strike " .. level .. " this month)"
		end,
	},]] 
}

KarmaBan.Players = KarmaBan.Players or {}
KarmaBan.MySQLActive = KarmaBan.MySQLActive or false

local playerLocks = {}
local recentOrigins = {}

function KarmaBan.GetMonthKey(timestamp)
	timestamp = timestamp or os.time()
	return os.date("%Y%m", timestamp)
end

function KarmaBan.CalculateDuration(banLevel)
	banLevel = math.max(tonumber(banLevel) or 1, 1)
	return KarmaBan.BASE_MINUTES * (2 ^ (banLevel - 1))
end

function KarmaBan.ResolveBanLevel(storedLevel, storedMonth, monthKey)
	storedLevel = tonumber(storedLevel) or 0
	monthKey = monthKey or KarmaBan.GetMonthKey()

	if storedMonth ~= monthKey then
		return 1
	end

	return storedLevel + 1
end

function KarmaBan.MakeToken(_, banLevel)
    local issued = os.date("!%Y-%m-%d %H:%M UTC")

    return string.format(
        "%s [Strike: %d | Issued: %s]",
        KarmaBan.REASON_TAG,
        banLevel,
        issued
    )
end

function KarmaBan.ReasonHasTag(reason)
	if not isstring(reason) then return false end

	return string.find(reason, KarmaBan.REASON_TAG, 1, true) ~= nil
		or string.find(reason, KarmaBan.LEGACY_REASON_TAG, 1, true) ~= nil
end

function KarmaBan.GetReasonDefinition(reasonKey)
	return KarmaBan.REASONS[reasonKey] or KarmaBan.REASONS.low_karma
end

function KarmaBan.ParseTokenLevel(reason)
	if not KarmaBan.ReasonHasTag(reason) then return nil end

	local level = string.match(reason, "Strike:%s+(%d+)")
	return tonumber(level)
end

function KarmaBan.HasActiveSyncedBan(steamID)
	local banData = ULib and ULib.bans and ULib.bans[steamID]
	if not banData then return false end

	local unban = tonumber(banData.unban)
	if unban and unban > 0 and unban <= os.time() then
		return false
	end

	return KarmaBan.ReasonHasTag(banData.reason)
end

function KarmaBan.MarkOrigin(token)
	if not token then return end
	recentOrigins[token] = CurTime()
end

function KarmaBan.IsRecentOrigin(token)
	local issuedAt = recentOrigins[token]
	if not issuedAt then return false end

	if CurTime() - issuedAt > 30 then
		recentOrigins[token] = nil
		return false
	end

	return true
end

function KarmaBan.ShouldSkipEscalation(steamID, steamID64)
	if KarmaBan.HasActiveSyncedBan(steamID) then
		return true, "active_guilt_ban"
	end

	local cached = KarmaBan.Players[steamID64]
	if cached and cached.active_ban_token and cached.last_ban_time then
		local elapsed = os.time() - (tonumber(cached.last_ban_time) or 0)
		if elapsed >= 0 and elapsed < 15 and KarmaBan.HasActiveSyncedBan(steamID) then
			return true, "recent_guilt_ban"
		end
	end

	return false
end

hook.Add("ULibPlayerBanned", "ZB_KarmaBanSyncGuard", function(steamID, banData)
	if not banData or not KarmaBan.ReasonHasTag(banData.reason) then return end

	local token = banData.reason and string.match(banData.reason, "%[ZB%-[GK]B%][^%s]+")
	if token and KarmaBan.IsRecentOrigin(token) then
		return
	end

	if KarmaBan.HasActiveSyncedBan(steamID) then
		local steamID64 = util.SteamIDTo64(steamID)
		local cached = KarmaBan.Players[steamID64]
		local parsedLevel = KarmaBan.ParseTokenLevel(banData.reason)

		if cached and parsedLevel and tonumber(cached.ban_level) == parsedLevel then
			cached.active_ban_token = token or cached.active_ban_token
		end
	end
end)

local FallbackStore = {}

local function ReadFallbackStore()
	if FallbackStore.loaded then return FallbackStore.data end

	FallbackStore.loaded = true
	FallbackStore.data = {}

	if file.Exists(KarmaBan.FALLBACK_FILE, "DATA") then
		local parsed = util.JSONToTable(file.Read(KarmaBan.FALLBACK_FILE, "DATA") or "") or {}
		if istable(parsed) then
			FallbackStore.data = parsed
		end
	end

	return FallbackStore.data
end

local function WriteFallbackStore()
	if not FallbackStore.loaded then return end
	file.Write(KarmaBan.FALLBACK_FILE, util.TableToJSON(FallbackStore.data, true))
end

local function CachePlayer(steamID64, row)
	if hg.PlayerDB then
		KarmaBan.Players[steamID64] = {
			ban_level = tonumber(row.ban_level) or 0,
			reset_month = tostring(row.reset_month or ""),
			active_ban_token = row.active_ban_token or "",
			last_ban_time = tonumber(row.last_ban_time) or 0,
			loaded = true,
			stored = row.stored ~= false,
		}
		return
	end

	KarmaBan.Players[steamID64] = {
		ban_level = tonumber(row.ban_level) or 0,
		reset_month = tostring(row.reset_month or ""),
		active_ban_token = row.active_ban_token or "",
		last_ban_time = tonumber(row.last_ban_time) or 0,
		loaded = true,
		stored = row.stored ~= false,
	}
end

function KarmaBan.LoadPlayer(steamID64, callback)
	if KarmaBan.Players[steamID64] and KarmaBan.Players[steamID64].loaded then
		if callback then callback(KarmaBan.Players[steamID64]) end
		return
	end

	if hg.PlayerDB then
		hg.PlayerDB.Load("karma_ban", steamID64, function(data)
			if data then
				CachePlayer(steamID64, data)
			end
			if callback then callback(KarmaBan.Players[steamID64]) end
		end)
		return
	end

	if KarmaBan.MySQLActive and mysql and mysql.module == "mysqloo" then
		local query = mysql:Select(KarmaBan.TABLE_NAME)
			query:Select("ban_level")
			query:Select("reset_month")
			query:Select("active_ban_token")
			query:Select("last_ban_time")
			query:Where("steamid", steamID64)
			query:Callback(function(result)
				if istable(result) and #result > 0 then
					CachePlayer(steamID64, {
						ban_level = result[1].ban_level,
						reset_month = result[1].reset_month,
						active_ban_token = result[1].active_ban_token,
						last_ban_time = result[1].last_ban_time,
						stored = true,
					})
				else
					CachePlayer(steamID64, {
						ban_level = 0,
						reset_month = KarmaBan.GetMonthKey(),
						active_ban_token = "",
						last_ban_time = 0,
						stored = false,
					})
				end

				if callback then callback(KarmaBan.Players[steamID64]) end
			end)
		query:Execute()
		return
	end

	local store = ReadFallbackStore()
	local row = store[steamID64]

	if row then
		CachePlayer(steamID64, row)
	else
		CachePlayer(steamID64, {
			ban_level = 0,
			reset_month = KarmaBan.GetMonthKey(),
			active_ban_token = "",
			last_ban_time = 0,
			stored = false,
		})
	end

	if callback then callback(KarmaBan.Players[steamID64]) end
end

local function SavePlayerRow(steamID64, row, callback)
	CachePlayer(steamID64, row)

	if hg.PlayerDB then
		hg.PlayerDB.Set("karma_ban", steamID64, {
			ban_level = row.ban_level,
			reset_month = row.reset_month,
			active_ban_token = row.active_ban_token,
			last_ban_time = row.last_ban_time,
		}, { callback = callback and function() callback(true) end })
		return
	end

	if KarmaBan.MySQLActive and mysql and mysql.module == "mysqloo" then
		if row.stored then
			local updateQuery = mysql:Update(KarmaBan.TABLE_NAME)
				updateQuery:Update("ban_level", row.ban_level)
				updateQuery:Update("reset_month", row.reset_month)
				updateQuery:Update("active_ban_token", row.active_ban_token or "")
				updateQuery:Update("last_ban_time", row.last_ban_time or 0)
				updateQuery:Where("steamid", steamID64)
				if callback then updateQuery:Callback(function() callback(true) end) end
			updateQuery:Execute()
		else
			local insertQuery = mysql:Insert(KarmaBan.TABLE_NAME)
				insertQuery:Insert("steamid", steamID64)
				insertQuery:Insert("ban_level", row.ban_level)
				insertQuery:Insert("reset_month", row.reset_month)
				insertQuery:Insert("active_ban_token", row.active_ban_token or "")
				insertQuery:Insert("last_ban_time", row.last_ban_time or 0)
				if callback then insertQuery:Callback(function() callback(true) end) end
			insertQuery:Execute()

			row.stored = true
		end

		return
	end

	local store = ReadFallbackStore()
	store[steamID64] = {
		ban_level = row.ban_level,
		reset_month = row.reset_month,
		active_ban_token = row.active_ban_token,
		last_ban_time = row.last_ban_time,
		stored = true,
	}
	WriteFallbackStore()

	if callback then callback(true) end
end

local function ReserveBanLevelMySQL(steamID64, callback)
	local monthKey = KarmaBan.GetMonthKey()
	local escapedID = mysql:Escape(steamID64)

	local upsertQuery = string.format([[
INSERT INTO `%s` (`steamid`, `ban_level`, `reset_month`, `active_ban_token`, `last_ban_time`)
VALUES ('%s', 1, '%s', '', 0)
ON DUPLICATE KEY UPDATE
	`ban_level` = IF(`reset_month` <> '%s', 1, `ban_level` + 1),
	`reset_month` = '%s'
]], KarmaBan.TABLE_NAME, escapedID, monthKey, monthKey, monthKey)

	mysql:RawQuery(upsertQuery, function()
		local selectQuery = string.format(
			"SELECT `ban_level`, `reset_month`, `active_ban_token`, `last_ban_time` FROM `%s` WHERE `steamid` = '%s' LIMIT 1",
			KarmaBan.TABLE_NAME,
			escapedID
		)

		mysql:RawQuery(selectQuery, function(result)
			local row = istable(result) and result[1] or nil
			local banLevel = tonumber(row and row.ban_level) or 1

			CachePlayer(steamID64, {
				ban_level = banLevel,
				reset_month = row and row.reset_month or monthKey,
				active_ban_token = row and row.active_ban_token or "",
				last_ban_time = tonumber(row and row.last_ban_time) or 0,
				stored = true,
			})

			callback(banLevel)
		end)
	end)
end

local function ReserveBanLevelFallback(steamID64, callback)
	KarmaBan.LoadPlayer(steamID64, function(cached)
		local monthKey = KarmaBan.GetMonthKey()
		local banLevel = KarmaBan.ResolveBanLevel(cached.ban_level, cached.reset_month, monthKey)

		cached.ban_level = banLevel
		cached.reset_month = monthKey

		SavePlayerRow(steamID64, cached, function()
			callback(banLevel)
		end)
	end)
end

local function WithPlayerLock(steamID64, worker)
	if playerLocks[steamID64] then
		timer.Simple(0.05, function()
			WithPlayerLock(steamID64, worker)
		end)
		return
	end

	playerLocks[steamID64] = true

	local function release(...)
		playerLocks[steamID64] = nil
	end

	local ok, err = pcall(worker, release)
	if not ok then
		release()
		ErrorNoHalt("[KarmaBan] " .. tostring(err) .. "\n")
	end
end

function KarmaBan.ReserveNextBanLevel(steamID64, callback)
	if hg.PlayerDB and hg.PlayerDB.IsMySQL() then
		ReserveBanLevelMySQL(steamID64, callback)
	elseif KarmaBan.MySQLActive and mysql and mysql.module == "mysqloo" then
		ReserveBanLevelMySQL(steamID64, callback)
	else
		ReserveBanLevelFallback(steamID64, callback)
	end
end

hook.Add("DatabaseConnected", "KarmaBanCreateData", function()
	KarmaBan.MySQLActive = hg.PlayerDB and hg.PlayerDB.IsMySQL() or false
end)

hook.Add("DatabaseConnectionFailed", "KarmaBanFallbackMode", function()
	KarmaBan.MySQLActive = false
end)

hook.Add("PlayerInitialSpawn", "ZB_KarmaBan_Preload", function(ply)
	if hg.PlayerDB then return end
	KarmaBan.LoadPlayer(ply:SteamID64())
end)

function KarmaBan.ApplyBan(steamID, name, opts, callback)
	if isfunction(opts) then
		callback = opts
		opts = nil
	end

	if not ULib or not ULib.addBan then
		if callback then callback(false, "ulib_missing") end
		return
	end

	local reasonKey = isstring(opts) and opts or (istable(opts) and opts.reasonKey) or "low_karma"
	local reasonDef = KarmaBan.GetReasonDefinition(reasonKey)
	local steamID64 = util.SteamIDTo64(steamID)
	local skip, skipReason = KarmaBan.ShouldSkipEscalation(steamID, steamID64)

	if skip then
		local existingLevel = KarmaBan.ParseTokenLevel(ULib.bans[steamID] and ULib.bans[steamID].reason)
		if callback then
			callback(false, skipReason, existingLevel and KarmaBan.CalculateDuration(existingLevel) or nil, existingLevel)
		end
		return
	end

	WithPlayerLock(steamID64, function(release)
		KarmaBan.ReserveNextBanLevel(steamID64, function(banLevel)
			local minutes = KarmaBan.CalculateDuration(banLevel)
			local monthKey = KarmaBan.GetMonthKey()
			local token = KarmaBan.MakeToken(steamID64, banLevel, monthKey)
			local reasonText = reasonDef.reason .. " " .. token
			local now = os.time()

			local row = KarmaBan.Players[steamID64] or {}
			row.ban_level = banLevel
			row.reset_month = monthKey
			row.active_ban_token = token
			row.last_ban_time = now
			row.stored = row.stored ~= false

			SavePlayerRow(steamID64, row, function()
				KarmaBan.MarkOrigin(token)
				ULib.addBan(steamID, minutes, reasonText, name, "System")

				PrintMessage(HUD_PRINTTALK, reasonDef.announce(name or steamID, minutes, banLevel))

				release()

				if callback then callback(true, minutes, banLevel) end
			end)
		end)
	end)
end

function KarmaBan.ApplyBanSync(steamID, name, reasonKey)
	local completed, minutes, banLevel = false, KarmaBan.BASE_MINUTES, 1

	KarmaBan.ApplyBan(steamID, name, reasonKey, function(ok, _, mins, level)
		completed = true
		if ok then
			minutes = mins
			banLevel = level
		end
	end)

	local deadline = SysTime() + 2
	while not completed and SysTime() < deadline do
		if mysql and mysql.Think then mysql:Think() end
	end

	return minutes, banLevel
end
