if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Heavy Wrench"
SWEP.Instructions = "A heavy-duty wrench built for gripping and twisting. Its solid metal frame makes it effective for blocking paths or slowing down anyone trying to push through.\n\nLMB to attack.\nRMB to block.\nRMB + LMB to throw."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Ammo = "Nails"
if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/newwrench.png")
	SWEP.IconOverride = "vgui/newwrench.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.SuicidePos = Vector(-12, -4, -8)
SWEP.SuicideAng = Angle(-0, 30, -50)
SWEP.SuicideCutVec = Vector(-2, -6, 2)
SWEP.SuicideCutAng = Angle(10, 0, 0)
SWEP.SuicideTime = 0.5
SWEP.SuicideSound = "player/flesh/flesh_bullet_impact_03.wav"
SWEP.CanSuicide = false
SWEP.SuicideNoLH = true
SWEP.SuicidePunchAng = Angle(5, -15, 0)
SWEP.WorldModel = "models/hatedmekkr/boneworks/weapons/melee/blunts/misc/bw_wpn_bnt_wrench.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_hatchet.mdl"
SWEP.WorldModelExchange = "models/hatedmekkr/boneworks/weapons/melee/blunts/misc/bw_wpn_bnt_wrench.mdl"
SWEP.DontChangeDropped = false
SWEP.ViewModel = ""
SWEP.HoldType = "melee"
SWEP.HoldPos = Vector(-15, 2, -4)
SWEP.HoldAng = Angle(-15, 0, 0)
SWEP.AttackTime = 0.5
SWEP.AnimTime1 = 1.65
SWEP.WaitTime1 = 1.35
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
SWEP.weaponPos = Vector(0, 0, 0)
SWEP.weaponAng = Angle(-5, -90, 0)
SWEP.AnimList = {
	["idle"] = "Idle",
	["deploy"] = "Draw",
	["attack"] = "Attack_Quick",
	["attack2"] = "Attack_Quick",
}

SWEP.modelscale = 0.85
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
SWEP.HitFleshExtraPitch = 115
SWEP.SwingSound = "baseballbat/swing.ogg"
SWEP.SwingSoundPitch = {145, 152}
SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.1
SWEP.AttackRads = 55
SWEP.AttackRads2 = 65
SWEP.SwingAng = -90
SWEP.SwingAng2 = 0
SWEP.AttackPos = Vector(0, 0, 0)
SWEP.UnNailables = {MAT_METAL, MAT_SAND, MAT_SLOSH, MAT_GLASS}
game.AddDecal("hmcd_jackanail", "decals/mat_jack_hmcd_nailhead")
function hgCheckBindObjects(ent1)
	if not ent1.Nails then return end
	return (ent1.Nails and ent1.Nails[0] and #ent1.Nails[0]) or 0
end

function SWEP:CanPrimaryAttack()
	return true
end

SWEP.BlockTier = 2
SWEP.MeleeMaterial = "metal	"
SWEP.BlockImpactSound = "physics/metal/metal_solid_impact_soft1.wav"

SWEP.CanHeavyAttack = true -- Set to true to enable
SWEP.NeckBreakChance = 0.01

SWEP.HeavyAttackDamageMul = 2.0 -- Max damage multiplier at full charge
SWEP.HeavyAttackWaitTime = 1.7 -- Time before you can attack again
SWEP.HeavyAttackAnimTimeBegin = 1.0 -- Duration of the wind-up/start animation
SWEP.HeavyAttackAnimTimeIdle = 1 -- Duration of the idle loop
SWEP.HeavyAttackAnimTimeEnd = 1.85 -- Duration of the attack animation
SWEP.HeavyAttackDelay = 0.43 -- Time delay before the hit actually connects (during attack anim)
SWEP.HeavyAttackTimeLength = 0.45 -- Duration of the active hit window
SWEP.HeavyAttackViewPunch = Angle(5, 0, 0) -- View punch angle on hit
SWEP.HeavyAttackMaxChargeTime = 2.0 -- Time in seconds to reach max damage/shake
SWEP.HeavyAttackSwingAng = -90 -- Custom swing angle for heavy attack
SWEP.HeavyAttackRads = 100 -- Custom radius/arc for heavy attack
SWEP.HeavyChargeHoldPos = Vector(-6,2,6.5)

SWEP.DamageType = DMG_CLUB
SWEP.PenetrationPrimary = 2
SWEP.MaxPenLen = 1
SWEP.PainMultiplier = 1.65
SWEP.PenetrationSizePrimary = 1
SWEP.StaminaPrimary = 25
function SWEP:ThinkAdd()
	self.DamagePrimary = 20
	self.DamageType = DMG_CLUB
	self.weaponPos = Vector(0, 0, -6.45)
	self.weaponAng = Angle(-5, -90, 0)
	self.PenetrationPrimary = 2
	self.MaxPenLen = 1
	self.PainMultiplier = 1.2
	self.PenetrationSizePrimary = 1
	self.StaminaPrimary = 27
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
			print(weld)
		if weld then
			ent1.Nails[bone1] = {weld, 1}
			weld:CallOnRemove("removefromtbl", function() ent1.Nails[bone1] = nil end)
		end
	else
		if not ent1:IsRagdoll() and not ent2:IsRagdoll() then 
			local weld = constraint.Ballsocket(ent1, ent2, bone1 or 0, bone2 or 0, ent2:WorldToLocal(pos2), (500 + 1 * 100) * 5)
		end
		local weld = ent1.Nails[bone1][1]
		if IsValid(weld) and (ent2:IsRagdoll() or ent1:IsRagdoll()) then
			weld:SetKeyValue("forcelimit", tostring( tonumber(weld:GetInternalVariable("forcelimit")) + ((500 + 1 * 100) * 5) ))
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
			ent2.Nails[bone2] = {weld, 1}
			weld:CallOnRemove("removefromtbl", function() ent2.Nails[bone2] = nil end)
		end
	else
		if not ent1:IsRagdoll() and not ent2:IsRagdoll() then 
			local weld = constraint.Ballsocket(ent1, ent2, bone1 or 0, bone2 or 0, ent2:WorldToLocal(pos2), (500 + 1 * 100) * 5)
		end
		local weld = ent2.Nails[bone2][1]
		if IsValid(weld) and (ent2:IsRagdoll() or ent1:IsRagdoll()) then
			weld:SetKeyValue("forcelimit", tostring( tonumber(weld:GetInternalVariable("forcelimit")) + ((500 + 1 * 100) * 5) ))
		end
		ent2.Nails[bone2][2] = ent2.Nails[bone2][2] + 1
		
	end

	if ent2.Nails[bone2] then ent2.Nails[bone2][3] = ent1.Nails[bone1] and ent1.Nails[bone1][1] end
	if ent1.Nails[bone1] then ent1.Nails[bone1][3] = ent2.Nails[bone2] and ent2.Nails[bone2][1] end
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
			end
		end
	end)
end

local vec1, vec2, vec3 = Vector(0, 0, .15), Vector(0, .15, 0), Vector(.15, 0, 0)
function SWEP:SprayDecals()
	local Owner = self:GetOwner()
	local Tr = util.QuickTrace(Owner:GetShootPos(), Owner:GetAimVector() * 70, {Owner})
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
	return (Owner:GetAmmoCount(self.Ammo) > 0) and Tr.Hit and Tr.Entity and (IsValid(Tr.Entity) or Tr.Entity:IsWorld()) and not (Tr.Entity:IsPlayer() or Tr.Entity:IsNPC()) and not table.HasValue(self.UnNailables, Tr.MatType)
end

function DoorIsOpen(door)
	return not door:GetInternalVariable("m_bLocked")
end

local vpang = Angle(3, 0, 0)
function SWEP:SecondaryAttack(override)
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

	end
end
