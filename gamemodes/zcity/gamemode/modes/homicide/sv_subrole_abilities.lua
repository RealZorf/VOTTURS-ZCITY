local MODE = MODE

util.AddNetworkString("HMCD_BeingVictimOfNeckBreak")
util.AddNetworkString("HMCD_BreakingOtherNeck")
util.AddNetworkString("HMCD_BeingVictimOfDisarmament")
util.AddNetworkString("HMCD_DisarmingOther")
util.AddNetworkString("HMCD_UpdateChemicalResistance")
util.AddNetworkString("HMCD_ChemistNeutralizerTarget")
util.AddNetworkString("HMCD_StalkerMarks")
util.AddNetworkString("HMCD_CannibalStacked")

resource.AddFile("sound/cannibal_eating.mp3")
resource.AddFile("sound/cannibalstacked.wav")

local cannibal_body_gib_models = {
	"models/gibs/hgibs.mdl",
	"models/gibs/hgibs_spine.mdl",
	"models/gibs/hgibs_rib.mdl",
	"models/gibs/hgibs_scapula.mdl"
}

for _, model in ipairs(cannibal_body_gib_models) do
	util.PrecacheModel(model)
end

local cannibal_eating_sound = "cannibal_eating.mp3"
local cannibal_eating_volume = 0.82
local cannibal_eating_pitch_min = 118
local cannibal_eating_pitch_max = 128

local revenantWeaponBlacklist = {
	weapon_hands_sh = true
}

local revenantPossessions = setmetatable({}, {__mode = "k"})

local function getRevenantState(ply)
	if not IsValid(ply) then return nil end
	return revenantPossessions[ply] or ply.Ability_RevenantPossession
end

local function setRevenantState(ply, state)
	if not IsValid(ply) then return end
	revenantPossessions[ply] = state
	ply.Ability_RevenantPossession = state
end

local function captureRevenantVisuals(ent, appearance)
	local accessories = ent.GetNetVar and ent:GetNetVar("Accessories", "") or ""
	if istable(accessories) then accessories = table.Copy(accessories) end

	local visuals = {
		model = ent:GetModel(),
		modelScale = ent:GetModelScale(),
		skin = ent:GetSkin(),
		color = ent:GetColor(),
		playerColor = ent.GetPlayerColor and ent:GetPlayerColor() or nil,
		material = ent:GetMaterial(),
		appearance = table.Copy(appearance or ent.CurAppearance or {}),
		playerName = ent:GetNWString("PlayerName", ""),
		accessories = accessories,
		bodygroups = {},
		submaterials = {}
	}

	for _, bodygroup in ipairs(ent:GetBodyGroups() or {}) do
		visuals.bodygroups[bodygroup.id] = ent:GetBodygroup(bodygroup.id)
	end

	for index = 0, #(ent:GetMaterials() or {}) - 1 do
		visuals.submaterials[index] = ent:GetSubMaterial(index)
	end

	return visuals
end

local function applyRevenantVisuals(ent, visuals)
	if not IsValid(ent) or not visuals then return end

	if visuals.model and util.IsValidModel(visuals.model) then
		ent:SetModel(visuals.model)
	end
	ent:SetModelScale(visuals.modelScale or 1, 0)

	local appearance = visuals.appearance
	if istable(appearance) and appearance.AModel and appearance.AColor and hg.Appearance and hg.Appearance.ForceApplyAppearance then
		ent.CurAppearance = table.Copy(appearance)
		hg.Appearance.ForceApplyAppearance(ent, table.Copy(appearance))
	else
		ent.CurAppearance = istable(appearance) and table.Copy(appearance) or nil
	end
	if istable(appearance) and appearance.AName then
		ent:SetNWString("PlayerName", appearance.AName)
	elseif visuals.playerName ~= "" then
		ent:SetNWString("PlayerName", visuals.playerName)
	end
	if istable(appearance) and appearance.AAttachments then
		ent:SetNetVar("Accessories", table.Copy(appearance.AAttachments))
	elseif ent.SetNetVar and visuals.accessories ~= "" then
		ent:SetNetVar("Accessories", table.Copy(visuals.accessories))
	end
	if visuals.playerColor and ent.SetPlayerColor then ent:SetPlayerColor(visuals.playerColor) end

	ent:SetSkin(visuals.skin or 0)
	ent:SetColor(visuals.color or color_white)
	ent:SetMaterial(visuals.material or "")
	for id, value in pairs(visuals.bodygroups or {}) do ent:SetBodygroup(id, value) end
	for index, material in pairs(visuals.submaterials or {}) do ent:SetSubMaterial(index, material) end
end

local function deferRevenantVisualRestore(ply, visuals)
	if not IsValid(ply) or not visuals then return end

	local timerName = "HMCD_RevenantRestoreVisuals_" .. ply:EntIndex()
	timer.Remove(timerName)
	timer.Create(timerName, 0.1, 10, function()
		if not IsValid(ply) or not ply:Alive() then
			timer.Remove(timerName)
			return
		end

		applyRevenantVisuals(ply, visuals)
	end)
end

local function capturePlayerLoadout(ply)
	local data = {weapons = {}, ammo = {}, inventory = table.Copy(ply:GetNetVar("Inventory", {}) or {}), active = nil}
	for _, wep in ipairs(ply:GetWeapons()) do
		if not IsValid(wep) or revenantWeaponBlacklist[wep:GetClass()] then continue end
		local info = wep.GetInfo and wep:GetInfo() or {Clip1 = wep:Clip1(), Clip2 = wep:Clip2()}
		data.weapons[wep:GetClass()] = istable(info) and table.Copy(info) or true
	end
	for ammoID, count in pairs(ply:GetAmmo()) do
		local name = game.GetAmmoName(ammoID)
		if name and count > 0 then data.ammo[name] = count end
	end
	local active = ply:GetActiveWeapon()
	data.active = IsValid(active) and active:GetClass() or nil
	return data
end

local function captureCorpseLoadout(corpse)
	local networkInventory = corpse:GetNetVar("Inventory", {})
	local localInventory = corpse.inventory
	if not istable(networkInventory) then networkInventory = {} end
	if not istable(localInventory) then localInventory = {} end
	local data = {weapons = {}, ammo = {}, inventory = table.Copy(networkInventory)}

	for key, value in pairs(localInventory) do
		if key ~= "Weapons" then data.inventory[key] = istable(value) and table.Copy(value) or value end
	end

	data.inventory.Weapons = table.Copy(networkInventory.Weapons or {})
	for class, value in pairs(localInventory.Weapons or {}) do
		data.inventory.Weapons[class] = istable(value) and table.Copy(value) or value
	end

	local inventoryWeapons = data.inventory.Weapons
	for class, value in pairs(inventoryWeapons) do
		if isentity(value) and IsValid(value) and value:IsWeapon() then
			local info = value.GetInfo and value:GetInfo() or {Clip1 = value:Clip1(), Clip2 = value:Clip2()}
			data.weapons[class] = istable(info) and table.Copy(info) or true
			value:Remove()
		elseif weapons.Get(class) and istable(value) then
			data.weapons[class] = table.Copy(value)
		elseif weapons.Get(class) and value == true and not revenantWeaponBlacklist[class] then
			data.weapons[class] = true
		end
	end
	for ammoID, count in pairs(data.inventory.Ammo or {}) do
		local name = isnumber(ammoID) and game.GetAmmoName(ammoID) or ammoID
		if name and count > 0 then data.ammo[name] = count end
	end
	return data
end

local function applyLoadout(ply, data)
	if not IsValid(ply) or not data then return end
	ply:SetSuppressPickupNotices(true)
	ply:StripWeapons()
	ply:RemoveAllAmmo()
	ply:Give("weapon_hands_sh")
	local inv = table.Copy(data.inventory or {})
	inv.Weapons = inv.Weapons or {}
	inv.Ammo = inv.Ammo or {}
	ply.inventory = inv
	ply:SetNetVar("Inventory", inv)
	for class, info in pairs(data.weapons or {}) do
		local wep = ply:Give(class)
		if IsValid(wep) and istable(info) then
			if wep.SetInfo then wep:SetInfo(table.Copy(info)) else
				if info.Clip1 then wep:SetClip1(info.Clip1) end
				if info.Clip2 then wep:SetClip2(info.Clip2) end
			end
		end
		if IsValid(wep) then inv.Weapons[class] = wep end
	end
	for name, count in pairs(data.ammo or {}) do ply:GiveAmmo(count, name, true) end
	inv.Ammo = ply:GetAmmo()
	ply:SetNetVar("Inventory", inv)
	if data.active then timer.Simple(0, function() if IsValid(ply) and ply:Alive() then ply:SelectWeapon(data.active) end end) end
	ply:SetSuppressPickupNotices(false)
end

local function copyBodyPose(source, rag)
	for physID = 0, rag:GetPhysicsObjectCount() - 1 do
		local phys = rag:GetPhysicsObjectNum(physID)
		local bone = rag:TranslatePhysBoneToBone(physID)
		local matrix = bone and source:GetBoneMatrix(bone)
		if IsValid(phys) and matrix then
			phys:SetPos(matrix:GetTranslation())
			phys:SetAngles(matrix:GetAngles())
			phys:SetVelocity(source:GetVelocity())
		end
	end
end

local function createRevenantRagdoll(source, appearance)
	local visuals = captureRevenantVisuals(source, appearance)
	local rag = ents.Create("prop_ragdoll")
	if not IsValid(rag) then return nil end
	rag:SetModel(visuals.model)
	rag:SetPos(source:GetPos())
	rag:SetAngles(source:GetAngles())
	rag:Spawn()
	rag:Activate()
	applyRevenantVisuals(rag, visuals)
	copyBodyPose(source, rag)
	return rag
end

local function clearRevenantBleeding(org)
	org.wounds = {}
	org.arterialwounds = {}
	org.bleed = 0
	org.venousBleed = 0
	org.arterialBleed = 0
	org.internalBleed = 0
	org.internalBleedRate = 0
	org.internalBleedHeal = 0
	org.arteria = 0
	org.rarmartery = 0
	org.larmartery = 0
	org.rlegartery = 0
	org.llegartery = 0
	org.spineartery = 0
	org.bleedStart = 0
	org.wantToVomit = 0
	org.vomitInThroat = nil
	org.throatcut = false
	org.throatCutTime = 0
	org.throatCutUntil = 0
	org.throatCutSeverity = 0
	org.throatCutPressureShock = 0
	org.throatCutGurgleNext = 0
end

local revenantNeurologyFields = {
	"brain",
	"brainFrontal",
	"brainParietal",
	"brainTemporal",
	"brainOccipital",
	"brainHemorrhage",
	"brainBleedRate",
	"brainSwelling",
	"intracranialPressure",
	"skull",
	"heart",
	"trachea",
	"pneumothorax"
}

local function stabilizeRevenantNeurology(org)
	local original = {}
	for _, field in ipairs(revenantNeurologyFields) do
		original[field] = tonumber(org[field]) or 0
	end
	original.lungsL = table.Copy(org.lungsL or {0, 0})
	original.lungsR = table.Copy(org.lungsR or {0, 0})

	org.brain = math.min(original.brain, 0.08)
	org.brainFrontal = math.min(original.brainFrontal, 0.15)
	org.brainParietal = math.min(original.brainParietal, 0.15)
	org.brainTemporal = math.min(original.brainTemporal, 0.15)
	org.brainOccipital = math.min(original.brainOccipital, 0.15)
	org.brainHemorrhage = 0
	org.brainBleedRate = 0
	org.brainSwelling = math.min(original.brainSwelling, 0.05)
	org.intracranialPressure = math.min(original.intracranialPressure, 0.05)
	org.skull = math.min(original.skull, 0.35)
	org.heart = math.min(original.heart, 0.2)
	org.trachea = math.min(original.trachea, 0.15)
	org.pneumothorax = math.min(original.pneumothorax, 0.1)
	org.lungsL = table.Copy(original.lungsL)
	org.lungsR = table.Copy(original.lungsR)
	org.lungsL[1] = math.min(tonumber(org.lungsL[1]) or 0, 0.25)
	org.lungsL[2] = math.min(tonumber(org.lungsL[2]) or 0, 0.25)
	org.lungsR[1] = math.min(tonumber(org.lungsR[1]) or 0, 0.25)
	org.lungsR[2] = math.min(tonumber(org.lungsR[2]) or 0, 0.25)
	org.seizure = 0
	org.seizureActive = false
	org.seizureStart = 0
	org.seizureEnd = 0
	org.neckBrainOxygenPenalty = 0
	org.incapacitated = false
	org.critical = false

	return original
end

local function restoreRevenantNeurology(org, original)
	if not original then return end
	for _, field in ipairs(revenantNeurologyFields) do
		org[field] = math.max(tonumber(org[field]) or 0, original[field] or 0)
	end
	org.lungsL = org.lungsL or {0, 0}
	org.lungsR = org.lungsR or {0, 0}
	for index = 1, 2 do
		org.lungsL[index] = math.max(tonumber(org.lungsL[index]) or 0, tonumber(original.lungsL and original.lungsL[index]) or 0)
		org.lungsR[index] = math.max(tonumber(org.lungsR[index]) or 0, tonumber(original.lungsR and original.lungsR[index]) or 0)
	end
end

local function prepareRevenantReturnRagdoll(ply, rag)
	if not IsValid(rag) then return end

	if IsValid(rag.ConsLH) then rag.ConsLH:Remove() end
	if IsValid(rag.ConsRH) then rag.ConsRH:Remove() end
	rag.ConsLH = nil
	rag.ConsRH = nil
	rag.cooldownLH = 0
	rag.cooldownRH = 0
	rag.lastCallTime = SysTime()
	if IsValid(rag.bull) then rag.bull.ply = ply end

	if hg.ApplySetCollisionGroupNow then
		hg.ApplySetCollisionGroupNow(rag, COLLISION_GROUP_WEAPON)
	else
		rag:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	end
	rag:AddEFlags(EFL_NO_DAMAGE_FORCES + EFL_DONTBLOCKLOS)

	local masses = hg.IdealMassPlayer or {}
	for physID = 0, rag:GetPhysicsObjectCount() - 1 do
		local phys = rag:GetPhysicsObjectNum(physID)
		local bone = rag:TranslatePhysBoneToBone(physID)
		if IsValid(phys) then
			phys:SetMass(masses[bone and rag:GetBoneName(bone) or ""] or 4)
			phys:EnableMotion(true)
			phys:EnableGravity(true)
			phys:Wake()
		end
	end

	if hg.ApplyRagdollPhysicsScale then
		hg.ApplyRagdollPhysicsScale(rag, hg.GetPlayerModelScale and hg.GetPlayerModelScale(ply) or ply:GetModelScale())
	end
end

local function getRevenantRagdollPhysicsPos(rag)
	if not IsValid(rag) then return nil end

	local phys = rag:GetPhysicsObject()
	if IsValid(phys) then return phys:GetPos() end

	return rag:WorldSpaceCenter()
end

local function captureRevenantRagdollPose(rag)
	if not IsValid(rag) then return nil end

	local pose = {}
	for physID = 0, rag:GetPhysicsObjectCount() - 1 do
		local phys = rag:GetPhysicsObjectNum(physID)
		if IsValid(phys) then
			pose[physID] = {
				pos = phys:GetPos(),
				ang = phys:GetAngles(),
				velocity = phys:GetVelocity(),
				angularVelocity = phys:GetAngleVelocity()
			}
		end
	end

	return pose
end

local function restoreRevenantRagdollPose(rag, pose)
	if not IsValid(rag) or not istable(pose) then return end

	for physID, data in pairs(pose) do
		local phys = rag:GetPhysicsObjectNum(physID)
		if IsValid(phys) then
			phys:SetPos(data.pos)
			phys:SetAngles(data.ang)
			phys:SetVelocity(data.velocity)
			phys:AddAngleVelocity(data.angularVelocity - phys:GetAngleVelocity())
			phys:EnableMotion(true)
			phys:EnableGravity(true)
			phys:Wake()
		end
	end
end

local function isRevenantRagdollIrrecoverable(rag)
	if not IsValid(rag) then return true end
	if rag.noHead or rag.headexploded or rag.headamputated then return true end
	if istable(rag.gibRemove) and next(rag.gibRemove) ~= nil then return true end

	local organism = rag.organism
	return istable(organism) and (organism.noHead or organism.headamputated) or false
end

local function replaceRevenantPassengerRagdoll(state, passenger, body)
	local pose = IsValid(body) and captureRevenantRagdollPose(body) or nil
	local bodyPos = IsValid(body) and (getRevenantRagdollPhysicsPos(body) or body:GetPos()) or state.ShellLastPos
	local visuals = state.PassengerVisuals
	local replacement = createRevenantRagdoll(passenger, visuals and visuals.appearance)
	if not IsValid(replacement) then return nil end

	if visuals then applyRevenantVisuals(replacement, visuals) end
	if bodyPos then replacement:SetPos(bodyPos) end
	if pose then restoreRevenantRagdollPose(replacement, pose) end

	if IsValid(body) then
		body:RemoveCallOnRemove("Fake")
		body:RemoveCallOnRemove("HMCD_RevenantPassengerFallback")
		if hg.organism and hg.organism.list then hg.organism.list[body] = nil end
		body:Remove()
	end

	state.ShellRagdoll = replacement
	state.ShellLastPos = bodyPos
	return replacement
end

local function forceAttachRevenantPassenger(passenger, body)
	if not IsValid(passenger) or not passenger:Alive() or not IsValid(body) then return false end

	passenger.FakeRagdoll = body
	passenger:SetNWEntity("FakeRagdoll", body)
	body.ply = passenger
	body:SetNWEntity("ply", passenger)
	body:RemoveCallOnRemove("Fake")
	body:CallOnRemove("HMCD_RevenantPassengerFallback", function(removed, owner)
		if not IsValid(owner) or owner.FakeRagdoll ~= removed then return end
		owner.FakeRagdoll = nil
		owner:SetNWEntity("FakeRagdoll", NULL)
		if hg.ragdollFake then hg.ragdollFake[owner] = nil end
		if owner:Alive() then owner:Kill() end
	end, passenger)

	if hg.CacheFakeRagdollData then hg.CacheFakeRagdollData(body) end
	if hg.ragdollFake then hg.ragdollFake[passenger] = body end
	if IsValid(body.bull) then body.bull.ply = passenger end
	passenger.fakecd = CurTime() + 1
	passenger.FakeRagdollOld = nil
	passenger.OldRagdoll = nil
	passenger.ActiveWeapon = passenger:GetActiveWeapon()
	hook.Run("Fake", passenger, body)

	passenger:DrawWorldModel(false)
	passenger:DrawShadow(false)
	passenger:SetNoDraw(false)
	passenger:SetRenderMode(RENDERMODE_NONE)
	if hg.ApplySetCollisionGroupNow then
		hg.ApplySetCollisionGroupNow(passenger, COLLISION_GROUP_IN_VEHICLE)
	else
		passenger:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	end
	if hg.SetFreemove then
		hg.SetFreemove(passenger, false)
	else
		passenger:SetMoveType(MOVETYPE_NOCLIP)
	end
	if passenger:FlashlightIsOn() then passenger:Flashlight(false) end
	passenger:AllowFlashlight(false)

	net.Start("Player Ragdoll")
		net.WriteEntity(passenger)
		net.WriteEntity(body)
	net.Broadcast()
	return true
end

local function clearRevenantNW(ply)
	ply:SetNWBool("HMCD_RevenantPossessing", false)
	ply:SetNWEntity("HMCD_RevenantImplantCorpse", NULL)
	ply:SetNWEntity("HMCD_RevenantOriginalBody", NULL)
	ply:SetNWFloat("HMCD_RevenantImplantStart", 0)
	ply:SetNWFloat("HMCD_RevenantImplantReadyAt", 0)
	ply:SetNWFloat("HMCD_RevenantEndsAt", 0)
end

local function ensureRevenantShellControl(ply, state)
	if not IsValid(ply) or not ply:Alive() or not state then return false end

	if state.ShellStanding then
		local attached = ply.FakeRagdoll
		if IsValid(attached) then
			state.ShellStanding = nil
			state.ShellRagdoll = attached
			state.ShellLastPos = getRevenantRagdollPhysicsPos(attached) or attached:GetPos()
			attached:SetNWBool("HMCD_RevenantLiveEligible", false)
			attached:SetNWBool("HMCD_RevenantUsed", true)
			if IsValid(state.Passenger) then
				state.Passenger:SetNWEntity("HMCD_RevenantPassengerBody", attached)
			end
			return true
		end

		state.ShellLastPos = ply:GetPos()
		if IsValid(state.Passenger) then
			state.Passenger:SetNWEntity("HMCD_RevenantPassengerBody", ply)
		end
		return true
	end

	local shell = state.ShellRagdoll
	if not IsValid(shell) then return false end
	if ply.FakeRagdoll == shell and ply:GetNWEntity("FakeRagdoll", NULL) == shell then return true end

	timer.Remove("faking_up" .. ply:EntIndex())
	local detached = ply.FakeRagdoll
	if IsValid(detached) and detached ~= shell then
		detached.override = true
		detached:Remove()
	end
	ply.FakeRagdoll = nil
	ply:SetNWEntity("FakeRagdoll", NULL)
	ply.FakeRagdollOld = nil
	ply.OldRagdoll = nil
	ply:SetNWEntity("FakeRagdollOld", NULL)
	if hg.ragdollFake then hg.ragdollFake[ply] = nil end

	shell.override = nil
	shell.ply = ply
	shell:SetNWEntity("ply", ply)
	if ply:GetMoveType() == MOVETYPE_NONE then ply:SetMoveType(MOVETYPE_WALK) end
	hg.Fake(ply, shell, true, true)
	return ply.FakeRagdoll == shell
end

local function clearRevenantPassengerLock(passenger)
	if not IsValid(passenger) then return end
	passenger.HMCD_RevenantPassengerController = nil
	passenger.HMCD_RevenantPassengerSyncNext = nil
	passenger:SetNWBool("HMCD_RevenantPassenger", false)
	passenger:SetNWEntity("HMCD_RevenantPassengerController", NULL)
	passenger:SetNWEntity("HMCD_RevenantPassengerBody", NULL)
	passenger:UnSpectate()
	passenger:SetObserverMode(OBS_MODE_NONE)
	passenger:SetViewEntity(passenger)
end

local function lockRevenantPassenger(state, controller, body)
	local passenger = state.Passenger
	if not IsValid(passenger) or not passenger:Alive() or not IsValid(body) then return false end
	timer.Remove("faking_up" .. passenger:EntIndex())

	passenger.HMCD_RevenantPassengerController = controller
	passenger.HMCD_RevenantBodyUsed = true
	passenger:SetNWBool("HMCD_RevenantPassenger", true)
	passenger:SetNWEntity("HMCD_RevenantPassengerController", controller)
	passenger:SetNWEntity("HMCD_RevenantPassengerBody", body)
	passenger:SetHealth(math.max(1, math.min(state.PassengerHealth or passenger:Health(), passenger:GetMaxHealth())))
	body:SetNWBool("HMCD_RevenantLiveEligible", false)
	body:SetNWBool("HMCD_RevenantUsed", true)

	if hg.organism and hg.organism.list then hg.organism.list[passenger] = nil end
	if body.ply == passenger or body:GetNWEntity("ply", NULL) == passenger then body:RemoveCallOnRemove("Fake") end
	passenger.FakeRagdoll = nil
	passenger:SetNWEntity("FakeRagdoll", NULL)
	passenger.FakeRagdollOld = nil
	passenger.OldRagdoll = nil
	passenger:SetNWEntity("FakeRagdollOld", NULL)
	if hg.ragdollFake then hg.ragdollFake[passenger] = nil end

	local viewOrganism = table.Copy(state.PassengerOrganism or {})
	viewOrganism.owner = passenger
	viewOrganism.alive = true
	viewOrganism.otrub = false
	viewOrganism.needotrub = false
	viewOrganism.needfake = false
	viewOrganism.fake = false
	viewOrganism.consciousness = 1
	passenger.organism = viewOrganism
	if hg.send_organism then hg.send_organism(viewOrganism, passenger) end

	passenger:UnSpectate()
	passenger:SetObserverMode(OBS_MODE_NONE)
	passenger:SetViewEntity(passenger)
	passenger:SetMoveType(MOVETYPE_NONE)
	passenger:SetNotSolid(true)
	passenger:SetNoTarget(true)
	if hg.ApplySetCollisionGroupNow then
		hg.ApplySetCollisionGroupNow(passenger, COLLISION_GROUP_IN_VEHICLE)
	else
		passenger:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	end
	passenger:SetPos((getRevenantRagdollPhysicsPos(body) or body:GetPos()) + Vector(0, 0, 8))
	passenger:SetNoDraw(true)
	passenger:DrawWorldModel(false)
	passenger:DrawShadow(false)
	passenger:SetRenderMode(RENDERMODE_NONE)
	return true
end

local function recoverRevenantPassenger(state, controller, passenger)
	if state.PassengerRecovering then return end
	state.PassengerRecovering = true

	timer.Simple(0, function()
		if not IsValid(controller) or not IsValid(passenger) or getRevenantState(controller) ~= state or state.Ending or state.Passenger ~= passenger then
			state.PassengerRecovering = nil
			return
		end

		local function removeProxyRagdoll()
			local rag = passenger:GetNWEntity("RagdollDeath", NULL)
			if not IsValid(rag) then rag = passenger.RagdollDeath end
			if IsValid(rag) and rag ~= state.ShellRagdoll then rag:Remove() end
			passenger.RagdollDeath = nil
			passenger:SetNWEntity("RagdollDeath", NULL)
			if IsValid(passenger.FakeRagdoll) and passenger.FakeRagdoll ~= state.ShellRagdoll then passenger.FakeRagdoll:Remove() end
			passenger.FakeRagdoll = nil
			passenger:SetNWEntity("FakeRagdoll", NULL)
			if hg.ragdollFake then hg.ragdollFake[passenger] = nil end
		end

		removeProxyRagdoll()
		if not passenger:Alive() then
			local previousOverride = OverrideSpawn
			OverrideSpawn = true
			passenger:Spawn()
			OverrideSpawn = previousOverride
		end

		timer.Simple(0, function()
			if not IsValid(controller) or not IsValid(passenger) or getRevenantState(controller) ~= state or state.Ending or state.Passenger ~= passenger then
				state.PassengerRecovering = nil
				return
			end

			removeProxyRagdoll()
			if not passenger:Alive() or not IsValid(state.ShellRagdoll) then
				state.PassengerRecovering = nil
				MODE.EndRevenantPossession(controller, "passenger_link_lost")
				return
			end

			lockRevenantPassenger(state, controller, state.ShellRagdoll)
			applyLoadout(passenger, {weapons = {}, ammo = {}, inventory = {}})
			state.PassengerRecovering = nil
		end)
	end)
end

local function restoreRevenantPassenger(state, body, loadout, markUsed, silent)
	local passenger = state and state.Passenger
	if not IsValid(passenger) or not passenger:Alive() then return false end
	local used = markUsed ~= false

	if not IsValid(body) or isRevenantRagdollIrrecoverable(body) then
		body = replaceRevenantPassengerRagdoll(state, passenger, body)
	end
	if not IsValid(body) then return false end

	local pose = captureRevenantRagdollPose(body)
	local bodyPos = getRevenantRagdollPhysicsPos(body) or body:GetPos()
	clearRevenantPassengerLock(passenger)
	passenger:SetMoveType(MOVETYPE_WALK)
	passenger:SetNotSolid(false)
	passenger:SetNoTarget(state.PassengerNoTarget == true)
	passenger:SetPos(bodyPos + Vector(0, 0, 8))
	if state.PassengerEyeAngles then passenger:SetEyeAngles(state.PassengerEyeAngles) end
	applyRevenantVisuals(passenger, state.PassengerVisuals)
	passenger:SetMaxHealth(state.PassengerMaxHealth or passenger:GetMaxHealth())
	passenger:SetHealth(math.Clamp(state.PassengerHealth or passenger:Health(), 1, passenger:GetMaxHealth()))

	local organism = table.Copy(state.PassengerOrganism or {})
	organism.owner = passenger
	organism.alive = true
	passenger.organism = organism
	if hg.organism and hg.organism.list then
		hg.organism.list[body] = nil
		hg.organism.list[passenger] = organism
	end

	passenger.FakeRagdoll = nil
	if hg.ragdollFake then hg.ragdollFake[passenger] = nil end
	body.ply = passenger
	body:SetNWEntity("ply", passenger)
	body:SetNWBool("HMCD_RevenantLiveEligible", false)
	body:SetNWBool("HMCD_RevenantUsed", used)
	if not used then passenger.HMCD_RevenantBodyUsed = nil end

	prepareRevenantReturnRagdoll(passenger, body)
	if hg.Fake then hg.Fake(passenger, body, true, true) end
	if passenger.FakeRagdoll ~= body then forceAttachRevenantPassenger(passenger, body) end
	if state.PassengerFlashlightAllowed ~= nil then passenger.oldCanUseFlashlight = state.PassengerFlashlightAllowed end
	if passenger.FakeRagdoll ~= body then
		clearRevenantPassengerLock(passenger)
		passenger.FakeRagdoll = nil
		passenger:SetNWEntity("FakeRagdoll", NULL)
		passenger:SetNoDraw(false)
		passenger:DrawWorldModel(true)
		passenger:DrawShadow(true)
		passenger:SetRenderMode(RENDERMODE_NORMAL)
		if state.PassengerFlashlightAllowed ~= nil then passenger:AllowFlashlight(state.PassengerFlashlightAllowed) end
		if hg.ApplySetCollisionGroupNow then
			hg.ApplySetCollisionGroupNow(passenger, COLLISION_GROUP_PLAYER)
		else
			passenger:SetCollisionGroup(COLLISION_GROUP_PLAYER)
		end
		applyLoadout(passenger, loadout or state.PassengerLoadout)
		passenger:SetNetVar("wounds", organism.wounds or {})
		passenger:SetNetVar("arterialwounds", organism.arterialwounds or {})
		passenger.fullsend = true
		if hg.send_bareinfo then hg.send_bareinfo(organism) end
		if hg.send_organism then hg.send_organism(organism, passenger) end
		return false
	end
	restoreRevenantRagdollPose(body, pose)
	prepareRevenantReturnRagdoll(passenger, body)

	applyLoadout(passenger, loadout or state.PassengerLoadout)
	passenger:SetNetVar("wounds", organism.wounds or {})
	passenger:SetNetVar("arterialwounds", organism.arterialwounds or {})
	passenger.fullsend = true
	if hg.send_bareinfo then hg.send_bareinfo(organism) end
	if hg.send_organism then hg.send_organism(organism, passenger) end
	if not silent then passenger:Notify("The neural link released your body.", 0, "revenant_passenger_released", 3, nil, Color(90, 210, 235)) end
	timer.Simple(0, function()
		if not IsValid(passenger) or not IsValid(body) or passenger.FakeRagdoll ~= body then return end
		passenger:SetPos((getRevenantRagdollPhysicsPos(body) or body:GetPos()) + Vector(0, 0, 8))
		prepareRevenantReturnRagdoll(passenger, body)
	end)
	return true
end

local function killRevenantPassengerInShell(state, body, loadout)
	local passenger = state and state.Passenger
	if not IsValid(passenger) or not passenger:Alive() then return false end
	if not IsValid(body) then
		body = createRevenantRagdoll(passenger, state.PassengerVisuals and state.PassengerVisuals.appearance)
		if IsValid(body) and state.ShellLastPos then body:SetPos(state.ShellLastPos) end
	end
	if not IsValid(body) then return false end

	clearRevenantPassengerLock(passenger)
	passenger:SetMoveType(MOVETYPE_WALK)
	passenger:SetNotSolid(false)
	passenger:SetNoTarget(state.PassengerNoTarget == true)
	passenger:SetNoDraw(false)
	passenger:DrawWorldModel(true)
	passenger:DrawShadow(true)
	passenger:SetRenderMode(RENDERMODE_NORMAL)
	passenger:SetPos((getRevenantRagdollPhysicsPos(body) or body:GetPos()) + Vector(0, 0, 8))
	applyRevenantVisuals(passenger, state.PassengerVisuals)
	passenger:SetMaxHealth(state.PassengerMaxHealth or passenger:GetMaxHealth())
	passenger:SetHealth(1)

	local organism = table.Copy(body.organism or state.PassengerOrganism or {})
	organism.owner = passenger
	organism.alive = true
	passenger.organism = organism
	if hg.organism and hg.organism.list then
		hg.organism.list[body] = nil
		hg.organism.list[passenger] = organism
	end

	body:SetNWBool("HMCD_RevenantLiveEligible", false)
	body:SetNWBool("HMCD_RevenantUsed", true)
	body.ply = passenger
	body:SetNWEntity("ply", passenger)
	body.override = nil
	prepareRevenantReturnRagdoll(passenger, body)
	forceAttachRevenantPassenger(passenger, body)
	applyLoadout(passenger, loadout or state.PassengerLoadout)
	passenger:SetNetVar("wounds", organism.wounds or {})
	passenger:SetNetVar("arterialwounds", organism.arterialwounds or {})
	passenger:SetNWEntity("RagdollDeath", body)
	passenger.RagdollDeath = body
	passenger:Kill()
	return true
end

local function playCannibalStackedSound(cannibal)
	local recipients = RecipientFilter()
	local has_recipients = false

	if IsValid(cannibal) and cannibal:IsPlayer() and cannibal:Alive() then
		recipients:AddPlayer(cannibal)
		has_recipients = true
	end

	for _, listener in player.Iterator() do
		if IsValid(listener) and listener ~= cannibal and listener:Alive() then
			recipients:AddPlayer(listener)
			has_recipients = true
		end
	end

	if not has_recipients then return end

	net.Start("HMCD_CannibalStacked")
	net.Send(recipients)
end

local function stopCannibalEatingSound(ply, fade)
	local data = IsValid(ply) and ply.Ability_CannibalConsume or nil
	local snd = data and data.EatingSound
	if not snd then return end

	if fade then
		snd:FadeOut(0.2)
	else
		snd:Stop()
	end

	data.EatingSound = nil
end

MODE.ManiacFuryHarmThreshold = 5
MODE.ManiacFuryAdrenaline = 0.65
MODE.ManiacFuryAdrenalineMax = 0.8
MODE.ManiacFuryAnalgesia = 0.9
MODE.ManiacFuryAnalgesiaMax = 0.95
MODE.ManiacFuryStaminaRegenPerSecond = MODE.ManiacFuryStaminaRegenPerSecond or 26
MODE.ManiacFuryPainCap = MODE.ManiacFuryPainCap or 30
MODE.ManiacFurySecondWindStaminaFraction = 0.65
MODE.ManiacFurySecondWindOxygen = 30
MODE.ManiacFurySecondWindPainCap = 12
MODE.ManiacFuryNoFlinchDuration = 5
MODE.ManiacBloodFrenzyDuration = MODE.ManiacRampageDuration or 15
MODE.ManiacBloodFrenzyMaxStacks = MODE.ManiacRampageMaxStacks or 5
MODE.ManiacBloodFrenzyStaminaRegenPerStack = 12
MODE.ManiacBloodFrenzyImmediateStamina = 9
MODE.ManiacBloodFrenzyImmobilizationRelief = 4
MODE.ManiacRampageMinHarm = 4
MODE.ManiacRampageHitCooldown = 0.18
MODE.ManiacRampageNoFlinchRefresh = 0.7
MODE.ManiacPainConversionStaminaPerHarm = 1.3
MODE.ManiacPainConversionShockRelief = 0.55
MODE.ManiacPainConversionPainRelief = 0.65
MODE.ManiacFuryPhrases = MODE.ManiacFuryPhrases or {
	"NOW IT'S MY TURN",
	"TIME TO GO CRAZY",
	"THIS FEELS UNREAL",
	"I CAN'T FEEL A THING",
	"YOU SHOULD HAVE FINISHED ME"
}
MODE.CannibalWitnessFearRadius = 850
MODE.CannibalWitnessFearCooldown = 3
MODE.CannibalWitnessFearAdd = 0.55
MODE.CannibalWitnessShockAdd = 5
MODE.CannibalWitnessViewDot = math.cos(math.rad(62))

local function canUseShadowCamouflageOnEntity(ent, tr)
	if not tr.Hit or tr.HitSky then
		return false
	end

	if tr.HitWorld then
		return true
	end

	if not IsValid(ent) then
		return false
	end

	if ent:IsPlayer() or ent:IsNPC() or ent:IsWeapon() or ent:IsRagdoll() then
		return false
	end

	if hgIsDoor and hgIsDoor(ent) then
		return true
	end

	local moveType = ent:GetMoveType()
	local isTrigger = ent.IsTrigger and ent:IsTrigger() or false

	return ent:GetSolid() ~= SOLID_NONE and not isTrigger and (moveType == MOVETYPE_NONE or moveType == MOVETYPE_PUSH)
end

function MODE.IsPlayerNearWallForShadowCamouflage(ply)
	local origin = ply:WorldSpaceCenter()
	origin.z = ply:GetPos().z + math.max(ply:OBBMaxs().z * 0.4, 35)

	for yaw = 0, 330, 30 do
		local dir = Angle(0, yaw, 0):Forward()
		local tr = util.TraceLine({
			start = origin,
			endpos = origin + dir * MODE.ShadowCamouflageWallDistance,
			filter = ply,
			mask = MASK_PLAYERSOLID,
		})

		if canUseShadowCamouflageOnEntity(tr.Entity, tr) then
			return true, tr
		end
	end

	return false
end

function MODE.SetShadowCamouflageActive(ply, state)
	if ply.Ability_ShadowCamouflage_Active == state then
		return
	end

	if state then
		ply.Ability_ShadowCamouflage_OriginalColor = ply.Ability_ShadowCamouflage_OriginalColor or ply:GetColor()
		ply.Ability_ShadowCamouflage_OriginalRenderMode = ply.Ability_ShadowCamouflage_OriginalRenderMode or ply:GetRenderMode()

		ply:SetRenderMode(RENDERMODE_TRANSCOLOR)
		local tint = MODE.ShadowCamouflageTint or Color(255, 255, 255, MODE.ShadowCamouflageAlpha)
		ply:SetColor(Color(255, 255, 255, tint.a))
		ply:DrawShadow(false)
		if ply.RemoveAllDecals then
			ply:RemoveAllDecals()
		end
	else
		local clr = ply.Ability_ShadowCamouflage_OriginalColor or color_white

		ply:SetRenderMode(ply.Ability_ShadowCamouflage_OriginalRenderMode or RENDERMODE_NORMAL)
		ply:SetColor(Color(clr.r, clr.g, clr.b, clr.a))
		ply:DrawShadow(true)
	end

	ply.Ability_ShadowCamouflage_Active = state
	ply:SetNWBool("HMCD_ShadowCamouflageActive", state)
end

function MODE.ResetShadowCamouflage(ply)
	ply.Ability_ShadowCamouflage_ChargeStart = nil
	ply.Ability_ShadowCamouflage_LastNearWall = nil
	ply:SetNWFloat("HMCD_ShadowCamouflageChargeStart", 0)
	ply:SetNWFloat("HMCD_ShadowCamouflageReadyAt", 0)

	MODE.SetShadowCamouflageActive(ply, false)
end

local function isStalkerRoundActive()
	if(not MODE.RoleChooseRoundTypes[MODE.Type])then return false end

	local round = CurrentRound and CurrentRound()
	return round == MODE
end

local function normalizeStalkerTarget(ent)
	if not IsValid(ent) then return nil end

	local ply = hg.RagdollOwner and (hg.RagdollOwner(ent) or ent) or ent
	if not IsValid(ply) or not ply:IsPlayer() then return nil end

	return ply
end

local function normalizeStalkerAttacker(ent)
	local ply = normalizeStalkerTarget(ent)
	if IsValid(ply) then return ply end

	if IsValid(ent) and ent.GetOwner then
		ply = normalizeStalkerTarget(ent:GetOwner())
		if IsValid(ply) then return ply end
	end

	return nil
end

function MODE.CanStalkerMarkTarget(stalker, target)
	return IsValid(stalker)
		and IsValid(target)
		and stalker ~= target
		and stalker:IsPlayer()
		and target:IsPlayer()
		and stalker:Alive()
		and target:Alive()
		and stalker.isTraitor
		and not target.isTraitor
		and stalker:Team() ~= TEAM_SPECTATOR
		and target:Team() ~= TEAM_SPECTATOR
end

function MODE.GetStalkerMarks(stalker)
	stalker.Ability_StalkerMarks = stalker.Ability_StalkerMarks or {}
	return stalker.Ability_StalkerMarks
end

function MODE.CleanupStalkerMarks(stalker)
	local marks = MODE.GetStalkerMarks(stalker)

	for i = #marks, 1, -1 do
		local mark = marks[i]
		if not mark or not MODE.CanStalkerMarkTarget(stalker, mark.Target) then
			table.remove(marks, i)
		end
	end

	stalker.Ability_StalkerMarks = marks

	return marks
end

function MODE.IsStalkerTargetMarked(stalker, target)
	local marks = MODE.CleanupStalkerMarks(stalker)

	for i = 1, #marks do
		local mark = marks[i]
		if mark.Target == target then
			return true, mark
		end
	end

	return false
end

function MODE.SyncStalkerMarks(stalker)
	if not IsValid(stalker) then return end

	local valid_marks = MODE.CleanupStalkerMarks(stalker)
	local send_count = math.min(#valid_marks, MODE.StalkerMarkMax)

	net.Start("HMCD_StalkerMarks")
		net.WriteUInt(send_count, 2)
		for i = 1, send_count do
			local mark = valid_marks[i]
			net.WriteEntity(mark.Target)
			net.WriteBool(not mark.StunSpent)
			net.WriteBool(MODE.IsStalkerVictimIsolated(stalker, mark.Target))
		end
	net.Send(stalker)
end

function MODE.ResetStalkerTracking(stalker)
	if not IsValid(stalker) then return end

	stalker.Ability_StalkerMarks = nil
	stalker.Ability_StalkerGazeTarget = nil
	stalker.Ability_StalkerGazeStartedAt = nil
	stalker.Ability_StalkerPursuitTarget = nil
	stalker.Ability_StalkerPursuitLastThink = nil
	stalker.Ability_StalkerNextSenseSync = nil
	stalker:SetNWEntity("HMCD_StalkerGazeTarget", NULL)
	stalker:SetNWFloat("HMCD_StalkerGazeStartedAt", 0)
	stalker:SetNWFloat("HMCD_StalkerGazeReadyAt", 0)
	stalker:SetNWBool("HMCD_StalkerPursuitActive", false)
	stalker:SetNWEntity("HMCD_StalkerPursuitTarget", NULL)

	net.Start("HMCD_StalkerMarks")
		net.WriteUInt(0, 2)
	net.Send(stalker)
end

function MODE.GetStalkerLookTarget(stalker)
	local start_pos = stalker:GetShootPos()
	local aim = stalker:GetAimVector()
	local best_target
	local best_score = MODE.StalkerMarkAngleCos
	local tr = util.TraceLine({
		start = start_pos,
		endpos = start_pos + aim * MODE.StalkerMarkDistance,
		filter = stalker,
		mask = MASK_SHOT
	})

	local target = normalizeStalkerTarget(tr.Entity)
	if MODE.CanStalkerMarkTarget(stalker, target) then
		local offset = target:WorldSpaceCenter() - start_pos
		offset:Normalize()
		if aim:Dot(offset) >= MODE.StalkerMarkAngleCos then
			return target
		end
	end

	for _, ply in player.Iterator() do
		if not MODE.CanStalkerMarkTarget(stalker, ply) then continue end

		local center = ply:WorldSpaceCenter()
		local distance = center:Distance(start_pos)
		if distance > MODE.StalkerMarkDistance then continue end

		local offset = center - start_pos
		offset:Normalize()
		local score = aim:Dot(offset)
		if score < best_score then continue end

		local closest = util.DistanceToLine(start_pos, start_pos + aim * MODE.StalkerMarkDistance, center)
		if closest > MODE.StalkerMarkAssistDistance then continue end

		local blocker = util.TraceLine({
			start = start_pos,
			endpos = center,
			filter = stalker,
			mask = MASK_SHOT
		})

		local blocker_ply = normalizeStalkerTarget(blocker.Entity)
		if blocker.Hit and blocker_ply ~= ply then continue end

		best_score = score
		best_target = ply
	end

	return best_target
end

function MODE.UpdateStalkerTracking(stalker)
	if not isStalkerRoundActive() then return end
	if not MODE.IsStalkerRole or not MODE.IsStalkerRole(stalker.SubRole) then return end

	local now = CurTime()
	local target = MODE.GetStalkerLookTarget(stalker)

	if not IsValid(target) then
		if IsValid(stalker.Ability_StalkerGazeTarget) then
			stalker.Ability_StalkerGazeTarget = nil
			stalker.Ability_StalkerGazeStartedAt = nil
			stalker:SetNWEntity("HMCD_StalkerGazeTarget", NULL)
			stalker:SetNWFloat("HMCD_StalkerGazeStartedAt", 0)
			stalker:SetNWFloat("HMCD_StalkerGazeReadyAt", 0)
		end

		return
	end

	local already_marked = MODE.IsStalkerTargetMarked(stalker, target)
	if already_marked then
		stalker.Ability_StalkerGazeTarget = nil
		stalker.Ability_StalkerGazeStartedAt = nil
		stalker:SetNWEntity("HMCD_StalkerGazeTarget", NULL)
		stalker:SetNWFloat("HMCD_StalkerGazeStartedAt", 0)
		stalker:SetNWFloat("HMCD_StalkerGazeReadyAt", 0)
		return
	end

	local marks = MODE.CleanupStalkerMarks(stalker)
	if #marks >= MODE.StalkerMarkMax then
		stalker.Ability_StalkerGazeTarget = nil
		stalker.Ability_StalkerGazeStartedAt = nil
		stalker:SetNWEntity("HMCD_StalkerGazeTarget", NULL)
		stalker:SetNWFloat("HMCD_StalkerGazeStartedAt", 0)
		stalker:SetNWFloat("HMCD_StalkerGazeReadyAt", 0)
		return
	end

	if stalker.Ability_StalkerGazeTarget ~= target then
		stalker.Ability_StalkerGazeTarget = target
		stalker.Ability_StalkerGazeStartedAt = now
		stalker:SetNWEntity("HMCD_StalkerGazeTarget", target)
		stalker:SetNWFloat("HMCD_StalkerGazeStartedAt", now)
		stalker:SetNWFloat("HMCD_StalkerGazeReadyAt", now + MODE.StalkerMarkTime)
		return
	end

	local started_at = stalker.Ability_StalkerGazeStartedAt or now
	if started_at + MODE.StalkerMarkTime > now then return end

	marks[#marks + 1] = {
		Target = target,
		MarkedAt = now,
		StunSpent = false
	}

	stalker.Ability_StalkerGazeTarget = nil
	stalker.Ability_StalkerGazeStartedAt = nil
	stalker:SetNWEntity("HMCD_StalkerGazeTarget", NULL)
	stalker:SetNWFloat("HMCD_StalkerGazeStartedAt", 0)
	stalker:SetNWFloat("HMCD_StalkerGazeReadyAt", 0)

	if isfunction(stalker.Notify) then
		stalker:Notify("Heartbeat marked.", true, "stalker_mark", 2, nil, Color(80, 210, 255))
	else
		stalker:ChatPrint("Heartbeat marked.")
	end

	MODE.SyncStalkerMarks(stalker)
end

function MODE.IsStalkerVictimIsolated(stalker, victim)
	if not IsValid(stalker) or not IsValid(victim) then return false end

	local victim_pos = victim:GetPos()
	local radius_sqr = (MODE.StalkerIsolatedRadius or 430) ^ 2

	for _, ply in player.Iterator() do
		if ply == victim or ply == stalker then continue end
		if not IsValid(ply) or not ply:Alive() or ply:Team() == TEAM_SPECTATOR then continue end
		if ply.isTraitor then continue end

		if ply:GetPos():DistToSqr(victim_pos) <= radius_sqr then
			return false
		end
	end

	return true
end

function MODE.GetStalkerPursuitPrey(stalker)
	if not IsValid(stalker) then return nil end

	local marks = MODE.CleanupStalkerMarks(stalker)
	local stalker_pos = stalker:GetPos()
	local radius_sqr = (MODE.StalkerPursuitRadius or 1450) ^ 2
	local best_target
	local best_dist_sqr = radius_sqr

	for i = 1, #marks do
		local target = marks[i].Target
		if not MODE.CanStalkerMarkTarget(stalker, target) then continue end
		if not MODE.IsStalkerVictimIsolated(stalker, target) then continue end

		local dist_sqr = target:GetPos():DistToSqr(stalker_pos)
		if dist_sqr <= best_dist_sqr then
			best_target = target
			best_dist_sqr = dist_sqr
		end
	end

	return best_target
end

function MODE.SetStalkerPursuitTarget(stalker, target)
	if not IsValid(stalker) then return end

	local active = IsValid(target)
	if stalker.Ability_StalkerPursuitTarget == target and stalker:GetNWBool("HMCD_StalkerPursuitActive", false) == active then return end

	stalker.Ability_StalkerPursuitTarget = active and target or nil
	stalker:SetNWBool("HMCD_StalkerPursuitActive", active)
	stalker:SetNWEntity("HMCD_StalkerPursuitTarget", active and target or NULL)
end

function MODE.UpdateStalkerPursuit(stalker)
	if not isStalkerRoundActive() or not IsValid(stalker) or not stalker:Alive() then
		MODE.SetStalkerPursuitTarget(stalker, nil)
		return
	end

	local now = CurTime()
	local last_think = stalker.Ability_StalkerPursuitLastThink or now
	local delta = math.Clamp(now - last_think, 0, 0.25)
	stalker.Ability_StalkerPursuitLastThink = now

	local target = MODE.GetStalkerPursuitPrey(stalker)
	MODE.SetStalkerPursuitTarget(stalker, target)

	if not IsValid(target) or delta <= 0 then return end

	local org = stalker.organism
	local stamina = org and org.stamina
	if not stamina then return end

	local max_stamina = stamina.max or stamina.range or 0
	if max_stamina <= 0 then return end

	stamina[1] = math.min(max_stamina, (stamina[1] or max_stamina) + (MODE.StalkerPursuitStaminaRegen or 8) * delta)
end

function MODE.TryStalkerFirstHit(attacker, victim, dmg_info)
	if not isStalkerRoundActive() then return end
	if not IsValid(attacker) or not MODE.IsStalkerRole or not MODE.IsStalkerRole(attacker.SubRole) then return end

	victim = normalizeStalkerTarget(victim)
	if not MODE.CanStalkerMarkTarget(attacker, victim) then return end

	local marked, mark = MODE.IsStalkerTargetMarked(attacker, victim)
	if not marked or not mark or mark.StunSpent then return end

	mark.StunSpent = true
	local isolated = MODE.IsStalkerVictimIsolated(attacker, victim)
	local stun_time = isolated and (MODE.StalkerIsolatedFirstHitStunTime or 2.35) or (MODE.StalkerFirstHitStunTime or 1.35)
	local damage_mul = isolated and (MODE.StalkerIsolatedFirstHitDamageMultiplier or 1.4) or (MODE.StalkerFirstHitDamageMultiplier or 1.15)

	if dmg_info and damage_mul > 1 then
		dmg_info:SetDamage((dmg_info:GetDamage() or 0) * damage_mul)
	end

	if hg.LightStunPlayer then
		hg.LightStunPlayer(victim, stun_time)
	end

	local org = victim.organism
	local stamina = org and org.stamina
	if stamina then
		stamina[1] = math.max((stamina[1] or 0) - (MODE.StalkerFirstHitStaminaDrain or 45), 0)
	end

	victim:ViewPunch(Angle(math.Rand(-7, -3), math.Rand(-4, 4), math.Rand(-4, 4)))
	victim:EmitSound("player/heartbeat1.wav", 55, isolated and 70 or 82, 0.35)

	if isolated then
		if isfunction(attacker.Notify) then
			attacker:Notify("Isolated heartbeat staggered.", true, "stalker_isolated_hit", 2, nil, Color(80, 210, 255))
		else
			attacker:ChatPrint("Isolated heartbeat staggered.")
		end
	end

	MODE.SyncStalkerMarks(attacker)
end

function MODE.IsManiacFuryRoundActive()
	if(not MODE.RoleChooseRoundTypes[MODE.Type])then return false end

	local round = CurrentRound and CurrentRound()
	return round == MODE
end

function MODE.CanTriggerManiacFury(ply)
	return IsValid(ply)
		and ply:IsPlayer()
		and ply:Alive()
		and MODE.IsManiacRole(ply.SubRole)
		and not ply.Ability_ManiacFury_Active
		and not ply.Ability_ManiacFury_Triggered
		and ply.organism ~= nil
end

function MODE.ResetManiacFury(ply)
	if not IsValid(ply) then return end

	ply.Ability_ManiacFury_Active = nil
	ply.Ability_ManiacFury_Triggered = nil
	ply.Ability_ManiacFury_LastThink = nil
	ply.Ability_ManiacFury_NoFlinchUntil = nil
	ply.Ability_ManiacBloodFrenzyUntil = nil
	ply.Ability_ManiacBloodFrenzyStacks = nil
	ply.Ability_ManiacRampageExpiries = nil
	ply.Ability_ManiacRampageHitCooldowns = nil
	ply.Ability_ManiacRampageIncapacitatedVictims = nil
	if ply.HMCDManiacRampageModifiersApplied then
		ply.MeleeDamageMul = ply.HMCDManiacBaseMeleeDamageMul
		ply.MeleeSpeedMul = ply.HMCDManiacBaseMeleeSpeedMul
	end
	ply.HMCDManiacRampageModifiersApplied = nil
	ply.HMCDManiacBaseMeleeDamageMul = nil
	ply.HMCDManiacBaseMeleeSpeedMul = nil
	if ply.organism then
		ply.organism.injuryDefianceGripFloor = nil
	end
	ply:SetNWBool("HMCD_ManiacFuryActive", false)
	ply:SetNWFloat("HMCD_ManiacFuryStartedAt", 0)
	ply:SetNWInt("HMCD_ManiacRampageStacks", 0)
	ply:SetNWFloat("HMCD_ManiacRampageNextDecay", 0)
end

function MODE.ActivateManiacFury(ply)
	if not IsValid(ply) or ply.Ability_ManiacFury_Triggered then return end

	local now = CurTime()
	ply.Ability_ManiacFury_Triggered = true
	ply.Ability_ManiacFury_Active = true
	ply.Ability_ManiacFury_LastThink = now
	ply.Ability_ManiacFury_NoFlinchUntil = now + (MODE.ManiacFuryNoFlinchDuration or 5)
	ply.HMCDManiacRampageModifiersApplied = true
	ply.HMCDManiacBaseMeleeDamageMul = ply.MeleeDamageMul or 1
	ply.HMCDManiacBaseMeleeSpeedMul = ply.MeleeSpeedMul or 1
	ply:SetNWBool("HMCD_ManiacFuryActive", true)
	ply:SetNWFloat("HMCD_ManiacFuryStartedAt", now)
	MODE.ApplyManiacSecondWind(ply)
	MODE.ApplyManiacFury(ply)

	local phrase = MODE.ManiacFuryPhrases[math.random(#MODE.ManiacFuryPhrases)]
	if isfunction(ply.Notify) then
		ply:Notify(phrase, true, "maniac_fury", 0, nil, Color(255, 45, 45))
	else
		ply:ChatPrint(phrase)
	end

	-- Keep fury feedback personal; a world-audible gasp makes the passive an audio beacon.
end

function MODE.GetManiacBloodFrenzyStacks(ply)
	if not IsValid(ply) then return 0 end

	local now = CurTime()
	local expiries = ply.Ability_ManiacRampageExpiries or {}
	for index = #expiries, 1, -1 do
		if expiries[index] <= now then
			table.remove(expiries, index)
		end
	end

	table.sort(expiries)
	ply.Ability_ManiacRampageExpiries = expiries

	local stacks = math.Clamp(#expiries, 0, MODE.ManiacBloodFrenzyMaxStacks or 5)
	local next_decay = expiries[1] or 0
	ply.Ability_ManiacBloodFrenzyStacks = stacks
	ply.Ability_ManiacBloodFrenzyUntil = expiries[#expiries]

	if ply:GetNWInt("HMCD_ManiacRampageStacks", 0) ~= stacks then
		ply:SetNWInt("HMCD_ManiacRampageStacks", stacks)
	end
	if ply:GetNWFloat("HMCD_ManiacRampageNextDecay", 0) ~= next_decay then
		ply:SetNWFloat("HMCD_ManiacRampageNextDecay", next_decay)
	end

	return stacks
end

function MODE.AddManiacBloodFrenzy(ply, harm, victim)
	if not IsValid(ply) or not ply.Ability_ManiacFury_Active then return end

	local org = ply.organism
	if not org then return end
	local amount = math.max(tonumber(harm) or 0, 0)
	if amount < (MODE.ManiacRampageMinHarm or 4) then return end

	local now = CurTime()
	local target = IsValid(victim) and (hg.RagdollOwner and (hg.RagdollOwner(victim) or victim) or victim) or nil
	if IsValid(target) then
		ply.Ability_ManiacRampageHitCooldowns = ply.Ability_ManiacRampageHitCooldowns or {}
		if (ply.Ability_ManiacRampageHitCooldowns[target] or 0) > now then return end
		ply.Ability_ManiacRampageHitCooldowns[target] = now + (MODE.ManiacRampageHitCooldown or 0.18)
	end

	local gain = 1
	if IsValid(target) and target:IsPlayer() then
		local target_org = target.organism
		local incapacitated = not target:Alive() or (target_org and (target_org.otrub or target_org.needotrub or (target_org.consciousness or 1) <= 0.2))
		ply.Ability_ManiacRampageIncapacitatedVictims = ply.Ability_ManiacRampageIncapacitatedVictims or {}

		if incapacitated and not ply.Ability_ManiacRampageIncapacitatedVictims[target] then
			gain = 2
			ply.Ability_ManiacRampageIncapacitatedVictims[target] = true
		elseif not incapacitated then
			ply.Ability_ManiacRampageIncapacitatedVictims[target] = nil
		end
	end

	local expiries = ply.Ability_ManiacRampageExpiries or {}
	local max_stacks = MODE.ManiacBloodFrenzyMaxStacks or 5
	local expires_at = now + (MODE.ManiacBloodFrenzyDuration or 15)
	for _ = 1, gain do
		if #expiries < max_stacks then
			expiries[#expiries + 1] = expires_at
		else
			table.sort(expiries)
			expiries[1] = expires_at
		end
	end

	ply.Ability_ManiacRampageExpiries = expiries
	local stacks = MODE.GetManiacBloodFrenzyStacks(ply)
	ply.Ability_ManiacFury_NoFlinchUntil = math.max(ply.Ability_ManiacFury_NoFlinchUntil or 0, now + (MODE.ManiacRampageNoFlinchRefresh or 0.7))

	local stamina = org.stamina
	if stamina then
		local max_stamina = stamina.max or stamina.range or 0
		if max_stamina > 0 then
			stamina[1] = math.min(max_stamina, (stamina[1] or 0) + (MODE.ManiacBloodFrenzyImmediateStamina or 9) * gain)
		end
	end

	org.immobilization = math.max((org.immobilization or 0) - (MODE.ManiacBloodFrenzyImmobilizationRelief or 4) * gain, 0)
end

function MODE.ApplyManiacPainConversion(ply, harm)
	if not IsValid(ply) or not ply.Ability_ManiacFury_Active then return end

	local org = ply.organism
	if not org then return end

	local amount = math.Clamp(tonumber(harm) or 0, 0, 30)
	if amount <= 0 then return end

	local shock_relief = amount * (MODE.ManiacPainConversionShockRelief or 0.55)
	local pain_relief = amount * (MODE.ManiacPainConversionPainRelief or 0.65)
	org.shock = math.max((org.shock or 0) - shock_relief, 0)
	org.painadd = math.max((org.painadd or 0) - pain_relief, 0)
	org.avgpain = math.max((org.avgpain or 0) - pain_relief * 0.5, 0)
	org.pain = math.max((org.pain or 0) - pain_relief * 0.5, 0)

	local stamina = org.stamina
	if stamina then
		local max_stamina = stamina.max or stamina.range or 0
		if max_stamina > 0 then
			stamina[1] = math.min(max_stamina, (stamina[1] or 0) + amount * (MODE.ManiacPainConversionStaminaPerHarm or 1.3))
		end
	end
end

function MODE.SuppressManiacFlinch(ply)
	if not IsValid(ply) or not ply.Ability_ManiacFury_NoFlinchUntil or ply.Ability_ManiacFury_NoFlinchUntil <= CurTime() then return end

	local org = ply.organism
	if not org then return end

	local now = CurTime()
	if (org.stun or 0) > now then
		org.stun = now
	end

	if (org.lightstun or 0) > now then
		org.lightstun = now
		ply:SetLocalVar("stun", now)
	end

	org.needfake = false
end

function MODE.ApplyManiacSecondWind(ply)
	local org = IsValid(ply) and ply.organism or nil
	if not org then return end

	local stamina = org.stamina
	if stamina then
		local max_stamina = stamina.max or stamina.range or 0
		if max_stamina > 0 then
			stamina[1] = math.max(stamina[1] or 0, max_stamina * MODE.ManiacFurySecondWindStaminaFraction)
		end
	end

	if org.o2 and org.o2[1] then
		org.o2[1] = math.max(org.o2[1], math.min(MODE.ManiacFurySecondWindOxygen, org.o2.range or MODE.ManiacFurySecondWindOxygen))
	end

	org.heartstop = false
	org.shock = math.min(org.shock or 0, MODE.ManiacFurySecondWindPainCap)
	org.avgpain = math.min(org.avgpain or 0, MODE.ManiacFurySecondWindPainCap)
	org.pain = math.min(org.pain or 0, MODE.ManiacFurySecondWindPainCap)
	org.painadd = math.min(org.painadd or 0, MODE.ManiacFurySecondWindPainCap)

	local o2 = org.o2 and org.o2[1] or 30
	local can_stand_back_up = (org.brain or 0) < 0.4 and (org.blood or 5000) >= 2700 and o2 > 5
	if can_stand_back_up then
		org.holdingbreath = false
		org.needotrub = false
		org.otrub = false
		org.uncon_timer = 0
	end
end

function MODE.TryTriggerManiacFury(ply, dmgInfo, harm)
	if not MODE.IsManiacFuryRoundActive() then return end
	if not MODE.CanTriggerManiacFury(ply) then return end

	local damage = dmgInfo and dmgInfo.GetDamage and dmgInfo:GetDamage() or 0
	local serious_harm = math.max(isnumber(harm) and harm or 0, damage)
	if serious_harm < MODE.ManiacFuryHarmThreshold then return end

	MODE.ActivateManiacFury(ply)
end

function MODE.ApplyManiacFury(ply)
	local org = IsValid(ply) and ply.organism or nil
	if not org then return end

	local now = CurTime()
	local delta = math.Clamp(now - (ply.Ability_ManiacFury_LastThink or now), 0, 0.25)
	ply.Ability_ManiacFury_LastThink = now

	org.adrenaline = math.Clamp(org.adrenaline or 0, MODE.ManiacFuryAdrenaline, MODE.ManiacFuryAdrenalineMax)
	org.adrenalineAdd = math.min(org.adrenalineAdd or 0, 0)
	org.analgesia = math.Clamp(org.analgesia or 0, MODE.ManiacFuryAnalgesia, MODE.ManiacFuryAnalgesiaMax)
	org.analgesiaAdd = math.min(org.analgesiaAdd or 0, 0)
	org.heartstop = false
	if not org.larmamputated and not org.rarmamputated then
		org.injuryDefianceGripFloor = MODE.ManiacInjuryDefianceGripFloor or 0.70
	else
		org.injuryDefianceGripFloor = nil
	end

	org.avgpain = math.min(org.avgpain or 0, MODE.ManiacFuryPainCap)
	org.pain = math.min(org.pain or 0, MODE.ManiacFuryPainCap)
	org.painadd = math.min(org.painadd or 0, MODE.ManiacFuryPainCap)
	org.shock = math.min(org.shock or 0, MODE.ManiacFuryPainCap)
	MODE.SuppressManiacFlinch(ply)

	local o2 = org.o2 and org.o2[1] or 30
	local can_override_blackout = (org.brain or 0) < 0.4 and (org.blood or 5000) >= 2700 and o2 > 5
	if can_override_blackout then
		org.needotrub = false
		org.otrub = false
		org.uncon_timer = 0
	end

	local stamina = org.stamina
	local frenzy_stacks = MODE.GetManiacBloodFrenzyStacks(ply)
	ply.MeleeDamageMul = (ply.HMCDManiacBaseMeleeDamageMul or 1) * (1 + frenzy_stacks * (MODE.ManiacRampageMeleeDamagePerStack or 0.06))
	ply.MeleeSpeedMul = (ply.HMCDManiacBaseMeleeSpeedMul or 1) * (1 + frenzy_stacks * (MODE.ManiacRampageMeleeSpeedPerStack or 0.04))
	if stamina then
		local max_stamina = stamina.max or stamina.range or 0
		if max_stamina > 0 then
			local frenzy_regen = frenzy_stacks * (MODE.ManiacBloodFrenzyStaminaRegenPerStack or 12)
			stamina[1] = math.min(max_stamina, (stamina[1] or max_stamina) + (MODE.ManiacFuryStaminaRegenPerSecond + frenzy_regen) * delta)
		end
	end
end

function MODE.GetCannibalStacks(ply)
	if not IsValid(ply) then return 0 end

	return math.Clamp(ply.Ability_CannibalConsumedBodies or 0, 0, MODE.CannibalMaxConsumedBodies or 6)
end

local function canWitnessCannibalFeast(witness, cannibal, corpse, victim, corpse_pos)
	if not IsValid(witness) or witness == cannibal or witness == victim then return false end
	if not witness:IsPlayer() or not witness:Alive() or not witness.organism or witness.organism.otrub then return false end
	if witness:GetShootPos():DistToSqr(corpse_pos) > (MODE.CannibalWitnessFearRadius or 850) ^ 2 then return false end

	local to_corpse = corpse_pos - witness:EyePos()
	if to_corpse:IsZero() then return false end
	if witness:EyeAngles():Forward():Dot(to_corpse:GetNormalized()) < (MODE.CannibalWitnessViewDot or 0.47) then return false end

	local tr = util.TraceLine({
		start = witness:EyePos(),
		endpos = corpse_pos,
		filter = {witness, cannibal},
		mask = MASK_SHOT
	})

	return not tr.Hit or tr.Entity == corpse or tr.Fraction > 0.98
end

function MODE.PulseCannibalWitnessFear(cannibal, corpse, victim, force)
	if not IsValid(cannibal) or not IsValid(corpse) then return end

	local data = cannibal.Ability_CannibalConsume
	if not force and data and (data.NextWitnessFear or 0) > CurTime() then return end
	if data then
		data.NextWitnessFear = CurTime() + (MODE.CannibalWitnessFearCooldown or 3)
	end

	local corpse_pos = corpse:WorldSpaceCenter()
	for _, witness in player.Iterator() do
		if not canWitnessCannibalFeast(witness, cannibal, corpse, victim, corpse_pos) then continue end

		local org = witness.organism
		org.fearadd = math.min((org.fearadd or 0) + (MODE.CannibalWitnessFearAdd or 0.55), 3)
		org.shock = math.min((org.shock or 0) + (MODE.CannibalWitnessShockAdd or 5), 45)
		witness:ViewPunch(Angle(math.Rand(-4, 4), math.Rand(-5, 5), math.Rand(-5, 5)))

		if isfunction(witness.Notify) then
			witness:Notify("What the hell am I watching?", 5, "cannibal_witness_fear", 0, nil, Color(170, 45, 45))
		end
	end
end

function MODE.ApplyCannibalStacks(ply)
	if not IsValid(ply) or not ply.organism or not MODE.IsCannibalRole or not MODE.IsCannibalRole(ply.SubRole) then return end

	local stamina = ply.organism.stamina
	if not stamina then return end

	local stacks = MODE.GetCannibalStacks(ply)
	local base = ply.Ability_CannibalBaseStaminaRange or stamina.range or 180
	ply.Ability_CannibalBaseStaminaRange = base

	local new_range = base + stacks * (MODE.CannibalStaminaBonusPerBody or 22)
	stamina.range = new_range
	stamina.max = math.max(stamina.max or new_range, new_range)
	stamina[1] = math.min(math.max(stamina[1] or new_range, 0), stamina.max)
	ply:SetNWInt("HMCD_CannibalStacks", stacks)
end

function MODE.ResetCannibal(ply)
	if not IsValid(ply) then return end

	MODE.StopCannibalConsume(ply)
	ply.Ability_CannibalConsumedBodies = nil
	ply.Ability_CannibalBaseStaminaRange = nil
	ply:SetNWInt("HMCD_CannibalStacks", 0)
end

function MODE.StartCannibalConsume(ply, corpse, victim)
	if not IsValid(ply) or not MODE.IsCannibalRole or not MODE.IsCannibalRole(ply.SubRole) then return end
	if ply.Ability_CannibalConsume then return end
	if MODE.GetCannibalStacks(ply) >= (MODE.CannibalMaxConsumedBodies or 6) then
		if isfunction(ply.Notify) then
			ply:Notify("I can't stomach any more.", true, "cannibal_full", 2, nil, Color(170, 45, 45))
		else
			ply:ChatPrint("I can't stomach any more.")
		end
		return
	end

	if not IsValid(corpse) or not IsValid(victim) then return end
	if corpse.HMCDCannibalConsumed or (corpse.GetNWBool and corpse:GetNWBool("HMCD_CannibalConsumed", false)) then return end
	if victim == ply or not MODE.IsCannibalConsumableVictim or not MODE.IsCannibalConsumableVictim(victim, corpse) then return end

	local now = CurTime()
	ply.Ability_CannibalConsume = {
		Corpse = corpse,
		Victim = victim,
		StartedAt = now,
		ReadyAt = now + (MODE.GetCannibalConsumeTime and MODE.GetCannibalConsumeTime(ply) or MODE.CannibalConsumeTime or 4.5)
	}

	ply:SetNWEntity("HMCD_CannibalConsumeCorpse", corpse)
	ply:SetNWFloat("HMCD_CannibalConsumeStart", now)
	ply:SetNWFloat("HMCD_CannibalConsumeReadyAt", ply.Ability_CannibalConsume.ReadyAt)

	local eating_sound = CreateSound(corpse, cannibal_eating_sound)
	if eating_sound then
		eating_sound:PlayEx(cannibal_eating_volume, math.random(cannibal_eating_pitch_min, cannibal_eating_pitch_max))
		ply.Ability_CannibalConsume.EatingSound = eating_sound
	end

	MODE.PulseCannibalWitnessFear(ply, corpse, victim, true)
end

local function spawnCannibalBodyGibs(corpse, center, force)
	if not IsValid(corpse) then return end

	local base_velocity = corpse:GetVelocity()
	for i, model in ipairs(cannibal_body_gib_models) do
		local ent = ents.Create("prop_physics")
		if not IsValid(ent) then continue end

		local offset = VectorRand(-18, 18)
		offset.z = math.Rand(4, 20)

		ent:SetModel(model)
		ent:SetPos(center + offset)
		ent:SetAngles(AngleRand(-180, 180))
		ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		ent:DrawShadow(false)
		ent.HMCDCannibalBodyGib = true
		ent:Spawn()
		ent:Activate()

		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then
			local side_force = VectorRand(-90, 90)
			side_force.z = math.Rand(70, 180)
			phys:SetVelocity(base_velocity + side_force + (force or vector_origin) / 12)
			phys:AddAngleVelocity(VectorRand(-220, 220))
		end
	end
end

function MODE.SplatCannibalCorpse(ply, corpse, victim)
	if not IsValid(corpse) or not corpse:IsRagdoll() then return end

	corpse.HMCDCannibalConsumed = true
	if corpse.SetNWBool then
		corpse:SetNWBool("HMCD_CannibalConsumed", true)
	end

	local center = corpse:WorldSpaceCenter()
	local force = VectorRand(-250, 250) + Vector(0, 0, 450)

	local breakSound = "physics/body/body_medium_break3.wav"
	local breakPitch = math.random(85, 100)
	if not hg.EmitOccludedSound or not hg.EmitOccludedSound(corpse, breakSound, 58, breakPitch, 0.75, CHAN_AUTO, center) then
		sound.Play(breakSound, center, 58, breakPitch, 0.75)
	end
	for i = 1, 7 do
		local offset = VectorRand(-22, 22)
		util.Decal("Blood", center + offset + Vector(0, 0, 30), center + offset - Vector(0, 0, 70), corpse)
	end

	if util and util.Effect then
		local effect = EffectData()
		effect:SetOrigin(center)
		effect:SetNormal(VectorRand():GetNormalized())
		effect:SetScale(16)
		util.Effect("BloodImpact", effect, true, true)
	end

	if SpawnMeatGore then
		SpawnMeatGore(corpse, center + Vector(0, 0, 14), 14, force, 0.85)
		SpawnMeatGore(corpse, center - Vector(0, 0, 8), 8, force * 0.65, 0.7)
	end
	spawnCannibalBodyGibs(corpse, center, force)

	local gib_bones = {
		"ValveBiped.Bip01_Head1",
		"ValveBiped.Bip01_Spine2",
		"ValveBiped.Bip01_L_UpperArm",
		"ValveBiped.Bip01_R_UpperArm",
		"ValveBiped.Bip01_L_Thigh",
		"ValveBiped.Bip01_R_Thigh"
	}

	for _, bone_name in ipairs(gib_bones) do
		local bone = corpse:LookupBone(bone_name)
		if not bone then continue end

		if Gib_Input and bone_name == "ValveBiped.Bip01_Head1" then
			Gib_Input(corpse, bone, force)
		elseif Gib_RemoveBone then
			local phys_bone = corpse:TranslateBoneToPhysBone(bone)
			if phys_bone and phys_bone >= 0 then
				Gib_RemoveBone(corpse, bone, phys_bone)
			else
				corpse:ManipulateBoneScale(bone, vector_origin)
			end
		else
			corpse:ManipulateBoneScale(bone, vector_origin)
		end
	end

	corpse:SetNoDraw(true)
	corpse:SetNotSolid(true)
	corpse:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	SafeRemoveEntityDelayed(corpse, 0.2)
end

function MODE.StopCannibalConsume(ply)
	if not IsValid(ply) then return end

	stopCannibalEatingSound(ply, true)

	ply.Ability_CannibalConsume = nil
	ply:SetNWEntity("HMCD_CannibalConsumeCorpse", NULL)
	ply:SetNWFloat("HMCD_CannibalConsumeStart", 0)
	ply:SetNWFloat("HMCD_CannibalConsumeReadyAt", 0)
end

function MODE.FinishCannibalConsume(ply, corpse, victim)
	if not IsValid(ply) or not IsValid(corpse) or not IsValid(victim) then return end
	if corpse.HMCDCannibalConsumed or (corpse.GetNWBool and corpse:GetNWBool("HMCD_CannibalConsumed", false)) then return end
	if victim == ply or not MODE.IsCannibalConsumableVictim or not MODE.IsCannibalConsumableVictim(victim, corpse) then return end

	corpse.HMCDCannibalConsumed = true
	if corpse.SetNWBool then
		corpse:SetNWBool("HMCD_CannibalConsumed", true)
	end

	local max_health = math.max(ply:GetMaxHealth(), 100)
	ply:SetHealth(math.min(max_health, ply:Health() + (MODE.CannibalHealthRestore or 30)))

	local org = ply.organism
	if org then
		org.blood = math.min(5000, (org.blood or 5000) + (MODE.CannibalBloodRestore or 900))
		org.shock = math.max((org.shock or 0) - 15, 0)
		org.avgpain = math.max((org.avgpain or 0) - 10, 0)
		org.pain = math.max((org.pain or 0) - 10, 0)
	end

	local previous_stacks = MODE.GetCannibalStacks(ply)
	local max_stacks = MODE.CannibalMaxConsumedBodies or 6
	ply.Ability_CannibalConsumedBodies = math.min(previous_stacks + 1, max_stacks)
	MODE.ApplyCannibalStacks(ply)

	if previous_stacks < max_stacks and MODE.GetCannibalStacks(ply) >= max_stacks then
		playCannibalStackedSound(ply)
	end

	local pos = corpse:WorldSpaceCenter()
	local consumeSound = "physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav"
	local consumePitch = math.random(75, 90)
	if not hg.EmitOccludedSound or not hg.EmitOccludedSound(corpse, consumeSound, 55, consumePitch, 0.65, CHAN_AUTO, pos) then
		sound.Play(consumeSound, pos, 55, consumePitch, 0.65)
	end

	if victim:Alive() then
		victim.HMCD_CannibalConsumedBy = ply
		victim:Kill()
		timer.Simple(0.08, function()
			if not IsValid(victim) then return end

			local death_rag = victim:GetNWEntity("RagdollDeath", NULL)
			if not IsValid(death_rag) then
				death_rag = IsValid(victim.RagdollDeath) and victim.RagdollDeath or nil
			end
			if not IsValid(death_rag) then
				death_rag = IsValid(corpse) and corpse or nil
			end
			if IsValid(death_rag) then
				MODE.SplatCannibalCorpse(ply, death_rag, victim)
			end
		end)
	else
		MODE.SplatCannibalCorpse(ply, corpse, victim)
	end

	local stacks = MODE.GetCannibalStacks(ply)
	local max_stacks = MODE.CannibalMaxConsumedBodies or 6
	local msg = stacks >= max_stacks and "Fully stacked. Nothing left to consume. (" .. stacks .. "/" .. max_stacks .. ")" or "Consumed. Strength growing. (" .. stacks .. "/" .. max_stacks .. ")"
	if isfunction(ply.Notify) then
		ply:Notify(msg, 0, "cannibal_consume_" .. stacks, 0, nil, Color(170, 45, 45))
	else
		ply:ChatPrint(msg)
	end
end

function MODE.ContinueCannibalConsume(ply)
	local data = IsValid(ply) and ply.Ability_CannibalConsume or nil
	if not data then return end

	local corpse = data.Corpse
	local victim = data.Victim
	if not IsValid(corpse) or not IsValid(victim) or not MODE.IsCannibalConsumableVictim or not MODE.IsCannibalConsumableVictim(victim, corpse) then
		MODE.StopCannibalConsume(ply)
		return
	end

	if corpse.HMCDCannibalConsumed or (corpse.GetNWBool and corpse:GetNWBool("HMCD_CannibalConsumed", false)) then
		MODE.StopCannibalConsume(ply)
		return
	end

	if ply:GetShootPos():DistToSqr(corpse:WorldSpaceCenter()) > ((MODE.CannibalConsumeReach or 95) + 35) ^ 2 then
		MODE.StopCannibalConsume(ply)
		return
	end

	if CurTime() < (data.NextSound or 0) then
		-- no-op
	else
		data.NextSound = CurTime() + 0.9
		if not data.EatingSound then
			local eating_sound = CreateSound(corpse, cannibal_eating_sound)
			if eating_sound then
				eating_sound:PlayEx(cannibal_eating_volume, math.random(cannibal_eating_pitch_min, cannibal_eating_pitch_max))
				data.EatingSound = eating_sound
			end
		end
	end
	MODE.PulseCannibalWitnessFear(ply, corpse, victim)

	if CurTime() < (data.ReadyAt or 0) then return end

	MODE.FinishCannibalConsume(ply, corpse, victim)
	MODE.StopCannibalConsume(ply)
end

function MODE.StopRevenantImplant(ply)
	if not IsValid(ply) then return end
	ply.Ability_RevenantImplant = nil
	ply:SetNWEntity("HMCD_RevenantImplantCorpse", NULL)
	ply:SetNWFloat("HMCD_RevenantImplantStart", 0)
	ply:SetNWFloat("HMCD_RevenantImplantReadyAt", 0)
end

local function isRevenantPassengerIncapacitated(org)
	if not istable(org) then return false end
	if org.otrub == true or org.needotrub == true then return true end

	local forcedDown = (org.tranquilizer or 0) > 0 or (org.neckBrainOxygenPenalty or 0) > 0
	return forcedDown and (org.needfake == true or (org.consciousness or 1) <= 0.4)
end

local function stabilizeInheritedRevenantIncapacitation(org)
	if not istable(org) then return end

	org.tranquilizer = 0
	org.needotrub = false
	org.otrub = false
	org.consciousness = math.max(org.consciousness or 0, 0.95)
	org.uncon_timer = 0
	org.choking = false
	org.neckBrainOxygenPenalty = 0
	org.stun = math.min(org.stun or 0, CurTime() - 1)
	org.lightstun = math.min(org.lightstun or 0, CurTime() - 1)
	org.canmove = (org.spine2 or 0) < hg.organism.fake_spine2 and (org.spine3 or 0) < hg.organism.fake_spine3
	org.canmovehead = (org.spine3 or 0) < hg.organism.fake_spine3
end

local function markRevenantShellDamage(ply, damagedEntity, damage)
	local state = IsValid(ply) and getRevenantState(ply) or nil
	if not state or state.Ending or (tonumber(damage) or 0) <= 0 then return state end
	if IsValid(damagedEntity) and damagedEntity ~= ply and damagedEntity ~= state.ShellRagdoll then return state end
	if CurTime() < (state.ShellDamageArmedAt or 0) then return state end

	state.ShellDamageUntil = math.max(state.ShellDamageUntil or 0, CurTime() + 6)
	return state
end

local function releaseRevenantFiberwire(body)
	if not IsValid(body) then return end

	local strangler = body.Strangler
	if IsValid(strangler) and strangler:IsPlayer() then
		for _, wep in ipairs(strangler:GetWeapons()) do
			if IsValid(wep) and wep:GetClass() == "weapon_hg_fiberwire" and wep.StrangleRag == body and wep.StopStrangling then
				wep:StopStrangling()
				return
			end
		end
	end

	body.Strangler = nil
	body.StrangleLocked = nil
	if body._oldCollisionGroup then
		body:SetCollisionGroup(body._oldCollisionGroup)
		body._oldCollisionGroup = nil
	end
end

function MODE.UpdateRevenantLiveBodyEligibility(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end
	if (ply.HMCD_RevenantLiveEligibilityNext or 0) > CurTime() then return end
	ply.HMCD_RevenantLiveEligibilityNext = CurTime() + 0.1

	local body = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply:GetNWEntity("FakeRagdoll", NULL)
	local previous = ply.HMCD_RevenantLiveBody
	if IsValid(previous) and previous ~= body then previous:SetNWBool("HMCD_RevenantLiveEligible", false) end
	ply.HMCD_RevenantLiveBody = IsValid(body) and body or nil
	if not IsValid(body) then return end

	local org = ply.organism or {}
	local validBrain = not org.headamputated and not org.noHead and not body.headamputated and not body.noHead and not body.headexploded
	local eligible = ply:Alive()
		and isRevenantPassengerIncapacitated(org)
		and not ply.isTraitor
		and not ply.HMCD_RevenantBodyUsed
		and not ply:GetNWBool("HMCD_RevenantPassenger", false)
		and not body:GetNWBool("HMCD_RevenantUsed", false)
		and validBrain

	local wasEligible = body:GetNWBool("HMCD_RevenantLiveEligible", false)
	if wasEligible ~= eligible then
		body:SetNWBool("HMCD_RevenantLiveEligible", eligible)
	end
	if eligible and (not wasEligible or not body.HMCD_RevenantVisuals) then
		body.HMCD_RevenantVisuals = captureRevenantVisuals(body, ply.CurAppearance or body.CurAppearance)
	end
end

function MODE.EndRevenantPossession(ply, reason, originalDead, skipShell)
	local state = getRevenantState(ply)
	if not state or state.Ending then return end
	state.Ending = true
	local passengerShellKilled = IsValid(state.Passenger) and reason == "shell_killed"
	local originalVisuals = state.OriginalVisuals
	local anchor = state.OriginalBody
	local returnPos = IsValid(anchor) and anchor:GetPos() + Vector(0, 0, 8) or state.OriginalReturnPos or state.OriginalPos
	local remainingHealth = IsValid(anchor) and anchor:Health() or state.Health
	local originalBodyMaxHealth = state.OriginalBodyMaxHealth or MODE.RevenantOriginalBodyHealth or 180
	local returnHealth = math.max(1, math.floor((state.Health or 100) * math.Clamp(remainingHealth / originalBodyMaxHealth, 0, 1)))
	local passengerLoadout
	if IsValid(state.Passenger) then
		if skipShell and IsValid(state.ShellRagdoll) then
			passengerLoadout = captureCorpseLoadout(state.ShellRagdoll)
		else
			passengerLoadout = capturePlayerLoadout(ply)
		end
	end
	if IsValid(state.Passenger) and state.ShellStanding and not skipShell and ply:Alive() then
		local standingShell = createRevenantRagdoll(ply, ply.CurAppearance)
		if IsValid(standingShell) then
			standingShell:SetNWBool("HMCD_RevenantLiveEligible", false)
			standingShell:SetNWBool("HMCD_RevenantUsed", true)
			state.ShellRagdoll = standingShell
			state.ShellLastPos = getRevenantRagdollPhysicsPos(standingShell) or standingShell:GetPos()
			state.ShellStanding = nil
		end
	end

	local shellRag
	if not IsValid(state.Passenger) and not skipShell and ply:Alive() then
		shellRag = state.ShellRagdoll
		if not IsValid(shellRag) then
			shellRag = createRevenantRagdoll(ply, ply.CurAppearance)
		end
		if IsValid(shellRag) then
			local shellOrganism = table.Copy(ply.organism or {})
			restoreRevenantNeurology(shellOrganism, state.ShellNeurology)
			shellRag.organism = shellOrganism
			shellRag.organism.owner = shellRag
			shellRag.organism.alive = false
			if hg.organism and hg.organism.list then hg.organism.list[shellRag] = shellRag.organism end
			shellRag:SetNWBool("HMCD_RevenantUsed", true)
			shellRag:SetNWEntity("ply", IsValid(state.ShellOriginalOwner) and state.ShellOriginalOwner or NULL)
			shellRag.ply = IsValid(state.ShellOriginalPly) and state.ShellOriginalPly or nil
			hg.RenewInv(ply, true, shellRag)
			hg.TransferItems(ply, shellRag)
		end
	end

	local originalOrganism = (IsValid(anchor) and istable(anchor.organism) and anchor.organism) or state.OriginalBodyOrganism or state.OriginalOrganism
	if hg.organism and hg.organism.list then
		hg.organism.list[ply] = nil
		if IsValid(anchor) then hg.organism.list[anchor] = nil end
	end
	ply.organism = originalOrganism
	if ply.organism then
		ply.organism.owner = ply
		ply.organism.fakePlayer = nil
		state.OriginalBodyOrganism = ply.organism
		if hg.organism and hg.organism.list then hg.organism.list[ply] = ply.organism end
		ply.organism.wounds = ply.organism.wounds or {}
		ply.organism.arterialwounds = ply.organism.arterialwounds or {}
		ply:SetNetVar("wounds", ply.organism.wounds)
		ply:SetNetVar("arterialwounds", ply.organism.arterialwounds)
		ply.fullsend = true
	end

	if not ply:Alive() and not originalDead then
		ply:Spawn()
	end
	applyRevenantVisuals(ply, originalVisuals)
	ply:SetMaxHealth(state.MaxHealth or 100)
	applyLoadout(ply, state.Loadout)

	ply:SetPos(returnPos)
	ply:SetHealth(math.min(returnHealth, ply:GetMaxHealth()))
	if ply.organism and hg.send_organism then
		hg.send_organism(ply.organism, ply)
	end
	setRevenantState(ply, nil)
	ply.HMCD_RevenantShellDeathReturn = nil
	ply.Ability_RevenantCooldownUntil = CurTime() + (MODE.RevenantPossessionCooldown or 20)
	clearRevenantNW(ply)
	deferRevenantVisualRestore(ply, originalVisuals)
	timer.Simple(1.1, function()
		if not IsValid(ply) or not ply:Alive() or ply.organism ~= originalOrganism then return end

		ply.fullsend = true
		if hg.send_bareinfo then hg.send_bareinfo(ply.organism) end
		if hg.send_organism then hg.send_organism(ply.organism, ply) end
	end)
	if not originalDead then
		timer.Simple(0, function()
			if IsValid(ply) and ply:Alive() then ply:SetPos(returnPos) end
		end)
	end

	if originalDead or (remainingHealth or 0) <= 0 then
		if IsValid(anchor) then anchor:Remove() end
		timer.Simple(0, function() if IsValid(ply) and ply:Alive() then ply:Kill() end end)
	elseif IsValid(anchor) and hg.Fake then
		prepareRevenantReturnRagdoll(ply, anchor)
		hg.Fake(ply, anchor, true, true)
		timer.Simple(0, function()
			if IsValid(ply) and ply.FakeRagdoll == anchor then
				prepareRevenantReturnRagdoll(ply, anchor)
			end
		end)
	end

	if IsValid(state.Passenger) then
		if ply.FakeRagdoll == state.ShellRagdoll then
			ply.FakeRagdoll = nil
			ply:SetNWEntity("FakeRagdoll", NULL)
			if hg.ragdollFake then hg.ragdollFake[ply] = nil end
		end
		if passengerShellKilled then
			killRevenantPassengerInShell(state, state.ShellRagdoll, passengerLoadout or state.PassengerLoadout)
		else
			restoreRevenantPassenger(state, state.ShellRagdoll, passengerLoadout or state.PassengerLoadout)
		end
	end
end

function MODE.BeginRevenantPossession(ply, corpse)
	if not IsValid(ply) or not IsValid(corpse) or not ply:Alive() then return false end
	if not MODE.IsRevenantRole(ply.SubRole) or getRevenantState(ply) then return false end
	local passenger = MODE.GetRevenantPassengerOwner and MODE.GetRevenantPassengerOwner(corpse) or nil
	if corpse:GetNWBool("HMCD_RevenantUsed", false) or (not IsValid(passenger) and not corpse:GetNWBool("HMCD_RevenantEligible", false)) then return false end
	if IsValid(passenger) and (passenger == ply or passenger.isTraitor or not isRevenantPassengerIncapacitated(passenger.organism)) then return false end
	if (ply.Ability_RevenantCharges or 0) <= 0 or (ply.Ability_RevenantCooldownUntil or 0) > CurTime() then return false end

	local appearance = table.Copy(ply.CurAppearance or {})
	local originalVisuals = captureRevenantVisuals(ply, appearance)
	local shellVisuals = table.Copy(corpse.HMCD_RevenantVisuals or captureRevenantVisuals(corpse, corpse.CurAppearance))
	local originalBody = createRevenantRagdoll(ply, appearance)
	if not IsValid(originalBody) then return false end
	local originalBodyHealth = math.max(MODE.RevenantOriginalBodyHealth or 180, ply:Health())
	originalBody:SetHealth(originalBodyHealth)
	originalBody:SetMaxHealth(originalBodyHealth)
	originalBody.HMCD_RevenantOriginalOwner = ply
	originalBody:SetNWBool("HMCD_RevenantOriginalBody", true)

	local state = {
		OriginalBody = originalBody,
		ShellRagdoll = corpse,
		ShellOriginalOwner = corpse:GetNWEntity("ply", NULL),
		ShellOriginalPly = corpse.ply,
		OriginalOrganism = ply.organism,
		Loadout = capturePlayerLoadout(ply),
		Model = ply:GetModel(),
		ModelScale = ply:GetModelScale(),
		Appearance = appearance,
		OriginalVisuals = originalVisuals,
		ShellVisuals = shellVisuals,
		Health = ply:Health(),
		MaxHealth = ply:GetMaxHealth(),
		OriginalBodyMaxHealth = originalBodyHealth,
		OriginalPos = ply:GetPos(),
		OriginalReturnPos = originalBody:GetPos() + Vector(0, 0, 8),
		EndsAt = CurTime() + (MODE.RevenantPossessionTime or 32)
	}
	if IsValid(passenger) then
		local flashlightAllowed = passenger.oldCanUseFlashlight
		if flashlightAllowed == nil then flashlightAllowed = passenger:CanUseFlashlight() end
		state.Passenger = passenger
		state.PassengerOrganism = table.Copy(passenger.organism or {})
		state.PassengerLoadout = capturePlayerLoadout(passenger)
		state.PassengerHealth = passenger:Health()
		state.PassengerMaxHealth = passenger:GetMaxHealth()
		state.PassengerVisuals = captureRevenantVisuals(passenger, passenger.CurAppearance)
		state.PassengerEyeAngles = passenger:EyeAngles()
		state.PassengerFlashlightAllowed = flashlightAllowed
		state.PassengerNoTarget = passenger:IsFlagSet(FL_NOTARGET)
		state.SuppressInheritedIncapacitation = true
		state.ShellDamageArmedAt = CurTime() + 4
	end

	if hg.organism and hg.organism.Add and state.OriginalOrganism then
		local originalBodyOrganism = hg.organism.Add(originalBody)
		table.Merge(originalBodyOrganism, state.OriginalOrganism)
		originalBodyOrganism.owner = originalBody
		originalBodyOrganism.fakePlayer = true
		originalBodyOrganism.alive = true
		state.OriginalBodyOrganism = originalBodyOrganism
		state.OriginalOrganism = originalBodyOrganism
	end

	local function rollback()
		if hg.organism and hg.organism.list then hg.organism.list[ply] = nil end
		if ply.FakeRagdoll == corpse then
			ply.FakeRagdoll = nil
			ply:SetNWEntity("FakeRagdoll", NULL)
			if hg.ragdollFake then hg.ragdollFake[ply] = nil end
		end
		ply.organism = state.OriginalBodyOrganism or state.OriginalOrganism
		if ply.organism then
			ply.organism.owner = ply
			ply.organism.fakePlayer = nil
			ply:SetNetVar("wounds", ply.organism.wounds or {})
			ply:SetNetVar("arterialwounds", ply.organism.arterialwounds or {})
			if hg.organism and hg.organism.list then hg.organism.list[ply] = ply.organism end
		end
		ply:SetPos(state.OriginalPos)
		if IsValid(state.Passenger) then
			restoreRevenantPassenger(state, corpse, state.PassengerLoadout, false, true)
		else
			corpse.ply = IsValid(state.ShellOriginalPly) and state.ShellOriginalPly or nil
			corpse:SetNWEntity("ply", IsValid(state.ShellOriginalOwner) and state.ShellOriginalOwner or NULL)
		end
		originalBody:Remove()
	end

	if IsValid(passenger) then releaseRevenantFiberwire(corpse) end

	local shellSourceOrg = IsValid(passenger) and passenger.organism or corpse.organism
	local shellOrg = table.Copy(shellSourceOrg or {})
	shellOrg.owner = ply
	shellOrg.alive = true
	shellOrg.otrub = false
	shellOrg.needotrub = false
	shellOrg.needfake = false
	shellOrg.fake = false
	shellOrg.heartstop = false
	shellOrg.lungsfunction = true
	shellOrg.CantCheckPulse = true
	shellOrg.blood = math.max(shellOrg.blood or 0, 4000)
	shellOrg.bloodpressure = math.max(shellOrg.bloodpressure or 0, 0.85)
	shellOrg.brainoxygen = math.max(shellOrg.brainoxygen or 0, 0.9)
	shellOrg.perfusion = math.max(shellOrg.perfusion or 0, 0.85)
	shellOrg.peripheralperfusion = math.max(shellOrg.peripheralperfusion or 0, 0.75)
	shellOrg.cerebralPerfusion = math.max(shellOrg.cerebralPerfusion or 0, 0.9)
	shellOrg.consciousness = math.max(shellOrg.consciousness or 0, 0.95)
	shellOrg.pulse = math.max(shellOrg.pulse or 0, 68)
	shellOrg.heartbeat = math.max(shellOrg.heartbeat or 0, 68)
	shellOrg.temperature = math.Clamp(shellOrg.temperature or 36.7, 35.5, 38)
	shellOrg.shock = math.min(shellOrg.shock or 0, 8)
	shellOrg.avgpain = math.min(shellOrg.avgpain or 0, 30)
	shellOrg.pain = math.min(shellOrg.pain or 0, 30)
	shellOrg.painadd = math.min(shellOrg.painadd or 0, 10)
	stabilizeInheritedRevenantIncapacitation(shellOrg)
	shellOrg.holdingbreath = false
	shellOrg.choking = false
	shellOrg.CO = 0
	shellOrg.COregen = 0
	shellOrg.stun = CurTime() - 1
	shellOrg.uncon_timer = 0
	shellOrg.hypoxiaTime = 0
	shellOrg.severeHypoxiaTime = 0
	if shellOrg.o2 then
		shellOrg.o2[1] = math.max(shellOrg.o2[1] or 0, math.min(shellOrg.o2.range or 30, 28))
	end
	clearRevenantBleeding(shellOrg)
	state.ShellNeurology = stabilizeRevenantNeurology(shellOrg)

	if hg.organism and hg.organism.list then hg.organism.list[ply] = nil end
	ply.organism = shellOrg
	if hg.organism and hg.organism.list then hg.organism.list[ply] = shellOrg end

	ply:SetPos(corpse:GetPos() + Vector(0, 0, 8))
	if not hg.Fake then
		rollback()
		return false
	end
	if IsValid(passenger) and not lockRevenantPassenger(state, ply, corpse) then
		rollback()
		return false
	end

	corpse.override = nil
	timer.Remove("faking_up" .. ply:EntIndex())
	corpse.ply = ply
	hg.Fake(ply, corpse, true, true)
	if ply.FakeRagdoll ~= corpse then
		rollback()
		return false
	end

	local corpseLoadout = IsValid(passenger) and state.PassengerLoadout or captureCorpseLoadout(corpse)
	corpse:SetNWBool("HMCD_RevenantUsed", true)
	setRevenantState(ply, state)
	ply.Ability_RevenantCharges = ply.Ability_RevenantCharges - 1
	ply:SetNWInt("HMCD_RevenantCharges", ply.Ability_RevenantCharges)
	if IsValid(passenger) then
		applyLoadout(passenger, {weapons = {}, ammo = {}, inventory = {}})
		passenger:Notify("A neural signal has seized your body. You are only a passenger.", 0, "revenant_passenger_seized", 4, nil, Color(90, 210, 235))
	end
	applyRevenantVisuals(ply, shellVisuals)
	applyLoadout(ply, corpseLoadout)
	ply:SetHealth(math.min(ply:GetMaxHealth(), math.max(25, math.floor((shellOrg.blood or 2500) / 65))))
	ply:SetNWBool("HMCD_RevenantPossessing", true)
	ply:SetNWEntity("HMCD_RevenantOriginalBody", originalBody)
	ply:SetNWFloat("HMCD_RevenantEndsAt", state.EndsAt)
	for _, delay in ipairs({0, 0.1}) do
		timer.Simple(delay, function()
			if not IsValid(ply) or getRevenantState(ply) ~= state then return end
			applyRevenantVisuals(ply, state.ShellVisuals)
		end)
	end
	return true
end

function MODE.StartRevenantImplant(ply, corpse)
	if not IsValid(ply) or not IsValid(corpse) or ply.Ability_RevenantImplant then return end
	if getRevenantState(ply) or (ply.Ability_RevenantCharges or 0) <= 0 then return end
	if (ply.Ability_RevenantCooldownUntil or 0) > CurTime() then
		ply:Notify("The neural link is still recovering.", 0, "revenant_cooldown", 2, nil, Color(180, 210, 190))
		return
	end
	local now = CurTime()
	ply.Ability_RevenantImplant = {Corpse = corpse, ReadyAt = now + (MODE.RevenantImplantTime or 4)}
	ply:SetNWEntity("HMCD_RevenantImplantCorpse", corpse)
	ply:SetNWFloat("HMCD_RevenantImplantStart", now)
	ply:SetNWFloat("HMCD_RevenantImplantReadyAt", ply.Ability_RevenantImplant.ReadyAt)
end

function MODE.ContinueRevenantImplant(ply)
	local data = IsValid(ply) and ply.Ability_RevenantImplant
	if not data then return end
	local corpse, trace = MODE.GetRevenantCorpseTarget(ply)
	if corpse ~= data.Corpse or not trace or ply:GetShootPos():DistToSqr(corpse:WorldSpaceCenter()) > ((MODE.RevenantImplantReach or 100) + 25) ^ 2 then
		MODE.StopRevenantImplant(ply)
		return
	end
	if CurTime() >= data.ReadyAt then
		MODE.StopRevenantImplant(ply)
		MODE.BeginRevenantPossession(ply, corpse)
	end
end

function MODE.UpdateJuggernautCarryState(ply)
	local carried, victim = MODE.GetJuggernautCarryTarget(ply)
	local old_carried = ply.Ability_JuggernautCarriedEnt

	if IsValid(old_carried) and old_carried ~= carried then
		old_carried.HMCD_JuggernautCarryExpire = CurTime() + 0.75
	end

	if IsValid(carried) and IsValid(victim) then
		ply.Ability_JuggernautCarriedEnt = carried
		carried.HMCD_JuggernautCarrier = ply
		carried.HMCD_JuggernautCarryVictim = victim
		carried.HMCD_JuggernautCarryExpire = CurTime() + 0.75
	elseif not IsValid(carried) then
		ply.Ability_JuggernautCarriedEnt = nil
	end
end

function MODE.StartJuggernautStrangle(ply, carried, victim)
	if not IsValid(ply) or not IsValid(carried) or not IsValid(victim) then return end

	local now = CurTime()
	local duration = MODE.JuggernautStrangleTime or 4.25
	ply.Ability_JuggernautStrangle = {
		CarryEnt = carried,
		Victim = victim,
		StartedAt = now,
		ReadyAt = now + duration,
		NextSound = now,
	}

	victim.BeingVictimOfNeckBreak = true
	if victim.organism then
		victim.organism.neckBrainOxygenPenalty = 1
	end

	ply:SetNWFloat("HMCD_JuggernautStrangleStart", now)
	ply:SetNWFloat("HMCD_JuggernautStrangleReadyAt", now + duration)
	ply:SetNWEntity("HMCD_JuggernautStrangleVictim", victim)

	net.Start("HMCD_BeingVictimOfNeckBreak")
		net.WriteBool(true)
	net.Send(victim)

	ply:EmitSound("Flesh.ImpactSoft", 55, math.random(82, 95), 0.55)
end

function MODE.StopJuggernautStrangle(ply)
	if not IsValid(ply) then return end

	local data = ply.Ability_JuggernautStrangle
	if data and IsValid(data.Victim) then
		data.Victim.BeingVictimOfNeckBreak = false
		if data.Victim.organism then
			data.Victim.organism.neckBrainOxygenPenalty = 0
		end

		net.Start("HMCD_BeingVictimOfNeckBreak")
			net.WriteBool(false)
		net.Send(data.Victim)
	end

	ply.Ability_JuggernautStrangle = nil
	ply:SetNWFloat("HMCD_JuggernautStrangleStart", 0)
	ply:SetNWFloat("HMCD_JuggernautStrangleReadyAt", 0)
	ply:SetNWEntity("HMCD_JuggernautStrangleVictim", NULL)
end

function MODE.ResetJuggernaut(ply, force_clear_scale)
	if not IsValid(ply) then return end

	MODE.StopJuggernautStrangle(ply)
	if IsValid(ply.Ability_JuggernautCarriedEnt) then
		ply.Ability_JuggernautCarriedEnt.HMCD_JuggernautCarryExpire = CurTime() + 0.75
	end
	ply.Ability_JuggernautCarriedEnt = nil

	if force_clear_scale or not MODE.IsJuggernautRole or not MODE.IsJuggernautRole(ply.SubRole) then
		ply.HMCDTraitorRoleModelScale = nil
		if ply.HMCDJuggernautStatsApplied then
			ply.HMCDJuggernautStatsApplied = nil
			ply.MeleeDamageMul = nil
			ply.StaminaExhaustMul = nil
			ply.JumpPowerMul = nil
			if ply.organism then
				ply.organism.legstrength = 1
			end
		end

		if hg and hg.ApplyPlayerModelScale then
			hg.ApplyPlayerModelScale(ply)
		elseif ply.SetModelScale then
			ply:SetModelScale(1, 0)
		end
	end
end

function MODE.FinishJuggernautStrangle(ply, victim, carried)
	if not IsValid(ply) or not IsValid(victim) or not victim:Alive() then return end

	if IsValid(carried) then
		carried:EmitSound("physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav", 70, math.random(78, 92), 1)
	end

	local blackout_until = CurTime() + (MODE.JuggernautStrangleBlackoutTime or 12)
	victim.HMCD_JuggernautBlackoutUntil = math.max(victim.HMCD_JuggernautBlackoutUntil or 0, blackout_until)

	local org = victim.organism
	if org then
		org.neckBrainOxygenPenalty = 1
		org.brainoxygen = math.min(org.brainoxygen or 1, MODE.JuggernautStrangleMinBrainOxygen or 0.12)
		org.hypoxiaTime = math.max(org.hypoxiaTime or 0, 20)
		org.severeHypoxiaTime = math.max(org.severeHypoxiaTime or 0, 8)
		org.consciousness = math.min(org.consciousness or 1, 0.05)
		org.needotrub = true
		org.needfake = true
		org.otrub = true
		org.fake = true
		org.stun = math.max(org.stun or 0, CurTime() + (MODE.JuggernautStrangleFinishStunTime or 7))
	end

	if hg and hg.Fake then
		hg.Fake(victim, nil, true, true)
	end
end

function MODE.ContinueJuggernautStrangle(ply)
	local data = IsValid(ply) and ply.Ability_JuggernautStrangle or nil
	if not data then return end

	local can_continue, carried, victim = MODE.CanJuggernautStrangle(ply)
	if not can_continue or victim ~= data.Victim or carried ~= data.CarryEnt then
		MODE.StopJuggernautStrangle(ply)
		return
	end

	local org = victim.organism
	if org then
		local progress = math.Clamp((CurTime() - (data.StartedAt or CurTime())) / math.max((data.ReadyAt or CurTime()) - (data.StartedAt or CurTime()), 0.1), 0, 1)
		local brain_target = Lerp(progress, 0.55, MODE.JuggernautStrangleMinBrainOxygen or 0.12)
		local consciousness_target = Lerp(progress, 0.8, MODE.JuggernautStrangleMinConsciousness or 0.2)

		org.neckBrainOxygenPenalty = 1
		org.brainoxygen = math.min(org.brainoxygen or 1, brain_target)
		org.consciousness = math.min(org.consciousness or 1, consciousness_target)
		org.hypoxiaTime = math.max(org.hypoxiaTime or 0, progress * 14)
		org.severeHypoxiaTime = math.max(org.severeHypoxiaTime or 0, progress * 5)
	end

	if CurTime() >= (data.NextSound or 0) then
		data.NextSound = CurTime() + 0.85
		carried:EmitSound("player/pl_pain" .. math.random(5, 7) .. ".wav", 55, math.random(82, 96), 0.35)
	end

	if CurTime() < (data.ReadyAt or 0) then return end

	MODE.FinishJuggernautStrangle(ply, victim, carried)
	MODE.StopJuggernautStrangle(ply)
end

function MODE.FinishJuggernautStomp(ply, rag, victim)
	if not IsValid(ply) or not IsValid(rag) or not IsValid(victim) or not victim:Alive() then return end
	if not MODE.IsJuggernautRole or not MODE.IsJuggernautRole(ply.SubRole) then return end
	if not victim.organism or victim.organism.otrub ~= true then return end
	if ply:GetShootPos():DistToSqr(rag:WorldSpaceCenter()) > ((MODE.JuggernautStompReach or 105) + 45) ^ 2 then return end
	local owner = hg and hg.RagdollOwner and hg.RagdollOwner(rag) or nil
	if IsValid(owner) and owner ~= victim then return end
	if not IsValid(owner) and victim.FakeRagdoll ~= rag and victim:GetNWEntity("FakeRagdoll", NULL) ~= rag then return end

	local now = CurTime()
	if (victim.HMCD_JuggernautStompFinalizing or 0) > now or (rag.HMCD_JuggernautStompFinalizing or 0) > now then return end
	victim.HMCD_JuggernautStompFinalizing = now + 2
	rag.HMCD_JuggernautStompFinalizing = now + 2

	victim.FakeRagdoll = rag
	victim:SetNWEntity("FakeRagdoll", rag)
	victim:SetNWEntity("RagdollDeath", rag)
	victim.RagdollDeath = rag
	rag.ply = victim
	rag:SetNWEntity("ply", victim)

	local head = rag:LookupBone("ValveBiped.Bip01_Head1")
	local head_pos = head and rag:GetBonePosition(head) or rag:WorldSpaceCenter()
	local force = Vector(0, 0, -900) + ply:GetAimVector() * 180

	local phys_bone = head and rag:TranslateBoneToPhysBone(head) or -1
	local phys = phys_bone and phys_bone >= 0 and rag:GetPhysicsObjectNum(phys_bone) or rag:GetPhysicsObject()
	if IsValid(phys) then
		phys:ApplyForceOffset(force * math.max(phys:GetMass(), 1) * 3, head_pos)
		phys:Wake()
	end

	if victim.organism then
		victim.organism.brain = 1
		victim.organism.skull = 1
		victim.organism.neck = 1
	end

	local stompBreakSound = "physics/body/body_medium_break3.wav"
	local stompBreakPitch = math.random(82, 95)
	if not hg.EmitOccludedSound or not hg.EmitOccludedSound(rag, stompBreakSound, 58, stompBreakPitch, 0.75) then
		rag:EmitSound(stompBreakSound, 58, stompBreakPitch, 0.75)
	end

	local stompFleshSound = "physics/flesh/flesh_squishy_impact_hard" .. math.random(1, 4) .. ".wav"
	local stompFleshPitch = math.random(75, 90)
	if not hg.EmitOccludedSound or not hg.EmitOccludedSound(rag, stompFleshSound, 56, stompFleshPitch, 0.7) then
		rag:EmitSound(stompFleshSound, 56, stompFleshPitch, 0.7)
	end

	if util and util.Effect then
		local effect = EffectData()
		effect:SetOrigin(head_pos)
		effect:SetNormal(Vector(0, 0, 1))
		effect:SetScale(12)
		util.Effect("BloodImpact", effect, true, true)
	end

	util.Decal("Blood", head_pos + Vector(0, 0, 12), head_pos - Vector(0, 0, 38), rag)

	if head then
		if Gib_Input then
			Gib_Input(rag, head, force)
		elseif Gib_RemoveBone and phys_bone and phys_bone >= 0 then
			Gib_RemoveBone(rag, head, phys_bone)
		elseif phys_bone and phys_bone >= 0 then
			rag:RemoveInternalConstraint(phys_bone)
			rag:ManipulateBoneScale(head, vector_origin)
		end
	end

	if zb and zb.HarmDone then
		local harm = math.max(tonumber(zb.MaximumHarm) or 100, 100)
		zb.HarmDone[victim] = zb.HarmDone[victim] or {}
		zb.HarmDone[victim][ply] = math.max(zb.HarmDone[victim][ply] or 0, harm)
		zb.HarmDoneKarma = zb.HarmDoneKarma or {}
		zb.HarmDoneKarma[victim] = zb.HarmDoneKarma[victim] or {}
		zb.HarmDoneKarma[victim][ply] = 0
		zb.HarmDoneDetailed = zb.HarmDoneDetailed or {}
		local victim_id = victim:SteamID()
		local attacker_id = ply:SteamID()
		zb.HarmDoneDetailed[victim_id] = zb.HarmDoneDetailed[victim_id] or {}
		zb.HarmDoneDetailed[victim_id][attacker_id] = {
			harm = harm,
			amt = 1,
			teamVictim = victim:Team(),
			teamAttacker = ply:Team(),
			lasthitgroup = HITGROUP_HEAD,
			lastdmgtype = DMG_CRUSH,
			lastsource = "juggernaut_stomp",
			lastattacked = CurTime(),
		}
		zb.HarmAttacked[ply] = (zb.HarmAttacked[ply] or 0) + harm
		hook.Run("HarmDone", ply, victim, harm)
	end

	victim:Kill()
end

function MODE.StartJuggernautStomp(ply, rag, victim)
	if not IsValid(ply) or not IsValid(rag) or not IsValid(victim) then return end
	if (ply.Ability_JuggernautNextStomp or 0) > CurTime() then return end
	if ply:GetNWFloat("InLegKick", 0) > CurTime() then return end
	if not ply:IsOnGround() or ply:IsSprinting() then return end
	local current_char = hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply)
	if IsValid(current_char) and current_char:IsRagdoll() then return end
	if ply:EyeAngles()[1] < (MODE.JuggernautStompMinPitch or 58) then return end

	ply.Ability_JuggernautNextStomp = CurTime() + (MODE.JuggernautStompCooldown or 1.35)
	if ply.LegAttack then
		ply:LegAttack()
	else
		ply:DoAnimationEvent(ACT_GMOD_GESTURE_MELEE_SHOVE_2HAND)
	end

	timer.Simple(0.33, function()
		if not IsValid(ply) or not IsValid(rag) or not IsValid(victim) then return end
		MODE.FinishJuggernautStomp(ply, rag, victim)
	end)
end

--\\Chemical resistance
local function neutralizerTimerName(ply)
	return "HMCD_ChemistNeutralizer_" .. ply:UserID()
end

function MODE.ClearNeutralizedChemicals(ply)
	if not IsValid(ply) then return end

	if CleanChemicalsOfPlayer then
		CleanChemicalsOfPlayer(ply)
	else
		ply.PassiveAbility_ChemicalAccumulation = {}
	end

	if ply.organism then
		ply.organism.Poison_KCN = nil
		ply.organism.tranquilizer = 0
		ply.organism.poison3 = nil
		ply.organism.poison3notificate = nil
	end
end

function MODE.ClearChemistNeutralizerResistance(ply)
	if not IsValid(ply) then return end

	timer.Remove(neutralizerTimerName(ply))
	ply.Ability_ChemicalResistanceUntil = nil
	ply:SetNWFloat("HMCD_ChemicalResistanceUntil", 0)
end

function MODE.StartChemistNeutralizerResistance(ply)
	if not IsValid(ply) then return end

	MODE.ClearChemistNeutralizerResistance(ply)
	local expires = CurTime() + MODE.ChemistNeutralizerDuration
	local timer_name = neutralizerTimerName(ply)
	ply.Ability_ChemicalResistanceUntil = expires
	ply:SetNWFloat("HMCD_ChemicalResistanceUntil", expires)
	MODE.ClearNeutralizedChemicals(ply)
	if MODE.NetworkChemicalResistanceOfPlayer then
		MODE.NetworkChemicalResistanceOfPlayer(ply)
	end

	timer.Create(timer_name, 0.1, 0, function()
		local active_mode = CurrentRound and CurrentRound()
		if not IsValid(ply) or not ply:Alive() or active_mode ~= MODE or not zb or zb.ROUND_STATE ~= 1
			or ply.Ability_ChemicalResistanceUntil ~= expires or CurTime() >= expires then
			if IsValid(ply) and ply.Ability_ChemicalResistanceUntil == expires then
				ply.Ability_ChemicalResistanceUntil = nil
				ply:SetNWFloat("HMCD_ChemicalResistanceUntil", 0)
			end
			timer.Remove(timer_name)
			return
		end

		MODE.ClearNeutralizedChemicals(ply)
	end)
end

function MODE.UseChemistNeutralizer(ply)
	local active_mode = CurrentRound and CurrentRound()
	if active_mode ~= MODE or not zb or zb.ROUND_STATE ~= 1 then return false end
	if not IsValid(ply) or not ply:Alive() or not ply.isTraitor or not MODE.IsChemistRole(ply.SubRole) then return false end

	local target = MODE.GetChemistNeutralizerTarget(ply)
	if not IsValid(target) then return false end

	local doses = math.max(ply.Ability_ChemistNeutralizerDoses or 0, 0)
	if doses <= 0 then
		ply:Notify("No Neutralizer doses left.", 0, "chemist_neutralizer_empty", 2, nil, Color(80, 220, 150))
		return false
	end
	if target:GetNWFloat("HMCD_ChemicalResistanceUntil", 0) > CurTime() then
		ply:Notify("Their Neutralizer resistance is already active.", 0, "chemist_neutralizer_active", 2, nil, Color(80, 220, 150))
		return false
	end

	doses = doses - 1
	ply.Ability_ChemistNeutralizerDoses = doses
	ply:SetNWInt("HMCD_ChemistNeutralizerDoses", doses)
	MODE.StartChemistNeutralizerResistance(target)

	ply:Notify("Neutralizer administered. " .. doses .. " dose" .. (doses == 1 and "" or "s") .. " left.", 0, "chemist_neutralizer_used", 2, nil, Color(80, 220, 150))
	target:Notify("Chemical resistance active for " .. MODE.ChemistNeutralizerDuration .. " seconds.", 0, "chemist_neutralizer_received", 2, nil, Color(80, 220, 150))
	return true
end

function MODE.UpdateChemistNeutralizerTarget(ply)
	if not IsValid(ply) or not ply:Alive() or not MODE.IsChemistRole(ply.SubRole) then return end
	if (ply.HMCD_ChemistNeutralizerTargetNextUpdate or 0) > CurTime() then return end
	ply.HMCD_ChemistNeutralizerTargetNextUpdate = CurTime() + 0.1

	local target = MODE.GetChemistNeutralizerTarget(ply)
	local next_target = IsValid(target) and target or NULL
	if ply.HMCD_ChemistNeutralizerTarget == next_target then return end

	ply.HMCD_ChemistNeutralizerTarget = next_target

	net.Start("HMCD_ChemistNeutralizerTarget")
		net.WriteEntity(next_target)
	net.Send(ply)
end

	function MODE.NetworkChemicalResistanceOfPlayer(ply)
		ply.PassiveAbility_ChemicalAccumulation = ply.PassiveAbility_ChemicalAccumulation or {}
		
		net.Start("HMCD_UpdateChemicalResistance")
		
		for chemical_name, amt in pairs(ply.PassiveAbility_ChemicalAccumulation) do
			net.WriteString(chemical_name)
			net.WriteUInt(math.Round(amt), MODE.NetSize_ChemicalResistanceBits)
		end
		
		net.WriteString("")
		net.Send(ply)
	end
--

hook.Add("PlayerPostThink", "HMCD_SubRoles_Abilities", function(ply)
	if(MODE.RoleChooseRoundTypes[MODE.Type])then
		if ply:GetNWBool("HMCD_RevenantPassenger", false) and (ply.HMCD_RevenantPassengerSyncNext or 0) <= CurTime() then
			ply.HMCD_RevenantPassengerSyncNext = CurTime() + 0.1
			local controller = ply.HMCD_RevenantPassengerController
			local state = IsValid(controller) and getRevenantState(controller) or nil
			local body = ply:GetNWEntity("HMCD_RevenantPassengerBody", NULL)
			if state and state.Passenger == ply and not state.Ending and IsValid(body) then
				local bodyPos = getRevenantRagdollPhysicsPos(body) or body:GetPos()
				if ply:GetPos():DistToSqr(bodyPos) > 64 then ply:SetPos(bodyPos + Vector(0, 0, 8)) end
			elseif state and not state.Ending then
				MODE.EndRevenantPossession(controller, "passenger_link_lost")
			elseif not IsValid(controller) or not state then
				clearRevenantPassengerLock(ply)
				ply.FakeRagdoll = nil
				ply:SetNWEntity("FakeRagdoll", NULL)
				if hg.ragdollFake then hg.ragdollFake[ply] = nil end
				ply:SetMoveType(MOVETYPE_WALK)
				ply:SetNotSolid(false)
				ply:SetNoTarget(false)
				ply:SetNoDraw(false)
				ply:DrawWorldModel(true)
				ply:DrawShadow(true)
				ply:SetRenderMode(RENDERMODE_NORMAL)
				if hg.ApplySetCollisionGroupNow then
					hg.ApplySetCollisionGroupNow(ply, COLLISION_GROUP_PLAYER)
				else
					ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
				end
			end
		end

		MODE.UpdateRevenantLiveBodyEligibility(ply)
		local revenantState = getRevenantState(ply)
		if revenantState and ply:Alive() then
			if not revenantState.ReturningFromDeath and not ensureRevenantShellControl(ply, revenantState) then
				MODE.EndRevenantPossession(ply, "shell_link_lost")
				return
			end
			if IsValid(revenantState.ShellRagdoll) then revenantState.ShellLastPos = getRevenantRagdollPhysicsPos(revenantState.ShellRagdoll) or revenantState.ShellRagdoll:GetPos() end
			local shellDamageActive = (revenantState.ShellDamageUntil or 0) > CurTime()
			if revenantState.SuppressInheritedIncapacitation and not shellDamageActive then
				stabilizeInheritedRevenantIncapacitation(ply.organism)
			end
			local anchor = revenantState.OriginalBody
			local anchorOrg = IsValid(anchor) and anchor.organism or nil
			local anchorDestroyed = not IsValid(anchor)
				or (anchor:Health() or 0) <= 0
				or anchor.headexploded
				or anchor.noHead
				or (anchorOrg and (anchorOrg.headamputated or anchorOrg.alive == false))

			if anchorDestroyed then
				MODE.EndRevenantPossession(ply, "original_killed", true)
			elseif CurTime() >= revenantState.EndsAt or not ply.organism or ((ply.organism.otrub or (ply.organism.consciousness or 1) < 0.2) and (not revenantState.SuppressInheritedIncapacitation or shellDamageActive)) then
				MODE.EndRevenantPossession(ply, "shell_ended")
			end
		end

		if ply:Alive() and MODE.IsChemistRole(ply.SubRole) then
			MODE.UpdateChemistNeutralizerTarget(ply)
		end

		if(ply:Alive() and ply.organism and not ply.organism.otrub)then
			if MODE.IsChemistRole(ply.SubRole) and ply:KeyDown(IN_WALK) and ply:KeyPressed(IN_USE) then
				MODE.UseChemistNeutralizer(ply)
			end

			if(MODE.IsShadowRole(ply.SubRole))then
				local current_char = hg.GetCurrentCharacter(ply)
				local is_upright = current_char == ply and not IsValid(ply.FakeRagdoll)
				local is_still = ply:IsOnGround() and ply:GetVelocity():Length2DSqr() <= (MODE.ShadowCamouflageMoveSpeed * MODE.ShadowCamouflageMoveSpeed)
				local near_wall = is_upright and is_still and not ply:InVehicle() and MODE.IsPlayerNearWallForShadowCamouflage(ply)
				local now = CurTime()

				if(near_wall)then
					ply.Ability_ShadowCamouflage_LastNearWall = now
				end

				local grace_active = ply.Ability_ShadowCamouflage_LastNearWall and (now - ply.Ability_ShadowCamouflage_LastNearWall) <= MODE.ShadowCamouflageGraceTime

				if(near_wall or grace_active)then
					local charge_start = ply.Ability_ShadowCamouflage_ChargeStart

					if(not charge_start)then
						charge_start = now
						ply.Ability_ShadowCamouflage_ChargeStart = charge_start

						ply:SetNWFloat("HMCD_ShadowCamouflageChargeStart", charge_start)
						ply:SetNWFloat("HMCD_ShadowCamouflageReadyAt", charge_start + MODE.ShadowCamouflageChargeTime)
					elseif(ply:KeyPressed(IN_RELOAD))then
						if(ply.Ability_ShadowCamouflage_Active)then
							MODE.ResetShadowCamouflage(ply)
						elseif(charge_start + MODE.ShadowCamouflageChargeTime <= now)then
							MODE.SetShadowCamouflageActive(ply, true)
						end
					end
				elseif(ply.Ability_ShadowCamouflage_ChargeStart or ply.Ability_ShadowCamouflage_Active)then
					MODE.ResetShadowCamouflage(ply)
				end
			elseif(ply.Ability_ShadowCamouflage_ChargeStart or ply.Ability_ShadowCamouflage_Active)then
				MODE.ResetShadowCamouflage(ply)
			end

			if(ply.SubRole == "traitor_infiltrator" or ply.SubRole == "traitor_infiltrator_soe")then
				if(ply:KeyDown(IN_WALK))then
					if(ply:KeyPressed(IN_RELOAD))then
						local aim_ent, other_ply = hg.eyeTrace(ply,85).Entity
						other_ply = hg.RagdollOwner(aim_ent) or aim_ent
						
						if(IsValid(aim_ent) and aim_ent:IsRagdoll())then	--; REDO
							local other_appearance = aim_ent.CurAppearance
							local your_appearance = ply.CurAppearance

							local aMdl1,aMdl2 = your_appearance.AModel,other_appearance.AModel
							
							other_appearance.AModel = aMdl1
							your_appearance.AModel = aMdl2

							local aFace1,aFace2 = your_appearance.AFacemaps,other_appearance.AFacemaps

							other_appearance.AFacemaps = aFace1
							your_appearance.AFacemaps = aFace2

							hg.Appearance.ForceApplyAppearance(ply, other_appearance, true)
							local char = hg.GetCurrentCharacter(ply)
							if char:IsRagdoll() then
								hg.Appearance.ForceApplyAppearance(char, other_appearance, true)
							end
							ply:EmitSound("snd_jack_hmcd_disguise.wav",35,math.random(90,110),0.5)

							--local duplicator_data = duplicator.CopyEntTable(ply)
							--duplicator.DoGeneric(aim_ent, duplicator_data)
							aim_ent.CurAppearance = your_appearance

							hg.Appearance.ForceApplyAppearance(aim_ent, your_appearance, true)
							
							if other_ply:IsPlayer() and other_ply:Alive() then
								hg.Appearance.ForceApplyAppearance(other_ply, your_appearance, true)
							end
						end
					end
					
					if(ply:KeyPressed(IN_USE))then
						local action = MODE.GetNeckBreakAction(ply)
						if(action == "saw_head")then
							local _, aim_ent, other_ply = MODE.GetFiberwireSawTarget(ply)
							if(IsValid(other_ply) and MODE.CanPlayerSawHeadWithFiberwire(ply, aim_ent, other_ply))then
								MODE.StartBreakingOtherNeck(ply, other_ply, action)
							end
						else
							local aim_ent, other_ply = MODE.GetPlayerTraceToOther(ply)
							
							if(IsValid(aim_ent))then
								if(other_ply and MODE.CanPlayerBreakOtherNeck(ply, aim_ent))then
									MODE.StartBreakingOtherNeck(ply, other_ply, action)
								end
							end
						end
					elseif(ply:KeyDown(IN_USE))then
						if(ply.Ability_NeckBreak)then
							MODE.ContinueBreakingOtherNeck(ply)
						end
					end
					
					if(ply:KeyReleased(IN_USE))then
						MODE.StopBreakingOtherNeck(ply)
					end
				else
					MODE.StopBreakingOtherNeck(ply)
				end
			end
			
			if(MODE.IsAssassinRole and MODE.IsAssassinRole(ply.SubRole))then
				if(ply:KeyDown(IN_WALK))then
					if(ply:KeyPressed(IN_USE))then
						local aim_ent, other_ply, trace = MODE.GetPlayerTraceToOther(ply, nil, MODE.DisarmReach)
						
						if(IsValid(aim_ent))then
							if(other_ply and MODE.CanPlayerDisarmOther(ply, aim_ent, MODE.DisarmReach) and MODE.CanPlayerDisarmOtherPly(ply, other_ply, MODE.DisarmReach))then
								MODE.StartDisarmingOther(ply, other_ply)
							end
						end
					elseif(ply:KeyDown(IN_USE))then
						if(ply.Ability_Disarm)then
							MODE.ContinueDisarmingOther(ply)
						end
					end
					
					if(ply:KeyReleased(IN_USE))then
						MODE.StopDisarmingOther(ply)
					end
				else
					MODE.StopDisarmingOther(ply)
				end
			end
			
			if(ply.SubRole == "traitor_zombie")then
				if(ply:KeyDown(IN_WALK))then
					
				end
			end

			if(MODE.IsChemistRole and MODE.IsChemistRole(ply.SubRole))then
				DegradeChemicalsOfPlayer(ply)
				
				if(!ply.PassiveAbility_ChemicalAccumulation_NextNetworkTime or ply.PassiveAbility_ChemicalAccumulation_NextNetworkTime <= CurTime())then
					MODE.NetworkChemicalResistanceOfPlayer(ply)

					ply.PassiveAbility_ChemicalAccumulation_NextNetworkTime = CurTime() + 1
				end
			end

			if(ply.Ability_ManiacFury_Active)then
				MODE.ApplyManiacFury(ply)
			end

			if(MODE.IsStalkerRole and MODE.IsStalkerRole(ply.SubRole))then
				MODE.UpdateStalkerTracking(ply)
				MODE.UpdateStalkerPursuit(ply)

				if((ply.Ability_StalkerNextSenseSync or 0) <= CurTime())then
					MODE.SyncStalkerMarks(ply)
					ply.Ability_StalkerNextSenseSync = CurTime() + 1
				end
			elseif(ply.Ability_StalkerMarks or IsValid(ply.Ability_StalkerGazeTarget) or IsValid(ply.Ability_StalkerPursuitTarget) or ply:GetNWBool("HMCD_StalkerPursuitActive", false))then
				MODE.ResetStalkerTracking(ply)
			end

			if(MODE.IsCannibalRole and MODE.IsCannibalRole(ply.SubRole))then
				MODE.ApplyCannibalStacks(ply)

				if(ply:KeyDown(IN_WALK))then
					if(ply:KeyPressed(IN_USE))then
						local corpse, victim = MODE.GetCannibalConsumeTarget(ply)
						if(IsValid(corpse) and IsValid(victim))then
							MODE.StartCannibalConsume(ply, corpse, victim)
						end
					elseif(ply:KeyDown(IN_USE))then
						MODE.ContinueCannibalConsume(ply)
					end

					if(ply:KeyReleased(IN_USE))then
						MODE.StopCannibalConsume(ply)
					end
				else
					MODE.StopCannibalConsume(ply)
				end
			elseif(ply.Ability_CannibalConsume or (ply:GetNWInt("HMCD_CannibalStacks", 0) > 0))then
				MODE.ResetCannibal(ply)
			end

			if MODE.IsRevenantRole and MODE.IsRevenantRole(ply.SubRole) and not getRevenantState(ply) then
				if ply:KeyDown(IN_WALK) then
					if ply:KeyPressed(IN_USE) then
						local corpse = MODE.GetRevenantCorpseTarget(ply)
						if IsValid(corpse) then MODE.StartRevenantImplant(ply, corpse) end
					elseif ply:KeyDown(IN_USE) then
						MODE.ContinueRevenantImplant(ply)
					end
					if ply:KeyReleased(IN_USE) then MODE.StopRevenantImplant(ply) end
				else
					MODE.StopRevenantImplant(ply)
				end
			elseif ply.Ability_RevenantImplant then
				MODE.StopRevenantImplant(ply)
			end

			if(MODE.IsJuggernautRole and MODE.IsJuggernautRole(ply.SubRole))then
				MODE.UpdateJuggernautCarryState(ply)

				local can_strangle, carried, victim = MODE.CanJuggernautStrangle(ply)
				if(can_strangle and ply:KeyDown(IN_WALK))then
					if(not ply.Ability_JuggernautStrangle)then
						MODE.StartJuggernautStrangle(ply, carried, victim)
					end

					MODE.ContinueJuggernautStrangle(ply)
				else
					MODE.StopJuggernautStrangle(ply)
				end

				if((not can_strangle) and ply:KeyDown(IN_WALK) and ply:KeyPressed(IN_USE))then
					local rag, stomp_victim = MODE.GetJuggernautStompTarget(ply)
					if(IsValid(rag) and IsValid(stomp_victim))then
						MODE.StartJuggernautStomp(ply, rag, stomp_victim)
					end
				end
			elseif(ply.Ability_JuggernautStrangle or IsValid(ply.Ability_JuggernautCarriedEnt))then
				MODE.ResetJuggernaut(ply)
			end
		else
			if(ply.Ability_ShadowCamouflage_ChargeStart or ply.Ability_ShadowCamouflage_Active)then
				MODE.ResetShadowCamouflage(ply)
			end

			if(ply.Ability_StalkerMarks or IsValid(ply.Ability_StalkerGazeTarget) or IsValid(ply.Ability_StalkerPursuitTarget) or ply:GetNWBool("HMCD_StalkerPursuitActive", false))then
				MODE.ResetStalkerTracking(ply)
			end

			if(ply.Ability_CannibalConsume)then
				MODE.StopCannibalConsume(ply)
			end

			if(ply.Ability_JuggernautStrangle)then
				MODE.ResetJuggernaut(ply)
			end
		end
	end
end)

hook.Add("Ragdoll Collide", "HMCD_SubRoles_JuggernautOverpowerImpact", function(rag, data)
	if not IsValid(rag) or not data then return end
	if (rag.HMCD_JuggernautCarryExpire or 0) < CurTime() then return end
	if (rag.HMCD_JuggernautNextImpact or 0) > CurTime() then return end

	local attacker = rag.HMCD_JuggernautCarrier
	local victim = rag.HMCD_JuggernautCarryVictim or (hg and hg.RagdollOwner and hg.RagdollOwner(rag))
	if not IsValid(attacker) or not MODE.IsJuggernautRole(attacker.SubRole) then return end
	if not IsValid(victim) or not victim:IsPlayer() or not victim:Alive() then return end
	if not MODE.IsJuggernautVictimSmallEnough(attacker, victim) then return end

	local speed = math.max(data.Speed or 0, data.OurOldVelocity and data.OurOldVelocity:Length() or 0)
	if speed < (MODE.JuggernautImpactMinSpeed or 340) then return end

	local hit = data.HitEntity
	if IsValid(hit) and hit:IsPlayer() then return end

	rag.HMCD_JuggernautNextImpact = CurTime() + (MODE.JuggernautImpactCooldown or 1.25)

	timer.Simple(0, function()
		if not IsValid(attacker) or not IsValid(victim) or not victim:Alive() then return end

		local dmg = DamageInfo()
		dmg:SetAttacker(attacker)
		dmg:SetInflictor(IsValid(rag) and rag or attacker)
		dmg:SetDamage(MODE.JuggernautImpactDamage or 18)
		dmg:SetDamageType(DMG_CLUB)
		dmg:SetDamagePosition(data.HitPos or victim:WorldSpaceCenter())
		dmg:SetDamageForce((data.OurOldVelocity or attacker:GetAimVector() * speed) * 0.65)
		victim:TakeDamageInfo(dmg)

		if hg and hg.LightStunPlayer then
			hg.LightStunPlayer(victim, MODE.JuggernautImpactStunTime or 1.4)
		end
	end)
end)

hook.Add("HomigradDamage", "HMCD_SubRoles_ManiacFuryTrigger", function(victim, dmgInfo, hitgroup, ent, harm)
	local ply = IsValid(victim) and victim or ent
	ply = hg.RagdollOwner and (hg.RagdollOwner(ply) or ply) or ply
	local rawDamage = dmgInfo and dmgInfo.GetDamage and dmgInfo:GetDamage() or 0
	markRevenantShellDamage(ply, IsValid(ent) and ent or victim, math.max(tonumber(harm) or 0, rawDamage))

	MODE.TryTriggerManiacFury(ply, dmgInfo, harm)
	MODE.ApplyManiacPainConversion(ply, harm)
	MODE.SuppressManiacFlinch(ply)
	if IsValid(ply) and ply.Ability_ManiacFury_NoFlinchUntil and ply.Ability_ManiacFury_NoFlinchUntil > CurTime() then
		timer.Simple(0, function()
			if IsValid(ply) then
				MODE.SuppressManiacFlinch(ply)
			end
		end)
	end

	local attacker = dmgInfo and dmgInfo:GetAttacker()
	attacker = normalizeStalkerAttacker(attacker)
	if not IsValid(attacker) or attacker == ply or not MODE.IsManiacRole(attacker.SubRole) or not attacker.Ability_ManiacFury_Active then return end
	if not dmgInfo or not dmgInfo.IsDamageType then return end

	local melee_damage = dmgInfo:IsDamageType(DMG_CLUB) or dmgInfo:IsDamageType(DMG_SLASH)
	if not melee_damage then return end

	MODE.AddManiacBloodFrenzy(attacker, harm, ply)
end)

function MODE.CheckLastManStandingFinalStand(excluded_ply)
	local active_mode = CurrentRound and CurrentRound()
	if active_mode ~= MODE or not zb or zb.ROUND_STATE ~= 1 then return end

	local living_traitors = {}
	for _, ply in player.Iterator() do
		if ply ~= excluded_ply and IsValid(ply) and ply:Alive() and ply.isTraitor then
			living_traitors[#living_traitors + 1] = ply
		end
	end

	for _, ply in player.Iterator() do
		if not MODE.IsLastManStandingRole(ply.SubRole) then
			if ply.Ability_LMSFinalStand or ply:GetNWBool("HMCD_LMSFinalStand", false) then
				ply.Ability_LMSHadLivingTeammate = nil
				ply.Ability_LMSFinalStand = nil
				ply:SetNWBool("HMCD_LMSFinalStand", false)
				ply:SetNWFloat("HMCD_LMSFinalStandMultiplier", 1)
			end
		elseif ply:Alive() and ply.isTraitor and not ply.Ability_LMSFinalStand then
			local has_teammate = false
			for _, teammate in ipairs(living_traitors) do
				if teammate ~= ply then
					has_teammate = true
					break
				end
			end

			if has_teammate then
				ply.Ability_LMSHadLivingTeammate = true
			elseif ply.Ability_LMSHadLivingTeammate then
				ply.Ability_LMSFinalStand = true
				ply:SetNWBool("HMCD_LMSFinalStand", true)
				ply:SetNWFloat("HMCD_LMSFinalStandMultiplier", MODE.LMSFinalStandMultiplier)
				ply:Notify("All my teammates are dead, time for the last stand", 0, "lms_final_stand", 3, nil, Color(255, 190, 60))
			end
		end
	end
end

hook.Add("PlayerDeath", "HMCD_SubRoles_LastManStandingFinalStand", function()
	timer.Simple(0, function()
		MODE.CheckLastManStandingFinalStand()
	end)
end)

hook.Add("PlayerDisconnected", "HMCD_SubRoles_LastManStandingFinalStand", function(disconnected_ply)
	timer.Simple(0, function()
		MODE.CheckLastManStandingFinalStand(disconnected_ply)
	end)
end)

hook.Add("ZB_PreRoundStart", "HMCD_SubRoles_ResetRoundBuffs", function()
	for _, ply in player.Iterator() do
		MODE.ClearChemistNeutralizerResistance(ply)
		ply.Ability_ChemistNeutralizerDoses = nil
		ply:SetNWInt("HMCD_ChemistNeutralizerDoses", 0)
		ply.Ability_LMSHadLivingTeammate = nil
		ply.Ability_LMSFinalStand = nil
		ply:SetNWBool("HMCD_LMSFinalStand", false)
		ply:SetNWFloat("HMCD_LMSFinalStandMultiplier", 1)
	end
end)

hook.Add("HG_PlayerFootstep", "HMCD_SubRoles_StalkerSilentPursuit", function(ply, pos, foot, sound, volume, rf)
	if not IsValid(ply) or not ply:GetNWBool("HMCD_StalkerPursuitActive", false) then return end
	if not MODE.IsStalkerRole or not MODE.IsStalkerRole(ply.SubRole) then return end

	EmitSound(sound, pos, ply:EntIndex(), CHAN_AUTO, (volume or 1) * (MODE.StalkerPursuitFootstepVolume or 0.28), 70, nil, math.random(92, 98))

	return true
end)

hook.Add("StartCommand", "HMCD_RevenantPassengerInput", function(ply, cmd)
	if not ply:GetNWBool("HMCD_RevenantPassenger", false) then return end
	cmd:ClearButtons()
	cmd:ClearMovement()
end)

hook.Add("SetupPlayerVisibility", "HMCD_RevenantPassengerVisibility", function(ply)
	if not ply:GetNWBool("HMCD_RevenantPassenger", false) then return end
	local body = ply:GetNWEntity("HMCD_RevenantPassengerBody", NULL)
	if IsValid(body) then AddOriginToPVS(body:GetPos()) end
end)

hook.Add("Should Fake Up", "HMCD_RevenantPassengerFakeUp", function(ply)
	if ply:GetNWBool("HMCD_RevenantPassenger", false) then return false end
	if getRevenantState(ply) and not ply.HG_FakeUpRequestedByPlayer then return false end
end, -1)

hook.Add("Fake Up", "HMCD_RevenantShellFakeUp", function(ply, rag)
	local state = getRevenantState(ply)
	if not state or not ply.HG_FakeUpRequestedByPlayer or rag ~= state.ShellRagdoll then return end

	state.ShellLastPos = getRevenantRagdollPhysicsPos(rag) or rag:GetPos()
	state.ShellStanding = true
	state.ShellRagdoll = nil
	if IsValid(state.Passenger) then
		state.Passenger:SetNWEntity("HMCD_RevenantPassengerBody", ply)
	end
end, -1)

hook.Add("PlayerSwitchWeapon", "HMCD_RevenantPassengerWeapon", function(ply)
	if ply:GetNWBool("HMCD_RevenantPassenger", false) then return true end
end, -1)

hook.Add("PlayerUse", "HMCD_RevenantPassengerUse", function(ply)
	if ply:GetNWBool("HMCD_RevenantPassenger", false) then return false end
end, -1)

hook.Add("PlayerCanPickupWeapon", "HMCD_RevenantPassengerWeaponPickup", function(ply)
	if ply:GetNWBool("HMCD_RevenantPassenger", false) then return false end
end, -1)

hook.Add("AllowPlayerPickup", "HMCD_RevenantPassengerPickup", function(ply)
	if ply:GetNWBool("HMCD_RevenantPassenger", false) then return false end
end, -1)

hook.Add("CanPlayerEnterVehicle", "HMCD_RevenantPassengerVehicle", function(ply)
	if ply:GetNWBool("HMCD_RevenantPassenger", false) then return false end
end, -1)

hook.Add("PlayerSay", "HMCD_RevenantPassengerPlayerSay", function(ply)
	if ply:GetNWBool("HMCD_RevenantPassenger", false) then return "" end
end, -1)

hook.Add("HG_PlayerSay", "HMCD_RevenantPassengerChat", function(ply, text)
	if not ply:GetNWBool("HMCD_RevenantPassenger", false) or not istable(text) then return end
	text[1] = ""
	return true
end, -1)

hook.Add("HG_PlayerCanHearPlayersVoice", "HMCD_RevenantPassengerVoice", function(listener, speaker)
	if IsValid(speaker) and speaker:GetNWBool("HMCD_RevenantPassenger", false) then return false, false end
end, -1)

hook.Add("EntityTakeDamage", "HMCD_RevenantPassengerDamage", function(victim, dmgInfo)
	if IsValid(victim) and victim:IsPlayer() and victim:GetNWBool("HMCD_RevenantPassenger", false) then
		dmgInfo:SetDamage(0)
	end
end, -2)

hook.Add("EntityTakeDamage", "HMCD_SubRoles_ManiacFuryFallTrigger", function(victim, dmgInfo)
	if IsValid(victim) and IsValid(victim.HMCD_RevenantOriginalOwner) then
		local owner = victim.HMCD_RevenantOriginalOwner
		local state = getRevenantState(owner)
		if state then
			local damage = math.max(dmgInfo:GetDamage(), 0) * (MODE.RevenantOriginalBodyDamageMul or 0.35)
			victim.HMCD_RevenantProtectedHealth = math.max(victim:Health() - damage, 0)
			victim.HMCD_RevenantProtectedOwner = owner
		end
		return
	end

	local revenantState = IsValid(victim) and victim:IsPlayer() and markRevenantShellDamage(victim, victim, dmgInfo:GetDamage()) or nil

	if revenantState and dmgInfo:GetDamage() >= victim:Health() then
		dmgInfo:SetDamage(0)
		timer.Simple(0, function() if IsValid(victim) then MODE.EndRevenantPossession(victim, "shell_killed") end end)
		return
	end

	local ply = IsValid(victim) and victim or nil
	ply = hg.RagdollOwner and (hg.RagdollOwner(ply) or ply) or ply

	MODE.TryTriggerManiacFury(ply, dmgInfo)
	if IsValid(ply) and ply.Ability_ManiacFury_Active and dmgInfo then
		if dmgInfo:IsDamageType(DMG_FALL + DMG_CRUSH) then
			MODE.ApplyManiacPainConversion(ply, dmgInfo:GetDamage())
		end

		MODE.SuppressManiacFlinch(ply)
	end

	local attacker = dmgInfo and dmgInfo:GetAttacker()
	attacker = normalizeStalkerAttacker(attacker)
	MODE.TryStalkerFirstHit(attacker, victim, dmgInfo)

	if IsValid(attacker) and MODE.IsCannibalRole and MODE.IsCannibalRole(attacker.SubRole) then
		local stacks = MODE.GetCannibalStacks(attacker)
		if stacks > 0 then
			local inflictor = dmgInfo:GetInflictor()
			local damage_type = dmgInfo:GetDamageType()
			local melee_damage = bit.band(damage_type, DMG_CLUB) ~= 0 or bit.band(damage_type, DMG_SLASH) ~= 0
			local melee_weapon = IsValid(inflictor) and inflictor:IsWeapon() and (inflictor.Base == "weapon_melee" or inflictor:GetClass() == "weapon_hands_sh" or inflictor.DamagePrimary ~= nil)

			if melee_damage and melee_weapon then
				local bonus = 1 + math.min(stacks, MODE.CannibalMaxConsumedBodies or 6) * (MODE.CannibalMeleeDamageBonusPerBody or 0.08)
				dmgInfo:SetDamage(dmgInfo:GetDamage() * bonus)
			end
		end
	end
end)

hook.Add("PostEntityTakeDamage", "HMCD_RevenantOriginalBodyDamage", function(victim)
	if not IsValid(victim) then return end

	local remaining = victim.HMCD_RevenantProtectedHealth
	if not isnumber(remaining) then return end

	local owner = victim.HMCD_RevenantProtectedOwner
	victim.HMCD_RevenantProtectedHealth = nil
	victim.HMCD_RevenantProtectedOwner = nil
	victim:SetHealth(remaining)
	if remaining <= 0 then
		timer.Simple(0, function()
			if IsValid(owner) then MODE.EndRevenantPossession(owner, "original_killed", true) end
		end)
	end
end)

hook.Add("CanPlayerSuicide", "HMCD_RevenantShellSuicide", function(ply)
	if ply:GetNWBool("HMCD_RevenantPassenger", false) then return false end
	if not getRevenantState(ply) then return end
	MODE.EndRevenantPossession(ply, "shell_killed")
	return false
end, -1)

hook.Add("PlayerSpawn", "HMCD_SubRoles_ShadowCamouflage", function(ply)
	local passengerController = ply.HMCD_RevenantPassengerController
	local passengerState = IsValid(passengerController) and getRevenantState(passengerController) or nil
	if passengerState and passengerState.Passenger == ply and not passengerState.Ending then
		timer.Simple(0, function()
			if not IsValid(passengerController) or getRevenantState(passengerController) ~= passengerState or passengerState.Ending then return end

			local body = passengerState.ShellRagdoll
			if IsValid(body) then
				lockRevenantPassenger(passengerState, passengerController, body)
				applyLoadout(ply, {weapons = {}, ammo = {}, inventory = {}})
			else
				MODE.EndRevenantPossession(passengerController, "passenger_link_lost")
			end
		end)
		return
	end

	if not OverrideSpawn then
		clearRevenantPassengerLock(ply)
		ply.HMCD_RevenantBodyUsed = nil
		if IsValid(ply.HMCD_RevenantLiveBody) then ply.HMCD_RevenantLiveBody:SetNWBool("HMCD_RevenantLiveEligible", false) end
		ply.HMCD_RevenantLiveBody = nil
	end
	ply.HMCD_JuggernautBlackoutUntil = nil
	MODE.ResetShadowCamouflage(ply)
	if not OverrideSpawn then
		MODE.ResetManiacFury(ply)
	end
	MODE.ResetStalkerTracking(ply)
	MODE.StopCannibalConsume(ply)
	MODE.ResetJuggernaut(ply)
	MODE.StopRevenantImplant(ply)
	if not MODE.IsRevenantRole(ply.SubRole) then
		ply.Ability_RevenantCharges = nil
		ply:SetNWInt("HMCD_RevenantCharges", 0)
	end
end)

hook.Add("PlayerDeath", "HMCD_SubRoles_ShadowCamouflage", function(ply)
	local passengerController = ply.HMCD_RevenantPassengerController
	if IsValid(passengerController) then
		local controllerState = getRevenantState(passengerController)
		if controllerState and controllerState.Passenger == ply and not controllerState.Ending then
			recoverRevenantPassenger(controllerState, passengerController, ply)
			return
		end
		clearRevenantPassengerLock(ply)
	end

	local revenantState = getRevenantState(ply)
	if revenantState and not revenantState.Ending then
		if revenantState.ReturningFromDeath then return end
		revenantState.ReturningFromDeath = true
		revenantState.PendingShellReturn = true
		ply.HMCD_RevenantShellDeathReturn = true
		return
	end

	ply.HMCD_JuggernautBlackoutUntil = nil
	MODE.ResetShadowCamouflage(ply)
	MODE.ResetManiacFury(ply)
	MODE.ResetStalkerTracking(ply)
	MODE.StopCannibalConsume(ply)
	MODE.ResetJuggernaut(ply, true)
	MODE.StopRevenantImplant(ply)
	for _, stalker in player.Iterator() do
		if IsValid(stalker) and stalker.Ability_StalkerMarks then
			MODE.SyncStalkerMarks(stalker)
		end
	end
end)

local function markRevenantCorpse(rag, wasTraitor, visuals, resetUsed)
	if not IsValid(rag) or not rag:IsRagdoll() then return end

	if resetUsed then
		rag:SetNWBool("HMCD_RevenantTraitorCorpse", wasTraitor)
	else
		wasTraitor = wasTraitor or rag:GetNWBool("HMCD_RevenantTraitorCorpse", false)
	end

	local org = rag.organism or {}
	local validBrain = not org.headamputated and not org.noHead and not rag.headamputated and not rag.noHead and not rag.headexploded
	local eligible = not wasTraitor and validBrain and not rag:GetNWBool("HMCD_CannibalConsumed", false)
	rag:SetNWBool("HMCD_RevenantEligible", eligible)
	if resetUsed then rag:SetNWBool("HMCD_RevenantUsed", false) end
	rag.HMCD_RevenantVisuals = table.Copy(visuals or captureRevenantVisuals(rag, rag.CurAppearance))
end

hook.Add("RagdollDeath", "HMCD_RevenantMarkCorpseEarly", function(ply, rag)
	if not IsValid(ply) or not ply:IsPlayer() or getRevenantState(ply) then return end
	markRevenantCorpse(rag, ply.isTraitor == true, captureRevenantVisuals(rag, ply.CurAppearance or rag.CurAppearance), true)
	if ply.HMCD_RevenantBodyUsed and IsValid(rag) then rag:SetNWBool("HMCD_RevenantUsed", true) end
end)

hook.Add("PostPostPlayerDeath", "HMCD_RevenantMarkCorpse", function(ply, rag)
	if not IsValid(rag) then return end
	local revenantState = getRevenantState(ply)
	if revenantState and revenantState.PendingShellReturn and not revenantState.Ending then
		revenantState.PendingShellReturn = nil
		revenantState.ShellRagdoll = rag
		revenantState.ShellLastPos = getRevenantRagdollPhysicsPos(rag) or rag:GetPos()
		if IsValid(revenantState.Passenger) then
			revenantState.Passenger:SetNWEntity("HMCD_RevenantPassengerBody", rag)
		end
		if istable(rag.organism) then restoreRevenantNeurology(rag.organism, revenantState.ShellNeurology) end
		rag:SetNWBool("HMCD_RevenantUsed", true)
		timer.Simple(0, function()
			timer.Simple(0, function()
				if IsValid(ply) and getRevenantState(ply) == revenantState then
					MODE.EndRevenantPossession(ply, "shell_killed", false, true)
				end
			end)
		end)
		return
	end

	markRevenantCorpse(rag, ply.isTraitor == true, captureRevenantVisuals(rag, ply.CurAppearance or rag.CurAppearance), true)
	if ply.HMCD_RevenantBodyUsed then rag:SetNWBool("HMCD_RevenantUsed", true) end
end)

hook.Add("PlayerDisconnected", "HMCD_RevenantDisconnectedCorpse", function(ply)
	if not IsValid(ply) then return end

	local wasTraitor = ply.isTraitor == true
	local visuals = captureRevenantVisuals(ply, ply.CurAppearance)

	local rag = ply:GetNWEntity("RagdollDeath", NULL)
	if not IsValid(rag) then rag = ply.RagdollDeath end
	if not IsValid(rag) then rag = ply.FakeRagdoll end
	if not IsValid(rag) or rag:GetNWBool("HMCD_RevenantUsed", false) then return end

	markRevenantCorpse(rag, wasTraitor, visuals, false)
end, 1)

hook.Add("ZB_CanLootInventory", "HMCD_RevenantFinalSecondsLootLock", function(ply, ent)
	if ply:GetNWBool("HMCD_RevenantPassenger", false) then return ply, ent, false end
	local state = getRevenantState(ply)
	if state and state.EndsAt - CurTime() <= (MODE.RevenantLootLockTime or 5) then return ply, ent, false end
end, -1)

hook.Add("PlayerDisconnected", "HMCD_RevenantCleanup", function(ply)
	local state = getRevenantState(ply)
	if state then
		if IsValid(state.Passenger) then
			local loadout = ply:Alive() and capturePlayerLoadout(ply) or state.PassengerLoadout
			ply.FakeRagdoll = nil
			ply:SetNWEntity("FakeRagdoll", NULL)
			if hg.ragdollFake then hg.ragdollFake[ply] = nil end
			restoreRevenantPassenger(state, state.ShellRagdoll, loadout)
		end
		if IsValid(state.OriginalBody) then state.OriginalBody:Remove() end
	end
	setRevenantState(ply, nil)
end)

hook.Add("PlayerDisconnected", "HMCD_RevenantPassengerCleanup", function(ply)
	local controller = ply.HMCD_RevenantPassengerController
	if not IsValid(controller) then return end
	local state = getRevenantState(controller)
	clearRevenantPassengerLock(ply)
	if state and state.Passenger == ply and not state.Ending then
		state.Passenger = nil
		MODE.EndRevenantPossession(controller, "passenger_disconnected")
	end
end)

hook.Add("ZB_PreRoundStart", "HMCD_RevenantRoundCleanup", function()
	for _, ply in player.Iterator() do
		local state = getRevenantState(ply)
		if state then
			if IsValid(state.Passenger) then
				ply.FakeRagdoll = nil
				ply:SetNWEntity("FakeRagdoll", NULL)
				if hg.ragdollFake then hg.ragdollFake[ply] = nil end
				restoreRevenantPassenger(state, state.ShellRagdoll, state.PassengerLoadout)
			end
			if IsValid(state.OriginalBody) then state.OriginalBody:Remove() end
		end
		setRevenantState(ply, nil)
		ply.Ability_RevenantImplant = nil
		ply.Ability_RevenantCooldownUntil = nil
		ply.Ability_RevenantCharges = nil
		ply.HMCD_RevenantBodyUsed = nil
		ply:SetNWInt("HMCD_RevenantCharges", 0)
		clearRevenantNW(ply)
		clearRevenantPassengerLock(ply)
	end
	for _, rag in ipairs(ents.FindByClass("prop_ragdoll")) do
		if rag:GetNWBool("HMCD_RevenantOriginalBody", false) then rag:Remove() end
	end
end)
