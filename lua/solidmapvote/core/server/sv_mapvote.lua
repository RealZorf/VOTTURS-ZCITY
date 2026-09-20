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
    local winningMaps = SolidMapVote.getWinningMaps()
    local realWinner = table.Random( winningMaps )
    local fixedWinner = ''

    if not realWinner or realWinner == "" then
        if SolidMapVote.maps and #SolidMapVote.maps > 0 then
            realWinner = table.Random( SolidMapVote.maps )
        end
        
        if (not realWinner or realWinner == "") and SolidMapVote.mapPool and #SolidMapVote.mapPool > 0 then
            realWinner = table.Random( SolidMapVote.mapPool )
        end

        if not realWinner or realWinner == "" then
            realWinner = game.GetMap()
        end
    end

    if realWinner == 'random' then
        if SolidMapVote[ 'Config' ][ 'Random Mode' ] == 1 then
            fixedWinner = table.Random( SolidMapVote.maps )
        else
            fixedWinner = table.Random( SolidMapVote.mapPool )
        end
    elseif realWinner == 'extend' then
        fixedWinner = game.GetMap()
    end

    SolidMapVote.realWinner = realWinner
    SolidMapVote.fixedWinner = fixedWinner
    SolidMapVote.finished = true
    SolidMapVote.changeTime = RealTime() + SolidMapVote[ 'Config' ][ 'Post Vote Length' ]

    net.Start( 'SolidMapVote.end' )
    net.WriteTable( winningMaps )
    net.WriteString( realWinner )
    net.WriteString( fixedWinner )
    net.Broadcast()
end

function SolidMapVote.reset()
    SolidMapVote.close()
    SolidMapVote.autoStartTime = RealTime() + SolidMapVote[ 'Config' ][ 'Vote Autostart Delay' ]
    SolidMapVote.reminded = false
    SolidMapVote.finished = false
    SolidMapVote.RTVs = {}
    SolidMapVote.RTVDelayEnd = RealTime() + SolidMapVote[ 'Config' ][ 'RTV Delay' ]

    for _, ply in pairs( player.GetAll() ) do
        ply:ConCommand( 'solidmapvote_close_ui' )
    end
end


/*********************************************************
    Initializing and Stuff
 *********************************************************/
function SolidMapVote.getWinningMaps()
    local mapVoteCounts = {}
    local winningMaps = {}

    for _, map in pairs( SolidMapVote.maps ) do
        mapVoteCounts[ map ] = 0
    end

    if SolidMapVote[ 'Config' ][ 'Enable Extend' ] then
        mapVoteCounts[ 'extend' ] = 0
    end

    if SolidMapVote[ 'Config' ][ 'Enable Random' ] then
        mapVoteCounts[ 'random' ] = 0
    end

    for steamId64, vote in pairs(SolidMapVote.votes) do
        if not steamId64 or not vote then continue end
        
        local ply = player.GetBySteamID64(steamId64)
        local power = 1
        
        if IsValid(ply) then
            local votePowerFunc = SolidMapVote.Config and SolidMapVote.Config['Vote Power']
            if isfunction(votePowerFunc) then
                power = votePowerFunc(ply) or 1
            end
        end

        power = tonumber(power) or 1
        power = math.max(1, power)

        mapVoteCounts[vote] = (mapVoteCounts[vote] or 0) + power
    end

    local winningAmount = mapVoteCounts[ table.GetWinningKey( mapVoteCounts ) ]
    for map, voteCount in pairs( mapVoteCounts ) do
        if voteCount == winningAmount then
            table.insert( winningMaps, map )
        end
    end

    return winningMaps
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

function SolidMapVote.selectMaps()
    SolidMapVote.maps = {}

    if #SolidMapVote.mapPool <= 6 then
        SolidMapVote.maps = SolidMapVote.mapPool
        return SolidMapVote.maps
    end

    if #SolidMapVote.nominations >= 6 then
        for steamID64, map in pairs( SolidMapVote.nominations ) do
            table.insert( SolidMapVote.maps, map )
        end

        return SolidMapVote.maps
    else
        for steamID64, map in pairs( SolidMapVote.nominations ) do
            table.insert( SolidMapVote.maps, map )
        end
    end

    local i = table.Count( SolidMapVote.nominations )
    while i < 6 do
        local map = SolidMapVote[ 'Config' ][ 'Fair Map Recycling' ] and
                    SolidMapVote.selectRandomMapFairly( SolidMapVote.mapPool, SolidMapVote.mapPlayCounts ) or
                    table.Random( SolidMapVote.mapPool )

        if not table.HasValue( SolidMapVote.maps, map ) and map != nil then
            table.insert( SolidMapVote.maps, map )
            i = i + 1
        end
    end

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
