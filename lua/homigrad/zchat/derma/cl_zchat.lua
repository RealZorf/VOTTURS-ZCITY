--made by mrrp :3

local maxLength = GetConVar("zchat_maxmessagelength")

local NoDrop = CreateClientConVar("zchat_dropcharacters", 1, true, false, "Play the character dropping animation when erasing text", 0, 1)
local ShowTextBoxInactive = CreateClientConVar("zchat_showtextboxinactive", 1, true, false, "Showing your text in textbox while chat is turned off", 0, 1)

local chatMatGradD = Material("vgui/gradient-d")
local chatMatGradL = Material("vgui/gradient-l")
local chatMatGradR = Material("vgui/gradient-r")
local radioHintColor = Color(35, 255, 110)
local radioHintOutline = Color(0, 48, 22)

local chatCols = {
	bg = Color(4, 13, 9, 222),
	bgActive = Color(6, 19, 13, 238),
	panel = Color(7, 28, 18, 166),
	panelActive = Color(10, 38, 25, 204),
	accent = Color(35, 225, 110, 230),
	accentSoft = Color(35, 255, 110, 45),
	line = Color(35, 255, 110, 120),
	textSoft = Color(185, 220, 198, 145),
	row = Color(0, 0, 0, 54),
	rowHover = Color(35, 255, 110, 24),
	input = Color(3, 16, 10, 225),
	inputActive = Color(5, 32, 19, 240)
}

local chatStyles = {
	normal = {accent = Color(35, 225, 110), chip = nil},
	dead = {accent = Color(255, 54, 54), chip = "DEAD"},
	whisper = {accent = Color(160, 135, 255), chip = "WHISPER"},
	join = {accent = Color(70, 255, 145), chip = "JOIN"},
	leave = {accent = Color(255, 170, 75), chip = "LEAVE"},
	vote = {accent = Color(0, 220, 170), chip = "VOTE"},
	boost = {accent = Color(235, 255, 35), chip = "BOOST"},
	karma = {accent = Color(160, 255, 95), chip = "KARMA"},
	death = {accent = Color(255, 65, 65), chip = "KILL"},
	warning = {accent = Color(255, 95, 65), chip = "WARN"}
}

local function CallbackBind(self, callback)
	return function(_, ...)
		return callback(self, ...)
	end
end

local function DrawChatCutPoly(x, y, w, h, cut, col)
	surface.SetDrawColor(col)
	draw.NoTexture()
	surface.DrawPoly({
		{x = x + cut, y = y},
		{x = x + w - cut, y = y},
		{x = x + w, y = y + cut},
		{x = x + w, y = y + h - cut},
		{x = x + w - cut, y = y + h},
		{x = x + cut, y = y + h},
		{x = x, y = y + h - cut},
		{x = x, y = y + cut}
	})
end

local function DrawChatCutOutline(x, y, w, h, cut, col, thick)
	surface.SetDrawColor(col)
	thick = thick or 1

	for i = 0, thick - 1 do
		local xi, yi = x + i, y + i
		local wi, hi = w - i * 2, h - i * 2
		local ci = math.max(cut - i, 0)

		surface.DrawLine(xi + ci, yi, xi + wi - ci, yi)
		surface.DrawLine(xi + wi - ci, yi, xi + wi, yi + ci)
		surface.DrawLine(xi + wi, yi + ci, xi + wi, yi + hi - ci)
		surface.DrawLine(xi + wi, yi + hi - ci, xi + wi - ci, yi + hi)
		surface.DrawLine(xi + wi - ci, yi + hi, xi + ci, yi + hi)
		surface.DrawLine(xi + ci, yi + hi, xi, yi + hi - ci)
		surface.DrawLine(xi, yi + hi - ci, xi, yi + ci)
		surface.DrawLine(xi, yi + ci, xi + ci, yi)
	end
end

local function DrawChatCutBox(x, y, w, h, cut, fill, outline, thick)
	DrawChatCutPoly(x, y, w, h, cut, fill)
	DrawChatCutOutline(x, y, w, h, cut, outline, thick)
end

local function PlainTextFromElements(elements)
	local out = {}

	for _, v in ipairs(elements) do
		if isstring(v) then
			out[#out + 1] = v
		elseif isentity(v) and v:IsPlayer() then
			out[#out + 1] = v:Nick()
		elseif not (istable(v) and v.r and v.g and v.b) and type(v) ~= "IMaterial" then
			out[#out + 1] = tostring(v)
		end
	end

	return table.concat(out)
end

local function ClassifyChatElements(elements)
	local plain = PlainTextFromElements(elements)
	local lower = string.lower(plain)
	local style = chatStyles.normal
	local stripDeadPrefix = false
	local stripWhisperPrefix = false
	local playerAuthored = IsValid(CHAT_SPEAKER) and CHAT_SPEAKER:IsPlayer()

	if not playerAuthored then
		for _, v in ipairs(elements) do
			if isentity(v) and v:IsPlayer() then
				playerAuthored = true
				break
			end
		end
	end

	if IsValid(CHAT_SPEAKER) and CHAT_SPEAKER.ChatWhisper then
		style = chatStyles.whisper
		stripWhisperPrefix = true
	elseif string.find(plain, "^%*DEAD%*") then
		style = chatStyles.dead
		stripDeadPrefix = true
	elseif string.find(lower, "^%[whisper%]") then
		style = chatStyles.whisper
		stripWhisperPrefix = true
	elseif not playerAuthored and lower:find("joined the game", 1, true) then
		style = chatStyles.join
	elseif not playerAuthored and (lower:find("left the game", 1, true) or lower:find("disconnect", 1, true)) then
		style = chatStyles.leave
	elseif not playerAuthored and (lower:find("rock the vote", 1, true) or lower:find("vote", 1, true)) then
		style = chatStyles.vote
	elseif not playerAuthored and (lower:find("boost discord", 1, true) or lower:find("votekick access", 1, true)) then
		style = chatStyles.boost
	elseif not playerAuthored and lower:find("karma", 1, true) then
		style = chatStyles.karma
	elseif not playerAuthored and (lower:find("killed", 1, true) or lower:find("died", 1, true)) then
		style = chatStyles.death
	elseif not playerAuthored and (lower:find("warning", 1, true) or lower:find("error", 1, true)) then
		style = chatStyles.warning
	end

	return {
		accent = style.accent,
		chip = style.chip,
		stripDeadPrefix = stripDeadPrefix,
		stripWhisperPrefix = stripWhisperPrefix,
		plain = plain
	}
end

local function StripWhisperPrefixFromBuffer(buffer)
	for i, v in ipairs(buffer) do
		if not isstring(v) then continue end

		local text = v
		text = text:gsub("^<color=%d+,%d+,%d+>%[whisper%]</color>%s*", "")
		text = text:gsub("^%[whisper%]%s*", "")

		if text ~= v then
			buffer[i] = text
			return
		end
	end
end

local function PaintMarkupOverride(text, font, x, y, color, alignX, alignY, alpha)
	alpha = alpha or 255

	-- background for easier reading
	surface.SetTextPos(x + 1, y + 1)
	surface.SetTextColor(0, 0, 0, alpha)
	surface.SetFont(font)
	surface.DrawText(text)

	surface.SetTextPos(x, y)
	surface.SetTextColor(color.r, color.g, color.b, alpha)
	surface.SetFont(font)
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
	self.textInset = 10
	self.accent = chatCols.accent
	self.chip = nil
end

function PANEL:SetPresentation(data)
	self.accent = data.accent or chatCols.accent
	self.chip = data.chip
	self.textInset = self.chip and (self.chip == "WHISPER" and 82 or 66) or 12
end

function PANEL:SetMarkup(text)
	self.text = text

	self.markup = hg.markup.Parse(self.text, math.max(self:GetWide() - self.textInset - 12, 80))
	self.markup.onDrawText = PaintMarkupOverride

	self:SetTall(math.max(self.markup:GetHeight() + 8, 24))

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
	self.markup = hg.markup.Parse(self.text, math.max(width - self.textInset - 12, 80))
	self.markup.onDrawText = PaintMarkupOverride

	self:SetTall(math.max(self.markup:GetHeight() + 8, 24))
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
		local accent = self.accent or chatCols.accent
		local rowAlpha = math.Clamp(newAlpha, 0, 255)

		render.SetScissorRect(clipX, clipY, clipX + clipW, clipY + clipH, true)
			local stripY = math.floor(self.yAnim)
			local fillAlpha = hover and 74 or 42
			local centerY = stripY + height * 0.5

			surface.SetDrawColor(chatCols.row.r, chatCols.row.g, chatCols.row.b, fillAlpha * (rowAlpha / 255))
			surface.DrawRect(8, stripY + 2, width - 14, height - 5)

			surface.SetDrawColor(accent.r, accent.g, accent.b, (hover and 170 or 105) * (rowAlpha / 255))
			surface.DrawRect(4, stripY + 4, 2, height - 10)

			if self.chip then
				local chipW = self.chip == "WHISPER" and 62 or 46
				local chipH = 15
				local chipY = math.floor(centerY - chipH * 0.5)

				DrawChatCutBox(12, chipY, chipW, chipH, 4,
					Color(accent.r * 0.15, accent.g * 0.15, accent.b * 0.15, 150 * (rowAlpha / 255)),
					Color(accent.r, accent.g, accent.b, 150 * (rowAlpha / 255)), 1)
				draw.SimpleText(self.chip, "zChatFontSmall", 12 + chipW * 0.5, centerY, Color(accent.r, accent.g, accent.b, rowAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end

			self.markup:draw(self.textInset, math.floor(centerY - self.markup:GetHeight() * 0.5) + 1, nil, nil, newAlpha)
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

	self:SetTextColor(color_white)

	self:SetPaintBackground(false)
	self:SetTextInset(42, 0)

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

	local fill = active and chatCols.inputActive or chatCols.input

	DrawChatCutBox(0, 0, w, h, 7, fill, active and chatCols.accent or Color(35, 255, 110, 80), 1)

	surface.SetDrawColor(chatCols.accent.r, chatCols.accent.g, chatCols.accent.b, active and 34 or 14)
	surface.SetMaterial(chatMatGradL)
	surface.DrawTexturedRect(1, 1, w - 2, h - 2)
	surface.SetDrawColor(chatCols.accent.r, chatCols.accent.g, chatCols.accent.b, active and 160 or 70)
	surface.DrawRect(12, 5, 2, h - 10)
	draw.SimpleText(">", "zChatFont", 28, h * 0.5, Color(115, 255, 170, active and 230 or 110), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local drawText = active and self:GetText() or self.prevText
	local textX = 42
	surface.SetFont("zChatFont")
	local _, textH = surface.GetTextSize("Hg")
	local textY = math.floor((h - textH) * 0.5)
	local screenX, screenY = self:LocalToScreen(textX, 0)

	render.SetScissorRect(screenX, screenY, screenX + w - textX - 8, screenY + h, true)
		surface.SetTextColor(255, 255, 255, active and 255 or 65)
		surface.SetTextPos(textX, textY)
		surface.DrawText(drawText)

		if active and math.floor(CurTime() * 2) % 2 == 0 then
			local caretText = drawText:utf8sub(0, self:GetCaretPos()) or string.sub(drawText, 1, self:GetCaretPos())
			local caretW = surface.GetTextSize(caretText)
			surface.SetDrawColor(chatCols.accent.r, chatCols.accent.g, chatCols.accent.b, 220)
			surface.DrawRect(textX + caretW + 1, textY + 2, 1, textH - 4)
		end
	render.SetScissorRect(0, 0, 0, 0, false)

	for k, v in ipairs(self.droppedCharacters) do
		local text = v.text

		v.velocityY = v.velocityY + (5 * FrameTime())
		v.y = v.y + v.velocityY

		v.x = v.x + v.velocityX

		v.alpha = v.alpha - FrameTime() * 750

		DisableClipping(true)
			surface.SetTextColor(150, 150, 150, v.alpha)
			surface.SetTextPos(v.x, v.y)
			surface.SetFont("zChatFont")
			surface.DrawText(text)
		DisableClipping(false)

		if v.alpha <= 0 then
			table.remove(self.droppedCharacters, k)
		end
	end

	surface.SetAlphaMultiplier(1)
end

function PANEL:OnValueChange(text)
	local prevText = self.prevText

	if NoDrop:GetBool() then
		local len1, len2 = string.utf8len(prevText), string.utf8len(text)

		if len1 > len2 then
			local droppedText = string.utf8sub(prevText, self:GetCaretPos() + 1, self:GetCaretPos() + (len1 - len2))

			local droppedChars = string.Explode(utf8.charpattern, droppedText)
			for k, v in ipairs(droppedChars) do
				local data = {}
				data.text = v

				surface.SetFont("zChatFont")
				-- local tw1 = surface.GetTextSize(text)
				local tw2 = surface.GetTextSize(v)

				data.x = tw2 * (self:GetCaretPos())

				-- local panelWide = self:GetWide()

				-- if data.x > panelWide then
				-- 	data.x = data.x - (data.x - panelWide)
				-- end

				data.y = 8

				data.velocityX = math.Rand(-0.1, 0.1)
				data.velocityY = -1

				data.alpha = 255

				table.insert(self.droppedCharacters, data)
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
	self.entryPanel:DockMargin(8, 0, 8, 8)

	self.entry = self.entryPanel:Add("zChatboxEntry")
	self.entry:Dock(FILL)
	-- self.entry.OnValueChange = ix.util.Bind(self, self.OnTextChanged)
	-- self.entry.OnKeyCodeTyped = ix.util.Bind(self, self.OnKeyCodeTyped)
	self.entry.OnEnter = CallbackBind(self, self.OnMessageSent)

	self.history = self:Add("DScrollPanel")
	self.history:Dock(FILL)
	self.history:DockMargin(8, 8, 8, 6)
	self.history:SetPaintedManually(true)
	self:ApplyChatBounds(true)

	local bar = self.history:GetVBar()
	bar:SetWide(5)
	bar.Paint = function(_, w, h)
		surface.SetDrawColor(0, 0, 0, 105)
		surface.DrawRect(w - 2, 0, 2, h)
		surface.SetDrawColor(chatCols.accent.r, chatCols.accent.g, chatCols.accent.b, 60)
		surface.DrawRect(w - 1, 0, 1, h)
	end
	bar.btnUp.Paint = function() end
	bar.btnDown.Paint = function() end
	bar.btnGrip.Paint = function(_, w, h)
		DrawChatCutBox(0, 0, w, h, 2, Color(35, 225, 110, 120), Color(135, 255, 180, 180), 1)
	end

	self:SetActive(false)
end

local gray = Color(184, 205, 225, 120)
local black = Color(6, 14, 24, 220)

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

	local targetW = math.floor(math.Clamp(sw * (expanded and 0.36 or 0.31), 460, expanded and 760 or 650))
	local targetH = math.floor(math.Clamp(sh * (expanded and 0.27 or 0.21), 190, expanded and 340 or 260))

	self:SetSize(targetW, targetH)
	self:SetPos(math.floor(sw * 0.018), math.floor(sh - targetH - sh * 0.105))

	if IsValid(self.entryPanel) then
		self.entryPanel:SetTall((active or showDraft) and (active and 34 or 26) or 0)
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
	local fill = active and chatCols.bgActive or chatCols.bg
	local panel = active and chatCols.panelActive or chatCols.panel

	DrawChatCutBox(0, 0, w, h, 12, fill, Color(chatCols.accent.r, chatCols.accent.g, chatCols.accent.b, active and 190 or 95), 1)
	DrawChatCutBox(3, 3, w - 6, h - 6, 9, panel, Color(chatCols.accent.r, chatCols.accent.g, chatCols.accent.b, active and 70 or 38), 1)

	surface.SetDrawColor(chatCols.accent.r, chatCols.accent.g, chatCols.accent.b, active and 18 or 9)
	surface.SetMaterial(chatMatGradD)
	surface.DrawTexturedRect(3, 3, w - 6, h - 6)

	surface.SetDrawColor(chatCols.accent.r, chatCols.accent.g, chatCols.accent.b, active and 185 or 105)
	surface.DrawRect(8, 12, 2, h - 24)

	surface.SetAlphaMultiplier(1)
		self.history:PaintManual()
		local bar = self.history:GetVBar()
		bar:SetAlpha(self:GetAlpha())
	surface.SetAlphaMultiplier(self:GetAlpha() / 255)

	DisableClipping(true)
		local whisperHint = "Hold left ALT and press ENTER to whisper"
		local radioHint
		local activeWeapon = LocalPlayer():GetActiveWeapon()
		if IsValid(activeWeapon) and activeWeapon:GetClass() == "weapon_walkie_talkie" and activeWeapon:GetIsOn() then
			whisperHint = "Hold left ALT and press ENTER to whisper and radio "
			radioHint = string.format(
				"[%.1f MHz]",
				math.Round(activeWeapon:GetHudFrequency(), 1)
			)
		end

		draw.SimpleText(whisperHint, "zChatFontSmall", 5, h * 1.01 + 1, black)
		draw.SimpleText(whisperHint, "zChatFontSmall", 4, h * 1.01, gray)

		if radioHint then
			surface.SetFont("zChatFontSmall")
			local hintWidth = surface.GetTextSize(whisperHint)
			draw.SimpleTextOutlined(
				radioHint,
				"zChatFontSmall",
				4 + hintWidth,
				h * 1.01,
				radioHintColor,
				TEXT_ALIGN_LEFT,
				TEXT_ALIGN_TOP,
				1,
				radioHintOutline
			)
		end

		if LocalPlayer().organism and LocalPlayer().organism.otrub  then
			draw.SimpleText("Your messages are currently not visible to anyone.", "zChatFontSmall", ScrW() * 0.3 + 1, h * 1.01 + 1, black, TEXT_ALIGN_RIGHT)
			draw.SimpleText("Your messages are currently not visible to anyone.", "zChatFontSmall", ScrW() * 0.3, h * 1.01, gray, TEXT_ALIGN_RIGHT)
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

		input.SetCursorPos(self:LocalToScreen(10, self:GetTall() + 10))

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
	local presentation = ClassifyChatElements(elements)
	local buffer = {
		"<font=zChatFont>"
	}

	buffer = hook.Run("ModifyMessageBuffer", buffer, CHAT_SPEAKER) or buffer
	if presentation.stripWhisperPrefix then
		StripWhisperPrefixFromBuffer(buffer)
	end

	local strippedDeadPrefix = false
	local strippedWhisperPrefix = false

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
			local text = tostring(v)

			if presentation.stripDeadPrefix and not strippedDeadPrefix then
				text = text:gsub("^%*DEAD%*%s*", "")
				strippedDeadPrefix = true
			end

			if presentation.stripWhisperPrefix and not strippedWhisperPrefix then
				text = text:gsub("^%[whisper%]%s*", ""):gsub("^%[Whisper%]%s*", ""):gsub("^%[WHISPER%]%s*", "")
				strippedWhisperPrefix = true
			end

			buffer[#buffer + 1] = text:gsub("<", "&lt;"):gsub(">", "&gt;")
		end
	end

	local panel = self.history:Add("zChatMessage")
	panel:Dock(TOP)
	panel:InvalidateParent(true)
	panel:SetPresentation(presentation)
	panel:SetMarkup(table.concat(buffer))

	if (#self.entries >= 100) then
		local oldPanel = table.remove(self.entries, 1)

		if (IsValid(oldPanel)) then
			oldPanel:Remove()
		end
	end

	local bar = self.history:GetVBar()
	local bScroll = !self:GetActive() or bar.Scroll >= bar.CanvasSize - 2 -- only scroll when we're not at the bottom/inactive

	if bScroll then
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
