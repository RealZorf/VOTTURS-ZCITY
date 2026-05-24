MODE.name = "scugarena"
MODE.IntroTitle = "Slug Arena"
MODE.IntroRoleName = "Slugcat"
MODE.IntroObjective = "Survive and eliminate others."

local MODE = MODE

local roundend = false

local snds = {
	"https://eta.vgmtreasurechest.com/soundtracks/rain-world-gamerip-switch-ps4-windows-2017/esigrazbvx/RW%2013%20-%20Action%20Scene.mp3",
	"https://eta.vgmtreasurechest.com/soundtracks/rain-world-gamerip-switch-ps4-windows-2017/nhorqnrimw/RW%2043%20-%20Bio%20Engineering.mp3",
	"https://eta.vgmtreasurechest.com/soundtracks/rain-world-gamerip-switch-ps4-windows-2017/mytihhgmqb/RW%2046%20-%20Lonesound.mp3",
	"https://eta.vgmtreasurechest.com/soundtracks/rain-world-gamerip-switch-ps4-windows-2017/lpnpntddfm/RW%2042%20-%20Kayava.mp3",
	"https://eta.vgmtreasurechest.com/soundtracks/rain-world-gamerip-switch-ps4-windows-2017/ksytiscxay/RW%2043%20-%20Albino.mp3",
	"https://eta.vgmtreasurechest.com/soundtracks/rain-world-gamerip-switch-ps4-windows-2017/gwzlivihho/Threat%20-%20Chimney%20Canopy.mp3",
	"https://eta.vgmtreasurechest.com/soundtracks/rain-world-gamerip-switch-ps4-windows-2017/hoizfhtpik/Threat%20-%20Farm%20Arrays.mp3",
	"https://eta.vgmtreasurechest.com/soundtracks/rain-world-gamerip-switch-ps4-windows-2017/nrlhdzzkey/Threat%20-%20Garbage%20Wastes.mp3",
	"https://eta.vgmtreasurechest.com/soundtracks/rain-world-gamerip-switch-ps4-windows-2017/neszrspvqq/Threat%20-%20Heavy%20Industrial.mp3",
	"https://eta.vgmtreasurechest.com/soundtracks/rain-world-gamerip-switch-ps4-windows-2017/xlekgoehuo/Threat%20-%20Outskirts.mp3",
	"https://eta.vgmtreasurechest.com/soundtracks/rain-world-gamerip-switch-ps4-windows-2017/sqnnxelsyr/Threat%20-%20Shoreline.mp3",
	"https://eta.vgmtreasurechest.com/soundtracks/rain-world-gamerip-switch-ps4-windows-2017/opgbomraxz/Threat%20-%20Sky%20Islands.mp3",
	"https://eta.vgmtreasurechest.com/soundtracks/rain-world-downpour-soundtrack-2023/bnibwqpmxd/10.%20Threat%20-%20Waterfront%20Complex.mp3",
	"https://eta.vgmtreasurechest.com/soundtracks/rain-world-downpour-soundtrack-2023/zlemcmhgsb/16.%20Threat%20-%20Metropolis%20%28Day%29.mp3",
	"https://eta.vgmtreasurechest.com/soundtracks/rain-world-downpour-soundtrack-2023/xcjyveuqgx/17.%20Threat%20-%20Metropolis%20%28Night%29.mp3",
	"https://eta.vgmtreasurechest.com/soundtracks/rain-world-downpour-soundtrack-2023/tpekkwpwxt/23.%20Threat%20-%20Pipe%20Yard.mp3",
	"https://eta.vgmtreasurechest.com/soundtracks/rain-world-downpour-soundtrack-2023/ciyrnpxhky/29.%20Threat%20-%20Outer%20Expanse.mp3",
	"https://eta.vgmtreasurechest.com/soundtracks/rain-world-downpour-soundtrack-2023/umipiratiq/41.%20Threat%20-%20Rubicon%20%28Unused%29.mp3",
}

local function restartMusic()
	local snd = snds[math.random(#snds)]

	if IsValid(dmmusic) then
		dmmusic:Stop()
		dmmusic = nil
	end
	
	sound.PlayURL(snd, "mono noblock noplay", function(station, errID, err)
		if IsValid(station) then
			station:SetVolume(0.1)
			
			dmmusic = station
		else
			print(errID, err)
		end
	end)
end

net.Receive("scugarena_start", function()
	roundend = false

	restartMusic()

	zb.RemoveFade()
	
    StartTime = CurTime()
	--surface.PlaySound("snd_jack_hmcd_deathmatch.mp3")
end)

local slugcat = {
    objective = "Survive and eliminate others.",
    name = "Slugcat",
    color1 = Color(190,15,15)
}

function MODE:RenderScreenspaceEffects()
	zb.RoundFade.PaintBlackScreen()
end

function MODE:HUDPaint()
	if zb.ROUND_START + 20 > CurTime() then
		draw.SimpleText( string.FormattedTime(zb.ROUND_START + 20 - CurTime(), "%02i:%02i:%02i"	), "ZB_HomicideMedium", sw * 0.5, sh * 0.75, Color(255,55,55), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	else
		local ply = LocalPlayer()
		if IsValid(dmmusic) then
			if dmmusic:GetTime() >= (dmmusic:GetLength() - 1) then
				restartMusic()

				return
			end

			if dmmusic:GetState() != GMOD_CHANNEL_PLAYING then
				dmmusic:Play()
				
				return
			end

			local vol = math.Clamp((CurTime() - (zb.ROUND_START + 22)),0.1, ply:Alive() and ply.organism.otrub and 0.1 or 1)
			if roundend then
				vol =  math.Clamp((roundend - CurTime() + 1) / 2,0, ply:Alive() and ply.organism.otrub and 0 or 1)
			end
			local musicVolume = GetConVar("snd_musicvolume"):GetFloat()
			dmmusic:SetVolume(vol*musicVolume)
		end
	end

	zb.RoundFade.PaintStandardIntro(self)
end

local wonply = nil

-- [ZB] round end UI handled by libraries/round_transitions/cl_round_transitions.lua

function MODE:RoundStart()
    for i, ply in player.Iterator() do
		ply.won = nil
    end

    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Remove()
        hmcdEndMenu = nil
    end
end
