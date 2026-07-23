if SERVER then
	AddCSLuaFile()
	resource.AddFile("models/w_nail.mdl")
	resource.AddFile("models/w_nail.vvd")
	resource.AddFile("models/w_nail.dx80.vtx")
	resource.AddFile("models/w_nail.dx90.vtx")
	resource.AddFile("models/w_nail.sw.vtx")
	resource.AddFile("materials/models/weapons/nail/nail.vtf")
	resource.AddFile("materials/models/weapons/nail/nail.vmt")
end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Hammer"
SWEP.Instructions = "A regular household hammer, which has a blunt and a sharp side. Use it to block off paths or restrict someone from moving.\n\nLMB to attack.\nR + LMB to change attack mode.\nRMB to block.\nRMB + LMB to nail or throw."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Ammo = "Nails"
if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_hammer")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_hammer"
	SWEP.BounceWeaponIcon = false
end

SWEP.SuicidePos = Vector(-12, -4, -8)
SWEP.SuicideAng = Angle(-0, 30, -50)
SWEP.SuicideCutVec = Vector(-2, -6, 2)
SWEP.SuicideCutAng = Angle(10, 0, 0)
SWEP.SuicideTime = 0.5
SWEP.SuicideSound = "player/flesh/flesh_bullet_impact_03.wav"
SWEP.CanSuicide = true
SWEP.SuicideNoLH = true
SWEP.SuicidePunchAng = Angle(5, -15, 0)
SWEP.WorldModel = "models/weapons/w_jjife_t.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_hatchet.mdl"
SWEP.WorldModelExchange = "models/weapons/w_jjife_t.mdl"
SWEP.DontChangeDropped = false
SWEP.ViewModel = ""
SWEP.HoldType = "melee"
SWEP.HoldPos = Vector(-15, 2, -4)
SWEP.HoldAng = Angle(-15, 0, 0)
SWEP.AttackTime = 0.45
SWEP.AnimTime1 = 1.57
SWEP.WaitTime1 = 1.15
SWEP.AttackLen1 = 45
SWEP.ViewPunch1 = Angle(1, 1, 0)
SWEP.Attack2Time = 0.45
SWEP.AnimTime2 = 1.57
SWEP.WaitTime2 = 1.25
SWEP.AttackLen2 = 40
SWEP.ViewPunch2 = Angle(0, 0, -2)
SWEP.attack_ang = Angle(0, 0, 0)
SWEP.sprint_ang = Angle(15, 0, 0)
SWEP.basebone = 94
SWEP.weaponPos = Vector(0, 5, -2)
SWEP.weaponAng = Angle(-5, -90, 0)
SWEP.AnimList = {
	["idle"] = "Idle",
	["deploy"] = "Draw",
	["attack"] = "Attack_Quick",
	["attack2"] = "Attack_Quick",
}

SWEP.setlh = false
SWEP.setrh = true
SWEP.TwoHanded = false
SWEP.AttackHit = "Concrete.ImpactHard"
SWEP.Attack2Hit = "Concrete.ImpactHard"
SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "physics/metal/metal_solid_impact_soft1.wav"
SWEP.HitFleshExtra = {
    "shovelcrowbarshared/shovelhit1.ogg",
    "shovelcrowbarshared/shovelhit2.ogg",
}
SWEP.HitFleshExtraPitch = 125
SWEP.SwingSound = "baseballbat/swing.ogg"
SWEP.SwingSoundPitch = {145, 155}
SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.1
SWEP.AttackRads = 55
SWEP.AttackRads2 = 65
SWEP.SwingAng = -90
SWEP.SwingAng2 = 0
SWEP.AttackPos = Vector(0, 0, 0)
SWEP.UnNailables = {MAT_METAL, MAT_SAND, MAT_SLOSH, MAT_GLASS}
game.AddDecal("hmcd_jackanail", "decals/mat_jack_hmcd_nailhead")

local hammerDoorClasses = {
	["prop_door"] = true,
	["prop_door_rotating"] = true,
	["func_door"] = true,
	["func_door_rotating"] = true
}

local function IsHammerDoor(ent)
	return IsValid(ent) and hammerDoorClasses[ent:GetClass()] == true
end

function hgCheckBindObjects(ent1)
	if not ent1.Nails then return end
	return (ent1.Nails and ent1.Nails[0] and #ent1.Nails[0]) or 0
end

function SWEP:CanPrimaryAttack()
	return not hg.KeyDown(self:GetOwner(), IN_RELOAD)
end

SWEP.BlockTier = 2
SWEP.MeleeMaterial = "wood"
SWEP.BlockImpactSound = "physics/wood/wood_plank_impact_hard1.wav"

SWEP.DamageType = DMG_CLUB
SWEP.PenetrationPrimary = 2
SWEP.MaxPenLen = 1
SWEP.PainMultiplier = 1.65
SWEP.PenetrationSizePrimary = 1
SWEP.StaminaPrimary = 25
function SWEP:ThinkAdd()
	local ply = self:GetOwner()
	if SERVER and ply.suiciding then
		self:SetNetVar("AttackMode", 1)
	end
	
	if self:GetNetVar("AttackMode", 1) == 1 then
		self.DamagePrimary = 13
		self.DamageType = DMG_CLUB
		self.weaponPos = Vector(0, 4, -3)
		self.weaponAng = Angle(-5, -90, 0)
		self.PenetrationPrimary = 2
		self.MaxPenLen = 1
		self.PainMultiplier = 1.15
		self.PenetrationSizePrimary = 1
		self.StaminaPrimary = 25
	else
		self.DamagePrimary = 11
		self.DamageType = DMG_SLASH
		self.weaponPos = Vector(-0.5, -3, -6.5)
		self.weaponAng = Angle(-55, 90, 0)
		self.PenetrationPrimary = 4
		self.PainMultiplier = 1
		self.MaxPenLen = 4
		self.PenetrationSizePrimary = 0.5
		self.StaminaPrimary = 25
	end

	if CLIENT then return end
	if IsValid(ply) then
		if hg.KeyDown(ply, IN_ATTACK) and hg.KeyDown(ply, IN_RELOAD) then
			if not self.setmode then
				local int = self:GetNetVar("AttackMode", 1)
				self:SetNetVar("AttackMode", int >= 2 and 1 or (int + 1))
				self.setmode = true
			end
		else
			self.setmode = false
		end
	end
end

local function UpdateNailNetworkState(ent)
	if not SERVER or not IsValid(ent) then return end

	local hasNails = ent.LockedDoorNail == true
	if not hasNails and ent.Nails then
		for _, entry in pairs(ent.Nails) do
			if istable(entry) and (entry[2] or 0) > 0 then
				hasNails = true
				break
			end
		end
	end

	ent:SetNWBool("HasHammerNails", hasNails)
end

local function RemoveOneNailVisual(entry)
	local visuals = entry and entry.NailVisuals
	if not visuals then return end

	while #visuals > 0 do
		local visual = table.remove(visuals)
		if IsValid(visual) then
			visual:Remove()
			return
		end
	end
end

local function RemoveAllNailVisuals(entry)
	local visuals = entry and entry.NailVisuals
	if not visuals then return end

	for _, visual in ipairs(visuals) do
		if IsValid(visual) then visual:Remove() end
	end
	table.Empty(visuals)
end

local function CreateNailVisual(ent, pos, direction, physicsBone)
	if not SERVER or not IsValid(ent) then return end

	direction = direction:GetNormalized()
	local visualPos = pos + direction * 0.05
	local visualAng = direction:Angle()
	local visual = ents.Create("prop_dynamic")
	if not IsValid(visual) then return end

	visual:SetModel("models/w_nail.mdl")
	visual:SetPos(visualPos)
	visual:SetAngles(visualAng)
	visual:SetKeyValue("solid", "0")
	visual:Spawn()
	visual:SetMoveType(MOVETYPE_NONE)
	visual:SetSolid(SOLID_NONE)
	visual:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	visual:DrawShadow(false)

	local modelBone = ent:IsRagdoll() and ent:TranslatePhysBoneToBone(physicsBone or 0) or -1
	local boneMatrix = modelBone >= 0 and ent:GetBoneMatrix(modelBone)
	if boneMatrix then
		local localPos, localAng = WorldToLocal(visualPos, visualAng, boneMatrix:GetTranslation(), boneMatrix:GetAngles())
		visual:FollowBone(ent, modelBone)
		visual:SetLocalPos(localPos)
		visual:SetLocalAngles(localAng)
	else
		visual:SetParent(ent)
		visual:SetLocalPos(ent:WorldToLocal(visualPos))
		visual:SetLocalAngles(ent:WorldToLocalAngles(visualAng))
	end

	ent:DeleteOnRemove(visual)

	return visual
end

local function TrackNailVisual(ent1, bone1, ent2, bone2, visual)
	if not IsValid(visual) then return end

	local entry1 = ent1.Nails and ent1.Nails[bone1]
	local entry2 = not ent2:IsWorld() and ent2.Nails and ent2.Nails[bone2] or nil
	local visuals = entry1 and entry1.NailVisuals or entry2 and entry2.NailVisuals or {}

	if entry1 then entry1.NailVisuals = visuals end
	if entry2 then entry2.NailVisuals = visuals end
	table.insert(visuals, visual)
end

local function BindObjects(ent1, pos1, ent2, pos2, power, bone1, bone2)
	ent1.Nails = ent1.Nails or {}
	ent2.Nails = ent2.Nails or {}
	--ent2.Nails[bone2] = ent2.Nails[bone2] or {}
	--ent1.Nails[bone1] = ent1.Nails[bone1] or {}
	--ent2.Nails[bone2][2] = ent2.Nails[bone2][2] or 0
	--ent1.Nails[bone1][2] = ent1.Nails[bone1][2] or 0
	if not ent1.Nails[bone1] then
			local weld =
			(
				not ent1:IsRagdoll() and not ent2:IsRagdoll() 
				and constraint.Ballsocket(ent1, ent2, bone1 or 0, bone2 or 0, ent1:WorldToLocal(pos1), (500 + 1 * 100) * 5)
			)
			or constraint.Weld(ent1, ent2, bone1 or 0, bone2 or 0, (500 + 1 * 100) * 15, false, false)
		if weld then
			local entry = {weld, 1}
			ent1.Nails[bone1] = entry
			weld:CallOnRemove("removefromtbl", function()
				if ent1.Nails and ent1.Nails[bone1] == entry then
					ent1.Nails[bone1] = nil
				end
				RemoveAllNailVisuals(entry)
				UpdateNailNetworkState(ent1)
			end)
		end
	else
		local weld = ent1.Nails[bone1][1]
		if IsValid(weld) then
			local forceLimit = tonumber(weld:GetInternalVariable("forcelimit")) or 3000
			weld:SetKeyValue("forcelimit", tostring(forceLimit + 3000))
		end
		ent1.Nails[bone1][2] = ent1.Nails[bone1][2] + 1
	end

	if not ent2.Nails[bone2] then
			local weld =
			(
				not ent1:IsRagdoll() and not ent2:IsRagdoll()
				and constraint.Ballsocket(ent1, ent2, bone1 or 0, bone2 or 0, ent2:WorldToLocal(pos2), (500 + 1 * 100) * 5)
			)
			or constraint.Weld(ent1, ent2, bone1 or 0, bone2 or 0, (500 + 1 * 100) * 15, false, false)
		if weld then
			local entry = {weld, 1}
			ent2.Nails[bone2] = entry
			weld:CallOnRemove("removefromtbl", function()
				if ent2.Nails and ent2.Nails[bone2] == entry then
					ent2.Nails[bone2] = nil
				end
				RemoveAllNailVisuals(entry)
				UpdateNailNetworkState(ent2)
			end)
		end
	else
		local weld = ent2.Nails[bone2][1]
		if IsValid(weld) then
			local forceLimit = tonumber(weld:GetInternalVariable("forcelimit")) or 3000
			weld:SetKeyValue("forcelimit", tostring(forceLimit + 3000))
		end
		ent2.Nails[bone2][2] = ent2.Nails[bone2][2] + 1
		
	end

	if ent2.Nails[bone2] then ent2.Nails[bone2][3] = ent1.Nails[bone1] and ent1.Nails[bone1][1] end
	if ent1.Nails[bone1] then ent1.Nails[bone1][3] = ent2.Nails[bone2] and ent2.Nails[bone2][1] end
	if ent1.Nails[bone1] then ent1.Nails[bone1].NailPos = pos1 end
	if ent2.Nails[bone2] then ent2.Nails[bone2].NailPos = pos2 end
	UpdateNailNetworkState(ent1)
	UpdateNailNetworkState(ent2)
	return ent1:IsWorld() and ((ent2.Nails[bone2] and ent2.Nails[bone2][2]) or 1) or ((ent1.Nails[bone1] and ent1.Nails[bone1][2]) or 1)
end

if SERVER then
	hook.Add("Should Fake Up", "NailTaped", function(ply)
		if ply and IsValid(ply.FakeRagdoll) then
			local Nails = ply.FakeRagdoll.Nails
			if Nails then
				for i, tbl in pairs(Nails) do
					if tbl[2] > 0 then
						tbl[2] = tbl[2] - 0.05
						if math.random(3) == 1 then
							local dmginfo = DamageInfo()
							dmginfo:SetDamage(15)
							dmginfo:SetAttacker(ply)
							dmginfo:SetInflictor(ply)
							dmginfo:SetDamagePosition(ply.FakeRagdoll:GetPhysicsObjectNum(tbl[1]:GetTable()["Bone1"]):GetPos())
							dmginfo:SetDamageType(DMG_SLASH)
							dmginfo:SetDamageForce(vector_up)
							ply.Penetration = 5
							ply.FakeRagdoll:TakeDamageInfo(dmginfo)
							ply.Penetration = nil
						end

						--ply.FakeRagdoll:EmitSound("tape_friction"..math.random(3)..".mp3",65)
						if tbl[2] <= 0 then
							if IsValid(Nails[i][1]) then
								Nails[i][1]:Remove()
								Nails[i][1] = nil
							end

							if IsValid(Nails[i][3]) then
								Nails[i][3]:Remove()
								Nails[i][3] = nil
							end

							Nails[i] = nil
						end
					end
				end

				if table.Count(Nails) > 0 then
					ply.fakecd = CurTime() + 1
					return false
				end

				UpdateNailNetworkState(ply.FakeRagdoll)
			end
		end
	end)
end

local vec1, vec2, vec3 = Vector(0, 0, .15), Vector(0, .15, 0), Vector(.15, 0, 0)
function SWEP:SprayDecals()
	local Owner = self:GetOwner()
	local Tr = util.QuickTrace(Owner:GetShootPos(), Owner:GetAimVector() * 70, {Owner})
	if IsValid(Tr.Entity) then
		return CreateNailVisual(Tr.Entity, Tr.HitPos, Tr.HitPos - Owner:EyePos(), Tr.PhysicsBone or 0)
	end

	util.Decal("hmcd_jackanail", Tr.HitPos + Tr.HitNormal, Tr.HitPos - Tr.HitNormal)
end

function SWEP:InitAdd()
	if CLIENT then return end
	self.AmmoGive = self:GetOwner().Profession and self:GetOwner().Profession == "builder" and 4 or 3
end

function SWEP:OwnerChanged()
	if IsValid(self:GetOwner()) and SERVER then
		self:GetOwner():GiveAmmo(self.AmmoGive, self.Ammo, true)
		self.AmmoGive = 0
	end
end

function SWEP:CanNail(Tr)
	local Owner = self:GetOwner()
	return IsValid(Owner) and Tr and (Owner:GetAmmoCount(self.Ammo) > 0) and Tr.Hit and not Tr.HitSky and Tr.Entity and (IsValid(Tr.Entity) or Tr.Entity:IsWorld()) and not (Tr.Entity:IsPlayer() or Tr.Entity:IsNPC()) and not table.HasValue(self.UnNailables, Tr.MatType)
end

local nailHullMins = Vector(-2, -2, -2)
local nailHullMaxs = Vector(2, 2, 2)

function SWEP:GetNailTraces(Owner)
	local firstTrace = hg.eyeTrace(Owner)
	if not self:CanNail(firstTrace) then return firstTrace end

	local aimVector = Owner:GetAimVector()
	local secondTrace = util.TraceHull({
		start = firstTrace.HitPos + aimVector * 0.5,
		endpos = firstTrace.HitPos + aimVector * 28,
		mins = nailHullMins,
		maxs = nailHullMaxs,
		mask = MASK_SHOT,
		filter = {Owner, firstTrace.Entity}
	})

	if not self:CanNail(secondTrace) or secondTrace.Entity == firstTrace.Entity then
		return firstTrace
	end

	return firstTrace, secondTrace
end

local function FindNailEntry(Tr)
	local ent = Tr and Tr.Entity
	local nails = ent and ent.Nails
	if not nails then return end

	local physicsBone = Tr.PhysicsBone or 0
	if nails[physicsBone] then
		return nails[physicsBone], physicsBone
	end

	local closestEntry, closestBone, closestDistance
	for bone, entry in pairs(nails) do
		if not istable(entry) or (entry[2] or 0) <= 0 then continue end

		local nailPos = entry.NailPos
		if not isvector(nailPos) and IsValid(ent) then
			local phys = ent:GetPhysicsObjectNum(tonumber(bone) or 0)
			if IsValid(phys) then nailPos = phys:GetPos() end
		end

		local distance = isvector(nailPos) and nailPos:DistToSqr(Tr.HitPos) or 0
		if not closestDistance or distance < closestDistance then
			closestEntry = entry
			closestBone = bone
			closestDistance = distance
		end
	end

	return closestEntry, closestBone
end

function DoorIsOpen(door)
	return not door:GetInternalVariable("m_bLocked")
end

local vpang = Angle(3, 0, 0)
function SWEP:SecondaryAttack(override)
	if CLIENT then return end
	if self:GetLastAttack() + 3 > CurTime() then return end
	local Owner = self:GetOwner()
	local Tr = hg.eyeTrace(Owner)
	if self:GetNetVar("AttackMode", 1) == 2 then
		if self:CutDuct() then return end
		if not Tr or not Tr.Entity then return end

		local target = Tr.Entity
		local nailEntry, nailBone = FindNailEntry(Tr)
		local isDoorNailed = target.LockedDoorNail
		if (nailEntry or isDoorNailed) and not self.pulling then
			Owner:EmitSound("nail_pull.mp3", 65, 100, 1, CHAN_AUTO)
			self.pulling = true
			timer.Simple(2, function()
				if not IsValid(Owner) or not IsValid(self) then return end
				self.pulling = false

				if isDoorNailed and IsValid(target) and target.LockedDoorNail then
					if not target.LockedDoor and not target.LockedDoorMap then target:Fire("unlock", "", 0) end
					target.LockedDoorNail = nil
					if IsValid(target.LockedDoorNailVisual) then
						target.LockedDoorNailVisual:Remove()
					end
					target.LockedDoorNailVisual = nil
					UpdateNailNetworkState(target)
					Owner:SetAmmo(Owner:GetAmmoCount(self.Ammo) + (target.CadedByBuilder and 2 or 3), self.Ammo)
					return
				end

				if IsValid(target) and target.Nails and target.Nails[nailBone] == nailEntry then
					if (nailEntry[2] or 0) <= 0 then return end
					nailEntry[2] = nailEntry[2] - 1
					Owner:SetAmmo(Owner:GetAmmoCount(self.Ammo) + 1, self.Ammo)
					RemoveOneNailVisual(nailEntry)
					if nailEntry[2] > 0 then return end

					local primaryConstraint = nailEntry[1]
					local pairedConstraint = nailEntry[3]
					if IsValid(primaryConstraint) then
						primaryConstraint:Remove()
					end

					if IsValid(pairedConstraint) and pairedConstraint ~= primaryConstraint then
						pairedConstraint:Remove()
					end

					if target.Nails and target.Nails[nailBone] == nailEntry then
						target.Nails[nailBone] = nil
					end
					UpdateNailNetworkState(target)
				end
			end)
			return
		end
	else
		if Owner:KeyDown(IN_SPEED) then return end
		if Owner:GetAmmoCount(self.Ammo) > 0 then
			local AimVec = Owner:GetAimVector()
			local Tr, NewTr = self:GetNailTraces(Owner)
			if Tr and (NewTr or IsHammerDoor(Tr.Entity)) then
				local NewEnt = NewTr and NewTr.Entity
				if IsHammerDoor(Tr.Entity) or self:CanNail(NewTr) then
					if IsHammerDoor(Tr.Entity) or (NewEnt and (IsValid(NewEnt) or NewEnt:IsWorld()) and not (NewEnt:IsPlayer() or NewEnt:IsNPC() or (NewEnt == Tr.Entity))) then
						if IsHammerDoor(Tr.Entity) then
							if Owner:GetAmmoCount(self.Ammo) > (Owner.Profession and Owner.Profession == "builder" and 1 or 2) then
								if not DoorIsOpen(Tr.Entity) then
									if not Tr.Entity.LockedDoorNail then Tr.Entity.LockedDoorMap = true end
								else
									Tr.Entity.LockedDoorMap = false
								end

								Tr.Entity:Fire("lock", "", 0)
								Tr.Entity.LockedDoorNail = true
								Tr.Entity.CadedByBuilder = (Owner.Profession and Owner.Profession == "builder") and true or false
								UpdateNailNetworkState(Tr.Entity)
								Owner:SetAmmo(Owner:GetAmmoCount(self.Ammo) - (Owner.Profession and Owner.Profession == "builder" and 2 or 3), self.Ammo)
								sound.Play("snd_jack_hmcd_hammerhit.wav", Tr.HitPos, 65, math.random(90, 110))
								if IsValid(Tr.Entity.LockedDoorNailVisual) then
									Tr.Entity.LockedDoorNailVisual:Remove()
								end
								Tr.Entity.LockedDoorNailVisual = self:SprayDecals()
								Owner:PrintMessage(HUD_PRINTCENTER, "Door Sealed")
								Owner:ViewPunch(vpang)
								Owner:SetAnimation(PLAYER_ATTACK1)
								self:SetNextSecondaryFire(CurTime() + 2.5)
								self:SetNextPrimaryFire(CurTime() + 2.5)
							else
								Owner:PrintMessage(HUD_PRINTCENTER, "Need at least "..tostring((Owner.Profession and Owner.Profession == "builder") and 2 or 3).." nails to seal door.")
							end
						else
							if Tr.Entity:IsRagdoll() then
								local DmgInfo = DamageInfo()
								DmgInfo:SetDamage(15)
								DmgInfo:SetDamageType(DMG_SLASH)
								DmgInfo:SetDamageForce(AimVec * 5)
								DmgInfo:SetDamagePosition(Tr.HitPos)
								DmgInfo:SetInflictor(self)
								DmgInfo:SetAttacker(Owner)
								self.Penetration = 15
								Tr.Entity:TakeDamageInfo(DmgInfo)
								self.Penetration = nil
							end

							if NewEnt:IsRagdoll() then
								local DmgInfo = DamageInfo()
								DmgInfo:SetDamage(15)
								DmgInfo:SetDamageType(DMG_SLASH)
								DmgInfo:SetDamageForce(AimVec * 5)
								DmgInfo:SetDamagePosition(NewTr.HitPos)
								DmgInfo:SetInflictor(self)
								DmgInfo:SetAttacker(Owner)
								self.Penetration = 15
								NewEnt:TakeDamageInfo(DmgInfo)
								self.Penetration = nil
							end

							local Strength, Weld = BindObjects(Tr.Entity, Tr.HitPos, NewEnt, NewTr.HitPos, 3.5, Tr.PhysicsBone or 0, NewTr.PhysicsBone or 0)
							--print(Tr.Entity,Weld)
							if Weld or Weld == nil then Owner:SetAmmo(Owner:GetAmmoCount(self.Ammo) - 1, self.Ammo) end
							sound.Play("snd_jack_hmcd_hammerhit.wav", Tr.HitPos, 65, math.random(90, 110))
							local nailVisual = CreateNailVisual(Tr.Entity, Tr.HitPos, Tr.HitPos - Owner:EyePos(), Tr.PhysicsBone or 0)
							TrackNailVisual(Tr.Entity, Tr.PhysicsBone or 0, NewEnt, NewTr.PhysicsBone or 0, nailVisual)
							Owner:ChatPrint("Bond strength: " .. tostring(Strength))
							Owner:ViewPunch(vpang)
							self:PlayAnim("attack", 0.6, false, nil, false, true)
							
							self:SetNextSecondaryFire(CurTime() + 2.5)
							self:SetNextPrimaryFire(CurTime() + 2.5)
							self:SetLastBlocked(CurTime())
						end
						return
					end
				end
			end
		end
	end
	
	self.BaseClass.SecondaryAttack(self, override)
end

function SWEP:CustomAttack2()
    local ent = ents.Create("ent_throwable")
    ent.WorldModel = self.WorldModelExchange or self.WorldModel

    local ply = self:GetOwner()

    ent:SetPos(select(1, hg.eye(ply,60,hg.GetCurrentCharacter(ply))) - ply:GetAimVector() * 2)
    ent:SetAngles(ply:EyeAngles())
    ent:SetOwner(self:GetOwner())
    ent:Spawn()

    ent.localshit = Vector(0,0,0)
    ent.wep = self:GetClass()
    ent.owner = ply
    ent.damage = 15
    ent.MaxSpeed = 700
    ent.DamageType = DMG_CLUB
    ent.AttackHit = self.AttackHit
    ent.AttackHitFlesh = self.AttackHitFlesh
    ent.HitFleshExtra = self.HitFleshExtra
    ent.HitFleshExtraPitch = self.HitFleshExtraPitch
    ent.noStuck = true

    local phys = ent:GetPhysicsObject()

    if IsValid(phys) then
        phys:SetVelocity(ply:GetAimVector() * ent.MaxSpeed)
        phys:AddAngleVelocity(Vector(0,ent.MaxSpeed,0) )
    end

    ply:ViewPunch(Angle(0, 0, -8))
    ply:SelectWeapon("weapon_hands_sh")

    self:Remove()

    return true
end

if CLIENT then
	function SWEP:DrawHUD()
		if GetViewEntity() ~= LocalPlayer() then return end
		if LocalPlayer():InVehicle() then return end

		local Owner = self:GetOwner()
		if not IsValid(Owner) then return end

		if self:GetNetVar("AttackMode", 1) == 2 then
			local Tr = hg.eyeTrace(Owner)
			if Tr and IsValid(Tr.Entity) and Tr.Entity:GetNWBool("HasHammerNails", false) then
				local toScreen = Tr.HitPos:ToScreen()
				draw.SimpleText("RMB to Unnail", "HomigradFont", toScreen.x + 3, toScreen.y + 27, color_black, TEXT_ALIGN_CENTER)
				draw.SimpleText("RMB to Unnail", "HomigradFont", toScreen.x, toScreen.y + 25, color_white, TEXT_ALIGN_CENTER)
			end
			return
		end

		local Tr, NewTr = self:GetNailTraces(Owner)
		if Tr then
			if NewTr or IsHammerDoor(Tr.Entity) then
				local toScreen = Tr.HitPos:ToScreen()
				draw.SimpleText("RMB to Nail", "HomigradFont", toScreen.x + 3, toScreen.y + 27, color_black, TEXT_ALIGN_CENTER)
				draw.SimpleText("RMB to Nail", "HomigradFont", toScreen.x, toScreen.y + 25, color_white, TEXT_ALIGN_CENTER)
			end
		end
	end
end
