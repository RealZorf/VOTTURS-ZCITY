local lowGraphics = CreateClientConVar("hg_low_graphics", "0", true, false, "Force Source engine to lowest quality and enable lighter Homigrad effects", 0, 1)
local multicore = CreateClientConVar("hg_multicore", "0", true, false, "Use extra CPU threads for rendering. Can crash", 0, 1)

local MISSING = "__missing__"
local lowPrefix = "hg_lowgfx_"
local mcorePrefix = "hg_mcore_"

local lowGraphicsProfile = {
	r_shadows = 0,
	r_3dsky = 0,
	r_drawdetailprops = 0,
	cl_detaildist = 0,
	cl_detailfade = 0,
	mat_disable_bloom = 1,
	mat_picmip = 4,
	r_rootlod = 2,
	mat_forceaniso = 0,
	mat_reducefillrate = 1,
	mat_bumpmap = 0,
	mat_specular = 0,
	mat_filtertextures = 0,
	mat_mipmaptextures = 0,
	r_waterforceexpensive = 0,
	r_waterforcereflectentities = 0,
	r_flashlightdepthtexture = 0,
	props_break_max_pieces = 0,
	hg_potatopc = 1,
	hg_shells_enable = 0,
	hg_weaponshotblur_enable = 0,
	hg_optimise_scopes = 2,
	vfire_enable_glows = 0,
	vfire_enable_lights = 0,
	vfire_lod = 2,
	hg_anims_draw_distance = 128,
	hg_anim_fps = 12,
	hg_attachment_draw_distance = 128,
	hg_maxsmoketrails = 0,
	hg_blood_fps = 12
}

local multicoreProfile = {
	gmod_mcore_test = 1,
	mat_queue_mode = -1,
	cl_threaded_bone_setup = 1,
	r_threaded_renderables = 1,
	r_threaded_particles = 1,
	r_queued_ropes = 1
}

local function applyProfile(profile, prefix, on)
	local pending = false

	for name, value in pairs(profile) do
		local convar = GetConVar(name)
		if not convar then
			pending = on
			continue
		end

		local key = prefix .. name
		if on then
			if cookie.GetString(key, MISSING) == MISSING then
				cookie.Set(key, convar:GetString())
			end
			RunConsoleCommand(name, tostring(value))
		else
			local old = cookie.GetString(key, MISSING)
			if old ~= MISSING then
				RunConsoleCommand(name, old)
				cookie.Delete(key)
			end
		end
	end

	return pending
end

local function applyAll()
	local pending = applyProfile(lowGraphicsProfile, lowPrefix, lowGraphics:GetBool())
	pending = applyProfile(multicoreProfile, mcorePrefix, multicore:GetBool()) or pending

	if pending then
		timer.Create("HG.GraphicsProfiles", 0.5, 20, applyAll)
	else
		timer.Remove("HG.GraphicsProfiles")
	end
end

cvars.AddChangeCallback("hg_low_graphics", function()
	timer.Simple(0, applyAll)
end, "HG.LowGraphics")

cvars.AddChangeCallback("hg_multicore", function()
	timer.Simple(0, applyAll)
end, "HG.Multicore")

hook.Add("InitPostEntity", "HG.GraphicsProfiles", applyAll)
timer.Simple(0, applyAll)
