local MODE = MODE
local survivorAccent = Color(25, 230, 105)
local zombieAccent = Color(235, 55, 35)
local patientZeroAccent = Color(255, 90, 35)
local poisonAccent = Color(120, 210, 55)
local pendingAccent = Color(255, 185, 35)
local white = Color(238, 246, 241)
local muted = Color(130, 165, 145)
local panelBackground = Color(0, 13, 8, 188)
local consumeTextOutline = Color(0, 8, 4, 235)
local brainGlowMaterial = Material("sprites/light_glow02_add_noz")
local brainTargets = {}
local nextBrainTargetRefresh = 0
local brainAuraColor = Color(120, 8, 12, 0)
local brainLobeColor = Color(255, 48, 38, 0)
local brainCoreColor = Color(255, 205, 155, 0)
local zombiePlayerClasses = {
	headcrabzombie = true,
	fastzombie = true,
	poisonzombie = true,
}

surface.CreateFont("ZC_ZS_Header", {
	font = "Bahnschrift",
	size = 12,
	weight = 800,
})

surface.CreateFont("ZC_ZS_Status", {
	font = "Bahnschrift",
	size = 19,
	weight = 800,
})

surface.CreateFont("ZC_ZS_Metric", {
	font = "Bahnschrift",
	size = 11,
	weight = 800,
})

surface.CreateFont("ZC_ZS_Respawn", {
	font = "Bahnschrift",
	size = 24,
	weight = 800,
})

surface.CreateFont("ZC_ZS_SpawnReason", {
	font = "Bahnschrift",
	size = 14,
	weight = 900,
})

local roster = {
	nextUpdate = 0,
	survivors = 0,
	infected = 0
}

local respawnRingColor = Color(20, 45, 31, 220)
local respawnGradientCache = {}

local function FormatTime(seconds)
	seconds = math.max(math.ceil(seconds), 0)
	return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function DrawCutPanel(x, y, width, height, accent)
	local cut = 8
	local points = {
		{x = x + cut, y = y},
		{x = x + width - cut, y = y},
		{x = x + width, y = y + cut},
		{x = x + width, y = y + height - cut},
		{x = x + width - cut, y = y + height},
		{x = x + cut, y = y + height},
		{x = x, y = y + height - cut},
		{x = x, y = y + cut}
	}

	draw.NoTexture()
	surface.SetDrawColor(panelBackground)
	surface.DrawPoly(points)
	surface.SetDrawColor(accent.r, accent.g, accent.b, 175)
	for index = 1, #points do
		local nextIndex = index == #points and 1 or index + 1
		surface.DrawLine(points[index].x, points[index].y, points[nextIndex].x, points[nextIndex].y)
	end

	surface.DrawRect(x + 1, y + 21, width - 2, 1)
end

local function UpdateRosterCounts()
	if roster.nextUpdate > CurTime() then return end

	roster.nextUpdate = CurTime() + 0.5
	roster.survivors = 0
	roster.infected = 0

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR or ply:Team() == TEAM_UNASSIGNED then continue end

		if ply:GetNWBool("ZS_IsZombie", false) then
			roster.infected = roster.infected + 1
		elseif ply:Alive() then
			roster.survivors = roster.survivors + 1
		end
	end
end

local function IsZombiePlayer(ply)
	return IsValid(ply) and (zombiePlayerClasses[ply.PlayerClassName] == true or ply:GetNWBool("ZS_IsZombie", false))
end

local function GetBrainTransform(target, character)
	local attachmentID = character:LookupAttachment("eyes")
	if attachmentID and attachmentID > 0 then
		local attachment = character:GetAttachment(attachmentID)
		if attachment then
			return attachment.Pos - attachment.Ang:Forward() * 1.8 + attachment.Ang:Up() * 2.2, attachment.Ang:Right()
		end
	end

	local model = character:GetModel()
	if character.ZSBrainESPModel ~= model then
		character.ZSBrainESPModel = model
		character.ZSBrainESPBone = character:LookupBone("ValveBiped.Bip01_Head1")
	end

	local bone = character.ZSBrainESPBone
	if isnumber(bone) and bone >= 0 then
		local matrix = character:GetBoneMatrix(bone)
		if matrix then
			local ang = matrix:GetAngles()
			return matrix:GetTranslation() + ang:Up() * 2, ang:Right()
		end
	end

	return character:WorldSpaceCenter() + Vector(0, 0, character:BoundingRadius() * 0.35), target:GetRight()
end

local function RefreshBrainTargets(localPly)
	if CurTime() < nextBrainTargetRefresh then return end

	nextBrainTargetRefresh = CurTime() + 0.2
	brainTargets = {}
	local origin = localPly:EyePos()

	for _, target in player.Iterator() do
		if target == localPly or not target:Alive() or IsZombiePlayer(target) then continue end
		if target:Team() == TEAM_SPECTATOR or target:Team() == TEAM_UNASSIGNED then continue end

		local character = hg.GetCurrentCharacter(target)
		if not IsValid(character) then character = target end
		if not IsValid(character) or origin:DistToSqr(character:WorldSpaceCenter()) > 144000000 then continue end

		brainTargets[#brainTargets + 1] = {target, character}
	end
end

hook.Add("PostDrawTranslucentRenderables", "ZCityZombieSurvival_BrainESP", function(_, drawingSkybox)
	if drawingSkybox or zb.ROUND_STATE ~= 1 or CurrentRound() ~= MODE then return end

	local localPly = LocalPlayer()
	if not IsValid(localPly) or not localPly:Alive() or not IsZombiePlayer(localPly) or GetViewEntity() ~= localPly then
		brainTargets = {}
		return
	end

	RefreshBrainTargets(localPly)
	if #brainTargets == 0 then return end

	local now = CurTime()
	local origin = localPly:EyePos()
	render.SetMaterial(brainGlowMaterial)
	cam.IgnoreZ(true)

	for index = #brainTargets, 1, -1 do
		local entry = brainTargets[index]
		local target, character = entry[1], entry[2]
		if not IsValid(target) or not target:Alive() or IsZombiePlayer(target) or not IsValid(character) then
			table.remove(brainTargets, index)
			continue
		end

		local brainPos, brainRight = GetBrainTransform(target, character)
		local distance = origin:Distance(brainPos)
		local rangeFade = 1 - math.Clamp((distance - 8000) / 4000, 0, 1)
		if rangeFade <= 0 then continue end

		local beat = math.max(math.sin(now * 5.5 + target:EntIndex() * 0.37), 0) ^ 5
		local alpha = math.floor((195 + beat * 60) * rangeFade)
		local lobeOffset = 1.7 + beat * 0.35
		local lobeSize = 6.2 + beat * 1.8

		brainAuraColor.a = math.floor(alpha * 0.72)
		brainLobeColor.a = alpha
		brainCoreColor.a = alpha
		render.DrawSprite(brainPos, 18 + beat * 5, 18 + beat * 5, brainAuraColor)
		render.DrawSprite(brainPos - brainRight * lobeOffset, lobeSize, lobeSize, brainLobeColor)
		render.DrawSprite(brainPos + brainRight * lobeOffset, lobeSize, lobeSize, brainLobeColor)
		render.DrawSprite(brainPos, 3.4 + beat, 3.4 + beat, brainCoreColor)
	end

	cam.IgnoreZ(false)
end)

local function DrawProgressArc(centerX, centerY, radius, progress, accent)
	local segments = 48
	local endSegment = math.floor(segments * math.Clamp(progress, 0, 1))
	if endSegment <= 0 then return end

	local innerRadius = radius - 3

	draw.NoTexture()
	surface.SetDrawColor(accent.r, accent.g, accent.b, 235)
	for index = 0, endSegment - 1 do
		local angle1 = math.rad(-90 + index / segments * 360)
		local angle2 = math.rad(-90 + (index + 1) / segments * 360)
		surface.DrawPoly({
			{x = centerX + math.cos(angle1) * innerRadius, y = centerY + math.sin(angle1) * innerRadius},
			{x = centerX + math.cos(angle1) * radius, y = centerY + math.sin(angle1) * radius},
			{x = centerX + math.cos(angle2) * radius, y = centerY + math.sin(angle2) * radius},
			{x = centerX + math.cos(angle2) * innerRadius, y = centerY + math.sin(angle2) * innerRadius}
		})
	end
end

local function DrawGradientCircle(centerX, centerY, radius, accent)
	draw.RoundedBox(radius + 4, centerX - radius - 4, centerY - radius - 4, (radius + 4) * 2, (radius + 4) * 2, panelBackground)

	local cacheKey = accent.r .. ":" .. accent.g .. ":" .. accent.b
	local gradient = respawnGradientCache[cacheKey]
	if not gradient then
		gradient = {}
		for inset = 0, 12 do
			local blend = inset / 12
			gradient[inset] = Color(
				Lerp(blend, accent.r * 0.58, 2),
				Lerp(blend, accent.g * 0.58, 20),
				Lerp(blend, accent.b * 0.58, 11),
				Lerp(blend, 225, 245)
			)
		end
		respawnGradientCache[cacheKey] = gradient
	end

	for inset = 0, 12 do
		local currentRadius = radius - inset * 2
		draw.RoundedBox(currentRadius, centerX - currentRadius, centerY - currentRadius, currentRadius * 2, currentRadius * 2, gradient[inset])
	end
end

local spawnLocationValid = false
local spawnLocationStatus = 3
local spawnLocationCheckedAt = 0
local spawnLocationCheckedPos
local nextSpawnProbe = 0

local function GetSpawnCameraPosition()
	local view = render.GetViewSetup()
	return view and view.origin or EyePos()
end

local function IsCurrentSpawnLocationChecked()
	if not isvector(spawnLocationCheckedPos) then return false end
	if CurTime() - spawnLocationCheckedAt > 1.25 then return false end

	return GetSpawnCameraPosition():DistToSqr(spawnLocationCheckedPos) <= 32 * 32
end

local function IsCurrentSpawnLocationValid()
	return spawnLocationValid and IsCurrentSpawnLocationChecked()
end

net.Receive("ZCity_ZS_SpawnStatus", function()
	local checkedPos = net.ReadVector()
	local status = net.ReadUInt(2)
	local ply = LocalPlayer()
	if not IsValid(ply) or ply:Alive() or not ply:GetNWBool("ZS_SpawnReady", false) then return end

	spawnLocationCheckedPos = checkedPos
	spawnLocationCheckedAt = CurTime()
	spawnLocationStatus = status
	spawnLocationValid = status == 0
end)

hook.Add("Think", "ZCityZombieSurvival_SpawnLocationProbe", function()
	local ply = LocalPlayer()
	local ready = IsValid(ply)
		and zb.ROUND_STATE == 1
		and CurrentRound() == MODE
		and not ply:Alive()
		and ply:GetNWBool("ZS_IsZombie", false)
		and ply:GetNWBool("ZS_SpawnReady", false)

	if not ready then
		spawnLocationValid = false
		spawnLocationStatus = 3
		spawnLocationCheckedAt = 0
		spawnLocationCheckedPos = nil
		nextSpawnProbe = 0
		return
	end

	local cameraPos = GetSpawnCameraPosition()
	if isvector(spawnLocationCheckedPos) and cameraPos:DistToSqr(spawnLocationCheckedPos) > 32 * 32 then
		spawnLocationValid = false
		spawnLocationStatus = 3
	end

	if CurTime() < nextSpawnProbe then return end
	nextSpawnProbe = CurTime() + 0.6

	net.Start("ZCity_ZS_CheckSpawn")
		net.WriteVector(cameraPos)
	net.SendToServer()
end)

local function DrawRespawnTimer(ply, accent, isPatientZero)
	if ply:Alive() or not ply:GetNWBool("ZS_IsZombie", false) then return end

	local respawnAt = ply:GetNWFloat("ZS_RespawnAt", 0)
	local spawnReady = ply:GetNWBool("ZS_SpawnReady", false)
	if respawnAt <= 0 and not spawnReady then return end

	local remaining = spawnReady and 0 or math.max(respawnAt - CurTime(), 0)
	local duration = isPatientZero and MODE.FastZombieRespawnDelay or MODE.ZombieRespawnDelay
	local progress = spawnReady and 1 or 1 - math.Clamp(remaining / math.max(duration, 0.1), 0, 1)
	local centerX = math.floor(ScrW() * 0.5)
	local centerY = ScrH() - 88
	local radius = 38
	local ringAccent = spawnReady and (IsCurrentSpawnLocationValid() and survivorAccent or zombieAccent) or accent
	local rejectionText = spawnLocationStatus == 1 and "Too close to survivors"
		or spawnLocationStatus == 2 and "In sight of survivors"

	DrawGradientCircle(centerX, centerY, radius - 5, ringAccent)
	for ring = 0, 2 do
		surface.DrawCircle(centerX, centerY, radius - ring, respawnRingColor)
	end
	DrawProgressArc(centerX, centerY, radius, progress, ringAccent)

	draw.SimpleText(spawnReady and "E" or math.ceil(remaining), "ZC_ZS_Respawn", centerX, centerY - 13, white, TEXT_ALIGN_CENTER)
	draw.SimpleText(spawnReady and "SPAWN" or "REANIMATE", "ZC_ZS_Metric", centerX, centerY + 14, spawnReady and ringAccent or muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	if spawnReady and rejectionText and IsCurrentSpawnLocationChecked() then
		draw.SimpleTextOutlined(rejectionText, "ZC_ZS_SpawnReason", centerX, centerY - radius - 15, zombieAccent, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, consumeTextOutline)
	end
end

local nextSpawnRequest = 0

hook.Add("PlayerButtonDown", "ZCityZombieSurvival_CameraSpawn", function(ply, button)
	if ply ~= LocalPlayer() or button ~= KEY_E then return end
	if zb.ROUND_STATE ~= 1 or CurrentRound() ~= MODE then return end
	if ply:Alive() or not ply:GetNWBool("ZS_IsZombie", false) or not ply:GetNWBool("ZS_SpawnReady", false) then return end
	if gui.IsGameUIVisible() or vgui.CursorVisible() or IsValid(vgui.GetKeyboardFocus()) or CurTime() < nextSpawnRequest then return end

	nextSpawnRequest = CurTime() + 0.3
	local cameraPos = GetSpawnCameraPosition()

	net.Start("ZCity_ZS_RequestSpawn")
		net.WriteVector(cameraPos)
	net.SendToServer()
end)

local function DrawConsumePrompt(ply)
	if not ply:Alive() or not ply:GetNWBool("ZS_IsZombie", false) then return end

	local activeCorpse = ply:GetNWEntity("ZS_ConsumeCorpse", NULL)
	local corpse, _, trace = MODE:GetZombieConsumeTarget(ply)
	local drawCorpse = IsValid(activeCorpse) and activeCorpse or corpse
	if not IsValid(drawCorpse) then return end

	local worldPos = trace and trace.HitPos or drawCorpse:WorldSpaceCenter()
	local screenPos = worldPos:ToScreen()
	if not screenPos.visible then return end

	local text = "HOLD ALT + E  DEVOUR"
	surface.SetFont("ZC_ZS_Header")
	local textWidth, textHeight = surface.GetTextSize(text)
	local x, y = screenPos.x, screenPos.y + 16
	draw.SimpleTextOutlined(text, "ZC_ZS_Header", x, y, zombieAccent, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, consumeTextOutline)

	local progress = MODE:GetZombieConsumeProgress(ply)
	if progress <= 0 then return end

	surface.SetDrawColor(0, 12, 7, 220)
	surface.DrawRect(x - textWidth * 0.5, y + textHeight + 3, textWidth, 3)
	surface.SetDrawColor(zombieAccent)
	surface.DrawRect(x - textWidth * 0.5, y + textHeight + 3, textWidth * progress, 3)
end

local nextConsumeRequest = 0

local function UpdateConsumeRequest(ply)
	if not ply:Alive() or not ply:GetNWBool("ZS_IsZombie", false) then
		nextConsumeRequest = 0
		return
	end

	if not ply:KeyDown(IN_WALK) or not ply:KeyDown(IN_USE) then
		nextConsumeRequest = 0
		return
	end

	if IsValid(ply:GetNWEntity("ZS_ConsumeCorpse", NULL)) or CurTime() < nextConsumeRequest then return end

	local corpse = MODE:GetZombieConsumeTarget(ply)
	if not IsValid(corpse) then return end

	nextConsumeRequest = CurTime() + 0.4
	net.Start("ZCity_ZS_RequestConsume")
		net.WriteEntity(corpse)
	net.SendToServer()
end

function MODE:HUDPaint()
	if zb.ROUND_STATE ~= 1 then return end

	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	UpdateConsumeRequest(ply)

	UpdateRosterCounts()

	local infectionStarted = GetGlobalBool("ZS_InfectionStarted", false)
	local isZombie = ply:GetNWBool("ZS_IsZombie", false)
	local isPatientZero = ply:GetNWBool("ZS_IsPatientZero", false)
	local isPoisonZombie = ply:GetNWBool("ZS_IsPoisonZombie", false)
	local accent = not infectionStarted and pendingAccent or (isPoisonZombie and poisonAccent or (isPatientZero and patientZeroAccent or (isZombie and zombieAccent or survivorAccent)))
	local title
	local phase
	local role
	local progress

	if not infectionStarted then
		local remaining = GetGlobalFloat("ZS_InfectionAt", CurTime()) - CurTime()
		title = "INFECTION IN " .. FormatTime(remaining)
		phase = "PRE-INFECTION"
		role = "UNASSIGNED"
		progress = 1 - math.Clamp(remaining / math.max(MODE.InfectionDelay, 0.1), 0, 1)
	else
		local remaining = GetGlobalFloat("ZS_RoundEndsAt", CurTime()) - CurTime()
		phase = "OUTBREAK ACTIVE"
		progress = math.Clamp(remaining / math.max(MODE.ROUND_TIME, 0.1), 0, 1)

		if isPoisonZombie then
			title = "POISON CARRIER  |  " .. FormatTime(remaining)
			role = "POISON ZOMBIE"
		elseif isPatientZero then
			title = "PATIENT ZERO  |  " .. FormatTime(remaining)
			role = "FAST ZOMBIE"
		elseif isZombie then
			title = "INFECTED  |  " .. FormatTime(remaining)
			role = "ZOMBIE"
		else
			title = "SURVIVE  |  " .. FormatTime(remaining)
			role = "SURVIVOR"
		end
	end

	local width, height = math.min(420, ScrW() - 32), 70
	local x, y = math.floor((ScrW() - width) * 0.5), 14
	DrawCutPanel(x, y, width, height, accent)

	draw.SimpleText("ZOMBIE SURVIVAL", "ZC_ZS_Header", x + 11, y + 5, accent)
	draw.SimpleText(phase, "ZC_ZS_Metric", x + width - 11, y + 6, muted, TEXT_ALIGN_RIGHT)
	draw.SimpleText(title, "ZC_ZS_Status", x + width * 0.5, y + 28, white, TEXT_ALIGN_CENTER)

	surface.SetDrawColor(8, 45, 25, 230)
	surface.DrawRect(x + 11, y + 50, width - 22, 2)
	surface.SetDrawColor(accent)
	surface.DrawRect(x + 11, y + 50, math.floor((width - 22) * progress), 2)

	draw.SimpleText(role, "ZC_ZS_Metric", x + 11, y + 56, accent)
	draw.SimpleText("SURVIVORS " .. roster.survivors, "ZC_ZS_Metric", x + width * 0.5, y + 56, survivorAccent, TEXT_ALIGN_CENTER)
	draw.SimpleText("INFECTED " .. roster.infected, "ZC_ZS_Metric", x + width - 11, y + 56, zombieAccent, TEXT_ALIGN_RIGHT)

	DrawRespawnTimer(ply, accent, isPatientZero)
	DrawConsumePrompt(ply)
end
