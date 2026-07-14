local MODE = MODE
local vgui_color_main = Color(150, 80, 0, 255)
local vgui_color_warning = Color(150, 0, 0, 255)
local vgui_color_bg = Color(50, 50, 50, 255)
local vgui_color_ready = Color(0, 150, 50, 255)
local vgui_color_notready = Color(0, 50, 0, 255)
local vgui_color_text_main = Color(150, 50, 0, 255)
local vgui_color_text_shadow = Color(0, 0, 0, 255)

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
local color_white = Color(255, 255, 255, 255)

local function draw_shadow_text(text, cx, cy)
	draw.DrawText(text, "HomigradFontMedium", cx + 1, cy + 1, vgui_color_text_shadow, TEXT_ALIGN_CENTER)
	draw.DrawText(text, "HomigradFontMedium", cx, cy, vgui_color_text_main, TEXT_ALIGN_CENTER)
end

local vector_one = Vector(1, 1, 1)

local function draw_RotatedText(text, font, x, y, color, ang, scale)
	render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	render.PushFilterMin(TEXFILTER.ANISOTROPIC)

	local m = Matrix()
	
	m:Translate(Vector(x, y, 0))
	m:Rotate(Angle(0, ang, 0))
	m:Scale(vector_one * (scale or 1))

	surface.SetFont(font)
	
	local w, h = surface.GetTextSize(text)

	m:Translate(Vector(-w / 2, -h / 2, 0))

	cam.PushModelMatrix(m, true)
		draw.DrawText(text, font, 0, 0, color)
	cam.PopModelMatrix()

	render.PopFilterMag()
	render.PopFilterMin()
end

function MODE.GetShadowCamouflageVisuals(ply)
	if not IsValid(ply) then
		return {
			tint = MODE.ShadowCamouflageTint or color_white,
			modulation = MODE.ShadowCamouflageColorModulation or {0.78, 0.84, 0.94},
			blend = MODE.ShadowCamouflageBlend or 0.52,
			refract = 0.014,
			blur = 0.34
		}
	end

	local now = CurTime()
	local cache = ply.HMCD_ShadowCamouflageVisualCache
	if cache and cache.expires > now then
		return cache
	end

	local viewer = LocalPlayer()
	local distanceFrac = 0.25
	if IsValid(viewer) and viewer ~= ply then
		distanceFrac = math.Clamp(1 - (viewer:GetShootPos():Distance(ply:WorldSpaceCenter()) / 360), 0, 1)
	end

	local moveSpeed = MODE.ShadowCamouflageMoveSpeed or 28
	local speedFrac = math.Clamp(ply:GetVelocity():Length2D() / math.max(moveSpeed, 1), 0, 1)
	local shimmer = 0.5 + math.sin(now * 5.5 + ply:EntIndex() * 0.73) * 0.5
	local tint = MODE.ShadowCamouflageTint or Color(190, 205, 220, MODE.ShadowCamouflageAlpha or 82)
	local modulation = MODE.ShadowCamouflageColorModulation or {0.78, 0.84, 0.94}
	local blend = math.Clamp((MODE.ShadowCamouflageBlend or 0.52) + distanceFrac * 0.08 + speedFrac * 0.04 + shimmer * 0.015, 0.44, 0.68)
	local refract = math.Clamp(0.012 + distanceFrac * 0.006 + speedFrac * 0.006 + shimmer * 0.002, 0.01, 0.026)
	local blur = math.Clamp(0.26 + distanceFrac * 0.12 + speedFrac * 0.08, 0.22, 0.5)

	cache = {
		tint = tint,
		modulation = modulation,
		blend = blend,
		refract = refract,
		blur = blur,
		expires = now + 0.08
	}

	ply.HMCD_ShadowCamouflageVisualCache = cache

	return cache
end

local function applyShadowCamouflageRenderState(visuals)
	local tint = visuals.tint or color_white
	local modulation = visuals.modulation or {0.78, 0.84, 0.94}

	if render.UpdateRefractTexture then
		render.UpdateRefractTexture()
	end

	mat_shadow_camouflage:SetFloat("$refractamount", visuals.refract or 0.014)
	mat_shadow_camouflage:SetFloat("$bluramount", visuals.blur or 0.34)

	render.MaterialOverride(mat_shadow_camouflage)
	render.SetBlend(visuals.blend or 0.52)
	render.SetColorModulation((modulation[1] or 0.78) * (tint.r / 255), (modulation[2] or 0.84) * (tint.g / 255), (modulation[3] or 0.94) * (tint.b / 255))
end

local function clearShadowCamouflageDecals(ply)
	if not IsValid(ply) then return end

	local now = CurTime()
	if (ply.HMCD_ShadowCamouflageNextDecalClear or 0) > now then return end
	ply.HMCD_ShadowCamouflageNextDecalClear = now + 0.2

	if ply.RemoveAllDecals then
		ply:RemoveAllDecals()
	end

	local char = hg and hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply) or nil
	if IsValid(char) and char ~= ply and char.RemoveAllDecals then
		char:RemoveAllDecals()
	end
end

hook.Add("PrePlayerDraw", "HMCD_ShadowCamouflage_PrePlayerDraw", function(ply)
	if not MODE.IsShadowRole or not MODE.IsShadowRole(ply.SubRole) then return end
	if not ply:GetNWBool("HMCD_ShadowCamouflageActive") then return end

	clearShadowCamouflageDecals(ply)
	applyShadowCamouflageRenderState(MODE.GetShadowCamouflageVisuals(ply))
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
	local aim_ent, other_ply, trace = MODE.GetPlayerTraceToOther(ply)
	local after_text_offset = 5
	local y_offset = 30
	y_offset = y_offset + ScreenScale(15)
	
	surface.SetFont("HomigradFontMedium")
	
	if(ply:Alive())then
		if(ply.isTraitor)then
			if(ply.SubRole == "traitor_infiltrator" or ply.SubRole == "traitor_infiltrator_soe")then
				local action = MODE.GetNeckBreakAction and MODE.GetNeckBreakAction(ply) or "neck_break"
				local text = action == "saw_head" and "(HOLD)[ALT + E] Saw Off Head" or "(HOLD)[ALT + E] Break Neck"
				local tw, th = surface.GetTextSize(text)
				local text_pos = trace and trace.HitPos or (ply:GetShootPos() + ply:GetAimVector() * 60)
				local screen_pos = text_pos:ToScreen()
				local cx, cy = screen_pos.x, screen_pos.y
				cy = cy + y_offset
				
				local saw_prompt_active = false
				if(action == "saw_head")then
					local wep = MODE.GetActiveFiberwire and MODE.GetActiveFiberwire(ply)
					saw_prompt_active = IsValid(wep) and wep.GetStrangling and wep:GetStrangling()
				end

				local can_ability = false
				if(action == "saw_head")then
					can_ability = saw_prompt_active
				elseif(IsValid(aim_ent) and other_ply)then
					can_ability = MODE.CanPlayerBreakOtherNeck(ply, aim_ent)
				end

				if(can_ability or ply.Ability_NeckBreak)then
					draw_shadow_text(text, cx, cy)
					
					if(ply.Ability_NeckBreak)then
						local frac = ply.Ability_NeckBreak.Progress / 100
						
						surface.SetDrawColor(vgui_color_text_main)
						surface.DrawRect(cx - tw / 2, cy, tw * frac, th)
					end
				
					y_offset = y_offset + th + after_text_offset
				end
				
				if(IsValid(aim_ent))then
					if(aim_ent:IsRagdoll())then
						local text = "[ALT + R] Exchange Appearances"
						local tw, th = surface.GetTextSize(text)
						local cx, cy = trace.HitPos:ToScreen().x, trace.HitPos:ToScreen().y
						
						draw_shadow_text(text, cx, cy + y_offset)
						
						y_offset = y_offset + th + after_text_offset
					end
				end
			end
			
			if(MODE.IsCannibalRole and MODE.IsCannibalRole(ply.SubRole))then
				local active_corpse = ply:GetNWEntity("HMCD_CannibalConsumeCorpse")
				local corpse, victim, consume_trace = MODE.GetCannibalConsumeTarget and MODE.GetCannibalConsumeTarget(ply)
				local draw_corpse = IsValid(active_corpse) and active_corpse or corpse

				if(IsValid(draw_corpse))then
					local text = "(HOLD)[ALT + E] Consume Body"
					local stacks = ply:GetNWInt("HMCD_CannibalStacks", 0)
					if stacks > 0 then
						text = text .. " [" .. stacks .. "/" .. (MODE.CannibalMaxConsumedBodies or 6) .. "]"
					end

					local tw, th = surface.GetTextSize(text)
					local text_pos = consume_trace and consume_trace.HitPos or draw_corpse:WorldSpaceCenter()
					local screen_pos = text_pos:ToScreen()
					local cx, cy = screen_pos.x, screen_pos.y + y_offset

					draw_shadow_text(text, cx, cy)

					local frac = MODE.GetCannibalConsumeProgress and MODE.GetCannibalConsumeProgress(ply) or 0
					if(frac > 0)then
						surface.SetDrawColor(vgui_color_text_main)
						surface.DrawRect(cx - tw / 2, cy + th, tw * frac, math.max(ScreenScale(1), 2))
					end

					y_offset = y_offset + th + after_text_offset
				end
			end

			if(MODE.IsJuggernautRole and MODE.IsJuggernautRole(ply.SubRole))then
				local can_strangle, carried, victim = MODE.CanJuggernautStrangle and MODE.CanJuggernautStrangle(ply)
				local active_victim = ply:GetNWEntity("HMCD_JuggernautStrangleVictim")

				if(can_strangle or IsValid(active_victim))then
					local draw_ent = IsValid(carried) and carried or active_victim
					local text = "(HOLD)[ALT] Strangle"
					local tw, th = surface.GetTextSize(text)
					local text_pos = IsValid(draw_ent) and draw_ent:WorldSpaceCenter() or (ply:GetShootPos() + ply:GetAimVector() * 60)
					local screen_pos = text_pos:ToScreen()
					local cx, cy = screen_pos.x, screen_pos.y + y_offset

					draw_shadow_text(text, cx, cy)

					local frac = MODE.GetJuggernautStrangleProgress and MODE.GetJuggernautStrangleProgress(ply) or 0
					if(frac > 0)then
						surface.SetDrawColor(vgui_color_text_main)
						surface.DrawRect(cx - tw / 2, cy + th, tw * frac, math.max(ScreenScale(1), 2))
					end

					y_offset = y_offset + th + after_text_offset
				end

				if(not can_strangle and MODE.GetJuggernautStompTarget)then
					local rag, stomp_victim, stomp_trace = MODE.GetJuggernautStompTarget(ply)
					if(IsValid(rag) and IsValid(stomp_victim))then
						local text = "[ALT + E] Stomp Skull"
						local tw, th = surface.GetTextSize(text)
						local text_pos = stomp_trace and stomp_trace.HitPos or rag:WorldSpaceCenter()
						local screen_pos = text_pos:ToScreen()
						local cx, cy = screen_pos.x, screen_pos.y + y_offset

						draw_shadow_text(text, cx, cy)

						y_offset = y_offset + th + after_text_offset
					end
				end
			end

			if((MODE.IsAssassinRole and MODE.IsAssassinRole(ply.SubRole)) or ply.PlayerClassName == "sc_infiltrator")then
				local aim_ent, other_ply, trace = MODE.GetPlayerTraceToOther(ply, nil, MODE.DisarmReach)
				local text = "(HOLD)[ALT + E] Disarm"
				local tw, th = surface.GetTextSize(text)
				local cx, cy = trace.HitPos:ToScreen().x, trace.HitPos:ToScreen().y
				cy = cy + y_offset
				
				if((IsValid(aim_ent) and other_ply and MODE.CanPlayerDisarmOtherPly(ply, other_ply, MODE.DisarmReach) and MODE.CanPlayerDisarmOther(ply, aim_ent, MODE.DisarmReach)) or ply.Ability_Disarm)then
					draw_shadow_text(text, cx, cy)
					
					if(ply.Ability_Disarm)then
						local frac = ply.Ability_Disarm.Progress / 100
						
						surface.SetDrawColor(vgui_color_text_main)
						surface.DrawRect(cx - tw / 2, cy, tw * frac, th)
					end
					
					y_offset = y_offset + th + after_text_offset
				end
			end
			
			if(MODE.IsChemistRole and MODE.IsChemistRole(ply.SubRole))then
				local after_side_bar_offset = 5
				local bar_border = 5
				local bar_width = ScreenScale(20)
				local bar_height = ScreenScale(80)
				local bar_y = (ScrH() - bar_height) / 2
				local bar_x = ScrW() - after_side_bar_offset
				ply.PassiveAbility_ChemicalAccumulation = ply.PassiveAbility_ChemicalAccumulation or {}
				ply.PassiveAbility_VGUI_ChemicalAccumulation = ply.PassiveAbility_VGUI_ChemicalAccumulation or {}
				
				for chemical_name, amt in pairs(ply.PassiveAbility_ChemicalAccumulation) do
					ply.PassiveAbility_VGUI_ChemicalAccumulation[chemical_name] = ply.PassiveAbility_VGUI_ChemicalAccumulation[chemical_name] or 0
					ply.PassiveAbility_VGUI_ChemicalAccumulation[chemical_name] = Lerp(FrameTime() * 3, ply.PassiveAbility_VGUI_ChemicalAccumulation[chemical_name], amt)
					if(ply.PassiveAbility_VGUI_ChemicalAccumulation[chemical_name] > 0.1)then
						surface.SetDrawColor(vgui_color_bg)
						surface.DrawRect(bar_x - bar_width, bar_y, bar_width, bar_height)
						
						local frac = math.min(ply.PassiveAbility_VGUI_ChemicalAccumulation[chemical_name] / 100, 1)
						local y_end = bar_y + bar_border + bar_height - bar_border * 2
						local y_start = y_end - ((bar_height - bar_border * 2) * frac)
						local height = y_end - y_start
						
						surface.SetDrawColor(vgui_color_main)
						surface.DrawRect(bar_x - bar_width + bar_border, y_start, bar_width - bar_border * 2, height)
						
						render.SetScissorRect(bar_x - bar_width + bar_border, y_start, bar_x - bar_border, y_start + height, true)
							surface.SetDrawColor(vgui_color_warning)
							surface.SetMaterial(mat_gradientdown)
							surface.DrawTexturedRect(bar_x - bar_width + bar_border, bar_y + bar_border, bar_width - bar_border * 2, bar_height - bar_border * 2)
						render.SetScissorRect(0, 0, 0, 0, false)
						
						local tcx, tcy = bar_x - bar_width / 2, bar_y + bar_height / 2
						
						draw_RotatedText(chemical_name, "HomigradFontMedium", tcx, tcy, vgui_color_text_shadow, 90, 1)
						
						bar_x = bar_x - bar_width - after_side_bar_offset
					end
				end
			end

			if(MODE.IsShadowRole(ply.SubRole))then
				local active = ply:GetNWBool("HMCD_ShadowCamouflageActive")
				local charge_start = ply:GetNWFloat("HMCD_ShadowCamouflageChargeStart", 0)
				local ready_at = ply:GetNWFloat("HMCD_ShadowCamouflageReadyAt", 0)

				if(active or charge_start > 0)then
					local ready = not active and ready_at > 0 and CurTime() >= ready_at
					local text = active and "CAMOUFLAGED [R] Cancel" or (ready and "[R] Camouflage" or "Stand still by a wall to ready camouflage")
					local tw, th = surface.GetTextSize(text)
					local cx, cy = ScrW() * 0.5, ScrH() * 0.68 + y_offset

					draw_shadow_text(text, cx, cy)

					if(not active and ready_at > charge_start)then
						local frac = math.Clamp(1 - ((ready_at - CurTime()) / MODE.ShadowCamouflageChargeTime), 0, 1)

						surface.SetDrawColor(vgui_color_text_main)
						surface.DrawRect(cx - tw / 2, cy + th, tw * frac, math.max(ScreenScale(1), 2))
					end

					y_offset = y_offset + th + after_text_offset
				end
			end
		end
		
		--\\Professions
		
		--
	end
end)


--I'm fucked doing this

surface.CreateFont("TraitorPanelTitle", {
	font = "coolvetica",
	size = 22,
	weight = 500,
	antialias = true
})

surface.CreateFont("TraitorPanelText", {
	font = "coolvetica",
	size = 19,
	weight = 500,
	antialias = true
})

surface.CreateFont("TraitorPanelWords", {
	font = "coolvetica",
	size = 24,
	weight = 700,
	antialias = true,
	italic = false
})



local traitor_panel = {
    assistants = {},
    dead_anim = {}, 
    width = 300,
    height = 280,
    assist_height = 200,
    spacing = 26,
    padding = 15,
    left_padding = 90, 
    avatar_size = 24, 
    fade_speed = 3,
    instance = nil,
    visible = true,
    target_x = 0,
    smooth_toggle = 0,
    alpha = 255,
    last_toggle_time = 0,
    toggle_cooldown = 0.3,
    assistant_status_cache = {},
    assistant_avatars = {}, 
    avatar_materials = {}, 
    assistant_rows = {},
    assistants_dirty = true,
    avatars_visible = false,
    colors = {
        bg = Color(9, 0, 0, 235),
        bg_top = Color(60, 0, 0, 210),
        panel = Color(26, 0, 0, 185),
        panel_soft = Color(75, 0, 0, 70),
        border = Color(210, 18, 18, 245),
        border_inner = Color(120, 0, 0, 150),
        accent = Color(255, 55, 55, 230),
        accent_soft = Color(255, 35, 35, 55),
        title = Color(255, 255, 255, 255),
        text_soft = Color(205, 175, 175, 220),
        words = Color(255, 80, 80, 255),
        word_bg = Color(55, 0, 0, 175),
        assistant = Color(200, 70, 70, 255),
        row_bg = Color(40, 0, 0, 135),
        row_dead = Color(35, 35, 35, 155),
        role_bg = Color(75, 0, 0, 170)
    }
}

local function DrawTraitorCutPoly(x, y, w, h, cut, col)
    surface.SetDrawColor(col)
    draw.NoTexture()
    surface.DrawPoly({
        {x = x + cut, y = y},
        {x = x + w - cut, y = y},
        {x = x + w, y = y + cut},
        {x = x + w, y = y + h - cut},
        {x = x + w - cut, y = y + h},
        {x = x + cut, y = y + h},
        {x = x, y = y + h - cut},
        {x = x, y = y + cut}
    })
end

local function DrawTraitorCutOutline(x, y, w, h, cut, col, thick)
    surface.SetDrawColor(col)
    thick = thick or 1

    for i = 0, thick - 1 do
        local xi, yi = x + i, y + i
        local wi, hi = w - i * 2, h - i * 2
        local ci = math.max(cut - i, 0)

        surface.DrawLine(xi + ci, yi, xi + wi - ci, yi)
        surface.DrawLine(xi + wi - ci, yi, xi + wi, yi + ci)
        surface.DrawLine(xi + wi, yi + ci, xi + wi, yi + hi - ci)
        surface.DrawLine(xi + wi, yi + hi - ci, xi + wi - ci, yi + hi)
        surface.DrawLine(xi + wi - ci, yi + hi, xi + ci, yi + hi)
        surface.DrawLine(xi + ci, yi + hi, xi, yi + hi - ci)
        surface.DrawLine(xi, yi + hi - ci, xi, yi + ci)
        surface.DrawLine(xi, yi + ci, xi + ci, yi)
    end
end

local function DrawTraitorCutBox(x, y, w, h, cut, fill, outline, thick)
    DrawTraitorCutPoly(x, y, w, h, cut, fill)
    DrawTraitorCutOutline(x, y, w, h, cut, outline, thick)
end

local function DrawTraitorPanelTopBand(x, y, w, headerH, cut)
    surface.SetDrawColor(traitor_panel.colors.bg_top)
    draw.NoTexture()
    surface.DrawPoly({
        {x = x + cut + 1, y = y + 1},
        {x = x + w - cut - 1, y = y + 1},
        {x = x + w - 1, y = y + cut + 1},
        {x = x + w - 1, y = y + headerH},
        {x = x + 1, y = y + headerH},
        {x = x + 1, y = y + cut + 1}
    })
end

local function DrawTraitorPanelShell(x, y, w, h)
    local cut = 12
    local headerH = 46

    DrawTraitorCutBox(x, y, w, h, cut, traitor_panel.colors.bg, traitor_panel.colors.border, 1)
    DrawTraitorCutBox(x + 3, y + 3, w - 6, h - 6, cut - 3, traitor_panel.colors.panel, traitor_panel.colors.border_inner, 1)
    DrawTraitorPanelTopBand(x + 3, y + 3, w - 6, headerH, cut - 3)

    surface.SetDrawColor(traitor_panel.colors.accent_soft)
    surface.DrawRect(x + 18, y + headerH + 4, w - 36, 1)
    surface.DrawRect(x + 46, y + headerH + 9, w - 92, 1)

    surface.SetDrawColor(traitor_panel.colors.accent)
    surface.DrawRect(x + 9, y + headerH + 16, 3, h - headerH - 30)
    surface.SetDrawColor(traitor_panel.colors.accent_soft)
    surface.DrawRect(x + 14, y + h - 12, w - 28, 1)
end

local function DrawTraitorWordBox(text, x, y, w)
    DrawTraitorCutBox(x, y - 12, w, 24, 6, traitor_panel.colors.word_bg, traitor_panel.colors.border_inner, 1)
    surface.SetDrawColor(traitor_panel.colors.accent_soft)
    surface.DrawRect(x + 10, y + 9, w - 20, 1)
    draw.SimpleText(text, "TraitorPanelWords", x + w / 2, y, traitor_panel.colors.words, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end


local function HideTraitorPanelAvatars()
    for steamid, avatar in pairs(traitor_panel.assistant_avatars) do
        if IsValid(avatar) then
            avatar:SetVisible(false)
        end
    end

    traitor_panel.avatars_visible = false
end

local function CreateAvatarPanel(steamid)
    if not steamid or steamid == "" then return nil end

    local ply = player.GetBySteamID(steamid)
    if not IsValid(ply) then
        local oldAvatar = traitor_panel.assistant_avatars[steamid]
        if IsValid(oldAvatar) then oldAvatar:SetVisible(false) end
        return nil
    end

    if traitor_panel.assistant_avatars[steamid] and IsValid(traitor_panel.assistant_avatars[steamid]) then
        traitor_panel.assistant_avatars[steamid]:SetPlayer(ply, traitor_panel.avatar_size)
        return traitor_panel.assistant_avatars[steamid]
    end

    local avatar = vgui.Create("AvatarImage")
    avatar:SetSize(traitor_panel.avatar_size, traitor_panel.avatar_size)
    avatar:SetVisible(false) 
    avatar:SetPlayer(ply, traitor_panel.avatar_size)
    
    traitor_panel.assistant_avatars[steamid] = avatar
    return avatar
end

local function IsLocalTraitorInfo(ply, traitor_info)
    if not IsValid(ply) or not traitor_info then return false end

    local steamID = traitor_info[3] or ""
    if steamID ~= "" and ply.SteamID and steamID == ply:SteamID() then return true end

    return ply.CurAppearance and traitor_info[2] == ply.CurAppearance.AName
end

local function BuildTraitorPanelRows()
    traitor_panel.assistant_rows = {}
    traitor_panel.assistants_dirty = false

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply.MainTraitor then return end

    MODE.TraitorsLocal = MODE.TraitorsLocal or {}

    for _, traitor_info in ipairs(MODE.TraitorsLocal) do
        if not traitor_info or #traitor_info < 2 then continue end
        if IsLocalTraitorInfo(ply, traitor_info) then continue end

        local color = traitor_info[1]
        local name = traitor_info[2] or ""
        local steamID = traitor_info[3] or ""
        local subRole = traitor_info[4] or ""
        local roleName = MODE.SubRoles and MODE.SubRoles[subRole] and MODE.SubRoles[subRole].Name or "Traitor"

        if name ~= "" then
            traitor_panel.assistant_rows[#traitor_panel.assistant_rows + 1] = {
                color = IsColor(color) and color or traitor_panel.colors.assistant,
                name = name,
                display_name = #name > 20 and (string.sub(name, 1, 18) .. "..") or name,
                steamID = steamID,
                roleName = roleName
            }
        end
    end
end

local function RequestTraitorStatusNow()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply.isTraitor or not ply.MainTraitor then return end

    traitor_panel.next_status_request = CurTime() + 5
    net.Start("HMCD_RequestTraitorStatuses")
    net.SendToServer()
end


hook.Add("PlayerButtonDown", "TraitorPanelToggle", function(ply, btn)
    if ply ~= LocalPlayer() or btn ~= KEY_F4 then return end
    if not LocalPlayer().isTraitor then return end 
    

    local current_time = CurTime()
    if current_time - traitor_panel.last_toggle_time < traitor_panel.toggle_cooldown then
        return
    end
    
    traitor_panel.last_toggle_time = current_time
    traitor_panel.visible = not traitor_panel.visible
    
    if traitor_panel.visible then
        surface.PlaySound("buttons/button14.wav")
        traitor_panel.assistants_dirty = true
        RequestTraitorStatusNow()
    else
        HideTraitorPanelAvatars()
    end
end)




net.Receive("HMCD_UpdateTraitorAssistants", function()
    local count = net.ReadUInt(8)
    MODE.TraitorsLocal = {}
    
    for i = 1, count do
        local color = net.ReadColor()
        local name = net.ReadString()
        local steamID = net.ReadString()
        local subRole = net.ReadString()
        
        table.insert(MODE.TraitorsLocal, {color, name, steamID, subRole})
    end

    traitor_panel.assistants_dirty = true
end)


net.Receive("HMCD_TraitorDeathState", function()
    local traitor_name = net.ReadString()
    local is_alive = net.ReadBool()
    
    if traitor_name and traitor_name ~= "" then
        traitor_panel.assistant_status_cache[traitor_name] = is_alive
    end
end)

hook.Add("HUDPaint", "DrawTraitorPanel", function()
    local ply = LocalPlayer()
    if not ply.isTraitor or not ply:Alive() then 
        traitor_panel.visible = false 
        HideTraitorPanelAvatars()
        
        return 
    end


    local target = traitor_panel.visible and 0 or traitor_panel.width + 40
    traitor_panel.smooth_toggle = Lerp(FrameTime() * 10, traitor_panel.smooth_toggle, target)
    
    local is_main = ply.MainTraitor
    local height = is_main and traitor_panel.height or traitor_panel.assist_height
    local x = ScrW() - traitor_panel.width - 20 + traitor_panel.smooth_toggle
    local y = ScrH() / 2 - (height / 2)
    

    if traitor_panel.smooth_toggle > traitor_panel.width + 30 then 
        HideTraitorPanelAvatars()
        return 
    end
    

    DrawTraitorPanelShell(x, y, traitor_panel.width, height)
    

    local title = is_main and "MAIN TRAITOR" or "TRAITOR'S ASSISTANT"
    draw.SimpleText(title, "TraitorPanelTitle", x + traitor_panel.width/2, y + 15, 
                    traitor_panel.colors.title, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    

    draw.SimpleText("Press F4 to toggle panel", "TraitorPanelText", x + traitor_panel.width/2, y + 34,
                    traitor_panel.colors.text_soft, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    local word_y = y + 70
    draw.SimpleText("Secret Words:", "TraitorPanelText", x + traitor_panel.width/2, word_y, 
                    traitor_panel.colors.text_soft, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    word_y = word_y + 25
    local word1 = MODE.TraitorWord or "???"
    DrawTraitorWordBox(word1, x + traitor_panel.width * 0.5 - 78, word_y, 156)
    
    word_y = word_y + 30
    local word2 = MODE.TraitorWordSecond or "???"
    DrawTraitorWordBox(word2, x + traitor_panel.width * 0.5 - 78, word_y, 156)
    
    if is_main then
        if traitor_panel.assistants_dirty then
            BuildTraitorPanelRows()
        end
        
        local assist_y = y + 155
        local has_assistants = #traitor_panel.assistant_rows > 0
        
        if has_assistants then
            draw.SimpleText("Your Assistants:", "TraitorPanelText", x + traitor_panel.width/2, assist_y, 
                            traitor_panel.colors.text_soft, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            assist_y = assist_y + 25   
            
            for _, row in ipairs(traitor_panel.assistant_rows) do
                local name = row.name
                local is_alive = true
                if traitor_panel.assistant_status_cache[name] == false then
                    is_alive = false
                end

                if not is_alive then
                    traitor_panel.dead_anim[name] = traitor_panel.dead_anim[name] or 255
                    traitor_panel.dead_anim[name] = math.max(traitor_panel.dead_anim[name] - FrameTime() * 100 * traitor_panel.fade_speed, 0)
                    
                    if traitor_panel.dead_anim[name] <= 0 then continue end
                else
                    traitor_panel.dead_anim[name] = nil
                end
                
                local alpha = traitor_panel.dead_anim[name] or 255
                local display_color = is_alive and row.color or Color(150, 150, 150)
                display_color = Color(display_color.r, display_color.g, display_color.b, alpha)
                
                local status = is_alive and "" or " [DEAD]"
                local rowY = assist_y - 13
                local rowFill = is_alive and traitor_panel.colors.row_bg or traitor_panel.colors.row_dead
                local rowOutline = is_alive and Color(row.color.r, row.color.g, row.color.b, math.min(alpha, 130)) or Color(120, 120, 120, 80)
                DrawTraitorCutBox(x + 13, rowY, traitor_panel.width - 26, 24, 6, rowFill, rowOutline, 1)
                surface.SetDrawColor(is_alive and Color(row.color.r, row.color.g, row.color.b, math.min(alpha, 145)) or Color(120, 120, 120, 90))
                surface.DrawRect(x + 18, rowY + 4, 3, 16)

                if row.steamID and row.steamID ~= "" then
                    local avatar = CreateAvatarPanel(row.steamID)

                    if avatar then
                        avatar:SetPos(x + 15, assist_y - traitor_panel.avatar_size/2)
                        avatar:SetAlpha(alpha)
                        avatar:SetVisible(true)
                        traitor_panel.avatars_visible = true

                        surface.SetDrawColor(50, 50, 50, alpha)
                        surface.DrawOutlinedRect(x + 15, assist_y - traitor_panel.avatar_size/2,
                                                 traitor_panel.avatar_size, traitor_panel.avatar_size, 1)
                    end
                end

                local roleTextW = 84
                local roleX = x + traitor_panel.width - roleTextW - 13
                local roleDisplay = row.roleName
                if #roleDisplay > 11 then
                    roleDisplay = string.sub(roleDisplay, 1, 10) .. "."
                end
                DrawTraitorCutBox(roleX, assist_y - 11, roleTextW, 19, 5,
                    traitor_panel.colors.role_bg, Color(255, 70, 70, math.min(alpha, 145)), 1)
                
                draw.SimpleText(row.display_name..status, "TraitorPanelText", x + traitor_panel.width * 0.5, assist_y,
                                display_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(roleDisplay, "TraitorPanelText", roleX + roleTextW * 0.5, assist_y,
                                Color(255, 135, 135, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                
                assist_y = assist_y + 25   
                

                if assist_y > y + height - 30 then
                    break
                end
            end
        else
            HideTraitorPanelAvatars()

            draw.SimpleText("No assistants available", "TraitorPanelText", x + traitor_panel.width/2, assist_y, 
                            Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    else

        HideTraitorPanelAvatars()
    end
end)


hook.Add("PostPlayerDeath", "ClearTraitorPanel", function(ply)
    if ply == LocalPlayer() then
        traitor_panel.dead_anim = {}
        traitor_panel.smooth_toggle = 0
        traitor_panel.visible = false
        traitor_panel.assistants_dirty = true
        HideTraitorPanelAvatars()
    end
end)


hook.Add("Think", "UpdateTraitorAssistants", function()
	if not LocalPlayer().isTraitor or not LocalPlayer().MainTraitor then return end
    if not traitor_panel.visible then return end

	if not traitor_panel.next_assistant_check or traitor_panel.next_assistant_check < CurTime() then
		traitor_panel.next_assistant_check = CurTime() + 1.5
		
		for name, alpha in pairs(traitor_panel.dead_anim) do
			local is_alive = false
			for _, v in player.Iterator() do
				if v.isTraitor and v.CurAppearance and v.CurAppearance.AName == name then
					is_alive = v:Alive() and (not v.organism or not v.organism.incapacitated)
					break
				end
			end
			
			if is_alive then
				traitor_panel.dead_anim[name] = nil
			end
		end
	end
end)


hook.Add("Think", "RequestTraitorStatus", function()
	if not LocalPlayer().isTraitor or not LocalPlayer().MainTraitor then return end
    if not traitor_panel.visible then return end
	
	if not traitor_panel.next_status_request or traitor_panel.next_status_request < CurTime() then
		traitor_panel.next_status_request = CurTime() + 5
		
		net.Start("HMCD_RequestTraitorStatuses")
		net.SendToServer()
	end
end)

hook.Add("HUDPaint", "HMCD_ManiacRampage", function()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return end
	if not ply:GetNWBool("HMCD_ManiacFuryActive", false) then return end

	local max_stacks = MODE.ManiacRampageMaxStacks or 5
	local stacks = math.Clamp(ply:GetNWInt("HMCD_ManiacRampageStacks", 0), 0, max_stacks)
	local segment_w = math.max(ScreenScale(10), 16)
	local segment_h = math.max(ScreenScale(3), 5)
	local gap = math.max(ScreenScale(1), 2)
	local total_w = segment_w * max_stacks + gap * (max_stacks - 1)
	local x = math.floor((ScrW() - total_w) * 0.5)
	local y = math.floor(ScrH() * 0.78)
	local next_decay = ply:GetNWFloat("HMCD_ManiacRampageNextDecay", 0)
	local decay_fraction = math.Clamp((next_decay - CurTime()) / (MODE.ManiacRampageDuration or 15), 0, 1)

	draw.SimpleText("RAMPAGE", "HomigradFontSmall", ScrW() * 0.5 + 1, y - ScreenScale(9) + 1, Color(0, 0, 0, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText("RAMPAGE", "HomigradFontSmall", ScrW() * 0.5, y - ScreenScale(9), Color(235, 55, 42, 235), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	for index = 1, max_stacks do
		local sx = x + (index - 1) * (segment_w + gap)
		surface.SetDrawColor(8, 5, 5, 205)
		surface.DrawRect(sx, y, segment_w, segment_h)

		if index <= stacks then
			local intensity = index == 1 and math.max(decay_fraction, 0.35) or 1
			surface.SetDrawColor(235, 42 + 45 * intensity, 30, 235)
			surface.DrawRect(sx + 1, y + 1, segment_w - 2, segment_h - 2)
		end
	end
end)
