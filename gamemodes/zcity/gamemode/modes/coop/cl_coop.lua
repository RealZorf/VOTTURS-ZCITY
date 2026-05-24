MODE.name = "coop"
MODE.IntroTitle = "Homicide | CO-OP"

local MODE = MODE

net.Receive("coop_start",function()
    surface.PlaySound("hl2mode1.wav")
	zb.RemoveFade()
	hg.DynaMusic:Start("hl_coop")
end)

local teams = {
	[0] = {
		objective = "Go to the end of the map!",
		name = "rebel",
		color1 = Color(155,55,0),
		color2 = Color(129,129,129)
	}
}

MODE.IntroTeams = teams

function MODE:RenderScreenspaceEffects()
	zb.RoundFade.PaintBlackScreen()
end

function MODE:DrawRoundIntro(fade)
	if not IsValid(lply) or not lply:Alive() then return end

	local roleName = (lply.role and lply.role.name) or "Unknown"
	local colorRole = Color(teams[0].color1.r, teams[0].color1.g, teams[0].color1.b, 255 * fade)
	draw.SimpleText(MODE.IntroTitle, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("You are " .. roleName, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, colorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local objective = lply.PlayerClassName == "Gordon" and "Lead the resistance to victory!" or "Follow the Gordon!"
	local colorObj = Color(teams[0].color2.r, teams[0].color2.g, teams[0].color2.b, 255 * fade)
	draw.SimpleText(objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, colorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function MODE:HUDPaint()

	local startTimer = GetGlobalVar("coop_first_round_timer", 0)

	if startTimer > CurTime() then
		surface.SetFont("ZB_HomicideMediumLarge")

		local w, h = surface.GetTextSize("Awaiting players: ")
		local w2, h2 = surface.GetTextSize("00:00")

		surface.SetTextPos(sw * 0.5 - (w + w2) * 0.5, sh * 0.1 - h * 0.5)
		surface.SetTextColor(Color(0,162,255, 255))
		surface.DrawText("Awaiting players: ")
		
		surface.SetTextPos(sw * 0.5 + (w - w2) * 0.5, sh * 0.1 - h * 0.5)
		surface.DrawText(string.FormattedTime(startTimer - CurTime(), "%02i:%02i"))
	end

	zb.RoundFade.PaintStandardIntro(self)
end


-- [ZB] round end UI handled by libraries/round_transitions/cl_round_transitions.lua

function MODE:RoundStart()
    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Remove()
        hmcdEndMenu = nil
    end
end
