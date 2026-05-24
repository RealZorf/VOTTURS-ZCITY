local PHYS_TICK = 0.1
local PHYSGUN_CLASS = "weapon_physgun"
local GRAVGUN_CLASS = "weapon_physcannon"
local GRAVGUN_INTENT_WINDOW = 0.2
local HELD_MODE_PHYSGUN = "physgun"
local HELD_MODE_GRAVGUN_NATIVE = "gravgun_native"
local HELD_MODE_GRAVGUN_MANUAL = "gravgun_manual"

local function canUseAdminPhysgun(ply)
	if not IsValid(ply) or not ply:IsPlayer() then
		return false
	end

	return zb and zb.PlayerCanPhysgun and zb.PlayerCanPhysgun(ply)
end

local function getPlayerFromEntity(ent)
	if not IsValid(ent) then return end
	if ent:IsPlayer() then return ent end

	if hg and hg.RagdollOwner then
		local owner = hg.RagdollOwner(ent)
		if IsValid(owner) then return owner end
	end

	if ent.GetNWEntity then
		local owner = ent:GetNWEntity("ply", NULL)
		if IsValid(owner) then return owner end
	end
end

local function getPlayerRagdoll(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	if hg and hg.GetCurrentCharacter then
		local current = hg.GetCurrentCharacter(ply)
		if IsValid(current) and current ~= ply and current:IsRagdoll() then
			return current
		end
	end

	if IsValid(ply.FakeRagdoll) then
		return ply.FakeRagdoll
	end

	if IsValid(ply.RagdollDeath) then
		return ply.RagdollDeath
	end

	if ply.GetNWEntity then
		local rag = ply:GetNWEntity("FakeRagdoll", NULL)
		if IsValid(rag) then
			return rag
		end

		rag = ply:GetNWEntity("RagdollDeath", NULL)
		if IsValid(rag) then
			return rag
		end
	end
end

local function getHeldRagdollTarget(holder, ent)
	local target = getPlayerFromEntity(ent)
	if not IsValid(target) or target == holder then return end

	local rag = getPlayerRagdoll(target)
	if not IsValid(rag) or ent ~= rag then return end

	return target, rag
end

local function clearForcedFakeState(ply)
	if not IsValid(ply) then return end

	ply.ZCPhysgunForcedFake = nil
	ply.fakecd = 0

	if ply.organism then
		ply.organism.lightstun = 0
	end

	if ply.SetLocalVar then
		ply:SetLocalVar("stun", 0)
	end
end

local function clearHeldTarget(ply)
	if not IsValid(ply) then return end

	local rag = ply.ZCPhysgunHeldRagdoll
	if IsValid(rag) then
		rag.isheld = false
	end

	local holder = ply.ZCPhysgunHeldBy
	if IsValid(holder) and holder.ZCPhysgunHeldTarget == ply then
		holder.ZCPhysgunHeldTarget = nil
	end

	if IsValid(holder) and holder.ZCAdminGravHoldingTarget == ply then
		holder.ZCAdminGravHoldingTarget = nil
	end

	ply.ZCPhysgunHeldBy = nil
	ply.ZCPhysgunHeldRagdoll = nil
	ply.ZCPhysgunHeldMode = nil
end

local function clearHolderState(ply)
	if not IsValid(ply) then return end

	local target = ply.ZCPhysgunHeldTarget
	ply.ZCPhysgunHeldTarget = nil

	if IsValid(target) and target.ZCPhysgunHeldBy == ply then
		clearHeldTarget(target)
	end
end

local function setHeldTarget(holder, target, rag, mode)
	if not IsValid(holder) or not IsValid(target) or not IsValid(rag) then return end

	if IsValid(holder.ZCPhysgunHeldTarget) and holder.ZCPhysgunHeldTarget ~= target then
		clearHeldTarget(holder.ZCPhysgunHeldTarget)
	end

	if IsValid(target.ZCPhysgunHeldBy) and target.ZCPhysgunHeldBy ~= holder then
		clearHeldTarget(target)
	end

	holder.ZCPhysgunHeldTarget = target
	target.ZCPhysgunHeldBy = holder
	target.ZCPhysgunHeldRagdoll = rag
	target.ZCPhysgunHeldMode = mode or HELD_MODE_PHYSGUN
	rag.isheld = true
	rag:SetPhysicsAttacker(holder, 5)

	if target.ZCPhysgunHeldMode == HELD_MODE_GRAVGUN_NATIVE or target.ZCPhysgunHeldMode == HELD_MODE_GRAVGUN_MANUAL then
		holder.ZCAdminGravHoldingTarget = target
	else
		holder.ZCAdminGravHoldingTarget = nil
	end
end

local function hasGravityPickupIntent(ply)
	return (ply.ZCAdminGravIntentUntil or 0) >= CurTime()
end

local function consumeGravityPickupIntent(ply)
	if not hasGravityPickupIntent(ply) then return false end

	ply.ZCAdminGravIntentUntil = nil
	return true
end

local function finalizeGravityRelease(holder, target)
	if not IsValid(target) then return end

	clearHeldTarget(target)

	if target.ZCPhysgunForcedFake then
		clearForcedFakeState(target)
	end

	if IsValid(holder) and holder.ZCAdminGravHoldingTarget == target then
		holder.ZCAdminGravHoldingTarget = nil
	end
end

local function syncGravityHeldState(holder)
	local target = IsValid(holder) and holder.ZCAdminGravHoldingTarget or nil
	if not IsValid(target) then return end

	local rag = target.ZCPhysgunHeldRagdoll
	if not IsValid(rag) or not rag:IsPlayerHolding() then
		finalizeGravityRelease(holder, target)
	end
end

local function puntGravityHeldTarget(holder)
	if not IsValid(holder) then return end

	local target = holder.ZCAdminGravHoldingTarget
	if not IsValid(target) or target.ZCPhysgunHeldBy ~= holder then return end
	if target.ZCPhysgunHeldMode ~= HELD_MODE_GRAVGUN_MANUAL then return end

	local rag = target.ZCPhysgunHeldRagdoll
	if not IsValid(rag) then
		finalizeGravityRelease(holder, target)
		return
	end

	holder:DropObject()

	local force = holder:GetAimVector() * 12000
	local addVelocity = holder:GetVelocity()

	for i = 0, rag:GetPhysicsObjectCount() - 1 do
		local phys = rag:GetPhysicsObjectNum(i)
		if IsValid(phys) then
			phys:Wake()
			phys:ApplyForceCenter(force)
			phys:AddVelocity(addVelocity)
		end
	end

	rag:SetPhysicsAttacker(holder, 5)
	finalizeGravityRelease(holder, target)
end

local function tryGravityPickup(holder, target, rag)
	if not IsValid(holder) or not IsValid(target) or not IsValid(rag) then return end

	local function attemptPickup(triesLeft)
		timer.Simple(0, function()
			if not IsValid(holder) or not IsValid(target) or not IsValid(rag) then return end
			if not holder:Alive() or target == holder or not target:Alive() then return end
			if not IsValid(holder:GetActiveWeapon()) or holder:GetActiveWeapon():GetClass() ~= GRAVGUN_CLASS then return end
			if IsValid(target.ZCPhysgunHeldBy) and target.ZCPhysgunHeldBy ~= holder then return end

			holder:PickupObject(rag)

			timer.Simple(0, function()
				if not IsValid(holder) or not IsValid(target) or not IsValid(rag) then return end
				if rag:IsPlayerHolding() then
					setHeldTarget(holder, target, rag, HELD_MODE_GRAVGUN_MANUAL)
					return
				end

				if triesLeft > 0 then
					timer.Simple(0.05, function()
						attemptPickup(triesLeft - 1)
					end)
				end
			end)
		end)
	end

	attemptPickup(4)
end

local function primePlayerForPhysgun(target)
	if not IsValid(target) or not target:IsPlayer() or not target:Alive() then return end
	if target:InVehicle() then return end

	local rag = getPlayerRagdoll(target)
	if IsValid(rag) then return rag end

	if (target.ZCPhysgunPrimeUntil or 0) > CurTime() then
		return
	end

	target.ZCPhysgunPrimeUntil = CurTime() + PHYS_TICK

	if hg and hg.LightStunPlayer then
		hg.LightStunPlayer(target, PHYS_TICK)
	elseif hg and hg.Fake then
		hg.Fake(target, nil, true, true)
	end

	rag = getPlayerRagdoll(target)
	if IsValid(rag) then
		target.ZCPhysgunForcedFake = true
	end

	return rag
end

local function tracePhysgunTarget(ply)
	local filter = {ply}
	local current = hg and hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply) or nil

	if IsValid(current) and current ~= ply then
		filter[#filter + 1] = current
	end

	return util.TraceHull({
		start = ply:GetShootPos(),
		endpos = ply:GetShootPos() + ply:GetAimVector() * 4096,
		filter = filter,
		mins = Vector(-4, -4, -4),
		maxs = Vector(4, 4, 4),
		mask = MASK_SHOT
	})
end

hook.Add("StartCommand", "ZC_AdminPhysgunPrime", function(ply, cmd)
	if not canUseAdminPhysgun(ply) then return end

	local weapon = ply:GetActiveWeapon()
	if not IsValid(weapon) then
		ply.ZCAdminGravAttack2Down = false
		ply.ZCAdminGravAttack1Down = false
		return
	end

	local class = weapon:GetClass()
	if class == PHYSGUN_CLASS then
		if not cmd:KeyDown(IN_ATTACK) or cmd:KeyDown(IN_ATTACK2) then return end
	elseif class == GRAVGUN_CLASS then
		syncGravityHeldState(ply)

		local attack1Down = cmd:KeyDown(IN_ATTACK)
		local attack2Down = cmd:KeyDown(IN_ATTACK2)

		if attack1Down and not ply.ZCAdminGravAttack1Down then
			puntGravityHeldTarget(ply)
		end

		if attack2Down and not ply.ZCAdminGravAttack2Down then
			ply.ZCAdminGravIntentUntil = CurTime() + GRAVGUN_INTENT_WINDOW
		end

		ply.ZCAdminGravAttack1Down = attack1Down
		ply.ZCAdminGravAttack2Down = attack2Down
		return
	else
		syncGravityHeldState(ply)
		ply.ZCAdminGravAttack1Down = false
		ply.ZCAdminGravAttack2Down = false
		return
	end

	local tr = tracePhysgunTarget(ply)
	local ent = tr.Entity
	if not IsValid(ent) or ent == ply then return end

	local target = getPlayerFromEntity(ent)
	if not IsValid(target) or target == ply then return end

	primePlayerForPhysgun(target)
end)

hook.Add("PhysgunPickup", "ZC_AdminPhysgunPickup", function(ply, ent)
	if not canUseAdminPhysgun(ply) then return end

	local target = getPlayerFromEntity(ent)
	if not IsValid(target) or target == ply or not target:Alive() then return end

	if IsValid(target.ZCPhysgunHeldBy) and target.ZCPhysgunHeldBy ~= ply then
		return false
	end

	local rag = getPlayerRagdoll(target)
	if IsValid(rag) and ent == rag then
		return true
	end

	if ent:IsPlayer() then
		primePlayerForPhysgun(target)
		return false
	end
end)

hook.Add("GravGunPickupAllowed", "ZC_AdminPhysgunGravPickupAllowed", function(ply, ent)
	if not canUseAdminPhysgun(ply) then return end

	local target = getPlayerFromEntity(ent)
	if not IsValid(target) or target == ply then return end
	if not consumeGravityPickupIntent(ply) then return false end

	if IsValid(target.ZCPhysgunHeldBy) and target.ZCPhysgunHeldBy ~= ply then
		return false
	end

	local rag = getPlayerRagdoll(target)
	if IsValid(rag) and ent == rag then
		return true
	end

	if ent:IsPlayer() and target:Alive() then
		local forcedRag = primePlayerForPhysgun(target)
		if IsValid(forcedRag) then
			tryGravityPickup(ply, target, forcedRag)
		end
		return false
	end
end)

hook.Add("OnPhysgunPickup", "ZC_AdminPhysgunOnPickup", function(ply, ent)
	if not canUseAdminPhysgun(ply) then return end

	local target = getPlayerFromEntity(ent)
	if not IsValid(target) or target == ply or not target:Alive() then return end

	local rag = getPlayerRagdoll(target)
	if not IsValid(rag) or ent ~= rag then return end

	setHeldTarget(ply, target, rag, HELD_MODE_PHYSGUN)
end)

hook.Add("GravGunOnPickedUp", "ZC_AdminPhysgunGravOnPickedUp", function(ply, ent)
	if not canUseAdminPhysgun(ply) then return end

	local target, rag = getHeldRagdollTarget(ply, ent)
	if not IsValid(target) then return end

	setHeldTarget(ply, target, rag, HELD_MODE_GRAVGUN_NATIVE)
end)

hook.Add("PhysgunDrop", "ZC_AdminPhysgunDrop", function(ply, ent)
	local target = getPlayerFromEntity(ent)
	if not IsValid(target) then return end

	local rag = target.ZCPhysgunHeldRagdoll
	if not IsValid(rag) or ent ~= rag then return end
	if target.ZCPhysgunHeldBy ~= ply then return end

	clearHeldTarget(target)

	if target.ZCPhysgunForcedFake then
		clearForcedFakeState(target)
	end
end)

hook.Add("GravGunOnDropped", "ZC_AdminPhysgunGravOnDropped", function(ply, ent)
	local target, rag = getHeldRagdollTarget(ply, ent)
	if not IsValid(target) or not IsValid(rag) then return end
	if target.ZCPhysgunHeldBy ~= ply then return end

	finalizeGravityRelease(ply, target)
end)

hook.Add("GravGunPunt", "ZC_AdminPhysgunGravPunt", function(ply, ent)
	if not canUseAdminPhysgun(ply) then return end

	local target, rag = getHeldRagdollTarget(ply, ent)
	if not IsValid(target) or not IsValid(rag) then return end

	if IsValid(target.ZCPhysgunHeldBy) and target.ZCPhysgunHeldBy ~= ply then
		return false
	end

	if target.ZCPhysgunHeldBy == ply then
		finalizeGravityRelease(ply, target)
	end

	return true
end)

hook.Add("Should Fake Up", "ZC_AdminPhysgunBlockFakeUp", function(ply)
	if IsValid(ply.ZCPhysgunHeldBy) then
		return false
	end
end)

hook.Add("EntityRemoved", "ZC_AdminPhysgunEntityRemoved", function(ent)
	local target = getPlayerFromEntity(ent)
	if not IsValid(target) then return end
	if target.ZCPhysgunHeldRagdoll ~= ent then return end

	clearHeldTarget(target)
end)

hook.Add("PlayerDeath", "ZC_AdminPhysgunDeathReset", function(ply)
	clearHeldTarget(ply)
	clearHolderState(ply)
	ply.ZCPhysgunForcedFake = nil
	ply.ZCPhysgunPrimeUntil = nil
end)

hook.Add("PlayerSpawn", "ZC_AdminPhysgunSpawnReset", function(ply)
	clearHeldTarget(ply)
	clearHolderState(ply)
	ply.ZCPhysgunForcedFake = nil
	ply.ZCPhysgunPrimeUntil = nil
end)

hook.Add("PlayerDisconnected", "ZC_AdminPhysgunDisconnectReset", function(ply)
	clearHeldTarget(ply)
	clearHolderState(ply)
end)
