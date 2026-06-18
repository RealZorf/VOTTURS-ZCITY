if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Cue Stick"
SWEP.Instructions = "A cue stick is a long, sharp object used to hit a ball. The sticker on the bottom says \"Property of Zac90 Mansion\"."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/mu_hmcd_mansion/w_cuestick.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_fubar.mdl"
SWEP.WorldModelExchange = "models/mu_hmcd_mansion/w_cuestick.mdl"
SWEP.ViewModel = ""
SWEP.DontChangeDropped = false

SWEP.NoHolster = true


SWEP.HoldType = "camera"
SWEP.weight = 1

SWEP.HoldPos = Vector(-11,3,0)
SWEP.HoldAng = Angle(0,-6,0)

SWEP.AttackTime = 0.55
SWEP.AnimTime1 = 1.5
SWEP.WaitTime1 = 1.1
SWEP.ViewPunch1 = Angle(1,2,0)

SWEP.Attack2Time = 0.5
SWEP.AnimTime2 = 1.5
SWEP.WaitTime2 = 1
SWEP.ViewPunch2 = Angle(0,0,-2)

SWEP.attack_ang = Angle(0,0,0)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(-1,0,-39)
SWEP.weaponAng = Angle(0,90,0)
SWEP.modelscale = 0.85

SWEP.DamageType = DMG_CLUB
SWEP.DamagePrimary = 25
SWEP.DamageSecondary = 21

SWEP.BreakBoneMul = 0.55

SWEP.PenetrationPrimary = 1
SWEP.PenetrationSecondary = 2

SWEP.Ignorebelt = true

SWEP.MaxPenLen = 20

SWEP.PenetrationSizePrimary = 2
SWEP.PenetrationSizeSecondary = 2

SWEP.StaminaPrimary = 25
SWEP.StaminaSecondary = 20

SWEP.AttackLen1 = 85
SWEP.AttackLen2 = 75

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_hmcd_mansion_cuestick")
	SWEP.IconOverride = "vgui/wep_hmcd_mansion_cuestick"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = true
SWEP.setrh = true
SWEP.TwoHanded = true
SWEP.BlockTier = 2


SWEP.AttackHit = "physics/wood/wood_plank_impact_hard1.wav"
SWEP.Attack2Hit = "physics/wood/wood_plank_impact_hard1.wav"
SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "physics/wood/wood_plank_impact_soft2.wav"


SWEP.Attack_Charge_Begin = "Attack_Charge_Begin"
SWEP.Attack_Charge_Idle = "Attack_Charge_Idle"
SWEP.Attack_Charge_End = "Attack_Charge_End"

SWEP.HeavyAttackDamageMul = 1.7 -- Max damage multiplier at full charge
SWEP.HeavyAttackWaitTime = 1.5 -- Time before you can attack again
SWEP.HeavyAttackAnimTimeBegin = 1.0 -- Duration of the wind-up/start animation
SWEP.HeavyAttackAnimTimeIdle = 1 -- Duration of the idle loop
SWEP.HeavyAttackAnimTimeEnd = 1.85 -- Duration of the attack animation
SWEP.HeavyAttackDelay = 0.5 -- Time delay before the hit actually connects (during attack anim)
SWEP.HeavyAttackTimeLength = 0.4 -- Duration of the active hit window
SWEP.HeavyAttackViewPunch = Angle(5, 0, 0) -- View punch angle on hit
SWEP.HeavyAttackMaxChargeTime = 2.0 -- Time in seconds to reach max damage/shake
SWEP.HeavyAttackSwingAng = -90 -- Custom swing angle for heavy attack
SWEP.HeavyAttackRads = 95 -- Custom radius/arc for heavy attack
SWEP.HeavyAttackStamina = 24

SWEP.CanHeavyAttack = true -- Set to true to enable

SWEP.AttackPos = Vector(0,0,0)

SWEP.AttackTimeLength = 0.05
SWEP.Attack2TimeLength = 0.1

SWEP.AttackRads = 80
SWEP.AttackRads2 = 0

SWEP.BlockHoldPos = Vector(-15, 7, -6)
SWEP.BlockHoldAng = Angle(-5, 0, -45)

SWEP.SwingAng = -5
SWEP.SwingAng2 = 0


function SWEP:CanSecondaryAttack()
    return true
end

function SWEP:CanPrimaryAttack()
    return true
end


SWEP.MinSensivity = 0.65