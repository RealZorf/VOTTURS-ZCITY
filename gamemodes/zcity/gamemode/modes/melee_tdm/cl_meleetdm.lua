MODE.name = "tdmmelee"

local MODE = MODE
local MusicVolume = GetConVar("snd_musicvolume")
local meleeThemeStation

local function StopMeleeTheme()
	if IsValid(meleeThemeStation) then
		meleeThemeStation:Stop()
	end

	meleeThemeStation = nil
end

local function GetSoundPath(path)
	if not path or path == "" then return nil end
	if string.StartWith(path, "sound/") then return path end
	return "sound/" .. path
end

local function MusicMul()
	return (MusicVolume and MusicVolume:GetFloat()) or 1
end

local function StartMeleeTheme(round)
	local themePath = GetSoundPath(round and round.ThemeMusicFile)
	if not themePath then return false end

	local expectedRoundName = round.name
	StopMeleeTheme()

	sound.PlayFile(themePath, "noblock noplay", function(station, errCode, errStr)
		if not IsValid(station) then
			if errCode or errStr then
				print("[tdmmelee] theme missing, using fallback music:", errCode, errStr)
			end

			local currentRound = CurrentRound()
			if currentRound and currentRound.name == expectedRoundName and hg.DynaMusic then
				hg.DynaMusic:Start(round.FallbackDynaMusic or "swat4")
			end

			return
		end

		local currentRound = CurrentRound()
		if not currentRound or currentRound.name != expectedRoundName then
			station:Stop()
			return
		end

		if hg.DynaMusic then
			hg.DynaMusic:Stop()
		end

		meleeThemeStation = station
		station:EnableLooping(true)
		station:SetVolume((round.ThemeMusicVolume or 0.25) * MusicMul())
		station:Play()
	end)

	return true
end

net.Receive("tdmmelee_start", function()
	local round = CurrentRound() or MODE
	if not StartMeleeTheme(round) and hg.DynaMusic then
		hg.DynaMusic:Start(round.FallbackDynaMusic or "swat4")
	end
	zb.RemoveFade()
end)

hook.Add("Think", "MeleeTDMThemeVolumeThink", function()
	if not IsValid(meleeThemeStation) then return end

	local round = CurrentRound()
	if not round or round.name != "tdmmelee" or not round.ThemeMusicFile then
		StopMeleeTheme()
		return
	end

	local baseVol = (round.ThemeMusicVolume or 0.25) * MusicMul()
	local fade = round.ThemeLoopFade or 1.4
	local length = meleeThemeStation:GetLength()
	local t = meleeThemeStation:GetTime()
	local mul = 1

	if length > fade * 4 then
		if t < fade then
			mul = t / fade
		elseif length - t < fade then
			mul = math.max((length - t) / fade, 0)
		end
	end

	meleeThemeStation:SetVolume(baseVol * mul)

	if meleeThemeStation:GetState() != GMOD_CHANNEL_PLAYING then
		meleeThemeStation:Play()
	end
end)

hook.Add("RoundInfoCalled", "MeleeTDMThemeRoundInfo", function(rnd)
	if rnd == "tdmmelee" then return end
	StopMeleeTheme()
end)

local teams = {
	[0] = {
		objective = "Batter the roadmen. Last crew standing wins.",
		name = "a Hooligan",
		color1 = Color(150, 20, 45),
		color2 = Color(190, 50, 70)
	},
	[1] = {
		objective = "Batter the hooligans. Last crew standing wins.",
		name = "a Roadman",
		color1 = Color(40, 40, 45),
		color2 = Color(90, 90, 95)
	},
}

function MODE:RenderScreenspaceEffects()
	local startTime = zb.ROUND_START or CurTime()
	if startTime + 7.5 < CurTime() then return end

	local fade = math.Clamp(startTime + 7.5 - CurTime(), 0, 1)
	surface.SetDrawColor(0, 0, 0, 255 * fade)
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

function MODE:HUDPaint()
	local startTime = zb.ROUND_START or CurTime()
	if startTime + 8.5 < CurTime() then return end
	if not IsValid(lply) or not lply:Alive() then return end

	zb.RemoveFade()

	local fade = math.Clamp(startTime + 8 - CurTime(), 0, 1)
	local teamInfo = teams[lply:Team()]
	if not teamInfo then return end

	draw.SimpleText("Hooligans vs Roadmen", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local roleColor = Color(teamInfo.color1.r, teamInfo.color1.g, teamInfo.color1.b, 255 * fade)
	draw.SimpleText("You are " .. teamInfo.name, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, roleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local objColor = Color(teamInfo.color2.r, teamInfo.color2.g, teamInfo.color2.b, 255 * fade)
	draw.SimpleText(teamInfo.objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, objColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if hg.PluvTown.Active then
		surface.SetMaterial(hg.PluvTown.PluvMadness)
		surface.SetDrawColor(255, 255, 255, math.random(175, 255) * fade / 2)
		surface.DrawTexturedRect(sw * 0.25, sh * 0.44 - ScreenScale(15), sw / 2, ScreenScale(30))
		draw.SimpleText("SOMEWHERE IN PLUVTOWN", "ZB_ScrappersLarge", sw / 2, sh * 0.44 - ScreenScale(2), Color(0, 0, 0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

net.Receive("tdmmelee_end", function()
	StopMeleeTheme()
	if hg.DynaMusic then
		hg.DynaMusic:Stop()
	end
	CreateEndMenu()
end)

local colGray = Color(85, 85, 85, 255)
local colRed = Color(130, 10, 10)
local colRedUp = Color(160, 30, 30)
local colBlue = Color(10, 10, 160)
local colBlueUp = Color(40, 40, 160)
local col = Color(255, 255, 255, 255)
local colSpect1 = Color(75, 75, 75, 255)
local colSpect2 = Color(255, 255, 255)

BlurBackground = BlurBackground or hg.DrawBlur

if IsValid(hmcdEndMenu) then
	hmcdEndMenu:Remove()
	hmcdEndMenu = nil
end

CreateEndMenu = function()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end

	hmcdEndMenu = vgui.Create("ZFrame")

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
		if IsValid(hmcdEndMenu) then
			hmcdEndMenu:Close()
			hmcdEndMenu = nil
		end
	end

	closebutton.Paint = function(self, w, h)
		surface.SetDrawColor(122, 122, 122, 255)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
		surface.SetFont("ZB_InterfaceMedium")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local lengthX = surface.GetTextSize("Close")
		surface.SetTextPos(lengthX - lengthX / 1.1, 4)
		surface.DrawText("Close")
	end

	hmcdEndMenu.Paint = function(self, w, h)
		BlurBackground(self)
		surface.SetFont("ZB_InterfaceMediumLarge")
		surface.SetTextColor(col.r, col.g, col.b, col.a)
		local lengthX = surface.GetTextSize("Players:")
		surface.SetTextPos(w / 2 - lengthX / 2, 20)
		surface.DrawText("Players:")
		surface.SetDrawColor(255, 0, 0, 128)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	end

	local DScrollPanel = vgui.Create("DScrollPanel", hmcdEndMenu)
	DScrollPanel:SetPos(10, 80)
	DScrollPanel:SetSize(sizeX - 20, sizeY - 90)

	function DScrollPanel:Paint(w, h)
		BlurBackground(self)
		surface.SetDrawColor(255, 0, 0, 128)
		surface.DrawOutlinedRect(0, 0, w, h, 2.5)
	end

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end

		local steamID64 = ply.SteamID64 and ply:SteamID64() or nil
		local fallbackName = (ply.GetPlayerName and ply:GetPlayerName()) or ply:Name() or "Unknown Player"
		local but = vgui.Create("DButton", DScrollPanel)
		but:SetSize(100, 50)
		but:Dock(TOP)
		but:DockMargin(8, 6, 8, -1)
		but:SetText("")

		but.Paint = function(self, w, h)
			local isValidPly = IsValid(ply)
			local isAlive = isValidPly and zb:CanActivelyParticipate(ply)
			local onRoadmen = isValidPly and ply:Team() == 1
			local col1 = (isAlive and (onRoadmen and colBlue or colRed)) or colGray
			local col2 = (isAlive and (onRoadmen and colBlueUp or colRedUp)) or colSpect1

			surface.SetDrawColor(col1.r, col1.g, col1.b, col1.a)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(col2.r, col2.g, col2.b, col2.a)
			surface.DrawRect(0, h / 2, w, h / 2)

			local playerName = fallbackName
			if isValidPly then
				playerName = (ply.GetPlayerName and ply:GetPlayerName()) or ply:Name() or fallbackName
			end

			local nameColor = colSpect2
			if isValidPly and ply.GetPlayerColor then
				nameColor = ply:GetPlayerColor():ToColor()
			end

			surface.SetFont("ZB_InterfaceMediumLarge")
			local lengthX, lengthY = surface.GetTextSize(playerName)

			surface.SetTextColor(0, 0, 0, 255)
			surface.SetTextPos(w / 2 + 1, h / 2 - lengthY / 2 + 1)
			surface.DrawText(playerName)

			surface.SetTextColor(nameColor.r, nameColor.g, nameColor.b, nameColor.a)
			surface.SetTextPos(w / 2, h / 2 - lengthY / 2)
			surface.DrawText(playerName)

			local statusText = playerName .. (isValidPly and (not isAlive and " - died" or "") or " - disconnected")
			surface.SetTextColor(colSpect2.r, colSpect2.g, colSpect2.b, colSpect2.a)
			surface.SetTextPos(15, h / 2 - lengthY / 2)
			surface.DrawText(statusText)

			local fragsText = isValidPly and tostring(ply:Frags()) or "-"
			lengthX = surface.GetTextSize(fragsText)
			surface.SetTextPos(w - lengthX - 15, h / 2 - lengthY / 2)
			surface.DrawText(fragsText)
		end

		function but:DoClick()
			if not IsValid(ply) then
				chat.AddText(Color(255, 0, 0), "this player is no longer available")
				return
			end
			if ply:IsBot() then
				chat.AddText(Color(255, 0, 0), "no, you can't")
				return
			end
			if not steamID64 or steamID64 == "" then
				chat.AddText(Color(255, 0, 0), "steam profile unavailable")
				return
			end
			gui.OpenURL("https://steamcommunity.com/profiles/" .. steamID64)
		end

		DScrollPanel:AddItem(but)
	end

	return true
end

function MODE:RoundStart()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end
end

function MODE:RoundEnd()
	StopMeleeTheme()
end
