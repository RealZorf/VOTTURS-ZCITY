if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Barbed Bat"
SWEP.Instructions = "The mighty bat upgraded with barb wires. Can fracture skulls, use discreetly.\n\nLMB to attack.\nRMB to block.\nE+LMB to charge up a heavy attack."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.HoldType = "slam"

SWEP.WorldModel = "models/weapons/tfa_nmrih/w_me_bat_wood.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_bat_metal.mdl"
SWEP.WorldModelExchange = "models/hatedmekkr/boneworks/weapons/melee/blunts/clubs/bw_wpn_clb_barbed.mdl"
SWEP.DontChangeDropped = false
SWEP.ViewModel = ""
SWEP.modelscale = 1

SWEP.basebone = 94



SWEP.weight = 3.5

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/barbedbat.png")
	SWEP.IconOverride = "vgui/barbedbat.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.DamageType = DMG_SLASH
SWEP.DamagePrimary = 27
SWEP.NeckBreakChance = 0.04
SWEP.DamageSecondary = 12

SWEP.PenetrationPrimary = 3
SWEP.PenetrationSecondary = 1

SWEP.MaxPenLen = 2

SWEP.PenetrationSizePrimary = 3
SWEP.PenetrationSizeSecondary = 1.5

SWEP.StaminaPrimary = 35
SWEP.StaminaSecondary = 25
SWEP.HeavyAttackStamina = 25

SWEP.HoldPos = Vector(-8,0,0)
SWEP.HoldAng = Angle(0,0,-10)

SWEP.AttackTime = 0.58
SWEP.AnimTime1 = 1.8
SWEP.WaitTime1 = 1.36
SWEP.AttackLen1 = 42
SWEP.ViewPunch1 = Angle(2,4,0)

SWEP.Attack2Time = 0.3
SWEP.AnimTime2 = 1
SWEP.WaitTime2 = 0.9
SWEP.AttackLen2 = 30
SWEP.ViewPunch2 = Angle(0,0,-2)

SWEP.attack_ang = Angle(0,0,0)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(7.5,0.2,-1.15)
SWEP.weaponAng = Angle(-79,5,-4)

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}

SWEP.setlh = true
SWEP.setrh = true
SWEP.TwoHanded = true

SWEP.AttackHit = "physics/wood/wood_plank_impact_hard1.wav"
SWEP.Attack2Hit = "physics/wood/wood_plank_impact_hard1.wav"
SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "physics/wood/wood_plank_impact_soft2.wav"
SWEP.SwingSound = "baseballbat/swing.ogg"
SWEP.HitFleshExtra = {
    "baseballbat/hit1.ogg",
    "baseballbat/hit2.ogg",
    "baseballbat/hit3.ogg"
}

SWEP.HitFleshPlus = "baseballbat/hitplus.ogg"

SWEP.AttackPos = Vector(0,0,0)

SWEP.NoHolster = true

SWEP.BreakBoneMul = 1
SWEP.PainMultiplier = 1.17

SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.001

SWEP.AttackRads = 85
SWEP.AttackRads2 = 0

SWEP.SwingAng = -5
SWEP.SwingAng2 = 0

SWEP.MinSensivity = 0.6

SWEP.Attack_Charge_Begin = "Attack_Charge_Begin"
SWEP.Attack_Charge_Idle = "Attack_Charge_Idle"
SWEP.Attack_Charge_End = "Attack_Charge_End"

SWEP.HeavyAttackDamageMul = 2.0 -- Max damage multiplier at full charge
SWEP.HeavyAttackWaitTime = 1.7 -- Time before you can attack again
SWEP.HeavyAttackAnimTimeBegin = 1.0 -- Duration of the wind-up/start animation
SWEP.HeavyAttackAnimTimeIdle = 1 -- Duration of the idle loop
SWEP.HeavyAttackAnimTimeEnd = 1.85 -- Duration of the attack animation
SWEP.HeavyAttackDelay = 0.5 -- Time delay before the hit actually connects (during attack anim)
SWEP.HeavyAttackTimeLength = 0.4 -- Duration of the active hit window
SWEP.HeavyAttackViewPunch = Angle(5, 0, 0) -- View punch angle on hit
SWEP.HeavyAttackMaxChargeTime = 2.0 -- Time in seconds to reach max damage/shake
SWEP.HeavyAttackSwingAng = -90 -- Custom swing angle for heavy attack
SWEP.HeavyAttackRads = 95 -- Custom radius/arc for heavy attack


SWEP.CanHeavyAttack = true -- Set to true to enable

SWEP.BlockTier = 3
SWEP.MeleeMaterial = "wood"
SWEP.BlockImpactSound = "physics/wood/wood_plank_impact_hard1.wav"

function SWEP:CanSecondaryAttack()
    local owner = self:GetOwner()
    if owner.organism and owner.organism.larmamputated then return end

    self.DamageType = DMG_CLUB
    timer.Simple(0.5,function()
        if IsValid(self) then
            self.DamageType = DMG_SLASH
        end
    end)
    return true
end