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
hg._queuedRagdollSleeps = hg._queuedRagdollSleeps or {}

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

		for rag in pairs(hg._queuedRagdollSleeps) do
			hg._queuedRagdollSleeps[rag] = nil

			if IsValid(rag) and rag.hg_ragdollCollisionState == "settled" then
				for i = 0, rag:GetPhysicsObjectCount() - 1 do
					local phys = rag:GetPhysicsObjectNum(i)
					if IsValid(phys) then phys:Sleep() end
				end
			end
		end
	end)
end

hg.RagdollCollisionState = hg.RagdollCollisionState or {
	ACTIVE = "active",
	FAST = "fast",
	INTERACTING = "interacting",
	MOVING = "moving",
	SETTLED = "settled"
}

if SERVER then
	local ragdollState = hg.RagdollCollisionState
	local ragdollStateGroups = {
		[ragdollState.ACTIVE] = COLLISION_GROUP_WEAPON,
		[ragdollState.FAST] = COLLISION_GROUP_NONE,
		[ragdollState.INTERACTING] = COLLISION_GROUP_WEAPON,
		[ragdollState.MOVING] = COLLISION_GROUP_WEAPON,
		[ragdollState.SETTLED] = COLLISION_GROUP_DEBRIS
	}

	local function WakeRagdollPhysics(rag)
		for i = 0, rag:GetPhysicsObjectCount() - 1 do
			local phys = rag:GetPhysicsObjectNum(i)
			if IsValid(phys) then phys:Wake() end
		end
	end

	local function SleepRagdollPhysics(rag)
		for i = 0, rag:GetPhysicsObjectCount() - 1 do
			local phys = rag:GetPhysicsObjectNum(i)
			if IsValid(phys) then phys:Sleep() end
		end
	end

	function hg.SetRagdollCollisionState(rag, state, immediate)
		if not IsValid(rag) or not rag:IsRagdoll() then return false end

		local collisionGroup = ragdollStateGroups[state]
		if collisionGroup == nil then return false end

		local previousState = rag.hg_ragdollCollisionState
		rag.hg_ragdollCollisionState = state
		rag.hg_corpseSettled = state == ragdollState.SETTLED and true or nil

		local queuedGroup = hg._queuedCollisionGroupChanges[rag]
		if rag:GetCollisionGroup() ~= collisionGroup or (queuedGroup ~= nil and queuedGroup ~= collisionGroup) then
			if immediate then
				hg.ApplySetCollisionGroupNow(rag, collisionGroup)
			else
				hg.SafeSetCollisionGroup(rag, collisionGroup)
			end
		end

		if state == ragdollState.SETTLED and previousState ~= ragdollState.SETTLED then
			if immediate then
				SleepRagdollPhysics(rag)
			else
				hg._queuedRagdollSleeps[rag] = true
			end
		else
			hg._queuedRagdollSleeps[rag] = nil
		end

		if state ~= ragdollState.SETTLED and (previousState == ragdollState.SETTLED or (state == ragdollState.INTERACTING and previousState ~= ragdollState.INTERACTING)) then
			WakeRagdollPhysics(rag)
		end

		return true
	end

	local function InteractionStillActive(rag, token, interactionType)
		if interactionType == "carry_primary" then
			return IsValid(token) and token.GetCarrying and token:GetCarrying() == rag
		end

		if interactionType == "carry_secondary" then
			return IsValid(token) and token:IsPlayer() and token:GetNetVar("carryent2") == rag
		end

		if interactionType == "engine_hold" then
			return IsValid(token) and rag:IsPlayerHolding()
		end

		return IsValid(token)
	end

	function hg.IsRagdollCollisionInteracting(rag)
		if not IsValid(rag) or not rag:IsRagdoll() then return false end
		if IsValid(rag:GetParent()) or rag:IsPlayerHolding() then return true end

		local interactions = rag.hg_ragdollCollisionInteractions
		if not interactions then return false end

		local active = false
		for token, interactionType in pairs(interactions) do
			if InteractionStillActive(rag, token, interactionType) then
				active = true
			else
				interactions[token] = nil
			end
		end

		if not active then rag.hg_ragdollCollisionInteractions = nil end
		return active
	end

	function hg.BeginRagdollCollisionInteraction(rag, token, interactionType)
		if not IsValid(rag) or not rag:IsRagdoll() or token == nil then return end

		rag.hg_ragdollCollisionInteractions = rag.hg_ragdollCollisionInteractions or {}
		rag.hg_ragdollCollisionInteractions[token] = interactionType or true
		rag.hg_corpseLastActive = CurTime()
		hg.SetRagdollCollisionState(rag, ragdollState.INTERACTING)
	end

	function hg.EndRagdollCollisionInteraction(rag, token)
		if not IsValid(rag) or not rag:IsRagdoll() then return end

		local interactions = rag.hg_ragdollCollisionInteractions
		if interactions and token ~= nil then interactions[token] = nil end
		rag.hg_corpseLastActive = CurTime()

		if not hg.IsRagdollCollisionInteracting(rag) then
			hg.RefreshRagdollCollisionState(rag, nil, true)
			return
		end

		timer.Simple(0, function()
			if IsValid(rag) and not hg.IsRagdollCollisionInteracting(rag) then
				hg.RefreshRagdollCollisionState(rag, nil, true)
			end
		end)
	end

	function hg.IsLiveManagedRagdoll(rag, owner)
		if not IsValid(rag) or not rag:IsRagdoll() then return false end

		if not IsValid(owner) or not owner:IsPlayer() then
			owner = hg.RagdollOwner and hg.RagdollOwner(rag) or nil
		end

		if not IsValid(owner) or not owner:IsPlayer() then
			local networkOwner = rag:GetNWEntity("ply")
			if IsValid(networkOwner) and networkOwner:IsPlayer() then owner = networkOwner end
		end

		if IsValid(owner) and owner:IsPlayer() and owner:Alive() and owner.FakeRagdoll == rag then
			return true, owner
		end

		local organismAlive = rag.organism and rag.organism.alive == true or false
		return organismAlive, owner
	end

	function hg.RefreshRagdollCollisionState(rag, owner, forceMoving)
		if not IsValid(rag) or not rag:IsRagdoll() then return end

		if hg.IsRagdollCollisionInteracting(rag) then
			return hg.SetRagdollCollisionState(rag, ragdollState.INTERACTING)
		end

		local isLive, liveOwner = hg.IsLiveManagedRagdoll(rag, owner)
		if isLive then
			if IsValid(liveOwner) and (liveOwner.lastFake or 0) > 0 then
				return hg.SetRagdollCollisionState(rag, ragdollState.ACTIVE)
			end

			local state = rag:GetVelocity():LengthSqr() > 200 * 200 and ragdollState.FAST or ragdollState.ACTIVE
			return hg.SetRagdollCollisionState(rag, state)
		end

		if not forceMoving and (rag.hg_ragdollCollisionState == ragdollState.SETTLED or rag.hg_corpseSettled) then
			return hg.SetRagdollCollisionState(rag, ragdollState.SETTLED)
		end

		local state = rag:GetVelocity():LengthSqr() > 200 * 200 and ragdollState.FAST or ragdollState.MOVING
		return hg.SetRagdollCollisionState(rag, state)
	end

	local function CollisionRagdoll(ent)
		if not IsValid(ent) then return end
		if ent:IsRagdoll() then return ent end
		if ent:IsPlayer() and IsValid(ent.FakeRagdoll) then return ent.FakeRagdoll end
	end

	hook.Add("OnPhysgunPickup", "hg_ragdoll_collision_interaction", function(ply, ent)
		local rag = CollisionRagdoll(ent)
		if IsValid(rag) then hg.BeginRagdollCollisionInteraction(rag, ply, "engine_hold") end
	end)

	hook.Add("PhysgunDrop", "hg_ragdoll_collision_interaction", function(ply, ent)
		local rag = CollisionRagdoll(ent)
		if IsValid(rag) then hg.EndRagdollCollisionInteraction(rag, ply) end
	end)

	hook.Add("GravGunOnPickedUp", "hg_ragdoll_collision_interaction", function(ply, ent)
		local rag = CollisionRagdoll(ent)
		if IsValid(rag) then hg.BeginRagdollCollisionInteraction(rag, ply, "engine_hold") end
	end)

	hook.Add("GravGunOnDropped", "hg_ragdoll_collision_interaction", function(ply, ent)
		local rag = CollisionRagdoll(ent)
		if IsValid(rag) then hg.EndRagdollCollisionInteraction(rag, ply) end
	end)

	hook.Add("GravGunPunt", "hg_ragdoll_collision_punt", function(_, ent)
		local rag = CollisionRagdoll(ent)
		if not IsValid(rag) then return end

		rag.hg_corpseLastActive = CurTime()
		hg.RefreshRagdollCollisionState(rag, nil, true)
	end)

	hook.Add("PostEntityTakeDamage", "hg_ragdoll_collision_damage", function(ent, dmgInfo, tookDamage)
		if tookDamage == false or not IsValid(ent) or not ent:IsRagdoll() then return end
		if not dmgInfo or dmgInfo:GetDamageForce():LengthSqr() <= 1 then return end

		ent.hg_corpseLastActive = CurTime()
		hg.RefreshRagdollCollisionState(ent, nil, true)
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
