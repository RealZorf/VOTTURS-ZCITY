--
zb = zb or {}

zb.Experience = zb.Experience or {}
zb.Experience.PlayerInstances = zb.Experience.PlayerInstances or {}
zb.Experience.Active = zb.Experience.Active or false

hook.Add("ZCITY_DatabaseReady", "ExperienceActivate", function()
	zb.Experience.Active = ZCITY_DB and ZCITY_DB.IsReady and ZCITY_DB:IsReady() or zb.Experience.Active

	if not zb.Experience.Active then return end

	for _, ply in player.Iterator() do
		if IsValid(ply) and ply:IsPlayer() and not ply:IsBot() then
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

hook.Add( "PlayerInitialSpawn","ZB_Exp_OnInitSpawn", function( ply )
    local name = ply:Name()
	local steamID64 = ply:SteamID64()

    if not zb.Experience.Active then
        zb.Experience.PlayerInstances[steamID64] = {}
        return
    end 

	local query = mysql:Select("zb_experience")
		query:Select("skill")
		query:Select("experience")
        query:Select("deaths")
        query:Select("kills")
        query:Select("suicides")
		query:Where("steamid", steamID64)
		query:Callback(function(result)
			if (IsValid(ply) and istable(result) and #result > 0 and result[1].experience) then
				local updateQuery = mysql:Update("zb_experience")
					updateQuery:Update("steam_name", name)
					updateQuery:Where("steamid", steamID64)
				updateQuery:Execute()

				zb.Experience.PlayerInstances[steamID64] = {}

                zb.Experience.PlayerInstances[steamID64].skill = tonumber(result[1].skill)
                zb.Experience.PlayerInstances[steamID64].experience = tonumber(result[1].experience)
                zb.Experience.PlayerInstances[steamID64].deaths = tonumber(result[1].deaths)
                zb.Experience.PlayerInstances[steamID64].kills = tonumber(result[1].kills)
                zb.Experience.PlayerInstances[steamID64].suicides = tonumber(result[1].suicides)

			else
				local insertQuery = mysql:Insert("zb_experience")
					insertQuery:Insert("steamid", steamID64)
					insertQuery:Insert("steam_name", name)
					insertQuery:Insert("skill", 0)
		            insertQuery:Insert("experience", 0)
                    insertQuery:Insert("deaths", 0)
		            insertQuery:Insert("kills", 0)
                    insertQuery:Insert("suicides", 0)
				insertQuery:Execute()

				zb.Experience.PlayerInstances[steamID64] = {}

				zb.Experience.PlayerInstances[steamID64].skill = 0
                zb.Experience.PlayerInstances[steamID64].experience = 0
                zb.Experience.PlayerInstances[steamID64].deaths = 0
                zb.Experience.PlayerInstances[steamID64].kills = 0
                zb.Experience.PlayerInstances[steamID64].suicides = 0

			end
		end)
	query:Execute()

end)

local plyMeta = FindMetaTable("Player")

function plyMeta:GetExp()

    return math.Round(zb.Experience.PlayerInstances[self:SteamID64()].experience) or 0

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
    self:PS_AddPoints(math.Round(points * mul,0))
    --self:SetNWInt( "experience", exp + ammout )
end


function plyMeta:GetSkill()

    return zb.Experience.PlayerInstances[self:SteamID64()].skill or 0

end

function plyMeta:GiveSkill( ammout )

    local steamID64 = self:SteamID64()

    if not zb.Experience.Active then
        zb.Experience.PlayerInstances[steamID64] = {}
        return
    end 


    zb.Experience.PlayerInstances[steamID64].skill = math.max( zb.Experience.PlayerInstances[steamID64].skill + ammout, 0 )

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

    return zb.Experience.PlayerInstances[self:SteamID64()].deaths or 0

end

function plyMeta:GiveDeaths( ammout )

    local steamID64 = self:SteamID64()

    if not zb.Experience.Active then
        zb.Experience.PlayerInstances[steamID64] = {}
        return
    end 


    zb.Experience.PlayerInstances[steamID64].deaths = math.max( zb.Experience.PlayerInstances[steamID64].deaths + ammout, 0 )

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

    zb.Experience.PlayerInstances[steamID64].kills = math.max( zb.Experience.PlayerInstances[steamID64].kills + ammout, 0 )

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

    return zb.Experience.PlayerInstances[self:SteamID64()].suicides or 0

end

function plyMeta:GiveSuicides( ammout )

    local steamID64 = self:SteamID64()

    if not zb.Experience.Active then
        zb.Experience.PlayerInstances[steamID64] = {}
        return
    end 

    zb.Experience.PlayerInstances[steamID64].suicides =  math.max( zb.Experience.PlayerInstances[steamID64].suicides + ammout, 0 )

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
