MODE.name = "assassinsgreed"

local MODE = MODE

local startFade = 0
local lastTarget
local targetPortrait
local portraitTarget
local portraitTargetInfo
local portraitLastModel
local portraitLastEntity
local portraitLastSignature
local portraitAppliedSignature
local portraitObservedName = ""
local portraitSpectatorView = false
local buyMenu
local lastBuyToggleTime = 0
local contractRemaining = 0
local contractGraceRemaining = 0
local cashHintUntil = 0
local cashHintAmount = 0
local objectiveId = ""
local objectiveLabel = ""
local objectiveProgress = 0
local objectiveGoal = 0
local objectiveReward = 0
local objectiveHintUntil = 0
local objectiveHintLabel = ""
local objectiveHintReward = 0
local objectiveHintBalance = 0
local targetArrowBearing = 0
local targetArrowElevation = 0
local BASE_W, BASE_H = 1920, 1080
local lastScrW, lastScrH = 0, 0

local titleColor = Color(35, 255, 105)
local targetColor = Color(135, 255, 175)
local neutralColor = Color(232, 255, 238)
local frameGreen = Color(22, 220, 88, 230)
local ringDark = Color(2, 14, 8, 245)
local ringInner = Color(4, 32, 15, 232)
local warningColor = Color(255, 196, 96)
local panelFill = Color(2, 14, 7, 250)
local panelFillSoft = Color(7, 38, 18, 218)
local panelHot = Color(10, 96, 40, 205)
local dimGreen = Color(35, 255, 105, 70)
local mutedText = Color(148, 205, 165)

hook.Remove("PostDrawTranslucentRenderables", "ShipAssassins_Target3DPointer")

local function UIScale()
	return math.min(ScrW() / BASE_W, ScrH() / BASE_H)
end

local function ui(value)
	return math.max(1, math.floor(value * UIScale()))
end

local function rebuildFonts(force)
	if not force and lastScrW == ScrW() and lastScrH == ScrH() then return end
	lastScrW, lastScrH = ScrW(), ScrH()

	surface.CreateFont("ZB_ShipAssassinsLarge", {
		font = "Bahnschrift",
		size = ui(36),
		weight = 700,
		antialias = true
	})

	surface.CreateFont("ZB_ShipAssassinsHeader", {
		font = "Bahnschrift",
		size = ui(22),
		weight = 800,
		antialias = true
	})

	surface.CreateFont("ZB_ShipAssassinsName", {
		font = "Bahnschrift",
		size = ui(17),
		weight = 800,
		antialias = true
	})

	surface.CreateFont("ZB_ShipAssassinsLabel", {
		font = "Bahnschrift",
		size = ui(16),
		weight = 800,
		antialias = true
	})

	surface.CreateFont("ZB_ShipAssassinsMedium", {
		font = "Bahnschrift",
		size = ui(22),
		weight = 700,
		antialias = true
	})

	surface.CreateFont("ZB_ShipAssassinsSmall", {
		font = "Bahnschrift",
		size = ui(14),
		weight = 600,
		antialias = true
	})

	surface.CreateFont("ZB_ShipAssassinsTiny", {
		font = "Bahnschrift",
		size = ui(11),
		weight = 700,
		antialias = true
	})
end

local function getPortraitMetrics()
	return {
		panelX = ui(24),
		panelY = ui(44),
		spectatorY = ui(4),
		width = ui(460),
		height = ui(300),
		portraitW = ui(132),
		portraitH = ui(178),
		padding = ui(12),
		cut = ui(10),
		border = math.max(1, ui(2)),
		headerY = ui(24),
		modeY = ui(25),
		headerLineY = ui(44),
		contentY = ui(60),
		infoX = ui(158),
		infoW = ui(290),
		infoH = ui(178),
		infoPad = ui(12),
		warningY = ui(254),
		warningH = ui(30),
		barHeight = ui(7)
	}
end

local function formatContractTime(seconds)
	seconds = math.max(math.ceil(seconds or 0), 0)
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function getBuyMenuMetrics()
	return {
		width = ui(500),
		height = ui(420),
		border = math.max(1, ui(2)),
		cut = ui(14),
		titleY = ui(28),
		subtitleY = ui(55),
		cashY = ui(56),
		footerY = ui(24),
		closeSize = ui(28),
		listMarginLeft = ui(16),
		listMarginTop = ui(65),
		listMarginRight = ui(18),
		listMarginBottom = ui(25),
		rowGap = ui(4),
		rowHeight = ui(64),
		rowTitleX = ui(16),
		rowTitleY = ui(17),
		rowPriceX = ui(16),
		rowDescY = ui(42),
		rowTagY = ui(32),
		rowStatusY = ui(43)
	}
end

local function applyBuyMenuLayout(frame)
	if not IsValid(frame) then return end

	local metrics = getBuyMenuMetrics()
	frame:SetSize(metrics.width, metrics.height)
	frame:Center()
	frame.LayoutMetrics = metrics

	if IsValid(frame.ItemList) then
		frame.ItemList:DockMargin(metrics.listMarginLeft, metrics.listMarginTop, metrics.listMarginRight, metrics.listMarginBottom)
	end

	if IsValid(frame.CloseButton) then
		frame.CloseButton:SetSize(metrics.closeSize, metrics.closeSize)
		frame.CloseButton:SetPos(metrics.width - metrics.closeSize - ui(10), ui(10))
	end

	if istable(frame.ItemRows) then
		for _, row in ipairs(frame.ItemRows) do
			if IsValid(row) then
				row:DockMargin(0, 0, 0, metrics.rowGap)
				row:SetTall(metrics.rowHeight)
			end
		end
	end
end

rebuildFonts(true)

local buyItems = MODE.GetDefaultShopItems and MODE:GetDefaultShopItems() or {}

local function cutPoly(x, y, w, h, cut)
	return {
		{x = x + cut, y = y},
		{x = x + w - cut, y = y},
		{x = x + w, y = y + cut},
		{x = x + w, y = y + h - cut},
		{x = x + w - cut, y = y + h},
		{x = x + cut, y = y + h},
		{x = x, y = y + h - cut},
		{x = x, y = y + cut}
	}
end

local function drawCutBox(x, y, w, h, cut, fill, outline, thickness)
	draw.NoTexture()
	surface.SetDrawColor(fill)
	surface.DrawPoly(cutPoly(x, y, w, h, cut))

	if not outline then return end

	thickness = math.max(1, thickness or 1)
	for i = 0, thickness - 1 do
		surface.SetDrawColor(outline)
		local points = cutPoly(x + i, y + i, w - i * 2, h - i * 2, math.max(0, cut - i))
		for pointIndex = 1, #points do
			local current = points[pointIndex]
			local nextPoint = points[pointIndex == #points and 1 or pointIndex + 1]
			surface.DrawLine(current.x, current.y, nextPoint.x, nextPoint.y)
		end
	end
end

local function drawSectionLine(x, y, w, alpha)
	surface.SetDrawColor(Color(35, 255, 105, alpha or 115))
	surface.DrawRect(x, y, w, math.max(1, ui(1)))
end

local function drawProgressBar(x, y, w, h, fraction, fillColor)
	fraction = math.Clamp(fraction or 0, 0, 1)
	draw.RoundedBox(0, x, y, w, h, Color(0, 0, 0, 150))
	surface.SetDrawColor(Color(35, 255, 105, 85))
	surface.DrawOutlinedRect(x, y, w, h)

	if fraction > 0 then
		surface.SetDrawColor(fillColor or titleColor)
		surface.DrawRect(x + ui(1), y + ui(1), math.max(1, (w - ui(2)) * fraction), math.max(1, h - ui(2)))
	end
end

local function circlePoly(cx, cy, radius, segments)
	local points = {}
	segments = segments or 24

	for i = 1, segments do
		local ang = math.rad((i / segments) * 360)
		points[i] = {
			x = cx + math.cos(ang) * radius,
			y = cy + math.sin(ang) * radius
		}
	end

	return points
end

local function drawTargetDirectionArrow(cx, cy, size, target, alpha)
	if not IsValid(target) or not IsValid(lply) then return end

	local targetPos = target.WorldSpaceCenter and target:WorldSpaceCenter() or (target:GetPos() + Vector(0, 0, 36))
	local delta = targetPos - lply:EyePos()
	local flatDelta = Vector(delta.x, delta.y, 0)

	if flatDelta:LengthSqr() < 16 then return end

	local eyeAng = lply:EyeAngles()
	local bearing = -math.AngleDifference(flatDelta:Angle().y, eyeAng.y)
	local elevation = math.Clamp(delta:GetNormalized():Dot(eyeAng:Up()), -1, 1)
	targetArrowBearing = targetArrowBearing + math.AngleDifference(bearing, targetArrowBearing) * math.Clamp(FrameTime() * 14, 0, 1)
	targetArrowElevation = Lerp(math.Clamp(FrameTime() * 12, 0, 1), targetArrowElevation, elevation)

	local pulse = 0.5 + math.sin(CurTime() * 5.6) * 0.5
	local radius = size
	local innerRadius = math.max(1, size - ui(5))
	local rad = math.rad(targetArrowBearing)
	local dx, dy = math.sin(rad), -math.cos(rad)
	local pitchLift = -targetArrowElevation * size * 0.42
	local sideX, sideY = -dy, dx
	local tipX, tipY = cx + dx * (radius - ui(3)), cy + dy * (radius - ui(3)) + pitchLift
	local baseX, baseY = cx - dx * (size * 0.36), cy - dy * (size * 0.36) - pitchLift * 0.32
	local halfW = size * 0.38
	alpha = alpha or 235

	draw.NoTexture()
	surface.SetDrawColor(2, 18, 8, math.floor(alpha * 0.76))
	surface.DrawPoly(circlePoly(cx, cy, radius, 28))
	surface.SetDrawColor(35, 255, 105, math.floor((70 + pulse * 60) * (alpha / 255)))
	surface.DrawPoly(circlePoly(cx, cy, innerRadius, 28))
	surface.SetDrawColor(3, 21, 9, math.floor(alpha * 0.92))
	surface.DrawPoly(circlePoly(cx, cy, math.max(1, innerRadius - ui(3)), 28))

	surface.SetDrawColor(35, 255, 105, math.floor(alpha * 0.72))
	surface.DrawLine(cx - radius + ui(4), cy, cx + radius - ui(4), cy)
	surface.DrawLine(cx, cy - radius + ui(4), cx, cy + radius - ui(4))
	surface.DrawLine(cx + radius + ui(3), cy, cx + radius + ui(3), cy + pitchLift)

	surface.SetDrawColor(135, 255, 175, alpha)
	surface.DrawPoly({
		{x = tipX, y = tipY},
		{x = baseX + sideX * halfW, y = baseY + sideY * halfW},
		{x = cx - dx * ui(1), y = cy - dy * ui(1)},
		{x = baseX - sideX * halfW, y = baseY - sideY * halfW}
	})
end

local function fitText(text, font, maxWidth)
	text = tostring(text or "")
	surface.SetFont(font)

	if surface.GetTextSize(text) <= maxWidth then return text end

	local suffix = "..."
	local low, high = 0, #text
	while low < high do
		local mid = math.ceil((low + high) * 0.5)
		if surface.GetTextSize(string.sub(text, 1, mid) .. suffix) <= maxWidth then
			low = mid
		else
			high = mid - 1
		end
	end

	return string.sub(text, 1, low) .. suffix
end

local function drawToast(title, subtitle, y, color, fade)
	local sw = ScrW()
	local w, h = ui(430), ui(68)
	local x = sw * 0.5 - w * 0.5
	local alpha = math.Clamp((fade or 1) * 255, 0, 255)
	local fill = Color(3, 20, 10, 220 * (fade or 1))
	local outline = Color(color.r, color.g, color.b, alpha)

	drawCutBox(x, y, w, h, ui(10), fill, outline, math.max(1, ui(2)))
	drawSectionLine(x + ui(18), y + ui(43), w - ui(36), 80 * (fade or 1))
	draw.SimpleText(fitText(title, "ZB_ShipAssassinsMedium", w - ui(36)), "ZB_ShipAssassinsMedium", sw * 0.5, y + ui(21), ColorAlpha(color, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(fitText(subtitle, "ZB_ShipAssassinsSmall", w - ui(36)), "ZB_ShipAssassinsSmall", sw * 0.5, y + ui(50), ColorAlpha(neutralColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function clearPortraitAccessories(entity)
	if not IsValid(entity) or not entity.modelAccess then return end

	for key, model in pairs(entity.modelAccess) do
		if IsValid(model) then
			model:Remove()
		end

		entity.modelAccess[key] = nil
	end
end

local function normalizeTargetAppearance(info)
	if not istable(info) then return nil end

	local appearance = istable(info.appearance) and info.appearance or {}
	appearance.AClothes = istable(appearance.AClothes) and appearance.AClothes or {}
	appearance.AAttachments = istable(appearance.AAttachments) and appearance.AAttachments or {}
	appearance.ABodygroups = istable(appearance.ABodygroups) and appearance.ABodygroups or {}
	appearance.AFacemap = appearance.AFacemap or "Default"
	appearance.AColor = IsColor(appearance.AColor) and appearance.AColor or color_white

	info.appearance = appearance
	info.model = isstring(info.model) and info.model or ""
	info.skin = isnumber(info.skin) and info.skin or 0
	info.playerColor = isvector(info.playerColor) and info.playerColor or Vector(1, 1, 1)

	return info
end

local function applyPortraitMaterials(entity, info, targetModelInfo)
	for slot = 0, 31 do
		entity:SetSubMaterial(slot, "")
	end

	local appearance = info.appearance
	if not istable(appearance) then return end

	local clothes = hg.Appearance and hg.Appearance.Clothes
	local facemapSlots = hg.Appearance and hg.Appearance.FacemapsSlots
	local sexIndex = targetModelInfo and targetModelInfo.sex and 2 or 1
	local materials = entity:GetMaterials() or {}

	if istable(targetModelInfo and targetModelInfo.submatSlots) and istable(clothes) and istable(clothes[sexIndex]) then
		for clothingSlot, materialName in SortedPairs(targetModelInfo.submatSlots) do
			local materialIndex = 0

			for idx = 1, #materials do
				if materials[idx] == materialName then
					materialIndex = idx - 1
					break
				end
			end

			local clothingKey = appearance.AClothes[clothingSlot]
			entity:SetSubMaterial(materialIndex, clothes[sexIndex][clothingKey] or clothes[sexIndex].normal or "")
		end
	end

	if istable(facemapSlots) then
		for idx = 1, #materials do
			local facemapMaterial = facemapSlots[materials[idx]]
			if facemapMaterial and facemapMaterial[appearance.AFacemap] then
				entity:SetSubMaterial(idx - 1, facemapMaterial[appearance.AFacemap])
			end
		end
	end
end

local function applyPortraitBodygroups(entity, info, targetModelInfo)
	local appearance = info.appearance
	if not istable(appearance) or not istable(appearance.ABodygroups) then return end

	local allBodygroups = entity:GetBodyGroups() or {}
	local appearanceBodygroups = hg.Appearance and hg.Appearance.Bodygroups or {}
	local sexIndex = targetModelInfo and targetModelInfo.sex and 2 or 1

	for index, bodygroup in SortedPairs(allBodygroups) do
		local wantedName = appearance.ABodygroups[bodygroup.name]
		local config = appearanceBodygroups[bodygroup.name]
		local sexConfig = istable(config) and config[sexIndex]

		if wantedName and istable(sexConfig) and sexConfig[wantedName] then
			local wantedSubmodel = sexConfig[wantedName][1]
			for subIndex = 0, #bodygroup.submodels do
				if bodygroup.submodels[subIndex] == wantedSubmodel then
					entity:SetBodygroup(index - 1, subIndex)
					break
				end
			end
		end
	end
end

local portraitSequences = {
	"idle_subtle",
	"idle_all_01",
	"idle_all",
	"pose_standing_02",
	"pose_standing_01",
	"menu_walk",
	"idle"
}

local function applyPortraitPose(entity)
	if not IsValid(entity) then return end

	for _, sequenceName in ipairs(portraitSequences) do
		local sequence = entity:LookupSequence(sequenceName)
		if isnumber(sequence) and sequence >= 0 then
			entity:ResetSequence(sequence)
			entity:SetCycle(0.08)
			entity:SetPlaybackRate(0)
			entity:SetupBones()
			return
		end
	end

	entity:SetSequence(0)
	entity:SetCycle(0)
	entity:SetPlaybackRate(0)
	entity:SetupBones()
end

local function ensureTargetPortrait()
	if IsValid(targetPortrait) then return targetPortrait end

	portraitAppliedSignature = nil
	portraitLastEntity = nil
	portraitLastSignature = nil

	targetPortrait = vgui.Create("DModelPanel")
	targetPortrait:SetVisible(false)
	targetPortrait:SetFOV(24)
	targetPortrait:SetMouseInputEnabled(false)
	targetPortrait:SetKeyboardInputEnabled(false)
	targetPortrait:SetPaintBackground(false)
	targetPortrait:SetPaintedManually(true)
	targetPortrait:SetModel("models/player/group01/male_07.mdl")
	targetPortrait:SetDirectionalLight(BOX_RIGHT, Color(220, 200, 170))
	targetPortrait:SetDirectionalLight(BOX_LEFT, Color(120, 110, 100))
	targetPortrait:SetDirectionalLight(BOX_FRONT, Color(200, 195, 185))
	targetPortrait:SetDirectionalLight(BOX_TOP, Color(255, 245, 220))
	targetPortrait:SetAmbientLight(Color(95, 85, 72))

	function targetPortrait:LayoutEntity(entity)
		if not IsValid(entity) then return end

		entity:SetAngles(Angle(0, 0, 0))
		if not self.PortraitPoseApplied then
			applyPortraitPose(entity)
			self.PortraitPoseApplied = true
		end
	end

	function targetPortrait:PostDrawModel(entity)
		if not IsValid(entity) or not istable(portraitTargetInfo) then return end
		local appearance = portraitTargetInfo.appearance
		if not istable(appearance) or not istable(appearance.AAttachments) then return end

		for _, attachment in ipairs(appearance.AAttachments) do
			local attachmentData = hg.Accessories and hg.Accessories[attachment]
			if attachmentData then
				DrawAccesories(entity, entity, attachment, attachmentData, false, true)
			end
		end
	end

	function targetPortrait:OnRemove()
		if IsValid(self.Entity) then
			clearPortraitAccessories(self.Entity)
		end
	end

	return targetPortrait
end

local function buildPortraitSignature(target, info, model)
	local appearance = istable(info and info.appearance) and info.appearance or {}

	return table.concat({
		IsValid(target) and target:EntIndex() or 0,
		model or "",
		tostring(info and info.skin or 0),
		tostring(info and info.playerColor or ""),
		tostring(appearance.AModel or ""),
		tostring(appearance.AFacemap or ""),
		util.TableToJSON(appearance.AClothes or {}) or "",
		util.TableToJSON(appearance.AAttachments or {}) or "",
		util.TableToJSON(appearance.ABodygroups or {}) or ""
	}, "|")
end

local function updatePortraitCamera(panel)
	if not IsValid(panel) or not IsValid(panel.Entity) then return end

	local entity = panel.Entity
	entity:SetupBones()

	local headBone = entity:LookupBone("ValveBiped.Bip01_Head1")
	if headBone then
		local matrix = entity:GetBoneMatrix(headBone)
		if matrix then
			local headPos = matrix:GetTranslation()
			panel:SetLookAt(headPos + Vector(0, 0, -6))
			panel:SetCamPos(headPos + Vector(45, 0, 2))
			return
		end
	end

	local mins, maxs = entity:GetRenderBounds()
	local center = (mins + maxs) * 0.5
	panel:SetLookAt(center + Vector(0, 0, 9))
	panel:SetCamPos(center + Vector(56, 0, 10))
end

local function updateTargetPortrait(target)
	local panel = ensureTargetPortrait()
	portraitTarget = IsValid(target) and target or nil

	if not IsValid(panel) then return end

	local info = normalizeTargetAppearance(lply.ShipAssassinsTargetInfo)
	if not info or info.model == "" then
		panel:SetVisible(false)
		portraitLastEntity = nil
		portraitTargetInfo = nil
		portraitAppliedSignature = nil
		return
	end

	local targetModelInfo = hg.Appearance
		and hg.Appearance.PlayerModels
		and ((hg.Appearance.PlayerModels[1] and hg.Appearance.PlayerModels[1][info.appearance.AModel]) or (hg.Appearance.PlayerModels[2] and hg.Appearance.PlayerModels[2][info.appearance.AModel]))
	local model = isstring(info.model) and info.model or (targetModelInfo and targetModelInfo.mdl) or ""
	if not isstring(model) or model == "" then
		panel:SetVisible(false)
		portraitLastEntity = nil
		portraitAppliedSignature = nil
		return
	end

	panel:SetVisible(true)
	portraitTargetInfo = info
	local signature = model .. ":" .. tostring(info.skin) .. ":" .. tostring(info.appearance.AModel) .. ":" .. tostring(info.appearance.AFacemap)
	local appliedSignature = buildPortraitSignature(target, info, model)

	if portraitAppliedSignature == appliedSignature and IsValid(panel.Entity) then
		return
	end

	if portraitLastEntity ~= target or portraitLastModel ~= model or portraitLastSignature ~= signature then
		if IsValid(panel.Entity) then
			clearPortraitAccessories(panel.Entity)
		end

		panel:SetModel(model)
		panel.PortraitPoseApplied = false
		portraitLastModel = model
		portraitLastEntity = target
		portraitLastSignature = signature
	end

	local entity = panel.Entity
	if not IsValid(entity) then return end

	entity:SetSkin(info.skin)
	entity:SetBodyGroups("00000000000000000000")
	applyPortraitBodygroups(entity, info, targetModelInfo)
	applyPortraitMaterials(entity, info, targetModelInfo)

	entity:SetNWVector("PlayerColor", info.playerColor)
	entity:SetColor(color_white)
	applyPortraitPose(entity)
	panel.PortraitPoseApplied = true

	updatePortraitCamera(panel)
	portraitAppliedSignature = appliedSignature
end

local function canOpenBuyMenu()
	local round = CurrentRound and CurrentRound()
	return IsValid(lply)
		and round
		and round.name == MODE.name
		and zb.ROUND_STATE == 1
		and lply:Alive()
		and lply:Team() ~= TEAM_SPECTATOR
end

local function closeBuyMenu()
	if IsValid(buyMenu) then
		buyMenu:Remove()
	end
end

local function purchaseItem(itemId)
	net.Start("ShipAssassins_Buy")
		net.WriteString(itemId)
	net.SendToServer()
end

local function openBuyMenu()
	if not canOpenBuyMenu() then return end
	if IsValid(buyMenu) then
		buyMenu:Remove()
		return
	end

	rebuildFonts()
	buyMenu = vgui.Create("DFrame")
	buyMenu:SetTitle("")
	buyMenu:ShowCloseButton(false)
	buyMenu:MakePopup()
	if hg.AddSpaceCloseFooter then
		hg.AddSpaceCloseFooter(buyMenu, function()
			closeBuyMenu()
		end, {accent = frameGreen})
	end
	buyMenu.ItemRows = {}
	applyBuyMenuLayout(buyMenu)

	function buyMenu:Think()
		rebuildFonts()

		if self.LastLayoutScrW ~= ScrW() or self.LastLayoutScrH ~= ScrH() then
			self.LastLayoutScrW, self.LastLayoutScrH = ScrW(), ScrH()
			applyBuyMenuLayout(self)
		end
	end

	function buyMenu:Paint(w, h)
		local metrics = self.LayoutMetrics or getBuyMenuMetrics()
		local cash = LocalPlayer():GetNWInt("ShipAssassins_Money", 0)

		drawCutBox(0, 0, w, h, metrics.cut, panelFill, frameGreen, metrics.border)
		surface.SetDrawColor(dimGreen)

		draw.SimpleText("BLACK MARKET", "ZB_ShipAssassinsHeader", ui(24), metrics.titleY, titleColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("RANDOMIZED CONTRACT SUPPLY", "ZB_ShipAssassinsSmall", ui(25), metrics.subtitleY, mutedText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("CASH", "ZB_ShipAssassinsMedium", w - ui(65), metrics.subtitleY, mutedText, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		draw.SimpleText("$" .. cash, "ZB_ShipAssassinsMedium", w - ui(24), metrics.cashY, targetColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		surface.SetDrawColor(Color(35, 255, 105, 35))

		draw.SimpleText("SELECT EQUIPMENT", "ZB_ShipAssassinsSmall", ui(24), h - metrics.footerY, mutedText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	local closeButton = vgui.Create("DButton", buyMenu)
	buyMenu.CloseButton = closeButton
	closeButton:SetText("")

	function closeButton:Paint(w, h)
		local hovered = self:IsHovered()
		drawCutBox(0, 0, w, h, ui(5), hovered and Color(140, 18, 35, 235) or Color(24, 8, 12, 225), hovered and Color(255, 85, 105) or frameGreen, math.max(1, ui(1)))
		draw.SimpleText("X", "ZB_ShipAssassinsSmall", w * 0.5, h * 0.5, hovered and color_white or targetColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	function closeButton:DoClick()
		closeBuyMenu()
	end

	local list = vgui.Create("DScrollPanel", buyMenu)
	buyMenu.ItemList = list
	list:Dock(FILL)

	function list:Paint(w, h)
		surface.SetDrawColor(Color(0, 0, 0, 45))
		surface.DrawRect(0, 0, w, h)
	end

	local vbar = list:GetVBar()
	if IsValid(vbar) then
		vbar:SetWide(ui(8))

		function vbar:Paint(w, h)
			draw.RoundedBox(0, w * 0.5 - ui(1), 0, ui(2), h, Color(35, 255, 105, 35))
		end

		if IsValid(vbar.btnGrip) then
			function vbar.btnGrip:Paint(w, h)
				drawCutBox(0, 0, w, h, ui(3), Color(35, 255, 105, 90), Color(35, 255, 105, 150), math.max(1, ui(1)))
			end
		end

		if IsValid(vbar.btnUp) then vbar.btnUp.Paint = function() end end
		if IsValid(vbar.btnDown) then vbar.btnDown.Paint = function() end end
	end

	for _, item in ipairs(buyItems) do
		local panel = list:Add("DButton")
		panel:Dock(TOP)
		panel:SetText("")
		panel.HoverFrac = 0
		table.insert(buyMenu.ItemRows, panel)

		function panel:Paint(w, h)
			local metrics = buyMenu.LayoutMetrics or getBuyMenuMetrics()
			local cash = LocalPlayer():GetNWInt("ShipAssassins_Money", 0)
			local canAfford = cash >= item.price
			local hovered = self:IsHovered()
			self.HoverFrac = math.Approach(self.HoverFrac or 0, hovered and 1 or 0, FrameTime() * 8)

			local outline = canAfford and Color(35, 255, 105, 125 + 100 * self.HoverFrac) or Color(95, 120, 100, 135)
			local fill = canAfford and Color(3, 34 + 24 * self.HoverFrac, 14, 232) or Color(16, 24, 18, 225)
			local priceColor = canAfford and targetColor or Color(120, 145, 126)
			local textColor = canAfford and neutralColor or Color(150, 165, 152)
			local actionColor = canAfford and titleColor or warningColor
			local status = canAfford and "BUY" or ("NEED $" .. tostring(item.price - cash))

			drawCutBox(0, 0, w, h, ui(10), fill, outline, math.max(1, ui(1)))
			surface.SetDrawColor(canAfford and Color(35, 255, 105, 100 + 100 * self.HoverFrac) or Color(85, 110, 90, 85))
			surface.DrawRect(0, ui(10), ui(4), h - ui(20))

			draw.SimpleText(item.name, "ZB_ShipAssassinsMedium", metrics.rowTitleX, metrics.rowTitleY, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("$" .. item.price, "ZB_ShipAssassinsMedium", w - metrics.rowPriceX, metrics.rowTitleY, priceColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

			local chipW = ui(82)
			local chipX = w - metrics.rowPriceX - chipW
			drawCutBox(chipX, metrics.rowStatusY - ui(11), chipW, ui(22), ui(5), canAfford and Color(4, 62, 25, 210) or Color(44, 28, 13, 215), canAfford and Color(35, 255, 105, 120) or Color(255, 196, 96, 105), math.max(1, ui(1)))
			draw.SimpleText(status, "ZB_ShipAssassinsTiny", chipX + chipW * 0.5, metrics.rowStatusY, actionColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			draw.SimpleText(string.upper(item.categoryName or "Gear"), "ZB_ShipAssassinsTiny", metrics.rowTitleX, metrics.rowTagY, canAfford and targetColor or mutedText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(fitText(item.description, "ZB_ShipAssassinsTiny", chipX - metrics.rowTitleX - ui(8)), "ZB_ShipAssassinsTiny", metrics.rowTitleX, metrics.rowDescY + ui(9), canAfford and mutedText or Color(120, 140, 126), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		function panel:DoClick()
			if LocalPlayer():GetNWInt("ShipAssassins_Money", 0) < item.price then
				surface.PlaySound("buttons/button10.wav")
				return
			end

			surface.PlaySound("buttons/button14.wav")
			purchaseItem(item.id)
		end
	end

	applyBuyMenuLayout(buyMenu)
end

net.Receive("ShipAssassins_ShopSync", function()
	local count = net.ReadUInt(8)
	local items = {}

	for index = 1, count do
		items[index] = {
			category = net.ReadString(),
			categoryName = net.ReadString(),
			id = net.ReadString(),
			name = net.ReadString(),
			price = net.ReadUInt(16),
			description = net.ReadString()
		}
	end

	buyItems = items

	if IsValid(buyMenu) then
		closeBuyMenu()
	end
end)

net.Receive("ShipAssassins_RoundStart", function()
	net.ReadString()
	net.ReadString()
	net.ReadString()

	lply.ShipAssassinsTarget = nil
	lply.ShipAssassinsKills = 0
	lply.ShipAssassinsAliveCount = 0
	startFade = CurTime()
	lastTarget = nil
	portraitTarget = nil
	lply.ShipAssassinsTargetInfo = nil
	portraitLastEntity = nil
	portraitLastSignature = nil
	portraitAppliedSignature = nil
	portraitObservedName = ""
	portraitSpectatorView = false
	contractRemaining = 0
	contractGraceRemaining = 0
	objectiveId = ""
	objectiveLabel = ""
	objectiveProgress = 0
	objectiveGoal = 0
	objectiveReward = 0
	objectiveHintUntil = 0

	surface.PlaySound("snd_jack_hmcd_psycho.mp3")
	zb.RemoveFade()
end)

net.Receive("ShipAssassins_Sync", function()
	local newTarget = net.ReadEntity()
	net.ReadEntity()
	local hasTargetInfo = net.ReadBool()
	local targetInfo = hasTargetInfo and net.ReadTable() or nil
	local kills = net.ReadUInt(8)
	local aliveCount = net.ReadUInt(8)
	local newContractRemaining = net.ReadUInt(16)
	local newGraceRemaining = net.ReadUInt(16)
	local newPortraitSpectatorView = net.ReadBool()
	local newPortraitObservedName = net.ReadString() or ""

	newTarget = IsValid(newTarget) and newTarget or nil

	if not newPortraitSpectatorView and newGraceRemaining <= 0 and IsValid(newTarget) and IsValid(lastTarget) and newTarget ~= lastTarget then
		chat.AddText(targetColor, "New target assigned.")
		surface.PlaySound("buttons/blip1.wav")
	end

	lply.ShipAssassinsTarget = newTarget
	lply.ShipAssassinsTargetInfo = normalizeTargetAppearance(targetInfo)
	lply.ShipAssassinsKills = kills
	lply.ShipAssassinsAliveCount = aliveCount
	portraitSpectatorView = newPortraitSpectatorView
	portraitObservedName = newPortraitObservedName
	contractRemaining = newContractRemaining
	contractGraceRemaining = newGraceRemaining
	lastTarget = newTarget
	updateTargetPortrait(newTarget)
end)

net.Receive("ShipAssassins_TimerSync", function()
	contractRemaining = net.ReadUInt(16)
	contractGraceRemaining = net.ReadUInt(16)
end)

net.Receive("ShipAssassins_ObjectiveSync", function()
	local hasObjective = net.ReadBool()

	if not hasObjective then
		objectiveId = ""
		objectiveLabel = ""
		objectiveProgress = 0
		objectiveGoal = 0
		objectiveReward = 0
		return
	end

	objectiveId = net.ReadString()
	objectiveLabel = net.ReadString()
	objectiveProgress = net.ReadUInt(8)
	objectiveGoal = net.ReadUInt(8)
	objectiveReward = net.ReadUInt(16)
end)

net.Receive("ShipAssassins_ObjectiveComplete", function()
	objectiveHintLabel = net.ReadString()
	objectiveHintReward = net.ReadUInt(16)
	objectiveHintBalance = net.ReadUInt(16)
	objectiveHintUntil = CurTime() + 4
	surface.PlaySound("buttons/button15.wav")
end)

net.Receive("ShipAssassins_CashHint", function()
	cashHintAmount = net.ReadUInt(16)
	cashHintUntil = CurTime() + 4
	surface.PlaySound("buttons/button14.wav")
end)

net.Receive("ShipAssassins_RoundEnd", function()
	local winner = net.ReadEntity()
	local kills = net.ReadUInt(8)

	winner = IsValid(winner) and winner or nil

	if winner then
		chat.AddText(titleColor, "Assassin's Greed: ", neutralColor, winner:Name() .. " won the round.")
	else
		chat.AddText(titleColor, "Assassin's Greed: ", neutralColor, "no assassin survived.")
	end

	chat.AddText(titleColor, "Your kills this round: ", neutralColor, tostring(kills))

	if IsValid(targetPortrait) then
		targetPortrait:SetVisible(false)
	end

	objectiveId = ""
	objectiveLabel = ""
	objectiveProgress = 0
	objectiveGoal = 0
	objectiveReward = 0
end)

function MODE:RenderScreenspaceEffects()
	if startFade == 0 then return end

	local fade = math.Clamp((startFade + 7.5 - CurTime()) / 7.5, 0, 1)
	if fade <= 0 then return end

	surface.SetDrawColor(0, 0, 0, 255 * fade)
	surface.DrawRect(-1, -1, ScrW() + 1, ScrH() + 1)
end

function MODE:HUDPaint()
	rebuildFonts()

	if not IsValid(lply) then
		if IsValid(targetPortrait) then
			targetPortrait:SetVisible(false)
		end

		return
	end

	local spectTarget = not lply:Alive() and lply.GetNWEntity and lply:GetNWEntity("spect", NULL) or nil
	spectTarget = hg and hg.RagdollOwner and hg.RagdollOwner(spectTarget) or spectTarget
	local spectatingPlayer = not lply:Alive() and ((IsValid(spectTarget) and spectTarget:IsPlayer()) or portraitSpectatorView)
	if not lply:Alive() and not spectatingPlayer then
		if IsValid(targetPortrait) then
			targetPortrait:SetVisible(false)
		end

		return
	end

	local sw, sh = ScrW(), ScrH()
	local target = lply.ShipAssassinsTarget
	local portrait = ensureTargetPortrait()
	local metrics = getPortraitMetrics()

	if startFade > 0 then
		local fade = math.Clamp((startFade + 8 - CurTime()) / 8, 0, 1)
		if fade > 0 and lply:Alive() then
			local introW, introH = ui(660), ui(158)
			local introX, introY = sw * 0.5 - introW * 0.5, sh * 0.5 - introH * 0.5
			drawCutBox(introX, introY, introW, introH, ui(16), Color(3, 20, 10, 215 * fade), ColorAlpha(frameGreen, 230 * fade), math.max(1, ui(2)))
			draw.SimpleText("ASSASSIN'S GREED", "ZB_ShipAssassinsLarge", sw * 0.5, introY + ui(34), ColorAlpha(titleColor, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			drawSectionLine(introX + ui(34), introY + ui(62), introW - ui(68), 125 * fade)
			draw.SimpleText("CONTRACT ONLINE", "ZB_ShipAssassinsMedium", sw * 0.5, introY + ui(88), ColorAlpha(neutralColor, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("Only your target or hunter matters. Interference gets you slain.", "ZB_ShipAssassinsSmall", sw * 0.5, introY + ui(117), ColorAlpha(warningColor, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("Contract kills pay $250. F3 opens the Black Market.", "ZB_ShipAssassinsSmall", sw * 0.5, introY + ui(137), ColorAlpha(mutedText, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	if IsValid(portrait) then
		local x = spectatingPlayer and (sw * 0.5 - metrics.width * 0.5) or metrics.panelX
		local y = spectatingPlayer and metrics.spectatorY or metrics.panelY
		local portraitX = x + metrics.padding
		local portraitY = y + metrics.contentY
		local infoX = x + metrics.infoX
		local infoY = y + metrics.contentY
		local infoPad = metrics.infoPad
		local infoInnerW = metrics.infoW - infoPad * 2
		local title = (spectatingPlayer and portraitObservedName ~= "") and (portraitObservedName .. "'s Contract") or "HIT LIST"
		local targetName = "NO TARGET"
		local targetInfo = lply.ShipAssassinsTargetInfo

		if IsValid(target) then
			targetName = target:GetNWString("PlayerName", target:Nick())
		elseif istable(targetInfo) and isstring(targetInfo.displayName) and targetInfo.displayName ~= "" then
			targetName = targetInfo.displayName
		end

		drawCutBox(x, y, metrics.width, metrics.height, metrics.cut, panelFill, frameGreen, metrics.border)
		surface.SetDrawColor(Color(35, 255, 105, 75))
		drawSectionLine(x + metrics.padding, y + metrics.headerLineY, metrics.width - metrics.padding * 2, 150)

		draw.SimpleText(title, "ZB_ShipAssassinsHeader", x + metrics.padding + ui(8), y + metrics.headerY, titleColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("ASSASSINATION MODE", "ZB_ShipAssassinsLabel", x + metrics.width - metrics.padding - ui(8), y + metrics.modeY, targetColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

		drawCutBox(portraitX, portraitY, metrics.portraitW, metrics.portraitH, ui(10), ringInner, titleColor, math.max(1, ui(2)))
		drawCutBox(infoX, infoY, metrics.infoW, metrics.infoH, ui(8), Color(1, 12, 7, 230), Color(35, 255, 105, 70), math.max(1, ui(1)))

		draw.SimpleText("TARGET", "ZB_ShipAssassinsLabel", infoX + infoPad, infoY + ui(15), targetColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(fitText(targetName, "ZB_ShipAssassinsName", infoInnerW), "ZB_ShipAssassinsName", infoX + infoPad, infoY + ui(34), neutralColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		drawSectionLine(infoX + infoPad, infoY + ui(50), infoInnerW, 55)

		if not spectatingPlayer then
			draw.SimpleText("CASH", "ZB_ShipAssassinsLabel", infoX + infoPad, infoY + ui(67), titleColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("$" .. lply:GetNWInt("ShipAssassins_Money", 0), "ZB_ShipAssassinsName", infoX + metrics.infoW - infoPad, infoY + ui(67), targetColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			drawSectionLine(infoX + infoPad, infoY + ui(84), infoInnerW, 55)
		end

		local timerLabel = "CONTRACT"
		local timerValue = contractRemaining
		local timerMax = 240
		local timerColor = titleColor
		if contractGraceRemaining > 0 then
			timerLabel = "GRACE"
			timerValue = contractGraceRemaining
			timerMax = 30
			timerColor = warningColor
		end

		draw.SimpleText(timerLabel, "ZB_ShipAssassinsLabel", infoX + infoPad, infoY + ui(101), targetColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(formatContractTime(timerValue), "ZB_ShipAssassinsLabel", infoX + metrics.infoW - infoPad, infoY + ui(101), timerColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		drawProgressBar(infoX + infoPad, infoY + ui(115), infoInnerW, metrics.barHeight, timerMax > 0 and timerValue / timerMax or 0, timerColor)
		drawSectionLine(infoX + infoPad, infoY + ui(130), infoInnerW, 55)

		if not spectatingPlayer and objectiveLabel ~= "" then
			local objectiveText = string.upper(objectiveLabel) .. "  " .. tostring(objectiveProgress) .. "/" .. tostring(objectiveGoal)
			local objectiveFraction = objectiveGoal > 0 and objectiveProgress / objectiveGoal or 0
			draw.SimpleText("SIDE OBJECTIVE", "ZB_ShipAssassinsLabel", infoX + infoPad, infoY + ui(144), targetColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("$" .. tostring(objectiveReward), "ZB_ShipAssassinsLabel", infoX + metrics.infoW - infoPad, infoY + ui(144), targetColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			draw.SimpleText(fitText(objectiveText, "ZB_ShipAssassinsTiny", infoInnerW), "ZB_ShipAssassinsTiny", infoX + infoPad, infoY + ui(158), neutralColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			drawProgressBar(infoX + infoPad, infoY + ui(169), infoInnerW, metrics.barHeight, objectiveFraction, targetColor)
		end

		if not spectatingPlayer then
			local warningX = x + metrics.padding
			local warningY = y + metrics.warningY
			local warningW = metrics.width - metrics.padding * 2
			draw.SimpleText("IGNORE OTHER FIGHTS", "ZB_ShipAssassinsSmall", warningX + ui(14), warningY + ui(10), warningColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("WRONG TARGET/HUNTER = SLAY", "ZB_ShipAssassinsSmall", warningX + ui(14), warningY + ui(25), warningColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			drawTargetDirectionArrow(warningX + warningW * 0.58, warningY + ui(18), ui(16), target, 230)
			draw.SimpleText("F3 TO OPEN MARKET", "ZB_ShipAssassinsSmall", warningX + warningW - ui(14), warningY + ui(25), mutedText, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end

		if IsValid(target) then
			if not portraitAppliedSignature then
				updateTargetPortrait(target)
			end

			portrait:SetPos(portraitX + ui(2), portraitY + ui(2))
			portrait:SetSize(metrics.portraitW - ui(4), metrics.portraitH - ui(4))
			portrait:SetVisible(true)
		elseif lply.ShipAssassinsTargetInfo then
			if not portraitAppliedSignature then
				updateTargetPortrait(NULL)
			end

			portrait:SetPos(portraitX + ui(2), portraitY + ui(2))
			portrait:SetSize(metrics.portraitW - ui(4), metrics.portraitH - ui(4))
			portrait:SetVisible(true)
		else
			portrait:SetVisible(false)
			draw.SimpleText("NO SIGNAL", "ZB_ShipAssassinsSmall", portraitX + metrics.portraitW * 0.5, portraitY + metrics.portraitH * 0.5, mutedText, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		if portrait:IsVisible() then
			portrait:PaintManual()
		end
	end

	if cashHintUntil > CurTime() and lply:Alive() then
		local fade = math.Clamp((cashHintUntil - CurTime()) / 4, 0, 1)
		drawToast("CONTRACT REWARD $" .. tostring(cashHintAmount), "F3 opens the Black Market", sh - ui(128), titleColor, fade)
	end

	if objectiveHintUntil > CurTime() and lply:Alive() then
		local fade = math.Clamp((objectiveHintUntil - CurTime()) / 4, 0, 1)
		drawToast("OBJECTIVE COMPLETE $" .. tostring(objectiveHintReward), objectiveHintLabel .. " | Balance $" .. tostring(objectiveHintBalance), sh - ui(206), targetColor, fade)
	end
end

hook.Add("PlayerButtonDown", "ShipAssassins_BuyMenuToggle", function(ply, btn)
	if ply ~= LocalPlayer() or btn ~= KEY_F3 then return end

	local round = CurrentRound and CurrentRound()
	if not round or round.name ~= MODE.name then return end
	if CurTime() - lastBuyToggleTime < 0.25 then return end

	lastBuyToggleTime = CurTime()

	openBuyMenu()
end)
