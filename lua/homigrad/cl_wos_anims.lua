local cvEnable = CreateClientConVar("hg_wos_animmenus", "0", true, false, "Enable wOS animations in the radial menu and gm_showspare1 config", 0, 1)
local MAX_ANIMS = 14

local CRT_R, CRT_G, CRT_B = 35, 225, 110
local FRAME_R, FRAME_G, FRAME_B = 86, 94, 90
local color_bezel = Color(12, 13, 13)
local color_panel = Color(20, 22, 21)
local color_text = Color(236, 238, 236)
local color_idle = Color(168, 172, 170)
local color_accent = Color(CRT_R, CRT_G, CRT_B)

local CATALOG = {
	Fortnite = {
		"advanced_math", "balletic", "behold", "be_seeing_you", "best_mates", "bhangra_boogie",
		"billy_bounce", "blinding_lights", "bobbin", "bold_stance", "bombastic", "boneless",
		"boogie_bomb", "boogie_down", "breakdown", "breakin", "breakneck", "breezy",
		"bring_it_on", "brush_your_shoulders", "buckle_up", "bulletproof", "bunny_hop",
		"burpee", "business_hips", "cmere", "calculated", "call_me", "cap_kick",
		"cap_kick_fail", "capoeira", "cartwheelin", "cat_flip", "cheer_up", "chicken",
		"clean_groove", "click", "cluck_strut", "confused", "conga", "crabby",
		"crackdown", "crazyboy", "crazy_feet", "criss_cross", "dab", "dabstand",
		"dance_moves", "dance_off", "dance_therapy", "daydream", "death", "deep_dab",
		"deep_end", "denied", "disco_fever", "disc_spinner", "distracted", "double_up",
		"dragon_stance", "dream_feet", "droop", "drop_the_bass", "drum_major", "dynamic_shuffle",
		"eagle", "electro_shuffle", "electro_swing", "extraterrestial", "facepalm", "fanciful",
		"fancy_feet", "fandangle", "feelin_jaunty", "fierce", "finger_guns", "finger_wag",
		"fishin", "fist_pump", "flamenco", "flapper", "flex_on_em", "flippin_away",
		"flippin_incredible", "flippin_sexy", "floss", "flux", "free_flow", "free_mix",
		"freestylin", "freewheelin", "fresh", "fright_funk", "full_tilt", "gentlemans_dab",
		"get_funky", "get_loose", "glitter", "glowsticks", "glyphic", "go_go_go",
		"golf_clap", "groove_jam", "ground_pound", "guitar_walk", "gun_show", "hand_signals",
		"hang_loose", "hang_on", "harmony", "headbanger", "headbanger_alt", "hello_friend",
		"hemlock_bad_to_good", "hemlock_good_to_bad", "hitchhiker", "hoop_master", "hootenanny",
		"hot_marat", "howl", "hula", "hype", "idk", "infectious", "infinidab",
		"intensity", "introducing", "its_complicated", "jamboree", "jaywalking", "jazz_hands",
		"jitterbug", "job_well_done", "jubilation", "jumping_jacks", "jump_jets", "keep_it_mello",
		"kiss_kiss", "knee_slapper", "laid_back_shuffle", "laugh_it_up", "lavish", "lazer_blast",
		"lazy_shuffle", "leapin", "levitate", "living_large", "llama_conga", "lock_it_up",
		"make_it_rain", "marsh_walk", "martial_arts_master", "mime_time", "mind_blown", "moon_bounce",
		"my_idol", "nana_nana", "never_gonna", "ninja_style", "no_sweat", "old_school",
		"orange_justice", "out_west", "overdrive", "party_hips", "paws_and_claws", "peace_out",
		"peely_pulse", "phew", "pick_it_up", "pirouette", "planetary_vibe", "point_it_out",
		"poki", "pop_lock", "power_roar", "prickly_pose", "primo_moves", "pumpernickel",
		"pump_it_up", "punched_up", "pure_salt", "rage_quit", "rambunctious", "rawr",
		"reanimated", "regal_wave", "respect", "respect_the_peace", "revel", "ribbon_dancer",
		"ride_the_pony", "rock_out", "running_man", "sad_claps", "salute", "sasquatchin",
		"savor_the_w", "scenario", "secret_hand_shake", "shadow_boxer", "shadow_spar", "shake_it_up",
		"shaolin_sit_up", "sharpshooter", "shimmer", "showstopper", "side_hustle", "signature_shuffle",
		"sign_protest", "sign_spinner", "sizzlin", "slap_happy", "slick", "slitherin",
		"slow_clap", "smooth_moves", "snap", "snoozefest", "something_stinks", "so_square",
		"spike_it", "spring_loaded", "springy", "sprinkler", "squat_kick_intro", "squat_kick",
		"star_power", "statuesque", "step_it_up", "stride", "strut", "sugar_rush",
		"swipe_it", "switch_step", "taco_time", "tai_chi", "take_the_l", "taxi",
		"the_renegade", "the_robot", "thumbs_down", "thumbs_up", "tidy", "time_out",
		"tippy_tap", "toosie_slide", "t_pose", "tra_la_la", "travis_stage_dance", "true_heart",
		"tsss", "turbocharged", "twist", "unification", "verve", "very_sneaky",
		"vibin", "vivacious", "waddle_away", "waterworks", "wave", "wavy_t",
		"well_rounded", "where_is_matt", "whirlwind", "wiggle", "windmill_floss", "work_it",
		"work_it_out", "worm", "yay", "you_are_awesome", "zany", "zombified_still"
	},
	Other = {
		"0_to_100", "arona_dance", "badger_dance", "badger_snake_dance", "bubbletop",
		"car_shearer_dance", "caramelldansen", "chika_riley", "club_penguin_dance", "dao_ankha_dance",
		"dao_dr_livesey_walk_back", "dao_dr_livesey_walk_front", "dao_dr_livesey_walk_mid", "distraction_dance",
		"francium_mmd", "friday_night", "gentleman", "get_down", "head_spin", "internet_yamero",
		"jack_o_pose", "kami_dance", "laydown_lying_back", "laydown_prone", "laydown_sit",
		"lethal_company_dance", "lights_camera_action", "macarena_dance", "malo_mart_dance", "naruto_run",
		"omae_wa_mou", "over_the_top", "rickroll", "shake_it", "shoulder_shake", "simp_walk",
		"skibidi_pa_pa_pa", "specialist", "super_animal_royale_dance", "take_on_me", "toca_toca",
		"toothless_dance", "twerk", "who_put_you_on_the_planet", "zufolo_impazzito_dance"
	},
	MoCap = {
		"breaking", "choreography", "fast_movement_test_1", "fast_movement_test_2", "fast_movement_test_3",
		"freestyle_1", "freestyle_2", "freestyle_3", "freestyle_4", "freestyle_5", "freestyle_6",
		"freestyle_7", "freestyle_8", "freestyle_9", "freestyle_10", "freestyle_11", "freestyle_12",
		"freestyle_13", "freestyle_14", "freestyle_15", "freestyle_16", "freestyle_17", "freestyle_18",
		"freestyle_19", "hip_hop", "house_dance", "locking", "medusa_intro", "popping",
		"soft_bounce_1", "soft_bounce_2", "soft_bounce_3", "soft_bounce_4", "soft_bounce_5",
		"soft_bounce_6", "soft_bounce_7", "soft_bounce_8", "soft_bounce_9", "soft_bounce_10",
		"soft_bounce_11", "soft_bounce_12", "soft_bounce_13", "soft_bounce_14", "soft_bounce_15",
		"soft_bounce_16", "soft_bounce_17"
	},
	TF2 = {
		"all_aerobic", "demoman_aerobic", "demoman_conga", "demoman_russian", "engineer_aerobic",
		"engineer_conga", "engineer_russian", "heavy_aerobic", "heavy_conga", "heavy_russian",
		"medic_aerobic", "medic_conga", "medic_russian", "pyro_aerobic", "pyro_conga",
		"pyro_russian", "scout_aerobic", "scout_conga", "scout_russian", "sniper_aerobic",
		"sniper_conga", "sniper_russian", "soldier_aerobic", "soldier_conga", "soldier_russian",
		"spy_aerobic", "spy_conga", "spy_russian"
	}
}

local VALID = {}
for _, list in pairs(CATALOG) do
	for i = 1, #list do
		VALID[list[i]] = true
	end
end

local selected, configFrame = {}, nil

local function AnimLabel(name)
	return string.NiceName(string.gsub(name, "_", " "))
end

local function SaveSelected()
	while #selected > MAX_ANIMS do
		selected[#selected] = nil
	end
	file.Write("hg_wos_anims.txt", table.concat(selected, "\n"))
end

do
	if file.Exists("hg_wos_anims.txt", "DATA") then
		for _, name in ipairs(string.Explode("\n", file.Read("hg_wos_anims.txt", "DATA") or "")) do
			name = string.Trim(name)
			if VALID[name] and not table.HasValue(selected, name) then
				selected[#selected + 1] = name
			end
		end
	elseif file.Exists("wos_anim_wheel_config.txt", "DATA") then
		local cfg = util.JSONToTable(file.Read("wos_anim_wheel_config.txt", "DATA") or "")
		if cfg and istable(cfg.WheelAnimations) then
			for i = 1, #cfg.WheelAnimations do
				local name = cfg.WheelAnimations[i]
				if VALID[name] and not table.HasValue(selected, name) then
					selected[#selected + 1] = name
				end
			end
		end
	end
	SaveSelected()
end

local function PaintCRT(x, y, w, h, lit)
	surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, 230)
	surface.DrawRect(x, y, w, h)

	local ix, iy, iw, ih = x + 3, y + 3, w - 6, h - 6
	surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, lit and 200 or 150)
	surface.DrawOutlinedRect(ix, iy, iw, ih, 1)

	local a = lit and 230 or 150
	surface.SetDrawColor(CRT_R, CRT_G, CRT_B, a)
	surface.DrawRect(ix, iy, 10, 2)
	surface.DrawRect(ix, iy, 2, 10)
	surface.DrawRect(ix + iw - 10, iy, 10, 2)
	surface.DrawRect(ix + iw - 2, iy, 2, 10)
	surface.DrawRect(ix, iy + ih - 2, 10, 2)
	surface.DrawRect(ix, iy + ih - 10, 2, 10)
	surface.DrawRect(ix + iw - 10, iy + ih - 2, 10, 2)
	surface.DrawRect(ix + iw - 2, iy + ih - 10, 2, 10)

	surface.SetDrawColor(color_panel.r, color_panel.g, color_panel.b, 210)
	surface.DrawRect(ix + 1, iy + 1, iw - 2, ih - 2)
end

local function PaintButton(self, w, h)
	PaintCRT(0, 0, w, h, self:IsHovered() or self:IsDown())
end

local function PaintBox(_, w, h)
	surface.SetDrawColor(color_panel.r, color_panel.g, color_panel.b, 220)
	surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, 150)
	surface.DrawOutlinedRect(0, 0, w, h)
end

local function MakeButton(parent, text, dock, wide, click)
	local btn = vgui.Create("DButton", parent)
	btn:SetText(text)
	btn:SetFont("HomigradFontSmall")
	btn:SetTextColor(color_text)
	btn:SetTall(28)
	if dock then btn:Dock(dock) end
	if wide then btn:SetWide(wide) end
	btn.Paint = PaintButton
	btn.DoClick = click
	return btn
end

local function StyleList(list)
	list:SetMultiSelect(false)
	list.Paint = PaintBox
	local addLine = list.AddLine
	function list:AddLine(...)
		local line = addLine(self, ...)
		for _, col in ipairs(line.Columns or {}) do
			col:SetTextColor(color_text)
		end
		line.Paint = function(s, w, h)
			if s:IsSelected() or s:IsHovered() then
				surface.SetDrawColor(CRT_R, CRT_G, CRT_B, s:IsSelected() and 40 or 22)
				surface.DrawRect(0, 0, w, h)
			end
		end
		return line
	end
end

local function OpenConfig()
	if IsValid(configFrame) then
		configFrame:Remove()
		return
	end

	local frame = vgui.Create("DFrame")
	frame:SetSize(math.min(820, ScrW() * 0.8), math.min(520, ScrH() * 0.8))
	frame:Center()
	frame:MakePopup()
	frame:SetTitle("")
	frame:ShowCloseButton(false)
	frame.Paint = function(self, w, h)
		if hg.DrawBlur then hg.DrawBlur(self, 5) end
		PaintCRT(0, 0, w, h, true)
		draw.SimpleText("ANIMATIONS", "HomigradFontMedium", 16, 14, color_accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText("Double-click to add - " .. #selected .. " / " .. MAX_ANIMS, "HomigradFontSmall", 16, 36, color_idle, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
	configFrame = frame
	frame.OnRemove = function() configFrame = nil end

	MakeButton(frame, "X", nil, 32, function() frame:Remove() end):SetPos(frame:GetWide() - 42, 10)

	local body = vgui.Create("DPanel", frame)
	body:Dock(FILL)
	body:DockMargin(12, 48, 12, 12)
	body.Paint = nil

	local left = vgui.Create("DPanel", body)
	left:Dock(LEFT)
	left:SetWide(260)
	left:DockMargin(0, 0, 10, 0)
	left.Paint = PaintBox

	local catLabel = vgui.Create("DLabel", left)
	catLabel:SetText("Categories")
	catLabel:SetFont("HomigradFontSmall")
	catLabel:SetTextColor(color_text)
	catLabel:Dock(TOP)
	catLabel:DockMargin(10, 10, 10, 4)

	local categoryList = vgui.Create("DListView", left)
	categoryList:Dock(TOP)
	categoryList:SetTall(110)
	categoryList:DockMargin(8, 0, 8, 8)
	categoryList:AddColumn("Category")
	StyleList(categoryList)

	local animLabel = vgui.Create("DLabel", left)
	animLabel:SetText("Available")
	animLabel:SetFont("HomigradFontSmall")
	animLabel:SetTextColor(color_text)
	animLabel:Dock(TOP)
	animLabel:DockMargin(10, 0, 10, 4)

	local animList = vgui.Create("DListView", left)
	animList:Dock(FILL)
	animList:DockMargin(8, 0, 8, 8)
	animList:AddColumn("Animation")
	StyleList(animList)

	local right = vgui.Create("DPanel", body)
	right:Dock(FILL)
	right.Paint = PaintBox

	local wheelLabel = vgui.Create("DLabel", right)
	wheelLabel:SetText("On radial")
	wheelLabel:SetFont("HomigradFontSmall")
	wheelLabel:SetTextColor(color_text)
	wheelLabel:Dock(TOP)
	wheelLabel:DockMargin(10, 10, 10, 4)

	local buttons = vgui.Create("DPanel", right)
	buttons:Dock(BOTTOM)
	buttons:SetTall(28)
	buttons:DockMargin(8, 0, 8, 8)
	buttons.Paint = nil

	local wheelList = vgui.Create("DListView", right)
	wheelList:Dock(FILL)
	wheelList:DockMargin(8, 0, 8, 8)
	wheelList:AddColumn("Animation")
	StyleList(wheelList)

	local function RefreshWheel()
		wheelList:Clear()
		for i = 1, #selected do
			wheelList:AddLine(AnimLabel(selected[i])).AnimName = selected[i]
		end
	end

	MakeButton(buttons, "Remove", LEFT, 120, function()
		local _, line = wheelList:GetSelectedLine()
		if not line then return end
		table.RemoveByValue(selected, line.AnimName)
		SaveSelected()
		RefreshWheel()
	end):DockMargin(0, 0, 8, 0)

	MakeButton(buttons, "Clear", LEFT, 90, function()
		selected = {}
		SaveSelected()
		RefreshWheel()
	end)

	MakeButton(buttons, "Stop", RIGHT, 90, function()
		RunConsoleCommand("wos_uap", "stop")
	end)

	for _, cat in ipairs({"Fortnite", "Other", "MoCap", "TF2"}) do
		categoryList:AddLine(cat .. " (" .. #CATALOG[cat] .. ")").Category = cat
	end

	categoryList.OnRowSelected = function(_, _, row)
		animList:Clear()
		local anims = CATALOG[row.Category] or {}
		for i = 1, #anims do
			animList:AddLine(AnimLabel(anims[i])).AnimName = anims[i]
		end
	end

	animList.DoDoubleClick = function(_, _, row)
		local name = row.AnimName
		if not name or table.HasValue(selected, name) then return end
		if #selected >= MAX_ANIMS then
			surface.PlaySound("buttons/button10.wav")
			return
		end
		selected[#selected + 1] = name
		SaveSelected()
		RefreshWheel()
		surface.PlaySound("buttons/button15.wav")
	end

	RefreshWheel()
	categoryList:SelectFirstItem()
end

hook.Add("radialOptions", "HG_WOS_Anims", function()
	if not cvEnable:GetBool() then return end
	local ply = lply or LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return end
	if ply.organism and ply.organism.otrub then return end

	local opts = {}
	local max = math.min(#selected, MAX_ANIMS)
	for i = 1, max do
		local name = selected[i]
		opts[i] = {
			function() RunConsoleCommand("wos_uap", name) end,
			AnimLabel(name)
		}
	end
	opts[#opts + 1] = {
		function() RunConsoleCommand("wos_uap", "stop") end,
		"Stop"
	}

	hg.radialOptions[#hg.radialOptions + 1] = {
		function(mouseClick)
			if mouseClick == 1 then
				if max > 0 then
					RunConsoleCommand("wos_uap", selected[math.random(max)])
				end
			else
				hg.CreateRadialMenu(opts)
			end
		end,
		"Animations\nRMB - Menu"
	}
end)

hook.Add("PlayerBindPress", "HG_WOS_Anims", function(ply, bind, pressed)
	if not pressed or not string.find(bind, "gm_showspare1", 1, true) then return end
	if not cvEnable:GetBool() then return end
	if ply ~= LocalPlayer() or ply:IsTyping() then return end
	OpenConfig()
	return true
end)

cvars.AddChangeCallback("hg_wos_animmenus", function(_, _, val)
	if val == "0" and IsValid(configFrame) then configFrame:Remove() end
end, "HG_WOS_Anims")

hook.Add("InitPostEntity", "HG_WOS_Anims", function()
	hook.Add("PlayerBindPress", "wOS.TFTaunts.TFTauntMenu", function() end)
	hook.Add("HUDPaint", "wOS.TF2Taunts.ShowMenu", function() end)
end)
