if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Kitchen Knife"
SWEP.Instructions = "A Kitchen knife that is meant to be used to cut vegetables and ingredients. R+LMB to change mode to slash/stab. RMB to interact with environment."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/tfa_nmrih/w_me_kitknife.mdl"
SWEP.WorldModelReal = "models/zac/c_kitchenknife.mdl"
SWEP.WorldModelExchange = "models/weapons/mw22/att_p33_me_tac_knife03_v0.mdl"

SWEP.SuicidePos = Vector(10, -21, -7)
SWEP.SuicideAng = Angle(-40, 100, 0)
SWEP.SuicideCutVec = Vector(1, -5, 4)
SWEP.SuicideCutAng = Angle(10, 0, 0)
SWEP.SuicideTime = 0.5
SWEP.CanSuicide = true
SWEP.SuicidePunchAng = Angle(-5, -15, 0)

SWEP.basebone = 39


SWEP.weaponPos = Vector(0,0,-3)
SWEP.weaponAng = Angle(0,180,0)

SWEP.BreakBoneMul = 0.35

SWEP.AnimList = {
    ["idle"] = "idle",
    ["deploy"] = "draw",
    ["attack"] = "attack_stab",
    ["attack2"] = "attack",
}

if CLIENT then
	SWEP.WepSelectIcon = Material("entities/arc9_cod2019_tac_knife03_v0.png")
	SWEP.IconOverride = "entities/arc9_cod2019_tac_knife03_v0.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = false
SWEP.setrh = true

SWEP.HoldType = "melee"

SWEP.DeploySnd = ""

SWEP.AttackPos = Vector(0,0,0)
SWEP.DamageType = DMG_SLASH
SWEP.DamagePrimary = 13
SWEP.DamageSecondary = 8

SWEP.PenetrationPrimary = 3.5
SWEP.PenetrationSecondary = 3
SWEP.BleedMultiplier = 1.3

SWEP.MaxPenLen = 3

SWEP.PainMultiplier = 1

SWEP.PenetrationSizePrimary = 1.5
SWEP.PenetrationSizeSecondary = 1

SWEP.StaminaPrimary = 16
SWEP.StaminaSecondary = 10

SWEP.AttackLen1 = 42
SWEP.AttackLen2 = 35

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

SWEP.AttackRads = 80
SWEP.AttackRads2 = 55
SWEP.BlockTier = 2

SWEP.SwingAng = -90
SWEP.SwingAng2 = 0

SWEP.MultiDmg1 = false
SWEP.MultiDmg2 = true

SWEP.BlockHoldPos = Vector(-9.5, 15, -0.95)
SWEP.BlockHoldAng = Angle(-5, 0, -45)
SWEP.BlockSound = "physics/metal/metal_solid_impact_bullet3.wav"