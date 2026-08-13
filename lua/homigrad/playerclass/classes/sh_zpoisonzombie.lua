local CLASS = player.RegClass("poisonzombie")

CLASS.CanUseDefaultPhrase = false
CLASS.CanEmitRNDSound = false
CLASS.CanUseGestures = false

local poisonZombieModel = "models/zombie/poison.mdl"
local poisonZombieColor = Color(48, 78, 20)
local poisonZombieHeadBone = "ValveBiped.Bip01_Head1"
local poisonZombieAttackDuration = 0.95
local poisonZombieThrowDuration = 1.25
local poisonZombieThrowRelease = 0.58
local poisonZombieThrowCooldown = 5.5
local poisonZombieHeadcrabCount = 3

local throwWindup = {
	r_upperarm = Angle(-55, -70, -35),
	r_forearm = Angle(15, -85, -10),
	l_upperarm = Angle(-15, -20, 10),
	l_forearm = Angle(0, -25, 0)
}

local throwRelease = {
	r_upperarm = Angle(-85, -15, -10),
	r_forearm = Angle(0, -15, 0),
	l_upperarm = Angle(-5, -8, 4),
	l_forearm = Angle(0, -8, 0)
}

local function SetPoisonZombieNestCount(ent, count)
	if not IsValid(ent) then return end

	count = math.Clamp(math.floor(tonumber(count) or 0), 0, poisonZombieHeadcrabCount)
	for slot = 1, poisonZombieHeadcrabCount do
		local bodygroup = slot + 1
		if bodygroup < ent:GetNumBodyGroups() then
			ent:SetBodygroup(bodygroup, slot <= count and 1 or 0)
		end
	end
end

local function SetPoisonZombieHeadcrabs(ent)
	if not IsValid(ent) then return end

	for index = 0, ent:GetNumBodyGroups() - 1 do
		ent:SetBodygroup(index, 0)
	end

	-- Valve's poison zombie uses 1 for the worn headcrab and 2-4 for its nest.
	if ent:GetNumBodyGroups() > 1 then ent:SetBodygroup(1, 1) end
	SetPoisonZombieNestCount(ent, poisonZombieHeadcrabCount)

	-- Bodygroup 5 is only used while the NPC is holding a headcrab to throw.
	if ent:GetNumBodyGroups() > 5 then ent:SetBodygroup(5, 0) end
end

local function SyncPoisonZombieNestCount(ply, count)
	SetPoisonZombieNestCount(ply, count)

	local character = hg and hg.GetCurrentCharacter and hg.GetCurrentCharacter(ply)
	if IsValid(character) and character ~= ply and string.lower(character:GetModel() or "") == poisonZombieModel then
		SetPoisonZombieNestCount(character, count)
	end
end

local function IsPoisonZombie(ply)
	return IsValid(ply) and ply.PlayerClassName == "poisonzombie"
end

local function HasPoisonZombieCriticalSupportFailure(ply)
	local org = ply.organism
	if not org then return false end

	if org.otrub or org.needotrub or org.seizureActive or org.headamputated then return true end
	if org.llegamputated or org.rlegamputated then return true end
	if (tonumber(org.lleg) or 0) >= 1 or (tonumber(org.rleg) or 0) >= 1 then return true end
	if (tonumber(org.brain) or 0) >= 0.6 or (tonumber(org.consciousness) or 1) <= 0.1 then return true end

	local limits = hg.organism
	if not limits then return false end
	return (tonumber(org.spine1) or 0) >= (tonumber(limits.fake_spine1) or math.huge)
		or (tonumber(org.spine2) or 0) >= (tonumber(limits.fake_spine2) or math.huge)
		or (tonumber(org.spine3) or 0) >= (tonumber(limits.fake_spine3) or math.huge)
end

function CLASS.CanFake(self, ragdoll)
	if not self:Alive() or IsValid(ragdoll) or (self.organism and self.organism.alive == false) then return end
	if HasPoisonZombieCriticalSupportFailure(self) then return end
	return false
end

function CLASS.CanStun(self)
	if HasPoisonZombieCriticalSupportFailure(self) then return end
	return false
end

function CLASS.AddThrowableHeadcrabs(self, amount)
	if not SERVER or not IsPoisonZombie(self) then return false, 0 end

	local current = math.Clamp(math.floor(tonumber(self.ZCPoisonZombieHeadcrabs) or 0), 0, poisonZombieHeadcrabCount)
	local updated = math.Clamp(current + math.max(math.floor(tonumber(amount) or 1), 0), 0, poisonZombieHeadcrabCount)
	if updated == current then return false, current end

	self.ZCPoisonZombieHeadcrabs = updated
	SyncPoisonZombieNestCount(self, updated)
	return true, updated
end

local function GetZombieBase()
	return player.classList and player.classList.headcrabzombie
end

if CLIENT then
	local hiddenHeadScale = Vector(0.001, 0.001, 0.001)
	local visibleHeadScale = Vector(1, 1, 1)
	local throwReleaseFraction = poisonZombieThrowRelease / poisonZombieThrowDuration
	local throwWindupFraction = throwReleaseFraction * 0.7

	local function SmoothStep(value)
		value = math.Clamp(value, 0, 1)
		return value * value * (3 - 2 * value)
	end

	local function GetThrowBoneAngle(progress, windup, released)
		if progress < throwWindupFraction then
			return LerpAngle(SmoothStep(progress / throwWindupFraction), angle_zero, windup)
		end

		if progress < throwReleaseFraction then
			local fraction = (progress - throwWindupFraction) / (throwReleaseFraction - throwWindupFraction)
			return LerpAngle(SmoothStep(fraction), windup, released)
		end

		local fraction = (progress - throwReleaseFraction) / (1 - throwReleaseFraction)
		return LerpAngle(SmoothStep(fraction), released, angle_zero)
	end

	local function IsPoisonZombieFirstPerson(ply)
		if not IsPoisonZombie(ply) or ply ~= LocalPlayer() or not ply:Alive() then return false end
		if GetViewEntity() ~= ply then return false end
		if IsValid(ply.FakeRagdoll) or IsValid(ply:GetNWEntity("FakeRagdoll", NULL)) then return false end

		local thirdPerson = GetConVar("hg_thirdperson")
		local goPro = GetConVar("hg_gopro")
		return not (thirdPerson and thirdPerson:GetBool()) and not (goPro and goPro:GetBool())
	end

	local function RemoveFirstPersonBody(ply)
		if IsValid(ply.ZCPoisonZombieFirstPersonBody) then
			ply.ZCPoisonZombieFirstPersonBody:Remove()
		end

		ply.ZCPoisonZombieFirstPersonBody = nil
	end

	local function GetFirstPersonBody(ply)
		local body = ply.ZCPoisonZombieFirstPersonBody
		if IsValid(body) and string.lower(body:GetModel() or "") == poisonZombieModel then return body end

		RemoveFirstPersonBody(ply)
		body = ClientsideModel(poisonZombieModel, RENDERGROUP_OPAQUE)
		if not IsValid(body) then return end

		body:SetNoDraw(true)
		body:SetRenderBounds(Vector(-72, -72, -24), Vector(72, 72, 112))
		body.ZCPoisonZombieHiddenBones = {}

		local headBone = body:LookupBone(poisonZombieHeadBone)
		if headBone then
			for bone = 0, (body:GetBoneCount() or 0) - 1 do
				local current = bone
				while current and current >= 0 do
					if current == headBone then
						body.ZCPoisonZombieHiddenBones[bone] = true
						break
					end

					current = body:GetBoneParent(current)
				end
			end
		end

		ply.ZCPoisonZombieFirstPersonBody = body
		return body
	end

	local function UpdateFirstPersonBody(ply, body)
		body:SetPos(ply:GetPos())
		body:SetAngles(ply:GetAngles())
		body:SetSkin(ply:GetSkin())
		body:SetColor(ply:GetColor())
		body:SetRenderMode(ply:GetRenderMode())
		body:SetSequence(ply:GetSequence())
		body:SetCycle(ply:GetCycle())
		body:SetPlaybackRate(ply:GetPlaybackRate())
		body:SetPoseParameter("move_yaw", ply.ZCPoisonZombieMoveYaw or 0)

		for index = 0, ply:GetNumBodyGroups() - 1 do
			body:SetBodygroup(index, ply:GetBodygroup(index))
		end
		if body:GetNumBodyGroups() > 1 then body:SetBodygroup(1, 0) end

		body:InvalidateBoneCache()
		body:SetupBones()

		for bone in pairs(body.ZCPoisonZombieHiddenBones or {}) do
			local matrix = body:GetBoneMatrix(bone)
			if matrix then
				matrix:SetScale(hiddenHeadScale)
				body:SetBoneMatrix(bone, matrix)
			end
		end
	end

	function hg.DrawPoisonZombieFirstPersonBody(ply)
		if not IsPoisonZombieFirstPerson(ply) then return false end

		local body = GetFirstPersonBody(ply)
		if not IsValid(body) then return false end

		UpdateFirstPersonBody(ply, body)
		body:DrawModel()
		return true
	end

	local function SetFirstPersonHeadHidden(ply, hidden)
		if not IsValid(ply) or string.lower(ply:GetModel() or "") ~= poisonZombieModel then return end

		if ply:GetNumBodyGroups() > 1 then
			local headcrabState = hidden and 0 or 1
			if ply:GetBodygroup(1) ~= headcrabState then ply:SetBodygroup(1, headcrabState) end
		end

		local bone = ply:LookupBone(poisonZombieHeadBone)
		if not bone then return end

		local scale = hidden and hiddenHeadScale or visibleHeadScale
		local current = ply:GetManipulateBoneScale(bone)
		if current and current:IsEqualTol(scale, 0.001) then return end

		ply:ManipulateBoneScale(bone, scale)
	end

	function CLASS.UpdateFirstPersonHead(self)
		if self == LocalPlayer() then
			SetFirstPersonHeadHidden(self, IsPoisonZombieFirstPerson(self))
		end
	end

	function CLASS.RestoreFirstPersonHead(self)
		SetFirstPersonHeadHidden(self, false)
		RemoveFirstPersonBody(self)
	end

	hook.Add("Bones", "PoisonZombieThrowPose", function(ply)
		if not IsPoisonZombie(ply) or not ply:Alive() or IsValid(ply.FakeRagdoll) then return end

		local throwUntil = ply:GetNWFloat("ZCPoisonZombieThrowUntil", 0)
		if throwUntil <= CurTime() then return end

		local progress = math.Clamp(1 - (throwUntil - CurTime()) / poisonZombieThrowDuration, 0, 1)
		for bone, windup in pairs(throwWindup) do
			hg.bone.Set(ply, bone, vector_origin, GetThrowBoneAngle(progress, windup, throwRelease[bone]), "poisonthrow")
		end
	end)
end

local sequences = {
	idle = {"idle01", "Idle01", "idle02", "Idle02"},
	walk = {"walk", "Walk", "walk_all", "Run"},
	run = {"run", "Run", "walk", "Walk"},
	jump = {"JumpNavMove", "jump", "Jump", "Leap"},
	melee = {"melee_01", "Melee", "attackA", "AttackA", "attackB", "AttackB"},
	throw = {"Throw", "throw", "ThrowWarning"}
}

local sequenceActivities = {
	idle = ACT_IDLE,
	walk = ACT_WALK,
	run = ACT_RUN,
	jump = ACT_JUMP,
	melee = ACT_MELEE_ATTACK1,
	throw = ACT_RANGE_ATTACK2
}

local function GetPoisonZombieSequence(ply, state)
	local model = string.lower(ply:GetModel() or "")
	if ply.ZCPoisonZombieSequenceModel ~= model or not istable(ply.ZCPoisonZombieSequences) then
		ply.ZCPoisonZombieSequenceModel = model
		ply.ZCPoisonZombieSequences = {}
	end

	local cache = ply.ZCPoisonZombieSequences
	if cache[state] ~= nil then return cache[state] end

	for _, name in ipairs(sequences[state] or sequences.idle) do
		local sequence = ply:LookupSequence(name)
		if isnumber(sequence) and sequence >= 0 and sequence < ply:GetSequenceCount() then
			cache[state] = sequence
			return sequence
		end
	end

	local sequence = ply:SelectWeightedSequence(sequenceActivities[state] or ACT_IDLE)
	cache[state] = isnumber(sequence) and sequence >= 0 and sequence or 0
	return cache[state]
end

local function GetAttackTime(ply)
	local weapon = ply:GetActiveWeapon()
	if not IsValid(weapon) or weapon:GetClass() ~= "weapon_hands_sh" or not weapon.LastShootTime then return 0 end

	return tonumber(weapon:LastShootTime()) or 0
end

local function GetAnimationState(ply, velocity)
	if ply:GetNWFloat("ZCPoisonZombieAttackUntil", 0) > CurTime() then return "melee" end

	local attackTime = GetAttackTime(ply)
	if attackTime > 0 and CurTime() - attackTime <= poisonZombieAttackDuration then return "melee" end
	if not ply:OnGround() and ply:GetMoveType() ~= MOVETYPE_NOCLIP then return "jump" end

	local speedSqr = velocity:Length2DSqr()
	if speedSqr <= 1 then return "idle" end
	if ply:IsFlagSet(FL_ANIMDUCKING) or speedSqr < 14400 then return "walk" end
	return "run"
end

local npcEnemies = {
	npc_barney = true, npc_citizen = true, npc_dog = true, npc_eli = true,
	npc_kleiner = true, npc_magnusson = true, npc_monk = true, npc_mossman = true,
	npc_odessa = true, npc_rollermine_hacked = true, npc_turret_floor_resistance = true,
	npc_vortigaunt = true, npc_alyx = true, npc_combine_s = true, npc_metropolice = true,
	npc_helicopter = true, npc_combinegunship = true, npc_combine = true, npc_stalker = true,
	npc_hunter = true, npc_strider = true, npc_turret_floor = true, npc_combine_camera = true,
	npc_manhack = true, npc_cscanner = true, npc_clawscanner = true
}

local npcAllies = {
	npc_fastzombie = true, npc_fastzombie_torso = true, npc_headcrab = true,
	npc_headcrab_black = true, npc_headcrab_fast = true, npc_poisonzombie = true,
	npc_zombie = true, npc_zombie_torso = true, npc_zombine = true
}

local function ApplyNPCRelationship(ply, ent)
	if not IsValid(ent) or not ent:IsNPC() then return end

	local class = ent:GetClass()
	if npcEnemies[class] then
		ent:AddEntityRelationship(ply, D_HT, 99)
	elseif npcAllies[class] then
		ent:AddEntityRelationship(ply, D_LI, 99)
	end
end

function CLASS.On(self, data)
	self.PreZombClass = self.PreZombClass or "Rebel"
	local base = GetZombieBase()
	if base and base.On then base.On(self, data or {}) end

	self:SetModel(poisonZombieModel)
	self:SetSubMaterial()
	self:SetSkin(0)
	SetPoisonZombieHeadcrabs(self)
	self:SetNWString("PlayerName", "Poison Zombie")
	self:SetPlayerColor(poisonZombieColor:ToVector())
	self.JumpPowerMul = 0.8
	self.MeleeDamageMul = 1.25
	self.ClawPenetration = 2.75
	self.ClawDoorDamage = 120
	self.ClawReachDistance = 56

	if SERVER then
		self:SetNWFloat("ZCPoisonZombieAttackUntil", 0)
		self:SetNWFloat("ZCPoisonZombieThrowUntil", 0)
		self.ZCPoisonZombieHeadcrabs = poisonZombieHeadcrabCount
		self.ZCPoisonZombieNextThrow = 0
		self.ZSPreviousMaxHealth = self.ZSPreviousMaxHealth or self:GetMaxHealth()
		self:SetMaxHealth(350)
		self:SetHealth(350)

		timer.Simple(0, function()
			if not IsPoisonZombie(self) then return end
			local hands = self:GetWeapon("weapon_hands_sh")
			if not IsValid(hands) then hands = self:Give("weapon_hands_sh") end
			if not IsValid(hands) then return end

			self:SelectWeapon("weapon_hands_sh")
			self:SetActiveWeapon(hands)
			hands:SetFists(true)
			hands:SetNextDown(CurTime())
		end)

		local hookName = "PoisonZombieRelationships_" .. self:EntIndex()
		hook.Add("OnEntityCreated", hookName, function(ent)
			if not IsPoisonZombie(self) then
				hook.Remove("OnEntityCreated", hookName)
				return
			end

			ApplyNPCRelationship(self, ent)
		end)
	end
end

function CLASS.Off(self)
	if CLIENT and CLASS.RestoreFirstPersonHead then CLASS.RestoreFirstPersonHead(self) end

	local base = GetZombieBase()
	if base and base.Off then base.Off(self) end

	self.JumpPowerMul = nil
	self.MeleeDamageMul = nil
	self.ClawPenetration = nil
	self.ClawDoorDamage = nil
	self.ClawReachDistance = nil
	self.SpeedGainMul = nil
	self.ZCPoisonZombieSequenceModel = nil
	self.ZCPoisonZombieSequences = nil
	self.ZCPoisonZombieMoveYaw = nil
	self.ZCPoisonZombieNextClaw = nil
	self.ZCPoisonZombieHeadcrabs = nil
	self.ZCPoisonZombieNextThrow = nil

	if SERVER then
		self:SetNWFloat("ZCPoisonZombieAttackUntil", 0)
		self:SetNWFloat("ZCPoisonZombieThrowUntil", 0)
		hook.Remove("OnEntityCreated", "PoisonZombieRelationships_" .. self:EntIndex())
		self:SetMaxHealth(self.ZSPreviousMaxHealth or 100)
		self.ZSPreviousMaxHealth = nil
	end
end

function CLASS.PlayerDeath(self, ragdoll)
	hook.Remove("OnEntityCreated", "PoisonZombieRelationships_" .. self:EntIndex())
	local base = GetZombieBase()
	if base and base.PlayerDeath then return base.PlayerDeath(self, ragdoll) end
end

function CLASS.Guilt(self, victim)
	local base = GetZombieBase()
	return base and base.Guilt and base.Guilt(self, victim) or 0
end

local clawMins = Vector(-12, -12, -12)
local clawMaxs = Vector(12, 12, 12)

local function PoisonZombieClawAttack(ply)
	if CLIENT or not ply:Alive() or not IsPoisonZombie(ply) then return end
	if (ply.ZCPoisonZombieNextClaw or 0) > CurTime() then return end
	if ply:GetNWFloat("ZCPoisonZombieThrowUntil", 0) > CurTime() then return end
	if IsValid(ply.FakeRagdoll) or (ply.organism and (ply.organism.otrub or ply.organism.fake)) then return end

	ply.ZCPoisonZombieNextClaw = CurTime() + 1.1
	ply:SetNWFloat("ZCPoisonZombieAttackUntil", CurTime() + poisonZombieAttackDuration)
	local hands = ply:GetWeapon("weapon_hands_sh")
	if IsValid(hands) then
		hands:SetFists(true)
		hands:SetLastShootTime(CurTime())
	end

	local direction = ply:GetAimVector()
	local startPos = ply:GetShootPos()
	local reach = tonumber(ply.ClawReachDistance) or 56

	ply:LagCompensation(true)
	local trace = util.TraceHull({
		start = startPos,
		endpos = startPos + direction * reach,
		mins = clawMins,
		maxs = clawMaxs,
		mask = MASK_SHOT_HULL,
		filter = {ply, hg.GetCurrentCharacter(ply)}
	})
	ply:LagCompensation(false)

	local target = trace.Entity
	if not IsValid(target) or target:IsWorld() then return end

	local hitPos = trace.HitPos
	if hgIsDoor(target) then
		target.HP = (target.HP or 200) - (tonumber(ply.ClawDoorDamage) or 120)
		target:EmitSound("physics/wood/wood_crate_impact_hard" .. math.random(1, 4) .. ".wav", 88, math.random(82, 96))
		if target.HP <= 0 and not target:GetNoDraw() then
			hgBlastThatDoor(target, direction * 150 + ply:GetVelocity() * 0.3)
		end
		return
	end

	local damage = DamageInfo()
	damage:SetAttacker(ply)
	damage:SetInflictor(IsValid(hands) and hands or ply)
	damage:SetDamage(math.Rand(58, 66) * (tonumber(ply.MeleeDamageMul) or 1))
	damage:SetDamageType(DMG_SLASH)
	damage:SetDamagePosition(hitPos)
	damage:SetDamageForce(direction * 2200)

	local oldPenetration
	if IsValid(hands) then
		oldPenetration = hands.Penetration
		hands.Penetration = tonumber(ply.ClawPenetration) or 2.75
	end

	target:TakeDamageInfo(damage)
	if IsValid(hands) then hands.Penetration = oldPenetration end

	sound.Play("npc/zombie/claw_strike" .. math.random(1, 3) .. ".wav", hitPos, 78, math.random(82, 96))
	util.Decal("Blood", hitPos - direction, hitPos + direction, target)
end

local headcrabHullMins = Vector(-8, -8, -8)
local headcrabHullMaxs = Vector(8, 8, 8)

local function SpawnThrownPoisonHeadcrab(ply)
	if not IsPoisonZombie(ply) or not ply:Alive() then return end
	if IsValid(ply.FakeRagdoll) or (ply.organism and (ply.organism.otrub or ply.organism.fake)) then return end

	local count = math.Clamp(tonumber(ply.ZCPoisonZombieHeadcrabs) or 0, 0, poisonZombieHeadcrabCount)
	if count <= 0 then return end

	local direction = ply:GetAimVector()
	local startPos = ply:GetShootPos()
	local trace = util.TraceHull({
		start = startPos,
		endpos = startPos + direction * 38,
		mins = headcrabHullMins,
		maxs = headcrabHullMaxs,
		mask = MASK_NPCSOLID,
		filter = {ply, hg.GetCurrentCharacter(ply)}
	})
	local spawnPos = trace.Hit and trace.HitPos - direction * 10 or trace.HitPos
	if not util.IsInWorld(spawnPos) then return end

	local crab = ents.Create("npc_headcrab_black")
	if not IsValid(crab) then return end

	crab:SetPos(spawnPos)
	crab:SetAngles(direction:Angle())
	crab:SetOwner(ply)
	crab:Spawn()
	crab:Activate()
	crab.ZSPoisonZombieOwner = ply

	for _, target in player.Iterator() do
		local zombie = target.ZSIsZombie
			or target.PlayerClassName == "headcrabzombie"
			or target.PlayerClassName == "fastzombie"
			or target.PlayerClassName == "poisonzombie"
		crab:AddEntityRelationship(target, zombie and D_LI or D_HT, 99)
	end

	local target = ply:GetEyeTrace().Entity
	if IsValid(target) and target:IsPlayer() and not target.ZSIsZombie then crab:SetEnemy(target) end
	crab:SetVelocity(ply:GetVelocity() * 0.45 + direction * 620 + vector_up * 125)

	ply.ZCPoisonZombieHeadcrabs = count - 1
	SyncPoisonZombieNestCount(ply, ply.ZCPoisonZombieHeadcrabs)
	ply:EmitSound("NPC_PoisonZombie.Throw", 78, 100)
end

local function PoisonZombieThrowHeadcrab(ply)
	if CLIENT or not ply:Alive() or not IsPoisonZombie(ply) then return end
	if (ply.ZCPoisonZombieNextThrow or 0) > CurTime() then return end
	if (tonumber(ply.ZCPoisonZombieHeadcrabs) or 0) <= 0 then return end
	if IsValid(ply.FakeRagdoll) or (ply.organism and (ply.organism.otrub or ply.organism.fake)) then return end

	ply.ZCPoisonZombieNextThrow = CurTime() + poisonZombieThrowCooldown
	ply.ZCPoisonZombieNextClaw = CurTime() + poisonZombieThrowDuration
	ply:SetNWFloat("ZCPoisonZombieThrowUntil", CurTime() + poisonZombieThrowDuration)
	ply:EmitSound("NPC_PoisonZombie.ThrowWarn", 76, 100)

	timer.Simple(poisonZombieThrowRelease, function()
		SpawnThrownPoisonHeadcrab(ply)
	end)
end

function CLASS.Think(self, time, dtime)
	local base = GetZombieBase()
	if base and base.Think then base.Think(self, time, dtime) end

	if CLIENT and CLASS.UpdateFirstPersonHead then CLASS.UpdateFirstPersonHead(self) end
	if not SERVER then return end

	if self.organism and self.organism.stamina then
		self.organism.stamina.max = 220
		self.organism.stamina.range = 220
	end

	if self.organism and not HasPoisonZombieCriticalSupportFailure(self) then
		self.organism.stun = 0
		if (self.organism.lightstun or 0) > 0 then
			self.organism.lightstun = 0
			self:SetLocalVar("stun", 0)
		end
		self.organism.needfake = false
		self.organism.fake = false
	end

	if self:KeyDown(IN_ATTACK) then PoisonZombieClawAttack(self) end
	if self:KeyPressed(IN_ATTACK2) then PoisonZombieThrowHeadcrab(self) end
end

local painSounds = {}
local voiceSounds = {}
for index = 1, 3 do
	painSounds[#painSounds + 1] = "npc/zombie_poison/pz_pain" .. index .. ".wav"
end
for index = 2, 4 do voiceSounds[#voiceSounds + 1] = "npc/zombie_poison/pz_idle" .. index .. ".wav" end
for index = 1, 2 do voiceSounds[#voiceSounds + 1] = "npc/zombie_poison/pz_alert" .. index .. ".wav" end

hook.Add("HG_ReplaceBurnPhrase", "PoisonZombieBurnPhrases", function(ply)
	if IsPoisonZombie(ply) then return ply, voiceSounds[math.random(#voiceSounds)] end
end)

hook.Add("HG_ReplacePhrase", "PoisonZombiePhrases", function(ply, phrase, muffed, pitch)
	if not IsPoisonZombie(ply) then return end
	local inPain = ply.organism and ply.organism.pain > 30
	local sounds = inPain and painSounds or voiceSounds
	return ply, sounds[math.random(#sounds)], not inPain, pitch
end)

hook.Add("HG_CanThoughts", "PoisonZombieThoughts", function(ply)
	if IsPoisonZombie(ply) then return false end
end)

hook.Add("PlayerCanPickupWeapon", "PoisonZombieWeaponPickup", function(ply, ent)
	if IsPoisonZombie(ply) and ent:GetClass() ~= "weapon_hands_sh" then return false end
end)

hook.Add("PlayerUse", "PoisonZombieUse", function(ply, ent)
	if IsPoisonZombie(ply) and ent:GetClass() ~= "func_button" then return false end
end)

hook.Add("HG_MovementCalc_2", "PoisonZombieSpeed", function(mul, ply)
	if not IsPoisonZombie(ply) then return end
	mul[1] = ply:IsSprinting() and 0.36 or 0.28
	if ply.SpeedGainMul ~= 24 then ply.SpeedGainMul = 24 end
end)

hook.Add("UpdateAnimation", "PoisonZombieAnimationRate", function(ply, velocity)
	if not IsPoisonZombie(ply) or not ply:Alive() then return end

	local state = GetAnimationState(ply, velocity)
	local speed = velocity:Length2D()
	local playbackRate = 1
	if state == "run" then
		playbackRate = math.Clamp(speed / 150, 0.7, 1.25)
	elseif state == "walk" then
		playbackRate = math.Clamp(speed / 75, 0.55, 1.1)
	elseif state == "melee" then
		playbackRate = 0.95
	elseif state == "jump" then
		playbackRate = 0.8
	end

	if speed > 1 then
		local moveYaw = math.NormalizeAngle(velocity:Angle().y - ply:EyeAngles().y)
		ply.ZCPoisonZombieMoveYaw = moveYaw
		ply:SetPoseParameter("move_yaw", moveYaw)
	else
		ply.ZCPoisonZombieMoveYaw = 0
		ply:SetPoseParameter("move_yaw", 0)
	end

	ply:SetPlaybackRate(playbackRate)
	return true
end, -1)

if SERVER then
	hook.Add("HG_PlayerFootstep", "PoisonZombieFootsteps", function(ply)
		if not ply:Alive() or not IsPoisonZombie(ply) then return end
		if IsValid(ply.FakeRagdoll) and ply:GetNetVar("lastFake") == 0 then return end
		local character = hg.GetCurrentCharacter(ply)
		if not IsValid(character) then return end

		character:EmitSound(math.random(2) == 1 and "npc/zombie_poison/pz_left_foot1.wav" or "npc/zombie_poison/pz_right_foot1.wav", 72, math.random(90, 100))
		return true
	end)

	hook.Add("ZB_CanLootInventory", "PoisonZombieLoot", function(ply, ent)
		if IsPoisonZombie(ply) then return ply, ent, false end
	end)

	hook.Add("HG_PlayerCanHearPlayersVoice", "PoisonZombieVoice", function(listener, speaker)
		if not IsPoisonZombie(speaker) then return end
		local round = CurrentRound and CurrentRound()
		local zombieSurvival = zb and zb.modes and round == zb.modes.zombiesurvival
		local listenerIsZombie = listener.ZSIsZombie
			or listener.PlayerClassName == "headcrabzombie"
			or listener.PlayerClassName == "fastzombie"
			or listener.PlayerClassName == "poisonzombie"

		if zombieSurvival and listenerIsZombie then return end
		return false, false
	end)
end

hook.Add("PlayerCanLegAttack", "PoisonZombieKick", function(ply)
	if IsPoisonZombie(ply) then return false end
end)

hook.Add("CalcMainActivity", "PoisonZombieAnimations", function(ply, velocity)
	if not IsPoisonZombie(ply) then return end
	if ply:GetNWString("hg_CustomAnim", "") ~= "" then return end
	return -1, GetPoisonZombieSequence(ply, GetAnimationState(ply, velocity))
end, -1)

hook.Add("CanPlayerEnterVehicle", "PoisonZombieVehicle", function(ply)
	if IsPoisonZombie(ply) then return false end
end)

if CLIENT then
	local poisonHeat = Material("effects/shaders/zb_heat")
	local poisonGrain = Material("effects/shaders/zb_grain2")
	local smoothedSpeed = 0
	local smoothedStress = 0
	local smoothedTurn = 0
	local lastViewAngles
	local colorModify = {
		["$pp_colour_addr"] = -0.006,
		["$pp_colour_addg"] = 0.012,
		["$pp_colour_addb"] = -0.01,
		["$pp_colour_brightness"] = -0.012,
		["$pp_colour_contrast"] = 1.1,
		["$pp_colour_colour"] = 0.58,
		["$pp_colour_mulr"] = -0.025,
		["$pp_colour_mulg"] = 0.07,
		["$pp_colour_mulb"] = -0.025
	}

	hook.Add("Post Post Processing", "PoisonZombieVision", function()
		local ply = LocalPlayer()
		if not IsPoisonZombie(ply) or not ply:Alive() or GetViewEntity() ~= ply then
			lastViewAngles = nil
			return
		end

		local frameTime = math.min(FrameTime(), 0.05)
		local speedTarget = math.Clamp(ply:GetVelocity():Length2D() / 260, 0, 1)
		local healthTarget = 1 - math.Clamp(ply:Health() / math.max(ply:GetMaxHealth(), 1), 0, 1)
		local viewAngles = ply:EyeAngles()
		local turnTarget = 0

		if lastViewAngles then
			local yaw = math.abs(math.AngleDifference(viewAngles.y, lastViewAngles.y))
			local pitch = math.abs(math.AngleDifference(viewAngles.p, lastViewAngles.p))
			turnTarget = math.Clamp((yaw + pitch * 0.65) / 12, 0, 1)
		end
		lastViewAngles = Angle(viewAngles.p, viewAngles.y, viewAngles.r)

		smoothedSpeed = Lerp(math.Clamp(frameTime * 3.5, 0, 1), smoothedSpeed, speedTarget)
		smoothedStress = Lerp(math.Clamp(frameTime * 2.2, 0, 1), smoothedStress, healthTarget)
		smoothedTurn = Lerp(math.Clamp(frameTime * 11, 0, 1), smoothedTurn, turnTarget)

		local time = CurTime()
		local breath = 0.5 + math.sin(time * 1.45) * 0.5
		local throwPulse = 0
		local throwUntil = ply:GetNWFloat("ZCPoisonZombieThrowUntil", 0)
		if throwUntil > time then
			local progress = math.Clamp(1 - (throwUntil - time) / poisonZombieThrowDuration, 0, 1)
			throwPulse = math.sin(progress * math.pi) ^ 2
		end

		local toxicity = math.Clamp(0.18 + smoothedStress * 0.42 + smoothedSpeed * 0.13 + throwPulse * 0.27, 0, 1)
		colorModify["$pp_colour_addg"] = 0.01 + toxicity * 0.012 + breath * 0.003
		colorModify["$pp_colour_brightness"] = -0.01 - smoothedStress * 0.018
		colorModify["$pp_colour_contrast"] = 1.09 + toxicity * 0.07
		colorModify["$pp_colour_colour"] = 0.61 - toxicity * 0.17
		colorModify["$pp_colour_mulg"] = 0.06 + toxicity * 0.065
		DrawColorModify(colorModify)

		render.UpdateScreenEffectTexture()
		poisonHeat:SetFloat("$c0_x", -time * (0.035 + smoothedSpeed * 0.025))
		poisonHeat:SetFloat("$c0_y", 0.018 + toxicity * 0.018 + smoothedTurn * 0.018 + throwPulse * 0.035)
		poisonHeat:SetFloat("$c2_x", 1.25 + breath * 0.15)
		render.SetMaterial(poisonHeat)
		render.DrawScreenQuad()

		render.UpdateScreenEffectTexture()
		poisonGrain:SetFloat("$c0_x", time * 0.16)
		poisonGrain:SetFloat("$c0_y", -1)
		poisonGrain:SetFloat("$c0_z", 0.2 + toxicity * 0.35)
		poisonGrain:SetFloat("$c1_x", 13)
		poisonGrain:SetFloat("$c1_y", 0.16 + toxicity * 0.2 + breath * 0.025)
		poisonGrain:SetFloat("$c1_z", 0.012 + smoothedTurn * 0.045 + throwPulse * 0.025)
		poisonGrain:SetFloat("$c2_x", 0.025)
		poisonGrain:SetFloat("$c2_y", 0.105 + toxicity * 0.055)
		poisonGrain:SetFloat("$c2_z", 0.012)
		poisonGrain:SetFloat("$c3_x", 0.012 + smoothedStress * 0.018)
		render.SetMaterial(poisonGrain)
		render.DrawScreenQuad()

		DrawSharpen(0.34 + (1 - smoothedTurn) * 0.16, 0.62)
		local motionBlur = smoothedTurn * 0.055 + math.max(smoothedSpeed - 0.72, 0) * 0.035 + throwPulse * 0.025
		if motionBlur > 0.006 then DrawMotionBlur(0.012, motionBlur, 0.01) end

		local bloom = 0.1 + toxicity * 0.08 + throwPulse * 0.08
		DrawBloom(0.16, bloom, 1.5, 1.5, 1, 0.25, 0.18, 0.72, 0.22)
	end)
end
