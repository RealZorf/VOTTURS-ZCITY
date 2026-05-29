local CLASS = player.RegClass("homelander")

CLASS.NoFreeze = true
CLASS.CanUseDefaultPhrase = true
CLASS.CanEmitRNDSound = true
CLASS.CanUseGestures = true

local HOMELANDER_MODEL = "models/bread/cod/characters/the_boys/homelander.mdl"
local HOMELANDER_WEAPON = "weapon_homelander"

function CLASS.Off(self)
    if CLIENT then return end

    if self.organism then
        self.organism.godmode = false
        if self.organism.HomelanderOldStaminaMax then
            self.organism.stamina.max = self.organism.HomelanderOldStaminaMax
            self.organism.HomelanderOldStaminaMax = nil
        end
        self.organism.HomelanderShieldedFromOrganism = nil
    end

    self:SetNWBool("IsHomelander", false)
end

function CLASS.On(self, data)
    if CLIENT then return end

    if IsValid(self.FakeRagdoll) then
        hg.FakeUp(self, nil, nil, true)
    end

    ApplyAppearance(self, nil, nil, nil, true)
    local Appearance = self.CurAppearance or hg.Appearance.GetRandomAppearance()
    Appearance.AAttachments = ""
    Appearance.AColthes = ""
    self:SetNetVar("Accessories", "")
    self.CurAppearance = Appearance

    self:SetModel(HOMELANDER_MODEL)
    self:SetSubMaterial()
    self:SetPlayerColor(Color(255, 215, 0):ToVector())

    self:SetNWBool("IsHomelander", true)

    if self.organism then
        self.organism.godmode = true
        self.organism.recoilmul = 0.25
        self.organism.HomelanderOldStaminaMax = self.organism.stamina.max
        self.organism.stamina.max = 500
        self.organism.stamina.cur = 500
        self.organism.HomelanderShieldedFromOrganism = true
    end

    self:SetMaxHealth(10000)
    self:SetHealth(10000)
    self:SetArmor(500)

    if not (data and data.bNoEquipment) then
        self:StripWeapons()
        self:StripAmmo()

        self:Give("weapon_hands_sh")
        local wep = self:Give(HOMELANDER_WEAPON)
        if IsValid(wep) then
            self:SelectWeapon(HOMELANDER_WEAPON)
        end
    end

    if zb and zb.GiveRole then
        zb.GiveRole(self, "Homelander", Color(255, 215, 0))
    end
end

function CLASS.Guilt(self, Victim)
    if CLIENT then return end
    return 0
end

if SERVER then
    hook.Add("EntityTakeDamage", "HomelanderInvincible", function(ent, dmginfo)
        if not IsValid(ent) or not ent:IsPlayer() then return end
        if ent.PlayerClassName ~= "homelander" then return end

        dmginfo:SetDamage(0)
        return true
    end)

    hook.Add("PlayerShouldTakeDamage", "HomelanderShield", function(ply, attacker)
        if not IsValid(ply) then return end
        if ply.PlayerClassName ~= "homelander" then return end
        return false
    end)
end

return CLASS
