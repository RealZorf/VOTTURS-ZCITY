if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "KA-BAR"
SWEP.Instructions = "They wont last long."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = true

SWEP.WorldModel = "models/weapons/tfa_ins2/w_marinebayonet.mdl"
SWEP.WorldModelReal = "models/weapons/gleb/c_knife_t.mdl"
SWEP.WorldModelExchange = "models/weapons/tfa_ins2/w_marinebayonet.mdl"
SWEP.DontChangeDropped = true
SWEP.modelscale = 0.85
SWEP.modelscale2 = 1

SWEP.BleedMultiplier = 1.5
SWEP.PainMultiplier = 3

SWEP.DamagePrimary = 300
SWEP.DamageSecondary = 55

SWEP.AttackTime = 0.95
SWEP.AnimTime1 = 3
SWEP.WaitTime1 = 1.8
SWEP.AttackLen1 = 65

SWEP.Attack2Time = 0.45
SWEP.AnimTime2 = 1.5
SWEP.WaitTime2 = 1
SWEP.AttackLen2 = 40
SWEP.ViewPunch2 = Angle(0,0,-2)

SWEP.setlh = true
SWEP.setrh = true

SWEP.basebone =76

SWEP.weaponPos = Vector(-2,0,0)
SWEP.weaponAng = Angle(0,0,100)

SWEP.HoldType = "knife"

SWEP.InstantPainMul = 0.4

--models/weapons/gleb/c_knife_t.mdl
if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/hud/tfa_ins2_kabar")
	SWEP.IconOverride = "vgui/hud/tfa_ins2_kabar"
	SWEP.BounceWeaponIcon = false
end

SWEP.BreakBoneMul = 1
SWEP.ImmobilizationMul = 1
SWEP.StaminaMul = 0.6
SWEP.HadBackBonus = true

SWEP.HoldPos = Vector(-4.3,0,-4.1)
SWEP.HoldAng = Angle(-15,0,0)

-- Blocking configuration
SWEP.BlockHoldPos = Vector(-4.3,0,-4)
SWEP.BlockHoldAng = Angle(-45,0,0)
SWEP.BlockSound = "physics/metal/metal_solid_impact_bullet3.wav"

-- Animation list for actual weapon animations
SWEP.AnimList = {
    ["idle"] = "idle",
    ["deploy"] = "draw",
    ["attack"] = "stab",
    ["attack2"] = "midslash1",
}

SWEP.Attack2HitFlesh = "hit_flesh7.wav"
SWEP.BlockTier = 4

function SWEP:Initialize()
    self.attackanim = 0
    self.sprintanim = 0
    self.animtime = 0
    self.animspeed = 1
    self.reverseanim = false
    self.Initialzed = true
    self:PlayAnim("idle",10,true)

    self:SetAttackLength(60)
    self:SetAttackWait(0)

    self:SetHold(self.HoldType)

    self:InitAdd()
end

function SWEP:Reload()
    if SERVER then
        if self:GetOwner():KeyPressed(IN_ATTACK) then
            self:SetNetVar("mode", not self:GetNetVar("mode"))
            self:GetOwner():ChatPrint("Changed mode to "..(self:GetNetVar("mode") and "slash." or "stab."))
        end
    end
end

function SWEP:CanPrimaryAttack()
    if self:GetOwner():KeyDown(IN_RELOAD) then return end
    if not self:GetNetVar("mode") then
        return true
    else
        self.allowsec = true
	self:SecondaryAttack(true) -- fix: use DoSecondaryAttack for slash, not SecondaryAttack which blocks
        self.allowsec = nil
        return false
    end
end

function SWEP:CanSecondaryAttack()
    return self.allowsec and true or false
end

SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.1

SWEP.AttackRads = 35
SWEP.AttackRads2 = 65

SWEP.SwingAng = -90
SWEP.SwingAng2 = 0

SWEP.MultiDmg1 = false
SWEP.MultiDmg2 = true

function SWEP:Think()
    if SERVER then
        local owner = self:GetOwner()
        if IsValid(owner) and owner:IsPlayer() then
            owner:SetNetVar("slowDown", 0)
        end
    end
    
    if self.BaseClass and self.BaseClass.Think then
        self.BaseClass.Think(self)
    end
end

-- Override DoPrimaryAttack to add powerstab sound during swing
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
    
    -- Play random powerstab sound during swing
    if SERVER then
        local powerstabSound = "vocals_617/powerstab" .. math.random(1, 4) .. ".wav"
        ply:EmitSound(powerstabSound, 50, math.random(95, 105))
    end
    
    -- End blocking after attack
    self:EndBlock()
end

-- Override PrimaryAttackAdd to add stab_gib sound when hitting targets
function SWEP:PrimaryAttackAdd(ent, trace)
    if SERVER and self:IsEntSoft(ent) then
        -- Play random stab_gib sound when hitting flesh
        local stabGibSound = "stab_gib" .. math.random(1, 3) .. ".wav"
        self:GetOwner():EmitSound(stabGibSound, 50, math.random(95, 105))
    end
end