AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("flashbang_impact")

function ENT:PhysicsCollide(phys, deltaTime)
    if phys.Speed > 20 and not self.Exploded then self:Explode() end
end

local burnDamageRadius = 20
local explosionDamageRadius = 30
local disorientationRadius = 300

function ENT:Explode()
    if self:PoopBomb() then
        self:EmitSound("weapons/p99/slideback.wav", 75)
        self.Exploded = true
        return
    end

    local SelfPos = self:GetPos()
    local ownerHomelander = IsValid(self.Owner) and self.Owner:IsPlayer() and self.Owner.PlayerClassName == "homelander"
    local durationMul = ownerHomelander and 2 or 1

    local effectdata = EffectData()
    effectdata:SetOrigin(SelfPos)
    effectdata:SetScale(0.5)
    effectdata:SetNormal(-self:GetAngles():Forward())
    util.Effect("eff_jack_genericboom", effectdata)
    hg.EmitAISound(SelfPos, 512, 16, 1)

    timer.Simple(0.05, function()
        if IsValid(self) then
            self:EmitSound(table.Random(self.SoundBass), 150, 70, 0.95, CHAN_AUTO)
        end
    end)
    timer.Simple(0.1, function()
        if IsValid(self) then
            self:EmitSound(table.Random(self.SoundBass), 155, 60, 0.9, CHAN_BODY)
        end
    end)

    EmitSound(self.SoundMain, SelfPos, self:EntIndex() + 100, CHAN_STATIC, 1, 70, nil, 100)
    EmitSound(self.SoundMain, SelfPos, self:EntIndex() + 101, CHAN_STATIC, 1, 70, nil, 100)
    EmitSound(self.SoundMain, SelfPos, self:EntIndex() + 102, CHAN_STATIC, 1, 70, nil, 100)
    EmitSound(self.SoundFar, SelfPos, self:EntIndex() + 103, CHAN_STATIC, 1, 140, nil, 100)
    EmitSound("snd_jack_fireworkpop5.wav", SelfPos, self:EntIndex() + 200, CHAN_VOICE, 1, 150, nil, math.random(100, 110))

    for _, ply in ipairs(ents.FindInSphere(SelfPos, 700)) do
        if not ply:IsPlayer() or not ply:Alive() then continue end

        if hg.isVisible(ply:GetShootPos(), SelfPos, {ply, self}, MASK_VISIBLE) then
            net.Start("flashbang_impact")
                net.WriteVector(SelfPos)
                net.WriteFloat(durationMul)
            net.Send(ply)
        end

        local tr = hg.ExplosionTrace(SelfPos, ply:GetPos(), {self, ply})
        if tr.Hit then continue end

        local distance = ply:GetPos():Distance(SelfPos)
        local org = ply.organism

        if distance <= burnDamageRadius then
            local dmginfo = DamageInfo()
            dmginfo:SetDamage(50)
            dmginfo:SetDamageType(DMG_BURN)
            dmginfo:SetAttacker(IsValid(self.Owner) and self.Owner or self)
            ply:TakeDamageInfo(dmginfo)
        end

        if distance <= explosionDamageRadius then
            local dmginfo = DamageInfo()
            dmginfo:SetDamage(75)
            dmginfo:SetDamageType(DMG_BLAST)
            dmginfo:SetAttacker(IsValid(self.Owner) and self.Owner or self)
            ply:TakeDamageInfo(dmginfo)
        end

        if distance <= disorientationRadius then
            if org then
                hg.ExplosionDisorientation(org.owner, 5 * durationMul, 6 * durationMul)
                hg.RunZManipAnim(org.owner, "shieldexplosion")
            end
        end
    end

    self.Exploded = true
    self:Remove()
end
