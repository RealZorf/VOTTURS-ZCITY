local net, hg, pairs, Vector, ents, IsValid, util = net, hg, pairs, Vector, ents, IsValid, util

local vecZero = Vector(0,0,0)
local vecInf = Vector(0,0,0) / 0

local function removeBone(rag, bone, phys_bone, nohuys)
	if !nohuys then rag:ManipulateBoneScale(bone, vecZero) end
	--rag:ManipulateBonePosition(bone,vecInf) -- Thanks Rama (only works on certain graphics cards!)

	if rag.gibRemove[phys_bone] then return end

	local phys_obj = rag:GetPhysicsObjectNum(phys_bone)
	phys_obj:EnableCollisions(false)
	phys_obj:SetMass(0.1)
	--rag:RemoveInternalConstraint(phys_bone)

	constraint.RemoveAll(phys_obj)
	rag.gibRemove[phys_bone] = phys_obj
end

local function recursive_bone(rag, bone, list)
	for i,bone in pairs(rag:GetChildBones(bone)) do
		if bone == 0 then continue end

		list[#list + 1] = bone

		recursive_bone(rag, bone, list)
	end
end

function Gib_RemoveBone(rag, bone, phys_bone, nohuys)
	rag.gibRemove = rag.gibRemove or {}

	removeBone(rag, bone, phys_bone, nohuys)

	local list = {}
	recursive_bone(rag, bone, list)
	for i, bone in pairs(list) do
		removeBone(rag, bone, rag:TranslateBoneToPhysBone(bone), nohuys)
	end
end

gib_ragdols = gib_ragdols or {}
local gib_ragdols = gib_ragdols

local VectorRand, ents_Create = VectorRand, ents.Create
local CurTime = CurTime
local hg_gib_limit = ConVarExists("hg_gib_limit") and GetConVar("hg_gib_limit") or CreateConVar("hg_gib_limit", "80", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Maximum number of active Homigrad meat gibs.", 0, 512)
local hg_gib_lifetime = ConVarExists("hg_gib_lifetime") and GetConVar("hg_gib_lifetime") or CreateConVar("hg_gib_lifetime", "25", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Lifetime of Homigrad meat gibs in seconds. 0 disables timed cleanup.", 0, 300)
local hg_gib_freeze_delay = ConVarExists("hg_gib_freeze_delay") and GetConVar("hg_gib_freeze_delay") or CreateConVar("hg_gib_freeze_delay", "4", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Delay before settled Homigrad meat gibs are frozen.", 0, 60)
hg.meatGibs = hg.meatGibs or {}
local trackedMeatGibs = hg.meatGibs

local function TrimTrackedMeatGibs()
	for i = #trackedMeatGibs, 1, -1 do
		if not IsValid(trackedMeatGibs[i]) then
			table.remove(trackedMeatGibs, i)
		end
	end

	local maxGibs = math.max(hg_gib_limit:GetInt(), 0)
	local overflow = #trackedMeatGibs - maxGibs

	if overflow <= 0 then return end

	table.sort(trackedMeatGibs, function(a, b)
		return (a.hg_meat_gib_spawn or 0) < (b.hg_meat_gib_spawn or 0)
	end)

	local removeQueue = {}
	for i = 1, overflow do
		removeQueue[i] = trackedMeatGibs[i]
	end

	for i = 1, #removeQueue do
		local ent = removeQueue[i]
		if IsValid(ent) then ent:Remove() end
	end
end

local function FreezeTrackedMeatGib(ent)
	if not IsValid(ent) then return end

	local phys = ent:GetPhysicsObject()
	if not IsValid(phys) or phys:GetVelocity():LengthSqr() > 144 then return end

	ent:SetNotSolid(true)
	phys:EnableMotion(false)
	phys:Sleep()
end

local function TrackMeatGib(ent)
	ent.hg_meat_gib_spawn = CurTime()
	trackedMeatGibs[#trackedMeatGibs + 1] = ent

	ent:CallOnRemove("hg_meat_gib_cleanup", function()
		for i = #trackedMeatGibs, 1, -1 do
			if trackedMeatGibs[i] == ent then
				table.remove(trackedMeatGibs, i)
				break
			end
		end
	end)

	timer.Simple(hg_gib_freeze_delay:GetFloat(), function()
		FreezeTrackedMeatGib(ent)
	end)

	TrimTrackedMeatGibs()
end

local vector_up = Vector(0,0,1)
local function PhysCallback( ent, data )
	--data.HitPos -- data.HitNormal
	if data.DeltaTime < 0.2 then return end

	local now = CurTime()
	if (ent.hg_nextImpact or 0) > now then return end
	ent.hg_nextImpact = now + 0.15

	ent:EmitSound("physics/flesh/flesh_squishy_impact_hard"..math.random(4)..".wav")
	-- if !data.HitEntity:IsPlayer() and !data.HitEntity:IsRagdoll() and math.abs(data.HitNormal.z) < 0.75 then
	-- 	ent:SetMoveType(MOVETYPE_NONE)
	-- 	ent:SetSolid(SOLID_NONE)

	-- 	local tr = util.QuickTrace(data.HitPos - data.HitNormal * 1, data.HitNormal)
	-- 	ent:SetPos(tr.HitPos)
	-- 	local entindex = ent:EntIndex()
	-- 	local speed = math.Rand(0.2,0.4)
	-- 	local randspeed = math.Rand(-0.3,0.3)
	-- 	local needDecal = CurTime() + 1
	-- 	ent:SetModelScale(0, 10)
	-- 	SafeRemoveEntityDelayed(ent, 10)
	-- 	timer.Create("meatMove"..entindex, 0.1, 0, function()
	-- 		if !IsValid(ent) then timer.Remove("meatMove"..entindex) return end
	-- 		local tr = util.QuickTrace(ent:GetPos(), -data.HitNormal:Angle():Up())
	-- 		if math.abs(tr.HitNormal.z) > 0.75 then timer.Remove("meatMove"..entindex) return end
	-- 		local ang = data.HitNormal:Angle()
	-- 		ent:SetPos(ent:GetPos() - ang:Up() * speed + ang:Right() * randspeed)
	-- 		randspeed = LerpFT(0.05,randspeed, 0)
	-- 		if needDecal < CurTime() then
	-- 			needDecal = CurTime() + math.Rand(1,3)
	-- 			util.Decal("Normal.Blood24", ent:GetPos() - data.HitNormal * 1, ent:GetPos() + data.HitNormal * 1, ent)
	-- 		end
	-- 	end)
	-- end

	util.Decal("Normal.Blood24", data.HitPos - data.HitNormal * 1, data.HitPos + data.HitNormal * 1, ent)
end

local grub, mat, gamemod = Model("models/grub_nugget_small.mdl"), "models/flesh", engine.ActiveGamemode()
local meatModels = {
	Model("models/props_junk/watermelon01_chunk02a.mdl"),
}
function SpawnMeatGore(mainent, pos, count, force, scale)
	force = force or Vector(0,0,0)
	local gibRemoveTime = hg_gib_lifetime:GetFloat()
	for i = 1, (count or math.random(8, 10)) do
		local ent = ents_Create("prop_physics")
		ent:SetModel(meatModels[math.random(#meatModels)])
		ent:SetSubMaterial(0, mat)
		ent:SetPos(pos)
		ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		ent:SetModelScale(math.Rand(0.8,1.1) * (scale or 1))
		ent:SetAngles(AngleRand(-180,180))
		ent:Activate()
		ent:Spawn()
		ent:DrawShadow(false)

		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then
			phys:SetVelocity(mainent:GetVelocity() + VectorRand(-65,65) + force / 10)
			phys:AddAngleVelocity(VectorRand(-65,65))
		end

		if gibRemoveTime > 0 then
			ent:SetModelScale(0, gibRemoveTime)
			SafeRemoveEntityDelayed(ent, gibRemoveTime)
		end

		TrackMeatGib(ent)
		ent:AddCallback( "PhysicsCollide", PhysCallback )
	end
end

local headpos_male, headpos_female, headang = Vector(0,0,5), Vector(-2,0,4), Angle(0,0,-0)

util.AddNetworkString("addfountain")

hg.fountains = hg.fountains or {}
local headboom_mdl = Model("models/gleb/zcity/headboom.mdl")
local sounds = {
	Sound("player/zombie_head_explode_01.wav"),
	Sound("player/zombie_head_explode_02.wav"),
	Sound("player/zombie_head_explode_03.wav"),
	Sound("player/zombie_head_explode_04.wav"),
	Sound("player/zombie_head_explode_05.wav"),
	Sound("player/zombie_head_explode_06.wav")
}
util.PrecacheModel(headboom_mdl)
for _, snd in ipairs(sounds) do
	util.PrecacheSound(snd)
end
function Gib_Input(rag, bone, force)
	if not IsValid(rag) then return end
	
	local gibRemove = rag.gibRemove

	if not gibRemove then
		rag.gibRemove = {}
		gibRemove = rag.gibRemove

		gib_ragdols[rag] = true
	end

	local phys_bone = rag:TranslateBoneToPhysBone(bone)
	local phys_obj = rag:GetPhysicsObjectNum(phys_bone)
	
	if (not gibRemove[phys_bone]) and (bone == rag:LookupBone("ValveBiped.Bip01_Head1")) then
		--sound.Emit(rag,"player/headshot" .. math.random(1, 2) .. ".wav")
		--sound.Emit(rag,"physics/flesh/flesh_squishy_impact_hard" .. math.random(2, 4) .. ".wav")
		--sound.Emit(rag,"physics/body/body_medium_break3.wav")
		--sound.Emit(rag,"physics/glass/glass_sheet_step" .. math.random(1,4) .. ".wav", 90, 50, 2)
		rag:EmitSound(sounds[math.random(#sounds)], 70, math.random(95, 105), 2)

		Gib_RemoveBone(rag, bone, phys_bone)
		
		--rag:ManipulateBoneScale(rag:LookupBone("ValveBiped.Bip01_Neck1"),vecZero)
		rag:ManipulateBonePosition(rag:LookupBone("ValveBiped.Bip01_Neck1"),Vector(-1,0,0))

		local ent = ents_Create("prop_dynamic")
		ent:SetModel(headboom_mdl)
		local att = rag:GetAttachment(3)
		local pos, ang = LocalToWorld(ThatPlyIsFemale(rag) and headpos_female or headpos_male, headang, att.Pos, att.Ang)
		ent:SetPos(pos)
		ent:SetAngles(ang)
		--ent:AddEffects(EF_FOLLOWBONE)
		ent:SetParent(rag, 3)--rag:LookupBone("ValveBiped.Bip01_Head1"))
		ent:Spawn()

		SpawnMeatGore(ent, pos, nil, force) --change the models and it will be epic

		local armors = rag:GetNetVar("Armor",{})

		if armors["head"] and !hg.armor["head"][armors["head"]].nodrop then
			local ent = hg.DropArmorForce(rag, armors["head"])
			ent:SetPos(phys_obj:GetPos())
		end
		
		if armors["face"] and !hg.armor["face"][armors["face"]].nodrop then
			local ent = hg.DropArmorForce(rag, armors["face"])
			ent:SetPos(phys_obj:GetPos())
		end

		rag.noHead = true
		rag:SetNWString("PlayerName", "Beheaded body")

		net.Start("addfountain")
		net.WriteEntity(rag)
		net.WriteVector(force or vector_origin)
		net.Broadcast()

		hg.fountains[rag] = {bone = rag:LookupBone("ValveBiped.Bip01_Neck1"), lpos = ThatPlyIsFemale(rag) and Vector(4,0,0) or Vector(5,0,0),lang = Angle(0,0,0)}

		rag:CallOnRemove("removefountain", function()
			hg.fountains[rag] = nil
			SetNetVar("fountains", hg.fountains)
		end)

		SetNetVar("fountains", hg.fountains)
	end
end
