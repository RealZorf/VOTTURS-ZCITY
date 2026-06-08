zb = zb or {}
zb.ESPPerf = zb.ESPPerf or {}

local ESPPerf = zb.ESPPerf

local esp_range_limit = ConVarExists("zb_esp_range_limit") and GetConVar("zb_esp_range_limit") or CreateClientConVar("zb_esp_range_limit", "0", true, false, "Maximum ESP range in meters (0 = unlimited)", 0, 1000)
local esp_outline_limit = ConVarExists("zb_esp_outline_limit") and GetConVar("zb_esp_outline_limit") or CreateClientConVar("zb_esp_outline_limit", "0", true, false, "Maximum number of player outlines (0 = unlimited)", 0, 40)
local esp_show_outlines = ConVarExists("zb_esp_show_outlines") and GetConVar("zb_esp_show_outlines") or CreateClientConVar("zb_esp_show_outlines", "0", true, false, "Enable or disable player outlines", 0, 1)

local METERS_TO_UNITS = 52.49

local targetCache = {
	frame = -1,
	key = nil,
	localPly = NULL,
	origin = vector_origin,
	targets = {},
}

function ESPPerf.GetMaxDistanceSqr()
	local meters = esp_range_limit:GetFloat()
	if meters <= 0 then return math.huge end

	local units = meters * METERS_TO_UNITS
	return units * units
end

function ESPPerf.GetMaxOutlineCount()
	local configured = esp_outline_limit:GetInt()
	if configured > 0 then return configured end

	return math.huge
end

function ESPPerf.ShouldDrawOutlines()
	return esp_show_outlines:GetBool()
end

function ESPPerf.ShouldDrawHUDThisFrame()
	return true
end

function ESPPerf.GetDistanceMeters(origin, ent)
	if not IsValid(ent) then return 0 end
	return math.floor(origin:Distance(ent:WorldSpaceCenter()) / METERS_TO_UNITS)
end

function ESPPerf.BuildTargets(localPly, shouldDrawFn, getEntityFn, origin, cacheKey)
	if targetCache.frame == FrameNumber() and targetCache.localPly == localPly and targetCache.key == cacheKey then
		return targetCache.targets
	end

	origin = origin or EyePos()
	local maxDistSqr = ESPPerf.GetMaxDistanceSqr()
	local targets = {}

	for _, target in player.Iterator() do
		if not shouldDrawFn(localPly, target) then continue end

		local ent = getEntityFn(target)
		if not IsValid(ent) then continue end

		local distSqr = origin:DistToSqr(ent:WorldSpaceCenter())
		if distSqr > maxDistSqr then continue end

		targets[#targets + 1] = {
			ply = target,
			ent = ent,
			distSqr = distSqr,
		}
	end

	table.sort(targets, function(a, b)
		return a.distSqr < b.distSqr
	end)

	targetCache.frame = FrameNumber()
	targetCache.key = cacheKey
	targetCache.localPly = localPly
	targetCache.origin = origin
	targetCache.targets = targets

	return targets
end

function ESPPerf.AddGroupedOutlines(outline_Add, targets, getColorFn, groupKeyFn)
	if not ESPPerf.ShouldDrawOutlines() then return end
	if #targets == 0 then return end

	local maxOutlines = ESPPerf.GetMaxOutlineCount()
	local grouped = {}
	local outlineTargets = 0

	for i = 1, #targets do
		if outlineTargets >= maxOutlines then break end

		local entry = targets[i]
		local groupKey = groupKeyFn and groupKeyFn(entry.ply, entry.ent) or getColorFn(entry.ply)

		grouped[groupKey] = grouped[groupKey] or { ply = entry.ply, ents = {} }
		grouped[groupKey].ply = entry.ply

		local ents = grouped[groupKey].ents
		ents[#ents + 1] = entry.ent
		outlineTargets = outlineTargets + 1
	end

	for _, group in pairs(grouped) do
		if #group.ents == 0 then continue end
		outline_Add(group.ents, getColorFn(group.ply), OUTLINE_MODE_BOTH)
	end
end
