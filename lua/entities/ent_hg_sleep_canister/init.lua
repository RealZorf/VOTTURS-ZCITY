AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self.spawntime = CurTime()
	self.particles = {}
	self:SetModel(self.Model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:SetUseType(SIMPLE_USE)
	self:DrawShadow(true)

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetMass(1)
		phys:Wake()
		phys:EnableMotion(true)
	end
end

local ents_FindInSphere, CurTime, ipairs, table, math, VectorRand = ents.FindInSphere, CurTime, ipairs, table, math, VectorRand

local function isChemistSubRole(ent)
	local owner = ent.organism and ent.organism.owner
	local subRole = IsValid(owner) and owner.SubRole or ent.SubRole

	return subRole == "traitor_chemist" or subRole == "traitor_chemist_soe"
end

local function canSedate(ent)
	if not ent.organism then return false end
	if ent.organism.holdingbreath then return false end
	local owner = ent.organism.owner
	if not IsValid(owner) or not owner:IsPlayer() then return false end
	if owner:GetNWFloat("HMCD_ChemicalResistanceUntil", 0) > CurTime() then return false end
	if isChemistSubRole(ent) then return false end
	if owner.armors["face"] == "mask2" then return false end
	if ent.PlayerClassName == "Combine" then return false end

	return true
end

function ENT:Think()
	local activeDelay = self.ActiveDelay or 10
	local activeLifetime = self.ActiveLifetime or 90
	local activeStart = self.spawntime + activeDelay
	local activeEnd = activeStart + activeLifetime

	if CurTime() >= activeEnd then
		self:Remove()
		return
	end

	if activeStart > CurTime() then return end

	if (#self.particles < self.totalparticles) and ((math.Round(CurTime() - self.spawntime) % 3) == 0) then
		table.insert(self.particles, {self:GetPos(), VectorRand(-5, 5), CurTime() + 60})
	end

	if (#self.particles == self.totalparticles) and not self.particles[#self.particles] then
		return
	end

	for i, tbl in ipairs(self.particles) do
		if not tbl then continue end

		local pos, vel, time = tbl[1], tbl[2], tbl[3]
		if time < CurTime() then
			self.particles[i] = false
			continue
		end

		tbl[2] = vel - vector_up * 0.2

		local tr = util.TraceLine({
			start = pos,
			endpos = pos + vel,
			filter = self,
			mask = bit.bor(MASK_SOLID_BRUSHONLY, CONTENTS_WATER)
		})

		tbl[1] = tr.Hit and tr.HitPos or pos + vel

		local velLen = vel:Length()
		if tr.Hit then
			local vec = vel:Angle()
			vec:RotateAroundAxis(tr.HitNormal, 180)
			tbl[2] = -vec:Forward() * velLen
		end

		for _, ent in ipairs(ents_FindInSphere(pos, self.ExposureRadius or 64)) do
			if not canSedate(ent) then continue end
			if util.TraceLine({start = pos, endpos = ent:GetPos(), filter = {self, ent}, mask = MASK_SOLID_BRUSHONLY}).Hit then continue end

			ent.organism.tranquilizer = math.min(
				(ent.organism.tranquilizer or 0) + (self.TranquilizerPerTick or 4),
				self.TranquilizerCap or 20
			)
		end
	end

	self:NextThink(CurTime() + 1)
	return true
end
