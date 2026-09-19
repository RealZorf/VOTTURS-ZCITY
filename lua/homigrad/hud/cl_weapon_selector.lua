--
hg = hg or {}
hg.WeaponSelector = hg.WeaponSelector or {}
local WS = hg.WeaponSelector

WS.Show = 0
WS.Transparent = 0
WS.LastSelectedSlot = 0
WS.LastSelectedSlotPos = 0

WS.SelectedSlot = 0
WS.SelectedSlotPos = 0

local CRT_R, CRT_G, CRT_B = 35, 225, 110
local TRAITOR_R, TRAITOR_G, TRAITOR_B = 225, 35, 35
local GRAY_R, GRAY_G, GRAY_B = 148, 156, 150
local color_crt_soft = Color(160, 255, 200)
local color_traitor_soft = Color(255, 160, 160)
local color_idle = Color(172, 180, 174)
local color_idle_dim = Color(118, 126, 122)
local color_bezel = Color(8, 9, 9)

local IsValid = IsValid
local CurTime = CurTime
local FrameNumber = FrameNumber
local ScrW, ScrH = ScrW, ScrH
local math_min, math_max, math_floor, math_Clamp = math.min, math.max, math.floor, math.Clamp
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local surface_DrawOutlinedRect = surface.DrawOutlinedRect
local surface_SetMaterial = surface.SetMaterial
local surface_SetTexture = surface.SetTexture
local surface_DrawTexturedRect = surface.DrawTexturedRect
local surface_SetFont = surface.SetFont
local surface_GetTextSize = surface.GetTextSize
local surface_SetTextColor = surface.SetTextColor
local surface_SetTextPos = surface.SetTextPos
local surface_DrawText = surface.DrawText
local render_SetScissorRect = render.SetScissorRect
local render_PushFilterMag = render.PushFilterMag
local render_PushFilterMin = render.PushFilterMin
local render_PopFilterMin = render.PopFilterMin
local render_PopFilterMag = render.PopFilterMag
local isnumber = isnumber

local slotNums = { [0] = "1", "2", "3", "4", "5", "6" }

local textWidthCache = {}
local printNameCache = {}
local caretW
local frameAlpha = 0
local now = 0

local function CreateCRTFonts()
	surface.CreateFont("WS_CRT_Slot", {
		font = "Bahnschrift",
		size = math.max(16, ScreenScale(8)),
		weight = 700,
		antialias = true,
		extended = true
	})
	surface.CreateFont("WS_CRT_Item", {
		font = "Bahnschrift",
		size = math.max(12, ScreenScale(5.5)),
		weight = 600,
		antialias = true,
		extended = true
	})
	textWidthCache = {}
	caretW = nil
end

CreateCRTFonts()
hook.Add("OnScreenSizeChanged", "WeaponSelector_CRTFonts", CreateCRTFonts)

local function GetTextWidth(font, text)
	local byFont = textWidthCache[font]
	if not byFont then
		byFont = {}
		textWidthCache[font] = byFont
	end
	local w = byFont[text]
	if w then return w end
	surface_SetFont(font)
	w = surface_GetTextSize(text)
	byFont[text] = w
	return w
end

local function GetCaretWidth()
	if caretW then return caretW end
	caretW = GetTextWidth("WS_CRT_Item", ">")
	return caretW
end

local function CRTAlpha(mul)
	return math_Clamp(WS.Transparent * 255 * (mul or 1), 0, 255)
end

function WS.DrawText(text, font, posX, posY, color, textAlign)
	local a = frameAlpha ~= 0 and frameAlpha or CRTAlpha()
	surface_SetFont(font)
	if textAlign == TEXT_ALIGN_CENTER then
		posX = posX - GetTextWidth(font, text) * 0.5
	elseif textAlign == TEXT_ALIGN_RIGHT then
		posX = posX - GetTextWidth(font, text)
	end
	surface_SetTextColor(color.r, color.g, color.b, a)
	surface_SetTextPos(posX, posY)
	surface_DrawText(text)
end

local function DrawMarqueeText(text, font, x, y, w, color, seed, leftIfFit, startTime, clipL, clipT, clipR, clipB)
	local tw = GetTextWidth(font, text)
	if tw <= w then
		if leftIfFit then
			WS.DrawText(text, font, x, y, color, TEXT_ALIGN_LEFT)
		else
			WS.DrawText(text, font, x + w * 0.5, y, color, TEXT_ALIGN_CENTER)
		end
		return
	end

	local gap = math_max(24, math_floor(w * 0.35))
	local cycle = tw + gap
	local travel = cycle / 42
	local period = travel + 0.55
	local t = startTime and math_max(now - startTime, 0) % period or (now + (seed or 0)) % period
	local offset = t < 0.55 and 0 or ((t - 0.55) / travel) * cycle

	if clipL then
		render_SetScissorRect(clipL, clipT, clipR, clipB, true)
	end
	WS.DrawText(text, font, x - offset, y, color, TEXT_ALIGN_LEFT)
	WS.DrawText(text, font, x - offset + cycle, y, color, TEXT_ALIGN_LEFT)
	if clipL then
		render_SetScissorRect(0, 0, 0, 0, false)
	end
end

local function DrawStaticText(text, font, x, y, w, color, center, clipL, clipT, clipR, clipB)
	if clipL then
		render_SetScissorRect(clipL, clipT, clipR, clipB, true)
	end

	if center then
		WS.DrawText(text, font, x + w * 0.5, y, color, TEXT_ALIGN_CENTER)
	else
		WS.DrawText(text, font, x, y, color, TEXT_ALIGN_LEFT)
	end

	if clipL then
		render_SetScissorRect(0, 0, 0, 0, false)
	end
end

local function DrawCRTCorners(x, y, w, h, len, r, g, b, a)
	surface_SetDrawColor(r, g, b, a)
	surface_DrawRect(x, y, len, 2)
	surface_DrawRect(x, y, 2, len)
	surface_DrawRect(x + w - len, y, len, 2)
	surface_DrawRect(x + w - 2, y, 2, len)
	surface_DrawRect(x, y + h - 2, len, 2)
	surface_DrawRect(x, y + h - len, 2, len)
	surface_DrawRect(x + w - len, y + h - 2, len, 2)
	surface_DrawRect(x + w - 2, y + h - len, 2, len)
end

local function DrawWepIcon(wep, x, y, wide, tall, alpha)
	surface_SetDrawColor(255, 255, 255, alpha)
	local mat = wep.WepSelectIcon2
	if mat then
		if not wep.IconEdited then
			mat:SetInt("$flags", 32)
			wep.IconEdited = true
		end
		render_PushFilterMag(TEXFILTER.ANISOTROPIC)
		render_PushFilterMin(TEXFILTER.ANISOTROPIC)
		surface_SetMaterial(mat)
		if wep.WepSelectIcon2box then
			local s = wide / 1.95
			surface_DrawTexturedRect(x + (wide - s) * 0.5, y, s, s)
		else
			surface_DrawTexturedRect(x, y, wide, wide * 0.5)
		end
		render_PopFilterMin()
		render_PopFilterMag()
		return
	end

	local icon = wep.WepSelectIcon
	if not icon then return end
	if isnumber(icon) then
		surface_SetTexture(icon)
	else
		surface_SetMaterial(icon)
	end
	surface_DrawTexturedRect(x, y, wide, wide * 0.5)
end

local formattedSlots = {
	[0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {},
}
local slotCounts = { [0] = 0, 0, 0, 0, 0, 0 }
local wepCache = {}
local wepCacheSlot = {}
local wepCacheSlotPos = {}
local wepCacheN = 0
local wepCacheFrame = -1
local wepCacheBuilt = -1
local wepCachePly

local function SortSlotPos(a, b)
	return (a.SlotPos or 0) > (b.SlotPos or 0)
end

function WS.GetWeaponTable( ply )
    if not IsValid( ply ) or not ply:Alive() then return end

    local frame = FrameNumber()
    if wepCachePly == ply and wepCacheBuilt ~= -1 and (frame - wepCacheBuilt) < 5 then
        wepCacheFrame = frame
        return formattedSlots, slotCounts
    end

    local WeaponsGet = ply:GetWeapons()
    local n = #WeaponsGet
    local unchanged = n == wepCacheN
    if unchanged then
        for i = 1, n do
            local wep = WeaponsGet[i]
            if wepCache[i] ~= wep or wepCacheSlot[i] ~= (wep.Slot or 0) or wepCacheSlotPos[i] ~= (wep.SlotPos or 0) then
                unchanged = false
                break
            end
        end
    end

    if unchanged and wepCacheBuilt ~= -1 then
        wepCacheFrame = frame
        wepCacheBuilt = frame
        wepCachePly = ply
        return formattedSlots, slotCounts
    end

    for i = 0, 5 do
        local slotTbl = formattedSlots[i]
        for k in pairs(slotTbl) do
            slotTbl[k] = nil
        end
        slotCounts[i] = 0
    end

    table.sort(WeaponsGet, SortSlotPos)

    for i = 1, n do
        local wep = WeaponsGet[i]
        local slot = wep.Slot or 0
        local tTbl = formattedSlots[slot]
        if tTbl then
            local iMinPos = math_min(wep.SlotPos or 1, (#tTbl or 0) + 1) - 1
            local iPos = tTbl[iMinPos] and #tTbl + 1 or iMinPos
            tTbl[iPos] = wep
            slotCounts[slot] = slotCounts[slot] + 1
        end
        wepCache[i] = wep
        wepCacheSlot[i] = slot
        wepCacheSlotPos[i] = wep.SlotPos or 0
    end
    for i = n + 1, wepCacheN do
        wepCache[i] = nil
        wepCacheSlot[i] = nil
        wepCacheSlotPos[i] = nil
    end
    wepCacheN = n
    wepCacheFrame = frame
    wepCacheBuilt = frame
    wepCachePly = ply

    return formattedSlots, slotCounts
end

function WS.GetSelectedWeapon(Weapons)
    local ply = LocalPlayer()
    if not IsValid( ply ) or not ply:Alive() then return end
    Weapons = Weapons or WS.GetWeaponTable( ply )
    if not Weapons then return end
    return Weapons[WS.SelectedSlot] and Weapons[WS.SelectedSlot][WS.SelectedSlotPos] or Weapons[WS.LastSelectedSlot][WS.LastSelectedSlotPos] or Weapons[0][0]
end

function WS.GetPrintName( self )
	local class = self:GetClass()
	local cached = printNameCache[class]
	if cached then return cached end
	local phrase = language.GetPhrase(class)
	local name = phrase ~= class and phrase or self:GetPrintName()
	printNameCache[class] = name
	return name
end

local scrW, scrH = ScrW(), ScrH()
local hiddenReset = false

WS.MarqueeStarts = WS.MarqueeStarts or {}
WS.MarqueeWep = WS.MarqueeWep or nil
WS.MarqueeSlot = WS.MarqueeSlot or nil
WS.MarqueeSlotStart = WS.MarqueeSlotStart or 0

local function ResetMarqueeForWeapon(wep)
	if not IsValid(wep) then return end
	WS.MarqueeStarts[wep] = now
end

local function ResetMarqueeForSlot(slotTbl)
	if not slotTbl then return end

	for Id = 0, #slotTbl do
		local wep = slotTbl[Id]
		if IsValid(wep) then
			WS.MarqueeStarts[wep] = now
		end
	end

	WS.MarqueeSlotStart = now
end

local function GetMarqueeStart(wep)
	if not IsValid(wep) then return now end
	return WS.MarqueeStarts[wep] or WS.MarqueeSlotStart or now
end

function WS.WeaponSelectorDraw( ply )
    if not IsValid( ply ) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end
    now = CurTime()

    local isTraitor = ply.isTraitor
    local activeR, activeG, activeB = isTraitor and TRAITOR_R or CRT_R, isTraitor and TRAITOR_G or CRT_G, isTraitor and TRAITOR_B or CRT_B
    local activeColor = isTraitor and color_traitor_soft or color_crt_soft
    if WS.Show < now then
        if not hiddenReset then
            WS.SelectedSlot = WS.LastSelectedSlot
            WS.SelectedSlotPos = -1
            WS.MarqueeWep = nil
            WS.MarqueeSlot = nil
            WS.MarqueeSlotStart = 0
            hiddenReset = true
        end
        return
    end
    hiddenReset = false

    local Weapons, counts = WS.GetWeaponTable( ply )
    local SelectedWep = WS.GetSelectedWeapon(Weapons)
    if not IsValid(SelectedWep) then return end

    local selectedSlot = SelectedWep.Slot or 0
    local slotChanged = WS.MarqueeSlot ~= selectedSlot

    if slotChanged then
        WS.MarqueeSlot = selectedSlot
        WS.MarqueeWep = SelectedWep

        local selectedSlotTbl = Weapons[selectedSlot]
        ResetMarqueeForSlot(selectedSlotTbl)
    elseif WS.MarqueeWep ~= SelectedWep then
        WS.MarqueeWep = SelectedWep
        ResetMarqueeForWeapon(SelectedWep)
    end

    WS.Transparent = LerpFT( 0.2, WS.Transparent, math_min( WS.Show - now, 1 ) )

    scrW, scrH = ScrW(), ScrH()
    local a = CRTAlpha()
    frameAlpha = a

    local pad = 4
    local textPad = 4
    local gap = math_max(6, math_floor(scrW * 0.004))
    local sizeX = math_floor(scrW * 0.1)
    local rowH = math_max(16, math_floor(scrH * 0.025))
    local selH = math_max(rowH + 24, math_floor(scrH * 0.12))
    local headerH = math_max(18, math_floor(scrH * 0.022))
    local topY = math_floor(scrH * 0.018)
    local extraSel = selH - rowH

    local SuperAmmout = 0
    local AmmoutSlots = 0
    for i = 0, 5 do
        if (counts[i] or 0) > 0 then
            AmmoutSlots = AmmoutSlots + 1
        end
    end

    local totalW = AmmoutSlots * sizeX + math_max(AmmoutSlots - 1, 0) * gap
    local originX = math_floor(scrW * 0.5 - totalW * 0.5)

    local caretWidth = GetCaretWidth()

    for i = 0, 5 do
        local itemCount = counts[i] or 0
        if itemCount < 1 then continue end

        local slotTbl = Weapons[i]
        local position = originX + SuperAmmout * (sizeX + gap)
        local hasSelected = selectedSlot == i

        local itemsH = itemCount * rowH + (hasSelected and extraSel or 0)
        local colH = pad + headerH + pad + itemsH + pad
        local bezel = 3
        local accentR, accentG, accentB = hasSelected and activeR or GRAY_R, hasSelected and activeG or GRAY_G, hasSelected and activeB or GRAY_B

        surface_SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, a * 0.8)
        surface_DrawRect(position - bezel, topY - bezel, sizeX + bezel * 2, colH + bezel * 2)
        surface_SetDrawColor(accentR, accentG, accentB, a * (hasSelected and 0.7 or 0.4))
        surface_DrawOutlinedRect(position, topY, sizeX, colH, 1)
        DrawCRTCorners(position, topY, sizeX, colH, 10, accentR, accentG, accentB, a * (hasSelected and 0.95 or 0.55))

        local innerX = position + pad
        local innerW = sizeX - pad * 2
        local innerY = topY + pad
        local innerH = colH - pad * 2

        surface_SetDrawColor(0, 0, 0, a * 0.45)
        surface_DrawRect(innerX, innerY, innerW, innerH)
        surface_SetDrawColor(accentR, accentG, accentB, a * (hasSelected and 0.16 or 0.05))
        surface_DrawRect(innerX, innerY, innerW, headerH)
        WS.DrawText(slotNums[i] or "01", "WS_CRT_Slot", position + sizeX * 0.5, innerY + 1, hasSelected and activeColor or color_idle, TEXT_ALIGN_CENTER)

        local Ammout = 0
        local cursorY = innerY + headerH + pad
        for Id = 0, #slotTbl do
            local wep = slotTbl[Id]
            if not wep then continue end

            local selected = SelectedWep == wep
            local sizeH = selected and selH or rowH
            local boxY = cursorY
            local boxX = innerX
            local boxW = innerW

            if selected then
	            surface_SetDrawColor(activeR, activeG, activeB, a * 0.12)
	            surface_DrawRect(boxX, boxY, boxW, sizeH)
	            surface_SetDrawColor(activeR, activeG, activeB, a * 0.85)
	            surface_DrawOutlinedRect(boxX, boxY, boxW, sizeH, 1)
            end

            local label = WS.GetPrintName(wep) or ""
            local labelCol = selected and activeColor or (hasSelected and color_idle or color_idle_dim)
            local nameY = boxY + textPad
            local textX = boxX + textPad
            local textW = math_max(boxW - textPad * 2, 8)
            local clipL, clipR = boxX + textPad, boxX + boxW - textPad
            local clipBottom = boxY + math_min(rowH, sizeH) - 1

            if hasSelected then
                if selected then
                    local labelW = GetTextWidth("WS_CRT_Item", label)
                    local caretGap = 3
                    local caretX = textX
                    local nameX = caretX + caretWidth + caretGap
                    local nameW = math_max(boxX + boxW - textPad - nameX, 8)
                    local boxCenter = boxX + boxW * 0.5
                    local centeredCaretX = boxCenter - labelW * 0.5 - caretGap - caretWidth
                    local fitsCentered = centeredCaretX >= textX and (boxCenter + labelW * 0.5) <= boxX + boxW - textPad

                    if fitsCentered then
                        DrawStaticText(label, "WS_CRT_Item", boxX + textPad, nameY, textW, labelCol, true, clipL, boxY, clipR, clipBottom)
                        WS.DrawText(">", "WS_CRT_Item", centeredCaretX, nameY, activeColor, TEXT_ALIGN_LEFT)
                    else
                        DrawMarqueeText(label, "WS_CRT_Item", nameX, nameY, nameW, labelCol, i * 3 + Ammout, true, GetMarqueeStart(wep), nameX, boxY, clipR, clipBottom)
                        WS.DrawText(">", "WS_CRT_Item", caretX, nameY, activeColor, TEXT_ALIGN_LEFT)
                    end
                else
                    DrawMarqueeText(label, "WS_CRT_Item", textX, nameY, textW, labelCol, i * 3 + Ammout, false, GetMarqueeStart(wep), clipL, boxY, clipR, clipBottom)
                end
            else
	            DrawStaticText(label, "WS_CRT_Item", textX, nameY, textW, labelCol, true, clipL, boxY, clipR, clipBottom)
            end

            Ammout = Ammout + 1
            cursorY = cursorY + sizeH

            if selected then
                DrawWepIcon(wep, boxX + textPad, boxY + rowH, boxW - textPad * 2, sizeH - rowH - textPad, a)
                if wep.PrintWeaponInfo then
                    wep:PrintWeaponInfo(0, 0, a)
                end
            end
        end

        SuperAmmout = SuperAmmout + 1
    end
end

local tAcceptKeys = {
    ["slot1"] = 1,
    ["slot2"] = 2,
    ["slot3"] = 3,
    ["slot4"] = 4,
    ["slot5"] = 5,
    ["slot6"] = 6,
}

local function GetUpper(Weapons)
    if #LocalPlayer():GetWeapons() < 1 then return end
    WS.SelectedSlot = WS.SelectedSlot < 0 and #Weapons or WS.SelectedSlot - 1
    WS.SelectedSlotPos = Weapons[WS.SelectedSlot] and #Weapons[WS.SelectedSlot] or 0

    if Weapons[WS.SelectedSlot] == nil or Weapons[WS.SelectedSlot][WS.SelectedSlotPos] == nil then
        GetUpper(Weapons)
    end
end

local function GetDown(Weapons)
    if #LocalPlayer():GetWeapons() < 1 then return end
    WS.SelectedSlot = WS.SelectedSlot > #Weapons and 0 or WS.SelectedSlot + 1
    WS.SelectedSlotPos = 0

    if Weapons[WS.SelectedSlot] == nil or Weapons[WS.SelectedSlot][WS.SelectedSlotPos] == nil then
        GetDown(Weapons)
    end
end

local LastSelected = 0

local function get_active_tool(ply, tool)
    local activeWep = ply:GetActiveWeapon()
    if not IsValid(activeWep) or activeWep:GetClass() ~= "gmod_tool" or activeWep.Mode ~= tool then return end
    return activeWep:GetToolObject(tool)
end

local function canUseSelector(ply)
    local wep = ply:GetActiveWeapon()
    local tool = get_active_tool(ply, "submaterial")
    if tool and IsValid(ply:GetEyeTraceNoCursor().Entity) then
        return true
    end

    return IsAiming(ply) or (IsValid(wep) and wep:GetClass() == "weapon_physgun" and ply:KeyDown(IN_ATTACK)) or (lply.organism and lply.organism.pain and lply.organism.pain > 100) or GetGlobalBool("RadialInventory", false)
end

function WS.ConfirmSelection(ply)
    if WS.Selected and WS.Selected > CurTime() then return end

    local selectedWeapon = WS.GetSelectedWeapon()
    if IsValid(selectedWeapon) then
        WS.LastInv = WS.LastInv ~= ply:GetActiveWeapon() and WS.LastInv or ply:GetActiveWeapon()
        input.SelectWeapon(selectedWeapon)
    end

    WS.LastSelectedSlot = WS.SelectedSlot
    WS.LastSelectedSlotPos = WS.SelectedSlotPos
    WS.Selected = CurTime() + 0.2
    WS.Show = CurTime() + 0.2
    surface.PlaySound("arc9_eft_shared/weapon_generic_spin"..math.random(1,10)..".ogg")
end

function WS.ChangeSelectionWep( ply, key, pressed )
    if not IsValid( ply ) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end

    local attack = key == "+attack" and 1 or key == "+attack2" and 2 or nil
    if attack then
        local field = attack == 1 and "BlockAttackBind1" or "BlockAttackBind2"
        if pressed and WS.Show > CurTime() then
            WS[field] = true
            WS.ConfirmSelection(ply)
            net.Start("HG_WeaponSelectorConfirmed")
            net.WriteUInt(attack, 2)
            net.SendToServer()
            return true
        end

        if WS[field] then
            if not pressed then WS[field] = nil end
            return true
        end

        return
    end

    if ply.organism and ply.organism.otrub then return end
    if canUseSelector( ply ) then return end

    local iPos = tAcceptKeys[ key ]
    if iPos or key == "invnext" or key == "invprev" or key == "lastinv" then

        wepCacheBuilt = -1
        local Weapons = WS.GetWeaponTable( ply )

        WS.Show = CurTime() + 4
        net.Start("HG_WeaponSelectorOpened")
        net.SendToServer()
        surface.PlaySound("arc9_eft_shared/weapon_generic_rifle_spin"..math.random(10)..".ogg")
        if iPos then
            iPos = iPos - 1
            if LastSelected ~= iPos then
                WS.SelectedSlotPos = -1
            end
            WS.SelectedSlotPos = (Weapons[iPos] and LastSelected == iPos and WS.SelectedSlotPos + 1 > #Weapons[iPos] and 0 or math.min( WS.SelectedSlotPos + 1, #Weapons[iPos] )) or 0
            WS.SelectedSlot = iPos
            LastSelected = iPos
        elseif key == "invprev" then
            WS.SelectedSlotPos = WS.SelectedSlotPos - 1
            if Weapons[WS.SelectedSlot] and WS.SelectedSlotPos < 0  then
                GetUpper(Weapons)
            end
        elseif key == "invnext" then
            WS.SelectedSlotPos = WS.SelectedSlotPos + 1
            if Weapons[WS.SelectedSlot] and WS.SelectedSlotPos > #Weapons[WS.SelectedSlot] then
                GetDown(Weapons)
            end
        elseif key == "lastinv" and IsValid(WS.LastInv) then
            WS.Show = 0
            WS.LastInv = WS.LastInv or "weapon_hands_sh"
            local oldwep = ply:GetActiveWeapon()
            input.SelectWeapon( WS.LastInv )
            WS.LastInv = oldwep
        end

    end
end

function WS.SetActuallyWeapon( ply, cmd )
    local attack1 = cmd:KeyDown(IN_ATTACK)
    local attack2 = cmd:KeyDown(IN_ATTACK2)

    if WS.SuppressAttack1 then
        cmd:RemoveKey(IN_ATTACK)
        if not attack1 then WS.SuppressAttack1 = nil end
    end

    if WS.SuppressAttack2 then
        cmd:RemoveKey(IN_ATTACK2)
        if not attack2 then WS.SuppressAttack2 = nil end
    end

    if not IsValid( ply ) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end
    if (attack1 or attack2) and WS.Show > CurTime() then

        WS.SuppressAttack1 = attack1 or WS.SuppressAttack1
        WS.SuppressAttack2 = attack2 or WS.SuppressAttack2

        if WS.Selected and WS.Selected > CurTime() then
            cmd:RemoveKey(IN_ATTACK)
            cmd:RemoveKey(IN_ATTACK2)
        else
            cmd:RemoveKey(IN_ATTACK)
            cmd:RemoveKey(IN_ATTACK2)
            WS.ConfirmSelection(ply)
        end
    end
end

hook.Add( "PlayerBindPress", "WeaponSelector_PlayerBindPress", WS.ChangeSelectionWep )

hook.Add( "HUDPaint", "WeaponSelector_Draw", function()
    now = CurTime()
    if WS.Show < now then
        if not hiddenReset then
            WS.SelectedSlot = WS.LastSelectedSlot
            WS.SelectedSlotPos = -1
            hiddenReset = true
        end
        return
    end
    WS.WeaponSelectorDraw( LocalPlayer() )
end)

hook.Add( "StartCommand", "WeaponSelector_StartCommand", WS.SetActuallyWeapon )

local tHideElements = {
    ["CHudWeaponSelection"] = true
}

hook.Add("HUDShouldDraw", "WeaponSelector_HUDShouldDraw", function(sElementName)
    if tHideElements[sElementName] then return false end
end)
