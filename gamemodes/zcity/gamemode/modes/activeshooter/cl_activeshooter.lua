local MODE = MODE
local HNS_SCHIZO_PHRASES = {
    "I WILL FUCKING KILL EVERYONE",
    "YOU ALL DESERVE IT!",
    "YOU CANT HIDE FROM ME!",
    "WHO IS TALKING?!",
    "GET OUT OF MY HEAD",
    "I CAN SEE YOU",
}

local hnsSchizoNextAt = 0
local hnsSchizoShowUntil = 0
local hnsSchizoBatch = {}

hook.Add("HUDPaint", "HNS_SchizoFlashes", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if not ply:GetNetVar("HNS_Schizo", false) then return end

    local t = CurTime()

    -- Show for 5 seconds, then wait 10 seconds before next burst
    if hnsSchizoShowUntil == 0 or (t >= hnsSchizoShowUntil and t >= hnsSchizoNextAt) then
        hnsSchizoBatch = {}
        for i = 1, 12 do
            hnsSchizoBatch[i] = HNS_SCHIZO_PHRASES[math.random(#HNS_SCHIZO_PHRASES)]
        end
        hnsSchizoShowUntil = t + 5
        hnsSchizoNextAt = hnsSchizoShowUntil + 10
    end

    if t < hnsSchizoShowUntil then
        local w, h = ScrW(), ScrH()
        local alpha = math.Clamp(200 + 55 * math.sin(t * 15), 80, 255)
        surface.SetFont("Trebuchet24")
        for i = 1, #hnsSchizoBatch do
            local x = math.random(math.floor(w * 0.1), math.floor(w * 0.9))
            local y = math.random(math.floor(h * 0.1), math.floor(h * 0.9))
            draw.SimpleTextOutlined(
                hnsSchizoBatch[i], "Trebuchet24", x, y,
                Color(255, 0, 0, alpha),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                1, Color(0, 0, 0, alpha * 0.6)
            )
        end
    end
end)
MODE.name = "activeshooter"
MODE.IntroTitle = "ZBattle | Active Shooter"
local roundEnding = false
net.Receive("hns_start", function()
    timer.Simple(0.2, function()
        sound.PlayFile("sound/zbattle/criresp/criepmission.mp3", "mono noblock", function(station)
            if IsValid(station) then
                station:Play()
            end
        end)
    end)
end)

local teams = {
    [0] = {
        objective = "Kill the Active Shooter before it's to late!",
        name = "SWAT Seal Team",
        color1 = Color(68, 10, 255),
        color2 = Color(68, 10, 255)
    },
    [1] = {
        objective = "You better hide, something bad is about to happen...",
        name = "Innocent",
        color1 = Color(0, 190, 190),
        color2 = Color(0, 190, 190)
    },
    [2] = {
        objective = "Listen to the voices and shot everything that moves...",
        name = "Active Shooter",
        color1 = Color(255, 0, 0),
        color2 = Color(228, 49, 49)
    },
}

MODE.IntroTeams = teams

function MODE:RenderScreenspaceEffects()
	zb.RemoveFade()
	zb.RoundFade.PaintBlackScreen()
end
local posadd = 0
function MODE:HUDPaint()

    if zb.ROUND_START + 60 > CurTime() then
        posadd = Lerp(FrameTime() * 5,posadd or 0, zb.ROUND_START + 7.3 < CurTime() and 0 or -sw * 0.4)
        local blink = math.sin(CurTime()*3) >= 0 and Color(255,0,0) or Color(0,0,0)
        draw.SimpleText( "Active Shooter will arrive in: "..string.FormattedTime(zb.ROUND_START + 60 - CurTime(), "%02i:%02i"), "ZB_HomicideMedium", sw * 0.02 + posadd, sh * 0.91, Color(0,0,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText( "Active Shooter will arrive in: "..string.FormattedTime(zb.ROUND_START + 60 - CurTime(), "%02i:%02i"), "ZB_HomicideMedium", (sw * 0.02) - 2 + posadd, (sh * 0.91) - 2, blink, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    if zb.ROUND_START + 240 > CurTime() then
        posadd = Lerp(FrameTime() * 5,posadd or 0, zb.ROUND_START + 7.3 < CurTime() and 0 or -sw * 0.4) 
        local color = Color(255*-math.sin(CurTime()*3),25,255*math.sin(CurTime()*3))
        draw.SimpleText( string.FormattedTime(zb.ROUND_START + 240 - CurTime(), "%02i:%02i").." Until Round End", "ZB_HomicideMedium", sw * 0.02 + posadd, sh * 0.95, Color(0,0,0), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText( string.FormattedTime(zb.ROUND_START + 240 - CurTime(), "%02i:%02i").." Until Round End", "ZB_HomicideMedium", (sw * 0.02) - 2 + posadd, (sh * 0.95) - 2, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    if lply:Team() == 2 then
        local arrive = (zb.ROUND_START + 60) - CurTime()
        local t = CurTime()
        local active = t < arrive
        local fadeout = math.Clamp((arrive + 1.5 - t) / 1.5, 0, 1)
        local revealEnd = zb.ROUND_START + 8.5
        if (active or fadeout > 0) and t >= revealEnd then
            local alpha = active and 255 or math.floor(255 * fadeout)
            surface.SetDrawColor(0, 0, 0, alpha)
            surface.DrawRect(0, 0, sw, sh)
            local fade = active and 1 or fadeout
            local colRed = Color(228, 49, 49, 255 * fade)
            local colWhite = Color(255, 255, 255, 255 * fade)
            draw.SimpleText("You are a Active Shooter", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.4, colRed, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Find all people and kill them.", "ZB_HomicideMedium", sw * 0.5, sh * 0.5, colWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("You will arrive in " .. string.FormattedTime(math.max(arrive - t, 0), "%02i:%02i"), "ZB_HomicideMedium", sw * 0.5, sh * 0.6, colWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

	if lply:Team() ~= 2 then
		zb.RoundFade.PaintStandardIntro(self)
	end
end

-- [ZB] round end UI handled by libraries/round_transitions/cl_round_transitions.lua

function MODE:RoundStart()
    if IsValid(hmcdEndMenu) then
        hmcdEndMenu:Remove()
        hmcdEndMenu = nil
    end
end
