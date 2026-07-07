hg = hg or {}

local zb_voicechat_panel_groups

if SERVER then
	zb_voicechat_panel_groups = ConVarExists("zb_voicechat_panel_groups") and GetConVar("zb_voicechat_panel_groups") or CreateConVar(
		"zb_voicechat_panel_groups",
		"superadmin,owner,servermanager,headdeveloper,headadmin,developer,admin,moderator",
		bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY),
		"Comma-separated ULX/ULib groups allowed to use admin voice panels."
	)
end

local function metersToSourceUnits(meters)
	return meters * 52.4934
end

local function groupCanSeeVoicePanels(groupName)
	groupName = string.lower(string.Trim(groupName or ""))
	if groupName == "" then return false end

	local cvar = zb_voicechat_panel_groups or GetConVar("zb_voicechat_panel_groups")
	local allowList = string.Trim((cvar and cvar:GetString()) or "")
	if allowList == "" then return false end

	for _, rawGroup in ipairs(string.Explode(",", allowList, false)) do
		local wantedGroup = string.lower(string.Trim(rawGroup or ""))
		if wantedGroup ~= "" and wantedGroup == groupName then
			return true
		end
	end

	return false
end

if SERVER then
	util.AddNetworkString("ZB_AdminVoicePanelState")
	util.AddNetworkString("ZB_AdminVoicePanelAccess")
	util.AddNetworkString("ZB_AdminVoicePanelSnapshotRequest")
	util.AddNetworkString("ZB_AdminVoicePanelSetDistance")

	local adminVoicePanelState = {}
	local adminVoicePanelRefresh = {}
	local adminVoicePanelAccess = {}
	local adminVoicePanelAccessRefresh = {}
	local adminVoiceSpeakingUntil = {}
	local zb_admin_show_voicechat_distance_value = ConVarExists("zb_admin_show_voicechat_distance_value") and GetConVar("zb_admin_show_voicechat_distance_value") or CreateConVar(
		"zb_admin_show_voicechat_distance_value",
		"500",
		bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY),
		"Admin voice panel distance in meters.",
		1,
		500
	)
	local zb_admin_show_voicechat_require_pvs = ConVarExists("zb_admin_show_voicechat_require_pvs") and GetConVar("zb_admin_show_voicechat_require_pvs") or CreateConVar(
		"zb_admin_show_voicechat_require_pvs",
		"0",
		bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY),
		"Require admin voice panel listeners to have the speaker in PVS.",
		0,
		1
	)

	local function playerCanSeeVoicePanels(ply)
		if not IsValid(ply) then return false end

		local userGroup = (ply.GetUserGroup and ply:GetUserGroup()) or ""
		return groupCanSeeVoicePanels(userGroup)
	end

	local function getAdminVoicePanelDistanceMeters()
		return math.Clamp(zb_admin_show_voicechat_distance_value:GetFloat(), 1, 500)
	end

	local function getAdminVoicePanelDistanceSqr()
		local units = metersToSourceUnits(getAdminVoicePanelDistanceMeters())
		return units * units
	end

	local function isAdminVoicePanelSpectating(listener)
		if not IsValid(listener) then return false end
		if not listener:Alive() then return true end
		if IsValid(listener:GetNWEntity("spect", NULL)) then return true end
		if IsValid(listener:GetObserverTarget()) then return true end

		return false
	end

	local function printAdminVoiceDistance(target, value)
		local msg = string.format("[ZB Voice] Distanz ist aktuell auf %s Meter gesetzt.", value)

		if IsValid(target) then
			target:PrintMessage(HUD_PRINTCONSOLE, msg .. "\n")
		else
			print(msg)
		end
	end

	local function setAdminVoiceDistance(target, rawValue)
		if rawValue == nil or rawValue == "" then
			printAdminVoiceDistance(target, getAdminVoicePanelDistanceMeters())
			return
		end

		local distance = tonumber(rawValue)
		if not distance then
			local msg = "[ZB Voice] Bitte eine Zahl in Metern angeben.\n"
			if IsValid(target) then
				target:PrintMessage(HUD_PRINTCONSOLE, msg)
			else
				print(msg)
			end
			return
		end

		distance = math.Clamp(math.Round(distance, 2), 1, 500)
		RunConsoleCommand("zb_admin_show_voicechat_distance_value", tostring(distance))
		printAdminVoiceDistance(target, distance)
	end

	local function markAdminVoiceTalker(speaker, holdTime)
		if not IsValid(speaker) or not speaker:IsPlayer() then return end

		adminVoiceSpeakingUntil[speaker] = math.max(adminVoiceSpeakingUntil[speaker] or 0, CurTime() + holdTime)
	end

	function hg.AdminVoicePanelMarkSpeaking(speaker)
		markAdminVoiceTalker(speaker, 0.75)
	end

	local function isAdminVoiceTalkerSpeaking(talker)
		if not IsValid(talker) then return false end

		return (adminVoiceSpeakingUntil[talker] or 0) > CurTime()
	end

	hook.Add("StartVoice", "ZB_AdminVoicePanelTrackStart", function(speaker)
		markAdminVoiceTalker(speaker, 1.5)
	end)

	hook.Add("EndVoice", "ZB_AdminVoicePanelTrackEnd", function(speaker)
		if IsValid(speaker) and speaker:IsPlayer() and (adminVoiceSpeakingUntil[speaker] or 0) > CurTime() then
			adminVoiceSpeakingUntil[speaker] = CurTime() + 0.35
		end
	end)

	local function canAdminSeeVoicePanel(listener, talker)
		if not IsValid(listener) or not IsValid(talker) or listener == talker then return false end
		if not isAdminVoiceTalkerSpeaking(talker) then return false end
		if not isAdminVoicePanelSpectating(listener) and listener:EyePos():DistToSqr(talker:EyePos()) > getAdminVoicePanelDistanceSqr() then return false end
		if zb_admin_show_voicechat_require_pvs:GetBool() and not listener:TestPVS(talker) then return false end

		return true
	end

	local function sendAdminVoicePanelAccess(listener, allowed)
		if not IsValid(listener) then return end

		net.Start("ZB_AdminVoicePanelAccess")
			net.WriteBool(allowed and true or false)
		net.Send(listener)
	end

	local function sendAdminVoicePanelState(listener, talker, isSpeaking)
		if not IsValid(listener) or not IsValid(talker) then return end

		net.Start("ZB_AdminVoicePanelState")
			net.WriteEntity(talker)
			net.WriteBool(isSpeaking and true or false)
		net.Send(listener)
	end

	timer.Create("ZB_AdminVoicePanelStateSync", 0.15, 0, function()
		local humans = player.GetHumans()
		local activeListeners = {}
		local now = CurTime()

		for _, listener in ipairs(humans) do
			local allowed = playerCanSeeVoicePanels(listener)
			if adminVoicePanelAccess[listener] ~= allowed or (adminVoicePanelAccessRefresh[listener] or 0) <= now then
				adminVoicePanelAccess[listener] = allowed
				adminVoicePanelAccessRefresh[listener] = now + 5
				sendAdminVoicePanelAccess(listener, allowed)
			end

			if allowed then
				activeListeners[listener] = true

				local states = adminVoicePanelState[listener] or {}
				local refresh = adminVoicePanelRefresh[listener] or {}
				local validTalkers = {}
				adminVoicePanelState[listener] = states
				adminVoicePanelRefresh[listener] = refresh

				for _, talker in ipairs(humans) do
					if listener == talker then continue end

					validTalkers[talker] = true

					local shouldShow = canAdminSeeVoicePanel(listener, talker)
					if states[talker] ~= shouldShow then
						states[talker] = shouldShow
						refresh[talker] = shouldShow and (now + 0.75) or nil
						sendAdminVoicePanelState(listener, talker, shouldShow)
					elseif shouldShow and (refresh[talker] or 0) <= now then
						refresh[talker] = now + 0.75
						sendAdminVoicePanelState(listener, talker, true)
					end
				end

				for talker, wasShowing in pairs(states) do
					if not IsValid(talker) or not validTalkers[talker] then
						if wasShowing and IsValid(talker) then
							sendAdminVoicePanelState(listener, talker, false)
						end

						states[talker] = nil
						refresh[talker] = nil
					end
				end
			elseif adminVoicePanelState[listener] then
				for talker, wasShowing in pairs(adminVoicePanelState[listener]) do
					if wasShowing and IsValid(talker) then
						sendAdminVoicePanelState(listener, talker, false)
					end
				end

				adminVoicePanelState[listener] = nil
				adminVoicePanelRefresh[listener] = nil
			end
		end

		for listener in pairs(adminVoicePanelState) do
			if not IsValid(listener) or not activeListeners[listener] then
				adminVoicePanelState[listener] = nil
				adminVoicePanelRefresh[listener] = nil
			end
		end

		for listener in pairs(adminVoicePanelAccess) do
			if not IsValid(listener) then
				adminVoicePanelAccess[listener] = nil
				adminVoicePanelAccessRefresh[listener] = nil
			end
		end

		for talker, expire_time in pairs(adminVoiceSpeakingUntil) do
			if not IsValid(talker) or expire_time <= now then
				adminVoiceSpeakingUntil[talker] = nil
			end
		end
	end)

	net.Receive("ZB_AdminVoicePanelSnapshotRequest", function(_, ply)
		if not playerCanSeeVoicePanels(ply) then return end

		local states = adminVoicePanelState[ply] or {}
		adminVoicePanelState[ply] = states

		for talker, wasShowing in pairs(states) do
			if wasShowing and IsValid(talker) then
				sendAdminVoicePanelState(ply, talker, true)
			end
		end

		for _, talker in ipairs(player.GetHumans()) do
			if talker ~= ply and canAdminSeeVoicePanel(ply, talker) and not states[talker] then
				states[talker] = true
				sendAdminVoicePanelState(ply, talker, true)
			end
		end
	end)

	net.Receive("ZB_AdminVoicePanelSetDistance", function(_, ply)
		if not playerCanSeeVoicePanels(ply) then
			ply:PrintMessage(HUD_PRINTCONSOLE, "[ZB Voice] Keine Berechtigung fuer diesen Befehl.\n")
			return
		end

		setAdminVoiceDistance(ply, net.ReadString())
	end)

	concommand.Add("zb_admin_show_voicechat_distance", function(ply, _, args)
		if IsValid(ply) and not playerCanSeeVoicePanels(ply) then
			ply:PrintMessage(HUD_PRINTCONSOLE, "[ZB Voice] Keine Berechtigung fuer diesen Befehl.\n")
			return
		end

		setAdminVoiceDistance(ply, args[1])
	end)

	concommand.Add("zb_admin_voice_status", function(ply)
		if IsValid(ply) and not playerCanSeeVoicePanels(ply) then
			ply:PrintMessage(HUD_PRINTCONSOLE, "[ZB Voice] Keine Berechtigung fuer diesen Befehl.\n")
			return
		end

		local target = IsValid(ply) and ply or nil
		local now = CurTime()
		local lines = {
			"[ZB Voice] Admin voice status:",
			string.format("  distance=%sm require_pvs=%s", getAdminVoicePanelDistanceMeters(), zb_admin_show_voicechat_require_pvs:GetBool() and "1" or "0")
		}

		if IsValid(ply) then
			lines[#lines + 1] = string.format("  listener=%s group=%s allowed=%s spectating=%s", ply:Nick(), ply:GetUserGroup(), playerCanSeeVoicePanels(ply) and "yes" or "no", isAdminVoicePanelSpectating(ply) and "yes" or "no")
		end

		for _, talker in ipairs(player.GetHumans()) do
			local expireTime = adminVoiceSpeakingUntil[talker] or 0
			if expireTime > now then
				lines[#lines + 1] = string.format("  speaking=%s %.2fs", talker:Nick(), expireTime - now)
			end
		end

		local text = table.concat(lines, "\n") .. "\n"
		if target then
			target:PrintMessage(HUD_PRINTCONSOLE, text)
		else
			print(text)
		end
	end)

	return
end

local AdminShowVoiceChat = CreateClientConVar(
	"zb_admin_show_voicechat",
	"1",
	true,
	false,
	"Enable admin voice panels for allowed groups. Persists until changed.",
	0,
	1
)

local adminVoicePanelSpeakers = {}
local adminVoicePanelSuppressUntil = {}
local serverAllowsAdminVoicePanels = false

surface.CreateFont("ZB_AdminVoicePanel_Name", {
	font = "Bahnschrift",
	size = math.max(15, ScreenScale(6)),
	weight = 700,
	extended = true,
	antialias = true
})

surface.CreateFont("ZB_AdminVoicePanel_Tag", {
	font = "Bahnschrift",
	size = math.max(10, ScreenScale(4)),
	weight = 700,
	extended = true,
	antialias = true
})

surface.CreateFont("ZB_AdminVoicePanel_Meta", {
	font = "Bahnschrift",
	size = math.max(9, ScreenScale(3)),
	weight = 600,
	extended = true,
	antialias = true
})

local function canSeeVoicePanelsInRound(lply)
	if not IsValid(lply) then return false end
	if not AdminShowVoiceChat:GetBool() then return false end

	return serverAllowsAdminVoicePanels
end

hg.CanSeeVoicePanelsInRound = canSeeVoicePanelsInRound

local function requestAdminVoicePanelSnapshot()
	local lply = LocalPlayer()
	if not IsValid(lply) or not AdminShowVoiceChat:GetBool() then return end

	net.Start("ZB_AdminVoicePanelSnapshotRequest")
	net.SendToServer()
end

local function removeDefaultVoicePanel(ply)
	if not IsValid(ply) or not IsValid(g_VoicePanelList) then return end

	for _, panel in ipairs(g_VoicePanelList:GetChildren()) do
		if IsValid(panel) and (panel.ply == ply or panel.Player == ply or panel.Target == ply) then
			panel:Remove()
		end
	end
end

local function suppressDefaultVoicePanel(ply, duration)
	if not IsValid(ply) then return end

	adminVoicePanelSuppressUntil[ply] = math.max(adminVoicePanelSuppressUntil[ply] or 0, CurTime() + (duration or 1.5))
	ply.IsSpeak = false
	removeDefaultVoicePanel(ply)
end

local function clearAdminVoicePanels()
	local lply = LocalPlayer()

	table.Empty(adminVoicePanelSpeakers)
	table.Empty(adminVoicePanelSuppressUntil)

	for _, ply in ipairs(player.GetHumans()) do
		if IsValid(ply) and ply ~= lply then
			ply.IsSpeak = false

			if GAMEMODE and GAMEMODE.PlayerEndVoice then
				GAMEMODE:PlayerEndVoice(ply)
			end
		end
	end
end

net.Receive("ZB_AdminVoicePanelState", function()
	local ply = net.ReadEntity()
	local isSpeaking = net.ReadBool()
	local lply = LocalPlayer()

	if not IsValid(ply) or not IsValid(lply) or ply == lply then return end
	if not AdminShowVoiceChat:GetBool() then return end

	adminVoicePanelSpeakers[ply] = isSpeaking and (CurTime() + 1.75) or nil

	if isSpeaking then
		suppressDefaultVoicePanel(ply, 2)
	else
		suppressDefaultVoicePanel(ply, 0.35)
	end
end)

net.Receive("ZB_AdminVoicePanelAccess", function()
	serverAllowsAdminVoicePanels = net.ReadBool()

	if serverAllowsAdminVoicePanels then
		requestAdminVoicePanelSnapshot()
	else
		clearAdminVoicePanels()
	end
end)

function hg.IsAdminVoicePanelActive(ply)
	return IsValid(ply) and (adminVoicePanelSpeakers[ply] or 0) > CurTime()
end

hook.Add("PlayerStartVoice", "ZB_AdminVoicePanelSuppressDefault", function(ply)
	local lply = LocalPlayer()
	if not IsValid(ply) or not canSeeVoicePanelsInRound(lply) then return end

	suppressDefaultVoicePanel(ply, 2)

	timer.Simple(0, function()
		if not IsValid(ply) then return end

		suppressDefaultVoicePanel(ply, 2)
	end)

	return true
end)

hook.Add("PlayerEndVoice", "ZB_AdminVoicePanelSuppressDefault", function(ply)
	if not IsValid(ply) then return end
	if not hg.IsAdminVoicePanelActive or not hg.IsAdminVoicePanelActive(ply) then return end

	suppressDefaultVoicePanel(ply, 0.35)
end)

local function endVoicePanel(ply)
	if IsValid(ply) then
		suppressDefaultVoicePanel(ply, 0.25)
	end

	adminVoicePanelSpeakers[ply] = nil

	if GAMEMODE and GAMEMODE.PlayerEndVoice then
		GAMEMODE:PlayerEndVoice(ply)
	end
end

hook.Add("Think", "ZB_AdminVoicePanelClientWatchdog", function()
	local lply = LocalPlayer()
	if not IsValid(lply) then return end

	local now = CurTime()

	if not canSeeVoicePanelsInRound(lply) then
		if next(adminVoicePanelSpeakers) or next(adminVoicePanelSuppressUntil) then
			clearAdminVoicePanels()
		end

		return
	end

	for ply, expireTime in pairs(adminVoicePanelSpeakers) do
		if not IsValid(ply) or expireTime <= now then
			endVoicePanel(ply)
		else
			suppressDefaultVoicePanel(ply, 0.45)
		end
	end

	for ply, expireTime in pairs(adminVoicePanelSuppressUntil) do
		if not IsValid(ply) or expireTime <= now then
			adminVoicePanelSuppressUntil[ply] = nil
		else
			ply.IsSpeak = false
			removeDefaultVoicePanel(ply)
		end
	end
end)

hook.Add("HUDPaint", "ZB_AdminVoicePanelHUD", function()
	local lply = LocalPlayer()
	if not canSeeVoicePanelsInRound(lply) then return end

	local speakers = {}
	for ply, expireTime in pairs(adminVoicePanelSpeakers) do
		if IsValid(ply) and expireTime > CurTime() then
			speakers[#speakers + 1] = ply
		end
	end

	if #speakers <= 0 then return end

	table.sort(speakers, function(a, b)
		return string.lower(a:Nick() or "") < string.lower(b:Nick() or "")
	end)

	local now = CurTime()
	local scale = math.Clamp(math.min(ScrW() / 1920, ScrH() / 1080), 0.78, 1)
	local rowH = math.floor(34 * scale)
	local w = math.floor(235 * scale)
	local pad = math.floor(9 * scale)
	local x = ScrW() - w - math.floor(26 * scale)
	local y = math.floor(ScrH() * 0.20)
	local gap = math.floor(5 * scale)

	for i, ply in ipairs(speakers) do
		local expireTime = adminVoicePanelSpeakers[ply] or 0
		local rowY = y + (i - 1) * (rowH + gap)
		local voice = math.Clamp((ply.VoiceVolume and ply:VoiceVolume()) or 0, 0, 1)
		local pulse = 0.5 + math.sin(now * 9 + i) * 0.18
		local fill = math.Clamp(math.max(voice, pulse * 0.28), 0.05, 1)
		local fade = math.Clamp((expireTime - now) / 0.4, 0, 1)
		local alpha = math.floor(235 * fade)
		local green = Color(35, 255, 120, alpha)
		local softGreen = Color(35, 255, 120, math.floor(alpha * 0.13))
		local textMain = Color(245, 255, 248, alpha)
		local textSoft = Color(135, 255, 175, math.floor(alpha * 0.86))

		surface.SetDrawColor(2, 8, 5, math.floor(alpha * 0.82))
		surface.DrawRect(x, rowY, w, rowH)

		surface.SetDrawColor(0, 0, 0, math.floor(alpha * 0.35))
		surface.DrawRect(x + 1, rowY + 1, w - 2, rowH - 2)

		surface.SetDrawColor(softGreen)
		surface.DrawRect(x, rowY, math.floor(w * fill), rowH)

		surface.SetDrawColor(green)
		surface.DrawRect(x, rowY, math.max(3, math.floor(4 * scale)), rowH)
		surface.DrawRect(x + math.floor(4 * scale), rowY, w - math.floor(4 * scale), 1)
		surface.DrawOutlinedRect(x, rowY, w, rowH, 1)

		local name = string.Trim(tostring(ply:Nick() or "Unknown"))
		name = string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
		draw.SimpleText("ADMIN VOICE", "ZB_AdminVoicePanel_Tag", x + pad, rowY + math.floor(4 * scale), textSoft, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

		render.SetScissorRect(x + pad, rowY, x + w - math.floor(62 * scale), rowY + rowH, true)
			draw.SimpleText(name, "ZB_AdminVoicePanel_Name", x + pad, rowY + math.floor(15 * scale), textMain, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		render.SetScissorRect(0, 0, 0, 0, false)

		local barsX = x + w - math.floor(51 * scale)
		local barsY = rowY + math.floor(10 * scale)
		local barW = math.max(2, math.floor(4 * scale))
		local barGap = math.max(2, math.floor(2 * scale))
		local maxBarH = math.floor(17 * scale)

		for bar = 1, 5 do
			local wave = math.Clamp(fill * (0.6 + math.sin(now * 11 + bar * 0.8 + i) * 0.28), 0.08, 1)
			local barH = math.max(math.floor(4 * scale), math.floor(maxBarH * wave))
			local bx = barsX + (bar - 1) * (barW + barGap)
			local by = barsY + maxBarH - barH

			surface.SetDrawColor(35, 255, 120, math.floor(alpha * (0.35 + wave * 0.55)))
			surface.DrawRect(bx, by, barW, barH)
		end

		draw.SimpleText("LIVE", "ZB_AdminVoicePanel_Meta", x + w - pad, rowY + math.floor(4 * scale), Color(255, 255, 255, math.floor(alpha * 0.58)), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	end
end)

hook.Add("InitPostEntity", "ZB_AdminVoicePanelSnapshot", function()
	timer.Simple(1, function()
		requestAdminVoicePanelSnapshot()
	end)
end)

cvars.AddChangeCallback("zb_admin_show_voicechat", function(_, _, newValue)
	if tobool(newValue) then
		requestAdminVoicePanelSnapshot()
	else
		clearAdminVoicePanels()
	end
end, "ZB_AdminVoiceChatToggle")

concommand.Add("zb_admin_show_voicechat_distance", function(_, _, args)
	net.Start("ZB_AdminVoicePanelSetDistance")
		net.WriteString(args[1] or "")
	net.SendToServer()
end)

concommand.Add("zb_admin_voice_status", function()
	print("[ZB Voice] Client status:")
	print("  enabled=" .. tostring(AdminShowVoiceChat:GetBool()) .. " server_allowed=" .. tostring(serverAllowsAdminVoicePanels))

	local count = 0
	for ply, expireTime in pairs(adminVoicePanelSpeakers) do
		if IsValid(ply) and expireTime > CurTime() then
			count = count + 1
			print(string.format("  visible=%s %.2fs", ply:Nick(), expireTime - CurTime()))
		end
	end

	if count <= 0 then
		print("  visible=none")
	end

	requestAdminVoicePanelSnapshot()
end)
