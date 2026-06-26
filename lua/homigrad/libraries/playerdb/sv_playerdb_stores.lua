if not SERVER then return end

hg = hg or {}
local PDB = hg.PlayerDB

if not PDB or not PDB.RegisterStore then return end

local function escape(value)
	if mysql and mysql.Escape then
		return mysql:Escape(tostring(value))
	end

	return sql.SQLStr(tostring(value), true)
end

local function baseUpdatedAt()
	return {
		name = "updated_at",
		sqlType = "INT UNSIGNED NOT NULL DEFAULT 0",
		parse = tonumber,
		default = 0,
	}
end

local function buildCreateSQL(tableName, columns)
	local parts = {}

	for _, col in ipairs(columns) do
		parts[#parts + 1] = string.format("`%s` %s", col.name, col.sqlType)
	end

	return string.format(
		"CREATE TABLE IF NOT EXISTS `%s` (%s, PRIMARY KEY (`steamid`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci",
		tableName,
		table.concat(parts, ", ")
	)
end

local function buildSelectSQL(tableName, fields)
	local fieldList = {}

	for _, field in ipairs(fields) do
		fieldList[#fieldList + 1] = "`" .. field .. "`"
	end

	return "SELECT " .. table.concat(fieldList, ", ") .. " FROM `%s` WHERE `steamid` = '%s' LIMIT 1"
end

local function buildInsertFromColumns(tableName, columns, steamID64, data)
	local keys, values = { "`steamid`" }, { "'" .. escape(steamID64) .. "'" }

	for _, col in ipairs(columns) do
		if col.name == "steamid" then continue end

		keys[#keys + 1] = "`" .. col.name .. "`"
		local val = data[col.name]

		if col.toSQL then
			values[#values + 1] = col.toSQL(val, data)
		elseif col.parse == tonumber then
			values[#values + 1] = tostring(tonumber(val) or 0)
		else
			values[#values + 1] = "'" .. escape(val or "") .. "'"
		end
	end

	return string.format(
		"INSERT INTO `%s` (%s) VALUES (%s)",
		tableName,
		table.concat(keys, ", "),
		table.concat(values, ", ")
	)
end

local function buildUpsertFromColumns(tableName, columns, steamID64, data)
	local insertSQL = buildInsertFromColumns(tableName, columns, steamID64, data)
	return insertSQL .. " ON DUPLICATE KEY UPDATE `steamid` = `steamid`"
end

local function buildUpdateFromColumns(tableName, columns, steamID64, data)
	local sets = {}

	for _, col in ipairs(columns) do
		if col.name == "steamid" then continue end

		local val = data[col.name]

		if col.toSQL then
			sets[#sets + 1] = "`" .. col.name .. "` = " .. col.toSQL(val, data)
		elseif col.parse == tonumber then
			sets[#sets + 1] = "`" .. col.name .. "` = " .. tostring(tonumber(val) or 0)
		else
			sets[#sets + 1] = "`" .. col.name .. "` = '" .. escape(val or "") .. "'"
		end
	end

	sets[#sets + 1] = "`updated_at` = " .. tostring(tonumber(data.updated_at) or os.time())

	return string.format(
		"UPDATE `%s` SET %s WHERE `steamid` = '%s'",
		tableName,
		table.concat(sets, ", "),
		escape(steamID64)
	)
end

local function registerSimpleStore(storeId, tableName, columns, defaultFn)
	local fieldNames = {}

	for _, col in ipairs(columns) do
		fieldNames[#fieldNames + 1] = col.name
	end

	PDB.RegisterStore(storeId, {
		table = tableName,
		columns = columns,
		createSQL = buildCreateSQL(tableName, columns),
		selectSQL = buildSelectSQL(tableName, fieldNames),
		defaults = function(steamID64)
			local data = { steamid = steamID64, updated_at = os.time() }
			defaultFn(data)
			return data
		end,
		parseRow = function(row)
			local data = { steamid = row.steamid, updated_at = tonumber(row.updated_at) or 0 }

			for _, col in ipairs(columns) do
				if col.name == "steamid" then continue end

				if col.fromSQL then
					data[col.name] = col.fromSQL(row[col.name], row)
				elseif col.parse == tonumber then
					data[col.name] = tonumber(row[col.name]) or col.default or 0
				else
					data[col.name] = row[col.name] or col.default or ""
				end
			end

			return data
		end,
		serialize = function(data)
			local row = { steamid = data.steamid, updated_at = data.updated_at or os.time() }

			for _, col in ipairs(columns) do
				if col.name == "steamid" then continue end
				row[col.name] = data[col.name]
			end

			return row
		end,
		buildInsertSQL = function(steamID64, data)
			return buildInsertFromColumns(tableName, columns, steamID64, data)
		end,
		buildUpsertSQL = function(steamID64, data)
			return buildUpsertFromColumns(tableName, columns, steamID64, data)
		end,
		buildUpdateSQL = function(steamID64, data)
			return buildUpdateFromColumns(tableName, columns, steamID64, data)
		end,
	})
end

registerSimpleStore("guilt", "zb_guilt", {
	{ name = "steamid", sqlType = "VARCHAR(20) NOT NULL" },
	{ name = "steam_name", sqlType = "VARCHAR(32) NOT NULL DEFAULT ''", default = "" },
	{ name = "value", sqlType = "FLOAT NOT NULL DEFAULT 100", parse = tonumber, default = 100 },
	baseUpdatedAt(),
}, function(data)
	data.steam_name = ""
	data.value = 100
end)

registerSimpleStore("karmareset", "zb_karmareset", {
	{ name = "steamid", sqlType = "VARCHAR(20) NOT NULL" },
	{ name = "last_reset", sqlType = "INT NOT NULL DEFAULT 0", parse = tonumber, default = 0 },
	baseUpdatedAt(),
}, function(data)
	data.last_reset = 0
end)

registerSimpleStore("karma_ban", "zb_karma_ban", {
	{ name = "steamid", sqlType = "VARCHAR(20) NOT NULL" },
	{ name = "ban_level", sqlType = "INT NOT NULL DEFAULT 0", parse = tonumber, default = 0 },
	{ name = "reset_month", sqlType = "VARCHAR(6) NOT NULL DEFAULT '000000'", default = "000000" },
	{ name = "active_ban_token", sqlType = "VARCHAR(96) NOT NULL DEFAULT ''", default = "" },
	{ name = "last_ban_time", sqlType = "INT NOT NULL DEFAULT 0", parse = tonumber, default = 0 },
	baseUpdatedAt(),
}, function(data)
	data.ban_level = 0
	data.reset_month = os.date("%Y%m")
	data.active_ban_token = ""
	data.last_ban_time = 0
end)

registerSimpleStore("experience", "zb_experience", {
	{ name = "steamid", sqlType = "VARCHAR(20) NOT NULL" },
	{ name = "steam_name", sqlType = "VARCHAR(32) NOT NULL DEFAULT ''", default = "" },
	{ name = "skill", sqlType = "FLOAT NOT NULL DEFAULT 0", parse = tonumber, default = 0 },
	{ name = "experience", sqlType = "INT NOT NULL DEFAULT 0", parse = tonumber, default = 0 },
	{ name = "deaths", sqlType = "INT NOT NULL DEFAULT 0", parse = tonumber, default = 0 },
	{ name = "kills", sqlType = "INT NOT NULL DEFAULT 0", parse = tonumber, default = 0 },
	{ name = "suicides", sqlType = "INT NOT NULL DEFAULT 0", parse = tonumber, default = 0 },
	baseUpdatedAt(),
}, function(data)
	data.steam_name = ""
	data.skill = 0
	data.experience = 0
	data.deaths = 0
	data.kills = 0
	data.suicides = 0
end)

registerSimpleStore("achievements", "hg_achievements", {
	{ name = "steamid", sqlType = "VARCHAR(20) NOT NULL" },
	{ name = "steam_name", sqlType = "VARCHAR(32) NOT NULL DEFAULT ''", default = "" },
	{
		name = "achievements",
		sqlType = "TEXT NOT NULL",
		default = {},
		toSQL = function(val)
			return "'" .. escape(util.TableToJSON(val or {})) .. "'"
		end,
		fromSQL = function(val)
			return util.JSONToTable(val or "") or {}
		end,
	},
	baseUpdatedAt(),
}, function(data)
	data.steam_name = ""
	data.achievements = {}
end)

registerSimpleStore("pointshop", "hg_pointshop", {
	{ name = "steamid", sqlType = "VARCHAR(20) NOT NULL" },
	{ name = "steam_name", sqlType = "VARCHAR(32) NOT NULL DEFAULT ''", default = "" },
	{ name = "donpoints", sqlType = "FLOAT NOT NULL DEFAULT 0", parse = tonumber, default = 0 },
	{ name = "points", sqlType = "FLOAT NOT NULL DEFAULT 0", parse = tonumber, default = 0 },
	{
		name = "items",
		sqlType = "TEXT NOT NULL",
		default = {},
		toSQL = function(val)
			return "'" .. escape(util.TableToJSON(val or {})) .. "'"
		end,
		fromSQL = function(val)
			return util.JSONToTable(val or "") or {}
		end,
	},
	baseUpdatedAt(),
}, function(data)
	data.steam_name = ""
	data.donpoints = 0
	data.points = 0
	data.items = {}
end)

function PDB.SetKarma(steamID64, value, steamName, callback)
	PDB.Set("guilt", steamID64, {
		value = value,
		steam_name = steamName or "",
	}, { callback = callback })
end

function PDB.GetKarma(steamID64)
	local data = PDB.GetCached("guilt", steamID64)
	return data and tonumber(data.value) or 100
end

function PDB.AddKarma(steamID64, amount, steamName, callback)
	local data = PDB.GetCached("guilt", steamID64) or { value = 100 }
	local newValue = math.max(0, (tonumber(data.value) or 100) + amount)
	PDB.SetKarma(steamID64, newValue, steamName, callback)
	return newValue
end

hook.Add("HG_PlayerDBReady", "HG_PlayerDB_LegacyFlags", function()
	zb = zb or {}
	zb.GuiltSQL = zb.GuiltSQL or {}
	zb.GuiltSQL.Active = PDB.IsMySQL()

	zb.Experience = zb.Experience or {}
	zb.Experience.Active = PDB.IsMySQL()

	zb.KarmaReset = zb.KarmaReset or {}
	zb.KarmaReset.Active = PDB.IsMySQL()

	if hg.achievements then
		hg.achievements.SqlActive = PDB.IsMySQL()
	end

	if hg.Pointshop then
		hg.Pointshop.Active = PDB.IsMySQL()
	end
end)

hook.Add("HG_PlayerDBLoaded", "HG_PlayerDB_LegacyCacheMirror", function(ply, storeId, data)
	if not IsValid(ply) or not data then return end

	local steamID64 = ply:SteamID64()

	if storeId == "guilt" then
		zb.GuiltSQL = zb.GuiltSQL or {}
		zb.GuiltSQL.PlayerInstances = zb.GuiltSQL.PlayerInstances or {}
		zb.GuiltSQL.PlayerInstances[steamID64] = { value = tonumber(data.value) or 100 }

		ply.Karma = tonumber(data.value) or 100
		ply:SetNetVar("Karma", ply.Karma)
	elseif storeId == "experience" then
		zb.Experience = zb.Experience or {}
		zb.Experience.PlayerInstances = zb.Experience.PlayerInstances or {}
		zb.Experience.PlayerInstances[steamID64] = {
			skill = tonumber(data.skill) or 0,
			experience = tonumber(data.experience) or 0,
			deaths = tonumber(data.deaths) or 0,
			kills = tonumber(data.kills) or 0,
			suicides = tonumber(data.suicides) or 0,
		}
	elseif storeId == "achievements" then
		hg.achievements = hg.achievements or {}
		hg.achievements.achievements_data = hg.achievements.achievements_data or {}
		hg.achievements.achievements_data.player_achievements = hg.achievements.achievements_data.player_achievements or {}
		hg.achievements.achievements_data.player_achievements[steamID64] = data.achievements or {}
	elseif storeId == "karmareset" then
		zb.KarmaReset = zb.KarmaReset or {}
		zb.KarmaReset.PlayerInstances = zb.KarmaReset.PlayerInstances or {}
		zb.KarmaReset.PlayerInstances[steamID64] = {
			last_reset = tonumber(data.last_reset) or 0,
			stored = true,
			loaded = true,
		}
	elseif storeId == "karma_ban" then
		zb.KarmaBan = zb.KarmaBan or {}
		zb.KarmaBan.Players = zb.KarmaBan.Players or {}
		zb.KarmaBan.Players[steamID64] = {
			ban_level = tonumber(data.ban_level) or 0,
			reset_month = tostring(data.reset_month or ""),
			active_ban_token = data.active_ban_token or "",
			last_ban_time = tonumber(data.last_ban_time) or 0,
			loaded = true,
			stored = true,
		}
	elseif storeId == "pointshop" then
		hg.Pointshop = hg.Pointshop or {}
		hg.Pointshop.PlayerInstances = hg.Pointshop.PlayerInstances or {}
		hg.Pointshop.PlayerInstances[steamID64] = {
			donpoints = tonumber(data.donpoints) or 0,
			points = tonumber(data.points) or 0,
			items = data.items or {},
		}

		hook.Run("PS_PlayerLoaded", ply, steamID64)
	end
end)

hook.Add("HG_PlayerDBSynced", "HG_PlayerDB_LegacyCacheResync", function(ply, storeId, data)
	hook.Run("HG_PlayerDBLoaded", ply, storeId, data)
end)
