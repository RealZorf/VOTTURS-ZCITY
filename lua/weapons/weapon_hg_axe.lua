if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Woodcutting axe"
SWEP.Instructions = "An axe is an implement that has been used for millennia to shape, split, and cut wood. Can break down doors.\n\nLMB to attack.\nRMB to block.\nE+LMB to charge up a heavy attack."
SWEP.Category = "Weapons - Melee"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/props/cs_militia/axe.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_bat_metal.mdl"
SWEP.WorldModelExchange = "models/props/cs_militia/axe.mdl"
SWEP.ViewModel = ""

SWEP.SuicidePos = Vector(0, -1, -26)
SWEP.SuicideAng = Angle(-70, 50, -30)
SWEP.SuicideCutVec = Vector(-2, 4, -3)
SWEP.SuicideCutAng = Angle(10, 0, 0)
SWEP.SuicideTime = 0.5
SWEP.SuicideSound = "player/flesh/flesh_bullet_impact_03.wav"
SWEP.CanSuicide = true
SWEP.SuicideNoLH = false
SWEP.SuicideHoldType = "slam"

SWEP.HoldType = "pistol"

SWEP.HoldPos = Vector(-9,0,0)
SWEP.HoldAng = Angle(0,0,-20)

SWEP.AttackTime = 0.62
SWEP.AnimTime1 = 2.3
SWEP.WaitTime1 = 2.34
SWEP.ViewPunch1 = Angle(1,1,-1)
SWEP.weight = 5

SWEP.modelscale = 0.85

SWEP.Attack2Time = 0.3
SWEP.AnimTime2 = 1
SWEP.WaitTime2 = 0.8
SWEP.ViewPunch2 = Angle(0,0,-2)

SWEP.attack_ang = Angle(0,0,0)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(0,0,0.5)
SWEP.weaponAng = Angle(0,-90,-13)

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}

SWEP.DamageType = DMG_SLASH
SWEP.DamagePrimary = 35
SWEP.NeckBreakChance = 0.01
SWEP.DamageSecondary = 14

SWEP.PenetrationPrimary = 8
SWEP.PenetrationSecondary = 3

SWEP.MaxPenLen = 10

SWEP.PenetrationSizePrimary = 5.5
SWEP.PenetrationSizeSecondary = 1.5

SWEP.StaminaPrimary = 45
SWEP.StaminaSecondary = 15

SWEP.AttackLen1 = 50
SWEP.AttackLen2 = 40

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_axe")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_axe"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = true
SWEP.setrh = true
SWEP.TwoHanded = true
SWEP.BlockTier = 3

SWEP.AttackHit = "Canister.ImpactHard"
SWEP.Attack2Hit = "Canister.ImpactHard"
SWEP.AttackHitFlesh = "snd_jack_hmcd_axehit.wav"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "physics/wood/wood_plank_impact_soft2.wav"
SWEP.SwingSound = "baseballbat/swing.ogg"
SWEP.HitFleshExtra = {
    "axe/axehit1.wav",
    "axe/axehit2.wav",
    "axe/axehit3.wav",
    "axe/axehit4.wav",
    "axe/axehit5.wav",
}
SWEP.HitFleshExtraPitch = 112
SWEP.SwingSoundPitch = {85, 95}

SWEP.AttackPos = Vector(0,0,0)

SWEP.NoHolster = true

SWEP.AttackTimeLength = 0.155
SWEP.Attack2TimeLength = 0.01

SWEP.AttackRads = 75
SWEP.AttackRads2 = 0

SWEP.SwingAng = -20
SWEP.SwingAng2 = 0

SWEP.Attack_Charge_Begin = "Attack_Charge_Begin"
SWEP.Attack_Charge_Idle = "Attack_Charge_Idle"
SWEP.Attack_Charge_End = "Attack_Charge_End"
SWEP.CanHeavyAttack = true -- Set to true to enable

SWEP.HeavyAttackDamageMul = 2 -- Max damage multiplier at full charge
SWEP.HeavyAttackWaitTime = 3 -- Time before you can attack again
SWEP.HeavyAttackAnimTimeBegin = 1.0 -- Duration of the wind-up/start animation
SWEP.HeavyAttackAnimTimeIdle = 1 -- Duration of the idle loop
SWEP.HeavyAttackAnimTimeEnd = 1.85 -- Duration of the attack animation
SWEP.HeavyAttackDelay = 0.5 -- Time delay before the hit actually connects (during attack anim)
SWEP.HeavyAttackTimeLength = 0.4 -- Duration of the active hit window
SWEP.HeavyAttackViewPunch = Angle(5, 0, 0) -- View punch angle on hit
SWEP.HeavyAttackMaxChargeTime = 3 -- Time in seconds to reach max damage/shake
SWEP.HeavyAttackSwingAng = 90 -- Custom swing angle for heavy attack
SWEP.HeavyAttackRads = 95 -- Custom radius/arc for heavy attack

SWEP.HeavyAttackWeaponAng = Angle(-3, -90, -13) -- Configure this angle for heavy attack phase
SWEP.DefaultWeaponAng = Angle(0,-90,-13) -- Default angle (should match SWEP.weaponAng)
SWEP.HeavyAttackWeaponAngTransitionSpeed = 10 -- Speed of the smooth transition

SWEP.MeleeMaterial = "wood"
SWEP.BlockImpactSound = "physics/wood/wood_plank_impact_hard1.wav"

function SWEP:CanPrimaryAttack()
    self.DamageType = DMG_SLASH
    self.AttackHit = "Canister.ImpactHard"
    self.Attack2Hit = "Canister.ImpactHard"
    return true
end

function SWEP:CanSecondaryAttack()
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

SWEP.MinSensivity = 0.7

SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeVPShouldUseHand = false
SWEP.FakeViewBobBaseBone = "base"
SWEP.ViewPunchDiv = 50

function SWEP:Think()
    -- Call the base custom think logic (suicide, dropping, etc.)
    self:CustomThink()

    if CLIENT then
        local targetAng = self.DefaultWeaponAng
        
        -- Check if heavy attack is active (ChargeState > 0 means Begin, Idle, or Attack)
        if self:GetChargeState() > 0 then
            targetAng = self.HeavyAttackWeaponAng
        end
        
        -- Smoothly interpolate weaponAng
        self.weaponAng = LerpAngle(FrameTime() * (self.HeavyAttackWeaponAngTransitionSpeed or 10), self.weaponAng, targetAng)
    end
end