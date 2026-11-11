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
local ROW_H = 50

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
	if usableIcon(icon) and not isnumber(icon) then icon:SetInt("$flags", 32) end
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

local function gearIcon(item)
	local info = lookupIcon(item)
	if info then return info end
	local pool = placeholderIcons()
	if #pool > 0 then return pool[math.random(#pool)] end
end

local function drawWepIcon(info, w, h)
	if not info then return end
	local icon = info.icon
	surface.SetDrawColor(255, 255, 255, 235)
	if isnumber(icon) then surface.SetTexture(icon) else surface.SetMaterial(icon) end
	local maxW, maxH = w - S(8), math.max(h - S(4), 1)
	local iw, ih
	if info.square then
		ih = math.min(maxH, maxW)
		iw = ih
	else
		iw = math.min(maxW, maxH * 2)
		ih = iw * 0.5
	end
	surface.DrawTexturedRect((w - iw) * 0.5, math.max((h - ih) * 0.5, 0), iw, ih)
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
	return pnl
end

local savedView = "standard"
do
	local t = util.JSONToTable(file.Read(RANDOM_FILE, "DATA") or "")
	if istable(t) and (t.view == "soe" or t.view == "standard") then savedView = t.view end
end

local function saveView()
	file.CreateDir("zcity")
	file.Write(RANDOM_FILE, util.TableToJSON({view = savedView}, true))
end

local function syncTraitorRolePreferences()
	if not MODE.ConVar_SubRole_Traitor or not MODE.ConVar_SubRole_Traitor_SOE then return end
	net.Start("HMCD(SyncTraitorRolePreferences)")
		net.WriteString(MODE.ConVar_SubRole_Traitor:GetString())
		net.WriteString(MODE.ConVar_SubRole_Traitor_SOE:GetString())
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

local TILE = {}

function TILE:ModeRole()
	local mode = (IsValid(self.OwnerSelector) and self.OwnerSelector.ViewMode) or "standard"
	local data = self.RoleData
	return mode, data and (mode == "soe" and data.SOE or data.Standard)
end

function TILE:Init()
	self:SetTall(S(ROW_H))
	self:SetMouseInputEnabled(true)

	self.HeaderHit = vgui.Create("DButton", self)
	self.HeaderHit:SetText("")
	self.HeaderHit:SetCursor("hand")
	self.HeaderHit.Paint = function() end
	self.HeaderHit.DoClick = function()
		if IsValid(self.OwnerSelector) then self.OwnerSelector:SetExpandedRole(self.RoleData, true) end
		ClickSound(SND_CLICK)
	end

	self.AssignBtn = vgui.Create("DButton", self)
	self.AssignBtn:SetText("")
	self.AssignBtn:SetCursor("hand")
	self.AssignBtn.DoClick = function()
		local mode, role = self:ModeRole()
		if not role or isRandom(mode) or currentRole(mode) == role then return end
		setTraitorRolePreference(role, mode)
		ClickSound(SND_CLICK)
	end
	self.AssignBtn.OnCursorEntered = function()
		local mode, role = self:ModeRole()
		if role and not isRandom(mode) and currentRole(mode) ~= role then ClickSound(SND_HOVER) end
	end
	self.AssignBtn.Paint = function(btn, w, h)
		local mode, role = self:ModeRole()
		local randomOn = isRandom(mode)
		local active = role and not randomOn and currentRole(mode) == role
		local hover = btn:IsHovered() and not randomOn
		btn:SetCursor(randomOn and "arrow" or "hand")
		local r, g, b = FRAME_R, FRAME_G, FRAME_B
		if randomOn then
			r, g, b = color_gold.r, color_gold.g, color_gold.b
		elseif active then
			r, g, b = TRAITOR_R, TRAITOR_G, TRAITOR_B
		end
		paintBox(w, h, r, g, b, (randomOn or active) and 48 or (hover and 16 or nil), (randomOn or active or hover) and 220 or 140)
		local label = randomOn and "RANDOM" or (active and "ACTIVE" or "ASSIGN")
		draw.SimpleText(label, "ZC_MM_Tiny", w * 0.5, h * 0.5, (randomOn or active or hover) and color_text or color_idle_dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	self.Expand = vgui.Create("DPanel", self)
	self.Expand:SetVisible(false)
	self.Expand:SetPaintBackground(false)
end

function TILE:SetRoleData(data)
	self.RoleData = data
end

function TILE:FillExpand()
	for _, child in ipairs(self.Expand:GetChildren()) do
		child:Remove()
	end

	local data = self.RoleData
	if not data then return end
	local mode, role = self:ModeRole()

	local objective = (mode == "soe" and data.SOEObjective or data.StandardObjective) or ""
	local description = data.Description or ""
	if description == objective then description = "" end
	if objective ~= "" then
		addText(self.Expand, objective, "ZC_MM_Tiny", color_text, 0)
	elseif description ~= "" then
		addText(self.Expand, description, "ZC_MM_Tiny", color_text, 0)
		description = ""
	end
	if description ~= "" then
		addText(self.Expand, description, "ZC_MM_Tiny", color_idle_dim, S(8))
	end

	local gear = role and MODE.TraitorGear and MODE.TraitorGear[role]
	if not gear or #gear == 0 then return end

	local cardW, cardH = S(104), S(70)
	local optionGap, slotGap = S(6), S(22)
	local labelH = S(18)
	local function clipLabel(text)
		surface.SetFont("ZC_MM_Tiny")
		local maxW = cardW - S(8)
		if surface.GetTextSize(text) <= maxW then return text end
		while text ~= "" and surface.GetTextSize(text .. "...") > maxW do
			text = string.sub(text, 1, -2)
		end
		return text .. "..."
	end
	local function paintCard(panel, w, h, selected, hover)
		local r, g, b = selected and TRAITOR_R or FRAME_R, selected and TRAITOR_G or FRAME_G, selected and TRAITOR_B or FRAME_B
		paintBox(w, h, r, g, b, selected and 40 or (hover and 16 or nil), (selected or hover) and 210 or 90)
		drawWepIcon(panel.Icon, w, h - S(18))
		draw.SimpleText(panel.Label, "ZC_MM_Tiny", w * 0.5, h - S(9), panel.Locked and Color(140, 140, 140) or color_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	addText(self.Expand, "Given the next time you spawn as this role.", "ZC_MM_Tiny", color_idle_dim, S(12))

	local groups = vgui.Create("DPanel", self.Expand)
	groups.StackGap = S(8)
	groups:SetPaintBackground(false)
	groups.Reflow = function(panel, w)
		surface.SetFont("ZC_MM_Tiny")
		for _, group in ipairs(panel:GetChildren()) do
			local cards = group.Cards or {}
			local wrapped, line, lineW = {}, {}, 0
			for n = 1, #cards do
				local card = cards[n]
				local cw = card:GetWide()
				if #line > 0 and lineW + optionGap + cw > w then
					wrapped[#wrapped + 1] = {cards = line, w = lineW}
					line, lineW = {}, 0
				end
				line[#line + 1] = card
				lineW = lineW + (#line > 1 and optionGap or 0) + cw
			end
			if #line > 0 then wrapped[#wrapped + 1] = {cards = line, w = lineW} end

			local nameW = surface.GetTextSize(group.SlotName or "")
			local groupW = math.min(math.max(nameW, 1), w)
			for n = 1, #wrapped do
				groupW = math.max(groupW, math.min(wrapped[n].w, w))
			end
			local y = labelH
			for n = 1, #wrapped do
				local packed = wrapped[n]
				local x = math.max(math.floor((groupW - packed.w) * 0.5), 0)
				for i = 1, #packed.cards do
					local card = packed.cards[i]
					card:SetPos(x, y)
					x = x + card:GetWide() + optionGap
				end
				y = y + cardH + (n < #wrapped and optionGap or 0)
			end
			group.NaturalW = groupW
			group.NaturalH = math.max(y, labelH)
		end

		local rows, row, used = {}, {}, 0
		for _, group in ipairs(panel:GetChildren()) do
			local gw = group.NaturalW
			if used > 0 and used + gw > w then
				rows[#rows + 1] = row
				row, used = {}, 0
			end
			row[#row + 1] = group
			used = used + gw + slotGap
		end
		if #row > 0 then rows[#rows + 1] = row end

		local y = 0
		for r = 1, #rows do
			local line = rows[r]
			local base, rowH = 0, 0
			for i = 1, #line do
				base = base + line[i].NaturalW
				rowH = math.max(rowH, line[i].NaturalH)
			end
			local gaps = #line - 1
			local extra = 0
			if r < #rows and gaps > 0 then
				extra = math.max(w - base - gaps * slotGap, 0)
			end
			local x = 0
			for i = 1, #line do
				local group = line[i]
				group:SetPos(x, y)
				group:SetSize(group.NaturalW, group.NaturalH)
				local pad = slotGap
				if extra > 0 then
					pad = slotGap + math.floor(extra / gaps) + (i <= extra % gaps and 1 or 0)
				end
				x = x + group.NaturalW + pad
			end
			y = y + rowH + (r < #rows and slotGap or 0)
		end
		panel:SetTall(math.max(y, 0))
	end

	for _, spec in ipairs(gear) do
		local choices = {}
		for i = 1, #spec do
			if istable(spec[i]) then choices[#choices + 1] = spec[i] end
		end
		if #choices > 0 then
			local raw = spec.slot or "gear"
			local slotName = #raw <= 3 and string.upper(raw) or (string.upper(string.sub(raw, 1, 1)) .. string.lower(string.sub(raw, 2)))
			surface.SetFont("ZC_MM_Tiny")
			local group = vgui.Create("DPanel", groups)
			group.SlotName = slotName
			group.Cards = {}
			group.NaturalW = math.max(surface.GetTextSize(slotName), cardW)
			group.NaturalH = labelH + cardH
			group:SetPaintBackground(false)
			group.Paint = function(_, w)
				draw.SimpleText(slotName, "ZC_MM_Tiny", w * 0.5, 0, color_idle_dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			end
			local selectable = #choices > 1
			for n, opt in ipairs(choices) do
				local locked = opt.placeholder or not opt.item
				local stored = opt.item and (weapons.GetStored(opt.item) or (scripted_ents.GetStored(opt.item) or {}).t)
				local card = vgui.Create(selectable and "DButton" or "DPanel", group)
				card:SetPos(0, labelH)
				card:SetSize(cardW, cardH)
				group.Cards[#group.Cards + 1] = card
				card:SetMouseInputEnabled(selectable)
				card.Icon = gearIcon(opt.item)
				card.Locked = locked
				card.Label = clipLabel((stored and stored.PrintName) or (locked and "Placeholder" or opt.item))
				if selectable then
					card:SetText("")
					card:SetCursor(locked and "arrow" or "hand")
					card.Paint = function(panel, w, h)
						local resolved = (not locked) and MODE.ResolveTraitorGearOption(nil, role, spec.slot)
						local sel = resolved and resolved.item == opt.item
						paintCard(panel, w, h, sel, panel:IsHovered() and not locked and not sel)
					end
					if not locked then
						card.OnCursorEntered = function() ClickSound(SND_HOVER) end
						card.DoClick = function()
							ClickSound(SND_CLICK)
							setLocalTraitorGear(role, spec.slot, opt.item)
						end
					end
				else
					card.Paint = function(panel, w, h) paintCard(panel, w, h, not panel.Locked) end
				end
			end
		end
	end
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
		if child.Reflow then child:Reflow(innerW) end
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
	if not IsValid(self.HeaderHit) or not IsValid(self.AssignBtn) then return end
	local headerH = S(ROW_H)
	local pad, assignW, btnH = S(12), S(88), S(28)
	self.HeaderHit:SetZPos(0)
	self.AssignBtn:SetZPos(2)
	self.HeaderHit:SetPos(0, 0)
	self.HeaderHit:SetSize(w, headerH)
	self.AssignBtn:SetPos(math.max(w - pad - assignW, pad), math.floor((headerH - btnH) * 0.5))
	self.AssignBtn:SetSize(assignW, btnH)
end

function TILE:Paint(w, h)
	local mode, role = self:ModeRole()
	local data = self.RoleData or {}
	local hovered = vgui.GetHoveredPanel()
	local hover = hovered == self or (IsValid(hovered) and hovered:HasParent(self))
	local selected = role and not isRandom(mode) and currentRole(mode) == role
	local headerH = S(ROW_H)

	surface.SetDrawColor(32, 34, 33, hover and 210 or 160)
	surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(selected and TRAITOR_R or FRAME_R, selected and TRAITOR_G or FRAME_G, selected and TRAITOR_B or FRAME_B, selected and 180 or 70)
	surface.DrawOutlinedRect(0, 0, w, h, 1)
	if selected or self.Expanded then
		surface.SetDrawColor(TRAITOR_R, TRAITOR_G, TRAITOR_B, 200)
		surface.DrawRect(0, 0, 3, h)
	end

	local nameX = S(12)
	local statsRight = w - S(12) - S(88) - S(12)
	local games, wins = 0, 0
	if role then
		local key = MODE.NormalizeTraitorSubRole and MODE.NormalizeTraitorSubRole(role) or role
		local stats = key and MODE.HMCDTraitorRoleStats and MODE.HMCDTraitorRoleStats[key]
		wins = math.max(math.floor(tonumber(stats and stats.wins or 0) or 0), 0)
		games = math.max(math.floor(tonumber(stats and stats.games or 0) or 0), 0)
	end
	surface.SetFont("ZC_MM_Tiny")
	local gap = S(16)
	local roundsText, winText, lossText
	local roundsW, winW, statsW = 0, 0, 0
	if role and games <= 0 then
		roundsText = "No rounds yet"
		statsW = surface.GetTextSize(roundsText)
	elseif role then
		wins = math.min(wins, games)
		local winPct = math.Clamp(math.Round((wins / games) * 100), 0, 100)
		roundsText = games .. " rounds"
		winText = winPct .. "% win rate"
		lossText = (100 - winPct) .. "% loss rate"
		roundsW = surface.GetTextSize(roundsText)
		winW = surface.GetTextSize(winText)
		statsW = roundsW + gap + winW + gap + surface.GetTextSize(lossText)
	end
	local nameMax = math.max(statsRight - statsW - S(12) - nameX, S(48))
	local name = string.upper(data.Name or "UNKNOWN")
	surface.SetFont("ZC_MM_Header")
	if surface.GetTextSize(name) > nameMax then
		while name ~= "" and surface.GetTextSize(name .. "...") > nameMax do
			name = string.sub(name, 1, -2)
		end
		name = name .. "..."
	end
	draw.SimpleText(name, "ZC_MM_Header", nameX, headerH * 0.5, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	if roundsText then
		local cy = headerH * 0.5
		if not winText then
			draw.SimpleText(roundsText, "ZC_MM_Tiny", statsRight, cy, color_idle_dim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		else
			local x = statsRight - statsW
			draw.SimpleText(roundsText, "ZC_MM_Tiny", x, cy, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(winText, "ZC_MM_Tiny", x + roundsW + gap, cy, color_live, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(lossText, "ZC_MM_Tiny", x + roundsW + gap + winW + gap, cy, color_danger, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end
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
	self.ViewMode = savedView == "soe" and "soe" or "standard"

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

	local function modeButton(label, mode)
		local btn = vgui.Create("DButton", self)
		btn:SetText("")
		btn.DoClick = function()
			if self.ViewMode == mode then return end
			self:SetViewMode(mode)
			ClickSound(SND_CLICK)
		end
		btn.OnCursorEntered = function() ClickSound(SND_HOVER) end
		btn.Paint = function(panel, w, h)
			local on = self.ViewMode == mode
			local hover = panel:IsHovered()
			local r, g, b = on and TRAITOR_R or FRAME_R, on and TRAITOR_G or FRAME_G, on and TRAITOR_B or FRAME_B
			paintBox(w, h, r, g, b, (on or hover) and (on and 40 or 16) or nil, (on or hover) and 210 or 140)
			draw.SimpleText(label, "ZC_MM_Tiny", w * 0.5, h * 0.5, (on or hover) and color_text or color_idle_dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		return btn
	end
	self.StdModeButton = modeButton("STANDARD", "standard")
	self.SoeModeButton = modeButton("STATE OF EMERGENCY", "soe")

	self.RandomButton = vgui.Create("DButton", self)
	self.RandomButton:SetText("")
	self.RandomButton.DoClick = function()
		toggleRandom(self.ViewMode or "standard")
		ClickSound(SND_CLICK)
	end
	self.RandomButton.OnCursorEntered = function() ClickSound(SND_HOVER) end
	self.RandomButton.Paint = function(btn, w, h)
		local on = isRandom(self.ViewMode or "standard")
		local hover = btn:IsHovered()
		local r, g, b = on and color_gold.r or FRAME_R, on and color_gold.g or FRAME_G, on and color_gold.b or FRAME_B
		paintBox(w, h, r, g, b, (on or hover) and (on and 36 or 16) or nil, (on or hover) and 210 or 140)
		draw.SimpleText(on and "RANDOM ON" or "RANDOM", "ZC_MM_Tiny", w * 0.5, h * 0.5, (on or hover) and color_text or color_idle_dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	self.Scroll = vgui.Create("DScrollPanel", self)
	self.Scroll.Paint = function() end
	PaintScroll(self.Scroll)
	self.Scroll.Rebuild = function()
		if self.LayoutTiles then self:LayoutTiles() end
	end

	self.Roles = collectTraitorRolePairs()
	self.Tiles = {}
	for i, data in ipairs(self.Roles) do
		local tile = vgui.Create("HMCD_TraitorRoleTile", self.Scroll)
		tile.OwnerSelector = self
		tile:SetRoleData(data)
		self.Tiles[i] = tile
	end

	requestTraitorRoleStats(false)
	syncTraitorGear()
	queueTraitorRolePreferenceSync()
	self:InvalidateLayout(true)
end

function MENU:SetViewMode(mode)
	if self.ViewMode == mode then return end
	self.ViewMode = mode
	savedView = mode
	saveView()
	for _, tile in ipairs(self.Tiles or {}) do
		if tile.Expanded then tile:FillExpand() end
	end
	self:LayoutTiles()
end

function MENU:LayoutTiles()
	if self.LayingOutTiles or not IsValid(self.Scroll) then return end
	self.LayingOutTiles = true
	local canvas = self.Scroll:GetCanvas()
	local w = canvas:GetWide()
	if w < 1 then w = self.Scroll:GetWide() end
	local y, gap = 0, S(6)
	local key = self.ViewMode == "soe" and "SOE" or "Standard"
	for _, tile in ipairs(self.Tiles or {}) do
		local show = tile.RoleData and tile.RoleData[key] ~= nil
		tile:SetVisible(show)
		if show then
			tile:SetWide(w)
			if tile.Expanded then tile:LayoutExpand() else tile:SetTall(S(ROW_H)) end
			tile:SetPos(0, y)
			y = y + tile:GetTall() + gap
		end
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

function MENU:PerformLayout(w, h)
	if not IsValid(self.CloseButton) or not IsValid(self.Scroll) or not IsValid(self.StdModeButton) then return end

	if self.EmbeddedInMainMenu and IsValid(self:GetParent()) then
		self:SetSize(self:GetParent():GetWide(), self:GetParent():GetTall())
		w, h = self:GetSize()
	end

	local margin = INSET + S(8)
	local barH = S(36)
	local listTop = INSET + S(66)
	local edge = S(12)
	self.CloseButton:SetSize(S(32), S(32))
	self.CloseButton:SetPos(w - margin - edge - S(32), INSET + math.floor((barH - S(32)) * 0.5))

	self.Scroll:SetPos(margin, listTop)
	self.Scroll:SetSize(w - margin * 2, math.max(h - listTop - margin, 1))

	local btnH = S(26)
	local y = INSET + math.floor((barH - btnH) * 0.5)
	local x = w - margin - edge
	if self.CloseButton:IsVisible() then x = x - S(32) - S(10) end
	local buttons = {
		{self.RandomButton, S(108)},
		{self.SoeModeButton, S(188)},
		{self.StdModeButton, S(108)}
	}
	for i = 1, #buttons do
		local btn, bw = buttons[i][1], buttons[i][2]
		x = x - bw
		btn:SetPos(x, y)
		btn:SetSize(bw, btnH)
		x = x - S(8)
	end
end

function MENU:Paint(w, h)
	if not IsValid(self.Scroll) then return end
	if not self.EmbeddedInMainMenu then
		DrawTraitorFrame(0, 0, w, h)
	end
	local barH = S(36)
	surface.SetDrawColor(32, 34, 33, 210)
	surface.DrawRect(INSET, INSET, w - INSET * 2, barH)
	surface.SetDrawColor(TRAITOR_R, TRAITOR_G, TRAITOR_B, 36)
	surface.DrawRect(INSET, INSET, w - INSET * 2, barH)
	draw.SimpleText("TRAITOR ROLE", "ZC_MM_Header", INSET + S(12), INSET + barH * 0.5, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

	local mode = self.ViewMode == "soe" and "soe" or "standard"
	local modeName = mode == "soe" and "State of Emergency" or "Standard"
	local hint = isRandom(mode)
		and ("Random is on for " .. modeName .. ". Any role can be picked.")
		or ("Click a role to open it. ASSIGN plays that role in " .. modeName .. ". RANDOM picks any role.")
	draw.SimpleText(hint, "ZC_MM_Tiny", INSET + S(12), INSET + barH + S(8), color_idle_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
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
