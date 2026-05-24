MODE.name = "tdm"

if not zb.TDMShop then
	include("zcity/gamemode/modes/tdm/sh_tdm_buy.lua")
end

local MODE = MODE
local MusicVolume = GetConVar("snd_musicvolume")
local tdmThemeStation

local function StopTDMTheme()
	if IsValid(tdmThemeStation) then
		tdmThemeStation:Stop()
	end

	tdmThemeStation = nil
end

local function GetTDMThemePath(round)
	local themePath = round and round.ThemeMusicFile
	if not themePath or themePath == "" then return nil end

	if string.StartWith(themePath, "sound/") then
		return themePath
	end

	return "sound/" .. themePath
end

local function StartTDMTheme(round)
	local themePath = GetTDMThemePath(round)
	if not themePath then return false end

	local expectedRoundName = round.name
	StopTDMTheme()

	sound.PlayFile(themePath, "noblock noplay", function(station, errCode, errStr)
		if not IsValid(station) then
			print(errCode, errStr)

			local currentRound = CurrentRound()
			if currentRound and currentRound.name == expectedRoundName and hg.DynaMusic then
				hg.DynaMusic:Start("swat4")
			end

			return
		end

		local currentRound = CurrentRound()
		if not currentRound or currentRound.name != expectedRoundName then
			station:Stop()
			return
		end

		if hg.DynaMusic then
			hg.DynaMusic:Stop()
		end

		tdmThemeStation = station
		station:EnableLooping(true)
		station:SetVolume((round.ThemeMusicVolume or 0.35) * ((MusicVolume and MusicVolume:GetFloat()) or 1))
		station:Play()
	end)

	return true
end

net.Receive("tdm_start",function()
    surface.PlaySound("csgo_round.wav")
	zb.rtype = net.ReadString()

	if zb.RemoveFade then
		zb.RemoveFade()
	else
		zb.fade = 0
	end

	local round = CurrentRound() or MODE
	if not StartTDMTheme(round) and hg.DynaMusic then
		StopTDMTheme()
		hg.DynaMusic:Start("swat4")
	end
end)

hook.Add("StartCommand", "TDM_DisallowMoveOrShoting", function(ply, mv)
	if zb.CROUND ~= "tdm" then return end
	if (zb.ROUND_START or 0) + (zb.RoundFade and zb.RoundFade.TDM_MOVE_BLOCK or 20) > CurTime() then
		mv:RemoveKey(IN_ATTACK)
		mv:RemoveKey(IN_ATTACK2)
		mv:RemoveKey(IN_FORWARD)
		mv:RemoveKey(IN_BACK)
		mv:RemoveKey(IN_MOVELEFT)
		mv:RemoveKey(IN_MOVERIGHT)
	end
end)

hook.Add("Think", "TDMThemeVolumeThink", function()
	if not IsValid(tdmThemeStation) then return end

	local round = CurrentRound()
	if not round or not round.ThemeMusicFile then
		StopTDMTheme()
		return
	end

	tdmThemeStation:SetVolume((round.ThemeMusicVolume or 0.35) * ((MusicVolume and MusicVolume:GetFloat()) or 1))

	if tdmThemeStation:GetState() != GMOD_CHANNEL_PLAYING then
		tdmThemeStation:Play()
	end
end)

hook.Add("RoundInfoCalled", "TDMThemeRoundInfo", function(rnd)
	if not IsValid(tdmThemeStation) then return end

	local currentRound = CurrentRound()
	if currentRound and currentRound.ThemeMusicFile and rnd != currentRound.name then
		StopTDMTheme()
	end
end)

local teams = {
	[0] = {
		objective = "",
		name = "a Terrorist",
		color1 = Color(190,0,0),
		color2 = Color(190,0,0)
	},
	[1] = {
		objective = "",
		name = "a Counter Terrorist",
		color1 = Color(0,120,190),
		color2 = Color(0,120,190)
	},
}


function MODE:RenderScreenspaceEffects()
	zb.RoundFade.PaintBlackScreen()
end

function MODE:HUDPaint()
	local startTime = zb.ROUND_START or CurTime()

	self:AddHudPaint()

	local buyWindow = self.start_time or 20
	if startTime + buyWindow > CurTime() then
		draw.SimpleText(string.FormattedTime(startTime + buyWindow - CurTime(), "%02i:%02i:%02i"), "ZB_HomicideMedium", sw * 0.5, sh * 0.95, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("Press F3 to open buymenu", "ZB_HomicideMedium", sw * 0.5, sh * 0.9, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	else
		local time = string.FormattedTime(math.max(startTime + (zb.ROUND_TIME or 400) - CurTime(), 0), "%02i:%02i:%02i")
		draw.SimpleText(time, "ZB_HomicideMedium", sw * 0.5, sh * 0.95, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if startTime + buyWindow < CurTime() then return end

	zb.RoundFade.PaintStandardIntro(self)
end

function MODE:AddHudPaint()
end

MODE.IntroTitle = "ZBattle | Team Deathmatch"
MODE.IntroTeams = teams

function MODE:RoundStart()
end

surface.CreateFont("ZB_TDM_MENU", {
    font = "Bahnschrift",
    size = ScreenScale(12),
    extended = true,
    weight = 400,
    antialias = true
})
surface.CreateFont("ZB_TDM_DESC", {
    font = "Bahnschrift",
    size = ScreenScale(7),
    extended = true,
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_TDM_CATEGORY", {
    font = "Bahnschrift",
    size = ScreenScale(6),
    extended = true,
    weight = 400,
    antialias = true
})

surface.CreateFont("ZB_TDM_TAB", {
    font = "Bahnschrift",
    size = ScreenScale(8),
    extended = true,
    weight = 500,
    antialias = true
})

surface.CreateFont("ZB_TDM_TAB_COMPACT", {
    font = "Bahnschrift",
    size = ScreenScale(7),
    extended = true,
    weight = 500,
    antialias = true
})

surface.CreateFont("ZB_TDM_TAB_MICRO", {
    font = "Bahnschrift",
    size = ScreenScale(6),
    extended = true,
    weight = 500,
    antialias = true
})

surface.CreateFont("ZB_TDM_DESCSMALL", {
    font = "Bahnschrift",
    size = ScreenScale(5),
    extended = true,
    weight = 400,
    antialias = true
})

local defaultBuyMenuTheme = {
	Background = Color(0, 0, 0, 155),
	InnerBackground = Color(0, 0, 0, 140),
	Outline = Color(255, 0, 0, 128),
	Gradient = Color(155, 0, 0, 55),
	AttachmentGradient = Color(55, 155, 55, 25),
	AttachmentOutline = Color(55, 155, 55, 200),
}

zb = zb or {}
zb.TDM_BuyMenuTheme = defaultBuyMenuTheme

local function GetBuyMenuTheme()
	local round = CurrentRound and CurrentRound()
	local theme = (round and round.BuyMenuTheme) or defaultBuyMenuTheme

	return {
		Background = theme.Background or defaultBuyMenuTheme.Background,
		InnerBackground = theme.InnerBackground or defaultBuyMenuTheme.InnerBackground,
		Outline = theme.Outline or defaultBuyMenuTheme.Outline,
		Gradient = theme.Gradient or defaultBuyMenuTheme.Gradient,
		AttachmentGradient = theme.AttachmentGradient or defaultBuyMenuTheme.AttachmentGradient,
		AttachmentOutline = theme.AttachmentOutline or defaultBuyMenuTheme.AttachmentOutline,
	}
end

local function ApplyBuyMenuFrameColors(frame)
	if not IsValid(frame) then return end

	local theme = GetBuyMenuTheme()
	frame:SetColorBR(Color(theme.Outline.r, theme.Outline.g, theme.Outline.b, math.min(255, theme.Outline.a + 40)))
	frame:SetColorBG(Color(
		theme.InnerBackground.r,
		theme.InnerBackground.g,
		theme.InnerBackground.b,
		math.min(255, theme.InnerBackground.a + 15)
	))
end

local function SetThemeDrawColor(color, fallback)
	color = color or fallback
	surface.SetDrawColor(color.r, color.g, color.b, color.a)
end

local function PaintFrame(self,w,h)
	BlurBackground(self)

	local theme = GetBuyMenuTheme()
	SetThemeDrawColor(theme.Outline, defaultBuyMenuTheme.Outline)
    surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
end

local function PaintPanel(self,w,h)
	local theme = GetBuyMenuTheme()
	SetThemeDrawColor(theme.Background, defaultBuyMenuTheme.Background)
    surface.DrawRect( 0, 0, w, h, 2.5 )
	SetThemeDrawColor(theme.Outline, defaultBuyMenuTheme.Outline)
    surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
end

local gradient_l = Material("vgui/gradient-l")

local function PaintPanel1(self,w,h)
	local theme = GetBuyMenuTheme()
	SetThemeDrawColor(theme.Background, defaultBuyMenuTheme.Background)
    surface.DrawRect( 0, 0, w, h, 2.5 )
	SetThemeDrawColor(theme.Outline, defaultBuyMenuTheme.Outline)
    surface.DrawOutlinedRect( 0, 0, w, h, 2.5 )
	draw.RoundedBox( 0, 2.5, 2.5, w-5, h-5, theme.InnerBackground or defaultBuyMenuTheme.InnerBackground )
    SetThemeDrawColor(theme.Gradient, defaultBuyMenuTheme.Gradient)
    surface.SetMaterial(gradient_l)
    surface.DrawTexturedRect( 0, 0, w/1.5, h )
end

local function PaintPanel2(self,w,h)
	--surface.SetDrawColor( 15, 15, 15,25)
    --surface.DrawRect( 0, 0, w, h, 2.5 )
	--draw.RoundedBox( 0, 2.5, 2.5, w-5, h-5, Color( 0, 0, 0, 140) )
	local theme = GetBuyMenuTheme()
    SetThemeDrawColor(theme.AttachmentGradient, defaultBuyMenuTheme.AttachmentGradient)
    surface.SetMaterial(gradient_l)
    surface.DrawTexturedRect( 0, 0, w*1.2, h )
end

local function getTDMTabPadX(tab)
	if IsValid(tab) and tab._tdmTabMicroFont then
		return math.max(ScreenScale(3), 4)
	end

	if IsValid(tab) and tab._tdmTabCompactFont then
		return math.max(ScreenScale(4), 5)
	end

	return math.max(ScreenScale(5), 6)
end

local function getTDMTabFont(tab)
	if IsValid(tab) and tab._tdmTabMicroFont then
		return "ZB_TDM_TAB_MICRO"
	end

	if IsValid(tab) and tab._tdmTabCompactFont then
		return "ZB_TDM_TAB_COMPACT"
	end

	return "ZB_TDM_TAB"
end

local function getTDMTabBarHeight()
	surface.SetFont("ZB_TDM_TAB")
	local _, textH = surface.GetTextSize("Ay")

	return math.ceil(textH + ScreenScale(3))
end

local function measureTDMTabWidth(tabText, tab)
	local fontName = getTDMTabFont(tab)
	surface.SetFont(fontName)
	local textW = surface.GetTextSize(tabText or "")

	local iconWide = 0
	if IsValid(tab) and tab.Image then
		iconWide = 6 + tab.Image:GetWide()
	end

	local padX = getTDMTabPadX(tab)
	return textW + iconWide + padX * 2
end

local function paintTDMPropertySheetTab(self, w, h)
	local theme = GetBuyMenuTheme()
	local drawH = math.max(h - 2, 1)
	local outline = theme.Outline or defaultBuyMenuTheme.Outline

	SetThemeDrawColor(theme.Background, defaultBuyMenuTheme.Background)
	surface.DrawRect(0, 0, w, drawH)

	if self:IsActive() then
		draw.RoundedBox(0, 1, 1, w - 2, drawH - 2, theme.InnerBackground or defaultBuyMenuTheme.InnerBackground)
		SetThemeDrawColor(theme.Gradient, defaultBuyMenuTheme.Gradient)
		surface.SetMaterial(gradient_l)
		surface.DrawTexturedRect(0, 0, w / 1.5, drawH)
	end

	SetThemeDrawColor(outline, defaultBuyMenuTheme.Outline)
	surface.DrawRect(0, 0, w, 1)
	surface.DrawRect(0, drawH - 1, w, 1)

	if self._tdmTabDrawLeftEdge then
		surface.DrawRect(0, 0, 1, drawH)
	end

	if self._tdmTabDrawRightEdge then
		surface.DrawRect(w - 1, 0, 1, drawH)
	elseif self._tdmTabDrawDivider then
		surface.DrawRect(w - 1, 0, 1, drawH)
	end

	local label = self._tdmTabLabel or ""
	if label == "" then return end

	local fontName = getTDMTabFont(self)
	draw.SimpleText(label, fontName, w * 0.5, h * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function applyTDMPropertySheetTab(self)
	if not IsValid(self) then return end

	local tabText = self._tdmTabLabel or ""
	if tabText == "" then return end

	self._tdmTabPadX = getTDMTabPadX(self)
	self._tdmTabIconWide = self.Image and (6 + self.Image:GetWide()) or 0
	self:SetFont(getTDMTabFont(self))
	self:SetText("")
	self:SetTextColor(color_white)
	self:SetTextInset(0, 0)

	if self._tdmTabWidthLocked or self._tdmStretchedTab then return end

	local tabH = getTDMTabBarHeight()
	self:SetSize(measureTDMTabWidth(tabText, self), tabH)
end

local function installTDMPropertySheetTabPaint(tab)
	tab.Paint = paintTDMPropertySheetTab
	tab.PaintOver = function() end
	tab.DrawText = function() end
	tab.ApplySchemeSettings = function() end

	for _, child in ipairs(tab:GetChildren()) do
		if IsValid(child) and child ~= tab.Image then
			child:SetVisible(false)
			child:SetMouseInputEnabled(false)

			if child.SetText then
				child:SetText("")
			end
		end
	end
end

local function setupTDMPropertySheetTab(tab, label)
	if not IsValid(tab) then return end

	label = label or tab._tdmTabLabel or tab:GetText() or ""
	if label == "" then return end

	tab._tdmTabLabel = label

	if not tab._tdmTabStyled then
		tab._tdmTabStyled = true
		tab._tdmStretchedTab = true
		installTDMPropertySheetTabPaint(tab)
	end

	applyTDMPropertySheetTab(tab)
end

local function getTDMTabList(sheet)
	local tabs = {}

	for _, sheetData in ipairs(sheet.Items or {}) do
		if IsValid(sheetData.Tab) then
			tabs[#tabs + 1] = sheetData.Tab
		end
	end

	return tabs
end

local function getTDMTabSideInset()
	return math.max(ScreenScale(2), 2)
end

local function getTDMTabAvailWidth(sheet, scroller)
	local inset = getTDMTabSideInset() * 2

	if IsValid(sheet) and sheet:GetWide() > 0 then
		return math.max(sheet:GetWide() - inset, ScreenScale(80))
	end

	if IsValid(scroller) and scroller:GetWide() > 0 then
		return math.max(scroller:GetWide(), ScreenScale(80))
	end

	return ScreenScale(120)
end

local function sumTDMTabNaturalWidths(sheet)
	local total = 0

	for _, tab in ipairs(getTDMTabList(sheet)) do
		total = total + measureTDMTabWidth(tab._tdmTabLabel, tab)
	end

	return total
end

local function assignTDMTabProportionalWidths(sheet, availW)
	local tabs = getTDMTabList(sheet)
	local tabCount = #tabs
	if tabCount <= 0 then return end

	availW = math.floor(availW)

	local naturals = {}
	local totalNatural = 0

	for index, tab in ipairs(tabs) do
		local naturalW = measureTDMTabWidth(tab._tdmTabLabel, tab)
		naturals[index] = naturalW
		totalNatural = totalNatural + naturalW
	end

	if totalNatural <= 0 then
		local baseW = math.floor(availW / tabCount)

		for index, tab in ipairs(tabs) do
			tab._tdmTabWidthLocked = true
			tab:SetWide(baseW)
		end

		return
	end

	local scale = availW / totalNatural
	local usedW = 0

	for index, tab in ipairs(tabs) do
		local tabW = math.max(1, math.floor(naturals[index] * scale))
		tab._tdmTabWidthLocked = true
		tab:SetWide(tabW)
		usedW = usedW + tabW
	end

	local remainder = availW - usedW
	if remainder ~= 0 and IsValid(tabs[tabCount]) then
		tabs[tabCount]:SetWide(tabs[tabCount]:GetWide() + remainder)
	end
end

local layoutTDMTabBar

local function disableTDMTabScroller(scroller, sheet)
	if not IsValid(scroller) or not scroller.SetOverlap then return end

	scroller:SetOverlap(0)
	scroller._tdmSheet = sheet

	local function hideScrollButtons()
		if IsValid(scroller.btnLeft) then
			if scroller.btnLeft:IsVisible() then scroller.btnLeft:SetVisible(false) end
			if scroller.btnLeft:GetWide() ~= 0 then scroller.btnLeft:SetWide(0) end
			scroller.btnLeft:SetMouseInputEnabled(false)
		end

		if IsValid(scroller.btnRight) then
			if scroller.btnRight:IsVisible() then scroller.btnRight:SetVisible(false) end
			if scroller.btnRight:GetWide() ~= 0 then scroller.btnRight:SetWide(0) end
			scroller.btnRight:SetMouseInputEnabled(false)
		end
	end

	scroller.Scroll = 0
	hideScrollButtons()

	if scroller._tdmScrollerPinned then return end
	scroller._tdmScrollerPinned = true

	local oldPerformLayout = scroller.PerformLayout
	scroller.PerformLayout = function(s, w, h)
		if s._tdmPinningLayout then return end
		s._tdmPinningLayout = true

		if oldPerformLayout then
			oldPerformLayout(s, w, h)
		end

		s.Scroll = 0
		hideScrollButtons()

		if IsValid(s._tdmSheet) then
			layoutTDMTabBar(s._tdmSheet, s, w, h)
		end

		s._tdmPinningLayout = false
	end

	scroller.OnMouseWheeled = function()
		return true
	end
end

local function resetTDMTabFonts(sheet)
	for _, sheetData in ipairs(sheet.Items) do
		local tab = sheetData.Tab
		if not IsValid(tab) then continue end

		tab._tdmTabCompactFont = nil
		tab._tdmTabMicroFont = nil
		tab._tdmTabLabel = sheetData.Name or tab._tdmTabLabel
		tab:SetFont(getTDMTabFont(tab))
		tab:SetText("")
	end
end

local function applyTDMTabFontMode(sheet, fontMode)
	for _, sheetData in ipairs(sheet.Items) do
		local tab = sheetData.Tab
		if IsValid(tab) then
			tab._tdmTabCompactFont = fontMode == "compact" or fontMode == "micro"
			tab._tdmTabMicroFont = fontMode == "micro"
			tab:SetFont(getTDMTabFont(tab))
		end
	end
end

local function pickTDMTabFontMode(sheet, availW)
	local fontModes = {nil, "compact", "micro"}

	for _, fontMode in ipairs(fontModes) do
		applyTDMTabFontMode(sheet, fontMode)

		if sumTDMTabNaturalWidths(sheet) <= availW then
			return
		end
	end

	applyTDMTabFontMode(sheet, "micro")
end

local function updateTDMTabEdgeFlags(sheet)
	local tabs = getTDMTabList(sheet)

	for tabIndex, tab in ipairs(tabs) do
		tab._tdmTabDrawLeftEdge = tabIndex == 1
		tab._tdmTabDrawRightEdge = tabIndex == #tabs
		tab._tdmTabDrawDivider = tabIndex < #tabs
	end
end

layoutTDMTabBar = function(sheet, scroller, barW, barH)
	if not IsValid(sheet) or not IsValid(scroller) then return end

	barW = math.floor(barW or getTDMTabAvailWidth(sheet, scroller))
	barH = getTDMTabBarHeight()

	if barW <= 0 then return end

	local tabs = getTDMTabList(sheet)
	if #tabs <= 0 then return end

	resetTDMTabFonts(sheet)
	pickTDMTabFontMode(sheet, barW)
	assignTDMTabProportionalWidths(sheet, barW)

	local x = 0

	for _, tab in ipairs(tabs) do
		tab:SetPos(x, 0)
		tab:SetTall(barH)
		x = x + tab:GetWide()
	end

	local canvasW = math.max(barW, x)

	if IsValid(scroller.pnlCanvas) then
		scroller.pnlCanvas:SetPos(0, 0)
		scroller.pnlCanvas:SetSize(canvasW, barH)
	end

	scroller.Scroll = 0
	updateTDMTabEdgeFlags(sheet)
end

local function fitTDMPropertySheetTabs(sheet)
	if not IsValid(sheet) or not istable(sheet.Items) then return end
	if sheet._tdmTabFitting then return end

	sheet._tdmTabFitting = true

	local scroller = sheet.tabScroller
	if IsValid(scroller) then
		disableTDMTabScroller(scroller, sheet)

		local availW = getTDMTabAvailWidth(sheet, scroller)
		layoutTDMTabBar(sheet, scroller, availW, getTDMTabBarHeight())
	end

	sheet._tdmTabFitting = false
end

local TDM_BuyMenuBuildTimer
local TDM_BuyMenuBuildingPanel
local TDM_BUY_ITEMS_PER_TICK = 8

local function cancelBuyMenuBuildTimer()
	if TDM_BuyMenuBuildTimer then
		timer.Remove(TDM_BuyMenuBuildTimer)
		TDM_BuyMenuBuildTimer = nil
	end

	if IsValid(TDM_BuyMenuBuildingPanel) and TDM_BuyMenuBuildingPanel._tdmBuilding then
		TDM_BuyMenuBuildingPanel._tdmBuilding = false
		TDM_BuyMenuBuildingPanel._tdmBuilt = false

		local canvas = TDM_BuyMenuBuildingPanel.GetCanvas and TDM_BuyMenuBuildingPanel:GetCanvas()
		if IsValid(canvas) then
			canvas:Clear()
		end
	end

	TDM_BuyMenuBuildingPanel = nil
end

local function buildAmmoLookup(buyItems)
	local lookup = {}

	for name2, ammoEntry in pairs(buyItems["Ammo"] or {}) do
		if istable(ammoEntry) and ammoEntry.ItemClass then
			lookup[ammoEntry.ItemClass] = name2
		end
	end

	return lookup
end

local function getCachedWeapon(class, cache)
	if cache[class] == nil then
		cache[class] = weapons.GetStored(class)
	end

	return cache[class]
end

local function getCachedEnt(class, cache)
	if cache[class] == nil then
		cache[class] = scripted_ents.GetStored(class)
	end

	return cache[class]
end

local TDM_ATTACH_ICON_SIZE = function()
	return math.ceil(ScrH() * 0.068)
end

local TDM_ATTACH_ICON_COLS = 4
local TDM_ATTACH_MAX_ROWS = 2
local TDM_ICON_PAD = 4
local TDM_ICON_PLACEHOLDER = "icon16/wrench"
local TDM_CARD_ROW_MARGIN = 6
local TDM_CONTENT_PAD = 8
local TDM_CARD_PAD_TOP = 5
local TDM_CARD_PAD_LEFT = 7
local TDM_CARD_PAD_BOTTOM = 5
local TDM_ICON_BOTTOM_ACCENT = 2

local TDM_BTN_ROW_H = function()
	return math.ceil(ScrH() * 0.036)
end

local function getTDMItemIconDimensions(rowH)
	local iconH = math.max(56, math.ceil(rowH - TDM_CARD_PAD_TOP - TDM_CARD_PAD_BOTTOM - TDM_ICON_BOTTOM_ACCENT))
	local iconW = math.ceil(iconH * 1.12)

	return iconW, iconH
end

local function getTDMTextBlockHeight()
	surface.SetFont("ZB_TDM_MENU")
	local _, nameLineH = surface.GetTextSize("Ay")
	surface.SetFont("ZB_TDM_DESC")
	local _, priceLineH = surface.GetTextSize("Ay")

	return math.ceil(nameLineH * 2 + priceLineH + 14)
end

local function TDM_BUY_ROW_H(hasAttachments, attGridRows)
	local att = TDM_ATTACH_ICON_SIZE()
	local btnH = TDM_BTN_ROW_H()
	local textH = getTDMTextBlockHeight()
	local minIconH = math.ceil(ScrH() * 0.102)
	local coreH = math.max(
		minIconH + TDM_CARD_PAD_TOP + TDM_CARD_PAD_BOTTOM + TDM_ICON_BOTTOM_ACCENT,
		textH + btnH + 16
	)

	if not hasAttachments then
		return coreH
	end

	local visibleRows = math.min(attGridRows or 1, TDM_ATTACH_MAX_ROWS)

	return math.max(coreH, visibleRows * att + 18)
end

local function hidePanelScrollBar(scrollBar)
	if not IsValid(scrollBar) then return end

	scrollBar:SetEnabled(false)
	scrollBar:SetWide(0)
end

local function setupBuyMenuScrollPanel(scrollPanel)
	if not IsValid(scrollPanel) then return end

	if scrollPanel.GetHBar then
		hidePanelScrollBar(scrollPanel:GetHBar())
	end

	if scrollPanel.GetVBar then
		local vBar = scrollPanel:GetVBar()
		if IsValid(vBar) then
			vBar:SetHideButtons(true)
		end
	end
end

local function getBuyMenuListParent(categoryPanel)
	if IsValid(categoryPanel) and categoryPanel.GetCanvas then
		local canvas = categoryPanel:GetCanvas()
		if IsValid(canvas) then return canvas end
	end

	return categoryPanel
end

local function resolveItemIconPath(weapon, ent)
	if weapon then
		if weapon.WepSelectIcon2 then
			return weapon.WepSelectIcon2:GetName() .. ".png", weapon.WepSelectIcon2box == true
		end

		if weapon.IconOverride then
			return weapon.IconOverride, false
		end
	end

	if ent and ent.t and ent.t.IconOverride then
		return ent.t.IconOverride, true
	end

	return nil
end

local function resolveAttachmentIconPath(attName)
	if not attName then return TDM_ICON_PLACEHOLDER end

	if hg and hg.attachmentsIcons and hg.attachmentsIcons[attName] then
		return hg.attachmentsIcons[attName]
	end

	local entStored = scripted_ents.Get("ent_att_" .. attName)
	if entStored and entStored.IconOverride and entStored.IconOverride ~= "" then
		return entStored.IconOverride
	end

	if hg and hg.attachments then
		for _, tbl in pairs(hg.attachments) do
			local attData = tbl[attName]
			if istable(attData) and isstring(attData[2]) and attData[2] ~= "" then
				return attData[2]
			end
		end
	end

	return TDM_ICON_PLACEHOLDER
end

local function resolvePurchaseIconPath(purchase, weaponCache, entCache)
	if not istable(purchase) then return nil end

	if purchase.purchaseType == "attachment" and purchase.attachment then
		return resolveAttachmentIconPath(purchase.attachment)
	end

	local class = purchase.itemClass or purchase.weaponClass
	if not class then return nil end

	local weapon = getCachedWeapon(class, weaponCache)
	local ent = getCachedEnt(class, entCache)

	return resolveItemIconPath(weapon, ent)
end

local function loadTDMIconMaterial(imagePath)
	if not imagePath or imagePath == "" then
		return Material(TDM_ICON_PLACEHOLDER, "smooth mips")
	end

	local mat = Material(imagePath, "smooth mips")
	if not mat:IsError() then return mat end

	if not string.find(imagePath, "%.") then
		mat = Material(imagePath .. ".png", "smooth mips")
		if not mat:IsError() then return mat end
	end

	return Material(TDM_ICON_PLACEHOLDER, "smooth mips")
end

-- Fit entire icon inside the box (letterbox) so nothing is cropped off.
local function paintContainedImage(mat, w, h, pad)
	pad = pad or TDM_ICON_PAD

	if not mat or mat:IsError() then return end

	local matW, matH = mat:Width(), mat:Height()
	if matW < 1 or matH < 1 then
		matW, matH = 1, 1
	end

	local boxW, boxH = math.max(1, w - pad * 2), math.max(1, h - pad * 2)
	local scale = math.min(boxW / matW, boxH / matH)
	local drawW, drawH = matW * scale, matH * scale
	local x = pad + (boxW - drawW) * 0.5
	local y = pad + (boxH - drawH) * 0.5

	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(mat)
	surface.DrawTexturedRect(x, y, drawW, drawH)
end

local function configureTDMButton(btn)
	btn:SetContentAlignment(5)
end

local function styleBuyMenuActionButton(btn)
	configureTDMButton(btn)
	btn:SetTall(TDM_BTN_ROW_H())
end

local function configureTDMItemLabel(lbl, text, font, textColor, maxLines)
	lbl:SetText(text or "")
	lbl:SetFont(font or "ZB_TDM_MENU")
	lbl:SetTextColor(textColor or color_white)
	lbl:SetWrap(true)
	lbl:SetContentAlignment(4)
	lbl:Dock(TOP)

	if maxLines and maxLines > 0 then
		surface.SetFont(lbl:GetFont())
		local _, lineH = surface.GetTextSize("Ay")
		local extraPad = (font == "ZB_TDM_DESC" or lbl:GetFont() == "ZB_TDM_DESC") and 6 or 2
		lbl:SetTall(lineH * maxLines + extraPad)
	else
		lbl:SetAutoStretchVertical(true)
	end
end

local function createTDMItemTextBlock(parent, itemName, priceText)
	local textBlock = vgui.Create("DPanel", parent)
	textBlock:Dock(TOP)
	textBlock:DockMargin(6, 0, 6, 2)
	textBlock:SetTall(getTDMTextBlockHeight())
	textBlock.Paint = function() end

	local nameLbl = vgui.Create("DLabel", textBlock)
	configureTDMItemLabel(nameLbl, itemName, "ZB_TDM_MENU", Color(238, 238, 238), 2)
	nameLbl:DockMargin(0, 0, 4, 2)

	local priceLbl = vgui.Create("DLabel", textBlock)
	configureTDMItemLabel(priceLbl, priceText, "ZB_TDM_DESC", Color(130, 210, 145), 1)
	priceLbl:DockMargin(0, 0, 4, 2)

	return textBlock
end

local function createTDMRefundTextBlock(parent, itemName, priceText)
	local textBlock = vgui.Create("DPanel", parent)
	textBlock:Dock(FILL)
	textBlock:DockMargin(10, 0, 8, 0)
	textBlock.Paint = function() end

	local nameLbl = vgui.Create("DLabel", textBlock)
	nameLbl:SetText(itemName or "")
	nameLbl:SetFont("ZB_TDM_MENU")
	nameLbl:SetTextColor(Color(238, 238, 238))
	nameLbl:SetWrap(true)
	nameLbl:SetContentAlignment(5)

	local priceLbl = vgui.Create("DLabel", textBlock)
	priceLbl:SetText(priceText or "")
	priceLbl:SetFont("ZB_TDM_DESC")
	priceLbl:SetTextColor(Color(130, 210, 145))
	priceLbl:SetContentAlignment(5)

	function textBlock:PerformLayout(w, h)
		surface.SetFont("ZB_TDM_MENU")
		local _, nameLineH = surface.GetTextSize("Ay")
		surface.SetFont("ZB_TDM_DESC")
		local _, priceLineH = surface.GetTextSize("Ay")

		nameLbl:SetWide(w)
		priceLbl:SetWide(w)
		nameLbl:SetTall(nameLineH * 2 + 2)
		priceLbl:SetTall(priceLineH + 2)

		local blockH = nameLbl:GetTall() + priceLbl:GetTall() + 6
		local y = math.max(0, math.floor((h - blockH) * 0.5))

		nameLbl:SetPos(0, y)
		priceLbl:SetPos(0, y + nameLbl:GetTall() + 4)
	end

	return textBlock
end

local function paintTDMIconSlot(slot, w, h, weaponAccent)
	local theme = GetBuyMenuTheme()
	local accentH = weaponAccent and TDM_ICON_BOTTOM_ACCENT or 0
	local imageH = h - accentH

	draw.RoundedBox(0, 1, 1, w - 2, imageH - 2, theme.InnerBackground)
	SetThemeDrawColor(theme.Outline, defaultBuyMenuTheme.Outline)
	surface.DrawOutlinedRect(0, 0, w, imageH, 1)

	paintContainedImage(slot._tdmMat, w, imageH, TDM_ICON_PAD)

	if weaponAccent then
		SetThemeDrawColor(theme.Outline, defaultBuyMenuTheme.Outline)
		surface.DrawRect(1, imageH, w - 2, accentH)
	end
end

local function createTDMIconSlot(parent, imagePath, opts)
	opts = opts or {}

	local rowH = opts.rowH
	local iconW, iconH

	if rowH then
		iconW, iconH = getTDMItemIconDimensions(rowH)
	else
		local size = opts.size or math.ceil(ScrH() * 0.088)
		iconW, iconH = size, size
	end

	local marginL = opts.marginL or TDM_CARD_PAD_LEFT
	local marginT = opts.marginT or TDM_CARD_PAD_TOP
	local marginR = opts.marginR or 6
	local marginB = opts.marginB or TDM_CARD_PAD_BOTTOM
	local weaponAccent = opts.weaponAccent ~= false

	local wrap = vgui.Create("DPanel", parent)
	wrap:Dock(opts.dock or LEFT)
	wrap:SetWide(iconW + marginL + marginR)
	wrap:DockMargin(marginL, marginT, marginR, marginB)
	wrap.Paint = function() end
	wrap._tdmIconW = iconW
	wrap._tdmIconH = iconH

	local slot = vgui.Create("DPanel", wrap)
	slot._tdmMat = loadTDMIconMaterial(imagePath)
	slot._tdmWeaponAccent = weaponAccent

	function wrap:PerformLayout(w, h)
		local iw, ih = self._tdmIconW, self._tdmIconH
		local totalH = ih + (slot._tdmWeaponAccent and TDM_ICON_BOTTOM_ACCENT or 0)
		self:SetTall(totalH)
		slot:SetSize(iw, totalH)
		slot:SetPos(0, 0)
	end

	function slot:Paint(w, h)
		paintTDMIconSlot(self, w, h, self._tdmWeaponAccent)
	end

	return wrap
end

local function createTDMAttachmentButton(parent, imagePath, size, onClick)
	local btn = vgui.Create("DButton", parent)
	btn:SetSize(size, size)
	btn:SetText("")
	btn._tdmMat = loadTDMIconMaterial(imagePath)
	configureTDMButton(btn)

	function btn:Paint(w, h)
		PaintPanel2(self, w, h)

		local theme = GetBuyMenuTheme()
		SetThemeDrawColor(theme.AttachmentOutline, defaultBuyMenuTheme.AttachmentOutline)
		surface.DrawOutlinedRect(0, 0, w, h, 1)

		paintContainedImage(self._tdmMat, w, h, TDM_ICON_PAD)
	end

	function btn:DoClick()
		if onClick then onClick(self) end
	end

	return btn
end

local TDM_BUY_CATEGORY_ORDER = {
	"Medical",
	"Melee",
	"Pistols",
	"Submachine",
	"Carbines",
	"Assault",
	"Shotguns",
	"Heavy",
	"Marksman/Sniper",
	"Special",
	"Equipment",
	"Explosive",
	"Ammo",
}

local TDM_BUY_CATEGORY_RANK = {}
for i, categoryName in ipairs(TDM_BUY_CATEGORY_ORDER) do
	TDM_BUY_CATEGORY_RANK[categoryName] = i
end

local function getBuyItemPrice(item)
	if not istable(item) then return 0 end

	return tonumber(item.Price) or 0
end

local function compareBuyItemsByPrice(a, b)
	local priceA = getBuyItemPrice(a.item)
	local priceB = getBuyItemPrice(b.item)

	if priceA != priceB then
		return priceA < priceB
	end

	return a.n < b.n
end

local function getBuyCategorySortRank(categoryName, category)
	local rank = TDM_BUY_CATEGORY_RANK[categoryName]
	if rank then return rank end

	local priority = istable(category) and tonumber(category.Priority) or 999

	return 1000 + priority
end

local function categoryHasVisibleItems(category, team)
	for n, Item in pairs(category) do
		if n == "Priority" then continue end
		if Item.TeamBased != nil and Item.TeamBased != team then continue end
		return true
	end

	return false
end

local function collectSortedBuyCategories(buyItems, team)
	local categories = {}

	for categoryName, category in pairs(buyItems) do
		if categoryHasVisibleItems(category, team) then
			categories[#categories + 1] = {
				name = categoryName,
				category = category,
			}
		end
	end

	table.sort(categories, function(a, b)
		local rankA = getBuyCategorySortRank(a.name, a.category)
		local rankB = getBuyCategorySortRank(b.name, b.category)

		if rankA != rankB then
			return rankA < rankB
		end

		return a.name < b.name
	end)

	return categories
end

local function collectVisibleCategoryItems(category, team)
	local itemsList = {}

	for n, Item in pairs(category) do
		if n == "Priority" then continue end
		if Item.TeamBased != nil and Item.TeamBased != team then continue end
		itemsList[#itemsList + 1] = {n = n, item = Item}
	end

	table.sort(itemsList, compareBuyItemsByPrice)

	return itemsList
end

local function GetShop()
	return zb.TDMShop
end

TDM_ActiveConfirmFrame = TDM_ActiveConfirmFrame or nil

local function flushTDMConfirmPendingInventoryRefresh()
	if not IsValid(TDM_OpenedBuyMenu) or not TDM_OpenedBuyMenu._tdmPendingInventoryRefresh then return end

	TDM_OpenedBuyMenu._tdmPendingInventoryRefresh = nil

	if IsValid(TDM_OpenedBuyMenu._tdmInventoryPanel) then
		buildTDMInventoryPanel(TDM_OpenedBuyMenu._tdmInventoryPanel)
	end
end

local function restoreBuyMenuInputAfterConfirm()
	if not IsValid(TDM_OpenedBuyMenu) then return end

	if TDM_OpenedBuyMenu._tdmConfirmRestoreInput ~= nil then
		TDM_OpenedBuyMenu:SetMouseInputEnabled(TDM_OpenedBuyMenu._tdmConfirmRestoreInput)
		TDM_OpenedBuyMenu._tdmConfirmRestoreInput = nil
	end
end

local function dismissTDMConfirm(frame)
	if IsValid(frame) then
		frame:Remove()
	end

	if frame == nil or TDM_ActiveConfirmFrame == frame then
		TDM_ActiveConfirmFrame = nil
	end

	restoreBuyMenuInputAfterConfirm()
	flushTDMConfirmPendingInventoryRefresh()
end

local function createTDMConfirmButton(parent, label, paintFn, textColor, onClick, btnWide)
	local btnH = TDM_BTN_ROW_H()

	local btn = vgui.Create("DButton", parent)
	btn:SetWide(btnWide)
	btn:SetTall(btnH)
	btn:SetText(label)
	btn:SetFont("ZB_TDM_DESC")
	btn:SetTextColor(textColor)
	btn.Paint = paintFn
	btn:SetMouseInputEnabled(true)
	btn:SetKeyboardInputEnabled(true)
	styleBuyMenuActionButton(btn)

	function btn:DoClick()
		if self._tdmConfirmLocked then return end
		self._tdmConfirmLocked = true

		if onClick then
			onClick()
		end
	end

	return btn
end

local function getTDMConfirmChrome()
	return {
		margin = math.max(ScreenScale(10), 12),
		btnGap = math.max(ScreenScale(8), 10),
		titleBarH = math.max(ScreenScale(24), 26),
		btnPadX = math.max(ScreenScale(14), 20),
		outlineSlack = ScreenScale(6),
	}
end

local function measureTDMConfirmButtonWidth(label, chrome)
	surface.SetFont("ZB_TDM_DESC")
	local textW = select(1, surface.GetTextSize(label or ""))

	return math.max(textW + chrome.btnPadX * 2, ScreenScale(52))
end

local function measureTDMCompactConfirmLayout(title, confirmLabel, cancelLabel)
	local chrome = getTDMConfirmChrome()
	local confirmW = measureTDMConfirmButtonWidth(confirmLabel, chrome)
	local cancelW = measureTDMConfirmButtonWidth(cancelLabel, chrome)
	local buttonsW = confirmW + cancelW + chrome.btnGap
	local btnH = TDM_BTN_ROW_H()

	surface.SetFont("ZB_TDM_MENU")
	local titleW = select(1, surface.GetTextSize(title or ""))

	local frameW = math.max(buttonsW, titleW) + chrome.margin * 2 + chrome.outlineSlack
	local frameH = chrome.titleBarH + chrome.margin + btnH + chrome.margin + chrome.outlineSlack

	return {
		frameW = frameW,
		frameH = frameH,
		confirmW = confirmW,
		cancelW = cancelW,
		btnH = btnH,
		chrome = chrome,
	}
end

local function layoutTDMCompactConfirmButtons(btnRow, confirmBtn, cancelBtn, layout)
	local chrome = layout.chrome
	local rowW = layout.confirmW + layout.cancelW + chrome.btnGap

	function btnRow:PerformLayout(w, h)
		if not IsValid(confirmBtn) or not IsValid(cancelBtn) then return end

		local x = math.max(0, math.floor((w - rowW) * 0.5))
		local y = math.max(0, math.floor((h - layout.btnH) * 0.5))

		confirmBtn:SetSize(layout.confirmW, layout.btnH)
		confirmBtn:SetPos(x, y)

		cancelBtn:SetSize(layout.cancelW, layout.btnH)
		cancelBtn:SetPos(x + layout.confirmW + chrome.btnGap, y)
	end

	btnRow:InvalidateLayout(true)
end

local function applyTDMCompactConfirmFrameSize(frame, body, layout)
	local chrome = layout.chrome

	frame:SetSize(layout.frameW, layout.frameH)
	frame:Center()

	body:DockMargin(chrome.margin, chrome.titleBarH, chrome.margin, chrome.margin)
end

local function ShowTDMCompactConfirm(title, confirmLabel, onConfirm, cancelLabel)
	cancelLabel = cancelLabel or "Cancel"
	title = title or "Confirm"
	confirmLabel = confirmLabel or "Confirm"

	dismissTDMConfirm(TDM_ActiveConfirmFrame)

	local layout = measureTDMCompactConfirmLayout(title, confirmLabel, cancelLabel)

	local frame = vgui.Create("ZFrame")
	TDM_ActiveConfirmFrame = frame
	frame:SetTitle(title)
	frame:ShowCloseButton(false)
	frame.Paint = PaintFrame
	ApplyBuyMenuFrameColors(frame)
	frame:SetKeyboardInputEnabled(true)
	frame:SetMouseInputEnabled(true)
	frame:SetDrawOnTop(true)
	frame:SetZPos(32767)
	frame._tdmOnConfirm = onConfirm
	frame._tdmConfirmLayout = layout

	if IsValid(TDM_OpenedBuyMenu) then
		TDM_OpenedBuyMenu._tdmConfirmRestoreInput = TDM_OpenedBuyMenu:IsMouseInputEnabled()
		TDM_OpenedBuyMenu:SetMouseInputEnabled(false)
	end

	function frame:OnRemove()
		if TDM_ActiveConfirmFrame == self then
			TDM_ActiveConfirmFrame = nil
		end

		restoreBuyMenuInputAfterConfirm()
		flushTDMConfirmPendingInventoryRefresh()
	end

	function frame:OnKeyCodePressed(key)
		if key == KEY_ESCAPE then
			dismissTDMConfirm(self)
		end
	end

	local body = vgui.Create("DPanel", frame)
	body:Dock(FILL)
	body.Paint = function() end
	body:SetMouseInputEnabled(true)

	local btnRow = vgui.Create("DPanel", body)
	btnRow:Dock(FILL)
	btnRow.Paint = function() end
	btnRow:SetMouseInputEnabled(true)

	local confirmBtn = createTDMConfirmButton(btnRow, confirmLabel, PaintPanel1, Color(255, 220, 220), function()
		local callback = frame._tdmOnConfirm
		frame._tdmOnConfirm = nil
		dismissTDMConfirm(frame)

		if callback then
			callback()
		end
	end, layout.confirmW)

	local cancelBtn = createTDMConfirmButton(btnRow, cancelLabel, PaintPanel, Color(210, 210, 210), function()
		frame._tdmOnConfirm = nil
		dismissTDMConfirm(frame)
	end, layout.cancelW)

	applyTDMCompactConfirmFrameSize(frame, body, layout)
	layoutTDMCompactConfirmButtons(btnRow, confirmBtn, cancelBtn, layout)
	frame:MakePopup()
	frame:MoveToFront()

	timer.Simple(0, function()
		if not IsValid(frame) then return end

		local titleBarH = frame.lblTitle and frame.lblTitle:GetTall() or layout.chrome.titleBarH
		if titleBarH > layout.chrome.titleBarH then
			layout.chrome.titleBarH = titleBarH
			layout.frameH = titleBarH + layout.chrome.margin + layout.btnH + layout.chrome.margin + layout.chrome.outlineSlack
			applyTDMCompactConfirmFrameSize(frame, body, layout)
			layoutTDMCompactConfirmButtons(btnRow, confirmBtn, cancelBtn, layout)
		end

		frame:MakePopup()
		frame:Center()
		frame:MoveToFront()
		frame:RequestFocus()
	end)
end

local function sendBuyRequest(itemTable, replace)
	net.Start("tdm_buyitem")
		net.WriteTable(itemTable)
		net.WriteBool(replace or false)
	net.SendToServer()
end

local function promptBuyAttachment(itemName, item, categoryName, itemTable, attName)
	local Shop = GetShop()
	if not Shop then return end

	if not LocalPlayer():HasWeapon(item.ItemClass) then
		sendBuyRequest(itemTable, false)
		return
	end

	local hasConflict = Shop.GetAttachmentConflict(LocalPlayer(), item.ItemClass, attName)
	if not hasConflict then
		sendBuyRequest(itemTable, false)
		return
	end

	ShowTDMCompactConfirm("Replace Item", "Replace", function()
		sendBuyRequest(itemTable, true)
	end)
end

local function promptBuy(itemName, item, categoryName, itemTable)
	local Shop = GetShop()
	if not Shop then return end

	if Shop.IsAmmoPurchase(categoryName, item) then
		sendBuyRequest(itemTable, false)
		return
	end

	local ply = LocalPlayer()
	local needsPrompt, _, _, title = Shop.GetWeaponReplacePromptInfo(ply, item, itemName, categoryName)

	if needsPrompt then
		ShowTDMCompactConfirm(title, "Replace", function()
			sendBuyRequest(itemTable, true)
		end)

		return
	end

	sendBuyRequest(itemTable, false)
end

local function requestTDMPurchaseSync()
	net.Start("tdm_sync_purchases")
	net.SendToServer()
end

local function buildTDMInventoryPanel(InventoryPanel)
	if not IsValid(InventoryPanel) then return end

	local canvas = getBuyMenuListParent(InventoryPanel)
	if not IsValid(canvas) then return end

	canvas:Clear()

	local Shop = GetShop()
	local ply = LocalPlayer()
	local purchases = ply:GetNetVar("TDM_Purchases", {}) or {}
	local hasAny = false
	local weaponCache = {}
	local entCache = {}
	local rowH = TDM_BUY_ROW_H(false)
	local purchaseList = {}

	for purchaseId, purchase in pairs(purchases) do
		if not istable(purchase) then continue end
		if Shop and not Shop.PurchaseStillOwned(ply, purchase) then continue end
		purchaseList[#purchaseList + 1] = {id = purchaseId, purchase = purchase}
	end

	table.sort(purchaseList, function(a, b)
		local priceA = tonumber(a.purchase.price) or 0
		local priceB = tonumber(b.purchase.price) or 0

		if priceA != priceB then
			return priceA < priceB
		end

		local nameA = a.purchase.displayName or a.purchase.index or ""
		local nameB = b.purchase.displayName or b.purchase.index or ""

		return nameA < nameB
	end)

	for _, entry in ipairs(purchaseList) do
		local purchaseId = entry.id
		local purchase = entry.purchase
		hasAny = true

		local row = vgui.Create("DPanel", canvas)
		row:SetSize(0, rowH)
		row:Dock(TOP)
		row:DockMargin(0, TDM_CARD_ROW_MARGIN, 0, 0)
		row.Paint = PaintPanel1

		local iconPath = resolvePurchaseIconPath(purchase, weaponCache, entCache)
		createTDMIconSlot(row, iconPath, {rowH = rowH, weaponAccent = true})

		local textCol = vgui.Create("DPanel", row)
		textCol:Dock(FILL)
		textCol:DockMargin(6, 8, 4, 8)
		textCol.Paint = function() end

		createTDMRefundTextBlock(textCol, purchase.displayName or purchase.index or "Item", "$" .. (purchase.price or 0))

		local refundBtn = vgui.Create("DButton", row)
		refundBtn:Dock(RIGHT)
		refundBtn:DockMargin(6, 8, TDM_CONTENT_PAD, 8)
		refundBtn:SetWide(ScrW() * 0.1)
		refundBtn:SetText("Refund")
		refundBtn:SetFont("ZB_TDM_DESCSMALL")
		refundBtn:SetTextColor(Color(220, 220, 220))
		refundBtn.Paint = PaintPanel
		styleBuyMenuActionButton(refundBtn)
		refundBtn.purchaseId = purchaseId

		function refundBtn:DoClick()
			local purchaseId = self.purchaseId

			ShowTDMCompactConfirm("Refund", "Confirm", function()
				net.Start("tdm_refunditem")
					net.WriteUInt(purchaseId, 16)
				net.SendToServer()
			end)
		end
	end

	if not hasAny then
		local emptyLbl = vgui.Create("DLabel", canvas)
		emptyLbl:Dock(TOP)
		emptyLbl:DockMargin(10, 12, 10, 0)
		emptyLbl:SetFont("ZB_TDM_DESC")
		emptyLbl:SetTextColor(Color(200, 200, 200))
		emptyLbl:SetText("No purchased items to refund.")
	end
end

local function addBuyItemRow(CategoryPanel, categoryName, itemName, Item, buyItems, ammoLookup, weaponCache, entCache)
	local weapon = getCachedWeapon(Item.ItemClass, weaponCache)
	local ent = getCachedEnt(Item.ItemClass, entCache)

	local attachmentNames = {}
	if Item.Attachments then
		for _, attachName in pairs(Item.Attachments) do
			attachmentNames[#attachmentNames + 1] = attachName
		end
	end

	local attCount = #attachmentNames
	local attCols = TDM_ATTACH_ICON_COLS
	local attIconSize = TDM_ATTACH_ICON_SIZE()
	local attGridRows = attCount > 0 and math.ceil(attCount / attCols) or 0
	local attPanelW = attCount > 0 and (attCols * attIconSize + 20) or 0
	local attPanelH = attCount > 0 and (math.min(attGridRows, TDM_ATTACH_MAX_ROWS) * attIconSize + 14) or 0
	local rowH = TDM_BUY_ROW_H(attCount > 0, attGridRows)
	local needsAttScroll = attGridRows > TDM_ATTACH_MAX_ROWS

	local listParent = getBuyMenuListParent(CategoryPanel)

	local ItemPanel = vgui.Create("DPanel", listParent)
	ItemPanel:SetTall(rowH)
	ItemPanel:Dock(TOP)
	ItemPanel:DockMargin(0, TDM_CARD_ROW_MARGIN, 0, 0)
	ItemPanel.Paint = PaintPanel1

	local iconPath = resolveItemIconPath(weapon, ent)
	createTDMIconSlot(ItemPanel, iconPath, {rowH = rowH, weaponAccent = true})

	if attCount > 0 then
		local attWrap = vgui.Create("DPanel", ItemPanel)
		attWrap:Dock(RIGHT)
		attWrap:SetWide(attPanelW)
		attWrap:SetTall(attPanelH)
		attWrap:DockMargin(4, TDM_CARD_PAD_TOP, TDM_CONTENT_PAD, TDM_CARD_PAD_BOTTOM)
		attWrap.Paint = function(self, w, h)
			PaintPanel2(self, w, h)
		end

		local attParent = attWrap

		if needsAttScroll then
			local attScroll = vgui.Create("DScrollPanel", attWrap)
			attScroll:Dock(FILL)
			attScroll:DockMargin(4, 4, 4, 4)
			attScroll.Paint = function() end
			setupBuyMenuScrollPanel(attScroll)
			attParent = attScroll
		end

		local ItemAtt = vgui.Create("DGrid", attParent)
		ItemAtt:Dock(TOP)
		ItemAtt:SetCols(attCols)
		ItemAtt:SetColWide(attIconSize)
		ItemAtt:SetRowHeight(attIconSize)
		ItemAtt.Paint = function() end

		for _, AttachN in ipairs(attachmentNames) do
			local ico = resolveAttachmentIconPath(AttachN)
			local attachmentData = {categoryName, itemName, AttachN}
			local Attach = createTDMAttachmentButton(ItemAtt, ico, attIconSize, function()
				promptBuyAttachment(itemName, Item, categoryName, attachmentData, AttachN)
			end)

			Attach.Attachment = attachmentData
			ItemAtt:AddItem(Attach)
		end

		ItemAtt:SetTall(attGridRows * attIconSize)
	end

	local contentPanel = vgui.Create("DPanel", ItemPanel)
	contentPanel:Dock(FILL)
	contentPanel:DockMargin(4, TDM_CARD_PAD_TOP, attCount > 0 and 6 or TDM_CONTENT_PAD, TDM_CARD_PAD_BOTTOM)
	contentPanel.Paint = function() end

	createTDMItemTextBlock(contentPanel, itemName, "Price: $" .. Item.Price)

	local textSpacer = vgui.Create("DPanel", contentPanel)
	textSpacer:Dock(FILL)
	textSpacer.Paint = function() end

	local btnRow = vgui.Create("DPanel", contentPanel)
	btnRow:Dock(BOTTOM)
	btnRow:SetTall(TDM_BTN_ROW_H())
	btnRow:DockMargin(0, 6, 0, 0)
	btnRow.Paint = function() end

	local BuyBtn = vgui.Create("DButton", btnRow)
	BuyBtn:Dock(LEFT)
	BuyBtn:DockMargin(0, 0, 6, 0)
	BuyBtn:SetWide(math.max(ScrW() * 0.065, 72))
	BuyBtn:SetText("Buy")
	BuyBtn:SetTextColor(Color(225, 225, 225))
	BuyBtn:SetFont("ZB_TDM_DESC")
	BuyBtn.Paint = PaintPanel
	styleBuyMenuActionButton(BuyBtn)
	BuyBtn.Item = {categoryName, itemName}

	function BuyBtn:DoClick()
		promptBuy(itemName, Item, categoryName, self.Item)
	end

	if weapon and weapon.Primary then
		local ammo = weapon.Primary.Ammo != "none" and weapon.Primary.Ammo or weapon.Ammo
		if not ammo and weapon.Base then
			local baseWeapon = getCachedWeapon(weapon.Base, weaponCache)
			ammo = baseWeapon and baseWeapon.Primary and baseWeapon.Primary.Ammo
		end

		if ammo and hg.ammotypeshuy[ammo] then
			local amm = vgui.Create("DButton", btnRow)
			amm:Dock(LEFT)
			amm:SetText(ammo)
			amm:SetTextColor(Color(210, 210, 210))
			amm:SetFont("ZB_TDM_DESCSMALL")

			surface.SetFont("ZB_TDM_DESCSMALL")
			local textW = surface.GetTextSize(ammo)

			amm:DockMargin(0, 0, 0, 0)
			amm:SetWide(textW + 16)
			styleBuyMenuActionButton(amm)
			local ammo2 = "ent_ammo_" .. hg.ammotypeshuy[ammo].name
			local name = ammoLookup[ammo2]

			amm.huy = {"Ammo", name}

			function amm:DoClick()
				sendBuyRequest(amm.huy, false)
			end

			amm.Paint = PaintPanel
		end
	end
end

local function buildCategoryItems(categoryName, categoryPanel, category, buyItems, ammoLookup, weaponCache, entCache)
	if not IsValid(categoryPanel) or categoryPanel._tdmBuilt or categoryPanel._tdmBuilding then return end

	cancelBuyMenuBuildTimer()

	local itemsList = collectVisibleCategoryItems(category, LocalPlayer():Team())
	if #itemsList == 0 then
		categoryPanel._tdmBuilt = true
		return
	end

	categoryPanel._tdmBuilding = true
	TDM_BuyMenuBuildingPanel = categoryPanel

	local index = 1
	local timerName = "TDM_BuyMenuBuild_" .. categoryName .. "_" .. tostring(categoryPanel)

	TDM_BuyMenuBuildTimer = timerName
	timer.Create(timerName, 0, 0, function()
		if not IsValid(categoryPanel) then
			cancelBuyMenuBuildTimer()
			return
		end

		for _ = 1, TDM_BUY_ITEMS_PER_TICK do
			if index > #itemsList then
				categoryPanel._tdmBuilt = true
				categoryPanel._tdmBuilding = false
				cancelBuyMenuBuildTimer()
				return
			end

			local entry = itemsList[index]
			addBuyItemRow(categoryPanel, categoryName, entry.n, entry.item, buyItems, ammoLookup, weaponCache, entCache)
			index = index + 1
		end
	end)
end

local function OpenBuyMenu()
	cancelBuyMenuBuildTimer()

	if TDM_OpenedBuyMenu then
		TDM_OpenedBuyMenu:Remove()
		TDM_OpenedBuyMenu = nil
	end

	local StartTime = zb.ROUND_START or CurTime()
	if not LocalPlayer():Alive() or StartTime + 40 < CurTime() then return end

	local round = CurrentRound and CurrentRound() or MODE
	local buyItems = (round and round.BuyItems) or MODE.BuyItems
	if not buyItems then return end

	local playerTeam = LocalPlayer():Team()
	local ammoLookup = buildAmmoLookup(buyItems)
	local weaponCache = {}
	local entCache = {}
	local categoryPanels = {}
	local categoryData = {}

	TDM_OpenedBuyMenu = vgui.Create("ZFrame")
	local Frame = TDM_OpenedBuyMenu
	Frame:SetSize(math.min(ScrW() * 0.58, 1180), ScrH() * 0.85)
	Frame:Center()
	Frame:MakePopup()
	Frame:SetTitle("Buy menu")
	Frame.Paint = PaintFrame
	ApplyBuyMenuFrameColors(Frame)

	function Frame:OnRemove()
		cancelBuyMenuBuildTimer()

		dismissTDMConfirm(TDM_ActiveConfirmFrame)
	end

	local Sheet = vgui.Create("DPropertySheet", Frame)
	Sheet:Dock(FILL)
	Sheet.Paint = function() end
	Sheet.tabScroller:SetOverlap(0)
	Sheet.tabScroller:DockMargin(getTDMTabSideInset(), 0, getTDMTabSideInset(), 0)
	Sheet:SetFadeTime(0.1)

	local sheetBasePerformLayout = Sheet.PerformLayout
	function Sheet:PerformLayout(w, h)
		if self._tdmTabLayouting then return end
		self._tdmTabLayouting = true

		if sheetBasePerformLayout then
			sheetBasePerformLayout(self, w, h)
		end

		fitTDMPropertySheetTabs(self)

		self._tdmTabLayouting = false
	end

	local function buildActiveCategoryTab(tab)
		if not IsValid(tab) or not tab._categoryName then return end

		if tab._tdmInventoryTab then
			requestTDMPurchaseSync()
			buildTDMInventoryPanel(categoryPanels.Inventory)
			return
		end

		local categoryName = tab._categoryName
		local categoryPanel = categoryPanels[categoryName]
		local category = categoryData[categoryName]

		if IsValid(categoryPanel) and category then
			buildCategoryItems(categoryName, categoryPanel, category, buyItems, ammoLookup, weaponCache, entCache)
		end
	end

	function Sheet:OnActiveTabChanged(_, new)
		buildActiveCategoryTab(new)
	end

	local InventoryPanel = vgui.Create("DScrollPanel", Sheet)
	InventoryPanel.Paint = function() end
	setupBuyMenuScrollPanel(InventoryPanel)
	categoryPanels.Inventory = InventoryPanel

	local inventoryTab = Sheet:AddSheet("Inventory", InventoryPanel)
	local inventoryRTab = inventoryTab["Tab"]
	setupTDMPropertySheetTab(inventoryRTab, "Inventory")
	inventoryRTab._categoryName = "Inventory"
	inventoryRTab._tdmInventoryTab = true

	Frame._tdmInventoryPanel = InventoryPanel
	requestTDMPurchaseSync()
	buildTDMInventoryPanel(InventoryPanel)

	for _, categoryEntry in ipairs(collectSortedBuyCategories(buyItems, playerTeam)) do
		local k = categoryEntry.name
		local category = categoryEntry.category

		categoryData[k] = category

		local CategoryPanel = vgui.Create("DScrollPanel", Sheet)
		CategoryPanel.Paint = function() end
		setupBuyMenuScrollPanel(CategoryPanel)
		categoryPanels[k] = CategoryPanel

		local tab = Sheet:AddSheet(k, CategoryPanel)
		local rTab = tab["Tab"]
		setupTDMPropertySheetTab(rTab, k)
		rTab._categoryName = k
	end

	fitTDMPropertySheetTabs(Sheet)

	function Frame:PerformLayout(w, h)
		if self.BaseClass and self.BaseClass.PerformLayout then
			self.BaseClass.PerformLayout(self, w, h)
		end

		if IsValid(Sheet) then
			fitTDMPropertySheetTabs(Sheet)
		end
	end

	timer.Simple(0, function()
		if not IsValid(Frame) then return end
		fitTDMPropertySheetTabs(Sheet)
		buildActiveCategoryTab(Sheet:GetActiveTab())
	end)

	local lbl = vgui.Create("DLabel", Frame)
	lbl:SetText("Time Left: "..string.FormattedTime(StartTime + 40 - CurTime(), "%02i:%02i:%02i"))
	lbl:DockMargin(10,0,10,10)
	lbl:Dock(BOTTOM)
	lbl:SetTextColor(Color(255,255,255))
	lbl:SetFont("ZB_TDM_DESC")
	lbl:SetSize(0,ScrH()*0.015)

	function lbl:Think()
		if not LocalPlayer():Alive() or StartTime + 40 < CurTime() then TDM_OpenedBuyMenu:Remove() end
		self:SetText("Time Left: "..string.FormattedTime(StartTime + 40 - CurTime(), "%02i:%02i:%02i"))
	end

	local lbl = vgui.Create("DLabel", Frame)
	lbl:SetText("Cash: $"..LocalPlayer():GetNWInt("TDM_Money",0))
	lbl:DockMargin(10,5,10,5)
	lbl:Dock(BOTTOM)
	lbl:SetTextColor(Color(61,173,61))
	lbl:SetFont("ZB_TDM_DESC")
	lbl:SetSize(0,ScrH()*0.02)

	function lbl:Think()
		self:SetText("Cash: $"..LocalPlayer():GetNWInt("TDM_Money",0))
	end

end

net.Receive("tdm_open_buymenu",function() OpenBuyMenu() end)
TDM_OpenedBuyMenu = TDM_OpenedBuyMenu or nil

hook.Add("OnNetVarSet", "TDM_BuyMenu_InventoryRefresh", function(index, key)
	if key != "TDM_Purchases" then return end
	if index != LocalPlayer():EntIndex() then return end
	if not IsValid(TDM_OpenedBuyMenu) or not IsValid(TDM_OpenedBuyMenu._tdmInventoryPanel) then return end

	if IsValid(TDM_ActiveConfirmFrame) then
		TDM_OpenedBuyMenu._tdmPendingInventoryRefresh = true
		return
	end

	buildTDMInventoryPanel(TDM_OpenedBuyMenu._tdmInventoryPanel)
end)
