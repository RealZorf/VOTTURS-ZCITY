--
zb = zb or {}

zb.Experience = zb.Experience or {}
zb.Experience.PlayerInstances = zb.Experience.PlayerInstances or {}
zb.Experience.Active = zb.Experience.Active or false

local function SyncExperienceCache(steamID64, data)
	zb.Experience.PlayerInstances[steamID64] = {
		skill = tonumber(data.skill) or 0,
		experience = tonumber(data.experience) or 0,
		deaths = tonumber(data.deaths) or 0,
		kills = tonumber(data.kills) or 0,
		suicides = tonumber(data.suicides) or 0,
	}
end

local function SaveExperienceField(ply, partial)
	if not IsValid(ply) then return end

	local steamID64 = ply:SteamID64()

	if hg.PlayerDB then
		partial.steam_name = ply:Name()
		hg.PlayerDB.Set("experience", steamID64, partial)
		SyncExperienceCache(steamID64, hg.PlayerDB.GetCached("experience", steamID64) or partial)
		return
	end

	if not zb.Experience.Active then return end

	for key, value in pairs(partial) do
		zb.Experience.PlayerInstances[steamID64][key] = value
	end

	local updateQuery = mysql:Update("zb_experience")
	for key, value in pairs(partial) do
		updateQuery:Update(key, value)
	end
	updateQuery:Where("steamid", steamID64)
	updateQuery:Execute()
end

hook.Add("DatabaseConnected", "ExperienceCreateData", function()
	zb.Experience.Active = hg.PlayerDB and hg.PlayerDB.IsMySQL() or false
end)

hook.Add("PlayerInitialSpawn", "ZB_Exp_OnInitSpawn", function(ply)
	if hg.PlayerDB then return end

	local name = ply:Name()
	local steamID64 = ply:SteamID64()

	if not zb.Experience.Active then
		zb.Experience.PlayerInstances[steamID64] = {
			skill = 0,
			experience = 0,
			deaths = 0,
			kills = 0,
			suicides = 0,
		}
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
			if istable(result) and #result > 0 then
				SyncExperienceCache(steamID64, result[1])
			else
				SyncExperienceCache(steamID64, {
					skill = 0,
					experience = 0,
					deaths = 0,
					kills = 0,
					suicides = 0,
				})
			end
		end)
	query:Execute()
end)

local plyMeta = FindMetaTable("Player")

function plyMeta:GetExp()
	local data = zb.Experience.PlayerInstances[self:SteamID64()]
	return math.Round(data and data.experience or 0)
end

function plyMeta:GiveExp(ammout)
	local steamID64 = self:SteamID64()
	local data = zb.Experience.PlayerInstances[steamID64]
	if not data then return end

	local newExp = math.max((data.experience or 0) + ammout, 0)
	SaveExperienceField(self, { experience = newExp })

	local points = math.min(ammout / 5, 10) * (1 + (self.EA_HasAccess and self:EA_HasAccess() and 2 or 0))
	local mul = math.min(player.GetCount() / 10, 1)
	self:PS_AddPoints(math.Round(points * mul, 0))
end

function plyMeta:GetSkill()
	return zb.Experience.PlayerInstances[self:SteamID64()] and zb.Experience.PlayerInstances[self:SteamID64()].skill or 0
end

function plyMeta:GiveSkill(ammout)
	local steamID64 = self:SteamID64()
	local data = zb.Experience.PlayerInstances[steamID64]
	if not data then return end

	SaveExperienceField(self, { skill = math.max((data.skill or 0) + ammout, 0) })
end

function plyMeta:GetDeaths()
	return zb.Experience.PlayerInstances[self:SteamID64()] and zb.Experience.PlayerInstances[self:SteamID64()].deaths or 0
end

function plyMeta:GiveDeaths(ammout)
	local data = zb.Experience.PlayerInstances[self:SteamID64()]
	if not data then return end

	SaveExperienceField(self, { deaths = math.max((data.deaths or 0) + ammout, 0) })
end

function plyMeta:GetKills()
	return zb.Experience.PlayerInstances[self:SteamID64()] and zb.Experience.PlayerInstances[self:SteamID64()].kills or 0
end

function plyMeta:GiveKills(ammout)
	local data = zb.Experience.PlayerInstances[self:SteamID64()]
	if not data then return end

	SaveExperienceField(self, { kills = math.max((data.kills or 0) + ammout, 0) })
end

function plyMeta:GetSuicides()
	return zb.Experience.PlayerInstances[self:SteamID64()] and zb.Experience.PlayerInstances[self:SteamID64()].suicides or 0
end

function plyMeta:GiveSuicides(ammout)
	local data = zb.Experience.PlayerInstances[self:SteamID64()]
	if not data then return end

	SaveExperienceField(self, { suicides = math.max((data.suicides or 0) + ammout, 0) })
end

util.AddNetworkString("zb_xp_get")

net.Receive("zb_xp_get", function(len, ply)
	local get_ply = net.ReadEntity()
	if not IsValid(get_ply) then return end

	net.Start("zb_xp_get")
		net.WriteEntity(get_ply)
		net.WriteFloat(get_ply:GetSkill())
		net.WriteInt(get_ply:GetExp(), 19)
	net.Send(ply)
end)

hook.Add("HG_PlayerDBSynced", "ZB_ExperienceResync", function(ply, storeId, data)
	if storeId ~= "experience" or not IsValid(ply) then return end
	SyncExperienceCache(ply:SteamID64(), data)
end)
