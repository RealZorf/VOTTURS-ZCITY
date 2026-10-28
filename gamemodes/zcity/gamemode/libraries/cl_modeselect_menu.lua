if not CLIENT then return end

zb.availableModes = zb.availableModes or {}
zb.RoundList = zb.RoundList or {}
zb.nextround = zb.nextround or nil
zb.forcemode = zb.forcemode or "random"

local menuFrame
local CRT_R, CRT_G, CRT_B = 35, 225, 110
local TRAITOR_R, TRAITOR_G, TRAITOR_B = 225, 35, 35
local FRAME_R, FRAME_G, FRAME_B = 86, 94, 90
local GOLD_R, GOLD_G, GOLD_B = 220, 175, 55
local color_idle = Color(168, 172, 170)
local color_idle_dim = Color(112, 118, 116)
local color_bezel = Color(12, 13, 13)
local color_panel = Color(20, 22, 21)
local color_text = Color(236, 238, 236)
local color_gold = Color(GOLD_R, GOLD_G, GOLD_B)
local color_live = Color(CRT_R, CRT_G, CRT_B)
local color_danger = Color(TRAITOR_R, TRAITOR_G, TRAITOR_B)

local BEZEL = 3
local SND_CLICK = "shitty/tap_depress.wav"
local SND_RELEASE = "shitty/tap_release.wav"
local SND_HOVER = "shitty/tap-resonant.wav"

local allowedModes = {
	overstimulated = true, assassinsgreed = true, coop = true, criresp = true,
	tdm = true, cstrike = true, ww2 = true, defense = true, dm = true, event = true,
	fear = true, gwars = true, hmcd = true, hl2dm = true, hl3 = true, pathowogen = true,
	riot = true, tdmmelee = true, sandbox = true, scugarena = true,
	superfighters = true, zombiesurvival = true,
}

local function S(n)
	return math.max(1, math.Round(n * ScrH() / 1080))
end

local function CreateFonts()
	surface.CreateFont("ZC_MS_Title", {font = "Bahnschrift", size = math.max(18, S(24)), weight = 700, antialias = true, extended = true})
	surface.CreateFont("ZC_MS_Header", {font = "Bahnschrift", size = math.max(14, S(18)), weight = 700, antialias = true, extended = true})
	surface.CreateFont("ZC_MS_Item", {font = "Bahnschrift", size = math.max(13, S(17)), weight = 600, antialias = true, extended = true})
	surface.CreateFont("ZC_MS_Tiny", {font = "Bahnschrift", size = math.max(11, S(13)), weight = 500, antialias = true, extended = true})
end
CreateFonts()
hook.Add("OnScreenSizeChanged", "ZC_ModeSelect_Fonts", CreateFonts)

local function ClickSound(path)
	local ply = LocalPlayer()
	if IsValid(ply) then ply:EmitSound(path, 75, 100, 0.09) else surface.PlaySound(path) end
end

local function ForceActive()
	return zb.forcemode and zb.forcemode ~= "random" and zb.forcemode ~= ""
end

local function ModeName(key)
	for _, mode in ipairs(zb.availableModes) do
		if mode.key == key then return mode.name end
	end
	return key
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

local function DrawCRTFrame(x, y, w, h, selected)
	surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, 230)
	surface.DrawRect(x, y, w, h)
	local ix, iy, iw, ih = x + BEZEL, y + BEZEL, w - BEZEL * 2, h - BEZEL * 2
	surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, selected and 200 or 150)
	surface.DrawOutlinedRect(ix, iy, iw, ih, 1)
	DrawCRTCorners(ix, iy, iw, ih, 10, CRT_R, CRT_G, CRT_B, selected and 230 or 150)
	surface.SetDrawColor(color_panel.r, color_panel.g, color_panel.b, 210)
	surface.DrawRect(ix + 1, iy + 1, iw - 2, ih - 2)
end

local function DrawHeaderStrip(x, y, w, h, title)
	surface.SetDrawColor(32, 34, 33, 210)
	surface.DrawRect(x, y, w, h)
	surface.SetDrawColor(CRT_R, CRT_G, CRT_B, 36)
	surface.DrawRect(x, y, w, h)
	draw.SimpleText(title, "ZC_MS_Header", x + w * 0.5, y + h * 0.5, color_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function StyleScroll(scroll)
	local bar = scroll:GetVBar()
	bar:SetWide(S(8))
	bar:SetHideButtons(true)
	bar.Paint = function(_, w, h)
		surface.SetDrawColor(0, 0, 0, 70)
		surface.DrawRect(1, 0, w - 2, h)
	end
	bar.btnGrip.Paint = function(self, w, h)
		surface.SetDrawColor(self:IsHovered() and CRT_R or FRAME_R, self:IsHovered() and CRT_G or FRAME_G, self:IsHovered() and CRT_B or FRAME_B, self:IsHovered() and 180 or 130)
		surface.DrawRect(1, 0, w - 2, h)
	end
end

local function CRTButton(parent, label, accent)
	local btn = vgui.Create("DButton", parent)
	btn:SetText("")
	btn.Label = label
	btn.Accent = accent
	btn.Paint = function(self, w, h)
		local hover = self:IsHovered()
		local ac = self.Accent
		local r, g, b = FRAME_R, FRAME_G, FRAME_B
		if ac then r, g, b = ac.r, ac.g, ac.b elseif hover then r, g, b = CRT_R, CRT_G, CRT_B end
		surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, 230)
		surface.DrawRect(0, 0, w, h)
		if hover then
			surface.SetDrawColor(r, g, b, 28)
			surface.DrawRect(1, 1, w - 2, h - 2)
		end
		surface.SetDrawColor(r, g, b, hover and 210 or (ac and 150 or 130))
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.SimpleText(self.Label, "ZC_MS_Item", w * 0.5, h * 0.5, hover and color_text or (ac or color_idle), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btn.OnCursorEntered = function() ClickSound(SND_HOVER) end
	return btn
end

net.Receive("ZB_SendModesInfo", function()
	zb.availableModes = net.ReadTable()
	if IsValid(menuFrame) then menuFrame:RebuildModes() end
end)

net.Receive("ZB_SendRoundList", function()
	zb.RoundList = net.ReadTable()
	zb.nextround = net.ReadString()
	zb.forcemode = net.ReadString()
	if zb.nextround ~= "" then
		table.insert(zb.RoundList, 1, zb.nextround)
	end
	zb.nextround = nil
	if IsValid(menuFrame) then menuFrame:QueueUpdate() end
end)

net.Receive("ZB_NotifyRoundListChange", function()
	chat.AddText(Color(180, 180, 255), net.ReadString(), color_text, " has modified the game mode queue")
	net.Start("ZB_RequestRoundList")
	net.SendToServer()
end)

local function OpenModeSelect()
	if IsValid(menuFrame) then
		local open = menuFrame
		menuFrame = nil
		open:Close()
		return
	end

	local inset = BEZEL + S(4)
	local headerH = S(32)
	local rowH, rowGap = S(44), S(6)
	local stride = rowH + rowGap
	local frame = vgui.Create("ZFrame")
	menuFrame = frame
	frame:SetSize(math.Clamp(S(1100), 820, math.min(1280, ScrW() - S(40))), math.Clamp(S(720), 520, math.min(780, ScrH() - S(40))))
	frame:Center()
	frame:SetTitle("")
	frame:SetDraggable(true)
	frame:ShowCloseButton(false)
	frame:SetBorder(false)
	frame:SetColorBG(Color(8, 11, 10, 200))
	frame:MakePopup()
	frame:DockPadding(inset, inset, inset, inset)
	if IsValid(frame.lblTitle) then frame.lblTitle:SetVisible(false) end
	for _, key in ipairs({"btnClose", "btnMaxim", "btnMinim"}) do
		if IsValid(frame[key]) then frame[key]:SetVisible(false) end
	end
	frame.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, self.ColorBG)
		if hg.DrawBlur then hg.DrawBlur(self, 4) end
		DrawCRTFrame(0, 0, w, h, true)
	end

	local header = vgui.Create("DPanel", frame)
	header:Dock(TOP)
	header:SetTall(headerH)
	header:DockMargin(0, 0, 0, S(8))
	header:SetPaintBackground(false)
	header.Paint = function(_, w, h)
		DrawHeaderStrip(0, 0, w, h, "MODE SELECT")
	end

	local close = vgui.Create("DButton", header)
	close:SetSize(headerH, headerH)
	close:Dock(RIGHT)
	close:SetText("")
	close.Paint = function(self, w, h)
		local col = self:IsHovered() and color_danger or color_text
		local m = S(10)
		surface.SetDrawColor(col)
		surface.DrawLine(m, m, w - m, h - m)
		surface.DrawLine(w - m, m, m, h - m)
	end
	close.OnCursorEntered = function() ClickSound(SND_HOVER) end
	close.DoClick = function()
		ClickSound(SND_RELEASE)
		frame:Close()
	end

	local body = vgui.Create("DPanel", frame)
	body:Dock(FILL)
	body:SetPaintBackground(false)

	local left = vgui.Create("DPanel", body)
	left:Dock(LEFT)
	left:SetWide(math.floor(frame:GetWide() * 0.55) - S(8))
	left:DockMargin(0, 0, S(8), 0)
	left:SetPaintBackground(false)
	left.Paint = function(_, w, h) DrawCRTFrame(0, 0, w, h) end

	local leftHead = vgui.Create("DPanel", left)
	leftHead:Dock(TOP)
	leftHead:SetTall(headerH)
	leftHead:DockMargin(inset, inset, inset, S(6))
	leftHead:SetPaintBackground(false)
	leftHead.Paint = function(_, w, h) DrawHeaderStrip(0, 0, w, h, "AVAILABLE MODES") end

	local search = vgui.Create("DTextEntry", left)
	search:Dock(TOP)
	search:SetTall(S(28))
	search:DockMargin(inset, 0, inset, S(6))
	search:SetFont("ZC_MS_Item")
	search.Paint = function(self, w, h)
		surface.SetDrawColor(color_bezel)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, self:IsEditing() and 200 or 120)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		self:DrawTextEntryText(color_text, Color(CRT_R, CRT_G, CRT_B, 80), color_text)
		if self:GetText() == "" then
			draw.SimpleText("Search modes...", "ZC_MS_Item", S(8), h * 0.5, color_idle_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end

	local modeScroll = vgui.Create("DScrollPanel", left)
	modeScroll:Dock(FILL)
	modeScroll:DockMargin(inset, 0, inset, inset)
	StyleScroll(modeScroll)

	local queue = vgui.Create("DPanel", body)
	queue:Dock(FILL)
	queue:SetPaintBackground(false)
	queue.Paint = function(_, w, h) DrawCRTFrame(0, 0, w, h) end

	local queueHead = vgui.Create("DPanel", queue)
	queueHead:Dock(TOP)
	queueHead:SetTall(headerH)
	queueHead:DockMargin(inset, inset, inset, S(6))
	queueHead:SetPaintBackground(false)
	queueHead.Paint = function(_, w, h) DrawHeaderStrip(0, 0, w, h, "ROUND QUEUE") end

	local btnBar = vgui.Create("DPanel", queue)
	btnBar:Dock(BOTTOM)
	btnBar:SetTall(S(34))
	btnBar:DockMargin(inset, S(6), inset, inset)
	btnBar:SetPaintBackground(false)

	local applyBtn = CRTButton(btnBar, "APPLY", color_live)
	local clearBtn = CRTButton(btnBar, "CLEAR", color_gold)
	local endBtn = CRTButton(btnBar, "END ROUND", color_danger)
	btnBar.PerformLayout = function(self, w, h)
		local gap = S(6)
		local third = math.floor((w - gap * 2) / 3)
		applyBtn:SetPos(0, 0)
		applyBtn:SetSize(third, h)
		clearBtn:SetPos(third + gap, 0)
		clearBtn:SetSize(third, h)
		endBtn:SetPos(third * 2 + gap * 2, 0)
		endBtn:SetSize(w - third * 2 - gap * 2, h)
	end

	local queueList = vgui.Create("DPanel", queue)
	queueList:Dock(FILL)
	queueList:DockMargin(inset, 0, inset, 0)
	queueList:SetPaintBackground(false)
	queueList.rows = {}
	queueList.scroll, queueList.scrollTarget = 0, 0

	queueList.Paint = function(self, w, h)
		if #self.rows == 0 then
			draw.SimpleText("Queue empty — modes are picked at random.", "ZC_MS_Item", S(6), S(8), color_idle_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end
	end
	queueList.PaintOver = function(self, w, h)
		local contentH = #self.rows * stride
		if contentH <= h + 2 then return end
		local barH = math.max(S(24), h * (h / contentH))
		local maxScroll = contentH - h
		local barY = maxScroll > 0 and (self.scroll / maxScroll) * (h - barH) or 0
		surface.SetDrawColor(0, 0, 0, 70)
		surface.DrawRect(w - S(5), 0, S(4), h)
		surface.SetDrawColor(CRT_R, CRT_G, CRT_B, 160)
		surface.DrawRect(w - S(5), barY, S(4), barH)
	end
	queueList.OnMouseWheeled = function(self, delta)
		self.scrollTarget = self.scrollTarget - delta * stride
		return true
	end
	queueList.Think = function(self)
		local h, w = self:GetTall(), self:GetWide()
		local maxScroll = math.max(0, #self.rows * stride - h)
		if IsValid(self.dragging) then
			local _, my = self:LocalCursorPos()
			local desiredY = math.Clamp(my - self.grabDY, -rowH * 0.5, h - rowH * 0.5)
			self.dragging.animY = desiredY
			self.dragging:SetPos(0, desiredY)
			self.dragging:MoveToFront()
			local minIndex = ForceActive() and 2 or 1
			local newIndex = math.Clamp(math.Round((desiredY + self.scroll) / stride) + 1, minIndex, #self.rows)
			if newIndex ~= self.dragIndex then
				local row = table.remove(self.rows, self.dragIndex)
				table.insert(self.rows, newIndex, row)
				local key = table.remove(zb.RoundList, self.dragIndex)
				table.insert(zb.RoundList, newIndex, key)
				self.dragIndex = newIndex
				ClickSound(SND_HOVER)
			end
			if my < S(26) then self.scrollTarget = self.scrollTarget - 8 end
			if my > h - S(26) then self.scrollTarget = self.scrollTarget + 8 end
		end
		self.scrollTarget = math.Clamp(self.scrollTarget, 0, maxScroll)
		self.scroll = Lerp(FrameTime() * 12, self.scroll, self.scrollTarget)
		if math.abs(self.scroll - self.scrollTarget) < 0.4 then self.scroll = self.scrollTarget end
		for i, row in ipairs(self.rows) do
			if not IsValid(row) then continue end
			row.queueIndex = i
			if row:GetWide() ~= w then row:SetSize(w, rowH) end
			row:SetCursor((ForceActive() and i == 1) and "arrow" or "sizeall")
			if row ~= self.dragging then
				local targetY = (i - 1) * stride - self.scroll
				row.animY = Lerp(FrameTime() * 16, row.animY or targetY, targetY)
				if math.abs(row.animY - targetY) < 0.4 then row.animY = targetY end
				row:SetPos(0, row.animY)
			end
		end
	end

	local function MakeQueueRow(modeKey)
		local row = vgui.Create("DPanel", queueList)
		row:SetTall(rowH)
		row:SetCursor("sizeall")
		row.animY = 0
		row.Paint = function(self, w, h)
			local idx = self.queueIndex or 1
			local isNext, forced, dragging = idx == 1, idx == 1 and ForceActive(), queueList.dragging == self
			if dragging then
				surface.SetDrawColor(48, 52, 50, 250)
			elseif forced then
				surface.SetDrawColor(42, 36, 18, 235)
			elseif isNext then
				surface.SetDrawColor(18, 36, 26, 235)
			else
				surface.SetDrawColor(32, 34, 33, self:IsHovered() and 210 or 160)
			end
			surface.DrawRect(0, 0, w, h)
			local ar, ag, ab = FRAME_R, FRAME_G, FRAME_B
			if forced then ar, ag, ab = GOLD_R, GOLD_G, GOLD_B elseif isNext then ar, ag, ab = CRT_R, CRT_G, CRT_B end
			surface.SetDrawColor(ar, ag, ab, dragging and 210 or 140)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			if forced then
				surface.SetDrawColor(GOLD_R, GOLD_G, GOLD_B, 220)
				surface.DrawRect(S(10), h * 0.5 - S(4), S(10), S(8))
			else
				surface.SetDrawColor(dragging and 200 or 110, dragging and 200 or 110, dragging and 200 or 110)
				for gy = 0, 2 do
					for gx = 0, 1 do
						surface.DrawRect(S(10) + gx * S(5), h * 0.5 - S(7) + gy * S(6), S(3), S(3))
					end
				end
			end
			local tag = isNext and (forced and "FORCE" or "NEXT") or ("#" .. idx)
			draw.SimpleText(tag, "ZC_MS_Tiny", S(30), h * 0.5, forced and color_gold or (isNext and color_live or color_idle_dim), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(ModeName(modeKey), "ZC_MS_Item", S(84), h * 0.5, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
		row.OnMousePressed = function(self, code)
			if code ~= MOUSE_LEFT or (ForceActive() and (self.queueIndex or 1) == 1) then
				if code == MOUSE_LEFT then ClickSound(SND_RELEASE) end
				return
			end
			queueList.dragging, queueList.dragIndex = self, self.queueIndex
			local _, my = queueList:LocalCursorPos()
			queueList.grabDY = my - self.animY
			self:MouseCapture(true)
			ClickSound(SND_CLICK)
		end
		row.OnMouseReleased = function(self)
			if queueList.dragging == self then
				queueList.dragging, queueList.dragIndex = nil, nil
				self:MouseCapture(false)
				ClickSound(SND_RELEASE)
			end
		end
		local removeBtn = CRTButton(row, "X", color_danger)
		removeBtn:SetWide(S(28))
		removeBtn:Dock(RIGHT)
		removeBtn:DockMargin(S(4), S(8), S(8), S(8))
		removeBtn.Think = function(self)
			self:SetVisible(not (ForceActive() and (row.queueIndex or 1) == 1))
		end
		removeBtn.DoClick = function()
			if ForceActive() and (row.queueIndex or 1) == 1 then return end
			table.remove(zb.RoundList, row.queueIndex or 1)
			frame:QueueUpdate()
		end
		return row
	end

	function frame:RebuildModes()
		modeScroll:Clear()
		local filter = search:GetValue():lower()
		local ply = LocalPlayer()
		for _, mode in SortedPairsByMemberValue(zb.availableModes, "canlaunch", true) do
			if not ply:IsSuperAdmin() and not allowedModes[mode.key] then continue end
			if filter ~= "" and not string.find(string.lower(mode.name or ""), filter, 1, true) then continue end

			local row = vgui.Create("DPanel", modeScroll)
			row:Dock(TOP)
			row:SetTall(rowH)
			row:DockMargin(0, 0, 0, rowGap)
			row:SetTooltip((mode.description and mode.description ~= "" and mode.description) or mode.key)
			row.Paint = function(self, w, h)
				local forced = zb.forcemode == mode.key
				surface.SetDrawColor(32, 34, 33, self:IsHovered() and 210 or 160)
				surface.DrawRect(0, 0, w, h)
				surface.SetDrawColor(forced and GOLD_R or FRAME_R, forced and GOLD_G or FRAME_G, forced and GOLD_B or FRAME_B, 120)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
				local sr, sg, sb = TRAITOR_R, TRAITOR_G, TRAITOR_B
				local status = "BLOCKED"
				if forced then
					sr, sg, sb, status = GOLD_R, GOLD_G, GOLD_B, "FORCED"
				elseif mode.canlaunch == 1 then
					sr, sg, sb, status = CRT_R, CRT_G, CRT_B, "READY"
				end
				surface.SetDrawColor(sr, sg, sb, 220)
				surface.DrawRect(S(10), h * 0.5 - S(4), S(8), S(8))
				draw.SimpleText(mode.name, "ZC_MS_Item", S(28), h * 0.5 - S(6), color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				draw.SimpleText(status, "ZC_MS_Tiny", S(28), h * 0.5 + S(10), Color(sr, sg, sb), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end

			local force = vgui.Create("DButton", row)
			force:SetText("")
			force:SetWide(S(52))
			force:Dock(RIGHT)
			force:DockMargin(S(6), S(10), S(10), S(10))
			force:SetTooltip("Force this mode every round")
			force.Paint = function(self, w, h)
				local on = zb.forcemode == mode.key
				local hover = self:IsHovered()
				surface.SetDrawColor(color_bezel)
				surface.DrawRect(0, 0, w, h)
				surface.SetDrawColor(on and CRT_R or (hover and TRAITOR_R or FRAME_R), on and CRT_G or (hover and TRAITOR_G or FRAME_G), on and CRT_B or (hover and TRAITOR_B or FRAME_B), 180)
				surface.DrawOutlinedRect(0, 0, w, h, 1)
				local knob = h - S(8)
				surface.DrawRect(on and (w - knob - S(4)) or S(4), S(4), knob, knob)
			end
			force.OnCursorEntered = function() ClickSound(SND_HOVER) end
			force.DoClick = function()
				ClickSound(SND_CLICK)
				local target = zb.forcemode == mode.key and "random" or mode.key
				net.Start("AdminSetGameMode")
				net.WriteString("setforcemode")
				net.WriteString(target)
				net.WriteBool(false)
				net.SendToServer()
				zb.forcemode = target
				self:QueueUpdate()
			end

			local add = CRTButton(row, "+ QUEUE", color_live)
			add:SetWide(S(88))
			add:Dock(RIGHT)
			add:DockMargin(S(6), S(10), 0, S(10))
			add.DoClick = function()
				table.insert(zb.RoundList, mode.key)
				ClickSound(SND_CLICK)
				self:QueueUpdate()
			end
		end
	end

	function frame:QueueUpdate()
		for _, row in ipairs(queueList.rows) do
			if IsValid(row) then row:Remove() end
		end
		queueList.rows, queueList.dragging, queueList.dragIndex = {}, nil, nil
		local w = queueList:GetWide()
		for i, key in ipairs(zb.RoundList) do
			local row = MakeQueueRow(key)
			row.queueIndex = i
			row.animY = (i - 1) * stride - queueList.scroll
			row:SetSize(w, rowH)
			row:SetPos(0, row.animY)
			queueList.rows[i] = row
		end
		queueList.scrollTarget = math.Clamp(queueList.scrollTarget, 0, math.max(0, #zb.RoundList * stride - queueList:GetTall()))
	end

	search.OnChange = function() frame:RebuildModes() end
	applyBtn.DoClick = function()
		net.Start("ZB_UpdateRoundList")
		net.WriteTable(zb.RoundList)
		net.WriteBool(true)
		net.SendToServer()
		chat.AddText(color_live, "Game mode queue has been set.")
		ClickSound(SND_CLICK)
	end
	clearBtn.DoClick = function()
		zb.RoundList = {}
		frame:QueueUpdate()
		ClickSound(SND_CLICK)
		chat.AddText(color_gold, "Queue cleared locally. Press APPLY to save.")
	end
	endBtn.DoClick = function()
		ClickSound(SND_CLICK)
		net.Start("AdminEndRound")
		net.SendToServer()
		frame:Close()
	end

	frame.OnClose = function() menuFrame = nil end
	frame:RebuildModes()
	frame:QueueUpdate()
	net.Start("ZB_RequestRoundList")
	net.SendToServer()
end

hook.Add("InitPostEntity", "RequestModeData", function()
	if LocalPlayer():IsAdmin() then
		timer.Simple(2, function()
			net.Start("ZB_RequestRoundList")
			net.SendToServer()
		end)
	end
end)

hook.Add("PlayerButtonDown", "OpenAdminMenuF6", function(ply, key)
	if key ~= KEY_F6 or ply ~= LocalPlayer() or not ply:IsAdmin() then return end
	if not IsFirstTimePredicted() then return end
	OpenModeSelect()
end)
