hg = hg or {}

local zb_voicechat_panel_groups

if SERVER then
	zb_voicechat_panel_groups = ConVarExists("zb_voicechat_panel_groups") and GetConVar("zb_voicechat_panel_groups") or CreateConVar(
		"zb_voicechat_panel_groups",
		"superadmin,owner,servermanager,headdeveloper,staffmanager,headadmin,developer,admin,moderator",
		bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY),
		"Comma-separated ULX/ULib groups allowed to use admin voice panels."
	)
end

local function groupCanSeeVoicePanels(groupName)
	groupName = string.lower(string.Trim(groupName or ""))
	if groupName == "" then return false end

	local cvar = zb_voicechat_panel_groups or GetConVar("zb_voicechat_panel_groups")
	local allowList = string.Trim((cvar and cvar:GetString()) or "")
	if allowList == "" then return false end

	for _, rawGroup in ipairs(string.Explode(",", allowList, false)) do
		if string.lower(string.Trim(rawGroup or "")) == groupName then
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
	local adminVoicePanelAccess = {}
	local adminVoicePanelAccessRefresh = {}
	local adminVoiceSpeaking = {}
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
		return IsValid(ply) and groupCanSeeVoicePanels((ply.GetUserGroup and ply:GetUserGroup()) or "")
	end

	local function getAdminVoicePanelDistanceMeters()
		return math.Clamp(zb_admin_show_voicechat_distance_value:GetFloat(), 1, 500)
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

	local function canAdminSeeVoicePanel(listener, talker)
		if not IsValid(listener) or not IsValid(talker) or adminVoiceSpeaking[talker] ~= true then return false end

		if not isAdminVoicePanelSpectating(listener) then
			local units = getAdminVoicePanelDistanceMeters() * 52.4934
			if listener:EyePos():DistToSqr(talker:EyePos()) > units * units then return false end
		end

		if zb_admin_show_voicechat_require_pvs:GetBool() and not listener:TestPVS(talker) then return false end

		return true
	end

	local function sendAdminVoicePanelState(listener, talker, isSpeaking)
		if not IsValid(listener) or not IsValid(talker) then return end

		net.Start("ZB_AdminVoicePanelState")
			net.WriteEntity(talker)
			net.WriteBool(isSpeaking and true or false)
		net.Send(listener)
	end

	local function syncAdminVoicePanelState(listener, talker, shouldShow)
		if not IsValid(listener) or not IsValid(talker) then return end

		local states = adminVoicePanelState[listener]
		if not states then
			states = {}
			adminVoicePanelState[listener] = states
		end

		if states[talker] == shouldShow then return end

		states[talker] = shouldShow
		sendAdminVoicePanelState(listener, talker, shouldShow)
	end

	local function pushAdminVoiceSpeakingState(talker)
		if not IsValid(talker) then return end

		for _, listener in ipairs(player.GetHumans()) do
			if playerCanSeeVoicePanels(listener) then
				syncAdminVoicePanelState(listener, talker, canAdminSeeVoicePanel(listener, talker))
			end
		end
	end

	local function setAdminVoiceSpeaking(speaker, speaking)
		if not IsValid(speaker) or not speaker:IsPlayer() then return end

		speaking = speaking and true or false
		if adminVoiceSpeaking[speaker] == speaking then return end

		adminVoiceSpeaking[speaker] = speaking or nil
		pushAdminVoiceSpeakingState(speaker)
	end

	function hg.AdminVoicePanelMarkSpeaking(speaker)
		setAdminVoiceSpeaking(speaker, true)
	end

	hook.Add("StartVoice", "ZB_AdminVoicePanelTrackStart", function(speaker)
		setAdminVoiceSpeaking(speaker, true)
	end)

	hook.Add("EndVoice", "ZB_AdminVoicePanelTrackEnd", function(speaker)
		setAdminVoiceSpeaking(speaker, false)
	end)

	timer.Create("ZB_AdminVoicePanelStateSync", 0.2, 0, function()
		local humans = player.GetHumans()
		local activeListeners = {}
		local now = CurTime()

		for _, listener in ipairs(humans) do
			local allowed = playerCanSeeVoicePanels(listener)
			if adminVoicePanelAccess[listener] ~= allowed or (adminVoicePanelAccessRefresh[listener] or 0) <= now then
				adminVoicePanelAccess[listener] = allowed
				adminVoicePanelAccessRefresh[listener] = now + 5

				net.Start("ZB_AdminVoicePanelAccess")
					net.WriteBool(allowed)
				net.Send(listener)
			end

			if allowed then
				activeListeners[listener] = true

				local states = adminVoicePanelState[listener] or {}
				adminVoicePanelState[listener] = states

				local validTalkers = {}
				for _, talker in ipairs(humans) do
					validTalkers[talker] = true
					syncAdminVoicePanelState(listener, talker, canAdminSeeVoicePanel(listener, talker))
				end

				for talker, wasShowing in pairs(states) do
					if not IsValid(talker) or not validTalkers[talker] then
						if wasShowing and IsValid(talker) then
							sendAdminVoicePanelState(listener, talker, false)
						end
						states[talker] = nil
					end
				end
			elseif adminVoicePanelState[listener] then
				for talker, wasShowing in pairs(adminVoicePanelState[listener]) do
					if wasShowing and IsValid(talker) then
						sendAdminVoicePanelState(listener, talker, false)
					end
				end
				adminVoicePanelState[listener] = nil
			end
		end

		for listener in pairs(adminVoicePanelState) do
			if not IsValid(listener) or not activeListeners[listener] then
				adminVoicePanelState[listener] = nil
			end
		end

		for listener in pairs(adminVoicePanelAccess) do
			if not IsValid(listener) then
				adminVoicePanelAccess[listener] = nil
				adminVoicePanelAccessRefresh[listener] = nil
			end
		end

		for talker in pairs(adminVoiceSpeaking) do
			if not IsValid(talker) or not talker:IsSpeaking() then
				setAdminVoiceSpeaking(talker, false)
			end
		end
	end)

	net.Receive("ZB_AdminVoicePanelSnapshotRequest", function(_, ply)
		if not playerCanSeeVoicePanels(ply) then return end

		adminVoicePanelState[ply] = adminVoicePanelState[ply] or {}
		for _, talker in ipairs(player.GetHumans()) do
			syncAdminVoicePanelState(ply, talker, canAdminSeeVoicePanel(ply, talker))
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

		local lines = {
			"[ZB Voice] Admin voice status:",
			string.format("  distance=%sm require_pvs=%s", getAdminVoicePanelDistanceMeters(), zb_admin_show_voicechat_require_pvs:GetBool() and "1" or "0")
		}

		if IsValid(ply) then
			lines[#lines + 1] = string.format("  listener=%s group=%s allowed=%s spectating=%s", ply:Nick(), ply:GetUserGroup(), playerCanSeeVoicePanels(ply) and "yes" or "no", isAdminVoicePanelSpectating(ply) and "yes" or "no")
		end

		for _, talker in ipairs(player.GetHumans()) do
			if adminVoiceSpeaking[talker] then
				lines[#lines + 1] = string.format("  speaking=%s", talker:Nick())
			end
		end

		local text = table.concat(lines, "\n") .. "\n"
		if IsValid(ply) then
			ply:PrintMessage(HUD_PRINTCONSOLE, text)
		else
			print(text)
		end
	end)

	return
end

local AdminShowVoiceChat = CreateClientConVar("zb_admin_show_voicechat", "1", true, false, "Enable admin voice panels for allowed groups. Persists until changed.", 0, 1)

local HANG_TIME, FADE_TIME = 1.5, 0.4
local CRT_R, CRT_G, CRT_B = 35, 225, 110
local FRAME_R, FRAME_G, FRAME_B = 86, 94, 90
local color_bezel = Color(12, 13, 13)
local color_panel = Color(20, 22, 21)
local color_text = Color(236, 238, 236)
local color_sub = Color(150, 154, 152)

local eligible, levels, slots, slotOwners, expiresAt, suppressUntil, avatars = {}, {}, {}, {}, {}, {}, {}
local serverAllowsAdminVoicePanels = false

local function S(n)
	return math.max(1, math.Round(n * ScrH() / 1080))
end

local function CreateFonts()
	surface.CreateFont("ZB_AdminVoice", {
		font = "Bahnschrift",
		size = math.max(14, S(17)),
		weight = 600,
		antialias = true,
		extended = true
	})
	surface.CreateFont("ZB_AdminVoiceSub", {
		font = "Bahnschrift",
		size = math.max(12, S(13)),
		weight = 500,
		antialias = true,
		extended = true
	})
end

CreateFonts()
hook.Add("OnScreenSizeChanged", "ZB_AdminVoiceFonts", CreateFonts)

local function canSeeVoicePanelsInRound(lply)
	return IsValid(lply) and AdminShowVoiceChat:GetBool() and serverAllowsAdminVoicePanels
end

hg.CanSeeVoicePanelsInRound = canSeeVoicePanelsInRound

local function requestSnapshot()
	if not IsValid(LocalPlayer()) or not AdminShowVoiceChat:GetBool() then return end

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

	suppressUntil[ply] = math.max(suppressUntil[ply] or 0, CurTime() + (duration or 0.35))
	ply.IsSpeak = false
	removeDefaultVoicePanel(ply)
end

local function takeSlot(ply)
	if slots[ply] then return slots[ply] end

	local slot = 1
	while slotOwners[slot] do
		slot = slot + 1
	end

	slots[ply] = slot
	slotOwners[slot] = ply
	return slot
end

local function dropAvatar(ply)
	local av = avatars[ply]
	if IsValid(av) then av:Remove() end
	avatars[ply] = nil
end

local function dropPanel(ply)
	local slot = slots[ply]
	if slot then slotOwners[slot] = nil end

	eligible[ply] = nil
	levels[ply] = nil
	expiresAt[ply] = nil
	slots[ply] = nil
	dropAvatar(ply)
end

local function hangPanel(ply)
	expiresAt[ply] = math.max(expiresAt[ply] or 0, CurTime() + HANG_TIME)
end

local function clearPanels()
	local lply = LocalPlayer()
	table.Empty(eligible)
	table.Empty(levels)
	table.Empty(slots)
	table.Empty(slotOwners)
	table.Empty(expiresAt)
	table.Empty(suppressUntil)

	for ply, av in pairs(avatars) do
		if IsValid(av) then av:Remove() end
		avatars[ply] = nil
	end

	for _, ply in ipairs(player.GetHumans()) do
		if IsValid(ply) and ply ~= lply then
			ply.IsSpeak = false
			if GAMEMODE and GAMEMODE.PlayerEndVoice then
				GAMEMODE:PlayerEndVoice(ply)
			end
		end
	end
end

local function shouldDraw(ply)
	if not IsValid(ply) or not slots[ply] then return false end
	if eligible[ply] and ply:IsSpeaking() then return true end

	return (expiresAt[ply] or 0) > CurTime()
end

function hg.IsAdminVoicePanelActive(ply)
	return IsValid(ply) and eligible[ply] and ply:IsSpeaking()
end

net.Receive("ZB_AdminVoicePanelState", function()
	local ply = net.ReadEntity()
	local speaking = net.ReadBool()
	if not IsValid(ply) or not AdminShowVoiceChat:GetBool() then return end

	if speaking then
		eligible[ply] = true
		expiresAt[ply] = nil
		takeSlot(ply)
		suppressDefaultVoicePanel(ply, 0.35)
	else
		eligible[ply] = nil
		if slots[ply] then
			hangPanel(ply)
		else
			dropPanel(ply)
		end
		suppressDefaultVoicePanel(ply, 0.1)
	end
end)

net.Receive("ZB_AdminVoicePanelAccess", function()
	serverAllowsAdminVoicePanels = net.ReadBool()
	if serverAllowsAdminVoicePanels then
		requestSnapshot()
	else
		clearPanels()
	end
end)

hook.Add("PlayerStartVoice", "ZB_AdminVoicePanelSuppressDefault", function(ply)
	local lply = LocalPlayer()
	if not IsValid(ply) or not canSeeVoicePanelsInRound(lply) then return end

	if ply == lply then
		eligible[ply] = true
		expiresAt[ply] = nil
		takeSlot(ply)
	end

	suppressDefaultVoicePanel(ply, 0.35)
	timer.Simple(0, function()
		if IsValid(ply) then suppressDefaultVoicePanel(ply, 0.35) end
	end)

	return true
end)

hook.Add("PlayerEndVoice", "ZB_AdminVoicePanelSuppressDefault", function(ply)
	if not IsValid(ply) then return end
	if slots[ply] or eligible[ply] then hangPanel(ply) end
	if hg.IsAdminVoicePanelActive(ply) then suppressDefaultVoicePanel(ply, 0.1) end
end)

hook.Add("Think", "ZB_AdminVoicePanelClientWatchdog", function()
	local lply = LocalPlayer()
	if not IsValid(lply) then return end

	if not canSeeVoicePanelsInRound(lply) then
		if next(eligible) or next(slots) or next(expiresAt) or next(suppressUntil) then
			clearPanels()
		end
		return
	end

	local ft = FrameTime()
	local stale
	for ply in pairs(slots) do
		if not IsValid(ply) or ((expiresAt[ply] or 0) > 0 and expiresAt[ply] <= CurTime() and not ply:IsSpeaking()) then
			stale = stale or {}
			stale[#stale + 1] = ply
		elseif ply:IsSpeaking() then
			expiresAt[ply] = nil
			eligible[ply] = true
			levels[ply] = Lerp(ft * 18, levels[ply] or 0, math.Clamp(((ply.VoiceVolume and ply:VoiceVolume()) or 0) * 3, 0, 1))
			suppressDefaultVoicePanel(ply, 0.2)
		else
			levels[ply] = Lerp(ft * 8, levels[ply] or 0, 0)
		end
	end

	if stale then
		for i = 1, #stale do
			dropPanel(stale[i])
		end
	end

	for ply, untilTime in pairs(suppressUntil) do
		if not IsValid(ply) or untilTime <= CurTime() then
			suppressUntil[ply] = nil
		else
			ply.IsSpeak = false
			removeDefaultVoicePanel(ply)
		end
	end
end)

hook.Add("HUDPaint", "ZB_AdminVoicePanelHUD", function()
	local lply = LocalPlayer()
	if not canSeeVoicePanelsInRound(lply) then return end

	local rowH, gap, pad, bezel = S(44), S(4), S(10), math.max(2, S(3))
	local w = S(240)
	local x = ScrW() - w - S(18)
	local bottom = ScrH() - S(18)
	local len = math.max(6, S(8))

	for ply, slot in pairs(slots) do
		if not shouldDraw(ply) then continue end

		local hang = 1
		if expiresAt[ply] and not ply:IsSpeaking() then
			local remaining = expiresAt[ply] - CurTime()
			if remaining <= 0 then continue end
			if remaining < FADE_TIME then hang = remaining / FADE_TIME end
		end

		local a = math.floor(255 * hang)
		local fill = levels[ply] or 0
		local y = bottom - slot * rowH - (slot - 1) * gap
		local ix, iy, iw, ih = x + bezel, y + bezel, w - bezel * 2, rowH - bezel * 2

		surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, math.floor(230 * hang))
		surface.DrawRect(x, y, w, rowH)
		surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, math.floor(150 * hang))
		surface.DrawOutlinedRect(ix, iy, iw, ih, 1)
		surface.SetDrawColor(CRT_R, CRT_G, CRT_B, math.floor(180 * hang))
		surface.DrawRect(ix, iy, len, 2)
		surface.DrawRect(ix, iy, 2, len)
		surface.DrawRect(ix + iw - len, iy, len, 2)
		surface.DrawRect(ix + iw - 2, iy, 2, len)
		surface.DrawRect(ix, iy + ih - 2, len, 2)
		surface.DrawRect(ix, iy + ih - len, 2, len)
		surface.DrawRect(ix + iw - len, iy + ih - 2, len, 2)
		surface.DrawRect(ix + iw - 2, iy + ih - len, 2, len)
		surface.SetDrawColor(color_panel.r, color_panel.g, color_panel.b, math.floor(210 * hang))
		surface.DrawRect(ix + 1, iy + 1, iw - 2, ih - 2)

		if fill > 0.02 then
			surface.SetDrawColor(CRT_R, CRT_G, CRT_B, math.floor(40 * hang))
			surface.DrawRect(ix + 1, iy + 1, math.floor((iw - 2) * fill), ih - 2)
		end

		local avSize = math.max(14, S(24))
		local avPad = math.floor((ih - avSize) * 0.5)
		local avX, avY = ix + avPad, iy + avPad
		local av = avatars[ply]
		if not IsValid(av) then
			av = vgui.Create("AvatarImage")
			av:SetPaintedManually(true)
			av:SetPlayer(ply, 32)
			avatars[ply] = av
		end
		av:SetPos(avX, avY)
		av:SetSize(avSize, avSize)
		av:SetAlpha(a)
		av:PaintManual()

		local steam = ply:Nick() or "Unknown"
		local ingame = string.Trim((ply.GetPlayerName and ply:GetPlayerName()) or ply:GetNWString("PlayerName", "") or "")
		if ingame == "" or string.lower(ingame) == string.lower(steam) then
			ingame = nil
		end

		local nameX = avX + avSize + S(6)
		local maxNameW = (ix + iw - pad) - nameX
		local function fitName(text, font)
			surface.SetFont(font)
			if surface.GetTextSize(text) <= maxNameW then return text end
			while #text > 1 and surface.GetTextSize(string.sub(text, 1, #text - 1) .. "...") > maxNameW do
				text = string.sub(text, 1, #text - 1)
			end
			return text .. "..."
		end

		steam = fitName(steam, "ZB_AdminVoice")
		if ingame then
			ingame = fitName(ingame, "ZB_AdminVoiceSub")
			draw.SimpleText(steam, "ZB_AdminVoice", nameX, y + rowH * 0.36, Color(color_text.r, color_text.g, color_text.b, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(ingame, "ZB_AdminVoiceSub", nameX, y + rowH * 0.68, Color(color_sub.r, color_sub.g, color_sub.b, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		else
			draw.SimpleText(steam, "ZB_AdminVoice", nameX, y + rowH * 0.5, Color(color_text.r, color_text.g, color_text.b, a), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end
end)

hook.Add("InitPostEntity", "ZB_AdminVoicePanelSnapshot", function()
	timer.Simple(1, requestSnapshot)
end)

cvars.AddChangeCallback("zb_admin_show_voicechat", function(_, _, newValue)
	if tobool(newValue) then
		requestSnapshot()
	else
		clearPanels()
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
	for ply in pairs(eligible) do
		if shouldDraw(ply) then
			count = count + 1
			print(string.format("  visible=%s fill=%.2f speaking=%s", ply:Nick(), levels[ply] or 0, tostring(ply:IsSpeaking())))
		end
	end

	if count <= 0 then print("  visible=none") end
	requestSnapshot()
end)
