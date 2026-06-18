if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Scalpel"
SWEP.Instructions = "A scalpel thats used in surgeries. R+LMB to change mode to slash/stab. RMB to interact with environment."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/w_knife_swch.mdl"
SWEP.WorldModelReal = "models/weapons/salat/reanim/c_s&wch0014.mdl"
SWEP.WorldModelExchange = "models/surgeon simulator 2013/scalpel_1.mdl"


SWEP.SuicidePos = Vector(-6, 2, -9)
SWEP.SuicideAng = Angle(-30, 0, 0)
SWEP.SuicideCutVec = Vector(-1, -5, 1)
SWEP.SuicideCutAng = Angle(10, 0, 0)
SWEP.SuicideTime = 0.5
SWEP.CanSuicide = true
SWEP.SuicideNoLH = true
SWEP.SuicidePunchAng = Angle(5, -15, 0)

SWEP.basebone = 39
SWEP.weaponPos = Vector(-0.5,1.3,0)
SWEP.weaponAng = Angle(0,280,180)

SWEP.HoldPos = Vector(-4,0,-2)

SWEP.BreakBoneMul = 0.20

SWEP.AnimList = {
    ["idle"] = "idle",
    ["deploy"] = "draw",
    ["attack"] = "stab",
    ["attack2"] = "midslash1",
}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/scapel.png")
	SWEP.IconOverride = "vgui/scapel.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.setlh = true
SWEP.setrh = true

SWEP.DeploySnd = ""

SWEP.AttackPos = Vector(0,0,0)
SWEP.DamageType = DMG_SLASH
SWEP.DamagePrimary = 21
SWEP.DamageSecondary = 12

SWEP.PenetrationPrimary = 5
SWEP.PenetrationSecondary = 3
SWEP.BleedMultiplier = 2

SWEP.MaxPenLen = 3

SWEP.PainMultiplier = 0.6

SWEP.PenetrationSizePrimary = 1.5
SWEP.PenetrationSizeSecondary = 1

SWEP.StaminaPrimary = 10
SWEP.StaminaSecondary = 11

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

SWEP.SwingAng = -90
SWEP.SwingAng2 = 0

SWEP.MultiDmg1 = false
SWEP.MultiDmg2 = true