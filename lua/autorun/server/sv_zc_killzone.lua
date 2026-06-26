ZC_Killzone = ZC_Killzone or {}

local DATA_DIR = "zcity/killzones"
local CHECK_INTERVAL = 0.5
local ACCESS_GROUPS = {
	superadmin = true,
	owner = true,
	servermanager = true,
	headdeveloper = true,
	headadmin = true,
	developer = true,
	admin = true
}

local function mapFilePath()
	local map = string.lower(game.GetMap() or "unknown")
	map = string.gsub(map, "[^%w_%-]", "_")

	return DATA_DIR .. "/" .. map .. ".json"
end

local function syncGlobals()
	local active = ZC_Killzone.Active == true and isnumber(ZC_Killzone.Z)

	SetGlobalBool("zc_killzone_active", active)
	SetGlobalFloat("zc_killzone_z", active and ZC_Killzone.Z or 0)
end

function ZC_Killzone.CanEdit(ply)
	if not IsValid(ply) then return true end
	if ply:IsSuperAdmin() or ply:IsAdmin() then return true end

	if ply.GetUserGroup then
		local group = string.lower(tostring(ply:GetUserGroup() or ""))
		if ACCESS_GROUPS[group] then return true end
	end

	return false
end

function ZC_Killzone.Load()
	ZC_Killzone.Active = false
	ZC_Killzone.Z = nil

	local path = mapFilePath()
	if not file.Exists(path, "DATA") then
		syncGlobals()
		return
	end

	local data = util.JSONToTable(file.Read(path, "DATA") or "")
	local z = data and tonumber(data.z)

	if z then
		ZC_Killzone.Active = data.active ~= false
		ZC_Killzone.Z = z
	end

	syncGlobals()
end

function ZC_Killzone.Save()
	file.CreateDir("zcity")
	file.CreateDir(DATA_DIR)

	file.Write(mapFilePath(), util.TableToJSON({
		active = ZC_Killzone.Active == true,
		z = ZC_Killzone.Z,
		map = game.GetMap()
	}, true))
end

function ZC_Killzone.SetZ(z, actor)
	z = tonumber(z)
	if not z then return false end

	ZC_Killzone.Active = true
	ZC_Killzone.Z = math.Round(z, 2)
	ZC_Killzone.Save()
	syncGlobals()

	if IsValid(actor) then
		actor:ChatPrint("Killzone set at Z " .. ZC_Killzone.Z .. " for " .. game.GetMap() .. ".")
	end

	return true
end

function ZC_Killzone.Clear(actor)
	ZC_Killzone.Active = false
	ZC_Killzone.Z = nil
	ZC_Killzone.Save()
	syncGlobals()

	if IsValid(actor) then
		actor:ChatPrint("Killzone cleared for " .. game.GetMap() .. ".")
	end
end

local function getLowestZ(ply)
	local ent = (hg and hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply)) or ply
	if not IsValid(ent) then ent = ply end

	local mins = ent:WorldSpaceAABB()
	return mins.z, ent
end

local function killBelowZone(ply, ent)
	if (ply.ZC_KillzoneNextKill or 0) > CurTime() then return end
	ply.ZC_KillzoneNextKill = CurTime() + 1

	local dmg = DamageInfo()
	dmg:SetDamage(10000)
	dmg:SetDamageType(DMG_FALL + DMG_CRUSH)
	dmg:SetAttacker(Entity(0))
	dmg:SetInflictor(Entity(0))
	dmg:SetDamagePosition(IsValid(ent) and ent:WorldSpaceCenter() or ply:GetPos())

	ply:TakeDamageInfo(dmg)

	if ply:Alive() then
		ply:Kill()
	end
end

timer.Create("ZC_Killzone_Check", CHECK_INTERVAL, 0, function()
	if ZC_Killzone.Active ~= true or not isnumber(ZC_Killzone.Z) then return end

	local z = ZC_Killzone.Z
	for _, ply in player.Iterator() do
		if not IsValid(ply) or not ply:Alive() then continue end
		if ply:Team() == TEAM_SPECTATOR then continue end

		local lowestZ, ent = getLowestZ(ply)
		if lowestZ and lowestZ < z then
			killBelowZone(ply, ent)
		end
	end
end)

concommand.Add("zc_killzone_set_z", function(ply, cmd, args)
	if IsValid(ply) and not ZC_Killzone.CanEdit(ply) then return end

	local z = tonumber(args[1])
	if not z then
		if IsValid(ply) then ply:ChatPrint("Usage: zc_killzone_set_z <z>") end
		return
	end

	ZC_Killzone.SetZ(z, ply)
end)

concommand.Add("zc_killzone_here", function(ply)
	if not IsValid(ply) or not ZC_Killzone.CanEdit(ply) then return end

	ZC_Killzone.SetZ(ply:GetPos().z, ply)
end)

concommand.Add("zc_killzone_clear", function(ply)
	if IsValid(ply) and not ZC_Killzone.CanEdit(ply) then return end

	ZC_Killzone.Clear(ply)
end)

concommand.Add("zc_killzone_print", function(ply)
	if IsValid(ply) and not ZC_Killzone.CanEdit(ply) then return end

	local msg = ZC_Killzone.Active and ("Killzone active at Z " .. tostring(ZC_Killzone.Z) .. " for " .. game.GetMap() .. ".") or ("No active killzone for " .. game.GetMap() .. ".")

	if IsValid(ply) then
		ply:ChatPrint(msg)
	else
		print(msg)
	end
end)

hook.Add("Initialize", "ZC_Killzone_Load", function()
	ZC_Killzone.Load()
end)

timer.Simple(0, function()
	ZC_Killzone.Load()
end)
