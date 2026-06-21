if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Metal Pot"
SWEP.Instructions = "A simple metal pot that can be used as a melee weapon.\n\nLMB to attack.\nRMB to block.\nE+LMB to charge up a heavy attack."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Weight = 0
SWEP.weight = 1.25
SWEP.WorldModelExchange =  "models/props_c17/metalpot001a.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_tool_extinguisher.mdl"
SWEP.WorldModelExchange =  "models/props_c17/metalpot001a.mdl"
SWEP.ViewModel = ""

SWEP.HoldType = "camera"

SWEP.DamageType = DMG_SLASH

SWEP.HoldPos = Vector(-15,1,2)

SWEP.AttackTime = 0.49
SWEP.AnimTime1 = 1.9
SWEP.WaitTime1 = 1.3
SWEP.ViewPunch1 = Angle(1,2,0)

SWEP.Attack2Time = 0.25
SWEP.AnimTime2 = 1
SWEP.WaitTime2 = 0.8
SWEP.ViewPunch2 = Angle(0,0,-2)

SWEP.attack_ang = Angle(0,0,-15)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 93

SWEP.weaponPos = Vector(-0.5,0,-0.6)
SWEP.weaponAng = Angle(0,0,-75)
SWEP.modelscale = 0.63

SWEP.DamageType = DMG_CLUB
SWEP.DamagePrimary = 21
SWEP.DamageSecondary = 15

SWEP.PenetrationPrimary = 4
SWEP.PenetrationSecondary = 2

SWEP.MaxPenLen = 5

SWEP.PenetrationSizePrimary = 3
SWEP.PenetrationSizeSecondary = 1.25

SWEP.StaminaPrimary = 21
SWEP.StaminaSecondary = 15

SWEP.AttackLen1 = 65
SWEP.AttackLen2 = 30

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Attack_Quick",
    ["holster"] = "Draw",
}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/pot.png")
	SWEP.IconOverride = "vgui/pot.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = true
SWEP.setrh = true

SWEP.BlockTier = 2
SWEP.AttackHit = "Canister.ImpactHard"
SWEP.Attack2Hit = "Canister.ImpactHard"
SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "physics/metal/metal_grenade_impact_soft1.wav"

SWEP.AttackPos = Vector(0,0,0)

SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.01

SWEP.BlockHoldPos = Vector(-15,1,7)
SWEP.BlockHoldAng = Angle(18, 15, -20)

SWEP.AttackRads = 60
SWEP.AttackRads2 = 0

SWEP.BreakBoneMul = 1.1
SWEP.PainMultiplier = 1.6

SWEP.SwingAng = -30
SWEP.SwingAng2 = 0

SWEP.holsteredBone = "ValveBiped.Bip01_Pelvis" -- Different attachment point
SWEP.holsteredPos = Vector(-1.1, -9, -5.3) -- Adjust position
SWEP.holsteredAng = Angle(195, 75, 230) -- Adjust rotation
SWEP.Concealed = false -- wont show up on the body
SWEP.HolsterIgnored = true -- the holster system will ignore
SWEP.Ignorebelt = true

SWEP.CanHeavyAttack = true -- Set to true to enable
SWEP.HeavyAttackDamageMul = 2.0 -- Max damage multiplier at full charge
SWEP.HeavyAttackWaitTime = 1.7 -- Time before you can attack again
SWEP.HeavyAttackAnimTimeBegin = 1.0 -- Duration of the wind-up/start animation
SWEP.HeavyAttackAnimTimeIdle = 1 -- Duration of the idle loop
SWEP.HeavyAttackAnimTimeEnd = 1.85 -- Duration of the attack animation
SWEP.HeavyAttackDelay = 0.3 -- Time delay before the hit actually connects (during attack anim)
SWEP.HeavyAttackTimeLength = 0.4 -- Duration of the active hit window
SWEP.HeavyAttackViewPunch = Angle(5, 0, 0) -- View punch angle on hit
SWEP.HeavyAttackMaxChargeTime = 2.0 -- Time in seconds to reach max damage/shake
SWEP.HeavyAttackSwingAng = -90 -- Custom swing angle for heavy attack
SWEP.HeavyAttackRads = 95 -- Custom radius/arc for heavy attack
SWEP.HeavyChargeHoldPos = Vector(6, 5, 1)



function SWEP:SecondaryAttack()
    self.BaseClass.SecondaryAttack(self)
end

function SWEP:PrimaryAttack()
    self.BaseClass.PrimaryAttack(self)
end



SWEP.NoHolster = true
SWEP.MinSensivity = 0.75