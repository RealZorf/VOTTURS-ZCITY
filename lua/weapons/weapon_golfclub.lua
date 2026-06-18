if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Golf Club"
SWEP.Instructions = "A golf club is a precision tool designed to drive balls across the green, combining balance, leverage, and a solid swing."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/tfa_l4d_mw2019/melee/w_golfclub.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_l4d_mw2019/melee/c_golfclub.mdl"
SWEP.DontChangeDropped = false
SWEP.ViewModel = ""
SWEP.modelscale = 1

SWEP.Weight = 0
SWEP.weight = 2

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/hud/tfa_mw2019_golf_club")
	SWEP.IconOverride = "vgui/hud/tfa_mw2019_golf_club"
	SWEP.BounceWeaponIcon = false
end

SWEP.HoldType = "camera"

SWEP.DamageType = DMG_CLUB
SWEP.DamagePrimary = 30
SWEP.DamageSecondary = 15

SWEP.PenetrationPrimary = 2.5
SWEP.PenetrationSecondary = 1.5

SWEP.MaxPenLen = 2

SWEP.PenetrationSizePrimary = 2
SWEP.PenetrationSizeSecondary = 1

SWEP.StaminaPrimary = 26
SWEP.StaminaSecondary = 7

SWEP.HoldPos = Vector(-7,0,0)

SWEP.AttackTime = 0.5
SWEP.AnimTime1 = 1.5
SWEP.WaitTime1 = 0.95
SWEP.AttackLen1 = 65
SWEP.ViewPunch1 = Angle(2,4,0)

SWEP.BlockTier = 3

-- Blocking configuration
SWEP.BlockHoldPos = Vector(-7,0,7)
SWEP.BlockHoldAng = Angle(18, 15, -20)
SWEP.BlockSound = "physics/wood/wood_plank_impact_hard2.wav"

SWEP.Attack2Time = 0.3
SWEP.AnimTime2 = 1
SWEP.WaitTime2 = 0.8
SWEP.AttackLen2 = 40
SWEP.ViewPunch2 = Angle(0,0,-2)

SWEP.attack_ang = Angle(0,0,0)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(0,0,0)
SWEP.weaponAng = Angle(0,0,0)

SWEP.AnimList = {
    ["idle"] = "idle",
    ["deploy"] = "deploy",
    ["attack"] = "swing_e_w",
    ["attack2"] = "secondary_swing",
}

SWEP.setlh = true
SWEP.setrh = true
SWEP.TwoHanded = true




SWEP.AnimList["Attack_Charge_End"] = SWEP.AnimList["attack"]

SWEP.HeavyAttackDamageMul = 2.0 -- Max damage multiplier at full charge
SWEP.HeavyAttackWaitTime = 1.0 -- Time before you can attack again
SWEP.HeavyAttackAnimTimeBegin = 1.0 -- Duration of the wind-up/start animation
SWEP.HeavyAttackAnimTimeIdle = 1 -- Duration of the idle loop
SWEP.HeavyAttackAnimTimeEnd = 2 -- Duration of the attack animation
SWEP.HeavyAttackDelay = 0.5 -- Time delay before the hit actually connects (during attack anim)
SWEP.HeavyAttackTimeLength = 0.4 -- Duration of the active hit window
SWEP.HeavyAttackViewPunch = Angle(5, 0, 0) -- View punch angle on hit
SWEP.HeavyAttackMaxChargeTime = 2.0 -- Time in seconds to reach max damage/shake
SWEP.HeavyAttackSwingAng = -90 -- Custom swing angle for heavy attack
SWEP.HeavyAttackRads = 75 -- Custom radius/arc for heavy attack
SWEP.HeavyChargeHoldPos = Vector(-6,1,-10)
SWEP.HeavyChargeHoldAng = Angle(-80, 0, 0) 


SWEP.CanHeavyAttack = true -- Set to true to enable





SWEP.AttackHit = "weapons/tfa_l4d_mw2019/golf_club/wpn_golf_club_impact_world1.wav"
SWEP.Attack2Hit = "weapons/tfa_l4d_mw2019/golf_club/wpn_golf_club_impact_world2.wav"
SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "weapons/tfa_l4d_mw2019/golf_club/golf_club_deploy_1.wav"

SWEP.AttackPos = Vector(0,0,0)

-- Random flesh hit sounds for primary attack
function SWEP:CanPrimaryAttack()
    self.GolfFleshSound = "weapons/tfa_l4d_mw2019/golf_club/wpn_golf_club_melee_0"..math.random(1,2)..".wav"
    return true
end

-- Random flesh hit sounds for secondary attack  

-- Custom flesh hit sound with random pitch for primary attacks
function SWEP:PrimaryAttackAdd(ent, trace)
    if SERVER and self:IsEntSoft(trace.Entity) and self.GolfFleshSound then
        local owner = self:GetOwner()
        if IsValid(owner) then
            -- Sound cooldown to prevent spam
            local currentTime = CurTime()
            if not self.LastFleshSoundTime or (currentTime - self.LastFleshSoundTime) > 0.15 then
                self.LastFleshSoundTime = currentTime
                -- Play golf club flesh sound with random pitch 95-110
                owner:EmitSound(self.GolfFleshSound, 50, math.random(95, 110))
            end
        end
    end
end

-- Custom flesh hit sound with random pitch for secondary attacks
function SWEP:SecondaryAttackAdd(ent, trace)
    if SERVER and self:IsEntSoft(trace.Entity) and self.GolfFleshSound2 then
        local owner = self:GetOwner()
        if IsValid(owner) then
            -- Sound cooldown to prevent spam
            local currentTime = CurTime()
            if not self.LastFleshSoundTime2 or (currentTime - self.LastFleshSoundTime2) > 0.15 then
                self.LastFleshSoundTime2 = currentTime
                -- Play golf club flesh sound with random pitch 95-110
                owner:EmitSound(self.GolfFleshSound2, 50, math.random(95, 110))
            end
        end
    end
end

SWEP.NoHolster = true


SWEP.Swing = true -- Это отвесает за первый вид удара, изначально с права на лево
SWEP.LSwing = false -- Это отвесает за второй вид удара, изначально с права на лево
SWEP.SwingLeft = false -- Это отвесает за первый вид удара, переключает с лева на право
SWEP.LSwingLeft = false -- Это отвесает за второй вид удара, переключает с лева на право
SWEP.UpSwing = false -- Это отвесает за первый вид удара, Сверху вниз
SWEP.LUpSwing = false -- Это отвесает за второй вид удара, Сверху вниз

SWEP.BreakBoneMul = 0.5
SWEP.PainMultiplier = 0.7

SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.001

SWEP.AttackRads = 90
SWEP.AttackRads2 = 5

SWEP.SwingAng = -30
SWEP.SwingAng2 = 0

SWEP.MinSensivity = 0.6