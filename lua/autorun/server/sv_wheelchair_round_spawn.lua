local ENABLED = CreateConVar(
    "zc_wheelchair_round_spawn",
    "1",
    FCVAR_ARCHIVE,
    "Allow a wheelchair to randomly fall into Z-City rounds.",
    0,
    1
)

local CHANCE = CreateConVar(
    "zc_wheelchair_round_chance",
    "0.25",
    FCVAR_ARCHIVE,
    "Chance for one wheelchair to spawn per Z-City round.",
    0,
    1
)

local UP = Vector( 0, 0, 1 )
local HULL_MINS = Vector( -30, -24, -18 )
local HULL_MAXS = Vector( 30, 24, 44 )
local MIN_PLAYER_DISTANCE_SQR = 240 * 240
local DROP_TIMER = "GlideWheelchair.RoundDrop"

local function IsAwayFromPlayers( position )
    for _, ply in player.Iterator() do
        if ply:Alive() and ply:GetPos():DistToSqr( position ) < MIN_PLAYER_DISTANCE_SQR then
            return false
        end
    end

    return true
end

local function FindDropPosition( preferredPosition, allowNearPlayers )
    for attempt = 1, 12 do
        local basePosition = attempt == 1 and preferredPosition

        if not isvector( basePosition ) and zb and zb.GetRandomSpawn then
            basePosition = zb:GetRandomSpawn()
        end

        if not isvector( basePosition ) then return end

        local groundTrace = util.TraceHull( {
            start = basePosition + UP * 72,
            endpos = basePosition - UP * 512,
            mins = HULL_MINS,
            maxs = HULL_MAXS,
            mask = MASK_SOLID_BRUSHONLY
        } )

        if groundTrace.Hit and ( allowNearPlayers or IsAwayFromPlayers( groundTrace.HitPos ) ) then
            local launchStart = groundTrace.HitPos + UP * 48
            local ceilingTrace = util.TraceHull( {
                start = launchStart,
                endpos = launchStart + UP * 420,
                mins = HULL_MINS,
                maxs = HULL_MAXS,
                mask = MASK_SOLID_BRUSHONLY
            } )

            local clearance = ceilingTrace.HitPos[3] - launchStart[3]

            if clearance >= 150 then
                local dropHeight = math.min( math.random( 175, 285 ), clearance - 42 )
                local dropPosition = launchStart + UP * dropHeight
                local blocked = util.TraceHull( {
                    start = dropPosition,
                    endpos = dropPosition,
                    mins = HULL_MINS,
                    maxs = HULL_MAXS,
                    mask = MASK_SOLID
                } ).Hit

                if not blocked then
                    return dropPosition
                end
            end
        end

        preferredPosition = nil
    end
end

local function SpawnFallingWheelchair( preferredPosition, allowNearPlayers )
    local dropPosition = FindDropPosition( preferredPosition, allowNearPlayers )
    if not dropPosition then return false end

    local wheelchair = ents.Create( "glide_wheelchair" )
    if not IsValid( wheelchair ) then return false end

    wheelchair:SetPos( dropPosition )
    wheelchair:SetAngles( Angle( math.random( -8, 8 ), math.random( -180, 180 ), math.random( -6, 6 ) ) )
    wheelchair:Spawn()
    wheelchair:Activate()

    wheelchair.WheelchairRoundSpawned = true
    wheelchair.WheelchairDropGraceUntil = CurTime() + 5

    local phys = wheelchair:GetPhysicsObject()

    if IsValid( phys ) then
        phys:SetVelocity( Vector( math.random( -22, 22 ), math.random( -22, 22 ), math.random( -80, -45 ) ) )
        phys:AddAngleVelocity( Vector( math.random( -16, 16 ), math.random( -16, 16 ), math.random( -25, 25 ) ) )
        phys:Wake()
    end

    return true
end

local function RemoveRoundWheelchairs()
    timer.Remove( DROP_TIMER )

    for _, wheelchair in ipairs( ents.FindByClass( "glide_wheelchair" ) ) do
        if wheelchair.WheelchairRoundSpawned then
            wheelchair:Remove()
        end
    end
end

hook.Add( "ZB_PreRoundStart", "GlideWheelchair.CleanupRoundDrop", RemoveRoundWheelchairs )

hook.Add( "ZB_StartRound", "GlideWheelchair.ScheduleRoundDrop", function()
    if not ENABLED:GetBool() or math.Rand( 0, 1 ) > CHANCE:GetFloat() then return end

    local mode = CurrentRound and CurrentRound()
    if mode and mode.DisableRandomWheelchair then return end

    timer.Create( DROP_TIMER, math.Rand( 7, 18 ), 1, function()
        if not zb or zb.ROUND_STATE ~= 1 then return end

        SpawnFallingWheelchair()
    end )
end )

concommand.Add( "zc_wheelchair_drop", function( ply )
    if IsValid( ply ) and not ply:IsAdmin() then return end

    local preferredPosition

    if IsValid( ply ) then
        preferredPosition = ply:GetEyeTrace().HitPos
    end

    SpawnFallingWheelchair( preferredPosition, true )
end )
