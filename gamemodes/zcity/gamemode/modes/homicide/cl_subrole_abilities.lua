local MODE = MODE

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
--//

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
--//

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
--//

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

net.Receive("HMCD_StalkerMarks", function()
	stalkerMarks.List = {}
	local count = net.ReadUInt(2)

	for i = 1, count do
		stalkerMarks.List[i] = {
			Target = net.ReadEntity(),
			StunReady = net.ReadBool()
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
		if beat <= 0.04 then continue end

		local pos = getStalkerTargetDrawPos(target)
		if not pos then continue end

		local scr = pos:ToScreen()
		if not scr.visible then continue end

		local color = getStalkerPulseColor(target, mark.StunReady)
		local size = ScreenScale(mark.StunReady and 15 or 13) + ScreenScale(5) * beat
		local alpha = color.a * math.Clamp(beat, 0, 1)

		surface.SetMaterial(matStalkerGlow)
		surface.SetDrawColor(color.r, color.g, color.b, alpha)
		surface.DrawTexturedRect(scr.x - size, scr.y - size, size * 2, size * 2)
	end
end)
--//

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

hook.Add("PrePlayerDraw", "HMCD_SubRoles_Abilities", function(ply, flags)
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
