AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

DEFINE_BASECLASS( "base_glide" )

util.AddNetworkString( "GlideWheelchair.SeatFakeTarget" )

local Clamp = math.Clamp
local Abs = math.abs
local BitBand = bit.band
local ExpDecay = Glide.ExpDecay
local TraceLine = util.TraceLine
local ZERO_ANGLE = Angle( 0, 0, 0 )

local GROUND_OFFSET = Vector( 0, 0, 3 )
local GROUND_DEPTH = Vector( 0, 0, 10 )
local ROLLOVER_UP = Vector( 0, 0, 1 )
local ROLLOVER_DOT_LIMIT = 0.65
local ROLLOVER_ANGLE_LIMIT = 50
local ROLLOVER_CONFIRM_TIME = 0.12
local PUSH_HANDLE_REACH = 30
local PUSH_WALK_SPEED = 115
local PUSH_SPRINT_SPEED = 145
local PUSH_REVERSE_SPEED = 115
local DRIVE_REVERSE_SPEED = 62

local traceData = {
    mask = MASK_SOLID
}

function ENT:OnPostInitialize()
    self.wheelchairBroken = false
    self.nextPushSound = 0
    self.driveMultiplier = 1
    self.isGrounded = false
    self:SetChairSteering( 0 )

    local phys = self:GetPhysicsObject()

    if IsValid( phys ) then
        phys:SetMaterial( "gmod_silent" )

        if phys.SetMassCenter then
            phys:SetMassCenter( Vector( -3, 0, 1.5 ) )
        end
    end
end

function ENT:CreateFeatures()
    self:CreateSeat( Vector( -12, 0, 12 ), Angle( 0, 270, 0 ), Vector( 0, 34, 8 ), true )
end

function ENT:GetWheelchairSteerInput()
    local left = self:GetInputBool( 1, "steer_left" )
    local right = self:GetInputBool( 1, "steer_right" )

    if left == right then return 0 end

    return left and -1 or 1
end

function ENT:GetWheelchairDriveInput( driver )
    if IsValid( driver ) then
        local forwardDown = driver:KeyDown( IN_FORWARD )
        local reverseDown = driver:KeyDown( IN_BACK )

        if forwardDown ~= reverseDown then
            return forwardDown and 1 or -1
        end
    end

    return self:GetInputFloat( 1, "accelerate" ) - self:GetInputFloat( 1, "brake" )
end

function ENT:GetWheelchairPushInput( pusher )
    if IsValid( pusher ) then
        local forward = pusher:KeyDown( IN_FORWARD )
        local reverse = pusher:KeyDown( IN_BACK )

        if forward ~= reverse then
            return forward and 1 or -1
        end
    end

    return self.wheelchairPushInput or 0
end

function ENT:ApplyWheelchairReverse( phys, input, pusher )
    if input >= -0.05 or not self.isGrounded or not IsValid( phys ) then return end

    local forward = self:GetForward()
    forward[3] = 0

    if forward:LengthSqr() < 0.001 then return end
    forward:Normalize()

    local driveMultiplier = Clamp( self.driveMultiplier or 0, 0, 1.12 )
    local currentSpeed = phys:GetVelocity():Dot( forward )
    local targetSpeed
    local accelerationLimit

    if IsValid( pusher ) then
        local expectedPusherPosition = self:GetWheelchairPusherPosition()
        local handleError = pusher:GetPos() - expectedPusherPosition
        handleError[3] = 0

        local pusherSpeed = pusher:GetVelocity():Dot( forward )
        local distanceCorrection = handleError:Dot( forward ) * 3.5

        targetSpeed = Clamp( pusherSpeed + distanceCorrection, -PUSH_REVERSE_SPEED, 24 ) * driveMultiplier
        accelerationLimit = 240
    else
        targetSpeed = -DRIVE_REVERSE_SPEED * driveMultiplier
        accelerationLimit = 105
    end

    local acceleration = Clamp( ( targetSpeed - currentSpeed ) * 4.5, -accelerationLimit, accelerationLimit )

    phys:ApplyForceCenter( forward * acceleration * phys:GetMass() )
    phys:Wake()
end

function ENT:GetPropulsionMultiplier( driver, dt, isPushing, forceSprint )
    if not IsValid( driver ) or not driver:Alive() then return 0 end

    local org = driver.organism
    if not org then return 1 end
    if org.canmove == false then return 0 end

    local function ArmStrength( side )
        if org[side .. "amputated"] then return 0 end

        local strength = Clamp( 1 - ( tonumber( org[side] ) or 0 ) / 1.3, 0, 1 )

        if org[side .. "dislocation"] then
            strength = strength * 0.4
        end

        return strength
    end

    local armMultiplier = ( ArmStrength( "larm" ) + ArmStrength( "rarm" ) ) * 0.5
    local perfusionMultiplier = Clamp( tonumber( org.perfusionMoveMul ) or 1, 0.2, 1 )
    local staminaMultiplier = 1
    local stamina = org.stamina

    if type( stamina ) == "table" and tonumber( stamina[1] ) then
        local maximum = math.max( tonumber( stamina.max ) or tonumber( stamina.range ) or 100, 1 )
        local fraction = Clamp( stamina[1] / maximum, 0, 1 )

        staminaMultiplier = 0.25 + fraction * 0.75

        if isPushing then
            local sprintRequested = forceSprint

            if sprintRequested == nil then
                sprintRequested = self:GetInputBool( 1, "throttle_modifier" )
            end

            local sprinting = sprintRequested and fraction > 0.15
            local exertion = sprinting and 1.35 or 0.9

            stamina.subadd = ( tonumber( stamina.subadd ) or 0 ) + dt * exertion

            if sprinting then
                staminaMultiplier = staminaMultiplier * 1.12
            end
        end
    end

    return Clamp( armMultiplier * perfusionMultiplier * staminaMultiplier, 0, 1.12 )
end

function ENT:IsValidWheelchairPusher( ply, requireBehind )
    if not IsValid( ply ) or not ply:IsPlayer() or not ply:Alive() then return false end
    if ply:InVehicle() or IsValid( ply.FakeRagdoll ) then return false end
    if not ply.GetNetVar then return false end
    if ply:GetNetVar( "carryent" ) ~= self and ply:GetNetVar( "carryent2" ) ~= self then return false end
    if ply.organism and ply.organism.canmove == false then return false end

    local offset = ply:GetPos() - self:GetPos()
    offset[3] = 0

    if offset:LengthSqr() > 125 * 125 then return false end
    if offset:LengthSqr() < 1 then return true end

    offset:Normalize()

    local rearDot = offset:Dot( self:GetForward() )
    if rearDot >= ( requireBehind and 0.2 or 0.65 ) then return false end

    local uprightDot = self:GetUp():Dot( ROLLOVER_UP )
    if not requireBehind then
        return uprightDot >= 0.88
    end

    if uprightDot < 0.94 then return false end

    local primaryCarry = ply:GetNetVar( "carryent" ) == self
    local carryPosition = ply:GetNetVar( primaryCarry and "carrypos" or "carrypos2" )
    if not isvector( carryPosition ) then return false end

    local grabOffset = self:LocalToWorld( carryPosition ) - self:GetPos()
    if grabOffset:Dot( self:GetForward() ) > -4 then return false end
    if grabOffset[3] < 8 then return false end

    return true
end

function ENT:StopWheelchairPush()
    local pusher = self.wheelchairPusher
    local carrySlot = self.wheelchairPushCarrySlot

    self.wheelchairPusher = nil
    self.wheelchairPushCarrySlot = nil
    self.wheelchairPushHandleLocal = nil
    self.wheelchairPushInput = 0
    self.wheelchairPushSteer = 0
    self.wheelchairPushSprint = false

    if IsValid( pusher ) and pusher.WheelchairPushing == self then
        pusher.WheelchairPushing = nil

        if hg and hg.SafeCollisionRulesChanged then
            hg.SafeCollisionRulesChanged( pusher )
        else
            pusher:CollisionRulesChanged()
        end
    end

    if hg and hg.SafeCollisionRulesChanged then
        hg.SafeCollisionRulesChanged( self )
    else
        self:CollisionRulesChanged()
    end

    if not IsValid( self:GetDriver() ) then
        self:TurnOff()
        self.driveMultiplier = 0
    end

    if not IsValid( pusher ) or not pusher.GetNetVar then return end

    if carrySlot == 2 and pusher:GetNetVar( "carryent2" ) == self and hg and hg.SetCarryEnt2 then
        hg.SetCarryEnt2( pusher )
    elseif carrySlot == 1 and pusher:GetNetVar( "carryent" ) == self then
        local weapon = pusher:GetActiveWeapon()

        if IsValid( weapon ) and weapon.SetCarrying then
            weapon:SetCarrying()
        else
            pusher:SetNetVar( "carryent", nil )
            pusher:SetNetVar( "carrybone", nil )
            pusher:SetNetVar( "carrymass", 0 )
            pusher:SetNetVar( "carrypos", nil )
        end
    end
end

function ENT:ClaimWheelchairPusher( ply )
    if not self:IsValidWheelchairPusher( ply, true ) then return false end

    self.wheelchairPusher = ply
    ply.WheelchairPushing = self
    self.wheelchairPushStarted = CurTime()
    self:SetEngineState( 2 )

    if hg and hg.SafeSetCustomCollisionCheck then
        hg.SafeSetCustomCollisionCheck( self, true )
        hg.SafeSetCustomCollisionCheck( ply, true )
        hg.SafeCollisionRulesChanged( self )
        hg.SafeCollisionRulesChanged( ply )
    else
        self:SetCustomCollisionCheck( true )
        ply:SetCustomCollisionCheck( true )
        self:CollisionRulesChanged()
        ply:CollisionRulesChanged()
    end

    local primaryCarry = ply:GetNetVar( "carryent" ) == self
    self.wheelchairPushCarrySlot = primaryCarry and 1 or 2
    self.wheelchairPushHandleLocal = ply:GetNetVar( primaryCarry and "carrypos" or "carrypos2" )

    if primaryCarry then
        local weapon = ply:GetActiveWeapon()

        if IsValid( weapon ) and weapon.GetCarrying and weapon:GetCarrying() == self then
            weapon.CarryEnt = nil
            weapon.CarryBone = nil
            weapon.CarryPos = nil
            weapon.CarryDist = nil
        end
    end

    if heldents then
        local held = heldents[self:EntIndex()]

        if held and held[1] == self and held[2] == ply then
            heldents[self:EntIndex()] = nil
        end
    end

    return true
end

function ENT:GetWheelchairPusherPosition()
    local forward = self:GetForward()
    forward[3] = 0

    if forward:LengthSqr() < 0.001 then return self:GetPos() end
    forward:Normalize()

    local handlePosition = isvector( self.wheelchairPushHandleLocal )
        and self:LocalToWorld( self.wheelchairPushHandleLocal )
        or self:GetPos()

    return handlePosition - forward * PUSH_HANDLE_REACH
end

function ENT:UpdateWheelchairPusher()
    local pusher = self.wheelchairPusher

    if pusher ~= nil and not IsValid( pusher ) then
        self:StopWheelchairPush()
        pusher = nil
    end

    if IsValid( pusher ) then
        local activeWeapon = pusher:GetActiveWeapon()
        local usingHands = IsValid( activeWeapon ) and activeWeapon.GetCarrying and activeWeapon.SetCarrying
        local released = CurTime() > ( self.wheelchairPushStarted or 0 ) + 0.3
            and ( pusher:KeyPressed( IN_RELOAD ) or not usingHands )

        if self.wheelchairBroken or released or not self:IsValidWheelchairPusher( pusher, false ) then
            self:StopWheelchairPush()
            return
        end

        if self:GetEngineState() ~= 2 then
            self:SetEngineState( 2 )
        end

        return pusher
    end

    if CurTime() < ( self.nextWheelchairPusherScan or 0 ) then return end
    self.nextWheelchairPusherScan = CurTime() + 0.12

    for _, ent in ipairs( ents.FindInSphere( self:GetPos(), 125 ) ) do
        if ent:IsPlayer() and self:ClaimWheelchairPusher( ent ) then
            return ent
        end
    end
end

function ENT:UpdateGroundTraceFilter( driver, pusher )
    local filter = self.groundTraceFilter or {}
    table.Empty( filter )

    for _, ent in ipairs( self.selfTraceFilter ) do
        filter[#filter + 1] = ent
    end

    if IsValid( driver ) then
        filter[#filter + 1] = driver

        if IsValid( driver.FakeRagdoll ) then
            filter[#filter + 1] = driver.FakeRagdoll
        end
    end

    if IsValid( pusher ) then
        filter[#filter + 1] = pusher
    end

    if self.rags then
        for _, ragdoll in pairs( self.rags ) do
            if IsValid( ragdoll ) then
                filter[#filter + 1] = ragdoll
            end
        end
    end

    self.groundTraceFilter = filter
end

function ENT:RestoreFakeOccupantMass()
    local ragdoll = self.wheelchairFakeRagdoll
    local masses = self.wheelchairFakeMasses
    local materials = self.wheelchairFakeMaterials

    if IsValid( ragdoll ) and masses then
        for physIndex, mass in pairs( masses ) do
            local phys = ragdoll:GetPhysicsObjectNum( physIndex )

            if IsValid( phys ) then
                phys:SetMass( mass )
                phys:SetMaterial( materials and materials[physIndex] or "flesh" )
                phys:Wake()
            end
        end
    end

    local chairPhys = self:GetPhysicsObject()
    if IsValid( chairPhys ) and self.wheelchairOriginalChassisMass then
        chairPhys:SetMass( self.wheelchairOriginalChassisMass )
        chairPhys:Wake()
    end

    self.wheelchairFakeRagdoll = nil
    self.wheelchairFakeMasses = nil
    self.wheelchairFakeMaterials = nil
    self.wheelchairOriginalChassisMass = nil
end

function ENT:SetFakeOccupantRagdoll( ragdoll )
    if ragdoll == self.wheelchairFakeRagdoll then return end

    self:RestoreFakeOccupantMass()
    if not IsValid( ragdoll ) then return end

    local masses = {}
    local materials = {}

    for physIndex = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local phys = ragdoll:GetPhysicsObjectNum( physIndex )

        if IsValid( phys ) then
            masses[physIndex] = phys:GetMass()
            materials[physIndex] = phys:GetMaterial()
            phys:SetMass( math.min( masses[physIndex], 0.6 ) )
            phys:SetMaterial( "gmod_silent" )
        end
    end

    local chairPhys = self:GetPhysicsObject()
    if IsValid( chairPhys ) then
        self.wheelchairOriginalChassisMass = chairPhys:GetMass()
        chairPhys:SetMass( math.max( self.wheelchairOriginalChassisMass, 260 ) )
        chairPhys:Wake()
    end

    self.wheelchairFakeRagdoll = ragdoll
    self.wheelchairFakeMasses = masses
    self.wheelchairFakeMaterials = materials
end

local function DetachRolloverRagdoll( seat, ragdoll )
    if not IsValid( ragdoll ) then return end

    ragdoll.removingwelds = true

    if ragdoll.welds then
        for _, weld in pairs( ragdoll.welds ) do
            if IsValid( weld ) then
                weld:Remove()
            end
        end
    end

    ragdoll.welds = nil
    ragdoll:SetParent()
    ragdoll.removingwelds = nil

    if IsValid( seat ) and seat.rags then
        table.RemoveByValue( seat.rags, ragdoll )
    end
end

local function RestoreRolloverFakeState( driver, ragdoll )
    if not IsValid( driver ) or not driver:Alive() or not IsValid( ragdoll ) then return false end

    driver.switchingseat = nil
    driver.FakeRagdoll = ragdoll
    driver:SetNWEntity( "FakeRagdoll", ragdoll )
    driver:SetMoveType( MOVETYPE_NOCLIP )
    driver:SetNoDraw( false )
    driver:SetRenderMode( RENDERMODE_NONE )
    driver:DrawShadow( false )

    ragdoll:SetNWEntity( "ply", driver )

    if hg then
        hg.ragdollFake = hg.ragdollFake or {}
        hg.ragdollFake[driver] = ragdoll

        if hg.ApplySetCollisionGroupNow then
            hg.ApplySetCollisionGroupNow( driver, COLLISION_GROUP_IN_VEHICLE )
            hg.ApplySetCollisionGroupNow( ragdoll, COLLISION_GROUP_WEAPON )
        else
            driver:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
            ragdoll:SetCollisionGroup( COLLISION_GROUP_WEAPON )
        end
    end

    return true
end

local function RecoverFailedRolloverEjection( driver )
    if not IsValid( driver ) or not driver:Alive() or driver:InVehicle() then return end
    if IsValid( driver.FakeRagdoll ) then return end

    driver.switchingseat = nil
    driver.WheelchairRolloverEjecting = nil
    timer.Remove( "faking_up" .. driver:EntIndex() )
    driver:SetMoveType( MOVETYPE_WALK )
    driver:SetNoDraw( false )
    driver:SetRenderMode( RENDERMODE_NORMAL )
    driver:DrawShadow( true )

    if hg and hg.ApplySetCollisionGroupNow then
        hg.ApplySetCollisionGroupNow( driver, COLLISION_GROUP_PLAYER )
    else
        driver:SetCollisionGroup( COLLISION_GROUP_PLAYER )
    end
end

function ENT:EjectUpsideDown( driver )
    if self.rolloverEjecting or not IsValid( driver ) or not driver:Alive() then return end

    local chairPhys = self:GetPhysicsObject()
    if not IsValid( chairPhys ) then return end

    local momentum = chairPhys:GetVelocity()
    local angularMomentum = chairPhys:GetAngleVelocity()
    local seat = driver:GetVehicle()
    local ragdoll = driver.FakeRagdoll

    self.rolloverEjecting = true
    self:RestoreFakeOccupantMass()

    driver.WheelchairRolloverEjecting = true
    driver.switchingseat = nil

    DetachRolloverRagdoll( seat, ragdoll )
    if IsValid( ragdoll ) then
        driver.FakeRagdoll = nil
    end

    driver:ExitVehicle()

    if IsValid( ragdoll ) then
        RestoreRolloverFakeState( driver, ragdoll )
    end

    timer.Simple( 0, function()
        if not IsValid( driver ) then return end

        if driver:InVehicle() then
            driver.WheelchairRolloverEjecting = nil
            driver.switchingseat = nil

            if IsValid( self ) then
                self.rolloverEjecting = false
                self.upsideDownSince = CurTime()
            end

            return
        end

        driver.WheelchairRolloverEjecting = nil
        driver.switchingseat = nil
        if not driver:Alive() then return end

        if not RestoreRolloverFakeState( driver, ragdoll ) then
            RecoverFailedRolloverEjection( driver )
            return
        end

        for physIndex = 0, ragdoll:GetPhysicsObjectCount() - 1 do
            local phys = ragdoll:GetPhysicsObjectNum( physIndex )

            if IsValid( phys ) then
                phys:SetVelocity( momentum )
                phys:AddAngleVelocity( angularMomentum * 0.35 )
                phys:Wake()
            end
        end

        timer.Create( "GlideWheelchair.RolloverRecovery." .. driver:EntIndex(), 0.25, 1, function()
            RecoverFailedRolloverEjection( driver )
        end )
    end )
end

function ENT:UpdateRolloverEjection( driver )
    if not IsValid( driver ) or self.rolloverEjecting then
        self.upsideDownSince = nil
        return false
    end

    local angles = self:GetAngles()
    local pitch = Abs( math.NormalizeAngle( angles[1] ) )
    local roll = Abs( math.NormalizeAngle( angles[3] ) )
    local tipped = self:GetUp():Dot( ROLLOVER_UP ) <= ROLLOVER_DOT_LIMIT
        or pitch >= ROLLOVER_ANGLE_LIMIT
        or roll >= ROLLOVER_ANGLE_LIMIT

    if not tipped then
        self.upsideDownSince = nil
        return false
    end

    self.upsideDownSince = self.upsideDownSince or CurTime()
    if CurTime() - self.upsideDownSince < ROLLOVER_CONFIRM_TIME then return false end

    self:EjectUpsideDown( driver )
    return true
end

function ENT:OnPostThink( dt )
    local driver = self:GetDriver()
    local pusher = self:UpdateWheelchairPusher()

    self:UpdateGroundTraceFilter( driver, pusher )
    self:SetFakeOccupantRagdoll( IsValid( driver ) and driver.FakeRagdoll or nil )

    if self:UpdateRolloverEjection( driver ) then return end

    local controller = IsValid( pusher ) and pusher or driver
    local input = IsValid( pusher ) and self:GetWheelchairPushInput( pusher )
        or self:GetWheelchairDriveInput( driver )
    local steerTarget = IsValid( pusher ) and ( self.wheelchairPushSteer or 0 ) or self:GetWheelchairSteerInput()
    local isPushing = Abs( input ) > 0.05 or Abs( steerTarget ) > 0.1
    local sprintOverride

    if IsValid( pusher ) then
        sprintOverride = self.wheelchairPushSprint == true
    end

    self.driveMultiplier = self.wheelchairBroken and 0
        or self:GetPropulsionMultiplier( controller, dt, isPushing, sprintOverride )

    self:ApplyWheelchairReverse( self:GetPhysicsObject(), input, pusher )

    if isPushing then
        local phys = self:GetPhysicsObject()

        if IsValid( phys ) and phys:IsAsleep() then
            phys:Wake()
        end
    end

    local steer = ExpDecay( self:GetChairSteering(), steerTarget, 5, dt )
    self:SetChairSteering( steer )

    if isPushing and self.driveMultiplier > 0.1 and self.isGrounded and CurTime() >= self.nextPushSound then
        self.nextPushSound = CurTime() + 0.62
        self:EmitSound( "buttons/lever1.wav", 55, 118 + math.floor( self.driveMultiplier * 10 ), 0.28 )
    end
end

function ENT:OnSimulatePhysics( phys, dt, outLin, outAng )
    local driver = self:GetDriver()
    local pusher = self.wheelchairPusher

    if self.wheelchairBroken or ( not IsValid( driver ) and not IsValid( pusher ) ) then
        self.isGrounded = false
        return
    end

    local origin = phys:GetPos()

    traceData.start = origin + GROUND_OFFSET
    traceData.endpos = traceData.start - GROUND_DEPTH
    traceData.filter = self.groundTraceFilter or self.selfTraceFilter

    local tr = TraceLine( traceData )
    self.isGrounded = tr.Hit and tr.HitNormal[3] > 0.35

    if not self.isGrounded then return end

    local normal = tr.HitNormal
    local forward = self:GetForward()

    forward = forward - normal * forward:Dot( normal )

    if forward:LengthSqr() < 0.001 then return end
    forward:Normalize()

    local right = normal:Cross( forward )
    right:Normalize()

    local velocity = phys:GetVelocity()
    local forwardSpeed = velocity:Dot( forward )
    local sideSpeed = velocity:Dot( right )
    local isAttendantPush = IsValid( pusher )
    local input = isAttendantPush and self:GetWheelchairPushInput( pusher )
        or self:GetWheelchairDriveInput( driver )
    local targetSpeed

    if isAttendantPush then
        local handleError = pusher:GetPos() - self:GetWheelchairPusherPosition()
        handleError[3] = 0

        local coupling = Clamp( 1 - math.max( handleError:Length() - 12, 0 ) / 55, 0, 1 )

        if input > 0.05 then
            local limit = self.wheelchairPushSprint and PUSH_SPRINT_SPEED or PUSH_WALK_SPEED
            targetSpeed = input * limit * coupling
        elseif input < -0.05 then
            targetSpeed = input * PUSH_REVERSE_SPEED * coupling
        else
            targetSpeed = 0
        end
    else
        targetSpeed = input >= 0 and input * 150 or input * DRIVE_REVERSE_SPEED
    end

    local mass = phys:GetMass()
    local driveMultiplier = self.driveMultiplier or 0

    local response = Abs( input ) > 0.01 and 5.5 or 3.5
    local forceLimit = mass * 700
    local forwardForce

    if input < -0.05 then
        forwardForce = 0
    else
        forwardForce = ( targetSpeed - forwardSpeed ) * mass * response
    end

    forwardForce = Clamp( forwardForce, -forceLimit, forceLimit ) * driveMultiplier

    outLin:Add( forward * forwardForce )
    outLin:Add( right * Clamp( -sideSpeed * mass * 7, -mass * 500, mass * 500 ) )

    local steer = self:GetChairSteering()
    local speedFactor = Clamp( Abs( forwardSpeed ) / 45, 0, 1 )
    local pivotFactor = Abs( input ) < 0.05 and 0.45 or 1
    local turnForce = steer * mass * ( 65 + speedFactor * 85 ) * pivotFactor * driveMultiplier

    outAng:Add( normal * turnForce )

    if Abs( steer ) < 0.05 then
        local angVel = phys:GetAngleVelocity()
        outAng:Add( normal * -angVel[3] * mass * 1.4 )
    end
end

function ENT:PhysicsCollide( data )
    local hitEntity = data.HitEntity

    if IsValid( hitEntity ) then
        if hitEntity == self.wheelchairFakeRagdoll then return end

        if hg and hg.RagdollOwner and hg.RagdollOwner( hitEntity ) == self:GetDriver() then
            return
        end
    end

    local velocityChange = data.OurNewVelocity - data.OurOldVelocity
    local impactSpeed = velocityChange:Length()

    if CurTime() < ( self.WheelchairDropGraceUntil or 0 ) then
        return
    end

    if data.HitNormal[3] > 0.35 and impactSpeed < 250 then return end
    if impactSpeed < 90 then return end

    local now = CurTime()
    if now < ( self.nextWheelchairCollision or 0 ) then return end

    self.nextWheelchairCollision = now + 0.22
    BaseClass.PhysicsCollide( self, data )
end

function ENT:Repair()
    self:SetIsEngineOnFire( false )
    self:SetChassisHealth( self.MaxChassisHealth )
    self:SetEngineHealth( 1 )
    self:UpdateHealthOutputs()
    self.wheelchairBroken = false
end

function ENT:TurnOff()
    self:SetEngineState( 0 )
    self:SetChairSteering( 0 )
end

function ENT:OnTakeDamage( dmginfo )
    if self.wheelchairBroken then return end

    local amount = dmginfo:GetDamage()

    if dmginfo:IsDamageType( DMG_BLAST ) then
        amount = amount * self.BlastDamageMultiplier
    elseif dmginfo:IsDamageType( DMG_BULLET ) then
        amount = amount * self.BulletDamageMultiplier
    end

    local health = math.max( self:GetChassisHealth() - amount, 0 )
    self:SetChassisHealth( health )
    self:SetEngineHealth( 1 )
    self:UpdateHealthOutputs()

    if health > 0 then return end

    self.wheelchairBroken = true
    self:TurnOff()

    local driver = self:GetDriver()
    if IsValid( driver ) then
        driver:ExitVehicle()
    end

    self:EmitSound( "physics/metal/metal_box_break2.wav", 70, 105, 0.7 )
end

function ENT:OnDriverEnter()
    if self.wheelchairBroken then
        local driver = self:GetDriver()

        if IsValid( driver ) then
            driver:ExitVehicle()
        end

        return
    end

    self.rolloverEjecting = false
    self.upsideDownSince = nil
    self:SetEngineState( 2 )
end

function ENT:OnDriverExit()
    self:RestoreFakeOccupantMass()
    self.upsideDownSince = nil
    self:TurnOff()
    self.driveMultiplier = 0
end

function ENT:OnRemove()
    self:StopWheelchairPush()
    self:RestoreFakeOccupantMass()
    BaseClass.OnRemove( self )
end

hook.Add( "ShouldCollide", "GlideWheelchair.AttendantCollision", function( ent1, ent2 )
    local ply, other

    if ent1:IsPlayer() then
        ply, other = ent1, ent2
    elseif ent2:IsPlayer() then
        ply, other = ent2, ent1
    end

    if not IsValid( ply ) or not IsValid( other ) then return end

    local wheelchair = ply.WheelchairPushing
    if not IsValid( wheelchair ) then return end

    if other == wheelchair or other == wheelchair.wheelchairFakeRagdoll or other:GetParent() == wheelchair then
        return false
    end
end )

hook.Add( "SetupMove", "GlideWheelchair.AttendantMovement", function( ply, moveData )
    local wheelchair = ply.WheelchairPushing

    if not IsValid( wheelchair ) or wheelchair.wheelchairPusher ~= ply then return end
    if not wheelchair:IsValidWheelchairPusher( ply, false ) then return end

    local buttons = moveData:GetButtons()
    local commandForward = moveData:GetForwardSpeed()
    local commandSide = moveData:GetSideSpeed()
    local forwardDown = BitBand( buttons, IN_FORWARD ) ~= 0 or commandForward > 1
    local backDown = BitBand( buttons, IN_BACK ) ~= 0 or commandForward < -1
    local rightDown = BitBand( buttons, IN_MOVERIGHT ) ~= 0 or commandSide > 1
    local leftDown = BitBand( buttons, IN_MOVELEFT ) ~= 0 or commandSide < -1

    wheelchair.wheelchairPushInput = ( forwardDown and 1 or 0 ) - ( backDown and 1 or 0 )
    wheelchair.wheelchairPushSteer = ( rightDown and 1 or 0 ) - ( leftDown and 1 or 0 )
    wheelchair.wheelchairPushSprint = BitBand( buttons, IN_SPEED ) ~= 0

    if wheelchair.wheelchairPushInput < -0.05 then return end

    local forward = wheelchair:GetForward()
    forward[3] = 0

    if forward:LengthSqr() < 0.001 then return end

    forward:Normalize()

    local chairVelocity = wheelchair:GetVelocity()
    local targetVelocity = Vector( chairVelocity[1], chairVelocity[2], 0 )
    local currentVelocity = moveData:GetVelocity()
    local verticalVelocity = currentVelocity[3]
    local chairFollow = 0.8

    targetVelocity[3] = verticalVelocity
    moveData:SetVelocity( currentVelocity * ( 1 - chairFollow ) + targetVelocity * chairFollow )
end )

hook.Add( "FinishMove", "GlideWheelchair.AttendantHandlePosition", function( ply, moveData )
    local wheelchair = ply.WheelchairPushing

    if not IsValid( wheelchair ) or wheelchair.wheelchairPusher ~= ply then return end
    if not wheelchair:IsValidWheelchairPusher( ply, false ) then return end
    if wheelchair:GetWheelchairPushInput( ply ) < -0.05 then return end

    local currentPosition = moveData:GetOrigin()
    local desiredPosition = wheelchair:GetWheelchairPusherPosition()
    desiredPosition[3] = currentPosition[3]

    local filter = { ply, wheelchair }

    if IsValid( wheelchair.wheelchairFakeRagdoll ) then
        filter[#filter + 1] = wheelchair.wheelchairFakeRagdoll
    end

    if wheelchair.seats then
        for _, seat in pairs( wheelchair.seats ) do
            if IsValid( seat ) then
                filter[#filter + 1] = seat
            end
        end
    end

    local mins, maxs = ply:GetHull()
    local tr = util.TraceHull( {
        start = currentPosition,
        endpos = desiredPosition,
        mins = mins,
        maxs = maxs,
        mask = MASK_PLAYERSOLID,
        filter = filter
    } )

    if not tr.StartSolid then
        local correction = tr.HitPos - currentPosition
        local correctionFraction = Clamp( FrameTime() * 10, 0, 0.24 )
        local finalPosition = currentPosition + correction * correctionFraction

        moveData:SetOrigin( finalPosition )
    end
end )

local function GetWheelchairFromEntity( ent )
    if not IsValid( ent ) then return end
    if ent.IsGlideWheelchair then return ent end

    local parent = ent:GetParent()
    if IsValid( parent ) and parent.IsGlideWheelchair then
        return parent
    end
end

local function FindFakeEntryWheelchair( ply, ragdoll )
    if hg and hg.eyeTrace then
        local tr = hg.eyeTrace( ply, 100, ragdoll )
        local wheelchair = tr and GetWheelchairFromEntity( tr.Entity )

        if IsValid( wheelchair ) then
            return wheelchair
        end
    end

    local origin = ragdoll:WorldSpaceCenter()
    local nearest
    local nearestDistance = 90 * 90

    for _, ent in ipairs( ents.FindInSphere( origin, 90 ) ) do
        local wheelchair = GetWheelchairFromEntity( ent )

        if IsValid( wheelchair ) then
            local distance = origin:DistToSqr( wheelchair:WorldSpaceCenter() )

            if distance < nearestDistance then
                local tr = util.TraceLine( {
                    start = origin,
                    endpos = wheelchair:WorldSpaceCenter(),
                    filter = { ply, ragdoll },
                    mask = MASK_SOLID
                } )

                if not tr.Hit or GetWheelchairFromEntity( tr.Entity ) == wheelchair then
                    nearest = wheelchair
                    nearestDistance = distance
                end
            end
        end
    end

    return nearest
end

local function HasClearWheelchairAssistPath( helper, target, ragdoll, wheelchair )
    local bodyTrace = util.TraceLine( {
        start = helper:GetShootPos(),
        endpos = ragdoll:WorldSpaceCenter(),
        filter = { helper, target },
        mask = MASK_SOLID
    } )

    if bodyTrace.Hit and bodyTrace.Entity ~= ragdoll then return false end

    local chairTrace = util.TraceLine( {
        start = ragdoll:WorldSpaceCenter(),
        endpos = wheelchair:WorldSpaceCenter(),
        filter = { helper, target, ragdoll },
        mask = MASK_SOLID
    } )

    return not chairTrace.Hit or GetWheelchairFromEntity( chairTrace.Entity ) == wheelchair
end

local function ClearWheelchairAssist( target, wheelchair )
    if IsValid( target ) then
        target.WheelchairFakeEntryPending = nil
        target.switchingseat = nil
    end

    if IsValid( wheelchair ) and wheelchair.WheelchairAssistTarget == target then
        wheelchair.WheelchairAssistTarget = nil
    end
end

local function GetSeatPoseSettleTime( seat )
    return seat:GetVehicleClass() == "Pod" and 0.55 or 1.05
end


net.Receive( "GlideWheelchair.SeatFakeTarget", function( _, helper )
    local ragdoll = net.ReadEntity()
    local wheelchair = GetWheelchairFromEntity( net.ReadEntity() )
    local now = CurTime()

    if now < ( helper.NextWheelchairAssist or 0 ) then return end
    helper.NextWheelchairAssist = now + 0.5

    if not helper:Alive() or helper:InVehicle() or IsValid( helper.FakeRagdoll ) then return end
    if helper.organism and helper.organism.canmove == false then return end
    if not IsValid( ragdoll ) or not IsValid( wheelchair ) then return end
    if wheelchair.wheelchairBroken or IsValid( wheelchair.WheelchairAssistTarget ) then return end
    if wheelchair:GetVelocity():LengthSqr() > 100 * 100 then return end
    if not hg or not hg.RagdollOwner or not hg.FakeUp or not hg.Fake then return end

    local target = hg.RagdollOwner( ragdoll )

    if not IsValid( target ) or not target:IsPlayer() or target == helper then return end
    if not target:Alive() or target:InVehicle() or target.FakeRagdoll ~= ragdoll then return end
    if target.WheelchairFakeEntryPending then return end

    local helperPos = helper:GetPos()
    local bodyPos = ragdoll:WorldSpaceCenter()
    local chairPos = wheelchair:WorldSpaceCenter()

    if helperPos:DistToSqr( bodyPos ) > 125 * 125 then return end
    if bodyPos:DistToSqr( chairPos ) > 115 * 115 then return end
    if helperPos:DistToSqr( chairPos ) > 165 * 165 then return end
    if not HasClearWheelchairAssistPath( helper, target, ragdoll, wheelchair ) then return end

    local seat = wheelchair:GetFreeSeat()
    if not IsValid( seat ) or IsValid( seat:GetDriver() ) then return end

    target.WheelchairFakeEntryPending = true
    target.switchingseat = true
    wheelchair.WheelchairAssistTarget = target

    if hg.FakeUp( target, true, true ) ~= true then
        ClearWheelchairAssist( target, wheelchair )
        return
    end

    timer.Simple( 0, function()
        if not IsValid( target ) or not IsValid( wheelchair ) or not IsValid( seat ) then
            ClearWheelchairAssist( target, wheelchair )
            return
        end

        if wheelchair.wheelchairBroken or IsValid( seat:GetDriver() ) or wheelchair.WheelchairAssistTarget ~= target then
            ClearWheelchairAssist( target, wheelchair )
            return
        end

        target:SetAllowWeaponsInVehicle( false )
        target:EnterVehicle( seat )

        timer.Simple( GetSeatPoseSettleTime( seat ), function()
            if not IsValid( target ) then
                if IsValid( wheelchair ) then
                    wheelchair.WheelchairAssistTarget = nil
                end

                return
            end

            target.WheelchairFakeEntryPending = nil

            if target:Alive() and IsValid( wheelchair ) and target:InVehicle() and target:GetVehicle() == seat then
                wheelchair.WheelchairAssistTarget = nil

                if not IsValid( target.FakeRagdoll ) then
                    target:SetEyeAngles( ZERO_ANGLE )
                    target:InvalidateBoneCache()
                    target:SetupBones()
                    hg.Fake( target, nil, nil, true )
                end
            else
                ClearWheelchairAssist( target, wheelchair )
            end
        end )
    end )
end )


hook.Add( "KeyPress", "GlideWheelchair.FakeEntry", function( ply, key )
    if key ~= IN_USE or not ply:KeyDown( IN_WALK ) then return end
    if not ply:Alive() or ply:InVehicle() then return end
    if ply.WheelchairFakeEntryPending then return end

    local ragdoll = ply.FakeRagdoll
    if not IsValid( ragdoll ) then return end
    if not hg or not hg.FakeUp or not hg.Fake then return end

    local org = ply.organism
    if org and org.canmove == false then return end

    local wheelchair = FindFakeEntryWheelchair( ply, ragdoll )
    if not IsValid( wheelchair ) or wheelchair.wheelchairBroken then return end
    if wheelchair:GetVelocity():LengthSqr() > 140 * 140 then return end

    local seat = wheelchair:GetFreeSeat()
    if not IsValid( seat ) then return end

    ply.WheelchairFakeEntryPending = true
    ply.switchingseat = true

    if hg.FakeUp( ply, true, true ) ~= true then
        ply.WheelchairFakeEntryPending = nil
        ply.switchingseat = nil
        return
    end

    timer.Simple( 0, function()
        if not IsValid( ply ) then return end

        if not IsValid( wheelchair ) or not IsValid( seat ) or IsValid( seat:GetDriver() ) then
            ply.WheelchairFakeEntryPending = nil
            ply.switchingseat = nil
            return
        end

        ply:SetAllowWeaponsInVehicle( false )
        ply:EnterVehicle( seat )

        timer.Simple( GetSeatPoseSettleTime( seat ), function()
            if not IsValid( ply ) then return end

            ply.WheelchairFakeEntryPending = nil

            if ply:Alive() and IsValid( wheelchair ) and ply:InVehicle() and ply:GetVehicle() == seat then
                if not IsValid( ply.FakeRagdoll ) then
                    ply:SetEyeAngles( ZERO_ANGLE )
                    ply:InvalidateBoneCache()
                    ply:SetupBones()
                    hg.Fake( ply, nil, nil, true )
                end
            else
                ply.switchingseat = nil
            end
        end )
    end )
end )

hook.Add( "Fake", "GlideWheelchair.AttachFakeOccupant", function( ply, ragdoll )
    if not IsValid( ply ) or not ply:InVehicle() then return end

    local wheelchair = GetWheelchairFromEntity( ply:GetVehicle() )
    if IsValid( wheelchair ) then
        wheelchair:SetFakeOccupantRagdoll( ragdoll )
    end
end )
