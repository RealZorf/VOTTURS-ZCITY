MODE.name = "riot"

local MODE = MODE

net.Receive("riot_start", function()
    if RiotSound then
        RiotSound:Stop()
        RiotSound = nil
    end

    sound.PlayFile("sound/zbattle/riot.wav", "noplay", function(station)
        if IsValid(station) then
            station:SetVolume(6)
            station:Play()
            RiotSound = station
        end
    end)

    zb.RemoveFade()
end)

local teams = {
	[0] = {
		objective = "",
		name = "a Rioter",
		color1 = Color(190, 0, 0),
		color2 = Color(190, 0, 0),
	},
	[1] = {
		objective = "",
		name = "a Law Enforcement",
		color1 = Color(0, 120, 190),
		color2 = Color(0, 120, 190),
	},
}

function MODE:RenderScreenspaceEffects()
	zb.RoundFade.PaintBlackScreen()
end

function MODE:HUDPaint()
	if zb.ROUND_START + 8.5 < CurTime() then return end
	if not lply:Alive() then return end

	zb.RemoveFade()

	local fade = zb.RoundFade.GetIntroAlpha()
	local team_ = lply:Team()
	local teamData = teams[team_] or teams[0]

	draw.SimpleText("Homicide | Riot", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local colorRole = Color(teamData.color1.r, teamData.color1.g, teamData.color1.b, 255 * fade)
	draw.SimpleText("You are " .. teamData.name, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, colorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local colorObj = Color(teamData.color2.r, teamData.color2.g, teamData.color2.b, 255 * fade)
	draw.SimpleText(teamData.objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, colorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if hg.PluvTown.Active then
		surface.SetMaterial(hg.PluvTown.PluvMadness)
		surface.SetDrawColor(255, 255, 255, math.random(175, 255) * fade / 2)
		surface.DrawTexturedRect(sw * 0.25, sh * 0.44 - ScreenScale(15), sw / 2, ScreenScale(30))

		draw.SimpleText("SOMEWHERE IN PLUVTOWN", "ZB_ScrappersLarge", sw / 2, sh * 0.44 - ScreenScale(2), Color(0, 0, 0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

-- [ZB] round end UI handled by libraries/round_transitions/cl_round_transitions.lua

function MODE:RoundStart()
    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Remove()
        hmcdEndMenu = nil
    end
end
