local MODE = MODE
MODE.name = "criresp"
MODE.IntroTitle = "Crisis Response"
local song
local songfade = 0

net.Receive("criresp_start", function()
	surface.PlaySound("zbattle/criresp.mp3")

	timer.Simple(3, function()
		sound.PlayFile("sound/zbattle/criresp/criepmission.mp3", "mono noblock", function(station)
			if IsValid(station) then
				station:Play()
				song = station
				songfade = 1
			end
		end)
	end)
end)

local teams = {
	[0] = {
		objective = "Negotiations failed, eliminate the threat. 10-4",
		name = "a SWAT Operator",
		color1 = Color(68, 10, 255),
		color2 = Color(68, 10, 255),
	},
	[1] = {
		objective = "This is my fucking house, bitches, I can do what I want.",
		name = "a Suspect",
		color1 = Color(228, 49, 49),
		color2 = Color(228, 49, 49),
	},
}

function MODE:RenderScreenspaceEffects()
	zb.RemoveFade()

	if zb.ROUND_START + 85 < CurTime() then
		if songfade <= 0.01 and IsValid(song) then
			song:Stop()
			surface.PlaySound(lply:Team() == 0 and "zbattle/criresp/barricadedsuspectstart.mp3" or "snd_jack_hmcd_policesiren.wav")
		elseif IsValid(song) then
			songfade = Lerp(0.01, songfade, 0)
			song:SetVolume(songfade)
		end
	end

	zb.RoundFade.PaintBlackScreen()
end

local posadd = 0

function MODE:HUDPaint()
	local introFade = zb.RoundFade.GetIntroAlpha()

	if zb.ROUND_START + 90 > CurTime() then
		posadd = Lerp(FrameTime() * 5, posadd or 0, zb.ROUND_START + 7.3 < CurTime() and 0 or -sw * 0.4)
		local color = Color(255 * -math.sin(CurTime() * 3), 25, 255 * math.sin(CurTime() * 3))
		draw.SimpleText("SWAT will arrive in: " .. string.FormattedTime(zb.ROUND_START + 90 - CurTime(), "%02i:%02i"), "ZB_HomicideMedium", sw * 0.02 + posadd, sh * 0.95, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("SWAT will arrive in: " .. string.FormattedTime(zb.ROUND_START + 90 - CurTime(), "%02i:%02i"), "ZB_HomicideMedium", (sw * 0.02) - 2 + posadd, (sh * 0.95) - 2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	if zb.ROUND_START + 8.5 > CurTime() and lply:Alive() then
		zb.RemoveFade()

		local fade = introFade
		local team_ = lply:Team()
		local teamData = teams[team_] or teams[0]

		draw.SimpleText("Crisis Response", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local colorRole = Color(teamData.color1.r, teamData.color1.g, teamData.color1.b, 255 * fade)
		draw.SimpleText("You are " .. teamData.name, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, colorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local colorObj = Color(teamData.color2.r, teamData.color2.g, teamData.color2.b, 255 * fade)
		draw.SimpleText(teamData.objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, colorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if hg.PluvTown.Active and introFade > 0 then
		surface.SetMaterial(hg.PluvTown.PluvMadness)
		surface.SetDrawColor(255, 255, 255, math.random(175, 255) * introFade / 2)
		surface.DrawTexturedRect(sw * 0.25, sh * 0.44 - ScreenScale(15), sw / 2, ScreenScale(30))

		draw.SimpleText("SOMEWHERE IN PLUVTOWN", "ZB_ScrappersLarge", sw / 2, sh * 0.44 - ScreenScale(2), Color(0, 0, 0, 255 * introFade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

-- [ZB] round end UI handled by libraries/round_transitions/cl_round_transitions.lua

function MODE:RoundStart()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end
end
