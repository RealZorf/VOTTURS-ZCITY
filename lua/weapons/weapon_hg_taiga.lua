if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Taiga"
SWEP.Instructions = "A taiga is a versatile machete designed for clearing dense foliage and performing rugged outdoor tasks with efficiency."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/tfa_nmrih/w_me_cleaver.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_cleaver.mdl"
SWEP.WorldModelExchange = "models/bf4_sweps/w_knife_machete.mdl"
SWEP.ViewModel = ""

SWEP.weight = 1.2

SWEP.SuicidePos = Vector(12, -17, -22)
SWEP.SuicideAng = Angle(-40, 100, 0)
SWEP.SuicideCutVec = Vector(1, -7, 4)
SWEP.SuicideCutAng = Angle(10, 0, 0)
SWEP.SuicideTime = 0.5
SWEP.SuicideSound = "weapons/knife/knife_hit1.wav"
SWEP.CanSuicide = true
SWEP.SuicidePunchAng = Angle(-5, -10, 10)


SWEP.NoHolster = true

SWEP.HoldType = "slam"

SWEP.DamageType = DMG_SLASH

SWEP.HoldPos = Vector(-14,0,0)

SWEP.AttackTime = 0.25
SWEP.AnimTime1 = 1.1
SWEP.WaitTime1 = 0.9
SWEP.ViewPunch1 = Angle(1,2,0)

SWEP.Attack2Time = 0.15
SWEP.AnimTime2 = 0.7
SWEP.WaitTime2 = 0.8
SWEP.ViewPunch2 = Angle(1,2,-2)

SWEP.attack_ang = Angle(0,0,0)
SWEP.sprint_ang = Angle(15,0,0)

SWEP.basebone = 94

SWEP.weaponPos = Vector(0.4,-1.4,-4)
SWEP.weaponAng = Angle(-35,-85,-2)

SWEP.DamageType = DMG_SLASH
SWEP.DamagePrimary = 22
SWEP.DamageSecondary = 1
SWEP.BleedMultiplier = 1.5
SWEP.PainMultiplier = 1.6

SWEP.PenetrationPrimary = 5.5
SWEP.PenetrationSecondary = 0

SWEP.MaxPenLen = 6

SWEP.PenetrationSizePrimary = 1.5
SWEP.PenetrationSizeSecondary = 0

SWEP.StaminaPrimary = 19
SWEP.StaminaSecondary = 13

SWEP.AttackLen1 = 50
SWEP.AttackLen2 = 35

-- Blocking configuration
SWEP.BlockHoldPos = Vector(-15, 7, -6)
SWEP.BlockHoldAng = Angle(-5, 0, -45)
SWEP.BlockSound = "physics/metal/metal_solid_impact_bullet3.wav"

SWEP.AnimList = {
    ["idle"] = "Idle",
    ["deploy"] = "Draw",
    ["attack"] = "Attack_Quick",
    ["attack2"] = "Shove",
}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/hud/taiga")
	SWEP.IconOverride = "vgui/hud/taiga"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = false
SWEP.setrh = true

SWEP.holsteredBone = "ValveBiped.Bip01_Pelvis" -- Different attachment point
SWEP.holsteredPos = Vector(6, -1.5, -6) -- Adjust position
SWEP.holsteredAng = Angle(65, 0, 0) -- Adjust rotation
SWEP.Concealed = true -- wont show up on the body
SWEP.HolsterIgnored = false -- the holster system will ignore


SWEP.AttackHit = "snd_jack_hmcd_knifehit.wav"
SWEP.Attack2Hit = "snd_jack_hmcd_knifehit.wav"
SWEP.AttackHitFlesh = "weapons/knife/knife_hit1.wav"
SWEP.Attack2HitFlesh = "physics/flesh/flesh_impact_hard1.wav"
SWEP.DeploySnd = "physics/metal/metal_grenade_impact_soft2.wav"

SWEP.AttackPos = Vector(0,0,0)
SWEP.BlockTier = 3


function SWEP:CanSecondaryAttack()
    self.DamageType = DMG_CLUB
    self.AttackHit = "physics/flesh/flesh_impact_hard"..math.random(1,6)..".wav"
    self.Attack2Hit = "physics/flesh/flesh_impact_hard"..math.random(1,6)..".wav"
    self.Attack2HitFlesh = "physics/flesh/flesh_impact_hard"..math.random(1,6)..".wav"
    self.setlh = true
    self.HoldType = "duel"
    timer.Simple(0.5,function()
        if IsValid(self) then
            self.setlh = false
            self.HoldType = "slam"
        end
    end)
    return true
end

function SWEP:CanPrimaryAttack()
    self.DamageType = DMG_SLASH
    self.AttackHit = "snd_jack_hmcd_knifehit.wav"
    self.Attack2Hit = "snd_jack_hmcd_knifehit.wav"
    -- Store the base sound path for custom pitch handling
    self.TaigaFleshSound = "taiga/hit"..math.random(3)..".wav"
    self.AttackHitFlesh = "" -- Disable default flesh sound to use custom one
    return true
end

SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.05

SWEP.AttackRads = 65
SWEP.AttackRads2 = 35

SWEP.SwingAng = -15
SWEP.SwingAng2 = 0

SWEP.MultiDmg1 = true
SWEP.MultiDmg2 = false

function SWEP:SecondaryAttackAdd(ent, trace)
    if trace.Entity:IsPlayer() or trace.Entity:IsNPC() then trace.Entity:SetVelocity(trace.Normal * 70 * (trace.Entity:IsNPC() and 35 or 5)) end
    local phys = trace.Entity:GetPhysicsObjectNum(trace.PhysicsBone or 0)

    if IsValid(phys) then
        phys:ApplyForceOffset(trace.Normal * 42 * 100,trace.HitPos)
    end
end

function SWEP:PrimaryAttackAdd(ent, trace)
    -- Play custom flesh hit sound with random pitch when hitting soft targets
    if SERVER and self:IsEntSoft(trace.Entity) and self.TaigaFleshSound then
        local owner = self:GetOwner()
        if IsValid(owner) then
            -- Sound cooldown to prevent multiple sounds during slash attacks
            local currentTime = CurTime()
            if not self.LastFleshSoundTime or (currentTime - self.LastFleshSoundTime) > 0.15 then
                self.LastFleshSoundTime = currentTime
                -- Play the taiga flesh sound with random pitch between 95-110
                owner:EmitSound(self.TaigaFleshSound, 50, math.random(95, 110))
            end
        end
    end
end

SWEP.MinSensivity = 0.25