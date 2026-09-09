local MODE = MODE

MODE.ExtractionRevealTime = 90
MODE.ExtractionOpenTime = 60
MODE.ExtractionHoldTime = 10
MODE.ExtractionSpawnBuffer = 650
MODE.ExtractionFallbackDistance = 1800

if SERVER then
    function MODE:PickSpawnExtraction()
        self:BuildZombieSpawnCache()
        local survivors = {}
        for _, ply in player.Iterator() do
            if ply:Alive() and not ply.ZSIsZombie and ply:Team() ~= TEAM_SPECTATOR and ply:Team() ~= TEAM_UNASSIGNED then
                local body = hg.GetCurrentCharacter(ply)
                survivors[#survivors + 1] = IsValid(body) and body:GetPos() or ply:GetPos()
            end
        end
        local best, bestScore
        for _, pos in ipairs(self.ZombieSpawnPoints or {}) do
            if not util.IsInWorld(pos + Vector(0, 0, 40)) then continue end
            local trace = util.TraceHull({start = pos + Vector(0, 0, 4), endpos = pos + Vector(0, 0, 4),
                mins = Vector(-16, -16, 0), maxs = Vector(16, 16, 72), mask = MASK_PLAYERSOLID_BRUSHONLY})
            if trace.Hit or trace.StartSolid then continue end
            local score, nearest = 0, math.huge
            for _, survivorPos in ipairs(survivors) do
                local distance = pos:Distance(survivorPos)
                score = score + math.abs(distance - self.ExtractionFallbackDistance)
                nearest = math.min(nearest, distance)
            end
            score = score / math.max(#survivors, 1) + math.max(800 - nearest, 0) * 3
            if not bestScore or score < bestScore then best, bestScore = pos, score end
        end
        if not best then return end
        return {mins = best + Vector(-128, -128, 0), maxs = best + Vector(128, 128, 128), name = "EVAC", fallback = true}
    end

    function MODE:ResetExtraction()
        self.ExtractionZone = nil
        self.ExtractionRevealed = false
        self.ExtractionOpened = false
        self.ExtractedCount = 0
        SetGlobalBool("ZS_ExtractionRevealed", false)
        SetGlobalBool("ZS_ExtractionEnabled", false)
        for _, ply in player.Iterator() do
            ply.ZSExtracted = nil
            ply:SetNWBool("ZS_Extracted", false)
            ply:SetNWFloat("ZS_ExtractionStartedAt", 0)
        end
    end

    function MODE:SetupExtraction()
        self:ResetExtraction()
        local zones = {}
        for _, name in ipairs({"BOMB_ZONE_A", "BOMB_ZONE_B"}) do
            local points = zb.GetMapPoints(name) or {}
            local a, b = points[1] and points[1].pos, points[2] and points[2].pos
            if not isvector(a) or not isvector(b) then continue end
            local mins = Vector(math.min(a.x, b.x), math.min(a.y, b.y), math.min(a.z, b.z))
            local maxs = Vector(math.max(a.x, b.x), math.max(a.y, b.y), math.max(a.z, b.z))
            if maxs.x <= mins.x or maxs.y <= mins.y or maxs.z <= mins.z then continue end
            zones[#zones + 1] = {mins = mins, maxs = maxs, name = string.sub(name, -1)}
        end
        self.ExtractionZone = table.Random(zones) or self:PickSpawnExtraction()
        local zone = self.ExtractionZone
        if not zone then
            PrintMessage(HUD_PRINTTALK, "No bomb zone or usable player spawn on this map. Survive until time runs out.")
            return
        end
        SetGlobalBool("ZS_ExtractionEnabled", true)
        SetGlobalVector("ZS_ExtractionMins", zone.mins)
        SetGlobalVector("ZS_ExtractionMaxs", zone.maxs)
        SetGlobalString("ZS_ExtractionSite", zone.name)
        PrintMessage(HUD_PRINTTALK, "Survivors must evacuate to win. Extraction will be marked with 90 seconds remaining.")
    end

    function MODE:IsExtractionSpawnBlocked(pos)
        local zone = self.ExtractionZone
        if not zone or not self.ExtractionRevealed then return false end
        local nearest = Vector(math.Clamp(pos.x, zone.mins.x, zone.maxs.x),
            math.Clamp(pos.y, zone.mins.y, zone.maxs.y), math.Clamp(pos.z, zone.mins.z, zone.maxs.z))
        return pos:DistToSqr(nearest) < self.ExtractionSpawnBuffer ^ 2
    end

    function MODE:UpdateExtraction()
        local zone = self.ExtractionZone
        if not zone then return end
        local now = CurTime()
        local remaining = self.RoundEndsAt - now
        if remaining <= self.ExtractionRevealTime and not self.ExtractionRevealed then
            if zone.fallback then
                zone = self:PickSpawnExtraction() or zone
                self.ExtractionZone = zone
                SetGlobalVector("ZS_ExtractionMins", zone.mins)
                SetGlobalVector("ZS_ExtractionMaxs", zone.maxs)
            end
            self.ExtractionRevealed = true
            SetGlobalBool("ZS_ExtractionRevealed", true)
            PrintMessage(HUD_PRINTTALK, "Extraction marked at site " .. zone.name .. ". Reach the zone! It opens with 30 seconds remaining.")
            for _, ply in player.Iterator() do ply:SendLua([[surface.PlaySound("ambient/alarms/klaxon1.wav")]]) end
        end
        if remaining <= self.ExtractionOpenTime and not self.ExtractionOpened then
            self.ExtractionOpened = true
            PrintMessage(HUD_PRINTTALK, "Extraction is OPEN! Survivors: stay inside for 10 seconds to escape.")
        end
        if not self.ExtractionOpened then return end
        for _, ply in player.Iterator() do
            if ply.ZSExtracted then continue end
            local eligible = remaining >= 0 and ply:Alive() and not ply.ZSIsZombie
                and ply:Team() ~= TEAM_SPECTATOR and ply:Team() ~= TEAM_UNASSIGNED
                and not IsValid(ply.FakeRagdoll) and not (ply.organism and ply.organism.otrub)
                and ply:WorldSpaceCenter():WithinAABox(zone.mins, zone.maxs)
            local started = ply:GetNWFloat("ZS_ExtractionStartedAt", 0)
            if not eligible then
                if started ~= 0 then ply:SetNWFloat("ZS_ExtractionStartedAt", 0) end
            elseif started == 0 then
                ply:SetNWFloat("ZS_ExtractionStartedAt", now)
            elseif now - started >= self.ExtractionHoldTime then
                ply.ZSExtracted = true
                ply:SetNWBool("ZS_Extracted", true)
                ply:SetNWFloat("ZS_ExtractionStartedAt", 0)
                self.ExtractedCount = self.ExtractedCount + 1
                self:StopZombieConsume(ply)
                ply:KillSilent()
                ply:SetTeam(TEAM_SPECTATOR)
                PrintMessage(HUD_PRINTTALK, ply:Nick() .. " escaped the outbreak!")
            end
        end
    end
else
    hook.Add("HUDPaint", "ZCityZombieSurvival_Extraction", function()
        if CurrentRound() ~= MODE or zb.ROUND_STATE ~= 1 then return end
        local ply = LocalPlayer()
        if not IsValid(ply) then return end
        if ply:GetNWBool("ZS_Extracted", false) then
            draw.SimpleTextOutlined("EVACUATED", "ZC_ZS_Status", ScrW() / 2, 100, Color(30, 220, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
            return
        end
        if not GetGlobalBool("ZS_ExtractionRevealed", false) then return end
        local mins, maxs = GetGlobalVector("ZS_ExtractionMins"), GetGlobalVector("ZS_ExtractionMaxs")
        local pos = (mins + maxs) / 2
        local screen = pos:ToScreen()
        local x = math.Clamp(screen.x, 130, ScrW() - 130)
        local y = math.Clamp(screen.y, 150, ScrH() - 170)
        if not screen.visible then x, y = ScrW() / 2, ScrH() - 170 end
        local remaining = GetGlobalFloat("ZS_RoundEndsAt") - CurTime()
        local status = remaining > MODE.ExtractionOpenTime and ("OPENS IN " .. math.ceil(remaining - MODE.ExtractionOpenTime) .. "s") or "OPEN — HOLD 8s INSIDE"
        local distance = math.Round(ply:EyePos():Distance(pos) * 0.0254)
        draw.SimpleTextOutlined("EXTRACTION " .. GetGlobalString("ZS_ExtractionSite") .. " • " .. distance .. "m", "ZC_ZS_Status", x, y, Color(30, 220, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
        draw.SimpleTextOutlined(status, "ZC_ZS_SpawnReason", x, y + 25, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
        local started = ply:GetNWFloat("ZS_ExtractionStartedAt", 0)
        if started > 0 then
            local progress = math.Clamp((CurTime() - started) / MODE.ExtractionHoldTime, 0, 1)
            draw.RoundedBox(3, ScrW() / 2 - 120, ScrH() - 155, 240, 12, color_black)
            draw.RoundedBox(3, ScrW() / 2 - 120, ScrH() - 155, 240 * progress, 12, Color(30, 220, 100))
        end
    end)
    hook.Add("PostDrawTranslucentRenderables", "ZCityZombieSurvival_ExtractionZone", function(depth, sky)
        if depth or sky or CurrentRound() ~= MODE or zb.ROUND_STATE ~= 1 or not GetGlobalBool("ZS_ExtractionRevealed", false) then return end
        render.DrawWireframeBox(vector_origin, angle_zero, GetGlobalVector("ZS_ExtractionMins"), GetGlobalVector("ZS_ExtractionMaxs"), Color(30, 220, 100), false)
    end)
end
