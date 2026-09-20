hg.WoundNet = {}
local WoundNet = hg.WoundNet

local NET_SYNC = "zc_wound_sync_v1"
local NET_REQUEST = "zc_wound_request_v1"
local PROTOCOL = 1
local OP_BASELINE = 0
local OP_DELTA = 1
local OP_CLEAR = 2
local SEVERITY_SCALE = 16
local SYNC_INTERVAL = 0.25
local MAX_SEQUENCE = 4294967294
local EMPTY = {}

local function nextSequence(value)
    return value % MAX_SEQUENCE + 1
end

local function sequenceIsNewer(value, current)
    local distance = (value - current) % MAX_SEQUENCE
    return distance > 0 and distance < MAX_SEQUENCE / 2
end

function WoundNet.IsWoundKey(key)
    return key == "wounds" or key == "arterialwounds"
end

if SERVER then
    util.AddNetworkString(NET_SYNC)
    util.AddNetworkString(NET_REQUEST)

    local states = {}
    local nextSync = 0
    local syncSerial = 0
    hg.ZCWoundNetGeneration = hg.ZCWoundNetGeneration or 0
    WoundNet.States = states

    local function nextGeneration()
        hg.ZCWoundNetGeneration = nextSequence(hg.ZCWoundNetGeneration)
        return hg.ZCWoundNetGeneration
    end

    local function weakPlayerSet()
        return setmetatable({}, {__mode = "k"})
    end

    local function recipientList(set)
        local recipients = {}
        for ply in pairs(set) do
            if IsValid(ply) and ply:IsPlayer() then
                recipients[#recipients + 1] = ply
            end
        end
        return recipients
    end

    local function startMessage(operation, state, unreliable)
        net.Start(NET_SYNC, unreliable == true)
        net.WriteUInt(PROTOCOL, 4)
        net.WriteUInt(operation, 2)
        net.WriteUInt(state.index, 16)
        net.WriteUInt(state.generation, 32)
        net.WriteUInt(state.revision, 32)
    end

    local function sendClear(state)
        local recipients = recipientList(state.knownViewers)
        if #recipients == 0 then return end

        startMessage(OP_CLEAR, state)
        net.Send(recipients)
    end

    local function discardState(owner, sendRemoval)
        local state = states[owner]
        if not state then return end
        if sendRemoval then sendClear(state) end
        states[owner] = nil
    end

    local function createState(owner, org)
        local state = {
            owner = owner,
            org = org,
            index = owner:EntIndex(),
            generation = nextGeneration(),
            revision = 0,
            nextID = 0,
            scanSerial = 0,
            entries = {},
            seenIDs = {},
            baselineRecipients = {},
            deltaRecipients = {},
            viewers = weakPlayerSet(),
            knownViewers = weakPlayerSet()
        }
        states[owner] = state
        return state
    end

    local function getState(owner, org)
        if not IsValid(owner) or not org then return end

        local state = states[owner]
        if state and state.org ~= org then
            discardState(owner, true)
            state = nil
        end

        return state or createState(owner, org)
    end

    local function resolveOwner(ent)
        if not IsValid(ent) then return end

        local org = ent.organism
        if org and IsValid(org.owner) then return org.owner, org end

        if hg.RagdollOwner then
            local owner = hg.RagdollOwner(ent)
            if IsValid(owner) and owner.organism then return owner, owner.organism end
        end

        return ent, ent.organism
    end

    function WoundNet.Track(owner, org)
        if not IsValid(owner) or not org then return end
        if IsValid(org.owner) then owner = org.owner end
        return getState(owner, org)
    end

    function WoundNet.HandleLegacySet(ent, key, value)
        if not WoundNet.IsWoundKey(key) then return false end
        zb.net.list[ent] = zb.net.list[ent] or {}
        zb.net.list[ent][key] = nil

        if key == "wounds" then
            ent.ZCWoundLegacyWounds = value
        else
            ent.ZCWoundLegacyArterial = value
        end

        local owner, org = resolveOwner(ent)
        local state = getState(owner, org)
        if state then nextSync = math.min(nextSync, CurTime() + 0.05) end
        return true
    end

    function WoundNet.GetLegacyValue(ent, key)
        if not WoundNet.IsWoundKey(key) then return false end

        local owner, org = resolveOwner(ent)
        if org then
            return true, key == "wounds" and org.wounds or org.arterialwounds
        end

        if key == "wounds" then
            return true, ent.ZCWoundLegacyWounds
        end
        return true, ent.ZCWoundLegacyArterial
    end

    function WoundNet.EntityRemoved(ent)
        discardState(ent, true)
        ent.ZCWoundLegacyWounds = nil
        ent.ZCWoundLegacyArterial = nil
    end

    function WoundNet.ResetOwner(owner, org)
        if not IsValid(owner) then return end
        discardState(owner, true)
        if org then createState(owner, org) end
        nextSync = 0
    end

    function WoundNet.ForceOwner(owner)
        local state = states[owner]
        if not state then return end
        for ply in pairs(state.viewers) do
            state.viewers[ply] = nil
        end
        nextSync = 0
    end

    function WoundNet.ForceViewer(viewer)
        if not IsValid(viewer) then return end
        for _, state in pairs(states) do
            state.viewers[viewer] = nil
        end
        nextSync = 0
    end

    local function quantizeSeverity(value)
        return math.Clamp(math.floor((tonumber(value) or 0) * SEVERITY_SCALE + 0.5), 0, 65535)
    end

    local function validWoundID(value)
        value = tonumber(value)
        if not value or value < 1 or value > 4294967294 or value % 1 ~= 0 then return end
        return value
    end

    local function allocateWoundID(state, wound, seen)
        local id = validWoundID(wound.ZCWoundID)
        if id and not seen[id] then
            if id > state.nextID then state.nextID = id end
            return id
        end

        repeat
            state.nextID = state.nextID % 4294967294 + 1
            id = state.nextID
        until not seen[id] and not state.entries[id]

        wound.ZCWoundID = id
        return id
    end

    local function vectorMatches(expectedPresent, x, y, z, value)
        local present = isvector(value)
        if expectedPresent ~= present then return false end
        if not present then return true end
        return x == value.x and y == value.y and z == value.z
    end

    local function angleMatches(entry, value)
        local present = isangle(value)
        if entry.anglePresent ~= present then return false end
        if not present then return true end
        return entry.angleP == value.p and entry.angleY == value.y and entry.angleR == value.r
    end

    local function structureMatches(entry, wound, arterial)
        return entry.arterial == arterial
            and vectorMatches(entry.positionPresent, entry.positionX, entry.positionY, entry.positionZ, wound[2])
            and angleMatches(entry, wound[3])
            and entry.bone == wound[4]
            and vectorMatches(entry.directionPresent, entry.directionX, entry.directionY, entry.directionZ, wound[6])
            and entry.artery == wound[7]
    end

    local function capturePosition(entry, value)
        local present = isvector(value)
        entry.positionPresent = present
        if not present then
            entry.positionX = nil
            entry.positionY = nil
            entry.positionZ = nil
            return
        end

        entry.positionX = value.x
        entry.positionY = value.y
        entry.positionZ = value.z
    end

    local function captureDirection(entry, value)
        local present = isvector(value)
        entry.directionPresent = present
        if not present then
            entry.directionX = nil
            entry.directionY = nil
            entry.directionZ = nil
            return
        end

        entry.directionX = value.x
        entry.directionY = value.y
        entry.directionZ = value.z
    end

    local function captureStructure(entry, wound, arterial, severity)
        entry.arterial = arterial
        entry.severity = severity
        capturePosition(entry, wound[2])

        local ang = wound[3]
        entry.anglePresent = isangle(ang)
        if entry.anglePresent then
            entry.angleP = ang.p
            entry.angleY = ang.y
            entry.angleR = ang.r
        else
            entry.angleP = nil
            entry.angleY = nil
            entry.angleR = nil
        end

        entry.bone = wound[4]
        captureDirection(entry, wound[6])
        entry.artery = wound[7]
    end

    local function scanWounds(state)
        state.scanSerial = state.scanSerial + 1
        local serial = state.scanSerial
        local seen = state.seenIDs
        table.Empty(seen)
        local upserts
        local severityUpdates
        local removals

        local function scanList(wounds, arterial)
            for i = 1, #wounds do
                local wound = wounds[i]
                if not istable(wound) then continue end

                local id = allocateWoundID(state, wound, seen)
                seen[id] = true
                wound.ZCWoundID = id

                local severity = quantizeSeverity(wound[1])
                local entry = state.entries[id]
                if not entry then
                    entry = {}
                    state.entries[id] = entry
                    captureStructure(entry, wound, arterial, severity)
                    upserts = upserts or {}
                    upserts[#upserts + 1] = {wound = wound, arterial = arterial}
                elseif not structureMatches(entry, wound, arterial) then
                    captureStructure(entry, wound, arterial, severity)
                    upserts = upserts or {}
                    upserts[#upserts + 1] = {wound = wound, arterial = arterial}
                elseif entry.severity ~= severity then
                    entry.severity = severity
                    severityUpdates = severityUpdates or {}
                    severityUpdates[#severityUpdates + 1] = {id = id, severity = severity}
                end

                entry.seen = serial
            end
        end

        local org = state.org
        scanList(istable(org.wounds) and org.wounds or EMPTY, false)
        scanList(istable(org.arterialwounds) and org.arterialwounds or EMPTY, true)

        for id, entry in pairs(state.entries) do
            if entry.seen == serial then continue end
            state.entries[id] = nil
            removals = removals or {}
            removals[#removals + 1] = id
        end

        if not upserts and not severityUpdates and not removals then return end

        state.revision = nextSequence(state.revision)
        return {
            upserts = upserts or EMPTY,
            severityUpdates = severityUpdates or EMPTY,
            removals = removals or EMPTY
        }
    end

    local function writeBone(value)
        local numeric = isnumber(value)
        net.WriteBool(numeric)
        if numeric then
            net.WriteInt(math.Clamp(math.floor(value), -32768, 32767), 16)
        else
            net.WriteString(isstring(value) and value or "")
        end
    end

    local function writeWound(wound, arterial)
        net.WriteUInt(wound.ZCWoundID, 32)
        net.WriteBool(arterial)
        net.WriteUInt(quantizeSeverity(wound[1]), 16)

        local pos = wound[2]
        net.WriteBool(isvector(pos))
        if isvector(pos) then net.WriteVector(pos) end

        local ang = wound[3]
        net.WriteBool(isangle(ang))
        if isangle(ang) then net.WriteAngle(ang) end

        writeBone(wound[4])
        net.WriteFloat(tonumber(wound[5]) or CurTime())

        local direction = wound[6]
        net.WriteBool(isvector(direction))
        if isvector(direction) then net.WriteVector(direction) end

        local artery = wound[7]
        net.WriteBool(isstring(artery))
        if isstring(artery) then net.WriteString(artery) end
    end

    local function prepareWoundIDs(state, wounds, arterial)
        local seen = state.seenIDs
        table.Empty(seen)

        local function prepare(woundList)
            for i = 1, #woundList do
                local wound = woundList[i]
                if not istable(wound) then continue end
                local id = allocateWoundID(state, wound, seen)
                wound.ZCWoundID = id
                seen[id] = true
            end
        end

        prepare(wounds)
        prepare(arterial)
    end

    local function sendBaseline(state, recipients)
        if #recipients == 0 or not IsValid(state.owner) then return end

        local org = state.org
        local wounds = istable(org.wounds) and org.wounds or EMPTY
        local arterial = istable(org.arterialwounds) and org.arterialwounds or EMPTY
        prepareWoundIDs(state, wounds, arterial)

        local woundCount = 0
        for i = 1, #wounds do
            if istable(wounds[i]) then woundCount = woundCount + 1 end
        end

        local arterialCount = 0
        for i = 1, #arterial do
            if istable(arterial[i]) then arterialCount = arterialCount + 1 end
        end

        startMessage(OP_BASELINE, state)
        net.WriteUInt(woundCount, 16)
        for i = 1, #wounds do
            local wound = wounds[i]
            if istable(wound) then writeWound(wound, false) end
        end
        net.WriteUInt(arterialCount, 16)
        for i = 1, #arterial do
            local wound = arterial[i]
            if istable(wound) then writeWound(wound, true) end
        end
        net.Send(recipients)
    end

    local function sendDelta(state, recipients, delta)
        if #recipients == 0 or not delta then return end

        local structural = #delta.upserts > 0 or #delta.removals > 0
        startMessage(OP_DELTA, state, not structural)
        net.WriteUInt(#delta.upserts, 16)
        for i = 1, #delta.upserts do
            local item = delta.upserts[i]
            writeWound(item.wound, item.arterial)
        end

        net.WriteUInt(#delta.severityUpdates, 16)
        for i = 1, #delta.severityUpdates do
            local item = delta.severityUpdates[i]
            net.WriteUInt(item.id, 32)
            net.WriteUInt(item.severity, 16)
        end

        net.WriteUInt(#delta.removals, 16)
        for i = 1, #delta.removals do
            net.WriteUInt(delta.removals[i], 32)
        end
        net.Send(recipients)
    end

    local function targetMatchesOwner(target, owner)
        if not IsValid(target) then return false end
        if target == owner then return true end

        if target:IsPlayer() then
            if target:GetNWEntity("FakeRagdoll", NULL) == owner then return true end
            if target:GetNWEntity("RagdollDeath", NULL) == owner then return true end
        end

        if owner:IsPlayer() and target:IsRagdoll() then
            if target:GetNWEntity("ply", NULL) == owner then return true end
            if hg.RagdollOwner and hg.RagdollOwner(target) == owner then return true end
        end

        return false
    end

    local function isRelevant(viewer, state)
        local owner = state.owner
        if not IsValid(viewer) or not IsValid(owner) then return false end
        if viewer == owner then return true end

        local spect = viewer:GetNWEntity("spect", NULL)
        if targetMatchesOwner(spect, owner) then return true end
        if targetMatchesOwner(viewer:GetObserverTarget(), owner) then return true end

        local override = hook.Run("HG_WoundNetRelevant", viewer, owner, state.org)
        if override ~= nil then return override == true end

        if viewer:TestPVS(owner) then return true end
        if owner:IsPlayer() then
            local ragdoll = owner:GetNWEntity("FakeRagdoll", NULL)
            if IsValid(ragdoll) and viewer:TestPVS(ragdoll) then return true end
        end

        return false
    end

    local function syncState(state, players, delta)
        local baselineRecipients = state.baselineRecipients
        local deltaRecipients = state.deltaRecipients
        table.Empty(baselineRecipients)
        table.Empty(deltaRecipients)

        for i = 1, #players do
            local viewer = players[i]
            if isRelevant(viewer, state) then
                if not state.viewers[viewer] then
                    state.viewers[viewer] = true
                    state.knownViewers[viewer] = true
                    baselineRecipients[#baselineRecipients + 1] = viewer
                elseif delta then
                    deltaRecipients[#deltaRecipients + 1] = viewer
                end
            else
                state.viewers[viewer] = nil
            end
        end

        sendBaseline(state, baselineRecipients)
        sendDelta(state, deltaRecipients, delta)
    end

    hook.Add("Think", "ZC_WoundNetSync", function()
        local time = CurTime()
        if nextSync > time then return end
        nextSync = time + SYNC_INTERVAL

        local players = player.GetHumans()
        local organisms = hg.organism and hg.organism.list or EMPTY
        syncSerial = syncSerial + 1

        for owner, org in pairs(organisms) do
            if not IsValid(owner) or not org then continue end
            local state = getState(owner, org)
            state.syncSerial = syncSerial
            local delta = scanWounds(state)
            syncState(state, players, delta)
        end

        for owner, state in pairs(states) do
            if state.syncSerial == syncSerial and IsValid(owner) then continue end
            discardState(owner, true)
        end
    end)

    net.Receive(NET_REQUEST, function(_, ply)
        if not IsValid(ply) then return end
        local index = net.ReadUInt(16)
        local time = CurTime()
        ply.ZCWoundRequestNext = ply.ZCWoundRequestNext or {}
        if (ply.ZCWoundRequestNext[index] or 0) > time then return end
        ply.ZCWoundRequestNext[index] = time + 0.5

        local owner = Entity(index)
        local state = IsValid(owner) and states[owner]
        if not state or not isRelevant(ply, state) then return end

        state.viewers[ply] = true
        state.knownViewers[ply] = true
        sendBaseline(state, {ply})
    end)

    hook.Add("Org Clear", "ZC_WoundNetReset", function(org)
        if org and IsValid(org.owner) then WoundNet.ResetOwner(org.owner, org) end
    end)

    hook.Add("Fake", "ZC_WoundNetFakeBaseline", function(ply)
        WoundNet.ForceOwner(ply)
    end)

    hook.Add("Fake Up", "ZC_WoundNetFakeUpBaseline", function(ply)
        WoundNet.ForceOwner(ply)
    end)

    hook.Add("PostCleanupMap", "ZC_WoundNetCleanup", function()
        while true do
            local owner = next(states)
            if not owner then break end
            discardState(owner, true)
        end
        nextSync = 0
    end)
else
    local states = {}
    local requestTimes = {}
    local knownIndexes = {}
    WoundNet.States = states

    local function requestBaseline(index)
        local time = CurTime()
        if (requestTimes[index] or 0) > time then return end
        requestTimes[index] = time + 0.5

        net.Start(NET_REQUEST)
        net.WriteUInt(index, 16)
        net.SendToServer()
    end

    local function readBone()
        if net.ReadBool() then return net.ReadInt(16) end
        return net.ReadString()
    end

    local function readWound()
        local id = net.ReadUInt(32)
        local arterial = net.ReadBool()
        local wound = {}

        wound[1] = net.ReadUInt(16) / SEVERITY_SCALE
        if net.ReadBool() then wound[2] = net.ReadVector() end
        if net.ReadBool() then wound[3] = net.ReadAngle() end
        wound[4] = readBone()
        wound[5] = net.ReadFloat()
        if net.ReadBool() then wound[6] = net.ReadVector() end
        if net.ReadBool() then wound[7] = net.ReadString() end
        wound.ZCWoundID = id

        return id, arterial, wound
    end

    local function copyWound(target, source, preserveTime)
        local oldTime = target[5]
        for i = 1, 7 do
            target[i] = source[i]
        end
        if preserveTime and oldTime ~= nil then target[5] = oldTime end
        target.ZCWoundID = source.ZCWoundID
        return target
    end

    local function removeWound(array, wound)
        for i = #array, 1, -1 do
            if array[i] == wound then
                table.remove(array, i)
                return
            end
        end
    end

    local function publishState(state)
        local ent = Entity(state.index)
        if not IsValid(ent) then
            state.entity = nil
            return
        end

        state.entity = ent
        ent.wounds = state.wounds
        ent.arterialwounds = state.arterialwounds

        zb.net[state.index] = zb.net[state.index] or {}
        zb.net[state.index].wounds = state.wounds
        zb.net[state.index].arterialwounds = state.arterialwounds

        if ent:IsPlayer() then
            local ragdoll = ent:GetNWEntity("FakeRagdoll", NULL)
            if IsValid(ragdoll) then
                ragdoll.wounds = state.wounds
                ragdoll.arterialwounds = state.arterialwounds
                local ragIndex = ragdoll:EntIndex()
                zb.net[ragIndex] = zb.net[ragIndex] or {}
                zb.net[ragIndex].wounds = state.wounds
                zb.net[ragIndex].arterialwounds = state.arterialwounds
            end
        end

        hook.Run("HG_WoundNetUpdated", ent, state.wounds, state.arterialwounds)
    end

    local function installWound(state, id, arterial, incoming)
        local existing = state.byID[id]
        if existing then
            copyWound(existing.wound, incoming, true)
            if existing.arterial ~= arterial then
                removeWound(existing.arterial and state.arterialwounds or state.wounds, existing.wound)
                local destination = arterial and state.arterialwounds or state.wounds
                destination[#destination + 1] = existing.wound
                existing.arterial = arterial
            end
            return existing.wound
        end

        local destination = arterial and state.arterialwounds or state.wounds
        destination[#destination + 1] = incoming
        state.byID[id] = {wound = incoming, arterial = arterial}
        return incoming
    end

    local function removeWoundID(state, id)
        local existing = state.byID[id]
        if not existing then return end
        removeWound(existing.arterial and state.arterialwounds or state.wounds, existing.wound)
        state.byID[id] = nil
    end

    local function readBaseline(index, generation, revision)
        local oldState = states[index]
        local canReuse = oldState and oldState.generation == generation
        local oldByID = canReuse and oldState.byID
        local wounds = canReuse and oldState.wounds or {}
        local arterialwounds = canReuse and oldState.arterialwounds or {}
        table.Empty(wounds)
        table.Empty(arterialwounds)
        local state = {
            index = index,
            generation = generation,
            revision = revision,
            wounds = wounds,
            arterialwounds = arterialwounds,
            byID = {}
        }

        local function readList(count)
            for i = 1, count do
                local id, arterial, incoming = readWound()
                local old = oldByID and oldByID[id]
                local wound = incoming
                if old and old.arterial == arterial then
                    wound = copyWound(old.wound, incoming, true)
                end

                local destination = arterial and state.arterialwounds or state.wounds
                destination[#destination + 1] = wound
                state.byID[id] = {wound = wound, arterial = arterial}
            end
        end

        readList(net.ReadUInt(16))
        readList(net.ReadUInt(16))
        states[index] = state
        knownIndexes[index] = generation
        publishState(state)
    end

    local function readDelta(index, generation, revision)
        local state = states[index]
        if not state or state.generation ~= generation then
            requestBaseline(index)
            return
        end
        if revision ~= nextSequence(state.revision) then
            if sequenceIsNewer(revision, state.revision) then requestBaseline(index) end
            return
        end

        local upsertCount = net.ReadUInt(16)
        for i = 1, upsertCount do
            local id, arterial, wound = readWound()
            installWound(state, id, arterial, wound)
        end

        local severityCount = net.ReadUInt(16)
        for i = 1, severityCount do
            local id = net.ReadUInt(32)
            local severity = net.ReadUInt(16) / SEVERITY_SCALE
            local existing = state.byID[id]
            if existing then existing.wound[1] = severity end
        end

        local removalCount = net.ReadUInt(16)
        for i = 1, removalCount do
            removeWoundID(state, net.ReadUInt(32))
        end

        state.revision = revision
        publishState(state)
    end

    local function clearState(index, generation)
        local state = states[index]
        local knownGeneration = state and state.generation or knownIndexes[index]
        if knownGeneration ~= generation then return end

        local ent = Entity(index)
        if IsValid(ent) then
            ent.wounds = nil
            ent.arterialwounds = nil
            if ent:IsPlayer() then
                local ragdoll = ent:GetNWEntity("FakeRagdoll", NULL)
                if IsValid(ragdoll) then
                    ragdoll.wounds = nil
                    ragdoll.arterialwounds = nil
                    local ragIndex = ragdoll:EntIndex()
                    if zb.net[ragIndex] then
                        zb.net[ragIndex].wounds = nil
                        zb.net[ragIndex].arterialwounds = nil
                    end
                end
            end
        end
        if zb.net[index] then
            zb.net[index].wounds = nil
            zb.net[index].arterialwounds = nil
        end
        states[index] = nil
        knownIndexes[index] = nil
    end

    net.Receive(NET_SYNC, function()
        if net.ReadUInt(4) ~= PROTOCOL then return end

        local operation = net.ReadUInt(2)
        local index = net.ReadUInt(16)
        local generation = net.ReadUInt(32)
        local revision = net.ReadUInt(32)

        if operation == OP_BASELINE then
            readBaseline(index, generation, revision)
        elseif operation == OP_DELTA then
            readDelta(index, generation, revision)
        elseif operation == OP_CLEAR then
            clearState(index, generation)
        end
    end)

    hook.Add("NotifyShouldTransmit", "ZC_WoundNetPVS", function(ent, shouldTransmit)
        if not shouldTransmit or not IsValid(ent) then return end
        local index = ent:EntIndex()
        if states[index] or knownIndexes[index] or ent:IsPlayer() then
            requestBaseline(index)
        end
    end)

    hook.Add("NetworkEntityCreated", "ZC_WoundNetEntityCreated", function(ent)
        local index = ent:EntIndex()
        local state = states[index]
        if not state then
            if knownIndexes[index] then requestBaseline(index) end
            return
        end
        requestBaseline(index)
    end)

    hook.Add("EntityRemoved", "ZC_WoundNetEntityRemoved", function(ent)
        local index = ent:EntIndex()
        local state = states[index]
        if state and state.entity == ent then
            states[index] = nil
            knownIndexes[index] = state.generation
        end
    end)

    hook.Add("PostCleanupMap", "ZC_WoundNetCleanup", function()
        table.Empty(states)
        table.Empty(requestTimes)
        table.Empty(knownIndexes)
    end)
end
