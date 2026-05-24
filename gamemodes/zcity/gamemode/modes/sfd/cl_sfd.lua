
MODE.name = "superfighters"
MODE.IntroTitle = "Superfighters 3D"
MODE.IntroRoleName = "Superfighter"
MODE.IntroObjective = "Kill everyone."

local MODE = MODE

local fighter = {
	objective = "Kill everyone.",
	name = "Superfighter",
	color1 = Color(0, 120, 190),
}

local radius = nil
local mapsize = 7500
-- MODE.MapSize = mapsize

StartTime = StartTime or 0

zb.ROUND_START = zb.ROUND_START or 0

ZonePos = ZonePos or Vector(0,0,0)
dmmusic = dmmusic or nil

local roundend = false

local snds = {
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/iwhxpivf/01.%20A%20Grim%20Feeling.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/mtgdygkh/02.%20Alley%20.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/fflmfnap/03.%20Anarchy%20.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/korpbnkj/05.%20Balista.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/kskuvrwi/09.%20Cowboy%20Robot.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/pzdrcika/11.%20Downtown.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/ttnjhkbe/14.%20Funnyman.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/imlvujpu/17.%20Hazardous.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/digfibga/18.%20Heroes%20Battle.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/leltjoug/19.%20High%20Moon.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/vmvsazvg/20.%20Iron%20Fists.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/rwhvibkt/25.%20Military.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/ptymnflo/26.%20Rooftops.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/odapyyyv/27.%20Rust%20And%20Gore.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/icnhxrsl/28.%20Seek%20And%20Destroy.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/awhxnyct/29.%20SFD%20Classic.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/jrhivbwe/30.%20Shards.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/gucepmnf/31.%20Steamship%20Synths.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/mumzmlvt/32.%20Steamship.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/gakzpeyi/33.%20Steamy.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/rlfuhzdr/34.%20Submarine.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/pxtzqfeh/38.%20The%20Dragon.mp3",
	"https://vgmtreasurechest.com/soundtracks/superfighters-deluxe-original-soundtrack-2018/wkmgufqo/39.%20Zombie%20Nightmare.mp3",
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

net.Receive("supfight_start",function()	
	roundend = false

	restartMusic()

	zb.RemoveFade()
	
    StartTime = CurTime()
	ZonePos = net.ReadVector()
    --surface.PlaySound("snd_jack_hmcd_deathmatch.mp3")
end)

local fighter = {
    objective = "Kill everyone.",
    name = "Superfighter",
    color1 = Color(0,120,190)
}

--local zonemodel = ClientsideModel("models/hunter/misc/sphere375x375.mdl",RENDERGROUP_TRANSLUCENT)
--zonemodel:SetNoDraw(true)
--zonemodel:SetMaterial("hmcd_dmzone")

local mat = Material("hmcd_dmzone")

local mapsize = 7500

function MODE:RenderScreenspaceEffects()
	zb.RoundFade.PaintBlackScreen()
end

function MODE:PostDrawTranslucentRenderables(bDepth, bSkybox, isDraw3DSkybox)
	if(!bSkybox and !isDraw3DSkybox)then
		--render.SetMaterial(mat)
		--render.DrawSphere( ZonePos, -(mapsize * math.max(( (zb.ROUND_START + 300) - CurTime()) / 300,0.025)), 60, 60, color_white )
	end
	--zonemodel:DrawModel()
end

function MODE:HUDPaint()
	if zb.ROUND_START + 5 > CurTime() then
		draw.SimpleText( string.FormattedTime(zb.ROUND_START + 5 - CurTime(), "%02i:%02i:%02i"	), "ZB_HomicideMedium", sw * 0.5, sh * 0.75, Color(255,55,55), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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

			local vol = math.Clamp((CurTime() - (zb.ROUND_START + 7)),0.1, ply:Alive() and ply.organism.otrub and 0.1 or 1 + math.min((ply.organism.adrenaline or 0) * 25,2))
			if roundend then
				vol = math.Clamp((roundend - CurTime() + 1) / 2,0.1, ply:Alive() and ply.organism.otrub and 0.1 or 1 + math.min((ply.organism.adrenaline or 0) * 25,2))
			end
			local musicVolume = GetConVar("snd_musicvolume"):GetFloat()
			dmmusic:SetVolume(vol*musicVolume)
		end
	end
	
	for i, ply in player.Iterator() do
		if ply == LocalPlayer() or not ply:Alive() then continue end
		local tr = hg.eyeTrace(ply)
		if not tr or not tr.StartPos then continue end
		local dist = ply:GetPos():Distance(LocalPlayer():GetPos())
		local pos = tr.StartPos + vector_up * 15
		local posscr = pos:ToScreen()
		dist = math.Clamp(dist / 128, 1, 16)
		local width = ScrW() / 8 / dist
		local height = ScrH() / 64 / dist
		local health = ply:Health() / 100
		surface.SetDrawColor(122,122,122,255)
		surface.DrawRect(posscr.x - width / 2, posscr.y - height, width, height)
		surface.SetDrawColor(255 * (1 - health),255 * health,0,255)
		surface.DrawRect(posscr.x - width / 2, posscr.y - height, width * health, height)
		
		surface.SetTextColor(255,255,255,255)
		surface.SetFont("ScoreboardDefault")
		local txt = ply:Name()
		local w, h = surface.GetTextSize(txt)
		surface.SetTextPos(posscr.x - w / 2, posscr.y - h * 1 - height)
		surface.DrawText(txt)
	end

	if not lply:Alive() then return end
	if zb.ROUND_START + 8.5 < CurTime() then return end

	zb.RemoveFade()

	local fade = zb.RoundFade.GetIntroAlpha()
	draw.SimpleText("Superfighters 3D", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0, 162, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local colorRole = Color(fighter.color1.r, fighter.color1.g, fighter.color1.b, 255 * fade)
	draw.SimpleText("You are a " .. fighter.name, "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, colorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local colorObj = Color(fighter.color1.r, fighter.color1.g, fighter.color1.b, 255 * fade)
	draw.SimpleText(fighter.objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, colorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local wonply = nil

-- [ZB] round end UI handled by libraries/round_transitions/cl_round_transitions.lua

function MODE:RoundStart()
    for i,ply in player.Iterator() do
		ply.won = nil
    end

    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Remove()
        hmcdEndMenu = nil
    end
end
