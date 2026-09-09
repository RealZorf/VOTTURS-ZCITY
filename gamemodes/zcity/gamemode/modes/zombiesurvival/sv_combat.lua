local MODE = MODE

local function ZombieOwner(ent)
    if not IsValid(ent) then return end
    local ply = ent:IsPlayer() and ent or hg.RagdollOwner(ent)
    if not IsValid(ply) then ply = ent:GetOwner() end
    if not IsValid(ply) or not ply:IsPlayer() then
        ply = ent:GetPhysicsAttacker(5)
    end
    if IsValid(ply) and ply:IsPlayer() and ply.ZSIsZombie then return ply end
end

function MODE:BlockZombieFriendlyDamage(ent, damage)
    if zb.ROUND_STATE ~= 1 then return false end
    local victim = ent:IsPlayer() and ent or hg.RagdollOwner(ent)
    if not IsValid(victim) or not victim.ZSIsZombie then return false end
    local attacker = ZombieOwner(damage:GetAttacker()) or ZombieOwner(damage:GetInflictor())
    if not IsValid(attacker) or attacker == victim then return false end
    damage:SetDamage(0)
    damage:SetDamageForce(vector_origin)
    return true
end

function MODE:EntityTakeDamage(ent, damage)
    if self:BlockZombieFriendlyDamage(ent, damage) then return true end
    if zb.ROUND_STATE ~= 1 or damage:GetDamage() <= 0 then return end
    local attacker = damage:GetAttacker()
    if not IsValid(attacker) or not attacker:IsPlayer() or not attacker.ZSIsZombie then return end
    if not damage:IsDamageType(DMG_SLASH) and not damage:IsDamageType(DMG_CLUB) then return end
    local class = ent:GetClass()
    if class ~= "prop_physics" and class ~= "prop_physics_multiplayer" then return end
    if attacker:GetShootPos():DistToSqr(ent:NearestPoint(attacker:GetShootPos())) > 150 ^ 2 then return end
    if (ent.ZSNextZombieShove or 0) > CurTime() then return end
    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) or not phys:IsMotionEnabled() then return end
    ent.ZSNextZombieShove = CurTime() + 0.2
    local direction = attacker:GetAimVector()
    direction = Vector(direction.x, direction.y, math.max(direction.z, 0.3)):GetNormalized()
    local speed = attacker.ZSIsPoisonZombie and 650 or 500
    phys:Wake()
    phys:ApplyForceCenter(direction * math.min(phys:GetMass(), 1000) * speed)
    ent:SetPhysicsAttacker(attacker, 5)
end
