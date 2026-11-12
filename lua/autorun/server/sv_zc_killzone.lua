ZC_Killzone = ZC_Killzone or {}

local DIR = "zcity/killzones"
local ACCESS = "zc_killzone"

local function allowed(ply)
	if not IsValid(ply) then return true end

	local ucl = ULib and ULib.ucl
	if not ucl or not ucl.query or not ucl.authed or not ucl.authed[ply:UniqueID()] then return false end

	return ucl.query(ply, ACCESS) == true
end

local function path()
	local map = string.lower(game.GetMap() or "unknown")
	return DIR .. "/" .. string.gsub(map, "[^%w_%-]", "_") .. ".json"
end

local function sync()
	local active = ZC_Killzone.Active == true and isnumber(ZC_Killzone.Z)
	SetGlobalBool("zc_killzone_active", active)
	SetGlobalFloat("zc_killzone_z", active and ZC_Killzone.Z or 0)
end

local function save()
	file.CreateDir(DIR)
	file.Write(path(), util.TableToJSON({
		active = ZC_Killzone.Active,
		z = ZC_Killzone.Z
	}, true))
end

local function load()
	ZC_Killzone.Active = false
	ZC_Killzone.Z = nil

	local data = util.JSONToTable(file.Read(path(), "DATA") or "")
	local z = data and tonumber(data.z)
	if z then
		ZC_Killzone.Active = data.active ~= false
		ZC_Killzone.Z = z
	end

	sync()
end

function ZC_Killzone.SetZ(z, actor)
	z = tonumber(z)
	if not z then return end

	ZC_Killzone.Active = true
	ZC_Killzone.Z = math.Round(z, 2)
	save()
	sync()

	if IsValid(actor) then
		actor:ChatPrint("Killzone set at Z " .. ZC_Killzone.Z .. " for " .. game.GetMap() .. ".")
	end
end

function ZC_Killzone.Clear(actor)
	ZC_Killzone.Active = false
	ZC_Killzone.Z = nil
	save()
	sync()

	if IsValid(actor) then
		actor:ChatPrint("Killzone cleared for " .. game.GetMap() .. ".")
	end
end

function ZC_Killzone.Print(ply)
	local map = game.GetMap()
	local msg = ZC_Killzone.Active and ("Killzone active at Z " .. tostring(ZC_Killzone.Z) .. " for " .. map .. ".") or ("No active killzone for " .. map .. ".")

	if IsValid(ply) then
		ply:ChatPrint(msg)
	else
		print(msg)
	end
end

timer.Create("ZC_Killzone_Check", 0.5, 0, function()
	if ZC_Killzone.Active ~= true or not isnumber(ZC_Killzone.Z) then return end

	local z = ZC_Killzone.Z
	for _, ply in player.Iterator() do
		if not IsValid(ply) or not ply:Alive() or ply:Team() == TEAM_SPECTATOR then continue end
		if (ply.ZC_KillzoneNextKill or 0) > CurTime() then continue end

		local ent = (hg and hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply)) or ply
		if not IsValid(ent) then ent = ply end

		local mins = ent:WorldSpaceAABB()
		if mins.z >= z then continue end

		ply.ZC_KillzoneNextKill = CurTime() + 1

		local dmg = DamageInfo()
		dmg:SetDamage(10000)
		dmg:SetDamageType(DMG_FALL + DMG_CRUSH)
		dmg:SetAttacker(Entity(0))
		dmg:SetInflictor(Entity(0))
		dmg:SetDamagePosition(ent:WorldSpaceCenter())
		ply:TakeDamageInfo(dmg)

		if ply:Alive() then
			ply:Kill()
		end
	end
end)

concommand.Add("zc_killzone_set_z", function(ply, _, args)
	if IsValid(ply) and not allowed(ply) then return end

	local z = tonumber(args[1])
	if not z then
		if IsValid(ply) then ply:ChatPrint("Usage: zc_killzone_set_z <z>") end
		return
	end

	ZC_Killzone.SetZ(z, ply)
end)

concommand.Add("zc_killzone_here", function(ply)
	if not IsValid(ply) or not allowed(ply) then return end
	ZC_Killzone.SetZ(ply:GetPos().z, ply)
end)

concommand.Add("zc_killzone_clear", function(ply)
	if IsValid(ply) and not allowed(ply) then return end
	ZC_Killzone.Clear(ply)
end)

concommand.Add("zc_killzone_print", function(ply)
	if IsValid(ply) and not allowed(ply) then return end
	ZC_Killzone.Print(ply)
end)

hook.Add("Initialize", "ZC_Killzone", function()
	if ULib and ULib.ucl and ULib.ucl.registerAccess then
		ULib.ucl.registerAccess(ACCESS, nil, "Set, clear, and view the map killzone.", "Z-City")
	end

	load()
end)
