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
local portraitObservedName = ""
local portraitSpectatorView = false
local buyMenu
local lastBuyToggleTime = 0
local contractRemaining = 0
local contractGraceRemaining = 0
local cashHintUntil = 0
local cashHintAmount = 0
local BASE_W, BASE_H = 1920, 1080
local lastScrW, lastScrH = 0, 0

local titleColor = Color(129, 198, 255)
local targetColor = Color(174, 225, 255)
local neutralColor = Color(236, 245, 255)
local frameBlue = Color(123, 184, 255)
local accentBlue = Color(84, 144, 224, 210)
local ringDark = Color(18, 39, 70, 235)
local ringInner = Color(32, 62, 108, 220)
local warningColor = Color(255, 185, 120)
local warningOutlineColor = Color(132, 26, 26, 235)

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
end

local function getPortraitMetrics()
	local radius = ui(76)
	return {
		panelX = ui(24),
		panelY = ui(72),
		spectatorY = ui(18),
		radius = radius,
		titleOffsetY = ui(2),
		circleOffsetY = ui(34),
		cashOffsetY = ui(24),
		contractOffsetY = ui(40),
		warningOffsetY = ui(56),
		outlineRadius = ui(10),
		darkRingRadius = ui(5),
		accentRingRadius = ui(1),
		innerRingInset = ui(4)
	}
end

local function formatContractTime(seconds)
	seconds = math.max(math.ceil(seconds or 0), 0)
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function getBuyMenuMetrics()
	return {
		width = ui(380),
		height = ui(360),
		border = math.max(1, ui(2)),
		titleY = ui(22),
		cashY = ui(52),
		footerY = ui(16),
		listMarginLeft = ui(12),
		listMarginTop = ui(72),
		listMarginRight = ui(12),
		listMarginBottom = ui(28),
		rowGap = ui(8),
		rowHeight = ui(70),
		rowTitleX = ui(12),
		rowTitleY = ui(18),
		rowPriceX = ui(12),
		rowDescY = ui(46)
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

local buyItems = {
	{
		id = "pocketknife",
		name = "Pocket Knife",
		price = 100,
		description = "Cheap backup blade."
	},
	{
		id = "bat",
		name = "Bat",
		price = 250,
		description = "Reliable blunt pressure."
	},
	{
		id = "makarov",
		name = "Makarov Pistol",
		price = 500,
		description = "Compact pistol with spare ammo."
	},
	{
		id = "sr25",
		name = "M98B",
		price = 1000,
		description = "Long-range rifle for premium contracts."
	}
}

local function drawFilledCircle(x, y, radius, segments)
	draw.NoTexture()

	local poly = {}
	poly[1] = {x = x, y = y}

	for i = 0, segments do
		local angle = math.rad((i / segments) * 360)
		poly[#poly + 1] = {
			x = x + math.cos(angle) * radius,
			y = y + math.sin(angle) * radius
		}
	end

	surface.DrawPoly(poly)
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

local function ensureTargetPortrait()
	if IsValid(targetPortrait) then return targetPortrait end

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

		entity:SetSequence(entity:LookupSequence("idle_subtle"))
		entity:SetAngles(Angle(0, 0, 0))
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

local function updatePortraitCamera(panel)
	if not IsValid(panel) or not IsValid(panel.Entity) then return end

	local entity = panel.Entity
	entity:SetupBones()

	local headBone = entity:LookupBone("ValveBiped.Bip01_Head1")
	if headBone then
		local matrix = entity:GetBoneMatrix(headBone)
		if matrix then
			local headPos = matrix:GetTranslation()
			panel:SetLookAt(headPos + Vector(0, 0, -1))
			panel:SetCamPos(headPos + Vector(34, 0, 3))
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
		return
	end

	local targetModelInfo = hg.Appearance
		and hg.Appearance.PlayerModels
		and ((hg.Appearance.PlayerModels[1] and hg.Appearance.PlayerModels[1][info.appearance.AModel]) or (hg.Appearance.PlayerModels[2] and hg.Appearance.PlayerModels[2][info.appearance.AModel]))
	local model = isstring(info.model) and info.model or (targetModelInfo and targetModelInfo.mdl) or ""
	if not isstring(model) or model == "" then
		panel:SetVisible(false)
		portraitLastEntity = nil
		return
	end

	panel:SetVisible(true)
	portraitTargetInfo = info
	local signature = model .. ":" .. tostring(info.skin) .. ":" .. tostring(info.appearance.AModel) .. ":" .. tostring(info.appearance.AFacemap)

	if portraitLastEntity ~= target or portraitLastModel ~= model or portraitLastSignature ~= signature then
		if IsValid(panel.Entity) then
			clearPortraitAccessories(panel.Entity)
		end

		panel:SetModel(model)
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
	entity:SetSequence(entity:LookupSequence("idle_subtle"))

	updatePortraitCamera(panel)
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

	local sw, sh = ScrW(), ScrH()
	rebuildFonts()
	buyMenu = vgui.Create("DFrame")
	buyMenu:SetTitle("")
	buyMenu:ShowCloseButton(true)
	buyMenu:MakePopup()
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
		draw.RoundedBox(0, 0, 0, w, h, Color(10, 21, 39, 245))
		surface.SetDrawColor(frameBlue)
		surface.DrawOutlinedRect(0, 0, w, h, metrics.border)
		draw.SimpleText("Black Market", "ZB_ShipAssassinsLarge", w * 0.5, metrics.titleY, targetColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("Cash: $" .. LocalPlayer():GetNWInt("ShipAssassins_Money", 0), "ZB_ShipAssassinsMedium", w * 0.5, metrics.cashY, neutralColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("F3 to close", "ZB_ShipAssassinsSmall", w * 0.5, h - metrics.footerY, Color(160, 185, 215), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	local list = vgui.Create("DScrollPanel", buyMenu)
	buyMenu.ItemList = list
	list:Dock(FILL)

	for _, item in ipairs(buyItems) do
		local panel = list:Add("DButton")
		panel:Dock(TOP)
		panel:SetText("")
		table.insert(buyMenu.ItemRows, panel)

		function panel:Paint(w, h)
			local metrics = buyMenu.LayoutMetrics or getBuyMenuMetrics()
			draw.RoundedBox(0, 0, 0, w, h, Color(17, 35, 62, 230))
			surface.SetDrawColor(Color(83, 140, 220, 180))
			surface.DrawOutlinedRect(0, 0, w, h, math.max(1, ui(1)))
			draw.SimpleText(item.name, "ZB_ShipAssassinsMedium", metrics.rowTitleX, metrics.rowTitleY, neutralColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText("$" .. item.price, "ZB_ShipAssassinsMedium", w - metrics.rowPriceX, metrics.rowTitleY, targetColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			draw.SimpleText(item.description, "ZB_ShipAssassinsSmall", metrics.rowTitleX, metrics.rowDescY, Color(178, 205, 230), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end

		function panel:DoClick()
			purchaseItem(item.id)
		end
	end

	applyBuyMenuLayout(buyMenu)
end

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
	portraitObservedName = ""
	portraitSpectatorView = false
	contractRemaining = 0
	contractGraceRemaining = 0

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
			draw.SimpleText("ZBattle | Assassin's Greed", "ZB_ShipAssassinsLarge", sw * 0.5, sh * 0.12, ColorAlpha(titleColor, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("You are an Assassin", "ZB_ShipAssassinsLarge", sw * 0.5, sh * 0.5, ColorAlpha(titleColor, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("Only attack your target or hunter. Other fights are not your concern.", "ZB_ShipAssassinsMedium", sw * 0.5, sh * 0.855, ColorAlpha(warningColor, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("Interfering in someone else's fight gets you slain.", "ZB_ShipAssassinsMedium", sw * 0.5, sh * 0.892, ColorAlpha(warningColor, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("Each contract lasts 4 minutes. Contract kills pay $250. F3 opens the buy menu.", "ZB_ShipAssassinsMedium", sw * 0.5, sh * 0.93, ColorAlpha(neutralColor, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end

	if IsValid(portrait) then
		local x = spectatingPlayer and (sw * 0.5 - metrics.radius - metrics.outlineRadius) or metrics.panelX
		local y = spectatingPlayer and metrics.spectatorY or metrics.panelY
		local circleX = x + metrics.radius + metrics.outlineRadius
		local circleY = y + metrics.radius + metrics.circleOffsetY
		local title = (spectatingPlayer and portraitObservedName ~= "") and (portraitObservedName .. "'s Target") or "Current Target"

		draw.SimpleTextOutlined(title, "ZB_ShipAssassinsLarge", circleX, y + metrics.titleOffsetY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, math.max(1, ui(2)), ringDark)

		surface.SetDrawColor(frameBlue)
		drawFilledCircle(circleX, circleY, metrics.radius + metrics.outlineRadius, 48)
		surface.SetDrawColor(ringDark)
		drawFilledCircle(circleX, circleY, metrics.radius + metrics.darkRingRadius, 48)
		surface.SetDrawColor(accentBlue)
		drawFilledCircle(circleX, circleY, metrics.radius + metrics.accentRingRadius, 48)
		surface.SetDrawColor(ringInner)
		drawFilledCircle(circleX, circleY, metrics.radius - metrics.innerRingInset, 48)

		if not spectatingPlayer then
			draw.SimpleTextOutlined("Cash: $" .. lply:GetNWInt("ShipAssassins_Money", 0), "ZB_ShipAssassinsSmall", circleX, circleY + metrics.radius + metrics.cashOffsetY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, math.max(1, ui(2)), ringDark)
			if contractGraceRemaining > 0 then
				draw.SimpleTextOutlined("Grace: " .. formatContractTime(contractGraceRemaining), "ZB_ShipAssassinsSmall", circleX, circleY + metrics.radius + metrics.contractOffsetY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, math.max(1, ui(2)), ringDark)
			elseif contractRemaining > 0 then
				draw.SimpleTextOutlined("Contract: " .. formatContractTime(contractRemaining), "ZB_ShipAssassinsSmall", circleX, circleY + metrics.radius + metrics.contractOffsetY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, math.max(1, ui(2)), ringDark)
			end
			draw.SimpleTextOutlined("Ignore other fights.", "ZB_ShipAssassinsSmall", circleX, circleY + metrics.radius + metrics.warningOffsetY, warningColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, math.max(1, ui(2)), warningOutlineColor)
			draw.SimpleTextOutlined("Wrong target/hunter = slay", "ZB_ShipAssassinsSmall", circleX, circleY + metrics.radius + metrics.warningOffsetY + ui(16), warningColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, math.max(1, ui(2)), warningOutlineColor)
		else
			if contractGraceRemaining > 0 then
				draw.SimpleTextOutlined("Grace: " .. formatContractTime(contractGraceRemaining), "ZB_ShipAssassinsSmall", circleX, circleY + metrics.radius + metrics.cashOffsetY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, math.max(1, ui(2)), ringDark)
			elseif contractRemaining > 0 then
				draw.SimpleTextOutlined("Time Left: " .. formatContractTime(contractRemaining), "ZB_ShipAssassinsSmall", circleX, circleY + metrics.radius + metrics.cashOffsetY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, math.max(1, ui(2)), ringDark)
			end
		end

		if IsValid(target) then
			updateTargetPortrait(target)
			portrait:SetPos(circleX - metrics.radius, circleY - metrics.radius)
			portrait:SetSize(metrics.radius * 2, metrics.radius * 2)
			portrait:SetVisible(true)
		elseif lply.ShipAssassinsTargetInfo then
			updateTargetPortrait(NULL)
			portrait:SetPos(circleX - metrics.radius, circleY - metrics.radius)
			portrait:SetSize(metrics.radius * 2, metrics.radius * 2)
			portrait:SetVisible(true)
		else
			portrait:SetVisible(false)
			draw.SimpleText("No target", "ZB_ShipAssassinsLarge", circleX, circleY, neutralColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		if portrait:IsVisible() then
			render.ClearStencil()
			render.SetStencilEnable(true)
			render.SetStencilWriteMask(255)
			render.SetStencilTestMask(255)
			render.SetStencilReferenceValue(1)
			render.SetStencilCompareFunction(STENCIL_ALWAYS)
			render.SetStencilPassOperation(STENCIL_REPLACE)
			render.SetStencilFailOperation(STENCIL_KEEP)
			render.SetStencilZFailOperation(STENCIL_KEEP)

			surface.SetDrawColor(255, 255, 255, 255)
			drawFilledCircle(circleX, circleY, metrics.radius - ui(2), 48)

			render.SetStencilCompareFunction(STENCIL_EQUAL)
			render.SetStencilPassOperation(STENCIL_KEEP)
			portrait:PaintManual()
			render.SetStencilEnable(false)
		end
	end

	if cashHintUntil > CurTime() and lply:Alive() then
		local fade = math.Clamp((cashHintUntil - CurTime()) / 4, 0, 1)
		local hintY = sh - ui(120)
		draw.SimpleTextOutlined("Contract reward: $" .. tostring(cashHintAmount), "ZB_ShipAssassinsMedium", sw * 0.5, hintY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, math.max(1, ui(2)), color_black)
		draw.SimpleTextOutlined("F3 to open the Black Market", "ZB_ShipAssassinsMedium", sw * 0.5, hintY + ui(24), Color(255, 255, 255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, math.max(1, ui(2)), color_black)
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
