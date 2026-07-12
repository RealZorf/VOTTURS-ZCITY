include( "shared.lua" )

DEFINE_BASECLASS( "base_glide" )

function ENT:AllowFirstPersonMuffledSound()
    return false
end

function ENT:AllowWindSound()
    return false, 0
end

local DRIVER_POSE = {
    ["ValveBiped.Bip01_L_UpperArm"] = Angle( -10, 12, -4 ),
    ["ValveBiped.Bip01_R_UpperArm"] = Angle( 10, 12, 4 ),
    ["ValveBiped.Bip01_L_Forearm"] = Angle( -8, -12, 4 ),
    ["ValveBiped.Bip01_R_Forearm"] = Angle( 8, -12, -4 ),
    ["ValveBiped.Bip01_L_Thigh"] = Angle( -5, -5, 0 ),
    ["ValveBiped.Bip01_R_Thigh"] = Angle( 5, -5, 0 ),
    ["ValveBiped.Bip01_L_Calf"] = Angle( -12, 48, 2 ),
    ["ValveBiped.Bip01_R_Calf"] = Angle( 12, 48, -2 )
}

function ENT:GetSeatBoneManipulations( seatIndex )
    if seatIndex ~= 1 then return end

    return DRIVER_POSE
end

function ENT:OnUpdateAnimations()
end

local function GetWheelchairFromEntity( ent )
    if not IsValid( ent ) then return end
    if ent.IsGlideWheelchair then return ent end

    local parent = ent:GetParent()
    if IsValid( parent ) and parent.IsGlideWheelchair then
        return parent
    end
end

local function GetFakePlayerFromRagdoll( ent )
    if not IsValid( ent ) or not hg or not hg.RagdollOwner then return end

    local owner = hg.RagdollOwner( ent )

    if not IsValid( owner ) or not owner:IsPlayer() or not owner:Alive() then return end
    if owner == LocalPlayer() then return end

    return owner
end

local function FindNearestEmptyWheelchair( origin )
    local nearest
    local nearestDistance = 75 * 75

    for _, ent in ipairs( ents.FindInSphere( origin, 75 ) ) do
        local wheelchair = GetWheelchairFromEntity( ent )

        if IsValid( wheelchair ) and not IsValid( wheelchair:GetDriver() ) then
            local distance = origin:DistToSqr( wheelchair:WorldSpaceCenter() )

            if distance < nearestDistance then
                nearest = wheelchair
                nearestDistance = distance
            end
        end
    end

    return nearest
end


hook.Add( "radialOptions", "GlideWheelchair.SeatFakeTarget", function()
    if not hg or not hg.radialOptions or not hg.eyeTrace then return end

    local helper = LocalPlayer()

    if not IsValid( helper ) or not helper:Alive() or helper:InVehicle() or IsValid( helper.FakeRagdoll ) then return end
    if helper.organism and helper.organism.canmove == false then return end

    local tr = hg.eyeTrace( helper, 140 )
    local lookedAt = tr and tr.Entity
    local ragdoll = lookedAt
    local target = GetFakePlayerFromRagdoll( ragdoll )
    local wheelchair

    if IsValid( target ) then
        wheelchair = FindNearestEmptyWheelchair( ragdoll:WorldSpaceCenter() )
    else
        wheelchair = GetWheelchairFromEntity( lookedAt )

        if not IsValid( wheelchair ) or IsValid( wheelchair:GetDriver() ) then return end

        local nearestDistance = 75 * 75

        for _, ent in ipairs( ents.FindInSphere( wheelchair:WorldSpaceCenter(), 75 ) ) do
            local owner = GetFakePlayerFromRagdoll( ent )

            if IsValid( owner ) then
                local distance = wheelchair:WorldSpaceCenter():DistToSqr( ent:WorldSpaceCenter() )

                if distance < nearestDistance then
                    ragdoll = ent
                    target = owner
                    nearestDistance = distance
                end
            end
        end
    end

    if not IsValid( target ) or not IsValid( ragdoll ) or not IsValid( wheelchair ) then return end

    local name = target.GetPlayerName and target:GetPlayerName() or ""
    name = name ~= "" and name or target:Nick()

    hg.radialOptions[#hg.radialOptions + 1] = {
        function()
            if not IsValid( ragdoll ) or not IsValid( wheelchair ) then return end

            net.Start( "GlideWheelchair.SeatFakeTarget" )
            net.WriteEntity( ragdoll )
            net.WriteEntity( wheelchair )
            net.SendToServer()
        end,
        "Put " .. name .. " in wheelchair"
    }
end )
