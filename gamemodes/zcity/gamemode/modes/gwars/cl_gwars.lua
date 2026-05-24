MODE.name = "gwars"
local MODE = MODE

local playstart
local ended

local MusicVolume = GetConVar("snd_musicvolume")

net.Receive("gwars_start", function()
	surface.PlaySound("zbattle/nigshit.mp3")
	zb.RemoveFade()
	playstart = true
	ended = nil

	sound.PlayFile("sound/music_themes/ghetto_loop.wav", "noblock noplay", function(station)
		if IsValid(station) then
			GWARS_LoopStation = station
			station:SetVolume(1 * MusicVolume:GetFloat())
			station:EnableLooping(true)
		end
	end)

	sound.PlayFile("sound/music_themes/ghetto_police.wav", "noblock noplay", function(station)
		if IsValid(station) then
			GWARS_LoopStation2 = station
			station:SetVolume(1 * MusicVolume:GetFloat())
			station:EnableLooping(true)
		end
	end)

	//music_themes/ghetto_loop.wav
	//music_themes/ghetto_start.wav
	
end)

local teams = {
	[0] = {
		objective = "Kill all groove mazafakas",
		name = "a Bloodz Member",
		color1 = Color(180, 0, 0),
		color2 = Color(180, 0, 0)
	},
	[1] = {
		objective = "Kill all bloodz mazafakas",
		name = "a Groove Member",
		color1 = Color(0, 180, 0),
		color2 = Color(0, 180, 0)
	},
}

MODE.IntroTeams = teams

local lerpsnd = 0.3

function MODE:RenderScreenspaceEffects()
	zb.RoundFade.PaintBlackScreen()
end

surface.CreateFont("timer_Font2", {
	font = "Bahnschrift", 
	size = ScreenScale(12), 
	extended = true, 
	weight = 650,
	antialias = true,
	italic = false
})

function MODE:HUDPaint()
	//if !lply.organism or !lply.organism.fear then return end

	local timeBeforeSWAT = (zb.ROUND_START - CurTime() + 120)
	if timeBeforeSWAT > 0 and zb.ROUND_START + 10.5 < CurTime() then
		local time = string.FormattedTime(timeBeforeSWAT, "%02i:%02i:%02i")
		local text = "00:00:00"
		surface.SetFont("timer_Font2")
		surface.SetDrawColor(255, 255, 255, 255)
		local w, h = surface.GetTextSize(text)
		local w2, h2 = surface.GetTextSize("11:11:11 time left before SWAT arrives!")
		surface.SetTextPos(sw * 0.5 - w2 / 2, sh * 0.05)
		surface.DrawText(time)
		surface.SetTextPos(sw * 0.5 - w2 / 2 + w, sh * 0.05)
		surface.DrawText("time left before SWAT arrives!")
		//draw.SimpleText(" left before SWAT arrives!", "timer_Font2", sw * 0.432, sh * 0.05, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		//draw.SimpleText(time, "timer_Font2", sw * 0.36, sh * 0.05, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	if zb.ROUND_START + 8 < CurTime() then
		if playstart then
			sound.PlayFile("sound/music_themes/ghetto_start.wav", "noblock noplay", function(station)
				if IsValid(station) then
					station:SetVolume(0.3 * MusicVolume:GetFloat())
					station:Play()
				end
			end)

			playstart = nil
		end

		lerpsnd = LerpFT(0.01, lerpsnd, !ended and (lply:Alive() and lply.organism and !lply.organism.otrub and lply.organism.fear and math.Clamp(lply.organism.fear + 0.3 + (timeBeforeSWAT <= 0 and 2 or 0), 0, 1) or 0.3) or 0)
		
		if zb.ROUND_START + 12 < CurTime() then
			if IsValid(GWARS_LoopStation) then
				GWARS_LoopStation:SetVolume(lerpsnd * MusicVolume:GetFloat())
				GWARS_LoopStation:Play()
				
				if IsValid(GWARS_LoopStation2) then
					GWARS_LoopStation2:SetVolume(0)
					GWARS_LoopStation2:Play()
				end
			end
		end

		if IsValid(GWARS_LoopStation) and GWARS_LoopStation:GetState() == GMOD_CHANNEL_PLAYING then
			GWARS_LoopStation:SetVolume(lerpsnd * MusicVolume:GetFloat())
		end
	
		if timeBeforeSWAT <= 0 then
			if IsValid(GWARS_LoopStation2) then
				GWARS_LoopStation2:SetVolume(lerpsnd * MusicVolume:GetFloat())
			end
			
			if IsValid(GWARS_LoopStation) then
				GWARS_LoopStation:SetVolume(0)
			end
		end
	end

	if zb.ROUND_START + 8.5 < CurTime() then return end

	if not lply:Alive() then return end

	zb.RemoveFade()

	local fade = zb.RoundFade.GetIntroAlpha()
	local team_ = lply:Team()
	local teamData = teams[team_] or teams[0]

	draw.SimpleText("ZBattle | Gang Wars", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

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

MODE.IntroTitle = "ZBattle | Gang Wars"
MODE.IntroTeams = teams

-- [ZB] round end UI handled by libraries/round_transitions/cl_round_transitions.lua

function MODE:RoundStart()
	if IsValid(hmcdEndMenu) then
		hmcdEndMenu:Remove()
		hmcdEndMenu = nil
	end
end