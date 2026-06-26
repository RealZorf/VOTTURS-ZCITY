if not SERVER then return end

hg = hg or {}
hg.PlayerDB = hg.PlayerDB or {}

local PDB = hg.PlayerDB

PDB.Stores = PDB.Stores or {}
PDB.Cache = PDB.Cache or {}
PDB.MySQLActive = PDB.MySQLActive or false
PDB.FallbackDir = "zbattle/playerdb/"

local playerLocks = {}
local loadWaiters = {}
local refreshInterval = 45

local function Now()
	return os.time()
end

local function EnsureCacheStore(storeId)
	PDB.Cache[storeId] = PDB.Cache[storeId] or {}
end

function PDB.IsMySQL()
	return PDB.MySQLActive and mysql and mysql.module == "mysqloo"
end

function PDB.RegisterStore(storeId, config)
	config.id = storeId
	PDB.Stores[storeId] = config
	EnsureCacheStore(storeId)
end

local function WithLock(key, fn)
	if playerLocks[key] then
		timer.Simple(0.05, function() WithLock(key, fn) end)
		return
	end

	playerLocks[key] = true

	local ok, err = pcall(fn, function()
		playerLocks[key] = nil
	end)

	if not ok then
		playerLocks[key] = nil
		ErrorNoHalt("[PlayerDB] " .. tostring(err) .. "\n")
	end
end

local function ReadFallbackFile(storeId)
	local path = PDB.FallbackDir .. storeId .. ".json"

	if not file.Exists(path, "DATA") then
		return {}
	end

	return util.JSONToTable(file.Read(path, "DATA") or "") or {}
end

local function WriteFallbackFile(storeId, data)
	file.CreateDir(PDB.FallbackDir)
	file.Write(PDB.FallbackDir .. storeId .. ".json", util.TableToJSON(data, true))
end

local function GetFallbackRow(storeId, steamID64)
	local store = ReadFallbackFile(storeId)
	return store[steamID64]
end

local function SetFallbackRow(storeId, steamID64, row)
	local store = ReadFallbackFile(storeId)
	store[steamID64] = row
	WriteFallbackFile(storeId, store)
end

function PDB.GetCached(storeId, steamID64)
	EnsureCacheStore(storeId)
	local entry = PDB.Cache[storeId][steamID64]
	return entry and entry.data or nil, entry
end

local function SetCached(storeId, steamID64, data, meta)
	EnsureCacheStore(storeId)

	PDB.Cache[storeId][steamID64] = {
		data = data,
		loaded = meta.loaded ~= false,
		dirty = meta.dirty == true,
		updated_at = tonumber(meta.updated_at) or Now(),
		stored = meta.stored == true,
	}
end

function PDB.EnsureTables()
	if not mysql then return end

	for storeId, store in pairs(PDB.Stores) do
		if store.createSQL then
			mysql:RawQuery(store.createSQL)
		end

		if PDB.IsMySQL() and store.migrateSQL then
			for _, statement in ipairs(store.migrateSQL) do
				mysql:RawQuery(statement)
			end
		end
	end
end

function PDB.Load(storeId, steamID64, callback)
	local store = PDB.Stores[storeId]
	if not store then
		if callback then callback(nil, "unknown_store") end
		return
	end

	local _, cachedEntry = PDB.GetCached(storeId, steamID64)
	if cachedEntry and cachedEntry.loaded then
		if callback then callback(cachedEntry.data) end
		return
	end

	local lockKey = storeId .. ":" .. steamID64

	if loadWaiters[lockKey] then
		if callback then
			loadWaiters[lockKey][#loadWaiters[lockKey] + 1] = callback
		end
		return
	end

	loadWaiters[lockKey] = callback and { callback } or {}

	WithLock(lockKey, function(release)
		local function finishAll(data, err)
			local waiters = loadWaiters[lockKey] or {}
			loadWaiters[lockKey] = nil
			release()

			for _, cb in ipairs(waiters) do
				cb(data, err)
			end
		end

		local _, entry = PDB.GetCached(storeId, steamID64)
		if entry and entry.loaded then
			finishAll(entry.data)
			return
		end

		local function finish(data, err)
			finishAll(data, err)
		end

		if PDB.IsMySQL() then
			local escapedID = mysql:Escape(steamID64)
			local selectSQL = string.format(store.selectSQL, store.table, escapedID)

			mysql:RawQuery(selectSQL, function(result)
				local row = istable(result) and result[1] or nil

				if row then
					local data = store.parseRow(row)
					SetCached(storeId, steamID64, data, {
						loaded = true,
						dirty = false,
						updated_at = data.updated_at or Now(),
						stored = true,
					})
					finish(data)
					return
				end

				local defaults = store.defaults(steamID64)
				defaults.updated_at = Now()

				local upsertSQL = (store.buildUpsertSQL or store.buildInsertSQL)(steamID64, defaults)
				mysql:RawQuery(upsertSQL, function()
					mysql:RawQuery(selectSQL, function(result2)
						local row2 = istable(result2) and result2[1] or nil

						if row2 then
							local data = store.parseRow(row2)
							SetCached(storeId, steamID64, data, {
								loaded = true,
								dirty = false,
								updated_at = data.updated_at or Now(),
								stored = true,
							})
							finish(data)
							return
						end

						SetCached(storeId, steamID64, defaults, {
							loaded = true,
							dirty = false,
							updated_at = defaults.updated_at,
							stored = true,
						})
						finish(defaults)
					end)
				end)
			end)

			return
		end

		local row = GetFallbackRow(storeId, steamID64)

		if row then
			local data = store.parseRow(row)
			SetCached(storeId, steamID64, data, {
				loaded = true,
				dirty = false,
				updated_at = data.updated_at or Now(),
				stored = true,
			})
			finish(data)
		else
			local defaults = store.defaults(steamID64)
			defaults.updated_at = Now()
			SetFallbackRow(storeId, steamID64, store.serialize(defaults))
			SetCached(storeId, steamID64, defaults, {
				loaded = true,
				dirty = false,
				updated_at = defaults.updated_at,
				stored = true,
			})
			finish(defaults)
		end
	end)
end

function PDB.Save(storeId, steamID64, callback)
	local store = PDB.Stores[storeId]
	if not store then
		if callback then callback(false, "unknown_store") end
		return
	end

	local cached, entry = PDB.GetCached(storeId, steamID64)
	if not cached or not entry then
		if callback then callback(false, "not_loaded") end
		return
	end

	local lockKey = storeId .. ":" .. steamID64 .. ":save"

	WithLock(lockKey, function(release)
		local data = table.Copy(cached)
		data.updated_at = Now()

		local function finish(ok, err)
			if ok then
				SetCached(storeId, steamID64, data, {
					loaded = true,
					dirty = false,
					updated_at = data.updated_at,
					stored = true,
				})
			end

			release()
			if callback then callback(ok, err) end
		end

		if PDB.IsMySQL() then
			local buildSQL = entry.stored and store.buildUpdateSQL or (store.buildUpsertSQL or store.buildInsertSQL)
			mysql:RawQuery(buildSQL(steamID64, data), function()
				finish(true)
			end)
			return
		end

		SetFallbackRow(storeId, steamID64, store.serialize(data))
		finish(true)
	end)
end

function PDB.Set(storeId, steamID64, partial, opts)
	opts = opts or {}

	local cached = PDB.GetCached(storeId, steamID64)
	local data = table.Copy(cached or PDB.Stores[storeId].defaults(steamID64))

	for key, value in pairs(partial or {}) do
		data[key] = value
	end

	SetCached(storeId, steamID64, data, {
		loaded = true,
		dirty = true,
		updated_at = Now(),
		stored = cached ~= nil,
	})

	if opts.save ~= false then
		PDB.Save(storeId, steamID64, opts.callback)
	end

	return data
end

function PDB.Refresh(storeId, steamID64, callback)
	local _, entry = PDB.GetCached(storeId, steamID64)

	if entry and entry.dirty then
		PDB.Save(storeId, steamID64, function()
			PDB.Load(storeId, steamID64, callback)
		end)
		return
	end

	PDB.Load(storeId, steamID64, callback)
end

function PDB.RefreshSync(storeId, steamID64, timeout)
	local done, result = false, nil
	timeout = timeout or 2

	PDB.Refresh(storeId, steamID64, function(data)
		done = true
		result = data
	end)

	local deadline = SysTime() + timeout
	while not done and SysTime() < deadline do
		if mysql and mysql.Think then mysql:Think() end
	end

	return result or PDB.GetCached(storeId, steamID64)
end

function PDB.LoadSync(storeId, steamID64, timeout)
	local cached, entry = PDB.GetCached(storeId, steamID64)
	if cached and entry and entry.loaded then return cached end

	return PDB.RefreshSync(storeId, steamID64, timeout)
end

function PDB.RawQuery(sql, callback)
	if PDB.IsMySQL() then
		mysql:RawQuery(sql, callback)
	elseif callback then
		callback(nil, false)
	end
end

hook.Add("DatabaseConnected", "HG_PlayerDB_Init", function()
	PDB.MySQLActive = true
	PDB.EnsureTables()
	hook.Run("HG_PlayerDBReady")
end)

hook.Add("DatabaseConnectionFailed", "HG_PlayerDB_Fallback", function()
	PDB.MySQLActive = false
	MsgN("[PlayerDB] MySQL unavailable; using local JSON fallback storage.")
end)

hook.Add("PlayerInitialSpawn", "HG_PlayerDB_Preload", function(ply)
	local steamID64 = ply:SteamID64()

	for storeId in pairs(PDB.Stores) do
		PDB.Load(storeId, steamID64, function(data)
			if not IsValid(ply) then return end
			hook.Run("HG_PlayerDBLoaded", ply, storeId, data)
		end)
	end
end)

hook.Add("PlayerDisconnected", "HG_PlayerDB_Flush", function(ply)
	local steamID64 = ply:SteamID64()

	for storeId in pairs(PDB.Stores) do
		local _, entry = PDB.GetCached(storeId, steamID64)
		if entry and entry.dirty then
			PDB.Save(storeId, steamID64)
		end
	end
end)

timer.Create("HG_PlayerDB_PeriodicRefresh", refreshInterval, 0, function()
	for _, ply in player.Iterator() do
		if not IsValid(ply) then continue end

		local steamID64 = ply:SteamID64()

		for storeId in pairs(PDB.Stores) do
			local _, entry = PDB.GetCached(storeId, steamID64)
			if entry and not entry.dirty and entry.loaded then
				PDB.Refresh(storeId, steamID64, function(data)
					if not IsValid(ply) or not data then return end
					hook.Run("HG_PlayerDBSynced", ply, storeId, data)
				end)
			end
		end
	end
end)

hook.Add("ShutDown", "HG_PlayerDB_ShutdownFlush", function()
	for _, ply in player.Iterator() do
		local steamID64 = ply:SteamID64()

		for storeId in pairs(PDB.Stores) do
			local _, entry = PDB.GetCached(storeId, steamID64)
			if entry and entry.dirty then
				PDB.Save(storeId, steamID64)
			end
		end
	end
end)
