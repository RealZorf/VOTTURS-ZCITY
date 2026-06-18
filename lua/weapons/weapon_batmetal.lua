if SERVER then AddCSLuaFile() end

SWEP.Base = "weapon_melee"
SWEP.PrintName = "Metal Bat"
SWEP.Instructions = "An Alluminum bat, Usually stored as trophies but this one is an upgrade to the usual bat. "
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/tfa_nmrih/w_me_bat_metal.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_bat_metal.mdl"
SWEP.WorldModelExchange = false
SWEP.DontChangeDropped = false
SWEP.ViewModel = ""
SWEP.modelscale = 1

SWEP.Weight = 0
SWEP.bloodID = 3
SWEP.weight = 2.0

if CLIENT then
    SWEP.WepSelectIcon = Material("vgui/hud/tfa_nmrih_bat")
    SWEP.IconOverride = "vgui/hud/tfa_nmrih_bat"
    SWEP.BounceWeaponIcon = false
end

SWEP.HoldType = "slam"

SWEP.HoldPos = Vector(-7, 0, 0)
SWEP.HoldAng = Angle(0, 0, 0)

SWEP.DamageType = DMG_CLUB
SWEP.DamagePrimary = 26
SWEP.DamageSecondary = 13

SWEP.PenetrationPrimary = 3
SWEP.PenetrationSecondary = 2

SWEP.MaxPenLen = 2

SWEP.PenetrationSizePrimary = 4
SWEP.PenetrationSizeSecondary = 2

SWEP.StaminaPrimary = 25
SWEP.StaminaSecondary = 13


SWEP.AttackTime = 0.6
SWEP.AnimTime1 = 1.85
SWEP.WaitTime1 = 1.65
SWEP.AttackLen1 = 40
SWEP.ViewPunch1 = Angle(2,4,0)

-- Blocking configuration
SWEP.BlockHoldPos = Vector(-7, 0, 7)
SWEP.BlockHoldAng = Angle(18, 15, -20)
SWEP.BlockSound = "physics/metal/metal_solid_impact_bullet1.wav"

SWEP.Attack2Time = 0.3
SWEP.AnimTime2 = 1
SWEP.WaitTime2 = 0.8
SWEP.AttackLen2 = 40
SWEP.ViewPunch2 = Angle(0, 0, -2)

SWEP.attack_ang = Angle(0, 0, 0)
SWEP.sprint_ang = Angle(15, 0, 0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(0, 0, 0)
SWEP.weaponAng = Angle(0, 0, 0)

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}

SWEP.setlh = true
SWEP.setrh = true
SWEP.TwoHanded = true

SWEP.AttackHit = "Canister.ImpactHard"
SWEP.Attack2Hit = "Canister.ImpactHard"
SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "physics/metal/metal_grenade_impact_soft2.wav"

SWEP.AttackPos = Vector(0, 0, 0)

SWEP.NoHolster = true

SWEP.BlockTier = 3

SWEP.BreakBoneMul = 1.1
SWEP.PainMultiplier = 1.2

SWEP.Attack_Charge_Begin = "Attack_Charge_Begin"
SWEP.Attack_Charge_Idle = "Attack_Charge_Idle"
SWEP.Attack_Charge_End = "Attack_Charge_End"

SWEP.HeavyAttackDamageMul = 2.1 -- Max damage multiplier at full charge
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

SWEP.AttackTimeLength = 0.15   -- важно для остановки
SWEP.Attack2TimeLength = 0.001

SWEP.AttackRads = 100
SWEP.AttackRads2 = 0

SWEP.SwingAng = -5
SWEP.SwingAng2 = 0

SWEP.MinSensivity = 0.6


function SWEP:PrimaryAttack()

    

    self.BaseClass.PrimaryAttack(self)
end