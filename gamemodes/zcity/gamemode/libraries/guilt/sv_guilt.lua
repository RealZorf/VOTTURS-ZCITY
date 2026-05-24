zb = zb or {}
zb.GuiltSQL = zb.GuiltSQL or {}
zb.GuiltSQL.PlayerInstances = zb.GuiltSQL.PlayerInstances or {}
zb.GuiltSQL.Active = zb.GuiltSQL.Active or false
zb.GuiltSQL.DefaultKarma = zb.GuiltSQL.DefaultKarma or 100

local Guilt = zb.GuiltSQL

local function getKarmaMax()
	return (zb and zb.MaxKarma) or 120
end

local function clampKarma(value)
	return math.Clamp(tonumber(value) or Guilt.DefaultKarma, 0, getKarmaMax())
end

local function logKarmaAdmin(action, callingPly, targetPly, before, after, amount, dbOk, dbErr)
	local adminName = IsValid(callingPly) and callingPly:Nick() or "Console"
	local adminId = IsValid(callingPly) and (callingPly:SteamID64() or "unknown") or "console"
	local targetName = IsValid(targetPly) and targetPly:Nick() or "Unknown"
	local targetId = IsValid(targetPly) and (targetPly:SteamID64() or "unknown") or "unknown"
	local dbStatus = dbOk and "saved" or ("FAILED (" .. tostring(dbErr or "unknown") .. ")")

	MsgC(
		Color(100, 200, 255),
		string.format(
			"[GuiltSQL] %s | admin=%s (%s) | target=%s (%s) | before=%s after=%s amount=%s | db=%s\n",
			tostring(action),
			adminName,
			adminId,
			targetName,
			targetId,
			tostring(before),
			tostring(after),
			tostring(amount or ""),
			dbStatus
		)
	)
end

function Guilt.ApplyToPlayer(ply, value)
	if not IsValid(ply) or not ply:IsPlayer() or ply:IsBot() then return end

	value = clampKarma(value)
	ply.Karma = value

	if ply.SetNetVar then
		ply:SetNetVar("Karma", value)
	elseif ply.SetLocalVar then
		ply:SetLocalVar("Karma", value)
	end

	if ply.SetNWFloat then
		ply:SetNWFloat("Karma", value)
	end
end

function Guilt.SyncInstanceFromPlayer(ply)
	if not IsValid(ply) or not ply:IsPlayer() or ply:IsBot() then return end

	local steamID64 = ply:SteamID64()
	local inst = Guilt.EnsureInstance(steamID64)
	local value

	if istable(inst) and inst.value ~= nil then
		value = clampKarma(inst.value)
	elseif ply.Karma ~= nil then
		value = clampKarma(ply.Karma)
	else
		value = clampKarma(Guilt.DefaultKarma)
	end

	inst.value = value
	inst.loaded = true
	inst.pending = nil
	ply.Karma = value

	return value
end

function Guilt.SyncInstanceFromGameplay(ply, karma)
	if not IsValid(ply) or not ply:IsPlayer() or ply:IsBot() then return end

	local value = clampKarma(karma)
	local inst = Guilt.EnsureInstance(ply:SteamID64())
	inst.value = value
	inst.loaded = true
	inst.pending = nil
	ply.Karma = value

	return value
end

function Guilt.PersistFromPlayer(ply, immediate)
	if not IsValid(ply) or not ply:IsPlayer() or ply:IsBot() then return false end

	local value = Guilt.SyncInstanceFromPlayer(ply)
	local steamID64 = ply:SteamID64()

	if ZCITY_DB and ZCITY_DB.SaveGuiltData then
		return ZCITY_DB.SaveGuiltData(steamID64, ply:Name(), value, immediate == true)
	end

	Guilt.QueueSave(steamID64)
	return true
end

function Guilt.EnsureInstance(steamID64)
	if not isstring(steamID64) or steamID64 == "" then return nil end

	local inst = Guilt.PlayerInstances[steamID64]
	if not istable(inst) then
		inst = {loaded = false}
		Guilt.PlayerInstances[steamID64] = inst
	end

	return inst
end

function Guilt.ApplyJoinRow(ply, guiltValue, createIfMissing)
	if not IsValid(ply) or not ply:IsPlayer() or ply:IsBot() then return end

	local steamID64 = ply:SteamID64()
	if not steamID64 or steamID64 == "" or steamID64 == "0" then return end

	if not Guilt.Active then
		Guilt.ApplyToPlayer(ply, Guilt.DefaultKarma)
		return
	end

	if guiltValue ~= nil then
		local value = clampKarma(guiltValue)
		Guilt.PlayerInstances[steamID64] = {value = value, loaded = true}
		Guilt.ApplyToPlayer(ply, value)
		return
	end

	if not createIfMissing then
		Guilt.PlayerInstances[steamID64] = {loaded = false, pending = true}
		return
	end

	local value = Guilt.DefaultKarma
	Guilt.PlayerInstances[steamID64] = {value = value, loaded = true}
	Guilt.ApplyToPlayer(ply, value)

	if ZCITY_DB and ZCITY_DB.SaveGuiltData then
		ZCITY_DB.SaveGuiltData(steamID64, ply:Name(), value, true)
		return
	end

	if not mysql or not isfunction(mysql.Insert) then return end

	local insertQuery = mysql:Insert("zb_guilt")
	insertQuery:Insert("steamid", steamID64)
	insertQuery:Insert("steam_name", ply:Name())
	insertQuery:Insert("value", value)
	insertQuery:Execute()
end

function Guilt.QueueSave(steamID64)
	if ZCITY_DB and ZCITY_DB.SaveGuiltData then
		local inst = Guilt.PlayerInstances[steamID64]
		if not istable(inst) or inst.value == nil then return end

		ZCITY_DB.SaveGuiltData(steamID64, nil, inst.value, false)
		return
	end

	if not Guilt.Active or not mysql or not isfunction(mysql.Update) then return end

	local inst = Guilt.PlayerInstances[steamID64]
	if not istable(inst) or inst.loaded ~= true or inst.value == nil then return end

	local updateQuery = mysql:Update("zb_guilt")
	updateQuery:Update("value", inst.value)
	updateQuery:Where("steamid", steamID64)
	updateQuery:Execute()
end

function Guilt.SetPlayerKarma(ply, value, options)
	if not IsValid(ply) or not ply:IsPlayer() or ply:IsBot() then return false, "invalid player" end

	options = istable(options) and options or {}
	local skipSave = options.skipSave == true
	local immediate = options.immediate == true

	local steamID64 = ply:SteamID64()
	value = clampKarma(value)

	local inst = Guilt.EnsureInstance(steamID64)
	inst.value = value
	inst.loaded = true
	inst.pending = nil

	Guilt.ApplyToPlayer(ply, value)

	if skipSave then
		return true
	end

	if ZCITY_DB and ZCITY_DB.SaveGuiltData then
		local ok, err = ZCITY_DB.SaveGuiltData(steamID64, ply:Name(), value, immediate)
		if not ok and immediate then
			return false, err or "database save failed"
		end
		return ok ~= false, err
	end

	Guilt.QueueSave(steamID64)
	return true
end

function Guilt.AdminAdjustKarma(callingPly, targetPly, mode, amount)
	if not IsValid(targetPly) or not targetPly:IsPlayer() or targetPly:IsBot() then
		return false, "invalid target"
	end

	amount = math.floor(tonumber(amount) or 0)
	local before = targetPly:GetKarma()
	local after = before

	if mode == "set" then
		after = clampKarma(amount)
	elseif mode == "add" then
		after = clampKarma(before + amount)
	elseif mode == "remove" then
		after = clampKarma(before - amount)
	else
		return false, "invalid mode"
	end

	local ok, err = Guilt.SetPlayerKarma(targetPly, after, {immediate = true})
	logKarmaAdmin(mode, callingPly, targetPly, before, after, amount, ok, err)

	if ZCITY_DB and ZCITY_DB.LogPersist then
		ZCITY_DB.LogPersist("admin karma " .. mode, targetPly:SteamID64(), "after=" .. tostring(after), ok, err)
	end

	if not ok then
		if IsValid(callingPly) then
			callingPly:ChatPrint("[Karma] Database save failed: " .. tostring(err or "unknown error"))
		end
		return false, err
	end

	return true, after, before
end

local function onGuiltPlayerInitialSpawn(ply)
	if ZCITY_DB and ZCITY_DB.UsesUnifiedPlayerLoad and ZCITY_DB.UsesUnifiedPlayerLoad() and not ply.ZCITY_LegacyProfileLoad then
		return
	end

	if not Guilt.Active then
		Guilt.ApplyToPlayer(ply, Guilt.DefaultKarma)
		return
	end

	hook.Run("ZB_Guilt_ReloadPlayer", ply)
end

hook.Add("DatabaseConnected", "GuiltCreateData", function()
	if ZCITY_DB and ZCITY_DB.IsReady and ZCITY_DB:IsReady() then
		Guilt.Active = true
		return
	end

	Guilt.Active = mysql ~= nil
end)

hook.Add("ZCITY_DatabaseReady", "GuiltSQL_Activate", function(mysqlReady)
	Guilt.Active = mysqlReady == true and ZCITY_DB and ZCITY_DB.IsReady and ZCITY_DB:IsReady() or false
	if not Guilt.Active then return end

	for _, ply in player.Iterator() do
		if not IsValid(ply) or ply:IsBot() then continue end

		if ZCITY_DB.UsesUnifiedPlayerLoad and ZCITY_DB.UsesUnifiedPlayerLoad() then
			ZCITY_DB.ProfileLoadedSession[ply:SteamID64()] = nil
			ZCITY_DB.LoadPlayerProfile(ply)
		else
			hook.Run("ZB_Guilt_ReloadPlayer", ply)
		end
	end
end)

hook.Add("ZB_Guilt_ReloadPlayer", "GuiltSQL_ReloadQuery", function(ply)
	if not IsValid(ply) or not Guilt.Active then return end

	local steamID64 = ply:SteamID64()
	local query = mysql:Select("zb_guilt")
	query:Select("value")
	query:Where("steamid", steamID64)
	query:Callback(function(result)
		if not IsValid(ply) then return end

		local guiltValue = istable(result) and #result > 0 and result[1].value or nil
		Guilt.ApplyJoinRow(ply, guiltValue, guiltValue == nil)
	end)
	query:Execute()
end)

hook.Add("ZCITY_PlayerProfileLoaded", "GuiltSQL_AfterProfileLoaded", function(ply)
	if not IsValid(ply) or ply:IsBot() then return end

	local inst = Guilt.PlayerInstances[ply:SteamID64()]
	if istable(inst) and inst.loaded == true and inst.value ~= nil then
		Guilt.ApplyToPlayer(ply, inst.value)
	end
end)

hook.Add("PlayerInitialSpawn", "ZB_GuiltSQL", onGuiltPlayerInitialSpawn)
hook.Add("PlayerInitialSpawn", "GuiltSQL_OnJoin", onGuiltPlayerInitialSpawn)

local plyMeta = FindMetaTable("Player")

function plyMeta:guilt_GetValue()
	return self:GetKarma()
end

function plyMeta:guilt_SetValue(value)
	Guilt.SetPlayerKarma(self, value, {immediate = true})
end

function plyMeta:GetKarma()
	local steamID64 = self:SteamID64()
	local inst = Guilt.PlayerInstances[steamID64]
	if istable(inst) and inst.value ~= nil then
		return inst.value
	end

	return self.Karma or Guilt.DefaultKarma
end

function plyMeta:SetKarma(value)
	Guilt.SetPlayerKarma(self, value, {immediate = false})
end

function plyMeta:GiveKarma(amount)
	local current = self:GetKarma()
	Guilt.SetPlayerKarma(self, current + (tonumber(amount) or 0), {immediate = false})
end

local function registerKarmaULXCommands()
	if not ulx or not ULib then return end

	local CATEGORY = "Z-City"

	local function ulxSetKarma(calling_ply, target_plys, amount)
		for _, target in ipairs(target_plys) do
			Guilt.AdminAdjustKarma(calling_ply, target, "set", amount)
		end

		ulx.fancyLogAdmin(calling_ply, "#A set #T's karma to #i", target_plys, amount)
	end

	local setKarmaCmd = ulx.command(CATEGORY, "ulx setkarma", ulxSetKarma, "!setkarma")
	setKarmaCmd:addParam({type = ULib.cmds.PlayersArg})
	setKarmaCmd:addParam({type = ULib.cmds.NumArg, min = 0, max = (zb and zb.MaxKarma) or 120, hint = "karma"})
	setKarmaCmd:defaultAccess(ULib.ACCESS_ADMIN)
	setKarmaCmd:help("Set a player's karma (0-100). Saves immediately to the shared database.")

	local function ulxAddKarma(calling_ply, target_plys, amount)
		for _, target in ipairs(target_plys) do
			Guilt.AdminAdjustKarma(calling_ply, target, "add", amount)
		end

		ulx.fancyLogAdmin(calling_ply, "#A added #i karma to #T", amount, target_plys)
	end

	local addKarmaCmd = ulx.command(CATEGORY, "ulx addkarma", ulxAddKarma, "!addkarma")
	addKarmaCmd:addParam({type = ULib.cmds.PlayersArg})
	addKarmaCmd:addParam({type = ULib.cmds.NumArg, min = 0, hint = "amount"})
	addKarmaCmd:defaultAccess(ULib.ACCESS_ADMIN)
	addKarmaCmd:help("Add karma to a player. Saves immediately to the shared database.")

	local function ulxRemoveKarma(calling_ply, target_plys, amount)
		for _, target in ipairs(target_plys) do
			Guilt.AdminAdjustKarma(calling_ply, target, "remove", amount)
		end

		ulx.fancyLogAdmin(calling_ply, "#A removed #i karma from #T", amount, target_plys)
	end

	local removeKarmaCmd = ulx.command(CATEGORY, "ulx removekarma", ulxRemoveKarma, "!removekarma")
	removeKarmaCmd:addParam({type = ULib.cmds.PlayersArg})
	removeKarmaCmd:addParam({type = ULib.cmds.NumArg, min = 0, hint = "amount"})
	removeKarmaCmd:defaultAccess(ULib.ACCESS_ADMIN)
	removeKarmaCmd:help("Remove karma from a player. Saves immediately to the shared database.")

	MsgC(Color(100, 255, 100), "[GuiltSQL] Karma ULX commands registered.\n")
end

timer.Simple(0, registerKarmaULXCommands)
hook.Add("InitPostEntity", "GuiltSQL_RegisterULX", registerKarmaULXCommands)
