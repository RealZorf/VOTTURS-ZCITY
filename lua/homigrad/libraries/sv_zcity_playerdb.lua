ZCITY_DB = ZCITY_DB or {}

local DB = ZCITY_DB

DB.Ready = DB.Ready or false
DB.SchemaReady = DB.SchemaReady or false
DB.UseMySQL = DB.UseMySQL or false
DB.PlayerCache = DB.PlayerCache or {}
DB.PendingFlush = DB.PendingFlush or {}
DB.PendingFlushReplay = DB.PendingFlushReplay or {}
DB.LoadingPlayers = DB.LoadingPlayers or {}
DB.TraitorWeeklyCache = DB.TraitorWeeklyCache or nil
DB.TraitorAllTimeCache = DB.TraitorAllTimeCache or nil
DB.TraitorRewardState = DB.TraitorRewardState or nil
DB.TraitorWeekKey = DB.TraitorWeekKey or nil
DB.TraitorWeeklyDirty = DB.TraitorWeeklyDirty or false
DB.TraitorRewardDirty = DB.TraitorRewardDirty or false
DB.TraitorDirtySteamIds = DB.TraitorDirtySteamIds or {}
DB.GlobalSaveLock = DB.GlobalSaveLock or false
DB.ShuttingDown = DB.ShuttingDown or false

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

local function logQueryError(context, err)
	err = tostring(err or "unknown error")
	MsgC(Color(255, 80, 80), string.format("[ZCITY_DB] %s failed: %s\n", tostring(context or "query"), err))
end

function DB.LogPersist(action, steamId64, detail, ok, err)
	local status = ok and "ok" or ("FAILED (" .. tostring(err or "unknown") .. ")")
	MsgC(
		Color(100, 200, 255),
		string.format("[ZCITY_DB] %s | steamid=%s | %s | %s\n", tostring(action or "persist"), tostring(steamId64 or ""), tostring(detail or ""), status)
	)
end

function DB.HasGuiltInstance(steamId64)
	if not isValidSteamId64(steamId64) then return false end
	if not zb or not zb.GuiltSQL or not zb.GuiltSQL.PlayerInstances then return false end

	local row = zb.GuiltSQL.PlayerInstances[steamId64]
	if istable(row) and row.value ~= nil then return true end

	return false
end

function DB.SyncGuiltFromPlayer(ply)
	if not IsValid(ply) or not ply:IsPlayer() or ply:IsBot() then return end
	if not zb or not zb.GuiltSQL then return end

	local steamId64 = ply:SteamID64()
	local inst = zb.GuiltSQL.PlayerInstances and zb.GuiltSQL.PlayerInstances[steamId64]

	if istable(inst) and inst.value ~= nil and isfunction(zb.GuiltSQL.ApplyToPlayer) then
		zb.GuiltSQL.ApplyToPlayer(ply, inst.value)
	end

	if isfunction(zb.GuiltSQL.SyncInstanceFromPlayer) then
		zb.GuiltSQL.SyncInstanceFromPlayer(ply)
	end
end

local function runQuery(queryString, callback, context)
	if not mysql or not isfunction(mysql.RawQuery) then
		if isfunction(callback) then callback(nil, false, "mysql not loaded") end
		return
	end

	mysql:RawQuery(queryString, function(...)
		if select(2, ...) == false then
			logQueryError(context or "query", select(3, ...) or "unknown error")
		end

		if isfunction(callback) then
			callback(...)
		end
	end)
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
	[[CREATE TABLE IF NOT EXISTS `hg_pointshop` (
		`steamid` VARCHAR(20) NOT NULL,
		`steam_name` VARCHAR(32) NOT NULL,
		`donpoints` FLOAT NOT NULL,
		`points` FLOAT NOT NULL,
		`items` TEXT NOT NULL,
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
	[[CREATE TABLE IF NOT EXISTS `ulib_groups` (
		`id` INT AUTO_INCREMENT PRIMARY KEY,
		`name` VARCHAR(32) NOT NULL,
		`old_name` VARCHAR(32) DEFAULT NULL,
		`inherit_from` VARCHAR(32) DEFAULT NULL,
		`allow` MEDIUMTEXT,
		`team_kv` MEDIUMTEXT,
		`can_target` VARCHAR(512) DEFAULT NULL,
		`removed` TINYINT(1) NOT NULL DEFAULT 0,
		`is_builtin` TINYINT(1) NOT NULL DEFAULT 0,
		`date_created` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
		`date_updated` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
		UNIQUE KEY `uq_ulib_groups_name` (`name`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;]],
	[[CREATE TABLE IF NOT EXISTS `ulib_users` (
		`id` INT AUTO_INCREMENT PRIMARY KEY,
		`steamid` VARCHAR(24) NOT NULL,
		`group` VARCHAR(32) DEFAULT NULL,
		`allow` MEDIUMTEXT,
		`deny` MEDIUMTEXT,
		`removed` TINYINT(1) NOT NULL DEFAULT 0,
		`date_created` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
		`date_updated` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
		UNIQUE KEY `uq_ulib_users_steamid` (`steamid`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;]],
	[[CREATE TABLE IF NOT EXISTS `ulib_bans` (
		`id` INT AUTO_INCREMENT PRIMARY KEY,
		`steamid` VARCHAR(24) NOT NULL,
		`reason` TEXT,
		`unban` VARCHAR(16) NOT NULL DEFAULT '0',
		`manual_unban` TINYINT(1) NOT NULL DEFAULT 0,
		`username` VARCHAR(64) DEFAULT NULL,
		`host` VARCHAR(96) NOT NULL DEFAULT '',
		`admin` VARCHAR(64) DEFAULT NULL,
		`date_created` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
		`date_updated` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
		UNIQUE KEY `uq_ulib_bans_steamid` (`steamid`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;]],
}

local SCHEMA_MIGRATIONS = {
	[[ALTER TABLE `ulib_groups` MODIFY COLUMN `can_target` VARCHAR(512) DEFAULT NULL;]],
}

local function runSchemaMigrations(onReady)
	if not mysqlConnected() or #SCHEMA_MIGRATIONS == 0 then
		if isfunction(onReady) then onReady() end
		return
	end

	local index = 1

	local function step()
		if index > #SCHEMA_MIGRATIONS then
			if isfunction(onReady) then onReady() end
			return
		end

		local ddl = SCHEMA_MIGRATIONS[index]
		index = index + 1
		runQuery(ddl, step)
	end

	step()
end

local function ensureTables(onReady)
	if not mysqlConnected() or not istable(SCHEMA_DDL) or #SCHEMA_DDL == 0 then
		if isfunction(onReady) then onReady() end
		return
	end

	local remaining = #SCHEMA_DDL

	local function step(_result, ok, err)
		if ok == false then
			logQueryError("schema DDL", err)
		end

		remaining = remaining - 1
		if remaining <= 0 then
			runSchemaMigrations(onReady)
		end
	end

	for i, ddl in ipairs(SCHEMA_DDL) do
		runQuery(ddl, step, "schema DDL #" .. tostring(i))
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
	if not DB.CanPersistPlayerGuilt(steamId64) then return end
	DB.MarkDirty(steamId64, "guilt")
end

function DB.CanPersistPlayerGuilt(steamId64)
	if not isValidSteamId64(steamId64) or not DB.IsReady() then return false end
	if not zb or not zb.GuiltSQL or not zb.GuiltSQL.PlayerInstances then return false end

	if DB.UsesUnifiedPlayerLoad() and not DB.ProfileLoadedSession[steamId64] then
		return false
	end

	local row = zb.GuiltSQL.PlayerInstances[steamId64]
	return istable(row) and row.loaded == true and row.value ~= nil
end

function DB.QueueAchievementSave(steamId64)
	DB.MarkDirty(steamId64, "achievements")
end

function DB.QueueStoreSave(steamId64)
	DB.MarkDirty(steamId64, "store")
end

function DB.MarkDisconnectDirty(ply, steamId64)
	if not isValidSteamId64(steamId64) then return end

	DB.PlayerCache[steamId64] = DB.PlayerCache[steamId64] or {dirty = {}}
	local cache = DB.PlayerCache[steamId64]
	cache.steam_name = IsValid(ply) and ply:Name() or cache.steam_name or ""

	if ply and ply.ZCStoreData then
		cache.store = ply.ZCStoreData
		cache.dirty.store = true
	end

	cache.dirty.experience = true
	cache.dirty.achievements = true

	DB.SyncGuiltFromPlayer(ply)
	if DB.HasGuiltInstance(steamId64) or (IsValid(ply) and ply.Karma ~= nil) then
		cache.dirty.guilt = true
	end

	if hg and hg.Pointshop and hg.Pointshop.PlayerInstances and hg.Pointshop.PlayerInstances[steamId64] then
		cache.dirty.pointshop = true
	end

	if IsValid(ply) and ply.PATSB_PlaytimeSeconds ~= nil then
		cache.playtime_seconds = ply.PATSB_PlaytimeSeconds
		cache.dirty.playtime = true
	end
end

function DB.FlushPlayer(steamId64, force)
	if not DB.IsReady() or not isValidSteamId64(steamId64) then return end

	local cache = DB.PlayerCache[steamId64]
	if not istable(cache) or not istable(cache.dirty) then return end

	if DB.PendingFlush[steamId64] and not (force and DB.IsShuttingDown()) then
		if force then
			DB.PendingFlushReplay[steamId64] = true
		end
		return
	end

	if DB.PendingFlush[steamId64] and force and DB.IsShuttingDown() then
		DB.PendingFlush[steamId64] = nil
		DB.PendingFlushReplay[steamId64] = nil
	end

	if not next(cache.dirty) then return end

	DB.PendingFlush[steamId64] = true

	local dirty = cache.dirty
	cache.dirty = {}

	if dirty.experience and zb and zb.Experience and zb.Experience.PlayerInstances then
		local row = zb.Experience.PlayerInstances[steamId64]
		if istable(row) then
			DB.UpsertExperienceData(steamId64, cache.steam_name or "", row)
		end
	end

	if dirty.guilt then
		local row = zb and zb.GuiltSQL and zb.GuiltSQL.PlayerInstances and zb.GuiltSQL.PlayerInstances[steamId64]
		if istable(row) and row.value ~= nil then
			DB.UpsertGuiltData(steamId64, cache.steam_name or "", row.value)
		end
	end

	if dirty.achievements and hg and hg.achievements and hg.achievements.achievements_data then
		local achievements = hg.achievements.achievements_data.player_achievements[steamId64] or {}
		DB.UpsertAchievementData(steamId64, cache.steam_name or "", achievements)
	end

	if dirty.store and istable(cache.store) then
		DB.UpsertStoreData(steamId64, cache.steam_name or "", cache.store)
	end

	if dirty.pointshop and hg and hg.Pointshop and hg.Pointshop.PlayerInstances then
		local row = hg.Pointshop.PlayerInstances[steamId64]
		if istable(row) then
			DB.UpsertPointshopData(steamId64, cache.steam_name or "", row)
		end
	end

	if dirty.playtime then
		DB.UpsertPlaytimeData(
			steamId64,
			cache.steam_name or "",
			math.max(0, math.floor(tonumber(cache.playtime_seconds) or 0))
		)
	end

	local function finishFlush()
		DB.PendingFlush[steamId64] = nil

		if DB.PendingFlushReplay[steamId64] then
			DB.PendingFlushReplay[steamId64] = nil

			if istable(cache.dirty) and next(cache.dirty) then
				timer.Simple(0, function()
					DB.FlushPlayer(steamId64, true)
				end)
			end
		end
	end

	if DB.IsShuttingDown() then
		finishFlush()
	else
		timer.Simple(0, finishFlush)
	end
end

function DB.ClearProfileSession(steamId64)
	if not isValidSteamId64(steamId64) then return end

	DB.ProfileLoadedSession[steamId64] = nil
	DB.ProfileLoading[steamId64] = nil
	DB.PendingFlushReplay[steamId64] = nil
end

function DB.ReapplyLoadedProfile(ply)
	if not IsValid(ply) or ply:IsBot() then return end

	local steamId64 = ply:SteamID64()
	if not isValidSteamId64(steamId64) then return end

	if zb and zb.GuiltSQL then
		local inst = zb.GuiltSQL.PlayerInstances and zb.GuiltSQL.PlayerInstances[steamId64]
		if istable(inst) and inst.value ~= nil and isfunction(zb.GuiltSQL.ApplyToPlayer) then
			zb.GuiltSQL.ApplyToPlayer(ply, inst.value)
		end
	end

	local cached = DB.PlayerCache[steamId64]
	if cached and cached.playtime_seconds ~= nil then
		local seconds = math.max(0, math.floor(tonumber(cached.playtime_seconds) or 0))
		ply:SetNWInt("pat_scoreboard_playtime", seconds)
		ply.PATSB_PlaytimeSeconds = seconds
	end

	if zb and zb.Experience and zb.Experience.PlayerInstances then
		local expRow = zb.Experience.PlayerInstances[steamId64]
		if istable(expRow) and isfunction(zb.Experience.ApplyJoinRow) then
			zb.Experience.ApplyJoinRow(ply, expRow, false)
		end
	end

	hook.Run("ZCITY_PlayerProfileLoaded", ply)
end

function DB.IsShuttingDown()
	return DB.ShuttingDown == true
end

function DB.BeginShutdown()
	DB.ShuttingDown = true
end

local function markTraitorPlayerDirty(steamId64)
	if not isValidSteamId64(steamId64) then return end
	DB.TraitorDirtySteamIds[steamId64] = true
	DB.TraitorWeeklyDirty = true
end

local function upsertTraitorWeeklyRow(steamId64, entry)
	if not DB.IsReady() or not isValidSteamId64(steamId64) or not istable(entry) then return end

	local week = DB.TraitorWeekKey or DB.GetTraitorWeekKey()
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
		escape(steamId64),
		escape(week),
		escape(entry.name or "Unknown"),
		math.max(0, math.floor(tonumber(entry.traitorKills) or 0)),
		math.max(0, math.floor(tonumber(entry.traitorWins) or 0)),
		math.max(0, math.floor(tonumber(entry.traitorsKilled) or 0)),
		os.time()
	)
	runQuery(q)
end

local function upsertTraitorAlltimeRow(steamId64, entry)
	if not DB.IsReady() or not isValidSteamId64(steamId64) or not istable(entry) then return end

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
		escape(steamId64),
		escape(entry.name or "Unknown"),
		math.max(0, math.floor(tonumber(entry.traitorKills) or 0)),
		math.max(0, math.floor(tonumber(entry.traitorWins) or 0)),
		math.max(0, math.floor(tonumber(entry.traitorsKilled) or 0)),
		os.time()
	)
	runQuery(q)
end

local function getTraitorCacheEntry(steamId64)
	local key = "steamid64:" .. steamId64
	local weekly = DB.TraitorWeeklyCache and DB.TraitorWeeklyCache.players and DB.TraitorWeeklyCache.players[key]
	local alltime = DB.TraitorAllTimeCache and DB.TraitorAllTimeCache.players and DB.TraitorAllTimeCache.players[key]
	return weekly, alltime
end

function DB.FlushAllPlayers()
	for _, ply in player.Iterator() do
		if IsValid(ply) and ply:IsPlayer() and not ply:IsBot() then
			local steamId64 = ply:SteamID64()
			DB.PlayerCache[steamId64] = DB.PlayerCache[steamId64] or {dirty = {}}
			DB.PlayerCache[steamId64].steam_name = ply:Name()
			DB.PlayerCache[steamId64].dirty.experience = true
			DB.SyncGuiltFromPlayer(ply)
			if DB.HasGuiltInstance(steamId64) or ply.Karma ~= nil then
				DB.PlayerCache[steamId64].dirty.guilt = true
			end
			DB.PlayerCache[steamId64].dirty.achievements = true
			if hg and hg.Pointshop and hg.Pointshop.PlayerInstances and hg.Pointshop.PlayerInstances[steamId64] then
				DB.PlayerCache[steamId64].dirty.pointshop = true
			end
			if ply.ZCStoreData then
				DB.PlayerCache[steamId64].store = ply.ZCStoreData
				DB.PlayerCache[steamId64].dirty.store = true
			end
			if ply.PATSB_PlaytimeSeconds ~= nil then
				DB.PlayerCache[steamId64].playtime_seconds = ply.PATSB_PlaytimeSeconds
				DB.PlayerCache[steamId64].dirty.playtime = true
			end
			DB.FlushPlayer(steamId64, true)
		end
	end

	DB.SaveTraitorWeekly(false)
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
	if not isValidSteamId64(steamId64) then
		return false, "invalid steamid64"
	end

	DB.PlayerCache[steamId64] = DB.PlayerCache[steamId64] or {dirty = {}}
	DB.PlayerCache[steamId64].store = data
	DB.PlayerCache[steamId64].steam_name = plyName or DB.PlayerCache[steamId64].steam_name or ""

	if DB.ShouldUseFiles() then
		return false, "mysql not ready"
	end

	if immediate then
		timer.Remove(FLUSH_TIMER_PREFIX .. steamId64)
		DB.UpsertStoreData(steamId64, DB.PlayerCache[steamId64].steam_name or plyName or "", data)
		DB.PlayerCache[steamId64].dirty.store = nil
		return true
	end

	DB.QueueStoreSave(steamId64)
	return true
end

function DB.UpsertGuiltData(steamId64, plyName, value)
	if not DB.IsReady() or not isValidSteamId64(steamId64) then
		return false, "database not ready"
	end

	value = math.Clamp(tonumber(value) or 100, 0, (zb and zb.MaxKarma) or 120)
	local sid = escape(steamId64)
	local name = escape(plyName or "")

	runQuery(string.format([[
		INSERT INTO `zb_guilt` (`steamid`, `steam_name`, `value`)
		VALUES ('%s', '%s', %f)
		ON DUPLICATE KEY UPDATE
			`steam_name` = VALUES(`steam_name`),
			`value` = VALUES(`value`);
	]], sid, name, value), nil, "upsert guilt")

	return true
end

function DB.UpsertExperienceData(steamId64, plyName, row)
	if not DB.IsReady() or not isValidSteamId64(steamId64) or not istable(row) then
		return false, "database not ready"
	end

	local sid = escape(steamId64)
	local name = escape(plyName or "")

	runQuery(string.format([[
		INSERT INTO `zb_experience`
			(`steamid`, `steam_name`, `skill`, `experience`, `deaths`, `kills`, `suicides`)
		VALUES ('%s', '%s', %f, %d, %d, %d, %d)
		ON DUPLICATE KEY UPDATE
			`steam_name` = VALUES(`steam_name`),
			`skill` = VALUES(`skill`),
			`experience` = VALUES(`experience`),
			`deaths` = VALUES(`deaths`),
			`kills` = VALUES(`kills`),
			`suicides` = VALUES(`suicides`);
	]],
		sid,
		name,
		tonumber(row.skill) or 0,
		math.floor(tonumber(row.experience) or 0),
		math.floor(tonumber(row.deaths) or 0),
		math.floor(tonumber(row.kills) or 0),
		math.floor(tonumber(row.suicides) or 0)
	), nil, "upsert experience")

	return true
end

function DB.SaveExperienceData(steamId64, plyName, immediate)
	if not isValidSteamId64(steamId64) then
		return false, "invalid steamid64"
	end

	if not zb or not zb.Experience or not zb.Experience.PlayerInstances then
		return false, "experience unavailable"
	end

	local row = zb.Experience.PlayerInstances[steamId64]
	if not istable(row) then
		return false, "no experience data"
	end

	DB.PlayerCache[steamId64] = DB.PlayerCache[steamId64] or {dirty = {}}
	if plyName and plyName ~= "" then
		DB.PlayerCache[steamId64].steam_name = plyName
	end

	if DB.ShouldUseFiles() then
		return false, "mysql not ready"
	end

	if immediate then
		timer.Remove(FLUSH_TIMER_PREFIX .. steamId64)
		DB.UpsertExperienceData(steamId64, DB.PlayerCache[steamId64].steam_name or plyName or "", row)
		DB.PlayerCache[steamId64].dirty.experience = nil
		return true
	end

	DB.QueueExperienceSave(steamId64)
	return true
end

function DB.UpsertAchievementData(steamId64, plyName, achievements)
	if not DB.IsReady() or not isValidSteamId64(steamId64) then
		return false, "database not ready"
	end

	local sid = escape(steamId64)
	local name = escape(plyName or "")
	local encoded = escape(safeJSONEncode(achievements or {}))

	runQuery(string.format([[
		INSERT INTO `hg_achievements` (`steamid`, `steam_name`, `achievements`)
		VALUES ('%s', '%s', '%s')
		ON DUPLICATE KEY UPDATE
			`steam_name` = VALUES(`steam_name`),
			`achievements` = VALUES(`achievements`);
	]], sid, name, encoded), nil, "upsert achievements")

	return true
end

function DB.SaveAchievementData(steamId64, plyName, achievements, immediate)
	if not isValidSteamId64(steamId64) then
		return false, "invalid steamid64"
	end

	if hg and hg.achievements and hg.achievements.achievements_data then
		hg.achievements.achievements_data.player_achievements[steamId64] = achievements
			or hg.achievements.achievements_data.player_achievements[steamId64]
			or {}
	end

	DB.PlayerCache[steamId64] = DB.PlayerCache[steamId64] or {dirty = {}}
	if plyName and plyName ~= "" then
		DB.PlayerCache[steamId64].steam_name = plyName
	end

	if DB.ShouldUseFiles() then
		return false, "mysql not ready"
	end

	if immediate then
		timer.Remove(FLUSH_TIMER_PREFIX .. steamId64)
		local data = hg.achievements.achievements_data.player_achievements[steamId64] or achievements or {}
		local ok, err = DB.UpsertAchievementData(steamId64, DB.PlayerCache[steamId64].steam_name or plyName or "", data)
		if ok then
			DB.PlayerCache[steamId64].dirty.achievements = nil
		end
		return ok, err
	end

	DB.QueueAchievementSave(steamId64)
	return true
end

function DB.UpsertPlaytimeData(steamId64, plyName, seconds)
	if not DB.IsReady() or not isValidSteamId64(steamId64) then
		return false, "database not ready"
	end

	seconds = math.max(0, math.floor(tonumber(seconds) or 0))
	local sid = escape(steamId64)
	local name = escape(plyName or "")
	local now = os.time()

	runQuery(string.format([[
		INSERT INTO `zcity_scoreboard_playtime` (`steamid`, `steam_name`, `playtime_seconds`, `updated_at`)
		VALUES ('%s', '%s', %d, %d)
		ON DUPLICATE KEY UPDATE
			`steam_name` = VALUES(`steam_name`),
			`playtime_seconds` = VALUES(`playtime_seconds`),
			`updated_at` = VALUES(`updated_at`);
	]], sid, name, seconds, now), nil, "upsert playtime")

	return true
end

function DB.UpsertPointshopData(steamId64, plyName, row)
	if not DB.IsReady() or not isValidSteamId64(steamId64) or not istable(row) then
		return false, "database not ready"
	end

	local sid = escape(steamId64)
	local name = escape(plyName or "")
	local items = escape(safeJSONEncode(row.items or {}))

	runQuery(string.format([[
		INSERT INTO `hg_pointshop`
			(`steamid`, `steam_name`, `donpoints`, `points`, `items`)
		VALUES ('%s', '%s', %f, %f, '%s')
		ON DUPLICATE KEY UPDATE
			`steam_name` = VALUES(`steam_name`),
			`donpoints` = VALUES(`donpoints`),
			`points` = VALUES(`points`),
			`items` = VALUES(`items`);
	]],
		sid,
		name,
		tonumber(row.donpoints) or 0,
		tonumber(row.points) or 0,
		items
	), nil, "upsert pointshop")

	return true
end

function DB.SavePointshopData(steamId64, plyName, immediate)
	if not isValidSteamId64(steamId64) then
		return false, "invalid steamid64"
	end

	if not hg or not hg.Pointshop or not hg.Pointshop.PlayerInstances then
		return false, "pointshop unavailable"
	end

	local row = hg.Pointshop.PlayerInstances[steamId64]
	if not istable(row) then
		return false, "no pointshop data"
	end

	DB.PlayerCache[steamId64] = DB.PlayerCache[steamId64] or {dirty = {}}
	if plyName and plyName ~= "" then
		DB.PlayerCache[steamId64].steam_name = plyName
	end

	if DB.ShouldUseFiles() then
		return false, "mysql not ready"
	end

	if immediate then
		timer.Remove(FLUSH_TIMER_PREFIX .. steamId64)
		DB.UpsertPointshopData(steamId64, DB.PlayerCache[steamId64].steam_name or plyName or "", row)
		return true
	end

	DB.MarkDirty(steamId64, "pointshop")
	return true
end

function DB.SaveGuiltData(steamId64, plyName, value, immediate)
	if not isValidSteamId64(steamId64) then
		return false, "invalid steamid64"
	end

	value = math.Clamp(tonumber(value) or 100, 0, (zb and zb.MaxKarma) or 120)
	plyName = tostring(plyName or "")

	if zb and zb.GuiltSQL and isfunction(zb.GuiltSQL.EnsureInstance) then
		local inst = zb.GuiltSQL.EnsureInstance(steamId64)
		if inst then
			inst.value = value
			inst.loaded = true
			inst.pending = nil
		end
	end

	DB.PlayerCache[steamId64] = DB.PlayerCache[steamId64] or {dirty = {}}
	if plyName ~= "" then
		DB.PlayerCache[steamId64].steam_name = plyName
	end

	if DB.ShouldUseFiles() then
		return false, "mysql not ready"
	end

	if immediate then
		timer.Remove(FLUSH_TIMER_PREFIX .. steamId64)

		local ok, err = DB.UpsertGuiltData(steamId64, DB.PlayerCache[steamId64].steam_name or plyName, value)
		if ok then
			DB.PlayerCache[steamId64].dirty.guilt = nil
		end
		return ok, err
	end

	if DB.CanPersistPlayerGuilt(steamId64) then
		DB.QueueGuiltSave(steamId64)
		return true
	end

	DB.PlayerCache[steamId64].dirty.guilt = true
	DB.MarkDirty(steamId64, "guilt")
	return true
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
	]], sid, name, encoded, now), nil, "upsert store")
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
		timer.Remove(FLUSH_TIMER_PREFIX .. steamId64)
		DB.UpsertPlaytimeData(steamId64, DB.PlayerCache[steamId64].steam_name or plyName or "", seconds)
		DB.PlayerCache[steamId64].dirty.playtime = nil
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
	local cached = DB.PlayerCache[steamId64]
	if cached and cached.playtime_seconds ~= nil then
		local seconds = math.max(0, math.floor(tonumber(cached.playtime_seconds) or 0))
		ply:SetNWInt("pat_scoreboard_playtime", seconds)
		ply.PATSB_PlaytimeSeconds = seconds
		return
	end

	DB.LoadPlaytime(steamId64, function(seconds)
		if not IsValid(ply) then return end

		ply:SetNWInt("pat_scoreboard_playtime", seconds)
		ply.PATSB_PlaytimeSeconds = seconds
	end)
end

DB.ProfileLoading = DB.ProfileLoading or {}
DB.ProfileLoadedSession = DB.ProfileLoadedSession or {}

local unifiedLoadCvar = CreateConVar("zcity_unified_player_load", "1", FCVAR_ARCHIVE, "Load guilt, XP, achievements, pointshop, and playtime in one MySQL round-trip on join.", 0, 1)

function DB.UsesUnifiedPlayerLoad()
	return DB.IsReady() and unifiedLoadCvar:GetBool()
end

local function applyPlaytimeFromProfile(steamId64, seconds)
	seconds = math.max(0, math.floor(tonumber(seconds) or 0))
	DB.PlayerCache[steamId64] = DB.PlayerCache[steamId64] or {dirty = {}}
	DB.PlayerCache[steamId64].playtime_seconds = seconds
end

local function applyUnifiedProfileRow(ply, row)
	if not IsValid(ply) or not istable(row) then return end

	local steamId64 = ply:SteamID64()

	if zb and zb.GuiltSQL and isfunction(zb.GuiltSQL.ApplyJoinRow) then
		local guiltValue = tonumber(row.guilt_value)
		zb.GuiltSQL.ApplyJoinRow(ply, guiltValue, false)
	end

	if zb and zb.Experience and isfunction(zb.Experience.ApplyJoinRow) then
		local expRow
		if row.exp_experience ~= nil then
			expRow = {
				skill = row.exp_skill,
				experience = row.exp_experience,
				deaths = row.exp_deaths,
				kills = row.exp_kills,
				suicides = row.exp_suicides,
			}
		end
		zb.Experience.ApplyJoinRow(ply, expRow, true)
	end

	if hg and hg.achievements and isfunction(hg.achievements.ApplyJoinRow) then
		hg.achievements.ApplyJoinRow(ply, row.achievements_json, true)
	end

	if hg and hg.Pointshop and isfunction(hg.Pointshop.ApplyJoinRow) then
		local psRow
		if row.ps_donpoints ~= nil then
			psRow = {
				donpoints = row.ps_donpoints,
				points = row.ps_points,
				items = row.ps_items,
			}
		end
		hg.Pointshop.ApplyJoinRow(ply, psRow, true)
	end

	applyPlaytimeFromProfile(steamId64, row.playtime_seconds)
	ply:SetNWInt("pat_scoreboard_playtime", math.max(0, math.floor(tonumber(row.playtime_seconds) or 0)))
	ply.PATSB_PlaytimeSeconds = math.max(0, math.floor(tonumber(row.playtime_seconds) or 0))
end

function DB.LoadPlayerProfile(ply)
	if not DB.UsesUnifiedPlayerLoad() then return end
	if not IsValid(ply) or not ply:IsPlayer() or ply:IsBot() then return end

	local steamId64 = ply:SteamID64()
	if not isValidSteamId64(steamId64) then return end
	if DB.ProfileLoading[steamId64] or DB.ProfileLoadedSession[steamId64] then return end

	DB.ProfileLoading[steamId64] = true
	local sid = escape(steamId64)

	local queryString = string.format([[
SELECT
	(SELECT `value` FROM `zb_guilt` WHERE `steamid` = '%s' LIMIT 1) AS `guilt_value`,
	(SELECT `skill` FROM `zb_experience` WHERE `steamid` = '%s' LIMIT 1) AS `exp_skill`,
	(SELECT `experience` FROM `zb_experience` WHERE `steamid` = '%s' LIMIT 1) AS `exp_experience`,
	(SELECT `deaths` FROM `zb_experience` WHERE `steamid` = '%s' LIMIT 1) AS `exp_deaths`,
	(SELECT `kills` FROM `zb_experience` WHERE `steamid` = '%s' LIMIT 1) AS `exp_kills`,
	(SELECT `suicides` FROM `zb_experience` WHERE `steamid` = '%s' LIMIT 1) AS `exp_suicides`,
	(SELECT `achievements` FROM `hg_achievements` WHERE `steamid` = '%s' LIMIT 1) AS `achievements_json`,
	(SELECT `playtime_seconds` FROM `zcity_scoreboard_playtime` WHERE `steamid` = '%s' LIMIT 1) AS `playtime_seconds`,
	(SELECT `donpoints` FROM `hg_pointshop` WHERE `steamid` = '%s' LIMIT 1) AS `ps_donpoints`,
	(SELECT `points` FROM `hg_pointshop` WHERE `steamid` = '%s' LIMIT 1) AS `ps_points`,
	(SELECT `items` FROM `hg_pointshop` WHERE `steamid` = '%s' LIMIT 1) AS `ps_items`;
]], sid, sid, sid, sid, sid, sid, sid, sid, sid, sid, sid)

	local function finishProfileLoad(row)
		DB.ProfileLoading[steamId64] = nil
		if not IsValid(ply) then return end

		applyUnifiedProfileRow(ply, row or {})
		DB.ProfileLoadedSession[steamId64] = true
		hook.Run("ZCITY_PlayerProfileLoaded", ply)
	end

	if mysql and mysql.module == "mysqloo" and mysql.connection then
		local queryObj = mysql.connection:query(queryString)

		if mysqloo and mysqloo.OPTION_NAMED_FIELDS then
			queryObj:setOption(mysqloo.OPTION_NAMED_FIELDS)
		end

		queryObj.onSuccess = function(_, result)
			finishProfileLoad(istable(result) and result[1] or {})
		end

		queryObj.onError = function()
			DB.ProfileLoading[steamId64] = nil
			ErrorNoHalt("[ZCITY_DB] Unified profile load failed for " .. steamId64 .. "; using per-module loaders.\n")
			if IsValid(ply) then
				ply.ZCITY_LegacyProfileLoad = true
				hook.Run("ZCITY_PlayerProfileLoadFailed", ply)
			end
		end

		queryObj:start()
		return
	end

	runQuery(queryString, function(result, success)
		if success == false then
			DB.ProfileLoading[steamId64] = nil
			ErrorNoHalt("[ZCITY_DB] Unified profile load failed for " .. steamId64 .. "; using per-module loaders.\n")
			if IsValid(ply) then
				ply.ZCITY_LegacyProfileLoad = true
				hook.Run("ZCITY_PlayerProfileLoadFailed", ply)
			end
			return
		end

		finishProfileLoad(istable(result) and result[1] or {})
	end, "load unified profile")
end

function DB.RunLegacyPlayerLoads(ply)
	if not IsValid(ply) or not ply:IsPlayer() or ply:IsBot() then return end
	if not DB.IsReady() then return end

	ply.ZCITY_LegacyProfileLoad = true
	local steamId64 = ply:SteamID64()
	local name = ply:Name()

	if zb and zb.GuiltSQL and isfunction(zb.GuiltSQL.ApplyJoinRow) then
		local q = mysql:Select("zb_guilt")
		q:Select("value")
		q:Where("steamid", steamId64)
		q:Callback(function(result)
			if not IsValid(ply) then return end
			local guiltValue = istable(result) and #result > 0 and result[1].value or nil
			zb.GuiltSQL.ApplyJoinRow(ply, guiltValue, guiltValue == nil)
		end)
		q:Execute()
	end

	if zb and zb.Experience and isfunction(zb.Experience.ApplyJoinRow) and zb.Experience.Active then
		local q = mysql:Select("zb_experience")
		q:Select("skill")
		q:Select("experience")
		q:Select("deaths")
		q:Select("kills")
		q:Select("suicides")
		q:Where("steamid", steamId64)
		q:Callback(function(result)
			if not IsValid(ply) then return end
			local row = istable(result) and #result > 0 and result[1] or nil
			zb.Experience.ApplyJoinRow(ply, row and row.experience ~= nil and row or nil, true)
		end)
		q:Execute()
	end

	if hg and hg.achievements and isfunction(hg.achievements.ApplyJoinRow) and hg.achievements.SqlActive then
		local q = mysql:Select("hg_achievements")
		q:Select("achievements")
		q:Where("steamid", steamId64)
		q:Callback(function(result)
			if not IsValid(ply) then return end
			local achievementsJson = istable(result) and #result > 0 and result[1].achievements or nil
			hg.achievements.ApplyJoinRow(ply, achievementsJson, true)
		end)
		q:Execute()
	end

	if hg and hg.Pointshop and isfunction(hg.Pointshop.ApplyJoinRow) and hg.Pointshop.Active then
		local q = mysql:Select("hg_pointshop")
		q:Select("donpoints")
		q:Select("points")
		q:Select("items")
		q:Where("steamid", steamId64)
		q:Callback(function(result)
			if not IsValid(ply) then return end
			local row = istable(result) and #result > 0 and result[1] or nil
			hg.Pointshop.ApplyJoinRow(ply, row and row.donpoints ~= nil and row or nil, true)
		end)
		q:Execute()
	end

	DB.ApplyPlaytimeToPlayer(ply)
	DB.ProfileLoadedSession[steamId64] = true
	hook.Run("ZCITY_PlayerProfileLoaded", ply)
end

hook.Add("ZCITY_PlayerProfileLoadFailed", "ZCITY_DB_LegacyFallback", function(ply)
	DB.RunLegacyPlayerLoads(ply)
end)

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
		DB.TraitorWeeklyLoaded = true
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

	markTraitorPlayerDirty(steamId64)

	local weeklyEntry = DB.TraitorWeeklyCache.players[key]
	local alltimeEntry = DB.TraitorAllTimeCache.players[key]
	if weeklyEntry then
		upsertTraitorWeeklyRow(steamId64, weeklyEntry)
	end
	if alltimeEntry then
		upsertTraitorAlltimeRow(steamId64, alltimeEntry)
	end

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
		for steamId64, _ in pairs(DB.TraitorDirtySteamIds) do
			local weeklyEntry, alltimeEntry = getTraitorCacheEntry(steamId64)
			if weeklyEntry then
				upsertTraitorWeeklyRow(steamId64, weeklyEntry)
			end
			if alltimeEntry then
				upsertTraitorAlltimeRow(steamId64, alltimeEntry)
			end
		end
		DB.TraitorDirtySteamIds = {}
		DB.TraitorWeeklyDirty = false
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

function DB.MigrateTraitorWeeklyFromFiles(onFinished)
	if not DB.IsReady() or not ZC_TRAITOR_WEEKLY then
		if isfunction(onFinished) then onFinished(false) end
		return
	end

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

	local function applyFileMigration()
		local boardRaw = readDataFile(dataDir .. "/" .. ((TW.Config and TW.Config.DataFile) or "leaderboard.json"))
		local board = safeJSONDecode(boardRaw)
		if istable(board) then
			DB.TraitorWeekKey = board.week or DB.GetTraitorWeekKey()
			DB.TraitorWeeklyCache = board
			DB.TraitorWeeklyDirty = true
		end

		DB.SaveTraitorWeekly(true)
		MsgC(Color(100, 200, 255), "[ZCITY_DB] Traitor weekly file migration complete.\n")
		if isfunction(onFinished) then onFinished(true) end
	end

	local countQuery = mysql:Select("zcity_traitor_weekly")
	countQuery:Select("COUNT(*) AS row_count")
	countQuery:Callback(function(result)
		local row = istable(result) and result[1] or nil
		local rowCount = tonumber(row and (row.row_count or row["COUNT(*)"]) or 0) or 0
		if rowCount > 0 then
			MsgC(Color(255, 180, 80), "[ZCITY_DB] Skipping traitor weekly file migration — database already has data.\n")
			if isfunction(onFinished) then onFinished(false) end
			return
		end

		applyFileMigration()
	end)
	countQuery:Execute()
end

local function finishDatabaseStartup()
	hook.Run("ZCITY_DatabaseReady", true)

	if ULibSync and isfunction(ULibSync.Init) then
		timer.Simple(1, function()
			ULibSync.Init()
		end)
	else
		MsgC(Color(255, 180, 80), "[ZCITY_DB] ULibSync addon not loaded — install addons/ulibsync for cross-server ULX sync.\n")
	end

	for _, ply in player.Iterator() do
		if IsValid(ply) and ply:IsPlayer() and not ply:IsBot() then
			DB.ProfileLoadedSession[ply:SteamID64()] = nil
			DB.LoadPlayerProfile(ply)
		end
	end
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

		file.CreateDir("zcity_db")

		DB.LoadTraitorWeekly(function()
			local function afterTraitorMigration()
				if not file.Exists("zcity_db/migrated_store.txt", "DATA") then
					DB.MigrateStoreFromFiles()
					file.Write("zcity_db/migrated_store.txt", os.date())
				end

				finishDatabaseStartup()
			end

			if not file.Exists("zcity_db/migrated_traitor_weekly.txt", "DATA") then
				DB.MigrateTraitorWeeklyFromFiles(function()
					file.Write("zcity_db/migrated_traitor_weekly.txt", os.date())
					afterTraitorMigration()
				end)
			else
				afterTraitorMigration()
			end
		end)
	end)
end)

hook.Add("PlayerInitialSpawn", "ZCITY_DB_LoadProfile", function(ply)
	timer.Simple(0, function()
		if not IsValid(ply) then return end
		DB.LoadPlayerProfile(ply)
	end)

	if not DB.UsesUnifiedPlayerLoad() then
		timer.Simple(3, function()
			if IsValid(ply) then
				DB.ApplyPlaytimeToPlayer(ply)
			end
		end)
	end
end)

hook.Add("ZCITY_PlayerProfileLoaded", "ZCITY_DB_PostProfileSync", function(ply)
	if not IsValid(ply) or not ply.SyncVars then return end

	timer.Simple(0.15, function()
		if IsValid(ply) and ply.SyncVars then
			ply:SyncVars(true)
		end
	end)
end)

hook.Add("PlayerDisconnected", "ZCITY_DB_FlushOnDisconnect", function(ply)
	if DB.IsShuttingDown() then return end
	if not IsValid(ply) or ply:IsBot() then return end

	local steamId64 = ply:SteamID64()
	DB.MarkDisconnectDirty(ply, steamId64)
	DB.FlushPlayer(steamId64, true)

	DB.ProfileLoadedSession[steamId64] = nil
	DB.ProfileLoading[steamId64] = nil
	DB.PendingFlushReplay[steamId64] = nil
	ply.ZCITY_LegacyProfileLoad = nil
end)

hook.Add("ShutDown", "ZCITY_DB_FlushShutdown", function()
	DB.BeginShutdown()

	for _, ply in player.Iterator() do
		if IsValid(ply) and ply:IsPlayer() and not ply:IsBot() then
			local steamId64 = ply:SteamID64()
			timer.Remove(FLUSH_TIMER_PREFIX .. steamId64)
		end
	end

	DB.FlushAllPlayers()

	for _, ply in player.Iterator() do
		if IsValid(ply) and ply:IsPlayer() and not ply:IsBot() then
			DB.ClearProfileSession(ply:SteamID64())
		end
	end
end)

hook.Add("PostCleanupMap", "ZCITY_DB_MapChangeResync", function()
	timer.Simple(0, function()
		if not DB.IsReady() then return end

		for _, ply in player.Iterator() do
			if not IsValid(ply) or ply:IsBot() then continue end

			local steamId64 = ply:SteamID64()

			if DB.HasGuiltInstance(steamId64) then
				DB.ReapplyLoadedProfile(ply)
			else
				DB.ClearProfileSession(steamId64)
				DB.LoadPlayerProfile(ply)
			end
		end
	end)
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
