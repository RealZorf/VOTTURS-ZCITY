--
zb = zb or {}

zb.Experience = zb.Experience or {}
zb.Experience.PlayerInstances = zb.Experience.PlayerInstances or {}
zb.Experience.Active = zb.Experience.Active or false

local function defaultExperienceStats()
	return {
		skill = 0,
		experience = 0,
		deaths = 0,
		kills = 0,
		suicides = 0,
	}
end

function zb.Experience.EnsurePlayerInstance(steamID64)
	if not isstring(steamID64) or steamID64 == "" then return nil end

	local inst = zb.Experience.PlayerInstances[steamID64]
	if not istable(inst) or inst.experience == nil then
		inst = defaultExperienceStats()
		zb.Experience.PlayerInstances[steamID64] = inst
	else
		inst.skill = inst.skill or 0
		inst.experience = inst.experience or 0
		inst.deaths = inst.deaths or 0
		inst.kills = inst.kills or 0
		inst.suicides = inst.suicides or 0
	end

	return inst
end

hook.Add("DatabaseConnected", "ExperienceCreateData", function()
	if ZCITY_DB and ZCITY_DB.IsReady and ZCITY_DB:IsReady() then
		zb.Experience.Active = true
		return
	end

	if not mysql or not isfunction(mysql.Create) then return end

	local query = mysql:Create("zb_experience")
	query:Create("steamid", "VARCHAR(20) NOT NULL")
	query:Create("steam_name", "VARCHAR(32) NOT NULL")
	query:Create("skill", "FLOAT NOT NULL")
	query:Create("experience", "INT NOT NULL")
	query:Create("deaths", "INT NOT NULL")
	query:Create("kills", "INT NOT NULL")
	query:Create("suicides", "INT NOT NULL")
	query:PrimaryKey("steamid")
	query:Execute()

	zb.Experience.Active = true
end)

hook.Add("ZCITY_DatabaseReady", "ExperienceActivate", function()
	zb.Experience.Active = ZCITY_DB and ZCITY_DB.IsReady and ZCITY_DB:IsReady() or zb.Experience.Active

	if not zb.Experience.Active then return end

	for _, ply in player.Iterator() do
		if not IsValid(ply) or not ply:IsPlayer() or ply:IsBot() then continue end

		if ZCITY_DB and ZCITY_DB.UsesUnifiedPlayerLoad and ZCITY_DB.UsesUnifiedPlayerLoad() then
			ZCITY_DB.ProfileLoadedSession[ply:SteamID64()] = nil
			ZCITY_DB.LoadPlayerProfile(ply)
		else
			hook.Run("ZB_Exp_ReloadPlayer", ply)
		end
	end
end)

hook.Add("ZB_Exp_ReloadPlayer", "ZB_Exp_ReloadPlayerQuery", function(ply)
	if not IsValid(ply) then return end

	local name = ply:Name()
	local steamID64 = ply:SteamID64()

	local query = mysql:Select("zb_experience")
	query:Select("skill")
	query:Select("experience")
	query:Select("deaths")
	query:Select("kills")
	query:Select("suicides")
	query:Where("steamid", steamID64)
	query:Callback(function(result)
		if not IsValid(ply) then return end

		zb.Experience.PlayerInstances[steamID64] = zb.Experience.PlayerInstances[steamID64] or {}

		if istable(result) and #result > 0 then
			zb.Experience.PlayerInstances[steamID64].skill = tonumber(result[1].skill) or 0
			zb.Experience.PlayerInstances[steamID64].experience = tonumber(result[1].experience) or 0
			zb.Experience.PlayerInstances[steamID64].deaths = tonumber(result[1].deaths) or 0
			zb.Experience.PlayerInstances[steamID64].kills = tonumber(result[1].kills) or 0
			zb.Experience.PlayerInstances[steamID64].suicides = tonumber(result[1].suicides) or 0
		end
	end)
	query:Execute()
end)

--local query = mysql:Drop("zb_experience")
--query:Execute()

function zb.Experience.ApplyJoinRow(ply, row, createIfMissing)
	if not IsValid(ply) or not ply:IsPlayer() or ply:IsBot() then return end
	if not zb.Experience.Active then
		zb.Experience.PlayerInstances[ply:SteamID64()] = {}
		return
	end

	local name = ply:Name()
	local steamID64 = ply:SteamID64()
	local hasRow = istable(row) and row.experience ~= nil

	if hasRow then
		zb.Experience.PlayerInstances[steamID64] = {
			skill = tonumber(row.skill) or 0,
			experience = tonumber(row.experience) or 0,
			deaths = tonumber(row.deaths) or 0,
			kills = tonumber(row.kills) or 0,
			suicides = tonumber(row.suicides) or 0,
		}
		return
	end

	if not createIfMissing then return end

	zb.Experience.PlayerInstances[steamID64] = {
		skill = 0,
		experience = 0,
		deaths = 0,
		kills = 0,
		suicides = 0,
	}

	local insertQuery = mysql:Insert("zb_experience")
	insertQuery:Insert("steamid", steamID64)
	insertQuery:Insert("steam_name", name)
	insertQuery:Insert("skill", 0)
	insertQuery:Insert("experience", 0)
	insertQuery:Insert("deaths", 0)
	insertQuery:Insert("kills", 0)
	insertQuery:Insert("suicides", 0)
	insertQuery:Execute()
end

hook.Add("PlayerInitialSpawn", "ZB_Exp_OnInitSpawn", function(ply)
	if ZCITY_DB and ZCITY_DB.UsesUnifiedPlayerLoad and ZCITY_DB.UsesUnifiedPlayerLoad() and not ply.ZCITY_LegacyProfileLoad then return end

	if not zb.Experience.Active then
		zb.Experience.PlayerInstances[ply:SteamID64()] = {}
		return
	end

	local name = ply:Name()
	local steamID64 = ply:SteamID64()

	local query = mysql:Select("zb_experience")
	query:Select("skill")
	query:Select("experience")
	query:Select("deaths")
	query:Select("kills")
	query:Select("suicides")
	query:Where("steamid", steamID64)
	query:Callback(function(result)
		if not IsValid(ply) then return end

		if istable(result) and #result > 0 and result[1].experience ~= nil then
			local updateQuery = mysql:Update("zb_experience")
			updateQuery:Update("steam_name", name)
			updateQuery:Where("steamid", steamID64)
			updateQuery:Execute()
		end

		zb.Experience.ApplyJoinRow(ply, istable(result) and #result > 0 and result[1] or nil, true)
	end)
	query:Execute()
end)

local plyMeta = FindMetaTable("Player")

function plyMeta:GetExp()
	local inst = zb.Experience.PlayerInstances[self:SteamID64()]
	return math.Round(inst and inst.experience or 0)
end

function plyMeta:GiveExp( ammout )

    local steamID64 = self:SteamID64()

    if !zb.Experience or !zb.Experience.PlayerInstances or !zb.Experience.PlayerInstances[steamID64] then return end

    zb.Experience.PlayerInstances[steamID64].experience =  math.max( (zb.Experience.PlayerInstances[steamID64].experience or 0) + ammout, 0 )

	if ZCITY_DB and ZCITY_DB.QueueExperienceSave then
		ZCITY_DB.QueueExperienceSave(steamID64)
	else
		local updateQuery = mysql:Update("zb_experience")
			updateQuery:Update("experience", self:GetExp(),0)
			updateQuery:Where("steamid", steamID64)
		updateQuery:Execute()
	end

    local points = math.min(ammout / 5, 10) * (1 + (self.EA_HasAccess and self:EA_HasAccess() and 2 or 0))
    local mul = math.min(player.GetCount() / 10, 1)
    if self.PS_AddPoints and self.GetPointshopVars and self:GetPointshopVars() then
        self:PS_AddPoints(math.Round(points * mul, 0))
    end
    --self:SetNWInt( "experience", exp + ammout )
end


function plyMeta:GetSkill()
	local inst = zb.Experience.PlayerInstances[self:SteamID64()]
	return inst and inst.skill or 0
end

function plyMeta:GiveSkill( ammout )
    local steamID64 = self:SteamID64()

    if not zb.Experience.Active then
        zb.Experience.PlayerInstances[steamID64] = {}
        return
    end

	local inst = zb.Experience.EnsurePlayerInstance(steamID64)
	inst.skill = math.max((inst.skill or 0) + ammout, 0)

	if ZCITY_DB and ZCITY_DB.QueueExperienceSave then
		ZCITY_DB.QueueExperienceSave(steamID64)
	else
		local updateQuery = mysql:Update("zb_experience")
			updateQuery:Update("skill", self:GetSkill())
			updateQuery:Where("steamid", steamID64)
		updateQuery:Execute()
	end
    --self:SetNWFloat( "skill", skill + ammout )
    
end

function plyMeta:GetDeaths()
	local inst = zb.Experience.PlayerInstances[self:SteamID64()]
	return inst and inst.deaths or 0
end

function plyMeta:GiveDeaths( ammout )
    local steamID64 = self:SteamID64()

    if not zb.Experience.Active then
        zb.Experience.PlayerInstances[steamID64] = {}
        return
    end

	local inst = zb.Experience.EnsurePlayerInstance(steamID64)
	inst.deaths = math.max((inst.deaths or 0) + ammout, 0)

	if ZCITY_DB and ZCITY_DB.QueueExperienceSave then
		ZCITY_DB.QueueExperienceSave(steamID64)
	else
		local updateQuery = mysql:Update("zb_experience")
			updateQuery:Update("deaths", self:GetDeaths())
			updateQuery:Where("steamid", steamID64)
		updateQuery:Execute()
	end
    --self:SetNWInt( "experience", exp + ammout )
end

function plyMeta:GetKills()

    return zb.Experience.PlayerInstances[self:SteamID64()].kills or 0

end

function plyMeta:GiveKills( ammout )
    local steamID64 = self:SteamID64()

    if not zb.Experience.Active then
        zb.Experience.PlayerInstances[steamID64] = {}
        return
    end

	local inst = zb.Experience.EnsurePlayerInstance(steamID64)
	inst.kills = math.max((inst.kills or 0) + ammout, 0)

	if ZCITY_DB and ZCITY_DB.QueueExperienceSave then
		ZCITY_DB.QueueExperienceSave(steamID64)
	else
		local updateQuery = mysql:Update("zb_experience")
			updateQuery:Update("kills", self:GetKills())
			updateQuery:Where("steamid", steamID64)
		updateQuery:Execute()
	end
    --self:SetNWInt( "experience", exp + ammout )
end


function plyMeta:GetSuicides( ammout )
	local inst = zb.Experience.PlayerInstances[self:SteamID64()]
	return inst and inst.suicides or 0
end

function plyMeta:GiveSuicides( ammout )
    local steamID64 = self:SteamID64()

    if not zb.Experience.Active then
        zb.Experience.PlayerInstances[steamID64] = {}
        return
    end

	local inst = zb.Experience.EnsurePlayerInstance(steamID64)
	inst.suicides = math.max((inst.suicides or 0) + ammout, 0)

	if ZCITY_DB and ZCITY_DB.QueueExperienceSave then
		ZCITY_DB.QueueExperienceSave(steamID64)
	else
		local updateQuery = mysql:Update("zb_experience")
			updateQuery:Update("suicides", self:GetSuicides())
			updateQuery:Where("steamid", steamID64)
		updateQuery:Execute()
	end
    --self:SetNWInt( "experience", exp + ammout )
end


util.AddNetworkString("zb_xp_get")

net.Receive("zb_xp_get",function(len,ply)

    local steamID64 = ply:SteamID64()

    if not zb.Experience.Active then
        zb.Experience.PlayerInstances[steamID64] = {}
        return
    end 

    local get_ply = net.ReadEntity()

    net.Start("zb_xp_get")
        --print( ply:GetExp() )
        net.WriteEntity( get_ply )
        net.WriteFloat( get_ply:GetSkill() )
        net.WriteInt( get_ply:GetExp(), 19 )
    net.Send(ply)

end)


local function adminAdjustExperience(callingPly, targetPly, field, mode, amount)
	if not IsValid(targetPly) or not targetPly:IsPlayer() or targetPly:IsBot() then
		return false, "invalid target"
	end

	if not zb.Experience.Active then
		return false, "experience system inactive"
	end

	local steamID64 = targetPly:SteamID64()
	local inst = zb.Experience.EnsurePlayerInstance(steamID64)
	amount = math.floor(tonumber(amount) or 0)

	local before = tonumber(inst[field]) or 0
	local after = before

	if mode == "set" then
		after = math.max(0, amount)
	elseif mode == "add" then
		after = math.max(0, before + amount)
	elseif mode == "remove" then
		after = math.max(0, before - amount)
	else
		return false, "invalid mode"
	end

	inst[field] = after

	if ZCITY_DB and ZCITY_DB.SaveExperienceData then
		local ok, err = ZCITY_DB.SaveExperienceData(steamID64, targetPly:Name(), true)
		if ZCITY_DB.LogPersist then
			ZCITY_DB.LogPersist("admin " .. field .. " " .. mode, steamID64, "before=" .. before .. " after=" .. after, ok ~= false, err)
		end
		if not ok and IsValid(callingPly) then
			callingPly:ChatPrint("[Experience] Database save failed: " .. tostring(err or "unknown"))
		end
		return ok ~= false, err
	end

	return true
end

local function registerExperienceULXCommands()
	if not ulx or not ULib then return end

	local CATEGORY = "Z-City"

	local function ulxSetExp(calling_ply, target_plys, amount)
		for _, target in ipairs(target_plys) do
			adminAdjustExperience(calling_ply, target, "experience", "set", amount)
		end
		ulx.fancyLogAdmin(calling_ply, "#A set #T's experience to #i", target_plys, amount)
	end

	local setExpCmd = ulx.command(CATEGORY, "ulx setexperience", ulxSetExp, "!setexp")
	setExpCmd:addParam({type = ULib.cmds.PlayersArg})
	setExpCmd:addParam({type = ULib.cmds.NumArg, min = 0, hint = "experience"})
	setExpCmd:defaultAccess(ULib.ACCESS_ADMIN)
	setExpCmd:help("Set a player's experience. Saves immediately to the shared database.")

	local function ulxAddExp(calling_ply, target_plys, amount)
		for _, target in ipairs(target_plys) do
			adminAdjustExperience(calling_ply, target, "experience", "add", amount)
		end
		ulx.fancyLogAdmin(calling_ply, "#A added #i experience to #T", amount, target_plys)
	end

	local addExpCmd = ulx.command(CATEGORY, "ulx addexperience", ulxAddExp, "!addexp")
	addExpCmd:addParam({type = ULib.cmds.PlayersArg})
	addExpCmd:addParam({type = ULib.cmds.NumArg, min = 0, hint = "amount"})
	addExpCmd:defaultAccess(ULib.ACCESS_ADMIN)
	addExpCmd:help("Add experience to a player. Saves immediately to the shared database.")

	local function ulxRemoveExp(calling_ply, target_plys, amount)
		for _, target in ipairs(target_plys) do
			adminAdjustExperience(calling_ply, target, "experience", "remove", amount)
		end
		ulx.fancyLogAdmin(calling_ply, "#A removed #i experience from #T", amount, target_plys)
	end

	local removeExpCmd = ulx.command(CATEGORY, "ulx removeexperience", ulxRemoveExp, "!removeexp")
	removeExpCmd:addParam({type = ULib.cmds.PlayersArg})
	removeExpCmd:addParam({type = ULib.cmds.NumArg, min = 0, hint = "amount"})
	removeExpCmd:defaultAccess(ULib.ACCESS_ADMIN)
	removeExpCmd:help("Remove experience from a player. Saves immediately to the shared database.")

	MsgC(Color(100, 255, 100), "[Experience] ULX commands registered.\n")
end

timer.Simple(0, registerExperienceULXCommands)
hook.Add("InitPostEntity", "Experience_RegisterULX", registerExperienceULXCommands)

--hook.Add( "ZB_EndRound", "ZB_Exp_Give", function()
--    local exp = ply.RoundEXP or 0
--    local skill = ply.RoundSkill or 0
--
--    ply:SetPData( "zb_experience", exp )
--    ply:SetPData( "zb_skill", skill )
--
--    ply:SetNWInt( "experience", exp )
--    ply:SetNWFloat( "skill", skill )
--
--    ply.RoundEXP = 0
--    ply.RoundSkill = 0
--end)
