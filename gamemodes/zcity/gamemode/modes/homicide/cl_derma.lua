local MODE = MODE

local CRT_R, CRT_G, CRT_B = 35, 225, 110
local TRAITOR_R, TRAITOR_G, TRAITOR_B = 225, 35, 35
local FRAME_R, FRAME_G, FRAME_B = 86, 94, 90
local color_idle_dim = Color(112, 118, 116)
local color_bezel = Color(12, 13, 13)
local color_panel = Color(20, 22, 21)
local color_text = Color(236, 238, 236)
local color_gold = Color(220, 175, 55)
local color_danger = Color(TRAITOR_R, TRAITOR_G, TRAITOR_B)
local color_live = Color(CRT_R, CRT_G, CRT_B)
local BEZEL = 3
local INSET = BEZEL + 4
local SND_CLICK = "shitty/tap_depress.wav"
local SND_HOVER = "shitty/tap-resonant.wav"
local GEAR_FILE = "zcity/hmcd_traitor_gear.json"
local RANDOM_FILE = "zcity/hmcd_traitor_random.json"
local ROW_H = 64

local function S(n)
	return math.max(1, math.Round(n * ScrH() / 1080))
end

local function CreateFonts()
	surface.CreateFont("ZC_MM_Header", {font = "Bahnschrift", size = math.max(18, S(22)), weight = 700, antialias = true, extended = true})
	surface.CreateFont("ZC_MM_Tiny", {font = "Bahnschrift", size = math.max(12, S(15)), weight = 500, antialias = true, extended = true})
	surface.CreateFont("ZC_MM_Button", {font = "Bahnschrift", size = math.max(16, S(22)), weight = 600, antialias = true, extended = true})
end
CreateFonts()
hook.Add("OnScreenSizeChanged", "HMCD_TraitorMenu_Fonts", CreateFonts)

local function ClickSound(path)
	local ply = LocalPlayer()
	if IsValid(ply) then ply:EmitSound(path, 75, 100, 0.09) else surface.PlaySound(path) end
end

local function DrawTraitorFrame(x, y, w, h)
	surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, 230)
	surface.DrawRect(x, y, w, h)

	local ix, iy, iw, ih = x + BEZEL, y + BEZEL, w - BEZEL * 2, h - BEZEL * 2
	surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, 200)
	surface.DrawOutlinedRect(ix, iy, iw, ih, 1)

	surface.SetDrawColor(TRAITOR_R, TRAITOR_G, TRAITOR_B, 230)
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
	surface.SetDrawColor(TRAITOR_R, TRAITOR_G, TRAITOR_B, 6)
	for gx = 0, math.ceil(pw / step) do
		surface.DrawRect(px + gx * step - ox, py, 2, ph)
	end
	for gy = 0, math.ceil(ph / step) do
		surface.DrawRect(px, py + gy * step - ox + step, pw, 2)
	end
end

local function PaintScroll(scroll)
	local bar = scroll:GetVBar()
	bar:SetWide(S(8))
	bar:SetHideButtons(true)
	bar.Paint = function(_, w, h)
		surface.SetDrawColor(0, 0, 0, 70)
		surface.DrawRect(1, 0, w - 2, h)
	end
	bar.btnGrip.Paint = function(self, w, h)
		local hover = self:IsHovered()
		surface.SetDrawColor(hover and TRAITOR_R or FRAME_R, hover and TRAITOR_G or FRAME_G, hover and TRAITOR_B or FRAME_B, hover and 180 or 130)
		surface.DrawRect(1, 0, w - 2, h)
	end
end

local function paintBox(w, h, r, g, b, fill, outline)
	surface.SetDrawColor(color_bezel)
	surface.DrawRect(0, 0, w, h)
	if fill then
		surface.SetDrawColor(r, g, b, fill)
		surface.DrawRect(1, 1, w - 2, h - 2)
	end
	surface.SetDrawColor(r, g, b, outline)
	surface.DrawOutlinedRect(0, 0, w, h, 1)
end

local iconCache = {}
local placeholderPool

local function usableIcon(icon)
	if isnumber(icon) then return icon > 0 end
	return icon and icon.IsError and not icon:IsError()
end

local function lookupIcon(item)
	if not item or item == "" then return end
	if iconCache[item] ~= nil then return iconCache[item] or nil end

	local stored = weapons.GetStored(item)
	local icon, square
	if stored then
		icon = stored.WepSelectIcon2 or stored.WepSelectIcon
		square = stored.WepSelectIcon2box
	end
	if not usableIcon(icon) then
		local ent = scripted_ents.GetStored(item)
		local path = ent and ent.t and ent.t.IconOverride
		if path and path ~= "" then
			icon = Material(path, "smooth")
			square = true
		end
	end
	if not usableIcon(icon) and stored and stored.IconOverride and stored.IconOverride ~= "" then
		icon = Material(stored.IconOverride, "smooth")
		square = true
	end
	if usableIcon(icon) and not isnumber(icon) then
		icon:SetInt("$flags", 32)
	end
	iconCache[item] = usableIcon(icon) and {icon = icon, square = square} or false
	return iconCache[item] or nil
end

local function placeholderIcons()
	if placeholderPool then return placeholderPool end
	placeholderPool = {}
	for _, gear in pairs(MODE.TraitorGear or {}) do
		for i = 1, #gear do
			for j = 1, #gear[i] do
				local info = lookupIcon(gear[i][j].item)
				if info then placeholderPool[#placeholderPool + 1] = info end
			end
		end
	end
	return placeholderPool
end

local function drawWepIcon(info, w, h)
	if not info then return end
	local icon = info.icon
	surface.SetDrawColor(255, 255, 255, 235)
	if isnumber(icon) then surface.SetTexture(icon) else surface.SetMaterial(icon) end
	local maxW, maxH = w - S(10), h - S(20)
	local iw, ih
	if info.square then
		ih = math.min(maxH, maxW)
		iw = ih
	else
		iw = math.min(maxW, maxH * 2)
		ih = iw * 0.5
	end
	surface.DrawTexturedRect((w - iw) * 0.5, S(4), iw, ih)
end

local function PaintChip(self, w, h, on, col, label)
	local hover = self:IsHovered()
	local r, g, b = on and col.r or FRAME_R, on and col.g or FRAME_G, on and col.b or FRAME_B
	paintBox(w, h, r, g, b, (on or hover) and (on and 36 or 18) or nil, (on or hover) and 210 or 130)
	draw.SimpleText(label, "ZC_MM_Tiny", w * 0.5, h * 0.5, on and color_text or color_idle_dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function addText(parent, text, font, col, top)
	if not text or text == "" then return end
	local pnl = vgui.Create("DPanel", parent)
	pnl.StackGap = top or 0
	pnl.Text = text
	pnl.Font = font
	pnl.Color = col
	pnl:SetPaintBackground(false)
	pnl:SetMouseInputEnabled(false)
	pnl.Paint = function(self, w, h)
		draw.DrawText(self.DrawText or self.Text, self.Font, 0, 0, self.Color, TEXT_ALIGN_LEFT)
	end
	function pnl:SetText(value) self.Text = value self.DrawText = nil end
	function pnl:SetTextColor(value) self.Color = value end
	return pnl
end

local randomExclude = {standard = {}, soe = {}}

local function writeRandomExclude()
	for _, key in ipairs({"standard", "soe"}) do
		local list = {}
		for role in pairs(randomExclude[key]) do
			list[#list + 1] = role
		end
		net.WriteUInt(math.min(#list, 32), 8)
		for i = 1, math.min(#list, 32) do
			net.WriteString(list[i])
		end
	end
end

local function syncTraitorRolePreferences()
	if not MODE.ConVar_SubRole_Traitor or not MODE.ConVar_SubRole_Traitor_SOE then return end
	net.Start("HMCD(SyncTraitorRolePreferences)")
		net.WriteString(MODE.ConVar_SubRole_Traitor:GetString())
		net.WriteString(MODE.ConVar_SubRole_Traitor_SOE:GetString())
		writeRandomExclude()
	net.SendToServer()
end

local preferenceSyncQueued = false
local function queueTraitorRolePreferenceSync()
	if preferenceSyncQueued then return end
	preferenceSyncQueued = true
	timer.Simple(0, function()
		preferenceSyncQueued = false
		syncTraitorRolePreferences()
	end)
end

local function set_role(role, mode)
	RunConsoleCommand(mode == "soe" and MODE.ConVarName_SubRole_Traitor_SOE or MODE.ConVarName_SubRole_Traitor, role)
	queueTraitorRolePreferenceSync()
end

local function installTraitorRolePreferenceSync()
	local standard_name = MODE.ConVarName_SubRole_Traitor
	local soe_name = MODE.ConVarName_SubRole_Traitor_SOE
	if not standard_name or not soe_name then return end
	cvars.RemoveChangeCallback(standard_name, "HMCD_SyncStandardTraitorRolePreference")
	cvars.RemoveChangeCallback(soe_name, "HMCD_SyncSOETraitorRolePreference")
	cvars.AddChangeCallback(standard_name, queueTraitorRolePreferenceSync, "HMCD_SyncStandardTraitorRolePreference")
	cvars.AddChangeCallback(soe_name, queueTraitorRolePreferenceSync, "HMCD_SyncSOETraitorRolePreference")
	queueTraitorRolePreferenceSync()
end

timer.Simple(0, installTraitorRolePreferenceSync)
hook.Add("InitPostEntity", "HMCD_SyncTraitorRolePreferences", function()
	installTraitorRolePreferenceSync()
	timer.Simple(2, queueTraitorRolePreferenceSync)
end)

local function randomToken(mode)
	return mode == "soe" and (MODE.SubRole_Traitor_Random_SOE or "traitor_random_soe") or (MODE.SubRole_Traitor_Random or "traitor_random")
end

local function currentRole(mode)
	return mode == "soe" and MODE.ConVar_SubRole_Traitor_SOE:GetString() or MODE.ConVar_SubRole_Traitor:GetString()
end

local function isRandom(mode)
	return currentRole(mode) == randomToken(mode)
end

local function roleExists(role, mode)
	if not role or role == "" or role == randomToken(mode) then return false end
	if role == (mode == "soe" and (MODE.SubRole_Traitor_Disabled_SOE or "traitor_disabled_soe") or (MODE.SubRole_Traitor_Disabled or "traitor_disabled")) then return false end
	local roles = MODE.RoleChooseRoundTypes and MODE.RoleChooseRoundTypes[mode == "soe" and "soe" or "standard"]
	return roles and roles.Traitor and roles.Traitor[role] == true
end

local lastRoleBeforeRandom = {}
local function setTraitorRolePreference(role, mode)
	if roleExists(role, mode) then lastRoleBeforeRandom[mode] = role end
	set_role(role, mode)
end

local function toggleRandom(mode)
	if isRandom(mode) then
		local restore = lastRoleBeforeRandom[mode]
		if not roleExists(restore, mode) then
			local round = MODE.RoleChooseRoundTypes and MODE.RoleChooseRoundTypes[mode == "soe" and "soe" or "standard"]
			restore = (round and round.TraitorDefaultRole) or (mode == "soe" and "traitor_default_soe" or "traitor_default")
		end
		setTraitorRolePreference(restore, mode)
		return
	end
	local cur = currentRole(mode)
	if roleExists(cur, mode) then lastRoleBeforeRandom[mode] = cur end
	set_role(randomToken(mode), mode)
end

MODE.HMCDTraitorRoleStats = MODE.HMCDTraitorRoleStats or {}

local function getTraitorRoleStats(role)
	role = MODE.NormalizeTraitorSubRole and MODE.NormalizeTraitorSubRole(role) or role
	local stats = role and MODE.HMCDTraitorRoleStats and MODE.HMCDTraitorRoleStats[role]
	return {
		wins = math.max(math.floor(tonumber(stats and stats.wins or 0) or 0), 0),
		games = math.max(math.floor(tonumber(stats and stats.games or 0) or 0), 0)
	}
end

local function combinedStats(a, b)
	local sa, sb = getTraitorRoleStats(a), getTraitorRoleStats(b)
	return {wins = sa.wins + sb.wins, games = sa.games + sb.games}
end

local function statText(stats)
	local games = stats and stats.games or 0
	if games <= 0 then return "No rounds yet" end
	local wins = stats.wins or 0
	local losses = math.max(games - wins, 0)
	return string.format("%d%% win rate out of %d rounds", math.Clamp(math.Round((wins / games) * 100), 0, 100), games),
		string.format("%d rounds played", games),
		string.format("%d%% win rate", math.Clamp(math.Round((wins / games) * 100), 0, 100)),
		string.format("%d%% lose rate", math.Clamp(math.Round((losses / games) * 100), 0, 100))
end

local function requestTraitorRoleStats(force)
	local now = SysTime()
	if not force and (MODE.HMCDTraitorRoleStatsNextRequest or 0) > now then return end
	MODE.HMCDTraitorRoleStatsNextRequest = now + 5
	net.Start("HMCD_RequestTraitorRoleStats")
	net.SendToServer()
end

net.Receive("HMCD_TraitorRoleStats", function()
	local count = net.ReadUInt(8)
	local stats = {}
	for _ = 1, count do
		local role = net.ReadString()
		role = MODE.NormalizeTraitorSubRole and MODE.NormalizeTraitorSubRole(role) or role
		local wins, games = net.ReadUInt(24), net.ReadUInt(24)
		if role and role ~= "" then stats[role] = {wins = wins, games = games} end
	end
	MODE.HMCDTraitorRoleStats = stats
	if IsValid(VGUI_HMCD_TraitorTileMenu) and VGUI_HMCD_TraitorTileMenu.RefreshStats then
		VGUI_HMCD_TraitorTileMenu:RefreshStats()
	end
end)

local localGear = {}
local function loadLocalGear()
	local t = util.JSONToTable(file.Read(GEAR_FILE, "DATA") or "")
	localGear = istable(t) and t or {}
end
loadLocalGear()

function MODE.GetLocalTraitorGear(role, slot)
	return localGear[role] and localGear[role][slot]
end

local function syncTraitorGear()
	local entries = {}
	for role, slots in pairs(localGear) do
		if istable(slots) then
			for slot, item in pairs(slots) do
				entries[#entries + 1] = {role, slot, item}
			end
		end
	end
	net.Start("HMCD(SyncTraitorGear)")
		net.WriteUInt(#entries, 16)
		for i = 1, #entries do
			net.WriteString(entries[i][1])
			net.WriteString(entries[i][2])
			net.WriteString(entries[i][3])
		end
	net.SendToServer()
end

local function setLocalTraitorGear(role, slot, item)
	localGear[role] = localGear[role] or {}
	localGear[role][slot] = item
	file.CreateDir("zcity")
	file.Write(GEAR_FILE, util.TableToJSON(localGear, true))
	syncTraitorGear()
end

local function loadRandomPool()
	local t = util.JSONToTable(file.Read(RANDOM_FILE, "DATA") or "")
	if not istable(t) then return end
	for _, key in ipairs({"standard", "soe"}) do
		randomExclude[key] = {}
		if istable(t[key]) then
			for role, excluded in pairs(t[key]) do
				if excluded then randomExclude[key][role] = true end
			end
		end
	end
end
loadRandomPool()

local function inRandomPool(role, mode)
	return role and not randomExclude[mode][role]
end

local function toggleRandomPool(role, mode)
	if not role then return end
	if randomExclude[mode][role] then
		randomExclude[mode][role] = nil
	else
		randomExclude[mode][role] = true
	end
	file.CreateDir("zcity")
	file.Write(RANDOM_FILE, util.TableToJSON(randomExclude, true))
	queueTraitorRolePreferenceSync()
end

hook.Add("InitPostEntity", "HMCD_SyncTraitorGear", function()
	timer.Simple(2, function()
		syncTraitorGear()
		queueTraitorRolePreferenceSync()
	end)
end)

local function collectTraitorRolePairs()
	local roundTypes = MODE.RoleChooseRoundTypes or {}
	local byBase = {}
	for role in pairs(roundTypes.standard and roundTypes.standard.Traitor or {}) do
		local base = string.gsub(role, "_soe$", "")
		byBase[base] = byBase[base] or {}
		byBase[base].standard = role
	end
	for role in pairs(roundTypes.soe and roundTypes.soe.Traitor or {}) do
		local base = string.gsub(role, "_soe$", "")
		byBase[base] = byBase[base] or {}
		byBase[base].soe = role
	end

	local roles = {}
	for base, pair in pairs(byBase) do
		local info = (pair.standard and MODE.SubRoles[pair.standard]) or (pair.soe and MODE.SubRoles[pair.soe])
		if info then
			local desc = info.Description or info.Objective or ""
			if hg.ResolveKeybindText then desc = hg.ResolveKeybindText(desc) end
			local stdObj = pair.standard and MODE.SubRoles[pair.standard] and MODE.SubRoles[pair.standard].Objective or ""
			local soeObj = pair.soe and MODE.SubRoles[pair.soe] and MODE.SubRoles[pair.soe].Objective or ""
			if hg.ResolveKeybindText then
				stdObj = hg.ResolveKeybindText(stdObj)
				soeObj = hg.ResolveKeybindText(soeObj)
			end
			roles[#roles + 1] = {
				Base = base,
				Name = info.Name or base,
				Description = desc,
				StandardObjective = stdObj,
				SOEObjective = soeObj,
				Standard = pair.standard,
				SOE = pair.soe
			}
		end
	end
	table.sort(roles, function(a, b)
		if a.Base == "traitor_default" then return true end
		if b.Base == "traitor_default" then return false end
		return string.lower(a.Name) < string.lower(b.Name)
	end)
	return roles
end

local function addGearRole(parent, title, role)
	local gear = MODE.TraitorGear and MODE.TraitorGear[role]
	if not gear or #gear == 0 then return end

	addText(parent, title, "ZC_MM_Header", color_text, S(10))

	local btnH = S(72)
	for start = 1, #gear, 3 do
		local last = math.min(start + 2, #gear)
		local maxOpts = 1
		for i = start, last do
			maxOpts = math.max(maxOpts, #gear[i])
		end

		local line = vgui.Create("DPanel", parent)
		line.StackGap = S(6)
		line:SetTall(S(28) + maxOpts * btnH + S(4) * (maxOpts - 1) + S(8))
		line:SetPaintBackground(false)
		line.PerformLayout = function(self, w)
			local gap = S(6)
			local colW = math.floor((w - gap * 2) / 3)
			local x = 0
			for _, col in ipairs(self:GetChildren()) do
				col:SetPos(x, 0)
				col:SetSize(colW, self:GetTall())
				x = x + colW + gap
			end
		end

		for i = start, last do
			local spec = gear[i]
			local col = vgui.Create("DPanel", line)
			col:SetPaintBackground(false)
			col.Paint = function(_, w, h)
				surface.SetDrawColor(32, 34, 33, 180)
				surface.DrawRect(0, 0, w, h)
				surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, 70)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
				draw.SimpleText(string.upper(spec.slot), "ZC_MM_Tiny", w * 0.5, S(6), color_idle_dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			end

			local y = S(24)
			for _, opt in ipairs(spec) do
				local btn = vgui.Create("DButton", col)
				btn:SetPos(S(6), y)
				btn:SetTall(btnH)
				btn.PerformLayout = function(self)
					self:SetWide(math.max(col:GetWide() - S(12), 1))
				end
				y = y + btnH + S(4)
				btn:SetText("")
				local locked = opt.placeholder or not opt.item
				local stored = opt.item and (weapons.GetStored(opt.item) or (scripted_ents.GetStored(opt.item) or {}).t)
				local label = (stored and stored.PrintName) or "PLACEHOLDER"
				local icon = lookupIcon(opt.item)
				if not icon then
					local pool = placeholderIcons()
					if #pool > 0 then icon = pool[math.random(#pool)] end
				end
				btn.Paint = function(self, w, h)
					local resolved = not locked and MODE.ResolveTraitorGearOption(nil, role, spec.slot)
					local sel = resolved and resolved.item == opt.item
					local hover = self:IsHovered()
					local r, g, b = locked and 90 or (sel and TRAITOR_R or FRAME_R), locked and 90 or (sel and TRAITOR_G or FRAME_G), locked and 90 or (sel and TRAITOR_B or FRAME_B)
					paintBox(w, h, r, g, b, (sel or (hover and not locked)) and (sel and 40 or 16) or nil, (sel or hover) and 210 or 120)
					drawWepIcon(icon, w, h)
					draw.SimpleText(label, "ZC_MM_Tiny", w * 0.5, h - S(8), locked and Color(140, 140, 140) or color_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
				if not locked then
					btn.OnCursorEntered = function() ClickSound(SND_HOVER) end
					btn.DoClick = function()
						ClickSound(SND_CLICK)
						setLocalTraitorGear(role, spec.slot, opt.item)
					end
				end
			end
		end
	end
end

local TILE = {}

function TILE:Init()
	self:SetTall(S(ROW_H))
	self:SetMouseInputEnabled(true)

	self.HeaderHit = vgui.Create("DButton", self)
	self.HeaderHit:SetText("")
	self.HeaderHit:SetCursor("hand")
	self.HeaderHit.Paint = function() end
	self.HeaderHit.DoClick = function()
		if IsValid(self.OwnerSelector) then self.OwnerSelector:SetExpandedRole(self.RoleData, true) end
	end

	self.StdButton = vgui.Create("DButton", self)
	self.SoeButton = vgui.Create("DButton", self)
	self.Expand = vgui.Create("DPanel", self)
	self.Expand:SetVisible(false)
	self.Expand:SetPaintBackground(false)
end

function TILE:SetupModeButton(button, label, mode, role)
	button:SetText("")
	button:SetEnabled(role ~= nil)
	button.DoClick = function()
		if not role then return end
		setTraitorRolePreference(role, mode)
		ClickSound(SND_CLICK)
	end
	button.OnCursorEntered = function() if role then ClickSound(SND_HOVER) end end
	button.Paint = function(btn, w, h)
		local selected = role and not isRandom(mode) and currentRole(mode) == role
		local hover = role and btn:IsHovered()
		local r, g, b = FRAME_R, FRAME_G, FRAME_B
		if selected then r, g, b = TRAITOR_R, TRAITOR_G, TRAITOR_B end
		paintBox(w, h, r, g, b, (selected or hover) and (selected and 40 or 16) or nil, (selected or hover) and 210 or 120)
		if label == "State of Emergency" then
			draw.SimpleText("State of", "ZC_MM_Tiny", w * 0.5, h * 0.32, role and color_text or color_idle_dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("Emergency", "ZC_MM_Tiny", w * 0.5, h * 0.68, role and color_text or color_idle_dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		else
			draw.SimpleText(label, "ZC_MM_Tiny", w * 0.5, h * 0.5, role and color_text or color_idle_dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
end

function TILE:SetRoleData(data)
	self.RoleData = data
	self:SetupModeButton(self.StdButton, "Standard", "standard", data.Standard)
	self:SetupModeButton(self.SoeButton, "State of Emergency", "soe", data.SOE)
end

function TILE:FillExpand()
	for _, child in ipairs(self.Expand:GetChildren()) do
		child:Remove()
	end

	local data = self.RoleData
	if not data then return end

	local summary, rounds, wins, losses = statText(combinedStats(data.Standard, data.SOE))
	local statCol = rounds and color_live or color_gold
	self.RoundLabel = addText(self.Expand, rounds or summary, "ZC_MM_Tiny", statCol, S(4))
	self.WinLabel = wins and addText(self.Expand, wins, "ZC_MM_Tiny", statCol, S(2)) or nil
	self.LoseLabel = losses and addText(self.Expand, losses, "ZC_MM_Tiny", statCol, S(2)) or nil

	local objective = data.StandardObjective ~= "" and data.StandardObjective or data.SOEObjective
	local description = data.Description or ""
	if description ~= "" and description == objective then description = "" end
	if description ~= "" then
		addText(self.Expand, description, "ZC_MM_Tiny", color_idle_dim, S(12))
	end
	if objective ~= "" then
		addText(self.Expand, objective, "ZC_MM_Tiny", color_text, S(8))
	end

	addText(self.Expand, "GEAR", "ZC_MM_Header", color_text, S(14))
	addText(self.Expand, "Choices apply the next time you spawn as this role. Placeholders are not usable.", "ZC_MM_Tiny", color_idle_dim, S(4))
	if data.Standard then addGearRole(self.Expand, "Standard", data.Standard) end
	if data.SOE then addGearRole(self.Expand, "State of Emergency", data.SOE) end
end

function TILE:RefreshStats()
	if not IsValid(self.RoundLabel) or not self.RoleData then return end
	local summary, rounds, wins, losses = statText(combinedStats(self.RoleData.Standard, self.RoleData.SOE))
	local statCol = rounds and color_live or color_gold
	self.RoundLabel:SetText(rounds or summary)
	self.RoundLabel:SetTextColor(statCol)
	if IsValid(self.WinLabel) and wins then self.WinLabel:SetText(wins) self.WinLabel:SetTextColor(statCol) end
	if IsValid(self.LoseLabel) and losses then self.LoseLabel:SetText(losses) self.LoseLabel:SetTextColor(statCol) end
end

function TILE:LayoutExpand()
	local headerH, pad = S(ROW_H), S(12)
	local innerW = math.max(self:GetWide() - pad * 2, 1)
	self.Expand:SetPos(pad, headerH)
	self.Expand:SetWide(innerW)
	local y = 0
	for _, child in ipairs(self.Expand:GetChildren()) do
		y = y + (child.StackGap or 0)
		child:SetPos(0, y)
		child:SetWide(innerW)
		if child.Text then
			surface.SetFont(child.Font)
			local _, lineH = surface.GetTextSize("Ag")
			lineH = lineH + 2
			local lines = {}
			for _, para in ipairs(string.Explode("\n", child.Text)) do
				para = string.Trim(para)
				if para == "" then
					lines[#lines + 1] = ""
				else
					local line = ""
					for word in string.gmatch(para, "%S+") do
						local trial = line == "" and word or (line .. " " .. word)
						if line ~= "" and surface.GetTextSize(trial) > innerW then
							lines[#lines + 1] = line
							line = word
						else
							line = trial
						end
					end
					lines[#lines + 1] = line
				end
			end
			child.DrawText = table.concat(lines, "\n")
			child:SetTall(math.max(#lines, 1) * lineH)
		end
		y = y + child:GetTall()
	end
	y = y + S(8)
	self.Expand:SetTall(y)
	self:SetTall(headerH + y + pad)
end

function TILE:SetExpanded(on)
	self.Expanded = on
	self.Expand:SetVisible(on)
	if not on then
		for _, child in ipairs(self.Expand:GetChildren()) do
			child:Remove()
		end
		self:SetTall(S(ROW_H))
		return
	end
	self:FillExpand()
end

function TILE:PerformLayout(w)
	if not IsValid(self.HeaderHit) or not IsValid(self.StdButton) or not IsValid(self.SoeButton) then return end
	local pad, gap, headerH = S(12), S(8), S(ROW_H)
	local btnH = S(42)
	local soeW, stdW = S(132), S(96)
	local buttonsW = pad + soeW + gap + stdW
	self.HeaderHit:SetZPos(1)
	self.StdButton:SetZPos(2)
	self.SoeButton:SetZPos(2)
	self.HeaderHit:SetPos(0, 0)
	self.HeaderHit:SetSize(math.max(w - buttonsW, 1), headerH)
	self.StdButton:SetSize(stdW, btnH)
	self.SoeButton:SetSize(soeW, btnH)
	self.SoeButton:SetPos(w - pad - soeW, math.floor((headerH - btnH) * 0.5))
	self.StdButton:SetPos(w - pad - soeW - gap - stdW, math.floor((headerH - btnH) * 0.5))
end

function TILE:Paint(w, h)
	local data = self.RoleData or {}
	local hovered = vgui.GetHoveredPanel()
	local hover = hovered == self or (IsValid(hovered) and hovered:HasParent(self))
	local selected = (data.Standard and not isRandom("standard") and currentRole("standard") == data.Standard)
		or (data.SOE and not isRandom("soe") and currentRole("soe") == data.SOE)

	surface.SetDrawColor(32, 34, 33, hover and 210 or 160)
	surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(selected and TRAITOR_R or FRAME_R, selected and TRAITOR_G or FRAME_G, selected and TRAITOR_B or FRAME_B, selected and 180 or 70)
	surface.DrawOutlinedRect(0, 0, w, h, 1)
	if selected or self.Expanded then
		surface.SetDrawColor(TRAITOR_R, TRAITOR_G, TRAITOR_B, 180)
		surface.DrawRect(0, 0, 2, h)
	end

	draw.SimpleText(string.upper(data.Name or "UNKNOWN"), "ZC_MM_Header", S(16), S(12), color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	local summary = statText(combinedStats(data.Standard, data.SOE))
	draw.SimpleText(summary, "ZC_MM_Tiny", S(16), S(36), summary == "No rounds yet" and color_gold or color_live, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

vgui.Register("HMCD_TraitorRoleTile", TILE, "EditablePanel")

local MENU = {}

local function removeOtherTraitorMenus(keep)
	local function scan(pnl)
		if not IsValid(pnl) then return end
		for _, child in ipairs(pnl:GetChildren()) do
			if child ~= keep and child.GetClassName and child:GetClassName() == "HMCD_TraitorTileMenu" then
				child:Remove()
			elseif IsValid(child) then
				scan(child)
			end
		end
	end
	scan(vgui.GetWorldPanel())
end

function MENU:Init()
	CreateFonts()
	removeOtherTraitorMenus(self)
	VGUI_HMCD_TraitorTileMenu = self

	local embedParent = hg and IsValid(hg.HMCD_TraitorTileEmbedParent) and hg.HMCD_TraitorTileEmbedParent or nil
	if hg then hg.HMCD_TraitorTileEmbedParent = nil end

	self.EmbeddedInMainMenu = IsValid(embedParent)
	if self.EmbeddedInMainMenu then
		self:SetParent(embedParent)
		self:SetPos(0, 0)
		self:SetSize(embedParent:GetWide(), embedParent:GetTall())
		embedParent.Paint = function(_, w, h)
			DrawTraitorFrame(0, 0, w, h)
		end
	else
		self:SetSize(math.min(ScrW() * 0.86, S(1280)), math.min(ScrH() * 0.82, S(820)))
		self:Center()
		self:MakePopup()
		if hg.AddSpaceCloseFooter then hg.AddSpaceCloseFooter(self) end
	end

	self:SetKeyboardInputEnabled(false)
	self:SetAlpha(0)
	self:AlphaTo(255, 0.12)

	self.CloseButton = vgui.Create("DButton", self)
	self.CloseButton:SetText("")
	self.CloseButton:SetVisible(not self.EmbeddedInMainMenu)
	self.CloseButton.DoClick = function()
		ClickSound(SND_CLICK)
		self:Close()
	end
	self.CloseButton.Paint = function(panel, w, h)
		local hover = panel:IsHovered()
		paintBox(w, h, TRAITOR_R, TRAITOR_G, TRAITOR_B, nil, hover and 210 or 150)
		draw.SimpleText("X", "ZC_MM_Button", w * 0.5, h * 0.5, hover and color_text or color_danger, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	self.CloseButton.OnCursorEntered = function() ClickSound(SND_HOVER) end

	self.Scroll = vgui.Create("DScrollPanel", self)
	self.Scroll.Paint = function() end
	PaintScroll(self.Scroll)
	self.Scroll.Rebuild = function(scroll)
		if self.LayoutTiles then self:LayoutTiles() end
	end

	self.Side = vgui.Create("DPanel", self)
	self.Side:SetPaintBackground(false)
	self.Side.Paint = function(_, w, h)
		surface.SetDrawColor(32, 34, 33, 210)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(TRAITOR_R, TRAITOR_G, TRAITOR_B, 70)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.SimpleText("RANDOM", "ZC_MM_Header", S(12), S(12), color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	self.RandomStdButton = vgui.Create("DButton", self.Side)
	self.RandomSoeButton = vgui.Create("DButton", self.Side)
	self.RandomStdButton:SetText("")
	self.RandomSoeButton:SetText("")
	self.RandomStdButton.DoClick = function() toggleRandom("standard") ClickSound(SND_CLICK) end
	self.RandomSoeButton.DoClick = function() toggleRandom("soe") ClickSound(SND_CLICK) end
	self.RandomStdButton.OnCursorEntered = function() ClickSound(SND_HOVER) end
	self.RandomSoeButton.OnCursorEntered = function() ClickSound(SND_HOVER) end
	self.RandomStdButton.Paint = function(btn, w, h) PaintChip(btn, w, h, isRandom("standard"), color_gold, "RANDOM STD") end
	self.RandomSoeButton.Paint = function(btn, w, h) PaintChip(btn, w, h, isRandom("soe"), color_gold, "RANDOM SOE") end

	self.PoolHint = vgui.Create("DLabel", self.Side)
	self.PoolHint:SetFont("ZC_MM_Tiny")
	self.PoolHint:SetTextColor(color_idle_dim)
	self.PoolHint:SetWrap(true)
	self.PoolHint:SetAutoStretchVertical(true)
	self.PoolHint:SetText("Include roles in random STD / SOE. Gold means the role can be rolled.")
	self.PoolHint:SetMouseInputEnabled(false)

	self.PoolScroll = vgui.Create("DScrollPanel", self.Side)
	self.PoolScroll.Paint = function() end
	PaintScroll(self.PoolScroll)

	self.Roles = collectTraitorRolePairs()
	self.Tiles = {}
	for i, data in ipairs(self.Roles) do
		local tile = vgui.Create("HMCD_TraitorRoleTile", self.Scroll)
		tile.OwnerSelector = self
		tile:SetRoleData(data)
		self.Tiles[i] = tile
		self:AddPoolRow(data)
	end

	requestTraitorRoleStats(false)
	syncTraitorGear()
	queueTraitorRolePreferenceSync()
end

function MENU:AddPoolRow(data)
	local row = vgui.Create("DPanel", self.PoolScroll)
	row:Dock(TOP)
	row:SetTall(S(40))
	row:DockMargin(0, 0, S(6), S(6))
	row:SetPaintBackground(false)
	row.Paint = function(_, w, h)
		surface.SetDrawColor(32, 34, 33, 180)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, 70)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.SimpleText(string.upper(data.Name or "UNKNOWN"), "ZC_MM_Tiny", S(10), h * 0.5, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	local function poolChip(label, mode, role)
		local btn = vgui.Create("DButton", row)
		btn:Dock(RIGHT)
		btn:SetWide(S(52))
		btn:DockMargin(0, S(6), S(6), S(6))
		btn:SetText("")
		btn:SetEnabled(role ~= nil)
		btn.Paint = function(self, w, h)
			if not role then
				PaintChip(self, w, h, false, color_idle_dim, "N/A")
				return
			end
			PaintChip(self, w, h, inRandomPool(role, mode), color_gold, label)
		end
		btn.OnCursorEntered = function() if role then ClickSound(SND_HOVER) end end
		btn.DoClick = function()
			if not role then return end
			ClickSound(SND_CLICK)
			toggleRandomPool(role, mode)
		end
	end

	poolChip("SOE", "soe", data.SOE)
	poolChip("STD", "standard", data.Standard)
end

function MENU:LayoutTiles()
	if self.LayingOutTiles or not IsValid(self.Scroll) then return end
	self.LayingOutTiles = true
	local canvas = self.Scroll:GetCanvas()
	local w = canvas:GetWide()
	if w < 1 then w = self.Scroll:GetWide() end
	local y, gap = 0, S(8)
	for _, tile in ipairs(self.Tiles or {}) do
		tile:SetWide(w)
		if tile.Expanded then tile:LayoutExpand() else tile:SetTall(S(ROW_H)) end
		tile:SetPos(0, y)
		y = y + tile:GetTall() + gap
	end
	canvas:SetTall(math.max(y, 1))
	self.LayingOutTiles = false
end

function MENU:SetExpandedRole(data, closeIfOpen)
	if closeIfOpen and self.CurrentDetailRole == data then data = nil end
	self.CurrentDetailRole = data
	for _, tile in ipairs(self.Tiles) do
		tile:SetExpanded(data ~= nil and tile.RoleData == data)
	end
	self:LayoutTiles()
end

function MENU:RefreshStats()
	for _, tile in ipairs(self.Tiles) do
		tile:RefreshStats()
	end
end

function MENU:PerformLayout(w, h)
	if not IsValid(self.CloseButton) or not IsValid(self.Scroll) or not IsValid(self.Side) then return end

	if self.EmbeddedInMainMenu and IsValid(self:GetParent()) then
		self:SetSize(self:GetParent():GetWide(), self:GetParent():GetTall())
	end

	local margin = INSET
	local headerH = S(48)
	self.CloseButton:SetSize(S(32), S(32))
	self.CloseButton:SetPos(w - margin - S(32), margin + S(2))

	local side = w >= S(980)
	local detailW = side and S(360) or (w - margin * 2)
	local detailH = side and (h - headerH - margin) or S(240)
	local scrollW = side and (w - margin * 2 - detailW - S(10)) or (w - margin * 2)
	local scrollH = side and (h - headerH - margin) or (h - headerH - margin - detailH - S(10))

	self.Scroll:SetPos(margin, headerH)
	self.Scroll:SetSize(scrollW, scrollH)
	self.Side:SetPos(side and (margin + scrollW + S(10)) or margin, side and headerH or (headerH + scrollH + S(10)))
	self.Side:SetSize(detailW, detailH)

	local pad, gap, btnH = S(12), S(8), S(32)
	local btnW = math.floor((detailW - pad * 2 - gap) * 0.5)
	self.RandomStdButton:SetPos(pad, S(40))
	self.RandomSoeButton:SetPos(pad + btnW + gap, S(40))
	self.RandomStdButton:SetSize(btnW, btnH)
	self.RandomSoeButton:SetSize(btnW, btnH)

	self.PoolHint:SetPos(pad, S(80))
	self.PoolHint:SetWide(detailW - pad * 2)
	self.PoolHint:SizeToContentsY()

	local poolY = S(80) + self.PoolHint:GetTall() + S(8)
	self.PoolScroll:SetPos(pad, poolY)
	self.PoolScroll:SetSize(detailW - pad * 2, math.max(detailH - poolY - pad, 1))
end

function MENU:Paint(w, h)
	if not IsValid(self.Scroll) then return end
	if not self.EmbeddedInMainMenu then
		DrawTraitorFrame(0, 0, w, h)
	end
	surface.SetDrawColor(32, 34, 33, 210)
	surface.DrawRect(INSET, INSET, w - INSET * 2, S(36))
	surface.SetDrawColor(TRAITOR_R, TRAITOR_G, TRAITOR_B, 36)
	surface.DrawRect(INSET, INSET, w - INSET * 2, S(36))
	draw.SimpleText("TRAITOR ROLE", "ZC_MM_Header", INSET + S(12), INSET + S(18), color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

function MENU:Close()
	if self.Closing then return end
	self.Closing = true
	self:AlphaTo(0, 0.1, 0, function()
		if IsValid(self) then self:Remove() end
	end)
end

vgui.Register("HMCD_TraitorTileMenu", MENU, "EditablePanel")

timer.Simple(0, function()
	removeOtherTraitorMenus(IsValid(VGUI_HMCD_TraitorTileMenu) and VGUI_HMCD_TraitorTileMenu or nil)
end)
