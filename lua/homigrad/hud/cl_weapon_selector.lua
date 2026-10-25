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
local FRAME_R, FRAME_G, FRAME_B = 86, 94, 90
local GRAY_R, GRAY_G, GRAY_B = 148, 156, 150
local color_bezel = Color(12, 13, 13)
local color_panel = Color(20, 22, 21)
local color_text = Color(236, 238, 236)

local function S(n)
	return math.max(1, math.Round(n * ScrH() / 1080))
end

local function CreateCRTFonts()
	surface.CreateFont("WS_CRT_Slot", {
		font = "Bahnschrift",
		size = math.max(16, S(24)),
		weight = 700,
		antialias = true,
		extended = true
	})
	surface.CreateFont("WS_CRT_Item", {
		font = "Bahnschrift",
		size = math.max(12, S(17)),
		weight = 600,
		antialias = true,
		extended = true
	})
end

CreateCRTFonts()
hook.Add("OnScreenSizeChanged", "WeaponSelector_CRTFonts", CreateCRTFonts)

local function DrawCRTFrame(x, y, w, h, ar, ag, ab, selected, a, bezel)
	surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, a * 0.90)
	surface.DrawRect(x, y, w, h)

	local ix, iy, iw, ih = x + bezel, y + bezel, w - bezel * 2, h - bezel * 2
	local stroke = math.max(1, S(1))
	local thick = S(2)
	local len = S(10)
	surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, a * (selected and 0.78 or 0.59))
	surface.DrawOutlinedRect(ix, iy, iw, ih, stroke)

	local ca = a * (selected and 0.9 or 0.59)
	surface.SetDrawColor(ar, ag, ab, ca)
	surface.DrawRect(ix, iy, len, thick)
	surface.DrawRect(ix, iy, thick, len)
	surface.DrawRect(ix + iw - len, iy, len, thick)
	surface.DrawRect(ix + iw - thick, iy, thick, len)
	surface.DrawRect(ix, iy + ih - thick, len, thick)
	surface.DrawRect(ix, iy + ih - len, thick, len)
	surface.DrawRect(ix + iw - len, iy + ih - thick, len, thick)
	surface.DrawRect(ix + iw - thick, iy + ih - len, thick, len)

	surface.SetDrawColor(color_panel.r, color_panel.g, color_panel.b, a * 0.82)
	surface.DrawRect(ix + stroke, iy + stroke, iw - stroke * 2, ih - stroke * 2)
end

local function DrawText(text, font, x, y, col, a, align)
	surface.SetFont(font)
	local tw = surface.GetTextSize(text)
	if align == TEXT_ALIGN_CENTER then
		x = x - tw * 0.5
	elseif align == TEXT_ALIGN_RIGHT then
		x = x - tw
	end
	surface.SetTextColor(col.r, col.g, col.b, a)
	surface.SetTextPos(x, y)
	surface.DrawText(text)
end

local function DrawWepIcon(wep, x, y, wide, tall, alpha)
	if tall < 1 or wide < 1 then return end

	local iw, ih
	if wep.WepSelectIcon2box then
		local s = math.min(wide / 1.95, tall)
		iw, ih = s, s
	else
		ih = math.min(wide * 0.5, tall)
		iw = ih * 2
		if iw > wide then
			iw = wide
			ih = wide * 0.5
		end
	end
	x = x + (wide - iw) * 0.5
	y = y + math.max(0, (tall - ih) * 0.5)

	surface.SetDrawColor(255, 255, 255, alpha)
	local mat = wep.WepSelectIcon2
	if mat then
		if not wep.IconEdited then
			mat:SetInt("$flags", 32)
			wep.IconEdited = true
		end
		render.PushFilterMag(TEXFILTER.ANISOTROPIC)
		render.PushFilterMin(TEXFILTER.ANISOTROPIC)
		surface.SetMaterial(mat)
		surface.DrawTexturedRect(x, y, iw, ih)
		render.PopFilterMin()
		render.PopFilterMag()
		return
	end

	local icon = wep.WepSelectIcon
	if not icon then return end
	if isnumber(icon) then
		surface.SetTexture(icon)
	else
		surface.SetMaterial(icon)
	end
	surface.DrawTexturedRect(x, y, iw, ih)
end

local formattedSlots = {
	[0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {},
}
local slotCounts = { [0] = 0, 0, 0, 0, 0, 0 }

function WS.GetWeaponTable(ply)
	if not IsValid(ply) or not ply:Alive() then return end

	local weapons = ply:GetWeapons()
	table.sort(weapons, function(a, b)
		return (a.SlotPos or 0) > (b.SlotPos or 0)
	end)

	for i = 0, 5 do
		local slotTbl = formattedSlots[i]
		for k in pairs(slotTbl) do
			slotTbl[k] = nil
		end
		slotCounts[i] = 0
	end

	for i = 1, #weapons do
		local wep = weapons[i]
		local slot = wep.Slot or 0
		local tTbl = formattedSlots[slot]
		if tTbl then
			local iMinPos = math.min(wep.SlotPos or 1, #tTbl + 1) - 1
			local iPos = tTbl[iMinPos] and #tTbl + 1 or iMinPos
			tTbl[iPos] = wep
			slotCounts[slot] = slotCounts[slot] + 1
		end
	end

    return formattedSlots, slotCounts
end

function WS.GetSelectedWeapon(Weapons)
    local ply = LocalPlayer()
    if not IsValid( ply ) or not ply:Alive() then return end
    Weapons = Weapons or WS.GetWeaponTable( ply )
    if not Weapons then return end
    return Weapons[WS.SelectedSlot] and Weapons[WS.SelectedSlot][WS.SelectedSlotPos] or Weapons[WS.LastSelectedSlot][WS.LastSelectedSlotPos] or Weapons[0][0]
end

local hiddenReset = false

function WS.WeaponSelectorDraw(ply)
	if not IsValid(ply) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end

	local now = CurTime()
	if WS.Show < now then
		if not hiddenReset then
			WS.SelectedSlot = WS.LastSelectedSlot
			WS.SelectedSlotPos = -1
			WS.MarqueeWep = nil
			hiddenReset = true
		end
		return
	end
	hiddenReset = false

	local Weapons, counts = WS.GetWeaponTable(ply)
	local SelectedWep = WS.GetSelectedWeapon(Weapons)
	if not IsValid(SelectedWep) then return end

	WS.Transparent = LerpFT(0.2, WS.Transparent, math.min(WS.Show - now, 1))
	local a = math.Clamp(WS.Transparent * 255, 0, 255)

	local ar, ag, ab = CRT_R, CRT_G, CRT_B
	if ply.isTraitor then
		ar, ag, ab = TRAITOR_R, TRAITOR_G, TRAITOR_B
	end

	if WS.MarqueeWep ~= SelectedWep then
		WS.MarqueeWep = SelectedWep
		WS.MarqueeStart = now
	end

	local sw = ScrW()
	local bezel = S(3)
	local pad = S(4)
	local textPad = S(4)
	local gap = S(8)
	local sizeX = S(192)
	local rowH = S(27)
	local selH = S(129)
	local headerH = S(24)
	local topY = S(19)
	local extraSel = selH - rowH
	local stroke = math.max(1, S(1))

	surface.SetFont("WS_CRT_Slot")
	local _, slotNumH = surface.GetTextSize("1")

	local slotN = 0
	for i = 0, 5 do
		if (counts[i] or 0) > 0 then
			slotN = slotN + 1
		end
	end

	local originX = math.floor(sw * 0.5 - (slotN * sizeX + math.max(slotN - 1, 0) * gap) * 0.5)
	local colI = 0
	local selectedSlot = SelectedWep.Slot or 0

	for i = 0, 5 do
		local itemCount = counts[i] or 0
		if itemCount < 1 then continue end

		local slotTbl = Weapons[i]
		local x = originX + colI * (sizeX + gap)
		local selectedCol = selectedSlot == i
		local itemsH = itemCount * rowH + (selectedCol and extraSel or 0)
		local colH = bezel * 2 + pad + headerH + pad + itemsH + pad

		DrawCRTFrame(x, topY, sizeX, colH, selectedCol and ar or GRAY_R, selectedCol and ag or GRAY_G, selectedCol and ab or GRAY_B, selectedCol, a, bezel)

		local innerX = x + bezel + pad
		local innerY = topY + bezel + pad
		local innerW = sizeX - (bezel + pad) * 2

		if selectedCol then
    		surface.SetDrawColor(ar, ag, ab, a * 0.12)
		else
    		surface.SetDrawColor(64, 70, 68, a * 0.62)
		end
		surface.DrawRect(innerX, innerY, innerW, headerH)
		DrawText(tostring(i + 1), "WS_CRT_Slot", x + sizeX * 0.5, innerY + (headerH - slotNumH) * 0.5, color_text, a, TEXT_ALIGN_CENTER)

		local cursorY = innerY + headerH + pad
		for id = 0, #slotTbl do
			local wep = slotTbl[id]
			if not wep then continue end

			local selected = SelectedWep == wep
			local sizeH = selected and selH or rowH

			if selected then
				surface.SetDrawColor(ar, ag, ab, a * 0.12)
				surface.DrawRect(innerX, cursorY, innerW, sizeH)
				surface.SetDrawColor(ar, ag, ab, a * 0.85)
				surface.DrawOutlinedRect(innerX, cursorY, innerW, sizeH, stroke)
			end

			local class = wep:GetClass()
			local phrase = language.GetPhrase(class)
			local label = (phrase ~= class and phrase or wep:GetPrintName()) or ""
			local textY = cursorY + textPad
			local textX = innerX + textPad
			local textW = innerW - textPad * 2
			local clipB = cursorY + math.min(rowH, sizeH)

			surface.SetFont("WS_CRT_Item")
			local tw = surface.GetTextSize(label)

			render.SetScissorRect(textX, cursorY, textX + textW, clipB, true)
			if selected and tw > textW then
				local gapW = math.max(S(24), math.floor(textW * 0.35))
				local cycle = tw + gapW
				local travel = cycle / 42
				local t = math.max(now - (WS.MarqueeStart or now), 0) % (travel + 0.55)
				local offset = t < 0.55 and 0 or ((t - 0.55) / travel) * cycle
				DrawText(label, "WS_CRT_Item", textX - offset, textY, color_text, a, TEXT_ALIGN_LEFT)
				DrawText(label, "WS_CRT_Item", textX - offset + cycle, textY, color_text, a, TEXT_ALIGN_LEFT)
			else
				DrawText(label, "WS_CRT_Item", innerX + innerW * 0.5, textY, color_text, a, TEXT_ALIGN_CENTER)
			end
			render.SetScissorRect(0, 0, 0, 0, false)

			if selected then
				local iconY = cursorY + rowH
				local iconH = cursorY + sizeH - textPad - iconY
				render.SetScissorRect(innerX + stroke, cursorY + stroke, innerX + innerW - stroke, cursorY + sizeH - stroke, true)
				DrawWepIcon(wep, innerX + textPad, iconY, innerW - textPad * 2, iconH, a)
				render.SetScissorRect(0, 0, 0, 0, false)
				if wep.PrintWeaponInfo then
					wep:PrintWeaponInfo(0, 0, a)
				end
			end

			cursorY = cursorY + sizeH
		end

		colI = colI + 1
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

local function canUseSelector(ply)
	local wep = ply:GetActiveWeapon()
	if IsValid(wep) and wep:GetClass() == "gmod_tool" and wep.Mode == "submaterial" then
		local tool = wep:GetToolObject("submaterial")
		if tool and IsValid(ply:GetEyeTraceNoCursor().Entity) then
			return true
		end
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
	surface.PlaySound("arc9_eft_shared/weapon_generic_spin" .. math.random(1, 10) .. ".ogg")
end

function WS.ChangeSelectionWep(ply, key, pressed)
	if not IsValid(ply) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end

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
	if canUseSelector(ply) then return end

	local iPos = tAcceptKeys[key]
	if iPos or key == "invnext" or key == "invprev" or key == "lastinv" then
		local Weapons = WS.GetWeaponTable(ply)

		WS.Show = CurTime() + 4
		net.Start("HG_WeaponSelectorOpened")
		net.SendToServer()
		surface.PlaySound("arc9_eft_shared/weapon_generic_rifle_spin" .. math.random(10) .. ".ogg")
		if iPos then
			iPos = iPos - 1
			if LastSelected ~= iPos then
				WS.SelectedSlotPos = -1
			end
			WS.SelectedSlotPos = (Weapons[iPos] and LastSelected == iPos and WS.SelectedSlotPos + 1 > #Weapons[iPos] and 0 or math.min(WS.SelectedSlotPos + 1, #Weapons[iPos])) or 0
			WS.SelectedSlot = iPos
			LastSelected = iPos
		elseif key == "invprev" then
			WS.SelectedSlotPos = WS.SelectedSlotPos - 1
			if Weapons[WS.SelectedSlot] and WS.SelectedSlotPos < 0 then
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
			input.SelectWeapon(WS.LastInv)
			WS.LastInv = oldwep
		end
	end
end

function WS.SetActuallyWeapon(ply, cmd)
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

	if not IsValid(ply) or not ply:Alive() or GetGlobalBool("RadialInventory", false) then return end
	if (attack1 or attack2) and WS.Show > CurTime() then
		WS.SuppressAttack1 = attack1 or WS.SuppressAttack1
		WS.SuppressAttack2 = attack2 or WS.SuppressAttack2

		cmd:RemoveKey(IN_ATTACK)
		cmd:RemoveKey(IN_ATTACK2)
		if not (WS.Selected and WS.Selected > CurTime()) then
			WS.ConfirmSelection(ply)
		end
	end
end

hook.Add("PlayerBindPress", "WeaponSelector_PlayerBindPress", WS.ChangeSelectionWep)
hook.Add("HUDPaint", "WeaponSelector_Draw", function()
	WS.WeaponSelectorDraw(LocalPlayer())
end)
hook.Add("StartCommand", "WeaponSelector_StartCommand", WS.SetActuallyWeapon)
hook.Add("HUDShouldDraw", "WeaponSelector_HUDShouldDraw", function(name)
	if name == "CHudWeaponSelection" then return false end
end)
