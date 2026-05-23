ZCITY_DB = ZCITY_DB or {}

local DB = ZCITY_DB

DB.Ready = DB.Ready or false
DB.SchemaReady = DB.SchemaReady or false
DB.UseMySQL = DB.UseMySQL or false
DB.PlayerCache = DB.PlayerCache or {}
DB.PendingFlush = DB.PendingFlush or {}
DB.LoadingPlayers = DB.LoadingPlayers or {}
DB.TraitorWeeklyCache = DB.TraitorWeeklyCache or nil
DB.TraitorAllTimeCache = DB.TraitorAllTimeCache or nil
DB.TraitorRewardState = DB.TraitorRewardState or nil
DB.TraitorWeekKey = DB.TraitorWeekKey or nil
DB.TraitorWeeklyDirty = DB.TraitorWeeklyDirty or false
DB.TraitorRewardDirty = DB.TraitorRewardDirty or false
DB.GlobalSaveLock = DB.GlobalSaveLock or false

local SAVE_DEBOUNCE = 2
local FLUSH_TIMER_PREFIX = "ZCITY_DB_Flush_"

local function isValidSteamId64(steamId64)
	steamId64 = tostring(steamId64 or "")
	return steamId64 ~= "" and steamId64 ~= "0" and string.match(steamId64, "^%d+$") ~= nil
end

local function safeJSONEncode(tbl)
	local ok, encoded = pcall(util.TableToJSON, istable(tbl) and tbl or {}, true)
	return ok and isstring(encoded) and encoded or "{}"
end

local function safeJSONDecode(raw)
	if not isstring(raw) or raw == "" then return nil end
	local ok, decoded = pcall(util.JSONToTable, raw)
	return ok and istable(decoded) and decoded or nil
end

local function mysqlConnected()
	return mysql and mysql.module == "mysqloo" and isfunction(mysql.IsConnected) and mysql.IsConnected()
end

function DB.IsReady()
	return DB.SchemaReady == true and DB.UseMySQL == true and mysqlConnected()
end

function DB.ShouldUseFiles()
	return not DB.IsReady()
end

local function runQuery(queryString, callback)
	if not mysql or not isfunction(mysql.RawQuery) then
		if isfunction(callback) then callback() end
		return
	end

	mysql:RawQuery(queryString, callback)
end

local function escape(value)
	if mysql and mysql.Escape then
		return mysql:Escape(tostring(value or ""))
	end
	return sql.SQLStr(tostring(value or ""), true)
end

local SCHEMA_DDL = {
	[[CREATE TABLE IF NOT EXISTS `zb_guilt` (
		`steamid` VARCHAR(20) NOT NULL,
		`steam_name` VARCHAR(32) NOT NULL,
		`value` FLOAT NOT NULL,
		PRIMARY KEY (`steamid`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;]],
	[[CREATE TABLE IF NOT EXISTS `zb_experience` (
		`steamid` VARCHAR(20) NOT NULL,
		`steam_name` VARCHAR(32) NOT NULL,
		`skill` FLOAT NOT NULL,
		`experience` INT NOT NULL,
		`deaths` INT NOT NULL,
		`kills` INT NOT NULL,
		`suicides` INT NOT NULL,
		PRIMARY KEY (`steamid`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;]],
	[[CREATE TABLE IF NOT EXISTS `hg_achievements` (
		`steamid` VARCHAR(20) NOT NULL,
		`steam_name` VARCHAR(32) NOT NULL,
		`achievements` MEDIUMTEXT NOT NULL,
		PRIMARY KEY (`steamid`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;]],
	[[CREATE TABLE IF NOT EXISTS `zcity_player_store` (
		`steamid` VARCHAR(20) NOT NULL,
		`steam_name` VARCHAR(32) NOT NULL,
		`store_data` MEDIUMTEXT NOT NULL,
		`updated_at` INT UNSIGNED NOT NULL DEFAULT 0,
		PRIMARY KEY (`steamid`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;]],
	[[CREATE TABLE IF NOT EXISTS `zcity_scoreboard_playtime` (
		`steamid` VARCHAR(20) NOT NULL,
		`steam_name` VARCHAR(32) NOT NULL,
		`playtime_seconds` INT UNSIGNED NOT NULL DEFAULT 0,
		`updated_at` INT UNSIGNED NOT NULL DEFAULT 0,
		PRIMARY KEY (`steamid`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;]],
	[[CREATE TABLE IF NOT EXISTS `zcity_traitor_alltime` (
		`steamid` VARCHAR(20) NOT NULL,
		`steam_name` VARCHAR(64) NOT NULL DEFAULT '',
		`traitor_kills` INT UNSIGNED NOT NULL DEFAULT 0,
		`traitor_wins` INT UNSIGNED NOT NULL DEFAULT 0,
		`traitors_killed` INT UNSIGNED NOT NULL DEFAULT 0,
		`updated_at` INT UNSIGNED NOT NULL DEFAULT 0,
		PRIMARY KEY (`steamid`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;]],
	[[CREATE TABLE IF NOT EXISTS `zcity_traitor_weekly` (
		`steamid` VARCHAR(20) NOT NULL,
		`week_key` VARCHAR(16) NOT NULL,
		`steam_name` VARCHAR(64) NOT NULL DEFAULT '',
		`traitor_kills` INT UNSIGNED NOT NULL DEFAULT 0,
		`traitor_wins` INT UNSIGNED NOT NULL DEFAULT 0,
		`traitors_killed` INT UNSIGNED NOT NULL DEFAULT 0,
		`updated_at` INT UNSIGNED NOT NULL DEFAULT 0,
		PRIMARY KEY (`steamid`, `week_key`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;]],
	[[CREATE TABLE IF NOT EXISTS `zcity_traitor_meta` (
		`meta_key` VARCHAR(32) NOT NULL,
		`meta_value` MEDIUMTEXT NOT NULL,
		`updated_at` INT UNSIGNED NOT NULL DEFAULT 0,
		PRIMARY KEY (`meta_key`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;]],
}

local function ensureTables(onReady)
	if not mysqlConnected() or not istable(SCHEMA_DDL) or #SCHEMA_DDL == 0 then
		if isfunction(onReady) then onReady() end
		return
	end

	local remaining = #SCHEMA_DDL

	local function step()
		remaining = remaining - 1
		if remaining <= 0 and isfunction(onReady) then
			onReady()
		end
	end

	for _, ddl in ipairs(SCHEMA_DDL) do
		runQuery(ddl, step)
	end
end

local function activateLegacyModules()
	zb = zb or {}
	zb.Experience = zb.Experience or {}
	zb.Experience.Active = true
	zb.GuiltSQL = zb.GuiltSQL or {}
	zb.GuiltSQL.Active = true
	hg = hg or {}
	hg.achievements = hg.achievements or {}
end

function DB.MarkDirty(steamId64, category)
	if not isValidSteamId64(steamId64) then return end

	DB.PlayerCache[steamId64] = DB.PlayerCache[steamId64] or {dirty = {}}
	DB.PlayerCache[steamId64].dirty[category] = true

	local timerName = FLUSH_TIMER_PREFIX .. steamId64
	if timer.Exists(timerName) then return end

	timer.Create(timerName, SAVE_DEBOUNCE, 1, function()
		DB.FlushPlayer(steamId64)
	end)
end

function DB.QueueExperienceSave(steamId64)
	DB.MarkDirty(steamId64, "experience")
end

function DB.QueueGuiltSave(steamId64)
	DB.MarkDirty(steamId64, "guilt")
end

function DB.QueueAchievementSave(steamId64)
	DB.MarkDirty(steamId64, "achievements")
end

function DB.QueueStoreSave(steamId64)
	DB.MarkDirty(steamId64, "store")
end

function DB.FlushPlayer(steamId64, force)
	if not DB.IsReady() or not isValidSteamId64(steamId64) then return end

	local cache = DB.PlayerCache[steamId64]
	if not istable(cache) or not istable(cache.dirty) then return end

	if DB.PendingFlush[steamId64] and not force then return end
	DB.PendingFlush[steamId64] = true

	local dirty = cache.dirty
	cache.dirty = {}

	if dirty.experience and zb and zb.Experience and zb.Experience.PlayerInstances then
		local row = zb.Experience.PlayerInstances[steamId64]
		if istable(row) then
			local q = mysql:Update("zb_experience")
			q:Update("skill", row.skill or 0)
			q:Update("experience", row.experience or 0)
			q:Update("deaths", row.deaths or 0)
			q:Update("kills", row.kills or 0)
			q:Update("suicides", row.suicides or 0)
			q:Update("steam_name", cache.steam_name or "")
			q:Where("steamid", steamId64)
			q:Execute()
		end
	end

	if dirty.guilt and zb and zb.GuiltSQL and zb.GuiltSQL.PlayerInstances then
		local row = zb.GuiltSQL.PlayerInstances[steamId64]
		if istable(row) then
			local q = mysql:Update("zb_guilt")
			q:Update("value", row.value or 100)
			q:Update("steam_name", cache.steam_name or "")
			q:Where("steamid", steamId64)
			q:Execute()
		end
	end

	if dirty.achievements and hg and hg.achievements and hg.achievements.achievements_data then
		local achievements = hg.achievements.achievements_data.player_achievements[steamId64] or {}
		local q = mysql:Update("hg_achievements")
		q:Update("achievements", safeJSONEncode(achievements))
		q:Update("steam_name", cache.steam_name or "")
		q:Where("steamid", steamId64)
		q:Execute()
	end

	if dirty.store and istable(cache.store) then
		local q = mysql:Update("zcity_player_store")
		q:Update("store_data", safeJSONEncode(cache.store))
		q:Update("steam_name", cache.steam_name or "")
		q:Update("updated_at", os.time())
		q:Where("steamid", steamId64)
		q:Execute()
	end

	if dirty.playtime then
		local q = mysql:Update("zcity_scoreboard_playtime")
		q:Update("playtime_seconds", math.max(0, math.floor(tonumber(cache.playtime_seconds) or 0)))
		q:Update("steam_name", cache.steam_name or "")
		q:Update("updated_at", os.time())
		q:Where("steamid", steamId64)
		q:Execute()
	end

	DB.PendingFlush[steamId64] = nil
end

function DB.FlushAllPlayers()
	for _, ply in player.Iterator() do
		if IsValid(ply) and ply:IsPlayer() and not ply:IsBot() then
			local steamId64 = ply:SteamID64()
			DB.PlayerCache[steamId64] = DB.PlayerCache[steamId64] or {dirty = {}}
			DB.PlayerCache[steamId64].steam_name = ply:Name()
			DB.PlayerCache[steamId64].dirty.experience = true
			DB.PlayerCache[steamId64].dirty.guilt = true
			DB.PlayerCache[steamId64].dirty.achievements = true
			if ply.ZCStoreData then
				DB.PlayerCache[steamId64].store = ply.ZCStoreData
				DB.PlayerCache[steamId64].dirty.store = true
			end
			DB.FlushPlayer(steamId64, true)
		end
	end

	DB.SaveTraitorWeekly(true)
end

function DB.GetStoreData(steamId64, fallbackNormalizeFn, defaultDataFn)
	if not isValidSteamId64(steamId64) then
		return defaultDataFn and defaultDataFn() or {}
	end

	if DB.ShouldUseFiles() then
		return nil
	end

	local cache = DB.PlayerCache[steamId64]
	if cache and istable(cache.store) then
		return cache.store
	end

	return nil
end

function DB.LoadStoreData(steamId64, plyName, onLoaded)
	if not DB.IsReady() or not isValidSteamId64(steamId64) then
		if isfunction(onLoaded) then onLoaded(nil) end
		return
	end

	if DB.LoadingPlayers[steamId64] then
		return
	end
	DB.LoadingPlayers[steamId64] = true

	local q = mysql:Select("zcity_player_store")
	q:Select("store_data")
	q:Select("steam_name")
	q:Where("steamid", steamId64)
	q:Callback(function(result)
		DB.LoadingPlayers[steamId64] = nil

		local data
		if istable(result) and #result > 0 then
			data = safeJSONDecode(result[1].store_data)
		end

		DB.PlayerCache[steamId64] = DB.PlayerCache[steamId64] or {dirty = {}}
		DB.PlayerCache[steamId64].store = data
		DB.PlayerCache[steamId64].steam_name = plyName or (result and result[1] and result[1].steam_name) or ""

		if isfunction(onLoaded) then onLoaded(data) end
	end)
	q:Execute()
end

function DB.SaveStoreData(steamId64, plyName, data, immediate)
	if not isValidSteamId64(steamId64) then return end

	DB.PlayerCache[steamId64] = DB.PlayerCache[steamId64] or {dirty = {}}
	DB.PlayerCache[steamId64].store = data
	DB.PlayerCache[steamId64].steam_name = plyName or DB.PlayerCache[steamId64].steam_name or ""

	if DB.ShouldUseFiles() then return end

	if immediate then
		DB.PlayerCache[steamId64].dirty.store = true
		DB.FlushPlayer(steamId64, true)
		return
	end

	DB.QueueStoreSave(steamId64)
end

function DB.UpsertStoreData(steamId64, plyName, data)
	if not DB.IsReady() or not isValidSteamId64(steamId64) then return end

	local encoded = escape(safeJSONEncode(data))
	local name = escape(plyName or "")
	local sid = escape(steamId64)
	local now = os.time()

	runQuery(string.format([[
		INSERT INTO `zcity_player_store` (`steamid`, `steam_name`, `store_data`, `updated_at`)
		VALUES ('%s', '%s', '%s', %d)
		ON DUPLICATE KEY UPDATE
			`steam_name` = VALUES(`steam_name`),
			`store_data` = VALUES(`store_data`),
			`updated_at` = VALUES(`updated_at`);
	]], sid, name, encoded, now))
end

function DB.GetPlaytimeSeconds(steamId64)
	if not isValidSteamId64(steamId64) then return 0 end

	local cache = DB.PlayerCache[steamId64]
	if cache and cache.playtime_seconds ~= nil then
		return math.max(0, math.floor(tonumber(cache.playtime_seconds) or 0))
	end

	return 0
end

function DB.SetPlaytimeSeconds(steamId64, plyName, seconds, immediate)
	if not isValidSteamId64(steamId64) then return end

	seconds = math.max(0, math.floor(tonumber(seconds) or 0))
	DB.PlayerCache[steamId64] = DB.PlayerCache[steamId64] or {dirty = {}}
	DB.PlayerCache[steamId64].playtime_seconds = seconds
	DB.PlayerCache[steamId64].steam_name = plyName or DB.PlayerCache[steamId64].steam_name or ""

	if DB.ShouldUseFiles() then return end

	if immediate then
		DB.PlayerCache[steamId64].dirty.playtime = true
		DB.FlushPlayer(steamId64, true)
		return
	end

	DB.MarkDirty(steamId64, "playtime")
end

function DB.LoadPlaytime(steamId64, callback)
	if not DB.IsReady() or not isValidSteamId64(steamId64) then
		if callback then callback(0) end
		return
	end

	local q = mysql:Select("zcity_scoreboard_playtime")
	q:Select("playtime_seconds")
	q:Where("steamid", steamId64)
	q:Callback(function(result)
		local seconds = 0
		if istable(result) and #result > 0 then
			seconds = math.max(0, math.floor(tonumber(result[1].playtime_seconds) or 0))
		end

		DB.PlayerCache[steamId64] = DB.PlayerCache[steamId64] or {dirty = {}}
		DB.PlayerCache[steamId64].playtime_seconds = seconds

		if callback then callback(seconds) end
	end)
	q:Execute()
end

function DB.ApplyPlaytimeToPlayer(ply)
	if not IsValid(ply) or not ply:IsPlayer() or ply:IsBot() then return end

	local steamId64 = ply:SteamID64()
	DB.LoadPlaytime(steamId64, function(seconds)
		if not IsValid(ply) then return end

		ply:SetNWInt("pat_scoreboard_playtime", seconds)
		ply.PATSB_PlaytimeSeconds = seconds
	end)
end

local function setMeta(key, value, callback)
	if not DB.IsReady() then
		if callback then callback(false) end
		return
	end

	local q = string.format([[
		INSERT INTO `zcity_traitor_meta` (`meta_key`, `meta_value`, `updated_at`)
		VALUES ('%s', '%s', %d)
		ON DUPLICATE KEY UPDATE `meta_value` = VALUES(`meta_value`), `updated_at` = VALUES(`updated_at`);
	]], escape(key), escape(value), os.time())

	runQuery(q, callback)
end

local function getMeta(key, callback)
	if not DB.IsReady() then
		if callback then callback(nil) end
		return
	end

	local q = mysql:Select("zcity_traitor_meta")
	q:Select("meta_value")
	q:Where("meta_key", key)
	q:Callback(function(result)
		if istable(result) and #result > 0 and result[1].meta_value then
			callback(result[1].meta_value)
			return
		end
		callback(nil)
	end)
	q:Execute()
end

function DB.GetTraitorWeekKey()
	return DB.TraitorWeekKey or (os.date and os.date("%Y-W%W") or "unknown-week")
end

function DB.LoadTraitorWeekly(callback)
	if DB.ShouldUseFiles() then
		if callback then callback(false) end
		return
	end

	DB.TraitorWeekKey = DB.GetTraitorWeekKey()
	DB.TraitorWeeklyCache = {week = DB.TraitorWeekKey, updated = os.time(), players = {}}
	DB.TraitorAllTimeCache = {players = {}, updated = os.time()}
	DB.TraitorRewardState = {awarded = {}, lastRewards = {}}

	local pending = 4
	local function done()
		pending = pending - 1
		if pending > 0 then return end
		if callback then callback(true) end
		hook.Run("ZCITY_DB_TraitorWeeklyLoaded")
	end

	getMeta("reward_state", function(raw)
		DB.TraitorRewardState = safeJSONDecode(raw) or {awarded = {}, lastRewards = {}}
		DB.TraitorRewardState.awarded = istable(DB.TraitorRewardState.awarded) and DB.TraitorRewardState.awarded or {}
		done()
	end)

	getMeta("current_week", function(week)
		if isstring(week) and week ~= "" then
			DB.TraitorWeekKey = week
			DB.TraitorWeeklyCache.week = week
		end
		done()
	end)

	local q = mysql:Select("zcity_traitor_weekly")
	q:Select("steamid")
	q:Select("steam_name")
	q:Select("traitor_kills")
	q:Select("traitor_wins")
	q:Select("traitors_killed")
	q:Where("week_key", DB.TraitorWeekKey)
	q:Callback(function(result)
		if istable(result) then
			for _, row in ipairs(result) do
				local sid = tostring(row.steamid or "")
				if isValidSteamId64(sid) then
					DB.TraitorWeeklyCache.players["steamid64:" .. sid] = {
						id = "steamid64:" .. sid,
						steamID64 = sid,
						name = row.steam_name or "Unknown",
						traitorKills = tonumber(row.traitor_kills) or 0,
						traitorWins = tonumber(row.traitor_wins) or 0,
						traitorsKilled = tonumber(row.traitors_killed) or 0,
					}
				end
			end
		end
		done()
	end)
	q:Execute()

	local q2 = mysql:Select("zcity_traitor_alltime")
	q2:Select("steamid")
	q2:Select("steam_name")
	q2:Select("traitor_kills")
	q2:Select("traitor_wins")
	q2:Select("traitors_killed")
	q2:Callback(function(result)
		if istable(result) then
			for _, row in ipairs(result) do
				local sid = tostring(row.steamid or "")
				if isValidSteamId64(sid) then
					DB.TraitorAllTimeCache.players["steamid64:" .. sid] = {
						id = "steamid64:" .. sid,
						steamID64 = sid,
						name = row.steam_name or "Unknown",
						traitorKills = tonumber(row.traitor_kills) or 0,
						traitorWins = tonumber(row.traitor_wins) or 0,
						traitorsKilled = tonumber(row.traitors_killed) or 0,
					}
				end
			end
		end
		done()
	end)
	q2:Execute()
end

function DB.UpdateTraitorWeeklyPlayer(steamId64, plyName, stats)
	if not isValidSteamId64(steamId64) then return end

	stats = istable(stats) and stats or {}
	DB.TraitorWeeklyCache = DB.TraitorWeeklyCache or {week = DB.GetTraitorWeekKey(), players = {}}
	DB.TraitorWeeklyCache.players = DB.TraitorWeeklyCache.players or {}

	local key = "steamid64:" .. steamId64
	DB.TraitorWeeklyCache.players[key] = {
		id = key,
		steamID64 = steamId64,
		name = plyName or (DB.TraitorWeeklyCache.players[key] and DB.TraitorWeeklyCache.players[key].name) or "Unknown",
		traitorKills = math.max(0, math.floor(tonumber(stats.traitorKills) or 0)),
		traitorWins = math.max(0, math.floor(tonumber(stats.traitorWins) or 0)),
		traitorsKilled = math.max(0, math.floor(tonumber(stats.traitorsKilled) or 0)),
	}

	DB.TraitorAllTimeCache = DB.TraitorAllTimeCache or {players = {}}
	DB.TraitorAllTimeCache.players = DB.TraitorAllTimeCache.players or {}
	DB.TraitorAllTimeCache.players[key] = {
		id = key,
		steamID64 = steamId64,
		name = plyName or "Unknown",
		traitorKills = math.max(0, math.floor(tonumber(stats.traitorKills) or (DB.TraitorAllTimeCache.players[key] and DB.TraitorAllTimeCache.players[key].traitorKills) or 0)),
		traitorWins = math.max(0, math.floor(tonumber(stats.traitorWins) or (DB.TraitorAllTimeCache.players[key] and DB.TraitorAllTimeCache.players[key].traitorWins) or 0)),
		traitorsKilled = math.max(0, math.floor(tonumber(stats.traitorsKilled) or (DB.TraitorAllTimeCache.players[key] and DB.TraitorAllTimeCache.players[key].traitorsKilled) or 0)),
	}

	DB.TraitorWeeklyDirty = true
	if timer.Exists("ZCITY_DB_TraitorWeeklySave") then return end
	timer.Create("ZCITY_DB_TraitorWeeklySave", SAVE_DEBOUNCE, 1, function()
		DB.SaveTraitorWeekly(false)
	end)
end

function DB.SetTraitorRewardState(state, immediate)
	DB.TraitorRewardState = istable(state) and state or {awarded = {}}
	DB.TraitorRewardState.awarded = istable(DB.TraitorRewardState.awarded) and DB.TraitorRewardState.awarded or {}
	DB.TraitorRewardDirty = true

	if immediate then
		DB.SaveTraitorWeekly(true)
	end
end

function DB.SaveTraitorWeekly(force)
	if not DB.IsReady() then return end
	if DB.GlobalSaveLock and not force then return end

	DB.GlobalSaveLock = true

	local week = DB.TraitorWeekKey or DB.GetTraitorWeekKey()
	setMeta("current_week", week)

	if DB.TraitorRewardDirty or force then
		setMeta("reward_state", safeJSONEncode(DB.TraitorRewardState or {awarded = {}}))
		DB.TraitorRewardDirty = false
	end

	if DB.TraitorWeeklyDirty or force then
		local players = (DB.TraitorWeeklyCache and DB.TraitorWeeklyCache.players) or {}
		for id, entry in pairs(players) do
			local sid = entry.steamID64 or string.match(tostring(id), "^steamid64:(%d+)$")
			if not isValidSteamId64(sid) then continue end

			local q = string.format([[
				INSERT INTO `zcity_traitor_weekly`
					(`steamid`, `week_key`, `steam_name`, `traitor_kills`, `traitor_wins`, `traitors_killed`, `updated_at`)
				VALUES ('%s', '%s', '%s', %d, %d, %d, %d)
				ON DUPLICATE KEY UPDATE
					`steam_name` = VALUES(`steam_name`),
					`traitor_kills` = VALUES(`traitor_kills`),
					`traitor_wins` = VALUES(`traitor_wins`),
					`traitors_killed` = VALUES(`traitors_killed`),
					`updated_at` = VALUES(`updated_at`);
			]],
				escape(sid),
				escape(week),
				escape(entry.name or "Unknown"),
				math.max(0, math.floor(tonumber(entry.traitorKills) or 0)),
				math.max(0, math.floor(tonumber(entry.traitorWins) or 0)),
				math.max(0, math.floor(tonumber(entry.traitorsKilled) or 0)),
				os.time()
			)
			runQuery(q)
		end
		DB.TraitorWeeklyDirty = false
	end

	if force and DB.TraitorAllTimeCache and istable(DB.TraitorAllTimeCache.players) then
		for id, entry in pairs(DB.TraitorAllTimeCache.players) do
			local sid = entry.steamID64 or string.match(tostring(id), "^steamid64:(%d+)$")
			if not isValidSteamId64(sid) then continue end

			local q = string.format([[
				INSERT INTO `zcity_traitor_alltime`
					(`steamid`, `steam_name`, `traitor_kills`, `traitor_wins`, `traitors_killed`, `updated_at`)
				VALUES ('%s', '%s', %d, %d, %d, %d)
				ON DUPLICATE KEY UPDATE
					`steam_name` = VALUES(`steam_name`),
					`traitor_kills` = VALUES(`traitor_kills`),
					`traitor_wins` = VALUES(`traitor_wins`),
					`traitors_killed` = VALUES(`traitors_killed`),
					`updated_at` = VALUES(`updated_at`);
			]],
				escape(sid),
				escape(entry.name or "Unknown"),
				math.max(0, math.floor(tonumber(entry.traitorKills) or 0)),
				math.max(0, math.floor(tonumber(entry.traitorWins) or 0)),
				math.max(0, math.floor(tonumber(entry.traitorsKilled) or 0)),
				os.time()
			)
			runQuery(q)
		end
	end

	timer.Simple(0, function()
		DB.GlobalSaveLock = false
	end)
end

function DB.ResetTraitorWeeklyWeek(newWeek)
	if not DB.IsReady() then return end

	newWeek = tostring(newWeek or DB.GetTraitorWeekKey())
	DB.TraitorWeekKey = newWeek
	DB.TraitorWeeklyCache = {week = newWeek, updated = os.time(), players = {}}
	DB.TraitorWeeklyDirty = true
	setMeta("current_week", newWeek)
	runQuery(string.format("DELETE FROM `zcity_traitor_weekly` WHERE `week_key` != '%s';", escape(newWeek)))
end

local function readDataFile(path)
	if not isstring(path) or path == "" then return nil end
	if not file.Exists(path, "DATA") then return nil end
	return file.Read(path, "DATA")
end

function DB.MigrateStoreFromFiles()
	if not DB.IsReady() or not ZCStore then return end

	local folder = (ZCStore.Config and ZCStore.Config.SaveFolder) or "zcity_store"
	local files = file.Find(folder .. "/*.json", "DATA") or {}

	for _, fileName in ipairs(files) do
		local steamId64 = string.match(fileName, "^(%d+)%.json$")
		if isValidSteamId64(steamId64) then
			local raw = readDataFile(folder .. "/" .. fileName)
			local data = raw and util.JSONToTable(raw)
			if istable(data) and ZCStore.NormalizeData then
				data = ZCStore.NormalizeData(data)
				DB.UpsertStoreData(steamId64, data.last_name or "", data)
			end
		end
	end

	MsgC(Color(100, 200, 255), "[ZCITY_DB] Store file migration queued.\n")
end

function DB.MigrateTraitorWeeklyFromFiles()
	if not DB.IsReady() or not ZC_TRAITOR_WEEKLY then return end

	local TW = ZC_TRAITOR_WEEKLY
	local dataDir = (TW.Config and TW.Config.DataDir) or "zc_traitor_weekly"

	local allTimeRaw = readDataFile(dataDir .. "/" .. ((TW.Config and TW.Config.AllTimeFile) or "alltime.json"))
	local allTime = safeJSONDecode(allTimeRaw)
	if istable(allTime) and istable(allTime.players) then
		DB.TraitorAllTimeCache = {players = allTime.players, updated = os.time()}
	end

	local rewardRaw = readDataFile(dataDir .. "/" .. ((TW.Config and TW.Config.RewardStateFile) or "reward_state.json"))
	local reward = safeJSONDecode(rewardRaw)
	if istable(reward) then
		DB.TraitorRewardState = reward
		DB.TraitorRewardDirty = true
	end

	local boardRaw = readDataFile(dataDir .. "/" .. ((TW.Config and TW.Config.DataFile) or "leaderboard.json"))
	local board = safeJSONDecode(boardRaw)
	if istable(board) then
		DB.TraitorWeekKey = board.week or DB.GetTraitorWeekKey()
		DB.TraitorWeeklyCache = board
		DB.TraitorWeeklyDirty = true
	end

	DB.SaveTraitorWeekly(true)
	MsgC(Color(100, 200, 255), "[ZCITY_DB] Traitor weekly file migration complete.\n")
end

hook.Add("DatabaseConnected", "ZCITY_PlayerDB_Init", function()
	DB.UseMySQL = mysql and mysql.module == "mysqloo" and isfunction(mysql.IsConnected) and mysql.IsConnected()
	DB.SchemaReady = false

	if not DB.UseMySQL then
		MsgC(Color(255, 180, 80), "[ZCITY_DB] Using non-MySQL backend; cross-server sync disabled. Set dbmodule to mysqloo in data/zbattle/sql.json\n")
		DB.Ready = true
		hook.Run("ZCITY_DatabaseReady", false)
		return
	end

	DB.Ready = true

	ensureTables(function()
		DB.SchemaReady = true
		activateLegacyModules()

		if hg and hg.achievements and isfunction(hg.achievements.ActivateDatabase) then
			hg.achievements.ActivateDatabase()
		end

		MsgC(Color(100, 255, 100), "[ZCITY_DB] Player persistence tables ready (MySQLOO).\n")

		timer.Simple(2, function()
			if not file.Exists("zcity_db/migrated_store.txt", "DATA") then
				file.CreateDir("zcity_db")
				DB.MigrateStoreFromFiles()
				file.Write("zcity_db/migrated_store.txt", os.date())
			end

			if not file.Exists("zcity_db/migrated_traitor_weekly.txt", "DATA") then
				DB.MigrateTraitorWeeklyFromFiles()
				file.Write("zcity_db/migrated_traitor_weekly.txt", os.date())
			end
		end)

		hook.Run("ZCITY_DatabaseReady", true)

		for _, ply in player.Iterator() do
			if IsValid(ply) and ply:IsPlayer() and not ply:IsBot() then
				DB.ApplyPlaytimeToPlayer(ply)
			end
		end
	end)
end)

hook.Add("PlayerInitialSpawn", "ZCITY_DB_PlaytimeLoad", function(ply)
	timer.Simple(3, function()
		if IsValid(ply) then
			DB.ApplyPlaytimeToPlayer(ply)
		end
	end)
end)

hook.Add("PlayerDisconnected", "ZCITY_DB_FlushOnDisconnect", function(ply)
	if not IsValid(ply) or ply:IsBot() then return end

	local steamId64 = ply:SteamID64()
	DB.PlayerCache[steamId64] = DB.PlayerCache[steamId64] or {dirty = {}}
	DB.PlayerCache[steamId64].steam_name = ply:Name()

	if ply.ZCStoreData then
		DB.PlayerCache[steamId64].store = ply.ZCStoreData
		DB.PlayerCache[steamId64].dirty.store = true
	end

	DB.PlayerCache[steamId64].dirty.experience = true
	DB.PlayerCache[steamId64].dirty.guilt = true
	DB.PlayerCache[steamId64].dirty.achievements = true

	if ply.PATSB_PlaytimeSeconds ~= nil then
		DB.PlayerCache[steamId64].playtime_seconds = ply.PATSB_PlaytimeSeconds
		DB.PlayerCache[steamId64].dirty.playtime = true
	end

	DB.FlushPlayer(steamId64, true)
end)

hook.Add("ShutDown", "ZCITY_DB_FlushShutdown", function()
	DB.FlushAllPlayers()
end)

function DB.AddPlaytimeSeconds(ply, seconds)
	if not IsValid(ply) or not ply:IsPlayer() or ply:IsBot() then return end

	seconds = math.max(0, math.floor(tonumber(seconds) or 0))
	if seconds <= 0 then return end

	local steamId64 = ply:SteamID64()
	local total = DB.GetPlaytimeSeconds(steamId64) + seconds
	ply.PATSB_PlaytimeSeconds = total
	ply:SetNWInt("pat_scoreboard_playtime", total)
	DB.SetPlaytimeSeconds(steamId64, ply:Name(), total, false)
end

concommand.Add("zcity_db_status", function(ply)
	if IsValid(ply) and not ply:IsAdmin() then return end

	local status = DB.IsReady() and "MySQL ready" or "not ready"
	print("[ZCITY_DB] " .. status .. " | module=" .. tostring(mysql and mysql.module))
end)
