if not table.GetWinningKey then
    function table.GetWinningKey(tbl)
        local winner, winnerKey
        for k, v in pairs(tbl) do
            if not winner or v > winner then
                winner = v
                winnerKey = k
            end
        end
        return winnerKey
    end
end

/*********************************************************
    Checks and Sets
 *********************************************************/
function SolidMapVote.playerHasVoted( steamId64 )
    return SolidMapVote.votes[ steamId64 ]
end

function SolidMapVote.playerHasNominated( steamId64 )
    return SolidMapVote.nominations[ steamId64 ]
end

function SolidMapVote.playerHasRTVed( steamId64 )
    return table.HasValue( SolidMapVote.RTVs, steamId64 )
end

function SolidMapVote.vote( steamId64, vote )
    SolidMapVote.votes[ steamId64 ] = vote
    SolidMapVote.sendVotes( true )
end

function SolidMapVote.nominate( steamId64, nomination )
    SolidMapVote.nominations[ steamId64 ] = nomination
    SolidMapVote.sendNominations( true )
end

function SolidMapVote.getRTVAmount()
    return math.ceil( #player.GetAll()*SolidMapVote[ 'Config' ][ 'RTV Percentage' ] )
end


/*********************************************************
    Start and End
 *********************************************************/
function SolidMapVote.start()
    if SolidMapVote.isOpen or SolidMapVote.changingMap then return end

    SolidMapVote.stopMapChangeAttempts()
    SolidMapVote.cooldownsRecorded = false
    SolidMapVote.votes = {}
    SolidMapVote.finished = false
    SolidMapVote.realWinner = ''
    SolidMapVote.fixedWinner = ''
    SolidMapVote.changeQueue = {}
    SolidMapVote.triedMaps = {}

    SolidMapVote.poolMaps()
    local maps = SolidMapVote.selectMaps()
    local counts = SolidMapVote.createWeightedPool( maps, SolidMapVote.mapPlayCounts )

    SolidMapVote.isOpen = true
    SolidMapVote.startTime = CurTime()
    SolidMapVote.endTime = SolidMapVote.startTime + SolidMapVote[ 'Config' ][ 'Length' ]

    net.Start( 'SolidMapVote.start' )
    net.WriteTable( maps )
    net.WriteFloat( SolidMapVote.endTime )
    net.WriteFloat( SolidMapVote[ 'Config' ][ 'Length' ] )
    net.Broadcast()

    SolidMapVote.sendPlayCounts( counts, true )
end

function SolidMapVote.close()
    if SolidMapVote.finished then return end

    local winningMaps = SolidMapVote.getWinningMaps()
    local realWinner = (#winningMaps > 0) and table.Random( winningMaps ) or nil
    local fixedWinner = ''

    if not realWinner or realWinner == '' then
        realWinner = SolidMapVote.pickFallbackWinner()
    end

    if realWinner == 'random' then
        if SolidMapVote[ 'Config' ][ 'Random Mode' ] == 1 then
            fixedWinner = SolidMapVote.pickRandomEligible( SolidMapVote.maps )
        else
            fixedWinner = SolidMapVote.pickRandomEligible( SolidMapVote.mapPool )
        end

        if not fixedWinner or fixedWinner == '' then
            fixedWinner = SolidMapVote.pickFallbackWinner()
        end

        if fixedWinner == 'extend' or fixedWinner == 'random' then
            fixedWinner = game.GetMap()
        end
    elseif realWinner == 'extend' then
        fixedWinner = game.GetMap()
    end

    SolidMapVote.realWinner = realWinner or game.GetMap()
    SolidMapVote.fixedWinner = fixedWinner or ''
    SolidMapVote.finished = true
    SolidMapVote.isOpen = true
    SolidMapVote.changeTime = RealTime() + ( tonumber( SolidMapVote[ 'Config' ][ 'Post Vote Length' ] ) or 5 )
    SolidMapVote.changeQueue = SolidMapVote.buildChangeQueue( SolidMapVote.realWinner, SolidMapVote.fixedWinner )
    SolidMapVote.triedMaps = {}

    SolidMapVote.recordVoteCooldowns( SolidMapVote.realWinner, SolidMapVote.fixedWinner )

    net.Start( 'SolidMapVote.end' )
    net.WriteTable( winningMaps )
    net.WriteString( SolidMapVote.realWinner )
    net.WriteString( SolidMapVote.fixedWinner )
    net.Broadcast()
end

function SolidMapVote.reset()
    SolidMapVote.stopMapChangeAttempts()
    SolidMapVote.autoStartTime = RealTime() + SolidMapVote[ 'Config' ][ 'Vote Autostart Delay' ]
    SolidMapVote.reminded = false
    SolidMapVote.finished = false
    SolidMapVote.isOpen = false
    SolidMapVote.votes = {}
    SolidMapVote.RTVs = {}
    SolidMapVote.RTVDelayEnd = RealTime() + SolidMapVote[ 'Config' ][ 'RTV Delay' ]
    SolidMapVote.RTVCompleted = false
    SolidMapVote.startVoteAfterRound = false
    SolidMapVote.realWinner = ''
    SolidMapVote.fixedWinner = ''
    SolidMapVote.changeQueue = {}
    SolidMapVote.triedMaps = {}
    SolidMapVote.changeTime = 0
    SolidMapVote.cooldownsRecorded = false

    for _, ply in pairs( player.GetAll() ) do
        ply:ConCommand( 'solidmapvote_close_ui' )
    end
end


/*********************************************************
    Initializing and Stuff
 *********************************************************/
function SolidMapVote.getMapVoteCounts()
    local mapVoteCounts = {}

    for _, map in pairs( SolidMapVote.maps or {} ) do
        if isstring( map ) and map ~= '' then
            mapVoteCounts[ map ] = 0
        end
    end

    if SolidMapVote[ 'Config' ][ 'Enable Extend' ] then
        mapVoteCounts[ 'extend' ] = 0
    end

    if SolidMapVote[ 'Config' ][ 'Enable Random' ] then
        mapVoteCounts[ 'random' ] = 0
    end

    for steamId64, vote in pairs( SolidMapVote.votes or {} ) do
        if not steamId64 or not isstring( vote ) or vote == '' then continue end

        local ply = player.GetBySteamID64( steamId64 )
        local power = 1

        if IsValid( ply ) then
            local votePowerFunc = SolidMapVote.Config and SolidMapVote.Config[ 'Vote Power' ]
            if isfunction( votePowerFunc ) then
                local ok, result = pcall( votePowerFunc, ply )
                if ok then
                    power = result or 1
                end
            end
        end

        power = tonumber( power ) or 1
        power = math.max( 1, power )

        mapVoteCounts[ vote ] = ( mapVoteCounts[ vote ] or 0 ) + power
    end

    return mapVoteCounts
end

function SolidMapVote.getWinningMaps()
    local mapVoteCounts = SolidMapVote.getMapVoteCounts()
    local winningMaps = {}
    local winningKey = table.GetWinningKey( mapVoteCounts )

    if not winningKey then
        return winningMaps
    end

    local winningAmount = mapVoteCounts[ winningKey ]
    for map, voteCount in pairs( mapVoteCounts ) do
        if voteCount == winningAmount then
            table.insert( winningMaps, map )
        end
    end

    return winningMaps
end

function SolidMapVote.getRankedMaps()
    local ranked = {}

    for map, count in pairs( SolidMapVote.getMapVoteCounts() ) do
        if map ~= 'extend' and map ~= 'random' then
            table.insert( ranked, { map = map, count = tonumber( count ) or 0 } )
        end
    end

    table.sort( ranked, function( a, b )
        if a.count == b.count then
            return a.map < b.map
        end

        return a.count > b.count
    end )

    local maps = {}
    for _, entry in ipairs( ranked ) do
        table.insert( maps, entry.map )
    end

    return maps
end

function SolidMapVote.isMapInstalled( map )
    if not isstring( map ) or map == '' or map == 'extend' or map == 'random' then
        return false
    end

    return file.Exists( 'maps/' .. map .. '.bsp', 'GAME' )
end

function SolidMapVote.pickFallbackWinner()
    local sources = {
        SolidMapVote.maps,
        SolidMapVote.filterEligibleMaps( SolidMapVote.mapPool ),
        SolidMapVote.mapPool,
        SolidMapVote[ 'Config' ][ 'Construct Map Pool' ],
    }

    for _, source in ipairs( sources ) do
        for _, map in ipairs( source or {} ) do
            if SolidMapVote.isMapInstalled( map ) and map ~= game.GetMap() then
                return map
            end
        end
    end

    for _, source in ipairs( sources ) do
        local map = SolidMapVote.pickRandomEligible( source )
        if isstring( map ) and map ~= '' and map ~= 'extend' and map ~= 'random' then
            return map
        end
    end

    return game.GetMap()
end

function SolidMapVote.buildChangeQueue( realWinner, fixedWinner )
    local queue = {}
    local seen = {}
    local currentMap = game.GetMap()

    local function push( map )
        if not isstring( map ) or map == '' then return end
        if map == 'extend' or map == 'random' then return end
        if map == currentMap then return end
        if seen[ map ] then return end

        seen[ map ] = true
        table.insert( queue, map )
    end

    if realWinner == 'random' then
        push( fixedWinner )
    else
        push( realWinner )
    end

    for _, map in ipairs( SolidMapVote.getRankedMaps() ) do
        push( map )
    end

    for _, map in ipairs( SolidMapVote.maps or {} ) do
        push( map )
    end

    for _, map in ipairs( SolidMapVote.filterEligibleMaps( SolidMapVote.mapPool ) or {} ) do
        push( map )
    end

    for _, map in ipairs( SolidMapVote.mapPool or {} ) do
        push( map )
    end

    for _, map in ipairs( SolidMapVote[ 'Config' ][ 'Construct Map Pool' ] or {} ) do
        push( map )
    end

    return queue
end

function SolidMapVote.stopMapChangeAttempts()
    timer.Remove( 'SolidMapVote.ChangeLevelRetry' )
    SolidMapVote.changingMap = false
end

function SolidMapVote.applyExtend()
    SolidMapVote.stopMapChangeAttempts()
    SolidMapVote.reset()
    RTV_ACTIVE = false
    CURRENT_ROUND = 0
    RTV_ROUNDS = 20

    if zb then
        zb.Roundscount = 0
        zb.ROUND_STATE = 0
        zb.votestarted = false
        if zb.RoundStart then zb:RoundStart() end
    end
end

function SolidMapVote.tryNextMapChange()
    if SolidMapVote.changingMap then return end

    SolidMapVote.triedMaps = SolidMapVote.triedMaps or {}
    SolidMapVote.changeQueue = SolidMapVote.changeQueue or {}

    while true do
        local map = table.remove( SolidMapVote.changeQueue, 1 )

        if not map then
            ErrorNoHalt( '[SolidMapVote] No remaining maps could be loaded. Extending the current map instead.\n' )
            SolidMapVote.sendMessage( { color_white, 'No other maps could be loaded. Extending the current map.' }, true )
            SolidMapVote.applyExtend()
            return
        end

        if SolidMapVote.triedMaps[ map ] then continue end
        SolidMapVote.triedMaps[ map ] = true

        if not SolidMapVote.isMapInstalled( map ) then
            ErrorNoHalt( '[SolidMapVote] Skipping missing map "' .. map .. '", trying next highest voted map.\n' )
            continue
        end

        SolidMapVote.changingMap = true
        SolidMapVote.realWinner = map
        SolidMapVote.fixedWinner = map

        print( '[SolidMapVote] Changing level to ' .. map )
        local ok, err = pcall( RunConsoleCommand, 'changelevel', map )
        if not ok then
            SolidMapVote.changingMap = false
            ErrorNoHalt( '[SolidMapVote] changelevel to "' .. map .. '" errored: ' .. tostring( err ) .. '\n' )
            SolidMapVote.sendMessage( { color_white, 'Failed to load ', Color( 0, 177, 106 ), map, color_white, '. Trying the next highest voted map...' }, true )
            SolidMapVote.tryNextMapChange()
            return
        end

        timer.Create( 'SolidMapVote.ChangeLevelRetry', 2, 1, function()
            SolidMapVote.changingMap = false
            ErrorNoHalt( '[SolidMapVote] changelevel to "' .. map .. '" failed, trying next highest voted map.\n' )
            SolidMapVote.sendMessage( { color_white, 'Failed to load ', Color( 0, 177, 106 ), map, color_white, '. Trying the next highest voted map...' }, true )
            SolidMapVote.tryNextMapChange()
        end )

        return
    end
end

local function SolidMapVote_AddPoolMap( pool, map, currentMap )
    if not isstring( map ) or map == "" then return end
    if map == currentMap then return end
    if table.HasValue( pool, map ) then return end
    table.insert( pool, map )
end

function SolidMapVote.loadPlayableMaps()
    local path = SolidMapVote[ 'Config' ][ 'Playable Maps Path' ] or "map_registry/playable_maps.json"
    local maps = {}

    file.CreateDir( "map_registry" )

    if file.Exists( path, "DATA" ) then
        local decoded = util.JSONToTable( file.Read( path, "DATA" ) or "" )
        if istable( decoded ) then
            maps = decoded
        else
            ErrorNoHalt( "[SolidMapVote] Failed to parse " .. path .. "\n" )
        end
    else
        local fallback = SolidMapVote[ 'Config' ][ 'Map Pool' ] or {}
        file.Write( path, util.TableToJSON( fallback, true ) )
        maps = fallback
        print( "[SolidMapVote] Created " .. path .. " from config Map Pool." )
    end

    if not istable( maps ) or table.Count( maps ) == 0 then
        maps = SolidMapVote[ 'Config' ][ 'Map Pool' ] or {}
    end

    return maps
end

function SolidMapVote.poolMaps()
    SolidMapVote.mapPool = {}
    local currentMap = game.GetMap()
    local useCustomPool = SolidMapVote[ 'Config' ][ 'Custom Map Pool' ]
        or SolidMapVote[ 'Config' ][ 'Manual Map Pool' ]

    if useCustomPool then
        for _, map in ipairs( SolidMapVote.loadPlayableMaps() ) do
            SolidMapVote_AddPoolMap( SolidMapVote.mapPool, map, currentMap )
        end

        if #SolidMapVote.mapPool == 0 then
            ErrorNoHalt( "[SolidMapVote] Custom map pool was empty, scanning installed maps instead.\n" )
        else
            print( "[SolidMapVote] Loaded " .. #SolidMapVote.mapPool .. " maps from playable_maps.json" )
            return SolidMapVote.mapPool
        end
    end

    local maps = file.Find( 'maps/*.bsp', 'GAME' )

    for _, map in pairs( maps ) do
        local realMapName = string.sub( map, 1, string.find( map, '.bsp' )-1 )

        if realMapName == currentMap then continue end
        if realMapName == "gm_construct" or realMapName == "gm_flatgrass" then continue end

        if SolidMapVote[ 'Config' ][ 'Ignore Prefix' ] then
            SolidMapVote_AddPoolMap( SolidMapVote.mapPool, realMapName, currentMap )
        else
            for _, prefix in pairs( SolidMapVote[ 'Config' ][ 'Map Prefix' ] ) do
                if string.StartWith( realMapName, prefix ) then
                    SolidMapVote_AddPoolMap( SolidMapVote.mapPool, realMapName, currentMap )
                end
            end
        end
    end

    return SolidMapVote.mapPool
end

function SolidMapVote.getMapsOnVote()
    local n = tonumber( SolidMapVote[ 'Config' ][ 'Maps On Vote' ] ) or 12
    return math.max( 1, math.floor( n ) )
end

function SolidMapVote.getMapPlayCount( map )
    return tonumber( SolidMapVote.mapPlayCounts[ map ] ) or 0
end

function SolidMapVote.getCooldownPath()
    return SolidMapVote[ 'Config' ][ 'Map Cooldown Path' ] or 'solidmapvote/map_cooldowns.json'
end

function SolidMapVote.isMapCooldownEnabled()
    return SolidMapVote[ 'Config' ][ 'Map Cooldown Enabled' ] ~= false
end

local function ensureCooldownDir()
    local path = SolidMapVote.getCooldownPath()
    local dir = string.match( path, '^(.+)/[^/]+$' )
    if dir and dir ~= '' then
        file.CreateDir( dir )
    end
    return path
end

function SolidMapVote.loadMapCooldowns()
    SolidMapVote.mapCooldowns = {}

    if not SolidMapVote.isMapCooldownEnabled() then
        return SolidMapVote.mapCooldowns
    end

    local path = SolidMapVote.getCooldownPath()

    if not file.Exists( path, 'DATA' ) then
        return SolidMapVote.mapCooldowns
    end

    local decoded = util.JSONToTable( file.Read( path, 'DATA' ) or '' )
    if not istable( decoded ) then
        ErrorNoHalt( '[SolidMapVote] Failed to parse ' .. path .. '\n' )
        return SolidMapVote.mapCooldowns
    end

    for map, remaining in pairs( decoded ) do
        remaining = tonumber( remaining ) or 0
        if isstring( map ) and remaining > 0 then
            SolidMapVote.mapCooldowns[ map ] = math.floor( remaining )
        end
    end

    return SolidMapVote.mapCooldowns
end

function SolidMapVote.saveMapCooldowns()
    if not SolidMapVote.isMapCooldownEnabled() then return end

    file.Write( ensureCooldownDir(), util.TableToJSON( SolidMapVote.mapCooldowns or {}, true ) )
end

function SolidMapVote.isMapOnCooldown( map )
    if not SolidMapVote.isMapCooldownEnabled() then return false end
    if not isstring( map ) or map == '' or map == 'extend' or map == 'random' then return false end

    return SolidMapVote.getMapCooldown( map ) > 0
end

function SolidMapVote.getMapCooldown( map )
    return tonumber( ( SolidMapVote.mapCooldowns or {} )[ map ] ) or 0
end

function SolidMapVote.tickMapCooldowns()
    local remaining = {}

    for map, votesLeft in pairs( SolidMapVote.mapCooldowns or {} ) do
        votesLeft = ( tonumber( votesLeft ) or 0 ) - 1
        if votesLeft > 0 then
            remaining[ map ] = votesLeft
        end
    end

    SolidMapVote.mapCooldowns = remaining
end

function SolidMapVote.setMapCooldown( map, votes )
    if not isstring( map ) or map == '' or map == 'extend' or map == 'random' then return end

    votes = math.max( 0, math.floor( tonumber( votes ) or 0 ) )
    SolidMapVote.mapCooldowns = SolidMapVote.mapCooldowns or {}

    if votes <= 0 then
        SolidMapVote.mapCooldowns[ map ] = nil
    else
        SolidMapVote.mapCooldowns[ map ] = votes
    end
end

function SolidMapVote.recordVoteCooldowns( realWinner, fixedWinner )
    if not SolidMapVote.isMapCooldownEnabled() then return end
    if SolidMapVote.cooldownsRecorded then return end

    SolidMapVote.cooldownsRecorded = true
    SolidMapVote.tickMapCooldowns()

    if realWinner ~= 'extend' then
        local mapToCool = realWinner == 'random' and fixedWinner or realWinner
        local duration = tonumber( SolidMapVote[ 'Config' ][ 'Map Cooldown Votes' ] ) or 2
        SolidMapVote.setMapCooldown( mapToCool, duration )
    end

    SolidMapVote.saveMapCooldowns()
    SolidMapVote.sendCooldowns( true )
end

function SolidMapVote.filterEligibleMaps( pool )
    local eligible = {}
    local seen = {}

    for _, map in ipairs( pool or {} ) do
        if seen[ map ] then continue end
        if SolidMapVote.isMapOnCooldown( map ) then continue end
        seen[ map ] = true
        table.insert( eligible, map )
    end

    return eligible
end

function SolidMapVote.pickRandomEligible( pool )
    local eligible = SolidMapVote.filterEligibleMaps( pool )

    if #eligible == 0 then
        eligible = pool or {}
    end

    if #eligible == 0 then return nil end

    return table.Random( eligible )
end

function SolidMapVote.sortMapsLeastPlayed( maps )
    local grouped = {}
    local counts = {}
    local seenCount = {}

    for _, map in ipairs( maps ) do
        local playCount = SolidMapVote.getMapPlayCount( map )
        grouped[ playCount ] = grouped[ playCount ] or {}
        table.insert( grouped[ playCount ], map )

        if not seenCount[ playCount ] then
            seenCount[ playCount ] = true
            table.insert( counts, playCount )
        end
    end

    table.sort( counts )

    local ordered = {}
    for _, playCount in ipairs( counts ) do
        local group = grouped[ playCount ]
        for i = #group, 2, -1 do
            local j = math.random( i )
            group[ i ], group[ j ] = group[ j ], group[ i ]
        end
        for _, map in ipairs( group ) do
            table.insert( ordered, map )
        end
    end

    return ordered
end

function SolidMapVote.selectMaps()
    SolidMapVote.maps = {}

    local maxMaps = SolidMapVote.getMapsOnVote()
    local selected = {}

    local function addMap( map )
        if not isstring( map ) or map == '' then return false end
        if selected[ map ] then return false end
        if #SolidMapVote.maps >= maxMaps then return false end
        if SolidMapVote.isMapOnCooldown( map ) then return false end

        selected[ map ] = true
        table.insert( SolidMapVote.maps, map )
        return true
    end

    local function uniqueList( source )
        local list = {}
        local seen = {}

        for _, map in ipairs( source or {} ) do
            if isstring( map ) and map ~= '' and not seen[ map ] then
                seen[ map ] = true
                table.insert( list, map )
            end
        end

        return list
    end

    local function pickFrom( remaining )
        if #remaining == 0 then return nil, 0 end

        local map
        if SolidMapVote[ 'Config' ][ 'Prefer Least Played' ] ~= false then
            map = SolidMapVote.sortMapsLeastPlayed( remaining )[ 1 ]
        elseif SolidMapVote[ 'Config' ][ 'Fair Map Recycling' ] then
            map = SolidMapVote.selectRandomMapFairly( remaining, SolidMapVote.mapPlayCounts )
        end

        if not map then
            map = remaining[ math.random( #remaining ) ]
        end

        for i, name in ipairs( remaining ) do
            if name == map then
                return map, i
            end
        end

        return remaining[ 1 ], 1
    end

    local function fillFrom( candidates )
        local remaining = {}
        for _, map in ipairs( candidates ) do
            if not selected[ map ] then
                table.insert( remaining, map )
            end
        end

        while #SolidMapVote.maps < maxMaps and #remaining > 0 do
            local map, index = pickFrom( remaining )
            if not map then break end

            table.remove( remaining, index )
            addMap( map )
        end
    end

    local eligible = SolidMapVote.filterEligibleMaps( uniqueList( SolidMapVote.mapPool ) )

    for _, map in pairs( SolidMapVote.nominations or {} ) do
        addMap( map )
    end

    fillFrom( eligible )

    return SolidMapVote.maps
end

function SolidMapVote.initFairMapRecycling()
    SolidMapVote.mapPlayCounts = {}

    if not sql.TableExists( 'solid_map_vote_data' ) then
        sql.Query( 'CREATE TABLE solid_map_vote_data ( Map string, PlayCount int )' )
    end

    local currentMap = sql.Query( string.format( 'SELECT * FROM solid_map_vote_data WHERE Map = \'%s\'', game.GetMap() ) )
    if not currentMap then
        sql.Query( string.format( 'INSERT INTO solid_map_vote_data ( Map, PlayCount ) VALUES ( \'%s\', 1 )', game.GetMap() ) )
    else
        sql.Query( string.format( 'UPDATE solid_map_vote_data SET PlayCount = \'%d\' WHERE Map = \'%s\'', currentMap[1][ 'PlayCount' ]+1, game.GetMap() ) )
    end

    local allMapPlayCounts = sql.Query( 'SELECT * FROM solid_map_vote_data' )

    if not allMapPlayCounts then
        ErrorNoHalt( 'There was a problem pulling maps from the local database for the Fair Map Recycling System. It has been disabled.' )
        ErrorNoHalt( sql.LastError() )
        SolidMapVote[ 'Config' ][ 'Fair Map Recycling' ] = false
    else
        for _, mapData in pairs( allMapPlayCounts ) do
            SolidMapVote.mapPlayCounts[ mapData.Map ] = mapData.PlayCount
        end
    end

    return SolidMapVote.mapPlayCounts
end

function SolidMapVote.createWeightedPool( pool, weights, calc )
    local weightedPool = {}
    local calc = calc and calc or false

    for _, map in pairs( pool ) do
        weightedPool[ map ] = weights[ map ] or (calc and 1 or 0)
    end

    return weightedPool
end

function SolidMapVote.selectRandomMapFairly( pool, weights )
    local weightedPool = SolidMapVote.createWeightedPool( pool, weights, true )
    local inverseCumulativePoolSum = 0
    local random

    for map, weight in pairs( weightedPool ) do
        inverseCumulativePoolSum = inverseCumulativePoolSum + (1/weight)
    end

    random = math.random() * inverseCumulativePoolSum

    for map, weight in pairs( weightedPool ) do
        random = random - (1/weight)
        if random <= 0 then return map end
    end

    return nil
end
