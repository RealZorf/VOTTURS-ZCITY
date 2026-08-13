local CLASS = player.RegClass("fastzombie")

CLASS.CanUseDefaultPhrase = false
CLASS.CanEmitRNDSound = false
CLASS.CanUseGestures = false

local fastZombieColor = Color(105, 0, 0)
local fastZombieModel = "models/zombie/fast.mdl"

if CLIENT then
	local hiddenHeadScale = Vector(0.001, 0.001, 0.001)
	local fastZombieNormalHeadBone = "ValveBiped.Bip01_Head1"

	local function IsFastZombieFirstPerson(ply)
		if not IsValid(ply) or ply ~= LocalPlayer() or not ply:Alive() then return false end
		if GetViewEntity() ~= ply then return false end
		if IsValid(ply.FakeRagdoll) or IsValid(ply:GetNWEntity("FakeRagdoll", NULL)) then return false end

		local thirdPerson = GetConVar("hg_thirdperson")
		local goPro = GetConVar("hg_gopro")
		return not (thirdPerson and thirdPerson:GetBool()) and not (goPro and goPro:GetBool())
	end

	local function RemoveFastZombieFirstPersonBody(ply)
		if IsValid(ply.ZCFastZombieFirstPersonBody) then
			ply.ZCFastZombieFirstPersonBody:Remove()
		end

		ply.ZCFastZombieFirstPersonBody = nil
	end

	local function GetFastZombieFirstPersonBody(ply)
		local body = ply.ZCFastZombieFirstPersonBody
		if IsValid(body) and string.lower(body:GetModel() or "") == fastZombieModel then return body end

		RemoveFastZombieFirstPersonBody(ply)
		body = ClientsideModel(fastZombieModel, RENDERGROUP_OPAQUE)
		if not IsValid(body) then return end

		body:SetNoDraw(true)
		body:SetRenderBounds(Vector(-64, -64, -24), Vector(64, 64, 104))

		local normalHead = body:LookupBone(fastZombieNormalHeadBone)
		body.ZCFastZombieHiddenBones = {}

		for bone = 0, (body:GetBoneCount() or 0) - 1 do
			local current = bone
			while current and current >= 0 do
				if current == normalHead then
					body.ZCFastZombieHiddenBones[bone] = true
					break
				end

				current = body:GetBoneParent(current)
			end
		end

		ply.ZCFastZombieFirstPersonBody = body
		return body
	end

	local function UpdateFastZombieFirstPersonBody(ply, body)
		body:SetPos(ply:GetPos())
		body:SetAngles(ply:GetAngles())
		body:SetSkin(ply:GetSkin())
		body:SetColor(ply:GetColor())
		body:SetRenderMode(ply:GetRenderMode())
		body:SetSequence(ply:GetSequence())
		body:SetCycle(ply:GetCycle())
		body:SetPlaybackRate(ply:GetPlaybackRate())
		body:SetPoseParameter("move_yaw", ply.ZCFastZombieMoveYaw or 0)

		for index = 0, ply:GetNumBodyGroups() - 1 do
			body:SetBodygroup(index, ply:GetBodygroup(index))
		end
		if body:GetNumBodyGroups() > 1 then body:SetBodygroup(1, 0) end

		body:InvalidateBoneCache()
		body:SetupBones()

		local hiddenBones = body.ZCFastZombieHiddenBones or {}
		for bone in pairs(hiddenBones) do
			local matrix = body:GetBoneMatrix(bone)
			if not matrix then continue end

			matrix:SetScale(hiddenHeadScale)
			body:SetBoneMatrix(bone, matrix)
		end
	end

	function hg.DrawFastZombieFirstPersonBody(ply)
		if ply.PlayerClassName ~= "fastzombie" or not IsFastZombieFirstPerson(ply) then return false end

		local body = GetFastZombieFirstPersonBody(ply)
		if not IsValid(body) then return false end

		UpdateFastZombieFirstPersonBody(ply, body)
		body:DrawModel()
		return true
	end

	local function SetFastZombieFirstPersonHeadHidden(ply, hidden)
		if not IsValid(ply) or string.lower(ply:GetModel() or "") ~= fastZombieModel then return end
		if ply:GetNumBodyGroups() <= 1 then return end

		local headcrabState = hidden and 0 or 1
		if ply:GetBodygroup(1) ~= headcrabState then
			ply:SetBodygroup(1, headcrabState)
		end
		ply.ZCFastZombieHeadHidden = hidden or nil
	end

	function CLASS.UpdateFirstPersonHead(self)
		if self ~= LocalPlayer() then return end

		local hidden = IsFastZombieFirstPerson(self)
		SetFastZombieFirstPersonHeadHidden(self, hidden)
	end

	function CLASS.RestoreFirstPersonHead(self)
		SetFastZombieFirstPersonHeadHidden(self, false)
		RemoveFastZombieFirstPersonBody(self)
		self.ZCFastZombieHeadHidden = nil
	end
end

local fastZombieSequences = {
	idle = {"idle", "idle_angry"},
	walk = {"walk_all", "Run"},
	run = {"Run", "walk_all"},
	jump = {"JumpNavMove", "leap_loop", "Leap"},
	melee = {"Melee", "BR2_Attack"}
}

local function GetFastZombieSequence(ply, state)
	local model = string.lower(ply:GetModel() or "")
	if ply.ZCFastZombieSequenceModel ~= model or not istable(ply.ZCFastZombieSequences) then
		ply.ZCFastZombieSequenceModel = model
		ply.ZCFastZombieSequences = {}
	end

	local cache = ply.ZCFastZombieSequences
	local cached = cache[state]
	if cached ~= nil then return cached end

	for _, name in ipairs(fastZombieSequences[state] or fastZombieSequences.idle) do
		local sequence = ply:LookupSequence(name)
		if isnumber(sequence) and sequence >= 0 and sequence < ply:GetSequenceCount() then
			cache[state] = sequence
			return sequence
		end
	end

	return 0
end

local function GetFastZombieAttackTime(ply)
	local weapon = ply:GetActiveWeapon()
	if not IsValid(weapon) or weapon:GetClass() ~= "weapon_hands_sh" or not weapon.LastShootTime then return 0 end

	return tonumber(weapon:LastShootTime()) or 0
end

local function GetFastZombieAnimationState(ply, velocity)
	local attackTime = GetFastZombieAttackTime(ply)
	if attackTime > 0 and CurTime() - attackTime <= 0.72 then return "melee" end
	if not ply:OnGround() and ply:GetMoveType() ~= MOVETYPE_NOCLIP then return "jump" end

	local speedSqr = velocity:Length2DSqr()
	if speedSqr <= 1 then return "idle" end
	if ply:IsFlagSet(FL_ANIMDUCKING) or speedSqr < 22500 then return "walk" end

	return "run"
end

local function IsFastZombie(ply)
	return IsValid(ply) and ply.PlayerClassName == "fastzombie"
end

local function GetZombieBase()
	return player.classList and player.classList.headcrabzombie
end

local npcEnemies = {
	npc_barney = true,
	npc_citizen = true,
	npc_dog = true,
	npc_eli = true,
	npc_kleiner = true,
	npc_magnusson = true,
	npc_monk = true,
	npc_mossman = true,
	npc_odessa = true,
	npc_rollermine_hacked = true,
	npc_turret_floor_resistance = true,
	npc_vortigaunt = true,
	npc_alyx = true,
	npc_combine_s = true,
	npc_metropolice = true,
	npc_helicopter = true,
	npc_combinegunship = true,
	npc_combine = true,
	npc_stalker = true,
	npc_hunter = true,
	npc_strider = true,
	npc_turret_floor = true,
	npc_combine_camera = true,
	npc_manhack = true,
	npc_cscanner = true,
	npc_clawscanner = true
}

local npcAllies = {
	npc_fastzombie = true,
	npc_fastzombie_torso = true,
	npc_headcrab = true,
	npc_headcrab_black = true,
	npc_headcrab_fast = true,
	npc_poisonzombie = true,
	npc_zombie = true,
	npc_zombie_torso = true,
	npc_zombine = true
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
	data = data or {}

	local base = GetZombieBase()
	if base and base.On then
		base.On(self, data)
	end

	self:SetModel(fastZombieModel)
	self:SetSubMaterial()
	self:SetSkin(0)
	if self:GetNumBodyGroups() > 1 then
		self:SetBodygroup(1, 1)
	end
	self:SetNWString("PlayerName", "Fast Zombie")
	self:SetPlayerColor(fastZombieColor:ToVector())
	self.JumpPowerMul = 1.85
	self.MeleeDamageMul = 1.5
	self.ClawPenetration = 2.25
	self.ClawDoorDamage = 80
	self.ClawReachDistance = 52

	if SERVER then
		self.ZSPreviousMaxHealth = self.ZSPreviousMaxHealth or self:GetMaxHealth()
		self:SetMaxHealth(160)
		self:SetHealth(160)

		local owner = self
		timer.Simple(0, function()
			if not IsFastZombie(owner) then return end

			local hands = owner:GetWeapon("weapon_hands_sh")
			if not IsValid(hands) then
				hands = owner:Give("weapon_hands_sh")
			end
			if not IsValid(hands) then return end

			owner:SelectWeapon("weapon_hands_sh")
			owner:SetActiveWeapon(hands)
			hands:SetFists(true)
			hands:SetNextDown(CurTime())
		end)

		local hookName = "FastZombieRelationships_" .. self:EntIndex()
		hook.Add("OnEntityCreated", hookName, function(ent)
			if not IsFastZombie(self) then
				hook.Remove("OnEntityCreated", hookName)
				return
			end

			ApplyNPCRelationship(self, ent)
		end)
	end
end

function CLASS.Off(self)
	if CLIENT and CLASS.RestoreFirstPersonHead then
		CLASS.RestoreFirstPersonHead(self)
	end

	local base = GetZombieBase()
	if base and base.Off then
		base.Off(self)
	end

	self.JumpPowerMul = nil
	self.MeleeDamageMul = nil
	self.ClawPenetration = nil
	self.ClawDoorDamage = nil
	self.ClawReachDistance = nil
	self.SpeedGainMul = nil
	self.ZCFastZombieSequenceModel = nil
	self.ZCFastZombieSequences = nil
	self.ZCFastZombieAnimationState = nil
	self.ZCFastZombieMoveYaw = nil
	self.ZCFastZombieNextClaw = nil

	if SERVER then
		hook.Remove("OnEntityCreated", "FastZombieRelationships_" .. self:EntIndex())
		self:SetMaxHealth(self.ZSPreviousMaxHealth or 100)
		self.ZSPreviousMaxHealth = nil
	end
end

function CLASS.PlayerDeath(self, ragdoll)
	hook.Remove("OnEntityCreated", "FastZombieRelationships_" .. self:EntIndex())

	local base = GetZombieBase()
	if base and base.PlayerDeath then
		return base.PlayerDeath(self, ragdoll)
	end
end

function CLASS.Guilt(self, victim)
	local base = GetZombieBase()
	if base and base.Guilt then
		return base.Guilt(self, victim)
	end

	return 0
end

local fastZombieClawMins = Vector(-10, -10, -10)
local fastZombieClawMaxs = Vector(10, 10, 10)

local function FastZombieClawAttack(ply)
	if CLIENT or not ply:Alive() or not IsFastZombie(ply) then return end
	if (ply.ZCFastZombieNextClaw or 0) > CurTime() then return end
	if IsValid(ply.FakeRagdoll) or (ply.organism and (ply.organism.otrub or ply.organism.fake)) then return end

	ply.ZCFastZombieNextClaw = CurTime() + 0.8

	local hands = ply:GetWeapon("weapon_hands_sh")
	if IsValid(hands) then
		hands:SetFists(true)
		hands:SetLastShootTime(CurTime())
	end

	local direction = ply:GetAimVector()
	local startPos = ply:GetShootPos()
	local reach = tonumber(ply.ClawReachDistance) or 52

	ply:LagCompensation(true)
	local trace = util.TraceHull({
		start = startPos,
		endpos = startPos + direction * reach,
		mins = fastZombieClawMins,
		maxs = fastZombieClawMaxs,
		mask = MASK_SHOT_HULL,
		filter = {ply, hg.GetCurrentCharacter(ply)}
	})
	ply:LagCompensation(false)

	local target = trace.Entity
	if not IsValid(target) or target:IsWorld() then return end

	local hitPos = trace.HitPos
	if hgIsDoor(target) then
		target.HP = (target.HP or 200) - (tonumber(ply.ClawDoorDamage) or 80)
		target:EmitSound("physics/wood/wood_crate_impact_hard" .. math.random(1, 4) .. ".wav", 85, math.random(90, 105))

		if target.HP <= 0 and not target:GetNoDraw() then
			hgBlastThatDoor(target, direction * 175 + ply:GetVelocity() * 0.35)
		end
		return
	end

	local damage = DamageInfo()
	damage:SetAttacker(ply)
	damage:SetInflictor(IsValid(hands) and hands or ply)
	damage:SetDamage(math.Rand(42, 50) * (tonumber(ply.MeleeDamageMul) or 1))
	damage:SetDamageType(DMG_SLASH)
	damage:SetDamagePosition(hitPos)
	damage:SetDamageForce(direction * 1800)

	local oldPenetration
	if IsValid(hands) then
		oldPenetration = hands.Penetration
		hands.Penetration = tonumber(ply.ClawPenetration) or 2.25
	end

	target:TakeDamageInfo(damage)

	if IsValid(hands) then
		hands.Penetration = oldPenetration
	end

	sound.Play("npc/zombie/claw_strike" .. math.random(1, 3) .. ".wav", hitPos, 75, math.random(95, 110))
	util.Decal("Blood", hitPos - direction, hitPos + direction, target)
end

function CLASS.Think(self, time, dtime)
	local base = GetZombieBase()
	if base and base.Think then
		base.Think(self, time, dtime)
	end

	if CLIENT and CLASS.UpdateFirstPersonHead then
		CLASS.UpdateFirstPersonHead(self)
	end

	if SERVER then
		if self.organism and self.organism.stamina then
			self.organism.stamina.max = 300
			self.organism.stamina.range = 300
		end

		if self:KeyDown(IN_ATTACK) then
			FastZombieClawAttack(self)
		end
	end
end

local zombiePain = {"npc/zombie/zombie_die2.wav"}
local zombiePhrases = {}

for index = 1, 6 do
	zombiePain[#zombiePain + 1] = "npc/zombie/zombie_pain" .. index .. ".wav"
end

for index = 1, 3 do
	zombiePhrases[#zombiePhrases + 1] = "npc/zombie/zombie_alert" .. index .. ".wav"
end

for index = 1, 14 do
	zombiePhrases[#zombiePhrases + 1] = "npc/zombie/zombie_voice_idle" .. index .. ".wav"
end

hook.Add("HG_ReplaceBurnPhrase", "FastZombieBurnPhrases", function(ply)
	if IsFastZombie(ply) then
		return ply, zombiePhrases[math.random(#zombiePhrases)]
	end
end)

hook.Add("HG_ReplacePhrase", "FastZombiePhrases", function(ply, phrase, muffed, pitch)
	if not IsFastZombie(ply) then return end

	local inPain = ply.organism and ply.organism.pain > 30
	local sounds = inPain and zombiePain or zombiePhrases
	return ply, sounds[math.random(#sounds)], not inPain, pitch
end)

hook.Add("HG_CanThoughts", "FastZombieThoughts", function(ply)
	if IsFastZombie(ply) then return false end
end)

hook.Add("PlayerCanPickupWeapon", "FastZombieWeaponPickup", function(ply, ent)
	if IsFastZombie(ply) and ent:GetClass() ~= "weapon_hands_sh" then return false end
end)

hook.Add("PlayerUse", "FastZombieUse", function(ply, ent)
	if IsFastZombie(ply) and ent:GetClass() ~= "func_button" then return false end
end)

hook.Add("HG_MovementCalc_2", "FastZombieSpeed", function(mul, ply)
	if not IsFastZombie(ply) then return end

	mul[1] = ply:IsSprinting() and 1.5 or 1
	if ply.SpeedGainMul ~= 95 then
		ply.SpeedGainMul = 95
	end
end)

hook.Add("UpdateAnimation", "FastZombieAnimationRate", function(ply, vel, maxSeqGroundSpeed)
	if not IsFastZombie(ply) then return end

	local isAmputated = ply:IsBerserk() and ply.organism and (ply.organism.llegamputated or ply.organism.rlegamputated)
	if not ply:Alive() or isAmputated then return end

	local state = GetFastZombieAnimationState(ply, vel)
	ply.ZCFastZombieAnimationState = state
	local speed = vel:Length2D()
	local playbackRate = 1

	if state == "run" then
		playbackRate = math.Clamp(speed / 250, 0.85, 1.7)
	elseif state == "walk" then
		playbackRate = math.Clamp(speed / 90, 0.6, 1.35)
	elseif state == "melee" then
		playbackRate = 1.15
	elseif state == "jump" then
		playbackRate = 0.9
	end

	if speed > 1 then
		local moveYaw = math.NormalizeAngle(vel:Angle().y - ply:EyeAngles().y)
		ply.ZCFastZombieMoveYaw = moveYaw
		ply:SetPoseParameter("move_yaw", moveYaw)
	else
		ply.ZCFastZombieMoveYaw = 0
		ply:SetPoseParameter("move_yaw", 0)
	end

	ply:SetPlaybackRate(playbackRate)
	return true
end, -1)

if SERVER then
	hook.Add("KeyPress", "FastZombieLeap", function(ply, key)
		if key ~= IN_JUMP or not IsFastZombie(ply) or not ply:Alive() or not ply:OnGround() then return end
		if IsValid(ply.FakeRagdoll) or (ply.organism and (ply.organism.otrub or ply.organism.fake)) then return end

		local velocity = ply:GetVelocity()
		local direction = Vector(velocity.x, velocity.y, 0)
		if direction:LengthSqr() < 900 then
			direction = ply:EyeAngles():Forward()
			direction.z = 0
		end
		if direction:LengthSqr() < 0.01 then direction = ply:GetForward() end
		direction:Normalize()

		timer.Simple(0, function()
			if not IsFastZombie(ply) or not ply:Alive() or IsValid(ply.FakeRagdoll) then return end
			ply:SetVelocity(direction * 150 + Vector(0, 0, 65))
		end)
	end)

	hook.Add("HG_PlayerFootstep", "FastZombieFootsteps", function(ply)
		if not ply:Alive() or not IsFastZombie(ply) then return end
		if IsValid(ply.FakeRagdoll) and ply:GetNetVar("lastFake") == 0 then return end

		local character = hg.GetCurrentCharacter(ply)
		if not IsValid(character) then return end

		if not ply:IsSprinting() and (ply:KeyDown(IN_DUCK) or ply:KeyDown(IN_WALK)) then
			character:EmitSound("npc/zombie/foot_slide" .. math.random(3) .. ".wav", 60, math.random(95, 105), 0.5)
		else
			character:EmitSound("npc/zombie/foot" .. math.random(3) .. ".wav", 65, math.random(100, 110))
		end

		return true
	end)

	hook.Add("ZB_CanLootInventory", "FastZombieLoot", function(ply, ent)
		if IsFastZombie(ply) then return ply, ent, false end
	end)

	hook.Add("HG_PlayerCanHearPlayersVoice", "FastZombieVoice", function(listener, speaker)
		if not IsFastZombie(speaker) then return end

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

hook.Add("PlayerCanLegAttack", "FastZombieKick", function(ply)
	if IsFastZombie(ply) then return false end
end)

hook.Add("CalcMainActivity", "FastZombieAnimations", function(ply, vel)
	if not IsFastZombie(ply) then return end
	if ply:GetNWString("hg_CustomAnim", "") ~= "" then return end

	local state = GetFastZombieAnimationState(ply, vel)
	ply.ZCFastZombieAnimationState = state

	return -1, GetFastZombieSequence(ply, state)
end, -1)

hook.Add("CanPlayerEnterVehicle", "FastZombieVehicle", function(ply)
	if IsFastZombie(ply) then return false end
end)

if CLIENT then
	local fastZombieVision = Material("effects/shaders/zb_grain2")
	local motionColor = Color(220, 42, 22)
	local motionTargets = {}
	local nextMotionScan = 0
	local smoothedSpeed = 0
	local colorModify = {
		["$pp_colour_addr"] = 0.012,
		["$pp_colour_addg"] = -0.004,
		["$pp_colour_addb"] = -0.006,
		["$pp_colour_brightness"] = 0,
		["$pp_colour_contrast"] = 1.12,
		["$pp_colour_colour"] = 0.52,
		["$pp_colour_mulr"] = 0.065,
		["$pp_colour_mulg"] = 0,
		["$pp_colour_mulb"] = -0.01
	}

	hook.Add("Post Post Processing", "FastZombieVision", function()
		local ply = LocalPlayer()
		if not IsFastZombie(ply) or not ply:Alive() or GetViewEntity() ~= ply then return end

		local targetSpeed = math.Clamp(ply:GetVelocity():Length2D() / 550, 0, 1)
		smoothedSpeed = Lerp(math.Clamp(FrameTime() * 4, 0, 1), smoothedSpeed, targetSpeed)

		colorModify["$pp_colour_contrast"] = 1.12 + smoothedSpeed * 0.06
		colorModify["$pp_colour_colour"] = 0.52 - smoothedSpeed * 0.08
		colorModify["$pp_colour_mulr"] = 0.065 + smoothedSpeed * 0.04
		DrawColorModify(colorModify)

		render.UpdateScreenEffectTexture()
		fastZombieVision:SetFloat("$c0_x", CurTime() * 0.35)
		fastZombieVision:SetFloat("$c0_y", -1)
		fastZombieVision:SetFloat("$c0_z", 0.7 + smoothedSpeed * 0.45)
		fastZombieVision:SetFloat("$c1_x", 10)
		fastZombieVision:SetFloat("$c1_y", 0.13 + smoothedSpeed * 0.16)
		fastZombieVision:SetFloat("$c1_z", 0.02 + smoothedSpeed * 0.07)
		fastZombieVision:SetFloat("$c2_x", 0.14 + smoothedSpeed * 0.14)
		fastZombieVision:SetFloat("$c2_y", 0.015)
		fastZombieVision:SetFloat("$c2_z", 0.01)
		fastZombieVision:SetFloat("$c3_x", 0)

		render.SetMaterial(fastZombieVision)
		render.DrawScreenQuad()

		if smoothedSpeed > 0.3 then
			DrawMotionBlur(0.015, (smoothedSpeed - 0.3) * 0.11, 0.01)
		end
	end)

	hook.Add("PreDrawHalos", "FastZombieMotionInstinct", function()
		local ply = LocalPlayer()
		if not IsFastZombie(ply) or not ply:Alive() or GetViewEntity() ~= ply then
			motionTargets = {}
			return
		end

		local time = CurTime()
		if time >= nextMotionScan then
			nextMotionScan = time + 0.18
			local targets = {}
			local eyePos = ply:EyePos()

			for _, target in ipairs(player.GetAll()) do
				if target == ply or not target:Alive() then continue end
				if target.PlayerClassName == "fastzombie" or target.PlayerClassName == "headcrabzombie" or target.PlayerClassName == "poisonzombie" then continue end

				local character = hg.GetCurrentCharacter(target)
				if not IsValid(character) or eyePos:DistToSqr(character:WorldSpaceCenter()) > 1960000 then continue end
				if character:GetVelocity():Length2DSqr() < 7225 then continue end

				local blocked = util.TraceLine({
					start = eyePos,
					endpos = character:WorldSpaceCenter(),
					filter = {ply, character, target},
					mask = MASK_VISIBLE
				}).Hit
				if blocked then continue end

				targets[#targets + 1] = character
			end

			motionTargets = targets
		end

		if #motionTargets > 0 then
			halo.Add(motionTargets, motionColor, 1.5, 1.5, 1, true, false)
		end
	end)
end
