if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Crovel"
SWEP.Instructions = "A multifunctional combat shovel based on modern military entrenching tools. Combines a sharpened shovel head, chopping edge, and pry functionality in one tool."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/tfa_kf2/w_crovel.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_fubar.mdl"
SWEP.WorldModelExchange = "models/weapons/tfa_kf2/w_crovel.mdl"
SWEP.ViewModel = ""
SWEP.weight = 3.15

SWEP.SuicidePos = Vector(9, 12, 18)
SWEP.SuicideAng = Angle(60, -30, 0)
SWEP.SuicideCutVec = Vector(1, 5, 1)
SWEP.SuicideCutAng = Angle(10, 0, 0)
SWEP.SuicideTime = 0.5
SWEP.SuicideSound = "player/flesh/flesh_bullet_impact_03.wav"
SWEP.CanSuicide = true
SWEP.SuicideNoLH = false
SWEP.SuicideHoldType = "slam"

SWEP.NoHolster = true

SWEP.HoldType = "camera"

SWEP.DamageType = DMG_SLASH

SWEP.HoldPos = Vector(-11, 0, 0)

SWEP.AttackTime = 0.65
SWEP.AnimTime1 = 2
SWEP.WaitTime1 = 1.4
SWEP.ViewPunch1 = Angle(1, 2, 0)

SWEP.Attack2Time = 0.2
SWEP.AnimTime2 = 1
SWEP.WaitTime2 = 0.8
SWEP.ViewPunch2 = Angle(0, 0, -2)

SWEP.attack_ang = Angle(0, 0, 0)
SWEP.sprint_ang = Angle(15, 0, 0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(0, 0, -15)
SWEP.weaponAng = Angle(0, -90, 0)

SWEP.DamageType = DMG_CLUB
SWEP.DamagePrimary = 55
SWEP.DamageSecondary = 18

SWEP.PenetrationPrimary = 4
SWEP.PenetrationSecondary = 6

SWEP.MaxPenLen = 4

SWEP.PenetrationSizePrimary = 3
SWEP.PenetrationSizeSecondary = 1.25

SWEP.StaminaPrimary = 33
SWEP.StaminaSecondary = 25

SWEP.AttackLen1 = 65
SWEP.AttackLen2 = 45

-- Blocking configuration
SWEP.BlockHoldPos = Vector(-11, 0, 0)
SWEP.BlockHoldAng = Angle(0, 9, -25)
SWEP.BlockSound = "physics/metal/metal_solid_impact_bullet1.wav"

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}

if CLIENT then
    SWEP.WepSelectIcon = Material("vgui/crovel.png")
    SWEP.IconOverride = "vgui/crovel.png"
    SWEP.BounceWeaponIcon = false
end

SWEP.setlh = true
SWEP.setrh = true

SWEP.HeavyAttackDamageType = DMG_SLASH
SWEP.HeavyAttackDamageMul = 2.0 -- Max damage multiplier at full charge
SWEP.HeavyAttackWaitTime = 1.0 -- Time before you can attack again
SWEP.HeavyAttackAnimTimeBegin = 1.0 -- Duration of the wind-up/start animation
SWEP.HeavyAttackAnimTimeIdle = 1 -- Duration of the idle loop
SWEP.HeavyAttackAnimTimeEnd = 1.85 -- Duration of the attack animation
SWEP.HeavyAttackDelay = 0.5 -- Time delay before the hit actually connects (during attack anim)
SWEP.HeavyAttackTimeLength = 0.4 -- Duration of the active hit window
SWEP.HeavyAttackViewPunch = Angle(5, 0, 0) -- View punch angle on hit
SWEP.HeavyAttackMaxChargeTime = 2.0 -- Time in seconds to reach max damage/shake
SWEP.HeavyAttackSwingAng = -90 -- Custom swing angle for heavy attack
SWEP.HeavyAttackRads = 75 -- Custom radius/arc for heavy attack


SWEP.CanHeavyAttack = true -- Set to true to enable


SWEP.BreakBoneMul = 0.55
SWEP.PainMultiplier = 0.9

SWEP.AttackHit = "Canister.ImpactHard"
SWEP.Attack2Hit = "Canister.ImpactHard"
SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.Attack2HitFlesh = "snd_jack_hmcd_axehit.wav"
SWEP.DeploySnd = "physics/metal/metal_grenade_impact_soft2.wav"

if SERVER then 
    util.PrecacheSound("shovelhit.mp3")
    util.PrecacheSound("heavyshovel/hit1.mp3")
    util.PrecacheSound("heavyshovel/hit2.mp3")
    util.PrecacheSound("heavyshovel/hit3.mp3")
end

SWEP.AttackPos = Vector(0, 0, 0)

function SWEP:CanSecondaryAttack()
    self.DamageType = DMG_SLASH
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

SWEP.AttackTimeLength = 0.10
SWEP.Attack2TimeLength = 0.01

SWEP.AttackRads = 65
SWEP.AttackRads2 = 0

SWEP.SwingAng = -15
SWEP.SwingAng2 = 0
SWEP.BlockTier = 3


function SWEP:PrimaryAttack()
    if hg.KeyDown(self:GetOwner(),IN_USE) then
        local tr = self.Owner:GetEyeTrace()
        if IsValid(tr.Entity) and string.find(string.lower(tr.Entity:GetClass()), "door") and self:GetOwner():GetPos():Distance(tr.Entity:GetPos()) <= 80 then
            local locked = false
            if tr.Entity.GetInternalVariable then
                locked = tr.Entity:GetInternalVariable("m_bLocked")
            end
            if not locked then
                return
            end
            if not self.BreakingDoor then
                self.BreakingDoor = true
                self.BreakStartTime = CurTime()
                self.BreakDuration = math.random(15, 20)
                self.DoorEntity = tr.Entity
                self.NextBreakSound = CurTime() + math.Rand(1, 2)
            end
            return
        end
    end
    self.BaseClass.PrimaryAttack(self)
end

function SWEP:Think()
    if self.BreakingDoor then
        if not (hg.KeyDown(self:GetOwner(),IN_USE) and hg.KeyDown(self:GetOwner(),IN_ATTACK)) then
            self.BreakingDoor = false
        elseif not (IsValid(self.DoorEntity) and self:GetOwner():GetPos():Distance(self.DoorEntity:GetPos()) <= 80) then
            self.BreakingDoor = false
        else
            if not self.NextBreakSound then
                self.NextBreakSound = CurTime() + math.Rand(1, 2)
            end
            if CurTime() >= self.NextBreakSound then
                if IsValid(self.DoorEntity) then
                    self.DoorEntity:EmitSound("physics/wood/wood_crate_break2.wav", 75, 100)
                end
                self.NextBreakSound = CurTime() + math.Rand(1, 2)
            end
            if CurTime() >= self.BreakStartTime + self.BreakDuration then
                if IsValid(self.DoorEntity) then
                    self.DoorEntity:Fire("Unlock", "", 0)
                    self.DoorEntity:Fire("Open", "", 0)
                end
                self.BreakingDoor = false
            end
        end
    end
    self.BaseClass.Think(self)
end

SWEP.MinSensivity = 0.6

function SWEP:PrimaryAttackAdd(ent, trace)
    if SERVER and IsValid(ent) and self:IsEntSoft(ent) then
        self:GetOwner():EmitSound("shovelhit.mp3", 50, math.random(95, 115))
        self:GetOwner():EmitSound("heavyshovel/hit" .. math.random(1,3) .. ".mp3", 50, math.random(95, 115))
    end
end


