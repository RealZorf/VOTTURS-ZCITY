if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Drill"
SWEP.Instructions = "A Drill is a tool that is used to dismantle/destroy certain objects, anything with a bolt. Can dismantle doors."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/props_junk/drill.mdl"
SWEP.WorldModelReal = "models/zac/c_kitchenknife.mdl"
SWEP.WorldModelExchange = "models/props_junk/drill.mdl"

SWEP.SuicidePos = Vector(-9, 1, -15)
SWEP.SuicideAng = Angle(-40, 0, 0)
SWEP.SuicideCutVec = Vector(-1, 1, 8)
SWEP.SuicideCutAng = Angle(10, 0, 0)
SWEP.SuicideTime = 1.5
SWEP.CanSuicide = true
SWEP.SuicideSound = "DrillHit.wav"
SWEP.SuicideNoLH = true

SWEP.basebone = 39


SWEP.weaponPos = Vector(0,0,-3)
SWEP.weaponAng = Angle(25,95,180)
SWEP.modelscale = 0.75

SWEP.BreakBoneMul = 1.6

SWEP.AttackTime = 0.6
SWEP.AnimTime1 = 2.1
SWEP.WaitTime1 = 1.2
SWEP.AttackLen1 = 45
SWEP.ViewPunch1 = Angle(1,1,0)

SWEP.Attack2Time = 0.25
SWEP.AnimTime2 = 0.85
SWEP.WaitTime2 = 1
SWEP.AttackLen2 = 30
SWEP.ViewPunch2 = Angle(0,0,-2)

SWEP.AnimList = {
    ["idle"] = "idle",
    ["deploy"] = "draw",
    ["attack"] = "attack_stab",
    ["attack2"] = "attack",
}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/drill.png")
	SWEP.IconOverride = "vgui/drill.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = false
SWEP.setrh = true

SWEP.HoldType = "melee"

SWEP.DeploySnd = ""

SWEP.AttackPos = Vector(0,0,0)
SWEP.DamageType = DMG_SLASH
SWEP.DamagePrimary = 45
SWEP.DamageSecondary = 12

SWEP.PenetrationPrimary = 5
SWEP.PenetrationSecondary = 3
SWEP.BleedMultiplier = 1.5

SWEP.MaxPenLen = 3

SWEP.PainMultiplier = 1

SWEP.PenetrationSizePrimary = 4
SWEP.PenetrationSizeSecondary = 1

SWEP.StaminaPrimary = 20
SWEP.StaminaSecondary = 13

SWEP.AttackLen1 = 42
SWEP.AttackLen2 = 35

-- how many drill hits a door needs before breaching
SWEP.DoorBreakHitsRequired = 3
-- cooldown to avoid counting multiple traces within one swing
SWEP.DoorBreakHitCooldown = 0.4


function SWEP:CanPrimaryAttack()
    return true
end

SWEP.BlockTier = 2

function SWEP:CanSecondaryAttack()
    self.DamageType = DMG_CLUB
	self.SwingSound = ""
    self.AttackHit = "Canister.ImpactHard"
    self.Attack2Hit = "Canister.ImpactHard"
    return true
end


SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.1

SWEP.AttackRads = 80
SWEP.AttackRads2 = 55

SWEP.SwingAng = -90
SWEP.SwingAng2 = 0

SWEP.AttackHit = "Canister.ImpactHard"
SWEP.Attack2Hit = "Canister.ImpactHard"
SWEP.AttackHitFlesh = "snd_jack_hmcd_knifestab.wav"
SWEP.Attack2HitFlesh = "Flesh.ImpactHard"
SWEP.DeploySnd = "physics/metal/metal_grenade_impact_soft2.wav"
SWEP.SwingSound = "drill.mp3"

SWEP.MultiDmg1 = true
SWEP.MultiDmg2 = false

SWEP.BlockHoldPos = Vector(-9.5, 15, -0.95)
SWEP.BlockHoldAng = Angle(-5, 0, -45)
SWEP.BlockSound = "physics/metal/metal_solid_impact_bullet3.wav"

SWEP.AnimList["Attack_Charge_End"] = SWEP.AnimList["attack"]

SWEP.CanHeavyAttack = true -- Set to true to enable
SWEP.NeckBreakChance = 0.01
SWEP.NoReverse = true

SWEP.HeavyAttackDamageMul = 2.0 -- Max damage multiplier at full charge
SWEP.HeavyAttackWaitTime = 1.7 -- Time before you can attack again
SWEP.HeavyAttackAnimTimeBegin = 1.0 -- Duration of the wind-up/start animation
SWEP.HeavyAttackAnimTimeIdle = 1 -- Duration of the idle loop
SWEP.HeavyAttackAnimTimeEnd = 1.4 -- Duration of the attack animation
SWEP.HeavyAttackDelay = 0.5 -- Time delay before the hit actually connects (during attack anim)
SWEP.HeavyAttackTimeLength = 0.4 -- Duration of the active hit window
SWEP.HeavyAttackViewPunch = Angle(5, 0, 0) -- View punch angle on hit
SWEP.HeavyAttackMaxChargeTime = 2.0 -- Time in seconds to reach max damage/shake
SWEP.HeavyAttackSwingAng = -90 -- Custom swing angle for heavy attack
SWEP.HeavyAttackRads = 95 -- Custom radius/arc for heavy attack
SWEP.HeavyChargeHoldPos = Vector(10,-2,16)
SWEP.HeavyChargeHoldAng = Angle(60, 0, 0)



-- play drill sound on swing (primary only)
function SWEP:DoPrimaryAttack()
    if not self:CanPrimaryAttack() then return end
    if not IsFirstTimePredicted() then return end
    local ply = self:GetOwner()
    if not ply:IsPlayer() then return end

    local ent = hg.GetCurrentCharacter(ply)
    if not (ent == ply or hg.KeyDown(ply,IN_USE) or (ply:GetNetVar("lastFake",0) > CurTime())) then return end
    if (self:GetLastAttack() + self:GetAttackWait()) > CurTime() then return end

    local mul = 1 / math.Clamp((180 - self:GetOwner().organism.stamina[1]) / 90,1,2)
    self.HitEnts = nil
    self.FirstAttackTick = false
    self.AttackHitPlayed = false
    self:PlayAnim("attack",self.AnimTime1 / mul,false,nil,false)
    self:SetAttackType(1)
    self:SetLastAttack(CurTime() + self.AttackTime / mul)
    self:SetAttackTime( self:GetLastAttack() + (self.AttackTimeLength / mul) )
    self:SetAttackLength(self.AttackLen1)
    self:SetAttackWait(self.WaitTime1 / mul)
    self:SetInAttack(true)
    if CLIENT and not self:IsLocal() and ply.AnimRestartGesture then
        self:GetOwner():AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM, true)
    end
    self.viewpunch = true

    if SERVER then
        -- delayed drill sound after swing start
        timer.Simple(0.2, function()
            if not IsValid(self) then return end
            local owner = self:GetOwner()
            if not IsValid(owner) then return end
            if owner:GetActiveWeapon() ~= self then return end
            owner:EmitSound("drill.mp3", 50, math.random(95, 105))
        end)
    end

    -- end blocking after attack
    self:EndBlock()
end

-- play hit sound on impact (both attack types)
function SWEP:PrimaryAttackAdd(ent, trace)
    if SERVER then
        local owner = self:GetOwner()

        -- no hit sound on doors; only play break sound when breaching
        if not (IsValid(ent) and hgIsDoor(ent)) and IsValid(owner) then
            owner:EmitSound("DrillHit.wav", 45, math.random(135, 145))
        end

        -- count drill hits on doors; one increment per swing
        if IsValid(ent) and hgIsDoor(ent) and IsValid(owner) then
            local now = CurTime()
            local cd = self.DoorBreakHitCooldown or 0.4
            if (ent._drillLastHitTime or 0) + cd <= now then
                ent._drillLastHitTime = now
                ent._drillHitCount = (ent._drillHitCount or 0) + 1

                if ent._drillHitCount >= (self.DoorBreakHitsRequired or 3) then
                    hgBlastThatDoor(ent, owner:GetAimVector() * 50 + owner:GetVelocity())
                    ent._drillHitCount = 0
                    sound.Play("BreakDoor.wav", ent:GetPos(), 90, 135, 1)
                end
            end
        end
    end
end

