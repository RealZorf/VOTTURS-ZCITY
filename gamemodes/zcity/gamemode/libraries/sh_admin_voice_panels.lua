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
	util.AddNetworkString("ZB_AdminVoicePanelSnapshotRequest")
	util.AddNetworkString("ZB_AdminVoicePanelSetDistance")

	local adminVoicePanelState = {}
	local adminVoicePanelRefresh = {}
	local zb_admin_show_voicechat_distance_value = ConVarExists("zb_admin_show_voicechat_distance_value") and GetConVar("zb_admin_show_voicechat_distance_value") or CreateConVar(
		"zb_admin_show_voicechat_distance_value",
		"20",
		bit.bor(FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY),
		"Admin voice panel distance in meters.",
		1,
		500
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
		if not IsValid(listener) or not IsValid(talker) or listener == talker then return false end
		if not talker:IsSpeaking() then return false end
		if listener:GetPos():DistToSqr(talker:GetPos()) > getAdminVoicePanelDistanceSqr() then return false end
		if not listener:TestPVS(talker) then return false end

		return true
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
			if playerCanSeeVoicePanels(listener) then
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

local function canSeeVoicePanelsInRound(lply)
	if not IsValid(lply) then return false end
	if not AdminShowVoiceChat:GetBool() then return false end

	local userGroup = (lply.GetUserGroup and lply:GetUserGroup()) or ""
	return groupCanSeeVoicePanels(userGroup)
end

hg.CanSeeVoicePanelsInRound = canSeeVoicePanelsInRound

local function requestAdminVoicePanelSnapshot()
	local lply = LocalPlayer()
	if not canSeeVoicePanelsInRound(lply) then return end

	net.Start("ZB_AdminVoicePanelSnapshotRequest")
	net.SendToServer()
end

local function clearAdminVoicePanels()
	local lply = LocalPlayer()

	table.Empty(adminVoicePanelSpeakers)

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
	if not canSeeVoicePanelsInRound(lply) then return end

	ply.IsSpeak = isSpeaking
	adminVoicePanelSpeakers[ply] = isSpeaking and (CurTime() + 1.75) or nil

	if isSpeaking then
		if GAMEMODE and GAMEMODE.PlayerStartVoice then
			GAMEMODE:PlayerStartVoice(ply)
		end
	else
		if GAMEMODE and GAMEMODE.PlayerEndVoice then
			GAMEMODE:PlayerEndVoice(ply)
		end
	end
end)

function hg.IsAdminVoicePanelActive(ply)
	return IsValid(ply) and adminVoicePanelSpeakers[ply] ~= nil
end

local function endVoicePanel(ply)
	if IsValid(ply) then
		ply.IsSpeak = false
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
		if next(adminVoicePanelSpeakers) then
			clearAdminVoicePanels()
		end

		return
	end

	for ply, expireTime in pairs(adminVoicePanelSpeakers) do
		if not IsValid(ply) or expireTime <= now then
			endVoicePanel(ply)
		end
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
