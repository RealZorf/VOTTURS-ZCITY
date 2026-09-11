local sourceCache = {}
local function noReload() end
local mechanicalPatchVersion = 3

-- Legacy packs encode disposal in client callbacks, without shared weapon metadata.
-- Inspect those callbacks only when definitions load; retain their animation timings.
local function callbackSource(fn)
	if not isfunction(fn) then return "" end
	local info = debug.getinfo(fn, "S")
	if info.what ~= "Lua" then return "" end
	local path = string.sub(info.source, 2)
	local lines = sourceCache[path]
	if not lines then
		local text = file.Read(path, "GAME") or file.Read(path, "LUA")
		if not text then return "" end
		lines = string.Explode("\n", text)
		sourceCache[path] = lines
	end
	return table.concat(lines, "\n", info.linedefined, math.min(info.lastlinedefined, #lines))
end

local function isHomigradWeapon(swep)
	local seen = {}
	while swep do
		local base = swep.Base
		if base == "homigrad_base" then return true end
		if not base or seen[base] then return false end
		seen[base] = true
		swep = weapons.GetStored(base)
	end
	return false
end

local function runMechanicalEvents(self, animation, data)
	local sequence = (self.AnimList or {})[animation] or animation
	local events = self.HG_CompleteMechanicalEvents and (self.HG_CompleteMechanicalEvents[animation] or self.HG_CompleteMechanicalEvents[sequence])
	if not events then return end
	local model = self.GetWM and self:GetWM()
	if not IsValid(model) then return end
	local duration = 1
	if istable(data) then
		duration = tonumber(data[1]) or duration
	else
		duration = tonumber(data) or duration
	end

	self.HG_MechanicalEventGeneration = (self.HG_MechanicalEventGeneration or 0) + 1
	local generation = self.HG_MechanicalEventGeneration
	local index = 0
	for fraction, event in pairs(events) do
		if not isnumber(fraction) or not isfunction(event) then continue end
		local delay = duration * fraction
		index = index + 1
		local eventCallback = event
		local timerName = "HG_CompleteMechanicalEvent_" .. self:EntIndex() .. "_" .. generation .. "_" .. index
		timer.Create(timerName, delay, 1, function()
			if not IsValid(self) or self.HG_MechanicalEventGeneration != generation then return end
			eventCallback(self, model)
		end)
	end
end

if SERVER then
	util.AddNetworkString("HG_CompleteMechanicalAnimation")
else
	net.Receive("HG_CompleteMechanicalAnimation", function()
		local weapon = net.ReadEntity()
		local animation = net.ReadString()
		local payload = net.ReadTable()
		if IsValid(weapon) then runMechanicalEvents(weapon, animation, payload.data) end
	end)
end

local function patchMechanicalEvents(swep)
	if not swep.AnimsEvents or not swep.AnimList or not isHomigradWeapon(swep) then return end
	local base = weapons.GetStored("homigrad_base")
	local inheritedPlayAnim = base and base.PlayAnim
	if not isfunction(inheritedPlayAnim) then return end
	if swep.HG_MechanicalPatchVersion == mechanicalPatchVersion and swep.HG_MechanicalBasePlayAnim == inheritedPlayAnim then return end
	local animation = swep.AnimList.cycle
	local events = animation and swep.AnimsEvents[animation]
	if not events then return end
	local eventCount = 0
	for fraction, event in pairs(events) do
		if isnumber(fraction) and isfunction(event) then eventCount = eventCount + 1 end
	end
	if eventCount < 2 then return end

	swep.HG_CompleteMechanicalEvents = {[animation] = events}
	swep.HG_MechanicalPatchVersion = mechanicalPatchVersion
	swep.HG_MechanicalBasePlayAnim = inheritedPlayAnim
	swep.PlayAnim = function(self, animation, data, cycling, callback, reverse, sendtoclient)
		local sequence = (self.AnimList or {})[animation] or animation
		local events = self.HG_CompleteMechanicalEvents and (self.HG_CompleteMechanicalEvents[animation] or self.HG_CompleteMechanicalEvents[sequence])
		if not events then
			return inheritedPlayAnim(self, animation, data, cycling, callback, reverse, sendtoclient)
		end

		if SERVER then
			local result = inheritedPlayAnim(self, animation, data, cycling, callback, reverse, sendtoclient)
			local owner = self:GetOwner()
			if IsValid(owner) and owner:IsPlayer() then
				net.Start("HG_CompleteMechanicalAnimation")
					net.WriteEntity(self)
					net.WriteString(animation)
					net.WriteTable({data = data})
				net.Send(owner)
			end
			return result
		end

		local animationEvents = self.AnimsEvents
		self.AnimsEvents = false
		local result = inheritedPlayAnim(self, animation, data, cycling, callback, reverse, sendtoclient)
		self.AnimsEvents = animationEvents
		runMechanicalEvents(self, animation, data)
		return result
	end
end

local function dropSpentTube(self)
	if not SERVER then return false end
	local owner = self:GetOwner()
	local body = IsValid(owner) and hg.GetCurrentCharacter(owner) or self
	if not IsValid(body) then body = self end
	local origin = body:WorldSpaceCenter()
	local pos, ang = origin, self:GetAngles()
	local hand = body:LookupBone("ValveBiped.Bip01_R_Hand")
	local matrix = hand and body:GetBoneMatrix(hand)
	if matrix then pos, ang = matrix:GetTranslation(), matrix:GetAngles() end
	local tr = util.TraceHull({start = origin, endpos = pos, mins = Vector(-3, -3, -3),
		maxs = Vector(3, 3, 3), filter = {self, owner, body}, mask = MASK_SOLID})
	pos = tr.StartSolid and origin or tr.HitPos

	local tube = ents.Create("prop_physics")
	if not IsValid(tube) then return false end
	tube:SetModel(self.MagModel)
	tube:SetPos(pos)
	tube:SetAngles(ang)
	tube:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	tube:Spawn()
	if not IsValid(tube) then return false end
	local phys = tube:GetPhysicsObject()
	if not IsValid(phys) then
		tube:PhysicsInitBox(tube:OBBMins(), tube:OBBMaxs())
		tube:SetMoveType(MOVETYPE_VPHYSICS)
		tube:SetSolid(SOLID_VPHYSICS)
		phys = tube:GetPhysicsObject()
	end
	if not IsValid(phys) then tube:Remove() return false end
	phys:Wake()
	phys:SetVelocity(body:GetVelocity() + ang:Forward() * 35 - Vector(0, 0, 25))
	phys:AddAngleVelocity(Vector(0, 80, 30))
	SafeRemoveEntityDelayed(tube, 60)
	return true
end

local function patchDisposableEvents(swep)
	if not swep.Primary or swep.Primary.ClipSize ~= 1 or not swep.MagModel or not swep.AnimsEvents then return end
	for animation, events in pairs(swep.AnimsEvents) do
		local removeAt
		for fraction, callback in pairs(events) do
			local body = callbackSource(callback)
			if isnumber(fraction) and string.find(body, 'net.Start%s*%(%s*["\']RemoveWeapon["\']') then
				removeAt = fraction
			end
		end
		if removeAt then
			swep.Reload = noReload
			swep.ReloadStart = noReload
			swep.ReloadEnd = noReload
			swep.HG_DiscardAnimations = swep.HG_DiscardAnimations or {}
			swep.HG_DiscardAnimations[animation] = removeAt
			for fraction, callback in pairs(events) do
				local body = callbackSource(callback)
				if fraction == removeAt or string.find(body, "hg%.CreateMag%s*%(") then
					events[fraction] = noReload
				end
			end
		end
	end
end

function hg.ScheduleWeaponDiscard(self, animation, duration, start)
	local times = self.HG_DiscardAnimations
	local fraction = times and (times[animation] or times[(self.AnimList or {})[animation]])
	if not fraction or self:Clip1() > 0 or self.HG_DiscardPending then return end
	self.HG_DiscardPending = true
	timer.Simple(math.max(duration * fraction - (start or 0), 0), function()
		if not IsValid(self) then return end
		self.HG_DiscardPending = nil
		if self:Clip1() == 0 and dropSpentTube(self) then self:Remove() end
	end)
end

local function patchRegistered()
	sourceCache = {}
	for _, entry in ipairs(weapons.GetList()) do
		if weapons.IsBasedOn(entry.ClassName, "homigrad_base") then
			local swep = weapons.GetStored(entry.ClassName)
			if swep then
				patchDisposableEvents(swep)
				patchMechanicalEvents(swep)
			end
		end
	end
	sourceCache = {}
end

hook.Add("PreRegisterSWEP", "HG_DisposableWeaponCompatibility", function(swep)
	patchDisposableEvents(swep)
	patchMechanicalEvents(swep)
end)
hook.Add("OnReloaded", "HG_DisposableWeaponCompatibility", patchRegistered)
patchRegistered()
