local handleRadiusSqr = 2 ^ 2

hook.Add("EntityTakeDamage", "lockBreak", function(target, dmginfo)
    if not IsValid(target) or target:GetClass() ~= "prop_door_rotating" then return end
    if not SERVER then return end

    if not dmginfo:IsBulletDamage() and not dmginfo:IsDamageType(DMG_BUCKSHOT) then return end
    local hitPos = dmginfo:GetDamagePosition()
    local lockPos

    local attID = target:LookupAttachment("handle")
    if attID > 0 then
        local att = target:GetAttachment(attID)
        if att then lockPos = att.Pos end
    end

    if not lockPos then
        local mins, maxs = target:OBBMins(), target:OBBMaxs()
        local isXWide = (maxs.x - mins.x) > (maxs.y - mins.y)
        local lp = Vector()

        if isXWide then
            lp.x = (math.abs(maxs.x) > math.abs(mins.x)) and (maxs.x - 5) or (mins.x + 5)
            lp.y = (maxs.y + mins.y) / 2
        else
            lp.y = (math.abs(maxs.y) > math.abs(mins.y)) and (maxs.y - 5) or (mins.y + 5)
            lp.x = (maxs.x + mins.x) / 2
        end
        lp.z = mins.z + ((maxs.z - mins.z) * 0.45)
        lockPos = target:LocalToWorld(lp)
    end

    if lockPos and hitPos:DistToSqr(lockPos) <= handleRadiusSqr then
        target:Fire("Unlock")
        local effect = EffectData()
        effect:SetOrigin(hitPos)
        effect:SetNormal(dmginfo:GetDamageForce():GetNormalized())
        effect:SetMagnitude(2)
        effect:SetScale(1)
        util.Effect("MetalSpark", effect)
    end
end)