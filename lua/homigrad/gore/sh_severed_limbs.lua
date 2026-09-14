hg = hg or {}
hg.organism = hg.organism or {}

hg.SeveredLimbBones = {
	larm = "ValveBiped.Bip01_L_Forearm",
	rarm = "ValveBiped.Bip01_R_Forearm",
	lleg = "ValveBiped.Bip01_L_Calf",
	rleg = "ValveBiped.Bip01_R_Calf",
	head = "ValveBiped.Bip01_Head1"
}

hg.SeveredLimbStumps = {
	larm = {"ValveBiped.Bip01_L_UpperArm", Vector(11, 0, 0)},
	rarm = {"ValveBiped.Bip01_R_UpperArm", Vector(11, 0, 0)},
	lleg = {"ValveBiped.Bip01_L_Thigh", Vector(16, 0, 0)},
	rleg = {"ValveBiped.Bip01_R_Thigh", Vector(16, 0, 0)},
	head = {"ValveBiped.Bip01_Neck1", Vector(5, 0, 0)}
}

if SERVER then
	util.AddNetworkString("hg_severed_limb_effect")

	local zeroScale = Vector(0, 0, 0)
	local severedScale = Vector(0.01, 0.01, 0.01)
	local limbLimit = ConVarExists("hg_severed_limb_limit") and GetConVar("hg_severed_limb_limit") or CreateConVar("hg_severed_limb_limit", "24", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Maximum number of detached body parts.", 0, 64)
	local limbLifetime = ConVarExists("hg_severed_limb_lifetime") and GetConVar("hg_severed_limb_lifetime") or CreateConVar("hg_severed_limb_lifetime", "120", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Detached body part lifetime in seconds. 0 disables timed cleanup.", 0, 600)
	local trackedLimbs = hg.severedLimbs or {}
	hg.severedLimbs = trackedLimbs

	local function copyVector(vec)
		if not isvector(vec) then return Vector(0, 0, 0) end
		return Vector(vec.x, vec.y, vec.z)
	end

	local function getCharacter(owner)
		if not IsValid(owner) then return end
		local character = hg.GetCurrentCharacter and hg.GetCurrentCharacter(owner) or owner
		if IsValid(character) and ((owner.Alive and owner:Alive()) or character ~= owner) then return character end
		local deathRagdoll = owner.GetNWEntity and owner:GetNWEntity("RagdollDeath")
		return IsValid(deathRagdoll) and deathRagdoll or character
	end

	local function getModelScale(source, owner)
		if IsValid(owner) and hg.GetPlayerModelScale then
			return math.Clamp(hg.GetPlayerModelScale(owner), 0.1, 10)
		end
		if source.GetNWFloat then
			return math.Clamp(source:GetNWFloat("ZCModelScale", source:GetModelScale()), 0.1, 10)
		end
		return math.Clamp(source:GetModelScale(), 0.1, 10)
	end

	local function copyAppearance(source, piece, owner)
		piece:SetSkin(source:GetSkin() or 0)
		for _, bodygroup in ipairs(source:GetBodyGroups() or {}) do
			piece:SetBodygroup(bodygroup.id, source:GetBodygroup(bodygroup.id))
		end

		piece:SetColor(source:GetColor())
		piece:SetMaterial(source:GetMaterial() or "")
		piece:SetRenderMode(source:GetRenderMode())
		for index = 0, #(source:GetMaterials() or {}) - 1 do
			local material = source:GetSubMaterial(index)
			if material and material ~= "" then piece:SetSubMaterial(index, material) end
		end

		local playerColor = source.GetPlayerColor and source:GetPlayerColor() or source:GetNWVector("PlayerColor", Vector(1, 1, 1))
		piece:SetNWVector("PlayerColor", playerColor)
		if piece.SetPlayerColor then piece:SetPlayerColor(playerColor) end

		local appearanceSource = IsValid(owner) and owner or source
		if piece.SetNetVar and appearanceSource.GetNetVar then
			local accessories = appearanceSource:GetNetVar("Accessories", "none")
			piece:SetNetVar("Accessories", istable(accessories) and table.Copy(accessories) or accessories)
		end
		if IsValid(owner) and owner:IsPlayer() and isfunction(ApplyAppearanceRagdoll) then
			ApplyAppearanceRagdoll(piece, owner)
		elseif source.GetNWString then
			piece:SetNWString("PlayerName", source:GetNWString("PlayerName", ""))
		end
	end

	local function collectBones(ent, bone, list, lookup)
		if lookup[bone] then return end
		lookup[bone] = true
		list[#list + 1] = bone
		for _, child in ipairs(ent:GetChildBones(bone) or {}) do
			collectBones(ent, child, list, lookup)
		end
	end

	local function trimLimbs(requiredSpace)
		for index = #trackedLimbs, 1, -1 do
			if not IsValid(trackedLimbs[index]) then table.remove(trackedLimbs, index) end
		end

		local limit = math.max(limbLimit:GetInt(), 0)
		while #trackedLimbs + (requiredSpace or 0) > limit and #trackedLimbs > 0 do
			local oldest = table.remove(trackedLimbs, 1)
			if IsValid(oldest) then oldest:Remove() end
		end
		return limit > 0
	end

	local function trackLimb(piece)
		trackedLimbs[#trackedLimbs + 1] = piece
		piece:CallOnRemove("hg_severed_limb_cleanup", function(removed)
			for index = #trackedLimbs, 1, -1 do
				if trackedLimbs[index] == removed then
					table.remove(trackedLimbs, index)
					break
				end
			end
		end)
	end

	hook.Add("Think", "HGSeveredLimbPhysics", function()
		for index = #trackedLimbs, 1, -1 do
			local piece = trackedLimbs[index]
			if not IsValid(piece) then
				table.remove(trackedLimbs, index)
				continue
			end

			local rootPhys = piece:GetPhysicsObjectNum(piece.HGSeverRootPhys or -1)
			if not IsValid(rootPhys) then continue end
			local position = rootPhys:GetPos()
			local angles = rootPhys:GetAngles()
			for hiddenIndex = 1, #(piece.HGSeverHiddenPhys or {}) do
				local phys = piece:GetPhysicsObjectNum(piece.HGSeverHiddenPhys[hiddenIndex])
				if not IsValid(phys) then continue end
				phys:SetPos(position)
				phys:SetAngles(angles)
			end
		end
	end)

	local function sendEffect(source, owner, piece, limb, position, force, bleedUntil)
		local recipients = RecipientFilter()
		recipients:AddPVS(position)
		if IsValid(owner) and owner:IsPlayer() then recipients:AddPlayer(owner) end

		net.Start("hg_severed_limb_effect", true)
		net.WriteEntity(source)
		net.WriteEntity(IsValid(piece) and piece or NULL)
		net.WriteString(limb)
		net.WriteVector(position)
		net.WriteVector(force)
		net.WriteFloat(bleedUntil)
		net.Send(recipients)
	end

	function hg.SpawnSeveredLimb(source, limb, damageContext)
		local rootName = hg.SeveredLimbBones[limb]
		if not IsValid(source) or not rootName then return end

		local sourceRootBone = source:LookupBone(rootName)
		if not sourceRootBone then return end
		if not trimLimbs(1) then return end

		local owner = hg.RagdollOwner and hg.RagdollOwner(source) or nil
		if not IsValid(owner) and source:IsPlayer() then owner = source end
		if not IsValid(owner) and IsValid(source.ply) and source.ply:IsPlayer() then owner = source.ply end
		if not IsValid(owner) and source.organism then owner = source.organism.owner end

		local piece = ents.Create("prop_ragdoll")
		if not IsValid(piece) then return end

		local modelScale = getModelScale(source, owner)
		local bleedUntil = CurTime() + (limb == "head" and 8 or 12)
		piece:SetModel(source:GetModel())
		piece:SetPos(source:GetPos())
		piece:SetAngles(source:GetAngles())
		piece:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		piece:SetNWBool("IsSeveredLimb", true)
		piece:SetNWString("SeveredLimb", limb)
		piece:SetNWFloat("ZCModelScale", modelScale)
		piece:SetNWFloat("SeverBleedUntil", bleedUntil)
		piece:SetNWEntity("SeveredOwner", IsValid(owner) and owner or NULL)
		piece:SetModelScale(modelScale, 0)
		piece:Spawn()
		piece:Activate()
		piece:AddEFlags(EFL_DONTBLOCKLOS)
		piece.IsSeveredLimb = true
		piece.HGSeveredLimb = true
		piece.severedLimb = limb
		piece.organism = nil
		piece.ply = nil
		copyAppearance(source, piece, owner)

		local rootBone = piece:LookupBone(rootName)
		if not rootBone then piece:Remove() return end
		local keepBones = {}
		local keepLookup = {}
		collectBones(piece, rootBone, keepBones, keepLookup)
		local keepPhys = {}
		local hiddenPhys = {}
		local rootPhysNum

		for physNum = 0, piece:GetPhysicsObjectCount() - 1 do
			local phys = piece:GetPhysicsObjectNum(physNum)
			if not IsValid(phys) then continue end
			local bone = piece:TranslatePhysBoneToBone(physNum)
			if bone == nil then continue end
			local matrix = source:GetBoneMatrix(bone)
			local position, angles
			if matrix then
				position = matrix:GetTranslation()
				angles = matrix:GetAngles()
			else
				position, angles = source:GetBonePosition(bone)
			end
			if isvector(position) then phys:SetPos(position) end
			if isangle(angles) then phys:SetAngles(angles) end
			phys:Wake()

			if keepLookup[bone] then
				keepPhys[physNum] = true
				if bone == rootBone then rootPhysNum = physNum end
			else
				hiddenPhys[#hiddenPhys + 1] = physNum
			end
		end

		if rootPhysNum == nil then
			for physNum in pairs(keepPhys) do rootPhysNum = physNum break end
		end
		if rootPhysNum == nil then piece:Remove() return end
		local rootPhys = piece:GetPhysicsObjectNum(rootPhysNum)
		if not IsValid(rootPhys) then piece:Remove() return end

		for bone = 0, piece:GetBoneCount() - 1 do
			if not keepLookup[bone] then piece:ManipulateBoneScale(bone, zeroScale) end
		end

		piece:RemoveInternalConstraint(rootPhysNum)
		for index = 1, #hiddenPhys do
			local physNum = hiddenPhys[index]
			local phys = piece:GetPhysicsObjectNum(physNum)
			if not IsValid(phys) then continue end
			piece:RemoveInternalConstraint(physNum)
			phys:SetPos(rootPhys:GetPos())
			phys:SetAngles(rootPhys:GetAngles())
			phys:EnableCollisions(false)
			phys:EnableMotion(false)
			phys:EnableGravity(false)
			phys:SetMass(0.01)
		end

		for physNum in pairs(keepPhys) do
			local phys = piece:GetPhysicsObjectNum(physNum)
			if not IsValid(phys) then continue end
			phys:EnableMotion(true)
			phys:EnableGravity(true)
			phys:EnableCollisions(physNum == rootPhysNum)
			phys:SetMass(physNum == rootPhysNum and 6 or 2)
		end

		piece.HGSeverRootPhys = rootPhysNum
		piece.HGSeverHiddenPhys = hiddenPhys
		piece:SetNWInt("SeveredRootPhys", rootPhysNum)

		local context = istable(damageContext) and damageContext or {}
		local force = copyVector(context.force)
		local forceLength = force:Length()
		if forceLength > 28000 then force:Mul(28000 / forceLength) end

		local sourceVelocity = source:GetVelocity()
		local sourcePhysBone = source:TranslateBoneToPhysBone(sourceRootBone)
		local sourcePhys = sourcePhysBone and sourcePhysBone >= 0 and source:GetPhysicsObjectNum(sourcePhysBone) or nil
		if IsValid(sourcePhys) then sourceVelocity = sourcePhys:GetVelocity() end

		for physNum in pairs(keepPhys) do
			local phys = piece:GetPhysicsObjectNum(physNum)
			if not IsValid(phys) then continue end
			phys:SetVelocity(sourceVelocity + force * 0.025 + VectorRand(-24, 24))
			phys:AddAngleVelocity(VectorRand(-110, 110))
		end

		piece:AddCallback("PhysicsCollide", function(ent, data)
			if data.DeltaTime < 0.18 or data.Speed < 45 then return end
			local now = CurTime()
			if (ent.HGNextImpactSound or 0) <= now then
				ent.HGNextImpactSound = now + 0.16
				ent:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", 46, math.random(92, 108), 0.32)
			end
			if (ent.HGNextBloodDecal or 0) <= now then
				ent.HGNextBloodDecal = now + 0.3
				util.Decal("Blood", data.HitPos + data.HitNormal * 2, data.HitPos - data.HitNormal * 4, ent)
			end
		end)

		local lifetime = limbLifetime:GetFloat()
		if lifetime > 0 then SafeRemoveEntityDelayed(piece, lifetime) end
		trackLimb(piece)
		sendEffect(source, owner, piece, limb, rootPhys:GetPos(), force, bleedUntil)
		return piece
	end

	local function dropHeadArmor(source, piece)
		if not IsValid(source) or not IsValid(piece) or not hg.DropArmorForce or not hg.armor then return end
		local armor = source.GetNetVar and source:GetNetVar("Armor", {}) or {}
		for _, slot in ipairs({"head", "face"}) do
			local armorName = armor[slot]
			local armorData = armorName and hg.armor[slot] and hg.armor[slot][armorName]
			if armorData and not armorData.nodrop then
				local dropped = hg.DropArmorForce(source, armorName)
				if IsValid(dropped) then
					dropped:SetPos(piece:GetPos())
					local phys = dropped:GetPhysicsObject()
					local piecePhys = piece:GetPhysicsObject()
					if IsValid(phys) and IsValid(piecePhys) then phys:SetVelocity(piecePhys:GetVelocity()) end
				end
			end
		end
	end

	function hg.organism.Decapitate(org, attacker, damageContext, acceptExternalState)
		if not istable(org) or org.headamputated and not acceptExternalState then return false end
		local owner = org.owner
		if not IsValid(owner) or owner.HGDecapitated then return false end
		local source = getCharacter(owner)
		if not IsValid(source) or not source:LookupBone(hg.SeveredLimbBones.head) then return false end

		local piece = hg.SpawnSeveredLimb(source, "head", damageContext)
		if not IsValid(piece) then return false end

		org.headamputated = true
		org.brain = 1
		org.skull = 1
		if owner:IsNPC() then org.shock = 100 end
		owner.HGDecapitated = true
		owner:SetNWBool("HGDecapitated", true)
		source.HGDecapitated = true
		source:SetNWBool("HGDecapitated", true)
		if source:IsRagdoll() then source:SetNWString("PlayerName", "Beheaded body") end

		local headBone = source:LookupBone(hg.SeveredLimbBones.head)
		if headBone then source:ManipulateBoneScale(headBone, severedScale) end
		dropHeadArmor(source, piece)

		local soundName = "player/zombie_head_explode_0" .. math.random(1, 6) .. ".wav"
		local soundPitch = math.random(92, 104)
		if not hg.EmitOccludedSound or not hg.EmitOccludedSound(source, soundName, 62, soundPitch, 0.85) then
			source:EmitSound(soundName, 62, soundPitch, 0.85)
		end

		hook.Run("OnAmputateLimb", org, source, "head", attacker)
		owner.fullsend = true
		if hg.send_bareinfo then hg.send_bareinfo(org) end

		if owner:IsPlayer() and owner:Alive() then
			local context = istable(damageContext) and damageContext or {}
			local lethal = DamageInfo()
			local responsible = IsValid(attacker) and attacker or game.GetWorld()
			local inflictor = IsValid(context.inflictor) and context.inflictor or responsible
			lethal:SetAttacker(responsible)
			lethal:SetInflictor(inflictor)
			lethal:SetDamageType(DMG_SLASH)
			lethal:SetDamage(10000)
			lethal:SetDamagePosition(isvector(context.position) and context.position or source:GetPos())
			lethal:SetDamageForce(isvector(context.force) and context.force or vector_origin)
			owner:TakeDamageInfo(lethal)
		end
		return true
	end

	local function isRecentSlash(context, maxAge)
		if not istable(context) then return false end
		if (context.time or 0) + maxAge < CurTime() then return false end
		local damageType = tonumber(context.damageType) or 0
		if bit.band(damageType, DMG_SLASH) == 0 then return false end
		return bit.band(damageType, DMG_BULLET + DMG_BUCKSHOT + DMG_BLAST) == 0
	end

	local function isRecentHeadSlash(context, maxAge)
		return istable(context) and context.hitgroup == HITGROUP_HEAD and isRecentSlash(context, maxAge)
	end

	local function findHeadSlashOrganism(owner, maxAge, requireAmputated)
		local bestOrganism
		local bestTime = -math.huge
		local checked = {}
		local function consider(entity)
			if not IsValid(entity) or checked[entity] then return end
			checked[entity] = true
			local organism = entity.organism
			if not istable(organism) or requireAmputated and not organism.headamputated then return end
			local context = organism.HGRecentAmputationDamage
			if not isRecentHeadSlash(context, maxAge) then return end
			local contextTime = context.time or 0
			if contextTime <= bestTime then return end
			bestTime = contextTime
			bestOrganism = organism
		end

		consider(owner)
		if not IsValid(owner) or not owner:IsPlayer() then return bestOrganism end
		if hg.GetCurrentCharacter then consider(hg.GetCurrentCharacter(owner)) end
		consider(owner.FakeRagdoll)
		consider(owner:GetNWEntity("FakeRagdoll"))
		consider(owner:GetNWEntity("RagdollDeath"))
		if owner.GetRagdollEntity then consider(owner:GetRagdollEntity()) end
		return bestOrganism
	end

	local function decapitateFatalSlash(victim, attacker)
		if not IsValid(victim) then return end
		local org = findHeadSlashOrganism(victim, 0.25, false)
		local context = org and org.HGRecentAmputationDamage
		if not istable(org) or org.headamputated or not isRecentHeadSlash(context, 0.25) then return end

		local responsible = IsValid(attacker) and attacker or context.attacker
		hg.organism.Decapitate(org, responsible, context)
	end

	hook.Add("PlayerDeath", "HGSeveredLimbFatalSlash", function(victim, inflictor, attacker)
		decapitateFatalSlash(victim, attacker)
	end)

	hook.Add("OnNPCKilled", "HGSeveredLimbFatalSlash", function(victim, attacker)
		decapitateFatalSlash(victim, attacker)
	end)

	local nextExternalDecapitationCheck = 0
	hook.Add("Think", "HGExternalDecapitationBridge", function()
		local now = CurTime()
		if nextExternalDecapitationCheck > now then return end
		nextExternalDecapitationCheck = now + 0.05

		for _, owner in ipairs(player.GetAll()) do
			if owner.HGDecapitated then continue end
			local org = findHeadSlashOrganism(owner, 1, true)
			if not istable(org) then continue end
			local context = org.HGRecentAmputationDamage
			hg.organism.Decapitate(org, context.attacker, context, true)
		end
	end)

	local function installNativeHeadGibBridge()
		if not isfunction(Gib_Input) then return false end

		local nativeGibInput = Gib_Input
		if nativeGibInput == hg.HGSeveredHeadGibWrapper and isfunction(hg.HGSeveredHeadNativeGibInput) then
			nativeGibInput = hg.HGSeveredHeadNativeGibInput
		end

		local function bridgedGibInput(ragdoll, bone, force, ...)
			if IsValid(ragdoll) and not ragdoll:GetNWBool("IsSeveredLimb", false) then
				local headBone = ragdoll:LookupBone(hg.SeveredLimbBones.head)
				local org = ragdoll.organism
				local context = istable(org) and org.HGRecentAmputationDamage or nil

				if headBone and bone == headBone and isRecentSlash(context, 1) and not ragdoll.HGDecapitated then
					local severContext = table.Copy(context)
					if isvector(force) then severContext.force = copyVector(force) end
					local position = ragdoll:GetBonePosition(headBone)
					if isvector(position) then severContext.position = copyVector(position) end
					hg.organism.Decapitate(org, severContext.attacker, severContext, true)
				end
			end

			return nativeGibInput(ragdoll, bone, force, ...)
		end

		hg.HGSeveredHeadNativeGibInput = nativeGibInput
		hg.HGSeveredHeadGibWrapper = bridgedGibInput
		Gib_Input = bridgedGibInput
		return true
	end

	hook.Add("HomigradRun", "HGSeveredHeadNativeGibBridge", function()
		timer.Simple(0, installNativeHeadGibBridge)
	end)
	hook.Add("InitPostEntity", "HGSeveredHeadNativeGibBridge", function()
		installNativeHeadGibBridge()
	end)
	timer.Simple(0, installNativeHeadGibBridge)

	local function applyDecapitatedBodyState(ragdoll)
		if not IsValid(ragdoll) then return end
		ragdoll.HGDecapitated = true
		ragdoll:SetNWBool("HGDecapitated", true)
		ragdoll:SetNWString("PlayerName", "Beheaded body")
		local headBone = ragdoll:LookupBone(hg.SeveredLimbBones.head)
		if headBone then ragdoll:ManipulateBoneScale(headBone, severedScale) end
	end

	hook.Add("Ragdoll_Create", "HGSeveredHeadState", function(ply, ragdoll)
		if not IsValid(ply) or not IsValid(ragdoll) or not ply.HGDecapitated then return end
		applyDecapitatedBodyState(ragdoll)
		timer.Simple(0, function()
			if IsValid(ragdoll) and ragdoll:GetNWBool("HGDecapitated", false) then applyDecapitatedBodyState(ragdoll) end
		end)
	end)

	hook.Add("Org Clear", "HGSeveredHeadReset", function(org)
		local owner = org and org.owner
		if not IsValid(owner) then return end
		local restoreHead = owner.HGDecapitated
		owner.HGDecapitated = nil
		owner:SetNWBool("HGDecapitated", false)
		if restoreHead then
			timer.Simple(0, function()
				if not IsValid(owner) then return end
				local headBone = owner:LookupBone(hg.SeveredLimbBones.head)
				if headBone then owner:ManipulateBoneScale(headBone, Vector(1, 1, 1)) end
			end)
		end
	end)

	return
end

local zeroScale = Vector(0, 0, 0)
local clientSeveredLimbs = setmetatable({}, {__mode = "k"})

local function collectClientBones(ent, bone, keep)
	if keep[bone] then return end
	keep[bone] = true
	for _, child in ipairs(ent:GetChildBones(bone) or {}) do
		collectClientBones(ent, child, keep)
	end
end

local function getClientBoneCache(ent)
	local limb = ent:GetNWString("SeveredLimb", "")
	local model = ent:GetModel()
	local cache = ent.HGSeverBoneCache
	if cache and cache.limb == limb and cache.model == model then return cache end

	local rootName = hg.SeveredLimbBones[limb]
	local root = rootName and ent:LookupBone(rootName)
	if not root then return end
	local keep = {}
	collectClientBones(ent, root, keep)
	local hidden = {}
	for bone = 0, ent:GetBoneCount() - 1 do
		if not keep[bone] then hidden[#hidden + 1] = bone end
	end

	cache = {limb = limb, model = model, root = root, hidden = hidden}
	ent.HGSeverBoneCache = cache
	return cache
end

local function drawHeadAccessories(ent)
	if ent:GetNWString("SeveredLimb", "") ~= "head" or not DrawAccesories or not hg.Accessories then return end
	local accessories = ent.GetNetVar and ent:GetNetVar("Accessories", "none") or "none"
	if accessories == "none" or accessories == "" then return end
	local list = istable(accessories) and accessories or {accessories}
	for index = 1, #list do
		local name = list[index]
		local data = hg.Accessories[name]
		if not data then continue end
		if data.bone ~= "ValveBiped.Bip01_Head1" and data.placement ~= "head" and data.placement ~= "face" then continue end
		DrawAccesories(ent, ent, name, data, false, true)
	end
end

local function drawSeveredLimb(ent)
	local cache = getClientBoneCache(ent)
	if not cache then return end
	ent:SetupBones()
	local rootMatrix = ent:GetBoneMatrix(cache.root)
	if not rootMatrix then return end
	local rootPosition = rootMatrix:GetTranslation()
	local rootAngles = rootMatrix:GetAngles()
	for index = 1, #cache.hidden do
		local matrix = ent:GetBoneMatrix(cache.hidden[index])
		if not matrix then continue end
		matrix:SetTranslation(rootPosition)
		matrix:SetAngles(rootAngles)
		matrix:SetScale(zeroScale)
		ent:SetBoneMatrix(cache.hidden[index], matrix)
	end
	ent:DrawModel()
	drawHeadAccessories(ent)
end

local function setupClientSeveredLimb(ent)
	if not IsValid(ent) or ent:GetClass() ~= "prop_ragdoll" or not ent:GetNWBool("IsSeveredLimb", false) then return end
	if ent.HGSeverRenderInstalled then return end
	ent.HGSeverRenderInstalled = true
	clientSeveredLimbs[ent] = true
	ent.RenderOverride = drawSeveredLimb
end

hook.Add("OnEntityCreated", "HGSeveredLimbClientSetup", function(ent)
	timer.Simple(0, function() setupClientSeveredLimb(ent) end)
end)

hook.Add("NetworkEntityCreated", "HGSeveredLimbClientSetup", setupClientSeveredLimb)

hook.Add("Think", "HGSeveredLimbClientSetup", function()
	local now = CurTime()
	if (hg.HGNextSeveredLimbScan or 0) > now then return end
	hg.HGNextSeveredLimbScan = now + 0.35
	for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
		setupClientSeveredLimb(ent)
	end
end)

local activeBleeds = {}

local function getStumpTransform(source, limb)
	local data = hg.SeveredLimbStumps[limb]
	if not IsValid(source) or not data then return end
	if source:IsPlayer() and hg.GetCurrentCharacter then
		local character = hg.GetCurrentCharacter(source)
		if IsValid(character) then source = character end
	end

	local bone = source:LookupBone(data[1])
	if not bone then return end
	local matrix = source:GetBoneMatrix(bone)
	local position, angles
	if matrix then
		position = matrix:GetTranslation()
		angles = matrix:GetAngles()
	else
		position, angles = source:GetBonePosition(bone)
	end
	if not isvector(position) or not isangle(angles) then return end
	return LocalToWorld(data[2], angle_zero, position, angles), angles, source
end

local function addBlood(position, velocity, source, size, impact)
	if not hg.addBloodPart then return end
	hg.addBloodPart(position, velocity, nil, size, size, true, impact, source)
end

net.Receive("hg_severed_limb_effect", function()
	local source = net.ReadEntity()
	local piece = net.ReadEntity()
	local limb = net.ReadString()
	local position = net.ReadVector()
	local force = net.ReadVector()
	local bleedUntil = net.ReadFloat()

	for index = 1, limb == "head" and 5 or 7 do
		local velocity = force * 0.035 + VectorRand(-55, 55)
		velocity.z = velocity.z + math.Rand(20, 85)
		addBlood(position + VectorRand(-2, 2), velocity, IsValid(source) and source or piece, math.Rand(1.4, 2.8), index <= 2)
	end

	activeBleeds[#activeBleeds + 1] = {
		source = source,
		limb = limb,
		position = position,
		untilTime = bleedUntil,
		nextDrop = CurTime()
	}
	if #activeBleeds > 24 then table.remove(activeBleeds, 1) end
end)

hook.Add("Think", "HGSeveredLimbArteries", function()
	if not hg.addBloodPart then return end
	local now = CurTime()
	local localPlayer = LocalPlayer()

	for index = #activeBleeds, 1, -1 do
		local bleed = activeBleeds[index]
		if now > bleed.untilTime or not IsValid(bleed.source) then
			table.remove(activeBleeds, index)
			continue
		end
		if now < bleed.nextDrop then continue end

		local position, angles, source = getStumpTransform(bleed.source, bleed.limb)
		position = position or bleed.position
		if not isvector(position) then continue end
		if IsValid(localPlayer) and localPlayer:GetPos():DistToSqr(position) > 2200 * 2200 then
			bleed.nextDrop = now + 0.35
			continue
		end

		local remaining = math.Clamp((bleed.untilTime - now) / (bleed.limb == "head" and 8 or 12), 0, 1)
		local pulse = 0.45 + math.abs(math.sin(now * 10.5)) * 0.55
		local direction = isangle(angles) and angles:Forward() or vector_up
		local velocity = direction * (45 + 105 * pulse) * remaining + VectorRand(-14, 14)
		velocity.z = velocity.z + 10 + 25 * pulse
		addBlood(position + VectorRand(-1.2, 1.2), velocity, IsValid(source) and source or bleed.source, math.Rand(1.0, 2.0), pulse > 0.86)
		bleed.nextDrop = now + (pulse > 0.86 and math.Rand(0.065, 0.09) or math.Rand(0.12, 0.2))
	end
end)
