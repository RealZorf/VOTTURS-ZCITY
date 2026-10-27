hg.settings = hg.settings or {}
hg.settings.tbl = {}
hg.settings.categoryOrder = {}

function hg.settings:AddOpt(category, cvar, title, decimals, isString, kind, help)
	if not self.tbl[category] then
		self.tbl[category] = {}
		self.categoryOrder[#self.categoryOrder + 1] = category
	end

	self.tbl[category][#self.tbl[category] + 1] = {
		cvar = cvar,
		title = title,
		decimals = decimals and 2 or 0,
		kind = isString and "string" or kind,
		help = help
	}
end

hg.settings:AddOpt("Gameplay", "hg_showthoughts", "Character thoughts", nil, nil, nil, "Show pain and status thoughts from your character")
hg.settings:AddOpt("Gameplay", "hg_hints", "Object hints", nil, nil, nil, "Show interaction hints when you look at usable objects")
hg.settings:AddOpt("Gameplay", "hg_old_notificate", "Old notifications", nil, nil, nil, "Unused. Was meant to print damage notices in chat")
hg.settings:AddOpt("Gameplay", "hg_deathfadeout", "Death fade", nil, nil, nil, "Fade the screen and mute sound when you die")
hg.settings:AddOpt("Gameplay", "hg_gary", "Center gun when downed", nil, nil, nil, "When ragdolled, keep the gun pointed with your head")
hg.settings:AddOpt("Gameplay", "hg_cheats", "Invert mouse and strafe", nil, nil, nil, "Flips look-left/right and A/D movement")
hg.settings:AddOpt("Gameplay", "hg_wos_animmenus", "Emote menu", nil, nil, nil, "Adds emotes to the radial menu. Press F3 to pick which ones")

hg.settings:AddOpt("View", "hg_fov", "Field of view", nil, nil, nil, "How wide your view is while not aiming")
hg.settings:AddOpt("View", "hg_nofovzoom", "Disable aiming zoom", nil, nil, nil, "Stop the camera from zooming in when you aim")
hg.settings:AddOpt("View", "hg_leancam_mul", "Lean tilt", true, nil, "int", "How much the camera tilts when you lean")
hg.settings:AddOpt("View", "hg_firstperson_death", "First-person death", nil, nil, nil, "Stay in first person on your body after you die")
hg.settings:AddOpt("View", "hg_newspectate", "Smooth spectate", nil, nil, nil, "Smoothly blend the camera when switching players")
hg.settings:AddOpt("View", "hg_newfakecam", "New downed camera", nil, nil, nil, "Unused. The new downed camera code is turned off")
hg.settings:AddOpt("View", "hg_cshs_fake", "Locked downed camera", nil, nil, nil, "Lock the camera to your head while down instead of free-look")
hg.settings:AddOpt("View", "hg_gopro", "Head camera", nil, nil, nil, "Put the camera on your head. Also changes footsteps and gun sound")
hg.settings:AddOpt("View", "hg_realismcam", "Weapon camera lag", nil, nil, nil, "Camera lags with the gun. Can feel nauseating")
hg.settings:AddOpt("View", "hg_gun_cam", "Gun camera (admin)", nil, nil, nil, "Put the camera on the gun. Admins only")

hg.settings:AddOpt("Weapons", "hg_dynamic_mags", "Auto ammo HUD", nil, nil, nil, "Show remaining ammo after you shoot when the mag is low")
hg.settings:AddOpt("Weapons", "hg_zoomsensitivity", "Aiming mouse speed", nil, nil, nil, "Mouse speed while aiming. Lower is slower")
hg.settings:AddOpt("Weapons", "hg_weaponshotblur_enable", "Shot blur", nil, nil, nil, "Blur the screen when you fire")
hg.settings:AddOpt("Weapons", "hg_highpitchgunfire", "Indoor gunshots", nil, nil, nil, "Add extra indoor echo when shooting inside")

hg.settings:AddOpt("UI", "hg_font", "HUD font", false, true, nil, "Font name used by HUD text")
hg.settings:AddOpt("UI", "mzb_MoodleHud_enabled", "Status icons", nil, nil, "bool", "Show status icons like pain and bleeding")
hg.settings:AddOpt("UI", "zb_spectator_esp", "Spectator names", nil, nil, "bool", "Show player names through walls only while you are dead")
hg.settings:AddOpt("UI", "zb_esp_show_outlines", "Player outlines", nil, nil, "bool", "Draw a colored outline around players")
hg.settings:AddOpt("UI", "zb_esp_outline_limit", "Max outlines (0 = all)", true, nil, "int", "How many player outlines can draw at once")
hg.settings:AddOpt("UI", "zb_esp_range_limit", "Outline range (0 = all)", true, nil, "int", "How far away outlines still draw, in meters")

hg.settings:AddOpt("Sound", "hg_dmusic", "Dynamic music", nil, nil, nil, "Play mood music. GMod music volume must be on")
hg.settings:AddOpt("Sound", "hg_quietshots", "Quieter gunshots", nil, nil, nil, "Play each gunshot once instead of stacking extra copies")

hg.settings:AddOpt("Blood", "hg_blood_draw_distance", "Blood draw range", nil, nil, nil, "How far away blood still draws")
hg.settings:AddOpt("Blood", "hg_blood_fps", "Blood update rate", nil, nil, nil, "How often blood updates. Lower is cheaper")
hg.settings:AddOpt("Blood", "hg_old_blood", "Old blood splats", nil, nil, nil, "Use the old blood textures on walls")
hg.settings:AddOpt("Blood", "hg_blood_sprites", "Sprite blood", nil, nil, nil, "Unused. Does not change blood right now")

hg.settings:AddOpt("Optimization", "hg_potatopc", "Lighter effects", nil, nil, nil, "Turns off extra blur and shell effects. Does not change GMod graphics")
hg.settings:AddOpt("Optimization", "hg_low_graphics", "Low graphics", nil, nil, nil, "Lowers shadows, details, and effects. Restores them when off. Can freeze")
hg.settings:AddOpt("Optimization", "hg_multicore", "Multicore rendering", nil, nil, nil, "Uses extra CPU threads for rendering. Can crash")
hg.settings:AddOpt("Optimization", "hg_anims_draw_distance", "Body animation range", true, nil, "int", "How far you see other players' body animations. 0 = unlimited")
hg.settings:AddOpt("Optimization", "hg_anim_fps", "Body animation FPS", nil, nil, "int", "How often other players' bodies update. Not your gun. 0 = unlimited")
hg.settings:AddOpt("Optimization", "hg_attachment_draw_distance", "Attachment range", true, nil, "int", "How far you see sights, grips, and other attachments")
hg.settings:AddOpt("Optimization", "hg_tpik_distance", "Gun arm range", true, nil, "int", "How far you see other players holding guns with animated arms")
hg.settings:AddOpt("Optimization", "hg_tpik_remote_near_fps", "Close arm FPS", nil, nil, "int", "How often nearby gun arms update. Higher is smoother")
hg.settings:AddOpt("Optimization", "hg_tpik_remote_mid_fps", "Mid arm FPS", nil, nil, "int", "How often mid-range gun arms update. Higher is smoother")
hg.settings:AddOpt("Optimization", "hg_tpik_remote_far_fps", "Far arm FPS", nil, nil, "int", "How often distant gun arms update. Higher is smoother")
hg.settings:AddOpt("Optimization", "hg_tpik_remote_near_distance", "Close arm range", nil, nil, "int", "Distance where close arm FPS switches to mid")
hg.settings:AddOpt("Optimization", "hg_tpik_remote_mid_distance", "Mid arm range", nil, nil, "int", "Distance where mid arm FPS switches to far")
hg.settings:AddOpt("Optimization", "hg_maxsmoketrails", "Max smoke trails", nil, nil, "int", "How many gun smoke trails can exist at once. High values lag")
hg.settings:AddOpt("Optimization", "hg_player_occlusion", "Hide players behind walls", nil, nil, nil, "Skip drawing players you cannot see")
hg.settings:AddOpt("Optimization", "hg_player_occlusion_full", "Hide gear behind walls", nil, nil, nil, "Also hide their gun, armor, and arms. Needs the option above")
hg.settings:AddOpt("Optimization", "hg_player_occlusion_checks", "Wall checks per frame", nil, nil, "int", "How many players are wall-checked each frame")
hg.settings:AddOpt("Optimization", "hg_player_occlusion_delay", "Wall check delay", true, nil, "int", "Seconds between checks on the same player. Higher uses less CPU")
hg.settings:AddOpt("Optimization", "hg_player_occlusion_hide_delay", "Hide delay", true, nil, "int", "Seconds they must stay behind a wall before hiding. Stops flicker")
hg.settings:AddOpt("Optimization", "hg_player_occlusion_side", "Side peek check", true, nil, "int", "How far to check left and right so peeking players stay visible")
hg.settings:AddOpt("Optimization", "hg_player_occlusion_top", "Head peek check", true, nil, "int", "How far to check above the head so only-head peeks stay visible")

if not game.IsDedicated() then
	hg.settings:AddOpt("Server", "hg_thirdperson", "Third person", nil, nil, nil, "Server-wide third-person camera. Unfinished")
	hg.settings:AddOpt("Server", "hg_legacycam", "Legacy camera", nil, nil, nil, "Use the old first-person camera if third person is on")
	hg.settings:AddOpt("Server", "hg_ragdollcombat", "Ragdoll combat", nil, nil, nil, "Let people walk and fight while ragdolled")
	hg.settings:AddOpt("Server", "hg_healanims", "Heal animations", nil, nil, nil, "Play animations when using meds or food")
	hg.settings:AddOpt("Server", "hg_aimtoshoot", "Aim to shoot", nil, nil, nil, "Guns only fire while aiming")
	hg.settings:AddOpt("Server", "hg_slings", "Weapon slings", nil, nil, nil, "Show unused guns slung on the body")
	hg.settings:AddOpt("Server", "hg_movement_stamina_debuff", "Tired speed floor", true, nil, "int", "Slowest you can move when stamina is low. 1 = no slowdown")
	hg.settings:AddOpt("Server", "hg_toughnpcs", "Tougher NPCs", nil, nil, nil, "Give NPCs more health")
	hg.settings:AddOpt("Server", "hg_furcity", "Furry chat", nil, nil, nil, "Rewrite chat and thoughts in furry speak")
	hg.settings:AddOpt("Server", "hg_appearance_access_for_all", "Free appearance items", nil, nil, "bool", "Let everyone use all appearance items, not just unlocked ones")
	hg.settings:AddOpt("Server", "homicide_traitoramount", "Homicide traitors", nil, nil, "int", "How many traitors spawn in Homicide")
end

hg.settings:AddOpt("Debug", "hg_show_hitbox", "Show hitboxes", nil, nil, nil, "Draw player hitboxes. Admins or sv_cheats 1")
hg.settings:AddOpt("Debug", "hg_show_hitposmuzzle", "Show muzzle point", nil, nil, nil, "Draw where the gun is aiming. Admins or sv_cheats 1")
hg.settings:AddOpt("Debug", "hg_setzoompos", "Edit aim zoom", nil, nil, nil, "Superadmin only. Hold RMB to move iron-sight zoom and print values")

local CRT_R, CRT_G, CRT_B = 35, 225, 110
local TRAITOR_R, TRAITOR_G, TRAITOR_B = 225, 35, 35
local FRAME_R, FRAME_G, FRAME_B = 86, 94, 90
local color_idle_dim = Color(112, 118, 116)
local color_bezel = Color(12, 13, 13)
local color_panel = Color(20, 22, 21)
local color_text = Color(236, 238, 236)
local color_danger = Color(TRAITOR_R, TRAITOR_G, TRAITOR_B)
local BEZEL = 3
local INSET = BEZEL + 4
local SND_CLICK = "shitty/tap_depress.wav"
local SND_HOVER = "shitty/tap-resonant.wav"

local function S(n)
	return math.max(1, math.Round(n * ScrH() / 1080))
end

local function CreateFonts()
	surface.CreateFont("ZC_MM_Header", {font = "Bahnschrift", size = math.max(18, S(22)), weight = 700, antialias = true, extended = true})
	surface.CreateFont("ZC_MM_Tiny", {font = "Bahnschrift", size = math.max(12, S(15)), weight = 500, antialias = true, extended = true})
end
CreateFonts()
hook.Add("OnScreenSizeChanged", "ZC_Settings_Fonts", CreateFonts)

local function ClickSound(path)
	local ply = LocalPlayer()
	if IsValid(ply) then ply:EmitSound(path, 75, 100, 0.09) else surface.PlaySound(path) end
end

local function IsModified(cvar)
	local cur, def = cvar:GetString(), cvar:GetDefault()
	if not def then return false end
	local ncur, ndef = tonumber(cur), tonumber(def)
	if ncur and ndef then
		local min, max = cvar:GetMin(), cvar:GetMax()
		if min ~= max then ndef = math.Clamp(ndef, min, max) end
		return ncur ~= ndef
	end
	return cur ~= def
end

local function PaintEntry(self, w, h)
	surface.SetDrawColor(color_bezel)
	surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, self:IsEditing() and 200 or 120)
	surface.DrawOutlinedRect(0, 0, w, h, 1)

	local text = self:GetText()
	draw.SimpleText(text, "ZC_MM_Tiny", w * 0.5, h * 0.5, color_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if self:IsEditing() and (CurTime() * 2) % 2 < 1 then
		surface.SetFont("ZC_MM_Tiny")
		local full = surface.GetTextSize(text)
		local caret = surface.GetTextSize(string.sub(text, 1, self:GetCaretPos()))
		surface.SetDrawColor(color_text)
		surface.DrawRect(math.floor(w * 0.5 - full * 0.5 + caret), math.floor(h * 0.5 - 7), 1, 14)
	end
end

local function AddSettingRow(parent, opt)
	local cvar = GetConVar(opt.cvar)
	if not cvar then return end

	local kind = opt.kind
	if kind == "int" then
		kind = "num"
	elseif kind ~= "bool" and kind ~= "string" then
		local str = cvar:GetString()
		kind = (str == "0" or str == "1") and "bool" or (tonumber(str) and "num" or "string")
	end

	local rowH, btnH, toggleH = S(64), S(36), S(24)
	local side = math.floor((rowH - btnH) * 0.5)
	local row = vgui.Create("DPanel", parent)
	row:Dock(TOP)
	row:SetTall(rowH)
	row:DockMargin(0, 0, 0, S(8))
	row:SetPaintBackground(false)
	row.Paint = function(self, w, h)
		surface.SetDrawColor(32, 34, 33, self:IsHovered() and 210 or 160)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, 70)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.SimpleText(opt.title, "ZC_MM_Header", S(16), h * 0.5 - S(8), color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(opt.help or cvar:GetHelpText() or "", "ZC_MM_Tiny", S(16), h * 0.5 + S(12), color_idle_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	if kind == "bool" then
		local toggle = vgui.Create("DButton", row)
		toggle:SetText("")
		toggle:SetWide(S(52))
		toggle:Dock(RIGHT)
		toggle:DockMargin(S(6), math.floor((rowH - toggleH) * 0.5), S(10), math.floor((rowH - toggleH) * 0.5))
		toggle.Paint = function(self, w, h)
			local on = cvar:GetBool()
			local hover = self:IsHovered()
			surface.SetDrawColor(color_bezel)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(on and CRT_R or (hover and TRAITOR_R or FRAME_R), on and CRT_G or (hover and TRAITOR_G or FRAME_G), on and CRT_B or (hover and TRAITOR_B or FRAME_B), 180)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			local knob = h - S(8)
			surface.DrawRect(on and (w - knob - S(4)) or S(4), S(4), knob, knob)
		end
		toggle.OnCursorEntered = function() ClickSound(SND_HOVER) end
		toggle.DoClick = function()
			ClickSound(SND_CLICK)
			RunConsoleCommand(cvar:GetName(), cvar:GetBool() and "0" or "1")
		end
	elseif kind == "num" then
		local min, max = cvar:GetMin() or 0, cvar:GetMax() or 100
		if min == max then max = min + 1 end
		local span, decimals = max - min, opt.decimals
		local wrap = vgui.Create("DPanel", row)
		wrap:Dock(RIGHT)
		wrap:SetWide(S(268))
		wrap:DockMargin(S(12), side, S(16), side)
		wrap:SetPaintBackground(false)

		local entry = vgui.Create("DTextEntry", wrap)
		entry:Dock(LEFT)
		entry:SetWide(S(72))
		entry:DockMargin(0, 0, S(8), 0)
		entry:SetFont("ZC_MM_Tiny")
		entry:SetText(tostring(decimals > 0 and math.Round(cvar:GetFloat(), decimals) or cvar:GetInt()))
		entry.Paint = PaintEntry

		local slider = vgui.Create("DSlider", wrap)
		slider:Dock(FILL)
		slider:SetLockY(0.5)
		slider:SetTrapInside(true)
		slider:SetSlideX(math.Clamp((cvar:GetFloat() - min) / span, 0, 1))
		local knob = math.max(8, S(10))
		slider.Knob:SetSize(knob, knob)
		slider.Knob:SetCursor("hand")
		slider.Knob.Paint = function(self, w, h)
			local active = self:IsHovered() or self:IsDown() or slider.Dragging
			surface.SetDrawColor(CRT_R, CRT_G, CRT_B, active and 255 or 230)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(12, 14, 12, 220)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
		end
		slider.Paint = function(self, w, h)
			local frac = math.Clamp(self:GetSlideX(), 0, 1)
			local y = math.floor((h - 3) * 0.5)
			surface.SetDrawColor(0, 0, 0, 210)
			surface.DrawRect(0, y, w, 3)
			surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, 90)
			surface.DrawRect(0, y, w, 3)
			surface.SetDrawColor(CRT_R, CRT_G, CRT_B, 230)
			surface.DrawRect(0, y, w * frac, 3)
		end

		local function Apply(v)
			if not v then
				entry:SetText(tostring(decimals > 0 and math.Round(cvar:GetFloat(), decimals) or cvar:GetInt()))
				return
			end
			v = decimals > 0 and math.Round(math.Clamp(v, min, max), decimals) or math.Round(math.Clamp(v, min, max))
			RunConsoleCommand(cvar:GetName(), tostring(v))
			slider.ignore = true
			slider:SetSlideX(math.Clamp((v - min) / span, 0, 1))
			slider.ignore = false
			if not entry:HasFocus() then entry:SetText(tostring(v)) end
		end
		slider.OnValueChanged = function(_, x)
			if not slider.ignore then Apply(min + math.Clamp(x, 0, 1) * span) end
		end
		entry.OnEnter = function(self) Apply(tonumber(self:GetText())) end
		entry.OnLoseFocus = function(self) Apply(tonumber(self:GetText())) end
		wrap.Think = function()
			if entry:HasFocus() or slider.Dragging then return end
			local v = decimals > 0 and math.Round(cvar:GetFloat(), decimals) or cvar:GetInt()
			local text = tostring(v)
			if entry:GetText() ~= text then entry:SetText(text) end
			local x = math.Clamp((cvar:GetFloat() - min) / span, 0, 1)
			if math.abs(slider:GetSlideX() - x) > 0.001 then
				slider.ignore = true
				slider:SetSlideX(x)
				slider.ignore = false
			end
		end
	else
		local entry = vgui.Create("DTextEntry", row)
		entry:Dock(RIGHT)
		entry:SetWide(S(180))
		entry:DockMargin(S(12), side, S(16), side)
		entry:SetFont("ZC_MM_Tiny")
		entry:SetText(cvar:GetString())
		entry:SetUpdateOnType(true)
		entry.Paint = PaintEntry
		entry.OnValueChange = function(_, val)
			RunConsoleCommand(cvar:GetName(), val)
		end
		entry.Think = function(self)
			if self:HasFocus() then return end
			local val = cvar:GetString()
			if self:GetText() ~= val then self:SetText(val) end
		end
	end

	local reset = vgui.Create("DButton", row)
	reset:SetText("")
	reset:SetWide(0)
	reset:Dock(RIGHT)
	reset:DockMargin(0, side, 0, side)
	reset.Paint = function(self, w, h)
		if w < 2 then return end
		local hover = self:IsHovered()
		surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, 230)
		surface.DrawRect(0, 0, w, h)
		if hover then
			surface.SetDrawColor(TRAITOR_R, TRAITOR_G, TRAITOR_B, 28)
			surface.DrawRect(1, 1, w - 2, h - 2)
		end
		surface.SetDrawColor(TRAITOR_R, TRAITOR_G, TRAITOR_B, hover and 210 or 150)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.SimpleText("RESET", "ZC_MM_Tiny", w * 0.5, h * 0.5, hover and color_text or color_danger, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	reset.OnCursorEntered = function(self)
		if self:GetWide() > 2 then ClickSound(SND_HOVER) end
	end
	reset.DoClick = function()
		local def = cvar:GetDefault()
		if not def then return end
		ClickSound(SND_CLICK)
		RunConsoleCommand(cvar:GetName(), def)
	end
	reset.Think = function(self)
		local dirty = IsModified(cvar)
		local w = dirty and S(72) or 0
		if self:GetWide() == w then return end
		self:SetWide(w)
		self:DockMargin(dirty and S(6) or 0, side, dirty and S(6) or 0, side)
		row:InvalidateLayout()
	end
end

function hg.DrawSettings(parent)
	if not IsValid(parent) then return end

	parent.Paint = function(_, w, h)
		surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, 230)
		surface.DrawRect(0, 0, w, h)
		local ix, iy, iw, ih = BEZEL, BEZEL, w - BEZEL * 2, h - BEZEL * 2
		surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, 200)
		surface.DrawOutlinedRect(ix, iy, iw, ih, 1)
		surface.SetDrawColor(CRT_R, CRT_G, CRT_B, 230)
		surface.DrawRect(ix, iy, 10, 2)
		surface.DrawRect(ix, iy, 2, 10)
		surface.DrawRect(ix + iw - 10, iy, 10, 2)
		surface.DrawRect(ix + iw - 2, iy, 2, 10)
		surface.DrawRect(ix, iy + ih - 2, 10, 2)
		surface.DrawRect(ix, iy + ih - 10, 2, 10)
		surface.DrawRect(ix + iw - 10, iy + ih - 2, 10, 2)
		surface.DrawRect(ix + iw - 2, iy + ih - 10, 2, 10)
		local px, py, pw, ph = ix + 1, iy + 1, iw - 2, ih - 2
		surface.SetDrawColor(color_panel.r, color_panel.g, color_panel.b, 210)
		surface.DrawRect(px, py, pw, ph)
		local step = S(72)
		local ox = (CurTime() * 18) % step
		surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, 8)
		for gx = 0, math.ceil(pw / step) do
			surface.DrawRect(px + gx * step - ox, py, 2, ph)
		end
		for gy = 0, math.ceil(ph / step) do
			surface.DrawRect(px, py + gy * step - ox + step, pw, 2)
		end
	end

	local header = vgui.Create("DPanel", parent)
	header:Dock(TOP)
	header:SetTall(S(36))
	header:DockMargin(INSET, INSET, INSET, 0)
	header:SetPaintBackground(false)
	header.Paint = function(_, w, h)
		surface.SetDrawColor(32, 34, 33, 210)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(CRT_R, CRT_G, CRT_B, 36)
		surface.DrawRect(0, 0, w, h)
		draw.SimpleText("SETTINGS", "ZC_MM_Header", S(12), h * 0.5, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	local scroll = vgui.Create("DScrollPanel", parent)
	scroll:Dock(FILL)
	scroll:DockMargin(INSET, 0, INSET, INSET)
	local bar = scroll:GetVBar()
	bar:SetWide(S(8))
	bar:SetHideButtons(true)
	bar.Paint = function(_, w, h)
		surface.SetDrawColor(0, 0, 0, 70)
		surface.DrawRect(1, 0, w - 2, h)
	end
	bar.btnGrip.Paint = function(self, w, h)
		surface.SetDrawColor(self:IsHovered() and CRT_R or FRAME_R, self:IsHovered() and CRT_G or FRAME_G, self:IsHovered() and CRT_B or FRAME_B, self:IsHovered() and 180 or 130)
		surface.DrawRect(1, 0, w - 2, h)
	end

	for i, category in ipairs(hg.settings.categoryOrder) do
		local heading = vgui.Create("DPanel", scroll)
		heading:Dock(TOP)
		heading:SetTall(S(32))
		heading:DockMargin(0, i == 1 and S(10) or 0, 0, 0)
		heading:SetPaintBackground(false)
		heading.Paint = function()
			draw.SimpleText(string.upper(category), "ZC_MM_Header", S(12), S(4), color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end
		for _, opt in ipairs(hg.settings.tbl[category]) do
			AddSettingRow(scroll, opt)
		end
	end
end


