if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Razor"
SWEP.Instructions = "A Sharp razor used for haircuts, trimming and slitting throats."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/wm/razor/w.mdl"
SWEP.WorldModelReal = "models/wm/razor/v.mdl"
SWEP.ViewModel = ""

SWEP.SuicidePos = Vector(16, -4, -20)
SWEP.SuicideAng = Angle(-70, -180, 90)
SWEP.SuicideCutVec = Vector(3, -6, 3)
SWEP.SuicideCutAng = Angle(10, 0, 0)
SWEP.SuicideTime = 0.5
SWEP.SuicideSound = "player/flesh/flesh_bullet_impact_03.wav"
SWEP.CanSuicide = true
SWEP.SuicideNoLH = true
SWEP.SuicidePunchAng = Angle(5, -15, 0)

SWEP.HoldType = "slam"

SWEP.DamageType = DMG_SLASH

SWEP.HoldPos = Vector(-6.2,0,-1)

SWEP.AttackTime = 0.25
SWEP.AnimTime1 = 1
SWEP.WaitTime1 = 0.8
SWEP.ViewPunch1 = Angle(1,2,0)

SWEP.Attack2Time = 0.15
SWEP.AnimTime2 = 0.7
SWEP.WaitTime2 = 0.8
SWEP.ViewPunch2 = Angle(1,2,-2)

SWEP.attack_ang = Angle(0,0,0)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(0,0,0)
SWEP.weaponAng = Angle(0,0,0)

SWEP.DamageType = DMG_SLASH
SWEP.DamagePrimary = 16
SWEP.DamageSecondary = 1
SWEP.BleedMultiplier = 1.6
SWEP.PainMultiplier = 1.1
SWEP.BreakBoneMul = 0.5

SWEP.PenetrationPrimary = 3
SWEP.PenetrationSecondary = 0

SWEP.MaxPenLen = 6

SWEP.PenetrationSizePrimary = 1.5
SWEP.PenetrationSizeSecondary = 0

SWEP.StaminaPrimary = 12


SWEP.AttackLen1 = 42
SWEP.AttackLen2 = 35
SWEP.BlockTier = 2

-- Blocking configuration
SWEP.BlockHoldPos = Vector(-15, 7, -6)
SWEP.BlockHoldAng = Angle(-5, 0, -45)
SWEP.BlockSound = "physics/metal/metal_solid_impact_bullet3.wav"

SWEP.AnimList = {
    ["idle"] = "h1_wpn_melee_razor_idle",
    ["deploy"] = "h1_wpn_melee_razor_pullout",
    ["attack"] = "h1_wpn_melee_razor_swipe",
}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wm_razor_i.png")
	SWEP.IconOverride = "vgui/wm_razor_i.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = false
SWEP.setrh = true


SWEP.AttackHit = "snd_jack_hmcd_knifehit.wav"
SWEP.Attack2Hit = "snd_jack_hmcd_knifehit.wav"
SWEP.AttackHitFlesh = "snd_jack_hmcd_slash.wav"
SWEP.Attack2HitFlesh = "physics/flesh/flesh_impact_hard1.wav"
SWEP.DeploySnd = "knife_bayonet_equip.ogg"

SWEP.AttackPos = Vector(0,0,0)

function SWEP:CanSecondaryAttack()
    return false
end

function SWEP:CanPrimaryAttack()
    return true
end

SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.05

SWEP.AttackRads = 45
SWEP.AttackRads2 = 35

SWEP.SwingAng = -15
SWEP.SwingAng2 = 0

SWEP.MultiDmg1 = false
SWEP.MultiDmg2 = false

function SWEP:SecondaryAttackAdd(ent, trace)
    if trace.Entity:IsPlayer() or trace.Entity:IsNPC() then trace.Entity:SetVelocity(trace.Normal * 70 * (trace.Entity:IsNPC() and 35 or 5)) end
    local phys = trace.Entity:GetPhysicsObjectNum(trace.PhysicsBone or 0)

    if IsValid(phys) then
        phys:ApplyForceOffset(trace.Normal * 42 * 100,trace.HitPos)
    end
end

SWEP.MinSensivity = 0.25