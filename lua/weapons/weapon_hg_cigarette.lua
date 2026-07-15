if SERVER then
	AddCSLuaFile()

	local requiredFiles = {
		"models/props/cigarettes/cigarettebox.mdl",
		"models/props/cigarettes/cigarettebox.vvd",
		"models/props/cigarettes/cigarettebox.dx80.vtx",
		"models/props/cigarettes/cigarettebox.dx90.vtx",
		"models/props/cigarettes/cigarettebox.phy",
		"models/props/cigarettes/cigarette_marlboro.mdl",
		"models/props/cigarettes/cigarette_marlboro.vvd",
		"models/props/cigarettes/cigarette_marlboro.dx80.vtx",
		"models/props/cigarettes/cigarette_marlboro.dx90.vtx",
		"materials/props/cigarettes/cigarette_marlboro.vmt",
		"materials/props/cigarettes/cigarette_marlboro.vtf",
		"materials/props/cigarettes/cigarette_marlboro_lit.vmt",
		"materials/props/cigarettes/cigarette_marlboro_lit.vtf",
		"materials/props/cigarettes/cigarette_marlboro_out.vmt",
		"materials/props/cigarettes/cigarette_n.vtf",
		"materials/props/cigarettes/cigarettelit_i2.vtf",
		"materials/props/cigarettes/cigarettebox_marlboro.vmt",
		"materials/props/cigarettes/cigarettepack.vtf",
		"materials/props/cigarettes/cigarettepack_n.vtf",
		"materials/props/cigarettes/cigarettepack_exp.vtf",
		"materials/vgui/cigarette.png",
		"sound/pat_cigarette/inhale.wav",
		"sound/pat_cigarette/exhale.wav"
	}

	for _, path in ipairs(requiredFiles) do
		resource.AddFile(path)
	end
end

SWEP.Base = "weapon_tpik_base"
SWEP.PrintName = "Cigarette"
SWEP.Category = "ZCity Other"
SWEP.Instructions = "Hold LMB: Light / smoke\nRMB: Extinguish"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3
SWEP.SlotPos = 6
SWEP.Weight = 0
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.ViewModel = ""
SWEP.WorldModel = "models/props/cigarettes/cigarettebox.mdl"
SWEP.WorldModelReal = "models/weapons/sweps/stalker2/bread/v_item_bread.mdl"
SWEP.WorldModelExchange = "models/props/cigarettes/cigarette_marlboro.mdl"
SWEP.PAT_IconPath = "materials/vgui/cigarette.png"
SWEP.IconOverride = SWEP.PAT_IconPath
SWEP.WepSelectIcon = CLIENT and Material(SWEP.PAT_IconPath) or nil
SWEP.BounceWeaponIcon = false
SWEP.DrawWeaponInfoBox = true
SWEP.PAT_IconScale = 0.65
SWEP.PAT_IconYOffset = -16
SWEP.HoldType = "normal"
SWEP.WorkWithFake = true

if CLIENT then
	function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
		self:PrintWeaponInfo(x + wide + 20, y + tall * 0.15, alpha)

		self.PAT_IconMat = self.PAT_IconMat or Material(self.PAT_IconPath, "smooth noclamp")
		if not self.PAT_IconMat or self.PAT_IconMat:IsError() then return end

		surface.SetDrawColor(255, 255, 255, alpha or 255)
		surface.SetMaterial(self.PAT_IconMat)

		local size = math.min(wide, tall) * self.PAT_IconScale
		local ix = x + (wide - size) * 0.5
		local iy = y + (tall - size) * 0.5 + self.PAT_IconYOffset

		surface.DrawTexturedRect(ix, iy, size, size)
	end
end

SWEP.setlh = true
SWEP.setrh = false
SWEP.basebone = 56
SWEP.weaponPos = Vector(-0.25, 1.5, 0)
SWEP.weaponAng = Angle(0, 180, 0)
SWEP.modelscale = 0.7
SWEP.BaseCigaretteModelScale = 0.7
SWEP.modelscale2 = 1

SWEP.HoldPos = Vector(2, 2, 2)
SWEP.HoldAng = Angle(-10, 20, -4)
SWEP.HoldClampMin = -50
SWEP.HoldClampMax = 50

SWEP.DeploySnd = "physics/cardboard/cardboard_box_impact_soft1.wav"
SWEP.BurnDuration = 180
SWEP.DragDelay = 3.2
SWEP.InhaleLeadTime = 0.65
SWEP.TipUsesPositiveEnd = true
SWEP.InhaleSound = "pat_cigarette/inhale.wav"
SWEP.ExhaleSound = "pat_cigarette/exhale.wav"
SWEP.SmokeOrganismDuration = 2.1
SWEP.SmokeOxygenRegenMul = 0.08
SWEP.SmokeStaminaRegenMul = 0.94
SWEP.SmokeOxygenCost = 0.25
SWEP.SmokeAnalgesia = 0.025
SWEP.SmokeAnalgesiaCap = 0.12
SWEP.SmokeFearRelief = 0.04
SWEP.SmokeHeartbeatIncrease = 2
SWEP.SmokeCOIncrease = 0.15
SWEP.SmokeAimPuffsRequired = 3
SWEP.SmokeAimPuffWindow = 35
SWEP.SmokeAimDuration = 25
SWEP.SmokeAimMul = 0.94
SWEP.MinimumBurnLengthScale = 0.42

SWEP.AnimList = {
	["deploy"] = {"idle", 1, false},
	["idle"] = {"idle", 5, true},
	["smoke"] = {"use", 1.6, false}
}

function SWEP:SetupDataTables()
	self:NetworkVar("Bool", 0, "Lit")
	self:NetworkVar("Bool", 1, "Spent")
	self:NetworkVar("Bool", 2, "HasBurned")
	self:NetworkVar("Bool", 3, "Lighting")
	self:NetworkVar("Bool", 4, "Smoking")
	self:NetworkVar("Float", 0, "BurnEnd")
	self:NetworkVar("Float", 1, "BurnRemaining")
	self:NetworkVar("Float", 2, "PuffAt")
	self:NetworkVar("Int", 0, "PuffSerial")
end

function SWEP:GetStateSkin()
	if self:GetLit() then return 1 end
	if self:GetSpent() or self:GetHasBurned() then return 2 end

	return 0
end

function SWEP:ApplyServerVisual()
	if CLIENT then return end

	self:SetSkin(0)
end

function SWEP:InitAdd()
	if SERVER then
		self:SetModel(self.WorldModel)
		self:SetLit(false)
		self:SetSpent(false)
		self:SetHasBurned(false)
		self:SetLighting(false)
		self:SetSmoking(false)
		self:SetBurnEnd(0)
		self:SetBurnRemaining(self.BurnDuration)
		self:SetPuffAt(0)
		self:SetPuffSerial(0)
		self:ApplyServerVisual()
	else
		self.ClientPuffSerial = 0
	end
end

function SWEP:CanUseCigarette()
	local owner = self:GetOwner()

	return IsValid(owner) and owner:IsPlayer() and owner:Alive()
end

function SWEP:BurnOut()
	if CLIENT then return end

	self:StopSmoking()
	self:SetLighting(false)
	self:SetLit(false)
	self:SetSpent(true)
	self:SetHasBurned(true)
	self:SetBurnEnd(0)
	self:SetBurnRemaining(0)
	self:ApplyServerVisual()

	self:EmitSound("ambient/fire/mtov_flame2.wav", 45, 120, 0.25, CHAN_ITEM)
end

function SWEP:LightCigarette()
	if CLIENT or self:GetLighting() or self:GetLit() or self:GetSpent() then return end
	if not self:CanUseCigarette() or self:GetBurnRemaining() <= 0 then return end

	local owner = self:GetOwner()
	self:SetLighting(true)
	self:SetNextPrimaryFire(CurTime() + 1)
	self:SetNextSecondaryFire(CurTime() + 1)
	self:PlayAnim("smoke")
	owner:EmitSound("weapons/molotov/handling/molotov_lighter_strike.wav", 55, 108, 0.45, CHAN_ITEM)

	timer.Simple(0.35, function()
		if not IsValid(self) or not self:GetLighting() then return end

		local currentOwner = self:GetOwner()
		if not IsValid(currentOwner) or currentOwner:GetActiveWeapon() ~= self then
			self:SetLighting(false)
			return
		end

		local remaining = math.max(self:GetBurnRemaining(), 0)
		if remaining <= 0 then
			self:BurnOut()
			return
		end

		self:SetLighting(false)
		self:SetLit(true)
		self:SetHasBurned(true)
		self:SetBurnEnd(CurTime() + remaining)
		self:ApplyServerVisual()
		self:EmitSound("weapons/molotov/handling/molotov_ignite.wav", 52, 118, 0.35, CHAN_ITEM)
	end)
end

function SWEP:ExtinguishCigarette(playSound)
	if CLIENT then return end

	self:StopSmoking()
	self:SetLighting(false)
	if not self:GetLit() then return end

	local remaining = math.max(self:GetBurnEnd() - CurTime(), 0)
	self:SetLit(false)
	self:SetBurnEnd(0)
	self:SetBurnRemaining(remaining)
	self:SetHasBurned(true)

	if remaining <= 0 then
		self:BurnOut()
		return
	end

	self:ApplyServerVisual()
	if playSound ~= false then
		self:EmitSound("ambient/fire/mtov_flame2.wav", 42, 130, 0.2, CHAN_ITEM)
	end
end

function SWEP:TriggerPuff()
	if CLIENT or not self:GetLit() or not self:GetSmoking() or not self:CanUseCigarette() then return end

	local owner = self:GetOwner()
	local puffAt = CurTime() + 0.72
	self:SetPuffAt(puffAt)
	self:SetPuffSerial(self:GetPuffSerial() + 1)

	timer.Simple(math.max(puffAt - CurTime(), 0), function()
		if not IsValid(self) or not self:GetLit() or self:GetOwner() ~= owner or not IsValid(owner) then return end

		self:StopInhaleSound()
		owner:EmitSound(self.ExhaleSound, 55, 100, 0.52, CHAN_BODY)
	end)

	hook.Run("HomigradCigarettePuff", owner, self)
end

function SWEP:StartInhaleSound()
	if CLIENT or self.CigaretteInhalePlaying then return end

	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	self.CigaretteInhalePlaying = true
	owner:StopSound(self.InhaleSound)
	owner:EmitSound(self.InhaleSound, 52, 100, 0.46, CHAN_BODY)
end

function SWEP:StopInhaleSound()
	if CLIENT or not self.CigaretteInhalePlaying then return end

	self.CigaretteInhalePlaying = nil
	local owner = self:GetOwner()
	if IsValid(owner) then
		owner:StopSound(self.InhaleSound)
	end
end

function SWEP:StartSmoking()
	if CLIENT or self:GetSmoking() or not self:GetLit() or not self:CanUseCigarette() then return end

	self:SetSmoking(true)
	self.NextHeldPuff = CurTime() + self.InhaleLeadTime
	self:StartInhaleSound()
	self:PlayAnim("smoke")
end

function SWEP:StopSmoking()
	if CLIENT or not self:GetSmoking() then return end

	self:SetSmoking(false)
	self.NextHeldPuff = nil
	self:StopInhaleSound()
	if IsValid(self:GetOwner()) then
		self:PlayAnim("idle")
	end
end

function SWEP:CustomTiming()
	if self:GetSmoking() then return 0.64 end
end

function SWEP:PrimaryAttack()
	if CLIENT then return end
	if not self:CanUseCigarette() then return end

	if self:GetLit() then
		self:SetNextPrimaryFire(CurTime() + 0.2)
		self:StartSmoking()
	else
		self:LightCigarette()
	end
end

function SWEP:SecondaryAttack()
	if CLIENT then return end
	if self:GetLighting() then
		self:SetLighting(false)
		return
	end

	if not self:GetLit() then return end

	self:SetNextPrimaryFire(CurTime() + 0.5)
	self:SetNextSecondaryFire(CurTime() + 0.5)
	self:ExtinguishCigarette(true)
end

function SWEP:Holster(nextWeapon)
	if SERVER then
		self:StopSmoking()
		self:SetLighting(false)
		self:ExtinguishCigarette(false)
	end

	return self.BaseClass.Holster(self, nextWeapon)
end

function SWEP:OwnerChanged()
	if SERVER and not IsValid(self:GetOwner()) then
		self:SetLighting(false)
		self:ExtinguishCigarette(false)
	end

	return self.BaseClass.OwnerChanged(self)
end

function SWEP:ThinkAdd()
	if SERVER then
		if self:GetLit() and self:GetBurnEnd() > 0 and CurTime() >= self:GetBurnEnd() then
			self:BurnOut()
			return
		end

		local owner = self:GetOwner()
		local wantsToSmoke = self:GetLit()
			and IsValid(owner)
			and owner:GetActiveWeapon() == self
			and owner:KeyDown(IN_ATTACK)

		if wantsToSmoke then
			self:StartSmoking()
			local puffIn = (self.NextHeldPuff or 0) - CurTime()
			if puffIn > 0 and puffIn <= self.InhaleLeadTime then
				self:StartInhaleSound()
			end

			if (self.NextHeldPuff or 0) <= CurTime() then
				self:TriggerPuff()
				self.NextHeldPuff = CurTime() + self.DragDelay
			end
		else
			self:StopSmoking()
		end

		return
	end
end

if SERVER then
	hook.Add("HomigradCigarettePuff", "PAT_Cigarette_OrganismPuff", function(owner, cigarette)
		if not IsValid(owner) or not owner:IsPlayer() or not owner:Alive() then return end
		if not IsValid(cigarette) then return end

		local org = owner.organism
		if not org or not org.o2 or not org.stamina then return end

		local duration = cigarette.SmokeOrganismDuration or 2.1
		org.cigaretteSmokeUntil = math.max(org.cigaretteSmokeUntil or 0, CurTime() + duration)
		org.cigaretteOxygenRegenMul = cigarette.SmokeOxygenRegenMul or 0.08
		org.cigaretteStaminaRegenMul = cigarette.SmokeStaminaRegenMul or 0.94
		org.o2[1] = math.max((org.o2[1] or 0) - (cigarette.SmokeOxygenCost or 0.25), 0)
		org.lastCOBreathe = CurTime()
		org.CO = math.min((org.CO or 0) + (cigarette.SmokeCOIncrease or 0.15), 30)
		org.analgesia = math.min((org.analgesia or 0) + (cigarette.SmokeAnalgesia or 0.025), cigarette.SmokeAnalgesiaCap or 0.12)
		org.fear = math.max((org.fear or 0) - (cigarette.SmokeFearRelief or 0.04), -1)
		org.fearadd = math.max((org.fearadd or 0) - (cigarette.SmokeFearRelief or 0.04), 0)
		org.heartbeat = math.min((org.heartbeat or 70) + (cigarette.SmokeHeartbeatIncrease or 2), 300)

		local now = CurTime()
		local puffWindow = cigarette.SmokeAimPuffWindow or 35
		if not org.cigaretteLastPuff or now - org.cigaretteLastPuff > puffWindow then
			org.cigaretteAimPuffs = 0
		end

		org.cigaretteLastPuff = now
		org.cigaretteAimPuffs = math.min((org.cigaretteAimPuffs or 0) + 1, cigarette.SmokeAimPuffsRequired or 3)

		if org.cigaretteAimPuffs >= (cigarette.SmokeAimPuffsRequired or 3) then
			org.cigaretteAimMul = math.Clamp(cigarette.SmokeAimMul or 0.94, 0.85, 1)
			org.cigaretteAimUntil = now + (cigarette.SmokeAimDuration or 25)
		end
	end)

	hook.Add("Org Think", "PAT_Cigarette_OrganismRecovery", function(_, org)
		local now = CurTime()
		if org.cigaretteSmokeUntil and org.cigaretteSmokeUntil <= now then
			org.cigaretteSmokeUntil = nil
			org.cigaretteOxygenRegenMul = nil
			org.cigaretteStaminaRegenMul = nil
		end

		if org.cigaretteAimUntil and org.cigaretteAimUntil <= now then
			org.cigaretteAimUntil = nil
			org.cigaretteAimMul = nil
			org.cigaretteAimPuffs = nil
			org.cigaretteLastPuff = nil
		end
	end)
end

if CLIENT then
	local cigaretteFingerPose = {
		{"ValveBiped.Bip01_L_Finger0", Angle(2, 0, 0)},
		{"ValveBiped.Bip01_L_Finger1", Angle(1, 7, 7)},
		{"ValveBiped.Bip01_L_Finger11", Angle(4, 0, -3)},
		{"ValveBiped.Bip01_L_Finger2", Angle(-5, -25, -5)},
		{"ValveBiped.Bip01_L_Finger21", Angle(4, -5, 0)},
		{"ValveBiped.Bip01_L_Finger3", Angle(3, -25, 2)},
		{"ValveBiped.Bip01_L_Finger31", Angle(3, -22, 0)},
		{"ValveBiped.Bip01_L_Finger4", Angle(2, -32, 0)},
		{"ValveBiped.Bip01_L_Finger41", Angle(2, -28, 0)}
	}
	local smokeMaterials = {}
	for index = 1, 16 do
		local suffix = index < 10 and "000" .. index or "00" .. index
		smokeMaterials[index] = Material("particle/smokesprites_" .. suffix, "smooth")
	end
	local smokeColor = Color(198, 202, 194)
	local maxSmokePuffs = 192
	local smokePuffs = {}
	local clientCigarettes = {}
	local nextCigaretteRefresh = 0
	local function getAxisValue(vector, axis)
		if axis == "x" then return vector.x end
		if axis == "y" then return vector.y end

		return vector.z
	end

	local function setAxisValue(vector, axis, value)
		if axis == "x" then
			vector.x = value
		elseif axis == "y" then
			vector.y = value
		else
			vector.z = value
		end
	end

	local function applyFingerRotation(character, boneName, adjustment)
		local bone = character:LookupBone(boneName)
		if not bone then return end

		local matrix = character:GetBoneMatrix(bone)
		if not matrix then return end

		local _, angles = LocalToWorld(vector_origin, adjustment, matrix:GetTranslation(), matrix:GetAngles())
		matrix:SetAngles(angles)
		hg.bone_apply_matrix(character, bone, matrix)
	end

	function SWEP:PostSetHandPos()
		local owner = self:GetOwner()
		if not IsValid(owner) then return end

		local character = hg.GetCurrentCharacter(owner)
		if not IsValid(character) then return end
		if not hg.set_hold then return end

		hg.set_hold(character, "normal")

		for _, pose in ipairs(cigaretteFingerPose) do
			applyFingerRotation(character, pose[1], pose[2])
		end
	end

	local function addSmokePuff(position, velocity, lifetime, startSize, endSize, alpha)
		smokePuffs[#smokePuffs + 1] = {
			position = position,
			velocity = velocity,
			created = CurTime(),
			die = CurTime() + lifetime,
			startSize = startSize,
			endSize = endSize,
			alpha = alpha,
			material = smokeMaterials[math.random(#smokeMaterials)],
			color = Color(smokeColor.r, smokeColor.g, smokeColor.b, 0)
		}

		if #smokePuffs > maxSmokePuffs then
			table.remove(smokePuffs, 1)
		end
	end

	function SWEP:GetCigaretteLengthScale()
		if self:GetSpent() then return self.MinimumBurnLengthScale end
		if not self:GetHasBurned() then return 1 end

		local remaining = self:GetBurnRemaining()
		if self:GetLit() and self:GetBurnEnd() > 0 then
			remaining = math.max(self:GetBurnEnd() - CurTime(), 0)
		end

		local fraction = math.Clamp(remaining / math.max(self.BurnDuration, 0.01), 0, 1)
		return Lerp(fraction, self.MinimumBurnLengthScale, 1)
	end

	function SWEP:GetCigaretteLengthData(model)
		if self.ClientLengthModel == model and self.ClientLengthAxis then
			return self.ClientLengthAxis, self.ClientLengthAnchor, self.ClientLengthTip
		end

		local mins, maxs = model:GetModelBounds()
		local extents = maxs - mins
		local axis = "x"
		if extents.y >= extents.x and extents.y >= extents.z then
			axis = "y"
		elseif extents.z >= extents.x and extents.z >= extents.y then
			axis = "z"
		end

		local tip = self.TipUsesPositiveEnd and getAxisValue(maxs, axis) or getAxisValue(mins, axis)
		local anchor = self.TipUsesPositiveEnd and getAxisValue(mins, axis) or getAxisValue(maxs, axis)
		self.ClientLengthModel = model
		self.ClientLengthAxis = axis
		self.ClientLengthAnchor = anchor
		self.ClientLengthTip = tip

		return axis, anchor, tip
	end

	function SWEP:ApplyClientVisual()
		local model = self.worldModel2
		if not IsValid(model) then return end

		local skin = self:GetStateSkin()
		local lengthScale = math.Round(self:GetCigaretteLengthScale(), 3)
		if self.ClientVisualModel == model and self.ClientVisualSkin == skin and self.ClientVisualLengthScale == lengthScale and self.ClientVisualTransformMode == "native-length" then return end

		model:SetSkin(skin)

		local axis, anchor = self:GetCigaretteLengthData(model)
		local inverseLength = 1 / math.max(lengthScale, 0.01)
		local scale = Vector(inverseLength, inverseLength, inverseLength)
		local translation = Vector(0, 0, 0)
		setAxisValue(scale, axis, 1)
		setAxisValue(translation, axis, anchor * (1 - lengthScale) * self.BaseCigaretteModelScale)

		local renderMatrix = Matrix()
		renderMatrix:SetScale(scale)
		renderMatrix:SetTranslation(translation)
		model:EnableMatrix("RenderMultiply", renderMatrix)
		self.modelscale = self.BaseCigaretteModelScale * lengthScale
		model:SetModelScale(self.modelscale)

		self.ClientVisualModel = model
		self.ClientVisualSkin = skin
		self.ClientVisualLengthScale = lengthScale
		self.ClientVisualTransformMode = "native-length"
	end

	function SWEP:GetCigaretteTip()
		local model = self.worldModel2
		if not IsValid(model) then return nil end

		local origin = model:GetRenderOrigin() or model:GetPos()
		local angles = model:GetRenderAngles() or model:GetAngles()
		local mins, maxs = model:GetModelBounds()
		local localTip = (mins + maxs) * 0.5
		local axis, anchor, tip = self:GetCigaretteLengthData(model)
		setAxisValue(localTip, axis, anchor + (tip - anchor) * self:GetCigaretteLengthScale())

		localTip = localTip * self.BaseCigaretteModelScale
		local position, tipAngles = LocalToWorld(localTip, angle_zero, origin, angles)

		return position, tipAngles
	end

	function SWEP:EmitTipSmoke(position)
		if (self.NextTipSmoke or 0) > CurTime() then return end
		if EyePos():DistToSqr(position) > 2200 * 2200 then return end

		self.NextTipSmoke = CurTime() + math.Rand(0.14, 0.2)
		addSmokePuff(
			position + VectorRand() * 0.12,
			Vector(math.Rand(-0.8, 0.8), math.Rand(-0.8, 0.8), math.Rand(5, 8)),
			math.Rand(1.8, 2.6),
			math.Rand(0.7, 1),
			math.Rand(4.5, 6.5),
			math.Rand(58, 82)
		)
	end

	function SWEP:GetMouthTransform(owner)
		local attachment = owner:LookupAttachment("mouth")
		if attachment and attachment > 0 then
			local data = owner:GetAttachment(attachment)
			if data then return data.Pos, data.Ang end
		end

		local head = owner:LookupBone("ValveBiped.Bip01_Head1")
		local matrix = head and owner:GetBoneMatrix(head)
		if matrix then
			local angles = matrix:GetAngles()
			return matrix:GetTranslation() + angles:Forward() * 4, angles
		end

		return owner:EyePos() + owner:EyeAngles():Forward() * 4, owner:EyeAngles()
	end

	function SWEP:EmitExhale()
		local owner = self:GetOwner()
		if not IsValid(owner) then return end

		local position, angles = self:GetMouthTransform(owner)
		if EyePos():DistToSqr(position) > 2200 * 2200 then return end

		for _ = 1, 7 do
			addSmokePuff(
				position + angles:Forward() * math.Rand(0, 1.5),
				angles:Forward() * math.Rand(12, 22) + VectorRand() * 2 + vector_up * math.Rand(1, 4),
				math.Rand(1.2, 1.9),
				math.Rand(1, 1.5),
				math.Rand(5, 8),
				math.Rand(68, 92)
			)
		end
	end

	function SWEP:HandleClientPuff()
		local serial = self:GetPuffSerial()
		if serial ~= (self.ClientPuffSerial or 0) then
			self.ClientPuffSerial = serial
			local puffAt = self:GetPuffAt()
			if puffAt >= CurTime() - 0.15 then
				self.ClientExhaleAt = math.max(puffAt, CurTime())
			end
		end

		if not self.ClientExhaleAt or CurTime() < self.ClientExhaleAt then return end

		self.ClientExhaleAt = nil
		self:EmitExhale()
	end

	function SWEP:DrawPostWorldModel()
		self:ApplyClientVisual()

		if not self:GetLit() then return end

		self:HandleClientPuff()
		local position = self:GetCigaretteTip()
		if position then
			self:EmitTipSmoke(position)
		end
	end

	function SWEP:DrawWorldModel2()
		if not IsValid(self:GetOwner()) then
			self:SetSkin(0)
			self:DrawModel()
			return
		end

		self.BaseClass.DrawWorldModel2(self)
	end

	hook.Add("Think", "PAT_Cigarette_ClientEffects", function()
		if nextCigaretteRefresh <= CurTime() then
			clientCigarettes = ents.FindByClass("weapon_hg_cigarette")
			nextCigaretteRefresh = CurTime() + 0.5
		end

		for _, cigarette in ipairs(clientCigarettes) do
			if IsValid(cigarette) and cigarette:GetLit() then
				cigarette:ApplyClientVisual()
				cigarette:HandleClientPuff()

				local position = cigarette:GetCigaretteTip()
				if position then
					cigarette:EmitTipSmoke(position)
				end
			end
		end
	end)

	hook.Add("PostDrawTranslucentRenderables", "PAT_Cigarette_SmokeRender", function(_, drawingSkybox)
		if drawingSkybox then return end

		local currentTime = CurTime()

		for index = #smokePuffs, 1, -1 do
			local puff = smokePuffs[index]
			if puff.die <= currentTime then
				table.remove(smokePuffs, index)
			else
				local lifetime = puff.die - puff.created
				local age = currentTime - puff.created
				local fraction = math.Clamp(age / lifetime, 0, 1)
				local fadeIn = math.Clamp(age / 0.12, 0, 1)
				local alpha = puff.alpha * fadeIn * (1 - fraction)
				local position = puff.position + puff.velocity * age + vector_up * (age * age * 1.5)
				local size = Lerp(fraction, puff.startSize, puff.endSize)

				puff.color.a = alpha
				render.SetMaterial(puff.material)
				render.DrawSprite(position, size, size, puff.color)
			end
		end
	end)
end

function SWEP:OnRemove()
	if self.BaseClass.OnRemove then
		self.BaseClass.OnRemove(self)
	end
end
