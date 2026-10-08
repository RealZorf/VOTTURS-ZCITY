-- implemented from https://steamcommunity.com/sharedfiles/filedetails/?id=3276614862
local util, Vector, hook, IsValid, bit = util, Vector, hook, IsValid, bit
local grabdist, grabhdelta = 24, Vector(0, 0, 6)

local ENTITY, MOVE = FindMetaTable("Entity"), FindMetaTable("CMoveData")
local PLAYER = FindMetaTable("Player")
local getMT = ENTITY.GetMoveType
local getVel, getOrigin = MOVE.GetVelocity, MOVE.GetOrigin
local getAABB = PLAYER.GetHull
local hullmult = Vector(1, 1, 0)

local function onladder(tab, ply)
	local tr = util.TraceHull(tab, ply)
	tab.mask = bit.bxor(tab.mask, CONTENTS_PLAYERCLIP)
	if bit.band(tr.Contents, CONTENTS_LADDER) != 0 then return true end
	local sd = util.GetSurfaceData(tr.SurfaceProps)
	if IsValid(sd) and sd.climbable != 0 then return true end

	return false
end

hook.Add("Move", "hg_fixladders", function(ply, mv)
	if not IsValid(ply) then return end
	if bit.band(mv:GetButtons(), IN_JUMP) == IN_JUMP then return end

	if getMT(ply) == MOVETYPE_LADDER then
		if ply:GetInternalVariable("m_vecLadderNormal").z == 1 then
			ply:SetMoveType(MOVETYPE_WALK)
			return
		end
	end

 	if getMT(ply) != MOVETYPE_WALK then return end
	if ply:OnGround() then return end
	local velo = getVel(mv)
	if velo:Length2DSqr() == 0 then return end
	if (velo.z > 0 or velo.z < -50) then return end

	velo.z = 0
	local origin, wishdir = getOrigin(mv), velo:GetNormalized()
	local mins, maxs = getAABB(ply)
	mins:Mul(hullmult)
	maxs:Mul(hullmult)
	local trable = {}
	trable.start = origin
	trable.endpos = origin + wishdir
	trable.mask = MASK_PLAYERSOLID
	trable.collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT
	trable.filter = ply
	trable.mins, trable.maxs = mins, maxs

	local trace = util.TraceHull(trable, ply)
	if (trace.Fraction != 1) then return end

	trable.start = origin - grabhdelta
	trable.endpos = origin - (wishdir * grabdist)
	trace = util.TraceHull(trable, ply)

	if trace.Fraction != 1 and onladder(trable, ply) and trace.HitNormal.z != 1 then
		ply:SetMoveType(MOVETYPE_LADDER)
		ply:SetSaveValue("m_vecLadderNormal", trace.HitNormal)
		trable.mask = MASK_PLAYERSOLID
		trace = util.TraceHull(trable, ply)
		mv:SetOrigin(trace.HitPos)
		return
	end
end)