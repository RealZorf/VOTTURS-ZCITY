hg = hg or {}
hg.Keybinds = hg.Keybinds or {}

local Keybinds = hg.Keybinds
local STORAGE_DIRECTORY = "zcity"
local STORAGE_PATH = STORAGE_DIRECTORY .. "/keybinds.json"
local PROFILE_STORAGE_PATH = STORAGE_DIRECTORY .. "/keybind_profiles.json"
local LEGACY_PATH = "zcity_keybinds.txt"
local MAX_BIND_SLOTS = 2
local MAX_SAVED_PROFILES = 12
local MAX_PROFILE_NAME_LENGTH = 28

local function IsPlayerFake(ply)
	if not IsValid(ply) then return false end
	return IsValid(ply.FakeRagdoll) or IsValid(ply:GetNWEntity("FakeRagdoll", NULL))
end

local function HasSearchableFakeTarget(ply)
	if not IsPlayerFake(ply) or not hg.eyeTrace then return false end

	local trace = hg.eyeTrace(ply, 60)
	if not trace then return false end

	local function isSearchable(ent)
		if not IsValid(ent) or ent == ply then return false end

		local owner = hg.RagdollOwner and hg.RagdollOwner(ent)
		if IsValid(owner) then
			if owner == ply then return false end
			ent = owner
		end

		if ent:IsPlayer() then return ent ~= ply end
		return ent:GetNetVar("Inventory") ~= nil
	end

	if isSearchable(trace.Entity) then return true end
	if not isvector(trace.HitPos) then return false end

	for _, ent in ipairs(ents.FindInSphere(trace.HitPos, 40)) do
		if isSearchable(ent) then return true end
	end

	return false
end

local COLOR = {
	background = Color(5, 10, 8, 232),
	panel = Color(5, 17, 11, 218),
	panelStrong = Color(3, 14, 8, 244),
	panelSoft = Color(8, 24, 15, 210),
	row = Color(5, 22, 13, 224),
	rowHover = Color(8, 38, 21, 238),
	accent = Color(35, 255, 110),
	accentSoft = Color(35, 255, 110, 80),
	accentFaint = Color(35, 255, 110, 28),
	text = Color(232, 242, 235),
	textDim = Color(132, 161, 143),
	warning = Color(255, 190, 48),
	danger = Color(235, 68, 68),
}

local ACTIONS = {
	{
		id = "kick",
		group = "COMBAT",
		title = "Kick",
		description = "Perform a standing or jumping kick.",
		command = "hg_kick",
		mode = "press",
		default = KEY_H,
	},
	{
		id = "laser",
		group = "COMBAT",
		title = "Toggle Weapon Laser",
		description = "Toggle the active weapon's laser attachment.",
		command = "hmcd_togglelaser",
		mode = "press",
		default = KEY_NONE,
	},
	{
		id = "breath",
		group = "COMBAT",
		title = "Hold Breath",
		description = "Steady breathing while the key remains held.",
		command = "+hmcd_holdbreath",
		release = "-hmcd_holdbreath",
		mode = "hold",
		default = KEY_NONE,
	},
	{
		id = "fake",
		group = "RAGDOLL",
		title = "Ragdoll / Stand Up",
		description = "Enter fake or attempt to stand back up.",
		command = "fake",
		mode = "press",
		default = KEY_G,
	},
	{
		id = "control_head",
		group = "RAGDOLL",
		title = "Control Head",
		description = "Control your head while ragdolled.",
		mode = "hold",
		context = "fake",
		inputBits = IN_USE,
		default = KEY_E,
	},
	{
		id = "left_arm_reach",
		group = "RAGDOLL",
		title = "Reach Left Arm",
		description = "Extend and steer your left arm while ragdolled.",
		mode = "hold",
		context = "fake",
		inputBits = IN_ATTACK,
		default = MOUSE_LEFT,
	},
	{
		id = "right_arm_reach",
		group = "RAGDOLL",
		title = "Reach Right Arm",
		description = "Extend and steer your right arm while ragdolled.",
		mode = "hold",
		context = "fake",
		inputBits = IN_ATTACK2,
		default = MOUSE_RIGHT,
	},
	{
		id = "left_hand",
		group = "RAGDOLL",
		title = "Left Hand Grab",
		description = "Close and grip with your left hand while ragdolled.",
		mode = "hold",
		context = "fake",
		inputBits = IN_SPEED,
		default = KEY_LSHIFT,
	},
	{
		id = "right_hand",
		group = "RAGDOLL",
		title = "Right Hand Grab",
		description = "Close and grip with your right hand while ragdolled.",
		mode = "hold",
		context = "fake",
		inputBits = IN_WALK,
		default = KEY_LALT,
	},
	{
		id = "search_loot",
		group = "INTERACTION",
		title = "Search / Loot",
		description = "Search the aimed body or container while standing or ragdolled.",
		mode = "hold",
		canActivate = function(ply)
			return not IsPlayerFake(ply) or HasSearchableFakeTarget(ply)
		end,
		getInputBits = function(ply)
			if IsPlayerFake(ply) then return bit.bor(IN_WALK, IN_SPEED) end
			return bit.bor(IN_ATTACK2, IN_USE)
		end,
		getClearInputBits = function(ply)
			if IsPlayerFake(ply) then return bit.bor(IN_ATTACK, IN_ATTACK2) end
		end,
		default = {MOUSE_RIGHT, KEY_E},
	},
	{
		id = "special_interaction",
		group = "INTERACTION",
		title = "Special Interaction",
		description = "Use role abilities and contextual special interactions.",
		mode = "hold",
		inputBits = bit.bor(IN_WALK, IN_USE),
		default = {KEY_LALT, KEY_E},
	},
	{
		id = "weapon_butt",
		group = "INTERACTION",
		title = "Weapon Butt",
		description = "Strike with the held weapon's close-range butt attack.",
		mode = "hold",
		context = "standing",
		inputBits = bit.bor(IN_USE, IN_ATTACK),
		default = {KEY_E, MOUSE_LEFT},
	},
	{
		id = "suicide",
		group = "CHARACTER",
		title = "Suicide / Cancel",
		description = "Prepare or cancel suicide with a supported weapon.",
		command = "suicide",
		mode = "press",
		default = KEY_NONE,
	},
	{
		id = "gesture",
		group = "CHARACTER",
		title = "Random Gesture",
		description = "Perform a random available hand gesture.",
		command = "hg_randomgesture",
		mode = "press",
		default = KEY_NONE,
	},
	{
		id = "drop_weapon",
		group = "EQUIPMENT",
		title = "Drop Weapon",
		description = "Drop the weapon currently held in your hands.",
		command = "drop",
		mode = "press",
		default = KEY_NONE,
	},
	{
		id = "inspect_weapon",
		group = "EQUIPMENT",
		title = "Inspect Weapon",
		description = "Inspect the active weapon when it supports inspection.",
		command = "hg_inspect",
		mode = "press",
		default = KEY_NONE,
	},
	{
		id = "lean_left",
		group = "MOVEMENT AND VIEW",
		title = "Lean Left",
		description = "Lean left while the key remains held.",
		command = "+alt1",
		release = "-alt1",
		mode = "hold",
		default = KEY_NONE,
	},
	{
		id = "lean_right",
		group = "MOVEMENT AND VIEW",
		title = "Lean Right",
		description = "Lean right while the key remains held.",
		command = "+alt2",
		release = "-alt2",
		mode = "hold",
		default = KEY_NONE,
	},
	{
		id = "free_look",
		group = "MOVEMENT AND VIEW",
		title = "Look Around",
		description = "Move your view independently while held.",
		command = "+altlook",
		release = "-altlook",
		mode = "hold",
		default = KEY_NONE,
	},
	{
		id = "zoom",
		group = "MOVEMENT AND VIEW",
		title = "Camera Zoom",
		description = "Use the focused camera zoom while held.",
		command = "+hg_zoom",
		release = "-hg_zoom",
		mode = "hold",
		context = "standing",
		default = {KEY_LALT, MOUSE_RIGHT},
	},
}

local GROUPS = {
	"COMBAT",
	"INTERACTION",
	"RAGDOLL",
	"CHARACTER",
	"EQUIPMENT",
	"MOVEMENT AND VIEW",
}

local actionByKey = {}
local actionByID = {}
for _, action in ipairs(ACTIONS) do
	action.bindKey = action.command or action.id
	actionByKey[action.bindKey] = action
	actionByID[action.id] = action
end

local fontWidth
local fontHeight

local function Scale(value)
	local scale = math.Clamp(math.min(ScrW() / 1920, ScrH() / 1080), 0.9, 1.15)
	return math.Round(value * scale)
end

local function CreateFonts()
	if fontWidth == ScrW() and fontHeight == ScrH() then return end

	fontWidth = ScrW()
	fontHeight = ScrH()

	surface.CreateFont("ZC_KB_Title", {
		font = "Bahnschrift",
		size = Scale(38),
		weight = 800,
		extended = true,
	})

	surface.CreateFont("ZC_KB_Section", {
		font = "Bahnschrift",
		size = Scale(18),
		weight = 800,
		extended = true,
	})

	surface.CreateFont("ZC_KB_RowTitle", {
		font = "Bahnschrift",
		size = Scale(22),
		weight = 700,
		extended = true,
	})

	surface.CreateFont("ZC_KB_Body", {
		font = "Bahnschrift",
		size = Scale(16),
		weight = 500,
		extended = true,
	})

	surface.CreateFont("ZC_KB_Small", {
		font = "Bahnschrift",
		size = Scale(13),
		weight = 700,
		extended = true,
	})

	surface.CreateFont("ZC_KB_Key", {
		font = "Bahnschrift",
		size = Scale(17),
		weight = 800,
		extended = true,
	})
end

local function DrawCutPanel(x, y, w, h, cut, fillColor, borderColor)
	cut = math.min(cut or 8, w * 0.25, h * 0.25)

	local points = {
		{x = x + cut, y = y},
		{x = x + w - cut, y = y},
		{x = x + w, y = y + cut},
		{x = x + w, y = y + h - cut},
		{x = x + w - cut, y = y + h},
		{x = x + cut, y = y + h},
		{x = x, y = y + h - cut},
		{x = x, y = y + cut},
	}

	draw.NoTexture()
	surface.SetDrawColor(fillColor)
	surface.DrawPoly(points)
	surface.SetDrawColor(borderColor)

	local inset = 1
	local left = x + inset
	local top = y + inset
	local right = x + w - inset - 1
	local bottom = y + h - inset - 1
	local borderCut = math.max(1, cut - inset)
	local borderPoints = {
		{x = left + borderCut, y = top},
		{x = right - borderCut, y = top},
		{x = right, y = top + borderCut},
		{x = right, y = bottom - borderCut},
		{x = right - borderCut, y = bottom},
		{x = left + borderCut, y = bottom},
		{x = left, y = bottom - borderCut},
		{x = left, y = top + borderCut},
	}

	for index = 1, #borderPoints do
		local nextIndex = index == #borderPoints and 1 or index + 1
		surface.DrawLine(borderPoints[index].x, borderPoints[index].y, borderPoints[nextIndex].x, borderPoints[nextIndex].y)
	end
end

local FRIENDLY_KEYS = {
	[MOUSE_LEFT] = "LMB",
	[MOUSE_RIGHT] = "RMB",
	[MOUSE_MIDDLE] = "MMB",
	[KEY_LSHIFT] = "LSHIFT",
	[KEY_RSHIFT] = "RSHIFT",
	[KEY_LALT] = "LALT",
	[KEY_RALT] = "RALT",
	[KEY_LCONTROL] = "LCTRL",
	[KEY_RCONTROL] = "RCTRL",
	[KEY_SPACE] = "SPACE",
}

local function IsValidKey(key)
	key = tonumber(key)
	if not key or key <= KEY_NONE or key ~= math.floor(key) then return false end
	return input.GetKeyName(key) ~= nil
end

local function NormaliseChord(source)
	if isnumber(source) then source = {source} end
	if not istable(source) then return {} end

	local chord = {}
	local used = {}
	for _, rawKey in ipairs(source) do
		local key = tonumber(rawKey)
		if IsValidKey(key) then
			key = math.floor(key)
			if not used[key] then
				used[key] = true
				chord[#chord + 1] = key
			end
		end
	end

	return chord
end

local function DefaultSlots(action)
	local chord = NormaliseChord(action.default)
	return {chord, {}}
end

local function FreshDefaults()
	local binds = {}
	for _, action in ipairs(ACTIONS) do
		binds[action.bindKey] = DefaultSlots(action)
	end
	return binds
end

local function SanitiseBinds(source)
	local binds = FreshDefaults()
	if not istable(source) then return binds end

	for _, action in ipairs(ACTIONS) do
		local saved = source[action.bindKey]
		if saved == nil and action.command then saved = source[action.command] end
		if saved == nil then continue end

		local slots = {{}, {}}
		if isnumber(saved) or (istable(saved) and isnumber(saved[1])) then
			slots[1] = NormaliseChord(saved)
		elseif istable(saved) then
			for slot = 1, MAX_BIND_SLOTS do
				slots[slot] = NormaliseChord(saved[slot])
			end
		end
		binds[action.bindKey] = slots
	end

	return binds
end

local function SanitiseProfileName(value)
	local name = string.Trim(tostring(value or ""))
	name = string.gsub(name, "[%c]", "")
	name = string.gsub(name, "%s+", " ")

	return string.sub(name, 1, MAX_PROFILE_NAME_LENGTH)
end

local function ReadSavedProfiles()
	local raw = file.Read(PROFILE_STORAGE_PATH, "DATA")
	if not raw then return {} end

	local decoded = util.JSONToTable(raw)
	local source = istable(decoded) and (decoded.profiles or decoded) or nil
	if not istable(source) then return {} end

	local profiles = {}
	local usedNames = {}
	for _, saved in ipairs(source) do
		if not istable(saved) then continue end

		local name = SanitiseProfileName(saved.name)
		local nameKey = string.lower(name)
		if name == "" or usedNames[nameKey] then continue end

		usedNames[nameKey] = true
		profiles[#profiles + 1] = {
			name = name,
			binds = SanitiseBinds(saved.binds),
			savedAt = math.max(0, tonumber(saved.savedAt) or 0),
		}

		if #profiles >= MAX_SAVED_PROFILES then break end
	end

	table.sort(profiles, function(a, b)
		if a.savedAt == b.savedAt then return string.lower(a.name) < string.lower(b.name) end
		return a.savedAt > b.savedAt
	end)

	return profiles
end

local function ReadSavedBinds()
	local raw = file.Read(STORAGE_PATH, "DATA")
	local migrated = false

	if not raw and file.Exists(LEGACY_PATH, "DATA") then
		raw = file.Read(LEGACY_PATH, "DATA")
		migrated = raw ~= nil
	end

	if not raw then return FreshDefaults(), false end

	local decoded = util.JSONToTable(raw)
	if not istable(decoded) then return FreshDefaults(), false end
	migrated = migrated or decoded.version ~= 2

	return SanitiseBinds(decoded.binds or decoded), migrated
end

Keybinds.Views = Keybinds.Views or setmetatable({}, {__mode = "k"})
Keybinds.Binds, Keybinds.MigratedLegacy = ReadSavedBinds()
Keybinds.Profiles = ReadSavedProfiles()

function Keybinds.Save()
	file.CreateDir(STORAGE_DIRECTORY)
	file.Write(STORAGE_PATH, util.TableToJSON({version = 2, binds = Keybinds.Binds}, true))
end

local function RefreshViews()
	for view in pairs(Keybinds.Views) do
		if IsValid(view) and view.RefreshBinds then view:RefreshBinds() end
	end
end

local function SaveProfiles()
	file.CreateDir(STORAGE_DIRECTORY)
	file.Write(PROFILE_STORAGE_PATH, util.TableToJSON({version = 1, profiles = Keybinds.Profiles}, true))
end

local activeHeld = {}
local actionStates = {}

function Keybinds.ReleaseHeld()
	for id, state in pairs(activeHeld) do
		RunConsoleCommand(state.release)
		activeHeld[id] = nil
	end
	table.Empty(actionStates)
end

function Keybinds.Assign(bindKey, slot, chord)
	local action = actionByKey[bindKey]
	if not action or slot < 1 or slot > MAX_BIND_SLOTS then return false end
	chord = NormaliseChord(chord)
	Keybinds.ReleaseHeld()
	Keybinds.Binds[bindKey] = Keybinds.Binds[bindKey] or {{}, {}}
	Keybinds.Binds[bindKey][slot] = chord
	Keybinds.Save()
	RefreshViews()

	return true
end

function Keybinds.Reset()
	if IsValid(Keybinds.ActiveCapture) and Keybinds.ActiveCapture.CancelCapture then Keybinds.ActiveCapture:CancelCapture() end
	Keybinds.ReleaseHeld()
	Keybinds.Binds = FreshDefaults()
	Keybinds.Save()
	RefreshViews()
end

function Keybinds.Clear()
	if IsValid(Keybinds.ActiveCapture) and Keybinds.ActiveCapture.CancelCapture then Keybinds.ActiveCapture:CancelCapture() end
	Keybinds.ReleaseHeld()

	for _, action in ipairs(ACTIONS) do
		Keybinds.Binds[action.bindKey] = {{}, {}}
	end

	Keybinds.Save()
	RefreshViews()
end

function Keybinds.SaveProfile(name)
	name = SanitiseProfileName(name)
	if name == "" then return false, "Enter a profile name first." end

	local profile
	local nameKey = string.lower(name)
	for _, saved in ipairs(Keybinds.Profiles) do
		if string.lower(saved.name) == nameKey then
			profile = saved
			break
		end
	end

	if not profile then
		if #Keybinds.Profiles >= MAX_SAVED_PROFILES then
			return false, "Profile limit reached. Delete one first."
		end

		profile = {}
		Keybinds.Profiles[#Keybinds.Profiles + 1] = profile
	end

	profile.name = name
	profile.binds = SanitiseBinds(Keybinds.Binds)
	profile.savedAt = os.time()
	table.sort(Keybinds.Profiles, function(a, b)
		if a.savedAt == b.savedAt then return string.lower(a.name) < string.lower(b.name) end
		return a.savedAt > b.savedAt
	end)
	SaveProfiles()

	return true, "Saved " .. name .. ".", profile
end

function Keybinds.LoadProfile(name)
	local nameKey = string.lower(SanitiseProfileName(name))
	for _, profile in ipairs(Keybinds.Profiles) do
		if string.lower(profile.name) ~= nameKey then continue end

		if IsValid(Keybinds.ActiveCapture) and Keybinds.ActiveCapture.CancelCapture then Keybinds.ActiveCapture:CancelCapture() end
		Keybinds.ReleaseHeld()
		Keybinds.Binds = SanitiseBinds(profile.binds)
		Keybinds.Save()
		RefreshViews()

		return true, "Loaded " .. profile.name .. ".", profile
	end

	return false, "Select a saved profile first."
end

function Keybinds.DeleteProfile(name)
	local nameKey = string.lower(SanitiseProfileName(name))
	for index, profile in ipairs(Keybinds.Profiles) do
		if string.lower(profile.name) ~= nameKey then continue end

		table.remove(Keybinds.Profiles, index)
		SaveProfiles()
		return true, "Deleted " .. profile.name .. "."
	end

	return false, "Select a saved profile first."
end

local function InputIsBlocked()
	if gui.IsGameUIVisible() or vgui.CursorVisible() then return true end
	return IsValid(vgui.GetKeyboardFocus())
end

local function IsActionContextValid(action, ply)
	local fake = IsPlayerFake(ply)
	if action.context == "fake" and not fake then return false end
	if action.context == "standing" and fake then return false end
	return true
end

local function IsChordDown(chord)
	if not chord or #chord == 0 then return false end
	for _, key in ipairs(chord) do
		if not input.IsButtonDown(key) then return false end
	end
	return true
end

local function IsChordSubset(smaller, larger)
	if #smaller >= #larger then return false end
	local keys = {}
	for _, key in ipairs(larger) do keys[key] = true end
	for _, key in ipairs(smaller) do
		if not keys[key] then return false end
	end
	return true
end

local function GetActiveChord(action)
	local slots = Keybinds.Binds[action.bindKey]
	if not slots then return nil end

	local best
	for slot = 1, MAX_BIND_SLOTS do
		local chord = slots[slot]
		if IsChordDown(chord) and (not best or #chord > #best) then best = chord end
	end
	return best
end

local FAKE_HAND_INPUT_BITS = bit.bor(bit.bor(IN_ATTACK, IN_ATTACK2), bit.bor(IN_SPEED, IN_WALK))

hook.Add("CreateMove", "ZC_Keybinds_Runtime", function(cmd)
	local ply = LocalPlayer()
	if not IsValid(ply) or InputIsBlocked() then
		if next(actionStates) ~= nil or next(activeHeld) ~= nil then Keybinds.ReleaseHeld() end
		return
	end

	local matches = {}
	for _, action in ipairs(ACTIONS) do
		if IsActionContextValid(action, ply) then
			local chord = GetActiveChord(action)
			if chord and (not action.canActivate or action.canActivate(ply)) then
				matches[#matches + 1] = {action = action, chord = chord}
			end
		end
	end

	for _, match in ipairs(matches) do
		for _, other in ipairs(matches) do
			if match ~= other and IsChordSubset(match.chord, other.chord) then
				match.suppressed = true
				break
			end
		end
	end

	local activeNow = {}
	local buttons = cmd:GetButtons()
	if IsPlayerFake(ply) then
		buttons = bit.band(buttons, bit.bnot(FAKE_HAND_INPUT_BITS))
	end

	for _, match in ipairs(matches) do
		if match.suppressed then continue end
		local action = match.action
		activeNow[action.id] = true

		local inputBits = action.getInputBits and action.getInputBits(ply) or action.inputBits
		local clearInputBits = action.getClearInputBits and action.getClearInputBits(ply)
		if clearInputBits then buttons = bit.band(buttons, bit.bnot(clearInputBits)) end
		if inputBits then buttons = bit.bor(buttons, inputBits) end

		if action.command and not actionStates[action.id] then
			RunConsoleCommand(action.command)
			if action.mode == "hold" and action.release then
				activeHeld[action.id] = {release = action.release}
			end
		end
	end
	cmd:SetButtons(buttons)

	for _, action in ipairs(ACTIONS) do
		if actionStates[action.id] and not activeNow[action.id] and activeHeld[action.id] then
			RunConsoleCommand(activeHeld[action.id].release)
			activeHeld[action.id] = nil
		end
		actionStates[action.id] = activeNow[action.id] or nil
	end
end)

hook.Add("ShutDown", "ZC_Keybinds_Release", Keybinds.ReleaseHeld)
hook.Add("OnPauseMenuShow", "ZC_Keybinds_Release", Keybinds.ReleaseHeld)
hook.Add("OnSpawnMenuOpen", "ZC_Keybinds_Release", Keybinds.ReleaseHeld)
hook.Add("OnContextMenuOpen", "ZC_Keybinds_Release", Keybinds.ReleaseHeld)

if Keybinds.MigratedLegacy then Keybinds.Save() end

concommand.Add("zc_keybinds_reset", function()
	Keybinds.Reset()
	chat.AddText(COLOR.accent, "[Keybinds] ", COLOR.text, "Default controls restored.")
end)

concommand.Add("zc_keybinds_clear", function()
	Keybinds.Clear()
	chat.AddText(COLOR.accent, "[Keybinds] ", COLOR.text, "Custom controls cleared.")
end)

concommand.Add("zc_keybinds_dump", function()
	MsgC(COLOR.accent, "[Z-City Keybinds]\n")
	for _, action in ipairs(ACTIONS) do
		local slots = Keybinds.Binds[action.bindKey] or {{}, {}}
		local labels = {}
		for slot = 1, MAX_BIND_SLOTS do
			local names = {}
			for _, key in ipairs(slots[slot] or {}) do names[#names + 1] = FRIENDLY_KEYS[key] or string.upper(input.GetKeyName(key) or "?") end
			labels[slot] = #names > 0 and table.concat(names, " + ") or "NOT SET"
		end
		MsgC(COLOR.text, action.title, COLOR.textDim, " -> ", COLOR.accent, table.concat(labels, " / "), COLOR.textDim, " (", action.bindKey, ")\n")
	end
end)

local function StyleScrollBar(scrollPanel)
	local bar = scrollPanel:GetVBar()
	bar:SetWide(Scale(7))
	bar.Paint = function(_, w, h)
		surface.SetDrawColor(0, 0, 0, 100)
		surface.DrawRect(0, 0, w, h)
	end
	bar.btnUp.Paint = function() end
	bar.btnDown.Paint = function() end
	bar.btnGrip.Paint = function(_, w, h)
		draw.RoundedBox(0, 1, 0, w - 2, h, COLOR.accentSoft)
	end
end

local function GetAssignedCount()
	local assigned = 0

	for _, action in ipairs(ACTIONS) do
		local slots = Keybinds.Binds[action.bindKey]
		if slots and ((slots[1] and #slots[1] > 0) or (slots[2] and #slots[2] > 0)) then assigned = assigned + 1 end
	end

	return assigned
end

local function FormatChord(chord)
	if not chord or #chord == 0 then return "NOT SET" end
	local names = {}
	for _, key in ipairs(chord) do
		names[#names + 1] = FRIENDLY_KEYS[key] or string.upper(input.GetKeyName(key) or "?")
	end
	return table.concat(names, " + ")
end

function Keybinds.GetDisplayBinding(actionID, fallback)
	local action = actionByID[actionID]
	if not action then return fallback or "NOT SET" end

	local slots = Keybinds.Binds and Keybinds.Binds[action.bindKey]
	if not slots then slots = DefaultSlots(action) end

	local labels = {}
	for slot = 1, MAX_BIND_SLOTS do
		local chord = slots[slot]
		if chord and #chord > 0 then
			labels[#labels + 1] = FormatChord(chord)
		end
	end

	return #labels > 0 and table.concat(labels, " / ") or "NOT SET"
end

function Keybinds.ResolveDisplayText(value)
	if not isstring(value) then return value end

	local text = value
	local special = Keybinds.GetDisplayBinding("special_interaction", "LALT + E")
	local search = Keybinds.GetDisplayBinding("search_loot", "RMB + E")
	local weaponButt = Keybinds.GetDisplayBinding("weapon_butt", "E + LMB")

	text = string.gsub(text, "%f[%a]ALT%s*%+%s*E%f[^%a]", function() return special end)
	text = string.gsub(text, "%f[%a]RMB%s*%+%s*E%f[^%a]", function() return search end)
	text = string.gsub(text, "%f[%a]E%s*%+%s*LMB%f[^%a]", function() return weaponButt end)

	return text
end

hg.GetKeybindDisplay = Keybinds.GetDisplayBinding
hg.ResolveKeybindText = Keybinds.ResolveDisplayText

local CAPTURE_BUTTON_LAST = MOUSE_LAST or MOUSE_WHEEL_DOWN or 113

local function CreateCaptureButton(parent, action, slot)
	local button = vgui.Create("DButton", parent)
	button:SetText("")
	button:SetTooltip("Click, hold a key combination, then release. Right-click to clear this slot.")
	button.Capturing = false
	button.Captured = {}
	button.CapturedSet = {}
	button.CaptureDown = {}
	button.CaptureArmed = false

	function button:CancelCapture()
		self.Capturing = false
		table.Empty(self.Captured)
		table.Empty(self.CapturedSet)
		table.Empty(self.CaptureDown)
		self.CaptureArmed = false
		if Keybinds.ActiveCapture == self then Keybinds.ActiveCapture = nil end
	end

	function button:FinishCapture(chord)
		local captured = table.Copy(chord or {})
		self:CancelCapture()
		Keybinds.Assign(action.bindKey, slot, captured)
	end

	button.DoClick = function(self)
		if self.Capturing then return end

		if IsValid(Keybinds.ActiveCapture) and Keybinds.ActiveCapture ~= self then
			Keybinds.ActiveCapture:CancelCapture()
		end

		Keybinds.ActiveCapture = self
		self.Capturing = true
		table.Empty(self.Captured)
		table.Empty(self.CapturedSet)
		table.Empty(self.CaptureDown)
		self.CaptureArmed = false
	end

	button.DoRightClick = function(self)
		if self.Capturing then return end

		self:CancelCapture()
		Keybinds.Assign(action.bindKey, slot, {})
	end

	button.Think = function(self)
		if not self.Capturing then return end

		if not self.CaptureArmed then
			if input.IsButtonDown(MOUSE_LEFT) then return end
			self.CaptureArmed = true
		end

		for key = 1, CAPTURE_BUTTON_LAST do
			local down = input.IsButtonDown(key)
			local wasDown = self.CaptureDown[key] == true

			if down and not wasDown then
				if key == KEY_ESCAPE then
					self:CancelCapture()
					return
				end

				if key == KEY_BACKSPACE or key == KEY_DELETE then
					self:FinishCapture({})
					return
				end

				if IsValidKey(key) and not self.CapturedSet[key] and #self.Captured < 3 then
					self.CapturedSet[key] = true
					self.Captured[#self.Captured + 1] = key
				end
			end

			self.CaptureDown[key] = down or nil
		end

		if #self.Captured == 0 then return end

		for _, key in ipairs(self.Captured) do
			if input.IsButtonDown(key) then return end
		end

		self:FinishCapture(self.Captured)
	end

	button.Paint = function(self, w, h)
		local capturing = self.Capturing
		local border = capturing and COLOR.warning or (self:IsHovered() and COLOR.accent or COLOR.accentSoft)
		local fill = capturing and Color(255, 190, 48, 12) or COLOR.panelStrong
		DrawCutPanel(0, 0, w, h, Scale(6), fill, border)

		local slots = Keybinds.Binds[action.bindKey] or {{}, {}}
		local chord = slots[slot] or {}
		local label = capturing and (#self.Captured > 0 and FormatChord(self.Captured) or "HOLD COMBO") or FormatChord(chord)
		local textColor = capturing and COLOR.warning or (#chord > 0 and COLOR.text or COLOR.textDim)
		draw.SimpleText(label, #label > 15 and "ZC_KB_Small" or "ZC_KB_Key", w * 0.5, h * 0.5, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	button.OnRemove = function(self)
		self:CancelCapture()
	end

	return button
end

local function CreateActionRow(parent, action, view)
	local row = vgui.Create("DPanel", parent)
	row:Dock(TOP)
	row:DockMargin(0, 0, Scale(8), Scale(10))
	row:SetTall(Scale(88))
	row.Action = action
	view.Rows[action.bindKey] = row

	row.Paint = function(self, w, h)
		local hovered = self:IsHovered() or self.PrimaryButton:IsHovered() or self.SecondaryButton:IsHovered() or self.ClearButton:IsHovered()
		DrawCutPanel(0, 0, w, h, Scale(8), hovered and COLOR.rowHover or COLOR.row, hovered and COLOR.accentSoft or COLOR.accentFaint)
		surface.SetDrawColor(COLOR.accent)
		surface.DrawRect(0, Scale(13), Scale(4), h - Scale(26))

		draw.SimpleText(action.title, "ZC_KB_RowTitle", Scale(20), Scale(14), COLOR.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText(action.description, "ZC_KB_Body", Scale(20), Scale(51), COLOR.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

		local modeText = action.mode == "hold" and "HOLD" or "PRESS"
		local badgeX = w - Scale(438)
		DrawCutPanel(badgeX, Scale(29), Scale(68), Scale(30), Scale(5), COLOR.panelStrong, COLOR.accentFaint)
		draw.SimpleText(modeText, "ZC_KB_Small", badgeX + Scale(34), Scale(44), COLOR.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local clear = vgui.Create("DButton", row)
	row.ClearButton = clear
	clear:SetSize(Scale(42), Scale(44))
	clear:SetText("")
	clear:SetTooltip("Clear this keybind")
	clear.Paint = function(self, w, h)
		local color = self:IsHovered() and COLOR.danger or COLOR.textDim
		DrawCutPanel(0, 0, w, h, Scale(5), Color(0, 0, 0, 90), Color(color.r, color.g, color.b, 150))
		draw.SimpleText("X", "ZC_KB_Key", w * 0.5, h * 0.5, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	clear.DoClick = function()
		Keybinds.Assign(action.bindKey, 1, {})
		Keybinds.Assign(action.bindKey, 2, {})
	end

	local primary = CreateCaptureButton(row, action, 1)
	local secondary = CreateCaptureButton(row, action, 2)
	row.PrimaryButton = primary
	row.SecondaryButton = secondary
	primary:SetSize(Scale(146), Scale(44))
	secondary:SetSize(Scale(146), Scale(44))

	row.PerformLayout = function(_, w)
		clear:SetPos(w - Scale(54), Scale(22))
		secondary:SetPos(w - Scale(210), Scale(22))
		primary:SetPos(w - Scale(366), Scale(22))
	end

	return row
end

local function CreateActionList(parent, view)
	local scroll = vgui.Create("DScrollPanel", parent)
	scroll:Dock(FILL)
	scroll:DockMargin(Scale(24), Scale(14), Scale(16), Scale(20))
	StyleScrollBar(scroll)

	for _, group in ipairs(GROUPS) do
		local heading = vgui.Create("DPanel", scroll)
		heading:Dock(TOP)
		heading:DockMargin(0, Scale(4), Scale(8), Scale(7))
		heading:SetTall(Scale(38))
		heading.Paint = function(_, w, h)
			draw.SimpleText(group, "ZC_KB_Section", 0, h * 0.5, COLOR.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			local primaryCenter = w - Scale(293)
			local secondaryCenter = w - Scale(137)
			local labelGap = Scale(38)
			local lineY = math.floor(h * 0.5)
			surface.SetFont("ZC_KB_Section")
			local titleWidth = surface.GetTextSize(group)
			local lineStart = titleWidth + Scale(16)
			local lineEnd = w - Scale(4)

			surface.SetDrawColor(COLOR.accentSoft)
			if primaryCenter - labelGap > lineStart then surface.DrawLine(lineStart, lineY, primaryCenter - labelGap, lineY) end
			if secondaryCenter - labelGap > primaryCenter + labelGap then surface.DrawLine(primaryCenter + labelGap, lineY, secondaryCenter - labelGap, lineY) end
			if lineEnd > secondaryCenter + labelGap then surface.DrawLine(secondaryCenter + labelGap, lineY, lineEnd, lineY) end
			draw.SimpleText("BIND 1", "ZC_KB_Small", primaryCenter, h * 0.5, COLOR.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("BIND 2", "ZC_KB_Small", secondaryCenter, h * 0.5, COLOR.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		for _, action in ipairs(ACTIONS) do
			if action.group == group then CreateActionRow(scroll, action, view) end
		end
	end

	return scroll
end

local function CreateCommandButton(parent, label, color, callback)
	local button = vgui.Create("DButton", parent)
	button:SetText("")
	button:SetTall(Scale(38))
	button.Paint = function(self, w, h)
		local border = self:IsHovered() and color or Color(color.r, color.g, color.b, 95)
		local fill = self:IsHovered() and Color(color.r, color.g, color.b, 20) or Color(0, 0, 0, 80)
		DrawCutPanel(0, 0, w, h, Scale(6), fill, border)
		draw.SimpleText(label, "ZC_KB_Small", w * 0.5, h * 0.5, self:IsHovered() and color or COLOR.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	button.DoClick = callback

	return button
end

local function CountAssignedBinds(binds)
	local assigned = 0
	for _, action in ipairs(ACTIONS) do
		local slots = binds and binds[action.bindKey]
		if slots and ((slots[1] and #slots[1] > 0) or (slots[2] and #slots[2] > 0)) then assigned = assigned + 1 end
	end

	return assigned
end

local function CreateSavedProfilesPanel(parent)
	local panel = vgui.Create("DPanel", parent)
	panel:Dock(TOP)
	panel:DockMargin(0, Scale(9), 0, 0)
	panel:SetTall(Scale(224))
	panel.SelectedName = nil
	panel.StatusText = "Profiles are stored locally on this computer."
	panel.StatusColor = COLOR.textDim

	panel.Paint = function(self, w, h)
		DrawCutPanel(0, 0, w, h, Scale(10), COLOR.panel, COLOR.accentFaint)
		draw.SimpleText("SAVED PROFILES", "ZC_KB_Section", Scale(20), Scale(16), COLOR.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText(#Keybinds.Profiles .. " / " .. MAX_SAVED_PROFILES, "ZC_KB_Small", w - Scale(20), Scale(20), COLOR.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		draw.SimpleText("Keep separate layouts for different play styles.", "ZC_KB_Small", Scale(20), Scale(43), COLOR.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText(self.StatusText, "ZC_KB_Small", Scale(20), h - Scale(17), self.StatusColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	function panel:SetStatus(text, color)
		self.StatusText = text
		self.StatusColor = color or COLOR.textDim
	end

	local nameEntry = vgui.Create("DTextEntry", panel)
	nameEntry:SetFont("ZC_KB_Body")
	nameEntry:SetTextColor(COLOR.text)
	nameEntry:SetHighlightColor(COLOR.accentSoft)
	nameEntry:SetCursorColor(COLOR.accent)
	nameEntry:SetPlaceholderText("Profile name")
	if nameEntry.SetPlaceholderColor then nameEntry:SetPlaceholderColor(COLOR.textDim) end
	nameEntry:SetDrawBackground(false)
	if nameEntry.SetMaximumCharCount then nameEntry:SetMaximumCharCount(MAX_PROFILE_NAME_LENGTH) end
	nameEntry.Paint = function(self, w, h)
		DrawCutPanel(0, 0, w, h, Scale(5), COLOR.panelStrong, self:HasFocus() and COLOR.accent or COLOR.accentFaint)
		self:DrawTextEntryText(COLOR.text, COLOR.accent, COLOR.text)
	end

	local saveButton
	saveButton = CreateCommandButton(panel, "SAVE CURRENT", COLOR.accent, function()
		local ok, message, profile = Keybinds.SaveProfile(nameEntry:GetValue())
		panel:SetStatus(message, ok and COLOR.accent or COLOR.warning)
		if not ok then return end

		panel.SelectedName = profile.name
		nameEntry:SetText(profile.name)
		panel:RebuildProfiles()
	end)
	nameEntry.OnEnter = function() saveButton:DoClick() end

	local list = vgui.Create("DScrollPanel", panel)
	StyleScrollBar(list)

	local loadButton = CreateCommandButton(panel, "LOAD", COLOR.accent, function()
		local ok, message, profile = Keybinds.LoadProfile(panel.SelectedName)
		panel:SetStatus(message, ok and COLOR.accent or COLOR.warning)
		if ok and profile then nameEntry:SetText(profile.name) end
	end)

	local deleteButton = CreateCommandButton(panel, "DELETE", COLOR.danger, function()
		local ok, message = Keybinds.DeleteProfile(panel.SelectedName)
		panel:SetStatus(message, ok and COLOR.textDim or COLOR.warning)
		if not ok then return end

		panel.SelectedName = nil
		nameEntry:SetText("")
		panel:RebuildProfiles()
	end)

	function panel:RebuildProfiles()
		local canvas = list:GetCanvas()
		for _, child in ipairs(canvas:GetChildren()) do child:Remove() end

		local selectedStillExists = false
		for _, profile in ipairs(Keybinds.Profiles) do
			local savedProfile = profile
			if savedProfile.name == self.SelectedName then selectedStillExists = true end

			local row = vgui.Create("DButton", list)
			row:Dock(TOP)
			row:DockMargin(0, 0, Scale(5), Scale(5))
			row:SetTall(Scale(34))
			row:SetText("")
			row.Paint = function(button, w, h)
				local selected = panel.SelectedName == savedProfile.name
				local border = selected and COLOR.accent or (button:IsHovered() and COLOR.accentSoft or COLOR.accentFaint)
				local fill = selected and Color(35, 255, 110, 16) or COLOR.panelStrong
				DrawCutPanel(0, 0, w, h, Scale(5), fill, border)
				draw.SimpleText(savedProfile.name, "ZC_KB_Body", Scale(12), h * 0.5, selected and COLOR.text or COLOR.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				draw.SimpleText(CountAssignedBinds(savedProfile.binds) .. " / " .. #ACTIONS, "ZC_KB_Small", w - Scale(12), h * 0.5, selected and COLOR.accent or COLOR.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			end
			row.DoClick = function()
				panel.SelectedName = savedProfile.name
				nameEntry:SetText(savedProfile.name)
				panel:SetStatus("Selected " .. savedProfile.name .. ".", COLOR.textDim)
			end
		end

		if self.SelectedName and not selectedStillExists then self.SelectedName = nil end
		if #Keybinds.Profiles > 0 then return end

		local empty = vgui.Create("DLabel", list)
		empty:Dock(TOP)
		empty:SetTall(Scale(38))
		empty:SetFont("ZC_KB_Body")
		empty:SetTextColor(COLOR.textDim)
		empty:SetContentAlignment(5)
		empty:SetText("No saved profiles yet")
	end

	panel.PerformLayout = function(_, w)
		local margin = Scale(20)
		local gap = Scale(7)
		local saveWidth = Scale(112)
		nameEntry:SetPos(margin, Scale(60))
		nameEntry:SetSize(w - margin * 2 - gap - saveWidth, Scale(34))
		saveButton:SetPos(w - margin - saveWidth, Scale(60))
		saveButton:SetSize(saveWidth, Scale(34))

		list:SetPos(margin, Scale(101))
		list:SetSize(w - margin * 2, Scale(60))

		local buttonWidth = math.floor((w - margin * 2 - gap) * 0.5)
		loadButton:SetPos(margin, Scale(169))
		loadButton:SetSize(buttonWidth, Scale(34))
		deleteButton:SetPos(margin + buttonWidth + gap, Scale(169))
		deleteButton:SetSize(buttonWidth, Scale(34))
	end

	panel:RebuildProfiles()

	return panel
end

local function CreateInformationPanel(parent)
	local info = vgui.Create("DPanel", parent)
	info:Dock(RIGHT)
	info:DockMargin(0, Scale(14), Scale(24), Scale(20))
	info:SetWide(math.Clamp(Scale(382), 344, 440))
	info.Paint = function() end

	local profile = vgui.Create("DPanel", info)
	profile:Dock(TOP)
	profile:SetTall(Scale(236))
	profile.Paint = function(_, w, h)
		local assigned = GetAssignedCount()
		local completion = assigned / math.max(1, #ACTIONS)

		DrawCutPanel(0, 0, w, h, Scale(10), COLOR.panel, COLOR.accentFaint)
		draw.SimpleText("QUICK SETUP", "ZC_KB_Section", Scale(20), Scale(18), COLOR.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText("MAKE THESE CONTROLS YOUR OWN", "ZC_KB_Small", Scale(20), Scale(44), COLOR.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText(assigned .. " / " .. #ACTIONS .. " ASSIGNED", "ZC_KB_Small", w - Scale(20), Scale(22), COLOR.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

		surface.SetDrawColor(COLOR.accentFaint)
		surface.DrawRect(Scale(20), Scale(65), w - Scale(40), 1)
		surface.DrawRect(Scale(20), Scale(77), w - Scale(40), Scale(7))
		surface.SetDrawColor(COLOR.accent)
		surface.DrawRect(Scale(20), Scale(77), math.floor((w - Scale(40)) * completion), Scale(7))

		local steps = {
			{"1", "CHOOSE AN ACTION", "Select either binding slot."},
			{"2", "PRESS YOUR KEYS", "Use one key or hold a full chord."},
			{"3", "RETURN TO PLAY", "Your changes are already active."},
		}

		for index, step in ipairs(steps) do
			local y = Scale(96) + (index - 1) * Scale(44)
			surface.SetDrawColor(index % 2 == 1 and COLOR.panelSoft or COLOR.panelStrong)
			surface.DrawRect(Scale(13), y, w - Scale(26), Scale(38))
			DrawCutPanel(Scale(20), y + Scale(4), Scale(30), Scale(30), Scale(5), COLOR.panelStrong, COLOR.accentSoft)
			draw.SimpleText(step[1], "ZC_KB_Key", Scale(35), y + Scale(19), COLOR.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText(step[2], "ZC_KB_Small", Scale(64), y + Scale(4), COLOR.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			draw.SimpleText(step[3], "ZC_KB_Small", Scale(64), y + Scale(20), COLOR.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end
	end

	local shortcutsPanel = vgui.Create("DPanel", info)
	shortcutsPanel:Dock(TOP)
	shortcutsPanel:DockMargin(0, Scale(9), 0, 0)
	shortcutsPanel:SetTall(Scale(218))
	shortcutsPanel.Paint = function(_, w, h)
		DrawCutPanel(0, 0, w, h, Scale(10), COLOR.panel, COLOR.accentFaint)
		draw.SimpleText("YOUR KEY CONTROLS", "ZC_KB_Section", Scale(20), Scale(18), COLOR.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		surface.SetDrawColor(COLOR.accentFaint)
		surface.DrawRect(Scale(20), Scale(54), w - Scale(40), 1)

		local controls = {
			{"RAGDOLL", "fake", "Enter or stand up"},
			{"KICK", "kick", "Kick someone/something"},
			{"SEARCH / LOOT", "search_loot", "Bodies and containers"},
			{"SPECIAL", "special_interaction", "Contextual actions"},
		}

		local y = Scale(62)
		for index, control in ipairs(controls) do
			local rowY = y + (index - 1) * Scale(37)
			surface.SetDrawColor(index % 2 == 1 and COLOR.panelSoft or COLOR.panelStrong)
			surface.DrawRect(Scale(12), rowY, w - Scale(24), Scale(33))

			local binding = Keybinds.GetDisplayBinding(control[2])
			local bindingColor = binding == "NOT SET" and COLOR.warning or COLOR.accent

			draw.SimpleText(control[1], "ZC_KB_Small", Scale(20), rowY + Scale(5), COLOR.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			draw.SimpleText(control[3], "ZC_KB_Small", Scale(20), rowY + Scale(19), COLOR.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

			surface.SetFont("ZC_KB_Small")
			local bindingW = math.max(Scale(72), surface.GetTextSize(binding) + Scale(22))
			DrawCutPanel(w - Scale(20) - bindingW, rowY + Scale(4), bindingW, Scale(25), Scale(4), COLOR.panelStrong, Color(bindingColor.r, bindingColor.g, bindingColor.b, 125))
			draw.SimpleText(binding, "ZC_KB_Small", w - Scale(20) - bindingW * 0.5, rowY + Scale(16), bindingColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	local controls = vgui.Create("DPanel", info)
	controls:Dock(TOP)
	controls:DockMargin(0, Scale(9), 0, 0)
	controls:SetTall(Scale(112))
	controls.Paint = function(_, w, h)
		DrawCutPanel(0, 0, w, h, Scale(10), COLOR.panel, COLOR.accentFaint)
		draw.SimpleText("PROFILE OPTIONS", "ZC_KB_Section", Scale(20), Scale(16), COLOR.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText("Start fresh or return to the recommended layout.", "ZC_KB_Small", Scale(20), Scale(43), COLOR.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	local reset = CreateCommandButton(controls, "RESTORE DEFAULTS", COLOR.accent, Keybinds.Reset)
	local clearAll = CreateCommandButton(controls, "CLEAR PROFILE", COLOR.danger, Keybinds.Clear)

	controls.PerformLayout = function(_, w)
		local gap = Scale(7)
		local buttonWidth = math.floor((w - Scale(40) - gap) * 0.5)
		reset:SetPos(Scale(20), Scale(66))
		reset:SetSize(buttonWidth, Scale(34))
		clearAll:SetPos(Scale(20) + buttonWidth + gap, Scale(66))
		clearAll:SetSize(buttonWidth, Scale(34))
	end

	CreateSavedProfilesPanel(info)

	return info
end

function hg.DrawKeybinds(parent)
	if not IsValid(parent) then return end

	CreateFonts()
	Keybinds.ReleaseHeld()

	parent:SetAlpha(0)
	parent.Paint = function(_, w, h)
		surface.SetDrawColor(COLOR.background)
		surface.DrawRect(0, 0, w, h)

		local grid = Scale(88)
		surface.SetDrawColor(255, 255, 255, 2)
		for x = 0, w, grid do surface.DrawRect(x, 0, 1, h) end
		for y = 0, h, grid do surface.DrawRect(0, y, w, 1) end
	end
	parent:AlphaTo(255, 0.15, 0)

	local view = vgui.Create("DPanel", parent)
	view:Dock(FILL)
	view.Paint = function() end
	view.Rows = {}
	Keybinds.Views[view] = true

	function view:RefreshBinds()
		for _, row in pairs(self.Rows) do
			if IsValid(row) then row:InvalidateLayout() end
		end
	end

	local header = vgui.Create("DPanel", view)
	header:Dock(TOP)
	header:DockMargin(Scale(24), Scale(20), Scale(24), 0)
	header:SetTall(Scale(92))
	header.Paint = function(_, w, h)
		draw.SimpleText("Z-CITY KEYBINDS", "ZC_KB_Title", 0, Scale(2), COLOR.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText("BUILD A CUSTOM CONTROL LAYOUT THAT FEELS NATURAL", "ZC_KB_Small", 0, Scale(58), COLOR.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		surface.SetDrawColor(COLOR.accentSoft)
		surface.DrawRect(0, h - 1, w, 1)
	end

	local body = vgui.Create("DPanel", view)
	body:Dock(FILL)
	body.Paint = function() end

	local information = CreateInformationPanel(body)
	CreateActionList(body, view)
	body.PerformLayout = function(_, w)
		information:SetVisible(w >= Scale(1160))
	end
	view:RefreshBinds()
end
