if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Shovel"
SWEP.Instructions = "A shovel may be big and slow but it can pack a punch.\n\nLMB to attack.\nRMB to block.\nE+LMB to charge up a heavy attack."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/props_junk/Shovel01a.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_fubar.mdl"
SWEP.WorldModelExchange = "models/props_junk/Shovel01a.mdl"
SWEP.ViewModel = ""

SWEP.NoHolster = true


SWEP.HoldType = "revolver"
SWEP.weight = 3

SWEP.HoldPos = Vector(-11,0,0)
SWEP.HoldAng = Angle(0,0,0)

SWEP.AttackTime = 0.68
SWEP.AnimTime1 = 2
SWEP.WaitTime1 = 1.95
SWEP.ViewPunch1 = Angle(1,2,0)

SWEP.Attack2Time = 0.46
SWEP.AnimTime2 = 1.4
SWEP.WaitTime2 = 1
SWEP.ViewPunch2 = Angle(0,0,-2)

SWEP.attack_ang = Angle(0,0,0)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(0,1,-10)
SWEP.weaponAng = Angle(180,90,-2)

SWEP.DamageType = DMG_CLUB
SWEP.DamagePrimary = 18
SWEP.NeckBreakChance = 0.01
SWEP.DamageSecondary = 10
SWEP.BreakBoneMul = 0.65
SWEP.PainMultiplier = 0.85

SWEP.PenetrationPrimary = 3
SWEP.PenetrationSecondary = 4

SWEP.MaxPenLen = 6

SWEP.PenetrationSizePrimary = 2
SWEP.PenetrationSizeSecondary = 1.25

SWEP.StaminaPrimary = 39
SWEP.HeavyAttackStamina = 30
SWEP.StaminaSecondary = 24

SWEP.AttackLen1 = 65
SWEP.AttackLen2 = 40

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/icons/ico_shovel.png")
	SWEP.IconOverride = "vgui/icons/ico_shovel.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = true
SWEP.setrh = true
SWEP.TwoHanded = true

SWEP.AttackHit = "SolidMetal.ImpactHard"
SWEP.Attack2Hit = "SolidMetal.ImpactHard"
SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "SolidMetal.ImpactSoft"
SWEP.HitFleshExtra = {
    "shovelcrowbarshared/shovelhit1.ogg",
    "shovelcrowbarshared/shovelhit2.ogg",
}
SWEP.HitFleshExtraPitch = 60
SWEP.SwingSound = "baseballbat/swing.ogg"
SWEP.SwingSoundPitch = {85, 90}

SWEP.HeavyAttackDamageType = DMG_SLASH
SWEP.HeavyAttackDamageMul = 2.0 -- Max damage multiplier at full charge
SWEP.HeavyAttackWaitTime = 1.0 -- Time before you can attack again
SWEP.HeavyAttackAnimTimeBegin = 1.0 -- Duration of the wind-up/start animation
SWEP.HeavyAttackAnimTimeIdle = 1 -- Duration of the idle loop
SWEP.HeavyAttackAnimTimeEnd = 1.85 -- Duration of the attack animation
SWEP.HeavyAttackDelay = 0.5 -- Time delay before the hit actually connects (during attack anim)
SWEP.HeavyAttackTimeLength = 0.4 -- Duration of the active hit window
SWEP.HeavyAttackViewPunch = Angle(5, 0, 0) -- View punch angle on hit
SWEP.HeavyAttackMaxChargeTime = 2.0 -- Time in seconds to reach max damage/shake
SWEP.HeavyAttackSwingAng = -90 -- Custom swing angle for heavy attack
SWEP.HeavyAttackRads = 75 -- Custom radius/arc for heavy attack


SWEP.CanHeavyAttack = true -- Set to true to enable

SWEP.BlockTier = 3
SWEP.MeleeMaterial = "metal"
SWEP.BlockImpactSound = "physics/metal/metal_solid_impact_bullet1.wav"

SWEP.AttackPos = Vector(0,0,0)

function SWEP:CanSecondaryAttack()
    self.DamageType = DMG_CLUB
    return true
end

function SWEP:CanPrimaryAttack()
    self.DamageType = DMG_CLUB
    return true
end

SWEP.AttackTimeLength = 0.155
SWEP.Attack2TimeLength = 0.01

SWEP.AttackRads = 70
SWEP.AttackRads2 = 0

SWEP.SwingAng = -5
SWEP.SwingAng2 = 0