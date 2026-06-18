if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Cinderblock"
SWEP.Instructions = "A Cinderblock, used for building and construction."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Weight = 0
SWEP.WorldModelExchange =  "models/props_junk/cinderblock01a.mdl"
SWEP.WorldModelReal = "models/viper/mw/weapons/v_cinderblock.mdl"
SWEP.WorldModelExchange =  "models/props_junk/cinderblock01a.mdl"
SWEP.ViewModel = ""


SWEP.HoldType = "camera"

SWEP.HoldPos = Vector(-5,1,0)

SWEP.AttackTime = 0.45
SWEP.AnimTime1 = 2.15
SWEP.WaitTime1 = 1.3
SWEP.ViewPunch1 = Angle(1,2,0)

SWEP.Attack2Time = 0.25
SWEP.AnimTime2 = 2
SWEP.WaitTime2 = 0.8
SWEP.ViewPunch2 = Angle(0,0,-2)

SWEP.attack_ang = Angle(0,0,-15)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 115

SWEP.weaponPos = Vector(-0.5,0,0.5)
SWEP.weaponAng = Angle(0,0,-75)
SWEP.modelscale = 0.71

SWEP.DamageType = DMG_CLUB
SWEP.DamagePrimary = 25
SWEP.DamageSecondary = 20

SWEP.PenetrationPrimary = 2.5
SWEP.PenetrationSecondary = 2

SWEP.BlockTier = 3
SWEP.MaxPenLen = 5

SWEP.PenetrationSizePrimary = 3
SWEP.PenetrationSizeSecondary = 1.25

SWEP.StaminaPrimary = 30
SWEP.StaminaSecondary = 20

SWEP.AttackLen1 = 70
SWEP.AttackLen2 = 65

SWEP.AnimList = {
    ["idle"] = "idle",
    ["deploy"] = "draw",
    ["attack"] = "melee_miss_01",
    ["attack2"] = "melee_miss_02",
    ["holster"] = "holster",
}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/entities/mg_cinderblock")
	SWEP.IconOverride = "vgui/entities/mg_cinderblock"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = true
SWEP.setrh = true

SWEP.AttackHit = "cinderblock/hit1.ogg"
SWEP.Attack2Hit = "cinderblock/hit1.ogg"
SWEP.AttackHitFlesh = "Flesh.ImpactHard"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "physics/metal/metal_grenade_impact_soft1.wav"


SWEP.AttackPos = Vector(0,0,0)


SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.01

SWEP.BlockHoldPos = Vector(-7.5,1,10)
SWEP.BlockHoldAng = Angle(18, 15, -20)

SWEP.AttackRads = 60
SWEP.AttackRads2 = 0

SWEP.BreakBoneMul = 1.1
SWEP.PainMultiplier = 1.5

SWEP.SwingAng = -30
SWEP.SwingAng2 = 0

SWEP.holsteredBone = "ValveBiped.Bip01_Pelvis" -- Different attachment point
SWEP.holsteredPos = Vector(-1.1, -9, -5.3) -- Adjust position
SWEP.holsteredAng = Angle(195, 75, 230) -- Adjust rotation
SWEP.Concealed = false -- wont show up on the body
SWEP.HolsterIgnored = true -- the holster system will ignore
SWEP.Ignorebelt = true



function SWEP:CanSecondaryAttack()
    self.DamageType = DMG_CLUB
    return true
end

function SWEP:PrimaryAttack()
    self.AttackHit = self:GetRandomCinderHitSound()
    self.BaseClass.PrimaryAttack(self)
end


SWEP.AnimList["Attack_Charge_End"] = SWEP.AnimList["attack"]

SWEP.CanHeavyAttack = true
SWEP.HeavyAttackDamageMul = 2.5          
SWEP.HeavyAttackWaitTime = 2.0            -- перезарядка
SWEP.HeavyAttackAnimTimeBegin = 0.7       -- подготовка
SWEP.HeavyAttackAnimTimeIdle = 0.8        -- цикл удержания
SWEP.HeavyAttackAnimTimeEnd = 2.5        -- длительность удара
SWEP.HeavyAttackDelay = 0.4               -- задержка до попадания
SWEP.HeavyAttackTimeLength = 0.25         -- окно попадания
SWEP.HeavyAttackMaxChargeTime = 1.5       -- время до полной зарядки
SWEP.HeavyAttackSwingAng = -45
SWEP.HeavyAttackRads = 110                -- широкий угол удара
SWEP.HeavyChargeHoldPos = Vector(-13,0,7)
SWEP.HeavyChargeHoldAng = Angle(-30, 0, 0) 




SWEP.NoHolster = true
SWEP.MinSensivity = 0.75
SWEP.CinderHitSounds = {
    "cinderblock/cinderhit1.ogg",
    "cinderblock/cinderhit2.ogg",
    "cinderblock/cinderhit3.ogg",
    "cinderblock/cinderhit4.ogg",
}


function SWEP:GetRandomCinderHitSound()
    return self.CinderHitSounds[math.random(#self.CinderHitSounds)]
end

function SWEP:InitAdd()
    util.PrecacheSound("cinderblock/cinderhit1.ogg")
    util.PrecacheSound("cinderblock/cinderhit2.ogg")
    util.PrecacheSound("cinderblock/cinderhit3.ogg")
    util.PrecacheSound("cinderblock/cinderhit4.ogg")
end

function SWEP:PrimaryAttackAdd(ent, trace)
    if SERVER and IsValid(ent) and self:IsEntSoft(ent) then
        local owner = self:GetOwner()
        if IsValid(owner) then
            owner:EmitSound(self:GetRandomCinderHitSound(), 50, math.random(95,105))
        end
    end
end

function SWEP:SecondaryAttackAdd(ent, trace)
    if SERVER and IsValid(ent) and self:IsEntSoft(ent) then
        local owner = self:GetOwner()
        if IsValid(owner) then
            owner:EmitSound(self:GetRandomCinderHitSound(), 50, math.random(95,105))
        end
    end
end