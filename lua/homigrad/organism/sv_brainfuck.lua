local CurTime, IsValid = CurTime, IsValid
local math_max, math_clamp, math_rand, math_random = math.max, math.Clamp, math.Rand, math.random

hook.Remove("Should Fake Up", "BrainfuckFencing")
hook.Remove("Fake", "BrainfuckFencing")
hook.Remove("HG_OnOtrub", "BrainfuckFencing")
hook.Remove("RagdollDeath", "BrainfuckStart")
hook.Remove("Org Clear", "BrainfuckClear")
hook.Remove("Org Think", "BrainfuckThink")
hook.Remove("HomigradDamage", "BrainfuckFencing")

hg.applySpasm = nil
hg.getRandomSpasm = nil

local FENCING_DURATION = 3.8
local FENCING_FADE = 0.45
local FENCING_RECENT_DAMAGE = 1.5
local FENCING_HEAVY_DURATION = 0.18
local FENCING_HEAVY_FORCE = 15
local SHAKE_REFRESH_MIN = 0.035
local SHAKE_REFRESH_MAX = 0.095

local fencingOffsets = {
	["male"] = {
		[1] = Angle(6.540, 90.000, 90.000),
		[2] = Angle(-37.045, -105.045, -85.963),
		[3] = Angle(-44.859, -61.829, -55.931),
		[4] = Angle(-25.275, -157.402, -8.719),
		[5] = Angle(18.369, 160.064, 98.145),
		[6] = Angle(-28.958, 53.028, 34.571),
		[7] = Angle(-1.339, -1.693, 74.846),
		[8] = Angle(-14.129, -96.146, -48.883),
		[9] = Angle(-8.891, -78.821, -46.443),
		[10] = Angle(12.777, 89.905, -90.156),
		[11] = Angle(-31.164, -86.388, -52.031),
		[12] = Angle(38.609, -100.609, -77.015),
		[13] = Angle(-5.608, -92.318, -84.065),
		[14] = Angle(-30.825, -75.116, -60.820)
	},
	["female"] = {
		[1] = Angle(11.243, 90.000, 90.000),
		[2] = Angle(-33.726, -98.938, -84.097),
		[3] = Angle(-41.284, -68.324, -56.945),
		[4] = Angle(-25.633, -164.044, -9.989),
		[5] = Angle(16.043, 150.152, 101.607),
		[6] = Angle(-30.158, 60.254, 34.493),
		[7] = Angle(-4.705, 9.362, 72.585),
		[8] = Angle(-13.971, -93.535, -48.900),
		[9] = Angle(-8.086, -76.238, -46.278),
		[10] = Angle(12.777, 90.000, -90.000),
		[11] = Angle(-31.007, -89.000, -52.020),
		[12] = Angle(39.416, -103.343, -77.216),
		[13] = Angle(-5.209, -92.337, -84.082),
		[14] = Angle(-30.571, -75.143, -60.742)
	}
}

local armBones = {[2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true}
local spineBones = {[1] = 0.18}

local function hasNoHead(owner, rag, org)
	return org.noHead or org.headamputated
		or IsValid(owner) and (owner.noHead or owner.headamputated)
		or IsValid(rag) and (rag.noHead or rag.headamputated)
end

local function getRagdoll(owner)
	if not IsValid(owner) then return end
	if owner:GetClass() == "prop_ragdoll" then return owner end
	if not owner:IsPlayer() then return end

	if IsValid(owner.FakeRagdoll) then return owner.FakeRagdoll end

	local fakeRag = owner:GetNWEntity("FakeRagdoll")
	if IsValid(fakeRag) then return fakeRag end

	local deathRag = owner:GetNWEntity("RagdollDeath")
	if IsValid(deathRag) then return deathRag end
end

local function getBrainSeverity(org)
	local lobes = math.min(org.brainFrontal or 0, 0.2)
		+ math.min(org.brainParietal or 0, 0.2)
		+ math.min(org.brainTemporal or 0, 0.2)
		+ math.min(org.brainOccipital or 0, 0.2)

	return math_clamp(math_max(org.brain or 0, lobes), 0, 1)
end

local function startFencing(org, duration, strength)
	if not org then return end

	local time = CurTime()
	if not org.fencingEnd or time >= org.fencingEnd then
		org.fencingHeavyEnd = time + FENCING_HEAVY_DURATION
	end

	org.fencingStart = time
	org.fencingEnd = time + (duration or FENCING_DURATION)
	org.fencingStrength = math_clamp(strength or 0.75, 0.55, 1)
end

function hg.applyFencingToPlayer(ply, durationOrOrg)
	if not IsValid(ply) then return end

	local org = istable(durationOrOrg) and durationOrOrg or ply.organism
	if not org then return end

	local duration = isnumber(durationOrOrg) and durationOrOrg or FENCING_DURATION
	startFencing(org, duration, 0.75 + getBrainSeverity(org) * 0.25)
end

local function clearFencing(org, rag)
	if org then
		org.fencingStart = nil
		org.fencingEnd = nil
		org.fencingHeavyEnd = nil
		org.fencingStrength = nil
	end

	if IsValid(rag) then rag.fencingShake = nil end
end

local function getShake(rag, physBone, scale, seizure)
	local time = CurTime()
	rag.fencingShake = rag.fencingShake or {}

	local shake = rag.fencingShake[physBone]
	if not shake or time >= shake.next then
		local amplitude = seizure and (armBones[physBone] and 2.2 or 0.65) or (armBones[physBone] and 0.45 or 0.09)
		local burst = math_random(100) <= (seizure and 28 or 14) and math_rand(1.35, seizure and 3.4 or 2.8) or 1

		shake = {
			next = time + math_rand(seizure and 0.025 or SHAKE_REFRESH_MIN, seizure and 0.065 or SHAKE_REFRESH_MAX),
			p = shake and shake.p or 0,
			y = shake and shake.y or 0,
			r = shake and shake.r or 0,
			tp = math_rand(-amplitude, amplitude) * burst * scale,
			ty = math_rand(-amplitude, amplitude) * burst * scale,
			tr = math_rand(-amplitude * 0.35, amplitude * 0.35) * burst * scale
		}

		rag.fencingShake[physBone] = shake
	end

	shake.p = shake.p + (shake.tp - shake.p) * 0.38
	shake.y = shake.y + (shake.ty - shake.y) * 0.38
	shake.r = shake.r + (shake.tr - shake.r) * 0.38

	return shake.p, shake.y, shake.r
end

local function processFencing(rag, org, scale, seizure)
	if not IsValid(rag) or not hg.ShadowControl then return end

	local reference = rag:GetPhysicsObjectNum(0)
	if not IsValid(reference) then return end

	local model = string.lower(rag:GetModel() or "")
	local offsets = string.find(model, "female", 1, true) and fencingOffsets.female or fencingOffsets.male
	local referenceAng = reference:GetAngles()
	local force = (seizure and 900 or 450) + (seizure and 1100 or 750) * scale
	local damping = (seizure and 28 or 18) + (seizure and 55 or 42) * scale

	for physBone, baseAngle in pairs(offsets) do
		local realPhysBone = hg.realPhysNum and hg.realPhysNum(rag, physBone) or physBone
		local phys = rag:GetPhysicsObjectNum(realPhysBone or physBone)
		if not IsValid(phys) then continue end

		local boneForce = force
		local boneDamping = damping
		local spineMultiplier = spineBones[physBone]

		if spineMultiplier then
			boneForce = boneForce * spineMultiplier
			boneDamping = boneDamping * 0.35
		elseif not armBones[physBone] then
			boneForce = boneForce * 0.65
			boneDamping = boneDamping * 0.65
		end

		local shakeP, shakeY, shakeR = getShake(rag, physBone, scale, seizure)
		local targetLocal = Angle(baseAngle.p + shakeP, baseAngle.y + shakeY, baseAngle.r + shakeR)
		local _, targetWorld = LocalToWorld(vector_origin, targetLocal, vector_origin, referenceAng)

		hg.ShadowControl(rag, physBone, 0.07, targetWorld, boneForce, boneDamping, vector_origin, 0, 0)
	end

	if org.fencingHeavyEnd and CurTime() < org.fencingHeavyEnd then
		for i = 0, rag:GetPhysicsObjectCount() - 1 do
			local phys = rag:GetPhysicsObjectNum(i)
			if IsValid(phys) then
				phys:ApplyForceCenter(Vector(0, 0, -phys:GetMass() * FENCING_HEAVY_FORCE))
			end
		end
	else
		org.fencingHeavyEnd = nil
	end
end

local function shouldStartFromTrauma(org)
	if not org then return false end

	local recentHeadDamage = org.fencingBrainDamage
		and CurTime() - org.fencingBrainDamage <= FENCING_RECENT_DAMAGE

	return recentHeadDamage or ((org.consciousness or 1) <= 0.4 and getBrainSeverity(org) > 0.01)
end

hook.Add("HomigradDamage", "BrainfuckFencing", function(victim, dmgInfo, hitgroup)
	local ply = IsValid(victim) and victim:IsPlayer() and victim or hg.RagdollOwner and hg.RagdollOwner(victim)
	if not IsValid(ply) or hitgroup ~= HITGROUP_HEAD or not dmgInfo or dmgInfo:GetDamage() <= 0 then return end

	local org = ply.organism
	if not org then return end

	org.fencingBrainDamage = CurTime()
end)

hook.Add("HG_OnOtrub", "BrainfuckFencing", function(ply)
	if not IsValid(ply) or not shouldStartFromTrauma(ply.organism) then return end
	hg.applyFencingToPlayer(ply)
end)

hook.Add("Fake", "BrainfuckFencing", function(ply)
	if not IsValid(ply) or not shouldStartFromTrauma(ply.organism) then return end
	hg.applyFencingToPlayer(ply)
end)

hook.Add("RagdollDeath", "BrainfuckStart", function(ply, rag)
	if not IsValid(rag) then return end

	local org = rag.organism or IsValid(ply) and ply.organism
	if not org or hasNoHead(ply, rag, org) then return end

	local headDamage = shouldStartFromTrauma(org)
		or (org.brain or 0) > 0.01
		or (org.skull or 0) > 0.05
		or org.dmgstack and org.dmgstack[HITGROUP_HEAD]

	if headDamage then
		startFencing(org, FENCING_DURATION, 0.75 + getBrainSeverity(org) * 0.25)
	end
end)

hook.Add("Org Think", "BrainfuckThink", function(owner, passedOrg)
	if not IsValid(owner) then return end

	local org = passedOrg or owner.organism
	if not org then return end

	local rag = getRagdoll(owner)
	if org.seizureActive and CurTime() < (org.seizureEnd or 0) then
		if hasNoHead(owner, rag, org) or not IsValid(rag) then return end
		processFencing(rag, org, 1, true)
		return
	end

	if not org.fencingEnd then return end

	if hasNoHead(owner, rag, org) or CurTime() >= org.fencingEnd then
		clearFencing(org, rag)
		return
	end

	if not IsValid(rag) then return end

	local remaining = org.fencingEnd - CurTime()
	local scale = org.fencingStrength or 0.75
	if remaining < FENCING_FADE then scale = scale * math_clamp(remaining / FENCING_FADE, 0, 1) end

	processFencing(rag, org, scale, false)
end)

hook.Add("Org Clear", "BrainfuckClear", function(org)
	if not org then return end
	clearFencing(org, IsValid(org.owner) and getRagdoll(org.owner) or nil)
	org.fencingBrainDamage = nil
end)
