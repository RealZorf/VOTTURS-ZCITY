if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_melee"
SWEP.PrintName = "Wrench"
SWEP.Instructions = "A solid metal wrench designed for tightening bolts and repairing equipment, but can also be swung as a makeshift melee tool."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/tfa_nmrih/w_me_wrench.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_wrench.mdl"
SWEP.WorldModelExchange = false
SWEP.ViewModel = ""

SWEP.HoldType = "melee"
SWEP.bloodID = 3
SWEP.weight = 1.8

SWEP.HoldPos = Vector(-15, 0, 0)
SWEP.HoldAng = Angle(8, 6, -12)

SWEP.AttackTime = 0.6
SWEP.AnimTime1 = 1.6
SWEP.WaitTime1 = 1
SWEP.ViewPunch1 = Angle(0, -5, 3)

SWEP.PainMultiplier = 1.1
SWEP.BreakBoneMul = 0.9

SWEP.Attack2Time = 0.3
SWEP.AnimTime2 = 1
SWEP.WaitTime2 = 0.8
SWEP.ViewPunch2 = Angle(0, 0, -4)

SWEP.sprint_ang = Angle(15, 0, 0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(0, 0, -8)
SWEP.weaponAng = Angle(0, -90, 0)

SWEP.DamageType = DMG_CLUB
SWEP.DamagePrimary = 18
SWEP.DamageSecondary = 13

SWEP.BlockHoldPos = Vector(-15, 7, -11)
SWEP.BlockHoldAng = Angle(-5, 0, -45)

SWEP.PenetrationPrimary = 3
SWEP.PenetrationSecondary = 3

SWEP.MaxPenLen = 3

SWEP.PenetrationSizePrimary = 2
SWEP.PenetrationSizeSecondary = 2

SWEP.StaminaPrimary = 16
SWEP.StaminaSecondary = 8

SWEP.AttackLen1 = 55
SWEP.AttackLen2 = 30

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}

if CLIENT then
    SWEP.WepSelectIcon = Material("vgui/hud/tfa_nmrih_wrench")
    SWEP.IconOverride = "vgui/hud/tfa_nmrih_wrench"
    SWEP.BounceWeaponIcon = false
end

SWEP.setlh = false
SWEP.setrh = true
SWEP.TwoHanded = false
SWEP.BlockTier = 2


SWEP.AttackHit = "SolidMetal.ImpactHard"
SWEP.Attack2Hit = "SolidMetal.ImpactHard"
SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "SolidMetal.ImpactSoft"

SWEP.AttackPos = Vector(0, 0, 0)

function SWEP:CanSecondaryAttack()
    return true
end

SWEP.AttackTimeLength = 0.155
SWEP.Attack2TimeLength = 0.1

SWEP.AttackRads = 65
SWEP.AttackRads2 = 0

SWEP.SwingAng = -90
SWEP.SwingAng2 = 0

SWEP.NoHolster = true