local MODE = MODE
MODE.name = "overstimulated"

local roles = {
	[0] = {
		objective = "Hold your line and neutralize the threat.",
		name = "SWAT",
		color1 = Color(68, 10, 255),
		color2 = Color(68, 10, 255)
	},
	[1] = {
		objective = "Loot fast and survive.",
		name = "a Victim",
		color1 = Color(255, 255, 255),
		color2 = Color(255, 255, 255)
	},
	[2] = {
		objective = "Wait for your entry and eliminate everyone.",
		name = "overstimulated",
		color1 = Color(228, 49, 49),
		color2 = Color(228, 49, 49)
	}
}

local function DrawScaledText(text, font, x, y, color, alignX, alignY, scale)
	if scale == 1 then
		draw.SimpleText(text, font, x, y, color, alignX, alignY)
		return
	end

	local matrix = Matrix()
	matrix:Translate(Vector(x, y, 0))
	matrix:Scale(Vector(scale, scale, 1))
	matrix:Translate(Vector(-x, -y, 0))

	cam.PushModelMatrix(matrix)
	draw.SimpleText(text, font, x, y, color, alignX, alignY)
	cam.PopModelMatrix()
end

local function WrapNamesForWidth(names, maxWidth, font)
	if not istable(names) or #names == 0 then
		return {"none"}
	end

	surface.SetFont(font)
	local lines = {}
	local current = ""

	for i = 1, #names do
		local piece = current == "" and names[i] or ", " .. names[i]
		local candidate = current .. piece
		local width = surface.GetTextSize(candidate)

		if current ~= "" and width > maxWidth then
			lines[#lines + 1] = current
			current = names[i]
		else
			current = candidate
		end
	end

	if current ~= "" then
		lines[#lines + 1] = current
	end

	return lines
end

local function PlayCountdownTick()
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	ply:EmitSound("press4.mp3", 55, 120, 0.2, CHAN_AUTO)
end

function MODE:RenderScreenspaceEffects()
	zb.RemoveFade()
	if zb.ROUND_START + 7.5 < CurTime() then return end
	local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(), 0, 1)
	surface.SetDrawColor(0, 0, 0, 255 * fade)
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

local posadd = 0
local shooterCountdownStarted = false
local shooterCountdownStartTime = 0
local shooterLastSecond = -1
local shooterPulseScale = 1
local copsCountdownStarted = false
local copsCountdownStartTime = 0
local copsLastSecond = -1
local copsPulseScale = 1
local lastStandCountdownStarted = false
local lastStandCountdownStartTime = 0
local lastStandLastSecond = -1
local lastStandPulseScale = 1
local reportData = nil
local reportUntil = 0
local reportStart = 0
local roundCueStation = nil
local lastStandStation = nil

local function StopAllMusic()
	for _, station in ipairs({roundCueStation, lastStandStation}) do
		if IsValid(station) and station.Stop then
			station:Stop()
		end
	end

	roundCueStation = nil
	lastStandStation = nil
end

net.Receive("overstimulated_round_report", function()
	StopAllMusic()
	reportData = net.ReadTable()
	reportStart = CurTime()
	reportUntil = CurTime() + 8
end)

net.Receive("overstimulated_audio_cue", function()
	local cue = net.ReadString()
	if cue == "round45" then
		if IsValid(roundCueStation) then
			roundCueStation:Stop()
			roundCueStation = nil
		end

		sound.PlayFile("sound/overstimulatedround.mp3", "mono noblock", function(station)
			if not IsValid(station) then return end
			station:SetVolume(0.6)
			station:Play()
			roundCueStation = station
		end)
	elseif cue == "laststand" then
		if IsValid(lastStandStation) then
			lastStandStation:Stop()
			lastStandStation = nil
		end

		sound.PlayFile("sound/overstimlaststand.mp3", "mono noblock", function(station)
			if not IsValid(station) then return end
			station:SetVolume(0.75)
			station:Play()
			lastStandStation = station
		end)
	end
end)

function MODE:HUDPaint()
	local sw = ScrW()
	local sh = ScrH()
	local ply = LocalPlayer()
	local now = CurTime()

	local shooterCountdownStartAt = GetGlobalFloat("overstimulated_shooter_countdown_start_at", zb.ROUND_START + 10)
	local shooterSpawnAt = GetGlobalFloat("overstimulated_shooter_spawn_at", zb.ROUND_START + 60)
	local copsArrivalAt = GetGlobalFloat("overstimulated_cops_arrival_at", zb.ROUND_START + 240)
	local copsArrivalDelay = GetGlobalFloat("overstimulated_cops_arrival_delay", 240)
	local lastStandEndAt = GetGlobalFloat("overstimulated_laststand_end_at", 0)

	local shooterRemain = math.max(shooterSpawnAt - now, 0)
	local showShooterCountdown = now >= shooterCountdownStartAt and shooterRemain > 0

	if showShooterCountdown and not shooterCountdownStarted then
		shooterCountdownStarted = true
		shooterCountdownStartTime = now
		shooterLastSecond = -1
		shooterPulseScale = 1.15
	end

	if not showShooterCountdown then
		shooterCountdownStarted = false
		shooterLastSecond = -1
		shooterPulseScale = Lerp(FrameTime() * 10, shooterPulseScale, 1)
	end

	if showShooterCountdown then
		local sec = math.ceil(shooterRemain)
		if sec ~= shooterLastSecond then
			shooterLastSecond = sec
			shooterPulseScale = 1.18
			PlayCountdownTick()
		end

		shooterPulseScale = Lerp(FrameTime() * 9, shooterPulseScale, 1)

		local intro = math.Clamp((now - shooterCountdownStartTime) / 0.45, 0, 1)
		local alpha = math.floor(255 * intro)
		local shakeAmp = (1 - intro) * 6
		local shakeX = math.Rand(-shakeAmp, shakeAmp)
		local shakeY = math.Rand(-shakeAmp, shakeAmp)
		local x = sw * 0.5 + shakeX
		local y = sh * 0.14 + shakeY
		local color = Color(220, 45, 45, alpha)
		local shadow = Color(0, 0, 0, alpha)
		local text = tostring(sec) .. "s"

		DrawScaledText(text, "ZC_MM_Title", x + 2, y + 2, shadow, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, shooterPulseScale)
		DrawScaledText(text, "ZC_MM_Title", x, y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, shooterPulseScale)
	end

	local copsRemain = math.max(copsArrivalAt - now, 0)
	local copsShowWindow = math.max(copsArrivalDelay * 0.5, 1)
	local showCopsCountdown = copsRemain > 0 and copsRemain <= copsShowWindow

	if showCopsCountdown and not copsCountdownStarted then
		copsCountdownStarted = true
		copsCountdownStartTime = now
		copsLastSecond = -1
		copsPulseScale = 1.15
	end

	if not showCopsCountdown then
		copsCountdownStarted = false
		copsLastSecond = -1
		copsPulseScale = Lerp(FrameTime() * 10, copsPulseScale, 1)
	end

	if showCopsCountdown then
		local sec = math.ceil(copsRemain)
		if sec ~= copsLastSecond then
			copsLastSecond = sec
			copsPulseScale = 1.18
			PlayCountdownTick()
		end

		copsPulseScale = Lerp(FrameTime() * 9, copsPulseScale, 1)

		local intro = math.Clamp((now - copsCountdownStartTime) / 0.5, 0, 1)
		local alpha = math.floor(255 * intro)
		local shakeAmp = (1 - intro) * 8
		local shakeX = math.Rand(-shakeAmp, shakeAmp)
		local shakeY = math.Rand(-shakeAmp, shakeAmp)
		local x = sw * 0.5 + shakeX
		local y = sh * 0.07 + shakeY
		local color = Color(255, 80, 80, alpha)
		local shadow = Color(0, 0, 0, alpha)
		local text = tostring(sec) .. "s"

		DrawScaledText(text, "ZC_MM_Title", x + 2, y + 2, shadow, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, copsPulseScale)
		DrawScaledText(text, "ZC_MM_Title", x, y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, copsPulseScale)
	end

	local lastStandRemain = math.max(lastStandEndAt - now, 0)
	local showLastStandCountdown = lastStandEndAt > 0 and lastStandRemain > 0

	if showLastStandCountdown and not lastStandCountdownStarted then
		lastStandCountdownStarted = true
		lastStandCountdownStartTime = now
		lastStandLastSecond = -1
		lastStandPulseScale = 1.15
	end

	if not showLastStandCountdown then
		lastStandCountdownStarted = false
		lastStandLastSecond = -1
		lastStandPulseScale = Lerp(FrameTime() * 10, lastStandPulseScale, 1)
	end

	if showLastStandCountdown then
		local sec = math.ceil(lastStandRemain)
		if sec ~= lastStandLastSecond then
			lastStandLastSecond = sec
			lastStandPulseScale = 1.18
			PlayCountdownTick()
		end

		lastStandPulseScale = Lerp(FrameTime() * 9, lastStandPulseScale, 1)

		local intro = math.Clamp((now - lastStandCountdownStartTime) / 0.4, 0, 1)
		local alpha = math.floor(255 * intro)
		local shakeAmp = (1 - intro) * 5
		local shakeX = math.Rand(-shakeAmp, shakeAmp)
		local shakeY = math.Rand(-shakeAmp, shakeAmp)
		local x = sw * 0.5 + shakeX
		local y = sh * 0.07 + shakeY
		local color = Color(255, 70, 70, alpha)
		local shadow = Color(0, 0, 0, alpha)
		local text = tostring(sec) .. "s"

		DrawScaledText(text, "ZC_MM_Title", x + 2, y + 2, shadow, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, lastStandPulseScale)
		DrawScaledText(text, "ZC_MM_Title", x, y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, lastStandPulseScale)
	end

	if ply:Team() == 2 then
		local roleName = ply:GetNWString("OverstimulatedRole", "overstimulated")
		local waiting = now < shooterSpawnAt
		local fadeout = math.Clamp((shooterSpawnAt + 1.5 - now) / 1.5, 0, 1)
		local revealEnd = zb.ROUND_START + 8.5

		if (waiting or fadeout > 0) and now >= revealEnd then
			local alpha = waiting and 255 or math.floor(255 * fadeout)
			surface.SetDrawColor(0, 0, 0, alpha)
			surface.DrawRect(0, 0, sw, sh)

			local fade = waiting and 1 or fadeout
			local red = Color(228, 49, 49, 255 * fade)
			local white = Color(255, 255, 255, 255 * fade)

			draw.SimpleText("You are " .. roleName, "ZC_MM_Title", sw * 0.5, sh * 0.45, red, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("Its about time.", "ZCity_Veteran", sw * 0.5, sh * 0.54, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("Spawn in " .. string.FormattedTime(math.max(shooterSpawnAt - now, 0), "%02i:%02i"), "ZCity_Veteran", sw * 0.5, sh * 0.62, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	if zb.ROUND_START + 8.5 > now then
		if not ply:Alive() and ply:Team() ~= 0 and ply:Team() ~= 2 then return end

		local fade = math.Clamp(zb.ROUND_START + 8 - now, 0, 1)
		local teamId = ply:Team()
		local data = roles[teamId] or roles[1]
		local roleName = teamId == 2 and ply:GetNWString("OverstimulatedRole", data.name) or data.name

		local microShake = 1.2
		local titleX = sw * 0.5 + math.Rand(-microShake, microShake)
		local titleY = sh * 0.1 + math.Rand(-microShake, microShake)
		draw.SimpleText("Overstimulated", "ZC_MM_Title", titleX, titleY, Color(220, 35, 35, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local roleColor = Color(data.color1.r, data.color1.g, data.color1.b, 255 * fade)
		local objectiveColor = Color(data.color2.r, data.color2.g, data.color2.b, 255 * fade)

		draw.SimpleText("You are " .. roleName, "ZC_MM_Title", sw * 0.5, sh * 0.5, roleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(data.objective, "ZCity_Veteran", sw * 0.5, sh * 0.9, objectiveColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if reportData and reportUntil > now then
		local fadeIn = math.Clamp((now - reportStart) / 0.8, 0, 1)
		local fadeOut = math.Clamp((reportUntil - now) / 1.5, 0, 1)
		local fade = math.min(fadeIn, fadeOut)
		surface.SetDrawColor(0, 0, 0, 180 * fade)
		surface.DrawRect(0, 0, sw, sh)

		draw.SimpleText(reportData.title or "Incident Report", "ZC_MM_Title", sw * 0.5, sh * 0.25, Color(200, 50, 50, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(reportData.winner or "Outcome: unknown", "ZCity_Veteran", sw * 0.5, sh * 0.34, Color(255, 255, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		local reportFont = "ZCity_Veteran"
		local maxLineWidth = sw * 0.92
		local deceasedLines = WrapNamesForWidth(reportData.deceased or {}, maxLineWidth, reportFont)
		local survivorsLines = WrapNamesForWidth(reportData.survivors or {}, maxLineWidth, reportFont)
		surface.SetFont(reportFont)
		local _, lineHeight = surface.GetTextSize("W")
		lineHeight = math.max(lineHeight, 18)

		local y = sh * 0.42
		draw.SimpleText("Deceased:", reportFont, sw * 0.5, y, Color(220, 220, 220, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		for i = 1, #deceasedLines do
			y = y + lineHeight
			draw.SimpleText(deceasedLines[i], reportFont, sw * 0.5, y, Color(220, 220, 220, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		y = y + lineHeight * 0.65
		draw.SimpleText("Survivors:", reportFont, sw * 0.5, y, Color(180, 180, 180, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		for i = 1, #survivorsLines do
			y = y + lineHeight
			draw.SimpleText(survivorsLines[i], reportFont, sw * 0.5, y, Color(180, 180, 180, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		draw.SimpleText("Silence lingers where the shots once spoke.", reportFont, sw * 0.5, math.min(y + lineHeight * 1.25, sh * 0.9), Color(190, 190, 190, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end
