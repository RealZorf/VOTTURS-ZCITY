local enabled = CreateClientConVar("hg_player_occlusion", "1", true, false, "Skip drawing players who are behind walls", 0, 1)
local fullHide = CreateClientConVar("hg_player_occlusion_full", "1", true, false, "Also hide their weapons, armor, and third-person gun animations", 0, 1)
local checksPerFrame = CreateClientConVar("hg_player_occlusion_checks", "6", true, false, "How many players to wall-check each frame", 1, 60)
local checkDelay = CreateClientConVar("hg_player_occlusion_delay", "0.01", true, false, "Minimum seconds between wall checks for one player", 0.01, 5)
local hideDelay = CreateClientConVar("hg_player_occlusion_hide_delay", "0", true, false, "Seconds to wait before hiding someone behind a wall", 0, 1)
local sideWidth = CreateClientConVar("hg_player_occlusion_side", "2", true, false, "How far left/right traces reach around a player", 0, 10)
local topHeight = CreateClientConVar("hg_player_occlusion_top", "0.6", true, false, "How high the head traces go on a player", 0, 10)

local cache = setmetatable({}, {__mode = "k"})
local queued = setmetatable({}, {__mode = "k"})
local queue, queueIndex, queueEnd = {}, 1, 0
local dirty = false
local scanSerial = 0
local lastViewEntity
local lastViewX, lastViewY, lastViewZ

local up = Vector(0, 0, 1)
local points = {}
local traceData = {mask = MASK_VISIBLE, filter = {}}
local closeDistanceSqr = 96 * 96

local function getData(ply)
	local data = cache[ply]
	if data then return data end

	data = {visible = true, nextCheck = 0, hiddenSince = nil, lastVisiblePoint = 1}
	cache[ply] = data
	dirty = true
	return data
end

local function setHidden(ply, hidden)
    if hidden then
        ply.HG_WallHidden = true
        ply.NotSeen = fullHide:GetBool() or false
        return
    end

    if not ply.HG_WallHidden then return end
    ply.HG_WallHidden = nil
    ply.NotSeen = false
end

local function getCheckInterval(data, distanceSqr)
	local delay
	if distanceSqr < 700 * 700 then
		delay = 0.03
	elseif distanceSqr < 1800 * 1800 then
		delay = 0.07
	elseif distanceSqr < 3500 * 3500 then
		delay = data.visible and 0.15 or 0.3
	else
		delay = data.visible and 0.25 or 0.5
	end

	return math.max(checkDelay:GetFloat(), delay)
end

local function queuePlayer(ply, data, now, distanceSqr)
	if data.nextCheck > now or queued[ply] then return end

	data.nextCheck = now + getCheckInterval(data, distanceSqr)
	queueEnd = queueEnd + 1
	queue[queueEnd] = ply
	queued[ply] = true
	dirty = true
end

local function getPlayerDimensions(ply, data)
    local model = ply:GetModel()
    local scale = ply:GetModelScale()
    if data.boundsModel == model and data.boundsScale == scale then
        return data.height, data.halfWidth
    end

    local mins, maxs = ply:GetModelBounds()
    if not isvector(mins) or not isvector(maxs) then
        data.height, data.halfWidth = 72, 16
    else
        data.height = math.max(maxs.z - mins.z, 32)
        data.halfWidth = math.max(maxs.x - mins.x, maxs.y - mins.y, 16) * 0.5
    end

    data.boundsModel = model
    data.boundsScale = scale
    return data.height, data.halfWidth
end

local function checkOcclusion(ply, data, origin)
    local center = ply:WorldSpaceCenter()
    if origin:DistToSqr(center) <= closeDistanceSqr then return true end

    local height, halfWidth = getPlayerDimensions(ply, data)
    local lower = center - up * math.min(height * 0.3, 28)

	points[1] = center
	points[2] = center + up * math.min(height * 0.35, 36)
	points[3] = lower

	local pointCount = 3
	local width = sideWidth:GetFloat()

	if width > 0 then
		local side = (center - origin):Cross(up)
        if side:LengthSqr() > 0.001 then
            side:Normalize()
            local offset = side * (halfWidth * width)
            local top = center + up * (height * topHeight:GetFloat())

			points[4], points[5] = center + offset, center - offset
			points[6], points[7] = top + offset, top - offset
			points[8], points[9] = lower + offset, lower - offset
			pointCount = 9
		end
	end

	traceData.start = origin
	traceData.filter[1] = LocalPlayer()
	traceData.filter[2] = GetViewEntity()
	traceData.filter[3] = ply
	local activeWeapon = ply:GetActiveWeapon()
	traceData.filter[4] = IsValid(activeWeapon) and activeWeapon or nil

	local first = math.Clamp(data.lastVisiblePoint or 1, 1, pointCount)
	for step = 0, pointCount - 1 do
		local i = ((first + step - 1) % pointCount) + 1
        traceData.endpos = points[i]

        local trace = util.TraceLine(traceData)
        if trace.StartSolid or not trace.Hit or trace.Entity == ply then
            data.lastVisiblePoint = i
            return true
		end
	end

	return false
end

local function applyResult(ply, data, now, visible)
	if visible then
		data.visible = true
		data.hiddenSince = nil
		setHidden(ply, false)
		return
	end

	data.hiddenSince = data.hiddenSince or now
	if now - data.hiddenSince >= hideDelay:GetFloat() then
		data.visible = false
		setHidden(ply, true)
	end
end

local function processQueue(origin, now, serial)
	local processed, limit = 0, checksPerFrame:GetInt()

	while processed < limit and queueIndex <= queueEnd do
		local ply = queue[queueIndex]
		queue[queueIndex] = nil
		queueIndex = queueIndex + 1
		queued[ply] = nil

        if IsValid(ply) then
            local data = cache[ply]
            if data and data.seenSerial == serial then
                applyResult(ply, data, now, checkOcclusion(ply, data, origin))
                processed = processed + 1
			end
		end
	end

	if queueIndex > queueEnd then
		queue, queueIndex, queueEnd = {}, 1, 0
	end
end

local function resetForViewChange(viewEnt, origin)
    local moved = false
    if lastViewX then
        local x, y, z = origin.x - lastViewX, origin.y - lastViewY, origin.z - lastViewZ
        moved = x * x + y * y + z * z > 512 * 512
    end

    local changed = lastViewEntity ~= viewEnt or moved
    lastViewEntity = viewEnt
    lastViewX, lastViewY, lastViewZ = origin.x, origin.y, origin.z
    if not changed then return end

    for _, data in pairs(cache) do
        data.visible = true
        data.hiddenSince = nil
        data.nextCheck = 0
        data.seenSerial = nil
    end

    queued = setmetatable({}, {__mode = "k"})
    queue, queueIndex, queueEnd = {}, 1, 0
end

local function resetState()
    lastViewEntity = nil
    lastViewX, lastViewY, lastViewZ = nil, nil, nil
    if not dirty then return end

	for ply in pairs(cache) do
		if IsValid(ply) then
			if ply.HG_WallHidden then ply.NotSeen = false end
			ply.HG_WallHidden = nil
		end
	end

	cache = setmetatable({}, {__mode = "k"})
	queued = setmetatable({}, {__mode = "k"})
	queue, queueIndex, queueEnd = {}, 1, 0
	dirty = false
end

hook.Add("HG.OverrideNotSeen", "HG.PlayerOcclusion", function(ent)
	if enabled:GetBool() and fullHide:GetBool() and ent.HG_WallHidden then
		ent.NotSeen = true
	end
end)

hook.Add("PrePlayerDraw", "HG.PlayerOcclusion", function(ply)
	if enabled:GetBool() and ply.HG_WallHidden then
		return true
	end
end)

hook.Add("Think", "HG.PlayerOcclusion", function()
	if not enabled:GetBool() or (g_VR and g_VR.active) then
		resetState()
		return
	end

	local seen = hg.seenents
	if not seen then return end

	local lp = LocalPlayer()
	if not IsValid(lp) then return end

	local view = render.GetViewSetup()
	if not view or not isvector(view.origin) then return end

	local now = CurTime()
    local origin = view.origin
    local viewEnt = GetViewEntity()

    resetForViewChange(viewEnt, origin)
    scanSerial = scanSerial + 1
    local previousSerial = scanSerial - 1

    for i = 1, #seen do
        local ply = seen[i]
        if not IsValid(ply) then
            continue
        end

        if not ply:IsPlayer() or ply == lp or ply == viewEnt or not ply:Alive() or IsValid(ply.FakeRagdoll) then
            local oldData = cache[ply]
            if oldData then
                oldData.visible, oldData.hiddenSince = true, nil
                oldData.nextCheck = 0
                setHidden(ply, false)
            end
            continue
        end

        local data = getData(ply)
        if data.seenSerial ~= previousSerial then
            data.visible, data.hiddenSince = true, nil
            data.nextCheck = 0
            setHidden(ply, false)
        end
        data.seenSerial = scanSerial

        if queued[ply] or data.nextCheck > now then continue end

		local distanceSqr = origin:DistToSqr(ply:GetPos())

        if distanceSqr <= closeDistanceSqr then
            data.visible, data.hiddenSince = true, nil
            data.nextCheck = now + getCheckInterval(data, distanceSqr)
            setHidden(ply, false)
            continue
        end

        queuePlayer(ply, data, now, distanceSqr)
    end

    processQueue(origin, now, scanSerial)
end)
