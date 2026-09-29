local PANEL = {}
local current_panel
local menuFontW, menuFontH

local CRT_R, CRT_G, CRT_B = 35, 225, 110
local TRAITOR_R, TRAITOR_G, TRAITOR_B = 225, 35, 35
local color_crt = Color(CRT_R, CRT_G, CRT_B)
local color_crt_soft = Color(160, 255, 200)
local color_idle = Color(172, 180, 174)
local color_idle_dim = Color(118, 126, 122)
local color_bezel = Color(8, 9, 9)
local color_text = Color(220, 220, 220)
local color_gold = Color(220, 175, 55)
local color_faint = Color(255, 255, 255, 38)

local MM_PAD = 4
local MM_BEZEL = 3

local GITHUB_URL = "GITHUB.COM/REALZORF/VOTTURS-ZCITY"
local DISCORD_URL = "https://discord.gg/votturzcity"

local function MenuScale(size)
	local scale = math.Clamp(math.min(ScrW() / 1920, ScrH() / 1080), 0.78, 1.15)
	return math.Round(size * scale)
end

local function DrawCRTCorners(x, y, w, h, len, r, g, b, a)
	surface.SetDrawColor(r, g, b, a)
	surface.DrawRect(x, y, len, 2)
	surface.DrawRect(x, y, 2, len)
	surface.DrawRect(x + w - len, y, len, 2)
	surface.DrawRect(x + w - 2, y, 2, len)
	surface.DrawRect(x, y + h - 2, len, 2)
	surface.DrawRect(x, y + h - len, 2, len)
	surface.DrawRect(x + w - len, y + h - 2, len, 2)
	surface.DrawRect(x + w - 2, y + h - len, 2, len)
end

local function PlayMenuSound(path, vol)
	local ply = LocalPlayer()
	if IsValid(ply) then
		ply:EmitSound(path, 75, 100, vol)
	else
		surface.PlaySound(path)
	end
end

local Selects = {
	{Title = "Disconnect", Danger = true, Func = function() RunConsoleCommand("disconnect") end},
	{Title = "Main Menu", Func = function(luaMenu)
		gui.ActivateGameUI()
		luaMenu:Close()
	end},
	{Title = "Workshop Collection", Func = function()
		gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3715931702")
	end},
	{Title = "Discord", Func = function() gui.OpenURL(DISCORD_URL) end},
	{Title = "Guide", Func = function()
		gui.OpenURL("https://docs.google.com/document/d/1oVOleCQSrbfWddLKOgjAKD-EKpbS1dxCfNdCSUwNfn4")
	end},
	{Title = "Traitor Role", GamemodeOnly = true, OpensPanel = true, Func = function(luaMenu, pp)
		if hg.SelectPlayerRole then hg.SelectPlayerRole("Traitor", nil, pp) end
	end},
	{Title = "Achievements", OpensPanel = true, Func = function(luaMenu, pp)
		hg.DrawAchievmentsMenu(pp)
	end},
	{Title = "Appearance", OpensPanel = true, Func = function(luaMenu, pp)
		hg.CreateApperanceMenu(pp)
	end},
	{Title = "Settings", OpensPanel = true, Func = function(luaMenu, pp)
		hg.DrawSettings(pp)
	end},
	{Title = "Keybinds", Featured = true, OpensPanel = true, Func = function(luaMenu, pp)
		if hg.DrawKeybinds then hg.DrawKeybinds(pp) end
	end},
	{Title = "Rules", Func = function() RunConsoleCommand("ulx", "motd") end},
	{Title = "Store", Func = function() RunConsoleCommand("say", "!store") end},
	{Title = "Support Us", Support = true, Func = function() gui.OpenURL("https://ko-fi.com/votturzcity") end},
	{Title = "Return", Func = function(luaMenu) luaMenu:Close() end},
}

local splasheh = {
	"100% LUA, 200% SPAGHETTI",
	"IT WORKS ON MY SERVER",
	"FEATURE OR BUG? YES.",
	"SOURCE MOMENT",
	"THE MAP IS FINE",
	"NO ERRORS (YET)",
	"WHO TOUCHED THE CONFIG",
	"IF IT LAGS, ITS IMMERSION",
	"ADMINS ARE WATCHING",
	"THE LOGS KNOW EVERYTHING",
	"SERVER RESTARTING AGAIN IN 3",
	"HE WAS JUST STANDING THERE",
	"THE RDM WAS ACCIDENTAL",
	"FUCK THE KARMA SYSTEM",
	"NOTHING EVER HAPPENED",
	"WE SAW THAT",
	"SOMEONE CHECK THE LOGS",
	"MORE FPS SOON™",
	"GM_CONSTRUCT IS PEAK",
	"MAP CHANGE IN 5 MINUTES",
	"ANGERED SUX",
	"LAST ROUND, I SWEAR",
	"EVERYTHING IS CLIENTSIDED",
	"TRUST THE LUA",
	"THIS IS FINE",
	"NO CLIP? NO PROBLEM.",
	"WAKE UP, NEW ZCITY UPDATE",
	"PLUV APPROVED",
	"CERTIFIED SOURCE JANK",
	"UNPAID LUA INTERN",
	"MISSING TEXTURE ENJOYER",
	"DON'T LOOK AT THE CONSOLE",
	"IT'S A FEATURE",
	"YOUR PING IS A SKILL ISSUE",
	"ABSOLUTELY NO EXPLOITS",
	"JUST ONE MORE HOTFIX",
	"Слава Україні! Героям слава!",
	"VOTTURS IN S&BOX SOON™",
	"HL3 CONFIRMED",
	"PURPLE AND BLACK NEVER DIES",
	"WHY IS MY FPS 12",
	"WHY IS GMOD USING 1 CPU",
	"MULTICORE RENDERING: MAYBE",
	"I AM THE ADMIN NOW",
	"THERES SOMETHING BEHIND YOU",
	"ABUSE YOUR POWERS RESPONSIBLY",
	"THE DETECTIVE IS DEAD",
	"THE TRAITOR IS PROBABLY YOU",
	"I THOUGHT HE WAS TRAITOR",
	"I SWEAR HE WAS TRAITOR",
	"SELF DEFENSE BTW",
	"IT WAS AN ACCIDENT",
	"HE LOOKED SUSPICIOUS",
	"HE WAS ACTING WEIRD",
	"HE WALKED TOWARDS ME",
	"HE LOOKED AT ME FUNNY",
	"WELCOME TO VOTTUR'S Z-CITY",
	"ANOTHER DAY IN Z-CITY",
	"VOTTUR IS WATCHING",
	"VOTTUR KNOWS",
	"ANGERED STILL SUCKS",
	"KARMA IS A SOCIAL CONSTRUCT",
	"TICKRATE IS JUST A NUMBER",
	"REMORSE IS A STRONG WORD FOR 'OBSESSED FAN'",
	"WORKS PERFECTLY IN DEVELOPMENT",
}

local Pluv = Material("pluv/pluvkid.jpg")

function PANEL:Init()
	if menuFontW ~= ScrW() or menuFontH ~= ScrH() then
		menuFontW, menuFontH = ScrW(), ScrH()
		surface.CreateFont("ZC_MM_Title", {
			font = "Bahnschrift",
			size = MenuScale(72),
			weight = 800,
			extended = true,
			antialias = true
		})
		surface.CreateFont("ZC_MM_Button", {
			font = "Bahnschrift",
			size = MenuScale(26),
			weight = 600,
			extended = true,
			antialias = true
		})
		surface.CreateFont("ZC_MM_Tiny", {
			font = "Bahnschrift",
			size = MenuScale(15),
			weight = 500,
			extended = true,
			antialias = true
		})
	end

	self:SetAlpha(0)
	self:SetSize(ScrW(), ScrH())
	self:Center()
	self:SetTitle("")
	self:SetDraggable(false)
	self:SetBorder(false)
	self:SetColorBG(Color(8, 11, 10, 248))
	self:SetColorBR(Color(CRT_R, CRT_G, CRT_B, 180))
	if self.SetBlurStrengh then
		self:SetBlurStrengh(4)
	end
	self:ShowCloseButton(false)
	if IsValid(self.lblTitle) then
		self.lblTitle:SetVisible(false)
	end
	for _, key in ipairs({"btnClose", "btnMaxim", "btnMinim"}) do
		if IsValid(self[key]) then
			self[key]:SetVisible(false)
		end
	end

	current_panel = nil
	self.SplashText = splasheh[math.random(#splasheh)]
	if hg.PluvTown and hg.PluvTown.Active and hg.PluvTown.PluvMats then
		self.SelectedPluv = table.Random(hg.PluvTown.PluvMats)
	end

	timer.Simple(0, function()
		if IsValid(self) and self.First then
			self:First()
		end
	end)

	local maxWidth = math.min(ScrW() * 0.32, 640)
	local sidebarW = math.Clamp(MenuScale(480), math.min(340, maxWidth), maxWidth)
	local sidebarX = MenuScale(24)
	local sidebarY = MenuScale(24)
	local sidebarH = ScrH() - sidebarY * 2
	local innerPad = MenuScale(22)
	local brandRowY = innerPad + MenuScale(96)
	local tagY = brandRowY + MenuScale(12)
	local navTop = tagY + MenuScale(28)
	local footerBlockH = MenuScale(76)
	local footerY = sidebarH - footerBlockH - MenuScale(18)
	self.SidebarLayout = {
		brandRowY = brandRowY,
		tagY = tagY,
		navTop = navTop,
		footerY = footerY,
		footerBlockH = footerBlockH,
	}

	self.lDock = vgui.Create("DPanel", self)
	local lDock = self.lDock
	lDock:SetPos(sidebarX, sidebarY)
	lDock:SetSize(sidebarW, sidebarH)
	lDock.Paint = function(this, w, h)
		surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, 204)
		surface.DrawRect(0, 0, w, h)
		local ix, iy, iw, ih = MM_BEZEL, MM_BEZEL, w - MM_BEZEL * 2, h - MM_BEZEL * 2
		surface.SetDrawColor(CRT_R, CRT_G, CRT_B, 178)
		surface.DrawOutlinedRect(ix, iy, iw, ih, 1)
		DrawCRTCorners(ix, iy, iw, ih, 10, CRT_R, CRT_G, CRT_B, 242)
		surface.SetDrawColor(0, 0, 0, 115)
		surface.DrawRect(ix + MM_PAD, iy + MM_PAD, iw - MM_PAD * 2, ih - MM_PAD * 2)

		local layout = self.SidebarLayout
		local brandRowY = layout.brandRowY
		if hg.PluvTown and hg.PluvTown.Active then
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(self.SelectedPluv or Pluv)
			surface.DrawTexturedRect(innerPad, brandRowY - MenuScale(36), MenuScale(56), MenuScale(42))
			draw.SimpleText("ZCITY", "ZC_MM_Title", innerPad + MenuScale(64), brandRowY, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
		else
			surface.SetFont("ZC_MM_Title")
			local votturW = surface.GetTextSize("VOTTUR'S")
			draw.SimpleText("VOTTUR'S", "ZC_MM_Title", innerPad, brandRowY, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
			draw.SimpleText("ZCITY", "ZC_MM_Title", innerPad + votturW + MenuScale(18), brandRowY, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
		end

		draw.SimpleText(self.SplashText, "ZC_MM_Tiny", w * 0.5, layout.tagY, color_idle_dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end

	local visibleSelects = {}
	for _, v in ipairs(Selects) do
		if v.GamemodeOnly and engine.ActiveGamemode() ~= "zcity" then continue end
		visibleSelects[#visibleSelects + 1] = v
	end

	local buttonGap = MenuScale(4)
	local layout = self.SidebarLayout
	local navTop = layout.navTop
	local navBottom = layout.footerY - MenuScale(8)
	local navAvail = math.max(navBottom - navTop, MenuScale(24))
	local count = math.max(#visibleSelects, 1)
	local buttonHeight = math.min(MenuScale(40), math.floor((navAvail - buttonGap * count) / count))
	buttonHeight = math.max(buttonHeight, MenuScale(24))
	local buttonDockH = count * (buttonHeight + buttonGap)
	self.ButtonHeight = buttonHeight

	self.Buttons = {}
	local buttonDock = vgui.Create("DPanel", lDock)
	buttonDock:SetPos(innerPad, navTop)
	buttonDock:SetSize(sidebarW - innerPad * 2, buttonDockH)
	buttonDock:SetPaintBackground(false)
	buttonDock.Paint = function() end

	for _, v in ipairs(visibleSelects) do
		self:AddSelect(buttonDock, v.Title, v)
	end

	local bottomDock = vgui.Create("DPanel", lDock)
	bottomDock:SetPos(innerPad, layout.footerY)
	bottomDock:SetSize(sidebarW - innerPad * 2, layout.footerBlockH)
	bottomDock:SetPaintBackground(false)
	bottomDock.Paint = function() end

	local git = vgui.Create("DLabel", bottomDock)
	git:Dock(BOTTOM)
	git:DockMargin(0, MenuScale(2), 0, MenuScale(8))
	git:SetFont("ZC_MM_Tiny")
	git:SetText(GITHUB_URL)
	git:SetTextColor(color_faint)
	git:SetContentAlignment(4)
	git:SetMouseInputEnabled(true)
	git:SizeToContents()
	function git:DoClick()
		PlayMenuSound("shitty/tap_depress.wav", 0.09)
		gui.OpenURL(GITHUB_URL)
	end
	function git:Think()
		self:SetTextColor(self:IsHovered() and color_crt_soft or color_faint)
	end

	local zteam = vgui.Create("DLabel", bottomDock)
	zteam:Dock(BOTTOM)
	zteam:DockMargin(0, 0, 0, MenuScale(4))
	zteam:SetFont("ZC_MM_Tiny")
	zteam:SetTextColor(color_idle_dim)
	zteam:SetText("Vottur, Zorf, Patidinho")
	zteam:SetContentAlignment(4)
	zteam:SizeToContents()

	local contentX = sidebarX + sidebarW + MenuScale(20)
	self.ContentX = contentX
	self.ContentY = sidebarY
	self.ContentW = ScrW() - contentX - MenuScale(24)
	self.ContentH = sidebarH

	self.panelparrent = vgui.Create("DPanel", self)
	self.panelparrent:SetPos(self.ContentX, self.ContentY)
	self.panelparrent:SetSize(self.ContentW, self.ContentH)
	self.panelparrent:SetPaintBackground(false)
	self.panelparrent.Paint = function() end
end

function PANEL:RebuildContent(callback)
	local pp = self.panelparrent
	if not IsValid(pp) then return end

	pp:AlphaTo(0, 0.12, 0, function()
		if not IsValid(self) then return end
		if IsValid(pp) then
			pp:Remove()
		end

		self.panelparrent = vgui.Create("DPanel", self)
		self.panelparrent:SetPos(self.ContentX, self.ContentY)
		self.panelparrent:SetSize(self.ContentW, self.ContentH)
		self.panelparrent:SetPaintBackground(false)
		self.panelparrent.Paint = function() end
		self.panelparrent:SetAlpha(0)

		if callback then
			callback(self.panelparrent)
		end

		if IsValid(self.panelparrent) then
			self.panelparrent:AlphaTo(255, 0.12, 0)
		end
	end)
end

function PANEL:First()
	self:AlphaTo(255, 0.15, 0, nil)
end

function PANEL:Paint(w, h)
	draw.RoundedBox(0, 0, 0, w, h, self.ColorBG)
	hg.DrawBlur(self, 4)

	local gridStep = MenuScale(64)
	surface.SetDrawColor(255, 255, 255, 2)
	for gx = 0, w, gridStep do
		surface.DrawRect(gx, 0, 1, h)
	end
	for gy = 0, h, gridStep do
		surface.DrawRect(0, gy, w, 1)
	end
end

function PANEL:AddSelect(pParent, strTitle, tbl)
	local id = #self.Buttons + 1
	self.Buttons[id] = vgui.Create("DButton", pParent)
	local btn = self.Buttons[id]
	btn:SetText(strTitle)
	btn:SetFont("ZC_MM_Button")
	btn:SetTextColor(Color(255, 255, 255, 0))
	btn:SetTall(self.ButtonHeight or MenuScale(40))
	btn:SetWide(pParent:GetWide())
	btn:Dock(BOTTOM)
	btn:DockMargin(0, MenuScale(4), 0, 0)
	btn.StrTitle = strTitle
	btn.Featured = tbl.Featured == true
	btn.Danger = tbl.Danger == true
	btn.Support = tbl.Support == true
	btn.Id = string.lower(strTitle)
	btn.RColor = color_idle
	btn.ActiveColor = color_text
	if btn.Featured then
		btn:SetTooltip("NEW")
	end

	local luaMenu = self

	btn.Paint = function(this, w, h)
		local isActive = current_panel == this.Id
		local v = this.HoverLerp or 0
		local r, g, b = CRT_R, CRT_G, CRT_B
		if this.Danger then
			r, g, b = TRAITOR_R, TRAITOR_G, TRAITOR_B
		elseif this.Support then
			r, g, b = color_gold.r, color_gold.g, color_gold.b
		end

		if isActive or v > 0.02 then
			surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, 180)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(r, g, b, isActive and 31 or math.floor(18 * v))
			surface.DrawRect(1, 1, w - 2, h - 2)
			surface.SetDrawColor(r, g, b, isActive and 216 or math.floor(120 + 90 * v))
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			DrawCRTCorners(0, 0, w, h, 6, r, g, b, isActive and 230 or math.floor(140 * v))
		end

		local targetCol = isActive and this.ActiveColor or Color(r, g, b)
		local textCol = this.RColor:Lerp(targetCol, isActive and 1 or v)
		local textX = MenuScale(12)
		local text = this:GetText()
		draw.SimpleText(text, "ZC_MM_Button", textX, h * 0.5, textCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

		if this.Featured then
			surface.SetFont("ZC_MM_Button")
			local textW = surface.GetTextSize(text)
			draw.SimpleText("★", "ZC_MM_Button", textX + textW + MenuScale(9), h * 0.5, color_gold, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end

	function btn:Think()
		local hovered = self:IsHovered()
		self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, (hovered or current_panel == self.Id) and 1 or 0)

		local source = current_panel == self.Id and string.upper(strTitle) or strTitle
		local ntxt = ""
		local reveal = math.ceil(#source * self.HoverLerp)
		for i = 1, #source do
			local char = source:sub(i, i)
			ntxt = ntxt .. (i <= reveal and string.upper(char) or char)
		end
		if self:GetText() ~= ntxt then
			surface.PlaySound("shitty/tap-resonant.wav")
			self:SetText(ntxt)
		end

		self:SetWide(pParent:GetWide())
		self:SetTall(luaMenu.ButtonHeight or MenuScale(40))
	end

	function btn:DoClick()
		if not tbl.OpensPanel then
			PlayMenuSound("shitty/tap_depress.wav", 0.09)
			tbl.Func(luaMenu, luaMenu.panelparrent)
			return
		end

		if current_panel == self.Id then
			PlayMenuSound("shitty/tap_release.wav", 0.05)
			luaMenu:RebuildContent()
			current_panel = nil
			return
		end

		PlayMenuSound("shitty/tap_depress.wav", 0.09)
		luaMenu:RebuildContent(function(pp)
			tbl.Func(luaMenu, pp)
			current_panel = btn.Id
		end)
	end
end

function PANEL:Close()
	self:AlphaTo(0, 0.1, 0, function()
		if IsValid(self) then
			self:Remove()
		end
	end)
	self:SetKeyboardInputEnabled(false)
	self:SetMouseInputEnabled(false)
end

vgui.Register("ZMainMenu", PANEL, "ZFrame")

hook.Add("OnPauseMenuShow", "OpenMainMenu", function()
	local run = hook.Run("OnShowZCityPause")
	if run ~= nil then
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