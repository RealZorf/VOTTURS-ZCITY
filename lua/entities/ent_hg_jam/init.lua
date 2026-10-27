AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local mins, maxs = Vector(-3, -3, -2), Vector(3, 3, 2)

function ENT:Initialize()
	self:SetModel(self.WorldModel)
	self:SetModelScale(self.ModelScale or 0.4)
	self:PhysicsInitBox(mins, maxs)
	self:SetCollisionBounds(mins, maxs)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
		phys:SetMass(1)
		phys:EnableMotion(true)
	end
end

function ENT:CanPickUp(ply)
	if not self.Blocking then return true end
	if not IsValid(ply) then return false end
	if self.BlockNormal and (ply:EyePos() - self:GetPos()):Dot(self.BlockNormal) < 0 then return false end

	return true
end

hook.Add("AllowPlayerPickup", "ent_hg_jam", function(ply, ent)
	if IsValid(ent) and ent:GetClass() == "ent_hg_jam" and not ent:CanPickUp(ply) then return false end
end)

function ENT:Use(ply)
	if not self:CanPickUp(ply) then return end

	self:UnBlock()
	ply:Give("weapon_hg_jam")
	ply:SelectWeapon("weapon_hg_jam")
	self:Remove()
end

function ENT:OnTakeDamage(dmginfo)
	if dmginfo:GetInflictor() == self then return end
	if dmginfo:IsDamageType(DMG_BLAST + DMG_BULLET + DMG_BUCKSHOT + DMG_BURN) and math.random(1, 5) == 1 then
		self:UnBlock()
		self:EmitSound("Wood_Plank.ImpactHard")
	end
end

function ENT:Think()
	if self.Blocking then
		for _, door in pairs(self.Doors) do
			if not IsValid(door) then
				self:UnBlock()
				break
			end

			door:Fire("lock", "", 0)
		end

		if not IsValid(self.Constraint) then
			self:UnBlock()
			self:EmitSound("Wood_Plank.ImpactSoft")
		end
	end

	self:NextThink(CurTime() + 0.1)
	return true
end

function ENT:UnBlock()
	if not self.Blocking then return end

	self.Blocking = false
	self.BlockNormal = nil

	for _, door in pairs(self.Doors) do
		if IsValid(door) and not self.DoorLocked then
			door:Fire("unlock", "", 0)
		end
	end

	self.Doors = {}
	self:EmitSound("Wood_Plank.ImpactSoft")
	self:EmitSound("Flesh.ImpactSoft")
	constraint.RemoveAll(self)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:EnableMotion(true) end
end

function ENT:Block(doors, bone, normal)
	if self.Blocking then return end

	self.Blocking = true
	self.Doors = doors
	self.BlockNormal = normal
	self.Constraint = constraint.Weld(self, doors[1], 0, bone or 0, 3000, true, false)

	for _, door in pairs(doors) do
		if IsValid(door) then door:Fire("lock", "", 0) end
	end

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then phys:EnableMotion(false) end

	self:EmitSound("Wood_Plank.ImpactSoft")
	self:EmitSound("Flesh.ImpactSoft")
end

function ENT:PhysicsCollide(data, physobj)
	if data.DeltaTime > 0.1 then
		self:EmitSound("Wood_Plank.ImpactSoft")
		self:EmitSound("Flesh.ImpactSoft")
	end
end
