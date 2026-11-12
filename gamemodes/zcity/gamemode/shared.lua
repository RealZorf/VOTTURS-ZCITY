GM.Name = "ZCity"
GM.Author = "uzelezz, sadsalat, Mr. Point, Zac90, Deka, Mannytko"
GM.Email = "N/A"
GM.Website = "N/A"

team.SetUp(0, "Players", Color(255, 0, 0))
team.SetUp(1, "Players2", Color(0, 0, 255))
team.SetUp(2, "Players3", Color(0, 255, 0))

DeriveGamemode("sandbox")

local blur = Material("pp/blurscreen")
local hg_potatopc --THIS SHIT NEEDS TO BE REWRITTEN NORMALLY, AND ALL THE MENUS ARE THE SAME TOO!!!
function hg.DrawBlur(panel, amount, passes, alpha)
	if is3d2d then return end
	amount = amount or 5
	hg_potatopc = hg_potatopc or hg.ConVars.potatopc

	if(hg_potatopc:GetBool())then
		surface.SetDrawColor(0, 0, 0, alpha or (amount * 20))
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
	else
		surface.SetMaterial(blur)
		surface.SetDrawColor(0, 0, 0, alpha or 125)
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())

		local x, y = panel:LocalToScreen(0, 0)

		for i = -(passes or 0.2), 1, 0.2 do
			blur:SetFloat("$blur", i * amount)
			blur:Recompute()
			
			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
		end
	end
end

function zb.HasAccess(ply, access)
	local ucl = ULib and ULib.ucl
	if not IsValid(ply) or not ucl or not ucl.query or not ucl.authed or not ucl.authed[ply:UniqueID()] then return false end
	return ucl.query(ply, access) == true
end

local spawnAccess = {
	PlayerGiveSWEP = "give weapons",
	PlayerSpawnSWEP = "weapons",
	PlayerSpawnEffect = "effects",
	PlayerSpawnNPC = "npcs",
	PlayerSpawnObject = "objects",
	PlayerSpawnProp = "props",
	PlayerSpawnRagdoll = "ragdolls",
	PlayerSpawnSENT = "entities",
	PlayerSpawnVehicle = "vehicles",
}

if SERVER then
	local function registerAccess()
		local ucl = ULib and ULib.ucl
		if not ucl or not ucl.registerAccess then return end
		for _, name in pairs(spawnAccess) do
			ucl.registerAccess(name, nil, name, "Spawnmenu")
		end
		ucl.registerAccess("openSpawnmenu", nil, "Open the spawn menu", "Spawnmenu")
		ucl.registerAccess("openContextmenu", nil, "Open the context menu", "Context menu")
		ucl.registerAccess("ulx addkarma", nil, "Grants access to the ulx addkarma command", "Guilt")
		ucl.registerAccess("ulx removekarma", nil, "Grants access to the ulx removekarma command", "Guilt")
		ucl.registerAccess("noclip", nil, "Use noclip", "Z-City")
		ucl.registerAccess("scoreboard hide", nil, "Hide yourself on other players' scoreboards", "Z-City")
		ucl.registerAccess("scoreboard role", nil, "Hide your rank on the scoreboard unless you choose to show it", "Z-City")
		ucl.registerAccess("ulx setspectator", nil, "Grants access to the ulx setspectator command", "Z-City")
	end

	registerAccess()
	hook.Add("Initialize", "ZC_RegisterAccess", registerAccess)
end

for hookName, access in pairs(spawnAccess) do
	hook.Add(hookName, "BlockSpawn", function(ply)
		if game.SinglePlayer() or zb.HasAccess(ply, access) then return true end
		if HG_SANDBOX and HG_SANDBOX.IsSandboxModeActive and HG_SANDBOX.IsSandboxModeActive() then
			if HG_SANDBOX.IsBypassPlayer and HG_SANDBOX.IsBypassPlayer(ply) then
				return true
			end

			return
		end

		return false
	end)
end

hook.Add( "PlayerNoClip", "FeelFreeToTurnItOff", function( ply, desiredState )
	if ( desiredState == false ) then -- the player wants to turn noclip off
		return true -- always allow
	elseif game.SinglePlayer() or zb.HasAccess(ply, "noclip") then
		return true
	end

	return false
end )

if CLIENT then
	hook.Add("SpawnMenuOpen", "SpawnMenuWhitelist", function()
		local ply = LocalPlayer()

		if game.SinglePlayer() or zb.HasAccess(ply, "openSpawnmenu") then return true end

		if HG_SANDBOX and HG_SANDBOX.IsSandboxModeActive and HG_SANDBOX.IsSandboxModeActive() then
			return true
		end

		return false
	end)
end

local team_GetAllTeams = team.GetAllTeams

function zb:CheckTeams()
	local tbl = {}
	for i, info in pairs(team_GetAllTeams()) do
		tbl[i] = {}
	end

	for _, ply in player.Iterator() do
		tbl[ply:Team()][#tbl[ply:Team()] + 1] = ply
	end
	return tbl
end

function zb:CanActivelyParticipate(ply)
	if not IsValid(ply) or not ply:Alive() then return false end

	local org = ply.organism
	if not org then return false end

	return not org.incapacitated and org.canmove
end

function zb:CheckAliveTeams(incapacitatedcheck)
	local tbl = {}

	for i, info in pairs(team_GetAllTeams()) do
		if i == TEAM_UNASSIGNED or i == TEAM_SPECTATOR then continue end
		tbl[i] = {}
	end

	for _, ply in player.Iterator() do
		if not ply:Alive() then continue end
		if incapacitatedcheck and not zb:CanActivelyParticipate(ply) then continue end

		tbl[ply:Team() or 0] = tbl[ply:Team() or 0] or {}
		tbl[ply:Team()][(#tbl[ply:Team() or 0] or 0) + 1] = ply
	end

	return tbl
end

function zb:CheckAlive(incapacitatedcheck)
	local tbl = {}
	for _, ply in player.Iterator() do
		if not ply:Alive() then continue end
		if incapacitatedcheck and not zb:CanActivelyParticipate(ply) then continue end
		tbl[#tbl + 1] = ply
	end
	return tbl
end

function zb:CheckPlaying(incapacitatedcheck)
	local tbl = {}
	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		if not ply:Alive() then continue end
		if incapacitatedcheck and not zb:CanActivelyParticipate(ply) then continue end

		tbl[#tbl + 1] = ply
	end
	return tbl
end
--Isn't this fundamental?
function GM:HandlePlayerLanding( ply, velocity, WasOnGround )
	if SERVER then return end
	if ply == LocalPlayer() and ply == GetViewEntity() then return end

	if ( ply:GetMoveType() == MOVETYPE_NOCLIP ) then return end

	if ( ply:IsOnGround() && !WasOnGround ) then
		ply:AnimRestartGesture( GESTURE_SLOT_JUMP, ACT_LAND, true )
	end

end

function GM:GrabEarAnimation(ply)
	hg.earanim(ply)
end
