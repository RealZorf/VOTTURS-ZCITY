if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_tpik_base"
SWEP.PrintName = "Trap Link"
SWEP.Category = "ZCity Other"
SWEP.Instructions = "Reveals traitor traps through walls.\n\nAim at a trap and press LMB or E to activate it."
SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false
SWEP.Slot = 4
SWEP.SlotPos = 5
SWEP.HomicideSWEP = true
SWEP.NoDrop = false
SWEP.WorkWithFake = true
SWEP.ActivationRange = 3333


SWEP.IdleHoldType = "normal"
SWEP.HoldType = "normal"
SWEP.ViewModel = ""
SWEP.WorldModel = "models/sirgibs/ragdoll/css/terror_arctic_radio.mdl"
SWEP.offsetVec = Vector(6, 5.5, -41)
SWEP.offsetAng = Angle(180, 160, 180)

function SWEP:CanPrimaryAttack()
	return true
end

function SWEP:CanSecondaryAttack()
	return false
end

function SWEP:PrimaryAttack()
	self:SetNextPrimaryFire(CurTime() + 0.2)
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
end

function SWEP:DrawWorldModel()
	if !self:GetOwner():IsPlayer() then
		self:DrawModel()
	end
end

function SWEP:DrawWorldModel2()
	self.model = IsValid(self.model) and self.model or ClientsideModel(self.WorldModel)
	local WorldModel = self.model
	local owner = hg.GetCurrentCharacter(self:GetOwner())

	WorldModel:SetNoDraw(true)
	WorldModel:SetModelScale(self.ModelScale or 1)

	if(IsValid(owner))then
		local offsetVec = self.offsetVec
		local offsetAng = self.offsetAng
		local boneid = owner:LookupBone("ValveBiped.Bip01_L_Hand")

		if(not boneid)then 
			return 
		end

		local matrix = owner:GetBoneMatrix(boneid)

		if(not matrix)then 
			return
		end

		local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())
		WorldModel:SetPos(newPos)
		WorldModel:SetAngles(newAng)
		WorldModel:SetupBones()

		WorldModel:DrawModel()
	else
		WorldModel:SetPos(self:GetPos())
		WorldModel:SetAngles(self:GetAngles())
		WorldModel:DrawModel()
	end
end

function SWEP:SetHold(value)
	self:SetWeaponHoldType(value)
	self:SetHoldType(value)
	self.holdtype = value
end

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_walkietalkie")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_walkietalkie.png"
	SWEP.BounceWeaponIcon = false
end

if(SERVER)then
	function SWEP:SetFakeGun(ent)
		self:SetNWEntity("fakeGun", ent)
		self.fakeGun = ent
	end

	function SWEP:RemoveFake()
		if(not IsValid(self.fakeGun))then 
			return 
		end

		self.fakeGun:Remove()
		self:SetFakeGun()
	end

	SWEP.RHandPos = Vector(0, 0, 0)

	function SWEP:CreateFake(ragdoll)
		if(IsValid(self:GetNWEntity("fakeGun")))then 
			return
		end

		local ent = ents.Create("prop_physics")
		local lh = ragdoll:GetPhysicsObjectNum(5)
		local rh = ragdoll:GetPhysicsObjectNum(7)

		rh:SetPos(rh:GetPos() + self:GetOwner():EyeAngles():Forward() * 20)
		rh:SetAngles(self:GetOwner():EyeAngles() + Angle(0, 0, -90))
		lh:SetPos(rh:GetPos())

		ent:SetModel(self.WorldModel)
		ent:SetPos(rh:GetPos())
		ent:SetAngles(rh:GetAngles() + Angle(0, 0, 180))
		ent:Spawn()

		ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		ent:SetOwner(ragdoll)
		ent:GetPhysicsObject():SetMass(0)
		ent:SetNoDraw(true)
		ent.dontPickup = true
		ent.fakeOwner = self

		ragdoll:DeleteOnRemove(ent)
		ragdoll.fakeGun = ent

		if(IsValid(ragdoll.ConsRH))then 
			ragdoll.ConsRH:Remove()
		end

		self:SetFakeGun(ent)
		ent:CallOnRemove("homigrad-swep", self.RemoveFake, self)

		local vec = Vector(0, 0, 0)
		vec:Set(-self.RHandPos or vector_origin)
		vec:Rotate(ent:GetAngles())

		rh:SetPos(ent:GetPos() + vec)
	end

	function SWEP:RagdollFunc(pos, angles, ragdoll)
		shadowControl = shadowControl or hg.ShadowControl
		local fakeGun = ragdoll.fakeGun

		--pos:Add(angles:Right() * 5)
		shadowControl(ragdoll, 5, 0.001, angles, 500, 30, pos, 500, 50)
	end
end

