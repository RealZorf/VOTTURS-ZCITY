zb = zb or {}
hg = hg or {}
zb.ROUND_STATE = zb.ROUND_STATE or 0
--0 = players can join, 1 = round is active, 2 = endround

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
AddCSLuaFile("loader.lua")
include("loader.lua")

local zb_voicechat_panel_groups = ConVarExists("zb_voicechat_panel_groups") and GetConVar("zb_voicechat_panel_groups") or CreateConVar(
	"zb_voicechat_panel_groups",
	"superadmin,owner,servermanager,headdeveloper,headadmin,developer,admin,moderator",
	bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY),
	"Comma-separated ULX/ULib groups allowed to always see alive voice panels."
)

local function groupCanSeeVoicePanels(groupName)
	groupName = string.lower(string.Trim(groupName or ""))
	if groupName == "" then return false end

	local allowList = string.Trim((zb_voicechat_panel_groups and zb_voicechat_panel_groups:GetString()) or "")
	if allowList == "" then return false end

	for _, rawGroup in ipairs(string.Explode(",", allowList, false)) do
		local wantedGroup = string.lower(string.Trim(rawGroup or ""))
		if wantedGroup ~= "" and wantedGroup == groupName then
			return true
		end
	end

	return false
end

local function playerCanSeeVoicePanels(ply)
	if not IsValid(ply) then return false end

	local userGroup = (ply.GetUserGroup and ply:GetUserGroup()) or ""
	return groupCanSeeVoicePanels(userGroup)
end

local PLAYER = FindMetaTable("Player")
function PLAYER:CanSpawn()
	return ( CurrentRound and CurrentRound() and CurrentRound().CanSpawn and CurrentRound():CanSpawn(self)) or (zb.ROUND_STATE == 0)
end

util.AddNetworkString("ZB_SpectatePlayer")
util.AddNetworkString("ZB_AdminVoicePanelState")

local adminVoicePanelState = {}

local function sendAdminVoicePanelState(talker, isSpeaking, targets)
	if not IsValid(talker) then return end

	targets = targets or {}
	if #targets == 0 then
		for _, ply in ipairs(player.GetHumans()) do
			if playerCanSeeVoicePanels(ply) then
				targets[#targets + 1] = ply
			end
		end
	end

	if #targets == 0 then return end

	net.Start("ZB_AdminVoicePanelState")
		net.WriteEntity(talker)
		net.WriteBool(isSpeaking and true or false)
	net.Send(targets)
end

timer.Create("ZB_AdminVoicePanelStateSync", 0.15, 0, function()
	for _, talker in ipairs(player.GetHumans()) do
		local isSpeaking = talker:IsSpeaking()

		if adminVoicePanelState[talker] ~= isSpeaking then
			adminVoicePanelState[talker] = isSpeaking
			sendAdminVoicePanelState(talker, isSpeaking)
		end
	end

	for talker in pairs(adminVoicePanelState) do
		if not IsValid(talker) then
			adminVoicePanelState[talker] = nil
		end
	end
end)

hook.Add("PlayerInitialSpawn", "ZB_AdminVoicePanelStateSnapshot", function(ply)
	timer.Simple(3, function()
		if not IsValid(ply) or not playerCanSeeVoicePanels(ply) then return end

		local snapshot = { ply }
		for talker, isSpeaking in pairs(adminVoicePanelState) do
			if IsValid(talker) and isSpeaking then
				sendAdminVoicePanelState(talker, true, snapshot)
			end
		end
	end)
end)

function PLAYER:GiveEquipment(team_)
end

local default_spawns = {
	"info_player_deathmatch", "info_player_combine", "info_player_rebel",
	"info_player_counterterrorist", "info_player_terrorist", "info_player_axis",
	"info_player_allies", "gmod_player_start", "info_player_teamspawn",
	"ins_spawnpoint", "aoc_spawnpoint", "dys_spawn_point", "info_player_pirate",
	"info_player_viking", "info_player_knight", "diprip_start_team_blue", "diprip_start_team_red",
	"info_player_red", "info_player_blue", "info_player_coop", "info_player_human", "info_player_zombie",
	"info_player_zombiemaster", "info_player_fof", "info_player_desperado", "info_player_vigilante", "info_survivor_rescue"
}

local vecup = Vector(0, 0, 64)

local spawners = {}

local function getRandSpawn()
	spawners = {}

	if #zb.GetMapPoints( "Spawnpoint" ) > 0 then
		for k, v in RandomPairs(zb.GetMapPoints( "Spawnpoint" )) do
			spawners[#spawners + 1] = v.pos
		end
	else
		for i, ent in RandomPairs(ents.FindByClass("info_player_start")) do
			spawners[#spawners + 1] = ent:GetPos()
		end
		
		for i, str in ipairs(default_spawns) do
			for k, v in RandomPairs(ents.FindByClass(str)) do
				spawners[#spawners + 1] = v:GetPos()
			end
		end

		--[[for k, v in ipairs(navmesh.GetAllNavAreas()) do
			local Randompos = v:GetCenter()
			local SpawnPos = Randompos + vecup

			spawners[#spawners + 1] = SpawnPos
		end--]]
	end
end

getRandSpawn()

hook.Add("InitPostEntity", "OwOmooooove", function()
	getRandSpawn()
end)

hook.Add("ZB_PreRoundStart", "reset_spawns", function()
	zb.ctspawn = nil
	zb.tspawn = nil
end)

function zb:GetTeamSpawn(ply)
	local team_ = ply:Team()

	local team0spawns, team1spawns = CurrentRound():GetTeamSpawn()
	
	if !team0spawns or !next(team0spawns) then
		team0spawns = {zb:GetRandomSpawn()}
	end

	if !team1spawns or !next(team1spawns) then
		team1spawns = {zb:GetRandomSpawn()}
	end

	local pos
	
	if team_ == 0 then
		if !zb.tspawn then
			zb.tspawn = table.Random(team0spawns)
			pos = zb.tspawn
		else
			pos = hg.tpPlayer(zb.tspawn, ply, math.Clamp(ply:EntIndex() % 24 + 1, 1, 24), 0)
		end

		return pos
	else
		if !zb.ctspawn then
			zb.ctspawn = table.Random(team1spawns)
			pos = zb.ctspawn
		else
			pos = hg.tpPlayer(zb.ctspawn, ply, math.Clamp(ply:EntIndex() % 24 + 1, 1, 24), 0)
		end

		return pos
	end

	ErrorNoHalt("TEAM SPAWN COULDN'T BE FOUND. INVALID TEAM")

	return team0spawns[1]
end

local check_playerspawns = function(SpawnPos, ply, tolerance)
	if !ply:Alive() then return true end
	
	local usedPos = ply:GetPos()

	local checkdist = (1024 / (math.pow(2, tolerance)))
	if usedPos:DistToSqr(SpawnPos) < checkdist * checkdist then
		return false
	end
	
	return true
end

function zb:GetRandomSpawn(target, spawns)
	if !spawns or table.IsEmpty(spawns) then
		spawns = spawners
	end
	
	return zb:FurthestFromEveryone(spawns, player.GetAll(), check_playerspawns)
end

function zb:FurthestFromEveryone(chooseTbl, restrictTbl, func, iStart, iEnd)
	if not chooseTbl or table.IsEmpty(chooseTbl) then
		chooseTbl = spawners
	end

	if not restrictTbl then
		restrictTbl = player.GetAll()

		func = check_playerspawns
	end
	
	for tolerance = (iStart or 1), (iEnd or 5) do
		for i, SpawnPos in RandomPairs(chooseTbl) do
			if not SpawnPos then continue end
			
			local allow

			for _, value in ipairs(restrictTbl) do
				allow = func(SpawnPos, value, tolerance)
				if allow == false then break end
			end
			
			if allow then
				return SpawnPos
			end
		end
	end
	
	local SpawnPos = table.Random(chooseTbl)
	
	return SpawnPos
end

function PLAYER:GetRandomSpawn()
	local spawnPos = zb:GetRandomSpawn(self)
	
	if not spawnPos then return end
	
	self:SetPos(spawnPos)
end

function GM:PlayerSelectSpawn(ply, transition)
end

local function PlayerSelectSpawn(ply, transition)
	if CurrentRound().randomSpawns then
		local randSpawn = zb:GetRandomSpawn()
		ply:SetPos(randSpawn)

		return
	end

	local spawnPos = zb:GetTeamSpawn(ply)

	if not spawnPos then
		local randSpawn = zb:GetRandomSpawn()
		ply:SetPos(randSpawn)
	else
		ply:SetPos(spawnPos)
	end
end

function PLAYER:SetupTeam(team_)
	self:SetTeam(team_)
	
	hg.CreateInv(self)

	PlayerSelectSpawn(self)
end

function GM:PlayerSpawn(ply)
    ply:SuppressHint("OpeningMenu")
    ply:SuppressHint("Annoy1")
    ply:SuppressHint("Annoy2")

    if OverrideSpawn then return end

    ply.viewmode = 3
    ply:UnSpectate()
    ply:SetMoveType(MOVETYPE_WALK)

    if ply.initialspawn then
        ply:KillSilent()
        ply:SetTeam(1001)
        ply.initialspawn = nil
        return
    end

    local round = CurrentRound()
    if round and not round.OverrideSpawn then
        ply:SetTeam(1001)
        if not round.SkipSpawnAppearance then
            ApplyAppearance(ply,nil,nil,nil,true)
        end
        ply:SetTeam(zb:BalancedChoice(0, 1))
    end

end

function GM:PlayerDisconnected()
end

RunConsoleCommand("mp_show_voice_icons", "0")

local hullscale = Vector(1, 1, 1)

util.AddNetworkString("ZB_ChooseSpecPly")

local function GetSpectateTargets(ply)
	local alive = zb:CheckAlive()
	if not istable(alive) then return {} end

	local targets = {}
	for _, target in ipairs(alive) do
		if IsValid(target) and target ~= ply and target:Alive() then
			targets[#targets + 1] = target
		end
	end

	return targets
end

local GetSpectateViewEntity

local function SendSpectateState(ply, target, prevTarget)
	if not IsValid(ply) then return end

	local viewmode = ply.viewmode or 1
	local viewEntity = viewmode ~= 3 and GetSpectateViewEntity and GetSpectateViewEntity(target) or nil
	if viewmode == 3 then
		ply.chosenSpectEntity = nil
		ply:SetNWEntity("spect", NULL)
		ply:SetNWEntity("spect_ragdoll", NULL)
		ply:SetNWInt("viewmode", 3)
		ply.lastSpectTarget = nil
	else
		ply.chosenSpectEntity = target
		ply:SetNWEntity("spect", IsValid(target) and target or NULL)
		ply:SetNWEntity("spect_ragdoll", IsValid(viewEntity) and viewEntity ~= target and viewEntity or NULL)
		ply:SetNWInt("viewmode", viewmode)
	end

	net.Start("ZB_SpectatePlayer")
	net.WriteEntity(viewmode ~= 3 and IsValid(target) and target or NULL)
	net.WriteEntity(IsValid(prevTarget) and prevTarget or NULL)
	net.WriteInt(viewmode, 4)
	net.WriteEntity(IsValid(viewEntity) and viewEntity ~= target and viewEntity or NULL)
	net.Send(ply)
end

function GetSpectateViewEntity(target)
	if not IsValid(target) then return end

	local ent = hg.GetCurrentCharacter and hg.GetCurrentCharacter(target) or target
	if IsValid(ent) and ent ~= target then return ent end

	local ragdoll = target:GetNWEntity("FakeRagdoll", NULL)
	if IsValid(ragdoll) then return ragdoll end

	ragdoll = target:GetNWEntity("RagdollDeath", NULL)
	if IsValid(ragdoll) then return ragdoll end

	return target
end

net.Receive("ZB_ChooseSpecPly",function(len,ply)
	if ply:Alive() then return end
	
	local key = net.ReadInt(32)
	local tbl = GetSpectateTargets(ply)
	
	if #tbl == 0 then
		ply.viewmode = key == IN_RELOAD and 3 or (ply.viewmode or 3)
		SendSpectateState(ply)
		return
	end
	
	ply.chosenspect = ply.chosenspect and isnumber(ply.chosenspect) and ply.chosenspect or 1
	ply.viewmode = ply.viewmode or 1
	
	ply.chosenspect = math.Clamp(ply.chosenspect, 1, #tbl)
	
	if key == IN_ATTACK then
		ply.chosenspect = ply.chosenspect + 1
		if ply.chosenspect > #tbl then ply.chosenspect = 1 end

		SendSpectateState(ply, tbl[ply.chosenspect], tbl[ply.chosenspect == 1 and #tbl or ply.chosenspect - 1])
	end

	if key == IN_ATTACK2 then
		ply.chosenspect = ply.chosenspect - 1
		if ply.chosenspect < 1 then ply.chosenspect = #tbl end

		SendSpectateState(ply, tbl[ply.chosenspect], tbl[ply.chosenspect == #tbl and 1 or ply.chosenspect + 1])
	end

	if key == IN_RELOAD then
		ply.viewmode = (ply.viewmode % 3) + 1  

		SendSpectateState(ply, tbl[ply.chosenspect], tbl[ply.chosenspect == 1 and #tbl or ply.chosenspect - 1])
	end
	
	ply.chosenspect = math.Clamp(ply.chosenspect, 1, #tbl)
	if ply.viewmode ~= 3 then
		ply.chosenSpectEntity = tbl[ply.chosenspect]
	end
	
	if ply.lastSpectTarget ~= ply.chosenSpectEntity then
		ply.lastSpectTarget = ply.chosenSpectEntity
	end
end)

hook.Add("SetupPlayerVisibility", "spectPVS", function(ply, viewent)
	if ply:Alive() then return end
	if (ply.viewmode or 1) == 3 then return end

	local entity = ply.chosenSpectEntity
	local viewEntity = GetSpectateViewEntity(entity)

	if IsValid(viewEntity) and !viewEntity:TestPVS(ply) then
		AddOriginToPVS(viewEntity:GetPos())
	end
end)

hook.Add("PlayerDeathThink", "spectNetwork", function(ply)
	if ply:Alive() then return end
	//ply:Spectate(OBS_MODE_ROAMING)

	ply.viewmode = ply.viewmode or 1

	if ply.viewmode == 3 then
		ply.chosenSpectEntity = nil
		ply:SetNWEntity("spect", NULL)
		ply:SetNWEntity("spect_ragdoll", NULL)
		ply:SetNWInt("viewmode", 3)
		ply.lastSpectTarget = nil

		if ply:GetMoveType() ~= MOVETYPE_NOCLIP then
			ply:SetMoveType(MOVETYPE_NOCLIP)
		end

		if ply:GetObserverMode() ~= OBS_MODE_ROAMING then
			ply:Spectate(OBS_MODE_ROAMING)
		end

		return
	end

	local ent = ply.chosenSpectEntity
	if not IsValid(ent) then
		local targets = GetSpectateTargets(ply)
		ent = targets[1]
		ply.chosenspect = IsValid(ent) and 1 or ply.chosenspect
		ply.chosenSpectEntity = ent
	end

	if IsValid(ply) then
		ply:SetNWEntity("spect", IsValid(ent) and ent or NULL)
		ply:SetNWInt("viewmode", ply.viewmode or 1)
		if IsValid(ent) then
			if ent.organism and ply.viewmode == 1 then
				if (ply.netsendtime or 0) < CurTime() then
					ply.netsendtime = CurTime() + 1

					hg.send_organism(ent.organism, ply)
				end
			end
			local entr = GetSpectateViewEntity(ent)
			local spectRagdoll = IsValid(entr) and entr ~= ent and entr or NULL
			ply:SetNWEntity("spect_ragdoll", spectRagdoll)

			if ply.lastSpectViewEntity ~= entr then
				ply.lastSpectViewEntity = entr
				SendSpectateState(ply, ent)
			end

			local pos = IsValid(entr) and entr:GetPos() or ent:GetPos()
			
			if ply.viewmode ~= 3 then
				local currentPos = ply:GetPos()
				local targetPos = pos
				local distance = currentPos:Distance(targetPos)
				
				if distance > 100 or ply.lastSpectTarget ~= ent then
					ply:SetPos(targetPos)
					ply.lastSpectTarget = ent
				end
			end
			--print(ply:GetPos())
		end
		
		if ply.viewmode == 3 then
			if ply:GetMoveType() ~= MOVETYPE_NOCLIP then
				ply:SetMoveType(MOVETYPE_NOCLIP)
			end
			if ply:GetObserverMode() ~= OBS_MODE_ROAMING then
				ply:Spectate(OBS_MODE_ROAMING)
			end
		else
			if ply:GetMoveType() == MOVETYPE_NOCLIP then
				ply:SetMoveType(MOVETYPE_WALK)
			end
		end
	end
end)

function GM:PlayerDeathThink(ply)
	if not ply:CanSpawn() then return false end
end

function GM:PlayerDeath(ply)
	ply.lastSpectTarget = nil
	ply.chosenSpectEntity = nil
	
	ply:Spectate(OBS_MODE_ROAMING)
	ply:SetHull(-hullscale,hullscale)
	ply:SetHullDuck(-hullscale,hullscale)
	

	ply.chosenspect = ply:EntIndex()
	ply.viewmode = 1 

	local alivePlayers = GetSpectateTargets(ply)
	if #alivePlayers > 0 then
		ply.chosenSpectEntity = alivePlayers[1]
		ply.chosenspect = 1
		local viewEntity = GetSpectateViewEntity(alivePlayers[1])
		ply:SetPos(IsValid(viewEntity) and viewEntity:GetPos() or alivePlayers[1]:GetPos())
		SendSpectateState(ply, alivePlayers[1])
	else
		SendSpectateState(ply)
	end
	
	timer.Simple(0.1, function()
		if IsValid(ply) and not ply:Alive() then
			local alivePlayers = GetSpectateTargets(ply)
			if #alivePlayers > 0 then
				ply.chosenSpectEntity = alivePlayers[1]
				ply.chosenspect = 1
				SendSpectateState(ply, alivePlayers[1])
			end
		end
	end)
end

hg.addbot = hg.addbot or false

function GM:PlayerInitialSpawn(ply)
	ply.initialspawn = true

	if #player.GetAll() == 1 then
		RunConsoleCommand("bot")
		hg.addbot = true
		zb:EndRound()
	end

	if #player.GetHumans() > 1 and hg.addbot then
		for i,bot in pairs(player.GetListByName("bot")) do
			RunConsoleCommand("kick",bot:Name())
		end
		hg.addbot = false
	end
end

function GM:IsSpawnpointSuitable( pl, spawnpointent, bMakeSuitable )
	return true
end

util.AddNetworkString("ZB_SpecMode")
net.Receive("ZB_SpecMode",function(len,ply)
	local bool = net.ReadBool()

	local enable = !hook.Run("ZB_JoinSpectators", ply)

	if enable and bool and ply:Team() != TEAM_SPECTATOR then if ply:Alive() then ply:Kill() end ply:SetTeam(TEAM_SPECTATOR) PrintMessage(HUD_PRINTTALK,ply:Name().." joined the spectators.") 
	elseif ply:Team() != 1 then
		ply:SetTeam(1) PrintMessage(HUD_PRINTTALK,ply:Name().." joined the players.")  
	end
end)

--[[
local tbl = {}
local maps = file.Find( "maps/*.bsp", "GAME" )

for _, map in ipairs( maps ) do
	map = map:sub( 1, -5 )
	table.insert( tbl, map )
end

for i, map in ipairs(ents.FindByClass("coop_mapend")) do
	if table.HasValue(tbl, map.map) then
		print(map.map)
	end
end
--]]

util.AddNetworkString("updtime")

function hg.UpdateRoundTime(time, time2, time3)
	zb.ROUND_TIME = time or zb.ROUND_TIME
	zb.ROUND_START = time2 or zb.ROUND_START or CurTime()
	zb.ROUND_BEGIN = time3 or zb.ROUND_BEGIN or CurTime() + 5
	net.Start("updtime")
	net.WriteFloat(zb.ROUND_TIME)
	net.WriteFloat(zb.ROUND_START)
	net.WriteFloat(zb.ROUND_BEGIN)
	net.Broadcast()
end

local function getspawnpos()
    local tab = {}
    local tbl = ents.FindByClass("info_player_start")
    for k, v in pairs(tbl) do
        if not v:HasSpawnFlags(1) then continue end
        tab[#tab + 1] = v:GetPos()
    end
    return tab[1] or tbl[1]:GetPos()
end

local maps = {}

hook.Add("PostCleanupMap","changelevel_generate",function()
	if CurrentRound().name != "coop" then return end
	local player_pos = getspawnpos()
    local dist = 0
    local map
    
    local maps = {}
    for i, map in pairs(ents.FindByClass("trigger_changelevel")) do
        local min, max = map:WorldSpaceAABB()
        local tdmlPos = max - ((max - min) / 2)

        maps[map] = tdmlPos
    end
    
    for ent, pos in pairs(maps) do
		if ent.map == game.GetMap() then continue end
        local dist2 = pos:Distance(player_pos)
        --print(dist,dist2,ent.map,pos,player_pos)
        if dist2 > dist then
            dist = dist2
            map = ent
        end
    end--выбираем самый дальний ченджлевел

    if not IsValid(map) then map = select(2, table.Random(maps)) end
    
    print("Next map is: "..map.map)

    local min, max = map:WorldSpaceAABB()
    local tdmlPos = max - ((max - min) / 2)
    local tdml = ents.Create("coop_mapend")
    tdml:SetPos(tdmlPos)
	tdml:SetAngles(map:GetAngles())
    tdml.min = min
    tdml.max = max
    tdml.map = map.map
    tdml:Spawn()
    tdml:Activate()
	--map:Remove()
end)

function GM:EntityKeyValue( ent, key, value )

	if ( ( ent:GetClass() == "trigger_changelevel" ) && ( key == "map" ) ) then
		ent.map = value
		ent:AddEFlags(2)
		ent:AddFlags(2)
		--[[
		maps[ent] = true
		
		timer.Create("fuckmapchanges",4,1,function()
			local random_player = table.Random(player.GetAll())
			if not IsValid(random_player) then return end
			local player_pos = random_player:GetPos()
			local dist = 0
			local map
			
			for ent, i in pairs(maps) do
				--print(ent.map,i)
				local dist2 = ent:GetPos():Distance(player_pos)
				if dist2 > dist then
					dist = dist2
					map = ent
				end
			end--выбираем самый дальний ченджлевел
			print("Next map is: "..map.map)
			if not map then map = maps[1] end

			local min, max = map:WorldSpaceAABB()
			tdmlPos = max - ((max - min) / 2)
			local tdml = ents.Create("coop_mapend")
			tdml:SetPos(tdmlPos)
			tdml.min = min
			tdml.max = max
			tdml.map = map.map
			tdml:Spawn()
			tdml:Activate()

			maps = {}
		end)--]]
	end

	if ( ent:GetClass() == "npc_combine_s" ) then
		ent:SetLagCompensated(true)
	end

	if ( ( ent:GetClass() == "npc_combine_s" ) && ( key == "additionalequipment" ) && ( value == "weapon_shotgun" ) ) then
	
		ent:SetSkin( 1 )
	
	end

end

hook.Add("CanProperty", "AntiExploit", function(ply, property, ent)
	if(!ply:IsAdmin())then
		return false
	end
end)
