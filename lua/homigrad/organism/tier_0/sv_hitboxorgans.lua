hg.organism = hg.organism or {}
local Vector = Vector
local util_IntersectRayWithOBB = util.IntersectRayWithOBB
local math_ceil = math.ceil
function hg.organism.Trace(pos, dir, size, maxpen, boxs, center, endDis, organs, ricochetable, funcInput, ...)
	if not istable(boxs) or not isvector(pos) or not isvector(dir) or not isvector(center) then
		return pos, {}, {}, {}, dir, 0, {}
	end
	if dir:LengthSqr() < 1e-8 then
		return Vector(pos), {}, {Vector(pos)}, {Vector(pos)}, dir, 0, {}
	end

	local endDisSqr = (endDis or 0) * (endDis or 0)
	local hitBoxs = {}
	local tracePoses = {}
	local inputHole, outputHole = {}, {}
	local inBody, hitSomething
	local distance = math.Clamp(math_ceil(dir:Length()), 0, 50)
	local distancereal = distance
	dir:Normalize()

	local tracePos = Vector(pos)
	local passing = 0
	local tries = 20
	while passing < distance and tries > 0 do
		tries = tries - 1
		if maxpen ~= 0 and passing >= maxpen then break end

		local frac, iHit, hit = 1, nil, nil
		for i = 1, #boxs do
			if hitBoxs[i] then continue end
			local box = boxs[i]
			if box[6] and not organs[box[6]] then continue end
			local hit_, _, frac_ = util_IntersectRayWithOBB(tracePos, dir * 100, box[1], box[2], box[3], box[4])
			if hit_ and frac_ < frac then
				iHit, frac, hit = i, frac_, hit_
			end
		end

		frac = math.max(frac, 0.001)
		dir = dir:GetNormalized() * frac * 100

		if iHit then
			hitBoxs[iHit] = true
			hitSomething = true
			local dirSub = funcInput(boxs[iHit], tracePos, nil, ...)
			if dirSub then
				distance = distance - dirSub * distance
			end
		end

		passing = passing + 100 * frac

		if not inBody and iHit then
			inBody = true
			inputHole[#inputHole + 1] = Vector(tracePos)
		end
		if inBody and not iHit then
			outputHole[#outputHole + 1] = Vector(tracePos)
			inBody = nil
		end

		if hit then
			tracePos:Set(hit)
		end

		tracePoses[#tracePoses + 1] = Vector(tracePos)
		if passing >= distance or tracePos:DistToSqr(center) > endDisSqr then break end
	end

	if not hitSomething then
		inputHole[1] = Vector(pos)
		outputHole[1] = Vector(tracePos)
	end

	dir:Normalize()
	return tracePos, hitBoxs, inputHole, outputHole, dir, distancereal, tracePoses
end

function hg.organism.BlastTrace(pos, size, dmg, boxs, organs, funcInput, ...)
	if not istable(boxs) then return end
	for i = 1, #boxs do
		local box = boxs[i]
		local dist = math.max(pos:Distance(box[1]), 1)
		local amt = dmg / dist * (1 - (organs[box[6]] and organs[box[6]][box[7]][2] or 0)) / size
		local dirSub = funcInput(box, amt, ...)
		size = size * (dirSub * 0.01 + 1)
	end
end