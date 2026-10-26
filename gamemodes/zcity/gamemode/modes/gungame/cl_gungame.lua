local MODE = MODE

local currentStage, stageTotal, stageKills, killsPerStage = 1, 1, 0, 2
local currentWeapon, nextWeapon, isFinalStage = "", "", false
local roundSeconds, graceEnd, graceDuration = 0, 0, 5
local lastStageBannerUntil, lastStageName = 0, ""
local uiRevealAt, uiPulse = 0, 0
local variationName, variationDesc, ladder = "Gun Game", "", {}
local introUntil, killFeed, boxReveal, respawnAt = 0, {}, {}, 0
local KILLFEED_MAX, KILLFEED_LIFE, KILLFEED_FADE, GUN_BOXES = 5, 26, 4, 6
local MusicVolume = GetConVar("snd_musicvolume")
local endPanel, gungameThemeStation
local colScratch = Color(255, 255, 255)

local color_bezel = Color(8, 9, 9)
local color_text = Color(220, 220, 220)
local color_idle = Color(172, 180, 174)
local color_idle_dim = Color(118, 126, 122)
local color_gold = Color(220, 175, 55)
local color_silver = Color(186, 196, 206)
local color_bronze = Color(196, 120, 55)
local color_karma = Color(90, 220, 130)
local color_current = Color(35, 225, 110)
local color_final = Color(225, 35, 35)
local MEDAL_COLORS = {color_gold, color_silver, color_bronze}
local PLACE_LABELS = {"1ST", "2ND", "3RD"}
local PORTRAIT_SEQUENCES = {"idle_subtle", "idle_all_01", "idle_all", "pose_standing_02", "pose_standing_01", "idle"}
local MAX_RESULTS = 26

local weaponIconCache = {}

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

local function DrawCRTFrame(x, y, w, h)
	surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, 230)
	surface.DrawRect(x, y, w, h)
	surface.SetDrawColor(0, 0, 0, 115)
	surface.DrawRect(x + 3, y + 3, w - 6, h - 6)
	surface.SetDrawColor(168, 168, 172, 178)
end

local function BadIcon(mat)
	if not mat then return true end
	if isnumber(mat) then return false end
	if type(mat) ~= "IMaterial" then return true end
	local name = mat.GetName and mat:GetName() or ""
	return name == "" or name == "null" or (mat.IsError and mat:IsError())
end

local function DrawWeaponIcon(class, x, y, wide, alpha, tall)
	local cached = weaponIconCache[class]
	local mat, wep
	if cached == false then
		return false
	elseif cached then
		mat, wep = cached[1], cached[2]
	else
		wep = weapons.GetStored(class)
		if not wep then
			weaponIconCache[class] = false
			return false
		end
		mat = wep.WepSelectIcon2
		if BadIcon(mat) and isstring(wep.IconOverride) and wep.IconOverride ~= "" then
			mat = Material(wep.IconOverride, "smooth")
		end
		if BadIcon(mat) then mat = wep.WepSelectIcon end
		if BadIcon(mat) then
			weaponIconCache[class] = false
			return false
		end
		weaponIconCache[class] = {mat, wep}
	end

	surface.SetDrawColor(255, 255, 255, alpha or 255)
	if type(mat) == "IMaterial" and wep and not wep.IconEdited then
		mat:SetInt("$flags", 32)
		wep.IconEdited = true
	end
	render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	render.PushFilterMin(TEXFILTER.ANISOTROPIC)
	if isnumber(mat) then surface.SetTexture(mat) else surface.SetMaterial(mat) end
	tall = tall or (wide * 0.5)
	if wep and wep.WepSelectIcon2box then
		local s = math.min(wide, tall)
		surface.DrawTexturedRect(x + (wide - s) * 0.5, y + (tall - s) * 0.5, s, s)
	else
		surface.DrawTexturedRect(x, y, wide, tall)
	end
	render.PopFilterMin()
	render.PopFilterMag()
	return true
end

local function RevealBoxes(fromStage, stagger)
	local start = math.max(1, (fromStage or currentStage) - 1)
	for offset = 0, GUN_BOXES - 1 do
		local stage = start + offset
		if ladder[stage] and not boxReveal[stage] then
			boxReveal[stage] = CurTime() + (stagger and offset * 0.07 or 0)
		end
	end
end

local function DrawGunBoxes()
	local start = math.max(1, currentStage - 1)
	local boxW, boxH = ScreenScale(58), ScreenScale(26)
	local gap, barH = ScreenScale(3), math.max(3, ScreenScale(2))
	local x, y = ScreenScale(8), ScreenScale(6)

	DisableClipping(true)
	for offset = 0, GUN_BOXES - 1 do
		local stage = start + offset
		local class = ladder[stage]
		if not class then
			if stage == currentStage then class = currentWeapon end
			if stage == currentStage + 1 then class = nextWeapon end
		end
		if not class or class == "" then continue end

		local fade = 1
		if boxReveal[stage] then fade = math.Clamp((CurTime() - boxReveal[stage]) / 0.35, 0, 1) end
		if fade <= 0 then continue end

		local isCurrent = stage == currentStage
		local alpha = (isCurrent and 255 or math.max(110, 220 - offset * 22)) * fade
		local by = y + offset * (boxH + gap)
		local accent = color_idle
		if isCurrent then
			accent = (isFinalStage or stage >= stageTotal) and color_final or color_current
		elseif stage >= stageTotal then
			accent = color_final
		end

		surface.SetDrawColor(8, 9, 9, 230 * fade)
		surface.DrawRect(x, by, boxW, boxH)
		if isCurrent then
			surface.SetDrawColor(accent.r, accent.g, accent.b, 55 * fade)
			surface.DrawRect(x, by, boxW, boxH)
		end
		surface.SetDrawColor(accent.r, accent.g, accent.b, isCurrent and alpha or (alpha * 0.55))
		surface.DrawOutlinedRect(x, by, boxW, boxH, 1)

		if not DrawWeaponIcon(class, x + 4, by + 4, boxW - 8, alpha, boxH - 10 - barH) then
			local stored = weapons.GetStored(class)
			colScratch.r, colScratch.g, colScratch.b, colScratch.a = 220, 220, 220, alpha
			draw.SimpleText((stored and stored.PrintName) or class, "SB_CRT_Item", x + boxW * 0.5, by + (boxH - barH) * 0.5, colScratch, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end

		local barX, barY, barW = x + 4, by + boxH - barH - 3, boxW - 8
		surface.SetDrawColor(20, 20, 22, 220 * fade)
		surface.DrawRect(barX, barY, barW, barH)
		local frac = (stage < currentStage and 1) or (isCurrent and math.Clamp(killsPerStage > 0 and stageKills / killsPerStage or 0, 0, 1) or 0)
		if frac > 0 then
			surface.SetDrawColor(255, 255, 255, alpha)
			surface.DrawRect(barX, barY, barW * frac, barH)
		end
	end
	DisableClipping(false)
end

local function StopGunGameTheme()
	if IsValid(gungameThemeStation) then
		gungameThemeStation:Stop()
	end
	gungameThemeStation = nil
end

local function CleanupGunGameClient()
	StopGunGameTheme()
	if IsValid(endPanel) then endPanel:Remove() end
	endPanel = nil
	ladder, killFeed, boxReveal = {}, {}, {}
	stageKills, roundSeconds, graceEnd, MODE.graceEnd = 0, 0, 0, 0
	lastStageBannerUntil, introUntil, respawnAt = 0, 0, 0
end

local function GetSoundPath(path)
	if not path or path == "" then return nil end
	if string.StartWith(path, "sound/") then return path end
	return "sound/" .. path
end

local function MusicMul()
	return (MusicVolume and MusicVolume:GetFloat()) or 1
end

local function StartGunGameTheme(round)
	round = round or CurrentRound() or MODE
	local themePath = GetSoundPath(round and round.ThemeMusicFile)
	if not themePath then return false end

	local expectedRoundName = round.name
	StopGunGameTheme()

	sound.PlayFile(themePath, "noblock noplay", function(station, errCode, errStr)
		if not IsValid(station) then
			if errCode or errStr then
				print("[gungame] theme missing:", errCode, errStr)
			end
			return
		end

		local currentRound = CurrentRound()
		if not currentRound or currentRound.name ~= expectedRoundName then
			station:Stop()
			return
		end

		if hg.DynaMusic then
			hg.DynaMusic:Stop()
		end

		gungameThemeStation = station
		station:EnableLooping(true)
		station:SetVolume((round.ThemeMusicVolume or 0.4) * MusicMul())
		station:Play()
	end)

	return true
end

hook.Add("Think", "GunGameThemeVolumeThink", function()
	if not IsValid(gungameThemeStation) then return end

	local round = CurrentRound()
	if not round or round.name ~= "gungame" or not round.ThemeMusicFile then
		StopGunGameTheme()
		return
	end

	local baseVol = (round.ThemeMusicVolume or 0.4) * MusicMul()
	local fade = round.ThemeLoopFade or 2.25
	local length = gungameThemeStation:GetLength()
	local t = gungameThemeStation:GetTime()
	local mul = 1

	if length > fade * 4 then
		if t < fade then
			mul = t / fade
		elseif length - t < fade then
			mul = math.max((length - t) / fade, 0)
		end
	end

	gungameThemeStation:SetVolume(baseVol * mul)

	if gungameThemeStation:GetState() ~= GMOD_CHANNEL_PLAYING then
		gungameThemeStation:Play()
	end
end)

local function HideRoundStandouts()
	zb.SkipRoundStandouts = true
	if IsValid(zb.RoundStandouts) then zb.RoundStandouts:Remove() end
	if IsValid(zb.RoundStandoutPanel) then zb.RoundStandoutPanel:Remove() end
	if IsValid(zb.StandoutPanel) then zb.StandoutPanel:Remove() end
	timer.Remove("ZC_RoundStars_Autoclose")
	if ZC_ROUNDSTARS and IsValid(ZC_ROUNDSTARS.ActivePanel) then
		ZC_ROUNDSTARS.ActivePanel:Remove()
		ZC_ROUNDSTARS.ActivePanel = nil
	end
end

local PORTRAIT = {}

function PORTRAIT:Init()
	self:SetFOV(26)
	self:SetMouseInputEnabled(false)
	self:SetKeyboardInputEnabled(false)
	self:SetPaintBackground(false)
	self:SetAmbientLight(Color(48, 48, 52))
	self:SetDirectionalLight(BOX_FRONT, Color(220, 220, 220))
	self.Snapshot = {}
end

function PORTRAIT:FrameCamera()
	local entity = self.Entity
	if not IsValid(entity) then return end
	entity:SetupBones()
	local w, h = self:GetSize()
	if w < 4 or h < 4 then return end

	local aspect = h / w
	local lift = math.max(0, 1.05 - aspect)
	local fov = 26 * math.Clamp(1.05 / math.max(aspect, 0.5), 1, 1.25)

	local headBone = entity:LookupBone("ValveBiped.Bip01_Head1")
	if headBone then
		local matrix = entity:GetBoneMatrix(headBone)
		if matrix then
			local headPos = matrix:GetTranslation()
			self:SetLookAt(headPos + Vector(0, 0, -8 + lift * 6))
			self:SetCamPos(headPos + Vector(52, 0, 3 + lift * 6))
			self:SetFOV(fov)
			return
		end
	end
	local mins, maxs = entity:GetRenderBounds()
	local center = (mins + maxs) * 0.5
	self:SetLookAt(center + Vector(0, 0, 12 + lift * 4))
	self:SetCamPos(center + Vector(56, 0, 10 + lift * 4))
	self:SetFOV(fov)
end

function PORTRAIT:ApplySnapshot(snapshot, medalCol)
	snapshot = snapshot or {}
	self.Snapshot = snapshot
	self:SetModel((isstring(snapshot.model) and snapshot.model ~= "" and snapshot.model) or "models/player/group01/male_07.mdl")

	local light = medalCol or color_gold
	self:SetDirectionalLight(BOX_RIGHT, Color(math.min(255, light.r + 40), math.min(255, light.g + 40), math.min(255, light.b + 40)))
	self:SetDirectionalLight(BOX_LEFT, Color(light.r * 0.45, light.g * 0.45, light.b * 0.45))

	local entity = self.Entity
	if not IsValid(entity) then return end
	entity:SetSkin(snapshot.skin or 0)
	entity:SetModelScale(snapshot.modelScale or 1, 0)
	entity:SetNWVector("PlayerColor", snapshot.playerColor or Vector(1, 1, 1))
	for bodygroup, value in pairs(snapshot.bodygroups or {}) do entity:SetBodygroup(bodygroup, value) end
	for materialIndex, materialName in pairs(snapshot.subMaterials or {}) do entity:SetSubMaterial(materialIndex, materialName) end
	for i = 1, #PORTRAIT_SEQUENCES do
		local sequence = entity:LookupSequence(PORTRAIT_SEQUENCES[i])
		if isnumber(sequence) and sequence >= 0 then
			entity:ResetSequence(sequence)
			entity:SetCycle(0.08)
			entity:SetPlaybackRate(0)
			entity:SetupBones()
			self:FrameCamera()
			return
		end
	end
	entity:SetSequence(0)
	entity:SetCycle(0)
	entity:SetPlaybackRate(0)
	entity:SetupBones()
	self:FrameCamera()
end

function PORTRAIT:LayoutEntity(entity)
	if not IsValid(entity) then return end
	entity:SetAngles(angle_zero)
	local w, h = self:GetSize()
	if self._framedW ~= w or self._framedH ~= h then
		self._framedW, self._framedH = w, h
		self:FrameCamera()
	end
end

function PORTRAIT:PostDrawModel(entity)
	if not IsValid(entity) or not DrawAccesories then return end
	local accessories = self.Snapshot and self.Snapshot.accessories
	if not accessories then return end
	for i = 1, #accessories do
		local accessoryData = hg.Accessories and hg.Accessories[accessories[i]]
		if accessoryData then DrawAccesories(entity, entity, accessories[i], accessoryData, false, true) end
	end
end

vgui.Register("ZGunGamePortrait", PORTRAIT, "DModelPanel")

local function ReadPortraitSnapshot()
	local snapshot = {
		model = net.ReadString(),
		skin = net.ReadUInt(8),
		modelScale = net.ReadFloat(),
		playerColor = net.ReadVector(),
		bodygroups = {},
		subMaterials = {},
		accessories = {}
	}
	for _ = 1, net.ReadUInt(5) do snapshot.bodygroups[net.ReadUInt(8)] = net.ReadUInt(8) end
	for _ = 1, net.ReadUInt(6) do snapshot.subMaterials[net.ReadUInt(8)] = net.ReadString() end
	for index = 1, net.ReadUInt(3) do snapshot.accessories[index] = net.ReadString() end
	return snapshot
end

local function FitName(text, font, maxW)
	text = text ~= "" and text or "Unknown"
	surface.SetFont(font)
	if surface.GetTextSize(text) <= maxW then return text end
	while #text > 1 and surface.GetTextSize(text .. "...") > maxW do
		text = string.sub(text, 1, #text - 1)
	end
	return text .. "..."
end

local function CreateEndPanel(list)
	if IsValid(endPanel) then endPanel:Remove() end

	local rowH = math.max(18, ScreenScale(11))
	local headerH = ScreenScale(16)
	local podiumH = ScreenScaleH(156)
	local colH = math.max(16, ScreenScale(10))
	local restCount = math.max(0, #list - 3)
	local listH = restCount > 0 and (colH + restCount * (rowH + 1) + 4) or 0
	local height = math.min(headerH + podiumH + listH + 22, ScrH() * 0.86)

	endPanel = vgui.Create("DFrame")
	endPanel:SetSize(math.min(ScrW() * 0.5, ScreenScale(360)), math.max(height, ScreenScaleH(220)))
	endPanel:Center()
	endPanel:SetTitle("")
	endPanel:ShowCloseButton(true)
	endPanel:SetDraggable(true)
	endPanel:MakePopup()
	endPanel:DockPadding(8, 8, 8, 8)
	function endPanel:Paint(w, h)
		DrawCRTFrame(0, 0, w, h)
		draw.SimpleText("Results", "SB_CRT_Header", w * 0.5, 8, color_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end

	local podium = vgui.Create("DPanel", endPanel)
	podium:Dock(TOP)
	podium:SetTall(podiumH)
	podium:DockMargin(2, headerH - 2, 2, 4)
	podium:SetPaintBackground(false)
	function podium:PerformLayout(w, h)
		local gap = 4
		local slotW = math.floor((w - gap * 2) / 3)
		for _, slot in ipairs(self.Slots or {}) do
			if not IsValid(slot) then continue end
			local sh = math.floor(h * slot.SlotHeight)
			slot:SetSize(slotW, sh)
			slot:SetPos(slot.SlotCol * (slotW + gap), h - sh)
		end
	end

	podium.Slots = {}
	for _, slotInfo in ipairs({
		{place = 2, col = 0, height = 0.90},
		{place = 1, col = 1, height = 1.00},
		{place = 3, col = 2, height = 0.84}
	}) do
		local result = list[slotInfo.place]
		if not result then continue end
		local medalCol = MEDAL_COLORS[slotInfo.place] or color_idle
		local snapshot = result.portrait
		if not snapshot and IsValid(result.ply) then
			local accessories = result.ply.GetNetVar and result.ply:GetNetVar("Accessories")
			if isstring(accessories) then accessories = {accessories} end
			snapshot = {
				model = result.ply:GetModel(),
				skin = result.ply:GetSkin() or 0,
				modelScale = result.ply:GetModelScale() or 1,
				playerColor = result.ply.GetPlayerColor and result.ply:GetPlayerColor() or Vector(1, 1, 1),
				bodygroups = {},
				accessories = istable(accessories) and accessories or {}
			}
			for _, bodygroup in ipairs(result.ply:GetBodyGroups() or {}) do
				snapshot.bodygroups[bodygroup.id or 0] = result.ply:GetBodygroup(bodygroup.id or 0)
			end
		end
		local slot = vgui.Create("DPanel", podium)
		slot.SlotCol, slot.SlotHeight = slotInfo.col, slotInfo.height
		slot:SetPaintBackground(false)
		function slot:Paint(w, h)
			surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, 235)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(medalCol.r, medalCol.g, medalCol.b, 40)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(medalCol.r, medalCol.g, medalCol.b, 210)
			surface.DrawOutlinedRect(0, 0, w, h, 2)
			DrawCRTCorners(1, 1, w - 2, h - 2, 10, medalCol.r, medalCol.g, medalCol.b, 230)
			draw.SimpleText(PLACE_LABELS[slotInfo.place], "SB_CRT_Item", 6, 5, medalCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end
		slot.Portrait = vgui.Create("ZGunGamePortrait", slot)
		slot.Portrait:ApplySnapshot(snapshot, medalCol)

		local caption = vgui.Create("DPanel", slot)
		caption:SetPaintBackground(false)
		caption:SetMouseInputEnabled(false)
		function caption:Paint(w, h)
			surface.SetDrawColor(8, 9, 9, 230)
			surface.DrawRect(0, 0, w, h)
			draw.SimpleText(FitName(result.name, "SB_CRT_Item", w - 10), "SB_CRT_Item", w * 0.5, 3, color_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			local killCount, karma = result.kills or 0, result.karma or 0
			draw.SimpleText(killCount .. (killCount == 1 and " KILL" or " KILLS"), "SB_CRT_Item", 6, h - 4, medalCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
			draw.SimpleText(karma > 0 and ("+" .. karma .. " KARMA") or "0 KARMA", "SB_CRT_Item", w - 6, h - 4, karma > 0 and color_karma or color_idle, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
		end
		slot.Caption = caption

		function slot:PerformLayout(w, h)
			local top = math.max(16, ScreenScale(14))
			local captionH = math.max(28, ScreenScale(22))
			if IsValid(self.Portrait) then
				self.Portrait:SetPos(2, top)
				self.Portrait:SetSize(math.max(8, w - 4), math.max(8, h - top - captionH))
			end
			if IsValid(self.Caption) then
				self.Caption:SetPos(2, h - captionH)
				self.Caption:SetSize(math.max(8, w - 4), captionH)
				self.Caption:MoveToFront()
			end
		end
		podium.Slots[#podium.Slots + 1] = slot
	end

	if restCount <= 0 then return end

	local scroll = vgui.Create("DScrollPanel", endPanel)
	scroll:Dock(FILL)
	scroll:DockMargin(2, 0, 2, 2)
	local vbar = scroll:GetVBar()
	vbar:SetWide(5)
	if vbar.SetHideButtons then vbar:SetHideButtons(true) end
	vbar.Paint = function(_, w, h)
		surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, 220)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(168, 168, 172, 70)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end
	vbar.btnUp.Paint = function() end
	vbar.btnDown.Paint = function() end
	vbar.btnGrip.Paint = function(self, w, h)
		local a = self:IsHovered() and 210 or 140
		surface.SetDrawColor(168, 168, 172, a)
		surface.DrawRect(1, 1, w - 2, h - 2)
	end

	local cols = vgui.Create("DPanel", scroll)
	cols:SetTall(colH)
	cols:Dock(TOP)
	cols:DockMargin(0, 0, 0, 1)
	function cols:Paint(w, h)
		draw.SimpleText("#", "SB_CRT_Item", 8, h * 0.5, color_idle_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("NAME", "SB_CRT_Item", 36, h * 0.5, color_idle_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("KILLS", "SB_CRT_Item", w - 86, h * 0.5, color_idle_dim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		draw.SimpleText("KARMA", "SB_CRT_Item", w - 8, h * 0.5, color_idle_dim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

	for index = 4, #list do
		local result = list[index]
		local line = vgui.Create("DPanel", scroll)
		line:SetTall(rowH)
		line:Dock(TOP)
		line:DockMargin(0, 0, 0, 1)
		function line:Paint(w, h)
			surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, 220)
			surface.DrawRect(0, 0, w, h)
			surface.SetDrawColor(168, 168, 172, 70)
			surface.DrawOutlinedRect(0, 0, w, h, 1)
			draw.SimpleText(tostring(index), "SB_CRT_Item", 8, h * 0.5, color_idle_dim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			draw.SimpleText(FitName(result.name, "SB_CRT_Item", w - 150), "SB_CRT_Item", 36, h * 0.5, color_text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			local killCount, karma = result.kills or 0, result.karma or 0
			draw.SimpleText(tostring(killCount), "SB_CRT_Item", w - 86, h * 0.5, color_idle, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			draw.SimpleText(karma > 0 and ("+" .. karma) or "0", "SB_CRT_Item", w - 8, h * 0.5, karma > 0 and color_karma or color_idle_dim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end
	end
end

net.Receive("gungame_start", function()
	CleanupGunGameClient()
	roundSeconds = net.ReadUInt(16)
	variationName = net.ReadString()
	variationDesc = net.ReadString()
	ladder = {}
	for index = 1, net.ReadUInt(8) do ladder[index] = net.ReadString() end
	currentStage, stageTotal = 1, math.max(#ladder, 1)
	stageKills, killsPerStage = 0, MODE.KillsPerStage or 2
	currentWeapon, nextWeapon, isFinalStage = ladder[1] or "", ladder[2] or "", false
	lastStageName = ""
	RevealBoxes(1, true)
	uiRevealAt = math.huge
	introUntil = CurTime() + 8.5
	StartGunGameTheme(CurrentRound() or MODE)
end)

net.Receive("gungame_grace", function()
	graceEnd = net.ReadFloat()
	graceDuration = math.max(graceEnd - CurTime(), 1)
	MODE.graceEnd = graceEnd
	uiRevealAt = CurTime() + graceDuration
end)

net.Receive("gungame_progress", function()
	local prevStage = currentStage
	currentStage = net.ReadUInt(12)
	stageTotal = net.ReadUInt(12)
	stageKills = net.ReadUInt(4)
	killsPerStage = math.max(1, net.ReadUInt(4))
	currentWeapon = net.ReadString()
	isFinalStage = net.ReadBool()
	nextWeapon = net.ReadString()
	if currentStage > prevStage then
		RevealBoxes(currentStage)
	end
end)

net.Receive("gungame_killfeed", function()
	table.insert(killFeed, 1, { killer = net.ReadString(), victim = net.ReadString(), time = CurTime() })
	while #killFeed > KILLFEED_MAX do table.remove(killFeed) end
end)

net.Receive("gungame_respawn", function()
	respawnAt = net.ReadFloat()
end)

net.Receive("gungame_final", function()
	local ply = net.ReadEntity()
	lastStageName = IsValid(ply) and ply:Nick() or "Someone"
	lastStageBannerUntil = CurTime() + 5
end)

net.Receive("gungame_end", function()
	HideRoundStandouts()
	net.ReadEntity()
	local list = {}
	for index = 1, math.min(net.ReadUInt(7), MAX_RESULTS) do
		list[index] = {
			name = net.ReadString(),
			kills = net.ReadUInt(16),
			stage = net.ReadUInt(12),
			karma = net.ReadUInt(10),
			ply = net.ReadEntity()
		}
		if net.ReadBool() then list[index].portrait = ReadPortraitSnapshot() end
	end
	StopGunGameTheme()
	CreateEndPanel(list)
end)

hook.Add("RoundInfoCalled", "gungame_cleanup_on_round_info", function(nextMode)
	timer.Simple(0, function()
		if nextMode ~= "gungame" then
			zb.SkipRoundStandouts = false
			CleanupGunGameClient()
		end
	end)
end)

function MODE:HUDPaint()
	uiPulse = uiPulse + FrameTime()
	local lply = LocalPlayer()
	local now = CurTime()

	if now >= uiRevealAt and roundSeconds > 0 then
		local remaining = math.max(0, (zb.ROUND_START or 0) + roundSeconds - now)
		local text = string.FormattedTime(remaining, "%02i:%02i")
		surface.SetFont("SB_CRT_Header")
		local textWidth, textHeight = surface.GetTextSize(text)
		local _, height = surface.GetTextSize(text)
		draw.SimpleText(text, "SB_CRT_Header", ScrW() / 2, ScreenScale(4) + height / 2, color_text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if introUntil > now and IsValid(lply) and lply:Alive() then
		if zb.RemoveFade then zb.RemoveFade() end
		local fade = math.Clamp(introUntil - now, 0, 1)
		local sw, sh = ScrW(), ScrH()
		draw.SimpleText("Gun Game", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(200, 200, 200, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("You are a Contender", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.48, Color(210, 210, 210, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText(variationName, "ZB_HomicideMedium", sw * 0.5, sh * 0.56, Color(220, 220, 220, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		if variationDesc ~= "" then
			draw.SimpleText(variationDesc, "ZB_HomicideMedium", sw * 0.5, sh * 0.61, Color(172, 180, 174, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		draw.SimpleText("Kill with the last weapon to win.", "ZB_HomicideMedium", sw * 0.5, sh * 0.88, Color(172, 180, 174, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if now < graceEnd then
		local pulse = 0.82 + math.abs(math.sin(uiPulse * 3)) * 0.18
		draw.SimpleText("Fighting starts in " .. math.max(1, math.ceil(graceEnd - now)), "ZB_HomicideMediumLarge", ScrW() / 2, ScrH() * 0.68, Color(188 * pulse, 188 * pulse, 188 * pulse), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	for index = #killFeed, 1, -1 do
		if now - killFeed[index].time > KILLFEED_LIFE then table.remove(killFeed, index) end
	end
	surface.SetFont("HomigradFontMedium")
	local _, lineH = surface.GetTextSize("Hg")
	lineH = lineH + ScreenScale(1)
	local feedX, feedY = ScrW() - ScreenScale(8), ScreenScale(6)
	for index, entry in ipairs(killFeed) do
		if index > KILLFEED_MAX then break end
		local alpha = 255 * (index >= KILLFEED_MAX and 0.7 or 1)
		if now - entry.time > KILLFEED_LIFE - KILLFEED_FADE then
			alpha = alpha * math.Clamp((KILLFEED_LIFE - (now - entry.time)) / KILLFEED_FADE, 0, 1)
		end
		local text = entry.killer .. " killed " .. entry.victim
		draw.SimpleText(text, "HomigradFontMedium", feedX + 1, feedY + (index - 1) * lineH + 1, Color(0, 0, 0, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		draw.SimpleText(text, "HomigradFontMedium", feedX, feedY + (index - 1) * lineH, Color(255, 255, 255, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
	end

	if IsValid(lply) and lply:Alive() and introUntil <= now then DrawGunBoxes() end

	if IsValid(lply) and not lply:Alive() and lply:Team() ~= TEAM_SPECTATOR and respawnAt > now then
		draw.SimpleText("Respawning in " .. math.max(1, math.ceil(respawnAt - now)), "ZB_HomicideMediumLarge", ScrW() / 2, ScrH() * 0.64, Color(210, 210, 210, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	if lastStageBannerUntil > now and lastStageName ~= "" then
		local alpha = math.Clamp((lastStageBannerUntil - now) / 5, 0, 1)
		local banner = lastStageName .. " reached the last weapon"
		surface.SetFont("SB_CRT_Item")
		local textW, textH = surface.GetTextSize(banner)
		local width, height = textW + ScreenScale(18), textH + ScreenScale(8)
		local x, y = ScrW() / 2 - width / 2, ScreenScale(36)
		surface.SetDrawColor(color_bezel.r, color_bezel.g, color_bezel.b, 220 * alpha)
		surface.DrawRect(x, y, width, height)
		surface.SetDrawColor(color_final.r, color_final.g, color_final.b, 200 * alpha)
		surface.DrawOutlinedRect(x, y, width, height, 1)
		surface.SetDrawColor(color_final.r, color_final.g, color_final.b, 28 * alpha)
		surface.DrawRect(x + 1, y + 1, width - 2, height - 2)
		draw.SimpleText(banner, "SB_CRT_Item", ScrW() / 2, y + height / 2, Color(color_final.r, color_final.g, color_final.b, 255 * alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
end

function MODE:RenderScreenspaceEffects()
	if graceEnd <= 0 or CurTime() >= graceEnd then return end
	local amount = math.Clamp((graceEnd - CurTime()) / graceDuration, 0, 1)
	DrawColorModify({
		["$pp_colour_addr"] = 0.02 * amount,
		["$pp_colour_addg"] = 0.02 * amount,
		["$pp_colour_addb"] = 0.02 * amount,
		["$pp_colour_brightness"] = -0.06 * amount,
		["$pp_colour_contrast"] = 1 - 0.18 * amount,
		["$pp_colour_colour"] = 1 - 0.55 * amount,
		["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0
	})
end

function MODE:RoundStart()
	zb.SkipRoundStandouts = false
	if IsValid(endPanel) then endPanel:Remove() end
	endPanel = nil
end

function MODE:EndRound()
	HideRoundStandouts()
	StopGunGameTheme()
end
