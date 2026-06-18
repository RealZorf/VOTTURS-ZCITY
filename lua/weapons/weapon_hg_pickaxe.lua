if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Pickaxe"
SWEP.Instructions = "Pickaxe, An old tool that is used to mine rocks and smash in skulls"
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.weight = 3
SWEP.Weight = 0

SWEP.WorldModel = "models/weapons/tfa_nmrih/w_me_sledge.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_sledge.mdl"
SWEP.WorldModelExchange = "models/props_mining/pickaxe01.mdl"
SWEP.ViewModel = ""

SWEP.SuicidePos = Vector(7, -5, -33)
SWEP.SuicideAng = Angle(-90, -180, 150)
SWEP.SuicideCutVec = Vector(3, -6, 0)
SWEP.SuicideCutAng = Angle(10, 0, 0)
SWEP.SuicideTime = 0.5
SWEP.SuicideSound = "weapons/knife/knife_hit1.wav"
SWEP.CanSuicide = true
SWEP.SuicideNoLH = false
SWEP.SuicidePunchAng = Angle(5, -15, 0)

SWEP.HoldType = "camera"

SWEP.DamageType = DMG_SLASH

SWEP.HoldPos = Vector(-14,-2,1)

SWEP.AttackTime = 0.46
SWEP.AnimTime1 = 1.9
SWEP.WaitTime1 = 1.3
SWEP.ViewPunch1 = Angle(1,2,0)

SWEP.Attack2Time = 0.3
SWEP.AnimTime2 = 1
SWEP.WaitTime2 = 0.8
SWEP.ViewPunch2 = Angle(0,0,-2)

SWEP.attack_ang = Angle(0,0,-15)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 94
SWEP.weaponPos = Vector(0,0,-16)
SWEP.weaponAng = Angle(0,100,0)
SWEP.modelscale = 0.75 -- Scale of the WorldModelExchange (pickaxe model)

SWEP.DamageType = DMG_SLASH
SWEP.DamagePrimary = 45
SWEP.DamageSecondary = 20

SWEP.PenetrationPrimary = 5
SWEP.PenetrationSecondary = 7

SWEP.MaxPenLen = 6

SWEP.PenetrationSizePrimary = 4.5
SWEP.PenetrationSizeSecondary = 1.25

SWEP.StaminaPrimary = 32
SWEP.StaminaSecondary = 35

SWEP.AttackLen1 = 60
SWEP.AttackLen2 = 45

-- Blocking configuration
SWEP.BlockHoldPos = Vector(-16,-5,2)
SWEP.BlockHoldAng = Angle(0, 0, 21)
SWEP.BlockSound = "physics/metal/metal_solid_impact_bullet2.wav"

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/hud/pickaxe5")
	SWEP.IconOverride = "vgui/hud/pickaxe5"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = true
SWEP.setrh = true


SWEP.AttackHit = "Canister.ImpactHard"
SWEP.Attack2Hit = "Canister.ImpactHard"
SWEP.AttackHitFlesh = "snd_jack_hmcd_axehit.wav"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "physics/wood/wood_plank_impact_soft2.wav"
SWEP.SwingSound = "baseballbat/swing.ogg"


SWEP.AttackPos = Vector(0,0,0)

SWEP.Attack_Charge_Begin = "Attack_Charge_Begin"
SWEP.Attack_Charge_Idle = "Attack_Charge_Idle"
SWEP.Attack_Charge_End = "Attack_Charge_End"

SWEP.HeavyAttackDamageMul = 2.1 -- Max damage multiplier at full charge
SWEP.HeavyAttackWaitTime = 3 -- Time before you can attack again
SWEP.HeavyAttackAnimTimeBegin = 0.9 -- Duration of the wind-up/start animation
SWEP.HeavyAttackAnimTimeIdle = 1 -- Duration of the idle loop
SWEP.HeavyAttackAnimTimeEnd = 1.85 -- Duration of the attack animation
SWEP.HeavyAttackDelay = 0.45 -- Time delay before the hit actually connects (during attack anim)
SWEP.HeavyAttackTimeLength = 0.4 -- Duration of the active hit window
SWEP.HeavyAttackViewPunch = Angle(5, 0, 0) -- View punch angle on hit
SWEP.HeavyAttackMaxChargeTime = 2.6 -- Time in seconds to reach max damage/shake
SWEP.HeavyAttackSwingAng = -90 -- Custom swing angle for heavy attack
SWEP.HeavyAttackRads = 95 -- Custom radius/arc for heavy attack


SWEP.CanHeavyAttack = true -- Set to true to enable

function SWEP:CanSecondaryAttack()
    self.DamageType = DMG_CLUB
    self.AttackHit = "Canister.ImpactHard"
    self.Attack2Hit = "Canister.ImpactHard"
    return true
end

function SWEP:CanPrimaryAttack()
    self.DamageType = DMG_SLASH
    self.AttackHit = "Concrete.ImpactHard"
    self.Attack2Hit = "Concrete.ImpactHard"
    return true
end

function SWEP:PrimaryAttackAdd(ent)
    if hgIsDoor(ent) and math.random(7) > 3 then
        hgBlastThatDoor(ent,self:GetOwner():GetAimVector() * 50 + self:GetOwner():GetVelocity())
    end
end

SWEP.NoHolster = true
SWEP.BlockTier = 3

SWEP.AttackTimeLength = 0.155
SWEP.Attack2TimeLength = 0.01

SWEP.AttackRads = 95
SWEP.AttackRads2 = 0

SWEP.SwingAng = -165
SWEP.SwingAng2 = 0

SWEP.MinSensivity = 0.87