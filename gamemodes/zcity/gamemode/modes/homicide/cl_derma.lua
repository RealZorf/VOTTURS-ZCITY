local MODE = MODE
local vgui_color_main = Color(155, 0, 0, 255)
local vgui_color_bg = Color(50, 50, 50, 255)
local vgui_color_ready = Color(0, 150, 50, 255)
local vgui_color_notready = Color(0, 50, 0, 255)

-- surface.CreateFont("RoleSelection_Main", {
	-- font = "Roboto",
	-- extended = false,
	-- size = ScreenScale(10),
	-- weight = 500,
	-- blursize = 0,
	-- scanlines = 0,
	-- antialias = true,
	-- underline = false,
	-- italic = false,
	-- strikeout = false,
	-- symbol = false,
	-- rotary = false,
	-- shadow = false,
	-- additive = false,
	-- outline = false,
-- })
local function set_role(role, mode)
	if mode == "soe" then
		RunConsoleCommand(MODE.ConVarName_SubRole_Traitor_SOE, role)
	else
		RunConsoleCommand(MODE.ConVarName_SubRole_Traitor, role)
	end
end

local function screen_scale_2(num)
	return ScreenScale(num) / (ScrW() / ScrH())
end

local function traitor_ui(num)
	local scale = math.Clamp(math.min(ScrW() / 1920, ScrH() / 1080), 0.95, 1.35)
	return math.Round(num * scale)
end

local traitorFontsW, traitorFontsH
local function refreshTraitorTileFonts()
	local sw, sh = ScrW(), ScrH()
	if traitorFontsW == sw and traitorFontsH == sh then return end

	traitorFontsW, traitorFontsH = sw, sh

	surface.CreateFont("HMCD_TraitorTiles_Title", {
		font = "Bahnschrift",
		size = traitor_ui(34),
		weight = 900,
		extended = true,
		antialias = true
	})

	surface.CreateFont("HMCD_TraitorTiles_Subtitle", {
		font = "Bahnschrift SemiBold",
		size = traitor_ui(17),
		weight = 700,
		extended = true,
		antialias = true
	})

	surface.CreateFont("HMCD_TraitorTiles_Role", {
		font = "Bahnschrift SemiBold",
		size = traitor_ui(25),
		weight = 800,
		extended = true,
		antialias = true
	})

	surface.CreateFont("HMCD_TraitorTiles_Code", {
		font = "Bahnschrift",
		size = traitor_ui(12),
		weight = 700,
		extended = true,
		antialias = true
	})

	surface.CreateFont("HMCD_TraitorTiles_Text", {
		font = "Bahnschrift",
		size = traitor_ui(15),
		weight = 500,
		extended = true,
		antialias = true
	})

	surface.CreateFont("HMCD_TraitorTiles_DetailHeader", {
		font = "Bahnschrift SemiBold",
		size = traitor_ui(18),
		weight = 800,
		extended = true,
		antialias = true
	})

	surface.CreateFont("HMCD_TraitorTiles_Button", {
		font = "Bahnschrift SemiBold",
		size = traitor_ui(17),
		weight = 800,
		extended = true,
		antialias = true
	})
end

local traitorTileAccent = Color(35, 255, 110)
local traitorTileAccentHot = Color(100, 255, 165)
local traitorTilePanel = Color(2, 13, 8, 248)
local traitorTilePanelAccent = Color(8, 33, 21, 238)
local traitorTileText = Color(220, 238, 226)
local traitorTileMuted = Color(135, 190, 154)
local traitorTileDanger = Color(185, 52, 68)
local traitorTileAmber = Color(255, 190, 75)
local traitorGradientR = Material("vgui/gradient-r")
local traitorGradientD = Material("vgui/gradient-d")
local traitorGradientU = Material("vgui/gradient-u")

local function stripSOESuffix(role)
	return string.gsub(role or "", "_soe$", "")
end

MODE.HMCDTraitorRoleStats = MODE.HMCDTraitorRoleStats or {}

local function getTraitorRoleStats(role)
	if not role or role == "" then
		return {wins = 0, games = 0}
	end

	local normalized_role = MODE.NormalizeTraitorSubRole and MODE.NormalizeTraitorSubRole(role) or role
	local stats = MODE.HMCDTraitorRoleStats and MODE.HMCDTraitorRoleStats[normalized_role]
	if not stats then
		return {wins = 0, games = 0}
	end

	return {
		wins = math.max(math.floor(tonumber(stats.wins or 0) or 0), 0),
		games = math.max(math.floor(tonumber(stats.games or 0) or 0), 0)
	}
end

local function combineTraitorRoleStats(...)
	local combined = {wins = 0, games = 0}

	for i = 1, select("#", ...) do
		local role = select(i, ...)
		local stats = getTraitorRoleStats(role)
		combined.wins = combined.wins + stats.wins
		combined.games = combined.games + stats.games
	end

	return combined
end

local function getTraitorWinratePercent(stats)
	if not stats or (stats.games or 0) <= 0 then return nil end
	return math.Clamp(math.Round((stats.wins / stats.games) * 100), 0, 100)
end

local function formatTraitorWinrateShort(stats)
	local rate = getTraitorWinratePercent(stats)
	if not rate then return "WR --" end

	return string.format("WR %d%% / %dR", rate, stats.games)
end

local function formatTraitorWinrateLine(label, stats)
	local rate = getTraitorWinratePercent(stats)
	if not rate then
		return label .. ": no server data yet"
	end

	return string.format("%s: %d%% over %d rounds (%dW/%dL)", label, rate, stats.games, stats.wins, math.max(stats.games - stats.wins, 0))
end

local function buildTraitorWinrateDetail(data)
	if not data then return "" end

	local combined = combineTraitorRoleStats(data.Standard, data.SOE)
	if combined.games <= 0 then
		return "No server data yet."
	end

	local lines = {
		formatTraitorWinrateLine("Combined", combined),
		formatTraitorWinrateLine("Standard", getTraitorRoleStats(data.Standard)),
		formatTraitorWinrateLine("SOE", getTraitorRoleStats(data.SOE))
	}

	return table.concat(lines, "\n")
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
		local normalized_role = MODE.NormalizeTraitorSubRole and MODE.NormalizeTraitorSubRole(role) or role
		local wins = net.ReadUInt(24)
		local games = net.ReadUInt(24)

		if normalized_role and normalized_role ~= "" then
			stats[normalized_role] = {
				wins = wins,
				games = games
			}
		end
	end

	MODE.HMCDTraitorRoleStats = stats

	if IsValid(VGUI_HMCD_TraitorTileMenu) and VGUI_HMCD_TraitorTileMenu.RefreshStats then
		VGUI_HMCD_TraitorTileMenu:RefreshStats()
	end
end)

local function getRoleDescription(info)
	if not info then return "" end

	local text = info.Description or info.Objective or ""
	text = string.gsub(text, "\r", "")
	text = string.gsub(text, "\n+", "\n")

	return text
end

local function getRoleSummary(info)
	local text = getRoleDescription(info)
	local lines = {}

	for line in string.gmatch(text, "[^\n]+") do
		line = string.Trim(line)
		if line ~= "" then
			lines[#lines + 1] = line
		end

		if #lines >= 3 then break end
	end

	return table.concat(lines, "\n")
end

local traitorLoadoutText = {
	traitor_default = "Suppressed P22 + spare ammo\nBuck 200 knife, RGD grenade, smoke grenade\nIED, poison vial, traitor suit, jam, shuriken\nAdrenaline, fiber wire, flashlight",
	traitor_default_soe = "Suppressed P22 + spare ammo\nSOG knife, RGD grenade, smoke grenade\nIED, poison 2 and poison 3\nWalkie-talkie, adrenaline, fiber wire, flashlight",
	traitor_infiltrator = "SOG knife\nAdrenaline\nSmoke grenade\nFiber wire, flashlight",
	traitor_infiltrator_soe = "Taser + 2 extra heads\nSOG knife, smoke grenade\nWalkie-talkie, adrenaline\nFiber wire, flashlight",
	traitor_thief = "SOG knife\nAdrenaline\nSmoke grenade\nHidden starter gear tracking, flashlight",
	traitor_thief_soe = "SOG knife\nWalkie-talkie\nAdrenaline\nSmoke grenade, hidden starter gear tracking, flashlight",
	traitor_assassin = "Katana with sling\nHigh recoil control\nExtra stamina\nBuilt to disarm and steal weapons",
	traitor_assassin_soe = "Katana with sling\nWalkie-talkie\nAdrenaline\nFiber wire\nHigher recoil control and stamina",
	traitor_chemist = "SOG knife\nAdrenaline\nPoison 1, 2, 3 and 4\nPoison consumable, sleep canister\nFiber wire, flashlight",
	traitor_chemist_soe = "SOG knife\nWalkie-talkie\nAdrenaline\nPoison 1, 2, 3 and 4\nPoison consumable, sleep canister\nFiber wire, flashlight",
	traitor_shadow = "Reload-key wall camouflage with short slip window\nTranquilizer gun with population-scaled ammo\nSOG knife, poison vial, traitor suit\nAdrenaline, handcuffs, smoke and decoy grenades\nFiber wire, flashlight",
	traitor_shadow_soe = "Reload-key wall camouflage with short slip window\nTranquilizer gun with population-scaled ammo\nSOG knife, poison vial, traitor suit\nWalkie-talkie, adrenaline, handcuffs\nSmoke and decoy grenades\nFiber wire, flashlight",
	traitor_maniac = "Poisoned fire axe\nM45, RGD grenade, molotov\nWalkie-talkie, poison 4, traitor suit\nAdrenaline, fiber wire, flashlight\nMassive stamina, bonus health\nFury after first serious wound",
	traitor_maniac_soe = "Poisoned fire axe\nM45, RGD grenade, molotov\nWalkie-talkie, poison 4, traitor suit\nAdrenaline, fiber wire, flashlight\nMassive stamina, bonus health, SOE recoil control\nFury after first serious wound",
	traitor_terrorist = "Bomb vest\nMatches\nClaymore, grenade\nIED, Buck 200 knife\nFlashlight",
	traitor_terrorist_soe = "Bomb vest\nMatches\nClaymore, grenade\nIED, SOG knife\nFlashlight",
	traitor_lastmanstanding = "Kar98 + 20 rounds\nSling\nBrass knuckles\nFlashlight",
	traitor_lastmanstanding_soe = "Kar98 + 20 rounds\nSling\nBrass knuckles\nFlashlight, SOE recoil control",
	traitor_stalker = "SOG knife\nAdrenaline\nSmoke grenade\nFiber wire, flashlight\nHammer + 6 nails\nOne-use death decoy\nPrey Sense sharpens isolated marked victims\nSilent Pursuit quiets your steps near isolated prey\nFirst hit staggers marked prey; isolated prey are hit harder",
	traitor_stalker_soe = "SOG knife\nWalkie-talkie\nAdrenaline\nSmoke grenade\nFiber wire, flashlight\nHammer + 6 nails\nOne-use death decoy\nPrey Sense sharpens isolated marked victims\nSilent Pursuit quiets your steps near isolated prey\nFirst hit staggers marked prey; isolated prey are hit harder"
}

local function getLoadoutText(role)
	return traitorLoadoutText[role or ""] or "Loadout metadata missing for this profile."
end

local function collectTraitorRolePairs()
	local roundTypes = MODE.RoleChooseRoundTypes or {}
	local standardRoles = roundTypes.standard and roundTypes.standard.Traitor or {}
	local soeRoles = roundTypes.soe and roundTypes.soe.Traitor or {}
	local byBase = {}

	for role in pairs(standardRoles) do
		local base = stripSOESuffix(role)
		byBase[base] = byBase[base] or {}
		byBase[base].standard = role
	end

	for role in pairs(soeRoles) do
		local base = stripSOESuffix(role)
		byBase[base] = byBase[base] or {}
		byBase[base].soe = role
	end

	local roles = {}
	for base, pair in pairs(byBase) do
		local standardInfo = pair.standard and MODE.SubRoles[pair.standard]
		local soeInfo = pair.soe and MODE.SubRoles[pair.soe]
		local info = standardInfo or soeInfo
		if info then
			roles[#roles + 1] = {
				Base = base,
				Name = info.Name or base,
				Description = getRoleSummary(info),
				DetailDescription = getRoleDescription(info),
				StandardLoadout = getLoadoutText(pair.standard),
				SOELoadout = getLoadoutText(pair.soe),
				StandardObjective = standardInfo and standardInfo.Objective or "",
				SOEObjective = soeInfo and soeInfo.Objective or "",
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

local function drawCornerBrackets(x, y, w, h, len, col)
	surface.SetDrawColor(col)
	surface.DrawRect(x, y, len, 1)
	surface.DrawRect(x, y, 1, len)
	surface.DrawRect(x + w - len, y, len, 1)
	surface.DrawRect(x + w - 1, y, 1, len)
	surface.DrawRect(x, y + h - 1, len, 1)
	surface.DrawRect(x, y + h - len, 1, len)
	surface.DrawRect(x + w - len, y + h - 1, len, 1)
	surface.DrawRect(x + w - 1, y + h - len, 1, len)
end

local function drawCutPoly(x, y, w, h, cut, col)
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

local function drawCutOutline(x, y, w, h, cut, col, thick)
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

local function drawGlowLine(x, y, w, h, col)
	surface.SetDrawColor(col.r, col.g, col.b, 18)
	surface.DrawRect(x - 4, y - 4, w + 8, h + 8)
	surface.SetDrawColor(col.r, col.g, col.b, 70)
	surface.DrawRect(x - 1, y - 1, w + 2, h + 2)
	surface.SetDrawColor(col)
	surface.DrawRect(x, y, w, h)
end

local function panelHoveredDeep(panel)
	local hovered = vgui.GetHoveredPanel()

	while IsValid(hovered) do
		if hovered == panel then return true end
		hovered = hovered:GetParent()
	end

	return false
end

local PANEL = {}

function PANEL:Init()
	self:SetMouseInputEnabled(true)

	self.Scroll = vgui.Create("DScrollPanel", self)
	self.Scroll.Paint = function() end
	self.Scroll:GetVBar():SetWide(traitor_ui(5))
	self.Scroll:GetVBar().Paint = function(_, w, h)
		surface.SetDrawColor(0, 0, 0, 90)
		surface.DrawRect(0, 0, w, h)
	end
	self.Scroll:GetVBar().btnGrip.Paint = function(_, w, h)
		surface.SetDrawColor(35, 255, 110, 120)
		surface.DrawRect(0, 0, w, h)
	end
	self.Scroll:GetVBar().btnUp.Paint = function() end
	self.Scroll:GetVBar().btnDown.Paint = function() end

	self.Body = vgui.Create("DPanel", self.Scroll)
	self.Body.Paint = function(_, w, h)
		if self.DetailMarkup then
			self.DetailMarkup:Draw(0, 0, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 255)
		end
	end

	self.Scroll:AddItem(self.Body)
	self.DetailParts = {}
	self:SetRoleData(nil)
end

local function detailMarkupColor(color)
	return string.format("%d,%d,%d,%d", color.r, color.g, color.b, color.a or 255)
end

function PANEL:ClearDetailLabels()
	self.DetailParts = {}
	self.DetailMarkup = nil
	self.DetailMarkupWidth = nil
end

function PANEL:AddDetailLabel(text, font, color, topGap)
	if not text or text == "" then return end

	self.DetailParts[#self.DetailParts + 1] = {
		Text = text,
		Font = font,
		Color = color,
		TopGap = topGap or 0
	}
end

function PANEL:AddDetailSection(title, body)
	if not body or body == "" then return end

	self:AddDetailLabel(title, "HMCD_TraitorTiles_DetailHeader", Color(220, 255, 232), #self.DetailParts > 0 and traitor_ui(18) or 0)
	self:AddDetailLabel(body, "HMCD_TraitorTiles_Text", traitorTileMuted, traitor_ui(2))
end

function PANEL:BuildDetailMarkup(width)
	width = math.max(width or 1, 1)
	if self.DetailMarkup and self.DetailMarkupWidth == width then return end

	local text = {}
	for _, part in ipairs(self.DetailParts or {}) do
		if part.TopGap and part.TopGap > 0 then
			text[#text + 1] = "\n"
		end

		text[#text + 1] = string.format("<font=%s><colour=%s>%s</colour></font>", part.Font, detailMarkupColor(part.Color), part.Text)
	end

	self.DetailMarkup = markup.Parse(table.concat(text, "\n"), width)
	self.DetailMarkupWidth = width
end

function PANEL:SetRoleData(data)
	self.RoleData = data
	self:ClearDetailLabels()

	if not data then
		self:AddDetailLabel("Hover or click a role node to inspect its full profile.\n\nSTD and SOE selections stay under each tile.", "HMCD_TraitorTiles_Text", traitorTileMuted)
		self:InvalidateLayout(true)
		return
	end

	local description = data.DetailDescription ~= "" and data.DetailDescription or data.Description
	local standardText = data.StandardLoadout ~= "" and data.StandardLoadout or "No Standard loadout configured."
	local soeText = data.SOELoadout ~= "" and data.SOELoadout or "No SOE loadout configured."
	local objective = data.StandardObjective ~= "" and data.StandardObjective or data.SOEObjective
	local winrateText = buildTraitorWinrateDetail(data)

	self:AddDetailSection("WINRATE", winrateText)

	if objective and objective ~= "" then
		self:AddDetailSection("OBJECTIVE", objective)
	end

	if description and description ~= "" then
		self:AddDetailSection("DESCRIPTION", description)
	end

	self:AddDetailSection("STANDARD LOADOUT", standardText)
	self:AddDetailSection("SOE LOADOUT", soeText)
	self:InvalidateLayout(true)
end

function PANEL:PerformLayout(w, h)
	self.Scroll:SetPos(traitor_ui(18), traitor_ui(68))
	self.Scroll:SetSize(w - traitor_ui(36), h - traitor_ui(86))
	local bodyW = math.max(self.Scroll:GetWide() - traitor_ui(10), 1)

	self:BuildDetailMarkup(bodyW)

	self.Body:SetSize(bodyW, (self.DetailMarkup and self.DetailMarkup:GetHeight() or 0) + traitor_ui(8))
end

function PANEL:Paint(w, h)
	drawCutPoly(0, 0, w, h, traitor_ui(14), Color(2, 14, 8, 228))
	drawCutPoly(1, 1, w - 2, h - 2, traitor_ui(13), Color(7, 30, 19, 210))
	drawCutOutline(0, 0, w, h, traitor_ui(14), Color(35, 255, 110, 105), 1)

	local data = self.RoleData
	local title = data and string.upper(data.Name or "ROLE PROFILE") or "ROLE PROFILE"
	local code = data and ("PROFILE / " .. string.upper(string.gsub(data.Base or "unknown", "traitor_", ""))) or "PROFILE / WAITING"

	draw.SimpleText(title, "HMCD_TraitorTiles_Role", traitor_ui(18), traitor_ui(15), traitorTileText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText(code, "HMCD_TraitorTiles_Code", traitor_ui(19), traitor_ui(47), Color(35, 255, 110, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

vgui.Register("HMCD_TraitorDetailPanel", PANEL, "EditablePanel")

local PANEL = {}

function PANEL:Init()
	refreshTraitorTileFonts()
	requestTraitorRoleStats(false)

	if IsValid(VGUI_HMCD_TraitorTileMenu) then
		VGUI_HMCD_TraitorTileMenu:Remove()
	end

	VGUI_HMCD_TraitorTileMenu = self
	local embedParent = hg and IsValid(hg.HMCD_TraitorTileEmbedParent) and hg.HMCD_TraitorTileEmbedParent or nil
	if hg then
		hg.HMCD_TraitorTileEmbedParent = nil
	end

	self.EmbeddedInMainMenu = IsValid(embedParent)
	if self.EmbeddedInMainMenu then
		self:SetParent(embedParent)
		self:SetPos(0, 0)
		self:SetSize(embedParent:GetWide(), embedParent:GetTall())
	else
		self:SetSize(math.min(ScrW() * 0.86, traitor_ui(1500)), math.min(ScrH() * 0.82, traitor_ui(860)))
		self:Center()
		self:MakePopup()
	end

	self:SetKeyboardInputEnabled(false)
	self:SetAlpha(0)
	self:AlphaTo(255, 0.12)
	self.OpenTime = SysTime()

	self.CloseButton = vgui.Create("DButton", self)
	self.CloseButton:SetText("")
	self.CloseButton.DoClick = function()
		self:Close()
	end
	self.CloseButton.Paint = function(panel, w, h)
		local hover = panel:IsHovered() and 1 or 0
		draw.RoundedBox(0, 0, 0, w, h, Color(3 + hover * 18, 8, 7, 218))
		surface.SetDrawColor(traitorTileDanger.r, traitorTileDanger.g + hover * 55, traitorTileDanger.b + hover * 45, 165 + hover * 65)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.SimpleText("X", "HMCD_TraitorTiles_Button", w * 0.5, h * 0.48, Color(255, 140 + hover * 70, 145 + hover * 55), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	self.Scroll = vgui.Create("DScrollPanel", self)
	self.Scroll.Paint = function() end
	self.DetailPanel = vgui.Create("HMCD_TraitorDetailPanel", self)

	local vbar = self.Scroll:GetVBar()
	vbar:SetWide(traitor_ui(7))
	vbar.Paint = function(_, w, h)
		surface.SetDrawColor(0, 0, 0, 120)
		surface.DrawRect(0, 0, w, h)
	end
	vbar.btnGrip.Paint = function(_, w, h)
		surface.SetDrawColor(traitorTileAccent.r, traitorTileAccent.g, traitorTileAccent.b, 170)
		surface.DrawRect(0, 0, w, h)
	end
	vbar.btnUp.Paint = function() end
	vbar.btnDown.Paint = function() end

	self.Tiles = {}
	local firstData
	for i, data in ipairs(collectTraitorRolePairs()) do
		local tile = vgui.Create("HMCD_TraitorRoleTile", self.Scroll)
		self.Scroll:AddItem(tile)
		tile.TileIndex = i
		tile.RevealStart = SysTime() + (i - 1) * 0.035
		tile.OwnerSelector = self
		tile:SetRoleData(data)
		firstData = firstData or data
		self.Tiles[#self.Tiles + 1] = tile
	end

	self:SetDetailRole(firstData, true)
end

function PANEL:SetDetailRole(data, pinned)
	if not data or not IsValid(self.DetailPanel) then return end
	self.CurrentDetailRole = data
	self.DetailPanel:SetRoleData(data)
end

function PANEL:RefreshStats()
	if IsValid(self.DetailPanel) and self.CurrentDetailRole then
		self.DetailPanel:SetRoleData(self.CurrentDetailRole)
	end

	for _, tile in ipairs(self.Tiles or {}) do
		if IsValid(tile) then
			tile:InvalidateLayout(false)
		end
	end
end

function PANEL:PerformLayout(w, h)
	if self.EmbeddedInMainMenu and IsValid(self:GetParent()) then
		self:SetSize(self:GetParent():GetWide(), self:GetParent():GetTall())
	end

	local margin = self.EmbeddedInMainMenu and traitor_ui(18) or traitor_ui(26)
	local headerH = self.EmbeddedInMainMenu and traitor_ui(108) or traitor_ui(118)

	self.CloseButton:SetSize(traitor_ui(32), traitor_ui(32))
	self.CloseButton:SetPos(w - margin - self.CloseButton:GetWide(), traitor_ui(30))

	local useSideDetail = w >= traitor_ui(1080)
	local detailGap = traitor_ui(18)
	local detailW = useSideDetail and traitor_ui(330) or 0
	local detailH = useSideDetail and (h - headerH - margin) or traitor_ui(185)
	local scrollW = useSideDetail and (w - margin * 2 - detailW - detailGap) or (w - margin * 2)
	local scrollH = useSideDetail and (h - headerH - margin) or (h - headerH - margin * 2 - detailH)

	self.Scroll:SetPos(margin, headerH)
	self.Scroll:SetSize(scrollW, scrollH)
	self.DetailPanel:SetPos(useSideDetail and (margin + scrollW + detailGap) or margin, useSideDetail and headerH or (headerH + scrollH + detailGap))
	self.DetailPanel:SetSize(useSideDetail and detailW or scrollW, detailH)

	local gap = traitor_ui(18)
	local available = self.Scroll:GetWide() - gap
	local cols = ScrW() >= 2200 and 3 or 2
	local tileW = math.floor((available - gap * (cols - 1)) / cols)

	if tileW < traitor_ui(360) then
		cols = 1
		tileW = available
	end

	local tileH = traitor_ui(280)
	if self.EmbeddedInMainMenu then
		tileH = traitor_ui(245)
	end
	for i, tile in ipairs(self.Tiles) do
		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)

		tile.BaseX = col * (tileW + gap)
		tile.BaseY = row * (tileH + gap)
		tile:SetPos(tile.BaseX, tile.BaseY)
		tile:SetSize(tileW, tileH)
	end

	local rows = math.ceil(#self.Tiles / cols)
	self.Scroll:GetCanvas():SetTall(rows * (tileH + gap))
end

function PANEL:Paint(w, h)
	local pulse = 0.5 + math.sin((SysTime() - self.OpenTime) * 2.2) * 0.5
	local sweepY = (SysTime() * traitor_ui(42)) % (h + traitor_ui(90)) - traitor_ui(90)

	if self.EmbeddedInMainMenu then
		drawCutPoly(0, 0, w, h, traitor_ui(16), Color(2, 8, 5, 196))
	else
		drawCutPoly(0, 0, w, h, traitor_ui(20), Color(2, 8, 5, 242))
	end

	surface.SetDrawColor(0, 0, 0, 120)
	surface.DrawRect(0, 0, w, h)
	drawCutOutline(0, 0, w, h, self.EmbeddedInMainMenu and traitor_ui(16) or traitor_ui(20), Color(traitorTileAccent.r, traitorTileAccent.g, traitorTileAccent.b, 90 + pulse * 50), 1)
	drawCornerBrackets(0, 0, w, h, traitor_ui(34), Color(35, 255, 110, self.EmbeddedInMainMenu and 115 or 150))

	surface.SetDrawColor(8, 45, 25, 120)
	surface.SetMaterial(traitorGradientD)
	surface.DrawTexturedRect(0, 0, w, h)

	surface.SetDrawColor(traitorTileAccent.r, traitorTileAccent.g, traitorTileAccent.b, 14)
	for y = 0, h, traitor_ui(28) do
		surface.DrawRect(0, y, w, 1)
	end

	surface.SetDrawColor(35, 255, 110, 16)
	surface.DrawRect(traitor_ui(14), sweepY, w - traitor_ui(28), traitor_ui(2))

	local headerH = traitor_ui(94)
	surface.SetDrawColor(1, 18, 10, 225)
	surface.DrawRect(0, 0, w, headerH)
	surface.SetDrawColor(traitorTileAccent.r, traitorTileAccent.g, traitorTileAccent.b, 42)
	surface.DrawRect(traitor_ui(28), headerH - 1, w - traitor_ui(56), 1)
	surface.SetDrawColor(135, 255, 178, 120)
	surface.DrawRect(traitor_ui(28), headerH - traitor_ui(5), w - traitor_ui(56), 1)

	draw.SimpleText("TRAITOR ROLE SELECTOR", "HMCD_TraitorTiles_Title", traitor_ui(34), traitor_ui(13), traitorTileText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText("SELECT LOADOUT PROFILE", "HMCD_TraitorTiles_Code", traitor_ui(37), traitor_ui(55), Color(35, 255, 110, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function PANEL:Close()
	if self.Closing then return end
	self.Closing = true
	self:AlphaTo(0, 0.1, 0, function()
		if IsValid(self) then
			self:Remove()
		end
	end)
end

vgui.Register("HMCD_TraitorTileMenu", PANEL, "EditablePanel")

local PANEL = {}

function PANEL:SetRoleData(data)
	self.RoleData = data
	self.Hover = 0
	self.StdButton = vgui.Create("DButton", self)
	self.SoeButton = vgui.Create("DButton", self)
	self.Description = vgui.Create("DLabel", self)
	self.Description:SetText(data.Description or "")
	self.Description:SetFont("HMCD_TraitorTiles_Text")
	self.Description:SetTextColor(traitorTileMuted)
	self.Description:SetWrap(true)
	self.Description:SetContentAlignment(7)
	self.Description:SetMouseInputEnabled(false)

	self:SetupModeButton(self.StdButton, "STD", "standard", data.Standard)
	self:SetupModeButton(self.SoeButton, "SOE", "soe", data.SOE)
end

function PANEL:SetupModeButton(button, label, mode, role)
	button:SetText("")
	button.ModeLabel = label
	button.Mode = mode
	button.Role = role
	button:SetEnabled(role ~= nil)
	button.DoClick = function(btn)
		if not btn.Role then return end

		set_role(btn.Role, btn.Mode)
		surface.PlaySound("buttons/button14.wav")
	end
	button.Paint = function(btn, w, h)
		local selected = btn.Mode == "soe" and MODE.ConVar_SubRole_Traitor_SOE:GetString() == btn.Role or MODE.ConVar_SubRole_Traitor:GetString() == btn.Role
		local enabled = btn.Role ~= nil
		local hover = enabled and btn:IsHovered() and 1 or 0
		local cut = traitor_ui(10)

		local bg = selected and Color(15, 165, 82, 205) or Color(2 + hover * 8, 17 + hover * 28, 10 + hover * 14, enabled and 226 or 120)
		drawCutPoly(0, 0, w, h, cut, bg)

		local border = selected and traitorTileAccent or (enabled and Color(75, 135, 92, 180) or Color(65, 70, 65, 130))
		drawCutOutline(0, 0, w, h, cut, border, selected and 2 or 1)

		local text = enabled and btn.ModeLabel or (btn.ModeLabel .. " N/A")
		local mainColor = enabled and (selected and color_white or traitorTileText) or Color(105, 110, 105)

		if enabled then
			local stats = getTraitorRoleStats(btn.Role)
			local rate = getTraitorWinratePercent(stats)
			local statText = rate and (rate .. "% / " .. stats.games .. "R") or "--"

			draw.SimpleText(text, "HMCD_TraitorTiles_Button", w * 0.5, h * 0.36, mainColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText(statText, "HMCD_TraitorTiles_Code", w * 0.5, h * 0.68, selected and Color(220, 255, 232, 230) or Color(135, 190, 154, 205), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		else
			draw.SimpleText(text, "HMCD_TraitorTiles_Button", w * 0.5, h * 0.5, mainColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		if selected then
			drawGlowLine(traitor_ui(14), h - 3, w - traitor_ui(28), 1, Color(145, 255, 185, 220))
		elseif hover > 0 then
			drawGlowLine(traitor_ui(16), h - 2, (w - traitor_ui(32)) * hover, 1, Color(35, 255, 110, 130))
		end
	end
end

function PANEL:PerformLayout(w, h)
	local pad = traitor_ui(18)
	local btnGap = traitor_ui(10)
	local btnH = traitor_ui(42)
	local btnW = (w - pad * 2 - btnGap) * 0.5

	self.StdButton:SetPos(pad, h - pad - btnH)
	self.StdButton:SetSize(btnW, btnH)
	self.SoeButton:SetPos(pad + btnW + btnGap, h - pad - btnH)
	self.SoeButton:SetSize(btnW, btnH)
	self.Description:SetPos(pad, traitor_ui(96))
	self.Description:SetSize(w - pad * 2, h - traitor_ui(164))
end

function PANEL:Think()
	local deepHover = panelHoveredDeep(self)
	self.Hover = LerpFT(0.14, self.Hover or 0, deepHover and 1 or 0)

	if deepHover and IsValid(self.OwnerSelector) then
		self.OwnerSelector:SetDetailRole(self.RoleData, false)
	end

	local reveal = math.Clamp((SysTime() - (self.RevealStart or SysTime())) / 0.22, 0, 1)
	reveal = 1 - (1 - reveal) * (1 - reveal)
	self:SetAlpha(255 * reveal)

	if self.BaseX and self.BaseY then
		self:SetPos(self.BaseX + (1 - reveal) * traitor_ui(34), self.BaseY)
	end
end

function PANEL:OnMousePressed(code)
	if code == MOUSE_LEFT and IsValid(self.OwnerSelector) then
		self.OwnerSelector:SetDetailRole(self.RoleData, true)
	end
end

function PANEL:Paint(w, h)
	local data = self.RoleData or {}
	local hover = self.Hover or 0
	local selectedStd = data.Standard and MODE.ConVar_SubRole_Traitor:GetString() == data.Standard
	local selectedSoe = data.SOE and MODE.ConVar_SubRole_Traitor_SOE:GetString() == data.SOE
	local selected = selectedStd or selectedSoe
	local cut = traitor_ui(18)
	local t = SysTime() + (self.TileIndex or 1) * 0.37
	local pulse = 0.5 + math.sin(t * 2.3) * 0.5

	drawCutPoly(0, 0, w, h, cut, Color(0, 0, 0, 145 + hover * 40))
	drawCutPoly(1, 1, w - 2, h - 2, cut, selected and Color(4, 44, 23, 248) or traitorTilePanel)
	drawCutPoly(traitor_ui(7), traitor_ui(7), w - traitor_ui(14), h - traitor_ui(14), traitor_ui(12), traitorTilePanelAccent)

	local border = selected and Color(35, 255, 110, 230) or Color(35, 255, 110, 75 + hover * 90)
	drawCutOutline(0, 0, w, h, cut, border, selected and 2 or 1)

	if hover > 0 or selected then
		surface.SetDrawColor(190, 255, 210, selected and 16 or (6 + hover * 10))
		surface.DrawRect(traitor_ui(24), traitor_ui(14), w - traitor_ui(86), 1)
	end

	local scanW = traitor_ui(44)
	local scanX = ((t * traitor_ui(30)) % (w + scanW * 2)) - scanW
	surface.SetDrawColor(traitorTileAccent.r, traitorTileAccent.g, traitorTileAccent.b, selected and 4 or (1 + hover * 2))
	surface.SetMaterial(traitorGradientR)
	surface.DrawTexturedRect(scanX, traitor_ui(14), scanW, h - traitor_ui(28))

	local railH = h - traitor_ui(44)
	drawGlowLine(traitor_ui(12), traitor_ui(21), 2, railH, selected and Color(35, 255, 110, 220) or Color(35, 255, 110, 95 + hover * 80))
	draw.SimpleText(string.upper(data.Name or "UNKNOWN"), "HMCD_TraitorTiles_Role", traitor_ui(26), traitor_ui(16), traitorTileText, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	draw.SimpleText("NODE " .. string.format("%02d", self.TileIndex or 0) .. " / " .. string.upper(string.gsub(data.Base or "unknown", "traitor_", "")), "HMCD_TraitorTiles_Code", traitor_ui(27), traitor_ui(51), Color(35, 255, 110, 155), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	local combinedStats = combineTraitorRoleStats(data.Standard, data.SOE)
	local winrateText = formatTraitorWinrateShort(combinedStats)
	local rate = getTraitorWinratePercent(combinedStats)
	local winrateColor = rate and Color(100, 255, 165, 205) or Color(255, 190, 75, 150)
	draw.SimpleText(winrateText, "HMCD_TraitorTiles_Code", traitor_ui(27), traitor_ui(69), winrateColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

	local status = {}
	if selectedStd then status[#status + 1] = "STD ACTIVE" end
	if selectedSoe then status[#status + 1] = "SOE ACTIVE" end

	local statusText = #status > 0 and table.concat(status, " / ") or "PENDING"
	local statusColor = #status > 0 and traitorTileAccentHot or traitorTileAmber
	local chipFill = #status > 0 and Color(35, 255, 110, 45) or Color(255, 190, 75, 18)
	local chipBorder = #status > 0 and Color(35, 255, 110, 150) or Color(255, 190, 75, 85)

	surface.SetFont("HMCD_TraitorTiles_Code")
	local tw, th = surface.GetTextSize(statusText)
	local chipW = tw + traitor_ui(22)
	local chipH = th + traitor_ui(10)
	local chipX = w - chipW - traitor_ui(16)
	local chipY = traitor_ui(18)
	drawCutPoly(chipX, chipY, chipW, chipH, traitor_ui(6), chipFill)
	drawCutOutline(chipX, chipY, chipW, chipH, traitor_ui(6), chipBorder, 1)
	draw.SimpleText(statusText, "HMCD_TraitorTiles_Code", chipX + chipW * 0.5, chipY + chipH * 0.5, Color(statusColor.r, statusColor.g, statusColor.b, #status > 0 and 230 or 175), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

vgui.Register("HMCD_TraitorRoleTile", PANEL, "EditablePanel")

--\\SubRole View Panel
local PANEL = {}

function PANEL:Construct()
	self:SetSkin(hg.GetMainSkin())
	
	self.Title = self.Title or "No title"
	local width, height = self:GetSize()
	local dock_bottom = 5
	
	local label_name = vgui.Create("DLabel", self)
	label_name.ZRolePanel = self
	local label_name_height = 50--height / 5
	height = height - label_name_height - dock_bottom
	label_name:SetText("")
	label_name:SetSkin(hg.GetMainSkin())
	label_name:DockMargin(0, 0, 0, dock_bottom)
	label_name:Dock(TOP)
	label_name:SetHeight(label_name_height)
	label_name:SetMouseInputEnabled(true)
	label_name.Paint = function(sel, w, h)
		if((self.Mode == "soe" and MODE.ConVar_SubRole_Traitor_SOE:GetString() == self.Role) or (self.Mode != "soe" and MODE.ConVar_SubRole_Traitor:GetString() == self.Role))then
			surface.SetDrawColor(vgui_color_main)
			surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 3)
		end
		
		surface.SetFont("ZB_InterfaceMedium")

		local tw, th = surface.GetTextSize(self.Title)
		
		surface.SetTextColor(255, 255, 255)
		surface.SetTextPos(w / 2 - tw / 2, h / 2 - th / 2)
		surface.DrawText(self.Title)
	end
	
	label_name.DoClick = function(sel)
		set_role(self.Role, self.Mode or "soe")
	end
	
	local text_description = vgui.Create("RichText", self)
	text_description.ZRolePanel = self
	text_description:SetText(self.Description)
	text_description:SetSkin(hg.GetMainSkin())
	text_description:Dock(FILL)
	text_description.PerformLayout = function(sel)
		if(sel:GetFont() != "ZB_InterfaceSmall")then
			sel:SetFontInternal("ZB_InterfaceSmall")
		end
		
		sel:SetFGColor(color_white)
	end
	text_description.Paint = function(sel, w, h)
		
	end
end

function PANEL:PaintOver(w, h)

end

local tex_gradient = surface.GetTextureID("vgui/gradient-d")
local mata = Material("vgui/traitor_icons/traitor_icon.png")

local rolesmaterials = {
	["traitor_default_soe"] = Material("vgui/traitor_icons/traitor_icon.png"),
}

local glow = Material("homigrad/vgui/models/circle.png")

function PANEL:PostPaintPanel(w, h)
	/*if((self.Mode == "soe" and MODE.ConVar_SubRole_Traitor_SOE:GetString() == self.Role) or (self.Mode != "soe" and MODE.ConVar_SubRole_Traitor:GetString() == self.Role))then
		local y_start = 0
		
		surface.SetDrawColor(vgui_color_main)
		//surface.SetTexture(tex_gradient)
		surface.SetMaterial(mata)
		surface.DrawTexturedRect(0, -100, w, h + 200)
	end*/
	if rolesmaterials[self.Role] then
		//surface.SetDrawColor(vgui_color_main)
		//surface.SetMaterial(rolesmaterials[self.Role])
		//surface.DrawTexturedRect(0, -100, w, h + 200)

		--[[ --whatever
        render.SetStencilWriteMask(0xFF)
        render.SetStencilTestMask(0xFF)
        render.SetStencilReferenceValue(0)
        render.SetStencilCompareFunction(STENCIL_NEVER)
        render.SetStencilPassOperation(STENCIL_KEEP)
        render.SetStencilFailOperation(STENCIL_KEEP)
        render.SetStencilZFailOperation(STENCIL_KEEP)
        render.ClearStencil()
        
        render.SetStencilEnable(true)
        render.SetStencilReferenceValue(1)
        render.SetStencilFailOperation(STENCIL_REPLACE)

		surface.SetDrawColor(Color(255, 255, 255, 255))
		surface.SetMaterial(glow)
		local x, y = self:ScreenToLocal(gui.MouseX() - 0, gui.MouseY() - 0)
		draw.Circle( x, y, 200, 16 )

        render.SetStencilFailOperation(STENCIL_KEEP)
        render.SetStencilCompareFunction(STENCIL_EQUAL)

		surface.SetDrawColor(Color(255, 0, 0, 50))
		surface.SetMaterial(rolesmaterials[self.Role])
		surface.DrawTexturedRect(0, -100, w, h + 200)

		render.SetStencilEnable( false )--]]
	end
end

derma.DefineControl("HMCD_RolePanel", "", PANEL, "DPanel")
--||Sub role carousel
local PANEL = {}

function PANEL:Construct()
	self:SetSkin(hg.GetMainSkin())
	
	self.RolesIDsList = self.RolesIDsList or MODE.RoleChooseRoundTypes["standard"].Traitor
	local width, height = self:GetSize()
	local dock_bottom = 5
	
	local hscroll = vgui.Create("ZHorizontalScroller", self)
	local hscroll_height = height - 50
	height = height - hscroll_height
	hscroll:SetHeight(hscroll_height)
	hscroll:SetSkin(hg.GetMainSkin())
	hscroll:DockMargin(0, 0, 0, dock_bottom)
	hscroll:Dock(TOP)
	hscroll:SetOverlap(-10)
	-- hscroll:SetUseLiveDrag(true)
	-- hscroll:InvalidateParent(false)
	for role_id, _ in pairs(self.RolesIDsList) do
		local role_info = MODE.SubRoles[role_id]
		local role_name = role_info.Name
		local role_description = role_info.Description
		
		local role_panel = vgui.Create("HMCD_RolePanel", hscroll)
		role_panel.Title = role_name
		role_panel.Description = role_description
		role_panel.Role = role_id
		role_panel.Mode = self.Mode or "soe"
		role_panel:SetWidth(ScreenScale(170))
		-- role_panel:SetHeight(hscroll_height)
		-- role_panel:InvalidateParent(false)
		role_panel:Construct()
		
		hscroll:AddPanel(role_panel)
	end
	
	local button_ready = vgui.Create("DButton", self)
	button_ready:Dock(FILL)
	button_ready:SetSkin(hg.GetMainSkin())
	button_ready:SetText("APPLY")
	button_ready.DoClick = function(sel)
		//if(sel.Clicked)then
			if(IsValid(VGUI_HMCD_RolePanelList))then
				VGUI_HMCD_RolePanelList:Remove()
			end
		//end
		
		//sel.Clicked = true
		
		//net.Start("HMCD(StartPlayersRoleSelection)")
		//net.SendToServer()
	end
	button_ready.Paint = function(sel, w, h)
		if(sel.Clicked)then
			surface.SetDrawColor(vgui_color_ready)
		else
			surface.SetDrawColor(vgui_color_notready)
		end
		
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(255, 255, 255, 10)
		surface.DrawRect(0, 0, w, h * 0.45)
		surface.SetDrawColor(color_black)
		surface.DrawOutlinedRect(0, 0, w, h)
	end
end

function PANEL:Paint()
	
end

derma.DefineControl("HMCD_RolePanelList", "", PANEL, "DPanel")
--//

--\\Manual Click detection
local delta = 0
hook.Add("CreateMove", "HMCD_RolePanelClick", function(cmd)
	local dlta = (input.WasMousePressed(MOUSE_WHEEL_DOWN) and -1) or (input.WasMousePressed(MOUSE_WHEEL_UP) and 1) or 0

	delta = LerpFT(0.05, delta, dlta)
	local delta = delta * 2

	if(math.abs(delta) > 0.01)then
		local hovered_panel = vgui.GetHoveredPanel()

		local parent_panel = IsValid(hovered_panel) and hovered_panel:GetParent()
		local parent_panel2 = IsValid(parent_panel) and parent_panel:GetParent()
		local parent_panel3 = IsValid(parent_panel2) and parent_panel2:GetParent()
		local parent_panel4 = IsValid(parent_panel3) and parent_panel3:GetParent()
		local parent_panel5 = IsValid(parent_panel4) and parent_panel4:GetParent()

		if IsValid(hovered_panel) and hovered_panel.OnMouseWheeled then
			hovered_panel:OnMouseWheeled(delta)
		end

		if IsValid(parent_panel) and parent_panel.OnMouseWheeled then
			parent_panel:OnMouseWheeled(delta)
		end

		if IsValid(parent_panel2) and parent_panel2.OnMouseWheeled then
			parent_panel2:OnMouseWheeled(delta)
		end

		if IsValid(parent_panel3) and parent_panel3.OnMouseWheeled then
			parent_panel3:OnMouseWheeled(delta)
		end

		if IsValid(parent_panel4) and parent_panel4.OnMouseWheeled then
			parent_panel4:OnMouseWheeled(delta)
		end

		if IsValid(parent_panel5) and parent_panel5.OnMouseWheeled then
			parent_panel5:OnMouseWheeled(delta)
		end
	end

	if(input.WasMousePressed(MOUSE_LEFT))then
			-- print("Left mouse button was pressed")
		local hovered_panel = vgui.GetHoveredPanel()
		
		if(IsValid(hovered_panel) and IsValid(hovered_panel.ZRolePanel))then
			set_role(hovered_panel.ZRolePanel.Role, hovered_panel.ZRolePanel.Mode)
		end
	end
end)
--//

--\\https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/vgui/dhorizontalscroller.lua
local PANEL = {}

AccessorFunc( PANEL, "m_iOverlap",			"Overlap" )
AccessorFunc( PANEL, "m_bShowDropTargets",	"ShowDropTargets", FORCE_BOOL )

function PANEL:Init()

	self.Panels = {}
	self.OffsetX = 0
	self.FrameTime = 0

	self.pnlCanvas = vgui.Create( "DDragBase", self )
	self.pnlCanvas:SetDropPos( "6" )
	self.pnlCanvas:SetUseLiveDrag( false )
	self.pnlCanvas.OnModified = function() self:OnDragModified() end

	self.pnlCanvas.UpdateDropTarget = function( Canvas, drop, pnl )
		if ( !self:GetShowDropTargets() ) then return end
		DDragBase.UpdateDropTarget( Canvas, drop, pnl )
	end

	self.pnlCanvas.OnChildAdded = function( Canvas, child )

		local dn = Canvas:GetDnD()
		if ( dn ) then

			child:Droppable( dn )
			child.OnDrop = function()

				local x, y = Canvas:LocalCursorPos()
				local closest, id = self.pnlCanvas:GetClosestChild( x, Canvas:GetTall() / 2 ), 0

				for k, v in pairs( self.Panels ) do
					if ( v == closest ) then id = k break end
				end

				table.RemoveByValue( self.Panels, child )
				table.insert( self.Panels, id, child )

				self:InvalidateLayout()

				return child

			end
		end

	end

	self:SetOverlap( 0 )

	self.btnLeft = vgui.Create( "DButton", self )
	self.btnLeft:SetText( "" )
	self.btnLeft.Paint = function( panel, w, h ) derma.SkinHook( "Paint", "ButtonLeft", panel, w, h ) end

	self.btnRight = vgui.Create( "DButton", self )
	self.btnRight:SetText( "" )
	self.btnRight.Paint = function( panel, w, h ) derma.SkinHook( "Paint", "ButtonRight", panel, w, h ) end

end

function PANEL:GetCanvas()
	return self.pnlCanvas
end

function PANEL:ScrollToChild( panel )

	-- make sure our size is all good
	self:InvalidateLayout( true )

	local x, y = self.pnlCanvas:GetChildPosition( panel )
	local w, h = panel:GetSize()

	x = x + w * 0.5
	x = x - self:GetWide() * 0.5

	self:SetScroll( x )

end

function PANEL:SetScroll( x )

	self.OffsetX = x
	self:InvalidateLayout( true )

end

function PANEL:SetUseLiveDrag( bool )
	self.pnlCanvas:SetUseLiveDrag( bool )
end

function PANEL:MakeDroppable( name, allowCopy )
	self.pnlCanvas:MakeDroppable( name, allowCopy )
end

function PANEL:AddPanel( pnl )

	table.insert( self.Panels, pnl )

	pnl:SetParent( self.pnlCanvas )
	self:InvalidateLayout( true )

end

function PANEL:Clear()
	self.pnlCanvas:Clear()
	self.Panels = {}
end

function PANEL:OnMouseWheeled( dlta )

	self.OffsetX = self.OffsetX + dlta * -30
	self:InvalidateLayout( true )

	return true

end

function PANEL:Think()

	-- Hmm.. This needs to really just be done in one place
	-- and made available to everyone.
	local FrameRate = VGUIFrameTime() - self.FrameTime
	self.FrameTime = VGUIFrameTime()

	if ( self.btnRight:IsDown() ) then
		self.OffsetX = self.OffsetX + ( 500 * FrameRate )
		self:InvalidateLayout( true )
	end

	if ( self.btnLeft:IsDown() ) then
		self.OffsetX = self.OffsetX - ( 500 * FrameRate )
		self:InvalidateLayout( true )
	end

	if ( dragndrop.IsDragging() ) then

		local x, y = self:LocalCursorPos()

		if ( x < 30 ) then
			self.OffsetX = self.OffsetX - ( 350 * FrameRate )
		elseif ( x > self:GetWide() - 30 ) then
			self.OffsetX = self.OffsetX + ( 350 * FrameRate )
		end

		self:InvalidateLayout( true )

	end

end

function PANEL:PerformLayout()

	local w, h = self:GetSize()

	self.pnlCanvas:SetTall( h )

	local x = 0

	for k, v in pairs( self.Panels ) do
		if ( !IsValid( v ) ) then continue end
		if ( !v:IsVisible() ) then continue end

		v:SetPos( x, 0 )
		v:SetTall( h )
		if ( v.ApplySchemeSettings ) then v:ApplySchemeSettings() end

		x = x + v:GetWide() - self.m_iOverlap

	end

	self.pnlCanvas:SetWide( x + self.m_iOverlap )

	if ( w < self.pnlCanvas:GetWide() ) then
		self.OffsetX = math.Clamp( self.OffsetX, 0, self.pnlCanvas:GetWide() - self:GetWide() )
	else
		self.OffsetX = 0
	end

	self.pnlCanvas.x = self.OffsetX * -1

	self.btnLeft:SetSize( 15, 15 )
	self.btnLeft:AlignLeft( 4 )
	self.btnLeft:AlignBottom( 5 )

	self.btnRight:SetSize( 15, 15 )
	self.btnRight:AlignRight( 4 )
	self.btnRight:AlignBottom( 5 )

	self.btnLeft:SetVisible( self.pnlCanvas.x < 0 )
	self.btnRight:SetVisible( self.pnlCanvas.x + self.pnlCanvas:GetWide() > self:GetWide() )

end

function PANEL:OnDragModified()
	-- Override me
end

derma.DefineControl( "ZHorizontalScroller", "", PANEL, "Panel" )
--//
