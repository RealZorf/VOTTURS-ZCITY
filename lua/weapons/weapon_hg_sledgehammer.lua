if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Sledgehammer"
SWEP.Instructions = "The Sledgehammer is a two-handed tool which can be used as a melee weapon.\n\nLMB to attack.\nRMB to block.\nE+LMB to charge up a heavy attack."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Weight = 0

SWEP.WorldModel = "models/weapons/tfa_nmrih/w_me_sledge.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_sledge.mdl"
SWEP.WorldModelExchange = "models/weapons/tfa_nmrih/w_me_sledge.mdl"
SWEP.ViewModel = ""

SWEP.HoldType = "revolver"

SWEP.weight = 3.5 

SWEP.HoldPos = Vector(-14,-2,1)
SWEP.HoldAng = Angle(0,0,0)

SWEP.AttackTime = 0.61
SWEP.AnimTime1 = 2.1
SWEP.WaitTime1 = 1.5
SWEP.ViewPunch1 = Angle(1,2,0)

SWEP.Attack2Time = 0.3
SWEP.AnimTime2 = 1
SWEP.WaitTime2 = 0.8
SWEP.ViewPunch2 = Angle(0,0,-2)

SWEP.attack_ang = Angle(0,0,-15)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(0,0,0)
SWEP.weaponAng = Angle(0,-90,0)
SWEP.modelscale = 0.89

SWEP.DamageType = DMG_CLUB
SWEP.DamagePrimary = 51
SWEP.NeckBreakChance = 0.1
SWEP.DamageSecondary = 16
SWEP.BreakBoneMul = 1.05
SWEP.PainMultiplier = 0.85

SWEP.PenetrationPrimary = 4
SWEP.PenetrationSecondary = 1.6

SWEP.MaxPenLen = 6

SWEP.PenetrationSizePrimary = 3
SWEP.PenetrationSizeSecondary = 1.25

SWEP.StaminaPrimary = 39
SWEP.StaminaSecondary = 30
SWEP.HeavyAttackStamina = 43

SWEP.AttackLen1 = 60
SWEP.AttackLen2 = 45

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/icons/ico_sledgehammer.png")
	SWEP.IconOverride = "vgui/icons/ico_sledgehammer.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = true
SWEP.setrh = true
SWEP.TwoHanded = true

SWEP.AttackHit = "Canister.ImpactHard"
SWEP.Attack2Hit = "Canister.ImpactHard"
SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "physics/wood/wood_plank_impact_soft2.wav"
SWEP.SwingSound = "baseballbat/swing.ogg"
SWEP.HitFleshExtra = {
    "sledge/sledgehit1.ogg",
    "sledge/sledgehit2.ogg",
    "sledge/sledgehit3.ogg"
}
SWEP.HitFleshExtraPitch = 115
SWEP.SwingSoundPitch = {85, 95}

SWEP.AttackPos = Vector(0,0,0)

SWEP.Attack_Charge_Begin = "Attack_Charge_Begin"
SWEP.Attack_Charge_Idle = "Attack_Charge_Idle"
SWEP.Attack_Charge_End = "Attack_Charge_End"

SWEP.HeavyAttackDamageMul = 2.1 -- Max damage multiplier at full charge
SWEP.HeavyAttackWaitTime = 3 -- Time before you can attack again
SWEP.HeavyAttackAnimTimeBegin = 1.0 -- Duration of the wind-up/start animation
SWEP.HeavyAttackAnimTimeIdle = 1 -- Duration of the idle loop
SWEP.HeavyAttackAnimTimeEnd = 1.85 -- Duration of the attack animation
SWEP.HeavyAttackDelay = 0.45 -- Time delay before the hit actually connects (during attack anim)
SWEP.HeavyAttackTimeLength = 0.4 -- Duration of the active hit window
SWEP.HeavyAttackViewPunch = Angle(5, 0, 0) -- View punch angle on hit
SWEP.HeavyAttackMaxChargeTime = 3 -- Time in seconds to reach max damage/shake
SWEP.HeavyAttackSwingAng = -90 -- Custom swing angle for heavy attack
SWEP.HeavyAttackRads = 95 -- Custom radius/arc for heavy attack
SWEP.HeavyChargeHoldPos = Vector(5,1,1)


SWEP.CanHeavyAttack = true -- Set to true to enable

SWEP.BlockTier = 5
SWEP.MeleeMaterial = "wood"
SWEP.BlockImpactSound = "physics/wood/wood_plank_impact_hard1.wav"

function SWEP:CanSecondaryAttack()
    self.DamageType = DMG_CLUB
    self.AttackHit = "Canister.ImpactHard"
    self.Attack2Hit = "Canister.ImpactHard"
    return true
end

function SWEP:CanPrimaryAttack()
    self.DamageType = DMG_CLUB
    self.AttackHit = "Concrete.ImpactHard"
    self.Attack2Hit = "Concrete.ImpactHard"
    return true
end

function SWEP:PrimaryAttackAdd(ent)
    if hgIsDoor(ent) and math.random(7) > 3 then
        hgBlastThatDoor(ent,self:GetOwner():GetAimVector() * 50 + self:GetOwner():GetVelocity())
    end
end

function SWEP:CustomBlockAnim(addPosLerp, addAngLerp)
    addPosLerp.z = addPosLerp.z + (self:GetBlocking() and -2 or 0)
    addPosLerp.x = addPosLerp.x + (self:GetBlocking() and 2 or 0)
    addPosLerp.y = addPosLerp.y + (self:GetBlocking() and -5 or 0)
    addAngLerp.p = addAngLerp.p + (self:GetBlocking() and 15 or 0)
    addAngLerp.r = addAngLerp.r + (self:GetBlocking() and 45 or 0)

    return true
end

SWEP.NoHolster = true

SWEP.AttackTimeLength = 0.155
SWEP.Attack2TimeLength = 0.01

SWEP.AttackRads = 95
SWEP.AttackRads2 = 0

SWEP.SwingAng = -165
SWEP.SwingAng2 = 0

SWEP.MinSensivity = 0.87