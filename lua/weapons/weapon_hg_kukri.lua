if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Kukri"
SWEP.Instructions = "A curved blade built for swift, deadly strikes. Precise, powerful, and intimidating up close."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/tfa_ins2/w_gurkha.mdl"
SWEP.WorldModelReal = "models/weapons/tfa_nmrih/v_me_cleaver.mdl"
SWEP.WorldModelExchange = "models/weapons/tfa_ins2/w_gurkha.mdl"
SWEP.ViewModel = ""

SWEP.SuicidePos = Vector(12, -21, -19)
SWEP.SuicideAng = Angle(-40, 100, 0)
SWEP.SuicideCutVec = Vector(1, -5, 4)
SWEP.SuicideCutAng = Angle(10, 0, 0)
SWEP.SuicideTime = 0.5
SWEP.SuicideSound = "weapons/knife/knife_hit1.wav"
SWEP.CanSuicide = true
SWEP.SuicidePunchAng = Angle(-5, -15, 0)

SWEP.NoHolster = true

SWEP.weight = 1

SWEP.HoldType = "slam"

SWEP.DamageType = DMG_SLASH

SWEP.HoldPos = Vector(-14,3.1,-6)
SWEP.HoldAng = Angle(0,0,-25)

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

SWEP.weaponPos = Vector(0,2,-1)
SWEP.weaponAng = Angle(102,85,0)

SWEP.DamageType = DMG_SLASH
SWEP.DamagePrimary = 18
SWEP.DamageSecondary = 1
SWEP.BleedMultiplier = 1.2
SWEP.PainMultiplier = 1.1

SWEP.PenetrationPrimary = 5
SWEP.PenetrationSecondary = 0

SWEP.MaxPenLen = 6

SWEP.PenetrationSizePrimary = 1.5
SWEP.PenetrationSizeSecondary = 0

SWEP.StaminaPrimary = 17
SWEP.StaminaSecondary = 12
SWEP.BlockTier = 2
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
	SWEP.WepSelectIcon = Material("vgui/hud/tfa_ins2_gurkha")
	SWEP.IconOverride = "vgui/hud/tfa_ins2_gurkha"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = false
SWEP.setrh = true


SWEP.AttackHit = "snd_jack_hmcd_knifehit.wav"
SWEP.Attack2Hit = "snd_jack_hmcd_knifehit.wav"
SWEP.AttackHitFlesh = "weapons/knife/knife_hit1.wav"
SWEP.Attack2HitFlesh = "physics/flesh/flesh_impact_hard1.wav"
SWEP.DeploySnd = "physics/metal/metal_grenade_impact_soft2.wav"

SWEP.AttackPos = Vector(0,0,0)



function SWEP:CanPrimaryAttack()
    self.DamageType = DMG_SLASH
    self.AttackHit = "snd_jack_hmcd_knifehit.wav"
    self.Attack2Hit = "snd_jack_hmcd_knifehit.wav"
    self.AttackHitFlesh = "cleaver/hit"..math.random(3)..".mp3"
    return true
end

SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.01 -- Match hatchet throwing timing

SWEP.AttackRads = 65
SWEP.AttackRads2 = 0 -- No radius for throwing attack

SWEP.SwingAng = -15
SWEP.SwingAng2 = 0

SWEP.MultiDmg1 = true
SWEP.MultiDmg2 = false

if SERVER then
    function SWEP:CustomAttack2()
        local ent = ents.Create("ent_throwable")
        ent.WorldModel = "models/weapons/tfa_ins2/w_gurkha.mdl"
        local ply = self:GetOwner()
        ent:SetPos(select(1, hg.eye(ply,60,hg.GetCurrentCharacter(ply))) - ply:GetAimVector() * 2)
        ent:SetAngles(ply:EyeAngles())
        ent:SetOwner(self:GetOwner())
        ent:Spawn()
        ent.localshit = Vector(4,6,0)
        ent.wep = self:GetClass()
        ent.owner = ply
        ent.damage = 25 
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetVelocity(ply:GetAimVector() * ent.MaxSpeed)
            phys:AddAngleVelocity(Vector(0,ent.MaxSpeed,0) )
        end
        ply:EmitSound("weapons/slam/throw.wav",50,math.random(95,105))
        ply:SelectWeapon("weapon_hands_sh")
        self:Remove()
        return true
    end
end

SWEP.MinSensivity = 0.25