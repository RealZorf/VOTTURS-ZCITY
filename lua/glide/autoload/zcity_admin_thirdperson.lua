Glide.AdminThirdperson = Glide.AdminThirdperson or {}

local Thirdperson = Glide.AdminThirdperson

if SERVER then return end

local STATE_CONVAR = CreateClientConVar(
    "zcity_glide_thirdperson",
    "0",
    true,
    false,
    "Toggle third person while inside Glide vehicles.",
    0,
    1
)

local TOGGLE_KEY = KEY_P
local CHAT_PREFIX_COLOR = Color( 110, 190, 255 )
local MASK_SOLID_BRUSHONLY = 16395
local ANGLE_ZERO = angle_zero
local VECTOR_ZERO = vector_origin

local isToggleKeyDown = false

local function GetGlideVehicle( ply )
    if not IsValid( ply ) then
        return NULL, 0
    end

    local vehicle = ply.GlideGetVehicle and ply:GlideGetVehicle() or NULL
    local seatIndex = ply.GlideGetSeatIndex and ply:GlideGetSeatIndex() or 0

    if IsValid( vehicle ) and vehicle.IsGlideVehicle then
        return vehicle, seatIndex
    end

    local seat = ply:GetVehicle()
    local parent = IsValid( seat ) and seat:GetParent() or NULL

    if IsValid( parent ) and parent.IsGlideVehicle then
        return parent, seatIndex
    end

    return NULL, 0
end

function Thirdperson.IsEnabled()
    return STATE_CONVAR:GetBool()
end

function Thirdperson.SetEnabled( enabled )
    RunConsoleCommand( "zcity_glide_thirdperson", enabled and "1" or "0" )
end

function Thirdperson.Toggle()
    local enabled = not Thirdperson.IsEnabled()
    Thirdperson.SetEnabled( enabled )

    chat.AddText(
        CHAT_PREFIX_COLOR,
        "[Glide] ",
        color_white,
        enabled and "Third person enabled." or "Third person disabled."
    )

    return enabled
end

function Thirdperson.IsAvailable( ply )
    local vehicle = GetGlideVehicle( ply )
    return IsValid( vehicle )
end

function Thirdperson.IsActive( ply )
    return Thirdperson.IsEnabled() and Thirdperson.IsAvailable( ply )
end

local ShouldUseThirdperson = Thirdperson.IsActive

local function BuildThirdpersonView( ply, znear, zfar )
    local vehicle = GetGlideVehicle( ply )
    if not IsValid( vehicle ) then return end

    local config = Glide.Config or {}
    local camera = Glide.Camera
    local externalFov = tonumber( config.cameraFOVExternal ) or GetConVar( "fov_desired" ):GetFloat()
    local distance = tonumber( config.cameraDistance ) or 1
    local height = tonumber( config.cameraHeight ) or 1
    local trailerFraction = vehicle.GetConnectedReceptacleCount and vehicle:GetConnectedReceptacleCount() > 0 and 1 or 0

    local viewAngles

    if camera and camera.vehicle == vehicle and camera.angles then
        viewAngles = Angle( camera.angles[1], camera.angles[2], camera.angles[3] )
    else
        local aimAngles = ply:GetAimVector():AngleEx( vehicle:GetUp() )
        viewAngles = Angle( aimAngles[1], aimAngles[2], aimAngles[3] )
    end

    local angleOffset = vehicle.CameraAngleOffset or ANGLE_ZERO
    local centerOffset = vehicle.CameraCenterOffset or VECTOR_ZERO
    local trailerOffset = vehicle.CameraTrailerOffset or VECTOR_ZERO
    local cameraOffset = vehicle.CameraOffset or Vector( -200, 0, 50 )
    local shakeOffset = camera and camera.shakeOffset or VECTOR_ZERO
    local offset = shakeOffset + cameraOffset * Vector( distance, 1, height )
    local startPos = vehicle:LocalToWorld( centerOffset + trailerOffset * trailerFraction )

    viewAngles = viewAngles + angleOffset

    local endPos = startPos
        + viewAngles:Forward() * offset[1] * ( 1 + trailerFraction * ( vehicle.CameraTrailerDistanceMultiplier or 0 ) )
        + viewAngles:Right() * offset[2]
        + viewAngles:Up() * offset[3]

    local dir = endPos - startPos
    dir:Normalize()

    local tr = util.TraceLine( {
        start = startPos,
        endpos = endPos + dir * 10,
        filter = { ply, vehicle },
        mask = MASK_SOLID_BRUSHONLY
    } )

    if tr.Hit then
        endPos = tr.HitPos - dir * 10
    end

    vehicle.isLocalPlayerInFirstPerson = false

    return {
        origin = endPos,
        angles = viewAngles + ( camera and camera.punchAngle or ANGLE_ZERO ),
        fov = externalFov,
        znear = znear,
        zfar = zfar,
        drawviewer = true
    }
end

function Thirdperson.GetClientView( ply, _origin, _angles, _fov, znear, zfar )
    if not ShouldUseThirdperson( ply ) then
        return
    end

    return BuildThirdpersonView( ply, znear, zfar )
end

local function ForceThirdperson()
    local ply = LocalPlayer()
    if not ShouldUseThirdperson( ply ) then
        return
    end

    local vehicle = GetGlideVehicle( ply )
    local camera = Glide.Camera

    if IsValid( vehicle ) then
        vehicle.isLocalPlayerInFirstPerson = false
    end

    if camera and camera.isInFirstPerson then
        camera:SetFirstPerson( false )
    end
end

hook.Add( "Think", "ZCity.GlideThirdperson.VehicleToggle", function()
    local ply = LocalPlayer()
    local isDown = input.IsKeyDown( TOGGLE_KEY )

    if isToggleKeyDown ~= isDown then
        isToggleKeyDown = isDown

        if
            isDown and
            IsValid( ply ) and
            Thirdperson.IsAvailable( ply ) and
            not vgui.CursorVisible() and
            not gui.IsGameUIVisible() and
            not ( ply.IsTyping and ply:IsTyping() )
        then
            Thirdperson.Toggle()
        end
    end

    ForceThirdperson()
end )

hook.Add( "ShouldDrawLocalPlayer", "ZCity.GlideThirdperson.DrawLocalPlayer", function()
    local ply = LocalPlayer()

    if ShouldUseThirdperson( ply ) then
        return true
    end
end )

hook.Add( "Glide_OnLocalEnterVehicle", "ZCity.GlideThirdperson.EnterMessage", function()
    chat.AddText(
        CHAT_PREFIX_COLOR,
        "[Glide] ",
        color_white,
        "Press P to toggle third person."
    )

    timer.Simple( 0, function()
        ForceThirdperson()
    end )
end )
