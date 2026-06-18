if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Pitchfork"
SWEP.Instructions = "A Traditional pitchfork used for farming."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/tfa_l4d_mw2019/melee/w_pitchfork.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_fubar.mdl"
SWEP.WorldModelExchange = "models/weapons/tfa_l4d_mw2019/melee/w_pitchfork.mdl"
SWEP.ViewModel = ""

SWEP.NoHolster = true
SWEP.weight = 3

SWEP.HoldType = "camera"

SWEP.HoldPos = Vector(-11,3,0)
SWEP.HoldAng = Angle(0,-6,0)

SWEP.AttackTime = 0.7
SWEP.AnimTime1 = 2
SWEP.WaitTime1 = 1.3
SWEP.ViewPunch1 = Angle(1,2,0)

SWEP.Attack2Time = 0.7
SWEP.AnimTime2 = 2.1
SWEP.WaitTime2 = 1.4
SWEP.ViewPunch2 = Angle(0,0,-2)

SWEP.attack_ang = Angle(0,0,0)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(0,0, -29)
SWEP.weaponAng = Angle(180,200,0)

SWEP.DamageType = DMG_SLASH
SWEP.DamagePrimary = 43
SWEP.DamageSecondary = 15

SWEP.BreakBoneMul = 1.4

SWEP.PenetrationPrimary = 6
SWEP.PenetrationSecondary = 5

SWEP.MaxPenLen = 20

SWEP.PenetrationSizePrimary = 3
SWEP.PenetrationSizeSecondary = 3

SWEP.StaminaPrimary = 25
SWEP.StaminaSecondary = 60

SWEP.AttackLen1 = 90
SWEP.AttackLen2 = 45

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Shove",
    ["attack2"] = "Shove",
}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/hud/tfa_mw2019_pitchfork")
	SWEP.IconOverride = "vgui/hud/tfa_mw2019_pitchfork"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = true
SWEP.setrh = true
SWEP.AnimAlwaysBack = true


SWEP.AttackHit = "Concrete.ImpactHard"
SWEP.Attack2Hit = "Concrete.ImpactHard"
SWEP.AttackHitFlesh = "snd_jack_hmcd_axehit.wav"
SWEP.Attack2HitFlesh = "snd_jack_hmcd_axehit.wav"
SWEP.DeploySnd = "physics/wood/wood_plank_impact_soft2.wav"

SWEP.AttackPos = Vector(0,0,0)

SWEP.AttackTimeLength = 0.05
SWEP.Attack2TimeLength = 0.1

SWEP.AttackRads = 0
SWEP.AttackRads2 = 0

SWEP.BlockHoldPos = Vector(-15, 7, -6)
SWEP.BlockHoldAng = Angle(-5, 0, -45)

SWEP.SwingAng = -90
SWEP.SwingAng2 = 0

SWEP.holsteredBone = "ValveBiped.Bip01_Pelvis" -- Different attachment point
SWEP.holsteredPos = Vector(3.5, -14, -5.3) -- Adjust position
SWEP.holsteredAng = Angle(205, 75, 230) -- Adjust rotation
SWEP.Concealed = false -- wont show up on the body
SWEP.HolsterIgnored = false -- the holster system will ignore


function SWEP:CanSecondaryAttack()
    local owner = self:GetOwner()
    if CLIENT and owner ~= LocalPlayer() then return false end
    local org = owner.organism
    if org and org.stamina and org.stamina[1] < self.StaminaSecondary then return false end
    return true
end

function SWEP:CanPrimaryAttack()
    return true
end


SWEP.MinSensivity = 0.65