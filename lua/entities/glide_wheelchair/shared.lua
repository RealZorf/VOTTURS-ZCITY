ENT.Type = "anim"
ENT.Base = "base_glide"

ENT.PrintName = "Wheelchair"
ENT.Author = "Patidinho"
ENT.Category = "Z-City Vehicles"
ENT.GlideCategory = "Z-City"
ENT.Purpose = "A manually propelled Glide wheelchair"
ENT.Instructions = "Press USE to sit"
ENT.AdminOnly = false

ENT.ChassisModel = "models/props_unique/wheelchair01.mdl"
ENT.MaxChassisHealth = 180
ENT.CanSwitchHeadlights = false
ENT.CanSwitchTurnSignals = false
ENT.CanCatchOnFire = false
ENT.VehicleType = Glide.VEHICLE_TYPE.CAR
ENT.IsGlideWheelchair = true

DEFINE_BASECLASS( "base_glide" )

function ENT:SetupDataTables()
    BaseClass.SetupDataTables( self )

    self:NetworkVar( "Float", "ChairSteering" )
end

function ENT:GetPlayerSitSequence( _seatIndex )
    return "drive_airboat"
end

function ENT:GetFirstPersonOffset( _seatIndex, localEyePos )
    localEyePos[1] = localEyePos[1] + 2
    localEyePos[3] = localEyePos[3] + 2

    return localEyePos
end

if CLIENT then
    ENT.CameraOffset = Vector( -92, 0, 43 )
    ENT.CameraCenterOffset = Vector( 0, 0, 19 )
    ENT.CameraAngleOffset = Angle( 5, 0, 0 )
    ENT.MaxSoundDistance = 1500
    ENT.MaxMiscDistance = 2500
    ENT.WheelSkidmarkScale = 0.18

    ENT.StartSound = ""
    ENT.StartTailSound = ""
    ENT.StartedSound = ""
    ENT.StoppedSound = ""
    ENT.ExternalGearSwitchSound = ""
    ENT.InternalGearSwitchSound = ""
    ENT.HornSound = ""
    ENT.ReverseSound = ""
    ENT.BrakeReleaseSound = ""
    ENT.BrakeSqueakSound = ""
    ENT.BrakeLoopSound = ""
    ENT.ExhaustOffsets = {}
    ENT.EngineSmokeStrips = {}
    ENT.EngineFireOffsets = {}
    ENT.LightSprites = {}
    ENT.Headlights = {}
end

if SERVER then
    ENT.ChassisMass = 90
    ENT.SpawnPositionOffset = Vector( 0, 0, 24 )
    ENT.SpawnAngleOffset = Angle( 0, 90, 0 )
    ENT.AngularDrag = Vector( -3, -2.5, -4 )

    ENT.BulletDamageMultiplier = 0.7
    ENT.BlastDamageMultiplier = 1.2
    ENT.CollisionDamageMultiplier = 0.35
    ENT.EngineDamageMultiplier = 0
    function ENT:GetInputGroups( seatIndex )
        return seatIndex > 1 and { "general_controls" } or { "general_controls", "land_controls" }
    end
end
