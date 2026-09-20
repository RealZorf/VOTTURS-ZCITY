local cv_custom_rtv = CreateConVar("smv_custom_rtv_internal", "0", FCVAR_ARCHIVE)

concommand.Add("smv_custom_rtv_enable", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:PrintMessage(HUD_PRINTCONSOLE, "Access Denied: You must be a Superadmin.")
        return
    end

    if not args[1] then
        local status = cv_custom_rtv:GetBool() and "1 (ON)" or "0 (OFF)"
        if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, "smv_custom_rtv_enable is " .. status) end
        return
    end

    local newValue = tonumber(args[1]) or 0
    cv_custom_rtv:SetInt(newValue)
    
    local adminName = IsValid(ply) and ply:Nick() or "Server Console"
    PrintMessage(HUD_PRINTTALK, "[MapVote] Custom RTV has been " .. (newValue > 0 and "ENABLED" or "DISABLED") .. " by " .. adminName)
end)

hook.Add( 'InitPostEntity', 'SolidMapVote.Init', function()
    SolidMapVote.votes = {}
    SolidMapVote.isOpen = false
    SolidMapVote.finished = false
    SolidMapVote.RTVs = {}
    SolidMapVote.RTVDelayEnd = RealTime() + SolidMapVote[ 'Config' ][ 'RTV Delay' ]

    SolidMapVote.PleaseRTVs = {}
    SolidMapVote.DontRTVs = {}
    SolidMapVote.AudioPlayed = false
    SolidMapVote.AudioCooldown = RealTime() + 600

    SolidMapVote.maps = {}
    SolidMapVote.mapPool = {}
    SolidMapVote.nominations = {}
    SolidMapVote.mapPlayCounts = {}
    SolidMapVote.realWinner = ''
    SolidMapVote.fixedWinner = ''

    SolidMapVote.startTime = 0
    SolidMapVote.endTime = 0
    SolidMapVote.changeTime = 0
    SolidMapVote.loadTime = RealTime()
    SolidMapVote.autoStartTime = SolidMapVote.loadTime + SolidMapVote[ 'Config' ][ 'Vote Autostart Delay' ]
    SolidMapVote.reminded = false
    SolidMapVote.RTVCompleted = false

    SolidMapVote.isTTT = string.find( string.lower( GAMEMODE.Name ), 'terrorist town' )
    SolidMapVote.isDeathRun = string.find( string.lower( GAMEMODE.Name ), 'deathrun' )
    SolidMapVote.isMurder = string.find( string.lower( GAMEMODE.Name ), 'murder' )
    SolidMapVote.isZombieSurvival = string.find( string.lower( GAMEMODE.Name ), 'zombie survival' )
    SolidMapVote.isJailBreak = string.find( string.lower( GAMEMODE.Name ), 'jail break' )
    SolidMapVote.isZCity = true
    SolidMapVote.startVoteAfterRound = false

    SolidMapVote.poolMaps()
    SolidMapVote.initFairMapRecycling()
    SolidMapVote.hackRoundBasedGamemodes()
end )

hook.Add( 'PlayerInitialSpawn', 'SolidMapVote.PlayerSpawn', function( ply )
    if SolidMapVote.isOpen then
        net.Start( 'SolidMapVote.start' )
        net.WriteTable( SolidMapVote.maps )
        net.WriteFloat( SolidMapVote.endTime )
        net.WriteFloat( SolidMapVote[ 'Config' ][ 'Length' ] )
        net.Send( ply )

        SolidMapVote.sendVotes( false, ply )
    end

    SolidMapVote.sendNominations( false, ply )
end )

hook.Add( 'PlayerDisconnected', 'SolidMapVote.PlayerLeave', function( ply )
    local steamId64 = ply:SteamID64()

    if SolidMapVote.playerHasVoted( steamId64 ) then
        SolidMapVote.votes[ steamId64 ] = nil
        SolidMapVote.sendVotes( true )
    end

    if SolidMapVote.playerHasNominated( steamId64 ) then
        SolidMapVote.nominations[ steamId64 ] = nil
        SolidMapVote.sendNominations( true )
    end

    if SolidMapVote.playerHasRTVed( steamId64 ) then
        table.RemoveByValue( SolidMapVote.RTVs, steamId64 )
    end

    table.RemoveByValue( SolidMapVote.PleaseRTVs, steamId64 )
    table.RemoveByValue( SolidMapVote.DontRTVs, steamId64 )
end )

local function SolidMapVote_ConsumeChat( txtTbl )
    if istable( txtTbl ) then
        txtTbl[1] = ""
    end
    return ""
end

hook.Add( 'HG_PlayerSay', 'SolidMapVote.PlayerCommands', function( ply, txtTbl, text )
    if not IsValid( ply ) then return end

    local command = string.lower( string.Trim( text or '' ) )
    if command == '' then return end

    local steamId64 = ply:SteamID64()
    local name = ply:Nick()

    if table.HasValue( SolidMapVote[ 'Config' ][ 'Force Vote Commands' ], command ) and not SolidMapVote.isOpen then
        if SolidMapVote[ 'Config' ][ 'Force Vote Permission' ]( ply ) then
            SolidMapVote.start()
            SolidMapVote.sendMessage( { Color( 0, 177, 106 ), name, color_white, ' has forced the mapvote!' }, true )
            return SolidMapVote_ConsumeChat( txtTbl )
        end
    end

    if cv_custom_rtv:GetBool() and (command == "!pleasertv" or command == "!dontrtv") and not SolidMapVote.isOpen then
        if NAXYIRTV then ply:ChatPrint("sasi") return SolidMapVote_ConsumeChat( txtTbl ) end
        if SolidMapVote.RTVCompleted then return SolidMapVote_ConsumeChat( txtTbl ) end

        if SolidMapVote.AudioCooldown > RealTime() then
            local timeRemaining = tostring( math.ceil( SolidMapVote.AudioCooldown - RealTime() ) )
            SolidMapVote.sendMessage( { color_white, 'You cannot use this command for another ', Color( 0, 177, 106 ), timeRemaining, color_white, ' seconds!' }, false, ply )
            return SolidMapVote_ConsumeChat( txtTbl )
        end

        if SolidMapVote.AudioPlayed then
            SolidMapVote.sendMessage( { color_white, 'This event has already occurred on this map!' }, false, ply )
            return SolidMapVote_ConsumeChat( txtTbl )
        end

        local isPlease = (command == "!pleasertv")
        local targetTable = isPlease and SolidMapVote.PleaseRTVs or SolidMapVote.DontRTVs
        local otherTable = isPlease and SolidMapVote.DontRTVs or SolidMapVote.PleaseRTVs
        local actionText = isPlease and "please rtv" or "don't rtv"
        
        local reqVotes = math.max(1, math.ceil(SolidMapVote.getRTVAmount() / 2))

        if table.HasValue(otherTable, steamId64) then
            table.RemoveByValue(otherTable, steamId64)
        end

        if table.HasValue(targetTable, steamId64) and SolidMapVote[ 'Config' ][ 'Enable UnVote' ] then
            table.RemoveByValue(targetTable, steamId64)
            SolidMapVote.sendMessage( { Color( 0, 177, 106 ), name, color_white, ' has removed their ' .. actionText .. ' vote! ', Color( 0, 177, 106 ), '(' .. #targetTable .. '/' .. reqVotes .. ')' }, true )
            return SolidMapVote_ConsumeChat( txtTbl )
        elseif not table.HasValue(targetTable, steamId64) then
            table.insert(targetTable, steamId64)
            SolidMapVote.sendMessage( { Color( 0, 177, 106 ), name, color_white, ' wants to ' .. actionText .. '! ', Color( 0, 177, 106 ), '(' .. #targetTable .. '/' .. reqVotes .. ')' }, true )
        end

        if #targetTable >= reqVotes then
            SolidMapVote.AudioPlayed = true
            
            if isPlease then
                BroadcastLua('surface.PlaySound("rtv.wav", 0, 100, 1.0)')
                SolidMapVote.sendMessage( { color_white, 'The server wants everyone to ', Color( 0, 177, 106 ), 'PLEASE RTV!' }, true )
            else
                BroadcastLua('surface.PlaySound("nortv.wav", 0, 100, 1.0)')
                SolidMapVote.sendMessage( { color_white, 'The server wants everyone to ', Color( 177, 0, 0 ), 'NOT RTV!' }, true )
            end
        end

        return SolidMapVote_ConsumeChat( txtTbl )
    end

    if table.HasValue( SolidMapVote[ 'Config' ][ 'Vote Commands' ], command ) and not SolidMapVote.isOpen then
        if NAXYIRTV then ply:ChatPrint("sasi") return SolidMapVote_ConsumeChat( txtTbl ) end

        if SolidMapVote.RTVDelayEnd > RealTime() then
            local timeRemaining = tostring( math.ceil( SolidMapVote.RTVDelayEnd - RealTime() ) )
            SolidMapVote.sendMessage( { color_white, 'You cannot RTV for another ', Color( 0, 177, 106 ), timeRemaining, color_white, ' seconds!' }, false, ply )
            return SolidMapVote_ConsumeChat( txtTbl )
        end

        if not SolidMapVote.RTVCompleted then
            if SolidMapVote.playerHasRTVed( steamId64 ) and SolidMapVote[ 'Config' ][ 'Enable UnVote' ] then
                table.RemoveByValue( SolidMapVote.RTVs, steamId64 )
                SolidMapVote.sendMessage( { Color( 0, 177, 106 ), name, color_white, ' has removed his rock the vote! ', Color( 0, 177, 106 ), '(' .. #SolidMapVote.RTVs .. '/' .. SolidMapVote.getRTVAmount() .. ')' }, true )
                return SolidMapVote_ConsumeChat( txtTbl )
            else
                table.insert( SolidMapVote.RTVs, steamId64 )
                SolidMapVote.sendMessage( { Color( 0, 177, 106 ), name, color_white, ' wants to rock the vote! ', Color( 0, 177, 106 ), '(' .. #SolidMapVote.RTVs .. '/' .. SolidMapVote.getRTVAmount() .. ')' }, true )
                return SolidMapVote_ConsumeChat( txtTbl )
            end

        else
            SolidMapVote.sendMessage( { color_white, 'The RTV count has already been reached. The map vote will start soon.' }, false, ply )
            return SolidMapVote_ConsumeChat( txtTbl )
        end
    end

    if table.HasValue( SolidMapVote[ 'Config' ][ 'Nomination Commands' ], command ) and not SolidMapVote.isOpen then
        if not SolidMapVote[ 'Config' ][ 'Nomination Permissions' ]( ply ) then
            SolidMapVote.sendMessage( { color_white, 'You do not have permission to nominate maps!' }, false, ply )
            return SolidMapVote_ConsumeChat( txtTbl )
        elseif not SolidMapVote[ 'Config' ][ 'Allow Nominations' ] then
            SolidMapVote.sendMessage( { color_white, 'Map nominations are currently disabled on the server!' }, false, ply )
            return SolidMapVote_ConsumeChat( txtTbl )
        else
            ply:ConCommand( 'solidmapvote_nomination_menu' )
            return SolidMapVote_ConsumeChat( txtTbl )
        end
    end

    if table.HasValue( SolidMapVote[ 'Config' ][ 'Time Left Commands' ], command ) and SolidMapVote[ 'Config' ][ 'Enable Vote Autostart' ] and not SolidMapVote.isOpen then
        local timeRemaining = math.ceil( SolidMapVote.autoStartTime - RealTime() )
        SolidMapVote.sendMessage( { color_white, 'There are ', Color( 0, 177, 106 ), tostring( timeRemaining ), color_white, ' seconds util the map vote will start!' }, false, ply )
        return SolidMapVote_ConsumeChat( txtTbl )
    end
end )

hook.Add( 'Think', 'SolidMapVote.ServerLoop', function()
    SolidMapVote.checkForRTV()

    SolidMapVote.checkForVoteEnd()

    SolidMapVote.postMapVoteChange()

    SolidMapVote.checkForAutostart()
end )

function SolidMapVote.checkForRTV()
    if #SolidMapVote.RTVs >= SolidMapVote.getRTVAmount() and not SolidMapVote.isOpen and #player.GetAll() > 0 then
        if (SolidMapVote.isTTT or
        SolidMapVote.isDeathRun or
        SolidMapVote.isMurder or
        SolidMapVote.isZombieSurvival or
        SolidMapVote.isJailBreak or
        SolidMapVote.isZCity) and
        not SolidMapVote.startVoteAfterRound then
            SolidMapVote.startVoteAfterRound = true
            SolidMapVote.RTVCompleted = true
            SolidMapVote.sendMessage( { color_white, 'The map vote will open after the current round!' }, true )

        elseif not SolidMapVote.startVoteAfterRound then
            SolidMapVote.RTVCompleted = true
            SolidMapVote.start()
        end
    end
end

function SolidMapVote.checkForVoteEnd()
    if SolidMapVote.endTime < CurTime() and SolidMapVote.isOpen and not SolidMapVote.finished then
        SolidMapVote.close()
    end
end

local mapChangeTriggered = false

function SolidMapVote.postMapVoteChange()
    if SolidMapVote.changeTime < RealTime() and SolidMapVote.finished then
        SolidMapVote.isOpen = false

        if SolidMapVote.realWinner == 'extend' then
            if SolidMapVote[ 'Config' ][ 'Enable Vote Autostart' ] then

                SolidMapVote.close()
                SolidMapVote.reset()
                RTV_ACTIVE = false
                if zb then 
                    zb.Roundscount = 0
                    zb.ROUND_STATE = 0
                    zb.votestarted = false
                    if zb.RoundStart then zb:RoundStart() end 
                end
            else
                SolidMapVote.close()
                SolidMapVote.reset()
                CURRENT_ROUND = 0
                RTV_ROUNDS = 20
                RTV_ACTIVE = false
                if zb then 
                    zb.Roundscount = 0
                    zb.ROUND_STATE = 0
                    zb.votestarted = false
                    if zb.RoundStart then zb:RoundStart() end 
                end
            end
        elseif SolidMapVote.realWinner == 'random' and !mapChangeTriggered then
            mapChangeTriggered = true
            if SolidMapVote.fixedWinner and SolidMapVote.fixedWinner ~= "" then
                RunConsoleCommand( 'changelevel', SolidMapVote.fixedWinner )
            else
                ErrorNoHalt("SolidMapVote: Random winner selected but fixedWinner is invalid!\n")
            end
        elseif !mapChangeTriggered then
            mapChangeTriggered = true
            if SolidMapVote.realWinner and SolidMapVote.realWinner ~= "" then
                RunConsoleCommand( 'changelevel', SolidMapVote.realWinner )
            else
                ErrorNoHalt("SolidMapVote: RealWinner is invalid!\n")
            end
        end
    end
end

function SolidMapVote.checkForAutostart()
    if SolidMapVote[ 'Config' ][ 'Enable Vote Autostart' ] and not SolidMapVote.isOpen then
        local timeRemaining = math.ceil( SolidMapVote.autoStartTime - RealTime() )

        if not SolidMapVote.reminded and timeRemaining < SolidMapVote[ 'Config' ][ 'Autostart Reminder' ] then
            SolidMapVote.reminded = true
            SolidMapVote.sendMessage( { color_white, 'The map vote will open in ', Color( 0, 177, 106 ), tostring( timeRemaining ), color_white, ' seconds!' }, true )
        end

        if timeRemaining <= 0 then
            SolidMapVote.start()
        end
    end
end

function SolidMapVote.hackRoundBasedGamemodes()
    if SolidMapVote.isTTT then
        GAMEMODE.StartFrettaVote = function() end

        game.LoadNextMap = function()
            SolidMapVote.start()
        end

        local oldTimerSimple = timer.Simple
        function timer.Simple( time, func, ... )
            if func == game.LoadNextMap then
                SolidMapVote.start()
                return
            end

            oldTimerSimple( time, func, ... )
        end

        hook.Add( 'TTTEndRound', 'SolidMapVote.TTTStartVoteAfterRound', function( result )
            if SolidMapVote.startVoteAfterRound then
                SolidMapVote.start()
            end
        end )
    end


    if SolidMapVote.isDeathRun then
        hook.Add( 'DeathrunShouldMapSwitch', 'SolidMapVote.DeathRunShouldStartVote', function( roundsPlayed )
            if SolidMapVote.startVoteAfterRound then
                return true
            end
        end )

        hook.Add( 'DeathrunStartMapvote', 'SolidMapVote.DeathRunStartVote', function( roundsPlayed )
            SolidMapVote.start()
            return true
        end )
    end

    if SolidMapVote.isMurder then
        hook.Add( 'OnEndRound', 'SolidMapVote.MurderVoteTrigger', function()
            if SolidMapVote.startVoteAfterRound then
                SolidMapVote.start()
            end

            if GAMEMODE.RoundLimit:GetInt() == GAMEMODE.RoundCount+1 then
                SolidMapVote.start()
            end
        end )
    end

    if SolidMapVote.isZombieSurvival then
        hook.Add( 'EndRound', 'SolidMapVote.ZombieSurvivalShouldStartVote', function( teamWinner )
            if SolidMapVote.startVoteAfterRound then
                SolidMapVote.start()
            end
        end )

        hook.Add( 'LoadNextMap', 'SolidMapVote.ZombieSurvivalVoteTrigger', function()
            SolidMapVote.start()
            return true
        end )
    end

    if SolidMapVote.isZCity then
        hook.Add( 'ZB_PreRoundStart', 'SolidMapVote.ZCityVoteTrigger', function()
            if SolidMapVote.startVoteAfterRound then
                SolidMapVote.start()
            end
        end )
        
        hook.Add( 'ZB_EndRound', 'SolidMapVote.ZCityEndTrigger', function()
            if SolidMapVote.startVoteAfterRound then
                timer.Simple(5, function()
                    if SolidMapVote.startVoteAfterRound and not SolidMapVote.isOpen then
                        SolidMapVote.start()
                    end
                end)
            end
        end)
    end
end