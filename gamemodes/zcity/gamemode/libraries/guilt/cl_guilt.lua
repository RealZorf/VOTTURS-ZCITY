ZCITY_GUILT = ZCITY_GUILT or {}
ZCITY_GUILT.Menu = ZCITY_GUILT.Menu or {}

hook.Add("OnNetVarSet", "Guilt", function(index, key, var)
    if key == "Karma" then
        Entity(index).Karma = var
    end
end)

concommand.Add("hg_getkarma", function(ply)
    if not ply:IsAdmin() then return end
    net.Start("get_karma")
    net.SendToServer()
end)

net.Receive("get_karma", function()
    local tbl = net.ReadTable()
    local printTbl = "\nPlayers karma: \n"
    for id, karma in pairs(tbl) do
        printTbl = printTbl .. "\t" .. (Player(id):Name() .. "'s karma is " .. math.Round(karma, 2)) .. "\n"
    end
    LocalPlayer():PrintMessage(HUD_PRINTCONSOLE, printTbl)
end)

concommand.Add("hg_guilt_menu", function()
    RunConsoleCommand("zcity_guilt_menu")
end)

local function CFG()
    return ZCITY_GUILT.Config or ZCITY_GUILT.DefaultConfig or {}
end

local GuiltFrame, leftScroll, rightScroll, selectedData, pressedOpen
local cachedRows = {}

local CRT_R, CRT_G, CRT_B = 35, 225, 110
local TRAITOR_R, TRAITOR_G, TRAITOR_B = 225, 35, 35
local FRAME_R, FRAME_G, FRAME_B = 86, 94, 90
local color_bezel = Color(12, 13, 13)
local color_panel = Color(20, 22, 21)
local color_text = Color(236, 238, 236)
local color_idle_dim = Color(112, 118, 116)
local color_danger = Color(TRAITOR_R, TRAITOR_G, TRAITOR_B)
local color_info = Color(35, 140, 225)
local color_disabled = Color(100, 104, 102)
local BEZEL = 3
local INSET = BEZEL + 4
local SND_CLICK = "shitty/tap_depress.wav"
local SND_HOVER = "shitty/tap-resonant.wav"

local FONT_HEADER = "PATGUILT_Header"
local FONT_MED = "PATGUILT_Med"
local FONT_SMALL = "PATGUILT_Small"
local FONT_TINY = "PATGUILT_Tiny"

local function S(n)
    return math.max(1, math.Round(n * ScrH() / 1080))
end

local function CreateGuiltFonts()
    surface.CreateFont(FONT_HEADER, {font = "Bahnschrift", size = math.max(16, S(20)), weight = 700, antialias = true, extended = true})
    surface.CreateFont(FONT_MED, {font = "Bahnschrift", size = math.max(14, S(18)), weight = 600, antialias = true, extended = true})
    surface.CreateFont(FONT_SMALL, {font = "Bahnschrift", size = math.max(13, S(16)), weight = 600, antialias = true, extended = true})
    surface.CreateFont(FONT_TINY, {font = "Bahnschrift", size = math.max(12, S(14)), weight = 500, antialias = true, extended = true})
end

CreateGuiltFonts()
hook.Add("OnScreenSizeChanged", "ZCITY_GUILT_RebuildFonts", function()
    CreateGuiltFonts()
    if not IsValid(GuiltFrame) then return end
    local rows = table.Copy(cachedRows)
    GuiltFrame:Remove()
    GuiltFrame = nil
    timer.Simple(0, function()
        if #rows > 0 and IsValid(LocalPlayer()) and LocalPlayer():GetNWInt("ZCITY_GUILT_PENDING_COUNT", 0) > 0 then
            openMenu(rows)
        end
    end)
end)

local function ClickSound(path)
    local ply = LocalPlayer()
    if IsValid(ply) then
        ply:EmitSound(path, 75, 100, 0.09)
    else
        surface.PlaySound(path)
    end
end

local function DrawCRTCorners(x, y, w, h, len, a)
    surface.SetDrawColor(CRT_R, CRT_G, CRT_B, a)
    surface.DrawRect(x, y, len, 2)
    surface.DrawRect(x, y, 2, len)
    surface.DrawRect(x + w - len, y, len, 2)
    surface.DrawRect(x + w - 2, y, 2, len)
    surface.DrawRect(x, y + h - 2, len, 2)
    surface.DrawRect(x, y + h - len, 2, len)
    surface.DrawRect(x + w - len, y + h - 2, len, 2)
    surface.DrawRect(x + w - 2, y + h - len, 2, len)
end

local function DrawCRTFrame(x, y, w, h, selected)
    surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, 230)
    surface.DrawRect(x, y, w, h)
    local ix, iy, iw, ih = x + BEZEL, y + BEZEL, w - BEZEL * 2, h - BEZEL * 2
    surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, selected and 200 or 150)
    surface.DrawOutlinedRect(ix, iy, iw, ih, 1)
    DrawCRTCorners(ix, iy, iw, ih, 10, selected and 230 or 150)
    surface.SetDrawColor(color_panel.r, color_panel.g, color_panel.b, 210)
    surface.DrawRect(ix + 1, iy + 1, iw - 2, ih - 2)
end

local function DrawHeaderStrip(x, y, w, h, title)
    surface.SetDrawColor(32, 34, 33, 210)
    surface.DrawRect(x, y, w, h)
    surface.SetDrawColor(CRT_R, CRT_G, CRT_B, 36)
    surface.DrawRect(x, y, w, h)
    draw.SimpleText(title, FONT_HEADER, x + S(12), y + h * 0.5, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

local function DrawRow(w, h, hovered, selected)
    surface.SetDrawColor(32, 34, 33, hovered and 210 or 160)
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, selected and 160 or 70)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
    if selected then
        surface.SetDrawColor(CRT_R, CRT_G, CRT_B, 216)
        surface.DrawRect(0, 0, 2, h)
    end
end

local function PaintCRTButton(self, w, h, label, danger)
    local hover = self:IsHovered()
    local r, g, b = danger and TRAITOR_R or CRT_R, danger and TRAITOR_G or CRT_G, danger and TRAITOR_B or CRT_B
    surface.SetDrawColor(color_bezel)
    surface.DrawRect(0, 0, w, h)
    if hover then
        surface.SetDrawColor(r, g, b, 28)
        surface.DrawRect(1, 1, w - 2, h - 2)
    end
    surface.SetDrawColor(r, g, b, hover and 210 or 150)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
    draw.SimpleText(label, FONT_TINY, w * 0.5, h * 0.5, hover and color_text or (danger and color_danger or color_text), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function PaintEntry(self, w, h)
    surface.SetDrawColor(color_bezel)
    surface.DrawRect(0, 0, w, h)
    surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, self:IsEditing() and 200 or 120)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
    local text = self:GetText()
    draw.SimpleText(text, FONT_TINY, w * 0.5, h * 0.5, color_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    if self:IsEditing() and (CurTime() * 2) % 2 < 1 then
        surface.SetFont(FONT_TINY)
        local full = surface.GetTextSize(text)
        local caret = surface.GetTextSize(string.sub(text, 1, self:GetCaretPos()))
        surface.SetDrawColor(color_text)
        surface.DrawRect(math.floor(w * 0.5 - full * 0.5 + caret), math.floor(h * 0.5 - 7), 1, 14)
    end
end

local function StyleScroll(panel)
    if not IsValid(panel) or not panel.GetVBar then return end
    if panel.GetCanvas then
        local canvas = panel:GetCanvas()
        if IsValid(canvas) then canvas:DockPadding(0, 0, 0, 0) end
    end
    local bar = panel:GetVBar()
    bar:SetWide(S(8))
    bar:SetHideButtons(true)
    bar.Paint = function(_, w, h)
        surface.SetDrawColor(0, 0, 0, 70)
        surface.DrawRect(1, 0, w - 2, h)
    end
    bar.btnGrip.Paint = function(self, w, h)
        local hover = self:IsHovered()
        surface.SetDrawColor(hover and CRT_R or FRAME_R, hover and CRT_G or FRAME_G, hover and CRT_B or FRAME_B, hover and 180 or 130)
        surface.DrawRect(1, 0, w - 2, h)
    end
end

local function setupFrame(frame)
    if frame.SetTitle then frame:SetTitle("") end
    if frame.ShowCloseButton then frame:ShowCloseButton(false) end
    if IsValid(frame.lblTitle) then
        frame.lblTitle:SetVisible(false)
        frame.lblTitle:SetText("")
        frame.lblTitle:SetTall(0)
    end
    for _, key in ipairs({"btnClose", "btnMaxim", "btnMinim"}) do
        if IsValid(frame[key]) then
            frame[key]:SetVisible(false)
            frame[key]:SetSize(0, 0)
        end
    end
    frame:DockPadding(0, 0, 0, 0)
    frame.First = function(self) self:SetAlpha(255) end
    frame:SetAlpha(255)
    if frame.SetBlurStrengh then frame:SetBlurStrengh(0) end
    local old = frame.PerformLayout
    frame.PerformLayout = function(self, w, h)
        self:DockPadding(0, 0, 0, 0)
        if old then old(self, w, h) end
        self:DockPadding(0, 0, 0, 0)
    end
    timer.Simple(0, function()
        if IsValid(frame) then frame:DockPadding(0, 0, 0, 0) end
    end)
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

local function getSourceLabel(source)
    source = tostring(source or "damage")
    if source == "fentanyl" then return "fentanyl" end
    if source == "jumpkick" then return "a jump kick" end
    if source == "kick" then return "a kick" end
    if source == "gunfire" then return "gunfire" end
    if source == "melee_threat" then return "a melee weapon" end
    if source == "blocked_melee" then return "a blocked melee swing" end
    return "an attack"
end

local function lockText(reason)
    reason = tostring(reason or "")
    if reason == "" then return "Punish is locked." end
    if reason == "Victim was a traitor." then return "You were a traitor, so this is not punishable." end
    if reason == "Attacker was a traitor." then return "They were a traitor, so this is not punishable." end
    if reason == "Victim was already marked guilty." then return "You were already marked guilty." end
    if reason == "Attacker was berserk." then return "They were berserk." end
    if reason:find("Protected self-defense", 1, true) then return "Punish is locked: they were defending themselves." end
    return reason
end

local function getCharacterName(ent)
    if not IsValid(ent) then return "Unknown" end
    if ent.GetNWString then
        local nwName = ent:GetNWString("PlayerName", "")
        if nwName ~= "" then return nwName end
    end
    if istable(ent.CurAppearance) and tostring(ent.CurAppearance.AName or "") ~= "" then
        return tostring(ent.CurAppearance.AName)
    end
    if ent.GetPlayerName then
        local playerName = ent:GetPlayerName()
        if tostring(playerName or "") ~= "" then return tostring(playerName) end
    end
    return ent:Nick() or "Unknown"
end

local function getCaseName(row)
    if IsValid(row.ent) then return getCharacterName(row.ent) end
    return tostring(row.name or "Disconnected player") .. " (offline)"
end

local function wrapLines(text, font, maxW)
    text = tostring(text or "")
    surface.SetFont(font)
    local words = string.Explode(" ", text)
    local lines, cur = {}, ""
    for i = 1, #words do
        local try = cur == "" and words[i] or (cur .. " " .. words[i])
        if cur ~= "" and surface.GetTextSize(try) > maxW then
            lines[#lines + 1] = cur
            cur = words[i]
        else
            cur = try
        end
    end
    if cur ~= "" then lines[#lines + 1] = cur end
    return lines
end

local function isDefenseLocked(row)
    if not row then return false end
    if row.actionAllowed == false then return true end
    local c = CFG()
    local incoming = tonumber(row.incomingHarm) or 0
    local harm = tonumber(row.harm) or 0
    local score = tonumber(row.threatScore) or 0
    return (tonumber(row.selfDefenseMul) or 1) <= (c.PunishLockKarmaScale or 0.2)
        or (incoming >= harm * (c.PunishLockIncomingVsHarm or 0.8) and score >= (c.PunishLockMinThreatScore or 0.35))
end

local function describeThreat(row)
    local them = getCaseName(row)
    local harm = math.Round(tonumber(row.harm) or 0, 1)
    local incoming = math.Round(tonumber(row.incomingHarm) or 0, 1)
    local ratio = tonumber(row.responseRatio) or 0
    local facts = {
        them .. " hurt you with " .. getSourceLabel(row.damageSource) .. ".",
        "Harm they dealt you: " .. harm,
    }
    if incoming > 0 then
        facts[#facts + 1] = "Harm you dealt them first: " .. incoming
        facts[#facts + 1] = ratio <= 1.1 and "They hit back about as hard as you had hit them."
            or ("They hit you " .. math.Round(ratio, 1) .. " times harder than you had hit them.")
    else
        facts[#facts + 1] = "You had not hurt them first."
    end

    local seen = {}
    for _, reason in ipairs(istable(row.threatReasons) and row.threatReasons or {}) do
        local low = string.lower(tostring(reason or ""))
        local extra
        if low:find("amputat", 1, true) or low:find("limb", 1, true) then
            extra = "You took a limb off them before they hit you."
        elseif low:find("fired a bullet", 1, true) or (low:find("gunfire", 1, true) and low:find("initiated", 1, true)) then
            extra = "They shot at you first."
        elseif low:find("struck first with", 1, true) or low:find("lethal melee", 1, true) then
            extra = "They swung a lethal melee weapon at you first."
        elseif low:find("blocked", 1, true) then
            extra = "You blocked their melee swing."
        end
        if extra and not seen[extra] then
            seen[extra] = true
            facts[#facts + 1] = extra
        end
    end

    local verdict
    if row.actionAllowed == false then
        verdict = lockText(row.actionLockReason)
    elseif isDefenseLocked(row) then
        verdict = "This looks like self-defense. Punish is locked."
    elseif incoming <= 0 then
        verdict = "They started it."
    elseif ratio > 2 then
        verdict = "They went much further than they needed to."
    else
        verdict = "This was a fight. Decide if they went too far."
    end
    return verdict, facts
end

local function createActionButton(parent, title, colorBg, enabled, callback, subtitle, extra)
    local btn = parent:Add("DButton")
    btn:Dock(TOP)
    btn:DockMargin(S(12), 0, S(12), S(8))
    btn:SetTall((subtitle and subtitle ~= "") and S(52) or S(40))
    btn:SetText("")
    btn:SetEnabled(enabled ~= false)
    btn.Paint = function(self, w, h)
        local on = self:IsEnabled()
        local hover = self:IsHovered() and on
        local col = on and colorBg or color_disabled
        surface.SetDrawColor(32, 34, 33, hover and 210 or 160)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(col.r, col.g, col.b, on and (hover and 210 or 150) or 90)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        if hover then
            surface.SetDrawColor(col.r, col.g, col.b, 216)
            surface.DrawRect(0, 0, 2, h)
        end
        local labelCol = on and color_text or color_idle_dim
        local hasSub = subtitle and subtitle ~= ""
        draw.SimpleText(title, FONT_SMALL, S(12), hasSub and S(8) or h * 0.5, labelCol, TEXT_ALIGN_LEFT, hasSub and TEXT_ALIGN_TOP or TEXT_ALIGN_CENTER)
        if extra and extra ~= "" then
            draw.SimpleText(extra, FONT_SMALL, w - S(12), hasSub and S(8) or h * 0.5, labelCol, TEXT_ALIGN_RIGHT, hasSub and TEXT_ALIGN_TOP or TEXT_ALIGN_CENTER)
        end
        if hasSub then
            draw.SimpleText(subtitle, FONT_TINY, S(12), h - S(10), on and color_idle_dim or color_disabled, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
        end
    end
    btn.OnCursorEntered = function() if enabled ~= false then ClickSound(SND_HOVER) end end
    btn.DoClick = function(self)
        if not self:IsEnabled() then return end
        ClickSound(SND_CLICK)
        if callback then callback() end
    end
end

local function rebuildRightPanel()
    if not IsValid(rightScroll) then return end
    rightScroll:Clear()

    local header = rightScroll:Add("DPanel")
    header:Dock(TOP)
    header:DockMargin(S(12), S(12), S(12), S(10))
    header:SetTall(S(118))
    header:SetPaintBackground(false)

    local nativeHelp = header:Add("DLabel")
    nativeHelp:SetText("")
    nativeHelp:SetFont(FONT_TINY)
    nativeHelp:SetMouseInputEnabled(true)
    nativeHelp:SetCursor("hand")
    nativeHelp:SetTooltip("Karma this player already lost from the built-in karma system for this harm. Extra punish buttons take more on top of that.")
    nativeHelp:SetVisible(false)

    header.PerformLayout = function()
        local penaltyText = selectedData and ("Karma they already lost: " .. math.Round(selectedData.karma or 0, 1)) or "Karma they already lost: 0"
        surface.SetFont(FONT_SMALL)
        nativeHelp:SetSize(S(16), S(16))
        nativeHelp:SetPos(S(14) + surface.GetTextSize(penaltyText) + S(6), S(64))
    end
    nativeHelp.Paint = function(self, w, h)
        local hover = self:IsHovered()
        surface.SetDrawColor(color_bezel)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(hover and CRT_R or FRAME_R, hover and CRT_G or FRAME_G, hover and CRT_B or FRAME_B, hover and 210 or 140)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("?", FONT_TINY, w * 0.5, h * 0.5, hover and color_text or color_idle_dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    header.Paint = function(_, w, h)
        DrawRow(w, h, false, false)
        if not selectedData then
            nativeHelp:SetVisible(false)
            draw.SimpleText("Select a player", FONT_HEADER, S(14), S(12), color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("Choose someone from the left panel to review their case.", FONT_SMALL, S(14), S(42), color_idle_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("You can forgive, punish, or report from here.", FONT_TINY, S(14), h - S(14), color_idle_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
            return
        end
        nativeHelp:SetVisible(true)
        draw.SimpleText(getCaseName(selectedData), FONT_HEADER, S(14), S(10), color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Harm they dealt you: " .. math.Round(selectedData.harm or 0, 1), FONT_SMALL, S(14), S(38), color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Karma they already lost: " .. math.Round(selectedData.karma or 0, 1), FONT_SMALL, S(14), S(60), color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Case state: " .. (selectedData.decided and "Resolved" or "Pending"), FONT_SMALL, S(14), S(84), selectedData.decided and color_idle_dim or color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    if not selectedData then return end

    if selectedData.decided then
        local resolved = rightScroll:Add("DPanel")
        resolved:Dock(TOP)
        resolved:DockMargin(S(12), 0, S(12), 0)
        resolved:SetTall(S(40))
        resolved:SetPaintBackground(false)
        resolved.Paint = function(_, w, h)
            DrawRow(w, h, false, false)
            draw.SimpleText("Decision already made for this player.", FONT_SMALL, S(12), h * 0.5, color_danger, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        return
    end

    local harm = tonumber(selectedData.harm) or 0
    local verdict, facts = describeThreat(selectedData)
    local review = rightScroll:Add("DPanel")
    review:Dock(TOP)
    review:DockMargin(S(12), 0, S(12), S(10))
    review:SetTall(S(120))
    review:SetPaintBackground(false)
    review.Paint = function(self, w, h)
        DrawRow(w, h, false, false)
        local x, y = S(12), S(8)
        local maxW = math.max(40, w - S(24))
        draw.SimpleText("WHAT HAPPENED", FONT_TINY, x, y, Color(CRT_R, CRT_G, CRT_B), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        y = y + S(18)
        local lines = wrapLines(verdict, FONT_SMALL, maxW)
        for i = 1, #lines do
            draw.SimpleText(lines[i], FONT_SMALL, x, y, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            y = y + S(18)
        end
        y = y + S(4)
        for i = 1, #facts do
            local wrapped = wrapLines(facts[i], FONT_TINY, maxW)
            for j = 1, #wrapped do
                draw.SimpleText(wrapped[j], FONT_TINY, x, y, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                y = y + S(16)
            end
        end
        local needed = y + S(10)
        if math.abs(self:GetTall() - needed) > 2 then self:SetTall(needed) end
    end

    local c = CFG()
    if selectedData.respectEligible then
        createActionButton(rightScroll, "Give Respect", Color(CRT_R, CRT_G, CRT_B), true, function()
            sendAction(selectedData, "respect")
        end, "They killed you as a traitor.", "+" .. c.RespectKarmaReward .. " karma")
    elseif c.EnableForgive then
        createActionButton(rightScroll, "Forgive", Color(CRT_R, CRT_G, CRT_B), true, function()
            sendAction(selectedData, "forgive")
        end, "No extra karma taken.")
    end

    if c.EnablePunish and not selectedData.respectEligible then
        local defenseLocked = isDefenseLocked(selectedData)
        for _, preset in ipairs(c.Presets or {}) do
            local minharm = tonumber(preset.minharm) or 0
            local punishAmount = ZCITY_GUILT.GetPunishAmount(preset, selectedData)
            local unlocked = harm >= minharm and punishAmount > 0 and not defenseLocked
            local subtitle
            if selectedData.actionAllowed == false then
                subtitle = lockText(selectedData.actionLockReason)
            elseif defenseLocked then
                subtitle = "Looks like self-defense"
            elseif not unlocked then
                subtitle = "Needs " .. minharm .. " harm"
            end
            local shown = math.Round((unlocked and punishAmount or tonumber(preset.amount) or 0), 1)
            createActionButton(
                rightScroll,
                tostring(preset.name or "Punish"):gsub("%s*%(.*%)%s*$", ""),
                ZCITY_GUILT.GetPresetColor(preset),
                unlocked,
                function() sendAction(selectedData, preset.id) end,
                subtitle,
                "-" .. shown .. " karma"
            )
        end
    end

    if c.EnableReport and not selectedData.respectEligible then
        createActionButton(rightScroll, "Report to Staff", color_info, true, function()
            sendAction(selectedData, "report")
        end, "Send this case to online admins.")
    end
end

local function rebuildLeftPanel()
    if not IsValid(leftScroll) then return end
    leftScroll:Clear()
    table.sort(cachedRows, function(a, b)
        local ah, bh = tonumber(a and a.harm) or 0, tonumber(b and b.harm) or 0
        if ah ~= bh then return ah > bh end
        local ak, bk = tonumber(a and a.karma) or 0, tonumber(b and b.karma) or 0
        if ak ~= bk then return ak > bk end
        return string.lower(getCaseName(a)) < string.lower(getCaseName(b))
    end)
    for _, row in ipairs(cachedRows) do
        if tostring(row.steamid64 or "") == "" then continue end
        local card = leftScroll:Add("DButton")
        card:SetTall(S(72))
        card:Dock(TOP)
        card:DockMargin(S(12), 0, S(12), S(8))
        card:SetText("")
        local avatar = vgui.Create("AvatarImage", card)
        avatar:SetSize(S(48), S(48))
        avatar:SetPos(S(12), S(12))
        if IsValid(row.ent) and not row.ent:IsBot() then
            avatar:SetPlayer(row.ent, 64)
        end
        card.Paint = function(self, w, h)
            DrawRow(w, h, self:IsHovered(), selectedData == row)
            local nameClr = row.decided and color_idle_dim or color_text
            draw.SimpleText(getCaseName(row), FONT_MED, S(72), S(12), nameClr, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText("Harm: " .. math.Round(row.harm or 0, 1), FONT_SMALL, S(72), S(38), row.decided and color_disabled or color_idle_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(row.decided and "Resolved" or "Pending", FONT_TINY, w - S(12), S(14), row.decided and color_idle_dim or color_text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        end
        card.OnCursorEntered = function() ClickSound(SND_HOVER) end
        card.DoClick = function()
            ClickSound(SND_CLICK)
            selectedData = row
            rebuildRightPanel()
        end
    end
end

function openMenu(rows)
    CreateGuiltFonts()
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
    if #cachedRows <= 0 then return end

    local frameClass = vgui.GetControlTable("ZFrame") and "ZFrame" or "DFrame"
    GuiltFrame = vgui.Create(frameClass)
    local sizeX = math.min(S(1180), ScrW() * 0.84)
    local sizeY = math.min(S(760), ScrH() * 0.84)
    GuiltFrame:SetSize(sizeX, sizeY)
    GuiltFrame:Center()
    GuiltFrame:MakePopup()
    GuiltFrame:SetKeyboardInputEnabled(false)
    setupFrame(GuiltFrame)
    GuiltFrame.Paint = function(self, w, h)
        if hg and hg.DrawBlur then hg.DrawBlur(self, 5, 1, 120) end
        DrawCRTFrame(0, 0, w, h, true)
    end

    local titleBar = GuiltFrame:Add("DPanel")
    titleBar:Dock(TOP)
    titleBar:SetTall(S(48))
    titleBar:DockMargin(INSET, INSET, INSET, 0)
    titleBar:SetPaintBackground(false)
    titleBar.Paint = function(_, w, h)
        local pending = 0
        for _, row in ipairs(cachedRows) do
            if row.decided ~= true then pending = pending + 1 end
        end
        DrawHeaderStrip(0, 0, w, h, "FORGIVENESS / PUNISHMENT")
        surface.SetFont(FONT_HEADER)
        local tw = surface.GetTextSize("FORGIVENESS / PUNISHMENT")
        draw.SimpleText(
            pending .. (pending == 1 and " pending case" or " pending cases"),
            FONT_SMALL,
            S(20) + tw,
            h * 0.5,
            Color(CRT_R, CRT_G, CRT_B),
            TEXT_ALIGN_LEFT,
            TEXT_ALIGN_CENTER
        )
    end

    local closeButton = titleBar:Add("DButton")
    closeButton:Dock(RIGHT)
    closeButton:DockMargin(0, S(12), S(10), S(12))
    closeButton:SetWide(S(40))
    closeButton:SetText("")
    closeButton.Paint = function(self, w, h) PaintCRTButton(self, w, h, "X", true) end
    closeButton.OnCursorEntered = function() ClickSound(SND_HOVER) end
    closeButton.DoClick = function()
        ClickSound(SND_CLICK)
        if IsValid(GuiltFrame) then
            GuiltFrame:Remove()
            GuiltFrame = nil
        end
    end

    local body = GuiltFrame:Add("DPanel")
    body:Dock(FILL)
    body:DockMargin(INSET, S(8), INSET, INSET)
    body:SetPaintBackground(false)

    local leftW = math.floor(sizeX * 0.46)
    local leftPanel = body:Add("DPanel")
    leftPanel:Dock(LEFT)
    leftPanel:SetWide(leftW)
    leftPanel:SetPaintBackground(false)
    leftPanel.Paint = function(_, w, h)
        surface.SetDrawColor(12, 13, 13, 160)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, 90)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("ELIGIBLE PLAYERS", FONT_HEADER, S(12), S(10), color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Pick a row to review the case.", FONT_TINY, S(12), S(32), color_idle_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    leftScroll = leftPanel:Add("DScrollPanel")
    leftScroll.Paint = function() end
    StyleScroll(leftScroll)
    leftPanel.PerformLayout = function(self, w, h)
        leftScroll:SetPos(0, S(52))
        leftScroll:SetSize(w, h - S(52))
    end

    local rightPanel = body:Add("DPanel")
    rightPanel:Dock(FILL)
    rightPanel:DockMargin(S(10), 0, 0, 0)
    rightPanel:SetPaintBackground(false)
    rightPanel.Paint = function(_, w, h)
        surface.SetDrawColor(12, 13, 13, 160)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, 90)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText("ACTIONS", FONT_HEADER, S(12), S(10), color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Server rules still validate every action.", FONT_TINY, S(12), S(32), color_idle_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end
    rightScroll = rightPanel:Add("DScrollPanel")
    rightScroll.Paint = function() end
    StyleScroll(rightScroll)
    rightPanel.PerformLayout = function(self, w, h)
        rightScroll:SetPos(0, S(52))
        rightScroll:SetSize(w, h - S(52))
    end

    rebuildLeftPanel()
    rebuildRightPanel()
end

hook.Add("HUDPaint", "ZCITY_GUILT_Prompt", function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    if lp:GetNWInt("ZCITY_GUILT_PENDING_COUNT", 0) <= 0 then return end
    if IsValid(GuiltFrame) then return end
    if gui.IsGameUIVisible() then return end
    if IsValid(vgui.GetKeyboardFocus()) then return end

    local text = CFG().MenuPromptText or "Press F to open the guilt menu."
    surface.SetFont(FONT_MED)
    local tw, th = surface.GetTextSize(text)
    local boxW, boxH = tw + S(28), th + S(16)
    local x, y = ScrW() * 0.5 - boxW * 0.5, math.floor(ScrH() * 0.9 - boxH * 0.5)
    DrawCRTFrame(x, y, boxW, boxH, true)
    draw.SimpleText(text, FONT_MED, x + boxW * 0.5, y + boxH * 0.5, color_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if input.IsKeyDown(CFG().MenuOpenKey) then
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
    if lp:GetNWInt("ZCITY_GUILT_PENDING_COUNT", 0) > 0 then return end
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
    ZCITY_GUILT.Config = ZCITY_GUILT.SanitizeConfig(net.ReadTable())
    if IsValid(GuiltFrame) then
        rebuildLeftPanel()
        rebuildRightPanel()
    end
end)

local function fieldDirty(work, field)
    local cur, def = work[field.key], field.default
    if field.type == "bool" then return (cur and true or false) ~= (def and true or false) end
    if field.type == "string" then return tostring(cur or "") ~= tostring(def or "") end
    return tonumber(cur) ~= tonumber(def)
end

local function presetsDirty(work)
    local a, b = work.Presets or {}, (ZCITY_GUILT.DefaultConfig and ZCITY_GUILT.DefaultConfig.Presets) or {}
    if #a ~= #b then return true end
    for i = 1, #a do
        local p, d = a[i], b[i]
        if tostring(p.id) ~= tostring(d.id) or tostring(p.name) ~= tostring(d.name) then return true end
        if tonumber(p.amount) ~= tonumber(d.amount) or tonumber(p.minharm) ~= tonumber(d.minharm) then return true end
        local pc, dc = p.color or {}, d.color or {}
        if tonumber(pc.r) ~= tonumber(dc.r) or tonumber(pc.g) ~= tonumber(dc.g) or tonumber(pc.b) ~= tonumber(dc.b) then return true end
    end
    return false
end

local function AddHeaderButton(parent, label, wide, danger, click)
    local btn = parent:Add("DButton")
    btn:Dock(RIGHT)
    btn:DockMargin(0, S(10), S(8), S(10))
    btn:SetWide(wide)
    btn:SetText("")
    btn.Paint = function(self, w, h) PaintCRTButton(self, w, h, label, danger) end
    btn.OnCursorEntered = function() ClickSound(SND_HOVER) end
    btn.DoClick = function()
        ClickSound(SND_CLICK)
        click()
    end
    return btn
end

local function AddSettingRow(parent, work, field)
    local kind = field.type
    if kind == "int" or kind == "number" then kind = "num" end
    local rowH, btnH, toggleH = S(64), S(36), S(24)
    local side = math.floor((rowH - btnH) * 0.5)
    local row = parent:Add("DPanel")
    row:Dock(TOP)
    row:SetTall(rowH)
    row:DockMargin(0, 0, 0, S(8))
    row:SetPaintBackground(false)
    row.Paint = function(self, w, h)
        DrawRow(w, h, self:IsHovered(), false)
        draw.SimpleText(field.label, FONT_HEADER, S(16), h * 0.5 - S(8), color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(field.desc or "", FONT_TINY, S(16), h * 0.5 + S(12), color_idle_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    if kind == "bool" then
        local toggle = vgui.Create("DButton", row)
        toggle:SetText("")
        toggle:SetWide(S(52))
        toggle:Dock(RIGHT)
        toggle:DockMargin(S(6), math.floor((rowH - toggleH) * 0.5), S(10), math.floor((rowH - toggleH) * 0.5))
        toggle.Paint = function(self, w, h)
            local on = work[field.key] and true or false
            local hover = self:IsHovered()
            surface.SetDrawColor(color_bezel)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(on and CRT_R or (hover and TRAITOR_R or FRAME_R), on and CRT_G or (hover and TRAITOR_G or FRAME_G), on and CRT_B or (hover and TRAITOR_B or FRAME_B), 180)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            local knob = h - S(8)
            surface.DrawRect(on and (w - knob - S(4)) or S(4), S(4), knob, knob)
        end
        toggle.OnCursorEntered = function() ClickSound(SND_HOVER) end
        toggle.DoClick = function()
            ClickSound(SND_CLICK)
            work[field.key] = not work[field.key]
        end
    elseif kind == "num" then
        local min, max = field.min or 0, field.max or 100
        if min == max then max = min + 1 end
        local span = max - min
        local decimals = field.type == "int" and 0 or 2
        local wrap = vgui.Create("DPanel", row)
        wrap:Dock(RIGHT)
        wrap:SetWide(S(268))
        wrap:DockMargin(S(12), side, S(16), side)
        wrap:SetPaintBackground(false)

        local entry = vgui.Create("DTextEntry", wrap)
        entry:Dock(LEFT)
        entry:SetWide(S(72))
        entry:DockMargin(0, 0, S(8), 0)
        entry:SetFont(FONT_TINY)
        entry:SetText(tostring(decimals > 0 and math.Round(tonumber(work[field.key]) or 0, decimals) or math.floor(tonumber(work[field.key]) or 0)))
        entry.Paint = PaintEntry

        local slider = vgui.Create("DSlider", wrap)
        slider:Dock(FILL)
        slider:SetLockY(0.5)
        slider:SetTrapInside(true)
        slider:SetSlideX(math.Clamp(((tonumber(work[field.key]) or min) - min) / span, 0, 1))
        local knob = math.max(8, S(10))
        slider.Knob:SetSize(knob, knob)
        slider.Knob:SetCursor("hand")
        slider.Knob.Paint = function(self, w, h)
            local active = self:IsHovered() or self:IsDown() or slider.Dragging
            surface.SetDrawColor(CRT_R, CRT_G, CRT_B, active and 255 or 230)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(12, 14, 12, 220)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
        slider.Paint = function(self, w, h)
            local frac = math.Clamp(self:GetSlideX(), 0, 1)
            local y = math.floor((h - 3) * 0.5)
            surface.SetDrawColor(0, 0, 0, 210)
            surface.DrawRect(0, y, w, 3)
            surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, 90)
            surface.DrawRect(0, y, w, 3)
            surface.SetDrawColor(CRT_R, CRT_G, CRT_B, 230)
            surface.DrawRect(0, y, w * frac, 3)
        end

        local function Apply(v)
            if not v then
                v = tonumber(work[field.key]) or field.default
            end
            v = decimals > 0 and math.Round(math.Clamp(v, min, max), decimals) or math.Round(math.Clamp(v, min, max))
            work[field.key] = v
            slider.ignore = true
            slider:SetSlideX(math.Clamp((v - min) / span, 0, 1))
            slider.ignore = false
            if not entry:HasFocus() then entry:SetText(tostring(v)) end
        end
        slider.OnValueChanged = function(_, x)
            if not slider.ignore then Apply(min + math.Clamp(x, 0, 1) * span) end
        end
        entry.OnEnter = function(self) Apply(tonumber(self:GetText())) end
        entry.OnLoseFocus = function(self) Apply(tonumber(self:GetText())) end
        wrap.Think = function()
            if entry:HasFocus() or slider.Dragging then return end
            local v = decimals > 0 and math.Round(tonumber(work[field.key]) or 0, decimals) or math.floor(tonumber(work[field.key]) or 0)
            local text = tostring(v)
            if entry:GetText() ~= text then entry:SetText(text) end
            local x = math.Clamp(((tonumber(work[field.key]) or min) - min) / span, 0, 1)
            if math.abs(slider:GetSlideX() - x) > 0.001 then
                slider.ignore = true
                slider:SetSlideX(x)
                slider.ignore = false
            end
        end
    else
        local entry = vgui.Create("DTextEntry", row)
        entry:Dock(RIGHT)
        entry:SetWide(S(220))
        entry:DockMargin(S(12), side, S(16), side)
        entry:SetFont(FONT_TINY)
        entry:SetText(tostring(work[field.key] or ""))
        entry:SetUpdateOnType(true)
        entry.Paint = PaintEntry
        entry.OnValueChange = function(_, val) work[field.key] = val end
        entry.Think = function(self)
            if self:HasFocus() then return end
            local val = tostring(work[field.key] or "")
            if self:GetText() ~= val then self:SetText(val) end
        end
    end

    local reset = vgui.Create("DButton", row)
    reset:SetText("")
    reset:SetWide(0)
    reset:Dock(RIGHT)
    reset:DockMargin(0, side, 0, side)
    reset.Paint = function(self, w, h)
        if w < 2 then return end
        PaintCRTButton(self, w, h, "RESET", true)
    end
    reset.OnCursorEntered = function(self)
        if self:GetWide() > 2 then ClickSound(SND_HOVER) end
    end
    reset.DoClick = function()
        ClickSound(SND_CLICK)
        work[field.key] = field.default
    end
    reset.Think = function(self)
        local dirty = fieldDirty(work, field)
        local w = dirty and S(72) or 0
        if self:GetWide() == w then return end
        self:SetWide(w)
        self:DockMargin(dirty and S(6) or 0, side, dirty and S(6) or 0, side)
        row:InvalidateLayout()
    end
end

local function openGuiltAdminMenu(cfg)
    if not IsValid(LocalPlayer()) or not LocalPlayer():IsAdmin() then return end
    CreateGuiltFonts()

    local work = ZCITY_GUILT.SanitizeConfig(cfg)
    local frameClass = vgui.GetControlTable("ZFrame") and "ZFrame" or "DFrame"
    local frame = vgui.Create(frameClass)
    frame:SetSize(math.min(S(1080), ScrW() * 0.86), math.min(S(900), ScrH() * 0.9))
    frame:Center()
    frame:MakePopup()
    setupFrame(frame)
    frame.Paint = function(self, w, h)
        if hg and hg.DrawBlur then hg.DrawBlur(self, 5, 1, 120) end
        DrawCRTFrame(0, 0, w, h, true)
    end

    local titleBar = frame:Add("DPanel")
    titleBar:Dock(TOP)
    titleBar:SetTall(S(48))
    titleBar:DockMargin(INSET, INSET, INSET, 0)
    titleBar:SetPaintBackground(false)
    titleBar.Paint = function(_, w, h)
        DrawHeaderStrip(0, 0, w, h, "GUILT ADMIN")
    end

    AddHeaderButton(titleBar, "X", S(40), true, function() frame:Remove() end)
    AddHeaderButton(titleBar, "SAVE", S(88), false, function()
        net.Start("zcity_guilt_admin_save")
        net.WriteTable(work)
        net.SendToServer()
        frame:Remove()
    end)

    local scroll = frame:Add("DScrollPanel")
    scroll:Dock(FILL)
    scroll:DockMargin(INSET, S(8), INSET, INSET)
    StyleScroll(scroll)

    local function fillSettings()
        scroll:Clear()
        local lastGroup
        for i, field in ipairs(ZCITY_GUILT.Settings or {}) do
            if field.group ~= lastGroup then
                lastGroup = field.group
                local heading = scroll:Add("DPanel")
                heading:Dock(TOP)
                heading:SetTall(S(32))
                heading:DockMargin(0, i == 1 and S(4) or 0, 0, 0)
                heading:SetPaintBackground(false)
                heading.Paint = function()
                    draw.SimpleText(string.upper(field.group), FONT_HEADER, S(12), S(4), color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                end
            end
            AddSettingRow(scroll, work, field)
        end

        local heading = scroll:Add("DPanel")
        heading:Dock(TOP)
        heading:SetTall(S(32))
        heading:SetPaintBackground(false)
        heading.Paint = function()
            draw.SimpleText("PUNISH PRESETS", FONT_HEADER, S(12), S(4), color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        local resetPresets = heading:Add("DButton")
        resetPresets:Dock(RIGHT)
        resetPresets:SetWide(0)
        resetPresets:DockMargin(0, S(2), S(8), S(2))
        resetPresets:SetText("")
        resetPresets.Paint = function(self, w, h)
            if w < 2 then return end
            PaintCRTButton(self, w, h, "RESET", true)
        end
        resetPresets.OnCursorEntered = function(self)
            if self:GetWide() > 2 then ClickSound(SND_HOVER) end
        end
        resetPresets.DoClick = function()
            ClickSound(SND_CLICK)
            work.Presets = table.Copy((ZCITY_GUILT.DefaultConfig and ZCITY_GUILT.DefaultConfig.Presets) or {})
            fillSettings()
        end
        resetPresets.Think = function(self)
            local dirty = presetsDirty(work)
            local w = dirty and S(72) or 0
            if self:GetWide() ~= w then self:SetWide(w) end
        end

        for i, preset in ipairs(work.Presets) do
            local row = scroll:Add("DPanel")
            row:Dock(TOP)
            row:SetTall(S(96))
            row:DockMargin(0, 0, 0, S(8))
            row:SetPaintBackground(false)
            row.Paint = function(self, w, h)
                DrawRow(w, h, self:IsHovered(), false)
                draw.SimpleText("Preset #" .. i, FONT_HEADER, S(16), S(10), color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end

            local function addField(dock, wide, label, value, onChange, numeric)
                local wrap = vgui.Create("DPanel", row)
                wrap:Dock(dock)
                wrap:SetWide(wide)
                wrap:DockMargin(S(8), S(36), S(8), S(10))
                wrap:SetPaintBackground(false)
                wrap.Paint = function(_, w, h)
                    draw.SimpleText(label, FONT_TINY, 0, 0, color_idle_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                end
                local entry = vgui.Create("DTextEntry", wrap)
                entry:Dock(BOTTOM)
                entry:SetTall(S(28))
                entry:SetFont(FONT_TINY)
                entry:SetText(tostring(value or ""))
                entry:SetUpdateOnType(true)
                entry.Paint = PaintEntry
                entry.OnValueChange = function(_, val)
                    if numeric then
                        onChange(tonumber(val) or 0)
                    else
                        onChange(val)
                    end
                end
            end

            local remove = vgui.Create("DButton", row)
            remove:Dock(RIGHT)
            remove:SetWide(S(88))
            remove:DockMargin(S(8), S(36), S(12), S(10))
            remove:SetText("")
            remove.Paint = function(self, w, h) PaintCRTButton(self, w, h, "REMOVE", true) end
            remove.OnCursorEntered = function() ClickSound(SND_HOVER) end
            remove.DoClick = function()
                ClickSound(SND_CLICK)
                table.remove(work.Presets, i)
                fillSettings()
            end

            addField(LEFT, S(140), "Internal ID", preset.id, function(v) preset.id = v end)
            addField(LEFT, S(220), "Button name", preset.name, function(v) preset.name = v end)
            addField(LEFT, S(90), "Karma removed", preset.amount, function(v) preset.amount = v end, true)
            addField(LEFT, S(90), "Min harm", preset.minharm, function(v) preset.minharm = v end, true)
            preset.color = preset.color or {r = 255, g = 255, b = 255}
            addField(LEFT, S(54), "R", preset.color.r, function(v) preset.color.r = v end, true)
            addField(LEFT, S(54), "G", preset.color.g, function(v) preset.color.g = v end, true)
            addField(LEFT, S(54), "B", preset.color.b, function(v) preset.color.b = v end, true)
        end

        local addRow = scroll:Add("DPanel")
        addRow:Dock(TOP)
        addRow:SetTall(S(44))
        addRow:DockMargin(0, 0, 0, S(12))
        addRow:SetPaintBackground(false)
        local addBtn = addRow:Add("DButton")
        addBtn:Dock(FILL)
        addBtn:SetText("")
        addBtn.Paint = function(self, w, h) PaintCRTButton(self, w, h, "ADD PRESET", false) end
        addBtn.OnCursorEntered = function() ClickSound(SND_HOVER) end
        addBtn.DoClick = function()
            ClickSound(SND_CLICK)
            work.Presets[#work.Presets + 1] = {
                id = "preset_" .. (#work.Presets + 1),
                name = "New Preset",
                amount = 5,
                minharm = 5,
                color = {r = 255, g = 255, b = 255}
            }
            fillSettings()
        end
    end

    AddHeaderButton(titleBar, "RESET ALL", S(110), true, function()
        work = ZCITY_GUILT.SanitizeConfig({})
        fillSettings()
    end)

    fillSettings()
end

concommand.Add("zcity_guilt_admin_menu", function()
    if not IsValid(LocalPlayer()) or not LocalPlayer():IsAdmin() then return end
    RunConsoleCommand("zcity_guilt_admin")
end)

net.Receive("zcity_guilt_admin_open", function()
    openGuiltAdminMenu(net.ReadTable())
end)

net.Receive("zcity_guilt_admin_openmenu", function()
    if not IsValid(LocalPlayer()) or not LocalPlayer():IsAdmin() then return end
    RunConsoleCommand("zcity_guilt_admin")
end)
