if not hg or not hg.AdminSystem then return end

local AS = hg.AdminSystem
ESP = ESP or {}

ESP.Enabled = false
ESP.InAdminMode = false
ESP.AllESP = false
ESP.NextToggle = 0

local adminESPEye = ConVarExists("zb_espeye") and GetConVar("zb_espeye") or CreateClientConVar("zb_espeye", "0", true, false, "Show admin ESP eye trace line")
local adminESPTextColor = Color(235, 235, 235)
local adminESPWeaponColor = Color(255, 200, 100)

local adminESPUserGroups = {
	["superadmin"] = true,
	["owner"] = true,
	["servermanager"] = true,
	["headdeveloper"] = true,
	["headadmin"] = true,
	["developer"] = true,
	["admin"] = true,
}

local adminESPDefaultColor = Color(255, 0, 0)
local adminESPRoleColors = {
	traitor = Color(255, 60, 60),
	innocent = Color(70, 220, 70),
	gunner = Color(70, 140, 255),
}
local adminESPRoleLabels = {
	traitor = "Traitor",
	innocent = "Innocent",
	gunner = "Gunner",
}
local adminESPRoleModes = {
	["hmcd"] = true,
	["fear"] = true,
}
local ROLE_SYNC_TRAITOR_KEY = "AS_ESP_IsTraitor"
local ROLE_SYNC_GUNNER_KEY = "AS_ESP_IsGunner"
local ROLE_SYNC_KNOWN_KEY = "AS_ESP_RoleKnown"

local function CanUseAdminESP(ply)
	if not IsValid(ply) then return false end
	return adminESPUserGroups[string.lower(ply:GetUserGroup() or "")] == true
end

local function IsAdminESPActive()
	return IsValid(LocalPlayer()) and ESP.Enabled
end

local function IsAdminESPRoleMode()
	if not AS or not AS.GetCurrentMode then return false end
	local mode = AS:GetCurrentMode()
	return mode and adminESPRoleModes[mode] == true or false
end

local function GetAdminESPEntity(ply)
	if not IsValid(ply) then return NULL end

	local ent = hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply) or ply

	return IsValid(ent) and ent or ply
end

local function GetAdminESPTeamColor(ply)
	if not IsValid(ply) then return adminESPDefaultColor end

	if zb.TeamESP and zb.TeamESP.IsTeamRound and zb.TeamESP.IsTeamRound() then
		local teamCol = zb.TeamESP.GetTeamColor(ply)
		if teamCol then return teamCol end
	end

	local teamColor = team.GetColor(ply:Team())
	if teamColor and (teamColor.r ~= 255 or teamColor.g ~= 255 or teamColor.b ~= 255) then
		return Color(teamColor.r, teamColor.g, teamColor.b, 255)
	end

	return adminESPDefaultColor
end

local function GetAdminESPRoleKey(ply)
	if not IsValid(ply) or not IsAdminESPRoleMode() then return nil end

	-- Server-synced roles (mid-round joins never get HMCD_RoundStart for other players)
	if ply:GetNWBool(ROLE_SYNC_KNOWN_KEY, false) then
		if ply:GetNWBool(ROLE_SYNC_TRAITOR_KEY, false) then return "traitor" end
		if ply:GetNWBool(ROLE_SYNC_GUNNER_KEY, false) then return "gunner" end

		return "innocent"
	end

	if ply.isTraitor == true then return "traitor" end
	if ply.isGunner == true then return "gunner" end
	if ply.isTraitor == false or ply.isGunner == false then return "innocent" end

	return nil
end

local function GetAdminESPColor(ply, useRoleMode)
	if useRoleMode then
		local roleKey = GetAdminESPRoleKey(ply)
		if roleKey and adminESPRoleColors[roleKey] then
			return adminESPRoleColors[roleKey]
		end
	end

	return GetAdminESPTeamColor(ply)
end

local function GetAdminESPRoleLabel(ply, useRoleMode)
	if not useRoleMode then return nil end
	local roleKey = GetAdminESPRoleKey(ply)
	return roleKey and adminESPRoleLabels[roleKey] or nil
end

local function GetAdminESPWeaponLabel(wep)
	if not IsValid(wep) then return "none" end

	return wep:GetClass()
end

local function ShouldDrawAdminESPFor(localPly, target)
	if not IsValid(target) then return false end
	if target == localPly then return false end
	if target:Team() == TEAM_SPECTATOR then return false end
	if not target:Alive() then return false end

	return IsValid(GetAdminESPEntity(target))
end

local function GetAdminESPLabelTopPos(ent)
	local maxs = ent:OBBMaxs()

	return ent:GetPos() + Vector(0, 0, maxs.z + 14)
end

local function GetAdminESPLabelBottomPos(ent)
	local mins = ent:OBBMins()

	return ent:GetPos() + Vector(0, 0, mins.z - 14)
end

function ESP:Init()
	self:SetupNetworking()
	self:SetupHooks()
end

function ESP:SetupNetworking()
	net.Receive("AS_Sync", function()
		ESP.Enabled = net.ReadBool()
		ESP.InAdminMode = net.ReadBool()
		ESP.AllESP = net.ReadBool()
	end)
end

function ESP:SetupHooks()
	hook.Remove("PlayerButtonDown", "ZB_AdminESP_ToggleKey")
	hook.Remove("SetupOutlines", "ZB_AdminESP_Outlines")
	hook.Remove("PreDrawHUD", "ZB_AdminESP_EyeTrace")
	hook.Remove("HUDPaint", "ZB_AdminESP_HUD")

	hook.Add("PlayerButtonDown", "ZB_AdminESP_ToggleKey", function(ply, button)
		if ply ~= LocalPlayer() then return end
		if button ~= KEY_O then return end
		if gui.IsGameUIVisible() or vgui.GetKeyboardFocus() then return end
		if RealTime() < ESP.NextToggle then return end

		ESP.NextToggle = RealTime() + 0.3
		RunConsoleCommand("zb_admesp")
	end)

	hook.Add("SetupOutlines", "ZB_AdminESP_Outlines", function(outline_Add)
		if not IsAdminESPActive() then return end
		if not CanUseAdminESP(LocalPlayer()) then return end
		if not zb.ESPPerf or not zb.ESPPerf.ShouldDrawOutlines() then return end

		local ply = LocalPlayer()
		local useRoleMode = IsAdminESPRoleMode()
		local targets = zb.ESPPerf.BuildTargets(ply, ShouldDrawAdminESPFor, GetAdminESPEntity, nil, "admin_outline")

		zb.ESPPerf.AddGroupedOutlines(outline_Add, targets, function(targetPly)
			return GetAdminESPColor(targetPly, useRoleMode)
		end, function(targetPly)
			return useRoleMode and (GetAdminESPRoleKey(targetPly) or targetPly:Team()) or targetPly:Team()
		end)
	end)

	hook.Add("PreDrawHUD", "ZB_AdminESP_EyeTrace", function()
		if not adminESPEye:GetBool() then return end
		if not IsAdminESPActive() then return end
		if not CanUseAdminESP(LocalPlayer()) then return end

		local ply = LocalPlayer()
		local useRoleMode = IsAdminESPRoleMode()
		local targets = zb.ESPPerf and zb.ESPPerf.BuildTargets(ply, ShouldDrawAdminESPFor, GetAdminESPEntity, nil, "admin_eye") or {}

		if #targets == 0 then return end

		cam.Start3D()
			for i = 1, #targets do
				local target = targets[i].ply
				local col = GetAdminESPColor(target, useRoleMode)
				local eyePos = target:EyePos()
				local endPos = eyePos + target:EyeAngles():Forward() * 10000

				render.DrawLine(eyePos, endPos, col, true)
			end
		cam.End3D()
	end)

	hook.Add("HUDPaint", "ZB_AdminESP_HUD", function()
		if not IsAdminESPActive() then return end
		if not CanUseAdminESP(LocalPlayer()) then return end
		if not zb.ESPPerf or not zb.ESPPerf.ShouldDrawHUDThisFrame() then return end

		local ply = LocalPlayer()
		local origin = EyePos()
		local useRoleMode = IsAdminESPRoleMode()
		local targets = zb.ESPPerf.BuildTargets(ply, ShouldDrawAdminESPFor, GetAdminESPEntity, origin, "admin_hud")

		for i = 1, #targets do
			local entry = targets[i]
			local target = entry.ply
			local ent = entry.ent
			local col = GetAdminESPColor(target, useRoleMode)
			local roleLabel = GetAdminESPRoleLabel(target, useRoleMode)

			local topScreen = GetAdminESPLabelTopPos(ent):ToScreen()
			if not topScreen.visible then continue end

			local distance = zb.ESPPerf.GetDistanceMeters(origin, ent)

			draw.SimpleTextOutlined(target:Nick(), "TargetIDSmall", topScreen.x, topScreen.y - 10, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
			draw.SimpleTextOutlined(distance .. " m", "TargetIDSmall", topScreen.x, topScreen.y + 5, adminESPTextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)

			local bottomScreen = GetAdminESPLabelBottomPos(ent):ToScreen()
			if not bottomScreen.visible then continue end

			if roleLabel then
				draw.SimpleTextOutlined(roleLabel, "TargetIDSmall", bottomScreen.x, bottomScreen.y - 10, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
			end

			draw.SimpleTextOutlined(GetAdminESPWeaponLabel(target:GetActiveWeapon()), "TargetIDSmall", bottomScreen.x, bottomScreen.y + 5, adminESPWeaponColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
		end
	end)
end

AS:RegisterModule("esp", ESP)
