MODE.name = "hl3"
MODE.IntroTitle = "ZBattle | Half Life 2: Vortessence War"

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

MODE.IntroTeams = teams

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

function MODE:RenderScreenspaceEffects()
	zb.RoundFade.PaintBlackScreen()
end

function MODE:HUDPaint()
	drawVortessenceHUD()
	zb.RoundFade.PaintStandardIntro(self)
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


-- [ZB] round end UI handled by libraries/round_transitions/cl_round_transitions.lua

function MODE:RoundStart()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end
end
