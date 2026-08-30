local MODE = MODE

net.Receive("HMCD_CannibalStacked", function()
	surface.PlaySound("cannibalstacked.wav")
end)

hook.Add("PreDrawHalos", "HMCD_RevenantTraitorMarker", function()
	local viewer = LocalPlayer()
	if not IsValid(viewer) or not viewer:Alive() or not viewer.isTraitor then return end
	local anchors = {}
	for _, ply in player.Iterator() do
		if ply ~= viewer and ply:GetNWBool("HMCD_RevenantPossessing", false) then
			local anchor = ply:GetNWEntity("HMCD_RevenantOriginalBody")
			if IsValid(anchor) then
				anchors[#anchors + 1] = anchor
			end
		end
	end
	if #anchors > 0 then
		halo.Add(anchors, Color(255, 155, 40), 1, 1, 1, true, false)
	end
end)

local revenantOverlay = Material("sprites/mat_jack_helmoverlay_r")
local revenantWasPossessing = false
local revenantBootUntil = 0
local revenantBootDuration = MODE.RevenantBootDuration or 2
local revenantBootRows = {}
local revenantBootRowWidth = 0
local revenantBootRowCount = 0

surface.CreateFont("HMCDRevenantBootTitle", {
	font = "Roboto Light",
	extended = true,
	size = ScreenScale(30),
	weight = 650,
	scanlines = 3,
	antialias = true,
})

surface.CreateFont("HMCDRevenantBootText", {
	font = "Roboto Light",
	extended = true,
	size = ScreenScale(6.5),
	weight = 1100,
	scanlines = 2,
	antialias = true,
})

surface.CreateFont("HMCDRevenantBootData", {
	font = "Roboto Light",
	extended = true,
	size = ScreenScale(5),
	weight = 700,
	antialias = true,
})

local function getRevenantBootRows(width, height)
	local rowHeight = math.max(18, math.floor(ScreenScale(6)))
	local rowCount = math.ceil(height / rowHeight) + 1
	if revenantBootRowWidth == width and revenantBootRowCount == rowCount then
		return rowHeight
	end

	local columns = math.ceil(width / math.max(12, ScreenScale(4)))
	revenantBootRows = {}
	for row = 1, rowCount do
		local values = {}
		for column = 1, columns do
			values[column] = ((row * 17 + column * 29 + row * column) % 7 < 3) and "1" or "0"
		end
		revenantBootRows[row] = table.concat(values, " ")
	end
	revenantBootRowWidth = width
	revenantBootRowCount = rowCount

	return rowHeight
end

local function drawRevenantBoot(width, height, remaining)
	local progress = math.Clamp(1 - remaining / revenantBootDuration, 0, 1)
	local alpha = 255
	local rowHeight = getRevenantBootRows(width, height)
	local dataOffset = math.floor(CurTime() * 18) % rowHeight

	surface.SetAlphaMultiplier(1)
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawRect(0, 0, width, height)
	for row, data in ipairs(revenantBootRows) do
		local y = (row - 1) * rowHeight - dataOffset
		draw.SimpleText(data, "HMCDRevenantBootData", 0, y, Color(25, 105, 145, 72), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	local diagnosticX = math.max(20, width * 0.035)
	local diagnosticY = math.max(20, height * 0.04)
	local diagnostics = {
		"NEURAL LINK INITIALIZATION",
		"ANCHOR SIGNAL: STABLE",
		"MOTOR CORTEX: ONLINE",
		"MEMORY ISOLATION: ACTIVE",
		"SHELL CONTROL: READY",
	}
	for index, text in ipairs(diagnostics) do
		draw.SimpleText(text, "HMCDRevenantBootText", diagnosticX, diagnosticY + (index - 1) * ScreenScale(7), Color(125, 210, 240, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	surface.SetFont("HMCDRevenantBootTitle")
	local _, titleHeight = surface.GetTextSize("REVENANT")
	surface.SetFont("HMCDRevenantBootText")
	local _, textHeight = surface.GetTextSize("SYNCHRONIZING")
	local titleY = height * 0.42
	local subtitleY = titleY + titleHeight * 0.5 + ScreenScale(3)
	local statusY = subtitleY + textHeight + ScreenScale(4)
	draw.SimpleText("REV3NANT", "HMCDRevenantBootTitle", width * 0.5, titleY, Color(120, 220, 245, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("LINKING TO REANIMATED SHELL", "HMCDRevenantBootText", width * 0.5, subtitleY, Color(195, 225, 235, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

	local barWidth = math.max(260, width * 0.24)
	local barHeight = math.max(8, ScreenScale(3))
	local barX = width * 0.5 - barWidth * 0.5
	local barY = statusY + textHeight + ScreenScale(3)
	surface.SetDrawColor(0, 8, 14, alpha)
	surface.DrawRect(barX - 2, barY - 2, barWidth + 4, barHeight + 4)
	surface.SetDrawColor(115, 215, 245, alpha)
	surface.DrawOutlinedRect(barX - 2, barY - 2, barWidth + 4, barHeight + 4, 1)
	surface.DrawRect(barX, barY, barWidth * progress, barHeight)
	draw.SimpleText(string.format("SYNCHRONIZING  %d%%", math.floor(progress * 100)), "HMCDRevenantBootText", width * 0.5, statusY, Color(195, 225, 235, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

hook.Add("RenderScreenspaceEffects", "HMCD_RevenantPossessionOverlay", function()
	local ply = LocalPlayer()
	local possessing = IsValid(ply) and ply:Alive() and ply:GetNWBool("HMCD_RevenantPossessing", false)
	if possessing and not revenantWasPossessing then
		revenantBootUntil = CurTime() + revenantBootDuration
		ply.HMCD_RevenantBootUntil = revenantBootUntil
	end
	revenantWasPossessing = possessing
	if not possessing then return end
	if CurTime() < revenantBootUntil then return end

	if not revenantOverlay:IsError() then
		surface.SetDrawColor(40, 165, 195, 185)
		surface.SetMaterial(revenantOverlay)
		surface.DrawTexturedRectRotated((ScrW() / 2) - 5, (ScrH() / 2) - 5, ScrW() + 10, ScrH() + 450, 180)
	end

	local width, height = ScrW(), ScrH()
	local lineSpacing = math.max(4, math.floor(ScreenScale(2)))
	local lineAlpha = 10 + math.floor((math.sin(CurTime() * 1.5) + 1) * 3)
	surface.SetDrawColor(70, 190, 225, lineAlpha)
	for y = 0, height, lineSpacing do
		surface.DrawRect(0, y, width, 1)
	end

end)

hook.Add("PostDrawHUD", "HMCD_RevenantPossessionBoot", function()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() or not ply:GetNWBool("HMCD_RevenantPossessing", false) then return end

	local remaining = (ply.HMCD_RevenantBootUntil or 0) - CurTime()
	if remaining > 0 then
		drawRevenantBoot(ScrW(), ScrH(), remaining)
	end
end)

--\\Neck Break
net.Receive("HMCD_BeingVictimOfNeckBreak", function(len, ply)
	LocalPlayer().BeingVictimOfNeckBreak = net.ReadBool()
	
	if(LocalPlayer().BeingVictimOfNeckBreak)then
		BeingVictimOfNeckBreakResetTime = CurTime() + 5
	else
		BeingVictimOfNeckBreakResetTime = nil
	end
end)

net.Receive("HMCD_BreakingOtherNeck", function(len, ply)
	local status = net.ReadBool()
	local attacker_ply = net.ReadEntity()
	
	if(status)then
		local other_ply = net.ReadEntity()
		local action = net.ReadString()
		
		if(IsValid(attacker_ply))then
			MODE.StartBreakingOtherNeck(LocalPlayer(), other_ply, action ~= "" and action or nil)
		end
	else
		if(IsValid(attacker_ply))then
			MODE.StopBreakingOtherNeck(LocalPlayer())
		end
	end
end)
--

--\\
net.Receive("HMCD_BeingVictimOfDisarmament", function(len, ply)
	LocalPlayer().BeingVictimOfDisarmament = net.ReadBool()
	
	if(LocalPlayer().BeingVictimOfDisarmament)then
		BeingVictimOfDisarmamentResetTime = CurTime() + 5
	else
		BeingVictimOfDisarmamentResetTime = nil
	end
end)

net.Receive("HMCD_DisarmingOther", function(len, ply)
	local status = net.ReadBool()
	
	if(status)then
		local other_ply = net.ReadEntity()
		
		MODE.StartDisarmingOther(LocalPlayer(), other_ply)
	else
		MODE.StopDisarmingOther(LocalPlayer())
	end
end)
--

--\\Chemical resistance
net.Receive("HMCD_UpdateChemicalResistance", function(len, ply)
	local chemical_name = net.ReadString()
	
	if(chemical_name == "")then
		LocalPlayer().PassiveAbility_ChemicalAccumulation = {}
		LocalPlayer().PassiveAbility_VGUI_ChemicalAccumulation = {}
	end
	
	while chemical_name != "" do
		local amt = net.ReadUInt(MODE.NetSize_ChemicalResistanceBits)
		
		SetChemicalToPlayer(LocalPlayer(), chemical_name, amt)
		
		chemical_name = net.ReadString()
	end
end)
--

net.Receive("HMCD_ChemistNeutralizerTarget", function()
	LocalPlayer().HMCD_ChemistNeutralizerTarget = net.ReadEntity()
end)

--\\Stalker sonar
local stalkerMarks = {}
local matStalkerGlow = Material("sprites/light_glow02_add")

local function getStalkerMarkState(target)
	stalkerMarks.State = stalkerMarks.State or {}
	stalkerMarks.State[target] = stalkerMarks.State[target] or {
		nextBeat = 0,
		lastBeat = 0,
		interval = 60 / 70
	}

	return stalkerMarks.State[target]
end

local function getStalkerPulseColor(target, stunReady)
	local vec = IsValid(target) and target:GetPlayerColor() or Vector(0.31, 0.82, 1)
	local color = Color(
		math.Clamp(vec.x * 255, 60, 255),
		math.Clamp(vec.y * 255, 60, 255),
		math.Clamp(vec.z * 255, 60, 255),
		stunReady and 190 or 120
	)

	if color.r + color.g + color.b < 210 then
		color.r = 80
		color.g = 210
		color.b = 255
	end

	return color
end

local function getStalkerTargetDrawPos(target)
	if not IsValid(target) then return nil end

	local ent = hg.GetCurrentCharacter and hg.GetCurrentCharacter(target) or target
	if not IsValid(ent) then ent = target end

	local bone = ent.LookupBone and ent:LookupBone("ValveBiped.Bip01_Spine2")
	if bone then
		local mat = ent:GetBoneMatrix(bone)
		if mat then return mat:GetTranslation() end
	end

	return ent:WorldSpaceCenter()
end

local function getTargetHeartbeat(target)
	local org = IsValid(target) and (target.organism or target.new_organism) or nil
	return math.Clamp((org and org.heartbeat) or 70, 45, 180)
end

local function getStalkerScreenPos(pos)
	local scr = pos:ToScreen()
	if scr.visible then
		return scr.x, scr.y, true
	end

	local ply = LocalPlayer()
	if IsValid(ply) then
		local dir = pos - ply:EyePos()
		if dir:LengthSqr() > 0 then
			dir:Normalize()
			if ply:EyeAngles():Forward():Dot(dir) < 0 then
				scr.x = ScrW() - scr.x
				scr.y = ScrH() - scr.y
			end
		end
	end

	local margin = ScreenScale(18)
	return math.Clamp(scr.x, margin, ScrW() - margin), math.Clamp(scr.y, margin, ScrH() - margin), false
end

local function drawStalkerPulseAt(x, y, color, size, alpha, offscreen, preySense)
	surface.SetMaterial(matStalkerGlow)
	surface.SetDrawColor(color.r, color.g, color.b, alpha)
	surface.DrawTexturedRect(x - size, y - size, size * 2, size * 2)

	if preySense then
		local core = size * 0.42
		surface.SetDrawColor(255, 245, 225, math.min(alpha + 40, 235))
		surface.DrawTexturedRect(x - core, y - core, core * 2, core * 2)
	end

	if offscreen then
		local ring = size * 0.55
		surface.SetDrawColor(color.r, color.g, color.b, math.min(alpha + 35, 220))
		surface.DrawOutlinedRect(x - ring, y - ring, ring * 2, ring * 2, math.max(1, ScreenScale(1)))

		if preySense then
			local outer = size * 0.82
			surface.SetDrawColor(255, 245, 225, math.min(alpha + 10, 190))
			surface.DrawOutlinedRect(x - outer, y - outer, outer * 2, outer * 2, math.max(1, ScreenScale(1)))
		end
	end
end

net.Receive("HMCD_StalkerMarks", function()
	stalkerMarks.List = {}
	local count = net.ReadUInt(2)

	for i = 1, count do
		stalkerMarks.List[i] = {
			Target = net.ReadEntity(),
			StunReady = net.ReadBool(),
			Isolated = net.ReadBool()
		}
	end
end)

hook.Add("HUDPaint", "HMCD_StalkerSonar", function()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() or not MODE.IsStalkerRole or not MODE.IsStalkerRole(ply.SubRole) then return end

	local now = CurTime()
	local gaze = ply:GetNWEntity("HMCD_StalkerGazeTarget")
	local ready_at = ply:GetNWFloat("HMCD_StalkerGazeReadyAt", 0)
	local start_at = ply:GetNWFloat("HMCD_StalkerGazeStartedAt", 0)

	if IsValid(gaze) and ready_at > start_at then
		local pos = getStalkerTargetDrawPos(gaze)
		if pos then
			local scr = pos:ToScreen()
			if scr.visible then
				local frac = math.Clamp(1 - ((ready_at - now) / MODE.StalkerMarkTime), 0, 1)
				local size = ScreenScale(10)
				local pulse = 0.65 + math.sin(now * 8) * 0.35
				local color = getStalkerPulseColor(gaze, true)

				surface.SetMaterial(matStalkerGlow)
				surface.SetDrawColor(color.r, color.g, color.b, 20 + 70 * frac + 14 * pulse)
				surface.DrawTexturedRect(scr.x - size * 1.7, scr.y - size * 1.7, size * 3.4, size * 3.4)

				local bar_w = size * 2.4
				local bar_h = math.max(2, ScreenScale(1))
				surface.SetDrawColor(0, 0, 0, 120)
				surface.DrawRect(scr.x - bar_w / 2, scr.y + size + ScreenScale(4), bar_w, bar_h)
				surface.SetDrawColor(color.r, color.g, color.b, 230)
				surface.DrawRect(scr.x - bar_w / 2, scr.y + size + ScreenScale(4), bar_w * frac, bar_h)
			end
		end
	end

	for _, mark in ipairs(stalkerMarks.List or {}) do
		local target = mark.Target
		if not IsValid(target) or not target:Alive() then continue end

		local state = getStalkerMarkState(target)
		local heartbeat = getTargetHeartbeat(target)
		if mark.Isolated then
			heartbeat = math.Clamp(heartbeat + 24, 55, 190)
		end

		local interval = 60 / heartbeat

		if state.nextBeat <= now then
			state.lastBeat = now
			state.interval = interval
			state.nextBeat = now + interval
		end

		local elapsed = now - state.lastBeat
		local beatFrac = math.Clamp(elapsed / math.max(state.interval, 0.1), 0, 1)
		local beat = math.exp(-beatFrac * 18)
		beat = beat + math.exp(-math.pow(beatFrac - 0.18, 2) * 280) * 0.55
		if mark.Isolated then
			beat = beat + math.exp(-math.pow(beatFrac - 0.32, 2) * 360) * 0.32
		end
		if beat <= 0.04 then continue end

		local pos = getStalkerTargetDrawPos(target)
		if not pos then continue end

		local color = getStalkerPulseColor(target, mark.StunReady)
		local x, y, onScreen = getStalkerScreenPos(pos)
		local senseMul = mark.Isolated and 1.22 or 1
		local size = (ScreenScale(mark.StunReady and 15 or 13) + ScreenScale(onScreen and 5 or 3) * beat) * senseMul
		local alpha = math.min(color.a * math.Clamp(beat, 0, 1) * (onScreen and 1 or 0.72) * (mark.Isolated and 1.18 or 1), 245)

		drawStalkerPulseAt(x, y, color, size, alpha, not onScreen, mark.Isolated)
	end
end)
--

hook.Add("Think", "HMCD_SubRole_Abilities", function()
	if(BeingVictimOfNeckBreakResetTime and BeingVictimOfNeckBreakResetTime <= CurTime())then
		BeingVictimOfNeckBreakResetTime = nil
		LocalPlayer().BeingVictimOfNeckBreak = false
	end
	
	if(LocalPlayer().Ability_NeckBreak)then
		MODE.ContinueBreakingOtherNeck(LocalPlayer())
	end
	
	if(BeingVictimOfDisarmamentResetTime and BeingVictimOfDisarmamentResetTime <= CurTime())then
		BeingVictimOfDisarmamentResetTime = nil
		LocalPlayer().BeingVictimOfDisarmament = false
	end
	
	if(LocalPlayer().Ability_Disarm)then
		MODE.ContinueDisarmingOther(LocalPlayer())
	end
end)
--[[
hook.Add("InputMouseApply", "HMCD_SubRole_Abilities", function(cmd, mouse_x, mouse_y, ang)
	-- if(LocalPlayer().BeingVictimOfNeckBreak)then
		local mouse_speed = 1.1
		local eye_angles = LocalPlayer():EyeAngles()
		
		-- cmd:SetMouseX(math.Clamp(mouse_x, -mouse_speed, mouse_speed))
		-- cmd:SetMouseY(math.Clamp(mouse_y, -mouse_speed, mouse_speed))
		cmd:SetViewAngles(eye_angles)
		
		-- return true
	-- end
end)
]]
hook.Add("hg_AdjustMouseSensitivity", "HMCD_SubRole_Abilities", function(sensitivity)
	if(LocalPlayer().BeingVictimOfNeckBreak)then
		return 0.1
	end
end)

hook.Add("PlayerBindPress", "HMCD_RevenantPassengerCommunication", function(ply, bind)
	if ply ~= LocalPlayer() or not ply:GetNWBool("HMCD_RevenantPassenger", false) then return end
	bind = string.lower(bind or "")
	if string.find(bind, "messagemode", 1, true) or string.find(bind, "+voicerecord", 1, true) then return true end
end)

hook.Add("PostPostHGCalcView", "HMCD_RevenantPassengerView", function(ply, view)
	local passenger = LocalPlayer()
	if ply ~= passenger or not passenger:GetNWBool("HMCD_RevenantPassenger", false) then return end

	local controller = passenger:GetNWEntity("HMCD_RevenantPassengerController", NULL)
	local body = passenger:GetNWEntity("HMCD_RevenantPassengerBody", NULL)
	if not IsValid(body) and IsValid(controller) then body = controller:GetNWEntity("FakeRagdoll", NULL) end
	if not IsValid(body) then return end

	body:SetupBones()
	local target
	local eyes = body:LookupAttachment("eyes")
	local attachment = eyes and eyes > 0 and body:GetAttachment(eyes) or nil
	if attachment then target = attachment.Pos end
	if not target then
		local head = body:LookupBone("ValveBiped.Bip01_Head1")
		local matrix = head and body:GetBoneMatrix(head) or nil
		target = matrix and matrix:GetTranslation() or body:WorldSpaceCenter()
	end

	local angles = IsValid(controller) and controller:EyeAngles() or view.angles
	local desired = target - angles:Forward() * 95 + Vector(0, 0, 14)
	local trace = util.TraceHull({
		start = target,
		endpos = desired,
		mins = Vector(-4, -4, -4),
		maxs = Vector(4, 4, 4),
		filter = {passenger, controller, body},
		mask = MASK_SOLID
	})

	view.origin = trace.StartSolid and target or trace.HitPos
	view.angles = angles
	view.drawviewer = true
	view.znear = 2
	return view
end, -1)

hook.Add("PrePlayerDraw", "HMCD_SubRoles_Abilities", function(ply, flags)
	if ply:GetNWBool("HMCD_RevenantPassenger", false) then return true end

	-- if(ply.Ability_NeckBreak)then
		-- local ability = ply.Ability_NeckBreak
		-- local victim = ability.Victim
		
		-- if(IsValid(victim))then
			-- local ragdoll = victim.FakeRagdoll or victim:GetNWEntity("RagdollDeath", victim.FakeRagdoll)
			
			-- print(ply, ragdoll)
			
			-- if(IsValid(ragdoll))then
				
			-- else
				-- ragdoll = victim
			-- end
			
			-- local bone_id = ragdoll:LookupBone("ValveBiped.Bip01_Head1")
			
			-- if(bone_id)then
				-- local bone_matrix = ragdoll:GetBoneMatrix(bone_id)
				
				-- if(bone_matrix)then
					-- local pos, ang = bone_matrix:GetTranslation(), bone_matrix:GetAngles()
					
					-- hg.DragHandsToPos(ply, ply:GetActiveWeapon(), pos, true, 3.5, ang:Up(), Angle(90,-15,180), Angle(90,15,0))
				-- end
			-- end
		-- end
		
		-- if(!ability.TimeToExpire)then
			-- ability.TimeToExpire = CurTime() + 5
		-- elseif(ability.TimeToExpire <= CurTime())then
			-- ply.Ability_NeckBreak = nil
		-- end
	-- end
end)
