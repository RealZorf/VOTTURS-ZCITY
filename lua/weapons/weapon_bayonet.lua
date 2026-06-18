if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Bayonet"
SWEP.Instructions = "Return to origins. Smuggled from Homicity, A deadly weapon that hasnt seen bright days."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/tfa_ins2/w_marinebayonet.mdl"
SWEP.WorldModelReal = "models/weapons/gleb/c_knife_t.mdl"
SWEP.WorldModelExchange = "models/weapons/tfa_ins2/w_marinebayonet.mdl"
SWEP.DontChangeDropped = true
SWEP.modelscale = 0.85
SWEP.modelscale2 = 1

SWEP.SuicidePos = Vector(20, -5, -3)
SWEP.SuicideAng = Angle(-40, 180, 0)
SWEP.SuicideCutVec = Vector(1, -5, 4)
SWEP.SuicideCutAng = Angle(10, 0, 0)
SWEP.SuicideTime = 0.5
SWEP.CanSuicide = true
SWEP.SuicidePunchAng = Angle(-5, -15, 0)
SWEP.SuicideNoLH = true

SWEP.BleedMultiplier = 1.5
SWEP.PainMultiplier = 3

SWEP.DamagePrimary = 18
SWEP.DamageSecondary = 10

SWEP.AttackTime = 0.35
SWEP.AnimTime1 = 1.3
SWEP.WaitTime1 = 0.66
SWEP.AttackLen1 = 65

SWEP.BlockTier = 2

SWEP.Attack2Time = 0.25
SWEP.AnimTime2 = 0.95
SWEP.WaitTime2 = 0.45
SWEP.AttackLen2 = 40
SWEP.ViewPunch2 = Angle(0,0,-2)

SWEP.setlh = true
SWEP.setrh = true

SWEP.basebone =76

SWEP.weaponPos = Vector(-2,0,0)
SWEP.weaponAng = Angle(0,0,100)

SWEP.HoldType = "knife"

SWEP.InstantPainMul = 0.4

--models/weapons/gleb/c_knife_t.mdl
if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/hud/tfa_ins2_kabar")
	SWEP.IconOverride = "vgui/hud/tfa_ins2_kabar"
	SWEP.BounceWeaponIcon = false
end

SWEP.BreakBoneMul = 1
SWEP.ImmobilizationMul = 1
SWEP.StaminaMul = 0.6
SWEP.HadBackBonus = true

SWEP.HoldPos = Vector(-4.3,0,-4.1)
SWEP.HoldAng = Angle(-15,0,0)

-- Blocking configuration
SWEP.BlockHoldPos = Vector(-4.3,0,-4)
SWEP.BlockHoldAng = Angle(-45,0,0)
SWEP.BlockSound = "physics/metal/metal_solid_impact_bullet3.wav"

-- Animation list for actual weapon animations
SWEP.AnimList = {
    ["idle"] = "idle",
    ["deploy"] = "draw",
    ["attack"] = "stab_miss",
    ["attack2"] = "midslash1",
}

function SWEP:Initialize()
    self.attackanim = 0
    self.sprintanim = 0
    self.animtime = 0
    self.animspeed = 1
    self.reverseanim = false
    self.Initialzed = true
    self:PlayAnim("idle",10,true)

    self:SetAttackLength(60)
    self:SetAttackWait(0)

    self:SetHold(self.HoldType)

    self:InitAdd()
end

function SWEP:Reload()
    if SERVER then
        if self:GetOwner():KeyPressed(IN_ATTACK) then
            self:SetNetVar("mode", not self:GetNetVar("mode"))
            self:GetOwner():ChatPrint("Changed mode to "..(self:GetNetVar("mode") and "slash." or "stab."))
        end
    end
end

function SWEP:CanPrimaryAttack()
    if self:GetOwner():KeyDown(IN_RELOAD) then return end
    if not self:GetNetVar("mode") then
        return true
    else
        self.allowsec = true
	self:SecondaryAttack(true) -- fix: use DoSecondaryAttack for slash, not SecondaryAttack which blocks
        self.allowsec = nil
        return false
    end
end

function SWEP:CanSecondaryAttack()
    return self.allowsec and true or false
end

SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.1

SWEP.AttackRads = 35
SWEP.AttackRads2 = 65

SWEP.SwingAng = -90
SWEP.SwingAng2 = 0

SWEP.MultiDmg1 = false
SWEP.MultiDmg2 = true