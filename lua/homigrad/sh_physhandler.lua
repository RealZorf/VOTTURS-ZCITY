local function SetAbsVelocity(pEntity, vAbsVelocity)
	if (pEntity:GetInternalVariable("m_vecAbsVelocity") ~= vAbsVelocity) then
		-- The abs velocity won't be dirty since we're setting it here
		pEntity:RemoveEFlags(EFL_DIRTY_ABSVELOCITY)

		-- All children are invalid, but we are not
		local tChildren = pEntity:GetChildren()

		for i = 1, #tChildren do
			tChildren[i]:AddEFlags(EFL_DIRTY_ABSVELOCITY)
		end

		pEntity:SetSaveValue("m_vecAbsVelocity", vAbsVelocity)

		-- NOTE: Do *not* do a network state change in this case.
		-- m_vVelocity is only networked for the player, which is not manual mode
		local pMoveParent = pEntity:GetMoveParent()

		if (pMoveParent:IsValid()) then
			-- First subtract out the parent's abs velocity to get a relative
			-- velocity measured in world space
			-- Transform relative velocity into parent space
			-- FIXME
			--pEntity:SetSaveValue("m_vecVelocity", (vAbsVelocity - pMoveParent:_GetAbsVelocity()):IRotate(pMoveParent:EntityToWorldTransform()))
			pEntity:SetSaveValue("velocity", vAbsVelocity)
		else
			pEntity:SetSaveValue("velocity", vAbsVelocity)
		end
	end
end

------------------------
-- Might be useful
------------------------
local inf,ninf,ind = 1/0,-1/0,(1/0)/(1/0)

--(ind==ind) == false :(. This should do though. >= and <= because you never know :3

function math.BadNumber(v) 
	return not v or v==inf or v==ninf or not (v>=0 or v<=0) or tostring(v) == "nan"
end

local max_reasonable_pos 		= 25000
local min_reasonable_pos 		= -25000

hg = hg or {}
hg._queuedCollisionRuleRefresh = hg._queuedCollisionRuleRefresh or {}
hg._queuedCollisionGroupChanges = hg._queuedCollisionGroupChanges or {}
hg._queuedCustomCollisionChecks = hg._queuedCustomCollisionChecks or {}

function hg.QueueCollisionRulesChanged(ent)
	if not IsValid(ent) then return end
	hg._queuedCollisionRuleRefresh[ent] = true
end

function hg.QueueSetCollisionGroup(ent, collisionGroup)
	if not IsValid(ent) then return end
	hg._queuedCollisionGroupChanges[ent] = collisionGroup
end

function hg.QueueSetCustomCollisionCheck(ent, enabled)
	if not IsValid(ent) then return end
	hg._queuedCustomCollisionChecks[ent] = enabled and true or false
end

function hg.SafeSetCustomCollisionCheck(ent, enabled)
	if not IsValid(ent) then return end

	if hg.QueueSetCustomCollisionCheck then
		hg.QueueSetCustomCollisionCheck(ent, enabled)
	else
		ent:SetCustomCollisionCheck(enabled)
	end
end

function hg.SafeSetCollisionGroup(ent, collisionGroup)
	if not IsValid(ent) then return end

	if hg.QueueSetCollisionGroup then
		hg.QueueSetCollisionGroup(ent, collisionGroup)
	else
		ent:SetCollisionGroup(collisionGroup)
	end
end

function hg.SafeCollisionRulesChanged(ent)
	if not IsValid(ent) then return end

	if hg.QueueCollisionRulesChanged then
		hg.QueueCollisionRulesChanged(ent)
	else
		ent:CollisionRulesChanged()
	end
end

function hg.ApplyCollisionRulesChangedNow(ent)
	if not IsValid(ent) then return end

	hg._queuedCollisionRuleRefresh[ent] = nil
	ent:CollisionRulesChanged()
end

function hg.ApplySetCollisionGroupNow(ent, collisionGroup, refreshRules)
	if not IsValid(ent) then return end

	hg._queuedCollisionGroupChanges[ent] = nil

	if ent:GetCollisionGroup() ~= collisionGroup then
		ent:SetCollisionGroup(collisionGroup)
	end

	if refreshRules ~= false then
		hg.ApplyCollisionRulesChangedNow(ent)
	end
end

function hg.ApplySetCustomCollisionCheckNow(ent, enabled, refreshRules)
	if not IsValid(ent) then return end

	hg._queuedCustomCollisionChecks[ent] = nil
	enabled = enabled and true or false

	if ent:GetCustomCollisionCheck() ~= enabled then
		ent:SetCustomCollisionCheck(enabled)
	end

	if refreshRules ~= false then
		hg.ApplyCollisionRulesChangedNow(ent)
	end
end

if SERVER then
	hook.Add("Tick", "hg_queue_collision_rules_changed", function()
		for ent, enabled in pairs(hg._queuedCustomCollisionChecks) do
			hg._queuedCustomCollisionChecks[ent] = nil

			if IsValid(ent) and ent:GetCustomCollisionCheck() ~= enabled then
				ent:SetCustomCollisionCheck(enabled)
			end
		end

		for ent, collisionGroup in pairs(hg._queuedCollisionGroupChanges) do
			hg._queuedCollisionGroupChanges[ent] = nil

			if IsValid(ent) and ent:GetCollisionGroup() ~= collisionGroup then
				ent:SetCollisionGroup(collisionGroup)
			end
		end

		for ent in pairs(hg._queuedCollisionRuleRefresh) do
			hg._queuedCollisionRuleRefresh[ent] = nil

			if IsValid(ent) then
				ent:CollisionRulesChanged()
			end
		end
	end)
end

function IsReasonable( pos )
	local posY, posZ = pos.y, pos.z

	if (pos.x > max_reasonable_pos or posY < min_reasonable_pos or
		posY > max_reasonable_pos or posZ < min_reasonable_pos or
		posZ > max_reasonable_pos) then
		return false
	end
	return true
end

hook.Add("OnCrazyPhysics","crazy_physics",function(ent, physobj)--function(a,msg,c,d, r,g,b)
	if ent.zcity_collision_proxy or IsValid(ent.hg_collision_source) then
		if IsValid(physobj) then
			physobj:EnableMotion(false)
			physobj:Sleep()
		end

		ent:SetVelocity(vector_origin)
		ent:SetLocalVelocity(vector_origin)
		ent:SetLocalAngularVelocity(angle_zero)
		return
	end

	local a = ent:GetPos()
	local angles = ent:GetAngles()
	local x, y, z = a.x, a.y, a.z
	local p, yaw, r = angles.x, angles.y, angles.z

	local badang = math.BadNumber(p) or p==0
				or math.BadNumber(yaw) or yaw==0
				or math.BadNumber(r) or r==0
		
	local badpos = math.BadNumber(x) or x==0
				or math.BadNumber(y) or y==0
				or math.BadNumber(z) or z==0

	local pos = ent:GetPos()

	hg.QueueCollisionRulesChanged(ent)

	if physobj:IsValid() then
		physobj:EnableMotion(false)
		physobj:Sleep()
		physobj:SetPos(vector_origin)
		physobj:SetAngles(angle_zero)
		physobj:SetVelocity(vector_origin)
		physobj:SetAngleVelocity(vector_origin)
	end

	ent:SetLocalAngularVelocity(angle_zero)
	ent:SetVelocity(vector_origin)
	ent:SetLocalVelocity(vector_origin)

	SetAbsVelocity(ent, vector_origin)
	if SERVER then
		local t = constraint.GetAllConstrainedEntities(ent)
		for k,v in next, t or {} do
			local t = constraint.GetAllConstrainedEntities(v)
			for k,v in next, t or {} do
				if ent ~= v and IsValid(v) and not v.__removed__ then
					v.__removed__ = true
					v:Remove()
				end
			end

			if IsValid(v) and not v.__removed__ then
				v.__removed__ = true
				v:Remove()
			end
		end
	end
end)
