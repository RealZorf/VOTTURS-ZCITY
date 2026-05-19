local MODE = MODE

local VORT_MODEL = "models/player/vortigaunt.mdl"
local VORT_ALLOWED_WEAPON = "vort_swep"
local VORT_TEAM = 2
local TEAM_ORDER = {0, 1, VORT_TEAM}
local MAX_TRIANGLE_POINTS = 40
local PLAYER_HULL_MINS = Vector(-16, -16, 0)
local PLAYER_HULL_MAXS = Vector(16, 16, 72)
local SPAWN_PROBE_UP = Vector(0, 0, 48)
local SPAWN_PROBE_DOWN = Vector(0, 0, 256)
local SPAWN_CLEARANCE = Vector(0, 0, 2)
local SPAWN_SURFACE_UP = Vector(0, 0, 64)
local SPAWN_SURFACE_DOWN = Vector(0, 0, 768)
local SPAWN_SUPPORT_RADIUS_FACTOR = 4
local MIN_SPAWN_SUPPORT_RADIUS_SQR = 1024 * 1024
local GROUND_TRACE_MASK = MASK_PLAYERSOLID_BRUSHONLY or MASK_PLAYERSOLID
local SPAWN_LINK_HEIGHT = Vector(0, 0, 32)
local SPAWN_LINK_HULL_MINS = Vector(-12, -12, 0)
local SPAWN_LINK_HULL_MAXS = Vector(12, 12, 52)
local SPAWN_LINK_END_TOLERANCE_SQR = 36 * 36
local MIN_TEAM_SPAWN_DIST_SQR = 1200 * 1200
local MAX_TEAM_SPAWN_DIST_SQR = 3500 * 3500
local TEAM_SPAWN_TARGET_PERCENTILE = 0.75
local VORT_START_HEALTH = 150
local VORT_HEALTH_CAP = 150
local VORT_START_ARMOR = 0
local VORT_ARMOR_CAP = 0
local VORT_REGEN_DELAY = 5
local VORT_REGEN_INTERVAL = 1
local VORT_REGEN_HEALTH = 2
local VORT_REGEN_ARMOR = 0
local VORT_SUPPORT_RADIUS_SQR = 320 * 320
local VORT_SUPPORT_HEALTH_BONUS = 1
local VORT_SUPPORT_ARMOR_BONUS = 0
local VORT_ESSENCE_START = 35
local VORT_ESSENCE_CAP = 100
local VORT_PASSIVE_ESSENCE = 1.25
local VORT_CHORUS_ESSENCE = 4
local VORT_CRITICAL_ESSENCE = 3
local VORT_CHORUS_RADIUS_SQR = 460 * 460
local VORT_SHIELD_DAMAGE_RATIO = 0.22
local VORT_SHIELD_ESSENCE_RATIO = 0.55
local VORT_DEATH_ECHO_MIN_ESSENCE = 45
local VORT_DEATH_ECHO_RADIUS = 360
local VORT_DEATH_ECHO_DAMAGE = 72
local VORT_DEATH_ECHO_HEAL = 22

local function shuffle(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
end

local function vectorKey(vec)
	return string.format("%.2f:%.2f:%.2f", vec.x, vec.y, vec.z)
end

local function extractSpawnPoint(point)
	if isvector(point) then return point end
	if istable(point) and isvector(point.pos) then
		return point.pos
	end
end

local function addUniquePoints(out, seen, points)
	for _, point in ipairs(points or {}) do
		point = extractSpawnPoint(point)
		if not isvector(point) then continue end

		local key = vectorKey(point)
		if seen[key] then continue end

		seen[key] = true
		out[#out + 1] = point
	end
end

local function isValidGroundTrace(tr)
	if not tr or tr.StartSolid or tr.AllSolid or not tr.Hit then
		return false
	end

	if tr.HitSky or tr.HitNoDraw or tr.HitTexture == "**empty**" then
		return false
	end

	if IsValid(tr.Entity) and not tr.Entity:IsWorld() then
		return false
	end

	return util.IsInWorld(tr.HitPos + SPAWN_CLEARANCE)
end

local function traceGroundSurface(pos, filterEnt, upVec, downVec)
	if not isvector(pos) or not util.IsInWorld(pos) then return nil end

	local tr = util.TraceLine({
		start = pos + (upVec or SPAWN_SURFACE_UP),
		endpos = pos - (downVec or SPAWN_SURFACE_DOWN),
		mask = GROUND_TRACE_MASK,
		filter = filterEnt
	})

	if not isValidGroundTrace(tr) then
		return nil
	end

	return tr
end

local function isSafeSpawnPos(pos, filterEnt)
	if not isvector(pos) then return false end
	if not util.IsInWorld(pos + SPAWN_CLEARANCE) then return false end
	if not util.IsInWorld(pos + Vector(0, 0, PLAYER_HULL_MAXS.z - 1)) then return false end

	local groundTrace = traceGroundSurface(pos, filterEnt, Vector(0, 0, 8), Vector(0, 0, 24))
	if not groundTrace then return false end

	local tr = util.TraceHull({
		start = pos + SPAWN_CLEARANCE,
		endpos = pos + SPAWN_CLEARANCE,
		mins = PLAYER_HULL_MINS,
		maxs = PLAYER_HULL_MAXS,
		mask = MASK_PLAYERSOLID,
		filter = filterEnt
	})

	return not tr.StartSolid and not tr.AllSolid and not tr.Hit
end

local function snapSpawnToGround(pos, filterEnt)
	pos = extractSpawnPoint(pos)
	if not isvector(pos) then return nil end

	local tr = traceGroundSurface(pos, filterEnt, SPAWN_PROBE_UP, SPAWN_PROBE_DOWN)
	if not tr then return nil end

	return tr.HitPos
end

local function findNearbySafeSpawn(pos, filterEnt)
	pos = extractSpawnPoint(pos)
	if not isvector(pos) then return nil end

	local grounded = snapSpawnToGround(pos, filterEnt)
	if grounded and isSafeSpawnPos(grounded, filterEnt) then
		return grounded
	end

	for i = 1, 24 do
		local testPos = hg.tpPlayer(pos, nil, i, 0)
		if not isvector(testPos) then continue end

		local groundedTest = snapSpawnToGround(testPos, filterEnt)
		if groundedTest and isSafeSpawnPos(groundedTest, filterEnt) then
			return groundedTest
		end
	end

	return nil
end

local function findSafeMapPoint(points, filterEnt)
	local choices = {}

	for _, point in ipairs(points or {}) do
		local pos = extractSpawnPoint(point)
		if isvector(pos) then
			choices[#choices + 1] = pos
		end
	end

	shuffle(choices)

	for _, pos in ipairs(choices) do
		local safePos = findNearbySafeSpawn(pos, filterEnt)
		if safePos and isSafeSpawnPos(safePos, filterEnt) then
			return safePos
		end
	end
end

local function collectSpawnCandidates()
	local candidates = {}
	local seen = {}

	addUniquePoints(candidates, seen, zb.TranslatePointsToVectors(zb.GetMapPoints("RandomSpawns") or {}))
	addUniquePoints(candidates, seen, zb.TranslatePointsToVectors(zb.GetMapPoints("Spawnpoint") or {}))
	addUniquePoints(candidates, seen, zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_T") or {}))
	addUniquePoints(candidates, seen, zb.TranslatePointsToVectors(zb.GetMapPoints("HMCD_TDM_CT") or {}))

	if #candidates == 0 then
		local fallback = extractSpawnPoint(zb:GetRandomSpawn())
		if isvector(fallback) then
			candidates[1] = fallback
		end
	end

	return candidates
end

local function distSqr(a, b)
	return a:DistToSqr(b)
end

local function areSpawnPointsConnected(a, b)
	if not isvector(a) or not isvector(b) then return false end
	if not util.IsInWorld(a + SPAWN_LINK_HEIGHT) or not util.IsInWorld(b + SPAWN_LINK_HEIGHT) then
		return false
	end

	local tr = util.TraceHull({
		start = a + SPAWN_LINK_HEIGHT,
		endpos = b + SPAWN_LINK_HEIGHT,
		mins = SPAWN_LINK_HULL_MINS,
		maxs = SPAWN_LINK_HULL_MAXS,
		mask = GROUND_TRACE_MASK
	})

	if not tr.Hit then
		return true
	end

	if tr.HitSky or tr.HitNoDraw or tr.HitTexture == "**empty**" then
		return false
	end

	return isvector(tr.HitPos) and distSqr(tr.HitPos, b + SPAWN_LINK_HEIGHT) <= SPAWN_LINK_END_TOLERANCE_SQR
end

local function buildSpawnSupport(points)
	local nearestDists = {}
	local connectivityCache = {}

	for index, point in ipairs(points) do
		local nearestDist = math.huge

		for otherIndex, otherPoint in ipairs(points) do
			if index == otherIndex then continue end

			local candidateDist = distSqr(point, otherPoint)
			if candidateDist < nearestDist then
				nearestDist = candidateDist
			end
		end

		nearestDists[index] = nearestDist
	end

	local sortedNearest = table.Copy(nearestDists)
	table.sort(sortedNearest)

	local medianNearest = sortedNearest[math.max(1, math.ceil(#sortedNearest * 0.5))] or 0
	if medianNearest == math.huge then
		medianNearest = 0
	end

	local supportRadiusSqr = math.max(medianNearest * SPAWN_SUPPORT_RADIUS_FACTOR, MIN_SPAWN_SUPPORT_RADIUS_SQR)
	local supportScores = {}

	for index, point in ipairs(points) do
		local supportCount = 0

		for otherIndex, otherPoint in ipairs(points) do
			if index == otherIndex then continue end

			local keyA = math.min(index, otherIndex)
			local keyB = math.max(index, otherIndex)
			connectivityCache[keyA] = connectivityCache[keyA] or {}

			local connected = connectivityCache[keyA][keyB]
			if connected == nil then
				connected = areSpawnPointsConnected(point, otherPoint)
				connectivityCache[keyA][keyB] = connected
			end

			if connected and distSqr(point, otherPoint) <= supportRadiusSqr then
				supportCount = supportCount + 1
			end
		end

		supportScores[index] = supportCount
	end

	return supportScores, connectivityCache
end

local function isCachedConnected(connectivityCache, points, firstIndex, secondIndex)
	local keyA = math.min(firstIndex, secondIndex)
	local keyB = math.max(firstIndex, secondIndex)
	connectivityCache[keyA] = connectivityCache[keyA] or {}

	local connected = connectivityCache[keyA][keyB]
	if connected == nil then
		connected = areSpawnPointsConnected(points[firstIndex], points[secondIndex])
		connectivityCache[keyA][keyB] = connected
	end

	return connected
end

local function buildSpawnDistanceGoal(points, connectivityCache)
	local distances = {}

	for index, point in ipairs(points) do
		for otherIndex = index + 1, #points do
			if not isCachedConnected(connectivityCache, points, index, otherIndex) then continue end

			distances[#distances + 1] = distSqr(point, points[otherIndex])
		end
	end

	if #distances == 0 then
		for index, point in ipairs(points) do
			for otherIndex = index + 1, #points do
				distances[#distances + 1] = distSqr(point, points[otherIndex])
			end
		end
	end

	if #distances == 0 then
		return MIN_TEAM_SPAWN_DIST_SQR
	end

	table.sort(distances)

	local percentileIndex = math.Clamp(math.ceil(#distances * TEAM_SPAWN_TARGET_PERCENTILE), 1, #distances)
	local goal = distances[percentileIndex] or MIN_TEAM_SPAWN_DIST_SQR

	return math.Clamp(goal, MIN_TEAM_SPAWN_DIST_SQR, MAX_TEAM_SPAWN_DIST_SQR)
end

local function triangleAreaScore(a, b, c)
	return (b - a):Cross(c - a):LengthSqr()
end

local function buildTriangleSample(points)
	if #points <= MAX_TRIANGLE_POINTS then
		return table.Copy(points)
	end

	local sample = table.Copy(points)
	shuffle(sample)

	local trimmed = {}
	for i = 1, MAX_TRIANGLE_POINTS do
		trimmed[i] = sample[i]
	end

	return trimmed
end

local function chooseBestTriangle(points)
	if #points <= 0 then return nil end
	if #points == 1 then return {points[1], points[1], points[1]} end
	if #points == 2 then return {points[1], points[2], points[1]} end

	local sample = buildTriangleSample(points)
	local supportScores, connectivityCache = buildSpawnSupport(sample)
	local distanceGoal = buildSpawnDistanceGoal(sample, connectivityCache)
	local bestDistanceMiss = math.huge
	local bestIsolatedPoints = math.huge
	local bestSupport = -1
	local bestScoreMin = -1
	local bestScoreArea = -1
	local bestScoreTotal = -1
	local bestTriangle

	for i = 1, #sample - 2 do
		local a = sample[i]
		for j = i + 1, #sample - 1 do
			local b = sample[j]
			local ab = distSqr(a, b)
			for k = j + 1, #sample do
				local c = sample[k]
				local ac = distSqr(a, c)
				local bc = distSqr(b, c)
				local isolatedPoints =
					((supportScores[i] or 0) == 0 and 1 or 0) +
					((supportScores[j] or 0) == 0 and 1 or 0) +
					((supportScores[k] or 0) == 0 and 1 or 0)
				local supportScore = (supportScores[i] or 0) + (supportScores[j] or 0) + (supportScores[k] or 0)
				local minDist = math.min(ab, ac, bc)
				local distanceMiss = math.max(distanceGoal - minDist, 0)
				local totalDist = ab + ac + bc
				local areaScore = triangleAreaScore(a, b, c)

				if
					distanceMiss < bestDistanceMiss or
					(distanceMiss == bestDistanceMiss and isolatedPoints < bestIsolatedPoints) or
					(distanceMiss == bestDistanceMiss and isolatedPoints == bestIsolatedPoints and minDist > bestScoreMin) or
					(distanceMiss == bestDistanceMiss and isolatedPoints == bestIsolatedPoints and minDist == bestScoreMin and areaScore > bestScoreArea) or
					(distanceMiss == bestDistanceMiss and isolatedPoints == bestIsolatedPoints and minDist == bestScoreMin and areaScore == bestScoreArea and totalDist > bestScoreTotal) or
					(distanceMiss == bestDistanceMiss and isolatedPoints == bestIsolatedPoints and minDist == bestScoreMin and areaScore == bestScoreArea and totalDist == bestScoreTotal and supportScore > bestSupport)
				then
					bestDistanceMiss = distanceMiss
					bestIsolatedPoints = isolatedPoints
					bestSupport = supportScore
					bestScoreMin = minDist
					bestScoreArea = areaScore
					bestScoreTotal = totalDist
					bestTriangle = {a, b, c}
				end
			end
		end
	end

	return bestTriangle or {sample[1], sample[2], sample[3]}
end

local function isLiveVort(ply)
	return IsValid(ply)
		and ply:IsPlayer()
		and ply:Alive()
		and ply:Team() == VORT_TEAM
		and not (ply.organism and ply.organism.incapacitated)
end

local function isActiveHL3Round()
	return CurrentRound and CurrentRound() == MODE and zb and zb.ROUND_STATE == 1
end

local function enforceVortRoundRestrictions(ply)
	if not IsValid(ply) or ply:Team() ~= VORT_TEAM then return end
	local needsWeaponStrip = false

	if ply:Alive() and not ply:HasWeapon(VORT_ALLOWED_WEAPON) then
		ply:Give(VORT_ALLOWED_WEAPON)
	end

	for _, wep in ipairs(ply:GetWeapons()) do
		local class = IsValid(wep) and wep:GetClass()
		if class and class ~= VORT_ALLOWED_WEAPON then
			needsWeaponStrip = true
			break
		end
	end

	if needsWeaponStrip then
		for _, wep in ipairs(ply:GetWeapons()) do
			local class = IsValid(wep) and wep:GetClass()
			if class and class ~= VORT_ALLOWED_WEAPON then
				ply:StripWeapon(class)
			end
		end
	end

	if ply.RemoveAllAmmo and (ply:GetAmmoCount("Pistol") > 0 or ply:GetAmmoCount("SMG1") > 0 or ply:GetAmmoCount("Buckshot") > 0 or ply:GetAmmoCount("357") > 0 or ply:GetAmmoCount("AR2") > 0 or ply:GetAmmoCount("XBowBolt") > 0 or ply:GetAmmoCount("Grenade") > 0 or ply:GetAmmoCount("RPG_Round") > 0 or ply:GetAmmoCount("slam") > 0) then
		ply:RemoveAllAmmo()
	end

	if ply:Armor() ~= 0 then
		ply:SetArmor(0)
	end

	if ply:Alive() and ply:HasWeapon(VORT_ALLOWED_WEAPON) then
		local active = ply:GetActiveWeapon()
		if not IsValid(active) or active:GetClass() ~= VORT_ALLOWED_WEAPON then
			ply:SelectWeapon(VORT_ALLOWED_WEAPON)
		end
	end
end

local function getVortEssence(ply)
	if not IsValid(ply) then return 0 end
	return ply:GetNWFloat("ZC_HL3_VortEssence", 0)
end

local function getVortEssenceMax(ply)
	if not IsValid(ply) then return VORT_ESSENCE_CAP end
	return ply:GetNWFloat("ZC_HL3_VortEssenceMax", VORT_ESSENCE_CAP)
end

local function setVortEssence(ply, amount)
	if not IsValid(ply) then return 0 end
	local maxEssence = getVortEssenceMax(ply)
	local value = math.Clamp(amount or 0, 0, maxEssence)
	ply:SetNWFloat("ZC_HL3_VortEssence", value)
	return value
end

local function addVortEssence(ply, amount)
	if not isLiveVort(ply) then return 0 end
	return setVortEssence(ply, getVortEssence(ply) + (amount or 0))
end

local function combatCenter(ent)
	if not IsValid(ent) then return vector_origin end
	if ent.WorldSpaceCenter then return ent:WorldSpaceCenter() end
	return ent:GetPos()
end

local function resolvePlayerEntity(ent)
	if not IsValid(ent) then return nil end

	local ragdollOwner = hg and hg.RagdollOwner and hg.RagdollOwner(ent) or nil
	if IsValid(ragdollOwner) then
		return ragdollOwner
	end

	return ent:IsPlayer() and ent or nil
end

function MODE:PrepareTeamSpawns()
	local candidates = collectSpawnCandidates()
	local safeCandidates = {}

	for _, candidate in ipairs(candidates) do
		local safeCandidate = findNearbySafeSpawn(candidate)
		if safeCandidate then
			safeCandidates[#safeCandidates + 1] = safeCandidate
		end
	end

	candidates = #safeCandidates > 0 and safeCandidates or candidates
	local triangle = chooseBestTriangle(candidates)
	if not triangle then return end

	shuffle(triangle)

	self.TeamSpawns = {
		[TEAM_ORDER[1]] = triangle[1],
		[TEAM_ORDER[2]] = triangle[2] or triangle[1],
		[TEAM_ORDER[3]] = triangle[3] or triangle[1]
	}

	self.TeamSpawnCounts = {
		[0] = 0,
		[1] = 0,
		[VORT_TEAM] = 0
	}
end

function MODE:PlacePlayerAtTeamSpawn(ply)
	if not IsValid(ply) then return end
	if not self.TeamSpawns then return end

	local teamID = ply:Team()
	local anchor = self.TeamSpawns[teamID]
	if not anchor then return end

	self.TeamSpawnCounts = self.TeamSpawnCounts or {
		[0] = 0,
		[1] = 0,
		[VORT_TEAM] = 0
	}

	self.TeamSpawnCounts[teamID] = (self.TeamSpawnCounts[teamID] or 0) + 1

	local slot = self.TeamSpawnCounts[teamID]
	local placeAnchor = findNearbySafeSpawn(anchor, ply) or anchor
	self.TeamSpawns[teamID] = placeAnchor

	local placedPos = hg.tpPlayer(placeAnchor, ply, slot, 0)
	if isvector(placedPos) and isSafeSpawnPos(placedPos, ply) then
		return
	end

	local groundedPlacedPos = isvector(placedPos) and findNearbySafeSpawn(placedPos, ply) or nil
	if groundedPlacedPos and isSafeSpawnPos(groundedPlacedPos, ply) then
		ply:SetPos(groundedPlacedPos)
		return
	end

	local fallback = findNearbySafeSpawn(extractSpawnPoint(zb:GetRandomSpawn()), ply)
	if fallback and isSafeSpawnPos(fallback, ply) then
		ply:SetPos(fallback)
	end
end

function MODE:OverrideBalance()
	return true
end

function MODE:GetTargetTeamSizes(playerCount)
	local targets = {
		[0] = 0,
		[1] = 0,
		[VORT_TEAM] = 0
	}

	local distributionOrder = {VORT_TEAM, 0, 1}
	for index = 1, playerCount do
		local teamID = distributionOrder[((index - 1) % #distributionOrder) + 1]
		targets[teamID] = targets[teamID] + 1
	end

	return targets
end

function MODE:ApplyVortBattleState(ply)
	if not IsValid(ply) or ply:Team() ~= VORT_TEAM then return end

	ply:SetNWBool("ZC_HL3_Vort", true)
	ply:SetNWInt("ZC_HL3_VortHealthCap", VORT_HEALTH_CAP)
	ply:SetNWInt("ZC_HL3_VortArmorCap", VORT_ARMOR_CAP)
	ply:SetNWFloat("ZC_HL3_VortEssenceMax", VORT_ESSENCE_CAP)
	ply:SetNWFloat("ZC_HL3_VortEssence", math.max(ply:GetNWFloat("ZC_HL3_VortEssence", 0), VORT_ESSENCE_START))
	ply:SetNWFloat("ZC_HL3_NextRiftAt", ply:GetNWFloat("ZC_HL3_NextRiftAt", 0))
	ply:SetNWFloat("ZC_HL3_NextBlinkAt", ply:GetNWFloat("ZC_HL3_NextBlinkAt", 0))
	ply:SetNWInt("ZC_HL3_VortChorusCount", 0)

	if ply.SetMaxHealth then
		ply:SetMaxHealth(VORT_HEALTH_CAP)
	end

	ply:SetHealth(VORT_START_HEALTH)
	ply:SetArmor(VORT_START_ARMOR)
	ply.ZCHL3NextRegenAt = CurTime() + VORT_REGEN_DELAY
	enforceVortRoundRestrictions(ply)
end

function MODE:ClearVortBattleState(ply)
	if not IsValid(ply) then return end

	local active = ply:GetActiveWeapon()
	local wasHoldingVort = IsValid(active) and active:GetClass() == VORT_ALLOWED_WEAPON

	if ply:HasWeapon(VORT_ALLOWED_WEAPON) then
		ply:StripWeapon(VORT_ALLOWED_WEAPON)
	end

	if ply:Alive() and ply:Team() ~= TEAM_SPECTATOR then
		if not ply:HasWeapon("weapon_hands_sh") then
			ply:Give("weapon_hands_sh")
		end

		if wasHoldingVort and ply:HasWeapon("weapon_hands_sh") then
			ply:SelectWeapon("weapon_hands_sh")
		end
	end

	if ply.AnimResetGestureSlot then
		for slot = 0, 6 do
			ply:AnimResetGestureSlot(slot)
		end
	end

	if ply.AnimRestartMainSequence then
		ply:AnimRestartMainSequence()
	end

	if ply.SetCycle then
		ply:SetCycle(0)
	end

	if ply.SetPlaybackRate then
		ply:SetPlaybackRate(1)
	end

	ply:SetNWBool("ZC_HL3_Vort", false)
	ply:SetNWInt("ZC_HL3_VortHealthCap", 0)
	ply:SetNWInt("ZC_HL3_VortArmorCap", 0)
	ply:SetNWFloat("ZC_HL3_VortEssence", 0)
	ply:SetNWFloat("ZC_HL3_VortEssenceMax", 0)
	ply:SetNWFloat("ZC_HL3_NextRiftAt", 0)
	ply:SetNWFloat("ZC_HL3_NextBlinkAt", 0)
	ply:SetNWInt("ZC_HL3_VortChorusCount", 0)
	ply.ZCHL3NextRegenAt = nil
end

function MODE:AssignTeams()
	local players = {}
	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		players[#players + 1] = ply
	end

	shuffle(players)

	local teamCounts = {
		[0] = 0,
		[1] = 0,
		[VORT_TEAM] = 0
	}
	local teamTargets = self:GetTargetTeamSizes(#players)

	self.VortIndices = {}

	for _, ply in ipairs(players) do
		local targetTeam = VORT_TEAM
		local highestNeed = -math.huge

		for _, teamID in ipairs({VORT_TEAM, 0, 1}) do
			local need = teamTargets[teamID] - teamCounts[teamID]
			if need > highestNeed then
				highestNeed = need
				targetTeam = teamID
			end
		end

		ply:SetTeam(targetTeam)
		teamCounts[targetTeam] = teamCounts[targetTeam] + 1

		if targetTeam == VORT_TEAM then
			self.VortIndices[ply] = teamCounts[targetTeam]
		end
	end
end

util.AddNetworkString("hl3_start")
function MODE:Intermission()
	game.CleanUpMap()

	self:AssignTeams()
	self:PrepareTeamSpawns()

	for _, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end

		ply:SetupTeam(ply:Team())
		self:PlacePlayerAtTeamSpawn(ply)
	end

	net.Start("hl3_start")
	net.Broadcast()
end

function MODE:GiveEquipment()
	timer.Simple(0.1, function()
		local elites = 1
		local medics = 1
		local grenadiers = 1
		local shotgunners = 1
		local snipersC = 1
		local snipersR = 1

		local playersAlive = zb:CheckPlaying()
		local leader = false

		for _, ply in RandomPairs(playersAlive) do
			ply:SetSuppressPickupNotices(true)
			ply.noSound = true
			ply.subClass = nil
			ply.leader = nil
			ply:SetNWString("PlayerRole", "")

			if ply:Team() == VORT_TEAM then
				ply:SetNWString("PlayerRole", "Vortigaunt")
				ply:SetPlayerClass("Vortigaunt")
				ply:StripWeapons()
				ply:RemoveAllAmmo()
				ply:SetModel(VORT_MODEL)
				ply:SetNetVar("Accessories", "")
				self:ClearVortBattleState(ply)
				local beam = ply:Give(VORT_ALLOWED_WEAPON)
				self:ApplyVortBattleState(ply)
				if IsValid(beam) then
					ply:SelectWeapon(VORT_ALLOWED_WEAPON)
				end
			else
				self:ClearVortBattleState(ply)
				local hands = ply:Give("weapon_hands_sh")
				if IsValid(hands) then
					ply:SelectWeapon("weapon_hands_sh")
				end

				if ply:Team() == 1 then
					if elites > 0 and not ply.subClass then
						elites = elites - 1
						ply.subClass = "elite"
						if not leader then
							ply.leader = true
							ply:SetNWString("PlayerRole", "Elite")
							leader = true
						end
					end

					if shotgunners > 0 and not ply.subClass then
						shotgunners = shotgunners - 1
						ply.subClass = "shotgunner"
						ply:SetNWString("PlayerRole", "Shotgunner")
					end

					if snipersC > 0 and (#playersAlive > 6) and not ply.subClass then
						snipersC = snipersC - 1
						ply.subClass = "sniper"
						local points = zb.GetMapPoints("HL2DM_SNIPERSPAWN") or {}
						local sniperSpawn = findSafeMapPoint(points, ply)
						if sniperSpawn then
							ply:SetPos(sniperSpawn)
						end
					end
				else
					if medics > 0 and not ply.subClass then
						medics = medics - 1
						ply.subClass = "medic"
					end

					if grenadiers > 0 and (#playersAlive > 6) and not ply.subClass then
						grenadiers = grenadiers - 1
						ply.subClass = "grenadier"
					end

					if snipersR > 0 and (#playersAlive > 6) and not ply.subClass then
						snipersR = snipersR - 1
						ply.subClass = "sniper"
						local points = zb.GetMapPoints("HL2DM_CROSSBOWSPAWN") or {}
						local sniperSpawn = findSafeMapPoint(points, ply)
						if sniperSpawn then
							ply:SetPos(sniperSpawn)
						end
					end
				end

				local inv = ply:GetNetVar("Inventory", {})
				inv["Weapons"] = inv["Weapons"] or {}
				inv["Weapons"]["hg_sling"] = true
				ply:SetNetVar("Inventory", inv)

				ply:SetPlayerClass(ply:Team() == 1 and "Combine" or "Rebel")
			end

			timer.Simple(0.1, function()
				if not IsValid(ply) then return end

				if ply:Team() == VORT_TEAM then
					self:ApplyVortBattleState(ply)
					enforceVortRoundRestrictions(ply)
				end

				ply.noSound = false
			end)

			ply:SetSuppressPickupNotices(false)
		end
	end)
end

function MODE:RoundThink()
	self.ZCHL3NextRegenThink = self.ZCHL3NextRegenThink or 0
	if self.ZCHL3NextRegenThink > CurTime() then return end

	self.ZCHL3NextRegenThink = CurTime() + VORT_REGEN_INTERVAL

	local aliveVorts = {}
	for _, ply in player.Iterator() do
		if IsValid(ply) and ply:Team() == VORT_TEAM then
			enforceVortRoundRestrictions(ply)
		end

		if isLiveVort(ply) then
			aliveVorts[#aliveVorts + 1] = ply
		end
	end

	for _, ply in ipairs(aliveVorts) do
		local healthCap = ply:GetNWInt("ZC_HL3_VortHealthCap", VORT_HEALTH_CAP)
		local armorCap = ply:GetNWInt("ZC_HL3_VortArmorCap", VORT_ARMOR_CAP)
		local nearbyVorts = 0

		for _, other in ipairs(aliveVorts) do
			if other == ply then continue end
			if other:GetPos():DistToSqr(ply:GetPos()) <= VORT_CHORUS_RADIUS_SQR then
				nearbyVorts = nearbyVorts + 1
			end
		end

		ply:SetNWInt("ZC_HL3_VortChorusCount", nearbyVorts)

		local criticalBonus = ply:Health() <= math.floor(healthCap * 0.35) and VORT_CRITICAL_ESSENCE or 0
		addVortEssence(ply, VORT_PASSIVE_ESSENCE + math.min(nearbyVorts, 3) * VORT_CHORUS_ESSENCE + criticalBonus)

		if (ply.ZCHL3NextRegenAt or 0) > CurTime() then continue end

		local supportBonus = nearbyVorts > 0 and 1 or 0
		if ply:Health() < healthCap then
			ply:SetHealth(math.min(healthCap, ply:Health() + VORT_REGEN_HEALTH + supportBonus * VORT_SUPPORT_HEALTH_BONUS))
		end
	end
end

function MODE:VortDeathEcho(ply)
	if not IsValid(ply) then return end

	local essence = getVortEssence(ply)
	if essence < VORT_DEATH_ECHO_MIN_ESSENCE then return end

	local pos = ply:GetPos() + Vector(0, 0, 38)
	local radius = VORT_DEATH_ECHO_RADIUS + essence * 1.6
	local damage = VORT_DEATH_ECHO_DAMAGE + essence * 0.35

	local fx = EffectData()
	fx:SetOrigin(pos)
	fx:SetScale(2)
	util.Effect("cball_explode", fx, true, true)
	ply:EmitSound("NPC_Vortigaunt.Dispell", 100, 72)

	for _, ent in ipairs(ents.FindInSphere(pos, radius)) do
		if not IsValid(ent) or ent == ply then continue end

		local targetPly = resolvePlayerEntity(ent)
		if IsValid(targetPly) and targetPly:Alive() and targetPly:Team() == VORT_TEAM then
			local healthCap = targetPly:GetNWInt("ZC_HL3_VortHealthCap", VORT_HEALTH_CAP)
			targetPly:SetHealth(math.min(healthCap, targetPly:Health() + VORT_DEATH_ECHO_HEAL))
			addVortEssence(targetPly, math.floor(essence * 0.22))
			continue
		end

		local combatEnt = targetPly or ent
		if IsValid(targetPly) and targetPly:Team() == VORT_TEAM then continue end
		if not (combatEnt:IsPlayer() or combatEnt:IsNPC() or string.find(combatEnt:GetClass() or "", "ragdoll", 1, true)) then continue end

		local entPos = combatCenter(combatEnt)
		local dir = entPos - pos
		if dir:LengthSqr() <= 1 then dir = VectorRand() else dir:Normalize() end

		local dmg = DamageInfo()
		dmg:SetDamageType(bit.bor(DMG_SHOCK, DMG_BLAST, DMG_DISSOLVE))
		dmg:SetDamage(damage)
		dmg:SetAttacker(ply)
		dmg:SetInflictor(ply)
		dmg:SetDamagePosition(entPos)
		dmg:SetDamageForce(dir * 42000)
		combatEnt:TakeDamageInfo(dmg)
	end
end

function MODE:EntityTakeDamage(target, dmgInfo)
	local ply = resolvePlayerEntity(target)
	if not isLiveVort(ply) then return end
	if not dmgInfo or (dmgInfo.GetDamage and dmgInfo:GetDamage() <= 0) then return end

	local damage = dmgInfo:GetDamage()
	local essence = getVortEssence(ply)
	if essence > 0 and damage > 0 then
		local absorbed = math.min(damage * VORT_SHIELD_DAMAGE_RATIO, essence * VORT_SHIELD_ESSENCE_RATIO)
		if absorbed > 0 then
			dmgInfo:SetDamage(math.max(0, damage - absorbed))
			setVortEssence(ply, essence - absorbed / math.max(VORT_SHIELD_ESSENCE_RATIO, 0.01))
		end
	end

	ply.ZCHL3NextRegenAt = CurTime() + VORT_REGEN_DELAY
end

function MODE:PlayerDeath(ply)
	if not IsValid(ply) then return end
	self:VortDeathEcho(ply)
	ply.ZCHL3NextRegenAt = nil
end

util.AddNetworkString("hl3_roundend")
function MODE:EndRound()
	local endround, winnerteam = zb:CheckWinner(self:CheckAlivePlayers())
	if not endround then
		winnerteam = 4
	end

	self:ClearPlayerRoles()
	for _, ply in player.Iterator() do
		self:ClearVortBattleState(ply)
	end

	timer.Simple(2, function()
		net.Start("hl3_roundend")
		net.WriteInt(winnerteam or 4, 3)
		net.Broadcast()
	end)
end

hook.Add("PlayerCanPickupWeapon", "ZC_HL3_VortWeaponLock", function(ply, wep)
	if not isActiveHL3Round() then return end
	if not IsValid(ply) or ply:Team() ~= VORT_TEAM then return end
	if not IsValid(wep) then return false end

	return wep:GetClass() == VORT_ALLOWED_WEAPON
end)

hook.Add("PlayerCanPickupItem", "ZC_HL3_VortArmorLock", function(ply, item)
	if not isActiveHL3Round() then return end
	if not IsValid(ply) or ply:Team() ~= VORT_TEAM then return end
	if not IsValid(item) then return false end

	local class = string.lower(item:GetClass() or "")
	if class == "item_battery" or class == "item_suit" then
		return false
	end
end)
