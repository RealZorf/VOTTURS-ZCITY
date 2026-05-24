zb = zb or {}
zb.Transition = zb.Transition or {}

hmcdEndMenu = hmcdEndMenu or nil

zb.fade = zb.fade or 0
zb.END_MENU_DURATION = zb.END_MENU_DURATION or (zb.Transition.DEFAULT_END_MENU or 4)
zb.endMenuUntil = zb.endMenuUntil or 0

zb.Transition.RevealAt = zb.Transition.RevealAt or 0
zb.Transition.SetupInProgress = zb.Transition.SetupInProgress or false
zb.Transition.lastEndMenuAt = zb.Transition.lastEndMenuAt or 0
local colGray = Color(85, 85, 85, 255)
local colRed = Color(130, 10, 10)
local colRedUp = Color(160, 30, 30)
local colBlue = Color(10, 10, 160)
local colBlueUp = Color(40, 40, 160)
local colWhite = Color(255, 255, 255, 255)
local colSpect1 = Color(75, 75, 75, 255)
local colSpect2 = Color(255, 255, 255, 255)

BlurBackground = BlurBackground or hg.DrawBlur

function zb.ClearClientFade()
	zb.fade = 0
end

function zb.ClearEngineScreenFade()
	local ply = LocalPlayer()
	if IsValid(ply) then
		ply:ScreenFade(SCREENFADE.IN, color_black, 0, 0)
	end
end

function zb.IsEndRoundMenuOpen()
	return IsValid(hmcdEndMenu)
end

function zb.ApplyIntermissionFade()
end

function zb.CloseEndRoundMenu()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Close()
		hmcdEndMenu = nil
	end

	zb.endMenuUntil = 0
	timer.Remove("ZB_EndRoundMenuAutoClose")

	if zb.pendingFadeAfterMenu then
		zb.pendingFadeAfterMenu = nil
		zb.fade = math.min(zb.fade + 1.25, 2)
	end

	zb.ApplyIntermissionFade()
end

function zb.WatchEndRoundMenu()
	if not IsValid(hmcdEndMenu) then return end
	if hmcdEndMenu.ZB_EndMenuWatching then return end

	hmcdEndMenu.ZB_EndMenuWatching = true
	zb.ClearClientFade()

	local duration = zb.Transition.GetEndMenuDuration(CurrentRound())
	zb.endMenuUntil = CurTime() + duration

	timer.Create("ZB_EndRoundMenuAutoClose", duration, 1, function()
		zb.CloseEndRoundMenu()
	end)
end

local function defaultPlayerRow(ply)
	if not IsValid(ply) then return nil end
	if ply:Team() == TEAM_SPECTATOR then return nil end

	return {
		nick = ply:Nick(),
		name = ply:GetPlayerName(),
		frags = ply:Frags(),
		steamid = ply:IsBot() and "BOT" or ply:SteamID64(),
		alive = ply:Alive(),
		col = ply:GetPlayerColor():ToColor(),
		isTraitor = ply.isTraitor,
		isGunner = ply.isGunner,
		incapacitated = ply.organism and ply.organism.otrub,
		won = ply.won,
		most_violent = ply.most_violent_player,
	}
end

local function collectLivePlayerRows()
	local rows = {}

	for _, ply in player.Iterator() do
		local row = defaultPlayerRow(ply)
		if row then
			rows[#rows + 1] = row
		end
	end

	return rows
end

local function paintCloseButton(self, w, h)
	surface.SetDrawColor(122, 122, 122, 255)
	surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	surface.SetFont("ZB_InterfaceMedium")
	surface.SetTextColor(colWhite.r, colWhite.g, colWhite.b, colWhite.a)
	local lengthX = surface.GetTextSize("Close")
	surface.SetTextPos(lengthX - lengthX / 1.1, 4)
	surface.DrawText("Close")
end

function zb.Transition.OpenEndMenu(opts)
	opts = opts or {}

	if zb.Transition.lastEndMenuAt and zb.Transition.lastEndMenuAt > CurTime() - zb.Transition.END_MENU_DEDUPE then
		return false
	end

	zb.Transition.lastEndMenuAt = CurTime()

	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end

	if hook.Run("ZB_TransitionOpenEndUI", opts) == true then
		zb.WatchEndRoundMenu()
		return true
	end

	local style = opts.style or "standard"
	local headerLines = opts.headerLines or opts.headers
	local players = opts.players or collectLivePlayerRows()

	hmcdEndMenu = vgui.Create("ZFrame")
	if not IsValid(hmcdEndMenu) then return false end

	surface.PlaySound(opts.sound or "ambient/alarms/warningbell1.wav")

	local sizeX, sizeY = ScrW() / 2.5, ScrH() / 1.2
	local posX, posY = ScrW() / 1.3 - sizeX / 2, ScrH() / 2 - sizeY / 2

	hmcdEndMenu:SetPos(posX, posY)
	hmcdEndMenu:SetSize(sizeX, sizeY)
	hmcdEndMenu:MakePopup()
	hmcdEndMenu:SetKeyboardInputEnabled(false)
	hmcdEndMenu:ShowCloseButton(false)

	local closebutton = vgui.Create("DButton", hmcdEndMenu)
	closebutton:SetPos(5, 5)
	closebutton:SetSize(ScrW() / 20, ScrH() / 30)
	closebutton:SetText("")
	closebutton.DoClick = function()
		zb.CloseEndRoundMenu()
	end
	closebutton.Paint = paintCloseButton

	hmcdEndMenu.Paint = function(self, w, h)
		BlurBackground(self)
		surface.SetFont("ZB_InterfaceMediumLarge")
		surface.SetTextColor(colWhite.r, colWhite.g, colWhite.b, colWhite.a)

		local header = headerLines and headerLines[1] or "Players:"
		local lengthX = surface.GetTextSize(header)
		surface.SetTextPos(w / 2 - lengthX / 2, 20)
		surface.DrawText(header)

		surface.SetDrawColor(255, 0, 0, 128)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	end

	if headerLines and #headerLines > 1 then
		local oldPaint = hmcdEndMenu.Paint
		hmcdEndMenu.PaintOver = function(self, w, h)
			if oldPaint then oldPaint(self, w, h) end
			surface.SetFont("ZB_InterfaceMedium")
			surface.SetTextColor(colWhite.r, colWhite.g, colWhite.b, colWhite.a)
			for i = 2, #headerLines do
				local line = headerLines[i]
				local lx = surface.GetTextSize(line)
				surface.SetTextPos(w / 2 - lx / 2, 20 + (i - 1) * 22)
				surface.DrawText(line)
			end
		end
	end

	local scroll = vgui.Create("DScrollPanel", hmcdEndMenu)
	scroll:SetPos(10, headerLines and (70 + (#headerLines - 1) * 22) or 80)
	scroll:SetSize(sizeX - 20, sizeY - (headerLines and (80 + (#headerLines - 1) * 22) or 90))

	function scroll:Paint(w, h)
		BlurBackground(self)
		surface.SetDrawColor(255, 0, 0, 128)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	end

	for _, info in ipairs(players) do
		local but = vgui.Create("DButton", scroll)
		but:SetSize(100, 50)
		but:Dock(TOP)
		but:DockMargin(8, 6, 8, -1)
		but:SetText("")

		if isentity(info) and IsValid(info) then
			local ply = info
			info = defaultPlayerRow(ply) or {
				nick = ply:Nick(),
				name = ply:GetPlayerName(),
				frags = ply:Frags(),
				steamid = ply:IsBot() and "BOT" or ply:SteamID64(),
				alive = ply:Alive(),
				col = ply:GetPlayerColor():ToColor(),
			}
		end

		but.Paint = function(self, w, h)
			local col1, col2, leftText, centerName, rightText

			if style == "tdm" then
				local alive = info.alive
				col1 = alive and colRed or colGray
				col2 = alive and colRedUp or colSpect1
				centerName = info.name or info.nick or "Unknown"
				leftText = (info.nick or info.name or "Unknown") .. (not alive and " - died" or "")
				rightText = tostring(info.frags or 0)
			elseif style == "homicide" then
				col1 = (info.isTraitor and colRed) or (info.alive and colBlue) or colGray
				col2 = info.isTraitor and (info.alive and colRedUp or colSpect1)
					or ((info.alive and not info.incapacitated) and colBlueUp or colSpect1)
				centerName = info.nick or info.name or "Unknown"
				leftText = (info.name or info.nick or "Unknown")
					.. (not info.alive and " - died" or (info.incapacitated and " - incapacitated" or ""))
				rightText = tostring(info.frags or 0)
			else
				local alive = info.alive
				if info.won or info.most_violent then
					col1 = colRed
					col2 = info.alive and colRedUp or colSpect1
				else
					col1 = alive and colBlue or colGray
					col2 = alive and colBlueUp or colSpect1
				end
				centerName = info.name or info.nick or "Unknown"
				leftText = (info.nick or info.name or "Unknown")
					.. (info.most_violent and " - MVP" or (not alive and " - died" or ""))
				rightText = tostring(info.frags or 0)
			end

			surface.SetDrawColor(col1.r, col1.g, col1.b, col1.a)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(col2.r, col2.g, col2.b, col2.a)
			surface.DrawRect(0, h / 2, w, h / 2)

			local plyCol = info.col or colWhite
			surface.SetFont("ZB_InterfaceMediumLarge")
			local _, lengthY = surface.GetTextSize(centerName)

			surface.SetTextColor(0, 0, 0, 255)
			surface.SetTextPos(w / 2 + 1, h / 2 - lengthY / 2 + 1)
			surface.DrawText(centerName)

			surface.SetTextColor(plyCol.r, plyCol.g, plyCol.b, plyCol.a)
			surface.SetTextPos(w / 2, h / 2 - lengthY / 2)
			surface.DrawText(centerName)

			surface.SetFont("ZB_InterfaceMediumLarge")
			surface.SetTextColor(colSpect2.r, colSpect2.g, colSpect2.b, colSpect2.a)
			local _, ly = surface.GetTextSize(leftText)
			surface.SetTextPos(15, h / 2 - ly / 2)
			surface.DrawText(leftText)

			local rx = surface.GetTextSize(rightText)
			surface.SetTextPos(w - rx - 15, h / 2 - ly / 2)
			surface.DrawText(rightText)
		end

		but.DoClick = function()
			if info.steamid == "BOT" then
				chat.AddText(Color(255, 0, 0), "That's a bot.")
				return
			end
			if info.steamid then
				gui.OpenURL("https://steamcommunity.com/profiles/" .. info.steamid)
			end
		end

		scroll:AddItem(but)
	end

	zb.WatchEndRoundMenu()
	return true
end

function zb.Transition.OnRoundInfo(state)
	if state == zb.Transition.STATE_ACTIVE then
		zb.CloseEndRoundMenu()
		zb.ClearEngineScreenFade()
	elseif state == zb.Transition.STATE_END then
		zb.CloseEndRoundMenu()
	end
end

function zb.Transition.DrawDefaultIntro(fade)
	if not fade or fade <= 0 then return end

	local mode = CurrentRound()
	if not mode then return end

	local sw, sh = ScrW(), ScrH()
	local introColor = mode.IntroColor or Color(0, 120, 190)
	local title = mode.IntroTitle or mode.PrintName or "Z-City"
	local roleName = mode.IntroRoleName
	local objective = mode.IntroObjective
	local description = mode.IntroDescription

	local lply = LocalPlayer()
	if IsValid(lply) and mode.IntroTeams then
		local teamData = mode.IntroTeams[lply:Team()] or mode.IntroTeams[0]
		if teamData then
			roleName = roleName or teamData.name
			objective = objective or teamData.objective
			if teamData.color1 then
				introColor = teamData.color1
			end
		end
	end

	if IsValid(lply) then
		if lply.SubRole and lply.SubRole ~= "" and mode.SubRoles and mode.SubRoles[lply.SubRole] then
			local sub = mode.SubRoles[lply.SubRole]
			roleName = roleName or sub.Name or lply.SubRole
			objective = objective or sub.Objective
		end

		if lply.Profession and lply.Profession ~= "" and mode.Professions and mode.Professions[lply.Profession] then
			local prof = mode.Professions[lply.Profession]
			if prof.Name then
				description = (description and description ~= "" and description) or ("Occupation: " .. prof.Name)
			end
			objective = objective or prof.Objective
		end

		if mode.name == "hmcd" and mode.Type and mode.TypeNames and mode.TypeNames[mode.Type] then
			title = "Homicide | " .. mode.TypeNames[mode.Type]
		end
	end

	if not roleName then
		roleName = "a Combatant"
	elseif not string.find(string.lower(roleName), "you are", 1, true) and roleName:sub(1, 2) ~= "a " and roleName:sub(1, 3) ~= "an " then
		roleName = "a " .. roleName
	end

	objective = objective or "Fight to win."

	local titleColor = Color(introColor.r, introColor.g, introColor.b, 255 * fade)
	draw.SimpleText(title, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, titleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if roleName then
		local roleColor = Color(introColor.r, introColor.g, introColor.b, 255 * fade)
		local roleLabel = string.find(string.lower(roleName), "you are", 1, true) and roleName or ("You are " .. roleName)
		draw.SimpleText(roleLabel, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, roleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if description and description ~= "" then
		local descriptionColor = Color(introColor.r, introColor.g, introColor.b, 235 * fade)
		draw.SimpleText(description, "ZB_HomicideMedium", sw * 0.5, sh * 0.82, descriptionColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local objectiveColor = Color(introColor.r, introColor.g, introColor.b, 255 * fade)
	draw.SimpleText(objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, objectiveColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if hg.PluvTown and hg.PluvTown.Active then
		surface.SetMaterial(hg.PluvTown.PluvMadness)
		surface.SetDrawColor(255, 255, 255, math.random(175, 255) * fade / 2)
		surface.DrawTexturedRect(sw * 0.25, sh * 0.44 - ScreenScale(15), sw / 2, ScreenScale(30))
		draw.SimpleText("SOMEWHERE IN PLUVTOWN", "ZB_ScrappersLarge", sw / 2, sh * 0.44 - ScreenScale(2), Color(0, 0, 0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function zb.RoundFade.PaintStandardIntro(mode)
	if not mode then return end

	local fade = zb.RoundFade.GetIntroAlpha()
	if fade <= 0 then return end

	if not IsValid(lply) or not lply:Alive() then return end

	if mode.buymenu then
		zb.fade = 0

		if zb.ClearEngineScreenFade then
			zb.ClearEngineScreenFade()
		end
	else
		zb.RemoveFade()
	end

	if mode.DrawRoundIntro then
		mode:DrawRoundIntro(fade)
		return
	end

	if zb.Transition and zb.Transition.DrawDefaultIntro then
		zb.Transition.DrawDefaultIntro(fade)
	end
end

net.Receive("ZB_RoundTransition", function()
	net.ReadUInt(3)
	net.ReadFloat()
	local revealAt = net.ReadFloat()
	zb.Transition.SetupInProgress = net.ReadBool()
	if revealAt > 0 then
		zb.Transition.RevealAt = revealAt
	end
end)

net.Receive("ZB_RoundTimes", function()
	zb.ROUND_TIME = net.ReadFloat()
	zb.ROUND_START = net.ReadFloat()
	zb.ROUND_BEGIN = net.ReadFloat()

	local round = CurrentRound and CurrentRound()
	if round and round.buymenu and zb.RemoveFade then
		zb.RemoveFade()
	end
end)

hook.Add("Think", "ZB_WatchEndRoundMenu", function()
	zb.WatchEndRoundMenu()
end)

-- Legacy end-round net bridges (deduped via OpenEndMenu)
local function openStandard(style, headerLines, players)
	zb.Transition.OpenEndMenu({
		style = style,
		headerLines = headerLines,
		players = players,
	})
end

net.Receive("tdm_roundend", function()
	openStandard("tdm", { "Players:" })
end)

net.Receive("hmcd_roundend", function()
	local mode = CurrentRound()
	local traitorBits = (mode and mode.TraitorExpectedAmtBits) or 5
	local traitors, gunners = {}, {}

	for _ = 1, net.ReadUInt(traitorBits) do
		local traitor = net.ReadEntity()
		if IsValid(traitor) then
			traitors[#traitors + 1] = traitor
			traitor.isTraitor = true
		end
	end

	for _ = 1, net.ReadUInt(traitorBits) do
		local gunner = net.ReadEntity()
		if IsValid(gunner) then
			gunners[#gunners + 1] = gunner
			gunner.isGunner = true
		end
	end

	local traitor = traitors[1]
	local header = { "Players:" }

	if IsValid(traitor) then
		header = {
			traitor:GetPlayerName() .. " was a traitor (" .. traitor:Nick() .. ")",
		}
	end

	local lply = LocalPlayer()
	timer.Simple(0, function()
		if not IsValid(lply) then return end
		lply.isPolice = false
		lply.isTraitor = false
		lply.isGunner = false
		lply.MainTraitor = false
		lply.SubRole = nil
		lply.Profession = nil
	end)

	openStandard("homicide", header)
end)

net.Receive("dm_end", function()
	local winner = net.ReadEntity()
	local violent = net.ReadEntity()

	if IsValid(violent) then
		violent.most_violent_player = true
	end

	if IsValid(winner) then
		winner.won = true
	end

	if StopDeathmatchTheme then
		StopDeathmatchTheme()
	end

	zb.SoundStation = nil
	if MODE and MODE.SoundStation and MODE.SoundStation.IsValid and MODE.SoundStation:IsValid() then
		MODE.SoundStation:Stop()
		MODE.SoundStation = nil
	end

	local header = { (IsValid(winner) and (winner:GetPlayerName() .. " won!") or "Nobody won!") }
	openStandard("standard", header)
end)

net.Receive("riot_roundend", function()
	openStandard("tdm", { "Riot Over" })
end)

net.Receive("event_end", function()
	local winner = net.ReadEntity()
	local header = { "Event Over" }

	if IsValid(winner) then
		winner.won = true
		header = { winner:Nick() .. " wins the event" }
	end

	openStandard("standard", header)
end)

net.Receive("coop_roundend", function()
	openStandard("standard", { "Co-op Mission Complete" })
end)

net.Receive("cri_roundend", function()
	local terroristsWin = net.ReadBool()
	openStandard("tdm", { terroristsWin and "Terrorists Win" or "Counter-Terrorists Win" })
end)

net.Receive("gwars_roundend", function()
	openStandard("standard", { "G-Wars Over" })
end)

net.Receive("hl2dm_roundend", function()
	openStandard("standard", { "Half-Life 2 Deathmatch Over" })
end)

net.Receive("hl3_roundend", function()
	openStandard("standard", { "Half-Life 3 Over" })
end)

net.Receive("npc_defense_roundend", function()
	openStandard("standard", { "Defense Over" })
end)

net.Receive("hns_roundend", function()
	local huntersWin = net.ReadBool()
	openStandard("standard", { huntersWin and "Hunters Win" or "Hiders Win" })
end)

net.Receive("scugarena_end", function()
	openStandard("standard", { "Arena Over" })
end)

net.Receive("supfight_end", function()
	openStandard("standard", { "Super Fight Over" })
end)

net.Receive("ShipAssassins_RoundEnd", function()
	openStandard("standard", { "Ship Assassins Over" })
end)

net.Receive("ZB_Pathowogen_RoundEnd", function()
	local win = net.ReadUInt(3)
	local data = net.ReadTable()

	if IsValid(zb.PathowogenEnd) then
		zb.PathowogenEnd:Remove()
	end

	local panel = vgui.Create("ZB_PathowogenEnd")
	if IsValid(panel) then
		panel:SetData(win, data)
	end

	zb.Transition.lastEndMenuAt = CurTime()
end)

-- Global helper used by legacy mode code
function CreateEndMenu(...)
	local first = ...
	if IsEntity(first) or (istable(first) and not first.style and not first.headerLines) then
		return zb.Transition.OpenEndMenu({
			style = "homicide",
			headerLines = IsValid(first) and {
				first:GetPlayerName() .. " was a traitor (" .. first:Nick() .. ")",
			} or { "Players:" },
			players = { first },
		})
	end

	if istable(first) then
		return zb.Transition.OpenEndMenu(first)
	end

	return zb.Transition.OpenEndMenu({ style = "standard" })
end
