
MODE.name = "dm"

local MODE = MODE

local fighter = {
	objective = "Kill everyone.",
	name = "Fighter",
	color1 = Color(0, 120, 190),
}

local radius = nil
local mapsize = 7500

local roundend = false

local snds = {
	"https://kappa.vgmsite.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/ujuwzquyre/01.%20A%20Grim%20Feeling.mp3",
	"https://kappa.vgmsite.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/zgagxqybov/02.%20Alley%20.mp3",
	"https://kappa.vgmsite.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/qsoislqepd/17.%20Hazardous.mp3",
	"https://kappa.vgmsite.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/zqxkrixwbn/26.%20Rooftops.mp3",
	"https://kappa.vgmsite.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/kvlgywwwnt/13.%20Escape.mp3"
}

local deathmatch_nozone = ConVarExists("deathmatch_nozone") and GetConVar("deathmatch_nozone") or CreateConVar("deathmatch_nozone", 0, FCVAR_REPLICATED, "Allows to disable deathmatch mode zone.", 0, 1)
local MusicVolume = GetConVar("snd_musicvolume")
local deathmatchThemeStation

local function IsDeathmatchZoneMode(mode)
	return mode and mode.UsesDeathmatchZone
end

local function StopDeathmatchTheme()
	if IsValid(deathmatchThemeStation) then
		deathmatchThemeStation:Stop()
	end

	deathmatchThemeStation = nil
end

local function GetDeathmatchThemePath(round)
	local themePath = round and round.ThemeMusicFile
	if not themePath or themePath == "" then return nil end

	if string.StartWith(themePath, "sound/") then
		return themePath
	end

	return "sound/" .. themePath
end

local function StartDeathmatchTheme(round)
	local themePath = GetDeathmatchThemePath(round)
	if not themePath then return false end

	local expectedRoundName = round.name
	StopDeathmatchTheme()

	sound.PlayFile(themePath, "noblock noplay", function(station, errCode, errStr)
		if not IsValid(station) then
			print(errCode, errStr)

			local currentRound = CurrentRound()
			if currentRound and currentRound.name == expectedRoundName and hg.DynaMusic then
				hg.DynaMusic:Start("mirrors_edge")
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

		deathmatchThemeStation = station
		station:EnableLooping(true)
		station:SetVolume((round.ThemeMusicVolume or 0.35) * ((MusicVolume and MusicVolume:GetFloat()) or 1))
		station:Play()
	end)

	return true
end

local function restartMusic()
	local snd = snds[math.random(#snds)]

	if IsValid(dmmusic) then
		dmmusic:Stop()
		dmmusic = nil
	end
	
	sound.PlayURL(snd, "mono noblock noplay", function(station, errID, err)
		if IsValid(station) then
			station:EnableLooping(true)
			station:SetVolume(0.1)
			
			dmmusic = station
		else
			print(errID, err)
		end
	end)
end


net.Receive("dm_start",function()
	roundend = false

	local round = CurrentRound() or MODE
	if round.ThemeMusicFile then
		StartDeathmatchTheme(round)
	else
		hg.DynaMusic:Start("mirrors_edge")
	end

	zb.RemoveFade()

	ZonePos = net.ReadVector()
	zonedistance = net.ReadFloat()

    surface.PlaySound("snd_jack_hmcd_deathmatch.mp3")
	sound.PlayFile( "sound/ambient/energy/force_field_loop1.wav", "noblock", function( station, errCode, errStr )
		if ( IsValid( station ) ) then
			zb.SoundStation = station
			
			station:Play()
			station:EnableLooping( true )
			station:SetVolume(0)
		end
	end )
end)

hook.Add("Think", "ZoneSoundThink", function()
	local round = CurrentRound()
	if not IsDeathmatchZoneMode(round) then return end
	local station = zb.SoundStation
	if not IsValid(station) then return end
	if deathmatch_nozone:GetBool() then return end
	local radius = MODE.GetZoneRadius()
	local volume = math.Clamp((LocalPlayer():GetPos():Distance(ZonePos) - radius) + 200,0,200) / 200
	station:SetVolume(volume)
end)

hook.Add("Think", "DeathmatchThemeVolumeThink", function()
	if not IsValid(deathmatchThemeStation) then return end

	local round = CurrentRound()
	if not round or not round.ThemeMusicFile then
		StopDeathmatchTheme()
		return
	end

	deathmatchThemeStation:SetVolume((round.ThemeMusicVolume or 0.35) * ((MusicVolume and MusicVolume:GetFloat()) or 1))

	if deathmatchThemeStation:GetState() != GMOD_CHANNEL_PLAYING then
		deathmatchThemeStation:Play()
	end
end)

hook.Add("RoundInfoCalled", "DeathmatchThemeRoundInfo", function(rnd)
	if not IsValid(deathmatchThemeStation) then return end

	local currentRound = CurrentRound()
	if currentRound and currentRound.ThemeMusicFile and rnd != currentRound.name then
		StopDeathmatchTheme()
	end
end)

--local zonemodel = ClientsideModel("models/hunter/misc/sphere375x375.mdl",RENDERGROUP_TRANSLUCENT)
--zonemodel:SetNoDraw(true)
--zonemodel:SetMaterial("hmcd_dmzone")

local mat = Material("hmcd_dmzone")

local mapsize = 7500

function MODE:PostDrawTranslucentRenderables(bDepth, bSkybox, isDraw3DSkybox)
	if(!bSkybox and !isDraw3DSkybox) and !deathmatch_nozone:GetBool() then
		local radius = MODE.GetZoneRadius()
		render.SetMaterial(mat)
		render.DrawSphere( ZonePos, -radius, 60, 60, color_white )
	end
	--zonemodel:DrawModel()
end

function MODE:RenderScreenspaceEffects()
	zb.RoundFade.PaintBlackScreen()
end

function MODE:HUDPaint()
	if zb.ROUND_START + 20 > CurTime() then
		draw.SimpleText(string.FormattedTime(zb.ROUND_START + 20 - CurTime(), "%02i:%02i:%02i"), "ZB_HomicideMedium", sw * 0.5, sh * 0.75, Color(255, 55, 55), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	else
		local ply = LocalPlayer()
		--if IsValid(dmmusic) then
		--	if dmmusic:GetTime() >= (dmmusic:GetLength() - 1) then
		--		restartMusic()
--
		--		return
		--	end
--
		--	if dmmusic:GetState() != GMOD_CHANNEL_PLAYING then
		--		dmmusic:Play()
		--		
		--		return
		--	end
--
		--	local vol = math.Clamp((CurTime() - (zb.ROUND_START + 22)),0.1, ply:Alive() and ply.organism.otrub and 0.1 or 0.2 + math.min((ply.organism.adrenaline or 0) * 25,2))
		--	if roundend then
		--		vol =  math.Clamp((roundend - CurTime() + 1) / 2,0.1, ply:Alive() and ply.organism.otrub and 0.1 or 0.2 + math.min((ply.organism.adrenaline or 0) * 25,2))
		--	end
		--	local musicVolume = GetConVar("snd_musicvolume"):GetFloat()
		--	dmmusic:SetVolume(vol*musicVolume)
		--end
	end

	if not lply:Alive() then return end
	if zb.ROUND_START + 8.5 < CurTime() then return end

	zb.RemoveFade()

	local fade = zb.RoundFade.GetIntroAlpha()
	draw.SimpleText("Homicide | DeathMatch", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local colorRole = Color(fighter.color1.r, fighter.color1.g, fighter.color1.b, 255 * fade)
	draw.SimpleText("You are a " .. fighter.name, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, colorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local colorObj = Color(fighter.color1.r, fighter.color1.g, fighter.color1.b, 255 * fade)
	draw.SimpleText(fighter.objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, colorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if hg.PluvTown.Active then
		surface.SetMaterial(hg.PluvTown.PluvMadness)
		surface.SetDrawColor(255, 255, 255, math.random(175, 255) * fade / 2)
		surface.DrawTexturedRect(sw * 0.25, sh * 0.44 - ScreenScale(15), sw / 2, ScreenScale(30))

		draw.SimpleText("SOMEWHERE IN PLUVTOWN", "ZB_ScrappersLarge", sw / 2, sh * 0.44 - ScreenScale(2), Color(0, 0, 0, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

-- [ZB] round end UI handled by libraries/round_transitions/cl_round_transitions.lua

function MODE:RoundStart()
    for i,ply in player.Iterator() do
		ply.won = nil
		ply.most_violent_player = nil
    end

    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Remove()
        hmcdEndMenu = nil
    end
end
