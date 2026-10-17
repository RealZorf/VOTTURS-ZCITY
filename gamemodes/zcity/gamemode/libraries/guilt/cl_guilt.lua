ZCITY_GUILT = ZCITY_GUILT or {}
ZCITY_GUILT.Menu = ZCITY_GUILT.Menu or {}

hook.Add("OnNetVarSet", "Guilt",function(index, key, var)
    if key == "Karma" then
        Entity(index).Karma = var
    end
end)

concommand.Add("hg_getkarma",function(ply)
    if not ply:IsAdmin() then return end

    net.Start("get_karma")
    net.SendToServer()
end)

net.Receive("get_karma",function()
    local tbl = net.ReadTable()
    local printTbl = "\nPlayers karma: \n"

    for id,karma in pairs(tbl) do
        printTbl = printTbl.."\t"..(Player(id):Name().."'s karma is "..math.Round(karma,2)).."\n"
    end

    LocalPlayer():PrintMessage(HUD_PRINTCONSOLE,printTbl)
end)

concommand.Add("hg_guilt_menu",function()
    RunConsoleCommand("zcity_guilt_menu")
end)

local function CFG()
    return ZCITY_GUILT.Config or ZCITY_GUILT.DefaultConfig or {}
end

local function mergeConfig(defaults, incoming)
    local merged = table.Copy(defaults or {})

    if not istable(incoming) then
        return merged
    end

    for k, v in pairs(incoming) do
        if k == "Presets" then
            merged.Presets = istable(v) and table.Copy(v) or table.Copy((defaults or {}).Presets or {})
        elseif istable(v) and istable(merged[k]) then
            merged[k] = table.Copy(v)
        else
            merged[k] = v
        end
    end

    if not istable(merged.Presets) then
        merged.Presets = table.Copy((defaults or {}).Presets or {})
    end

    return merged
end

local GuiltFrame
local leftScroll
local rightScroll
local selectedData
local cachedRows = {}
local pressedOpen

local BASE_W, BASE_H = 1920, 1080
local _lastScrW, _lastScrH = 0, 0

local FONT_TITLE = "PATGUILT_Title"
local FONT_HEADER = "PATGUILT_Header"
local FONT_MED = "PATGUILT_Med"
local FONT_SMALL = "PATGUILT_Small"
local FONT_TINY = "PATGUILT_Tiny"

local COL_WHITE
local COL_TEXT
local COL_MUTED
local COL_RED
local COL_RED_SOFT
local COL_BG
local COL_BG2
local COL_BG3
local COL_GREEN
local COL_BLUE
local COL_DISABLED

local function asColor(entry, fallback)
    local base = fallback or Color(255, 255, 255, 255)
    local value = istable(entry) and entry or {}

    return Color(
        math.Clamp(tonumber(value.r) or base.r or 255, 0, 255),
        math.Clamp(tonumber(value.g) or base.g or 255, 0, 255),
        math.Clamp(tonumber(value.b) or base.b or 255, 0, 255),
        math.Clamp(tonumber(value.a) or base.a or 255, 0, 255)
    )
end

local function ensureThemeTable(theme)
    theme = istable(theme) and theme or {}
    local defaults = ZCITY_GUILT.ThemeDefaults or {}

    for key, base in pairs(defaults) do
        theme[key] = istable(theme[key]) and theme[key] or table.Copy(base)
    end

    return theme
end

local function applyThemeColors(config)
    local theme = ensureThemeTable((config and config.Theme) or (CFG() and CFG().Theme) or {})

    COL_BG = asColor(theme.panelBg, Color(8, 8, 8, 220))
    COL_BG2 = asColor(theme.panelInner, Color(18, 18, 18, 235))
    COL_BG3 = asColor(theme.panelAlt, Color(28, 28, 28, 220))
    COL_RED = asColor(theme.accent, Color(190, 20, 20, 220))
    COL_RED_SOFT = asColor(theme.accentSoft, Color(255, 45, 45, 120))
    COL_WHITE = asColor(theme.textMain, Color(245, 245, 245, 255))
    COL_TEXT = asColor(theme.textSub, Color(220, 220, 220, 255))
    COL_MUTED = asColor(theme.muted, Color(160, 160, 160, 255))
    COL_GREEN = asColor(theme.success, Color(70, 170, 95, 255))
    COL_BLUE = asColor(theme.info, Color(80, 140, 220, 255))
    COL_DISABLED = asColor(theme.disabled, Color(100, 100, 100, 120))
end

local function UIScale()
    return math.min(ScrW() / BASE_W, ScrH() / BASE_H)
end

local function ui(v)
    return math.max(1, math.floor(v * UIScale()))
end

local function rebuildFonts(force)
    if not force and _lastScrW == ScrW() and _lastScrH == ScrH() then return end
    _lastScrW, _lastScrH = ScrW(), ScrH()

    surface.CreateFont(FONT_TITLE, {
        font = "Tahoma",
        size = ui(28),
        weight = 900,
        extended = true
    })

    surface.CreateFont(FONT_HEADER, {
        font = "Tahoma",
        size = ui(20),
        weight = 800,
        extended = true
    })

    surface.CreateFont(FONT_MED, {
        font = "Tahoma",
        size = ui(18),
        weight = 700,
        extended = true
    })

    surface.CreateFont(FONT_SMALL, {
        font = "Tahoma",
        size = ui(14),
        weight = 600,
        extended = true
    })

    surface.CreateFont(FONT_TINY, {
        font = "Tahoma",
        size = ui(12),
        weight = 500,
        extended = true
    })
end

rebuildFonts(true)
applyThemeColors(CFG())

hook.Add("OnScreenSizeChanged", "ZCITY_GUILT_RebuildFonts", function()
    rebuildFonts(true)

    if IsValid(GuiltFrame) then
        local rows = table.Copy(cachedRows or {})
        GuiltFrame:Remove()
        GuiltFrame = nil
        timer.Simple(0, function()
            if #rows > 0 then
                local stillOpen = IsValid(LocalPlayer()) and LocalPlayer():GetNWInt("ZCITY_GUILT_PENDING_COUNT", 0) > 0
                if stillOpen then
                    openMenu(rows)
                end
            end
        end)
    end
end)

local function drawOutlinedRect(x, y, w, h, col, thick)
    surface.SetDrawColor(col)
    surface.DrawOutlinedRect(x, y, w, h, thick or 1)
end

local function blurPanel(panel, a)
    if hg and hg.DrawBlur then
        hg.DrawBlur(panel, 5, 1, a or 120)
    else
        surface.SetDrawColor(0, 0, 0, a or 120)
        surface.DrawRect(0, 0, panel:GetWide(), panel:GetTall())
    end
end

local function clearScrollChildren(scroll)
    if not IsValid(scroll) then return end

    local canvas = scroll.GetCanvas and scroll:GetCanvas() or nil
    if IsValid(canvas) then
        for _, child in ipairs(canvas:GetChildren()) do
            if IsValid(child) then
                child:Remove()
            end
        end
    else
        for _, child in ipairs(scroll:GetChildren()) do
            if IsValid(child) then
                child:Remove()
            end
        end
    end
end

local function makeScrollBarPretty(panel)
    if not IsValid(panel) or not panel.GetVBar then return end

    local bar = panel:GetVBar()

    function bar:Paint() end
    function bar.btnUp:Paint(w, h)
        surface.SetDrawColor(0, 0, 0, 150)
        surface.DrawRect(0, 0, w, h)
        drawOutlinedRect(0, 0, w, h, COL_RED_SOFT, 1)
    end
    function bar.btnDown:Paint(w, h)
        surface.SetDrawColor(0, 0, 0, 150)
        surface.DrawRect(0, 0, w, h)
        drawOutlinedRect(0, 0, w, h, COL_RED_SOFT, 1)
    end
    function bar.btnGrip:Paint(w, h)
        surface.SetDrawColor(COL_BG3)
        surface.DrawRect(0, 0, w, h)
        drawOutlinedRect(0, 0, w, h, COL_RED, 1)
    end

    bar:SetWide(ui(10))
end

local function getPresetColor(preset)
    if ZCITY_GUILT.GetPresetColor then
        return ZCITY_GUILT.GetPresetColor(preset)
    end

    local c = preset and preset.color or nil
    if istable(c) then
        return Color(tonumber(c.r) or 255, tonumber(c.g) or 255, tonumber(c.b) or 255)
    end

    return Color(255, 120, 120)
end

local function sendAction(row, action)
    if not row or tostring(row.steamid64 or "") == "" then return end

    net.Start("zcity_guilt_action")
    net.WriteUInt(math.Clamp(math.floor(tonumber(row.caseid) or 0), 0, 4294967295), 32)
    net.WriteString(tostring(row.steamid64 or ""))
    net.WriteEntity(IsValid(row.ent) and row.ent or NULL)
    net.WriteString(action)
    net.SendToServer()
end

local function getDisplayedCaseState(row)
    return row and row.decided and "Resolved" or "Pending"
end

local function getSourceLabel(source)
    source = tostring(source or "damage")

    if source == "fentanyl" then
        return "Fentanyl injection"
    elseif source == "jumpkick" then
        return "Jump kick"
    elseif source == "kick" then
        return "Kick"
    end

    return "Damage"
end

local function getCharacterName(ent)
    if not IsValid(ent) then return "Unknown" end

    if ent.GetNWString then
        local nwName = ent:GetNWString("PlayerName", "")
        if nwName ~= "" then
            return nwName
        end
    end

    if istable(ent.CurAppearance) and tostring(ent.CurAppearance.AName or "") ~= "" then
        return tostring(ent.CurAppearance.AName)
    end

    if ent.GetPlayerName then
        local playerName = ent:GetPlayerName()
        if tostring(playerName or "") ~= "" then
            return tostring(playerName)
        end
    end

    return ent:Nick() or "Unknown"
end

local function replacementSafe(text)
    return tostring(text or ""):gsub("%%", "%%%%")
end

local function getCaseName(row)
    if IsValid(row.ent) then return getCharacterName(row.ent) end
    return tostring(row.name or "Disconnected player") .. " (offline)"
end

local function formatCaseText(text, row)
    text = tostring(text or "")

    local victimName = getCharacterName(LocalPlayer())
    local attackerName = row and getCaseName(row) or "attacker"

    text = text:gsub("%f[%a]Victim%f[%A]", replacementSafe(victimName))
    text = text:gsub("%f[%a]victim%f[%A]", replacementSafe(victimName))
    text = text:gsub("%f[%a]Attacker%f[%A]", replacementSafe(attackerName))
    text = text:gsub("%f[%a]attacker%f[%A]", replacementSafe(attackerName))

    return text
end

local function getDefenseLabel(row)
    if not row then return "No review data" end

    if row.actionAllowed == false then
        local reason = tostring(row.actionLockReason or "")
        return formatCaseText(reason ~= "" and reason or "Native guilt locked punishment", row)
    end

    local mul = tonumber(row.selfDefenseMul) or 1
    local score = tonumber(row.threatScore) or 0
    local incoming = tonumber(row.incomingHarm) or 0
    local harm = tonumber(row.harm) or 0

    if mul <= 0.2 or (incoming >= harm * 0.75 and score >= 0.35) then
        return "Likely proportional self-defense"
    elseif score >= 0.55 then
        return formatCaseText("Victim showed strong threat signs", row)
    elseif score >= 0.25 then
        return formatCaseText("Victim showed some threat signs", row)
    end

    return "No strong self-defense signs"
end

local function compactText(text, maxChars)
    text = tostring(text or "")
    maxChars = maxChars or 72

    if #text <= maxChars then
        return text
    end

    return string.sub(text, 1, math.max(maxChars - 3, 1)) .. "..."
end

local function getPendingRowsCount()
    local total = 0
    for _, row in ipairs(cachedRows or {}) do
        if row.decided ~= true then
            total = total + 1
        end
    end
    return total
end

local function styleHeaderButton(button, label)
    button:SetText("")
    button.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 180)
        surface.DrawRect(0, 0, w, h)
        drawOutlinedRect(0, 0, w, h, self:IsHovered() and COL_RED or COL_RED_SOFT, ui(2))
        draw.SimpleText(label, FONT_SMALL, w * 0.5, h * 0.5, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

local function createActionButton(parent, text, colorBg, enabled, callback, subtitle)
    local btn = parent:Add("DButton")
    btn:Dock(TOP)
    btn:DockMargin(ui(12), 0, ui(12), ui(8))
    btn:SetTall(subtitle and ui(52) or ui(40))
    btn:SetText("")
    btn:SetEnabled(enabled ~= false)

    local hover = 0

    function btn:Paint(w, h)
        hover = Lerp(FrameTime() * 10, hover, self:IsHovered() and self:IsEnabled() and 1 or 0)

        surface.SetDrawColor(COL_BG2)
        surface.DrawRect(0, 0, w, h)

        local col = self:IsEnabled() and colorBg or COL_DISABLED
        local r = math.Clamp(col.r + hover * 20, 0, 255)
        local g = math.Clamp(col.g + hover * 20, 0, 255)
        local b = math.Clamp(col.b + hover * 20, 0, 255)
        local a = self:IsEnabled() and 220 or 120

        drawOutlinedRect(0, 0, w, h, Color(r, g, b, a), ui(2))

        if subtitle and subtitle ~= "" then
            draw.SimpleText(text, FONT_SMALL, ui(12), ui(7), self:IsEnabled() and COL_WHITE or Color(170, 170, 170), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(subtitle, FONT_TINY, ui(12), h - ui(10), self:IsEnabled() and COL_MUTED or Color(140, 140, 140), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
        else
            draw.SimpleText(text, FONT_SMALL, ui(12), h * 0.5, self:IsEnabled() and COL_WHITE or Color(170, 170, 170), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    function btn:DoClick()
        if not self:IsEnabled() then return end
        if callback then callback() end
    end

    return btn
end

local function rebuildRightPanel()
    if not IsValid(rightScroll) then return end
    clearScrollChildren(rightScroll)

    local header = rightScroll:Add("DPanel")
    header:Dock(TOP)
    header:DockMargin(ui(12), ui(12), ui(12), ui(10))
    header:SetTall(ui(124))

    local nativePenaltyHelp = header:Add("DLabel")
    nativePenaltyHelp:SetText("")
    nativePenaltyHelp:SetFont(FONT_TINY)
    nativePenaltyHelp:SetMouseInputEnabled(true)
    nativePenaltyHelp:SetCursor("hand")
    nativePenaltyHelp:SetTooltip("Calculated native guilt penalty from this amount of harm. This is the karma loss the player would have gotten from the native karma system. Punish accordingly.")
    nativePenaltyHelp:SetVisible(false)
    nativePenaltyHelp:SizeToContents()

    function nativePenaltyHelp:Paint(w, h)
        local hovered = self:IsHovered()
        local border = hovered and COL_RED or COL_RED_SOFT
        local fill = hovered and Color(COL_BG3.r, COL_BG3.g, COL_BG3.b, 245) or Color(COL_BG2.r, COL_BG2.g, COL_BG2.b, 235)

        draw.RoundedBox(ui(6), 0, 0, w, h, fill)
        drawOutlinedRect(0, 0, w, h, border, 1)

        draw.SimpleText("?", FONT_TINY, w * 0.5, h * 0.5 - ui(1), hovered and COL_WHITE or COL_MUTED, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    function header:PerformLayout(w, h)
        local penaltyText = selectedData and ("Calculated native guilt penalty: " .. math.Round(selectedData.karma or 0, 1)) or "Calculated native guilt penalty: 0"
        surface.SetFont(FONT_SMALL)
        local textW = surface.GetTextSize(penaltyText)
        nativePenaltyHelp:SetSize(ui(14), ui(14))
        nativePenaltyHelp:SetPos(ui(14) + textW + ui(4), ui(66))
    end

    function header:Paint(w, h)
        surface.SetDrawColor(COL_BG2)
        surface.DrawRect(0, 0, w, h)
        drawOutlinedRect(0, 0, w, h, COL_RED_SOFT, ui(2))

        if not selectedData then
            nativePenaltyHelp:SetVisible(false)
            draw.SimpleText("Select a player", FONT_HEADER, ui(14), ui(12), COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("Choose someone from the left panel to review their case.", FONT_SMALL, ui(14), ui(46), COL_MUTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("You can forgive, punish, or report from here.", FONT_TINY, ui(14), h - ui(14), COL_MUTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
            return
        end

        local name = getCaseName(selectedData)
        local state = getDisplayedCaseState(selectedData)
        local harm = math.Round(selectedData.harm or 0, 1)
        local karma = math.Round(selectedData.karma or 0, 1)
        nativePenaltyHelp:SetVisible(true)

        draw.SimpleText(name, FONT_HEADER, ui(14), ui(12), COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Recorded harm: " .. harm, FONT_SMALL, ui(14), ui(42), COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Calculated native guilt penalty: " .. karma, FONT_SMALL, ui(14), ui(64), COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Case state: " .. state, FONT_SMALL, ui(14), ui(88), selectedData.decided and COL_MUTED or COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    if not selectedData then
        return
    end

    if selectedData.decided then
        local resolved = rightScroll:Add("DPanel")
        resolved:Dock(TOP)
        resolved:DockMargin(ui(12), 0, ui(12), 0)
        resolved:SetTall(ui(44))

        function resolved:Paint(w, h)
            surface.SetDrawColor(COL_BG3)
            surface.DrawRect(0, 0, w, h)
            drawOutlinedRect(0, 0, w, h, COL_RED_SOFT, 1)
            draw.SimpleText("Decision already made for this player.", FONT_SMALL, ui(12), h * 0.5, Color(255, 180, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        return
    end

    local harm = tonumber(selectedData.harm) or 0

    local review = rightScroll:Add("DPanel")
    review:Dock(TOP)
    review:DockMargin(ui(12), 0, ui(12), ui(10))
    review:SetTall(ui(116))

    function review:Paint(w, h)
        surface.SetDrawColor(COL_BG2)
        surface.DrawRect(0, 0, w, h)
        drawOutlinedRect(0, 0, w, h, COL_RED_SOFT, 1)

        local threatPct = math.Round((tonumber(selectedData.threatScore) or 0) * 100)
        local mulPct = math.Round((tonumber(selectedData.selfDefenseMul) or 1) * 100)
        local incoming = math.Round(tonumber(selectedData.incomingHarm) or 0, 1)
        local source = getSourceLabel(selectedData.damageSource)

        draw.SimpleText("Threat Review", FONT_SMALL, ui(12), ui(8), COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(getDefenseLabel(selectedData), FONT_TINY, w - ui(12), ui(10), COL_MUTED, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        draw.SimpleText(compactText("Source: " .. source .. "   Incoming harm: " .. incoming .. "   Threat: " .. threatPct .. "%   Karma scale: " .. mulPct .. "%", 92), FONT_TINY, ui(12), ui(34), COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local reasons = istable(selectedData.threatReasons) and selectedData.threatReasons or {}
        for i = 1, math.min(#reasons, 3) do
            draw.SimpleText("- " .. compactText(formatCaseText(reasons[i], selectedData), 82), FONT_TINY, ui(12), ui(52 + (i - 1) * 18), COL_MUTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end

    if selectedData.respectEligible then
        createActionButton(
            rightScroll,
            "Give Respect (+3 Karma)",
            COL_GREEN,
            true,
            function()
                sendAction(selectedData, "respect")
            end,
            "Reward " .. getCaseName(selectedData) .. " for a successful traitor kill."
        )
    elseif CFG().AllowForgive then
        createActionButton(
            rightScroll,
            "Forgive",
            COL_GREEN,
            true,
            function()
                sendAction(selectedData, "forgive")
            end,
            "Resolve the case without removing karma."
        )
    end

    if CFG().AllowPunish and not selectedData.respectEligible then
        for _, preset in ipairs(CFG().Presets or {}) do
            local minharm = tonumber(preset.minharm) or 0
            local punishAmount = ZCITY_GUILT.GetPunishAmount(preset, selectedData)
            local incoming = tonumber(selectedData.incomingHarm) or 0
            local threatScore = tonumber(selectedData.threatScore) or 0
            local defenseMul = tonumber(selectedData.selfDefenseMul) or 1
            local actionLocked = selectedData.actionAllowed == false
            local defenseLocked = actionLocked or defenseMul <= 0.2 or (incoming >= harm * 0.75 and threatScore >= 0.35)
            local unlocked = harm >= minharm and punishAmount > 0 and not defenseLocked
            local subtitle

            if actionLocked then
                local reason = tostring(selectedData.actionLockReason or "")
                subtitle = compactText(formatCaseText(reason ~= "" and reason or "Locked by native guilt rules.", selectedData), 72)
            elseif defenseLocked then
                subtitle = "Locked: likely proportional self-defense."
            elseif unlocked then
                subtitle = "Up to " .. math.Round(punishAmount, 1) .. " karma; limited by the calculated penalty and round cap."
            else
                subtitle = "Requires " .. minharm .. " harm."
            end

            createActionButton(
                rightScroll,
                tostring(preset.name or "Punish"):gsub("%s*%(%-%d+%.?%d*%s+[Kk]arma%)%s*$", "")
                    .. " (-" .. math.Round(punishAmount, 1) .. " Karma)",
                getPresetColor(preset),
                unlocked,
                function()
                    sendAction(selectedData, preset.id)
                end,
                subtitle
            )
        end
    end

    if CFG().AllowReport and not selectedData.respectEligible then
        createActionButton(
            rightScroll,
            "Report to Staff",
            COL_BLUE,
            true,
            function()
                sendAction(selectedData, "report")
            end,
            "Send " .. getCaseName(selectedData) .. "'s case to admins."
        )
    end

    local spacer = rightScroll:Add("DPanel")
    spacer:Dock(TOP)
    spacer:SetTall(ui(18))
    spacer.Paint = function() end
end

local function createEligibleRow(parent, row)
    local card = parent:Add("DButton")
    card:SetTall(ui(76))
    card:Dock(TOP)
    card:DockMargin(ui(12), 0, ui(12), ui(8))
    card:SetText("")

    local avatar = vgui.Create("AvatarImage", card)
    avatar:SetSize(ui(54), ui(54))
    avatar:SetPos(ui(12), ui(11))
    if IsValid(row.ent) and not row.ent:IsBot() then
        avatar:SetPlayer(row.ent, 64)
    end

    function card:Paint(w, h)
        surface.SetDrawColor(COL_BG2)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(COL_BG3)
        surface.DrawRect(0, h * 0.56, w, h * 0.44)

        local accent = selectedData == row and COL_RED or COL_RED_SOFT
        surface.SetDrawColor(accent)
        surface.DrawRect(0, 0, ui(6), h)
        drawOutlinedRect(0, 0, w, h, accent, ui(2))

        local nameClr = row.decided and Color(180, 180, 180) or COL_WHITE
        local subClr = row.decided and Color(140, 140, 140) or COL_TEXT
        local harm = math.Round(row.harm or 0, 1)

        draw.SimpleText(getCaseName(row), FONT_MED, ui(78), ui(12), nameClr, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Harm: " .. harm, FONT_SMALL, ui(78), ui(38), subClr, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(getDisplayedCaseState(row), FONT_TINY, w - ui(12), ui(14), row.decided and COL_MUTED or COL_WHITE, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end

    function card:DoClick()
        selectedData = row
        rebuildRightPanel()
    end

    return card
end

local function rebuildLeftPanel()
    if not IsValid(leftScroll) then return end
    clearScrollChildren(leftScroll)

    table.sort(cachedRows, function(a, b)
        local ah, bh = tonumber(a and a.harm) or 0, tonumber(b and b.harm) or 0
        if ah == bh then
            local ak, bk = tonumber(a and a.karma) or 0, tonumber(b and b.karma) or 0
            if ak == bk then
                local an = getCaseName(a)
                local bn = getCaseName(b)
                return string.lower(an) < string.lower(bn)
            end
            return ak > bk
        end
        return ah > bh
    end)

    for _, row in ipairs(cachedRows or {}) do
        if tostring(row.steamid64 or "") ~= "" then
            createEligibleRow(leftScroll, row)
        end
    end
end

function openMenu(rows)
    rebuildFonts()

    cachedRows = {}
    for _, row in ipairs(rows or {}) do
        if tostring(row.steamid64 or "") ~= "" then
            cachedRows[#cachedRows + 1] = row
        end
    end

    selectedData = cachedRows[1]

    if IsValid(GuiltFrame) then
        GuiltFrame:Remove()
        GuiltFrame = nil
    end

    if #cachedRows <= 0 then
        return
    end

    local frameClass = vgui.GetControlTable("ZFrame") and "ZFrame" or "DFrame"
    GuiltFrame = vgui.Create(frameClass)

    local sizeX = math.min(ui(1180), ScrW() * 0.84)
    local sizeY = math.min(ui(760), ScrH() * 0.84)

    GuiltFrame:SetSize(sizeX, sizeY)
    GuiltFrame:Center()
    GuiltFrame:MakePopup()
    GuiltFrame:SetKeyboardInputEnabled(false)

    if GuiltFrame.ShowCloseButton then
        GuiltFrame:ShowCloseButton(false)
    end
    if GuiltFrame.SetTitle then
        GuiltFrame:SetTitle("")
    end

    GuiltFrame.Paint = function(self, w, h)
        blurPanel(self, 100)
        surface.SetDrawColor(COL_BG)
        surface.DrawRect(0, 0, w, h)
        drawOutlinedRect(0, 0, w, h, COL_RED, ui(2))
    end

    local titleBar = GuiltFrame:Add("DPanel")
    titleBar:Dock(TOP)
    titleBar:SetTall(ui(82))
    titleBar.Paint = function(self, w, h)
        surface.SetDrawColor(COL_BG2)
        surface.DrawRect(0, 0, w, h)
        drawOutlinedRect(0, 0, w, h, COL_RED_SOFT, 1)

        draw.SimpleText("Forgiveness / Punishment", FONT_TITLE, ui(14), ui(10), COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(
            tostring(getPendingRowsCount()) .. " pending case" .. (getPendingRowsCount() == 1 and "" or "s"),
            FONT_SMALL,
            ui(16),
            ui(42),
            COL_MUTED,
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_TOP
        )
    end

    local closeButton = titleBar:Add("DButton")
    closeButton:Dock(RIGHT)
    closeButton:DockMargin(0, ui(12), ui(12), ui(12))
    closeButton:SetWide(ui(40))
    styleHeaderButton(closeButton, "X")
    closeButton.DoClick = function()
        if IsValid(GuiltFrame) then
            GuiltFrame:Remove()
            GuiltFrame = nil
        end
    end

    local body = GuiltFrame:Add("DPanel")
    body:Dock(FILL)
    body:DockMargin(ui(12), ui(12), ui(12), ui(12))
    body.Paint = nil

    local sidebarGap = ui(10)
    local leftW = math.floor(sizeX * 0.46)

    local leftPanel = body:Add("DPanel")
    leftPanel:Dock(LEFT)
    leftPanel:SetWide(leftW)
    leftPanel.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 155)
        surface.DrawRect(0, 0, w, h)
        drawOutlinedRect(0, 0, w, h, COL_RED_SOFT, ui(2))
        draw.SimpleText("ELIGIBLE PLAYERS", FONT_HEADER, ui(16), ui(10), COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Pick a row to review the case.", FONT_TINY, ui(16), ui(36), COL_MUTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    leftScroll = leftPanel:Add("DScrollPanel")
    leftScroll:SetPos(0, ui(58))
    leftScroll:SetSize(leftW, body:GetTall() - ui(58))
    leftScroll.Paint = function() end
    makeScrollBarPretty(leftScroll)

    leftPanel.PerformLayout = function(self, w, h)
        if IsValid(leftScroll) then
            leftScroll:SetPos(0, ui(58))
            leftScroll:SetSize(w, h - ui(58))
        end
    end

    local rightPanel = body:Add("DPanel")
    rightPanel:Dock(FILL)
    rightPanel:DockMargin(sidebarGap, 0, 0, 0)
    rightPanel.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 155)
        surface.DrawRect(0, 0, w, h)
        drawOutlinedRect(0, 0, w, h, COL_RED_SOFT, ui(2))
        draw.SimpleText("ACTIONS", FONT_HEADER, ui(16), ui(10), COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Server rules still validate every action.", FONT_TINY, ui(16), ui(36), COL_MUTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    rightScroll = rightPanel:Add("DScrollPanel")
    rightScroll:SetPos(0, ui(58))
    rightScroll:SetSize(rightPanel:GetWide(), body:GetTall() - ui(58))
    rightScroll.Paint = function() end
    makeScrollBarPretty(rightScroll)

    rightPanel.PerformLayout = function(self, w, h)
        if IsValid(rightScroll) then
            rightScroll:SetPos(0, ui(58))
            rightScroll:SetSize(w, h - ui(58))
        end
    end

    rebuildLeftPanel()
    rebuildRightPanel()
end

hook.Add("HUDPaint", "ZCITY_GUILT_Prompt", function()
    rebuildFonts()

    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    if lp:GetNWInt("ZCITY_GUILT_PENDING_COUNT", 0) <= 0 then return end
    if IsValid(GuiltFrame) then return end
    if gui.IsGameUIVisible() then return end
    if IsValid(vgui.GetKeyboardFocus()) then return end

    local text = CFG().PromptText or "Press F to open the guilt menu."
    surface.SetFont(FONT_MED)
    local tw, th = surface.GetTextSize(text)

    local padX = ui(14)
    local padY = ui(8)
    local boxW = tw + padX * 2
    local boxH = th + padY * 2
    local x = ScrW() * 0.5 - boxW * 0.5
    local y = ScrH() - boxH - ui(18)

    surface.SetDrawColor(0, 0, 0, 175)
    surface.DrawRect(x, y, boxW, boxH)
    drawOutlinedRect(x, y, boxW, boxH, COL_RED_SOFT, ui(2))
    draw.SimpleText(text, FONT_MED, x + boxW * 0.5, y + boxH * 0.5, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if input.IsKeyDown(CFG().PromptKey) then
        if not pressedOpen then
            RunConsoleCommand("zcity_guilt_menu")
            pressedOpen = true
        end
    else
        pressedOpen = nil
    end
end)

hook.Add("Think", "ZCITY_GUILT_CloseResolvedMenu", function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end

    if lp:GetNWInt("ZCITY_GUILT_PENDING_COUNT", 0) > 0 then
        return
    end

    if IsValid(GuiltFrame) then
        GuiltFrame:Remove()
        GuiltFrame = nil
    end
end)

net.Receive("zcity_guilt_open", function()
    local count = net.ReadUInt(8)
    local rows = {}
    local wireRows = {}

    for index = 1, count do
        local caseid = net.ReadUInt(32)
        local steamid64 = net.ReadString()
        local ent = net.ReadEntity()
        local harm = net.ReadFloat()
        local karma = net.ReadFloat()
        local decided = net.ReadBool()
        local threatScore = net.ReadFloat()
        local selfDefenseMul = net.ReadFloat()
        local incomingHarm = net.ReadFloat()
        local responseRatio = net.ReadFloat()
        local damageSource = net.ReadString()
        local actionAllowed = net.ReadBool()
        local actionLockReason = net.ReadString()
        local respectEligible = net.ReadBool()
        local reasonCount = net.ReadUInt(4)
        local threatReasons = {}

        for _ = 1, reasonCount do
            threatReasons[#threatReasons + 1] = net.ReadString()
        end

        if steamid64 ~= "" and steamid64 ~= "0" then
            rows[#rows + 1] = {
                ent = ent,
                caseid = caseid,
                steamid64 = steamid64,
                harm = harm,
                karma = karma,
                decided = decided,
                threatScore = threatScore,
                selfDefenseMul = selfDefenseMul,
                incomingHarm = incomingHarm,
                responseRatio = responseRatio,
                damageSource = damageSource,
                actionAllowed = actionAllowed,
                actionLockReason = actionLockReason,
                respectEligible = respectEligible,
                threatReasons = threatReasons
            }
            wireRows[index] = rows[#rows]
        end
    end

    -- Names are an optional extension; older server messages still work.
    local _, bitsLeft = net.BytesLeft()
    if (bitsLeft or 0) >= 40 and net.ReadUInt(32) == 0x5A43474E then
        local nameCount = net.ReadUInt(8)
        for i = 1, nameCount do
            local name = net.ReadString()
            if wireRows[i] then wireRows[i].name = name end
        end
    end

    openMenu(rows)
end)

net.Receive("zcity_guilt_feedback", function()
    local msg = net.ReadString()
    if msg ~= "" then
        chat.AddText(Color(255, 80, 80), "[Guilt] ", color_white, msg)
    end
end)

net.Receive("zcity_guilt_config", function()
    local incoming = net.ReadTable()
    ZCITY_GUILT.Config = mergeConfig(ZCITY_GUILT.DefaultConfig or {}, incoming)

    applyThemeColors(ZCITY_GUILT.Config)

    if IsValid(GuiltFrame) then
        rebuildLeftPanel()
        rebuildRightPanel()
    end
end)

local function styleAdminEntry(entry)
    entry:SetFont(FONT_SMALL)
    entry:SetTextColor(COL_WHITE)
    entry:SetHighlightColor(COL_RED)
    entry.Paint = function(self, w, h)
        surface.SetDrawColor(COL_BG3)
        surface.DrawRect(0, 0, w, h)
        drawOutlinedRect(0, 0, w, h, self:HasFocus() and COL_RED or COL_RED_SOFT, 1)
        self:DrawTextEntryText(COL_WHITE, COL_RED, COL_WHITE)
    end
end

local function styleAdminButton(button, label)
    button:SetText("")
    button.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 180)
        surface.DrawRect(0, 0, w, h)
        drawOutlinedRect(0, 0, w, h, self:IsHovered() and COL_RED or COL_RED_SOFT, ui(2))
        draw.SimpleText(label, FONT_SMALL, w * 0.5, h * 0.5, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

local function openGuiltAdminMenu(cfg)
    if not IsValid(LocalPlayer()) or not LocalPlayer():IsAdmin() then return end

    rebuildFonts()

    local work = table.Copy(cfg or {})
    work.Presets = istable(work.Presets) and work.Presets or {}
    work.Theme = ensureThemeTable(work.Theme)

    local function themeColor(key, fallback)
        return asColor(work.Theme[key], fallback)
    end

    local function applyWorkingTheme()
        applyThemeColors({
            Theme = work.Theme
        })

        if IsValid(GuiltFrame) then
            GuiltFrame:InvalidateLayout(true)
        end
    end

    local function restoreLiveTheme()
        applyThemeColors(CFG())
        if IsValid(GuiltFrame) then
            GuiltFrame:InvalidateLayout(true)
        end
    end

    applyWorkingTheme()

    local frameClass = vgui.GetControlTable("ZFrame") and "ZFrame" or "DFrame"
    local frame = vgui.Create(frameClass)

    frame:SetSize(math.min(ui(1080), ScrW() * 0.86), math.min(ui(920), ScrH() * 0.9))
    frame:Center()
    frame:MakePopup()

    if frame.SetTitle then frame:SetTitle("") end
    if frame.ShowCloseButton then frame:ShowCloseButton(false) end

    frame.Paint = function(self, w, h)
        blurPanel(self, 100)
        surface.SetDrawColor(themeColor("panelBg", Color(8, 8, 8, 220)))
        surface.DrawRect(0, 0, w, h)
        drawOutlinedRect(0, 0, w, h, themeColor("accent", Color(190, 20, 20, 220)), ui(2))
    end

    local titleBar = frame:Add("DPanel")
    titleBar:Dock(TOP)
    titleBar:SetTall(ui(58))
    titleBar.Paint = function(self, w, h)
        surface.SetDrawColor(themeColor("panelInner", Color(18, 18, 18, 235)))
        surface.DrawRect(0, 0, w, h)
        drawOutlinedRect(0, 0, w, h, themeColor("accentSoft", Color(255, 45, 45, 120)), 1)
        draw.SimpleText("Guilt Overhaul Admin", FONT_TITLE, ui(14), ui(6), themeColor("textMain", Color(245, 245, 245, 255)), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local closeButton = titleBar:Add("DButton")
    closeButton:Dock(RIGHT)
    closeButton:DockMargin(0, ui(10), ui(10), ui(10))
    closeButton:SetWide(ui(40))
    closeButton:SetText("")
    closeButton.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 180)
        surface.DrawRect(0, 0, w, h)
        drawOutlinedRect(0, 0, w, h, self:IsHovered() and themeColor("accent", Color(190, 20, 20, 220)) or themeColor("accentSoft", Color(255, 45, 45, 120)), ui(2))
        draw.SimpleText("X", FONT_SMALL, w * 0.5, h * 0.5, themeColor("textMain", Color(245, 245, 245, 255)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeButton.DoClick = function()
        restoreLiveTheme()
        frame:Remove()
    end

    local saveButton = titleBar:Add("DButton")
    saveButton:Dock(RIGHT)
    saveButton:DockMargin(0, ui(10), ui(10), ui(10))
    saveButton:SetWide(ui(130))
    saveButton:SetText("")
    saveButton.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 180)
        surface.DrawRect(0, 0, w, h)
        drawOutlinedRect(0, 0, w, h, self:IsHovered() and themeColor("accent", Color(190, 20, 20, 220)) or themeColor("accentSoft", Color(255, 45, 45, 120)), ui(2))
        draw.SimpleText("Save", FONT_SMALL, w * 0.5, h * 0.5, themeColor("textMain", Color(245, 245, 245, 255)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    saveButton.DoClick = function()
        net.Start("zcity_guilt_admin_save")
        net.WriteTable(work)
        net.SendToServer()
        frame:Remove()
    end

    local sheet = frame:Add("DPropertySheet")
    sheet:Dock(FILL)
    sheet:DockMargin(ui(12), ui(12), ui(12), ui(12))

    local generalScroll = vgui.Create("DScrollPanel", sheet)
    generalScroll:Dock(FILL)
    makeScrollBarPretty(generalScroll)
    sheet:AddSheet("General", generalScroll, "icon16/cog.png")

    local themePanel = vgui.Create("DPanel", sheet)
    themePanel:Dock(FILL)
    themePanel.Paint = nil
    sheet:AddSheet("Theme", themePanel, "icon16/color_wheel.png")

    local function addBlock(parent, h)
        local pnl = parent:Add("DPanel")
        pnl:Dock(TOP)
        pnl:DockMargin(0, 0, 0, ui(8))
        pnl:SetTall(h)
        pnl.Paint = function(self, w, hh)
            surface.SetDrawColor(themeColor("panelInner", Color(18, 18, 18, 235)))
            surface.DrawRect(0, 0, w, hh)
            drawOutlinedRect(0, 0, w, hh, themeColor("accentSoft", Color(255, 45, 45, 120)), 1)
        end
        return pnl
    end

    local function styleEntry(entry)
        entry:SetFont(FONT_SMALL)
        entry:SetTextColor(themeColor("textMain", Color(245, 245, 245, 255)))
        entry:SetHighlightColor(themeColor("accent", Color(190, 20, 20, 220)))
        entry.Paint = function(self, w, h)
            surface.SetDrawColor(themeColor("panelAlt", Color(28, 28, 28, 220)))
            surface.DrawRect(0, 0, w, h)
            drawOutlinedRect(0, 0, w, h, self:HasFocus() and themeColor("accent", Color(190, 20, 20, 220)) or themeColor("accentSoft", Color(255, 45, 45, 120)), 1)
            self:DrawTextEntryText(
                themeColor("textMain", Color(245, 245, 245, 255)),
                themeColor("accent", Color(190, 20, 20, 220)),
                themeColor("textMain", Color(245, 245, 245, 255))
            )
        end
    end

    local function addCheck(parent, labelText, key)
        local pnl = addBlock(parent, ui(38))

        local lbl = pnl:Add("DLabel")
        lbl:Dock(FILL)
        lbl:DockMargin(ui(10), 0, ui(10), 0)
        lbl:SetFont(FONT_SMALL)
        lbl:SetText(labelText)
        lbl:SetTextColor(themeColor("textMain", Color(245, 245, 245, 255)))
        lbl:SetContentAlignment(4)

        local checkbox = pnl:Add("DCheckBox")
        checkbox:Dock(RIGHT)
        checkbox:DockMargin(0, ui(8), ui(10), ui(8))
        checkbox:SetWide(ui(22))
        checkbox:SetChecked(work[key] and true or false)
        checkbox.Paint = function(self, w, h)
            surface.SetDrawColor(themeColor("panelAlt", Color(28, 28, 28, 220)))
            surface.DrawRect(0, 0, w, h)
            drawOutlinedRect(0, 0, w, h, self:GetChecked() and themeColor("accent", Color(190, 20, 20, 220)) or themeColor("accentSoft", Color(255, 45, 45, 120)), 1)
            if self:GetChecked() then
                surface.SetDrawColor(themeColor("accent", Color(190, 20, 20, 220)))
                surface.DrawRect(ui(4), ui(4), w - ui(8), h - ui(8))
            end
        end
        checkbox.OnChange = function(_, val)
            work[key] = val and true or false
        end
    end

    local function addEntry(parent, labelText, key)
        local pnl = addBlock(parent, ui(60))

        local lbl = pnl:Add("DLabel")
        lbl:Dock(TOP)
        lbl:DockMargin(ui(10), ui(6), ui(10), ui(4))
        lbl:SetTall(ui(14))
        lbl:SetFont(FONT_TINY)
        lbl:SetText(labelText)
        lbl:SetTextColor(themeColor("textMain", Color(245, 245, 245, 255)))
        lbl:SetContentAlignment(4)

        local entry = pnl:Add("DTextEntry")
        entry:Dock(FILL)
        entry:DockMargin(ui(10), 0, ui(10), ui(8))
        entry:SetText(tostring(work[key] or ""))
        entry:SetUpdateOnType(true)
        styleEntry(entry)
        entry.OnValueChange = function(self, val)
            work[key] = val
        end
    end

    local generalHeader = addBlock(generalScroll, ui(34))
    generalHeader.Paint = nil
    local generalLabel = generalHeader:Add("DLabel")
    generalLabel:Dock(FILL)
    generalLabel:SetFont(FONT_HEADER)
    generalLabel:SetText("General")
    generalLabel:SetTextColor(themeColor("textMain", Color(245, 245, 245, 255)))
    generalLabel:SetContentAlignment(4)

    addCheck(generalScroll, "Allow forgive", "AllowForgive")
    addCheck(generalScroll, "Allow punish", "AllowPunish")
    addCheck(generalScroll, "Allow report", "AllowReport")
    addCheck(generalScroll, "Log admin actions", "LogAdminActions")

    addEntry(generalScroll, "Prompt text", "PromptText")
    addEntry(generalScroll, "Min harm", "MinHarm")
    addEntry(generalScroll, "Harm expiry", "HarmExpiry")
    addEntry(generalScroll, "Case expiry", "CaseExpiry")
    addEntry(generalScroll, "Auto-expire min harm", "AutoExpireMinHarm")
    addEntry(generalScroll, "Auto-expire amount", "AutoExpireAmount")
    addEntry(generalScroll, "Auto-expire round cap", "AutoExpireRoundCap")
    addEntry(generalScroll, "Self-defense window", "SelfDefenseWindow")
    addEntry(generalScroll, "Self-defense min incoming harm", "SelfDefenseMinIncomingHarm")
    addEntry(generalScroll, "Self-defense attacker count", "SelfDefenseAttackerCount")
    addEntry(generalScroll, "Manual punish round cap", "ManualPunishRoundCap")
    addEntry(generalScroll, "Staff report prefix", "StaffReportPrefix")

    local presetsHeader = addBlock(generalScroll, ui(34))
    presetsHeader.Paint = nil
    local presetsLabel = presetsHeader:Add("DLabel")
    presetsLabel:Dock(FILL)
    presetsLabel:SetFont(FONT_HEADER)
    presetsLabel:SetText("Punish Presets")
    presetsLabel:SetTextColor(themeColor("textMain", Color(245, 245, 245, 255)))
    presetsLabel:SetContentAlignment(4)

    local function rebuildPresetEditors()
        for _, child in ipairs(generalScroll:GetCanvas():GetChildren()) do
            if child.ZPresetEditor then
                child:Remove()
            end
        end

        for i, preset in ipairs(work.Presets) do
            local pnl = addBlock(generalScroll, ui(138))
            pnl.ZPresetEditor = true

            local title = pnl:Add("DLabel")
            title:SetPos(ui(10), ui(8))
            title:SetSize(ui(200), ui(20))
            title:SetFont(FONT_SMALL)
            title:SetText("Preset #" .. i)
            title:SetTextColor(themeColor("textMain", Color(245, 245, 245, 255)))

            local function makeField(x, y, w, labelText, value, onChange)
                local lbl = pnl:Add("DLabel")
                lbl:SetPos(x, y)
                lbl:SetSize(w, ui(14))
                lbl:SetFont(FONT_TINY)
                lbl:SetText(labelText)
                lbl:SetTextColor(themeColor("muted", Color(160, 160, 160, 255)))

                local entry = pnl:Add("DTextEntry")
                entry:SetPos(x, y + ui(16))
                entry:SetSize(w, ui(24))
                entry:SetText(tostring(value or ""))
                entry:SetUpdateOnType(true)
                styleEntry(entry)
                entry.OnValueChange = function(self, val)
                    onChange(val)
                end
            end

            makeField(ui(10), ui(34), ui(150), "ID", preset.id, function(v) preset.id = v end)
            makeField(ui(170), ui(34), ui(260), "Name", preset.name, function(v) preset.name = v end)
            makeField(ui(440), ui(34), ui(90), "Amount", preset.amount, function(v) preset.amount = tonumber(v) or 0 end)
            makeField(ui(540), ui(34), ui(90), "Min Harm", preset.minharm, function(v) preset.minharm = tonumber(v) or 0 end)

            preset.color = preset.color or { r = 255, g = 255, b = 255 }
            makeField(ui(10), ui(80), ui(70), "R", preset.color.r, function(v) preset.color.r = tonumber(v) or 255 end)
            makeField(ui(90), ui(80), ui(70), "G", preset.color.g, function(v) preset.color.g = tonumber(v) or 255 end)
            makeField(ui(170), ui(80), ui(70), "B", preset.color.b, function(v) preset.color.b = tonumber(v) or 255 end)

            local remove = pnl:Add("DButton")
            remove:SetText("")
            remove.Paint = function(self, w, h)
                surface.SetDrawColor(0, 0, 0, 180)
                surface.DrawRect(0, 0, w, h)
                drawOutlinedRect(0, 0, w, h, themeColor("accent", Color(190, 20, 20, 220)), ui(2))
                draw.SimpleText("Remove", FONT_TINY, w * 0.5, h * 0.5, themeColor("textMain", Color(245, 245, 245, 255)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            remove.DoClick = function()
                table.remove(work.Presets, i)
                rebuildPresetEditors()
            end

            pnl.PerformLayout = function(self, w, h)
                remove:SetPos(w - ui(110), ui(48))
                remove:SetSize(ui(96), ui(30))
            end
        end

        local addPreset = addBlock(generalScroll, ui(42))
        addPreset.ZPresetEditor = true

        local addBtn = addPreset:Add("DButton")
        addBtn:Dock(FILL)
        addBtn:DockMargin(ui(10), ui(6), ui(10), ui(6))
        addBtn:SetText("")
        addBtn.Paint = function(self, w, h)
            surface.SetDrawColor(0, 0, 0, 180)
            surface.DrawRect(0, 0, w, h)
            drawOutlinedRect(0, 0, w, h, self:IsHovered() and themeColor("accent", Color(190, 20, 20, 220)) or themeColor("accentSoft", Color(255, 45, 45, 120)), ui(2))
            draw.SimpleText("Add Preset", FONT_SMALL, w * 0.5, h * 0.5, themeColor("textMain", Color(245, 245, 245, 255)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        addBtn.DoClick = function()
            work.Presets[#work.Presets + 1] = {
                id = "preset_" .. (#work.Presets + 1),
                name = "New Preset",
                amount = 5,
                minharm = 5,
                color = { r = 255, g = 255, b = 255 }
            }
            rebuildPresetEditors()
        end
    end

    rebuildPresetEditors()

local themeList = themePanel:Add("DScrollPanel")
themeList:Dock(LEFT)
themeList:SetWide(ui(260))
themeList:DockMargin(0, 0, ui(12), 0)
makeScrollBarPretty(themeList)

local themeRight = themePanel:Add("DPanel")
themeRight:Dock(FILL)
themeRight.Paint = nil

local previewWrap = themeRight:Add("DPanel")
previewWrap:Dock(TOP)
previewWrap:SetTall(ui(210))
previewWrap:DockMargin(0, 0, 0, ui(10))
previewWrap.Paint = nil

local menuPreview = previewWrap:Add("DPanel")
menuPreview:Dock(TOP)
menuPreview:SetTall(ui(210))
menuPreview.Paint = function(_, w, h)
    surface.SetDrawColor(themeColor("panelBg", Color(8, 8, 8, 220)))
    surface.DrawRect(0, 0, w, h)
    drawOutlinedRect(0, 0, w, h, themeColor("accent", Color(190, 20, 20, 220)), 2)

    surface.SetDrawColor(themeColor("panelInner", Color(18, 18, 18, 235)))
    surface.DrawRect(ui(10), ui(10), w - ui(20), ui(42))
    drawOutlinedRect(ui(10), ui(10), w - ui(20), ui(42), themeColor("accentSoft", Color(255, 45, 45, 120)), 1)
    draw.SimpleText("Forgiveness / Punishment", FONT_SMALL, ui(20), ui(20), themeColor("textMain", Color(245, 245, 245, 255)), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local leftX, leftY = ui(10), ui(62)
    local leftW, leftH = math.floor((w - ui(30)) * 0.46), h - ui(72)
    surface.SetDrawColor(themeColor("panelInner", Color(18, 18, 18, 235)))
    surface.DrawRect(leftX, leftY, leftW, leftH)
    drawOutlinedRect(leftX, leftY, leftW, leftH, themeColor("accentSoft", Color(255, 45, 45, 120)), 1)
    draw.SimpleText("ELIGIBLE PLAYERS", FONT_TINY, leftX + ui(10), leftY + ui(10), themeColor("textMain", Color(245, 245, 245, 255)), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    surface.SetDrawColor(themeColor("panelAlt", Color(28, 28, 28, 220)))
    surface.DrawRect(leftX + ui(10), leftY + ui(34), leftW - ui(20), ui(52))
    drawOutlinedRect(leftX + ui(10), leftY + ui(34), leftW - ui(20), ui(52), themeColor("accent", Color(190, 20, 20, 220)), 1)
    draw.SimpleText("Example Player", FONT_TINY, leftX + ui(20), leftY + ui(42), themeColor("textMain", Color(245, 245, 245, 255)), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("Harm: 18.5", FONT_TINY, leftX + ui(20), leftY + ui(58), themeColor("textSub", Color(220, 220, 220, 255)), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local rightX = leftX + leftW + ui(10)
    local rightW = w - rightX - ui(10)
    surface.SetDrawColor(themeColor("panelInner", Color(18, 18, 18, 235)))
    surface.DrawRect(rightX, leftY, rightW, leftH)
    drawOutlinedRect(rightX, leftY, rightW, leftH, themeColor("accentSoft", Color(255, 45, 45, 120)), 1)
    draw.SimpleText("ACTIONS", FONT_TINY, rightX + ui(10), leftY + ui(10), themeColor("textMain", Color(245, 245, 245, 255)), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local btnY = leftY + ui(34)
    local btnW = rightW - ui(20)
    local btnH = ui(28)

    surface.SetDrawColor(themeColor("success", Color(70, 170, 95, 255)))
    surface.DrawRect(rightX + ui(10), btnY, btnW, btnH)
    draw.SimpleText("Forgive", FONT_TINY, rightX + ui(18), btnY + btnH * 0.5, themeColor("textMain", Color(245, 245, 245, 255)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    surface.SetDrawColor(themeColor("accent", Color(190, 20, 20, 220)))
    surface.DrawRect(rightX + ui(10), btnY + ui(36), btnW, btnH)
    draw.SimpleText("Minor Punish", FONT_TINY, rightX + ui(18), btnY + ui(36) + btnH * 0.5, themeColor("textMain", Color(245, 245, 245, 255)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    surface.SetDrawColor(themeColor("info", Color(80, 140, 220, 255)))
    surface.DrawRect(rightX + ui(10), btnY + ui(72), btnW, btnH)
    draw.SimpleText("Report to Staff", FONT_TINY, rightX + ui(18), btnY + ui(72) + btnH * 0.5, themeColor("textMain", Color(245, 245, 245, 255)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    surface.SetDrawColor(themeColor("disabled", Color(100, 100, 100, 120)))
    surface.DrawRect(rightX + ui(10), btnY + ui(108), btnW, btnH)
    draw.SimpleText("Locked Punish", FONT_TINY, rightX + ui(18), btnY + ui(108) + btnH * 0.5, themeColor("textMain", Color(245, 245, 245, 255)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

local themeMixer = themeRight:Add("DColorMixer")
themeMixer:Dock(FILL)
themeMixer:SetPalette(true)
themeMixer:SetAlphaBar(true)
themeMixer:SetWangs(true)

local selectedThemeKey = ((ZCITY_GUILT.ThemeGroups or {})[1] and (ZCITY_GUILT.ThemeGroups[1].keys or {})[1]) or "panelBg"
local selectedThemeButtons = {}

local function syncThemeMixer()
    themeMixer:SetColor(themeColor(selectedThemeKey, Color(255, 255, 255, 255)))
end

local function refreshThemeButtons()
    for _, button in pairs(selectedThemeButtons) do
        if IsValid(button) then
            button:InvalidateLayout(true)
        end
    end
    menuPreview:InvalidateLayout(true)
end

local themeHelpWrap = themeList:Add("DPanel")
themeHelpWrap:Dock(TOP)
themeHelpWrap:DockMargin(0, ui(6), 0, ui(10))
themeHelpWrap:SetTall(ui(46))
themeHelpWrap.Paint = nil

local themeHelp = themeHelpWrap:Add("DLabel")
themeHelp:Dock(FILL)
themeHelp:DockMargin(ui(4), 0, ui(4), 0)
themeHelp:SetWrap(true)
themeHelp:SetAutoStretchVertical(true)
themeHelp:SetFont(FONT_TINY)
themeHelp:SetTextColor(themeColor("muted", Color(160, 160, 160, 255)))
themeHelp:SetText("Theme colors are grouped by UI surface. Click a button to edit it in the mixer.")

for _, group in ipairs(ZCITY_GUILT.ThemeGroups or {}) do
    local columns = 2
    local gap = ui(6)
    local buttonH = ui(30)
    local rows = math.max(1, math.ceil(#(group.keys or {}) / columns))
    local panelH = ui(28) + ui(8) + (rows * buttonH) + ((rows - 1) * gap) + ui(20)

    local groupPanel = themeList:Add("DPanel")
    groupPanel:Dock(TOP)
    groupPanel:DockMargin(0, 0, 0, ui(10))
    groupPanel:SetTall(panelH)
    groupPanel.Paint = function(_, w, h)
        surface.SetDrawColor(themeColor("panelInner", Color(18, 18, 18, 235)))
        surface.DrawRect(0, 0, w, h)
        drawOutlinedRect(0, 0, w, h, themeColor("accentSoft", Color(255, 45, 45, 120)), 1)
    end

    local groupHeader = groupPanel:Add("DLabel")
    groupHeader:Dock(TOP)
    groupHeader:SetTall(ui(28))
    groupHeader:DockMargin(ui(10), ui(4), ui(10), 0)
    groupHeader:SetFont(FONT_SMALL)
    groupHeader:SetText(group.title or "Group")
    groupHeader:SetTextColor(themeColor("textMain", Color(245, 245, 245, 255)))
    groupHeader:SetContentAlignment(4)

    local grid = groupPanel:Add("DPanel")
    grid:Dock(FILL)
    grid:DockMargin(ui(10), ui(8), ui(10), ui(10))
    grid.Paint = nil

    local function layoutGrid()
        local width = grid:GetWide()
        if width <= 0 then return end

        local buttonW = math.floor((width - gap) / columns)

        for index, key in ipairs(group.keys or {}) do
            local button = selectedThemeButtons[key]
            if not IsValid(button) then continue end

            local col = (index - 1) % columns
            local row = math.floor((index - 1) / columns)

            button:SetPos(col * (buttonW + gap), row * (buttonH + gap))
            button:SetSize(buttonW, buttonH)
        end
    end

    grid.PerformLayout = layoutGrid

    for _, key in ipairs(group.keys or {}) do
        local button = grid:Add("DButton")
        selectedThemeButtons[key] = button
        button:SetText("")
        button.Paint = function(self, w, h)
            local clr = themeColor(key, Color(255, 255, 255, 255))
            local selected = self.themeKey == selectedThemeKey

            surface.SetDrawColor(25, 25, 25, 220)
            surface.DrawRect(0, 0, w, h)
            drawOutlinedRect(
                0,
                0,
                w,
                h,
                selected and themeColor("accent", Color(190, 20, 20, 220)) or themeColor("accentSoft", Color(255, 45, 45, 120)),
                1
            )

            surface.SetDrawColor(clr)
            surface.DrawRect(ui(8), ui(8), ui(18), h - ui(16))

            draw.SimpleText(
                (ZCITY_GUILT.ThemeLabels and ZCITY_GUILT.ThemeLabels[key]) or key,
                FONT_TINY,
                ui(34),
                h * 0.5,
                themeColor("textMain", Color(245, 245, 245, 255)),
                TEXT_ALIGN_LEFT,
                TEXT_ALIGN_CENTER
            )
        end
        button.themeKey = key
        button.DoClick = function()
            selectedThemeKey = key
            syncThemeMixer()
            refreshThemeButtons()
        end
    end
end

themeMixer.ValueChanged = function(_, value)
    if not selectedThemeKey then return end

    work.Theme[selectedThemeKey] = {
        r = math.floor(value.r or 255),
        g = math.floor(value.g or 255),
        b = math.floor(value.b or 255),
        a = math.floor(value.a or 255)
    }

    applyWorkingTheme()
    refreshThemeButtons()
end

syncThemeMixer()
refreshThemeButtons()
end

concommand.Add("zcity_guilt_admin_menu", function()
    if not IsValid(LocalPlayer()) or not LocalPlayer():IsAdmin() then return end
    RunConsoleCommand("zcity_guilt_admin")
end)

net.Receive("zcity_guilt_admin_open", function()
    local cfg = net.ReadTable()
    openGuiltAdminMenu(cfg)
end)

net.Receive("zcity_guilt_admin_openmenu", function()
    if not IsValid(LocalPlayer()) or not LocalPlayer():IsAdmin() then return end
    RunConsoleCommand("zcity_guilt_admin")
end)
