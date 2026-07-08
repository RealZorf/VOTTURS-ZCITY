local PANEL = {}
local curent_panel 
local select_color = Color(35, 255, 110)
local menuFontW, menuFontH

local function MenuScale(size)
    local scale = math.Clamp(math.min(ScrW() / 1920, ScrH() / 1080), 0.78, 1.15)
    return math.Round(size * scale)
end

local function MenuLeftWidth()
    local maxWidth = math.min(ScrW() * 0.34, 680)
    local minWidth = math.min(360, maxWidth)

    return math.Clamp(MenuScale(520), minWidth, maxWidth)
end

local function CreateMenuFonts()
    if menuFontW == ScrW() and menuFontH == ScrH() then return end

    menuFontW, menuFontH = ScrW(), ScrH()

    surface.CreateFont("ZC_MM_Title", {
        font = "Bahnschrift",
        size = MenuScale(98),
        weight = 800,
        antialias = true
    })

    surface.CreateFont("ZC_MM_Button", {
        font = "Bahnschrift",
        size = MenuScale(38),
        weight = 700,
        antialias = true
    })

    surface.CreateFont("ZC_MM_Tiny", {
        font = "Bahnschrift",
        size = MenuScale(18),
        weight = 700,
        antialias = true
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
    {Title = "Settings", Func = function(luaMenu,pp) hg.DrawSettings(pp) end},
    {Title = "Achievements", Func = function(luaMenu,pp) hg.DrawAchievmentsMenu(pp) end},
    {Title = "Appearance", Func = function(luaMenu,pp) hg.CreateApperanceMenu(pp) end},
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

--print(string.upper('I wish you good health, Jason Statham'))
-- local Title = markup.Parse("error")

local Pluv = Material("pluv/pluvkid.jpg")

function PANEL:InitializeMarkup()
	local gm = splasheh[math.random(#splasheh)]

    if hg.PluvTown.Active then
        local text = "<font=ZC_MM_Title><colour=125,205,255>    </colour>City</font>\n<font=ZC_MM_Tiny><colour=105,105,105>" .. gm .. "</colour></font>"

        self.SelectedPluv = table.Random(hg.PluvTown.PluvMats)

        return markup.Parse(text)
    end

    local text = "<font=ZC_MM_Title><colour=35,255,110,255>VOTTUR'S</colour><colour=255,255,255,0>  </colour>\nZCITY</font>\n<font=ZC_MM_Tiny><colour=105,105,105>" .. gm .. "</colour></font>"
    return markup.Parse(text)
end

local color_red = Color(13, 82, 37, 45)
local clr_gray = Color(255, 255, 255, 25)
local clr_verygray = Color(10, 10, 19, 235)

function PANEL:Init()
    CreateMenuFonts()

    self:SetAlpha(0)
    self:SetSize(ScrW(), ScrH() + 50)
    self:Center()
    self:SetTitle("")
    self:SetDraggable(false)
    self:SetBorder(false)
    self:SetColorBG(clr_verygray)
    self:SetDraggable(false)
    self:ShowCloseButton(false)
    curent_panel = nil
    self.Title, self.TitleShadow = self:InitializeMarkup()

    timer.Simple(0, function()
        if self.First then
            self:First()
        end
    end)

    self.lDock = vgui.Create("DPanel", self)
    local lDock = self.lDock
    local leftWidth = MenuLeftWidth()
    local visibleSelects = {}
    for k, v in ipairs(Selects) do
        if v.GamemodeOnly and engine.ActiveGamemode() != "zcity" then continue end

        visibleSelects[#visibleSelects + 1] = v
    end

    local buttonHeight = MenuScale(47)
    local buttonGap = MenuScale(2)
    local titleToButtons = MenuScale(185)
    local footerHeight = MenuScale(76)
    local buttonDockH = #visibleSelects * (buttonHeight + buttonGap) + buttonGap
    local footerY = ScrH() - footerHeight - MenuScale(34)
    local maxGroupTop = footerY - titleToButtons - buttonDockH - MenuScale(44)
    local groupTop = math.max(MenuScale(54), math.min(ScrH() * 0.32, maxGroupTop))
    local buttonDockY = groupTop + titleToButtons

    lDock:Dock(LEFT)
    lDock:SetSize(leftWidth, ScrH())
    lDock:DockMargin(0, 0, MenuScale(10), 0)
    lDock.Paint = function(this, w, h)
        if hg.PluvTown.Active then
            surface.SetDrawColor(color_white)
            surface.SetMaterial(self.SelectedPluv or Pluv)
            surface.DrawTexturedRect(0, MenuScale(54), MenuScale(70), MenuScale(54))
        end

        self.Title:Draw(MenuScale(34), groupTop + MenuScale(120), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 255, TEXT_ALIGN_LEFT)
    end

    self.Buttons = {}
    local buttonDock = vgui.Create("DPanel", lDock)
    buttonDock:SetPos(0, buttonDockY)
    buttonDock:SetSize(leftWidth, buttonDockH)
    buttonDock.Paint = function(this, w, h) end

    for k, v in ipairs(visibleSelects) do
        self:AddSelect(buttonDock, v.Title, v)
    end

    local bottomDock = vgui.Create("DPanel", self)
    bottomDock:SetPos(MenuScale(24), footerY)
    bottomDock:SetSize(leftWidth, footerHeight)
    bottomDock.Paint = function(this, w, h) end
    self.panelparrent = vgui.Create("DPanel", self)
    self.panelparrent:SetPos(leftWidth + MenuScale(32), 0)
    self.panelparrent:SetSize(ScrW() - leftWidth - MenuScale(32), ScrH())
    self.panelparrent.Paint = function(this, w, h) end
    
    local gitHubURL = "https://github.com/RealZorf/Z-City"
    local gitHubText = "https://github.com/RealZorf/Z-City"

    local git = vgui.Create("DLabel", bottomDock)
    git:Dock(BOTTOM)
    git:DockMargin(MenuScale(10), 0, 0, 0)
    git:SetFont("ZC_MM_Tiny")
    git:SetTextColor(clr_gray)
    git:SetText(gitHubText)
    git:SetContentAlignment(4)
    git:SetMouseInputEnabled(true)
    git:SizeToContents()

    function git:DoClick()
        gui.OpenURL(gitHubURL)
    end

    local zteam = vgui.Create("DLabel", bottomDock)
    zteam:Dock(BOTTOM)
    zteam:DockMargin(MenuScale(10), 0, 0, 0)
    zteam:SetFont("ZC_MM_Tiny")
    zteam:SetTextColor(clr_gray)
    zteam:SetText("Authors: Vottur, Zorf, Patidinho")
    zteam:SetContentAlignment(4)
    zteam:SizeToContents()
end

function PANEL:First( ply )
    self:AlphaTo( 255, 0.1, 0, nil )
end

local gradient_d = surface.GetTextureID("vgui/gradient-d")
local gradient_r = surface.GetTextureID("vgui/gradient-u")
local gradient_l = surface.GetTextureID("vgui/gradient-l")

local clr_1 = Color(13, 64, 22, 72)
function PANEL:Paint(w,h)
    draw.RoundedBox( 0, 0, 0, w, h, self.ColorBG )
    hg.DrawBlur(self, 5)
    surface.SetDrawColor( self.ColorBG )
    surface.SetTexture( gradient_l )
    surface.DrawTexturedRect(0,0,w,h)
    surface.SetDrawColor( clr_1 )
    surface.SetTexture( gradient_d )
    surface.DrawTexturedRect(0,0,w,h)
end

function PANEL:AddSelect( pParent, strTitle, tbl )
    local id = #self.Buttons + 1
    self.Buttons[id] = vgui.Create( "DLabel", pParent )
    local btn = self.Buttons[id]
    btn:SetText( strTitle )
    btn:SetMouseInputEnabled( true )
    btn:SizeToContents()
    btn:SetFont( "ZC_MM_Button" )
    btn:SetTall( MenuScale( 44 ) )
    btn:Dock(BOTTOM)
    btn:DockMargin(MenuScale(34), MenuScale(2), 0, 0)
    btn.Func = tbl.Func
    btn.HoveredFunc = tbl.HoveredFunc
    local luaMenu = self 
    if tbl.CreatedFunc then tbl.CreatedFunc(btn, self, luaMenu) end
    btn.RColor = Color(225,225,225)
    function btn:DoClick()
        --,kz needs to be optimized, but there is an error (I should cache luaMenu.panelparrent instead of calling it every time)
        if curent_panel == string.lower(strTitle) then
			for i = 1, 3 do
				surface.PlaySound("shitty/tap_release.wav")
			end
            luaMenu.panelparrent:AlphaTo(0,0.2,0,function()
                luaMenu.panelparrent:Remove()
                luaMenu.panelparrent = nil
                luaMenu.panelparrent = vgui.Create("DPanel", luaMenu)
                
                luaMenu.panelparrent:SetPos(some_coordinates_x, 0)
                luaMenu.panelparrent:SetSize(some_size_x, some_size_y)
                luaMenu.panelparrent.Paint = function(this, w, h) end
                --btn.Func(luaMenu,luaMenu.panelparrent)
                curent_panel = nil
            end)
            return 
        end
        some_size_x = luaMenu.panelparrent:GetWide()
        some_size_y = luaMenu.panelparrent:GetTall()
        some_coordinates_x = luaMenu.panelparrent:GetX()
        luaMenu.panelparrent:AlphaTo(0,0.2,0,function()
            luaMenu.panelparrent:Remove()
            luaMenu.panelparrent = nil
            luaMenu.panelparrent = vgui.Create("DPanel", luaMenu)
            
            luaMenu.panelparrent:SetPos(some_coordinates_x, 0)
            luaMenu.panelparrent:SetSize(some_size_x, some_size_y)
            luaMenu.panelparrent.Paint = function(this, w, h) end
            btn.Func(luaMenu,luaMenu.panelparrent)
            curent_panel = string.lower(strTitle)
        end)
		for i = 1, 3 do
			surface.PlaySound("shitty/tap_depress.wav")
		end
    end

    function btn:Think()
        self.HoverLerp = LerpFT(0.2, self.HoverLerp or 0, (self:IsHovered() or (IsValid(self:GetChild(0)) and self:GetChild(0):IsHovered()) or (IsValid(self:GetChild(0)) and IsValid(self:GetChild(0):GetChild(0)) and self:GetChild(0):GetChild(0):IsHovered())) and 1 or 0)

        local v = self.HoverLerp
        self:SetTextColor(self.RColor:Lerp(select_color, v))

        local targetText = (self:IsHovered()) and string.upper(strTitle) or strTitle
        local crw = self:GetText()

        if (crw ~= targetText) or (curent_panel == string.lower(strTitle)) then
            local ntxt = ""
            local will_text = (curent_panel == string.lower(strTitle) and not strTitle == 'Traitor Role') and '[ '..string.upper(strTitle)..' ]' or strTitle
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
        self:SizeToContents()
    end
end

function PANEL:Close()
    self:AlphaTo( 0, 0.1, 0, function() self:Remove() end)
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

vgui.Register( "ZMainMenu", PANEL, "ZFrame")

hook.Add("OnPauseMenuShow","OpenMainMenu",function()
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
