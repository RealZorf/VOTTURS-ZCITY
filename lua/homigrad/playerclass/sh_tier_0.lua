player.classList = player.classList or {}
local classList = player.classList
local PlayerMeta = FindMetaTable("Player")
function PlayerMeta:GetPlayerClass()
	return classList[self.PlayerClassName or ""]
end

local meta
function PlayerMeta:PlayerClassEvent(name, ...) --haha
	meta = self:GetPlayerClass()
	meta = meta and meta[name]
	if meta then return meta(self, ...) end
end

function player.RegClass(name)
	local class = classList[name] or {}
	classList[name] = class
	return class
end

function player.EventPoint(pos, name, radius, ...)
	for i, ply in player.Iterator() do
		if ply:GetPos():Distance(pos) > radius then continue end
		ply:PlayerClassEvent("EventPoint", name, pos, radius, ...)
	end
end

function player.Event(ply, name, ...)
	ply:PlayerClassEvent("Event", name, ...)
end

local function ResetClassAnimationState(ply)
	if not IsValid(ply) then return end

	if ply.AnimResetGestureSlot then
		for slot = 0, 6 do
			ply:AnimResetGestureSlot(slot)
		end
	end

	if ply.AnimRestartMainSequence then ply:AnimRestartMainSequence() end
	if ply.SetCycle then ply:SetCycle(0) end
	if ply.SetPlaybackRate then ply:SetPlaybackRate(1) end
end

if SERVER then return end

local vecZero = Vector(0, 0, 0)
local angZero = Angle(0, 0, 0)
local vecFull = Vector(1, 1, 1)

local function ResetClassVisualState(ply)
	if not IsValid(ply) then return end

	ResetClassAnimationState(ply)

	-- First-person head hiding is clientside and can leave stale bone-index
	-- manipulations behind when a live class change swaps the player model.
	ply.ZC_FirstPersonHeadHidden = nil
	ply.manipulated = {}
	ply.unmanipulated = {}
	ply.manipulate = {}
	ply.matrixes = {}
	if hg.ResetTPIKState then
		hg.ResetTPIKState(ply)
	end

	local boneCount = ply.GetBoneCount and ply:GetBoneCount() or 0
	if ply.ManipulateBonePosition and ply.ManipulateBoneAngles and ply.ManipulateBoneScale then
		for bone = 0, boneCount do
			ply:ManipulateBonePosition(bone, vecZero, true)
			ply:ManipulateBoneAngles(bone, angZero, true)
			ply:ManipulateBoneScale(bone, vecFull, true)
		end
	end

	if ply.InvalidateBoneCache then ply:InvalidateBoneCache() end
	if ply.SetupBones then ply:SetupBones() end

	if ply ~= LocalPlayer() then return end

	local viewModel = ply:GetViewModel()
	if not IsValid(viewModel) then return end

	if viewModel.SetCycle then viewModel:SetCycle(0) end
	if viewModel.SetPlaybackRate then viewModel:SetPlaybackRate(1) end
	if viewModel.InvalidateBoneCache then viewModel:InvalidateBoneCache() end
	if viewModel.SetupBones then viewModel:SetupBones() end
end

local function QueueClassVisualReset(ply)
	ResetClassVisualState(ply)

	for _, delay in ipairs({0, 0.1, 0.35}) do
		timer.Simple(delay, function()
			if IsValid(ply) then ResetClassVisualState(ply) end
		end)
	end
end

net.Receive("setupclass", function()
	local ply = net.ReadEntity()
	if not IsValid(ply) then --lol
		return
	end

	ply.PlayerClassName = net.ReadString()
	ply.PlayerClassNameOld = net.ReadString()
	local data = net.ReadTable()
	local old = classList[ply.PlayerClassNameOld]
	if old and old.Off then old.Off(ply) end
	ply:PlayerClassEvent("On", data)
	QueueClassVisualReset(ply)
end)

hook.Add("PostDrawAppearance", "PlayerClass", function(ent,ply) end)

if CLIENT then
	hook.Add("Player Think", "ClassPlyThink", function(ply, time, dtime)
		ply:PlayerClassEvent("Think", time, dtime)
	end)
end

--hook.Add("HGReloading", "PlayerClass", function(wep) wep:GetOwner():PlayerClassEvent("HGReloading", wep) end)
--hook.Add("PlayerFootstep", "PlayerClass", function(ply, pos, foot, sound, volume, rf) ply:PlayerClassEvent("PlayerFootstep", ply, pos, foot, sound, volume, rf) end)
