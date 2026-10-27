if SERVER then AddCSLuaFile() end

SWEP.PrintName = "Door Wedge"
SWEP.Category = "ZCity Other"
SWEP.Instructions = "This is a heavy-duty commercial door wedge. It can be kicked into place to stop a door from moving.\n\nLeft click to jam a door.\nPress E to pick up wedge again."
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.HoldType = "slam"
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 4
SWEP.SlotPos = 4
SWEP.ModelScale = 0.4

SWEP.WorldModel = "models/props_junk/wood_pallet001a_chunka1.mdl"
SWEP.ViewModel = ""

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_jam")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_jam"
	SWEP.BounceWeaponIcon = false
end

SWEP.offsetVec = Vector(4, -1.6, -3)
SWEP.offsetAng = Angle(0, -90, 130)

local doors = {
	["prop_door"] = true,
	["prop_door_rotating"] = true,
	["func_door"] = true,
	["func_door_rotating"] = true,
	["func_breakable"] = true,
}

local JamPlacementRadius = 100

function SWEP:DrawWorldModel()
	self.model = IsValid(self.model) and self.model or ClientsideModel(self.WorldModel)
	local WorldModel = self.model
	local owner = self:GetOwner()

	if not IsValid(WorldModel) then return end

	WorldModel:SetNoDraw(true)
	WorldModel:SetModelScale(self.ModelScale or 0.4)

	if IsValid(owner) then
		local boneid = owner:LookupBone(((owner.organism and owner.organism.rarmamputated) or (owner.zmanipstart ~= nil and owner.zmanipseq == "interact" and not owner.organism.larmamputated)) and "ValveBiped.Bip01_L_Hand" or "ValveBiped.Bip01_R_Hand")
		if not boneid then return end
		local matrix = owner:GetBoneMatrix(boneid)
		if not matrix then return end
		local newPos, newAng = LocalToWorld(self.offsetVec, self.offsetAng, matrix:GetTranslation(), matrix:GetAngles())
		WorldModel:SetPos(newPos)
		WorldModel:SetAngles(newAng)
		WorldModel:SetupBones()
	else
		WorldModel:SetPos(self:GetPos())
		WorldModel:SetAngles(self:GetAngles())
	end

	WorldModel:DrawModel()
end

function SWEP:Initialize()
	self:SetHoldType("slam")
end

function SWEP:Think()
	if not self:GetOwner():KeyDown(IN_ATTACK) then
		self:SetHolding(math.max(self:GetHolding() - 3, 0))
	end
end

function SWEP:Animation()
	local owner = self:GetOwner()
	if owner.zmanipstart ~= nil and not owner.organism.larmamputated then return end

	local hold = self:GetHolding()
	hg.bone.Set(owner, "r_upperarm", vector_origin, Angle(20, -hold / 2 - 20, 0))
	hg.bone.Set(owner, "r_forearm", vector_origin, Angle(0, hold, 0))
end

function SWEP:SetupDataTables()
	self:NetworkVar("Float", 0, "Holding")
end

if CLIENT then
	local csent = ClientsideModel(SWEP.WorldModel)
	csent:SetNoDraw(true)

	function SWEP:DrawHUD()
		if not IsValid(csent) then
			csent = ClientsideModel(self.WorldModel)
			csent:SetNoDraw(true)
		end

		local ply = self:GetOwner()
		local tr = ply:GetEyeTrace()
		if not tr.Hit or tr.HitSky or not tr.HitPos then return end
		if tr.HitPos:DistToSqr(ply:GetPos()) > JamPlacementRadius * JamPlacementRadius then return end
		if not (IsValid(tr.Entity) and doors[tr.Entity:GetClass()]) then return end

		local pos, ang = tr.HitPos, tr.HitNormal:Angle()
		ang:RotateAroundAxis(ang:Right(), -90)
		ang:RotateAroundAxis(ang:Up(), -90)
		ang:RotateAroundAxis(ang:Forward(), 90)

		cam.Start3D()
			csent:SetModelScale(self.ModelScale or 0.4)
			csent:SetPos(pos)
			csent:SetAngles(ang)
			csent:SetMaterial("models/wireframe")
			csent:DrawModel()
		cam.End3D()
	end
end

function SWEP:PrimaryAttack()
	local ply = self:GetOwner()
	local tr = ply:GetEyeTrace()
	if not tr.Hit or tr.HitSky then return end
	if tr.HitPos:DistToSqr(ply:GetPos()) > JamPlacementRadius * JamPlacementRadius then return end
	if not (IsValid(tr.Entity) and doors[tr.Entity:GetClass()]) then return end

	self:SetHolding(math.min(self:GetHolding() + 5, 100))
	if self:GetHolding() < 100 then return end
	if CLIENT then return end

	local ang = tr.HitNormal:Angle()
	local pos = tr.HitPos + ang:Forward() * 4
	ang:RotateAroundAxis(ang:Right(), -90)
	ang:RotateAroundAxis(ang:Up(), -90)
	ang:RotateAroundAxis(ang:Forward(), 90)

	local jammed = {tr.Entity}
	for _, ent in ipairs(ents.FindInSphere(tr.HitPos, 65)) do
		if IsValid(ent) and doors[ent:GetClass()] then
			jammed[#jammed + 1] = ent
		end
	end

	local ent = ents.Create("ent_hg_jam")
	ent:SetAngles(ang)
	ent:SetPos(pos)
	ent:Spawn()
	ent:Activate()
	ent:Block(jammed, tr.PhysicsBone or 0, tr.HitNormal)
	ent.owner = ply

	ply:SelectWeapon("weapon_hands_sh")
	self:Remove()
end

function SWEP:SecondaryAttack()
end
