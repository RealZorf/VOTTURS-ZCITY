local PANEL = {}
local curent_panel 
local select_color = Color(35, 255, 110)
local menuFontW, menuFontH

local COL = {
	bg = Color(8, 11, 10, 248),
	sidebar = Color(14, 18, 16, 252),
	surface = Color(22, 28, 25, 220),
	accent = Color(35, 255, 110),
	accent_dim = Color(35, 255, 110, 45),
	accent_glow = Color(35, 255, 110, 12),
	text = Color(232, 236, 233),
	text_dim = Color(120, 135, 125),
	text_faint = Color(255, 255, 255, 38),
	border = Color(35, 255, 110, 28),
	border_strong = Color(35, 255, 110, 55),
	hover = Color(35, 255, 110, 10),
	active = Color(35, 255, 110, 18),
	shadow = Color(0, 0, 0, 90),
}

local function MenuScale(size)
    local scale = math.Clamp(math.min(ScrW() / 1920, ScrH() / 1080), 0.78, 1.15)
    return math.Round(size * scale)
end

local function MenuLeftWidth()
	local maxWidth = math.min(ScrW() * 0.32, 640)
	local minWidth = math.min(340, maxWidth)
	return math.Clamp(MenuScale(480), minWidth, maxWidth)
end

local function CreateMenuFonts()
	if menuFontW == ScrW() and menuFontH == ScrH() then return end

	menuFontW, menuFontH = ScrW(), ScrH()

	surface.CreateFont("ZC_MM_BrandSm", {
		font = "Bahnschrift",
		size = MenuScale(22),
		weight = 600,
		extended = true,
		antialias = true,
	})

	surface.CreateFont("ZC_MM_Title", {
		font = "Bahnschrift",
		size = MenuScale(72),
		weight = 800,
		extended = true,
		antialias = true,
	})

	surface.CreateFont("ZC_MM_Button", {
		font = "Bahnschrift",
		size = MenuScale(26),
		weight = 600,
		extended = true,
		antialias = true,
	})

	surface.CreateFont("ZC_MM_Tiny", {
		font = "Bahnschrift",
		size = MenuScale(15),
		weight = 500,
		extended = true,
		antialias = true,
	})

	surface.CreateFont("ZC_MM_Label", {
		font = "Bahnschrift",
		size = MenuScale(11),
		weight = 700,
		extended = true,
		antialias = true,
	})
end

local Selects = {
	{Title = "Disconnect", Func = function(luaMenu)
		RunConsoleCommand("disconnect")
	end},
	{Title = "Main Menu", Func = function(luaMenu)
		gui.ActivateGameUI()
		luaMenu:Close()
	end},
	{Title = "Workshop Collection", Func = function(luaMenu)
		luaMenu:Close()
		gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3715931702")
	end},
	{Title = "Discord", Func = function(luaMenu)
		luaMenu:Close()
		gui.OpenURL("https://discord.gg/votturzcity")
	end},
	{Title = "Support Us", Func = function(luaMenu)
		luaMenu:Close()
		gui.OpenURL("https://ko-fi.com/votturzcity")
	end},
	{Title = "Settings", Func = function(luaMenu, pp) hg.DrawSettings(pp) end},
	{Title = "Achievements", Func = function(luaMenu, pp) hg.DrawAchievmentsMenu(pp) end},
	{Title = "Appearance", Func = function(luaMenu, pp) hg.CreateApperanceMenu(pp) end},
	{Title = "Traitor Role",
		GamemodeOnly = true,
		Func = function(luaMenu, pp)
			if hg.SelectPlayerRole then
				hg.SelectPlayerRole("Traitor", nil, pp)
			end
		end,
	},
	{Title = "Return", Func = function(luaMenu) luaMenu:Close() end},
}

local splasheh = {
	'100% LUA, 200% SPAGHETTI',
	'IT WORKS ON MY SERVER',
	'FEATURE OR BUG? YES.',
	'SOURCE MOMENT',
	'THE MAP IS FINE',
	'NO ERRORS (YET)',
	'WHO TOUCHED THE CONFIG',
	'IF IT LAGS, ITS IMMERSION',
	'ADMINS ARE WATCHING',
	'THE LOGS KNOW EVERYTHING',
	'YOUR MIC IS OPEN',
	'SERVER RESTARTING AGAIN IN 3',
	'HE WAS JUST STANDING THERE',
	'DESYNC IS CANON',
	'THE RDM WAS ACCIDENTAL',
	'FUCK THE KARMA SYSTEM',
	'NOTHING EVER HAPPENED',
	'WE SAW THAT',
	'SOMEONE CHECK THE LOGS',
	'MORE FPS SOON™',
	'GM_CONSTRUCT IS PEAK',
	'MAP CHANGE IN 5 MINUTES',
	'ANGERED SUX',
	'LAST ROUND, I SWEAR',
	'YOU ARE BEING OBSERVED',
	'EVERYTHING IS CLIENTSIDED',
	'TRUST THE LUA',
	'THIS IS FINE',
	'NO CLIP? NO PROBLEM.',
	'THE DOORS ARE SENTIENT',
	'WAKE UP, NEW ZCITY UPDATE',
	'PLUV APPROVED',
	'404: BALANCE NOT FOUND',
	'CERTIFIED SOURCE JANK',
	'UNPAID LUA INTERN',
	'MISSING TEXTURE ENJOYER',
	"DON'T LOOK AT THE CONSOLE",
	"IT'S A FEATURE",
	'THE NPCS ARE PLOTTING',
	'YOUR PING IS A SKILL ISSUE',
	'ABSOLUTELY NO EXPLOITS',
	'JUST ONE MORE HOTFIX',
	'SHIP IT.',
	'JOIN OUR PLAYTEST SERVER TO BE ABUSED',
}

local Pluv = Material("pluv/pluvkid.jpg")

function PANEL:InitializeMarkup()
	local gm = splasheh[math.random(#splasheh)]

	if hg.PluvTown and hg.PluvTown.Active then
		local text = "<font=ZC_MM_Title><colour=125,205,255>    </colour>City</font>\n<font=ZC_MM_Tiny><colour=120,135,125>" .. gm .. "</colour></font>"
		self.SelectedPluv = table.Random(hg.PluvTown.PluvMats)
		return markup.Parse(text)
	end

	local text = "<font=ZC_MM_Title><colour=232,236,233,255>ZCITY</colour></font>\n<font=ZC_MM_Tiny><colour=120,135,125>" .. gm .. "</colour></font>"
	return markup.Parse(text)
end

local function DrawSidebarPanel(x, y, w, h, radius)
	draw.RoundedBox(radius, x, y, w, h, COL.sidebar)
	surface.SetDrawColor(COL.border)
	surface.DrawOutlinedRect(x, y, w, h, 1)
end

local function GetSidebarLayout(sidebarH, innerPad)
	local brandRowY = innerPad + MenuScale(64)
	local tagY = brandRowY + MenuScale(10)
	local navSeparatorY = tagY + MenuScale(30)
	local navTop = navSeparatorY + MenuScale(16)
	local footerBottomPad = MenuScale(18)
	local footerBlockH = MenuScale(76)
	local footerSeparatorY = sidebarH - footerBlockH - footerBottomPad

	return {
		brandRowY = brandRowY,
		tagY = tagY,
		navSeparatorY = navSeparatorY,
		navTop = navTop,
		footerSeparatorY = footerSeparatorY,
		footerBottomPad = footerBottomPad,
		footerBlockH = footerBlockH,
	}
end

function PANEL:Init()
	CreateMenuFonts()

	self:SetAlpha(0)
	self:SetSize(ScrW(), ScrH() + 50)
	self:Center()
	self:SetTitle("")
	self:SetDraggable(false)
	self:SetBorder(false)
	self:SetColorBG(COL.bg)
	self:ShowCloseButton(false)
	curent_panel = nil

	self.SplashText = splasheh[math.random(#splasheh)]
	self.Title, self.TitleShadow = self:InitializeMarkup()

	timer.Simple(0, function()
		if self.First then
			self:First()
		end
	end)

	local leftWidth = MenuLeftWidth()
	local sidebarPad = MenuScale(28)
	local sidebarW = leftWidth
	local sidebarX = MenuScale(24)
	local sidebarY = MenuScale(24)
	local sidebarH = ScrH() - sidebarY * 2
	local innerPad = MenuScale(22)
	local radius = MenuScale(6)

	self.lDock = vgui.Create("DPanel", self)
	local lDock = self.lDock
	lDock:SetPos(sidebarX, sidebarY)
	lDock:SetSize(sidebarW, sidebarH)
	self.SidebarLayout = GetSidebarLayout(sidebarH, innerPad)
	lDock.Paint = function(this, w, h)
		DrawSidebarPanel(0, 0, w, h, radius)

		local layout = self.SidebarLayout
		local brandRowY = layout.brandRowY
		local brandGap = MenuScale(10)

		if hg.PluvTown and hg.PluvTown.Active then
			surface.SetDrawColor(color_white)
			surface.SetMaterial(self.SelectedPluv or Pluv)
			surface.DrawTexturedRect(innerPad, brandRowY - MenuScale(36), MenuScale(56), MenuScale(42))

			draw.SimpleText("ZCITY", "ZC_MM_Title", innerPad + MenuScale(64), brandRowY, COL.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
		else
			surface.SetFont("ZC_MM_Title")
			local votturW = surface.GetTextSize("VOTTUR'S")
			draw.SimpleText("VOTTUR'S", "ZC_MM_Title", innerPad, brandRowY, COL.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
			draw.SimpleText("ZCITY", "ZC_MM_Title", innerPad + votturW + MenuScale(18), brandRowY, COL.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
		end

		draw.DrawText(self.SplashText, "ZC_MM_Tiny", innerPad, layout.tagY, COL.text_dim, TEXT_ALIGN_LEFT)

		surface.SetDrawColor(COL.border)
		surface.DrawRect(innerPad, layout.navSeparatorY, w - innerPad * 2, 1)
		surface.DrawRect(innerPad, layout.footerSeparatorY, w - innerPad * 2, 1)
	end

	local visibleSelects = {}
	for k, v in ipairs(Selects) do
		if v.GamemodeOnly and engine.ActiveGamemode() != "zcity" then continue end
		visibleSelects[#visibleSelects + 1] = v
	end

	local buttonHeight = MenuScale(42)
	local buttonGap = MenuScale(4)
	local layout = self.SidebarLayout
	local navTop = layout.navTop
	local footerHeight = layout.footerBlockH
	local footerBottomPad = layout.footerBottomPad
	local navBottom = layout.footerSeparatorY - MenuScale(8)
	local navAvail = navBottom - navTop
	local buttonDockH = math.min(#visibleSelects * (buttonHeight + buttonGap), navAvail)

	self.Buttons = {}
	local buttonDock = vgui.Create("DPanel", lDock)
	buttonDock:SetPos(innerPad, navTop)
	buttonDock:SetSize(sidebarW - innerPad * 2, buttonDockH)
	buttonDock.Paint = function(this, w, h) end

	for k, v in ipairs(visibleSelects) do
		self:AddSelect(buttonDock, v.Title, v)
	end

	local bottomDock = vgui.Create("DPanel", lDock)
	bottomDock:SetPos(innerPad, layout.footerSeparatorY + MenuScale(10))
	bottomDock:SetSize(sidebarW - innerPad * 2, footerHeight - MenuScale(10))
	bottomDock.Paint = function(this, w, h) end

	local contentX = sidebarX + sidebarW + MenuScale(20)
	self.ContentPanelPaint = function(this, w, h)
		local r = MenuScale(6)
		draw.RoundedBox(r, 0, 0, w, h, COL.surface)
		surface.SetDrawColor(COL.border)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	self.panelparrent = vgui.Create("DPanel", self)
	self.panelparrent:SetPos(contentX, sidebarY)
	self.panelparrent:SetSize(ScrW() - contentX - MenuScale(24), sidebarH)
	self.panelparrent.Paint = self.ContentPanelPaint

	local gitHubURL = "https://github.com/RealZorf/Z-City"
	local gitHubText = "GitHub.com/RealZorf/Z-City"

	local git = vgui.Create("DLabel", bottomDock)
	git:Dock(BOTTOM)
	git:DockMargin(0, MenuScale(2), 0, MenuScale(12))
	git:SetFont("ZC_MM_Tiny")
	git:SetTextColor(COL.text_faint)
	git:SetText(gitHubText)
	git:SetContentAlignment(4)
	git:SetMouseInputEnabled(true)
	git:SizeToContents()

	function git:DoClick()
		gui.OpenURL(gitHubURL)
	end

	function git:Think()
		local hov = self:IsHovered()
		self:SetTextColor(hov and COL.accent or COL.text_faint)
	end

	local zteam = vgui.Create("DLabel", bottomDock)
	zteam:Dock(BOTTOM)
	zteam:DockMargin(0, 0, 0, MenuScale(6))
	zteam:SetFont("ZC_MM_Tiny")
	zteam:SetTextColor(COL.text_dim)
	zteam:SetText("Vottur, Zorf, Patidinho")
	zteam:SetContentAlignment(4)
	zteam:SizeToContents()
end

function PANEL:First(ply)
	self:AlphaTo(255, 0.15, 0, nil)
end

function PANEL:Paint(w, h)
	draw.RoundedBox(0, 0, 0, w, h, self.ColorBG)
	hg.DrawBlur(self, 4)

	surface.SetDrawColor(COL.accent_glow)
	surface.DrawRect(0, 0, w, MenuScale(1))

	local gridStep = MenuScale(64)
	surface.SetDrawColor(255, 255, 255, 3)
	for gx = 0, w, gridStep do
		surface.DrawRect(gx, 0, 1, h)
	end
	for gy = 0, h, gridStep do
		surface.DrawRect(0, gy, w, 1)
	end
end

function PANEL:AddSelect(pParent, strTitle, tbl)
	local id = #self.Buttons + 1
	self.Buttons[id] = vgui.Create("DLabel", pParent)
	local btn = self.Buttons[id]
	btn:SetText(strTitle)
	btn:SetMouseInputEnabled(true)
	btn:SizeToContents()
	btn:SetFont("ZC_MM_Button")
	btn:SetTall(MenuScale(40))
	btn:SetWide(pParent:GetWide())
	btn:Dock(BOTTOM)
	btn:DockMargin(0, MenuScale(4), 0, 0)
	btn.Func = tbl.Func
	btn.HoveredFunc = tbl.HoveredFunc
	btn.StrTitle = strTitle
	local luaMenu = self
	if tbl.CreatedFunc then tbl.CreatedFunc(btn, self, luaMenu) end
	btn.RColor = COL.text_dim
	btn.ActiveColor = COL.text

	btn.Paint = function(this, w, h)
		local isActive = curent_panel == string.lower(strTitle)
		local v = this.HoverLerp or 0
		local pad = MenuScale(10)
		local barW = MenuScale(3)

		if isActive or v > 0.01 then
			local bgAlpha = isActive and COL.active.a or math.floor(COL.hover.a * v)
			draw.RoundedBox(MenuScale(4), 0, 0, w, h, Color(COL.hover.r, COL.hover.g, COL.hover.b, bgAlpha))
		end

		if isActive then
			draw.RoundedBox(0, 0, MenuScale(6), barW, h - MenuScale(12), COL.accent)
		elseif v > 0.01 then
			local barAlpha = math.floor(255 * v)
			draw.RoundedBox(0, 0, MenuScale(8), barW, h - MenuScale(16), Color(COL.accent.r, COL.accent.g, COL.accent.b, barAlpha))
		end

		local textCol = this.RColor:Lerp(isActive and btn.ActiveColor or select_color, isActive and 1 or v)
		draw.SimpleText(this:GetText(), "ZC_MM_Button", pad + barW + MenuScale(4), h * 0.5, textCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	function btn:DoClick()
		if curent_panel == string.lower(strTitle) then
			for i = 1, 3 do
				surface.PlaySound("shitty/tap_release.wav")
			end
			luaMenu.panelparrent:AlphaTo(0, 0.2, 0, function()
				luaMenu.panelparrent:Remove()
				luaMenu.panelparrent = nil
				luaMenu.panelparrent = vgui.Create("DPanel", luaMenu)

				luaMenu.panelparrent:SetPos(some_coordinates_x, some_coordinates_y)
				luaMenu.panelparrent:SetSize(some_size_x, some_size_y)
				luaMenu.panelparrent.Paint = luaMenu.ContentPanelPaint
				curent_panel = nil
			end)
			return
		end
		some_size_x = luaMenu.panelparrent:GetWide()
		some_size_y = luaMenu.panelparrent:GetTall()
		some_coordinates_x = luaMenu.panelparrent:GetX()
		some_coordinates_y = luaMenu.panelparrent:GetY()
		luaMenu.panelparrent:AlphaTo(0, 0.2, 0, function()
			luaMenu.panelparrent:Remove()
			luaMenu.panelparrent = nil
			luaMenu.panelparrent = vgui.Create("DPanel", luaMenu)

			luaMenu.panelparrent:SetPos(some_coordinates_x, some_coordinates_y)
			luaMenu.panelparrent:SetSize(some_size_x, some_size_y)
			luaMenu.panelparrent.Paint = luaMenu.ContentPanelPaint
			btn.Func(luaMenu, luaMenu.panelparrent)
			curent_panel = string.lower(strTitle)
		end)
		for i = 1, 3 do
			surface.PlaySound("shitty/tap_depress.wav")
		end
	end

	function btn:Think()
		self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, (self:IsHovered() or (IsValid(self:GetChild(0)) and self:GetChild(0):IsHovered()) or (IsValid(self:GetChild(0)) and IsValid(self:GetChild(0):GetChild(0)) and self:GetChild(0):GetChild(0):IsHovered())) and 1 or 0)

		local v = self.HoverLerp
		self:SetTextColor(ColorAlpha(color_white, 0))

		local targetText = (self:IsHovered()) and string.upper(strTitle) or strTitle
		local crw = self:GetText()

		if (crw ~= targetText) or (curent_panel == string.lower(strTitle)) then
			local ntxt = ""
			local will_text = (curent_panel == string.lower(strTitle) and not strTitle == 'Traitor Role') and '[ ' .. string.upper(strTitle) .. ' ]' or strTitle
			for i = 1, #will_text do
				local char = will_text:sub(i, i)
				if i <= math.ceil(#will_text * v) then
					ntxt = ntxt .. string.upper(char)
				else
					ntxt = ntxt .. char
				end
			end
			if self:GetText() ~= ntxt then
				surface.PlaySound("shitty/tap-resonant.wav")
			end
			self:SetText(ntxt)
		end
		self:SetWide(pParent:GetWide())
		self:SetTall(MenuScale(40))
	end
end

function PANEL:Close()
	self:AlphaTo(0, 0.1, 0, function() self:Remove() end)
	self:SetKeyboardInputEnabled(false)
	self:SetMouseInputEnabled(false)
end

vgui.Register("ZMainMenu", PANEL, "ZFrame")

hook.Add("OnPauseMenuShow", "OpenMainMenu", function()
	local run = hook.Run("OnShowZCityPause")
	if run != nil then
		return run
	end

	if MainMenu and IsValid(MainMenu) then
		MainMenu:Close()
		MainMenu = nil
		return false
	end

	MainMenu = vgui.Create("ZMainMenu")
	MainMenu:MakePopup()
	return false
end)
