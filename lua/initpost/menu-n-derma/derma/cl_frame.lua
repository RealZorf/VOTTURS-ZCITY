--

----
local PANEL = {}
--[[
hg.VGUI.SecondaryColor = Color(155,0,0,240)
hg.VGUI.BackgroundColor = Color(25,25,35,220)]]
local color_blacky = Color(6, 14, 10, 220)
local color_reddy = Color(35, 225, 110, 240)

local spaceCloseFontHeight
local spaceCloseSerial = 0
local spaceClosePressConsumed = false
local spaceCloseFooters = setmetatable({}, {__mode = "k"})

local function rebuildSpaceCloseFont()
    local height = math.Clamp(math.floor(ScrH() / 72 + 0.5), 13, 18)
    if spaceCloseFontHeight == height then return end

    spaceCloseFontHeight = height
    surface.CreateFont("ZC_SpaceCloseHint", {
        font = "Roboto",
        size = height,
        weight = 700,
        antialias = true,
        extended = true
    })
end

local function isTextEntryFocused(panel)
    local focus = vgui.GetKeyboardFocus()
    if not IsValid(focus) then return false end

    local className = focus.GetClassName and string.lower(focus:GetClassName() or "") or ""
    if string.find(className, "textentry", 1, true) == nil and string.find(className, "numberwang", 1, true) == nil then
        return false
    end

    local current = focus
    while IsValid(current) do
        if current == panel then return true end
        current = current:GetParent()
    end

    return false
end

local function getTopmostSpaceCloseFooter()
    local topmost
    local topmostSerial = -1

    for footer, serial in pairs(spaceCloseFooters) do
        if IsValid(footer) and serial > topmostSerial then
            local target = footer.TargetPanel
            if IsValid(target) and target:IsVisible() and not target.Closing then
                topmost = footer
                topmostSerial = serial
            end
        end
    end

    return topmost
end

function hg.AddSpaceCloseFooter(panel, closeCallback, options)
    if not IsValid(panel) then return end
    if IsValid(panel.ZCSpaceCloseFooter) then return panel.ZCSpaceCloseFooter end

    options = options or {}
    rebuildSpaceCloseFont()

    local footer = vgui.Create("DPanel")
    spaceCloseSerial = spaceCloseSerial + 1
    spaceCloseFooters[footer] = spaceCloseSerial
    panel.ZCSpaceCloseFooter = footer
    footer.TargetPanel = panel
    footer.SpaceCloseSerial = spaceCloseSerial
    footer.SpaceWasDown = input.IsKeyDown(KEY_SPACE)
    footer:SetMouseInputEnabled(false)
    footer:SetKeyboardInputEnabled(true)
    footer:SetSize(0, 0)

    footer.CloseTarget = function(self)
        local target = self.TargetPanel
        if not IsValid(target) or target.Closing then return end

        self.SpaceWasDown = true
        spaceClosePressConsumed = true

        if closeCallback then
            closeCallback(target)
        elseif target.Close then
            target:Close()
        else
            target:Remove()
        end
    end

    footer.OnKeyCodePressed = function(self, keyCode)
        local target = self.TargetPanel
        if keyCode == KEY_SPACE and getTopmostSpaceCloseFooter() == self and IsValid(target) and not isTextEntryFocused(target) then
            self:CloseTarget()
            return true
        end
    end

    local oldOnKeyCodePressed = panel.OnKeyCodePressed
    panel.OnKeyCodePressed = function(self, keyCode)
        if keyCode == KEY_SPACE and getTopmostSpaceCloseFooter() == footer and not isTextEntryFocused(self) then
            footer:CloseTarget()
            return true
        end

        if oldOnKeyCodePressed then
            return oldOnKeyCodePressed(self, keyCode)
        end
    end

    footer.Paint = function(self, w, h)
        local target = self.TargetPanel
        if not IsValid(target) or target.Closing then return end

        local accent = options.accent or target.ColorBR or color_reddy
        local textColor = options.textColor or Color(225, 245, 232)
        local keySize = math.floor(h * 0.62)
        local keyY = math.floor((h - keySize) * 0.5)
        local label = options.label or "Press SPACEBAR to close"

        surface.SetFont("ZC_SpaceCloseHint")
        local textWidth = surface.GetTextSize(label)
        local gap = math.max(7, math.floor(h * 0.22))
        local totalWidth = keySize + gap + textWidth
        local keyX = math.floor((w - totalWidth) * 0.5)

        surface.SetDrawColor(2, 14, 8, options.backgroundAlpha or 225)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(accent.r, accent.g, accent.b, 185)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        surface.DrawOutlinedRect(keyX, keyY, keySize, keySize, 1)
        surface.DrawRect(keyX + math.floor(keySize * 0.25), keyY + math.floor(keySize * 0.67), math.ceil(keySize * 0.5), 1)

        draw.SimpleText(label, "ZC_SpaceCloseHint", keyX + keySize + gap, h * 0.5, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    footer.Think = function(self)
        local target = self.TargetPanel
        if not IsValid(target) then
            self:Remove()
            return
        end

        rebuildSpaceCloseFont()

        local footerHeight = options.height or math.Clamp(math.floor(ScrH() * 0.036), 30, 40)
        local footerWidth = math.min(target:GetWide(), options.width or math.max(280, math.floor(ScrW() * 0.22)))
        local targetX, targetY = target:LocalToScreen(0, 0)
        local x = targetX + (target:GetWide() - footerWidth) * 0.5
        local y = targetY + target:GetTall() + (options.gap or 6)

        if y + footerHeight > ScrH() - 6 then
            y = targetY + target:GetTall() - footerHeight - (options.inset or 8)
        end

        local isTopmost = getTopmostSpaceCloseFooter() == self

        self:SetPos(math.floor(x), math.floor(y))
        self:SetSize(footerWidth, footerHeight)
        self:SetVisible(target:IsVisible() and not target.Closing and isTopmost)
        if isTopmost and not self.WasTopmost then
            self:MoveToFront()
            if not isTextEntryFocused(target) then
                self:RequestFocus()
            end
        end
        self.WasTopmost = isTopmost

        local spaceDown = input.IsKeyDown(KEY_SPACE)
        if not spaceDown then
            spaceClosePressConsumed = false
        end

        if isTopmost and spaceDown and not self.SpaceWasDown and not spaceClosePressConsumed and not isTextEntryFocused(target) then
            self:CloseTarget()
            return
        end

        self.SpaceWasDown = spaceDown
    end

    return footer
end

hook.Add("PlayerBindPress", "ZC_SpaceCloseModal", function(_, bind, pressed)
    if not pressed or not input.IsKeyDown(KEY_SPACE) then return end
    if not string.find(string.lower(bind or ""), "+jump", 1, true) then return end

    local footer = getTopmostSpaceCloseFooter()
    if not IsValid(footer) then return end

    local target = footer.TargetPanel
    if not IsValid(target) or isTextEntryFocused(target) then return end

    footer:CloseTarget()
    return true
end)

hook.Add("CreateMove", "ZC_BlockModalSpaceJump", function(command)
    if not input.IsKeyDown(KEY_SPACE) then return end

    local footer = getTopmostSpaceCloseFooter()
    if not IsValid(footer) then return end

    local target = footer.TargetPanel
    if not IsValid(target) or isTextEntryFocused(target) then return end

    command:RemoveKey(IN_JUMP)
end)

function PANEL:Init()
    self.Itensens = {}
    self:SetAlpha( 0 )
    self:SetTitle( "" )

    self.DrawBorder = true

    self.ColorBG = Color(color_blacky:Unpack())
    self.ColorBR = Color(color_reddy:Unpack())
    self.BlurStrengh = 2

    timer.Simple(0,function()
        if not self.DisableSpaceCloseFooter and not IsValid(self.ZCSpaceCloseFooter) then
            hg.AddSpaceCloseFooter(self)
        end

        if self.First then
            self:First()
        end
    end)
end

function PANEL:Paint(w,h)
    draw.RoundedBox(0,0,0,w,h,self.ColorBG)
    hg.DrawBlur(self, self.BlurStrengh)

    if self.DrawBorder then
        surface.SetDrawColor(self.ColorBR)
        surface.DrawOutlinedRect(0,0,w,h,1.5)
    end
end

function PANEL:SetBorder( bDraw )
    self.DrawBorder = bDraw
end

function PANEL:SetColorBG( cColor )
    self.ColorBG = cColor
end

function PANEL:SetColorBR( cColor )
    self.ColorBR = cColor
end

function PANEL:SetBlurStrengh( floatVal )
    self.BlurStrengh = floatVal
end

function PANEL:First( ply )
    self:SetY(self:GetY() + self:GetTall())
    self:MoveTo(self:GetX(), self:GetY() - self:GetTall(), 0.4, 0, 0.2, function() end)
    self:AlphaTo( 255, 0.2, 0.1, nil )

    if self.PostInit then
        self:PostInit()
    end
end

function PANEL:Close()
    if self.Closing then return end
    self.Closing = true
    self:MoveTo(self:GetX(), ScrH() / 2 + self:GetTall(), 5, 0, 0.3, function()
    end)
    self:AlphaTo( 0, 0.2, 0, function() 
        if self.OnClose then self:OnClose() end 
        self:Remove() 
    end)
    self:SetKeyboardInputEnabled(false)
    self:SetMouseInputEnabled(false)
end

vgui.Register( "ZFrame", PANEL, "DFrame")
