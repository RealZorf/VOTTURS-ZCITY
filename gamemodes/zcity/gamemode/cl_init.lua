zb = zb or {}
include("shared.lua")
include("loader.lua")

if not ConVarExists("hg_newspectate") then
    CreateClientConVar("hg_newspectate", "1", true, false, "Enables smooth spectator camera transitions", 0, 1)
end

function CurrentRound()
	return zb.modes[zb.CROUND]
end

zb.ROUND_STATE = 0
--0 = players can join, 1 = round is active, 2 = endround
local vecZero = Vector(0.2, 0.2, 0.2)
local vecFull = Vector(1, 1, 1)
spect,prevspect,viewmode,spectRagdoll = nil,nil,1,nil
local hullscale = Vector(0,0,0)
local nextSpectatorAudioRestore = 0
local spectatorAudioRestoreUntil = 0

local function RestoreSpectatorAudio(force)
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	if not force and spectatorAudioRestoreUntil <= CurTime() then return end
	if not force and nextSpectatorAudioRestore > CurTime() then return end
	nextSpectatorAudioRestore = CurTime() + 1

	ply:SetDSP(0, false)
	ply:ConCommand("soundfade 0 0.1")
end

local function QueueSpectatorAudioRestore(duration)
	spectatorAudioRestoreUntil = math.max(spectatorAudioRestoreUntil, CurTime() + (duration or 2))
	RestoreSpectatorAudio(true)
end

net.Receive("ZB_SpectatePlayer", function(len)
	spect = net.ReadEntity()
	prevspect = net.ReadEntity()
	viewmode = net.ReadInt(4)
	spectRagdoll = net.ReadEntity()
	LocalPlayer().spectLastPos = nil
	LocalPlayer().spectLastAng = nil

	if not LocalPlayer():Alive() then
		fakeTimer = nil
		if hg and hg.ClearLocalFakeFollow then
			hg.ClearLocalFakeFollow()
		end

		QueueSpectatorAudioRestore(2)
		timer.Simple(0, function() RestoreSpectatorAudio(true) end)
		timer.Simple(0.25, function() RestoreSpectatorAudio(true) end)
	end

	timer.Simple(0.1,function()
		-- LocalPlayer():BoneScaleChange()
		LocalPlayer():SetHull(-hullscale,hullscale)
		LocalPlayer():SetHullDuck(-hullscale,hullscale)

		if viewmode == 3 then
			LocalPlayer():SetMoveType(MOVETYPE_NOCLIP)
			LocalPlayer():SetObserverMode(OBS_MODE_ROAMING)
		end
	end)
end)

hook.Add("Player_Death", "ZC_ClearDeathSoundFadeForSpectator", function(ply)
	if ply ~= LocalPlayer() then return end

	timer.Simple(0.15, function()
		if not IsValid(LocalPlayer()) or LocalPlayer():Alive() then return end
		QueueSpectatorAudioRestore(2)
	end)

	timer.Simple(0.6, function()
		if not IsValid(LocalPlayer()) or LocalPlayer():Alive() then return end
		RestoreSpectatorAudio(true)
	end)
end)

zb.ROUND_TIME = zb.ROUND_TIME or 400
zb.ROUND_START = zb.ROUND_START or CurTime()
zb.ROUND_BEGIN = zb.ROUND_BEGIN or CurTime() + 5

net.Receive("updtime",function()
	local time = net.ReadFloat()
	local time2 = net.ReadFloat()
	local time3 = net.ReadFloat()

	zb.ROUND_TIME = time
	zb.ROUND_START = time2
	zb.ROUND_BEGIN = time3
end)

local blur = Material("pp/blurscreen")
local blur2 = Material("effects/shaders/zb_blur" )
local blursettings = {}
local hg_potatopc
hg = hg or {}
function hg.DrawBlur(panel, amount, passes, alpha)
	if is3d2d then return end
	amount = amount or 5
	hg_potatopc = hg_potatopc or (hg.ConVars and hg.ConVars.potatopc) or GetConVar("hg_potatopc")

	-- old blur
	if hg_potatopc and hg_potatopc:GetBool() then
		surface.SetDrawColor(0, 0, 0, alpha or (amount * 20))
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
	else
		surface.SetMaterial(blur)
		surface.SetDrawColor(0, 0, 0, alpha or 125)
		surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
		local x, y = panel:LocalToScreen(0, 0)
		if blursettings and blursettings[1] == amount and blursettings[2] == passes then
			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
			return
		end
		blursettings = {amount, passes}
		for i = -(passes or 0.2), 1, 0.2 do
			blur:SetFloat("$blur", i * amount)
			blur:Recompute()

			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
		end
	end

	--surface.SetMaterial(blur2)
	--surface.SetDrawColor(color_white)
	--local x, y = panel:LocalToScreen(0, 0)
--
	-- those are currently hardcoded cuz it would be too much of a hassle to change this
	--blur2:SetFloat("$c0_x", (amount or 5) * 2500) // density
	--blur2:SetFloat("$c0_y", (passes or 0.2) * 2000) // noise (inverted)
	--blur2:SetFloat("$c0_z", 1) // blending
--
	--render.UpdateScreenEffectTexture()
	--surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())

	-- surface.SetDrawColor(0, 0, 0, alpha or 125)
	-- surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
end

BlurBackground = BlurBackground or hg.DrawBlur

local keydownattack
local keydownattack2
local keydownreload
local spectateRagdollCache = {}

local function FindLiveFakeRagdoll(ply)
	if not IsValid(ply) then return end

	local ragdoll = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or nil
	if not IsValid(ragdoll) and ply.GetNWEntity then
		ragdoll = ply:GetNWEntity("FakeRagdoll", NULL)
	end

	return IsValid(ragdoll) and ragdoll or nil
end

local function FindSpectateRagdoll(ply)
	if not IsValid(ply) then return end

	local liveFake = FindLiveFakeRagdoll(ply)
	if IsValid(liveFake) then
		spectateRagdollCache[ply] = {ragdoll = liveFake, expires = CurTime() + 0.5}
		return liveFake
	end

	if ply:Alive() then
		spectateRagdollCache[ply] = nil
		return
	end

	if ply == spect and IsValid(spectRagdoll) then
		spectateRagdollCache[ply] = {ragdoll = spectRagdoll, expires = CurTime() + 1}
		return spectRagdoll
	end

	local syncedRagdoll = LocalPlayer():GetNWEntity("spect_ragdoll", NULL)
	if ply == spect and IsValid(syncedRagdoll) then
		spectateRagdollCache[ply] = {ragdoll = syncedRagdoll, expires = CurTime() + 1}
		return syncedRagdoll
	end

	local cached = spectateRagdollCache[ply]
	if cached and cached.expires > CurTime() then
		return IsValid(cached.ragdoll) and cached.ragdoll or nil
	end

	local ragdoll
	if not IsValid(ragdoll) and ply.GetNWEntity then
		ragdoll = ply:GetNWEntity("RagdollDeath", NULL)
	end

	if IsValid(ragdoll) then
		spectateRagdollCache[ply] = {ragdoll = ragdoll, expires = CurTime() + 0.5}
		return ragdoll
	end

	for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
		if ent.ply == ply or ent:GetNWEntity("ply") == ply then
			spectateRagdollCache[ply] = {ragdoll = ent, expires = CurTime() + 0.5}
			return ent
		end
	end

	local plyName = ply.GetPlayerName and ply:GetPlayerName() or ply:Name()
	for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
		local ragName = ent:GetNWString("PlayerName", "")
		if ragName ~= "" and ragName == plyName then
			spectateRagdollCache[ply] = {ragdoll = ent, expires = CurTime() + 0.5}
			return ent
		end
	end

	spectateRagdollCache[ply] = {ragdoll = nil, expires = CurTime() + 0.25}
end

local function GetSpectateCharacter(ply)
	if ply:Alive() then
		local ragdoll = FindSpectateRagdoll(ply)
		return IsValid(ragdoll) and ragdoll or ply
	end

	local ent = hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply) or ply
	if ent == ply then
		local ragdoll = FindSpectateRagdoll(ply)
		if IsValid(ragdoll) then ent = ragdoll end
	end

	return ent
end

local function GetSpectateEye(ent)
	local isRagdoll = ent.IsRagdoll and ent:IsRagdoll()
	if isRagdoll and ent.SetupBones then ent:SetupBones() end

	if ent.LookupBone and ent.GetBoneMatrix then
		local headBone = ent:LookupBone("ValveBiped.Bip01_Head1") or ent:LookupBone("ValveBiped.Bip01_Spine1") or 1
		if isRagdoll then
			local attachmentID = ent.LookupAttachment and ent:LookupAttachment("eyes") or 0
			if attachmentID and attachmentID > 0 then
				local attachment = ent:GetAttachment(attachmentID)
				if attachment then return attachment.Pos, attachment.Ang, true, true end
			end

			local boneMatrix = headBone and ent:GetBoneMatrix(headBone)
			local boneAng = boneMatrix and boneMatrix:GetAngles()

			if ent.TranslateBoneToPhysBone and ent.GetPhysicsObjectNum then
				local physBone = headBone and ent:TranslateBoneToPhysBone(headBone)
				local phys = physBone and physBone >= 0 and ent:GetPhysicsObjectNum(physBone)
				if IsValid(phys) then return phys:GetPos(), boneAng or phys:GetAngles(), true, true end
			end

			if boneMatrix then return boneMatrix:GetTranslation(), boneAng, true, true end
		else
			if ent:IsPlayer() then
				local attachmentID = ent.LookupAttachment and ent:LookupAttachment("eyes") or 0
				local attachment = attachmentID and attachmentID > 0 and ent:GetAttachment(attachmentID) or nil
				local eyeAng = ent:EyeAngles()
				local eyePos = attachment and hg and hg.eye and hg.eye(ent, 10, ent, attachment.Ang, attachment.Pos) or ent:EyePos()

				if eyePos and eyePos ~= vector_origin then
					return eyePos, eyeAng, true
				end
			end

			local attachmentID = ent.LookupAttachment and ent:LookupAttachment("eyes") or 0
			if attachmentID and attachmentID > 0 then
				local attachment = ent:GetAttachment(attachmentID)
				if attachment then return attachment.Pos, attachment.Ang, true end
			end

			local boneMatrix = headBone and ent:GetBoneMatrix(headBone)
			if boneMatrix then return boneMatrix:GetTranslation(), boneMatrix:GetAngles(), false end
		end
	end

	local eyePos = ent.EyePos and ent:EyePos()
	if eyePos and eyePos ~= vector_origin and ent.EyeAngles then return eyePos, ent:EyeAngles(), false end

	return ent:GetPos() + Vector(0, 0, 64), ent:GetAngles(), false
end

hook.Add("HUDPaint","FUCKINGSAMENAMEUSEDINHOOKFUCKME",function()
    if LocalPlayer():Alive() then return end
	local spect = LocalPlayer():GetNWEntity("spect")
	if not IsValid(spect) then return end
	if viewmode == 3 then return end
	
	surface.SetFont("HomigradFont")
	surface.SetTextColor(255, 255, 255, 255)
	local txt = "Spectating player: "..spect:Name()
	local w, h = surface.GetTextSize(txt)
	surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() / 8 * 7)
	surface.DrawText(txt)
	local txt = "In-game name: "..spect:GetPlayerName()
	local w, h = surface.GetTextSize(txt)
	surface.SetTextPos(ScrW() / 2 - w / 2, ScrH() / 8 * 7 + h)
	surface.DrawText(txt)
end)

hook.Add("HG_CalcView", "zzzzzzzUwU", function(ply, pos, angles, fov)
	if not lply:Alive() then
		local preserveRoll = false
		local firstPersonSpectate = false

		if IsValid(lply:GetNWEntity("spect", NULL)) or lply:GetNWInt("viewmode", viewmode) == 3 then
			RestoreSpectatorAudio()
		end

		if lply:KeyDown(IN_ATTACK) then
			if not keydownattack then
				keydownattack = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_ATTACK,32)
				net.SendToServer()
			end
		else
			keydownattack = false
		end

		if lply:KeyDown(IN_ATTACK2) then
			if not keydownattack2 then
				keydownattack2 = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_ATTACK2,32)
				net.SendToServer()
			end
		else
			keydownattack2 = false
		end

		if lply:KeyDown(IN_RELOAD) then
			if not keydownreload then
				keydownreload = true
				net.Start("ZB_ChooseSpecPly")
				net.WriteInt(IN_RELOAD,32)
				net.SendToServer()
			end
		else
			keydownreload = false
		end

		local viewmode = lply:GetNWInt("viewmode",viewmode)
		
		if viewmode == 3 then
			if lply:GetMoveType()!=MOVETYPE_NOCLIP then
				lply:SetMoveType(MOVETYPE_NOCLIP)
			end
			lply:SetObserverMode(OBS_MODE_ROAMING)
			lply.spectLastPos = nil
			lply.spectLastAng = nil

			return {
				origin = pos,
				angles = angles,
				fov = fov,
			}
		else
			local spect = lply:GetNWEntity("spect",spect)
			if not IsValid(spect) then return end

			local ent = GetSpectateCharacter(spect)
			if not IsValid(ent) then return end
			lply:SetPos(ent:GetPos())

			local usedEyeAttachment
			pos, ang, usedEyeAttachment, preserveRoll = GetSpectateEye(ent)

			local eyePos, eyeAng = lply:EyePos(), lply:EyeAngles()

			local tr = {}
			tr.start = pos
			tr.endpos = pos + eyeAng:Forward() * -120
			tr.filter = {ent, lply, spect}
			tr.mins = Vector(-4, -4, -4)
			tr.maxs = Vector(4, 4, 4)
			tr = util.TraceHull(tr)

			if viewmode == 2 then
				pos = tr.HitPos + eyeAng:Forward() * 8
				ang = eyeAng
			elseif viewmode == 1 then
				firstPersonSpectate = true

				if ent ~= spect and IsValid(ent) then
					if not usedEyeAttachment and IsValid(spect) then
						ang = spect:EyeAngles()
					end
				else
					ang = spect:EyeAngles()
				end
				pos = pos + ang:Forward() * (ent ~= spect and 3 or 8)
			else
				pos = eyePos
				ang = eyeAng
			end
		end
		
		if not preserveRoll then
			ang[3] = 0
		end
		
		local view
		local hg_newspectate = GetConVar("hg_newspectate")
		if firstPersonSpectate then
			lply.spectLastPos = pos
			lply.spectLastAng = ang

			view = {
				origin = pos,
				angles = ang,
				fov = fov,
			}
		elseif hg_newspectate and hg_newspectate:GetBool() then
			if not lply.spectLastPos then
				lply.spectLastPos = pos
				lply.spectLastAng = ang
			end
			
			local lerpFactor = FrameTime() * 10
			lply.spectLastPos = LerpVector(lerpFactor, lply.spectLastPos, pos)
			lply.spectLastAng = LerpAngle(lerpFactor, lply.spectLastAng, ang)

			view = {
				origin = lply.spectLastPos,
				angles = lply.spectLastAng,
				fov = fov,
			}
		else
			view = {
				origin = pos,
				angles = ang,
				fov = fov,
			}
		end

		return view
	else
		lply.spectLastPos = nil
		lply.spectLastAng = nil
		lply:SetObserverMode(OBS_MODE_NONE)
	end
end)

zb.fade = zb.fade or 0

hook.Add("RenderScreenspaceEffects", "huyhuyUwU", function()
	if zb.fade > 0 then
		zb.fade = math.Approach(zb.fade, 0, FrameTime() * 1)

		surface.SetDrawColor(0, 0, 0, 255 * math.min(zb.fade, 1))
		surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1 )
	end
end)

zb.ROUND_STATE = 0
net.Receive("RoundInfo", function()
	local rnd = net.ReadString()
	
	hook.Run("RoundInfoCalled", rnd)

	if zb.CROUND ~= rnd then
		if hg.DynaMusic then
			hg.DynaMusic:Stop()
		end
	end

	zb.CROUND = rnd

	zb.ROUND_STATE = net.ReadInt(4)

	if zb.ROUND_STATE == 1 and zb.SnapshotScoreboardKarma then
		zb.SnapshotScoreboardKarma()
	end
	
	if zb.ROUND_STATE == 0 then
		zb.fade = 7
	end

	if zb.CROUND ~= "" then
		if CurrentRound() then
			if zb.ROUND_STATE == 3 then
				if CurrentRound().EndRound then
					CurrentRound():EndRound()
				end
			elseif zb.ROUND_STATE == 1 then
				if CurrentRound().RoundStart then
					CurrentRound():RoundStart()
				end
			end
		end
	end
end)

if IsValid(scoreBoardMenu) then
	scoreBoardMenu:Remove()
	scoreBoardMenu = nil
end

hook.Add("Player Disconnected","retrymenu",function(data)
	if IsValid(scoreBoardMenu) and scoreBoardMenu.RefreshLists then
		scoreBoardMenu.RefreshLists()
	end
end)

--local hg_coolvetica = ConVarExists("hg_coolvetica") and GetConVar("hg_coolvetica") or CreateClientConVar("hg_coolvetica", "0", true, false, "changes every text to coolvetica because its good", 0, 1)
local hg_font = ConVarExists("hg_font") and GetConVar("hg_font") or CreateClientConVar("hg_font", "Bahnschrift", true, false, "Change UI text font")
local font = function() -- hg_coolvetica:GetBool() and "Coolvetica" or "Bahnschrift"
    local usefont = "Bahnschrift"

    if hg_font:GetString() != "" then
        usefont = hg_font:GetString()
    end

    return usefont
end

surface.CreateFont("ZB_InterfaceSmall", {
    font = font(),
    size = ScreenScale(6),
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_InterfaceMedium", {
    font = font(),
    size = ScreenScale(10),
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_ScrappersMedium", {
    font = font(),
    size = ScreenScale(10),
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_InterfaceMediumLarge", {
    font = font(),
    size = 35,
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_InterfaceLarge", {
    font = font(),
    size = ScreenScale(20),
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_InterfaceHumongous", {
    font = font(),
    size = 200,
    weight = 400,
    antialias = true
})

local spectatorESPEnabled = ConVarExists("zb_spectator_esp") and GetConVar("zb_spectator_esp") or CreateClientConVar("zb_spectator_esp", "1", true, false, "Show player ESP while dead or spectating", 0, 1)

local spectatorESPTextColor = Color(235, 235, 235)
local spectatorESPFallbackColor = zb.TeamESP and zb.TeamESP.DefaultColor or Color(35, 225, 110)
local spectatorESPNextToggle = 0
local spectatorESPWalkDown = false

local function IsSpectatorESPState(ply)
	if not IsValid(ply) then return false end
	if ply:Alive() then return false end

	local round = CurrentRound and CurrentRound()
	if not round or round.name == "coop" then return false end

	return true
end

local function SetSpectatorESPEnabled(enabled)
	RunConsoleCommand("zb_spectator_esp", enabled and "1" or "0")
end

local function IsSpectatorESPAllowed()
	if spectatorESPEnabled and not spectatorESPEnabled:GetBool() then return false end

	local ply = LocalPlayer()
	if not IsSpectatorESPState(ply) then return false end

	if ESP and ESP.Enabled then return false end

	return true
end

local function GetSpectatorESPColor(ply)
	if not zb.TeamESP then return spectatorESPFallbackColor end

	if zb.TeamESP.GetSpectatorColor then
		return zb.TeamESP.GetSpectatorColor(ply, spectatorESPFallbackColor)
	end

	if zb.TeamESP.GetDistinctPlayerColor then
		return zb.TeamESP.GetDistinctPlayerColor(ply, spectatorESPFallbackColor)
	end

	return spectatorESPFallbackColor
end

local function GetSpectatorESPEntity(ply)
	if not IsValid(ply) then return NULL end

	local ent = hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply) or ply

	return IsValid(ent) and ent or ply
end

local function ShouldDrawSpectatorESPFor(localPly, target)
	if not IsValid(target) then return false end
	if target == localPly then return false end
	if target:Team() == TEAM_SPECTATOR then return false end
	if not target:Alive() then return false end

	if localPly:GetNWInt("viewmode", 0) == 1 and localPly:GetNWEntity("spect") == target then
		return false
	end

	return IsValid(GetSpectatorESPEntity(target))
end

local function GetSpectatorESPLabelPos(ent)
	local maxs = ent:OBBMaxs()

	return ent:GetPos() + Vector(0, 0, maxs.z + 14)
end

hook.Add("SetupOutlines", "ZB_SpectatorESP_Outlines", function(outline_Add)
	if not IsSpectatorESPAllowed() then return end
	if not zb.ESPPerf or not zb.ESPPerf.ShouldDrawOutlines() then return end

	local ply = LocalPlayer()
	local targets = zb.ESPPerf.BuildTargets(ply, ShouldDrawSpectatorESPFor, GetSpectatorESPEntity, nil, "spectator_outline")

	zb.ESPPerf.AddGroupedOutlines(outline_Add, targets, GetSpectatorESPColor)
end)


hook.Add("CreateMove", "ZB_SpectatorESP_WalkToggle", function(cmd)
	if not cmd then return end

	local ply = LocalPlayer()
	if not IsSpectatorESPState(ply) then
		spectatorESPWalkDown = false
		return
	end
	if gui.IsGameUIVisible() or vgui.GetKeyboardFocus() then return end

	local walkDown = cmd:KeyDown(IN_WALK)
	if not walkDown then
		spectatorESPWalkDown = false
		return
	end
	if spectatorESPWalkDown or spectatorESPNextToggle > RealTime() then return end

	spectatorESPWalkDown = true
	spectatorESPNextToggle = RealTime() + 0.3
	SetSpectatorESPEnabled(not spectatorESPEnabled:GetBool())
end)

hook.Add("HUDPaint", "ZB_SpectatorESP_HUD", function()
	if not IsSpectatorESPAllowed() then return end
	if not zb.ESPPerf or not zb.ESPPerf.ShouldDrawHUDThisFrame() then return end

	local ply = LocalPlayer()
	local origin = EyePos()
	local targets = zb.ESPPerf.BuildTargets(ply, ShouldDrawSpectatorESPFor, GetSpectatorESPEntity, origin, "spectator_hud")

	for i = 1, #targets do
		local entry = targets[i]
		local target = entry.ply
		local ent = entry.ent
		local col = GetSpectatorESPColor(target)

		local screen = GetSpectatorESPLabelPos(ent):ToScreen()
		if not screen.visible then continue end

		local distance = zb.ESPPerf.GetDistanceMeters(origin, ent)

		draw.SimpleTextOutlined(target:Nick(), "TargetIDSmall", screen.x, screen.y - 10, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
		draw.SimpleTextOutlined(distance .. " m", "TargetIDSmall", screen.x, screen.y + 5, spectatorESPTextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
	end
end)

hg.playerInfo = hg.playerInfo or {}

local function addToPlayerInfo(ply, muted, volume)
	hg.playerInfo[ply:SteamID()] = {muted and true or false, volume}

	local json = util.TableToJSON(hg.playerInfo)
	file.Write("zcity_muted.txt", json)

	if file.Exists("zcity_muted.txt", "DATA") then
		local json = file.Read("zcity_muted.txt", "DATA")

		if json then
			hg.playerInfo = util.JSONToTable(json)
		end
	end
end

local function applySavedPlayerVoiceInfo(ply, steamID)
	if not IsValid(ply) or not ply:IsPlayer() then return false end

	local key = steamID or ply:SteamID()
	if not key or key == "" or key == "STEAM_ID_PENDING" then return false end

	local info = hg.playerInfo and hg.playerInfo[key]
	if info == nil then return true end

	if not istable(info) then
		info = {info == true, 1}
		hg.playerInfo[key] = info
	end

	local muted = info[1] == true
	local volume = math.Clamp(tonumber(info[2]) or 1, 0, 1)
	ply:SetMuted(muted)

	if hg.RefreshPlayerVoiceVolume then
		hg.RefreshPlayerVoiceVolume(ply)
	else
		ply:SetVoiceVolumeScale(muted and 0 or volume)
	end

	return true
end

gameevent.Listen("player_connect")
hook.Add("player_connect", "zcityhuy", function(data)
	local timerName = "zcity_voice_restore_" .. tostring(data.userid)
	timer.Create(timerName, 0.25, 12, function()
		local ply = Player(data.userid)
		if not applySavedPlayerVoiceInfo(ply, data.networkid) then return end

		timer.Remove(timerName)
	end)
end)

hook.Add("NetworkEntityCreated", "ZCityRestoreCreatedPlayerVoice", function(ent)
	if not IsValid(ent) or not ent:IsPlayer() then return end

	timer.Simple(0, function()
		applySavedPlayerVoiceInfo(ent)
	end)

	timer.Simple(1, function()
		applySavedPlayerVoiceInfo(ent)
	end)
end)

hook.Add("InitPostEntity", "furryhuy", function()
	if file.Exists("zcity_muted.txt", "DATA") then
		local json = file.Read("zcity_muted.txt", "DATA")

		if json then
			hg.playerInfo = util.JSONToTable(json)
		end

		if hg.playerInfo then
			for i, ply in player.Iterator() do
				if not istable(hg.playerInfo[ply:SteamID()]) then
					local muted = hg.playerInfo[ply:SteamID()]
					hg.playerInfo[ply:SteamID()] = {}
					hg.playerInfo[ply:SteamID()][1] = muted
					hg.playerInfo[ply:SteamID()][2] = 1
				end

				applySavedPlayerVoiceInfo(ply)
			end
		end
	end
end)

hg.muteall = false
hg.mutespect = false

local function refreshPlayerVoiceVolume(ply)
	if not IsValid(ply) then return end

	if hg.RefreshPlayerVoiceVolume then
		hg.RefreshPlayerVoiceVolume(ply)
		return
	end

	local info = hg.playerInfo and hg.playerInfo[ply:SteamID()]
	local muted = (istable(info) and info[1] == true) or (ply.IsMuted and ply:IsMuted())
	local volume = istable(info) and tonumber(info[2]) or 1
	local enabled = not muted and not hg.muteall and (not hg.mutespect or ply:Alive())
	ply:SetVoiceVolumeScale(enabled and math.Clamp(volume or 1, 0, 1) or 0)
end

local sbTextW, sbFontH, sbStackW = {}, {}, {}

local function CreateScoreboardFonts()
	surface.CreateFont("SB_CRT_Header", {
		font = "Bahnschrift",
		size = math.max(16, ScreenScale(8)),
		weight = 700,
		antialias = true,
		extended = true
	})
	surface.CreateFont("SB_CRT_Item", {
		font = "Bahnschrift",
		size = math.max(12, ScreenScale(5.5)),
		weight = 600,
		antialias = true,
		extended = true
	})
	sbTextW, sbFontH, sbStackW = {}, {}, {}
end

CreateScoreboardFonts()
hook.Add("OnScreenSizeChanged", "Scoreboard_CRTFonts", CreateScoreboardFonts)

local CRT_R, CRT_G, CRT_B = 35, 225, 110
local TRAITOR_R, TRAITOR_G, TRAITOR_B = 225, 35, 35
local color_idle = Color(172, 180, 174)
local color_idle_dim = Color(118, 126, 122)
local color_bezel = Color(8, 9, 9)
local color_text = Color(220, 220, 220)
local color_dead = Color(140, 144, 142)
local color_text_on = Color(12, 14, 12)
local color_toggle_off = Color(255, 160, 160)
local color_toggle_off_h = Color(255, 180, 180)
local color_ping_mid = Color(220, 200, 120)
local playAccentCol = Color(CRT_R, CRT_G, CRT_B)
local specAccentCol = Color(148, 156, 150)
local color_gold = Color(220, 175, 55)
local color_pink = Color(235, 90, 170)
local color_store = Color(35, 140, 225)
local color_rules = Color(TRAITOR_R, TRAITOR_G, TRAITOR_B)

local SB_PAD = 4
local SB_TEXT_PAD = 4
local SB_GAP = 6
local SB_BEZEL = 3
local SB_OUTER = 8

local function SB_HeaderH()
	return math.max(18, math.floor(ScrH() * 0.022))
end

local function SB_RowH()
	return math.max(18, math.floor(ScrH() * 0.025))
end

local function SB_PlayerRowH()
	return math.max(44, math.floor(ScrH() * 0.052))
end

local function SB_FontH(font)
	local h = sbFontH[font]
	if h then return h end
	surface.SetFont(font)
	local _, th = surface.GetTextSize("Hg")
	sbFontH[font] = th
	return th
end

local function SB_TextW(font, text)
	local byFont = sbTextW[font]
	if not byFont then
		byFont = {}
		sbTextW[font] = byFont
	end
	local w = byFont[text]
	if w then return w end
	surface.SetFont(font)
	w = surface.GetTextSize(text)
	byFont[text] = w
	return w
end

local function SB_StackW(label, sample)
	local w = sbStackW[label]
	if w then return w end
	w = math.max(SB_TextW("SB_CRT_Item", label), SB_TextW("SB_CRT_Item", sample)) + SB_TEXT_PAD * 2
	sbStackW[label] = w
	return w
end

local function GetVolumeRGB(frac)
	frac = math.Clamp(tonumber(frac) or 0, 0, 1)
	if frac <= 0.5 then
		local t = frac * 2
		return 225, 35 + (200 - 35) * t, 35 + (70 - 35) * t
	end
	local t = (frac - 0.5) * 2
	return 220 + (CRT_R - 220) * t, 200 + (CRT_G - 200) * t, 70 + (CRT_B - 70) * t
end

local matIconSound = Material("icon16/sound.png")
local matIconMute = Material("icon16/sound_mute.png")
local matIconTalk = Material("icon16/comment.png")

local STAFF_GROUPS = {
    superadmin = true,
    owner = true,
    servermanager = true,
    headdeveloper = true,
    staffmanager = true,
    headadmin = true,
    admin = true,
	developer = true,
	moderator = true,
}

local TEAM_SCORE_INFO = {
	tdm = {
		[0] = {name = "TERRORISTS", color = Color(225, 35, 35)},
		[1] = {name = "COUNTER-TERRORISTS", color = Color(35, 140, 225)},
	},
	cstrike = {
		[0] = {name = "TERRORISTS", color = Color(225, 35, 35)},
		[1] = {name = "COUNTER-TERRORISTS", color = Color(35, 140, 225)},
	},
	ww2 = {
		[0] = {name = "GERMAN FORCES", color = Color(180, 150, 110)},
		[1] = {name = "AMERICAN FORCES", color = Color(110, 170, 120)},
	},
	hl2dm = {
		[0] = {name = "REBELS", color = Color(230, 100, 5)},
		[1] = {name = "COMBINE", color = Color(0, 200, 220)},
	},
	hl3 = {
		[0] = {name = "REBELS", color = Color(230, 100, 5)},
		[1] = {name = "COMBINE", color = Color(0, 200, 220)},
		[2] = {name = "VORTIGAUNTS", color = Color(110, 220, 120)},
	},
	riot = {
		[0] = {name = "RIOTERS", color = Color(225, 35, 35)},
		[1] = {name = "LAW", color = Color(35, 140, 225)},
	},
	gwars = {
		[0] = {name = "BLOODZ", color = Color(225, 35, 35)},
		[1] = {name = "GROOVE", color = Color(35, 225, 110)},
		[2] = {name = "SWAT", color = Color(35, 140, 225)},
	},
	criresp = {
		[0] = {name = "SUSPECTS", color = Color(225, 35, 35)},
		[1] = {name = "SWAT", color = Color(70, 90, 255)},
	},
	overstimulated = {
		[0] = {name = "SWAT", color = Color(68, 10, 255)},
		[1] = {name = "VICTIMS", color = Color(220, 220, 220)},
		[2] = {name = "OVERSTIMULATED", color = Color(228, 49, 49)},
	},
}

local function DrawCRTCorners(x, y, w, h, len, r, g, b, a)
	surface.SetDrawColor(r, g, b, a)
	surface.DrawRect(x, y, len, 2)
	surface.DrawRect(x, y, 2, len)
	surface.DrawRect(x + w - len, y, len, 2)
	surface.DrawRect(x + w - 2, y, 2, len)
	surface.DrawRect(x, y + h - 2, len, 2)
	surface.DrawRect(x, y + h - len, 2, len)
	surface.DrawRect(x + w - len, y + h - 2, len, 2)
	surface.DrawRect(x + w - 2, y + h - len, 2, len)
end

local function DrawCRTFrame(x, y, w, h, ar, ag, ab, selected)
	surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, 204)
	surface.DrawRect(x, y, w, h)
	local ix, iy, iw, ih = x + SB_BEZEL, y + SB_BEZEL, w - SB_BEZEL * 2, h - SB_BEZEL * 2
	surface.SetDrawColor(ar, ag, ab, selected and 178 or 102)
	surface.DrawOutlinedRect(ix, iy, iw, ih, 1)
	DrawCRTCorners(ix, iy, iw, ih, 10, ar, ag, ab, selected and 242 or 140)
end

local function SB_Inset()
	return SB_BEZEL + SB_PAD
end

local function DrawSilkIcon(mat, x, y, size, r, g, b, a)
	if not mat then return end
	surface.SetMaterial(mat)
	surface.SetDrawColor(r or 255, g or 255, b or 255, a or 255)
	surface.DrawTexturedRect(x, y, size, size)
end

local function SB_DrawText(text, fontName, x, y, color, align)
	surface.SetFont(fontName)
	local tw = SB_TextW(fontName, text)
	if align == TEXT_ALIGN_CENTER then
		x = x - tw * 0.5
	elseif align == TEXT_ALIGN_RIGHT then
		x = x - tw
	end
	surface.SetTextColor(color.r, color.g, color.b, color.a or 255)
	surface.SetTextPos(x, y)
	surface.DrawText(text)
	return tw
end

local function SB_DrawInH(text, fontName, x, h, color, align)
	return SB_DrawText(text, fontName, x, math.floor((h - SB_FontH(fontName)) * 0.5), color, align)
end

local function SB_DrawInRect(text, font, x, rectY, rectH, color, align)
	return SB_DrawText(text, font, x, rectY + math.floor((rectH - SB_FontH(font)) * 0.5), color, align)
end

local function IsStaffPly(ply)
	if not IsValid(ply) then return false end
	if ply:IsAdmin() or ply:IsSuperAdmin() then return true end
	if not ply.GetUserGroup then return false end
	return STAFF_GROUPS[string.lower(ply:GetUserGroup() or "user")] == true
end

local function ShouldHideScoreboardPly(ply)
	if not IsValid(ply) then return true end
	if ply:GetNWBool("ZB_SB_HideSelf", false) and ply ~= LocalPlayer() then
		return true
	end
	local rnd = CurrentRound()
	if rnd and rnd.name == "fear" and not ply:Alive() then return true end
	local localPly = LocalPlayer()
	local disappearance = IsValid(localPly) and localPly.GetNetVar and localPly:GetNetVar("disappearance", nil)
	if disappearance and ply ~= localPly then return true end
	return false
end

local function SnapshotScoreboardKarma()
	zb.SBKarma = zb.SBKarma or {}
	for _, ply in player.Iterator() do
		if IsValid(ply) then
			zb.SBKarma[ply:SteamID()] = tonumber(ply.GetNetVar and ply:GetNetVar("Karma", 100)) or 100
		end
	end
end
zb.SnapshotScoreboardKarma = SnapshotScoreboardKarma

if (zb.ROUND_STATE or 0) == 1 then
	SnapshotScoreboardKarma()
end

local function GetScoreboardKarma(ply)
	if not IsValid(ply) then return 100 end
	zb.SBKarma = zb.SBKarma or {}
	local sid = ply:SteamID()
	if zb.SBKarma[sid] == nil then
		zb.SBKarma[sid] = tonumber(ply.GetNetVar and ply:GetNetVar("Karma", 100)) or 100
	end
	return zb.SBKarma[sid]
end

local function IsVoiceLocked(ply)
	if hg.muteall then return true end
	if hg.mutespect and IsValid(ply) and not ply:Alive() then return true end
	return false
end

local function GetPlayerVolume(ply)
	if not IsValid(ply) then return 1 end
	local info = hg.playerInfo[ply:SteamID()]
	if not istable(info) then
		addToPlayerInfo(ply, ply.IsMuted and ply:IsMuted() or false, 1)
		info = hg.playerInfo[ply:SteamID()]
	end
	return math.Clamp(tonumber(info[2]) or 1, 0, 1)
end

local function ApplyPlayerVolume(ply, vol)
	if not IsValid(ply) then return end
	vol = math.Clamp(tonumber(vol) or 1, 0, 1)
	addToPlayerInfo(ply, ply.IsMuted and ply:IsMuted() or false, vol)
	refreshPlayerVoiceVolume(ply)
end

local function TogglePlayerMute(ply)
	if not IsValid(ply) or IsVoiceLocked(ply) then return end
	ply:SetMuted(not ply:IsMuted())
	addToPlayerInfo(ply, ply:IsMuted(), GetPlayerVolume(ply))
	refreshPlayerVoiceVolume(ply)
end

local function IsTeamBasedMode()
	local rnd = CurrentRound()
	if not rnd then return false end
	if TEAM_SCORE_INFO[rnd.name] then return true end
	return rnd.base == "tdm" or rnd.base == "cstrike" or rnd.base == "hl2dm"
end

local function GetTeamDisplay(teamID)
	local rnd = CurrentRound()
	local modeName = rnd and rnd.name
	local info = modeName and TEAM_SCORE_INFO[modeName] and TEAM_SCORE_INFO[modeName][teamID]
	if info then return info.name, info.color end
	local name = team.GetName(teamID)
	if not name or name == "" or name == "Players" or name == "Players2" or name == "Players3" then
		name = "TEAM " .. tostring(teamID)
	end
	return string.upper(name), team.GetColor(teamID) or Color(CRT_R, CRT_G, CRT_B)
end

local function GetActiveTeams()
	local rnd = CurrentRound()
	local preset = rnd and TEAM_SCORE_INFO[rnd.name]
	local teams = {}
	if preset then
		for id in pairs(preset) do
			teams[#teams + 1] = id
		end
	else
		local seen = {}
		for _, ply in player.Iterator() do
			if ply:Team() == TEAM_SPECTATOR then continue end
			if ShouldHideScoreboardPly(ply) then continue end
			local id = ply:Team()
			if not seen[id] then
				seen[id] = true
				teams[#teams + 1] = id
			end
		end
	end
	table.sort(teams)
	if #teams == 0 then
		teams = {0, 1}
	end
	return teams
end

local function DrawLabeledStat(x, rectY, rectH, label, value, valueCol)
	local lw = SB_DrawInRect(label, "SB_CRT_Item", x, rectY, rectH, color_idle_dim, TEXT_ALIGN_LEFT)
	local vw = SB_DrawInRect(value, "SB_CRT_Item", x + lw + SB_TEXT_PAD, rectY, rectH, valueCol or color_text, TEXT_ALIGN_LEFT)
	return x + lw + SB_TEXT_PAD + vw + SB_GAP * 2
end

local function GetTDMRoundText()
	if not IsTeamBasedMode() then return nil end
	local maxR = GetGlobalInt("ZB_TDMMaxRounds", 0)
	local cur = GetGlobalInt("ZB_TDMRound", -1)
	if maxR <= 0 then return nil end
	if cur == 0 then return "WARM-UP" end
	if cur < 0 then return nil end
	return "ROUND " .. cur .. " / " .. maxR
end

local function CreateCRTButton(parent, text, onClick, extra)
	extra = extra or {}
	local but = vgui.Create("DButton", parent)
	but:SetText("")
	but.Label = text
	but.Active = false
	but.Toggle = extra.toggle and true or false
	but.Accent = extra.accent
	but.IconMat = extra.icon and Material(extra.icon) or nil
	but.DoClick = onClick
	if extra.tooltip then
		but:SetTooltip(extra.tooltip)
	end
	but.Paint = function(self, w, h)
		local hovered = self:IsHovered()
		local ac = self.Accent
		local r, g, b = CRT_R, CRT_G, CRT_B
		if self.Toggle then
			if self.Active then
				r, g, b = CRT_R, CRT_G, CRT_B
			else
				r, g, b = TRAITOR_R, TRAITOR_G, TRAITOR_B
			end
		elseif ac then
			r, g, b = ac.r, ac.g, ac.b
		end

		surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, 220)
		surface.DrawRect(0, 0, w, h)
		if self.Toggle then
			surface.SetDrawColor(r, g, b, self.Active and 180 or (hovered and 70 or 48))
			surface.DrawRect(1, 1, w - 2, h - 2)
		elseif hovered then
			surface.SetDrawColor(r, g, b, 28)
			surface.DrawRect(1, 1, w - 2, h - 2)
		end
		surface.SetDrawColor(r, g, b, hovered and 210 or 120)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		DrawCRTCorners(0, 0, w, h, 6, r, g, b, hovered and 230 or 140)

		local textCol = color_idle
		if self.Toggle and self.Active then
			textCol = color_text_on
		elseif self.Toggle then
			textCol = hovered and color_toggle_off_h or color_toggle_off
		elseif hovered then
			textCol = color_text
		elseif ac then
			textCol = ac
		end
		local tw = SB_TextW("SB_CRT_Item", self.Label)
		local iconSize = 16
		local hasIcon = self.IconMat ~= nil
		local total = tw + (hasIcon and (iconSize + SB_TEXT_PAD) or 0)
		local x = math.floor(w * 0.5 - total * 0.5)
		if hasIcon then
			DrawSilkIcon(self.IconMat, x, math.floor(h * 0.5 - iconSize * 0.5), iconSize, r, g, b, hovered and 255 or 230)
			x = x + iconSize + SB_TEXT_PAD
		end
		SB_DrawInH(self.Label, "SB_CRT_Item", hasIcon and x or math.floor(w * 0.5), h, textCol, hasIcon and TEXT_ALIGN_LEFT or TEXT_ALIGN_CENTER)
	end
	return but
end

local function OpenPlayerSoundSettings(ply)
	local Menu = DermaMenu()

	if not istable(hg.playerInfo[ply:SteamID()]) then addToPlayerInfo(ply, false, 1) end

	local mute = Menu:AddOption("Mute", function(self)
		if not IsValid(ply) then return end
		if hg.muteall or hg.mutespect then return end
		TogglePlayerMute(ply)
		self:SetChecked(ply:IsMuted())
	end)

	mute:SetIsCheckable(true)
	mute:SetChecked(ply:IsMuted())
	local volumeSlider = vgui.Create("DSlider", Menu)
	volumeSlider:SetLockY(0.5)
	volumeSlider:SetTrapInside(true)
	volumeSlider:SetSlideX(GetPlayerVolume(ply))
	volumeSlider.OnValueChanged = function(self, x, y)
		if not IsValid(ply) then return end
		if hg.muteall or (hg.mutespect and not ply:Alive()) then return end
		ApplyPlayerVolume(ply, x)
	end

	function volumeSlider:Paint(w, h)
		local frac = self:GetSlideX()
		local r, g, b = GetVolumeRGB(frac)
		draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0))
		draw.RoundedBox(0, 0, 0, w * frac, h, Color(r, g, b))
		SB_DrawInH(math.Round(frac * 100) .. "%", "SB_CRT_Item", w * 0.5, h, color_text, TEXT_ALIGN_CENTER)
	end
	function volumeSlider.Knob.Paint(self) end

	Menu:AddPanel(volumeSlider)
	Menu:Open()
end

local function RunULXCommand(cmd)
	if not IsValid(LocalPlayer()) then return end
	LocalPlayer():ConCommand(cmd)
end

local function HasZCityStoreULX()
	return istable(ZCITY_ULX_STORE)
		and ZCITY_ULX_STORE.Loaded
		and istable(ZCITY_ULX_STORE.Commands)
		and ZCITY_ULX_STORE.Commands.settokens
		and ZCITY_ULX_STORE.Commands.addtokens
		and ZCITY_ULX_STORE.Commands.removetokens
end

local function RequestULXAmount(title, prompt, defaultValue, onConfirm)
	Derma_StringRequest(title, prompt, tostring(defaultValue or ""), function(value)
		value = tonumber(value)
		if not value then return end
		onConfirm(math.max(0, math.floor(value)))
	end, function() end)
end

local function AddStaffULXMenu(menu, ply)
	if not IsStaffPly(LocalPlayer()) or not IsValid(ply) then return end

	local nick = string.gsub(ply:Nick() or "unknown", "\"", "")
	local staffMenu, staffOpt = menu:AddSubMenu("Staff / ULX")
	if IsValid(staffOpt) then
		staffOpt:SetIcon("icon16/shield.png")
	end

	local tpMenu, tpOpt = staffMenu:AddSubMenu("Teleport")
	if IsValid(tpOpt) then
		tpOpt:SetIcon("icon16/arrow_right.png")
	end
	tpMenu:AddOption("Bring", function() RunULXCommand('ulx bring "' .. nick .. '"') end):SetIcon("icon16/arrow_left.png")
	tpMenu:AddOption("Goto", function() RunULXCommand('ulx goto "' .. nick .. '"') end):SetIcon("icon16/arrow_up.png")
	tpMenu:AddOption("Return", function() RunULXCommand('ulx return "' .. nick .. '"') end):SetIcon("icon16/arrow_undo.png")

	local modMenu, modOpt = staffMenu:AddSubMenu("Moderation")
	if IsValid(modOpt) then
		modOpt:SetIcon("icon16/wrench.png")
	end
	modMenu:AddOption("Freeze", function() RunULXCommand('ulx freeze "' .. nick .. '"') end):SetIcon("icon16/weather_snow.png")
	modMenu:AddOption("Unfreeze", function() RunULXCommand('ulx unfreeze "' .. nick .. '"') end):SetIcon("icon16/weather_sun.png")
	modMenu:AddOption("Jail", function() RunULXCommand('ulx jail "' .. nick .. '"') end):SetIcon("icon16/lock.png")
	modMenu:AddOption("Unjail", function() RunULXCommand('ulx unjail "' .. nick .. '"') end):SetIcon("icon16/lock_open.png")
	modMenu:AddOption("Spectate", function() RunULXCommand('ulx spectate "' .. nick .. '"') end):SetIcon("icon16/eye.png")
	modMenu:AddOption("Slay", function()
		Derma_Query(
			"Slay " .. nick .. "?",
			"Confirm Slay",
			"Yes", function() RunULXCommand('ulx slay "' .. nick .. '"') end,
			"No"
		)
	end):SetIcon("icon16/bomb.png")
	modMenu:AddOption("Kick", function()
		Derma_StringRequest(
			"Kick Player",
			"Enter kick reason for " .. nick,
			"",
			function(reason)
				reason = reason ~= "" and reason or "No reason"
				RunULXCommand('ulx kick "' .. nick .. '" "' .. string.gsub(reason, '"', "'") .. '"')
			end
		)
	end):SetIcon("icon16/door_out.png")
	modMenu:AddOption("Ban (60m)", function()
		Derma_StringRequest(
			"Ban Player",
			"Enter ban reason for " .. nick,
			"",
			function(reason)
				reason = reason ~= "" and reason or "No reason"
				RunULXCommand('ulx ban "' .. nick .. '" 60 "' .. string.gsub(reason, '"', "'") .. '"')
			end
		)
	end):SetIcon("icon16/delete.png")

	local zcityMenu, zcityOpt = staffMenu:AddSubMenu("Z-City")
	if IsValid(zcityOpt) then
		zcityOpt:SetIcon("icon16/heart.png")
	end
	zcityMenu:AddOption("Set Karma", function()
		RequestULXAmount("Set Karma", "Enter karma value for " .. nick, GetScoreboardKarma(ply), function(value)
			RunULXCommand('ulx setkarma "' .. nick .. '" ' .. value)
		end)
	end):SetIcon("icon16/heart.png")
	zcityMenu:AddOption("Add Karma", function()
		RequestULXAmount("Add Karma", "Enter amount to add for " .. nick, 10, function(value)
			RunULXCommand('ulx addkarma "' .. nick .. '" ' .. value)
		end)
	end):SetIcon("icon16/add.png")
	zcityMenu:AddOption("Remove Karma", function()
		RequestULXAmount("Remove Karma", "Enter amount to remove from " .. nick, 10, function(value)
			RunULXCommand('ulx removekarma "' .. nick .. '" ' .. value)
		end)
	end):SetIcon("icon16/delete.png")
	zcityMenu:AddOption("Set Spectator", function()
		Derma_Query(
			"Move " .. nick .. " to spectators?",
			"Set Spectator",
			"Yes", function() RunULXCommand('ulx setspectator "' .. nick .. '"') end,
			"No"
		)
	end):SetIcon("icon16/user_go.png")

	if HasZCityStoreULX() then
		local setTokensCommand = tostring(ZCITY_ULX_STORE.Commands.settokens or "zbstoretokens")
		local addTokensCommand = tostring(ZCITY_ULX_STORE.Commands.addtokens or "zbstoreaddtokens")
		local removeTokensCommand = tostring(ZCITY_ULX_STORE.Commands.removetokens or "zbstoreremovetokens")
		zcityMenu:AddOption("Set Tokens", function()
			RequestULXAmount("Set Tokens", "Enter token total for " .. nick, ply:GetNWInt("ZCStore_Tokens", 0), function(value)
				RunULXCommand('ulx ' .. setTokensCommand .. ' "' .. nick .. '" ' .. value)
			end)
		end):SetIcon("icon16/coins.png")
		zcityMenu:AddOption("Add Tokens", function()
			RequestULXAmount("Add Tokens", "Enter token amount to add for " .. nick, 10, function(value)
				RunULXCommand('ulx ' .. addTokensCommand .. ' "' .. nick .. '" ' .. value)
			end)
		end):SetIcon("icon16/add.png")
		zcityMenu:AddOption("Remove Tokens", function()
			RequestULXAmount("Remove Tokens", "Enter token amount to remove from " .. nick, 10, function(value)
				RunULXCommand('ulx ' .. removeTokensCommand .. ' "' .. nick .. '" ' .. value)
			end)
		end):SetIcon("icon16/delete.png")
	end
end

local function AddPlayerContextMenu(ply)
	local Menu = DermaMenu()
	local account = Menu:AddOption("Account", function()
		if zb.Experience and zb.Experience.AccountMenu then
			zb.Experience.AccountMenu(ply)
		end
	end)
	account:SetIcon("icon16/user.png")
	local sid = Menu:AddOption("Copy SteamID", function()
		SetClipboardText(ply:SteamID())
	end)
	sid:SetIcon("icon16/page_copy.png")
	if not ply:IsBot() then
		local sid64 = Menu:AddOption("Copy SteamID64", function()
			SetClipboardText(ply:SteamID64())
		end)
		sid64:SetIcon("icon16/page_white_copy.png")
		local profile = Menu:AddOption("Open Steam Profile", function()
			gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
		end)
		profile:SetIcon("icon16/world.png")
	end
	AddStaffULXMenu(Menu, ply)
	Menu:Open()
end

local function CreateMuteControls(parent, ply)
	local wrap = vgui.Create("DPanel", parent)
	wrap:SetPaintBackground(false)
	wrap:Dock(RIGHT)
	local muteInner = SB_PlayerRowH() - SB_TEXT_PAD * 2
	wrap:SetWide(muteInner + SB_TEXT_PAD + 72)
	wrap:DockMargin(SB_TEXT_PAD, SB_TEXT_PAD, SB_TEXT_PAD, SB_TEXT_PAD)

	local speaker = vgui.Create("DButton", wrap)
	speaker:Dock(LEFT)
	speaker:SetWide(muteInner)
	speaker:DockMargin(0, 0, SB_TEXT_PAD, 0)
	speaker:SetText("")
	speaker:SetTooltip("Mute this player. Drag the bar to set volume.")
	speaker.DoClick = function()
		TogglePlayerMute(ply)
	end
	speaker.DoRightClick = function()
		OpenPlayerSoundSettings(ply)
	end
	speaker.Paint = function(self, w, h)
		if not IsValid(ply) then return end
		local muted = ply:IsMuted() or IsVoiceLocked(ply)
		local mat = muted and matIconMute or matIconSound
		local size = math.min(16, math.max(12, math.floor(h * 0.55)))
		DrawSilkIcon(mat, math.floor(w * 0.5 - size * 0.5), math.floor(h * 0.5 - size * 0.5), size, 255, 255, 255, self:IsHovered() and 255 or 220)
	end

	local slider = vgui.Create("DSlider", wrap)
	slider:Dock(FILL)
	slider:SetLockY(0.5)
	slider:SetTrapInside(true)
	slider:SetSlideX(GetPlayerVolume(ply))
	function slider.Knob:Paint() end
	slider.OnValueChanged = function(self, x)
		ApplyPlayerVolume(ply, x)
	end
	slider.Paint = function(self, w, h)
		if not IsValid(ply) then return end
		local locked = IsVoiceLocked(ply) or ply:IsMuted()
		local frac = locked and 0 or self:GetSlideX()
		local r, g, b = GetVolumeRGB(frac)
		if locked then
			r, g, b = TRAITOR_R, TRAITOR_G, TRAITOR_B
		end
		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(r, g, b, 190)
		surface.DrawRect(0, 0, w * math.max(frac, locked and 1 or 0), h)
		surface.SetDrawColor(r, g, b, 90)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		local label = ply:IsMuted() and "MUTE" or (math.Round(self:GetSlideX() * 100) .. "%")
		if IsVoiceLocked(ply) then label = hg.muteall and "ALL" or "SPEC" end
		SB_DrawInH(label, "SB_CRT_Item", w * 0.5, h, color_text, TEXT_ALIGN_CENTER)
	end

	ply.soundButton = speaker
	return wrap
end

local function CreatePlayerRow(parent, ply, accent, hideKarma)
	accent = accent or Color(CRT_R, CRT_G, CRT_B)
	local rowH = SB_PlayerRowH()
	local lineH = SB_FontH("SB_CRT_Item")

	local but = vgui.Create("DPanel", parent)
	but:SetTall(rowH)
	but:Dock(TOP)
	but:DockMargin(0, 0, 0, 2)
	but:SetPaintBackground(false)
	but:SetMouseInputEnabled(true)

	local avatar = vgui.Create("AvatarImage", but)
	avatar:Dock(LEFT)
	avatar:SetWide(rowH - SB_TEXT_PAD * 2)
	avatar:DockMargin(SB_TEXT_PAD, SB_TEXT_PAD, SB_TEXT_PAD, SB_TEXT_PAD)
	avatar:SetPlayer(ply, 64)
	avatar:SetMouseInputEnabled(false)

	CreateMuteControls(but, ply)

	local pingPnl = vgui.Create("DPanel", but)
	pingPnl:SetPaintBackground(false)
	pingPnl:Dock(RIGHT)
	pingPnl:SetWide(SB_StackW("MS", "000"))
	pingPnl:SetMouseInputEnabled(false)
	pingPnl:SetTooltip("Ping")
	pingPnl.Paint = function(self, w, h)
		if not IsValid(ply) then return end
		local ping = ply:Ping() or 0
		local pingCol = color_text
		if ping >= 150 then
			pingCol = color_rules
		elseif ping >= 80 then
			pingCol = color_ping_mid
		end
		local total = lineH * 2 + 1
		local y = math.floor((h - total) * 0.5)
		local cx = math.floor(w * 0.5)
		SB_DrawText("MS", "SB_CRT_Item", cx, y, color_idle_dim, TEXT_ALIGN_CENTER)
		SB_DrawText(tostring(ping), "SB_CRT_Item", cx, y + lineH + 1, pingCol, TEXT_ALIGN_CENTER)
	end

	if not hideKarma then
		local karmaPnl = vgui.Create("DPanel", but)
		karmaPnl:SetPaintBackground(false)
		karmaPnl:Dock(RIGHT)
		karmaPnl:SetWide(SB_StackW("KARMA", "000"))
		karmaPnl:SetMouseInputEnabled(false)
		karmaPnl:SetTooltip("Karma from the start of this round")
		karmaPnl.Paint = function(self, w, h)
			if not IsValid(ply) then return end
			local total = lineH * 2 + 1
			local y = math.floor((h - total) * 0.5)
			local cx = math.floor(w * 0.5)
			SB_DrawText("KARMA", "SB_CRT_Item", cx, y, color_idle_dim, TEXT_ALIGN_CENTER)
			SB_DrawText(tostring(math.Round(GetScoreboardKarma(ply) or 100)), "SB_CRT_Item", cx, y + lineH + 1, color_text, TEXT_ALIGN_CENTER)
		end
	end

	local nameBtn = vgui.Create("DButton", but)
	nameBtn:Dock(FILL)
	nameBtn:SetText("")
	nameBtn.Paint = function() end
	nameBtn.DoClick = function()
		if not IsValid(ply) then return end
		if ply:IsBot() then chat.AddText(Color(255, 0, 0), "no, you can't") return end
		gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
	end
	nameBtn.DoRightClick = function()
		if IsValid(ply) then AddPlayerContextMenu(ply) end
	end

	but.Paint = function(self, w, h)
		if not IsValid(ply) then return end
		local hovered = self:IsHovered() or self:IsChildHovered()
		local localPly = ply == LocalPlayer()
		local talking = (ply.IsSpeaking and ply:IsSpeaking()) or ply.IsSpeak
		local talkVol = 0
		if talking then
			talkVol = math.Clamp(math.max(((ply.VoiceVolume and ply:VoiceVolume()) or 0.28) * 5, 0.28), 0, 1)
		end
		local ar, ag, ab = accent.r, accent.g, accent.b
		if localPly or talking then
			surface.SetDrawColor(ar, ag, ab, localPly and 31 or (20 + talkVol * 40))
			surface.DrawRect(0, 0, w, h)
			if localPly then
				surface.SetDrawColor(ar, ag, ab, 216)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
			end
		elseif hovered then
			surface.SetDrawColor(ar, ag, ab, 18)
			surface.DrawRect(0, 0, w, h)
		end

		local name = ply:Name() or "Disconnected"
		local group = "USER"
		if ply.GetUserGroup then
			group = ply:GetUserGroup() or "user"
			if IsStaffPly(ply) and not ply:GetNWBool("ZB_SB_ShowRole", false) then
				group = "USER"
			else
				group = string.upper(string.Replace(tostring(group), "_", " "))
			end
		end
		local tags = {}
		if localPly and ply:GetNWBool("ZB_SB_HideSelf", false) then
			tags[#tags + 1] = "[HIDDEN]"
		end
		if group then
			tags[#tags + 1] = "[" .. group .. "]"
		end
		local sub = table.concat(tags, " ")
		local hasSub = sub ~= ""
		local total = hasSub and (lineH * 2 + 1) or lineH
		local y = math.floor((h - total) * 0.5)
		local nameCol = color_idle
		if talking then
			nameCol = color_text
		elseif not ply:Alive() and ply:Team() ~= TEAM_SPECTATOR then
			nameCol = color_dead
		elseif hovered or localPly then
			nameCol = color_text
		end
		local nameX = rowH + SB_TEXT_PAD
		local nameW = SB_DrawText(name, "SB_CRT_Item", nameX, y, nameCol, TEXT_ALIGN_LEFT)

		if talking then
			local iconSize = 16
			local iconX = nameX + nameW + 5
			local iconY = y + math.floor((lineH - iconSize) * 0.5)

			DrawSilkIcon(matIconTalk, iconX, iconY, iconSize, 255, 255, 255, 180 + talkVol * 75)

			surface.SetDrawColor(ar, ag, ab, 80 + talkVol * 160)
			surface.DrawRect(0, h - 2, w * talkVol, 2)
		end

		if hasSub then
			SB_DrawText(sub, "SB_CRT_Item", nameX, y + lineH + 1, color_idle_dim, TEXT_ALIGN_LEFT)
		end
	end

	parent:AddItem(but)
	return but
end

local function CreateListPanel(parent, title, accent)
	accent = accent or Color(CRT_R, CRT_G, CRT_B)
	local wrap = vgui.Create("DPanel", parent)
	wrap:SetPaintBackground(false)
	wrap.Title = title
	wrap.Count = 0
	wrap.Accent = accent
	wrap.Paint = function(self, w, h)
		DrawCRTFrame(0, 0, w, h, self.Accent.r, self.Accent.g, self.Accent.b, false)
		local inset = SB_Inset()
		surface.SetDrawColor(0, 0, 0, 115)
		surface.DrawRect(inset, inset, w - inset * 2, h - inset * 2)
	end

	local header = vgui.Create("DPanel", wrap)
	header:Dock(TOP)
	header:SetTall(SB_HeaderH())
	local inset = SB_Inset()
	header:DockMargin(inset, inset, inset, 0)
	header:SetPaintBackground(false)
	header.Paint = function(self, w, h)
		surface.SetDrawColor(wrap.Accent.r, wrap.Accent.g, wrap.Accent.b, 41)
		surface.DrawRect(0, 0, w, h)
		SB_DrawInH(wrap.Title, "SB_CRT_Header", SB_TEXT_PAD, h, color_text, TEXT_ALIGN_LEFT)
		SB_DrawInH(tostring(wrap.Count), "SB_CRT_Header", w - SB_TEXT_PAD, h, color_idle, TEXT_ALIGN_RIGHT)
	end

	local scroll = vgui.Create("DScrollPanel", wrap)
	scroll:Dock(FILL)
	scroll:DockMargin(inset, SB_PAD, inset, inset)
	scroll.Paint = function() end
	local canvas = scroll:GetCanvas()
	if IsValid(canvas) then
		canvas.Paint = function() end
	end
	local vbar = scroll:GetVBar()
	vbar:SetWide(4)
	vbar.Paint = function() end
	vbar.btnUp.Paint = function() end
	vbar.btnDown.Paint = function() end
	vbar.btnGrip.Paint = function(self, w, h)
		surface.SetDrawColor(accent.r, accent.g, accent.b, 140)
		surface.DrawRect(0, 0, w, h)
	end

	wrap.Scroll = scroll
	return wrap
end

hook.Add("Player Getup", "nomorespect", function(ply)
	if not hg.mutespect then return end
	refreshPlayerVoiceVolume(ply)
end)

hook.Add("Player_Death", "fixSpectatorVoiceMute", function(ply)
	if not hg.mutespect then return end
	refreshPlayerVoiceVolume(ply)
end)

hook.Add("Player_Death", "fixSpectatorVoiceEffect", function(ply)
	if eightbit and eightbit.EnableEffect and ply.UserID then
		eightbit.EnableEffect(ply:UserID(), 0)
	end
end)

local function GetScoreboardSig()
	local sig = player.GetCount()
	for _, ply in player.Iterator() do
		sig = (sig * 33 + ply:UserID() + ply:Team() * 17) % 2147483647
		if ply:GetNWBool("ZB_SB_HideSelf", false) then sig = sig + 3 end
		if ply:GetNWBool("ZB_SB_ShowRole", false) then sig = sig + 7 end
	end
	local lp = LocalPlayer()
	if IsValid(lp) then
		sig = sig + lp:Team() * 1009
	end
	return sig
end

function GM:ScoreboardShow()
	if IsValid(scoreBoardMenu) then
		if scoreBoardMenu.BuiltW == ScrW() and scoreBoardMenu.BuiltH == ScrH() then
			scoreBoardMenu:SetVisible(true)
			scoreBoardMenu:SetAlpha(255)
			scoreBoardMenu:MakePopup()
			scoreBoardMenu:SetKeyboardInputEnabled(false)
			scoreBoardMenu:SetMouseInputEnabled(true)
			if scoreBoardMenu.RefreshLists then
				scoreBoardMenu.RefreshLists()
			end
			return true
		end
		scoreBoardMenu:Remove()
		scoreBoardMenu = nil
	end
	Dynamic = 0
	scoreBoardMenu = vgui.Create("ZFrame")

	local sizeX, sizeY = math.min(ScrW() * 0.82, ScreenScale(520)), math.min(ScrH() * 0.84, ScreenScaleH(420))
	local posX, posY = ScrW() / 2 - sizeX / 2, ScrH() / 2 - sizeY / 2

	scoreBoardMenu:SetPos(posX, posY)
	scoreBoardMenu:SetSize(sizeX, sizeY)
	scoreBoardMenu:MakePopup()
	scoreBoardMenu:SetKeyboardInputEnabled(false)
	scoreBoardMenu:ShowCloseButton(false)
	scoreBoardMenu:SetDraggable(false)
	scoreBoardMenu:DockPadding(0, 0, 0, 0)
	if IsValid(scoreBoardMenu.lblTitle) then
		scoreBoardMenu.lblTitle:SetVisible(false)
	end
	for _, key in ipairs({"btnClose", "btnMaxim", "btnMinim"}) do
		if IsValid(scoreBoardMenu[key]) then
			scoreBoardMenu[key]:SetVisible(false)
		end
	end
	scoreBoardMenu:SetColorBR(Color(CRT_R, CRT_G, CRT_B, 180))
	scoreBoardMenu:SetColorBG(Color(8, 9, 9, 230))
	if scoreBoardMenu.SetBlurStrengh then
		scoreBoardMenu:SetBlurStrengh(0)
	end
	scoreBoardMenu.First = function(self)
		self:SetAlpha(255)
	end
	scoreBoardMenu:SetAlpha(255)
	scoreBoardMenu.BuiltW = ScrW()
	scoreBoardMenu.BuiltH = ScrH()

	local headerH = SB_HeaderH()
	local rowH = SB_RowH()
	local header = vgui.Create("DPanel", scoreBoardMenu)
	header:Dock(TOP)
	header:SetTall(SB_BEZEL * 2 + SB_PAD * 3 + headerH + rowH)
	header:DockMargin(SB_OUTER, SB_OUTER, SB_OUTER, 0)
	header:SetPaintBackground(false)
	header.Paint = function(self, w, h)
		DrawCRTFrame(0, 0, w, h, CRT_R, CRT_G, CRT_B, true)
		local inset = SB_Inset()
		local innerW = w - inset * 2
		local titleY = inset
		surface.SetDrawColor(0, 0, 0, 115)
		surface.DrawRect(inset, inset, innerW, h - inset * 2)
		surface.SetDrawColor(CRT_R, CRT_G, CRT_B, 41)
		surface.DrawRect(inset, titleY, innerW, headerH)
		SB_DrawInRect(GetHostName() or "ZCity", "SB_CRT_Header", math.floor(w * 0.5), titleY, headerH, color_text, TEXT_ALIGN_CENTER)

		local statsY = titleY + headerH + SB_PAD
		local x = inset + SB_TEXT_PAD
		local rnd = CurrentRound()
		local modeName = "UNKNOWN"
		if rnd and (rnd.PrintName or rnd.name) then
			modeName = string.upper(rnd.PrintName or rnd.name)
		elseif zb.CROUND and zb.CROUND ~= "" then
			modeName = string.upper(zb.CROUND)
		end
		x = DrawLabeledStat(x, statsY, rowH, "MODE", modeName)
		local tdmRound = GetTDMRoundText()
		if tdmRound then
			x = DrawLabeledStat(x, statsY, rowH, "ROUND", tdmRound)
		end
		local state = "WAITING"
		if (zb.ROUND_STATE or 0) == 1 then
			state = "LIVE"
		elseif (zb.ROUND_STATE or 0) == 3 then
			state = "ENDING"
		end
		local stateCol = color_idle
		if state == "LIVE" then
			stateCol = color_text
		elseif state == "ENDING" then
			stateCol = color_ping_mid
		end
		x = DrawLabeledStat(x, statsY, rowH, "STATE", state, stateCol)
		if (zb.ROUND_STATE or 0) ~= 0 then
			local startTime = zb.ROUND_START or CurTime()
			x = DrawLabeledStat(x, statsY, rowH, "TIME LEFT", string.FormattedTime(math.max(startTime + (zb.ROUND_TIME or 400) - CurTime(), 0), "%02i:%02i"))
		end
		local ft = engine.ServerFrameTime()
		DrawLabeledStat(x, statsY, rowH, "TICKRATE", (ft and ft > 0) and tostring(math.Round(1 / ft)) or "-")
	end

	local toolbar = vgui.Create("DPanel", scoreBoardMenu)
	toolbar:Dock(TOP)
	toolbar:SetTall(rowH)
	toolbar:DockMargin(SB_OUTER, SB_GAP, SB_OUTER, 0)
	toolbar:SetPaintBackground(false)
	toolbar.Paint = function(self, w, h)
		SB_DrawInH("Right-click a player for more options.", "SB_CRT_Item", SB_TEXT_PAD, h, color_idle_dim, TEXT_ALIGN_LEFT)
	end

	local tools = vgui.Create("DPanel", toolbar)
	tools:Dock(RIGHT)
	tools:SetPaintBackground(false)

	local toolWide = 0
	local function AddToolButton(label, click, isActive, tooltip)
		local but = CreateCRTButton(tools, label, click, {toggle = true, tooltip = tooltip})
		local wide = SB_TextW("SB_CRT_Item", label) + SB_TEXT_PAD * 4
		but:Dock(RIGHT)
		but:DockMargin(SB_GAP, 0, 0, 0)
		but:SetWide(wide)
		but.Think = function(self)
			if isActive then self.Active = isActive() end
		end
		toolWide = toolWide + wide + SB_GAP
		return but
	end

	AddToolButton("MUTE ALL", function()
		hg.muteall = not hg.muteall
		for _, ply in player.Iterator() do
			refreshPlayerVoiceVolume(ply)
		end
	end, function() return hg.muteall end, "Mute every player")

	AddToolButton("MUTE SPEC", function()
		hg.mutespect = not hg.mutespect
		for _, ply in player.Iterator() do
			if not ply:Alive() then
				refreshPlayerVoiceVolume(ply)
			end
		end
	end, function() return hg.mutespect end, "Mute dead and spectator voice")

	if IsStaffPly(LocalPlayer()) then
		AddToolButton("HIDE SELF", function()
			net.Start("ZB_SB_StaffOpt")
			net.WriteBool(not LocalPlayer():GetNWBool("ZB_SB_HideSelf", false))
			net.WriteBool(LocalPlayer():GetNWBool("ZB_SB_ShowRole", false))
			net.SendToServer()
		end, function() return LocalPlayer():GetNWBool("ZB_SB_HideSelf", false) end, "Hide yourself from everyone else's scoreboard")

		AddToolButton("SHOW ROLE", function()
			net.Start("ZB_SB_StaffOpt")
			net.WriteBool(LocalPlayer():GetNWBool("ZB_SB_HideSelf", false))
			net.WriteBool(not LocalPlayer():GetNWBool("ZB_SB_ShowRole", false))
			net.SendToServer()
		end, function() return LocalPlayer():GetNWBool("ZB_SB_ShowRole", false) end, "Show your real staff group to everyone")
	end
	tools:SetWide(math.max(0, toolWide - SB_GAP))

	local footer = vgui.Create("DPanel", scoreBoardMenu)
	footer:Dock(BOTTOM)
	footer:SetTall(rowH)
	footer:DockMargin(SB_OUTER, SB_GAP, SB_OUTER, SB_OUTER)
	footer:SetPaintBackground(false)

	local linkButtons = {
		{label = "SUPPORT US", accent = color_gold, icon = "icon16/heart.png", tooltip = "Support VOTTUR'S ZCITY on Ko-fi", url = "https://ko-fi.com/votturzcity"},
		{label = "DISCORD", accent = Color(CRT_R, CRT_G, CRT_B), icon = "icon16/comments.png", tooltip = "Join the Discord", url = "https://discord.gg/votturzcity"},
		{label = "GUIDE", accent = color_pink, icon = "icon16/book.png", tooltip = "Open Z-City Guide", url = "https://docs.google.com/document/d/1oVOleCQSrbfWddLKOgjAKD-EKpbS1dxCfNdCSUwNfn4"},
		{label = "RULES", accent = color_rules, icon = "icon16/page_white_text.png", tooltip = "Server rules", cmd = {"ulx", "motd"}},
		{label = "STORE", accent = color_store, icon = "icon16/cart.png", tooltip = "Open the in-game store", cmd = {"say", "!store"}},
		{label = "WORKSHOP", accent = Color(180, 180, 180), icon = "icon16/world.png", tooltip = "Open the Workshop", url = "https://steamcommunity.com/sharedfiles/filedetails/?id=3715931702"},
	}

	local footerBtns = {}
	for _, info in ipairs(linkButtons) do
		local but = CreateCRTButton(footer, info.label, function()
			if info.cmd then
				RunConsoleCommand(unpack(info.cmd))
			elseif info.url then
				gui.OpenURL(info.url)
			end
		end, {accent = info.accent, icon = info.icon, tooltip = info.tooltip})
		but:Dock(LEFT)
		footerBtns[#footerBtns + 1] = but
	end
	footer.PerformLayout = function(self, w, h)
		local n = #footerBtns
		if n <= 0 then return end
		local wide = math.floor((w - SB_GAP * (n - 1)) / n)
		for i, but in ipairs(footerBtns) do
			but:SetWide(wide)
			but:DockMargin(0, 0, i < n and SB_GAP or 0, 0)
		end
	end

	local content = vgui.Create("DPanel", scoreBoardMenu)
	content:Dock(FILL)
	content:DockMargin(SB_OUTER, SB_GAP, SB_OUTER, 0)
	content:SetPaintBackground(false)

	local function FillList(listPanel, players, accent, hideKarma)
		if not IsValid(listPanel) then return end
		listPanel.Scroll:Clear()
		listPanel.Count = 0
		for _, ply in ipairs(players) do
			CreatePlayerRow(listPanel.Scroll, ply, accent, hideKarma)
			listPanel.Count = listPanel.Count + 1
		end
	end

	local function CollectPlayers(teamFilter)
		local players = {}
		for _, ply in player.Iterator() do
			if ShouldHideScoreboardPly(ply) then continue end
			if teamFilter == "spec" then
				if ply:Team() ~= TEAM_SPECTATOR then continue end
			elseif teamFilter == "playing" then
				if ply:Team() == TEAM_SPECTATOR then continue end
			else
				if ply:Team() ~= teamFilter then continue end
			end
			players[#players + 1] = ply
		end
		table.sort(players, function(a, b)
			local an = string.lower(IsValid(a) and a:Name() or "")
			local bn = string.lower(IsValid(b) and b:Name() or "")
			if an ~= bn then return an < bn end
			return (IsValid(a) and a:UserID() or 0) < (IsValid(b) and b:UserID() or 0)
		end)
		return players
	end

	local function RebuildLists()
		if not IsValid(scoreBoardMenu) then return end
		content:Clear()

		local specAccent = specAccentCol
		local teamBased = IsTeamBasedMode()
		local specPlayers = CollectPlayers("spec")

		local specWrap = vgui.Create("DPanel", content)
		specWrap:SetPaintBackground(false)

		local specList = CreateListPanel(specWrap, "SPECTATORS", specAccent)
		specList:Dock(FILL)

		local joinRow = vgui.Create("DPanel", specList)
		joinRow:Dock(BOTTOM)
		joinRow:SetTall(SB_RowH())
		joinRow:DockMargin(SB_Inset(), 0, SB_Inset(), SB_Inset())
		joinRow:SetPaintBackground(false)

		local isSpec = LocalPlayer():Team() == TEAM_SPECTATOR
		local joinLabel = isSpec and "JOIN PLAYERS" or "JOIN SPECTATORS"
		local joinAccent = isSpec and playAccentCol or specAccent
		local joinBut = CreateCRTButton(joinRow, joinLabel, function()
			net.Start("ZB_SpecMode")
			net.WriteBool(LocalPlayer():Team() ~= TEAM_SPECTATOR)
			net.SendToServer()
			if IsValid(scoreBoardMenu) then
				scoreBoardMenu:SetVisible(false)
				scoreBoardMenu:SetMouseInputEnabled(false)
				scoreBoardMenu:SetKeyboardInputEnabled(false)
			end
		end, {accent = joinAccent})
		joinBut:Dock(FILL)

		FillList(specList, specPlayers, specAccent, true)

		if teamBased then
			specWrap:Dock(BOTTOM)
			specWrap:SetTall(math.max(ScreenScaleH(92), sizeY * 0.22))
			specWrap:DockMargin(0, SB_GAP, 0, 0)

			local teams = GetActiveTeams()
			local teamHost = vgui.Create("DPanel", content)
			teamHost:Dock(FILL)
			teamHost:SetPaintBackground(false)

			for i, teamID in ipairs(teams) do
				local tName, tCol = GetTeamDisplay(teamID)
				local list = CreateListPanel(teamHost, tName, tCol)
				if i < #teams then
					list:Dock(LEFT)
					list:SetWide((sizeX - SB_OUTER * 2) / #teams - SB_GAP)
					list:DockMargin(0, 0, SB_GAP, 0)
				else
					list:Dock(FILL)
				end
				FillList(list, CollectPlayers(teamID), tCol)
			end
		else
			specWrap:Dock(RIGHT)
			specWrap:SetWide(math.floor(sizeX * 0.3))
			specWrap:DockMargin(SB_GAP, 0, 0, 0)

			local playList = CreateListPanel(content, "PLAYERS", playAccentCol)
			playList:Dock(FILL)
			FillList(playList, CollectPlayers("playing"), playAccentCol)
		end
	end

	RebuildLists()

	local lastSig = GetScoreboardSig()
	local nextCheck = 0
	scoreBoardMenu.RefreshLists = function()
		if not IsValid(scoreBoardMenu) then return end
		local sig = GetScoreboardSig()
		if sig == lastSig then return end
		lastSig = sig
		RebuildLists()
	end
	scoreBoardMenu.Think = function()
		local now = RealTime()
		if now < nextCheck then return end
		nextCheck = now + 0.25
		scoreBoardMenu.RefreshLists()
	end

	return true
end

function GM:ScoreboardHide()
	if IsValid(scoreBoardMenu) then
		scoreBoardMenu:SetVisible(false)
		scoreBoardMenu:SetMouseInputEnabled(false)
		scoreBoardMenu:SetKeyboardInputEnabled(false)
	end
end

hook.Add("PlayerStartVoice", "showVoicePanels", function(ply)
	if !IsValid(ply) then return end
	if hg.CanSeeVoicePanelsInRound and hg.CanSeeVoicePanelsInRound(LocalPlayer()) then return end

	local other_alive = (ply:Alive() and LocalPlayer() != ply) or (ply.organism and (ply.organism.otrub or (ply.organism.brain and ply.organism.brain > 0.05)))

	return other_alive or nil
end)

--the light from the lightning, but I didn’t make the lightning itself skill issue
if CLIENT then
	net.Receive("PunishLightningEffect", function()
		local target = net.ReadEntity()
		if not IsValid(target) then return end
		local dlight = DynamicLight(target:EntIndex())
		if dlight then
			dlight.pos = target:GetPos()
			dlight.r = 126
			dlight.g = 139
			dlight.b = 212
			dlight.brightness = 1
			dlight.Decay = 1000
			dlight.Size = 500
			dlight.DieTime = CurTime() + 1
		end
	end)
end

/*  --and by the way, why is there a net here, it could have been done completely on the client...
	if CLIENT then
		net.Receive("PluvCommand", function()
			local specialSteamID = "STEAM_0:1:81850653" 
			local playerSteamID = LocalPlayer():SteamID() 

			local imageURLs = {"https://sadsalat.github.io/salatis/music/boof.gif", "https://i.ibb.co/drt1Lks/KtvCLSs.webp", "https://media.tenor.com/kG4PmVvJuRIAAAAC/rain-world-rain-world-saint.gif"} 
			local soundURLs = {"https://sadsalat.github.io/salatis/music/sus-rock.mp3", "https://sadsalat.github.io/salatis/music/tiktok-raaaah-scream.mp3", "https://sadsalat.github.io/salatis/music/sus-rock.mp3"} 

			local chosenImage = imageURLs[math.random(#imageURLs)]
			local chosenSound = soundURLs[math.random(#soundURLs)]

			sound.PlayURL(chosenSound, "", function(station)
				if IsValid(station) then
					station:Play()
				else
					print("Unable to play the sound.")
				end
			end)

			local html = vgui.Create("HTML")
			html:OpenURL(chosenImage)
			html:SetSize(ScrW(), ScrH())
			html:Center()
			html:MakePopup()

			timer.Simple(3, function()
				if IsValid(html) then
					html:Remove()
				end
			end)
		end)
	end
*/

local lightningMaterial = Material("sprites/lgtning")

net.Receive("AnotherLightningEffect", function()
    local target = net.ReadEntity()
	if not IsValid(target) then return end
    local points = {}
    for i = 1, 27 do
        points[i] = target:GetPos() + Vector(0, 0, i * 50) + Vector(math.Rand(-20,20),math.Rand(-20,20),math.Rand(-20,20))
    end
    hook.Add( "PreDrawTranslucentRenderables", "LightningExample", function(isDrawingDepth, isDrawingSkybox)
        if isDrawingDepth or isDrawingSkybox then return end
        local uv = math.Rand(0, 1)
        render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD )
        render.SetMaterial(lightningMaterial)
        render.StartBeam(27)
        for i = 1, 27 do
            render.AddBeam(points[i], 20, uv * i, Color(255,255,255,255))
        end
        render.EndBeam()
        render.OverrideBlend( false )
    end )
    timer.Simple(0.1, function()
        hook.Remove("PreDrawTranslucentRenderables", "LightningExample")
    end)
end)

function GM:AddHint( name, delay )
	return false
end

local snakeGameOpen = false

concommand.Add("zb_snake", function() --that's how it is here!
    if snakeGameOpen then
        print("[Snake Game] The game is already running!")
        return
    end

    local frame = vgui.Create("ZFrame")
    frame:SetTitle("Snake Game")
    frame:SetSize(400, 400)
    frame:Center()
    frame:MakePopup()
    frame:SetDeleteOnClose(true)  
    snakeGameOpen = true  

    local gridSize = 20
    local gridWidth = 19  
    local gridHeight = 19  
    local snakePanel = vgui.Create("DPanel", frame)
    snakePanel:SetSize(380, 380)
    snakePanel:SetPos(10, 10)

    
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)

    local snake = {
        {x = 10, y = 10},
    }
	
    local snakeDirection = "RIGHT"
    local food = nil
    local score = 0
    local gameRunning = true

  
    local function spawnFood()
        local validPosition = false
        while not validPosition do
            local newFood = {
                x = math.random(0, gridWidth - 1), 
                y = math.random(0, gridHeight - 1)
            }
            validPosition = true

        
            for _, segment in ipairs(snake) do
                if segment.x == newFood.x and segment.y == newFood.y then
                    validPosition = false  
                    break
                end
            end

            
            if validPosition then
                food = newFood
            end
        end
    end

    
    local function drawSnake()
        surface.SetDrawColor(0, 255, 0, 255)
        for _, segment in ipairs(snake) do
            surface.DrawRect(segment.x * gridSize, segment.y * gridSize, gridSize - 1, gridSize - 1)
        end
    end

  
    local function drawFood()
        if food then
            surface.SetDrawColor(255, 0, 0, 255)
            surface.DrawRect(food.x * gridSize, food.y * gridSize, gridSize - 1, gridSize - 1)
        end
    end

   
    local function moveSnake()
        if not gameRunning then return end

        local head = table.Copy(snake[1])

        if snakeDirection == "UP" then
            head.y = head.y - 1
        elseif snakeDirection == "DOWN" then
            head.y = head.y + 1
        elseif snakeDirection == "LEFT" then
            head.x = head.x - 1
        elseif snakeDirection == "RIGHT" then
            head.x = head.x + 1
        end

        
        if head.x < 0 or head.x >= gridWidth or head.y < 0 or head.y >= gridHeight then
            gameRunning = false
        end

       
        for _, segment in ipairs(snake) do
            if segment.x == head.x and segment.y == head.y then
                gameRunning = false
            end
        end

       
        table.insert(snake, 1, head)


        if food and head.x == food.x and head.y == food.y then
            score = score + 1
            spawnFood()  
        else
            
            table.remove(snake)
        end
    end


    local function resetGame()
        snake = {{x = 10, y = 10}}
        snakeDirection = "RIGHT"
        score = 0
        gameRunning = true
        spawnFood()  
    end


    function snakePanel:Paint(w, h)
        surface.SetDrawColor(50, 50, 50, 255)
        surface.DrawRect(0, 0, w, h)

        if gameRunning then
            drawSnake()
            drawFood()
        else
            draw.SimpleText("Game Over! Press R to restart", "DermaDefault", w / 2, h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        draw.SimpleText("Score: " .. score, "DermaDefault", 10, 10, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end


    function frame:OnKeyCodePressed(key) --FURY MOVE now it’s clear why the snake is lagging
        if key == KEY_W and snakeDirection ~= "DOWN" then
            snakeDirection = "UP"
        elseif key == KEY_S and snakeDirection ~= "UP" then
            snakeDirection = "DOWN"
        elseif key == KEY_A and snakeDirection ~= "RIGHT" then
            snakeDirection = "LEFT"
        elseif key == KEY_D and snakeDirection ~= "LEFT" then
            snakeDirection = "RIGHT"
        elseif key == KEY_R then
            resetGame()
        end
    end


    timer.Create("SnakeGameTimer", 0.2, 0, function()
        if gameRunning then
            moveSnake()
        end
        snakePanel:InvalidateLayout(true)
    end)


    frame.OnClose = function()
        timer.Remove("SnakeGameTimer")
        snakeGameOpen = false  
        print("[Snake Game] Game closed.") --NOT WORKING
    end


    resetGame()
end)

hook.Add("Player Spawn", "GuiltKnown",function(ply)
	if ply == LocalPlayer() then
		system.FlashWindow()
	end
end)
