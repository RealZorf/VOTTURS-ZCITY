MODE.name = "hl3"

local MODE = MODE

net.Receive("hl3_start", function()
	surface.PlaySound("hl2mode1.wav")
	zb.RemoveFade()
	hg.DynaMusic:Start("hl_coop")
end)

local teams = {
	[0] = {
		objective = "Destroy the Combine and the Vortigaunts.",
		name = "a Rebel",
		color1 = Color(230, 100, 5),
		color2 = Color(210, 80, 0),
	},
	[1] = {
		objective = "Destroy the Rebels and the Vortigaunts.",
		name = "a Combine Soldier",
		color1 = Color(0, 200, 220),
		color2 = Color(0, 180, 200),
	},
	[2] = {
		objective = "Destroy the Combine and the Rebels.",
		name = "a Vortigaunt",
		color1 = Color(110, 220, 120),
		color2 = Color(70, 190, 90),
	},
}


if CLIENT then
	surface.CreateFont("ZC_HL3_VortHudTitle", {
		font = "Tahoma",
		size = 22,
		weight = 900,
		antialias = true
	})

	surface.CreateFont("ZC_HL3_VortHudValue", {
		font = "Tahoma",
		size = 20,
		weight = 900,
		antialias = true
	})

	surface.CreateFont("ZC_HL3_VortHudPill", {
		font = "Tahoma",
		size = 16,
		weight = 800,
		antialias = true
	})
end

function MODE:RenderScreenspaceEffects()
	if zb.ROUND_START + 7.5 < CurTime() then return end
	local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)

	surface.SetDrawColor(0, 0, 0, 255 * fade)
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

local function drawStatusPill(x, y, w, h, text, textColor, fillColor, outlineColor)
	surface.SetDrawColor(fillColor.r, fillColor.g, fillColor.b, fillColor.a)
	surface.DrawRect(x, y, w, h)
	surface.SetDrawColor(outlineColor.r, outlineColor.g, outlineColor.b, outlineColor.a)
	surface.DrawOutlinedRect(x, y, w, h, 1)
	draw.SimpleText(text, "ZC_HL3_VortHudPill", x + w * 0.5, y + h * 0.5, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function drawVortessenceHUD()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() or not ply:GetNWBool("ZC_HL3_Vort", false) then return end

	local now = CurTime()
	local sw, sh = ScrW(), ScrH()
	local maxEssence = math.max(ply:GetNWFloat("ZC_HL3_VortEssenceMax", 100), 1)
	local essence = math.Clamp(ply:GetNWFloat("ZC_HL3_VortEssence", 0), 0, maxEssence)
	local frac = essence / maxEssence
	local riftReady = math.max(0, ply:GetNWFloat("ZC_HL3_NextRiftAt", 0) - now)
	local blinkReady = math.max(0, ply:GetNWFloat("ZC_HL3_NextBlinkAt", 0) - now)
	local chorus = ply:GetNWInt("ZC_HL3_VortChorusCount", 0)

	local panelW = math.Clamp(sw * 0.28, 360, 520)
	local panelH = 88
	local x = sw * 0.5 - panelW * 0.5
	local y = 16
	local barX = x + 12
	local barY = y + 28
	local barW = panelW - 24
	local barH = 14
	local pillY = y + 56
	local gap = 6
	local pillW = math.floor((barW - gap * 2) / 3)
	local valueText = string.format("%d / %d", math.floor(essence + 0.5), maxEssence)

	surface.SetDrawColor(0, 0, 0, 165)
	surface.DrawRect(x, y, panelW, panelH)
	surface.SetDrawColor(90, 220, 130, 200)
	surface.DrawOutlinedRect(x, y, panelW, panelH, 1)

	draw.SimpleText("VORTESSENCE", "ZC_HL3_VortHudTitle", x + 12, y + 13, Color(145, 255, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText(valueText, "ZC_HL3_VortHudValue", x + panelW - 12, y + 13, Color(225, 255, 235), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

	surface.SetDrawColor(16, 35, 22, 230)
	surface.DrawRect(barX, barY, barW, barH)
	surface.SetDrawColor(70, 235, 120, 245)
	surface.DrawRect(barX, barY, barW * frac, barH)
	surface.SetDrawColor(190, 255, 205, 230)
	surface.DrawOutlinedRect(barX, barY, barW, barH, 1)

	local riftText
	local riftColor
	if riftReady > 0 then
		riftText = string.format("RIFT %.1fs", riftReady)
		riftColor = Color(195, 210, 200)
	elseif essence >= maxEssence then
		riftText = "RIFT READY"
		riftColor = Color(145, 255, 170)
	else
		riftText = "RIFT CHARGING"
		riftColor = Color(175, 205, 180)
	end

	local blinkText = blinkReady > 0 and string.format("BLINK %.1fs", blinkReady) or "BLINK READY"
	local blinkColor = blinkReady > 0 and Color(180, 195, 210) or Color(145, 230, 255)

	local chorusText = chorus > 0 and ("CHORUS x" .. chorus) or "CHORUS SOLO"
	local chorusColor = chorus > 0 and Color(185, 255, 205) or Color(205, 220, 205)

	drawStatusPill(barX, pillY, pillW, 20, riftText, riftColor, Color(22, 36, 25, 215), Color(85, 150, 110, 220))
	drawStatusPill(barX + pillW + gap, pillY, pillW, 20, blinkText, blinkColor, Color(20, 28, 34, 215), Color(90, 125, 145, 220))
	drawStatusPill(barX + (pillW + gap) * 2, pillY, pillW, 20, chorusText, chorusColor, Color(20, 30, 22, 215), Color(90, 140, 100, 220))
end

function MODE:HUDPaint()
	drawVortessenceHUD()

	local lply = LocalPlayer()
	if not IsValid(lply) then return end

	local sw, sh = ScrW(), ScrH()
	if zb.ROUND_START + 8.5 < CurTime() then return end
	if not lply:Alive() then return end

	zb.RemoveFade()

	local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(), 0, 1)
	local teamID = lply:Team()
	local teamData = teams[teamID]
	if not teamData then return end

	draw.SimpleText("ZBattle | Half Life 2: Vortessence War", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local roleColor = Color(teamData.color1.r, teamData.color1.g, teamData.color1.b, 255 * fade)
	local objectiveColor = Color(teamData.color2.r, teamData.color2.g, teamData.color2.b, 255 * fade)

	draw.SimpleText("You are " .. teamData.name, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, roleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(teamData.objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, objectiveColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if hg.PluvTown.Active then
		surface.SetMaterial(hg.PluvTown.PluvMadness)
		surface.SetDrawColor(255, 255, 255, math.random(175, 255) * fade / 2)
		surface.DrawTexturedRect(sw * 0.25, sh * 0.44 - ScreenScale(15), sw / 2, ScreenScale(30))

		draw.SimpleText("SOMEWHERE IN PLUVTOWN", "ZB_ScrappersLarge", sw / 2, sh * 0.44 - ScreenScale(2), Color(0, 0, 0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

hook.Add("radialOptions", "CMB_Airstrike_HL3", function()
	local org = lply.organism

	if lply:GetNWString("PlayerRole") == "Elite" and org and not org.otrub then
		hg.radialOptions[#hg.radialOptions + 1] = {
			function()
				net.Start("ZB_RequestAirStrike")
				net.SendToServer()
			end,
			"Request Airstrike"
		}
	end
end)

local CreateEndMenu

net.Receive("hl3_roundend", function()
	net.ReadInt(3)
	surface.PlaySound("ambient/alarms/warningbell1.wav")
	CreateEndMenu()
end)

local colGray = Color(85, 85, 85, 255)
local colRed = Color(130, 10, 10)
local colRedUp = Color(160, 30, 30)
local colSpect1 = Color(75, 75, 75, 255)
local colSpect2 = Color(255, 255, 255)
local col = Color(255, 255, 255, 255)

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

		local but = vgui.Create("DButton", DScrollPanel)
		but:SetSize(100, 50)
		but:Dock(TOP)
		but:DockMargin(8, 6, 8, -1)
		but:SetText("")
		but.Paint = function(self, w, h)
			local col1 = (ply:Alive() and colRed) or colGray
			local col2 = (ply:Alive() and colRedUp) or colSpect1
			surface.SetDrawColor(col1.r, col1.g, col1.b, col1.a)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(col2.r, col2.g, col2.b, col2.a)
			surface.DrawRect(0, h / 2, w, h / 2)

			local pcol = ply:GetPlayerColor():ToColor()
			surface.SetFont("ZB_InterfaceMediumLarge")
			local _, lengthY = surface.GetTextSize(ply:GetPlayerName() or "He quited...")

			surface.SetTextColor(0, 0, 0, 255)
			surface.SetTextPos(w / 2 + 1, h / 2 - lengthY / 2 + 1)
			surface.DrawText(ply:GetPlayerName() or "He quited...")

			surface.SetTextColor(pcol.r, pcol.g, pcol.b, pcol.a)
			surface.SetTextPos(w / 2, h / 2 - lengthY / 2)
			surface.DrawText(ply:GetPlayerName() or "He quited...")

			surface.SetTextColor(colSpect2.r, colSpect2.g, colSpect2.b, colSpect2.a)
			surface.SetTextPos(15, h / 2 - lengthY / 2)
			surface.DrawText((ply:Name() .. (not ply:Alive() and " - died" or "")) or "He quited...")

			local fragText = tostring(ply:Frags() or 0)
			local fragWidth = surface.GetTextSize(fragText)
			surface.SetTextPos(w - fragWidth - 15, h / 2 - lengthY / 2)
			surface.DrawText(fragText)
		end

		function but:DoClick()
			if ply:IsBot() then
				chat.AddText(Color(255, 0, 0), "no, you can't")
				return
			end
			gui.OpenURL("https://steamcommunity.com/profiles/" .. ply:SteamID64())
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
