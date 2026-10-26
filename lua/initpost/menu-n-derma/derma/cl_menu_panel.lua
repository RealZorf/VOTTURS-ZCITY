local PANEL = {}
local current_panel

local CRT_R, CRT_G, CRT_B = 35, 225, 110
local TRAITOR_R, TRAITOR_G, TRAITOR_B = 225, 35, 35
local FRAME_R, FRAME_G, FRAME_B = 86, 94, 90
local color_idle = Color(168, 172, 170)
local color_idle_dim = Color(112, 118, 116)
local color_bezel = Color(12, 13, 13)
local color_panel = Color(20, 22, 21)
local color_text = Color(236, 238, 236)
local color_gold = Color(220, 175, 55)
local color_danger = Color(TRAITOR_R, TRAITOR_G, TRAITOR_B)
local color_danger_hot = Color(255, 170, 170)
local color_faint = Color(255, 255, 255, 38)
local color_ending = Color(220, 200, 120)
local color_live = Color(CRT_R, CRT_G, CRT_B)

local BEZEL = 3
local INSET = BEZEL + 4

local GITHUB_LABEL = "GITHUB.COM/REALZORF/VOTTURS-ZCITY"
local GITHUB_URL = "https://github.com/RealZorf/Votturs-ZCity"
local DISCORD_URL = "https://discord.gg/votturzcity"

local OtherServers = {
	{Name = "EU1", Address = "91.207.248.51:27015"},
	{Name = "EU2", Address = "91.207.248.51:27016"},
	{Name = "EU3", Address = "91.207.248.51:27017"},
	{Name = "EU4", Address = "91.207.248.51:27018"},
}

local Pluv = Material("pluv/pluvkid.jpg")

local function S(n)
	return math.max(1, math.Round(n * ScrH() / 1080))
end

local function CreateMenuFonts()
	surface.CreateFont("ZC_MM_Title", {
		font = "Bahnschrift",
		size = math.max(28, S(40)),
		weight = 800,
		extended = true,
		antialias = true
	})
	surface.CreateFont("ZC_MM_Header", {
		font = "Bahnschrift",
		size = math.max(18, S(22)),
		weight = 700,
		extended = true,
		antialias = true
	})
	surface.CreateFont("ZC_MM_Button", {
		font = "Bahnschrift",
		size = math.max(16, S(22)),
		weight = 600,
		extended = true,
		antialias = true
	})
	surface.CreateFont("ZC_MM_Tiny", {
		font = "Bahnschrift",
		size = math.max(12, S(15)),
		weight = 500,
		extended = true,
		antialias = true
	})
end

CreateMenuFonts()
hook.Add("OnScreenSizeChanged", "ZMainMenu_Fonts", CreateMenuFonts)

local function DrawCRTFrame(x, y, w, h)
	surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, 230)
	surface.DrawRect(x, y, w, h)

	local ix, iy, iw, ih = x + BEZEL, y + BEZEL, w - BEZEL * 2, h - BEZEL * 2
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
	local oy = ox
	surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, 8)
	for gx = 0, math.ceil(pw / step) do
		surface.DrawRect(px + gx * step - ox, py, 2, ph)
	end
	for gy = 0, math.ceil(ph / step) do
		surface.DrawRect(px, py + gy * step - oy + step, pw, 2)
	end
end

local function DrawHeaderStrip(x, y, w, h, title, center)
	surface.SetDrawColor(32, 34, 33, 210)
	surface.DrawRect(x, y, w, h)
	surface.SetDrawColor(CRT_R, CRT_G, CRT_B, 36)
	surface.DrawRect(x, y, w, h)
	draw.SimpleText(title, "ZC_MM_Header", center and (x + w * 0.5) or (x + S(12)), y + h * 0.5, color_text, center and TEXT_ALIGN_CENTER or TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

local function MenuSound(path, vol)
	local ply = LocalPlayer()
	if IsValid(ply) then
		ply:EmitSound(path, 75, 100, vol)
	else
		surface.PlaySound(path)
	end
end

local Selects = {
	{Title = "Resume", Func = function(menu) menu:Close() end},
	{Title = "Settings", OpensPanel = true, Func = function(_, pp) hg.DrawSettings(pp) end},
	{Title = "Keybinds", OpensPanel = true, Func = function(_, pp) if hg.DrawKeybinds then hg.DrawKeybinds(pp) end end},
	{Title = "Appearance", OpensPanel = true, Func = function(_, pp) hg.CreateApperanceMenu(pp) end},
	{Title = "Traitor Role", GamemodeOnly = true, OpensPanel = true, Func = function(_, pp)
		if hg.SelectPlayerRole then hg.SelectPlayerRole("Traitor", nil, pp) end
	end},
	{Title = "Achievements", OpensPanel = true, Func = function(_, pp) hg.DrawAchievmentsMenu(pp) end},
	{Title = "Rules", Func = function() RunConsoleCommand("ulx", "motd") end},
	{Title = "Guide", Func = function()
		gui.OpenURL("https://docs.google.com/document/d/1oVOleCQSrbfWddLKOgjAKD-EKpbS1dxCfNdCSUwNfn4")
	end},
	{Title = "Discord", Func = function() gui.OpenURL(DISCORD_URL) end},
	{Title = "Workshop", Func = function()
		gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3715931702")
	end},
	{Title = "Store", Func = function() RunConsoleCommand("say", "!store") end},
	{Title = "Support Us", Support = true, Func = function() gui.OpenURL("https://ko-fi.com/votturzcity") end},
	{Title = "Main Menu", Func = function(menu)
		gui.ActivateGameUI()
		menu:Close()
	end},
	{Title = "Reconnect", Danger = true, Func = function() RunConsoleCommand("retry") end},
	{Title = "Disconnect", Danger = true, Func = function() RunConsoleCommand("disconnect") end},
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

function PANEL:SetupHome(pp)
	if not IsValid(pp) then return end
	pp:Clear()
	pp.Paint = function(_, w, h)
		DrawCRTFrame(0, 0, w, h)
	end

	local headerH = S(36)
	local titleGap = S(14)
	local textPad = S(12)
	surface.SetFont("ZC_MM_Title")
	local _, titleH = surface.GetTextSize("ZCITY")

	local status = vgui.Create("DPanel", pp)
	status:Dock(TOP)
	status:SetTall(headerH + titleGap + titleH + S(36))
	status:DockMargin(INSET, INSET, INSET, 0)
	status:SetPaintBackground(false)
	status.Paint = function(_, w, h)
		DrawHeaderStrip(0, 0, w, headerH, "STATUS")
		draw.SimpleText(GetHostName() or "ZCITY", "ZC_MM_Title", textPad, headerH + titleGap, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

		local rnd = CurrentRound and CurrentRound()
		local mode = engine.ActiveGamemode() or "ZCITY"
		if rnd and (rnd.PrintName or rnd.name) then
			mode = rnd.PrintName or rnd.name
		elseif zb and zb.CROUND and zb.CROUND ~= "" then
			mode = zb.CROUND
		end

		local state, stateCol = "WAITING", color_idle
		local roundState = zb and zb.ROUND_STATE or 0
		if roundState == 1 then
			state, stateCol = "LIVE", color_live
		elseif roundState == 3 then
			state, stateCol = "ENDING", color_ending
		end

		local timeLeft = "--:--"
		if roundState ~= 0 then
			timeLeft = string.FormattedTime(math.max((zb.ROUND_START or CurTime()) + (zb.ROUND_TIME or 400) - CurTime(), 0), "%02i:%02i")
		end

		local ply = LocalPlayer()
		local ft = engine.ServerFrameTime()
		local stats = {
			{"MAP", string.upper(game.GetMap() or "-")},
			{"MODE", string.upper(mode)},
			{"PLAYERS", player.GetCount() .. " / " .. game.MaxPlayers()},
			{"STATE", state, stateCol},
			{"TIME", timeLeft, roundState == 1 and color_live or color_text},
			{"PING", IsValid(ply) and (ply:Ping() .. " MS") or "-"},
			{"TICK", (ft and ft > 0) and tostring(math.Round(1 / ft)) or "-"},
		}

		local x = textPad
		local y = headerH + titleGap + titleH + S(10)
		for i = 1, #stats do
			local stat = stats[i]
			draw.SimpleText(stat[1], "ZC_MM_Header", x, y, color_idle_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			surface.SetFont("ZC_MM_Header")
			x = x + surface.GetTextSize(stat[1]) + S(8)
			draw.SimpleText(stat[2], "ZC_MM_Header", x, y, stat[3] or color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			x = x + surface.GetTextSize(stat[2]) + S(20)
		end
	end

	local list = vgui.Create("DPanel", pp)
	list:Dock(FILL)
	list:DockMargin(INSET, S(10), INSET, INSET)
	list:SetPaintBackground(false)

	local listHead = vgui.Create("DPanel", list)
	listHead:Dock(TOP)
	listHead:SetTall(S(32))
	listHead:SetPaintBackground(false)
	listHead.Paint = function()
		draw.SimpleText("OUR OTHER SERVERS", "ZC_MM_Header", textPad, S(4), color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	local here = string.lower(game.GetIPAddress() or "")
	local menu = self
	local rowH, btnH = S(78), S(36)
	for _, srv in ipairs(OtherServers) do
		if string.lower(srv.Address) == here then continue end

		local row = vgui.Create("DPanel", list)
		row:Dock(TOP)
		row:SetTall(rowH)
		row:DockMargin(0, 0, 0, S(8))
		row:SetPaintBackground(false)
		row.Paint = function(_, w, h)
			surface.SetDrawColor(32, 34, 33, 180)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, 70)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			draw.SimpleText(srv.Name, "ZC_MM_Title", S(16), h * 0.5 - S(10), color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(srv.Address, "ZC_MM_Header", S(16), h * 0.5 + S(18), color_idle, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		local go = vgui.Create("DButton", row)
		go:SetText("")
		go:Dock(RIGHT)
		go:SetWide(S(148))
		go:DockMargin(S(16), math.floor((rowH - btnH) * 0.5), S(16), math.floor((rowH - btnH) * 0.5))
		go.DoClick = function()
			MenuSound("shitty/tap_depress.wav", 0.09)
			menu:Close()
			LocalPlayer():ConCommand("connect " .. srv.Address)
		end
		go.Paint = function(self, w, h)
			local hover = self:IsHovered()
			surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, 230)
			surface.DrawRect(0, 0, w, h)
			if hover then
				surface.SetDrawColor(CRT_R, CRT_G, CRT_B, 28)
				surface.DrawRect(1, 1, w - 2, h - 2)
			end
			surface.SetDrawColor(CRT_R, CRT_G, CRT_B, hover and 210 or 150)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			draw.SimpleText("CONNECT", "ZC_MM_Button", w * 0.5, h * 0.5, hover and color_text or color_live, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
end

function PANEL:Init()
	self:SetSize(ScrW(), ScrH())
	self:Center()
	self:SetTitle("")
	self:SetDraggable(false)
	self:SetBorder(false)
	self:SetColorBG(Color(8, 11, 10, 165))
	self:SetColorBR(Color(CRT_R, CRT_G, CRT_B, 180))
	self:SetBlurStrengh(4)
	self:ShowCloseButton(false)
	if IsValid(self.lblTitle) then self.lblTitle:SetVisible(false) end
	for _, key in ipairs({"btnClose", "btnMaxim", "btnMinim"}) do
		if IsValid(self[key]) then self[key]:SetVisible(false) end
	end

	current_panel = nil
	self.SplashText = splasheh[math.random(#splasheh)]
	if hg.PluvTown and hg.PluvTown.Active and hg.PluvTown.PluvMats then
		self.SelectedPluv = table.Random(hg.PluvTown.PluvMats)
	end

	local margin = S(24)
	local sidebarW = math.Clamp(S(440), 360, math.min(520, math.floor(ScrW() * 0.34)))
	local sidebarH = ScrH() - margin * 2
	local innerPad = S(18)
	local headerH = S(36)
	local titleGap = S(14)
	surface.SetFont("ZC_MM_Title")
	local _, titleH = surface.GetTextSize("ZCITY")
	local brandH = titleGap + titleH + S(28)
	local footerH = S(52)
	local navTop = INSET + headerH + brandH
	local navBottom = sidebarH - INSET - footerH - S(8)

	self.lDock = vgui.Create("DPanel", self)
	local lDock = self.lDock
	lDock:SetPos(margin, margin)
	lDock:SetSize(sidebarW, sidebarH)
	lDock.Paint = function(_, w, h)
		DrawCRTFrame(0, 0, w, h)
		DrawHeaderStrip(INSET, INSET, w - INSET * 2, headerH, "MAIN MENU", true)

		surface.SetFont("ZC_MM_Title")
		local gap = S(14)
		local tw1 = surface.GetTextSize("VOTTUR'S")
		local tw2 = surface.GetTextSize("ZCITY")
		local imgW = (hg.PluvTown and hg.PluvTown.Active) and (S(48) + S(10)) or 0
		local titleX = math.floor((w - (imgW + tw1 + gap + tw2)) * 0.5)
		local titleY = INSET + headerH + titleGap

		if imgW > 0 then
			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(self.SelectedPluv or Pluv)
			surface.DrawTexturedRect(titleX, titleY + math.floor((titleH - S(36)) * 0.5), S(48), S(36))
			titleX = titleX + imgW
		end
		draw.SimpleText("VOTTUR'S", "ZC_MM_Title", titleX, titleY, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText("ZCITY", "ZC_MM_Title", titleX + tw1 + gap, titleY, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		draw.SimpleText(self.SplashText, "ZC_MM_Tiny", w * 0.5, titleY + titleH + S(6), color_idle_dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end

	local visible = {}
	for _, v in ipairs(Selects) do
		if not (v.GamemodeOnly and engine.ActiveGamemode() ~= "zcity") then
			visible[#visible + 1] = v
		end
	end

	local gap = S(4)
	local count = math.max(#visible, 1)
	local buttonH = math.Clamp(math.floor((navBottom - navTop - gap * (count - 1)) / count), S(24), S(36))

	local buttonDock = vgui.Create("DPanel", lDock)
	buttonDock:SetPos(innerPad, navTop)
	buttonDock:SetSize(sidebarW - innerPad * 2, count * (buttonH + gap) - gap)
	buttonDock:SetPaintBackground(false)

	for i, v in ipairs(visible) do
		self:AddSelect(buttonDock, v, buttonH, i == 1)
	end

	local git = vgui.Create("DLabel", lDock)
	git:SetPos(innerPad, sidebarH - INSET - S(22))
	git:SetSize(sidebarW - innerPad * 2, S(18))
	git:SetFont("ZC_MM_Tiny")
	git:SetText(GITHUB_LABEL)
	git:SetTextColor(color_faint)
	git:SetContentAlignment(4)
	git:SetMouseInputEnabled(true)
	function git:DoClick()
		MenuSound("shitty/tap_depress.wav", 0.09)
		gui.OpenURL(GITHUB_URL)
	end
	function git:Think()
		self:SetTextColor(self:IsHovered() and color_text or color_faint)
	end

	local zteam = vgui.Create("DLabel", lDock)
	zteam:SetPos(innerPad, sidebarH - INSET - S(40))
	zteam:SetSize(sidebarW - innerPad * 2, S(18))
	zteam:SetFont("ZC_MM_Tiny")
	zteam:SetTextColor(color_idle_dim)
	zteam:SetText("Vottur, Zorf, Patidinho")
	zteam:SetContentAlignment(4)

	self.ContentX = margin + sidebarW + S(16)
	self.ContentY = margin
	self.ContentW = ScrW() - self.ContentX - margin
	self.ContentH = sidebarH

	self.panelparrent = vgui.Create("DPanel", self)
	self.panelparrent:SetPos(self.ContentX, self.ContentY)
	self.panelparrent:SetSize(self.ContentW, self.ContentH)
	self.panelparrent:SetPaintBackground(false)
	self:SetupHome(self.panelparrent)
end

function PANEL:RebuildContent(callback)
	local pp = self.panelparrent
	if not IsValid(pp) then return end

	pp:AlphaTo(0, 0.12, 0, function()
		if not IsValid(self) then return end
		if IsValid(pp) then pp:Remove() end

		self.panelparrent = vgui.Create("DPanel", self)
		self.panelparrent:SetPos(self.ContentX, self.ContentY)
		self.panelparrent:SetSize(self.ContentW, self.ContentH)
		self.panelparrent:SetPaintBackground(false)
		self.panelparrent:SetAlpha(0)

		if callback then
			callback(self.panelparrent)
		else
			self:SetupHome(self.panelparrent)
		end

		if IsValid(self.panelparrent) then
			self.panelparrent:AlphaTo(255, 0.12, 0)
		end
	end)
end

function PANEL:First()
	self:AlphaTo(255, 0.15, 0)
end

function PANEL:Paint(w, h)
	draw.RoundedBox(0, 0, 0, w, h, self.ColorBG)
	hg.DrawBlur(self, self.BlurStrengh or 4)
end

function PANEL:AddSelect(parent, tbl, buttonH, first)
	local btn = vgui.Create("DButton", parent)
	btn:SetText("")
	btn:SetTall(buttonH)
	btn:Dock(TOP)
	if not first then btn:DockMargin(0, S(4), 0, 0) end
	btn.Label = string.upper(tbl.Title)
	btn.Danger = tbl.Danger
	btn.Support = tbl.Support
	btn.Id = string.lower(tbl.Title)
	btn:SetWide(parent:GetWide())

	local menu = self
	btn.Paint = function(this, w, h)
		local active = current_panel == this.Id
		local hover = this:IsHovered() or active
		this.HoverLerp = LerpFT(0.2, this.HoverLerp or 0, hover and 1 or 0)
		local v = this.HoverLerp

		local r, g, b = CRT_R, CRT_G, CRT_B
		if this.Danger then
			r, g, b = TRAITOR_R, TRAITOR_G, TRAITOR_B
		elseif this.Support then
			r, g, b = color_gold.r, color_gold.g, color_gold.b
		end

		if active or v > 0.02 then
			surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, math.floor(36 * v))
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(r, g, b, active and 31 or math.floor(18 * v))
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(r, g, b, active and 216 or math.floor(24 + 90 * v))
			surface.DrawRect(0, 0, 2, h)
			if active then
				surface.SetDrawColor(r, g, b, 180)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
			end
		end

		local col = color_idle
		if this.Danger then
			col = (active or v > 0.5) and color_danger_hot or color_danger
		elseif this.Support then
			col = color_gold
		elseif active or v > 0.5 then
			col = color_text
		end
		draw.SimpleText(this.Label, "ZC_MM_Button", S(12), h * 0.5, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	function btn:DoClick()
		if not tbl.OpensPanel then
			MenuSound("shitty/tap_depress.wav", 0.09)
			tbl.Func(menu, menu.panelparrent)
			return
		end

		if current_panel == self.Id then
			MenuSound("shitty/tap_release.wav", 0.05)
			menu:RebuildContent()
			current_panel = nil
			return
		end

		MenuSound("shitty/tap_depress.wav", 0.09)
		menu:RebuildContent(function(nextPP)
			tbl.Func(menu, nextPP)
			current_panel = btn.Id
		end)
	end
end

function PANEL:Close()
	self:AlphaTo(0, 0.1, 0, function()
		if IsValid(self) then self:Remove() end
	end)
	self:SetKeyboardInputEnabled(false)
	self:SetMouseInputEnabled(false)
end

vgui.Register("ZMainMenu", PANEL, "ZFrame")

hook.Add("OnPauseMenuShow", "OpenMainMenu", function()
	local run = hook.Run("OnShowZCityPause")
	if run ~= nil then return run end

	if MainMenu and IsValid(MainMenu) then
		MainMenu:Close()
		MainMenu = nil
		return false
	end

	MainMenu = vgui.Create("ZMainMenu")
	MainMenu:MakePopup()
	return false
end)