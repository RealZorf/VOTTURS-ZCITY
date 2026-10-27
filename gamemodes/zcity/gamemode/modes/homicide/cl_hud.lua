local MODE = MODE

local TRAITOR_R, TRAITOR_G, TRAITOR_B = 225, 35, 35
local LINK_R, LINK_G, LINK_B = 40, 185, 220
local FRAME_R, FRAME_G, FRAME_B = 86, 94, 90
local color_bezel = Color(12, 13, 13)
local color_panel = Color(20, 22, 21)
local color_text = Color(236, 238, 236)
local color_idle = Color(168, 172, 170)
local color_idle_dim = Color(112, 118, 116)
local color_dead = Color(140, 144, 142)
local color_traitor = Color(TRAITOR_R, TRAITOR_G, TRAITOR_B)
local color_link = Color(LINK_R, LINK_G, LINK_B)

local mat_gradientdown = Material("vgui/gradient_down")
local mat_shadow_camouflage = CreateMaterial("hmcd_shadow_camouflage_refract", "Refract", {
	["$model"] = "1",
	["$translucent"] = "1",
	["$normalmap"] = "effects/strider_pinch_dudv",
	["$dudvmap"] = "effects/strider_pinch_dudv",
	["$refractamount"] = "0.014",
	["$bluramount"] = "0.34",
	["$forcerefract"] = "1",
	["$nocull"] = "1",
})

local function S(n)
	return math.max(1, math.Round(n * ScrH() / 1080))
end

local function CreateFonts()
	surface.CreateFont("ZC_HMCD_Header", {font = "Bahnschrift", size = math.max(16, S(22)), weight = 700, antialias = true, extended = true})
	surface.CreateFont("ZC_HMCD_Body", {font = "Bahnschrift", size = math.max(13, S(17)), weight = 600, antialias = true, extended = true})
	surface.CreateFont("ZC_HMCD_Tiny", {font = "Bahnschrift", size = math.max(11, S(13)), weight = 500, antialias = true, extended = true})
	surface.CreateFont("ZC_HMCD_Timer", {font = "Bahnschrift", size = math.max(18, S(28)), weight = 700, antialias = true, extended = true})
end
CreateFonts()
hook.Add("OnScreenSizeChanged", "HMCD_CRTFonts", CreateFonts)

local function DrawCRTCorners(x, y, w, h, a, ar, ag, ab)
	local thick, len = S(2), S(10)
	surface.SetDrawColor(ar or TRAITOR_R, ag or TRAITOR_G, ab or TRAITOR_B, a * 0.9)
	surface.DrawRect(x, y, len, thick)
	surface.DrawRect(x, y, thick, len)
	surface.DrawRect(x + w - len, y, len, thick)
	surface.DrawRect(x + w - thick, y, thick, len)
	surface.DrawRect(x, y + h - thick, len, thick)
	surface.DrawRect(x, y + h - len, thick, len)
	surface.DrawRect(x + w - len, y + h - thick, len, thick)
	surface.DrawRect(x + w - thick, y + h - len, thick, len)
end

local function DrawCRTFrame(x, y, w, h, a, ar, ag, ab)
	a = a or 255
	local bezel = S(3)
	local stroke = math.max(1, S(1))
	surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, a * 0.90)
	surface.DrawRect(x, y, w, h)
	local ix, iy, iw, ih = x + bezel, y + bezel, w - bezel * 2, h - bezel * 2
	surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, a * 0.78)
	surface.DrawOutlinedRect(ix, iy, iw, ih, stroke)
	DrawCRTCorners(ix, iy, iw, ih, a, ar, ag, ab)
	surface.SetDrawColor(color_panel.r, color_panel.g, color_panel.b, a * 0.82)
	surface.DrawRect(ix + stroke, iy + stroke, iw - stroke * 2, ih - stroke * 2)
	return ix + stroke, iy + stroke, iw - stroke * 2, ih - stroke * 2
end

local function DrawHeaderStrip(x, y, w, h, title, a, ar, ag, ab)
	surface.SetDrawColor(32, 34, 33, a * 0.82)
	surface.DrawRect(x, y, w, h)
	surface.SetDrawColor(ar or TRAITOR_R, ag or TRAITOR_G, ab or TRAITOR_B, a * 0.14)
	surface.DrawRect(x, y, w, h)
	draw.SimpleText(title, "ZC_HMCD_Header", x + w * 0.5, y + h * 0.5, Color(color_text.r, color_text.g, color_text.b, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function DrawPrompt(text, x, y, frac)
	draw.SimpleText(text, "ZC_HMCD_Body", x + 1, y + 1, color_bezel, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	draw.SimpleText(text, "ZC_HMCD_Body", x, y, color_traitor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	surface.SetFont("ZC_HMCD_Body")
	local tw, th = surface.GetTextSize(text)
	if frac and frac > 0 then
		local barH = math.max(S(2), 2)
		surface.SetDrawColor(color_bezel)
		surface.DrawRect(x - tw * 0.5, y + th + S(2), tw, barH)
		surface.SetDrawColor(TRAITOR_R, TRAITOR_G, TRAITOR_B, 230)
		surface.DrawRect(x - tw * 0.5, y + th + S(2), tw * math.Clamp(frac, 0, 1), barH)
		th = th + barH + S(2)
	end
	return th
end

function MODE.GetShadowCamouflageVisuals(ply)
	local tint = MODE.ShadowCamouflageTint or Color(190, 205, 220, MODE.ShadowCamouflageAlpha or 82)
	local modulation = MODE.ShadowCamouflageColorModulation or {0.78, 0.84, 0.94}
	if not IsValid(ply) then
		return {tint = tint, modulation = modulation, blend = MODE.ShadowCamouflageBlend or 0.52, refract = 0.014, blur = 0.34}
	end

	local now = CurTime()
	local viewer = LocalPlayer()
	local distanceFrac = 0.25
	if IsValid(viewer) and viewer ~= ply then
		distanceFrac = math.Clamp(1 - (viewer:GetShootPos():Distance(ply:WorldSpaceCenter()) / 360), 0, 1)
	end

	local speedFrac = math.Clamp(ply:GetVelocity():Length2D() / math.max(MODE.ShadowCamouflageMoveSpeed or 28, 1), 0, 1)
	local shimmer = 0.5 + math.sin(now * 5.5 + ply:EntIndex() * 0.73) * 0.5
	return {
		tint = tint,
		modulation = modulation,
		blend = math.Clamp((MODE.ShadowCamouflageBlend or 0.52) + distanceFrac * 0.08 + speedFrac * 0.04 + shimmer * 0.015, 0.44, 0.68),
		refract = math.Clamp(0.012 + distanceFrac * 0.006 + speedFrac * 0.006 + shimmer * 0.002, 0.01, 0.026),
		blur = math.Clamp(0.26 + distanceFrac * 0.12 + speedFrac * 0.08, 0.22, 0.5)
	}
end

hook.Add("PrePlayerDraw", "HMCD_ShadowCamouflage_PrePlayerDraw", function(ply)
	if not MODE.IsShadowRole or not MODE.IsShadowRole(ply.SubRole) then return end
	if not ply:GetNWBool("HMCD_ShadowCamouflageActive") then return end

	local now = CurTime()
	if (ply.HMCD_ShadowCamouflageNextDecalClear or 0) <= now then
		ply.HMCD_ShadowCamouflageNextDecalClear = now + 0.2
		if ply.RemoveAllDecals then ply:RemoveAllDecals() end
		local char = hg and hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply)
		if IsValid(char) and char ~= ply and char.RemoveAllDecals then
			char:RemoveAllDecals()
		end
	end

	local visuals = MODE.GetShadowCamouflageVisuals(ply)
	local tint = visuals.tint
	local modulation = visuals.modulation
	if render.UpdateRefractTexture then render.UpdateRefractTexture() end
	mat_shadow_camouflage:SetFloat("$refractamount", visuals.refract)
	mat_shadow_camouflage:SetFloat("$bluramount", visuals.blur)
	render.MaterialOverride(mat_shadow_camouflage)
	render.SetBlend(visuals.blend)
	render.SetColorModulation((modulation[1] or 0.78) * (tint.r / 255), (modulation[2] or 0.84) * (tint.g / 255), (modulation[3] or 0.94) * (tint.b / 255))
end)

hook.Add("PostPlayerDraw", "HMCD_ShadowCamouflage_PostPlayerDraw", function(ply)
	if not MODE.IsShadowRole or not MODE.IsShadowRole(ply.SubRole) then return end
	if not ply:GetNWBool("HMCD_ShadowCamouflageActive") then return end
	render.MaterialOverride(nil)
	render.SuppressEngineLighting(false)
	render.SetBlend(1)
	render.SetColorModulation(1, 1, 1)
	render.ResetModelLighting(1, 1, 1)
end)

hook.Add("HUDPaint", "HMCD_SubRoles_Abilities", function()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() or not ply.isTraitor then return end

	local aim_ent, other_ply, trace = MODE.GetPlayerTraceToOther(ply)
	local special_bind = hg.GetKeybindDisplay and hg.GetKeybindDisplay("special_interaction", "LALT + E") or "LALT + E"
	local y_offset = 30 + ScreenScale(15)
	local gap = S(5)

	if ply.SubRole == "traitor_infiltrator" or ply.SubRole == "traitor_infiltrator_soe" then
		local action = MODE.GetNeckBreakAction and MODE.GetNeckBreakAction(ply) or "neck_break"
		local text = action == "saw_head" and "(HOLD)[" .. special_bind .. "] Saw Off Head" or "(HOLD)[" .. special_bind .. "] Break Neck"
		local can_ability = false
		if action == "saw_head" then
			local wep = MODE.GetActiveFiberwire and MODE.GetActiveFiberwire(ply)
			can_ability = IsValid(wep) and wep.GetStrangling and wep:GetStrangling()
		elseif IsValid(aim_ent) and other_ply then
			can_ability = MODE.CanPlayerBreakOtherNeck(ply, aim_ent)
		end

		if can_ability or ply.Ability_NeckBreak then
			local pos = (trace and trace.HitPos or (ply:GetShootPos() + ply:GetAimVector() * 60)):ToScreen()
			local frac = ply.Ability_NeckBreak and (ply.Ability_NeckBreak.Progress / 100) or 0
			y_offset = y_offset + DrawPrompt(text, pos.x, pos.y + y_offset, frac) + gap
		end

		if IsValid(aim_ent) and aim_ent:IsRagdoll() and trace then
			local pos = trace.HitPos:ToScreen()
			y_offset = y_offset + DrawPrompt("[ALT + R] Exchange Appearances", pos.x, pos.y + y_offset) + gap
		end
	end

	if MODE.IsCannibalRole and MODE.IsCannibalRole(ply.SubRole) then
		local active_corpse = ply:GetNWEntity("HMCD_CannibalConsumeCorpse")
		local corpse, _, consume_trace = MODE.GetCannibalConsumeTarget and MODE.GetCannibalConsumeTarget(ply)
		local draw_corpse = IsValid(active_corpse) and active_corpse or corpse
		if IsValid(draw_corpse) then
			local stacks = ply:GetNWInt("HMCD_CannibalStacks", 0)
			local text = "(HOLD)[" .. special_bind .. "] Consume Body"
			if stacks > 0 then
				text = text .. " [" .. stacks .. "/" .. (MODE.CannibalMaxConsumedBodies or 6) .. "]"
			end
			local pos = (consume_trace and consume_trace.HitPos or draw_corpse:WorldSpaceCenter()):ToScreen()
			y_offset = y_offset + DrawPrompt(text, pos.x, pos.y + y_offset, MODE.GetCannibalConsumeProgress and MODE.GetCannibalConsumeProgress(ply) or 0) + gap
		end
	end

	if MODE.IsRevenantRole and MODE.IsRevenantRole(ply.SubRole) then
		if ply:GetNWBool("HMCD_RevenantPossessing", false) then
			if CurTime() >= (ply.HMCD_RevenantBootUntil or 0) then
				local remaining = math.max(0, ply:GetNWFloat("HMCD_RevenantEndsAt", 0) - CurTime())
				local visibleDuration = math.max(1, (MODE.RevenantPossessionTime or 32) - (MODE.RevenantBootDuration or 2))
				local fraction = math.Clamp(remaining / visibleDuration, 0, 1)
				local w, h = S(320), S(64)
				local x, y = (ScrW() - w) * 0.5, ScrH() * 0.84
				local a = 255
				local ix, iy, iw, ih = DrawCRTFrame(x, y, w, h, a, LINK_R, LINK_G, LINK_B)
				DrawHeaderStrip(ix + S(4), iy + S(4), iw - S(8), S(22), "NEURAL LINK", a, LINK_R, LINK_G, LINK_B)
				draw.SimpleText("ANCHOR AT RISK", "ZC_HMCD_Tiny", ix + S(8), iy + ih - S(16), color_idle, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				draw.SimpleText(string.format("%02d:%02d", math.floor(remaining / 60), math.floor(remaining % 60)), "ZC_HMCD_Timer", ix + iw - S(8), iy + S(34), color_link, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
				local barW = iw - S(16)
				surface.SetDrawColor(color_bezel)
				surface.DrawRect(ix + S(8), iy + ih - S(8), barW, S(2))
				surface.SetDrawColor(LINK_R, LINK_G, LINK_B, 255)
				surface.DrawRect(ix + S(8), iy + ih - S(8), barW * fraction, S(2))
			end
		else
			local active = ply:GetNWEntity("HMCD_RevenantImplantCorpse")
			local corpse, rtrace = MODE.GetRevenantCorpseTarget(ply)
			local draw_ent = IsValid(active) and active or corpse
			if IsValid(draw_ent) then
				local charges = ply:GetNWInt("HMCD_RevenantCharges", 0)
				local text = "(HOLD)[" .. special_bind .. "] Implant Neural Chip [" .. charges .. "/" .. (MODE.RevenantCharges or 3) .. "]"
				local pos = (rtrace and rtrace.HitPos or draw_ent:WorldSpaceCenter()):ToScreen()
				y_offset = y_offset + DrawPrompt(text, pos.x, pos.y + y_offset, MODE.GetRevenantImplantProgress(ply)) + gap
			end
		end
	end

	if MODE.IsJuggernautRole and MODE.IsJuggernautRole(ply.SubRole) then
		local can_strangle, carried = MODE.CanJuggernautStrangle and MODE.CanJuggernautStrangle(ply)
		local active_victim = ply:GetNWEntity("HMCD_JuggernautStrangleVictim")
		if can_strangle or IsValid(active_victim) then
			local draw_ent = IsValid(carried) and carried or active_victim
			local pos = (IsValid(draw_ent) and draw_ent:WorldSpaceCenter() or (ply:GetShootPos() + ply:GetAimVector() * 60)):ToScreen()
			y_offset = y_offset + DrawPrompt("(HOLD)[ALT] Strangle", pos.x, pos.y + y_offset, MODE.GetJuggernautStrangleProgress and MODE.GetJuggernautStrangleProgress(ply) or 0) + gap
		end
		if not can_strangle and MODE.GetJuggernautStompTarget then
			local rag, stomp_victim, stomp_trace = MODE.GetJuggernautStompTarget(ply)
			if IsValid(rag) and IsValid(stomp_victim) then
				local pos = (stomp_trace and stomp_trace.HitPos or rag:WorldSpaceCenter()):ToScreen()
				y_offset = y_offset + DrawPrompt("[" .. special_bind .. "] Stomp Skull", pos.x, pos.y + y_offset) + gap
			end
		end
	end

	if (MODE.IsAssassinRole and MODE.IsAssassinRole(ply.SubRole)) or ply.PlayerClassName == "sc_infiltrator" then
		local aent, aother, atrace = MODE.GetPlayerTraceToOther(ply, nil, MODE.DisarmReach)
		if ((IsValid(aent) and aother and MODE.CanPlayerDisarmOtherPly(ply, aother, MODE.DisarmReach) and MODE.CanPlayerDisarmOther(ply, aent, MODE.DisarmReach)) or ply.Ability_Disarm) and atrace then
			local pos = atrace.HitPos:ToScreen()
			local frac = ply.Ability_Disarm and (ply.Ability_Disarm.Progress / 100) or 0
			y_offset = y_offset + DrawPrompt("(HOLD)[" .. special_bind .. "] Disarm", pos.x, pos.y + y_offset, frac) + gap
		end
	end

	if MODE.IsChemistRole and MODE.IsChemistRole(ply.SubRole) then
		local neutralizer_target, _, neutralizer_trace = MODE.GetChemistNeutralizerTarget(ply)
		local doses = ply:GetNWInt("HMCD_ChemistNeutralizerDoses", 0)
		if IsValid(neutralizer_target) and neutralizer_trace and doses > 0 then
			local pos = neutralizer_trace.HitPos:ToScreen()
			y_offset = y_offset + DrawPrompt("(PRESS)[" .. special_bind .. "] Neutralize teammate [" .. doses .. "]", pos.x, pos.y + y_offset) + gap
		end

		local barW, barH = S(22), S(88)
		local barX = ScrW() - S(8)
		local barY = (ScrH() - barH) * 0.5
		ply.PassiveAbility_ChemicalAccumulation = ply.PassiveAbility_ChemicalAccumulation or {}
		ply.PassiveAbility_VGUI_ChemicalAccumulation = ply.PassiveAbility_VGUI_ChemicalAccumulation or {}
		for chemical_name, amt in pairs(ply.PassiveAbility_ChemicalAccumulation) do
			local shown = Lerp(FrameTime() * 3, ply.PassiveAbility_VGUI_ChemicalAccumulation[chemical_name] or 0, amt)
			ply.PassiveAbility_VGUI_ChemicalAccumulation[chemical_name] = shown
			if shown > 0.1 then
				barX = barX - barW
				DrawCRTFrame(barX, barY, barW, barH, 255)
				local frac = math.min(shown / 100, 1)
				local inner = S(4)
				local fillH = (barH - inner * 2) * frac
				surface.SetDrawColor(TRAITOR_R, TRAITOR_G, TRAITOR_B, 200)
				surface.DrawRect(barX + inner, barY + barH - inner - fillH, barW - inner * 2, fillH)
				render.SetScissorRect(barX + inner, barY + barH - inner - fillH, barX + barW - inner, barY + barH - inner, true)
				surface.SetDrawColor(TRAITOR_R, 10, 10, 160)
				surface.SetMaterial(mat_gradientdown)
				surface.DrawTexturedRect(barX + inner, barY + inner, barW - inner * 2, barH - inner * 2)
				render.SetScissorRect(0, 0, 0, 0, false)

				render.PushFilterMag(TEXFILTER.ANISOTROPIC)
				render.PushFilterMin(TEXFILTER.ANISOTROPIC)
				local m = Matrix()
				m:Translate(Vector(barX + barW * 0.5, barY + barH * 0.5, 0))
				m:Rotate(Angle(0, 90, 0))
				surface.SetFont("ZC_HMCD_Tiny")
				local tw, th = surface.GetTextSize(chemical_name)
				m:Translate(Vector(-tw * 0.5, -th * 0.5, 0))
				cam.PushModelMatrix(m, true)
				draw.DrawText(chemical_name, "ZC_HMCD_Tiny", 0, 0, color_text)
				cam.PopModelMatrix()
				render.PopFilterMin()
				render.PopFilterMag()
				barX = barX - S(6)
			end
		end
	end

	if MODE.IsShadowRole and MODE.IsShadowRole(ply.SubRole) then
		local active = ply:GetNWBool("HMCD_ShadowCamouflageActive")
		local charge_start = ply:GetNWFloat("HMCD_ShadowCamouflageChargeStart", 0)
		local ready_at = ply:GetNWFloat("HMCD_ShadowCamouflageReadyAt", 0)
		if active or charge_start > 0 then
			local ready = not active and ready_at > 0 and CurTime() >= ready_at
			local text = active and "CAMOUFLAGED [R] Cancel" or (ready and "[R] Camouflage" or "Stand still by a wall to ready camouflage")
			local frac
			if not active and ready_at > charge_start then
				frac = math.Clamp(1 - ((ready_at - CurTime()) / MODE.ShadowCamouflageChargeTime), 0, 1)
			end
			DrawPrompt(text, ScrW() * 0.5, ScrH() * 0.68 + y_offset, frac)
		end
	end
end)

local panel = {
	visible = true,
	slide = 0,
	lastToggle = 0,
	nextStatus = 0,
	dead = {},
}

net.Receive("HMCD_UpdateTraitorAssistants", function()
	MODE.TraitorsLocal = {}
	for i = 1, net.ReadUInt(8) do
		MODE.TraitorsLocal[i] = {net.ReadColor(), net.ReadString(), net.ReadString(), net.ReadString()}
	end
end)

net.Receive("HMCD_TraitorDeathState", function()
	local name = net.ReadString()
	local dead = not net.ReadBool()
	if name ~= "" then
		panel.dead[name] = dead
	end
end)

hook.Add("PlayerButtonDown", "TraitorPanelToggle", function(ply, btn)
	if btn ~= KEY_F4 or ply ~= LocalPlayer() or not ply.isTraitor then return end
	if not IsFirstTimePredicted() then return end
	if CurTime() - panel.lastToggle < 0.2 then return end
	panel.lastToggle = CurTime()
	panel.visible = not panel.visible
	if panel.visible then
		surface.PlaySound("shitty/tap_depress.wav")
		panel.nextStatus = 0
	else
		surface.PlaySound("shitty/tap_release.wav")
	end
end)

hook.Add("PostPlayerDeath", "ClearTraitorPanel", function(ply)
	if ply ~= LocalPlayer() then return end
	panel.visible = false
	panel.slide = 0
	panel.dead = {}
end)

hook.Add("HUDPaint", "DrawTraitorPanel", function()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply.isTraitor or not ply:Alive() then
		panel.visible = false
		return
	end

	local isMain = ply.MainTraitor
	local rows = {}
	if isMain then
		MODE.TraitorsLocal = MODE.TraitorsLocal or {}
		local steam = ply.SteamID and ply:SteamID() or ""
		local aname = ply.CurAppearance and ply.CurAppearance.AName
		for _, info in ipairs(MODE.TraitorsLocal) do
			if not info or not info[2] or info[2] == "" then continue end
			if (info[3] ~= "" and info[3] == steam) or info[2] == aname then continue end
			local sub = info[4] or ""
			rows[#rows + 1] = {
				name = info[2],
				role = (MODE.SubRoles and MODE.SubRoles[sub] and MODE.SubRoles[sub].Name) or "Traitor",
				dead = panel.dead[info[2]] == true
			}
		end
		if panel.visible and CurTime() >= panel.nextStatus then
			panel.nextStatus = CurTime() + 5
			net.Start("HMCD_RequestTraitorStatuses")
			net.SendToServer()
		end
	end

	local bezel, pad, headerH, rowH = S(3), S(4), S(24), S(22)
	local w = S(307)
	local innerW = w - (bezel + pad) * 2
	local bodyH = pad + S(14) + rowH * 2 + S(10)
	if isMain then
		bodyH = bodyH + S(18) + math.max(#rows, 1) * (rowH + S(4))
	end
	local h = bezel * 2 + pad + headerH + pad + bodyH + pad + S(16)
	local target = panel.visible and 0 or (w + S(40))
	panel.slide = Lerp(FrameTime() * 10, panel.slide, target)
	if panel.slide > w + S(32) then return end

	local a = 255
	local x = ScrW() - w - S(23) + panel.slide
	local y = ScrH() * 0.5 - h * 0.5
	local ix, iy, iw = DrawCRTFrame(x, y, w, h, a)
	local innerX, innerY = ix + pad, iy + pad
	DrawHeaderStrip(innerX, innerY, innerW, headerH, isMain and "MAIN TRAITOR" or "TRAITOR'S ASSISTANT", a)
	draw.SimpleText("F4 TO TOGGLE", "ZC_HMCD_Tiny", x + w * 0.5, innerY + headerH + S(2), color_idle_dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

	local wordY = innerY + headerH + pad + S(16)
	draw.SimpleText("SECRET WORDS", "ZC_HMCD_Tiny", x + w * 0.5, wordY, color_idle, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	wordY = wordY + S(16)
	local wordW = innerW - S(16)
	local wordX = innerX + S(8)
	for _, word in ipairs({MODE.TraitorWord or "???", MODE.TraitorWordSecond or "???"}) do
		surface.SetDrawColor(32, 34, 33, 200)
		surface.DrawRect(wordX, wordY, wordW, rowH)
		surface.SetDrawColor(TRAITOR_R, TRAITOR_G, TRAITOR_B, 160)
		surface.DrawOutlinedRect(wordX, wordY, wordW, rowH, 1)
		draw.SimpleText(word, "ZC_HMCD_Body", wordX + wordW * 0.5, wordY + rowH * 0.5, color_traitor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		wordY = wordY + rowH + S(4)
	end

	if not isMain then return end

	wordY = wordY + S(8)
	draw.SimpleText("ASSISTANTS", "ZC_HMCD_Tiny", x + w * 0.5, wordY, color_idle, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	wordY = wordY + S(16)

	if #rows == 0 then
		draw.SimpleText("None", "ZC_HMCD_Body", x + w * 0.5, wordY + S(4), color_idle_dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		return
	end

	for _, row in ipairs(rows) do
		surface.SetDrawColor(32, 34, 33, 180)
		surface.DrawRect(wordX, wordY, wordW, rowH)
		surface.SetDrawColor(row.dead and FRAME_R or TRAITOR_R, row.dead and FRAME_G or TRAITOR_G, row.dead and FRAME_B or TRAITOR_B, 140)
		surface.DrawRect(wordX, wordY, S(2), rowH)
		local nameCol = row.dead and color_dead or color_text
		draw.SimpleText(row.name, "ZC_HMCD_Body", wordX + S(8), wordY + rowH * 0.5, nameCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(row.dead and "DEAD" or string.upper(row.role), "ZC_HMCD_Tiny", wordX + wordW - S(8), wordY + rowH * 0.5, row.dead and color_dead or color_traitor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		wordY = wordY + rowH + S(4)
		if wordY > y + h - S(20) then break end
	end
end)

hook.Add("HUDPaint", "HMCD_ManiacRampage", function()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() or not ply:GetNWBool("HMCD_ManiacFuryActive", false) then return end

	local maxStacks = MODE.ManiacRampageMaxStacks or 5
	local stacks = math.Clamp(ply:GetNWInt("HMCD_ManiacRampageStacks", 0), 0, maxStacks)
	local segW, segH, gap = S(18), S(8), S(3)
	local totalW = segW * maxStacks + gap * (maxStacks - 1)
	local x = math.floor((ScrW() - totalW) * 0.5)
	local y = math.floor(ScrH() * 0.78)
	local decay = math.Clamp((ply:GetNWFloat("HMCD_ManiacRampageNextDecay", 0) - CurTime()) / (MODE.ManiacRampageDuration or 15), 0, 1)

	draw.SimpleText("RAMPAGE", "ZC_HMCD_Tiny", ScrW() * 0.5, y - S(12), color_traitor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	for i = 1, maxStacks do
		local sx = x + (i - 1) * (segW + gap)
		surface.SetDrawColor(color_bezel)
		surface.DrawRect(sx, y, segW, segH)
		surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, 140)
		surface.DrawOutlinedRect(sx, y, segW, segH, 1)
		if i <= stacks then
			surface.SetDrawColor(TRAITOR_R, TRAITOR_G, TRAITOR_B, i == 1 and (80 + 150 * math.max(decay, 0.35)) or 230)
			surface.DrawRect(sx + 1, y + 1, segW - 2, segH - 2)
		end
	end
end)
