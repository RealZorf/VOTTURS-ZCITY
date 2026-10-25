--made by mrrp :3

local maxLength = GetConVar("zchat_maxmessagelength")

local NoDrop = CreateClientConVar("zchat_dropcharacters", 1, true, false, "Play the character dropping animation when erasing text", 0, 1)
local ShowTextBoxInactive = CreateClientConVar("zchat_showtextboxinactive", 1, true, false, "Showing your text in textbox while chat is turned off", 0, 1)

local CRT_R, CRT_G, CRT_B = 35, 225, 110
local FRAME_R, FRAME_G, FRAME_B = 86, 94, 90
local color_bezel = Color(12, 13, 13)
local color_panel = Color(20, 22, 21)
local color_text = Color(236, 238, 236)
local color_idle_dim = Color(112, 118, 116)
local color_radio = Color(35, 225, 110)

local function S(n)
	return math.max(1, math.Round(ScreenScale(n)))
end

local function DrawCRTFrame(x, y, w, h, selected)
	local bezel = math.max(2, S(1))
	surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, 230)
	surface.DrawRect(x, y, w, h)

	local ix, iy, iw, ih = x + bezel, y + bezel, w - bezel * 2, h - bezel * 2
	surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, selected and 200 or 150)
	surface.DrawOutlinedRect(ix, iy, iw, ih, 1)

	local len, a = math.max(6, S(4)), selected and 230 or 150
	surface.SetDrawColor(CRT_R, CRT_G, CRT_B, a)
	surface.DrawRect(ix, iy, len, 2)
	surface.DrawRect(ix, iy, 2, len)
	surface.DrawRect(ix + iw - len, iy, len, 2)
	surface.DrawRect(ix + iw - 2, iy, 2, len)
	surface.DrawRect(ix, iy + ih - 2, len, 2)
	surface.DrawRect(ix, iy + ih - len, 2, len)
	surface.DrawRect(ix + iw - len, iy + ih - 2, len, 2)
	surface.DrawRect(ix + iw - 2, iy + ih - len, 2, len)

	surface.SetDrawColor(color_panel.r, color_panel.g, color_panel.b, 210)
	surface.DrawRect(ix + 1, iy + 1, iw - 2, ih - 2)
end

local function PaintMarkupOverride(text, font, x, y, color, alignX, alignY, alpha)
	alpha = alpha or 255

	surface.SetFont(font)
	surface.SetTextPos(x + 1, y + 1)
	surface.SetTextColor(0, 0, 0, alpha)
	surface.DrawText(text)

	surface.SetTextPos(x, y)
	surface.SetTextColor(color.r, color.g, color.b, alpha)
	surface.DrawText(text)
end

local PANEL = {}

function PANEL:Init()
	self.text = ""
	self.alpha = 0
	self.fadeDelay = 15
	self.fadeDuration = 5
	self.yAnimDuration = 1
	self.yAnim = 5
end

function PANEL:SetMarkup(text)
	self.text = text
	self.markup = hg.markup.Parse(self.text, math.max(self:GetWide() - S(6), 80))
	self.markup.onDrawText = PaintMarkupOverride
	self:SetTall(math.max(self.markup:GetHeight() + S(3), S(8)))

	timer.Simple(self.fadeDelay, function()
		if (!IsValid(self)) then
			return
		end

		self:CreateAnimation(self.fadeDuration, {
			index = 3,
			target = {alpha = 0}
		})
	end)

	self:CreateAnimation(self.yAnimDuration, {
		index = 4,
		target = {yAnim = 0},
		easing = "outQuint"
	})

	self:CreateAnimation(0.5, {
		index = 3,
		target = {alpha = 255},
	})
end

function PANEL:PerformLayout(width, height)
	self.markup = hg.markup.Parse(self.text, math.max(width - S(6), 80))
	self.markup.onDrawText = PaintMarkupOverride
	self:SetTall(math.max(self.markup:GetHeight() + S(3), S(8)))
end

function PANEL:Paint(width, height)
	local newAlpha

	if (hg.chat:GetActive()) then
		newAlpha = math.max(hg.chat.alpha, self.alpha)
	else
		newAlpha = self.alpha - (255 - hg.chat.realAlpha)
	end

	DisableClipping(true)
		local history = hg.chat.history
		local clipX, clipY = hg.chat:GetPos()
		local clipW, clipH = hg.chat:GetSize()
		if IsValid(history) then
			clipX, clipY = history:LocalToScreen(0, 0)
			clipW, clipH = history:GetSize()
		end

		local hover = hg.chat:GetActive() and self:IsHovered()
		local rowAlpha = math.Clamp(newAlpha, 0, 255)
		local stripY = math.floor(self.yAnim)

		render.SetScissorRect(clipX, clipY, clipX + clipW, clipY + clipH, true)
			if hover then
				surface.SetDrawColor(FRAME_R, FRAME_G, FRAME_B, 36 * (rowAlpha / 255))
				surface.DrawRect(0, stripY, width, height)
				surface.SetDrawColor(CRT_R, CRT_G, CRT_B, 24 * (rowAlpha / 255))
				surface.DrawRect(0, stripY, 2, height)
			end

			self.markup:draw(S(3), math.floor(stripY + (height - self.markup:GetHeight()) * 0.5), nil, nil, newAlpha)
		render.SetScissorRect(0, 0, 0, 0, false)
	DisableClipping(false)
end

vgui.Register("zChatMessage", PANEL, "Panel")

PANEL = {}

DEFINE_BASECLASS("DTextEntry")

function PANEL:Init()
	self:SetFont("zChatFont")
	self:SetUpdateOnType(true)
	self:SetHistoryEnabled(true)

	self.History = hg.chat.messageHistory
	self.droppedCharacters = {}
	self.prevText = ""
	self.scrollX = 0

	self:SetTextColor(color_text)
	self:SetPaintBackground(false)
	self:SetTextInset(S(8), 0)

	self.m_bLoseFocusOnClickAway = false
end

function PANEL:AllowInput(newCharacter)
	local text = self:GetText()
	local maxLen = maxLength:GetInt()

	-- we can't check for the proper length using utf-8 since AllowInput is called for single bytes instead of full characters
	if (string.len(text .. newCharacter) > maxLen) then
		surface.PlaySound("common/talk.wav")
		return true
	end
end

function PANEL:Think()
	local text = self:GetText()
	local maxLen = maxLength:GetInt()

	if (text:utf8len() > maxLen) then
		local newText = text:utf8sub(0, maxLen)

		self:SetText(newText)
		self:SetCaretPos(newText:utf8len())
	end
end

function PANEL:Paint(w, h)
	local active = hg.chat and hg.chat:GetActive()
	local showInactiveDraft = ShowTextBoxInactive:GetBool() and not active and self.prevText != ""

	if not active and not showInactiveDraft then return end

	DrawCRTFrame(0, 0, w, h, active)

	local inset = S(8)
	draw.SimpleText(">", "zChatFont", math.floor(inset * 0.55), h * 0.5, active and Color(CRT_R, CRT_G, CRT_B) or color_idle_dim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local drawText = active and self:GetText() or self.prevText
	surface.SetFont("zChatFont")
	local _, textH = surface.GetTextSize("Hg")
	local textY = math.floor((h - textH) * 0.5)
	local viewW = math.max(1, w - inset - S(3))
	local caretText = drawText:utf8sub(0, active and self:GetCaretPos() or drawText:utf8len()) or string.sub(drawText, 1, active and self:GetCaretPos() or #drawText)
	local caretW = surface.GetTextSize(caretText)
	local totalW = surface.GetTextSize(drawText)
	local scroll = self.scrollX or 0

	if caretW - scroll > viewW - 2 then
		scroll = caretW - viewW + 2
	elseif caretW - scroll < 0 then
		scroll = caretW
	end
	scroll = math.Clamp(scroll, 0, math.max(0, totalW - viewW + 2))
	self.scrollX = scroll

	local textX = inset - scroll
	local screenX, screenY = self:LocalToScreen(inset, 0)

	render.SetScissorRect(screenX, screenY, screenX + viewW, screenY + h, true)
		surface.SetTextColor(color_text.r, color_text.g, color_text.b, active and 255 or 65)
		surface.SetTextPos(textX, textY)
		surface.DrawText(drawText)

		if active and math.floor(CurTime() * 2) % 2 == 0 then
			surface.SetDrawColor(CRT_R, CRT_G, CRT_B, 220)
			surface.DrawRect(textX + caretW + 1, textY + 2, 1, textH - 4)
		end
	render.SetScissorRect(0, 0, 0, 0, false)

	for k, v in ipairs(self.droppedCharacters) do
		v.velocityY = v.velocityY + (5 * FrameTime())
		v.y = v.y + v.velocityY
		v.x = v.x + v.velocityX
		v.alpha = v.alpha - FrameTime() * 750

		DisableClipping(true)
			surface.SetTextColor(150, 150, 150, v.alpha)
			surface.SetTextPos(v.x, v.y)
			surface.SetFont("zChatFont")
			surface.DrawText(v.text)
		DisableClipping(false)

		if v.alpha <= 0 then
			table.remove(self.droppedCharacters, k)
		end
	end
end

function PANEL:OnValueChange(text)
	local prevText = self.prevText

	if NoDrop:GetBool() then
		local len1, len2 = string.utf8len(prevText), string.utf8len(text)

		if len1 > len2 then
			local droppedText = string.utf8sub(prevText, self:GetCaretPos() + 1, self:GetCaretPos() + (len1 - len2))

			for _, v in ipairs(string.Explode(utf8.charpattern, droppedText)) do
				surface.SetFont("zChatFont")
				table.insert(self.droppedCharacters, {
					text = v,
					x = surface.GetTextSize(v) * self:GetCaretPos(),
					y = S(3),
					velocityX = math.Rand(-0.1, 0.1),
					velocityY = -1,
					alpha = 255
				})
			end
		end
	end

	self.prevText = text
end

vgui.Register("zChatboxEntry", PANEL, "DTextEntry")

PANEL = {}

AccessorFunc(PANEL, "bActive", "Active", FORCE_BOOL)
AccessorFunc(PANEL, "realAlpha", "RealAlpha", FORCE_BOOL)

function PANEL:Init()
	hg.chat = self

	self.entries = {}
	self.messageHistory = {}

	self.alpha = 255
	self.realAlpha = 255
	self.lastScreenW = 0
	self.lastScreenH = 0
	self.lastActiveState = nil
	self.lastDraftState = nil

	self.entryPanel = self:Add("Panel")
	self.entryPanel:SetZPos(1)
	self.entryPanel:Dock(BOTTOM)

	self.entry = self.entryPanel:Add("zChatboxEntry")
	self.entry:Dock(FILL)
	self.entry.OnEnter = function()
		self:OnMessageSent()
	end

	self.history = self:Add("DScrollPanel")
	self.history:Dock(FILL)
	self.history:SetPaintedManually(true)
	self:ApplyChatBounds(true)

	local bar = self.history:GetVBar()
	bar.Paint = function() end
	bar.btnUp.Paint = function() end
	bar.btnDown.Paint = function() end
	bar.btnGrip.Paint = function(grip, w, h)
		local hovered = grip:IsHovered()
		surface.SetDrawColor(hovered and CRT_R or FRAME_R, hovered and CRT_G or FRAME_G, hovered and CRT_B or FRAME_B, hovered and 200 or 130)
		surface.DrawRect(0, 0, w, h)
	end

	self:SetActive(false)
end

function PANEL:ApplyChatBounds(force)
	local sw, sh = ScrW(), ScrH()
	local active = self:GetActive()
	local showDraft = IsValid(self.entry) and ShowTextBoxInactive:GetBool() and self.entry.prevText != ""
	local expanded = active or showDraft

	if not force and self.lastScreenW == sw and self.lastScreenH == sh and self.lastActiveState == active and self.lastDraftState == showDraft then return end

	self.lastScreenW = sw
	self.lastScreenH = sh
	self.lastActiveState = active
	self.lastDraftState = showDraft

	local pad = math.max(6, S(3))
	local targetW = math.floor(sw * (expanded and 0.34 or 0.30))
	local targetH = math.floor(sh * (expanded and 0.26 or 0.20))

	self:SetSize(targetW, targetH)
	self:SetPos(math.floor(sw * 0.018), math.floor(sh - targetH - sh * 0.105))

	if IsValid(self.history) then
		self.history:DockMargin(pad, pad, pad, math.max(4, S(2)))
		local bar = self.history:GetVBar()
		if IsValid(bar) then
			bar:SetWide(math.max(4, S(2)))
		end
	end

	if IsValid(self.entryPanel) then
		self.entryPanel:DockMargin(pad, 0, pad, pad)
		self.entryPanel:SetTall((active or showDraft) and (active and math.max(24, S(12)) or math.max(20, S(9))) or 0)
		self.entryPanel:SetVisible(active or showDraft)
	end

	if IsValid(self.history) and not active then
		self:ScrollHistoryToBottom()
	end
end

function PANEL:ScrollHistoryToBottom()
	if not IsValid(self.history) then return end

	self.history:InvalidateLayout(true)

	timer.Simple(0, function()
		if not IsValid(self) or not IsValid(self.history) then return end

		self.history:InvalidateLayout(true)

		local bar = self.history:GetVBar()
		if IsValid(bar) then
			bar:SetScroll(bar.CanvasSize)
		end

		timer.Simple(0, function()
			if not IsValid(self) or not IsValid(self.history) then return end

			local nextBar = self.history:GetVBar()
			if IsValid(nextBar) then
				nextBar:SetScroll(nextBar.CanvasSize)
			end
		end)
	end)
end

function PANEL:Think()
	self:ApplyChatBounds(false)
end

function PANEL:Paint(w, h)
	local active = self:GetActive()
	if active then
		DrawCRTFrame(0, 0, w, h, true)
	end

	surface.SetAlphaMultiplier(1)
		self.history:PaintManual()
		self.history:GetVBar():SetAlpha(self:GetAlpha())
	surface.SetAlphaMultiplier(self:GetAlpha() / 255)

	DisableClipping(true)
		local whisperHint = "Hold left ALT and press ENTER to whisper"
		local radioHint
		local activeWeapon = LocalPlayer():GetActiveWeapon()
		if IsValid(activeWeapon) and activeWeapon:GetClass() == "weapon_walkie_talkie" and activeWeapon:GetIsOn() then
			whisperHint = "Hold left ALT and press ENTER to whisper and radio "
			radioHint = string.format("[%.1f MHz]", math.Round(activeWeapon:GetHudFrequency(), 1))
		end

		local hintY = h + S(2)
		draw.SimpleText(whisperHint, "zChatFontSmall", 5, hintY + 1, color_bezel)
		draw.SimpleText(whisperHint, "zChatFontSmall", 4, hintY, color_idle_dim)

		if radioHint then
			surface.SetFont("zChatFontSmall")
			local hintWidth = surface.GetTextSize(whisperHint)
			draw.SimpleText(radioHint, "zChatFontSmall", 5 + hintWidth, hintY + 1, color_bezel)
			draw.SimpleText(radioHint, "zChatFontSmall", 4 + hintWidth, hintY, color_radio)
		end

		if LocalPlayer().organism and LocalPlayer().organism.otrub then
			draw.SimpleText("Your messages are currently not visible to anyone.", "zChatFontSmall", ScrW() * 0.3 + 1, hintY + 1, color_bezel, TEXT_ALIGN_RIGHT)
			draw.SimpleText("Your messages are currently not visible to anyone.", "zChatFontSmall", ScrW() * 0.3, hintY, color_idle_dim, TEXT_ALIGN_RIGHT)
		end
	DisableClipping(false)

	if self.bActive then
		self:SetAlpha(self.alpha - (255 - self.realAlpha))
	end

	surface.SetAlphaMultiplier(1)
end

function PANEL:SetActive(bActive, bRemovePrev)
	self.bActive = bActive
	self:ApplyChatBounds(true)

	if (bActive) then
		self:SetAlpha(255)
		self:MakePopup()
		self.entry:RequestFocus()

		input.SetCursorPos(self:LocalToScreen(S(4), self:GetTall() + S(4)))

		hook.Run("StartChat")
	else
		self:SetAlpha(0)
		self:SetMouseInputEnabled(false)
		self:SetKeyboardInputEnabled(false)

		if bRemovePrev then
			self.entry:SetText("")
			self.entry.prevText = ""
		end

		gui.EnableScreenClicker(false)

		hook.Run("FinishChat")
	end

	local bar = self.history:GetVBar()
	bar:SetScroll(bar.CanvasSize)
	self:ScrollHistoryToBottom()
end

function PANEL:AnimateAlpha(newAlpha)
	self:CreateAnimation(1, {
		index = 1,
		target = {alpha = newAlpha},
	})
end

function PANEL:AnimateRealAlpha(newAlpha)
	self:CreateAnimation(1, {
		index = 2,
		target = {realAlpha = newAlpha},
	})
end

function PANEL:SetRealAlpha(alpha)
	self.realAlpha = alpha
end

function PANEL:OnMessageSent()
	local text = self.entry:GetText()

	if (text:find("%S")) then
		local lastEntry = hg.chat.messageHistory[#hg.chat.messageHistory]

		-- only add line to textentry history if it isn't the same message
		if (lastEntry != text) then
			if (#hg.chat.messageHistory >= 20) then
				table.remove(hg.chat.messageHistory, 1)
			end

			hg.chat.messageHistory[#hg.chat.messageHistory + 1] = text
		end

		net.Start("zChatMessage")
			net.WriteString(text)
		net.SendToServer()
	end

	self:SetActive(false, true)
end

function PANEL:AddLine(elements)
	local buffer = {
		"<font=zChatFont>"
	}

	buffer = hook.Run("ModifyMessageBuffer", buffer, CHAT_SPEAKER) or buffer

	for _, v in ipairs(elements) do
		if (type(v) == "IMaterial") then
			local texture = v:GetName()

			if (texture) then
				buffer[#buffer + 1] = string.format("<img=%s,%dx%d> ", texture, v:Width(), v:Height())
			end
		elseif (istable(v) and v.r and v.g and v.b) then
			buffer[#buffer + 1] = string.format("<color=%d,%d,%d>", v.r, v.g, v.b)
		elseif (type(v) == "Player") then
			local color = team.GetColor(v:Team())

			buffer[#buffer + 1] = string.format("<color=%d,%d,%d>%s", color.r, color.g, color.b,
				v:GetName():gsub("<", "&lt;"):gsub(">", "&gt;"))
		else
			buffer[#buffer + 1] = tostring(v):gsub("<", "&lt;"):gsub(">", "&gt;")
		end
	end

	local panel = self.history:Add("zChatMessage")
	panel:Dock(TOP)
	panel:InvalidateParent(true)
	panel:SetMarkup(table.concat(buffer))

	if (#self.entries >= 100) then
		local oldPanel = table.remove(self.entries, 1)

		if (IsValid(oldPanel)) then
			oldPanel:Remove()
		end
	end

	local bar = self.history:GetVBar()
	if !self:GetActive() or bar.Scroll >= bar.CanvasSize - 2 then
		self:ScrollHistoryToBottom()
	end

	self.entries[#self.entries + 1] = panel
	return panel
end

function PANEL:AddMessage(...)
	self:AddLine({...})

	chat.PlaySound()
end

vgui.Register("zChatbox", PANEL, "EditablePanel")
